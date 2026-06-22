import {
  connect,
  type Client,
  type Publisher,
} from "rabbitmq-stream-js-client"
import { config } from "./config"

export async function connectClient(): Promise<Client> {
  return connect({
    hostname: config.hostname,
    port: config.port,
    username: config.username,
    password: config.password,
    vhost: config.vhost,
  })
}

// Declare the durable stream. createStream is idempotent: it resolves true whether the
// stream is newly created or already exists, so both web and worker can call it safely.
export async function ensureStream(client: Client): Promise<void> {
  await client.createStream({
    stream: config.streamName,
    arguments: { "max-length-bytes": config.streamMaxLengthBytes },
  })
}

type Pending = {
  resolve: (id: bigint) => void
  reject: (err: Error) => void
  timer: ReturnType<typeof setTimeout>
}

// A publisher that resolves only after the BROKER confirms the write. This is the crux
// of the fault-tolerance guarantee: POST /api/notes returns 201 only once the durable
// stream has acknowledged the message, independent of whether the worker is running.
//
// The underlying client `publisher.on("publish_confirm", ...)` registers a listener on
// the shared connection with NO removal API, so we register exactly ONE listener for the
// lifetime of the publisher and dispatch each confirm to the matching pending publish by
// its publishingId. Registering per-call would leak listeners on the shared connection.
export class ConfirmingPublisher {
  private readonly pending = new Map<string, Pending>()

  private constructor(
    private readonly client: Client,
    private readonly publisher: Publisher,
  ) {
    this.publisher.on("publish_confirm", (err: number | null, ids: bigint[]) => {
      for (const id of ids) {
        const key = id.toString()
        const p = this.pending.get(key)
        if (!p) continue
        this.pending.delete(key)
        clearTimeout(p.timer)
        if (err) p.reject(new Error(`publish_confirm error code ${err}`))
        else p.resolve(id)
      }
    })
  }

  static async create(): Promise<ConfirmingPublisher> {
    const client = await connectClient()
    await ensureStream(client)
    const publisher = await client.declarePublisher({
      stream: config.streamName,
      publisherRef: config.publisherRef,
    })
    return new ConfirmingPublisher(client, publisher)
  }

  // Publish one message and wait for the broker's publish confirm for its publishingId.
  // Rejects on publish error or timeout, so the caller never returns 201 for an
  // unconfirmed write.
  async publish(payload: Buffer, timeoutMs = 5000): Promise<bigint> {
    // send() resolves once the message is buffered/sent and returns its publishingId.
    // The confirm arrives asynchronously afterwards via the single listener above.
    const res = await this.publisher.send(payload)
    const id = res.publishingId
    const key = id.toString()

    return new Promise<bigint>((resolve, reject) => {
      // Guard against a confirm racing in before this promise body runs: if the listener
      // already saw and discarded this id, we would hang. In practice the confirm is a
      // separate network round-trip that cannot complete before send() resolves, so
      // registering here is safe. The timeout is the backstop either way.
      const timer = setTimeout(() => {
        if (this.pending.delete(key)) {
          reject(new Error("publish confirm timeout"))
        }
      }, timeoutMs)
      this.pending.set(key, { resolve, reject, timer })
    })
  }

  async close(): Promise<void> {
    for (const [, p] of this.pending) {
      clearTimeout(p.timer)
      p.reject(new Error("publisher closing"))
    }
    this.pending.clear()
    await this.publisher.close()
    await this.client.close()
  }
}

// Module-level singleton so each Node server process reuses one broker connection
// rather than reconnecting per request.
let publisherPromise: Promise<ConfirmingPublisher> | null = null

export function getPublisher(): Promise<ConfirmingPublisher> {
  if (!publisherPromise) {
    publisherPromise = ConfirmingPublisher.create().catch((e) => {
      // Reset so the next request retries the connection instead of caching a failure.
      publisherPromise = null
      throw e
    })
  }
  return publisherPromise
}
