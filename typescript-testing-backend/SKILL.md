---
name: typescript-testing-backend
description: Use when writing or reviewing backend tests in the YGG platform — Jest unit tests for services/controllers (mocked Prisma) or Supertest integration tests against a real isolated PostgreSQL via `TestDatabase` and `TestServer`. Triggers on edits to `*.service.test.ts`, `*.controller.test.ts`, `*.integration.test.ts`, files under `app/api/v1/**/__tests__/`, or mentions of "backend test", "service test", "API test", "database test".
---

# TypeScript Testing — Backend

Backend test stack: Jest 29 with `@swc/jest`, Supertest for HTTP, custom `TestServer` simulating Next.js route handlers, and `TestDatabase` provisioning isolated PostgreSQL instances per run with migrations + seed. Tests live co-located in `__tests__/` folders.

Unit tests mock `@repo/prisma` at the module boundary; integration tests use the real DB and `authTestHelpers` for auth state.

## Universal Rules

1. **Use Jest** — `jest.mock()` / `jest.fn()`, never `vi.*`.
2. **Co-locate tests** in `__tests__/` next to the source.
3. **Mock at the module boundary** — not internal functions.
4. **Literal expected values** — `expect(total).toBe(70)`, never expressions.
5. **Every `it()` asserts** observable behavior with at least one `expect()`.
6. **`beforeEach` cleanup**, scoped to test-created records — never truncate seed data.
7. **`authTestHelpers.clearMocks()`** between tests.
8. **Never `test.skip()`** — fix or delete.
9. **Real DB for integration tests**, mocked Prisma for unit tests.
10. **Internal utils stay real** — only mock external boundaries.

## References

- [references/framework-and-structure.md](references/framework-and-structure.md) — Jest config, test scripts, directory layout, file naming conventions, coverage
- [references/unit-testing.md](references/unit-testing.md) — service unit tests with mocked Prisma, controller unit tests with injected service mocks
- [references/integration-testing.md](references/integration-testing.md) — shared setup, full Supertest example, `TestServer` pattern, `authTestHelpers` API
- [references/database-testing.md](references/database-testing.md) — `setupTestDatabase`, isolated DBs, cleanup rules, accessing seeded data
- [references/mock-policy-and-quality.md](references/mock-policy-and-quality.md) — mock scope table, quality criteria, test failure triage
