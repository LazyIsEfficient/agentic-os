# marketing-shaper — optimization

Example of `/mshape` producing an `optimization-template.md` brief — improving something that already exists.

---

## User's initial request

> The pricing page converts at like 1.4%. Industry average is 4–6%. I want to figure out what's wrong and run a test.

## Shaper's batched questions

Specific underperforming asset, clear baseline, "run a test" — routes to `optimization-template.md`.

1. **URL of the page?** And what counts as a conversion — sign-up, demo request, purchase?
2. **Audience** — who lands here? Cold traffic from ads, organic search, intent-rich (clicked through "Pricing" from the nav)?
3. **What we've already tried** — any prior tests, audits, or copy changes?
4. **Available data** — analytics, heatmaps, session recordings, sales-call snippets?
5. **Scope of the optimization** — full-page redesign permitted, or only certain elements (headline, pricing tier copy, CTA)?
6. **Traffic available for testing** — daily visitors, and how long can the experiment run?

## User's answers

1. `/pricing`. Conversion = clicked "Start free trial" or "Talk to sales" CTA.
2. Mostly intent-rich — landed on the site from organic, browsed for a few minutes, hit Pricing. Some cold traffic from paid ads.
3. Two prior tests: changed CTA color (no effect), changed headline (no effect — but I'm not sure the headline test was well-scored).
4. Hotjar heatmaps + session recordings, GA4, last 6 months of sales-call recordings (Gong).
5. Above-the-fold area, pricing tier copy, CTA. Visual layout can change. Three-tier structure (Starter / Team / Enterprise) is fixed — sales has reasons.
6. ~3000 daily visitors. Experiment can run 2 weeks max.

## Output brief

```markdown
## What's underperforming
Pricing page at `/pricing`. Conversion = click on "Start free trial" or "Talk to sales".

## Current performance
- Metric: 1.4% conversion (page view → CTA click).
- Baseline: 1.4%.
- Target: 3% within one experiment cycle (industry midpoint of 4–6% is the eventual ambition; not realistic in a single test).

## Target audience
- Who sees this asset: mostly intent-rich visitors who browsed and clicked "Pricing"; minority cold from paid ads.
- Funnel stage: decision (intent-rich) and consideration (cold ad traffic).

## What we've already tried
- CTA color change — no effect.
- Headline change — no effect, but the test wasn't run through expert-panel scoring; quality of the variant is uncertain.

## Available data
- Hotjar heatmaps + session recordings (last 90 days).
- GA4: pageviews, scroll depth, CTA click rate by tier.
- Sales call recordings (Gong, last 6 months) — pricing-specific objections.

## Scope
- In: above-the-fold area (headline, sub-headline, social proof), pricing tier copy and ordering of features, CTA copy.
- Out: changing the three-tier structure (Starter / Team / Enterprise), changing pricing values themselves, changing nav or footer.

## Approach
1. Audit the current page. Score via expert panel. Identify the top 3 issues. Cross-reference with sales-call objections and session recordings.
2. Present audit findings and proposed variants. Stop for approval.
3. Generate optimized variants — 3–5 for an A/B/n test (not multivariate; traffic doesn't support it).
4. Score all variants through expert panel (target 90+).
5. Set up experiment with hypothesis, success metric, and sample size. Validate sample size against 3000 daily visitors and 2-week ceiling.
6. Monitor and report results with statistical significance.

## Constraints
- Timeline: experiment must conclude within 2 weeks of launch.
- Traffic: ~3000 daily visitors total across all variants.
- Technical: existing experiment platform; can swap copy and layout but not pricing values.
- Brand: keep three-tier structure; keep tier names; keep current pricing values.

## Quality gate
- [ ] Audit completed with scored baseline
- [ ] All variants scored 90+ by expert panel before testing
- [ ] Experiment design reviewed (hypothesis, metric, sample size, MDE)

## Deliverables
- Audit report with baseline scores and top 3 issues, supported by session-recording and sales-call evidence
- Optimized variants (3–5) with expert panel scorecards
- Experiment results with statistical analysis (significance, lift, confidence interval)
- Winner recommendation with rationale, or "no winner — here's what to try next"

## Open questions
- Are there segments where 1.4% is a blended average masking very different behavior? (e.g. cold paid traffic at 0.4% pulling down intent-rich at 3%.)
```

---

**Next step:** paste this into a fresh session, or say `go` and the executor pulls the data, audits, scores, and proposes variants before launching anything.
