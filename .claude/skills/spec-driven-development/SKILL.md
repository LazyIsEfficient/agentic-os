---
name: spec-driven-development
description: Creates a written, human-approved specification before any implementation begins, then drives a four-phase gated workflow (Specify → Plan → Tasks → Implement). Use when no spec exists yet and requirements are ambiguous, incomplete, or only a vague idea. Distinct from incremental-implementation (which executes an already-planned change in slices) and planning-and-task-breakdown (which decomposes an existing spec into a parallel task DAG) — reach for spec-driven-development when the question is still "what are we even building?" not "how do I build/break down this known thing?"
when_to_use: |
  Use when starting a new project or feature with no existing specification,
  requirements are ambiguous or incomplete, the change touches multiple files or
  modules, an architectural decision is about to be made, or the task would take
  more than 30 minutes to implement. Runs a four-phase gated workflow: Specify →
  Plan → Tasks → Implement, with human review between each phase.

  Not when: the task is a single-line fix, typo correction, or unambiguous
  self-contained change. Not when a spec already exists and you only need to break
  it into a parallel-runnable task DAG — use [planning-and-task-breakdown](../planning-and-task-breakdown/SKILL.md).
  Not when the plan is already settled and you just need to execute it in safe
  slices — use [incremental-implementation](../incremental-implementation/SKILL.md).
  The discriminator: spec-driven-development owns the "we don't yet know what to
  build" phase; the other two own decomposition and execution of a known thing.
---

# Spec-Driven Development

## Overview

Write a structured specification before writing any code. The spec is the shared source of truth between you and the human engineer — it defines what we're building, why, and how we'll know it's done. Code without a spec is guessing.

## Universal Rules

1. **Specify before implementing.** No code until there is a written, human-approved spec.
2. **Surface assumptions immediately.** List every assumption before writing spec content. Let the human correct you before code is written.
3. **Gate each phase.** Do not advance from Specify → Plan → Tasks → Implement without human review at each boundary.
4. **Reframe vague requirements as testable success criteria.** "Make it faster" must become concrete metrics (e.g. "LCP < 2.5s on 4G") before proceeding.
5. **Commit the spec.** The spec belongs in version control alongside the code. Update it when decisions or scope change.
6. **Reference the spec in PRs.** Each PR links back to the spec section it implements.

## The four-phase gated workflow

```
SPECIFY ──→ PLAN ──→ TASKS ──→ IMPLEMENT
   │          │        │          │
   ▼          ▼        ▼          ▼
 Human      Human    Human      Human
 reviews    reviews  reviews    reviews
```

**Phase 1 — Specify.** Start from the high-level vision. First, list your assumptions explicitly (`ASSUMPTIONS I'M MAKING: …` → "correct me now or I'll proceed") — never silently fill ambiguity, because assumptions are the most dangerous misunderstandings. Then ask clarifying questions until requirements are concrete, and write a spec document covering the six core areas (below). Reframe every vague instruction into a measurable success criterion.

**Phase 2 — Plan.** Turn the validated spec into a technical plan: major components and their dependencies, implementation order (what must exist first), risks and mitigations, what can go parallel vs. sequential, and verification checkpoints. The plan must be reviewable — the human should be able to say "yes, that approach" or "no, change X."

**Phase 3 — Tasks.** Break the plan into discrete tasks, each completable in one focused session, each with explicit acceptance criteria and a verification step (test/build/manual check), each touching no more than ~5 files. Order by dependency, not perceived importance.

**Phase 4 — Implement.** Execute tasks one at a time. Hand off to `incremental-implementation` and `test-driven-development` for the actual coding, and use `context-engineering` to load only the relevant spec section and source files per step rather than flooding the agent with the whole spec.

The spec is **living**: when a decision or the scope changes, update the spec first, then the code.

## The six core areas every spec must cover

1. **Objective** — what we're building and why; who the user is; what success looks like.
2. **Commands** — full executable commands with flags (`npm test -- --coverage`), not just tool names.
3. **Project structure** — where source, tests, and docs live.
4. **Code style** — one real snippet beats three paragraphs; include naming and formatting conventions.
5. **Testing strategy** — framework, where tests live, coverage expectations, which test level for which concern.
6. **Boundaries** — three tiers: **Always** (run tests before commit, validate inputs), **Ask first** (schema changes, new dependencies, CI config), **Never** (commit secrets, edit vendor dirs, delete failing tests unapproved).

The full spec template, task template, and worked assumption/reframing examples live in [references/gated-workflow.md](references/gated-workflow.md).

## Red Flags

- Starting to write code without any written requirements
- Asking "should I just start building?" before clarifying what "done" means
- Implementing features not mentioned in any spec or task list
- Making architectural decisions without documenting them
- Skipping the spec because "it's obvious what to build"

## Verification

Before proceeding to implementation, confirm:

- [ ] The spec covers all six core areas: objective, commands, project structure, code style, testing strategy, boundaries (defined above)
- [ ] The human has reviewed and approved the spec
- [ ] Success criteria are specific and testable
- [ ] Boundaries (Always / Ask first / Never) are defined
- [ ] The spec is saved to a file in the repository

## See Also

- [planning-and-task-breakdown](../planning-and-task-breakdown/SKILL.md) — use after Phase 3 (Tasks) to turn the task list into a parallel-dispatchable execution DAG.
- [incremental-implementation](../incremental-implementation/SKILL.md) — use during Phase 4 (Implement) to execute each task in safe vertical slices.
- [test-driven-development](../test-driven-development/SKILL.md) — use during Phase 4 alongside incremental-implementation to drive each task red-green-refactor.
- [context-engineering](../context-engineering/SKILL.md) — use during Phase 4 to keep agent context scoped to the relevant spec section instead of the whole document.
