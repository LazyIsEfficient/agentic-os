# Migrations and Local Dev Infrastructure

> **Scope:** database migrations and the **local development** stack (Docker Compose) only.
> Cloud provisioning — GCP/AWS/Cloudflare resources, Pulumi/IaC, secrets management — is
> out of scope here; see the `devops-engineer` agent. This file
> covers how migrations run and how to stand up the stores on your machine, not how the
> production stores are provisioned.

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

### Cloud (provisioning lives with the `devops-engineer` agent)

The production data stores this pipeline targets — Cloud Storage buckets, the BigQuery
warehouse, managed Postgres/Redis, secrets, DNS/CDN — are **provisioned and owned by
the `devops-engineer` agent** (Pulumi/IaC). Do not author
provisioning here. From this skill's side, treat those stores as given and connect to them
via environment config.

The one cloud touchpoint that *is* data-engineering's concern is **where migrations run** in
CI/CD: `npx prisma migrate deploy` is invoked from the deployment pipeline (see the Cloud Build
config referenced above). The pipeline wiring itself belongs to
[deployment-pipelines](../../deployment-pipelines/SKILL.md).

### Monorepo Structure

> The layout below is orientation for where pipeline/migration code lives. The repo's
> build/deploy tooling and cloud wiring are owned by
> [deployment-pipelines](../../deployment-pipelines/SKILL.md) and
> the `devops-engineer` agent.

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
