# marketing-shaper — pipeline

Example of `/mshape` producing a `pipeline-template.md` brief — building or tuning the sales motion.

---

## User's initial request

> Cold outbound is dead. We're getting 1% reply rates on Instantly. Need to fix the whole motion — sequences, list, deliverability, the works.

## Shaper's batched questions

Pipeline overhaul, multiple components named, performance evidence — routes to `pipeline-template.md`.

1. **Pipeline stage** — is this a tune of an existing motion, a rebuild, or actually broken (deliverability dead)?
2. **ICP** — who are we sending to, where do leads come from today, and do you suspect the list, the copy, or the infra is the bottleneck?
3. **Tools currently in play** — Instantly is named; what else (RB2B, Apollo, Clay, Smartlead, HubSpot, Gong)?
4. **Current and target deal size**?
5. **Constraints** — daily volume, email-account capacity, compliance (CAN-SPAM, GDPR), domain-warming state?
6. **Success metric** — qualified meetings booked per week, pipeline $ generated per month, or something else?

## User's answers

1. Existing motion is broken-ish. Sequences haven't been touched in 8 months. Two domains have spam-rate issues per Google Postmaster.
2. ICP: VPs of Engineering at Series B–D B2B SaaS, 100–800 employees. Leads from Apollo + Clay enrichment. I suspect copy and list are both the problem.
3. Instantly (sending), Apollo (sourcing), Clay (enrichment), HubSpot (CRM), no Gong yet.
4. Current $8–18k ARR. Target same — we want volume, not bigger deals.
5. Daily volume cap ~600/day across 6 sending domains. CAN-SPAM compliant. Two domains in domain-health trouble (need warming or replacement). No GDPR exposure (US-only).
6. Qualified meetings booked per week. Currently 2/week. Target 8/week within 90 days.

## Output brief

```markdown
## Goal
Rebuild the cold outbound motion from "1% reply, 2 meetings/week, two domains in spam-rate trouble" to "8 qualified meetings/week within 90 days" by fixing sequences, list quality, and deliverability infrastructure together.

## Current state
- Pipeline stage: tuning existing — sequences are 8 months stale and two domains have Google Postmaster spam-rate issues.
- Tools in play: Instantly (sending), Apollo (sourcing), Clay (enrichment), HubSpot (CRM). No call-recording / Gong yet.
- Current deal size: $8–18k ARR.
- Target deal size: same — goal is volume, not larger deals.

## ICP
- Who: VPs of Engineering at Series B–D B2B SaaS, 100–800 employees, in markets where developer productivity is a measurable line item.
- Current lead sources: Apollo sourcing, Clay enrichment.
- Bottleneck: top-of-funnel — reply rate at 1%. Suspect both list quality and copy; deliverability is a secondary blocker on two domains.

## Scope
- In: rebuild sequences (new copy, expert-panel scored), audit and rebuild ICP list, fix domain health (warm or replace the two spam-rate-flagged domains), set up suppression rules, route replies into HubSpot.
- Out: account-based outbound (1:1 ABM), LinkedIn outbound, paid retargeting, lead magnet creation, sales-team training.

## Approach
1. Audit current pipeline:
   - Sequences: each step's reply rate, open rate, unsubscribe rate.
   - List: Apollo + Clay filter set, lead quality sample (manual review of 100 leads).
   - Domain health: per-domain spam rate, sender reputation, warmup status.
2. Present findings and proposed changes. Stop for approval.
3. Implement changes:
   - Sequences: draft new copy and score through expert panel (target 90+).
   - List: tighten Apollo filters; add Clay enrichment criteria for fit signal; add suppression for current customers, competitors, and prior-opt-out.
   - Domains: pause and re-warm the two flagged domains, or replace with two new ones (decision based on audit).
   - Routing: HubSpot deal creation on positive reply; auto-suppression on opt-out.
4. Monitor first cohort and report results at 30 / 60 / 90 days.

## Constraints
- Timeline: 90 days to 8 meetings/week.
- Volume: ~600/day across 6 sending domains (4 healthy + 2 flagged or their replacements).
- Compliance: CAN-SPAM. US-only sending — no GDPR exposure today.
- Budget: existing tool stack (no new spend approved).

## Success metrics
- Primary: qualified meetings booked per week. Baseline 2/week. Target 8/week by day 90.
- Secondary: reply rate, lead-to-meeting conversion rate, opt-out rate, domain spam rate.
- Baseline: reply 1%, lead-to-meeting unknown until audit, opt-out unknown.

## Quality gate
- [ ] All outbound copy scored 90+ by expert panel
- [ ] Suppression rules verified (no sending to current customers, competitors, prior opt-outs)
- [ ] Domain health checked (SPF, DKIM, DMARC, warmup status, Postmaster spam rate)

## Deliverables
- Pipeline audit report (sequences, list quality sample, domain health)
- New sequences (with scorecards)
- Updated Apollo + Clay filter set
- Domain remediation plan and execution
- HubSpot routing rules
- Day-30 / Day-60 / Day-90 performance reports

## Open questions
- For the two flagged domains: warm back to health (4–6 weeks), or burn and replace (faster but loses domain history)?
- Is there budget headroom for adding Gong or similar to extract patterns from positive-reply calls into the next sequence iteration?
```

---

**Next step:** paste this into a fresh session, or say `go` and the executor runs the audit before changing any sequences or domains.
