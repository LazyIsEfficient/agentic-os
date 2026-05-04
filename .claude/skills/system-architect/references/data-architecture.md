# Data Architecture

Data is the hardest thing to change. Get the ownership model and consistency story right before writing services.

## Single-Writer Rule

- **Each table has exactly one owning service.** That service is the only one that issues writes.
- Other services read via API, events, or a derived read model — never by querying the owner's tables.
- Violations create invisible coupling: schema changes become cross-team negotiations and bugs become un-debuggable.

## Consistency Models

| Model | Guarantee | Use when |
|---|---|---|
| **Strong / linearizable** | Reads see latest write | Money, inventory, auth state |
| **Read-your-writes** | A client sees its own writes | User-edited content |
| **Monotonic reads** | Reads never go backwards | Feeds, timelines |
| **Eventual** | Converges, eventually | Analytics, recommendations, caches |

Strong consistency across services is **expensive and slow**. Use it only where wrong answers are unacceptable.

## Cross-Service Data Flow

### Synchronous query
- Service A calls Service B's API to get data on demand.
- **Pros**: always fresh.
- **Cons**: couples availability (B down → A degraded), adds latency.

### Replication via events
- B publishes events; A maintains a local read model.
- **Pros**: A is independent of B's availability, faster reads.
- **Cons**: eventual consistency, schema versioning, more moving parts.

### CDC (Change Data Capture)
- Stream B's DB changes (Debezium / RDS streams) into a topic; consumers derive views.
- **Pros**: no application changes in B.
- **Cons**: leaks B's schema as a public contract — version carefully.

## Outbox Pattern (essential)

When a service must update its DB **and** publish an event:

1. In one DB transaction: write the state change AND insert the event into an `outbox` table.
2. A relay process reads `outbox` and publishes to the broker, marking rows sent.
3. Guarantees at-least-once delivery without 2PC.

Without the outbox, the service can crash between DB commit and broker publish, losing the event silently.

## Polyglot Persistence

Pick the storage that fits the workload — but each new datastore is operational debt.

| Workload | Good fit |
|---|---|
| Transactional / relational | Postgres |
| Document / flexible schema | Postgres JSONB (default), MongoDB |
| Search / full-text | OpenSearch / Elasticsearch / Postgres tsvector |
| Time-series / metrics | Timescale, InfluxDB, Prometheus |
| Wide-column / massive scale | Cassandra, ScyllaDB |
| KV cache | Redis, Memcached |
| Graph | Neo4j (rare — most "graph" needs fit Postgres) |
| Object / blob | S3 / GCS |
| Analytics / OLAP | ClickHouse, BigQuery, Snowflake, DuckDB |

**Default to Postgres.** Add another store only when Postgres demonstrably can't meet the requirement.

## Schema Evolution

- **Backwards-compatible migrations only** in production: add columns nullable, deploy code that reads old + new, backfill, then drop old.
- Never `DROP` a column in the same release that stops writing it.
- Versioned events on the broker: consumers must tolerate unknown fields.

## Backups & Recovery
- Automated snapshots, encrypted, cross-region.
- **Test restores quarterly.** Document RTO/RPO measured (not assumed).
- PITR (point-in-time recovery) for any system where losing 5 minutes of data is unacceptable.
