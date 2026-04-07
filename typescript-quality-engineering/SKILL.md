---
name: typescript-quality-engineering
description: Use when writing or reviewing automated tests at any layer — Jest unit tests for components/hooks/services/controllers, Supertest+Postgres API integration tests, Playwright E2E, or Hardhat smart contract tests. Triggers on edits to *.test.ts/tsx, *.integration.test.ts, *.spec.ts under e2e/, or mentions of "test", "unit test", "integration test", "e2e", "Playwright", "coverage", "QA", or "test automation".
---

# Quality Engineering (TypeScript)

Multi-layer test stack for the YGG platform: Jest 29 + React Testing Library for unit tests, Jest + Supertest against a real PostgreSQL `TestDatabase` for API integration tests, Playwright 1.56 for E2E, and Hardhat + Chai + Ethers for smart contracts. CI runs unit + integration in GitHub Actions with a Postgres service container.

Tests live in co-located `__tests__/` folders. Unit tests mock at the module boundary (`@repo/prisma`, services); integration tests use a real isolated database with `authTestHelpers` instead.

## Universal Rules

1. **Assert observable behavior** — at least one `expect()` per `it()`, test what users see, not internal calls.
2. **Independent** — no test depends on another test's state or order.
3. **Deterministic** — same result every run, no `sleep()` or arbitrary timeouts.
4. **Literal expected values** — `expect(total).toBe(70)`, not `expect(total).toBe(a + b)`.
5. **Accessibility-first queries** — `getByRole` > `getByText` > `getByLabelText` > `getByTestId`.
6. **Prefer `userEvent.setup()`** over `fireEvent` for realistic interactions.
7. **`beforeEach` cleanup**, not `afterEach` — leaves a clean state after failures.
8. **Never `test.skip()`** — fix or delete.
9. **Mock at the module boundary** for unit tests (`@repo/prisma`); use the real DB for integration tests.
10. **`QueryClient` with `retry: false`** in test wrappers.

## References

- [references/frameworks-and-structure.md](references/frameworks-and-structure.md) — frameworks, dependencies, scripts, directory layout, file naming
- [references/unit-testing-components.md](references/unit-testing-components.md) — custom render, queries, user interactions, mocking child components/Next.js/Zustand/services
- [references/unit-testing-hooks.md](references/unit-testing-hooks.md) — `renderHook` with provider wrapper, sync + async patterns
- [references/unit-testing-backend.md](references/unit-testing-backend.md) — service unit tests with mocked Prisma, controller unit tests with injected service mocks
- [references/integration-testing-api.md](references/integration-testing-api.md) — `TestDatabase`, `TestServer`, `authTestHelpers`, shared setup pattern, full Supertest example, cleanup rules
- [references/e2e-playwright.md](references/e2e-playwright.md) — `playwright.config.ts`, example spec, retries/artifacts/reporters, auto web server
- [references/smart-contract-testing.md](references/smart-contract-testing.md) — Hardhat fixtures, time manipulation helpers, event assertions
- [references/ci-cd.md](references/ci-cd.md) — GitHub Actions workflow with Postgres service, coverage outputs, Foundry contract CI
- [references/test-quality-rules.md](references/test-quality-rules.md) — must/do-not lists, mock scope table by test layer, test failure triage
