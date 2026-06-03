---
name: incremental-implementation
description: Delivers changes incrementally. Use when implementing any feature or change that touches more than one file. Use when you're about to write a large amount of code at once, or when a task feels too big to land in one step.
when_to_use: |
  Use when implementing any multi-file change, building a new feature from a task breakdown, refactoring existing code, or any time you are tempted to write more than ~100 lines before testing. Use when a task feels too large to land in one step.

  Not when: the change is a single-file, single-function edit where the scope is already minimal — just implement it directly. Not when you need to break down the work into tasks first — use `planning-and-task-breakdown` before switching to this skill.
---

# Incremental Implementation

## Overview

Build in thin vertical slices — implement one piece, test it, verify it, then expand. Avoid implementing an entire feature in one pass. Each increment should leave the system in a working, testable state. This is the execution discipline that makes large features manageable.

## The Increment Cycle

For each slice: implement the smallest complete piece → test → verify (tests pass, build succeeds) → commit with a descriptive message → move to the next slice. See `git-workflow-and-versioning` for atomic commit guidance.

## Universal Rules

1. **Simplicity first.** Before writing any code, ask "what is the simplest thing that could work?"; implement the naive, obviously-correct version first.
2. **Scope discipline.** Touch only what the task requires; note out-of-scope observations rather than fixing them.
3. **One thing at a time.** Each increment changes one logical thing; mixed concerns are separate commits.
4. **Keep it compilable.** After each increment the project must build and all existing tests must pass.
5. **Feature flags for incomplete features.** If a feature isn't ready for users but you need to merge increments, gate it behind a flag set at creation time.
6. **Safe defaults.** New code defaults to conservative, opt-in behavior.
7. **Rollback-friendly.** Prefer additive changes; separate deletions from replacements across commits; database migrations need rollback migrations.

## References

- [references/slicing-strategies.md](references/slicing-strategies.md) — vertical slices, contract-first slicing, risk-first slicing with examples
- [references/implementation-rules.md](references/implementation-rules.md) — detailed rule explanations with code examples, simplicity checks, scope discipline template, feature flag pattern, agent-briefing template
- [references/rationalizations-and-red-flags.md](references/rationalizations-and-red-flags.md) — rationalization table and red-flag checklist

## Increment Checklist

After each increment, verify:

- [ ] The change does one thing and does it completely
- [ ] All existing tests still pass (`npm test`)
- [ ] The build succeeds (`npm run build`)
- [ ] Type checking passes (`npx tsc --noEmit`)
- [ ] Linting passes (`npm run lint`)
- [ ] The new functionality works as expected
- [ ] The change is committed with a descriptive message
