---
name: typescript-data-engineering
description: Use when building data pipelines, ETL jobs, event processors, database migrations, BigQuery queries, or event-sourcing handlers in the YGG platform. Triggers on edits to evm-indexer/**, points-service/**, packages/prisma/**, drizzle migrations, BigQuery integration code, or mentions of "data engineering", "ETL", "pipeline", "indexer", "event sourcing", "data warehouse", or "data migration".
---

# Data Engineering (TypeScript)

The YGG platform runs a microservices architecture with PostgreSQL 17 (Prisma + Drizzle), Redis 7, Google BigQuery as the analytics warehouse, and an event-sourcing pipeline that ingests blockchain events through an inbox/outbox pattern with exactly-once semantics.

Services share a database via `@repo/prisma` but stay decoupled through events. Cron jobs handle scheduled ETL (points distribution, quest resets) and merkle tree generation publishes to GCS.

## Universal Rules

1. **Idempotency everywhere** — every pipeline step must be safe to re-run.
2. **Single source of truth** — `InfraIngestEvent` is the immutable event log; downstream tables are projections.
3. **Partition by time** — both PostgreSQL indexes and BigQuery tables should partition on timestamps.
4. **Fail loudly** — invalid data goes to DLQ, not silently dropped.
5. **Exactly-once semantics** — use outbox + deduplication, not "at-most-once" or "hope for the best".
6. **Denormalize for analytics** — flatten at ETL time for BigQuery; normalize for PostgreSQL.
7. **Backfill-ready** — every projection must support replay from the event log via `ReplayJob`.
8. **Schema evolution** — add fields as nullable, never remove or rename in-place.
9. **Validate at boundaries** with Zod — not between internal modules.
10. **Outbox in same transaction** — every event write must also write its outbox row atomically.

## References

- [references/architecture.md](references/architecture.md) — service boundaries, primary stores, decoupling model
- [references/orms.md](references/orms.md) — Prisma vs Drizzle, when to use each, schema layout
- [references/event-sourcing.md](references/event-sourcing.md) — InfraIngestEvent/Outbox/Inbox/Cursor tables, event flow, outbox rules, CQRS commands
- [references/etl-pipelines.md](references/etl-pipelines.md) — EVM indexer pipeline, points distribution cron ETL, merkle tree generation
- [references/bigquery.md](references/bigquery.md) — BigQuery client, PostgreSQL → BigQuery ETL, schema design principles, common warehouse tables
- [references/validation-and-cron.md](references/validation-and-cron.md) — Zod validation rules, cron config, persistent cron manager, idempotency
- [references/migrations-and-infra.md](references/migrations-and-infra.md) — Prisma/Drizzle migrations, local Docker, GCP/AWS/Cloudflare/Pulumi, monorepo structure
- [references/data-models.md](references/data-models.md) — points ledger, allocation state machine, activity/quest system
