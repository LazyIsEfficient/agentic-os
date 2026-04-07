---
name: typescript-testing-frontend
description: Use when writing or reviewing frontend tests in the YGG platform — Jest unit/integration tests for React components and hooks built with Chakra UI, React Query, Zustand, and Next.js App Router. Triggers on edits to `*.test.tsx`, files under `domains/**/__tests__/`, `test-utils/render.tsx`, or mentions of "frontend test", "component test", "hook test", "React test", "UI test".
---

# TypeScript Testing — Frontend

Frontend test stack: Jest 29 with `@swc/jest`, React Testing Library 16, jest-dom matchers, jest-canvas-mock, in `jsdom`. All tests import from a `@/test-utils/render` wrapper that provides `ChakraProvider` + `QueryClientProvider` (with retries disabled). Tests are co-located in `__tests__/` next to source files.

Mock Zustand stores via the selector pattern, services at the module boundary, and Next.js `next/link` / `next/image` / `next/navigation` modules. Prefer accessibility-first queries.

## Universal Rules

1. **Import from `@/test-utils/render`** — never directly from `@testing-library/react`.
2. **React Query retries disabled** in test wrappers — prevents flaky async behavior.
3. **Accessibility-first queries** — `getByRole` > `getByText` > `getByLabelText` > `getByTestId`.
4. **`userEvent.setup()` over `fireEvent`** for realistic interactions.
5. **Mock at the module boundary** — services, stores, Next.js modules.
6. **Use `const React = require('react')`** inside `jest.mock()` factories.
7. **`waitFor()` for async**, `act()` for sync state updates — never `sleep()`.
8. **No snapshot tests** — behavioral assertions only.
9. **Never `test.skip()`** — fix or delete.
10. **Every `it()` asserts** at least one observable behavior.

## References

- [references/framework-and-setup.md](references/framework-and-setup.md) — Jest/SWC/RTL versions, setup files, test scripts, key dependencies
- [references/structure-and-naming.md](references/structure-and-naming.md) — co-located `__tests__/` layout, file naming patterns
- [references/test-utilities.md](references/test-utilities.md) — `@/test-utils/render` wrapper with Chakra + React Query providers
- [references/component-testing.md](references/component-testing.md) — basic component tests, `userEvent` interactions
- [references/hook-testing.md](references/hook-testing.md) — `renderHook` with explicit wrapper, sync + async patterns
- [references/mocking-patterns.md](references/mocking-patterns.md) — Zustand stores, services, Next.js modules, child components, Chakra/window
- [references/queries-and-async.md](references/queries-and-async.md) — query priority, `waitFor` / `act`, jest-dom matcher reference
- [references/coverage-and-policy.md](references/coverage-and-policy.md) — coverage config, no snapshots, test failure triage
