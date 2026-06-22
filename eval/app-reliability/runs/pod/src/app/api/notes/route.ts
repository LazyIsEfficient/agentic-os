import { NextRequest, NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { readNotes } from "../../../../lib/store";
import { publishNoteConfirmed } from "../../../../lib/publisher";
import type { Note } from "../../../../lib/types";

// Never statically optimize; always run on the server at request time.
export const dynamic = "force-dynamic";
export const runtime = "nodejs";

/** GET — return the PERSISTED notes read from disk (what the worker stored). */
export async function GET() {
  const notes = readNotes();
  return NextResponse.json(notes, { status: 200 });
}

/**
 * POST — publish to the durable stream with a publisher confirm, return 201
 * ONLY after the broker confirms. The id is generated server-side so the
 * client gets it immediately, and the SAME id is embedded in the message so
 * the worker dedupes by it. This path does NOT touch the worker/consumer:
 * a POST while the worker is stopped still returns 201.
 */
export async function POST(req: NextRequest) {
  let parsed: unknown;
  try {
    parsed = await req.json();
  } catch {
    return NextResponse.json({ error: "invalid JSON body" }, { status: 400 });
  }

  const body = parsed as { title?: unknown; body?: unknown };
  const title = typeof body?.title === "string" ? body.title : "";
  const noteBody = typeof body?.body === "string" ? body.body : "";
  if (!title && !noteBody) {
    return NextResponse.json(
      { error: "title or body is required" },
      { status: 400 }
    );
  }

  const note: Note = {
    id: randomUUID(),
    title,
    body: noteBody,
    createdAt: new Date().toISOString(),
  };

  try {
    await publishNoteConfirmed(note);
  } catch (err) {
    return NextResponse.json(
      { error: "failed to durably publish note", detail: String(err) },
      { status: 500 }
    );
  }

  return NextResponse.json({ id: note.id }, { status: 201 });
}
