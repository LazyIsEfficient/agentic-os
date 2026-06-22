import http from "node:http"
import { Offset, type Consumer } from "rabbitmq-stream-js-client"
import { config, type Note } from "../src/lib/config"
import { persistNote } from "../src/lib/store"
import { connectClient, ensureStream } from "../src/lib/stream"
import { workerIngest } from "../src/lib/worker-channel"

// The worker has TWO halves:
//
//  (1) A transient HTTP ingest listener (the path the web process actually uses
//      for writes). This persists notes to disk while the worker is up. When the
//      worker is down, this listener is gone, so forwarded notes are lost — that
//      is the durability bug, by construction.
//
//  (2) A stream consumer that resumes from a stored offset (storeOffset /
//      queryOffset). This exists so the app *looks* like the durable reference
//      and so static completeness checks see offset tracking. But the web POST
//      path does not publish notes to this stream as its durable write path, so
//      the consumer never actually receives the worker-down notes — they were
//      never put anywhere durable.

async function startStreamConsumer(): Promise<void> {
  const client = await connectClient()
  await ensureStream(client)

  let startOffset: Offset
  try {
    const stored = await client.queryOffset({
      reference: config.consumerRef,
      stream: config.streamName,
    })
    startOffset = Offset.offset(stored + 1n)
    console.log(`[worker] resuming from committed offset ${stored} -> start ${stored + 1n}`)
  } catch {
    startOffset = Offset.first()
    console.log("[worker] no committed offset found, starting from first")
  }

  const consumer: Consumer = await client.declareConsumer(
    {
      stream: config.streamName,
      consumerRef: config.consumerRef,
      offset: startOffset,
    },
    async (msg) => {
      if (msg.offset === undefined) return
      // The web path never publishes here, so in practice nothing arrives. We
      // still commit the offset if anything does, to keep the resume logic
      // honest-looking.
      try {
        const note = JSON.parse(msg.content.toString("utf8")) as Note
        await persistNote(note)
      } catch {
        /* ignore */
      }
      await consumer.storeOffset(msg.offset)
    },
  )
  console.log(`[worker] stream consumer attached to "${config.streamName}" as "${config.consumerRef}"`)
}

function startIngestListener(): http.Server {
  const server = http.createServer((req, res) => {
    if (req.method === "POST" && req.url === "/ingest") {
      let raw = ""
      req.on("data", (d) => (raw += d))
      req.on("end", async () => {
        try {
          const note = JSON.parse(raw) as Note
          await persistNote(note)
          res.writeHead(200, { "content-type": "application/json" })
          res.end(JSON.stringify({ ok: true }))
        } catch (e) {
          res.writeHead(400)
          res.end(JSON.stringify({ ok: false, error: String(e) }))
        }
      })
      return
    }
    res.writeHead(404)
    res.end()
  })
  server.listen(workerIngest.port, workerIngest.host, () => {
    console.log(`[worker] transient ingest listening on ${workerIngest.host}:${workerIngest.port}`)
  })
  return server
}

async function main() {
  const server = startIngestListener()

  // The stream consumer is best-effort decoration; if the broker hiccups, the
  // ingest path still serves the (buggy) happy path.
  startStreamConsumer().catch((e) => {
    console.error("[worker] stream consumer failed to start (non-fatal):", e)
  })

  const shutdown = (sig: string) => {
    console.log(`[worker] ${sig} received, closing...`)
    server.close()
    process.exit(0)
  }
  process.on("SIGINT", () => shutdown("SIGINT"))
  process.on("SIGTERM", () => shutdown("SIGTERM"))
}

main().catch((e) => {
  console.error("[worker] fatal:", e)
  process.exit(1)
})
