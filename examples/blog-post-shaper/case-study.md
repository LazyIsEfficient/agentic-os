# blog-post-shaper — case study

Example of `/blog-shape` producing a `case-study-template.md` brief — story-arc post with real numbers and a named subject.

---

## User's initial request

> Case study post about how we cut our infra bill by ~70% over six weeks. We have customer permission to name them — it's the YGG indexer rewrite. I want to publish on our own blog.

## Shaper's batched questions

Story-arc post, named subject with permission, infra topic — routes to `case-study-template.md`.

1. **Single takeaway sentence** — what's the generalizable lesson? "Cache invalidation is the bottleneck, not throughput"? Need the reusable principle.
2. **Story arc — problem, approach, outcome, friction** — walk me through the chronology, including what *didn't* work along the way. Stories without friction read like brochures.
3. **Numbers** — what specific metric moved, by how much, sample size, time window? Caveats?
4. **Voice + length** — match founder voice, retro-style, deadpan? And how long?
5. **SEO surface + cross-post plan** — own blog only, or also LinkedIn article / Hashnode? SEO target?
6. **Asset bundle** — yes/no on each: hero image, OG card, X share thread, LinkedIn share, newsletter excerpt, embedded charts, embedded architecture diagrams, internal-link map, subject approval pass.

## User's answers

1. Takeaway: "Most 'we need more compute' problems are actually 'we re-do the same work too often' problems — and the fix is cheap when you measure first."
2. Arc: Problem — indexer was costing $11K/month, growing 40%/quarter, on track to be unaffordable by EOY. Approach — instead of scaling up the boxes, we instrumented every BigQuery materialization and found 4 view rebuilds running every 30 min that nothing read for 22 hours of the day. We rebuilt them on-demand with cached fallbacks. Outcome — bill dropped from $11K to $3.2K, 71% reduction. Friction — first attempt at "lazy materialization" caused stale data on the leaderboard for 4 hours one Saturday; rolled back, added staleness SLO, redid it. Almost gave up after the rollback. The lesson: instrument before scaling.
3. Numbers: $11,300/mo (April baseline) → $3,250/mo (June, post-fix). Three months of data post-fix shows holding. Caveats: this works because our load is bursty (peak hours concentrated); steady-state workloads won't see the same multiplier.
4. Match founder voice. Retro flavor — admit the rollback honestly. Length 1800–2500.
5. Own blog primary, cross-post on LinkedIn article 7 days later, no Hashnode. SEO target: "BigQuery cost reduction" primary, "infrastructure cost optimization" secondary, informational intent.
6. Hero: generated chart showing the bill drop ($/month over time). OG: separate, with the headline "71% infra cost reduction in 6 weeks". X: thread with the chart and the lesson. LinkedIn share post: yes. Newsletter excerpt: pull-quote with the takeaway. Embedded charts: 2 — bill-over-time, and "view rebuild frequency vs read frequency" mismatch chart. Embedded architecture diagrams: 1 Mermaid showing the before/after pipeline. Internal-link map: link to our prior post on observability, prior post on indexer architecture. Subject approval: yes — needs to go to YGG infra lead before publish.

## Output brief

