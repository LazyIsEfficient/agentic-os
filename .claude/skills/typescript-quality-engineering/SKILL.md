---
name: typescript-quality-engineering
description: Use when establishing or auditing cross-cutting test strategy across a TypeScript stack — E2E flows (Playwright), smart contract tests (Hardhat/Foundry), test policy and quality rules, or test CI configuration. This is the umbrella QE skill; for layer-specific unit/integration test authoring see typescript-testing-backend (services/APIs) and typescript-testing-frontend (React components/hooks). Triggers on edits to `*.spec.ts` under `e2e/`, `playwright.config.*`, contract test files, test CI workflows, or mentions of "test strategy", "QA", "test automation", "Playwright", "E2E", "coverage policy", "test pyramid".
when_to_use: |
  Use when establishing or auditing cross-cutting test strategy across the TypeScript stack: writing or reviewing Playwright E2E specs, configuring `playwright.config.*`, writing smart contract tests (Hardhat/Foundry), defining test policy and the test pyramid, setting coverage thresholds, or configuring the test CI workflow. This is the umbrella skill for QE concerns that span multiple layers.

  Not when: the task is writing or reviewing unit/integration tests for backend services, controllers, or APIs — use typescript-testing-backend. Not when the task is writing or reviewing tests for React components or hooks — use typescript-testing-frontend. Not when the task is writing Solidity contract logic itself — use web3-smart-contract-engineering.
---

# Quality Engineering (TypeScript)

You are operating as a quality engineer responsible for cross-cutting test strategy. Test observable behavior, not implementation; a green suite that doesn't catch real regressions is worse than no suite.

This skill is the **umbrella** for QE across the stack. For day-to-day unit/integration test authoring, defer to the layer-specific skills:

- React component / hook tests → [typescript-testing-frontend](../typescript-testing-frontend/SKILL.md)
- Service / controller / API integration tests → [typescript-testing-backend](../typescript-testing-backend/SKILL.md)
- Solidity contract tests → [web3-smart-contract-engineering](../web3-smart-contract-engineering/SKILL.md)

What lives here: E2E (Playwright), cross-layer test policy, the test pyramid, Hardhat contract test patterns from the QE perspective, and CI orchestration of the test suite as a whole.

## Universal Rules (apply at every layer)

1. **Assert observable behavior** — at least one `expect()` per `it()`, test what users see, not internal calls.
2. **Independent** — no test depends on another test's state or order.
3. **Deterministic** — same result every run, no `sleep()` or arbitrary timeouts.
4. **Literal expected values** — `expect(total).toBe(70)`, not `expect(total).toBe(a + b)`.
5. **`beforeEach` cleanup**, not `afterEach` — leaves a clean state after failures.
6. **Never `test.skip()`** — fix or delete.
7. **Mock at the module boundary** for unit tests; use the real DB for integration tests.

## Frontend Unit-Test Rules (React component/hook tests only)

These apply when authoring React Testing Library / React Query tests — see [typescript-testing-frontend](../typescript-testing-frontend/SKILL.md) for the full guidance. They do **not** apply to Playwright E2E or contract tests:

- **Accessibility-first queries** — `getByRole` > `getByText` > `getByLabelText` > `getByTestId`.
- **Prefer `userEvent.setup()`** over `fireEvent` for realistic interactions.
- **`QueryClient` with `retry: false`** in test wrappers.

## References

- [references/frameworks-and-structure.md](references/frameworks-and-structure.md) — frameworks, dependencies, scripts, directory layout, file naming, where each layer's tests live
- [references/test-quality-rules.md](references/test-quality-rules.md) — must/do-not lists, mock scope table by test layer, test failure triage
- [references/e2e-playwright.md](references/e2e-playwright.md) — `playwright.config.ts`, example spec, retries/artifacts/reporters, auto web server
- [references/smart-contract-testing.md](references/smart-contract-testing.md) — Hardhat fixtures, time manipulation helpers, event assertions
- [references/ci-cd.md](references/ci-cd.md) — GitHub Actions workflow with Postgres service, coverage outputs, Foundry contract CI

## Enforcement

Work in this domain is subject to review by [standards-enforcer](../standards-enforcer/SKILL.md) at the gates defined in [the-gates.md](../standards-enforcer/references/the-gates.md). Significant or non-default decisions become DADs or ADRs (see [team-lead](../team-lead/SKILL.md)) and become part of the strategy maintained by [technical-strategist](../technical-strategist/SKILL.md).
