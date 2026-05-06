# Validation and Cron Scheduling

## Data Validation with Zod

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
