---
name: test-driven-development
description: Enforces the red-green-refactor cycle — a failing test must exist before any implementation. Use when implementing new behavior or fixing a bug whose expected behavior is known and you need to prove the code is correct, not just "seems right." For layer-specific React or backend tests see typescript-testing-frontend or typescript-testing-backend; for diagnosing an unknown failure first see debugging-and-error-recovery.
when_to_use: |
  Use when implementing any new logic or behavior, fixing any bug (write the reproduction test first), modifying existing functionality, adding edge case handling, or any change that could break existing behavior. The red-green-refactor cycle applies to all behavioral code changes.

  Not when: the change is pure configuration, documentation updates, or static content with no behavioral impact. Not when the cause of a failure is still unknown and needs diagnosis — use debugging-and-error-recovery to find the root cause first, then return here to write the reproduction test. Not when the task is establishing cross-cutting test strategy, E2E flows, or CI test configuration — use typescript-quality-engineering. Not when writing layer-specific tests for React components or backend services — use typescript-testing-frontend or typescript-testing-backend respectively.
---

# Test-Driven Development

## Overview

Write a failing test before writing the code that makes it pass. For bug fixes, reproduce the bug with a test before attempting a fix. Tests are proof — "seems right" is not done. A codebase with good tests is an AI agent's superpower; a codebase without tests is a liability.

## Universal Rules

1. **Red first.** Every new behavior starts with a failing test. A test that passes on the first run proves nothing.
2. **Prove-It for bugs.** Never fix a bug without first writing a test that reproduces it. The test must fail before the fix and pass after.
3. **Test state, not interactions.** Assert on outcomes, not on which internal methods were called.
4. **DAMP over DRY.** Each test tells a complete story. Duplication in tests is acceptable when it improves readability.
5. **Prefer real implementations.** Use real code > fakes > stubs > mocks. Mock only at boundaries where real dependencies are slow or non-deterministic.
6. **One assertion per concept.** Each test verifies one behavior. Split tests rather than stacking assertions.
7. **Name tests descriptively.** Test names are the specification. They should read as: "it [does X] when [condition Y]."
8. **Browser changes need runtime verification.** Unit tests alone are not enough for browser code — verify in a real browser with DevTools.

## Red Flags

- Writing code without any corresponding tests
- Tests that pass on the first run (they may not be testing what you think)
- Bug fixes without reproduction tests
- Tests that test framework behavior instead of application behavior
- Test names that don't describe the expected behavior
- Skipping tests to make the suite pass

## Verification

After completing any implementation:

- [ ] Every new behavior has a corresponding test
- [ ] All tests pass (run the project's test command, e.g. `npm test` / `go test ./...` / `pytest` / `cargo test`)
- [ ] Bug fixes include a reproduction test that failed before the fix
- [ ] Test names describe the behavior being verified
- [ ] No tests were skipped or disabled
- [ ] Coverage hasn't decreased (if tracked)

## References

- [references/tdd-cycle.md](references/tdd-cycle.md) — Red-Green-Refactor steps, Prove-It Pattern for bugs, Test Pyramid and test size classification
- [references/writing-good-tests.md](references/writing-good-tests.md) — State vs interaction testing, DAMP, AAA pattern, naming, anti-patterns table
- [references/browser-testing.md](references/browser-testing.md) — DevTools debugging workflow, what to check, security boundaries, subagent pattern

## Related skills

- [typescript-testing-backend](../typescript-testing-backend/SKILL.md) — TypeScript/Node backend test specialization
- [typescript-testing-frontend](../typescript-testing-frontend/SKILL.md) — React/browser frontend test specialization
- [rust-engineer](../rust-engineer/SKILL.md) — red-green-refactor applies in Rust; the borrow checker rewards test-first interface clarity
- [typescript-quality-engineering](../typescript-quality-engineering/SKILL.md) — linting, coverage, CI quality gates
- [code-review-and-quality](../code-review-and-quality/SKILL.md) — review discipline; TDD feeds into the review gate
