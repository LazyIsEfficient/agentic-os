# GCP Patterns

## Google Cloud Storage

Used for merkle tree and token list publishing:

```typescript
import * as gcp from '@pulumi/gcp'

const bucket = new gcp.storage.Bucket('merkle-bucket', {
  name: isProduction ? 'app_merkle_bucket_prod' : 'app_merkle_bucket',
  location: 'US',
  uniformBucketLevelAccess: true,
  versioning: { enabled: true },
  labels: { project: 'platform', environment: environment },
})
```

## BigQuery Dataset

```typescript
const dataset = new gcp.bigquery.Dataset('platform-analytics', {
  datasetId: 'platform',
  location: 'US',
  description: 'Platform analytics warehouse',
  labels: { project: 'platform', environment: environment },
})

// Partitioned + clustered table
const pointTransactions = new gcp.bigquery.Table('point-transactions', {
  datasetId: dataset.datasetId,
  tableId: 'point_transactions',
  timePartitioning: {
    type: 'DAY',
    field: 'distributed_at',
  },
  clustering: ['user_id', 'transaction_type'],
  schema: JSON.stringify([
    { name: 'transaction_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'user_id', type: 'STRING', mode: 'REQUIRED' },
    { name: 'point_amount', type: 'INTEGER', mode: 'REQUIRED' },
    { name: 'transaction_type', type: 'STRING', mode: 'REQUIRED' },
    { name: 'activity_slug', type: 'STRING', mode: 'NULLABLE' },
    { name: 'distributed_at', type: 'TIMESTAMP', mode: 'REQUIRED' },
  ]),
  labels: { project: 'platform' },
})
```

## Cloud Build (Database Migrations)

Prisma migrations run via Cloud Build:

```yaml
# packages/prisma/cloudbuild.migrate.yaml
steps:
  - name: 'node:22'
    entrypoint: 'npx'
    args: ['prisma', 'migrate', 'deploy']
    env:
      - 'DATABASE_URL=$_DATABASE_URL'
```

**Rules**:
- Always enable bucket versioning for data assets
- Use `uniformBucketLevelAccess` on GCS buckets
- Partition BigQuery tables by timestamp columns
- Cluster by high-cardinality query columns (user_id, etc.)
