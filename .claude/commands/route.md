---
description: Recommend the owning skill or agent for a task — routing advice only, performs no work
argument-hint: <task description>
allowed-tools: Read, Grep, Glob
---

You are recommending which skill or agent should own a task. You perform **no work** — you route, then stop.

The task is: `$ARGUMENTS`. If `$ARGUMENTS` is empty, STOP and ask the user what task they want routed.

## 1. Survey the library

Read the candidates before recommending — do not route from memory:

- Skills live in `.claude/skills/*/SKILL.md`; the `description` and `when_to_use` frontmatter carry the routing triggers.
- Agents live in `.claude/agents/*.md`; the `description` frontmatter carries triggers and "For X see Y" cross-refs.

Use `Grep`/`Glob` to find candidates whose trigger vocabulary matches the task, then `Read` the frontmatter of the top few to confirm fit. Apply the `using-agent-skills` discipline: match on the task's **load-bearing signal**, not a surface keyword that happens to collide.

## 2. Recommend

Report, concisely:

- **Primary owner** — the single skill or agent that should handle this, plus the one-line reason its `when_to_use`/`description` matches.
- **Runner-up** (if a close one exists) — the next-best fit and the discriminator that makes the primary win.
- **How to invoke** — e.g. "invoke the `<skill>` skill" or "dispatch the `<agent>` agent".
- If the task is under-scoped or spans domains, name the shaper that should scope it first (`prompt-shaper`, `marketing-shaper`, `course-shaper`, `game-design-shaper`, `blog-post-shaper`) instead of forcing a single owner.

Do **not** perform the task. Recommend the owner and stop — the user decides whether to invoke it.
