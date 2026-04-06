---
name: typescript-data-engineering
description: This skill provides data engineering rules for microservices with PostgreSQL, Google BigQuery, event sourcing, ETL pipelines, and data warehousing patterns. Automatically loaded when writing data pipelines, ETL jobs, event processors, database migrations, BigQuery queries, or when "data engineering", "ETL", "pipeline", "data warehouse", "BigQuery", "event sourcing", "indexer", or "data migration" are mentioned.
---

# Data Engineering Rules (TypeScript)

## Architecture Overview

The platform uses a microservices architecture with:

- **PostgreSQL 17** as the primary OLTP database (via Prisma and Drizzle ORMs)
- **Google BigQuery** as the data warehouse for analytics, reporting, and long-term storage
- **Redis 7.x** for pub/sub messaging and job queues
- **Event sourcing** with inbox/outbox pattern for reliable cross-service communication
- **Scheduled cron jobs** for recurring ETL and data distribution tasks

### Service Boundaries

| Service | Purpose | Port | Database Access |
|---|---|---|---|
| `evm-indexer` | Blockchain event ingestion pipeline | 3000 | Shared PostgreSQL (writes events, allocations) |
| `points-service` | Scheduled points distribution + quest resets | 3001 | Shared PostgreSQL (reads/writes points, activities) |
| `platform-app` | Next.js web frontend + API routes | 3000 | Shared PostgreSQL (reads all, writes user data) |
| `ygg-redeem` API | Token redemption platform | 4000 | Separate PostgreSQL (Drizzle migrations) |

Services share a PostgreSQL database via `@repo/prisma` but are decoupled through the event sourcing inbox/outbox pattern.

## ORMs and Database Access

### Prisma (Primary)

Used in platform-monorepo with a modular schema split across 17 files in `packages/prisma/schema/`:

```
packages/prisma/schema/
├── user.prisma
├── activity.prisma
├── point-transaction.prisma
├── token.prisma
├── allocation.prisma
├── indexer-infra.prisma      ← Event sourcing tables
├── action.prisma
├── boost.prisma
├── staking.prisma
├── announcement.prisma
├── claim.prisma
├── group.prisma
└── ...
```

Import the shared client:

```typescript
import { prisma } from '@repo/prisma'
```

### Drizzle ORM (Secondary)

Used in `ygg-redeem` and event sourcing POCs for services with independent schemas:

```typescript
import { pgTable, uuid, varchar, jsonb, bigserial, timestamp } from 'drizzle-orm/pg-core'

export const events = pgTable('events', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  idempotencyKey: varchar('idempotency_key', { length: 255 }).notNull().unique(),
  routingKey: varchar('routing_key', { length: 255 }).notNull(),
  source: varchar('source', { length: 255 }).notNull(),
  payload: jsonb('payload').notNull(),
  correlationId: uuid('correlation_id'),
  createdAt: timestamp('created_at').defaultNow().notNull(),
})
```

### When to Use Each

| ORM | Use When |
|---|---|
| **Prisma** | Shared platform data models, type-safe queries, relation traversal |
| **Drizzle** | Independent service schemas, event stores, migration-heavy workflows, raw SQL needs |

## Event Sourcing Infrastructure

The platform implements event sourcing with inbox/outbox for exactly-once processing. These models live in `indexer-infra.prisma`.

### Core Tables

```
InfraIngestEvent     — Immutable event log (source of truth)
  eventId            — Composite: chain:block:tx:logIndex
  blockNumber, blockHash, address, topic0
  partitionKey       — Hash of chainId:address
  payload            — Raw event data (JSON)

InfraIngestOutbox    — Exactly-once publishing
  eventId            — FK to IngestEvent
  publishedAt        — NULL = pending delivery

InfraInbox           — Per-handler event processing
  eventId, handlerKind (e.g. "AllocationProjector")
  status             — PENDING → ACK | FAIL | DLQ
  attempts, lastError, blockNumber, partitionKey

InfraCursor          — Resumable consumer offsets
  id                 — e.g. "allocation:shard-0"
  lastProcessedBlock

ProcessedEvent       — Deduplication table
  eventId, handlerKind, blockNumber, processedAt

HandlerRegistry      — Operational visibility
  handlerKind, eventTypes[], isActive, lastSeen, version

ReplayJob            — Operational recovery
  handlerKind, fromBlock, toBlock
  status             — PENDING → RUNNING → COMPLETED | FAILED | CANCELLED
  eventsTotal, eventsProcessed, eventsFailed
```

### Event Flow

```
Blockchain → Block Watcher (5s poll)
  → InfraIngestEvent (immutable log)
  → InfraIngestOutbox (pending publish)
  → InfraInbox (per handler: AllocationProjector, StakingProjector, etc.)
  → Domain Projectors (apply business logic)
  → DomainOutbox (commands: MintV1, SetMerkleRootV1, etc.)
```

### Outbox Pattern Rules

