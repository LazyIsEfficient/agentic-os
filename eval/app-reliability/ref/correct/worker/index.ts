import { Offset, type Consumer } from "rabbitmq-stream-js-client"
import { config, type Note } from "../src/lib/config"
import { persistNote } from "../src/lib/store"
import { connectClient, ensureStream } from "../src/lib/stream"

// Long-running consumer:
//   - resumes from the last COMMITTED offset stored server-side under consumerRef,
//   - persists each note idempotently (dedupe by id) to ./data/notes.json,
//   - commits (storeOffset) the offset after each persisted message.
// On restart it resumes from the stored offset -> no loss, no duplicates.

async function main() {
  const client = await connectClient()
  await ensureStream(client)

  // Determine where to resume. queryOffset throws when no offset has ever been stored
  // for this reference (fresh stream) -> start from the very first message.
  let startOffset: Offset
  try {
    const stored = await client.queryOffset({
      reference: config.consumerRef,
      stream: config.streamName,
    })
    // Resume strictly AFTER the last committed offset so we never re-process it.
    startOffset = Offset.offset(stored + 1n)
    console.log(`[worker] resuming from committed offset ${stored} -> start ${stored + 1n}`)
  } catch {
    startOffset = Offset.first()
    console.log("[worker] no committed offset found, starting from first")
  }

  let processed = 0
  let added = 0

  const consumer: Consumer = await client.declareConsumer(
    {
      stream: config.streamName,
      consumerRef: config.consumerRef,
      offset: startOffset,
    },
    async (msg) => {
      if (msg.offset === undefined) return
      let note: Note
      try {
        note = JSON.parse(msg.content.toString("utf8")) as Note
      } catch (e) {
        // Skip unparseable messages but still advance the offset so we don't loop.
        console.error(`[worker] skipping unparseable message at offset ${msg.offset}: ${e}`)
        await consumer.storeOffset(msg.offset)
        return
      }

      // Persist FIRST (idempotent dedupe by id), THEN commit the offset. If we crash
      // between persist and commit, the message is re-delivered on restart and the
      // dedupe makes the re-persist a no-op -> at-least-once delivery, exactly-once
      // effect.
      const isNew = await persistNote(note, msg.offset)
      await consumer.storeOffset(msg.offset)

      processed++
      if (isNew) added++
      console.log(
        `[worker] offset ${msg.offset} note ${note.id} ${isNew ? "ADDED" : "DUP"} ` +
          `(processed=${processed} added=${added})`,
      )
    },
  )

  console.log(`[worker] consuming stream "${config.streamName}" as "${config.consumerRef}"`)

  const shutdown = async (sig: string) => {
    console.log(`[worker] ${sig} received, closing...`)
    try {
      await consumer.close()
      await client.close()
    } finally {
      process.exit(0)
    }
  }
  process.on("SIGINT", () => void shutdown("SIGINT"))
  process.on("SIGTERM", () => void shutdown("SIGTERM"))
}

main().catch((e) => {
  console.error("[worker] fatal:", e)
  process.exit(1)
})
