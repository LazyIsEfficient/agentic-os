# marketing-shaper — research

Example of `/mshape` producing a `research-template.md` brief — a question to answer, no deliverables produced.

---

## User's initial request

> Need to know what content the top three competitors are publishing that's actually working. We've been guessing on topics for months and I want a data-backed list before we plan Q4.

## Shaper's batched questions

Question to answer, no campaign work — routes to `research-template.md`.

1. **Sharpen the question** — "what's working" can mean traffic, engagement, ranking, lead capture. Which definition?
2. **Three competitors — names?** Or do you want me to pick based on a definition (e.g. top three by SEO overlap)?
3. **What decision does this answer unblock?** Q4 content calendar, or something earlier (like a Q3 catch-up push)?
4. **Channels in scope** — blog only, or also LinkedIn, X, YouTube, podcasts, newsletter?
5. **What you already know / suspect** — any working hypotheses to test or rule out?
6. **Depth budget** — quick scan (a day), medium (2–3 days), thorough (a week)?

## User's answers

1. "Working" = ranking on first page for commercial-intent keywords, AND/OR generating measurable inbound (signals: high-engagement comments, syndication, guest references). Not raw traffic.
2. `competitor-a.com`, `competitor-b.com`, `competitor-c.com` — explicit list.
3. Q4 content calendar planning starts in 3 weeks.
4. Blog (primary), LinkedIn (secondary). Skip X, YouTube, podcasts.
5. Hypothesis: competitors A and B are winning with comparison content ("X vs. Y") and we're underweight on it. Want to verify or kill that hypothesis.
6. Medium — 2–3 days.

## Output brief

```markdown
## Question
Across `competitor-a.com`, `competitor-b.com`, `competitor-c.com`, which blog and LinkedIn pieces are actually working — defined as (a) ranking on page-one for commercial-intent keywords and/or (b) generating measurable inbound signal (high-engagement comments, syndication, guest references) — and what topical/format patterns connect the winners?

## Why it matters
Q4 content calendar planning starts in 3 weeks. We've been picking topics on instinct for months and the team wants a data-backed shortlist before committing the quarter.

## Scope
- Channels / competitors / data sources in play:
  - Blog (primary): `competitor-a.com/blog`, `competitor-b.com/blog`, `competitor-c.com/blog`
  - LinkedIn (secondary): company pages + top 2 named-author profiles per competitor
  - Tooling: Ahrefs/SEMrush for SERP positions and traffic estimates, LinkedIn for engagement counts
- Out of scope: X, YouTube, podcasts, paid content, gated content (we can't measure it externally), competitors outside the named three.

## What I already know / suspect
- Hypothesis to verify or kill: competitors A and B are winning with comparison content ("X vs. Y", "best Z for ABC") and we're underweight on that format.
- Competitor C has more posts but less SEO presence — suspect engagement-driven (LinkedIn) rather than search-driven.
- We do not currently rank on any of the top 20 commercial-intent keywords in our category.

## Deliverable
A written report with: findings, evidence (data sources, screenshots, links), confidence level, and recommended next action. **No content creation or campaign work** unless explicitly approved after the report.

The report should answer:
- Top 10 winning posts per competitor by the "working" definition above. Include URL, target keyword(s), SERP position, estimated traffic, and engagement proxy.
- Format breakdown: how much of the winners are comparison vs. how-to vs. listicle vs. opinion vs. case study?
- Topic clusters: which keyword families do winners concentrate around?
- Whitespace: which winning patterns we are *not* attempting today.
- Evidence on the comparison-content hypothesis — true, false, or partial?
- Top 5 recommended bets for Q4 calendar with rationale.

## Depth budget
medium — 2–3 days of analyst time, not a full SEO audit.
```

---

**Next step:** paste this into a fresh session, or say `go` and the executor produces the report. No campaign work happens unless explicitly approved after.
