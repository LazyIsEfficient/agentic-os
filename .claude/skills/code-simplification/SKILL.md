---
name: code-simplification
description: Simplifies code for clarity. Use when refactoring code for clarity without changing behavior. Use when code works but is harder to read, maintain, or extend than it should be. Use when reviewing code that has accumulated unnecessary complexity.
when_to_use: |
  Use after a feature is working and tests pass but the implementation is heavier than it needs to be — deeply nested logic, long functions, unclear names, duplication, or over-engineered abstractions. Also use during code review when readability or complexity issues are flagged.

  Not when: you don't yet understand what the code does (comprehend first), the code is performance-critical and simplification would measurably slow it, or you're about to rewrite the module entirely. Not when correctness bugs also need fixing — use [code-review-and-quality](../code-review-and-quality/SKILL.md) for that.
---

# Code Simplification

> Inspired by the [Claude Code Simplifier plugin](https://github.com/anthropics/claude-plugins-official/blob/main/plugins/code-simplifier/agents/code-simplifier.md). Adapted here as a model-agnostic, process-driven skill for any AI coding agent.

## Overview

Simplify code by reducing complexity while preserving exact behavior. The goal is not fewer lines — it's code that is easier to read, understand, modify, and debug. Every simplification must pass a simple test: "Would a new team member understand this faster than the original?"

## Universal Rules

1. **Understand before touching.** Apply Chesterton's Fence: understand why code exists before changing it. If you can't explain it, read more context first.
2. **Preserve behavior exactly.** Every input, output, side effect, error path, and edge case must remain identical. If you're uncertain, don't simplify.
3. **Follow project conventions.** Match the codebase's existing patterns. Imposing external style preferences is churn, not simplification.
4. **Prefer clarity over cleverness.** Explicit code beats compact code when the compact version requires a mental pause to parse.
5. **Scope to what changed.** Default to simplifying recently modified code only. Drive-by refactors create noisy diffs and risk regressions.
6. **One change at a time.** Make one simplification, run tests, commit. Batch simplifications hide which change caused a failure.
7. **Submit refactoring separately.** A PR that refactors and adds features is two PRs — split them.

## Red Flags

- Simplification that requires modifying tests to pass (you likely changed behavior)
- "Simplified" code that is longer and harder to follow than the original
- Renaming things to match your preferences rather than project conventions
- Removing error handling because "it makes the code cleaner"
- Simplifying code you don't fully understand
- Batching many simplifications into one large, hard-to-review commit
- Refactoring code outside the scope of the current task without being asked

## Verification

After completing a simplification pass:

- [ ] All existing tests pass without modification
- [ ] Build succeeds with no new warnings
- [ ] Linter/formatter passes (no style regressions)
- [ ] Each simplification is a reviewable, incremental change
- [ ] The diff is clean — no unrelated changes mixed in
- [ ] Simplified code follows project conventions (checked against CLAUDE.md or equivalent)
- [ ] No error handling was removed or weakened
- [ ] No dead code was left behind (unused imports, unreachable branches)
- [ ] A teammate or review agent would approve the change as a net improvement

## References

- [references/simplification-principles.md](references/simplification-principles.md) — Five principles: preserve behavior, follow conventions, clarity over cleverness, balance, scope discipline
- [references/simplification-patterns.md](references/simplification-patterns.md) — Four-step process, pattern tables (structural/naming/redundancy), language-specific examples (TS, Python, React)
