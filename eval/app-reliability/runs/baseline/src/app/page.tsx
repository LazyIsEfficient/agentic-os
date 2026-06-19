// Minimal server-rendered UI that lists the persisted notes and lets you add
// one. The list reflects what the worker has consumed and stored on disk.
import { readNotes } from "@/lib/store";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const notes = await readNotes();

  return (
    <main style={{ maxWidth: 640, margin: "2rem auto", fontFamily: "system-ui" }}>
      <h1>Notes</h1>
      <form method="post" action="/api/notes" style={{ display: "grid", gap: 8, marginBottom: 24 }}>
        <input name="title" placeholder="Title" required />
        <textarea name="body" placeholder="Body" required />
        <button type="submit">Add note</button>
      </form>
      <ul>
        {notes.map((n) => (
          <li key={n.id}>
            <strong>{n.title}</strong> — {n.body}{" "}
            <small>({new Date(n.createdAt).toLocaleString()})</small>
          </li>
        ))}
        {notes.length === 0 && <li>No notes persisted yet.</li>}
      </ul>
    </main>
  );
}
