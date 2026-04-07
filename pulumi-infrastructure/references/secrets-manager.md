# Secrets Management

## AWS Secrets Manager

```typescript
// Application config secret
export const appConfigSecret = new aws.secretsmanager.Secret('app-config', {
  name: getResourceName('secrets.appConfigName'),
  description: `Application configuration for YGG ${environment} environment`,
  tags: getTags({}),
})

// Auto-sync .env variables to Secrets Manager
for (const [key, value] of Object.entries(envVars)) {
  const secret = new aws.secretsmanager.Secret(`${key}-secret`, {
    name: `ygg-indexer-${environment}-${sanitize(key)}`,
    description: `Environment variable ${key} for ${environment}`,
    tags: getTags({}),
  })
  new aws.secretsmanager.SecretVersion(`${key}-version`, {
    secretId: secret.id,
    secretString: value,
  })
}
```

**Rules**:
- Never store secrets in Pulumi config as plaintext — use `pulumi config set --secret`
- Use `manageMasterUserPassword` for RDS credentials
- Use Secrets Manager ARNs in ECS task definitions, not raw values
- Scope IAM policies to specific secret ARNs, not `*`