- Every event write must also write an outbox row in the **same transaction**
- Publishers poll outbox for `publishedAt IS NULL`, deliver, then mark published
- Inbox handlers must be **idempotent** — use `ProcessedEvent` for deduplication
- Each handler processes events **in partition order** by `blockNumber`
- Failed handlers go to DLQ after max attempts — never block the pipeline

### Domain Commands (CQRS)

```
DomainOutbox
  commandKey          — Deterministic key for idempotency
  kind                — MintV1, SetMerkleRootV1, etc.
  payload             — Command parameters (JSON)
  publishedAt, txHash — Execution tracking
```

## ETL Pipeline Patterns

### EVM Indexer Pipeline

The primary data pipeline ingests blockchain events:

```typescript
// Pseudostructure of the indexer pipeline
class BlockWatcher {
  pollInterval = 5_000 // 5 seconds
  startBlock = 1_000_000 // configurable

  async poll() {
    const logs = await provider.getLogs({ fromBlock, toBlock })
    await this.ingest(logs)
  }

  async ingest(logs: Log[]) {
    // Single transaction: event + outbox
    await prisma.$transaction(async (tx) => {
      for (const log of logs) {
        const event = await tx.infraIngestEvent.create({
          data: {
            eventId: `${log.chainId}:${log.blockNumber}:${log.transactionIndex}:${log.logIndex}`,
            blockNumber: log.blockNumber,
            partitionKey: hashPartition(log.chainId, log.address),
            payload: log,
          },
        })
        await tx.infraIngestOutbox.create({
          data: { eventId: event.eventId },
        })
      }
    })
  }
}
```

### Points Distribution (Scheduled ETL)

Runs on a cron schedule (5m dev, 24h prod):

```typescript
// Daily job: finalize pending point transactions
async function awardPointsInProgress() {
  await prisma.pointTransaction.updateMany({
    where: { status: 'in_progress' },
    data: { status: 'completed', distributedAt: new Date() },
  })
}

// Daily/Weekly job: reset recurring quest progress
async function resetActivities(frequency: 'daily' | 'weekly') {
  await prisma.userActivity.updateMany({
    where: {
      activity: { frequency },
      state: { not: 'in_progress' },
    },
    data: { state: 'in_progress' },
  })
}
```

### Merkle Tree Generation

Processes allocation data and publishes to GCS:

```
Input:  Allocation records (address, points, ygg, tokensCommitted)
Rules:  1% per-wallet cap with proportional redistribution
Output: Merkle root + per-wallet proofs (JSON → GCS bucket)
```

Buckets: `ygg_play_merkle_bucket` (staging), `ygg_play_merkle_bucket_prod` (production)

## Google BigQuery Integration

BigQuery serves as the analytics data warehouse. Use `@google-cloud/bigquery` for programmatic access.

### Connection Pattern

```typescript
import { BigQuery } from '@google-cloud/bigquery'

const bigquery = new BigQuery({
  projectId: process.env.GCP_PROJECT_ID,
})
```

### ETL to BigQuery

Move data from PostgreSQL to BigQuery for analytics workloads:

```typescript
// Extract from PostgreSQL
const transactions = await prisma.pointTransaction.findMany({
  where: { distributedAt: { gte: lastSyncTimestamp } },
  include: { user: true, activity: true },
})

// Transform to BigQuery schema
const rows = transactions.map((tx) => ({
  transaction_id: tx.id,
  user_id: tx.userId,
  point_amount: tx.pointAmount,
  transaction_type: tx.transactionType,
  activity_slug: tx.activity?.slug,
  distributed_at: tx.distributedAt?.toISOString(),
}))

// Load to BigQuery
await bigquery.dataset('platform').table('point_transactions').insert(rows)
```

### BigQuery Schema Design Principles

- **Partitioned tables**: Partition by `distributed_at` or `created_at` for time-series data
- **Clustered columns**: Cluster by `user_id`, `transaction_type` for common query patterns
- **Denormalized models**: Flatten joins at ETL time — BigQuery prefers wide tables over joins
- **Append-only**: Treat BigQuery tables as immutable — insert new rows, don't update
- **Streaming vs batch**: Use streaming inserts for real-time, batch loads for bulk historical data

### Common Warehouse Tables

| BigQuery Table | Source | Grain | Partition |
|---|---|---|---|
| `point_transactions` | `PointTransaction` | One row per transaction | `distributed_at` |
| `user_activities` | `UserActivity` | One row per enrollment | `enrolled_at` |
| `allocation_events` | `InfraIngestEvent` | One row per blockchain event | `created_at` |
| `user_commitments` | `UserCommitment` | One row per commit action | `timestamp` |
| `token_launches` | `Token` | One row per token | `created_at` |

## Data Validation

### Zod (Primary)

Use Zod for all runtime validation at service boundaries:

