# Fault-Tolerant Notes

Note-taking app whose write path is durable via a **RabbitMQ Stream**. A POST
publishes to the stream and returns `201` only after a publisher confirm; a
separate worker consumes from its last committed offset and persists notes
idempotently. Acknowledged writes survive a worker (or broker) blip.

## Run

```bash
npm ci
npm run build

# terminal 1 — the durable consumer
npm run worker

# terminal 2 — the web app (port 3000, override with PORT)
npm start
```

## Environment

| Var | Default |
| --- | --- |
| `RABBITMQ_STREAM_HOST` | `localhost` |
| `RABBITMQ_STREAM_PORT` | `5552` |
| `RABBITMQ_USER` | `guest` |
| `RABBITMQ_PASS` | `guest` |
| `RABBITMQ_VHOST` | `/` |
| `RABBITMQ_STREAM_NAME` | `notes` |

## API

- `GET /api/notes` → `200` `[{ id, title, body, createdAt }]` — the persisted
  notes read from `./data/` (what the worker stored).
- `POST /api/notes` `{ title, body }` → `201 { id }` — publishes to the durable
  stream with a publisher confirm; does **not** require the worker to be up.

## Fault tolerance

1. **Durable POST without the worker.** The route declares a real stream and
   awaits the broker's `publish_confirm` before returning 201. It imports
   nothing from the worker, so a POST while the worker is down still succeeds.
2. **Worker resumes from its committed offset.** On boot it reads the last
   persisted offset from `./data/offset.json` and subscribes from `offset + 1`
   (or `first()` on the very first boot) — never replaying from 0.
3. **Idempotent dedupe-by-id.** The store keys by note id; a replayed message
   is a no-op. Net invariant: every acknowledged note appears in GET exactly
   once across worker stop/start.
