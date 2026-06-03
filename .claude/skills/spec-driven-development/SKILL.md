---
name: spec-driven-development
description: Creates specs before coding. Use when starting a new project, feature, or significant change and no specification exists yet. Use when requirements are unclear, ambiguous, or only exist as a vague idea.
when_to_use: |
  Use when starting a new project or feature with no existing specification,
  requirements are ambiguous or incomplete, the change touches multiple files or
  modules, an architectural decision is about to be made, or the task would take
  more than 30 minutes to implement. Runs a four-phase gated workflow: Specify →
  Plan → Tasks → Implement, with human review between each phase.

  Not when: the task is a single-line fix, typo correction, or unambiguous
  self-contained change. For breaking an existing spec into a parallel-runnable
  task DAG use planning-and-task-breakdown.
---

# Spec-Driven Development

## Overview

Write a structured specification before writing any code. The spec is the shared source of truth between you and the human engineer — it defines what we're building, why, and how we'll know it's done. Code without a spec is guessing.

## Universal Rules

1. **Specify before implementing.** No code until there is a written, human-approved spec.
2. **Surface assumptions immediately.** List every assumption before writing spec content. Let the human correct you before code is written.
3. **Gate each phase.** Do not advance from Specify → Plan → Tasks → Implement without human review at each boundary.
4. **Reframe vague requirements as testable success criteria.** "Make it faster" must become concrete metrics before proceeding.
5. **Commit the spec.** The spec belongs in version control alongside the code. Update it when decisions or scope change.
6. **Reference the spec in PRs.** Each PR links back to the spec section it implements.

## Red Flags

- Starting to write code without any written requirements
- Asking "should I just start building?" before clarifying what "done" means
- Implementing features not mentioned in any spec or task list
- Making architectural decisions without documenting them
- Skipping the spec because "it's obvious what to build"

## Verification

Before proceeding to implementation, confirm:

- [ ] The spec covers all six core areas (objective, commands, structure, style, testing, boundaries)
- [ ] The human has reviewed and approved the spec
- [ ] Success criteria are specific and testable
- [ ] Boundaries (Always/Ask First/Never) are defined
- [ ] The spec is saved to a file in the repository

## References

- [references/gated-workflow.md](references/gated-workflow.md) — Four-phase workflow detail, spec template, task template, assumption surfacing, keeping the spec alive
