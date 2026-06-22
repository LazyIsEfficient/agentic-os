import { connect, Client, Publisher } from "rabbitmq-stream-js-client";
import { getStreamConfig } from "./config";

/**
 * Durable stream publisher. POST publishes here and returns 201 ONLY after the
 * broker's publish_confirm fires for that publishingId. This path NEVER touches
 * the worker/consumer — a POST while the worker is stopped still succeeds,
 * because the note lands in the durable stream and is consumed on recovery.
 */
let clientPromise: Promise<Client> | null = null;
let publisherPromise: Promise<Publisher> | null = null;

// publishingId -> resolver, settled by the publish_confirm event.
const pending = new Map<string, { resolve: () => void; reject: (e: Error) => void }>();

async function getClient(): Promise<Client> {
  if (!clientPromise) {
    const cfg = getStreamConfig();
    clientPromise = connect({
      hostname: cfg.hostname,
      port: cfg.port,
      username: cfg.username,
      password: cfg.password,
      vhost: cfg.vhost,
    }).catch((e) => {
      clientPromise = null;
      throw e;
    });
  }
  return clientPromise;
}

async function getPublisher(): Promise<Publisher> {
  if (!publisherPromise) {
    publisherPromise = (async () => {
      const cfg = getStreamConfig();
      const client = await getClient();
      // Idempotent: creates the stream if absent, no error if it exists.
      // POST may run before the worker has ever started.
      await client.createStream({ stream: cfg.streamName, arguments: {} });
      const publisher = await client.declarePublisher({
        stream: cfg.streamName,
        publisherRef: "notes-api-publisher",
      });
      publisher.on("publish_confirm", (err, publishingIds) => {
        for (const id of publishingIds) {
          const key = id.toString();
          const waiter = pending.get(key);
          if (!waiter) continue;
          pending.delete(key);
          if (err) waiter.reject(new Error("publish rejected by broker, code " + err));
          else waiter.resolve();
        }
      });
      return publisher;
    })().catch((e) => {
      publisherPromise = null;
      throw e;
    });
  }
  return publisherPromise;
}

/**
 * Publish a note payload and resolve ONLY after the broker confirms it.
 * Rejects on broker error or timeout so the route returns 500 (never a false 201).
 */
export async function publishNoteConfirmed(
  payload: unknown,
  timeoutMs = 5000
): Promise<void> {
  const publisher = await getPublisher();
  const buf = Buffer.from(JSON.stringify(payload));
  const res = await publisher.send(buf);
  const key = res.publishingId.toString();

  await new Promise<void>((resolve, reject) => {
    const timer = setTimeout(() => {
      pending.delete(key);
      reject(new Error("publish confirm timeout"));
    }, timeoutMs);

    pending.set(key, {
      resolve: () => {
        clearTimeout(timer);
        resolve();
      },
      reject: (e) => {
        clearTimeout(timer);
        reject(e);
      },
    });
  });
}
