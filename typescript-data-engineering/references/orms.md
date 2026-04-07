# ORMs and Database Access

## Prisma (Primary)

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

## Drizzle ORM (Secondary)

Used in event sourcing POCs and standalone services with independent schemas:

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

## When to Use Each

| ORM | Use When |
|---|---|
| **Prisma** | Shared platform data models, type-safe queries, relation traversal |
| **Drizzle** | Independent service schemas, event stores, migration-heavy workflows, raw SQL needs |
