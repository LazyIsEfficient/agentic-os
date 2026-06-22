import type { Note } from "./config"

// The transient hand-off the POST path actually relies on. The worker runs a
// tiny local HTTP listener; the web process forwards each note to it directly.
// This is fast and works perfectly while the worker is up — but it is NOT a
// durable buffer. If the worker is down, the forward fails and the note is
// dropped on the floor while POST still returns 201. That is the durability bug.

const WORKER_INGEST_PORT = Number(
  process.env.WORKER_INGEST_PORT ?? 4001,
)
const WORKER_INGEST_HOST = process.env.WORKER_INGEST_HOST ?? "127.0.0.1"

export const workerIngest = {
  port: WORKER_INGEST_PORT,
  host: WORKER_INGEST_HOST,
}

// Forward a note to the worker's transient ingest endpoint. Returns true if the
// worker accepted it, false otherwise. The POST handler IGNORES the return value
// and acks optimistically — modelling "ack before the write is durably
// committed."
export async function deliverToWorker(note: Note): Promise<boolean> {
  try {
    const res = await fetch(
      `http://${WORKER_INGEST_HOST}:${WORKER_INGEST_PORT}/ingest`,
      {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(note),
        // Short timeout: if the worker is down we fail fast and (buggy) move on.
        signal: AbortSignal.timeout(1500),
      },
    )
    return res.ok
  } catch {
    // Worker down / unreachable: the note is lost. We swallow the error so the
    // caller can still (incorrectly) report success.
    return false
  }
}
