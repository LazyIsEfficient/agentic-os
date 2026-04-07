# ETL Pipeline Patterns

## EVM Indexer Pipeline

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

## Points Distribution (Scheduled ETL)

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

## Merkle Tree Generation

Processes allocation data and publishes to GCS:

```
Input:  Allocation records (address, points, baseToken, tokensCommitted)
Rules:  1% per-wallet cap with proportional redistribution
Output: Merkle root + per-wallet proofs (JSON → GCS bucket)
```

Buckets: `app_merkle_bucket` (staging), `app_merkle_bucket_prod` (production)
