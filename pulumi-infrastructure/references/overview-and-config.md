# Framework, Tooling, and Configuration

## Framework and Tooling

- **Pulumi 3.x**: Infrastructure-as-code framework (TypeScript)
- **Runtime**: Node.js 22+ with npm
- **Providers**:
  - `@pulumi/aws` ^7.0.0
  - `@pulumi/awsx` ^3.0.0 (higher-level AWS components)
  - `@pulumi/cloudflare` ^6.9.1
  - `@pulumi/pulumi` ^3.113.0
- **TypeScript**: Strict mode, target ES2022, module CommonJS
- **CI/CD**: GitHub Actions with OIDC-based AWS role assumption

### Scripts

```bash
npm run check                  # validate-node + type-check + lint + format + test
npm run deploy:staging         # pulumi stack select staging && pulumi up
npm run deploy:production      # pulumi stack select production && pulumi up
npm run preview:staging        # Preview changes without applying
npm run preview:production
npm run destroy:staging        # Teardown all resources
npm run destroy:production
```

## Project Structure

```
pulumi-ygg-play/
├── Pulumi.yaml                 ← Project definition
├── Pulumi.dev.yaml             ← Dev stack config
├── Pulumi.staging.yaml         ← Staging stack config
├── Pulumi.production.yaml      ← Production stack config
├── index.ts                    ← Entry point
├── src/
│   ├── config/
│   │   └── index.ts            ← Environment detection, naming, sizing, tags
│   ├── networking/
│   │   └── vpc.ts              ← VPC with public/private subnets
│   ├── security/
│   │   └── security-groups.ts  ← Per-service security groups
│   ├── persistence/
│   │   ├── rds.ts              ← PostgreSQL RDS + read replicas
│   │   └── elasticache.ts      ← Redis replication group
│   ├── application/
│   │   ├── ecr.ts              ← Container registry
│   │   ├── ecs.ts              ← ECS cluster + auto scaling
│   │   └── ecs-service.ts      ← Task definitions + services
│   ├── identity/
│   │   ├── iam-roles.ts        ← ECS task roles
│   │   ├── iam-policies.ts     ← Least-privilege policies
│   │   ├── github-actions.ts   ← OIDC federation for CI/CD
│   │   └── dev-access.ts       ← Developer IAM users
│   ├── secrets/
│   │   ├── secrets-manager.ts  ← App config + DB credentials
│   │   └── env-vars.ts         ← .env → Secrets Manager sync
│   ├── cloudflare/
│   │   ├── tunnels.ts          ← Zero Trust tunnels + DNS
│   │   └── zero-trust.ts       ← Access applications + policies
│   └── ethereum/
│       └── index.ts            ← Dev-only blockchain node
└── .github/workflows/
    └── ci.yml                  ← Test + lint + coverage
```

## Configuration and Environment Detection

### Stack-Based Environments

Every resource is environment-aware. Detect the stack and branch logic accordingly:

```typescript
import * as pulumi from '@pulumi/pulumi'

export const stack = pulumi.getStack() // 'dev' | 'staging' | 'production'
export const isDev = stack === 'dev'
export const isStaging = stack === 'staging'
export const isProduction = stack === 'production'
```

### Resource Naming

All resources follow a consistent naming pattern: `{appName}-{resourceType}-{environment}`:

```typescript
export function getResourceName(resourceType: string): string {
  return `${appConfig[resourceType]}-${environment}`
}

// Examples: ygg-ecs-cluster-staging, ygg-postgres-production
```

### Tagging Strategy

Every resource must be tagged:

```typescript
export function getTags(additionalTags: Record<string, string> = {}): Record<string, string> {
  return {
    Project: 'YGG',
    ManagedBy: 'Pulumi',
    Environment: environment,
    ...additionalTags,
  }
}
```

### Instance Sizing by Environment

Use a sizing lookup to avoid hardcoding sizes:

```typescript
export function getInstanceSizing<T extends keyof typeof instanceSizing>(
  resourceType: T,
) {
  if (isDev) return instanceSizing[resourceType].dev
  if (isStaging) return instanceSizing[resourceType].staging
  if (isProduction) return instanceSizing[resourceType].production
  return null
}
```

| Resource | Dev | Staging | Production |
|---|---|---|---|
| RDS | None (local) | db.t3.small, 20GB | db.t3.medium, 100GB, Multi-AZ |
| ElastiCache | None (local) | t3.micro, 1 node | t3.medium, 3 nodes, failover |
| ECS Instance | None | t3.medium | t3.medium |

## Conditional Resource Creation

Not all resources exist in all environments. Gate expensive or environment-specific resources:

```typescript
// Only create RDS in staging and production
if (!isDev) {
  export const rdsInstance = new aws.rds.Instance(...)
}

// Only create Ethereum node in dev
if (isDev) {
  export const ethereumInstance = new aws.ec2.Instance(...)
}

// Only create GitHub Actions OIDC role in staging/production
if (!isDev) {
  export const githubActionsRole = new aws.iam.Role(...)
}
```

**Dev uses**: Local Docker PostgreSQL + Redis, Cloudflare tunnels for team access
**Staging/Production uses**: RDS, ElastiCache, ECS, ECR, Secrets Manager
