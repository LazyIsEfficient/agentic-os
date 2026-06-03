---
name: content-ops
description: >-
  Score, evaluate, and iteratively improve any content or strategy using an
  auto-assembled panel of domain experts. Handles copy, sequences, landing pages,
  strategy docs, titles, charts, recruiting evaluations, or anything else that
  needs a quality gate. Recursively iterates until all scores hit 90+ (max 3
  rounds). Use when asked to: "expert panel this", "score this", "rate these
  variants", "quality check this", "panel review", "which version is better",
  "expert score", "evaluate this copy/strategy/page", or when another skill
  needs a quality gate on its output. Also triggers on: "score this landing page",
  "expert panel these email variants", "rate this headline", "panel these charts".
when_to_use: |
  Use when any content or strategy output needs a quality gate before publishing or handoff — scoring copy, landing pages, email sequences, strategy docs, charts, or candidate evaluations against an assembled panel of domain experts. Triggers on "expert panel this", "score this", "rate these variants", "quality check this", or when another skill (blog-post-author, course-author, outbound-engine) needs a final review gate.

  Not when: the goal is pre-launch variant generation and optimization through many rounds — use `autoresearch` instead. Not when the focus is conversion-specific auditing and CRO scoring of a URL — use `conversion-ops`.
---

# Expert Panel

General-purpose scoring and iterative improvement engine. Auto-assembles the right experts for whatever is being evaluated, scores it, and loops until 90+.

## Core rules

1. Intake: collect content, content type, offer context, variants, and source skill — full procedure in `references/procedure-steps.md` Step 1.
2. Auto-assemble 7–10 experts: start from `experts/` pre-built panels, add 1–3 domain experts, always include AI Writing Detector (1.5x weight) and Brand Voice Match.
3. Select scoring rubric from `scoring-rubrics/` by content type; read the file for criteria.
4. Score recursively until 90+ aggregate (max 3 rounds). Humanizer weighted 1.5x. Show all rounds in output — the iteration trail is the value.
5. Check `references/patterns.md` at every round start and dock points for known-bad patterns before expert scoring.
6. When scoring another skill's output, generate a Source Improvement Brief (Step 6).
7. On user rejection of 90+ content, capture the reason and append to `references/patterns.md`.

## References

- [references/procedure-steps.md](references/procedure-steps.md) — full 7-step procedure: intake, panel assembly, rubric selection, scoring loop, output format, feedback-to-source, pattern learning
- [references/expert-assembly.md](references/expert-assembly.md) — domain-expert examples for auto-assembly of unfamiliar panels
- [references/patterns.md](references/patterns.md) — learned rejection patterns; read every run
- [experts/humanizer.md](experts/humanizer.md) — AI writing detection rubric (24 patterns); always run
- [experts/](experts/) — pre-built panels: humanizer, instagram, linkedin, newsletter, podcast-quotes, recruiting, seo-strategy, x-articles, youtube-shorts
- [scoring-rubrics/](scoring-rubrics/) — content-quality, conversion-quality, evaluation-quality, strategic-quality, visual-quality
