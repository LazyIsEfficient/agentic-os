# Reference app — RUN & VERIFY

Known-correct, genuinely fault-tolerant notes app. Conforms to
[`../../SPEC.md`](../../SPEC.md). A note is published to a **durable RabbitMQ
stream** with a **publisher confirm**; `POST` returns `201` only after the broker
confirms — independent of whether the worker is up. A separate worker consumes
from its **last committed offset**, persists notes idempotently (dedupe by `id`)
to `./data/notes.json`, and commits the offset. On restart it resumes — no loss,
no duplicates.

## Layout

- `src/app/api/notes/route.ts` — `POST` (publish + confirm → `201 {id}`), `GET` (persisted notes).
- `src/lib/stream.ts` — `ConfirmingPublisher`: one `publish_confirm` listener, dispatch by `publishingId`. Resolves only on broker confirm.
- `src/lib/store.ts` — atomic on-disk JSON store, idempotent `persistNote` (dedupe by `id`).
- `worker/index.ts` — consumer: resume from committed offset, persist, `storeOffset`.

## 1. RabbitMQ in Docker (stream plugin, port 5552)

The classic stream gotcha: the stream client connects to the locator, the broker
then returns metadata with the node's advertised host, and the client reconnects
to *that* host. If the advertised host isn't reachable from where you run, the
consumer/publisher hangs. Fix: advertise `localhost`.

**Exact working commands used:**

```bash
docker run -d --name rmq-ref \
  -p 5552:5552 -p 5672:5672 -p 15672:15672 \
  -e RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS='-rabbitmq_stream advertised_host localhost' \
  rabbitmq:3-management-alpine

# enable the stream plugin (the alpine image ships it but not enabled)
docker exec rmq-ref rabbitmq-plugins enable rabbitmq_stream

# verify the stream listener is live on 5552
docker exec rmq-ref rabbitmq-diagnostics listeners | grep -i stream
#   -> Interface: [::], port: 5552, protocol: stream, purpose: stream
```

Default credentials `guest`/`guest`, vhost `/`. The app reads connection from env
(`RABBITMQ_STREAM_HOST` default `localhost`, `RABBITMQ_STREAM_PORT` default `5552`,
`RABBITMQ_USER`/`RABBITMQ_PASS` default `guest`, `RABBITMQ_STREAM_NAME` default
`notes`). See `.env.example`.

## 2. Build & run

```bash
npm ci
npm run build           # next build — passes (see below)
npm start               # Next on :3000  (override with PORT)
npm run worker          # long-running consumer (separate process)
```

## 3. Chaos verification (the whole point) — actually executed

`npm ci` + `npm run build` exit 0. Build output:

```
 ✓ Compiled successfully
Route (app)                              Size     First Load JS
┌ ○ /                                    923 B          88.1 kB
├ ○ /_not-found                          873 B          88.1 kB
└ ƒ /api/notes                           0 B                0 B   (dynamic — correct)
```

### Step 2 — POST 10 (worker UP) → all 201; GET shows 10

```
POST note-1 -> HTTP 201  {"id":"8fe20a7a-..."}
... (note-2 .. note-9) ...
POST note-10 -> HTTP 201  {"id":"205faff1-..."}
GET  persisted count: 10
```

### Step 3 — KILL the worker, POST 10 MORE → ALL still 201 (the crux)

With the worker process dead, the durable stream still accepts writes; each `POST`
awaits a publisher confirm and returns `201`. GET correctly still shows only 10
(worker not consuming) — the 10 unpersisted notes sit safely in the stream.

```
worker 63805 killed
POST note-11 -> HTTP 201  {"id":"8524fd5d-..."}
... (note-12 .. note-19) ...
POST note-20 -> HTTP 201  {"id":"90e85260-..."}
GET  persisted count (worker down): 10
```

### Step 4 — RESTART worker → converges to ALL 20, each exactly once

The restarted worker resumes from the committed offset (18 → start 19) and
consumes exactly the 10 missed notes (stream offsets 20–29), all `ADDED`, none
`DUP`:

```
[worker] resuming from committed offset 18 -> start 19
[worker] offset 20 note 8524fd5d-... ADDED (processed=1 added=1)
...
[worker] offset 29 note 90e85260-... ADDED (processed=10 added=10)

  t+1s persisted=10
  t+2s persisted=20   <- converged

CHAOS RESULT: PASS — 20/20 exactly once, no loss, no duplicates
  total notes:    20
  unique ids:     20
  duplicate ids:  0
  missing titles: NONE
  duplicate titles: NONE
```

### Extra — second worker restart proves no replay-from-0 duplicates

```
[worker] resuming from committed offset 29 -> start 30
(consumes nothing; count stays 20, unique 20)
on-disk data/notes.json: { offset: "29", notes: 20 }
```

### Step 5 — teardown

```bash
docker rm -f rmq-ref
```

## Why this genuinely survives (not a fake)

- `POST` does **not** write the store directly and does **not** require the worker.
  It publishes to the durable stream and blocks on the broker's publish confirm.
- The stream is created with `max-length-bytes` retention and is **disk-durable**,
  so acknowledged writes survive a worker outage (and a broker restart — streams
  persist to disk).
- The worker tracks its offset **server-side** via `storeOffset` and resumes with
  `Offset.offset(committed + 1)`. It never replays from 0.
- Persistence is **idempotent** (dedupe by note `id`) and writes atomically
  (temp file + rename), so an at-least-once redelivery after a mid-batch crash is
  a no-op → exactly-once effect.

## Input validation

`POST /api/notes` rejects: non-string `title`/`body` → `400`; oversized payloads
(`title > 1000` or `body > 100000` chars) → `413`. Smoke-verified: valid → `201`,
oversized → `413`, missing field → `400`.

## Security note

`npm audit` flags advisories on `next@14.2.35` confined to `next/image`
optimizer, `remotePatterns`, and rewrites — **none of which this app uses** (no
images, no `remotePatterns`, no rewrites). They do not affect the create+list
fault path. Pinned to the latest patched 14.2.x; a Next 15 major bump is out of
scope for a measurement anchor.
