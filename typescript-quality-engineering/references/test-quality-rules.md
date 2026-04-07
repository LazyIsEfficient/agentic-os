# Test Quality Rules

## Every Test Must

1. **Assert observable behavior** — at least one `expect()` per `it()` block
2. **Be independent** — no test depends on another test's state or execution order
3. **Be deterministic** — same result every run, no flaky timing dependencies
4. **Use literal expected values** — `expect(total).toBe(70)`, not `expect(total).toBe(a + b)`

## Do Not

- Use `test.skip()` or comment out tests — fix or delete them
- Share mutable state between tests without cleanup
- Assert implementation details — test behavior, not internal method calls
- Use `sleep()` or arbitrary timeouts — use `waitFor()` or event-based waits

## Mock Scope

| Dependency | Unit Tests | Integration Tests |
|---|---|---|
| Prisma / database | `jest.mock('@repo/prisma')` | Real test database |
| Auth session | `jest.mock(...)` | `authTestHelpers` |
| External APIs | `jest.mock(...)` | `jest.mock(...)` |
| React Query | QueryClient with `retry: false` | Same |
| Internal utils | Real implementation | Real implementation |

## Test Failure Response

- **Fix the test**: Wrong expected values, coupled to implementation details, flaky assertions
- **Fix the implementation**: Valid business rules, edge cases, contract violations
- **When in doubt**: Confirm with the team before changing either
