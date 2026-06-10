# Framework, Directory Structure, and Naming

## Test Framework

- **Jest 29.7.0**: Primary test runner (not Vitest)
- **@swc/jest**: TypeScript transpiler (fast SWC-based compilation)
- **Supertest**: For HTTP endpoint testing via custom `TestServer`
- **Test environment**: `jsdom`
- **Config**: `apps/platform-app/config/jest/jest.config.js`
- **Test scripts**:
  ```json
  "test": "jest --config ./config/jest/jest.config.js --setupFiles ./config/jest/env.setup.js"
  "test:ci": "jest --config ./config/jest/jest.config.js --setupFiles ./config/jest/env.setup.js --maxWorkers=2 --ci"
  ```
- **Mocks**: Use `jest.mock()` and `jest.fn()` — not `vi.mock()` / `vi.fn()`

## Directory Structure

Tests live in co-located `__tests__/` folders next to source files:

```
apps/platform-app/
├── app/api/v1/
│   ├── faq/
│   │   ├── services/faq.service.ts
│   │   ├── controllers/faq.controller.ts
│   │   └── __tests__/
│   │       ├── faq.service.test.ts
│   │       └── faq.controller.test.ts
│   ├── points/
│   │   └── __tests__/
│   │       ├── get-points.integration.test.ts
│   │       └── shared-test-setup.ts
│   └── shared/test-utils/        ← Shared backend test utilities
│       ├── test-database.ts
│       ├── server-mock.ts
│       └── mocks/
│           ├── authentication-mock.ts
│           ├── network-config-mock.ts
│           ├── common-mock.ts
│           └── thirdweb-mock.ts
└── test-utils/render.tsx          ← Frontend test utilities
```

## Naming Conventions

| Type | Pattern | Example |
|---|---|---|
| Service tests | `{module}.service.test.ts` | `user.service.test.ts` |
| Controller tests | `{module}.controller.test.ts` | `user.controller.test.ts` |
| Integration tests | `{feature}.integration.test.ts` | `checkout.integration.test.ts` |

## Coverage Configuration

Coverage is **enabled by default** (`collectCoverage: true`). CI outputs JUnit XML to `test-results/jest/results.xml`. No explicit thresholds are configured — rely on code review and PR process.
