import fs from "node:fs"
import fsp from "node:fs/promises"
import path from "node:path"
import { config, type Note } from "./config"

// On-disk JSON store. The worker writes it; the API reads it. Persistence itself
// is genuinely on-disk and survives a worker restart — the bug is NOT here. The
// bug is that notes posted while the worker is down never *reach* this store,
// because the write path is a transient worker hand-off, not a durable buffer.

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
    return { offset: null, notes: [] }
  }
}

export function readNotes(): Note[] {
  return readStore().notes
}

async function writeStore(store: StoreShape): Promise<void> {
  ensureDir()
  await fsp.writeFile(tmpPath, JSON.stringify(store, null, 2), "utf8")
  await fsp.rename(tmpPath, filePath)
}

export async function persistNote(note: Note): Promise<boolean> {
  const store = readStore()
  const exists = store.notes.some((n) => n.id === note.id)
  if (!exists) {
    store.notes.push(note)
  }
  await writeStore(store)
  return !exists
}
