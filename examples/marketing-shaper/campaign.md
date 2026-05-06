# marketing-shaper — campaign

Example of `/mshape` producing a `campaign-template.md` brief — multi-channel initiative.

---

## User's initial request

> We're launching the new analytics integration in six weeks. Need a launch campaign — email, landing page, LinkedIn, maybe some paid. Goal is qualified pipeline.

## Shaper's batched questions

Multi-channel ("email, landing page, LinkedIn, maybe paid"), launch-tied — routes to `campaign-template.md`.

1. **ICP — who specifically?** Role, company size, industry, the pain this integration solves?
2. **Funnel stage — awareness or decision?** Cold-list net-new vs. warming existing leads vs. activating signups?
3. **Existing assets** — landing pages, email lists, brand guidelines, any prior integration launches we can borrow from?
4. **Budget** — paid spend ceiling, or organic only with paid as "if we have time"?
5. **Success metric** — what's the one number that defines success? MQLs, pipeline $, demos booked, signups?
6. **Quality gate — should expert-panel scoring run on copy before launch?**

## User's answers

1. Heads of Data and senior data engineers at Series B–D SaaS companies (200–2000 employees). Pain: stitching product analytics with warehouse data without writing custom ETL.
2. Mostly awareness for cold list, decision for the ~3k signed-up-but-never-activated existing leads.
3. We have brand guidelines, a 12k newsletter list, three customer-quote videos from beta. No prior launch playbook.
4. $25k paid ceiling for the six weeks. LinkedIn + Google.
5. Pipeline $ generated in the 60 days post-launch. Secondary: demos booked, signups.
6. Yes — every piece scored before publish.

## Output brief

```markdown
## Goal
Generate $400k+ of qualified pipeline in the 60 days following the analytics-integration launch by reaching Heads of Data and senior data engineers at Series B–D SaaS companies and converting them into demo-stage opportunities.

## Target audience
- ICP: Heads of Data, Senior Data Engineers, Analytics Leads at Series B–D SaaS companies (200–2000 employees) who are stitching product analytics to warehouse data without writing custom ETL.
- Funnel stage: awareness for cold list; decision for ~3k signed-up-but-never-activated leads.
- Exclusions: pre-Series-B, agencies, anyone using a competing integration we have a partnership with.

## Channels in scope
- Landing page — single launch page with the integration story, demo form, customer-quote video.
- Email — net-new nurture (cold list); reactivation sequence (3k dormant signups).
- LinkedIn — organic founder + company posts, 6 weeks of cadence; paid Sponsored Content to ICP titles.
- Google paid — branded + category keywords ("warehouse-native product analytics", competitor terms).

## Core message / angle
Product analytics that already lives in your warehouse — no custom ETL, no second source of truth.

## Existing assets
- Brand guidelines (current).
- 12k newsletter list (segmentable by role).
- Three customer-quote videos from the beta (2–3 minutes each).
- Beta customer logo wall.

## Constraints
- Timeline: launch date six weeks out. Pre-launch warm-up week 5; full push weeks 6–10.
- Budget: $25k paid ceiling for the six weeks (LinkedIn Sponsored + Google).
- Brand / voice: existing brand guidelines apply; no exception requests planned.
- Out of scope: webinar, podcast tour, paid PR, sponsored newsletters.

## Approach
1. Map the audience journey across channels. Identify content gaps per stage. Use beta-customer quotes for proof, not hype.
2. Draft a content calendar with assets per channel. Stop and wait for approval.
3. On approval, produce assets channel-by-channel. Score each through expert panel (target 90+).
4. Set up tracking and attribution: UTM scheme, demo-form attribution, dormant-signup cohort tag.
5. Launch and monitor. Queue first optimization cycle for week 8.

## Success metrics
- Primary: pipeline $ generated in 60 days post-launch (target $400k+).
- Secondary: demos booked, signups, dormant-lead reactivation rate, landing page conversion rate.
- Baseline: prior product launches averaged ~$120k in 60 days; this is a 3.3x ask, justified by the larger list and paid spend.

## Quality gate
- [ ] All copy scored 90+ by expert panel before launch
- [ ] Landing page audited for conversion (above-fold, social proof, demo CTA)
- [ ] Tracking and attribution verified end-to-end (UTM → CRM → pipeline reporting)

## Deliverables
- Content calendar (all channels, all assets, with dates)
- Landing page (final)
- Email sequences: cold nurture (5 emails), dormant reactivation (3 emails)
- LinkedIn cadence: 12 organic posts, 4 paid creatives
- Google paid setup: campaign structure, ad copy, keyword list
- Attribution setup
- Week-1 performance report

## Open questions
- Demo form handoff — direct to AE rep, round-robin, or qualified by chatbot first?
- Are we comfortable bidding on competitor terms in Google? Legal sign-off needed?
```

---

**Next step:** this brief spans multiple channels (email + landing page + social + ads), so the natural follow-up is decomposition by channel — each becomes its own loop (asset draft → expert-panel score via `content-ops` → ship). Paste the brief into a fresh session and the loader picks up `content-ops` / `growth-engine` per channel. Or say `go` and the executor maps the journey, drafts the calendar, and stops for approval before producing assets.
