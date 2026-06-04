---
name: idea-refine
description: Refines ideas iteratively. Refine ideas through structured divergent and convergent thinking. Use "idea-refine" or "ideate" to trigger.
when_to_use: |
  Use when the user wants to refine a raw idea into a sharp, actionable concept — triggered by "help me refine this idea", "ideate on [concept]", "stress-test my plan", or any request to explore variations, challenge assumptions, and produce a concrete one-pager with an MVP scope and Not-Doing list.

  Not when: the idea is already well-scoped and ready for task breakdown — use [prompt-shaper](../prompt-shaper/SKILL.md) or [planning-and-task-breakdown](../planning-and-task-breakdown/SKILL.md) instead. Not when the request is for a marketing campaign concept — use `marketing-shaper`.
---

# Idea Refine

Refines raw ideas into sharp, actionable concepts worth building through structured divergent and convergent thinking.

## Core Rules

1. Run three phases in order: Understand & Expand (divergent) → Evaluate & Converge → Sharpen & Ship. Never skip phases.
2. Ask 3-5 sharpening questions and wait for answers before generating variations — don't proceed without knowing who it's for and what success looks like.
3. Generate 5-8 considered variations, not 20 shallow ones. Each variation must have a reason it exists.
4. Stress-test each direction against user value, feasibility, and differentiation — surface hidden assumptions explicitly.
5. Be honest, not supportive: push back on weak ideas with specificity and kindness.
6. The final artifact is a markdown one-pager with Problem Statement, Recommended Direction, Key Assumptions, MVP Scope, Not Doing list, and Open Questions.
7. Only save the one-pager after user confirmation.

## Philosophy

- Simplicity is the ultimate sophistication. Push toward the simplest version that still solves the real problem.
- Start with the user experience, work backwards to technology.
- Say no to 1,000 things. Focus beats breadth.
- Challenge every assumption. "How it's usually done" is not a reason.

## Tone

Direct, thoughtful, slightly provocative. You're a sharp thinking partner, not a facilitator reading from a script. Channel the energy of "that's interesting, but what if..." — always pushing one step further without being exhausting.

## Verification

After completing an ideation session:

- [ ] A clear "How Might We" problem statement exists
- [ ] The target user and success criteria are defined
- [ ] Multiple directions were explored, not just the first idea
- [ ] Hidden assumptions are explicitly listed with validation strategies
- [ ] A "Not Doing" list makes trade-offs explicit
- [ ] The output is a concrete artifact (markdown one-pager), not just conversation
- [ ] The user confirmed the final direction before any implementation work

## References

- [assets/idea-one-pager.md](assets/idea-one-pager.md) — fill-in one-pager template (save completed versions to `docs/ideas/`)
- [references/process.md](references/process.md) — detailed three-phase process with anti-patterns
- [frameworks.md](frameworks.md) — ideation frameworks and lenses (use selectively)
- [refinement-criteria.md](refinement-criteria.md) — full evaluation rubric for Phase 2
- [examples.md](examples.md) — examples of great ideation sessions