```typescript
import { z } from 'zod'

const EventPayloadSchema = z.object({
  eventId: z.string(),
  blockNumber: z.number().int().positive(),
  address: z.string().regex(/^0x[a-fA-F0-9]{40}$/),
  payload: z.record(z.unknown()),
})

type EventPayload = z.infer<typeof EventPayloadSchema>

// Validate at ingestion boundary
const validated = EventPayloadSchema.parse(rawEvent)
```

### Validation Rules

- Validate **at service boundaries** — not between internal modules
- Use Zod for API inputs, event payloads, config files, and ETL row schemas
- Use Prisma types for database query results (already type-safe)
- Fail fast on invalid data — do not silently coerce or drop fields

## Cron and Scheduling

### Cron Configuration

Jobs are configured in `settings.json` with environment-specific intervals:

```json
{
  "scheduleWindow": "5m",
  "dailyReset": { "dev": "5m", "prod": "24h" },
  "weeklyReset": { "dev": "6m", "prod": "7d" },
  "blockPollInterval": 5000,
  "dbPollInterval": 120000
}
```

### Persistent Cron Manager

- Tracks job execution state in the database for crash recovery
- On service restart, resumes from last known state
- Health endpoint: `GET /api/status`
- Manual trigger: `POST /api/distribution/trigger`

### Cron Job Rules

- Every cron job must be **idempotent** — safe to re-run if interrupted
- Log start/end timestamps and row counts for observability
- Use database-level locking or a lease mechanism to prevent concurrent runs
- Keep job duration well under the schedule interval

## Database Migration Rules

### Prisma Migrations

```bash
# Generate migration from schema changes
npx prisma migrate dev --name descriptive_migration_name

# Apply migrations in CI/production (Cloud Build)
npx prisma migrate deploy
```

Cloud Build config: `packages/prisma/cloudbuild.migrate.yaml`

### Drizzle Migrations

```bash
# Generate migration
npx drizzle-kit generate

# Apply migration
npx drizzle-kit migrate
```

### Migration Rules

- **Never** modify a deployed migration — create a new one
- Migrations must be backwards-compatible: add columns as nullable, backfill, then add constraints
- Name migrations descriptively: `add_user_wallet_address`, `create_point_categories_table`
- Test migrations against a copy of production data before deploying
- Include both `up` and `down` logic where possible

## Infrastructure

### Local Development

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:17
  redis:
    image: redis:7.2
    # password-protected
```

### Cloud (GCP + AWS)

- **GCP**: Google Cloud Storage (merkle buckets), BigQuery (warehouse)
- **AWS**: Secrets Manager (via Pulumi), infrastructure provisioning
- **Cloudflare**: DNS/CDN
- **IaC**: Pulumi (TypeScript) in `pulumi-ygg-play/`
- **CI/CD**: CircleCI, Google Cloud Build for migrations

### Monorepo Structure

```
platform-monorepo/
├── apps/
│   └── platform-app/       ← Next.js frontend + API routes
├── services/
│   ├── evm-indexer/         ← Blockchain data pipeline
│   └── points-service/      ← Scheduled points distribution
└── packages/
    ├── prisma/              ← Shared database client + schema
    ├── config/              ← Shared configuration
    └── typescript-config/   ← Shared tsconfig
```

Build orchestration: **Turbo** (v2.4.4+) with **pnpm** (v10.2.0+) workspaces.

## Key Data Models

### Points Ledger

```
PointTransaction {
  pointAmount, transactionType (CREDIT | DEBIT),
  status (in_progress | completed),
  distributedAt,
  userId → User,
  activityId → Activity (nullable),
  tokenId → Token (nullable),
  boostId → Boost (nullable)
}
```

### Allocation State Machine

```
NULL → COMMITTING → CLAIMABLE → REFUNDED

UserCommitment   — Records each wallet's committed amount + points
UserClaimRefund  — Records claim or refund events (eventType: Claimed | Refunded)
AllocationPool   — Uniswap V3 pool parameters (sqrtPriceX96, ticks, liquidity)
```

### Activity / Quest System

```
Activity {
  slug, frequency (oneTime | unlimited | daily | weekly),
  rewards (points), published, featured,
  tasks[] (ActivityTask: internalAction | gameAction | enrollAction)
}

UserActivity {
  state (in_progress | completed | rewarded),
  enrolledAt, completedAt
}
```

## Pipeline Design Principles

1. **Idempotency everywhere** — every pipeline step must be safe to re-run
2. **Single source of truth** — `InfraIngestEvent` is the immutable event log; downstream tables are projections
3. **Partition by time** — both PostgreSQL indexes and BigQuery tables should partition on timestamps
4. **Fail loudly** — invalid data goes to DLQ, not silently dropped
5. **Exactly-once semantics** — use outbox + deduplication, not "at-most-once" or "hope for the best"
6. **Denormalize for analytics** — flatten at ETL time for BigQuery; normalize for PostgreSQL
7. **Backfill-ready** — every projection must support replay from the event log via `ReplayJob`
8. **Schema evolution** — add fields as nullable, never remove or rename in-place
