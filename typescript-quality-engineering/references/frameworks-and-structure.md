# Test Frameworks and Project Structure

## Test Frameworks

| Layer | Framework | Config |
|---|---|---|
| Unit (frontend) | Jest 29.7.0 + React Testing Library 16.x | `config/jest/jest.config.js` |
| Unit (backend) | Jest 29.7.0 + Supertest | Same config, `testEnvironment: 'jsdom'` |
| Unit (contracts) | Hardhat + Chai + Ethers.js | `hardhat.config.ts` |
| Integration (API) | Jest + Supertest + real PostgreSQL | `*.integration.test.ts` |
| Integration (hooks) | Jest + renderHook + React Query | `*.test.tsx` with wrapper |
| End-to-end | Playwright 1.56.1 | `playwright.config.ts` |

## Key Dependencies

```
jest                               ^29.7.0
@swc/jest                          # Fast TS compilation (not Babel)
@testing-library/react             ^16.2.0
@testing-library/jest-dom          ^6.6.3
@testing-library/dom               ^10.4.0
@playwright/test                   ^1.56.1
supertest                          # HTTP integration testing
jest-junit                         # JUnit XML for CI
jest-canvas-mock                   # Canvas polyfill for jsdom
```

## Test Scripts

```json
{
  "test": "jest --config ./config/jest/jest.config.js --setupFiles ./config/jest/env.setup.js",
  "test:ci": "jest --config ... --maxWorkers=2 --ci",
  "e2e": "playwright test && npx shortest --headless",
  "e2e:playwright": "playwright test",
  "e2e:playwright:ci": "playwright test --reporter=list,junit"
}
```

## Directory Structure and Naming

Tests live in co-located `__tests__/` folders. Typical layout:

```
apps/<app>/
├── app/api/v1/<resource>/
│   ├── controllers/<resource>.controller.ts
│   ├── services/<resource>.service.ts
│   └── __tests__/
│       ├── <action>.integration.test.ts
│       └── shared-test-setup.ts
├── shared/test-utils/
│   ├── test-database.ts
│   ├── server-mock.ts
│   └── mocks/
├── domains/<domain>/
│   ├── components/__tests__/<Component>.test.tsx
│   └── hooks/__tests__/use<Hook>.test.tsx
├── e2e/playwright/__tests__/*.spec.ts
├── test-utils/render.tsx
└── config/jest/
    ├── jest.config.js
    ├── jest.setup.js
    └── env.setup.js
```

| Type | Pattern |
|---|---|
| Component unit | `{ComponentName}.test.tsx` |
| Hook unit | `use{HookName}.test.ts/tsx` |
| Service unit | `{module}.service.test.ts` |
| Controller unit | `{module}.controller.test.ts` |
| API integration | `{action}.integration.test.ts` |
| E2E | `{feature}.spec.ts` |
| Smart contract | `{contract}.test.ts` |
