// Long-running consumer. Reads the durable notes stream from its LAST COMMITTED
// OFFSET, persists each note idempotently to ./data/, and commits the offset.
//
// Fault-tolerance contract:
//  - On start it resumes from the offset recorded on disk (next-to-read), NOT
//    from offset 0, so it never replays the whole stream into duplicates.
//  - Persist-then-commit ordering: the note is written to disk BEFORE the
//    offset advances. If we crash between the two, the note is re-delivered on
//    restart and dedupe-by-id makes the re-persist a no-op. Net effect:
//    at-least-once delivery + idempotent store = exactly-once on disk.
//  - Notes posted while the worker was down sit durably in the stream and are
//    consumed on recovery — no acknowledged write is lost.

import { Client, Offset } from "rabbitmq-stream-js-client";

// `Message` isn't re-exported from the package index, so type the bits we use.
interface StreamMessage {
  content: Buffer;
  offset?: bigint;
}
import { getStreamConfig, CONSUMER_REF, type Note } from "../src/lib/config";
import { readNotes, writeNotes, readOffset, writeOffset } from "../src/lib/store";

async function main(): Promise<void> {
  const cfg = getStreamConfig();

  const client = await Client.connect({
    hostname: cfg.hostname,
    port: cfg.port,
    username: cfg.username,
    password: cfg.password,
    vhost: cfg.vhost,
  });

  // Declare idempotently so the worker can start before any POST has created
  // the stream (and vice versa).
  await client.createStream({ stream: cfg.streamName });

  // Resume point: prefer the disk-recorded next offset. Fall back to the
  // broker's server-side stored offset, then to the very first message.
  let startOffset: Offset;
  const diskOffset = await readOffset();
  if (diskOffset !== undefined) {
    startOffset = Offset.offset(diskOffset);
  } else {
    let serverOffset: bigint | undefined;
    try {
      serverOffset = await client.queryOffset({
        reference: CONSUMER_REF,
        stream: cfg.streamName,
      });
    } catch {
      serverOffset = undefined;
    }
    startOffset =
      serverOffset !== undefined && serverOffset > 0n
        ? Offset.offset(serverOffset)
        : Offset.first();
  }

  // In-memory index mirrors the on-disk store; keyed by note id for O(1)
  // dedupe. Seeded from disk so a restart keeps prior notes.
  const notes = await readNotes();
  const seen = new Set(notes.map((n) => n.id));

  console.log(
    `[worker] connected to ${cfg.hostname}:${cfg.port} stream="${cfg.streamName}", ` +
      `resuming from ${diskOffset !== undefined ? `offset ${diskOffset}` : "stored/first"}, ` +
      `${notes.length} note(s) already persisted`,
  );

  const consumer = await client.declareConsumer(
    {
      stream: cfg.streamName,
      consumerRef: CONSUMER_REF,
      offset: startOffset,
    },
    async (message: StreamMessage) => {
      const messageOffset = message.offset ?? 0n;

      let note: Note;
      try {
        note = JSON.parse(message.content.toString("utf8")) as Note;
      } catch (e) {
        // Poison message: skip it but still advance the offset so we do not
        // get stuck reprocessing it forever.
        console.error(`[worker] skipping unparseable message: ${(e as Error).message}`);
        await commitOffset(messageOffset);
        return;
      }

      if (!seen.has(note.id)) {
        seen.add(note.id);
        notes.push(note);
        // Persist BEFORE committing the offset (see ordering note above).
        await writeNotes(notes);
        console.log(`[worker] persisted note ${note.id} at offset ${messageOffset}`);
      } else {
        console.log(`[worker] duplicate note ${note.id} at offset ${messageOffset} (skipped)`);
      }

      await commitOffset(messageOffset);
    },
  );

  // Commit = advance our resume point to the NEXT offset (consumed + 1), both
  // on the broker (server-side tracking) and on disk (source of truth on
  // restart).
  async function commitOffset(consumed: bigint): Promise<void> {
    const next = consumed + 1n;
    await writeOffset(next);
    try {
      await consumer.storeOffset(consumed);
    } catch (e) {
      // Server-side store is best-effort; disk offset is authoritative.
      console.warn(`[worker] storeOffset failed (non-fatal): ${(e as Error).message}`);
    }
  }

  const shutdown = async (sig: string) => {
    console.log(`[worker] received ${sig}, shutting down`);
    try {
      await client.close();
    } catch {
      /* ignore */
    }
    process.exit(0);
  };
  process.on("SIGINT", () => void shutdown("SIGINT"));
  process.on("SIGTERM", () => void shutdown("SIGTERM"));

  console.log("[worker] consuming…");
}

main().catch((e) => {
  console.error("[worker] fatal:", e);
  process.exit(1);
});
