import {
  connect,
  type Client,
  type Publisher,
} from "rabbitmq-stream-js-client"
import { config } from "./config"

// NOTE: this app *imports* the stream client and declares a stream so it looks,
// at a glance, like the durable reference design. But the actual write path the
// POST handler uses is NOT this stream — it's a transient hand-off to the worker
// (see deliverToWorker below). The stream connection here is effectively
// decorative: it is established but never used as the durable buffer for writes.
// This is the realistic mistake the battery is designed to catch.

export async function connectClient(): Promise<Client> {
  return connect({
    hostname: config.hostname,
    port: config.port,
    username: config.username,
    password: config.password,
    vhost: config.vhost,
  })
}

export async function ensureStream(client: Client): Promise<void> {
  await client.createStream({
    stream: config.streamName,
    arguments: { "max-length-bytes": config.streamMaxLengthBytes },
  })
}

// Establish a publisher to the stream on first use. It exists, it connects, it
// even gets a publishingId back — but the POST handler does not block on a
// durable confirm before acking the client.
let publisherPromise: Promise<{ client: Client; publisher: Publisher }> | null =
  null

export function getPublisher(): Promise<{ client: Client; publisher: Publisher }> {
  if (!publisherPromise) {
    publisherPromise = (async () => {
      const client = await connectClient()
      await ensureStream(client)
      const publisher = await client.declarePublisher({
        stream: config.streamName,
        publisherRef: config.publisherRef,
      })
      return { client, publisher }
    })().catch((e) => {
      publisherPromise = null
      throw e
    })
  }
  return publisherPromise
}
