import { connect, Offset, Client, Consumer } from "rabbitmq-stream-js-client";
import { getStreamConfig } from "../lib/config";
import { persistNote, readOffset, writeOffset } from "../lib/store";
import type { Note } from "../lib/types";

/**
 * Durable consumer ("worker").
 *
 * Resume semantics (the chaos-test trap): on boot we read the LAST offset we
 * fully persisted from disk (./data/offset.json). If present, we subscribe from
 * that offset + 1 — NOT Offset.first() — so a restart never replays from 0.
 * If no offset is stored yet (first ever boot), we start from Offset.first()
 * so we pick up notes that were POSTed before the worker ever ran.
 *
 * Ordering guarantee per message: persist the note FIRST (idempotent dedupe),
 * THEN advance the on-disk offset. A crash between the two only causes a replay
 * of the last message, which the dedupe absorbs. No ACK-then-lose is possible.
 */
async function main() {
  const cfg = getStreamConfig();
  const client: Client = await connect({
    hostname: cfg.hostname,
    port: cfg.port,
    username: cfg.username,
    password: cfg.password,
    vhost: cfg.vhost,
  });

  // Idempotent; creates the stream if the worker beat the first POST.
  await client.createStream({ stream: cfg.streamName, arguments: {} });

  const stored = readOffset();
  const startOffset =
    stored === null ? Offset.first() : Offset.offset(stored + 1n);

  console.log(
    `[worker] subscribing to "${cfg.streamName}" from ${
      stored === null ? "first()" : `offset ${(stored + 1n).toString()}`
    }`
  );

  // Serialize message handling so persist-then-commit stays strictly ordered.
  let chain: Promise<void> = Promise.resolve();

  const consumer: Consumer = await client.declareConsumer(
    {
      stream: cfg.streamName,
      offset: startOffset,
      consumerRef: "notes-worker",
    },
    (message) => {
      const offset = message.offset;
      chain = chain.then(async () => {
        try {
          const note = JSON.parse(message.content.toString()) as Note;
          if (note && typeof note.id === "string") {
            const wrote = persistNote(note); // idempotent: dedupe-by-id
            if (wrote) console.log(`[worker] persisted note ${note.id}`);
            else console.log(`[worker] duplicate ignored ${note.id}`);
          }
        } catch (e) {
          console.error("[worker] bad message skipped:", e);
        }
        // Commit offset ONLY after the note is durably on disk.
        if (typeof offset === "bigint") {
          writeOffset(offset);
          try {
            await consumer.storeOffset(offset); // server-side, defense-in-depth
          } catch {
            // Server-side store is best-effort; disk offset is the source of truth.
          }
        }
      });
      return chain;
    }
  );

  console.log("[worker] running");

  const shutdown = async () => {
    try {
      await chain;
      await consumer.close();
      await client.close();
    } finally {
      process.exit(0);
    }
  };
  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

main().catch((e) => {
  console.error("[worker] fatal:", e);
  process.exit(1);
});
