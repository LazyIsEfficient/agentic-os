# CI/CD Integration

## GitHub Actions Workflow

```yaml
# .github/workflows/monorepo.ci.yml
jobs:
  run_unit_and_integration_tests:
    runs-on: platform-app-testing-ci-runner
    services:
      postgres:
        image: postgres:17
        env:
          POSTGRES_USER: testuser
          POSTGRES_PASSWORD: testpass
          POSTGRES_DB: platform_test
          POSTGRES_HOST_AUTH_METHOD: trust
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'pnpm' }
      - run: pnpm install --frozen-lockfile
      - run: pnpm run prisma:generate
      - run: pnpm turbo run build --filter=@repo/* --filter=!@repo/evm-indexer
      - run: pnpm -w run platform-app-unit-integration-tests
        env:
          CI: 'true'
          POSTGRES_PRISMA_URL: 'postgresql://testuser:testpass@localhost:5432/platform_test'
          POSTGRES_URL_NON_POOLING: 'postgresql://testuser:testpass@localhost:5432/platform_test'
```

## Coverage

- `collectCoverage: true` in Jest config
- JUnit XML output: `test-results/jest/results.xml` (Jest), `test-results/junit.xml` (Playwright)
- No explicit coverage thresholds — enforced via code review

## Smart Contract CI

```yaml
# Foundry tests
- uses: foundry-rs/foundry-toolchain@v1
  with: { version: nightly }
- run: forge build --sizes
- run: forge test -vvv
```
