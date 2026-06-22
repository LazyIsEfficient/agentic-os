"use client";

import { useEffect, useState } from "react";

interface Note {
  id: string;
  title: string;
  body: string;
  createdAt: string;
}

export default function Home() {
  const [notes, setNotes] = useState<Note[]>([]);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [status, setStatus] = useState("");

  async function load() {
    const res = await fetch("/api/notes", { cache: "no-store" });
    if (res.ok) setNotes(await res.json());
  }

  useEffect(() => {
    load();
    const t = setInterval(load, 2000);
    return () => clearInterval(t);
  }, []);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setStatus("publishing…");
    const res = await fetch("/api/notes", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ title, body }),
    });
    if (res.status === 201) {
      setTitle("");
      setBody("");
      setStatus("published (durable)");
      load();
    } else {
      setStatus("error: " + res.status);
    }
  }

  return (
    <main style={{ maxWidth: 640, margin: "2rem auto", padding: "0 1rem" }}>
      <h1>Notes</h1>
      <form onSubmit={submit} style={{ display: "grid", gap: 8, marginBottom: 24 }}>
        <input
          placeholder="Title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
        />
        <textarea
          placeholder="Body"
          value={body}
          onChange={(e) => setBody(e.target.value)}
          rows={3}
        />
        <button type="submit">Add note</button>
        <small>{status}</small>
      </form>
      <ul style={{ listStyle: "none", padding: 0 }}>
        {notes.map((n) => (
          <li
            key={n.id}
            style={{ border: "1px solid #ddd", borderRadius: 6, padding: 12, marginBottom: 8 }}
          >
            <strong>{n.title || "(untitled)"}</strong>
            <p style={{ margin: "4px 0" }}>{n.body}</p>
            <small style={{ color: "#888" }}>{n.createdAt}</small>
          </li>
        ))}
      </ul>
    </main>
  );
}
