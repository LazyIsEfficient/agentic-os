---
name: using-agent-skills
description: Entry point when no skill is already identified — use when the task spans multiple lifecycle phases (discover → spec → implement → test → ship) or when starting a session with no clear skill match. Not when a specific skill is already known — go straight to it. Not when the task clearly maps to a single skill.
when_to_use: |
  Use as the router of last resort: the user has work to do but no skill is obviously the match, and you need a procedure to pick one. Concretely — a session opens with an ambiguous ask, two or more skills look equally plausible, or a task clearly spans several phases (discovery → spec → implement → test → ship) and you need to decide what to load first.

  Prefer prompt-shaper over this skill when the task is an engineering request with a defined goal that is merely under-specified (missing repos, "done" criteria, or constraints) — that is a scoping job, not a routing job. Use this skill only when the task *type itself* is unknown. For marketing intake use marketing-shaper; course intake course-shaper; game-design intake game-design-shaper.

  Not when: a specific skill is already identified and loaded — go straight to it. Not when the task clearly maps to one skill (a bug fix → debugging-and-error-recovery; a component test → typescript-testing-frontend). Not when a multi-phase effort needs an execution plan with task ordering and dependencies — route once to planning-and-task-breakdown and hand off; do not keep orchestrating from here.
---

# Using Agent Skills

This is a meta-skill: it does not do engineering work, it routes you to the skill that does. Its job is to turn "I'm not sure which skill applies" into a loaded skill — fast, and without guessing. The catalog of skills lives in the dispatch matrix; this skill is the procedure for reading it.

## Routing process

Run these steps in order. Stop as soon as a skill is selected.

1. **Read the signal.** Identify the development phase from what the user said: are they refining an idea, defining requirements, planning, building, testing, debugging, reviewing, or shipping? If the phase is unclear, ask **one** scoping question before routing — e.g. *"Is there already a spec for this, or are we still defining what to build?"* Do not ask more than one; route on the answer.

2. **Consult the dispatch matrix.** Map the phase to a candidate skill using the discovery tree and quick-reference table:
   - [references/skill-dispatch-matrix.md](references/skill-dispatch-matrix.md) — discovery tree, lifecycle sequence, and phase → skill quick reference.

3. **Resolve ambiguity if two skills tie.** Apply, in order:
   - **Most specific wins.** A skill scoped to the exact artifact beats a general one (a React component test → typescript-testing-frontend, not the generic test skill).
   - **Earliest unmet phase wins.** If the work needs a spec it doesn't have, start at the spec phase, not at implementation — you cannot build what isn't defined.
   - **Honor "Not when" clauses.** Each candidate skill's frontmatter names what it defers to. If a candidate explicitly defers your case elsewhere, follow that pointer.
   - **Engineering request that's just under-specified → [prompt-shaper](../prompt-shaper/SKILL.md)**, not this skill. Routing is for unknown task *type*; shaping is for known goal, unclear scope.

4. **Load the selected skill and hand off.** Invoke the target skill and follow its process. **Stop acting as router** — this skill's job ends at selection. Do not keep narrating routing decisions once a skill is loaded.

## Multi-phase work

When the task plainly spans several phases (e.g. idea-refine → [spec-driven-development](../spec-driven-development/SKILL.md) → [planning-and-task-breakdown](../planning-and-task-breakdown/SKILL.md) → [incremental-implementation](../incremental-implementation/SKILL.md) → [test-driven-development](../test-driven-development/SKILL.md) → [code-review-and-quality](../code-review-and-quality/SKILL.md) → [shipping-and-launch](../shipping-and-launch/SKILL.md)), do **not** try to run the whole chain from here. Route to the first unmet phase. Once there is a spec, hand sequencing and task ordering to [planning-and-task-breakdown](../planning-and-task-breakdown/SKILL.md) — that skill owns the execution DAG; this one only finds the on-ramp.

## Core operating behaviors

These apply across every skill you route to, not just this one:

- [references/core-operating-behaviors.md](references/core-operating-behaviors.md) — surface assumptions, manage confusion, push back, enforce simplicity, hold scope, verify before done.

## When the matrix still leaves it unclear

If, after step 3, no single skill fits — the work is genuinely cross-cutting or novel — default to [spec-driven-development](../spec-driven-development/SKILL.md): writing down requirements and acceptance criteria is the safest first move for non-trivial, unscoped work, and the resulting spec usually makes the next skill obvious.

## Related skills

- [skill-library-review](../skill-library-review/SKILL.md) — audits and maintains the health of the skill library this meta-skill routes against; keeps descriptions and cross-references coherent so discovery works.
