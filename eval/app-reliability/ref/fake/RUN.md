# Fake reference app — plausible-but-NOT-fault-tolerant

This app conforms to [`../../SPEC.md`](../../SPEC.md)'s run interface (same API,
same `npm run worker` / `npm start` scripts, even imports
`rabbitmq-stream-js-client` and declares a stream) and **looks** fault-tolerant.
It is not. It exists to validate that the deterministic battery actually
discriminates: a correct app must PASS chaos, this one must FAIL it.

## The durability bug (by design)

`POST /api/notes` acks the client with `201` **before** the note is durably
committed. The real write path is a *transient* hand-off: the web process
forwards each note to the worker's local HTTP ingest listener
(`src/lib/worker-channel.ts` → `worker/index.ts`). While the worker is up this
works perfectly, so:

- **build** passes (`npm ci && npm run build`).
- **contract** passes (POST a note, worker persists it, GET returns it).

But when the **worker is down**, the forward fails, the note is dropped, and
`POST` still returns `201`. Those notes are never buffered anywhere durable, so
they never appear in `GET` after the worker restarts:

- **chaos** FAILS — the 10 notes posted while the worker was down are lost
  (battery reports `persisted=10/20 ... missing=10`).

The stream publisher/consumer wired up in `src/lib/stream.ts` and
`worker/index.ts` is decorative: it connects and tracks an offset (so static
completeness checks see a stream + offset), but the POST path never uses it as
the durable buffer. This mirrors the #1 real-world mistake: **acking before the
write is durably committed.**

## Run

Same as the correct app — the harness provides RabbitMQ. See
[`../correct/RUN.md`](../correct/RUN.md) for the exact broker command.

```bash
npm ci && npm run build
npm run worker      # transient ingest listener + decorative stream consumer
npm start           # Next on :3000
```
