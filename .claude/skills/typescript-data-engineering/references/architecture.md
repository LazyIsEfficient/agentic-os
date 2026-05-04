# Architecture Overview

The platform uses a microservices architecture with:

- **PostgreSQL 17** as the primary OLTP database (via Prisma and Drizzle ORMs)
- **Google BigQuery** as the data warehouse for analytics, reporting, and long-term storage
- **Redis 7.x** for pub/sub messaging and job queues
- **Event sourcing** with inbox/outbox pattern for reliable cross-service communication
- **Scheduled cron jobs** for recurring ETL and data distribution tasks

## Service Boundaries

| Service | Purpose | Port | Database Access |
|---|---|---|---|
| `evm-indexer` | Blockchain event ingestion pipeline | 3000 | Shared PostgreSQL (writes events, allocations) |
| `points-service` | Scheduled points distribution + quest resets | 3001 | Shared PostgreSQL (reads/writes points, activities) |
| `platform-app` | Next.js web frontend + API routes | 3000 | Shared PostgreSQL (reads all, writes user data) |
| `redeem-api` | Token redemption platform | 4000 | Separate PostgreSQL (Drizzle migrations) |

Services share a PostgreSQL database via `@repo/prisma` but are decoupled through the event sourcing inbox/outbox pattern.
