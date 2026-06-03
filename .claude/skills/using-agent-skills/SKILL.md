---
name: using-agent-skills
description: Discovers and invokes agent skills. Use when starting a session or when you need to discover which skill applies to the current task. This is the meta-skill that governs how all other skills are discovered and invoked.
when_to_use: |
  Use when starting a new session with an unfamiliar task, when uncertain which skill applies to the current work, or when a task spans multiple phases (discovery → spec → implementation → test → ship) and a routing decision is needed. This is the entry point for skill selection when no other skill is already clearly applicable.

  Not when: a specific skill has already been identified and loaded — go straight to that skill. Not when the task is well-scoped and clearly maps to a single skill (e.g., a bug fix maps directly to debugging-and-error-recovery, a component test to typescript-testing-frontend).
---

# Using Agent Skills

## Overview

Agent Skills is a collection of engineering workflow skills organized by development phase. Each skill encodes a specific process that senior engineers follow. This meta-skill helps you discover and apply the right skill for your current task.

## Skill Discovery

See the full dispatch tree, lifecycle sequence, and quick-reference table:

- [references/skill-dispatch-matrix.md](references/skill-dispatch-matrix.md) — discovery tree, lifecycle sequence, and phase → skill quick reference

## Core Operating Behaviors

Non-negotiable behaviors that apply at all times, across all skills:

- [references/core-operating-behaviors.md](references/core-operating-behaviors.md) — surface assumptions, manage confusion, push back, enforce simplicity, scope discipline, verify

## Skill Rules

1. **Check for an applicable skill before starting work.** Skills encode processes that prevent common mistakes.

2. **Skills are workflows, not suggestions.** Follow the steps in order. Don't skip verification steps.

3. **Multiple skills can apply.** A feature implementation might involve `idea-refine` → `spec-driven-development` → `planning-and-task-breakdown` → `incremental-implementation` → `test-driven-development` → `code-review-and-quality` → `shipping-and-launch` in sequence.

4. **When in doubt, start with a spec.** If the task is non-trivial and there's no spec, begin with `spec-driven-development`.
