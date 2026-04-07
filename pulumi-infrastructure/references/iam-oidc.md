# IAM Patterns

## GitHub Actions OIDC (No Stored Credentials)

```typescript
export const githubActionsRole = new aws.iam.Role('github-actions-role', {
  assumeRolePolicy: JSON.stringify({
    Version: '2012-10-17',
    Statement: [{
      Effect: 'Allow',
      Principal: { Federated: 'arn:aws:iam::*:oidc-provider/token.actions.githubusercontent.com' },
      Action: 'sts:AssumeRoleWithWebIdentity',
      Condition: {
        StringEquals: { 'token.actions.githubusercontent.com:aud': 'sts.amazonaws.com' },
        StringLike: { 'token.actions.githubusercontent.com:sub': 'repo:org/repo:*' },
      },
    }],
  }),
  tags: getTags({}),
})

// Attach ECR push/pull and ECS management policies
```

## Developer Access

```typescript
export const devTeamUser = new aws.iam.User('ygg-dev-team', {
  path: '/dev/',
  tags: getTags({ Purpose: 'LocalDev secrets access' }),
})

// Scoped to specific secret ARN patterns only
export const localDevSecretsPolicy = new aws.iam.Policy('local-dev-secrets', {
  policy: JSON.stringify({
    Version: '2012-10-17',
    Statement: [{
      Effect: 'Allow',
      Action: ['secretsmanager:GetSecretValue', 'secretsmanager:DescribeSecret'],
      Resource: [
        'arn:aws:secretsmanager:*:*:secret:ygg-indexer-dev/ygg-local-dev-*',
        'arn:aws:secretsmanager:*:*:secret:ygg-indexer-dev-env-*',
      ],
    }],
  }),
})
```

**Rules**:
- Always use OIDC federation for CI/CD — never store long-lived credentials
- Scope policies to minimum required actions and specific resource ARNs
- Create separate IAM users for dev-team access, not shared root