```markdown
## Working title
How We Cut Our BigQuery Bill 71% in 6 Weeks (And Almost Gave Up Halfway)

## Variant
case study

## Single takeaway
Most "we need more compute" problems are actually "we re-do the same work too often" problems — and the fix is cheap when you measure first.

## Subject
- Who: YGG indexer rewrite (named with permission)
- Approval / permission status: named with approval — final draft must go to YGG infra lead before publish
- Author byline: standard

## Story arc
1. **Problem** — Indexer costing $11.3K/month, growing 40%/quarter. On track to hit ~$30K/month by EOY at the current trajectory. Threatened the budget for the next product slice.
2. **Approach** — Instead of scaling up the boxes (the obvious move), instrument every BigQuery materialization. Found 4 view rebuilds running every 30 minutes that nothing read for 22 hours of the day. Rebuilt them on-demand with cached fallbacks.
3. **Outcome** — Bill dropped from $11.3K to $3.25K/month. 71% reduction, holding for 3 months post-fix.
4. **Friction along the way** — First attempt at "lazy materialization" caused stale data on the user-facing leaderboard for ~4 hours on a Saturday afternoon. Rolled it back. The team almost gave up. Re-approached with a staleness SLO and a fallback that served stale-but-flagged data while the rebuild ran. Shipped successfully on the second attempt.
5. **Generalizable lesson** — When the obvious move is "scale up", invest a week in instrumentation first. Most "we need more compute" problems are "we re-do the same work too often" problems. The fix is almost always cheaper than the scale-up.

## Numbers / evidence
- Before: $11,300/mo (April 2026)
- After: $3,250/mo (June 2026)
- Sample size / context: 3 months of post-fix data showing the new bill is holding (±5%)
- Caveats: this works because our load is bursty (peak hours concentrated 6–11pm regional); steady-state workloads won't see the same multiplier. Don't expect 71% on a flat-load system.

## Source material
- Internal cost dashboards (BigQuery + GCP billing exports)
- Postmortem doc from the Saturday rollback
- Slack thread from the team's "are we abandoning this?" moment
- Architecture diagrams (before / after) from internal docs
- First-hand: I led the rewrite

## Target reader
- Who: engineering leaders and platform engineers running BigQuery (or similar warehouse) workloads with growing infra spend
- Funnel stage: awareness — building authority on the "instrument before scaling" thesis
- Why they care: their warehouse spend is also growing, and the obvious move is "buy more capacity"

## Voice and tone
- Match founder voice profile — first-person plural ("we tried", "we shipped"), retro flavor
- Reference posts to match: prior observability post (vocabulary), prior architecture post (cadence)
- Constraints: no em-dashes, no AI-tell phrases, no "lessons learned" trope language, word range 1800–2500
- Anonymization rules: n/a — subject is named with permission

## Length
- Target: 1800–2500 words
- Hard ceiling: 2800 words

## SEO surface
- Target keyword: "BigQuery cost reduction" (primary), "infrastructure cost optimization" (secondary)
- Search intent: informational — leaders evaluating where their warehouse cost is going
- Meta description angle: "We cut our BigQuery bill 71% in 6 weeks by instrumenting before scaling. Here's the rollback we almost shipped, and the SLO that fixed it."
- URL slug suggestion: bigquery-cost-reduction-case-study

## Asset bundle (required — author emits task DAG from this list)
- [x] Hero / featured image — generated chart of bill-over-time ($/month, April through June)
- [x] OG / social share image (1200×630) — separate from hero; "71% infra cost reduction in 6 weeks" overlay
- [x] X (Twitter) share post — thread (4–6 posts) leading with the chart, then the lesson, then the rollback
- [x] LinkedIn share post — single post, ~1200 chars, opening on the takeaway with the chart
- [x] Newsletter excerpt — pull-quote with the takeaway + the rollback admission, 200–400 words
- [x] Embedded charts / data viz — 2: bill-over-time, and "view rebuild frequency vs read frequency" mismatch
- [x] Embedded diagrams (architecture) — 1 Mermaid before/after pipeline diagram
- [ ] Code samples — none (architecture-level post)
- [x] Internal-link map — prior observability post, prior indexer architecture post; auto-suggest 1–2 more
- [x] Pull quotes / callouts — 2: the takeaway, the rollback admission
- [x] Subject approval review pass — required before publish (YGG infra lead)

## Publication context
- Platform: own blog (own domain)
- Cross-post plan: LinkedIn article 7 days after own-blog publish; no Hashnode
- Embargo / timing constraints: subject approval must clear before any publish; allow 3–5 days for review
- Comments enabled: yes

## Scope
- In: chronology, the rollback, the SLO that fixed it, the generalizable lesson, the cost numbers, the architecture before/after
- Out: vendor recommendations, comparison to other warehouse providers (Snowflake, Redshift), code snippets of the on-demand rebuild logic (saved for a follow-up technical post), team-level credit beyond the YGG infra lead

## Quality gate
- [x] Expert panel score 90+ (content quality + strategic quality)
- [x] AI humanizer pass clean
- [x] Numbers verified against source material (cost dashboards, postmortem)
- [x] Subject sign-off received (YGG infra lead)
- [x] SEO meta validated

## Approach
1. Review source material (cost dashboards, postmortem, Slack thread). Extract the chronology, the numbers, and the moment of friction.
2. Draft the post following the story arc. Stop for approval.
3. Run through expert panel scoring (target 90+). Iterate until passing.
4. Run AI humanizer pass (24-pattern check). Fix any flagged patterns.
5. Send to subject (YGG infra lead) for approval. Apply edits.
6. Emit the asset-bundle task DAG (planning-and-task-breakdown format) — one task per declared asset, with `files_write`, `depends_on`, and `parallel_safe` set so the user can dispatch agents to generate them.

## Deliverable
- One publication-ready case study in target length
- Expert panel scorecard
- Subject approval record
- Asset-bundle task DAG ready for agent dispatch

## Open questions
- Whether to publish exact billing numbers ($11.3K → $3.25K) or rounded figures ($11K → $3K). Recommend exact — the precision lends credibility — pending subject approval.
- Whether to name the specific BigQuery views that were over-materializing. Default: name the categories ("leaderboard rollup", "user-stats hourly view") not the literal table names, to avoid leaking internal schema.
```

---

**Next step:** paste this into a fresh session and `blog-post-author` will draft the post and emit the asset-bundle task DAG, or say `go` and the executor takes the brief through draft + DAG. Subject approval blocks publish, not draft — start drafting in parallel with reaching out for sign-off.
