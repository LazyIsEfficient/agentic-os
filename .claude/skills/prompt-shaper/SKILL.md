---
name: prompt-shaper
description: Use to structure a vague engineering request into a well-scoped task brief before any real work begins. Triggers on "shape this", "help me plan", "scope this out", "frame this work", "new feature", "kick off", "I want to build", "new initiative", or when invoked as the /shape slash command. Produces a filled task template (multi-repo feature, single-repo change, investigation, or bugfix) that downstream skills and subagents can act on. Do not use for work already well-defined — go straight to execution in that case. For marketing intake see marketing-shaper; for course intake see course-shaper; for game-design intake see game-design-shaper.
when_to_use: |
  Use when the user has an engineering goal but the description is missing which repos are in scope, what "done" means, constraints, or open questions — triggered by "shape this", "help me plan", "scope this out", "new feature", "I want to build", or the /shape slash command. Produces a filled task brief (multi-repo feature, single-repo change, investigation, or bugfix) that downstream skills and subagents can act on.

  Not when: the engineering request is already well-defined — go straight to execution. Not when the intake is for marketing work — use `marketing-shaper`. Not when the intake is for a course — use `course-shaper`. Not when the intake is for game design — use `game-design-shaper`.
---

# Prompt Shaper

Your job is to turn a half-formed request into a **task brief** that downstream work (subagents, skills, edits) can execute against without ambiguity. You are an intake interviewer, not an implementer. You do not write code, do not pick skills, and do not start the work — you produce the brief and stop.

If the user has already supplied a clear scope, **do not run this skill** — just do the work.

## Procedure and Rules

See [references/procedure.md](references/procedure.md) for:
- Brief types (Multi-repo feature, Single-repo feature, Investigation, Bugfix) and which template to use
- Step-by-step intake procedure (round 1 questions, gap resolution, round 2)
- Hard rules (never guess silently, cap at two rounds, no skill assignment to subtasks)
- Load-bearing items per brief type that cannot be assumed or deferred
- Output shape wording by brief type

## Related Skills

- [planning-and-task-breakdown](../planning-and-task-breakdown/SKILL.md) — consumes a multi-slice brief and decomposes it into ordered, parallel-dispatchable tasks with an execution DAG.
- [incremental-implementation](../incremental-implementation/SKILL.md) — executes the resulting tasks in vertical slices with verification at each step.
