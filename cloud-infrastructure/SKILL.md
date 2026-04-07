---
name: cloud-infrastructure
description: Use when provisioning or modifying cloud resources with infrastructure-as-code — AWS (VPC, ECS, RDS, ElastiCache, SQS/SNS, MQ, MSK, Secrets Manager, IAM), Cloudflare Zero Trust, or GCP (BigQuery, GCS, Pub/Sub). Triggers on edits to IaC source files (Pulumi, Terraform, CDK), stack/state configuration, or mentions of "infrastructure", "IaC", "Pulumi", "Terraform", "AWS", "VPC", "RDS", "ECS", "SQS", "MSK", "RabbitMQ", "Pub/Sub", "Cloudflare", or "BigQuery". For build/deploy pipelines see deployment-pipelines. For infrastructure security hardening see security-engineering.
---

# Cloud Infrastructure

You are operating as an infrastructure engineer responsible for the cloud footprint. Treat every change as production-bound: prefer least privilege, reproducibility, and explicit environment parity over convenience.

The reference implementation uses Pulumi 3.x with TypeScript, but the rules apply to any IaC tool (Terraform, CDK, Pulumi). Multi-stack environments (`dev` / `staging` / `production`) provision AWS, Cloudflare, and GCP resources. Pipelines that consume these resources live in [deployment-pipelines](../deployment-pipelines/SKILL.md); security hardening guidance lives in [security-engineering](../security-engineering/SKILL.md).

Every resource should be environment-aware: dev can rely on local Docker for stateful services, while staging/production provision real RDS, ElastiCache, ECS, and Secrets Manager.

## Universal Rules

### Resource Creation
1. **Tag everything** — use `getTags()` on every resource.
2. **Name consistently** — use `getResourceName()` for all resource names.
3. **Encrypt everything** — at rest and in transit on all data stores.
4. **Size by environment** — use `getInstanceSizing()`, never hardcode instance types.
5. **Condition on environment** — skip expensive dev resources, enforce HA in production.

### Security
1. **No hardcoded secrets** — use Pulumi secrets or Secrets Manager.
2. **Least-privilege IAM** — scope to specific actions and resource ARNs.
3. **VPC isolation** — databases and caches only accessible from within VPC CIDR.
4. **OIDC for CI/CD** — no long-lived credentials in GitHub.
5. **Zero Trust access** — Cloudflare tunnels for dev, not VPN or public endpoints.

### Production Requirements
1. **Multi-AZ** on RDS and ElastiCache.
2. **Read replicas** on RDS.
3. **Auto scaling** on ECS services.
4. **Backup retention** of 7+ days.
5. **Final snapshots** enabled before any RDS deletion.
6. **Container image scanning** on ECR push.

## References

- [references/overview-and-config.md](references/overview-and-config.md) — framework, tooling, project structure, env detection, naming, tagging, sizing, conditional creation
- [references/vpc-and-security-groups.md](references/vpc-and-security-groups.md) — VPC creation with awsx, per-service security groups
- [references/rds.md](references/rds.md) — PostgreSQL instance, read replicas, encryption, multi-AZ
- [references/elasticache.md](references/elasticache.md) — Redis replication group, failover, encryption
- [references/ecr-ecs.md](references/ecr-ecs.md) — container registry, ECS cluster, task definitions, service auto-scaling
- [references/secrets-manager.md](references/secrets-manager.md) — app config secret, .env sync, IAM scoping
- [references/iam-oidc.md](references/iam-oidc.md) — GitHub Actions OIDC role, developer access policies
- [references/cloudflare-zero-trust.md](references/cloudflare-zero-trust.md) — tunnels, DNS, Access apps and policies, ingress config
- [references/gcp-bigquery-gcs.md](references/gcp-bigquery-gcs.md) — GCS buckets, BigQuery datasets/tables, Cloud Build migrations
- [references/messaging.md](references/messaging.md) — provisioning SQS, SNS fan-out, Amazon MQ (RabbitMQ), MSK (Kafka), and Google Pub/Sub with DLQs, encryption, and HA

For CI/CD pipeline authoring (GitHub Actions workflows, OIDC, caching, security hardening) see the [deployment-pipelines](../deployment-pipelines/SKILL.md) skill.
