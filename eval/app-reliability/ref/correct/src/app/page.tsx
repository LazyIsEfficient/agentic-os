"use client"

import { useEffect, useState } from "react"

type Note = { id: string; title: string; body: string; createdAt: string }

export default function Home() {
  const [notes, setNotes] = useState<Note[]>([])
  const [title, setTitle] = useState("")
  const [body, setBody] = useState("")
  const [status, setStatus] = useState<string>("")

  async function load() {
    const res = await fetch("/api/notes", { cache: "no-store" })
    setNotes(await res.json())
  }

  useEffect(() => {
    load()
    const t = setInterval(load, 2000)
    return () => clearInterval(t)
  }, [])

  async function submit(e: React.FormEvent) {
    e.preventDefault()
    setStatus("publishing...")
    const res = await fetch("/api/notes", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({ title, body }),
    })
    if (res.status === 201) {
      setStatus("published (durably confirmed)")
      setTitle("")
      setBody("")
    } else {
      setStatus(`error: ${res.status}`)
    }
  }

  return (
    <main>
      <h1>Notes</h1>
      <p style={{ color: "#666" }}>
        Each note is published to a durable RabbitMQ stream with a publisher confirm,
        then persisted by the worker. Writes survive a worker outage.
      </p>
      <form onSubmit={submit} style={{ display: "grid", gap: 8, marginBottom: 24 }}>
        <input
          placeholder="title"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          required
        />
        <textarea
          placeholder="body"
          value={body}
          onChange={(e) => setBody(e.target.value)}
          required
        />
        <button type="submit">Add note</button>
        <span style={{ color: "#666", fontSize: 14 }}>{status}</span>
      </form>
      <h2>Persisted notes ({notes.length})</h2>
      <ul>
        {notes.map((n) => (
          <li key={n.id}>
            <strong>{n.title}</strong> — {n.body}{" "}
            <small style={{ color: "#999" }}>{n.createdAt}</small>
          </li>
        ))}
      </ul>
    </main>
  )
}
