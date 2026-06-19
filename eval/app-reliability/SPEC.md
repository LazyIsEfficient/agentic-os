# App-reliability experiment — shared contract

Measures whether the library's multi-agent review pod produces a **more complete and
actually-fault-tolerant** app than a single-pass baseline, on a real distributed task,
scored by a **deterministic battery** (build + contract test + chaos test + completeness),
never a judge.

## The deliverable both arms build

A note-taking app whose API is fault-tolerant via a **RabbitMQ Stream**: every note mutation
is published to a durable stream and returns success only after a publisher confirm; a
separate consumer ("worker") reads the stream from its last committed offset and persists
notes idempotently. If the worker (or broker) blips, **acknowledged writes are not lost** —
they sit in the durable stream and are persisted on recovery, exactly once.

## Run interface the harness depends on (CONTRACT — every app must conform)

- Node project at the project root. `npm ci` then `npm run build` must succeed.
- **RabbitMQ is provided by the harness** in Docker (stream plugin, port 5552). The app reads
  connection from env: `RABBITMQ_STREAM_HOST` (default `localhost`), `RABBITMQ_STREAM_PORT`
  (default `5552`), `RABBITMQ_USER`/`RABBITMQ_PASS` (default `guest`/`guest`),
  `RABBITMQ_STREAM_NAME` (default `notes`).
- `npm run worker` — starts the long-running consumer (persists notes; tracks/commits offset).
- `npm start` — starts the Next.js app on port `3000` (override via `PORT`).
- Persistence path is a directory the worker writes to; readable via the API. Persistence must
  survive a worker restart (file/sqlite under `./data/`, not in-memory-only).
- Use the official `rabbitmq-stream-js-client` for the stream (NOT amqplib classic queues).

## API contract

- `GET /api/notes` → `200` JSON array `[{ id, title, body, createdAt }]` (the PERSISTED notes,
  i.e. what the worker has consumed and stored).
- `POST /api/notes` body `{ title, body }` → `201 { id }`. MUST publish to the durable stream
  with a publisher confirm and return only after the broker confirms the write. It must NOT
  depend on the worker being up — a POST while the worker is stopped still returns `201`.
- (PUT/DELETE optional for the first cut; create+list is the load-bearing fault path.)

## Fault-tolerance requirement (what the chaos test asserts)

1. POST N notes (worker up) → all `201`.
2. STOP the worker. POST M more notes → all still `201` (durable stream accepts them).
3. START the worker. Within a convergence timeout, `GET /api/notes` returns ALL N+M notes,
   each exactly once (idempotent; no loss, no duplication; offset resumed, not replayed-from-0
   into duplicates).
4. (Stretch) restart the broker container between 2 and 3 — a stream is disk-durable, so the
   M notes still survive.

A "fake" app that writes synchronously to the store (no durable stream buffering), or uses a
classic non-durable queue, LOSES the M notes posted while the worker is down → fails step 3.

## Deterministic battery (harness-owned, scores every produced app)

- **build**: `npm ci && npm run build` exit 0.
- **contract**: worker+web up; POST a note; GET returns it.
- **chaos**: the N/stop/M/start/converge scenario above; PASS iff all N+M persisted exactly once.
- **completeness checklist** (grep/AST + behavioral): uses `rabbitmq-stream-js-client`; declares
  a STREAM (not a classic queue); worker tracks/stores an offset; POST awaits publisher confirm;
  persistence is on-disk; `npm run worker` + `npm start` scripts exist.

Score = checks passed. The chaos check is the headline; a real fault-tolerant app passes it,
a plausible-but-fake one fails it.
