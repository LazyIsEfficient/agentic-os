// Server-side singleton that owns one RabbitMQ Stream connection + publisher
// for the Next.js process. POST /api/notes uses it to publish a note to the
// DURABLE STREAM and block until the broker confirms the write.
//
// Fault-tolerance contract: the stream is declared here (idempotently) so a
// POST succeeds even when the worker is down. The note is durable in the
// stream the moment the publisher confirm fires; the worker persists it later.

import { Client, Publisher } from "rabbitmq-stream-js-client";
import { getStreamConfig, PUBLISHER_REF, type Note } from "./config";

interface PublisherState {
  client: Client;
  publisher: Publisher;
  // Maps an in-flight publishingId -> resolver, so we can turn the broker's
  // async publish_confirm event into an awaited promise per message.
  pending: Map<string, { resolve: () => void; reject: (e: Error) => void }>;
}

// Cache on globalThis so Next's dev/HMR reloads reuse one connection instead
// of leaking a socket per module evaluation.
const globalForPublisher = globalThis as unknown as {
  __notesPublisher?: Promise<PublisherState>;
};

async function createPublisherState(): Promise<PublisherState> {
  const cfg = getStreamConfig();
  const client = await Client.connect({
    hostname: cfg.hostname,
    port: cfg.port,
    username: cfg.username,
    password: cfg.password,
    vhost: cfg.vhost,
  });

  // Declare the stream idempotently. Streams are disk-durable; this does not
  // require the worker to exist.
  await client.createStream({ stream: cfg.streamName });

  const pending = new Map<
    string,
    { resolve: () => void; reject: (e: Error) => void }
  >();

  const publisher = await client.declarePublisher({
    stream: cfg.streamName,
    publisherRef: PUBLISHER_REF,
  });

  // The broker confirms (or rejects) batches of publishingIds asynchronously.
  publisher.on("publish_confirm", (err, publishingIds) => {
    for (const id of publishingIds) {
      const key = id.toString();
      const waiter = pending.get(key);
      if (!waiter) continue;
      pending.delete(key);
      if (err) waiter.reject(new Error(`publish error code ${err}`));
      else waiter.resolve();
    }
  });

  return { client, publisher, pending };
}

function getPublisherState(): Promise<PublisherState> {
  if (!globalForPublisher.__notesPublisher) {
    globalForPublisher.__notesPublisher = createPublisherState().catch((e) => {
      // Reset on failure so the next request retries the connection.
      globalForPublisher.__notesPublisher = undefined;
      throw e;
    });
  }
  return globalForPublisher.__notesPublisher;
}

const CONFIRM_TIMEOUT_MS = 10_000;

// Publish one note and resolve ONLY after the broker has confirmed the write
// is durable in the stream. Rejects on timeout or broker error so the route
// can return a non-201 (we must never 201 an unconfirmed write).
export async function publishNote(note: Note): Promise<void> {
  const { publisher, pending } = await getPublisherState();
  const payload = Buffer.from(JSON.stringify(note), "utf8");

  const result = await publisher.send(payload);
  const key = result.publishingId.toString();

  // If somehow already confirmed (fast path), send() would still have queued a
  // pending entry race-free below — register the waiter before awaiting.
  await new Promise<void>((resolve, reject) => {
    const timer = setTimeout(() => {
      pending.delete(key);
      reject(new Error("publish confirm timeout"));
    }, CONFIRM_TIMEOUT_MS);

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

    // Flush to push the message out promptly rather than waiting for the
    // client's internal batch timer; the confirm cannot arrive before this.
    publisher.flush().catch((e) => {
      const waiter = pending.get(key);
      if (waiter) {
        pending.delete(key);
        waiter.reject(e as Error);
      }
    });
  });
}
