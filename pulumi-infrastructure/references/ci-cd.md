# CI/CD Integration

## GitHub Actions Pipeline

```yaml
# .github/workflows/ci.yml
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm run type-check
      - run: npm run lint
      - run: npm run format:check
      - run: npm run test:coverage
```

## Deployment Scripts

Deployments use Pulumi CLI via npm scripts:

```bash
# Preview changes
npm run preview:staging

# Apply changes
npm run deploy:staging

# Teardown (use with extreme caution)
npm run destroy:staging
```

**Rules**:
- Always `preview` before `deploy`
- Never run `destroy` on production without explicit team approval
- CI deploys use OIDC role assumption — no stored AWS credentials
