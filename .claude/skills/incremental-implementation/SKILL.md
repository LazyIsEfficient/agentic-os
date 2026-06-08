---
name: incremental-implementation
description: Execution discipline for shipping large changes in safe, testable vertical slices — implement one increment, test, commit, repeat. Use for the implementation phase of any multi-file change, especially after the work has been decomposed into tasks. For breaking work into tasks first see planning-and-task-breakdown; for pure complexity reduction of working code see code-simplification.
when_to_use: |
  Use when implementing any multi-file change, building a new feature from a task breakdown, restructuring code as part of delivering a change, or any time you are tempted to write more than ~100 lines before testing. Use when a task feels too large to land in one step. This is the *execution* phase — a single task or change, built in slices.

  Not when: the change is a single-file, single-function edit where the scope is already minimal — just implement it directly. Not when you still need to *decompose* the work into an ordered task list — use [planning-and-task-breakdown](../planning-and-task-breakdown/SKILL.md) first, then return here to execute each task. Not when no spec exists yet and requirements are ambiguous — use [spec-driven-development](../spec-driven-development/SKILL.md) to produce the spec first, then return to execute. Not when the goal is reducing complexity in already-working code without adding features or fixing bugs — use [code-simplification](../code-simplification/SKILL.md) for that.
---

# Incremental Implementation

## Overview

Build in thin vertical slices — implement one piece, test it, verify it, then expand. Avoid implementing an entire feature in one pass. Each increment should leave the system in a working, testable state. This is the execution discipline that makes large features manageable.

## The Increment Cycle

For each slice: implement the smallest complete piece → test → verify (tests pass, build succeeds) → commit with a descriptive message → move to the next slice. See [git-workflow-and-versioning](../git-workflow-and-versioning/SKILL.md) for atomic commit guidance.

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
- [ ] All existing tests still pass (run the project's test command)
- [ ] The build succeeds (run the project's build command)
- [ ] Static analysis passes (type check / lint / compile, as the project provides)
- [ ] The new functionality works as expected
- [ ] The change is committed with a descriptive message
