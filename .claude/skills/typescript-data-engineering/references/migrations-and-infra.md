# Migrations and Infrastructure

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
- **IaC**: Pulumi (TypeScript) in `pulumi-platform/`
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
