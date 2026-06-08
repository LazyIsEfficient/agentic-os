# Content Ops — Expert Panel

**Ship content that scores 90+ every time.**

An interactive Claude Code skill that auto-assembles a panel of 7–10 domain experts tailored to whatever you're scoring, grades it against a typed rubric, identifies weaknesses, revises, and loops until every expert scores 90+ (max 3 rounds). Includes a 1.5x-weighted AI Writing Detector that catches 24 known AI writing patterns.

Works on a single artifact at a time:
- Blog posts, social content, email sequences
- Landing-page drafts, ads, CTAs
- Strategy docs, pitch decks, charts
- Recruiting outreach, vendor evaluations
- Titles, headlines, variants to compare

This is a prompt-driven skill — there are no scripts to run. The full procedure lives in [SKILL.md](SKILL.md) and `references/`.

## How it works

1. **Intake** — collect the content, its type, offer context, any variants, and the source skill.
2. **Assemble** — pull pre-built panels from `experts/`, add 1–3 domain experts, always include the Humanizer (AI Writing Detector, 1.5x weight) and Brand Voice Match.
3. **Select rubric** — pick the matching file from `scoring-rubrics/` by content type.
4. **Score + iterate** — grade recursively until the aggregate hits 90+, showing every round (the iteration trail is the value).

## What's inside

Pre-built expert panels (`experts/`):
`humanizer` (mandatory, 24 patterns), `x-articles`, `linkedin`, `newsletter`, `youtube-shorts`, `instagram`, `podcast-quotes`, `recruiting`, `seo-strategy`.

Scoring rubrics (`scoring-rubrics/`):
`content-quality` (blog/social/email/scripts), `strategic-quality` (strategy & analysis), `conversion-quality` (landing pages, ads, CTAs), `visual-quality` (charts, infographics, slides), `evaluation-quality` (candidate/vendor evaluations).

References (`references/`):
`procedure-steps.md` (full 7-step procedure), `expert-assembly.md` (domain-expert examples), `patterns.md` (learned rejection patterns; read every run).

## Related skills

- [content-pipeline](../content-pipeline/SKILL.md) — script-driven content production (RSS quote mining, video-clip discovery, repurposing, batch draft gating). Its `content-transform` stage reuses this skill's `experts/` panels and `scoring-rubrics/content-quality.md` as its in-loop quality gate.
- [autoresearch](../autoresearch/SKILL.md) — pre-launch variant generation + multi-round optimization of conversion copy.
- [conversion-ops](../conversion-ops/SKILL.md) — post-publish conversion layer.
