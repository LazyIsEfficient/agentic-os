import fs from "node:fs"
import fsp from "node:fs/promises"
import path from "node:path"
import { config, type Note } from "./config"

// On-disk JSON store. The worker writes it; the API reads it. Notes survive a
// worker restart because they live on disk, not in process memory.
//
// File shape: { offset: string | null, notes: Note[] }
//   - offset: the last committed stream offset persisted alongside the notes, so a
//     reader can see how far the worker has progressed. The authoritative offset for
//     resume lives server-side (storeOffset), this is a local mirror for debugging.
//   - notes: appended in consume order; dedupe is by note id.

type StoreShape = {
  offset: string | null
  notes: Note[]
}

const filePath = path.join(config.dataDir, "notes.json")
const tmpPath = `${filePath}.tmp`

function ensureDir(): void {
  fs.mkdirSync(config.dataDir, { recursive: true })
}

export function readStore(): StoreShape {
  ensureDir()
  if (!fs.existsSync(filePath)) {
    return { offset: null, notes: [] }
  }
  try {
    const raw = fs.readFileSync(filePath, "utf8")
    if (!raw.trim()) return { offset: null, notes: [] }
    const parsed = JSON.parse(raw) as StoreShape
    return {
      offset: parsed.offset ?? null,
      notes: Array.isArray(parsed.notes) ? parsed.notes : [],
    }
  } catch {
    // Corrupt/partial file: treat as empty rather than crash the reader.
    return { offset: null, notes: [] }
  }
}

export function readNotes(): Note[] {
  return readStore().notes
}

// Atomic write: write to a temp file then rename, so a crash mid-write never leaves a
// half-written notes.json that loses already-persisted notes.
async function writeStore(store: StoreShape): Promise<void> {
  ensureDir()
  await fsp.writeFile(tmpPath, JSON.stringify(store, null, 2), "utf8")
  await fsp.rename(tmpPath, filePath)
}

// Persist a note idempotently (dedupe by id) and record the committed offset.
// Returns true if the note was newly added, false if it was a duplicate.
export async function persistNote(note: Note, offset: bigint): Promise<boolean> {
  const store = readStore()
  const exists = store.notes.some((n) => n.id === note.id)
  if (!exists) {
    store.notes.push(note)
  }
  store.offset = offset.toString()
  await writeStore(store)
  return !exists
}
