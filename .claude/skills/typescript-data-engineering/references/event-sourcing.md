# Event Sourcing Infrastructure

The platform implements event sourcing with inbox/outbox for exactly-once processing. These models live in `indexer-infra.prisma`.

## Core Tables

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

## Event Flow

```
Blockchain → Block Watcher (5s poll)
  → InfraIngestEvent (immutable log)
  → InfraIngestOutbox (pending publish)
  → InfraInbox (per handler: AllocationProjector, StakingProjector, etc.)
  → Domain Projectors (apply business logic)
  → DomainOutbox (commands: MintV1, SetMerkleRootV1, etc.)
```

## Outbox Pattern Rules

- Every event write must also write an outbox row in the **same transaction**
- Publishers poll outbox for `publishedAt IS NULL`, deliver, then mark published
- Inbox handlers must be **idempotent** — use `ProcessedEvent` for deduplication
- Each handler processes events **in partition order** by `blockNumber`
- Failed handlers go to DLQ after max attempts — never block the pipeline

## Domain Commands (CQRS)

```
DomainOutbox
  commandKey          — Deterministic key for idempotency
  kind                — MintV1, SetMerkleRootV1, etc.
  payload             — Command parameters (JSON)
  publishedAt, txHash — Execution tracking
```
