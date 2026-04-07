# Cloudflare Patterns

## Zero Trust Tunnels

Per-developer tunnels for secure access to dev resources:

```typescript
import * as cloudflare from '@pulumi/cloudflare'

// One tunnel per developer
export const devTunnels = developerNames.map(
  (name) => new cloudflare.ZeroTrustTunnelCloudflared(`tunnel-${name}`, {
    name: `app-dev-database-tunnel-${name}`,
    accountId: cloudflareConfig.accountId,
    configSrc: 'cloudflare',
  })
)
```

## DNS Records

```typescript
// CNAME pointing to tunnel
export const devDnsRecords = developerNames.map(
  (name, i) => new cloudflare.DnsRecord(`dns-${name}`, {
    zoneId: cloudflareConfig.zoneId,
    name: `dev-db-${name}`,           // dev-db-alice.example.com
    content: pulumi.interpolate`${devTunnels[i].id}.cfargotunnel.com`,
    type: 'CNAME',
    ttl: 1,
    proxied: true,
  })
)
```

## Zero Trust Access Applications

```typescript
export const devAccessApps = developerNames.map(
  (name) => new cloudflare.ZeroTrustAccessApplication(`access-${name}`, {
    name: `app-dev-database-access-${name}`,
    domain: `dev-db-${name}.example.com`,
    type: 'self_hosted',
    sessionDuration: '24h',
  })
)
```

## Zero Trust Access Policies

```typescript
// Allow by email domain (team members)
export const devTeamPolicies = developerNames.map(
  (name) => new cloudflare.ZeroTrustAccessPolicy(`policy-${name}`, {
    applicationId: devAccessApps[name].id,
    decision: 'allow',
    includes: [{
      emailDomain: { domain: 'example.com' },
    }],
  })
)

// Allow by IP range (external tools like Retool)
export const retoolPolicy = new cloudflare.ZeroTrustAccessPolicy('retool-policy', {
  applicationId: retoolAccessApp.id,
  decision: 'allow',
  includes: [
    { ip: { ip: '35.90.103.132/30' } },
    { ip: { ip: '44.208.168.68/30' } },
  ],
})
```

## Tunnel Ingress Configuration

```typescript
export const tunnelConfig = new cloudflare.ZeroTrustTunnelCloudflaredConfig('tunnel-config', {
  accountId: cloudflareConfig.accountId,
  tunnelId: tunnel.id,
  config: {
    ingresses: [
      {
        hostname: 'ethereum-rpc.example.com',
        service: 'http://hardhat-node:8545',
        originRequest: { noTlsVerify: true },
      },
      {
        hostname: 'ethereum-ws.example.com',
        service: 'ws://hardhat-node:8545',
        originRequest: { noTlsVerify: true },
      },
      { service: 'http_status:404' },  // Catch-all rule (required)
    ],
  },
})
```

**Rules**:
- Always include a catch-all `http_status:404` as the last ingress rule
- Use `proxied: true` on DNS records for Cloudflare protection
- Scope access policies by email domain for internal teams, IP ranges for external tools
- Set explicit `sessionDuration` on access applications
