# Google BigQuery Integration

BigQuery serves as the analytics data warehouse. Use `@google-cloud/bigquery` for programmatic access.

## Connection Pattern

```typescript
import { BigQuery } from '@google-cloud/bigquery'

const bigquery = new BigQuery({
  projectId: process.env.GCP_PROJECT_ID,
})
```

## ETL to BigQuery

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

## BigQuery Schema Design Principles

- **Partitioned tables**: Partition by `distributed_at` or `created_at` for time-series data
- **Clustered columns**: Cluster by `user_id`, `transaction_type` for common query patterns
- **Denormalized models**: Flatten joins at ETL time — BigQuery prefers wide tables over joins
- **Append-only**: Treat BigQuery tables as immutable — insert new rows, don't update
- **Streaming vs batch**: Use streaming inserts for real-time, batch loads for bulk historical data

## Common Warehouse Tables

| BigQuery Table | Source | Grain | Partition |
|---|---|---|---|
| `point_transactions` | `PointTransaction` | One row per transaction | `distributed_at` |
| `user_activities` | `UserActivity` | One row per enrollment | `enrolled_at` |
| `allocation_events` | `InfraIngestEvent` | One row per blockchain event | `created_at` |
| `user_commitments` | `UserCommitment` | One row per commit action | `timestamp` |
| `token_launches` | `Token` | One row per token | `created_at` |
