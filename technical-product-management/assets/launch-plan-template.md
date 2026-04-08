# Launch Plan: <feature name>

> Fillable launch plan template. Walk through this *before* the launch, not during. The pre-launch checks are where most launches succeed or fail.

## Header

- **Feature:** _____
- **PM owner:** _____
- **Eng owner:** _____
- **Designer:** _____
- **Target launch date:** _____
- **Launch type:** internal | closed beta | open beta | soft launch | hard launch
- **Linked PRD:** _____

## 1. The Bet

> One paragraph. What are we shipping, who is it for, what outcome are we trying to achieve?

> _____

## 2. Success Criteria

- **Primary metric:** _____
- **Target:** _____
- **Time horizon for evaluation:** _____ (e.g. "30 days after 100% rollout")
- **Counter-metric** (what we don't want to break): _____
- **Baseline** (current value of primary metric): _____
- **Baseline date:** _____

## 3. Phased Rollout Plan

> Don't launch to everyone at once. Each phase has bake time so you catch problems before scale.

| Phase | Target audience | % of users | Bake time | Move to next phase if... |
|---|---|---|---|---|
| 1. Internal dogfood | Build team | 100% (internal only) | _____ days | No critical bugs |
| 2. Internal beta | Whole company | 100% internal | _____ days | _____ |
| 3. Closed beta | Hand-picked customers | _____ users | _____ days | _____ |
| 4. Soft launch | _____% of users | _____% | _____ days | Metric trending right; no kill criteria triggered |
| 5. Expansion | _____% of users | _____% | _____ days | Same |
| 6. Full launch | All users | 100% | — | — |

## 4. Kill Criteria (Pre-Committed)

> Define BEFORE launch what would make you roll back. Don't trust yourself to decide this in a panic.

We will roll back if any of:

- [ ] Error rate exceeds _____ %
- [ ] Primary metric drops by _____ percentage points
- [ ] Counter-metric `<X>` exceeds _____
- [ ] Support volume on this feature exceeds _____ tickets in 24h
- [ ] Performance degrades by more than _____ %
- [ ] We discover a security or data integrity issue
- [ ] _____

We will pause expansion (but not roll back) if any of:

- [ ] _____
- [ ] _____

## 5. Rollback Plan

- **Rollback mechanism:** feature flag flip | revert deploy | database migration | _____
- **Estimated rollback time:** seconds | minutes | hours
- **Data implications:** what happens to data created with the new feature on rollback?
- **Decider** (who calls the rollback): _____ (named individual or on-call rotation)
- **Rollback drill completed:** [ ] yes [ ] no
- **Rollback comms plan:** _____ (what we say internally and externally if we roll back)

## 6. Metrics Setup

> Without these in place before launch, you can't tell if the launch worked.

- [ ] Primary metric is instrumented
- [ ] Counter-metric is instrumented
- [ ] Baseline is captured
- [ ] Launch dashboard exists at: _____
- [ ] Dashboard accessible to: _____
- [ ] Daily monitoring assigned to: _____ (for first 1–2 weeks)
- [ ] Weekly monitoring after that: _____

## 7. Internal Launch Brief

> Distributed 1–2 weeks before launch.

### To Sales

- What's launching: _____
- Talking points: _____
- What customers will see: _____
- Where to learn more: _____
- Who to contact with questions: _____

### To Customer Success / Support

- What's launching: _____
- Likely user questions: _____
- How to help users with the feature: _____
- Known limitations: _____
- Escalation path for issues: _____

### To Marketing

- Launch comms plan: _____
- Assets needed by date: _____
- Coordination point: _____

### To Leadership

- TL;DR: _____
- Key metric to watch: _____
- Risks: _____
- Decisions needed: _____

## 8. Customer Communication

> What we say to users at each phase.

### At soft launch

- **Channel:** in-product banner | email | changelog | _____
- **Message:** _____
- **CTA:** _____

### At full launch

- **Channels:** _____
- **Message:** _____
- **Detailed announcement:** _____ (link to blog post / docs)

### If we have to roll back

- **Channels:** _____
- **Message:** _____ (honest, brief, action-oriented)

## 9. Beta Program (if applicable)

- **Beta size:** _____ users
- **Recruitment criteria:** _____
- **Recruitment channels:** _____
- **Compensation / incentive:** _____
- **Feedback channel:** _____
- **Beta start date:** _____
- **Beta duration:** _____
- **Closing the loop with beta users:** _____ (how we'll thank them and tell them what changed)

## 10. Risks and Concerns

| Risk | Severity | Mitigation | Owner |
|---|---|---|---|
| _____ | high \| medium \| low | _____ | _____ |
| _____ | _____ | _____ | _____ |
| _____ | _____ | _____ | _____ |

## 11. Pre-Launch Checklist

The week before launch, verify:

### Build readiness
- [ ] All acceptance criteria from the PRD met
- [ ] Edge cases (empty, error, loading, large data, slow connection) handled
- [ ] Accessibility verified (WCAG 2.2 AA)
- [ ] Performance verified under expected load
- [ ] Internal beta complete; bugs fixed
- [ ] Closed beta complete; feedback addressed

### Launch readiness
- [ ] Feature flag in place
- [ ] Rollback mechanism tested
- [ ] Metrics instrumented and verified
- [ ] Launch dashboard live
- [ ] Internal launch brief sent
- [ ] Customer comms drafted and reviewed
- [ ] Support team trained
- [ ] Sales team enabled
- [ ] Status page entry prepared (if customer-facing)

### Operational readiness
- [ ] On-call has the runbook for this feature
- [ ] Alerts configured (per [SRE skill](../../site-reliability-engineering/SKILL.md))
- [ ] Capacity / load tested
- [ ] Database migrations completed (if any)
- [ ] Third-party dependencies confirmed available

### Decision readiness
- [ ] Kill criteria agreed in writing
- [ ] Decider for rollback identified
- [ ] Stakeholders briefed
- [ ] PM available to monitor in the launch window

## 12. Post-Launch Schedule

| When | What |
|---|---|
| Hour 1 | Verify launch is live; check error rates; confirm flag state |
| Day 1 | Check metrics; address any urgent issues |
| Day 2-7 | Daily metric check; respond to user feedback; expand rollout if healthy |
| Week 2 | Weekly metric check; address any patterns in feedback |
| Week 4 | Begin post-launch review prep |
| Week 4-6 | Post-launch review meeting; document lessons; decide next steps |
| Quarter | Revisit in next strategy review; was this the right bet? |

## 13. Post-Launch Review

> Filled in 4-6 weeks after launch.

- **Did we hit the success metric?** _____
- **What did we learn?** _____
- **What would we do differently?** _____
- **What's next for this feature?** iterate | move on | kill

---

## Sign-off (pre-launch)

- [ ] PM: _____ (date)
- [ ] Eng lead: _____ (date)
- [ ] Designer: _____ (date)
- [ ] On-call lead: _____ (date)
- [ ] Sponsor (if applicable): _____ (date)

> **Reminder**: launches go wrong in predictable ways. The point of this plan is to make the predictable failures *unhappen*. If a checkbox above is unchecked at launch time, that's a reason to delay, not a reason to "ship and figure it out."
