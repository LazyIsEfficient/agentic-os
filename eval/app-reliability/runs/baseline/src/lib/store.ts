// On-disk note store. The worker WRITES it; the API READS it. Persistence must
// survive a worker restart, so everything lives under ./data/ on disk.
//
// Layout:
//   ./data/notes.json  — JSON array of persisted notes (deduped by id)
//   ./data/offset      — last committed stream offset (the NEXT offset to read)
//
// Writes are atomic (write temp + rename) so a crash mid-write never corrupts
// the file. Dedupe-by-id makes the worker idempotent: replaying a message that
// was already persisted is a no-op, so "no duplicates" holds even if the
// offset commit lagged the note write on the previous run.

import { promises as fs } from "node:fs";
import path from "node:path";
import type { Note } from "./config";

const DATA_DIR = path.resolve(process.cwd(), "data");
const NOTES_FILE = path.join(DATA_DIR, "notes.json");
const OFFSET_FILE = path.join(DATA_DIR, "offset");

async function ensureDir(): Promise<void> {
  await fs.mkdir(DATA_DIR, { recursive: true });
}

async function atomicWrite(file: string, data: string): Promise<void> {
  const tmp = `${file}.${process.pid}.${Date.now()}.tmp`;
  await fs.writeFile(tmp, data, "utf8");
  await fs.rename(tmp, file);
}

export async function readNotes(): Promise<Note[]> {
  try {
    const raw = await fs.readFile(NOTES_FILE, "utf8");
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? (parsed as Note[]) : [];
  } catch (e) {
    if ((e as NodeJS.ErrnoException).code === "ENOENT") return [];
    throw e;
  }
}

export async function writeNotes(notes: Note[]): Promise<void> {
  await ensureDir();
  await atomicWrite(NOTES_FILE, JSON.stringify(notes, null, 2));
}

// Read the last committed stream offset (the next offset the worker should
// consume from). Returns undefined when no offset has ever been committed.
export async function readOffset(): Promise<bigint | undefined> {
  try {
    const raw = (await fs.readFile(OFFSET_FILE, "utf8")).trim();
    if (!raw) return undefined;
    return BigInt(raw);
  } catch (e) {
    if ((e as NodeJS.ErrnoException).code === "ENOENT") return undefined;
    throw e;
  }
}

export async function writeOffset(next: bigint): Promise<void> {
  await ensureDir();
  await atomicWrite(OFFSET_FILE, next.toString());
}
