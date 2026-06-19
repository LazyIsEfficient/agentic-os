import { NextResponse } from "next/server"
import { randomUUID } from "node:crypto"
import { readNotes } from "@/lib/store"
import { getPublisher } from "@/lib/stream"
import { deliverToWorker } from "@/lib/worker-channel"
import type { Note } from "@/lib/config"

export const dynamic = "force-dynamic"
export const runtime = "nodejs"

// GET /api/notes -> the persisted notes the worker has stored on disk.
export async function GET() {
  const notes = readNotes()
  return NextResponse.json(notes, { status: 200 })
}

// POST /api/notes { title, body } -> 201 { id }.
//
// THE BUG: this looks fault-tolerant — it even warms up a stream publisher — but
// it acks the client BEFORE the write is durably committed. The real write path
// is a transient hand-off to the worker (deliverToWorker). When the worker is
// up, the note is delivered and persisted, so contract + the happy path pass.
// When the worker is DOWN, the hand-off fails, the note is dropped, and we STILL
// return 201. Those notes are gone forever — they were never buffered durably.
// This is the #1 real-world mistake: ack before the durable write.
export async function POST(request: Request) {
  let payload: unknown
  try {
    payload = await request.json()
  } catch {
    return NextResponse.json({ error: "invalid JSON body" }, { status: 400 })
  }

  const { title, body } = (payload ?? {}) as { title?: unknown; body?: unknown }
  if (typeof title !== "string" || typeof body !== "string") {
    return NextResponse.json(
      { error: "title and body are required strings" },
      { status: 400 },
    )
  }

  const MAX_TITLE = 1_000
  const MAX_BODY = 100_000
  if (title.length > MAX_TITLE || body.length > MAX_BODY) {
    return NextResponse.json(
      { error: `title must be <= ${MAX_TITLE} and body <= ${MAX_BODY} chars` },
      { status: 413 },
    )
  }

  const note: Note = {
    id: randomUUID(),
    title,
    body,
    createdAt: new Date().toISOString(),
  }

  // Warm up the stream publisher so the connection exists (and so a casual
  // reviewer sees a stream being used). We do NOT block on a durable confirm.
  try {
    await getPublisher()
  } catch {
    // Even if the stream is unavailable we proceed — the transient hand-off is
    // what we actually depend on. (This is part of the bug.)
  }

  // Hand the note to the worker over the transient channel. We ignore whether it
  // succeeded and ack optimistically.
  void deliverToWorker(note)

  return NextResponse.json({ id: note.id }, { status: 201 })
}
