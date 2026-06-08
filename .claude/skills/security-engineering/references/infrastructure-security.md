# Infrastructure Security

## Network Isolation

**VPC design** (Pulumi):

- All databases and caches in private subnets, ingress restricted to VPC CIDR only
- No internet-facing databases — all access via VPC or Cloudflare tunnels

**Security group rules**:

| Resource | Port | Ingress Source |
|---|---|---|
| RDS PostgreSQL | 5432 | VPC CIDR only |
| ElastiCache Redis | 6379 | VPC CIDR only |
| ECS services | 80, 443 | 0.0.0.0/0 (public) |
| ECS dynamic ports | 32768-65535 | VPC CIDR only |
| Ethereum Geth RPC (dev) | 8545, 8546 | VPC CIDR only |

## Cloudflare Zero Trust

Per-developer tunnels with access policies scoped by email domain:

```typescript
// Access policy — team members (use your own org's email domain)
decision: 'allow'
includes: [{ emailDomain: { domain: 'example.com' } }]

// Access policy — external tools (IP-restricted)
decision: 'allow'
includes: [
  { ip: { ip: '203.0.113.0/30' } },  // e.g. a third-party admin tool (RFC 5737 example range)
]
```

- Session duration: 24 hours
- DNS records: `proxied: true` for Cloudflare protection
- Tunnel catch-all: `http_status:404` as last ingress rule

## Secrets Management

- **RDS**: `manageMasterUserPassword: true` — AWS-managed credential rotation
- **ECS tasks**: Secrets injected via Secrets Manager ARN, never as environment variables
- **IAM policies**: Scoped to specific secret ARN patterns, never `*`
- **GitHub Actions**: OIDC federation — no stored long-lived credentials
- **.env files**: Always in `.gitignore`, validated at startup via Zod
- **Dotenvx**: Encrypted secret files with `DECRYPT_PRIVATE_KEY` for shared dev environments

## Encryption

- **RDS**: `storageEncrypted: true` always
- **ElastiCache**: `atRestEncryptionEnabled: true` + `transitEncryptionEnabled: true`
- **ECR**: AES256 encryption, image scanning on push
- **TLS**: All services communicate over TLS; Cloudflare handles edge TLS

## IAM Principles

- **OIDC for CI/CD**: GitHub Actions uses `sts:AssumeRoleWithWebIdentity`, scoped to specific repo
- **Least privilege**: Each role has minimum required actions on specific resource ARNs
- **Separate dev access**: Dedicated IAM user for dev-team with secrets-read-only policy
- **No root usage**: Service accounts and scoped roles only
