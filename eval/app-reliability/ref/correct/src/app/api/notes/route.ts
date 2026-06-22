import { NextResponse } from "next/server"
import { randomUUID } from "node:crypto"
import { readNotes } from "@/lib/store"
import { getPublisher } from "@/lib/stream"
import type { Note } from "@/lib/config"

// Never statically optimize or cache: this route talks to the broker / disk per call.
export const dynamic = "force-dynamic"
export const runtime = "nodejs"

// GET /api/notes -> the PERSISTED notes (what the worker has consumed and stored).
export async function GET() {
  const notes = readNotes()
  return NextResponse.json(notes, { status: 200 })
}

// POST /api/notes { title, body } -> 201 { id } ONLY after the durable stream confirms.
// Does not depend on the worker being up.
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

  // Bound the payload so a single oversized request cannot bloat the stream/disk and
  // cannot exceed the stream frame size. Cheap defense; the harness never sends large
  // bodies, but the anchor should not accept unbounded input.
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

  try {
    const publisher = await getPublisher()
    await publisher.publish(Buffer.from(JSON.stringify(note), "utf8"))
  } catch (e) {
    // The broker did not confirm the write — do NOT report success.
    return NextResponse.json(
      { error: "failed to durably publish note", detail: String(e) },
      { status: 503 },
    )
  }

  return NextResponse.json({ id: note.id }, { status: 201 })
}
