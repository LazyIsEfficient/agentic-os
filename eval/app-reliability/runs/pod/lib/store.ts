import fs from "fs";
import path from "path";
import type { Note } from "./types";

/**
 * On-disk, append-only, idempotent (dedupe-by-id) note store under ./data/.
 *
 * Format: notes.jsonl — one JSON Note object per line, append-only.
 * Dedupe-by-id is the load-bearing safety net: persisting the same id twice
 * is a no-op, so a replayed stream message (after an offset commit lagged and
 * a redelivery happens) can never produce a duplicate in GET.
 *
 * The offset is persisted SEPARATELY in offset.json. Ordering guarantee:
 * the worker persists the note FIRST, then advances the offset. A crash in
 * between can at worst REPLAY the last message on the next boot — and the
 * dedupe absorbs it. It can never ACK-then-lose.
 */
const DATA_DIR = path.join(process.cwd(), "data");
const NOTES_FILE = path.join(DATA_DIR, "notes.jsonl");
const OFFSET_FILE = path.join(DATA_DIR, "offset.json");

function ensureDir(): void {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

/** Read all persisted notes, deduped by id (last write per id wins). */
export function readNotes(): Note[] {
  ensureDir();
  if (!fs.existsSync(NOTES_FILE)) return [];
  const raw = fs.readFileSync(NOTES_FILE, "utf8");
  const byId = new Map<string, Note>();
  for (const line of raw.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed) continue;
    try {
      const note = JSON.parse(trimmed) as Note;
      if (note && typeof note.id === "string") byId.set(note.id, note);
    } catch {
      // Skip a torn/partial trailing line (crash mid-append); the message is
      // still in the durable stream and will be re-delivered and re-persisted.
    }
  }
  return [...byId.values()].sort((a, b) =>
    a.createdAt < b.createdAt ? -1 : a.createdAt > b.createdAt ? 1 : 0
  );
}

function readIds(): Set<string> {
  return new Set(readNotes().map((n) => n.id));
}

/**
 * Persist a note idempotently. Returns true if newly written, false if the id
 * already existed (no-op). Append + fsync so the write survives a hard kill.
 */
export function persistNote(note: Note): boolean {
  ensureDir();
  if (readIds().has(note.id)) return false;
  const fd = fs.openSync(NOTES_FILE, "a");
  try {
    fs.writeSync(fd, JSON.stringify(note) + "\n");
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  return true;
}

/** Last stream offset that has been fully persisted, or null if none yet. */
export function readOffset(): bigint | null {
  ensureDir();
  if (!fs.existsSync(OFFSET_FILE)) return null;
  try {
    const { offset } = JSON.parse(fs.readFileSync(OFFSET_FILE, "utf8"));
    if (typeof offset === "string" && offset.length > 0) return BigInt(offset);
  } catch {
    return null;
  }
  return null;
}

/** Persist the offset durably AFTER the corresponding note is on disk. */
export function writeOffset(offset: bigint): void {
  ensureDir();
  const tmp = OFFSET_FILE + ".tmp";
  const fd = fs.openSync(tmp, "w");
  try {
    fs.writeSync(fd, JSON.stringify({ offset: offset.toString() }));
    fs.fsyncSync(fd);
  } finally {
    fs.closeSync(fd);
  }
  fs.renameSync(tmp, OFFSET_FILE);
}
