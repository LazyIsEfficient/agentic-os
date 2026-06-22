// GET  /api/notes  -> persisted notes the worker has stored (read from disk)
// POST /api/notes  -> publish to the durable stream, return 201 only after the
//                     broker confirms. Does NOT require the worker to be up.

import { randomUUID } from "node:crypto";
import { NextResponse } from "next/server";
import { publishNote } from "@/lib/publisher";
import { readNotes } from "@/lib/store";
import type { Note } from "@/lib/config";

// This route touches a live socket + the filesystem; it must never be
// statically optimized or cached.
export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export async function GET(): Promise<NextResponse> {
  const notes = await readNotes();
  return NextResponse.json(notes, { status: 200 });
}

export async function POST(request: Request): Promise<NextResponse> {
  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return NextResponse.json({ error: "invalid JSON body" }, { status: 400 });
  }

  const { title, body } = (payload ?? {}) as { title?: unknown; body?: unknown };
  if (typeof title !== "string" || typeof body !== "string") {
    return NextResponse.json(
      { error: "title and body are required strings" },
      { status: 400 },
    );
  }

  const note: Note = {
    id: randomUUID(),
    title,
    body,
    createdAt: new Date().toISOString(),
  };

  try {
    // Resolves ONLY after the broker confirms the write is durable in the
    // stream. If this throws we must not return 201.
    await publishNote(note);
  } catch (e) {
    return NextResponse.json(
      { error: `failed to publish note: ${(e as Error).message}` },
      { status: 503 },
    );
  }

  return NextResponse.json({ id: note.id }, { status: 201 });
}
