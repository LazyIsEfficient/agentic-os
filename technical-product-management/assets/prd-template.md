# PRD: <one-line title>

> Fillable one-page PRD. Aim for 1–3 pages total. The PRD answers *what* and *why*; it does not specify *how* (that's engineering's job). If you find yourself writing implementation details, stop and link to the design doc instead.

## Header

- **Owner (PM):** _____
- **Eng lead:** _____
- **Designer:** _____
- **Date:** YYYY-MM-DD
- **Status:** draft | reviewed | committed | shipped | killed
- **Linked artifacts:** strategy doc / research / design / ADR

## 1. One-line summary

> One sentence the team can repeat from memory.

> _____

## 2. The Problem

> One paragraph. What's the user pain? Be specific. Cite the evidence.

> _____

### Evidence

- _____
- _____
- _____

## 3. The User

> Who has this problem? Reference personas or JTBD if you have them.

- **Primary user:** _____
- **Secondary user (if any):** _____
- **Where they encounter this problem:** _____
- **Why it matters to them:** _____

## 4. Goal / Success Metric

> What does done look like? Concrete, observable, measurable.

- **Primary metric:** _____
- **Target value:** _____
- **Time horizon:** _____ (e.g. "30 days after 100% rollout")
- **Counter-metric** (what we don't want to break): _____
- **Baseline** (current value of the metric): _____

## 5. Approach (high level)

> The general direction the team is taking. *What* we'll build, in user-visible terms. **Not the implementation.**

> _____

## 6. Non-Goals

> What we are explicitly NOT doing. The most important section. Save your future self from re-arguing scope.

- _____
- _____
- _____

## 7. Open Questions

> Things we don't yet know that the build process needs to resolve. These don't block the PRD; they're flagged work.

- _____
- _____

## 8. Acceptance Criteria

> Concrete, testable conditions for "this is done." User-visible, not implementation.

- [ ] _____
- [ ] _____
- [ ] _____
- [ ] Performance: _____
- [ ] Accessibility: _____ (default: WCAG 2.2 AA)

## 9. Dependencies and Risks

| Dependency / Risk | Owner | Mitigation |
|---|---|---|
| _____ | _____ | _____ |
| _____ | _____ | _____ |

## 10. Timeline (loose)

> Honest timeline with confidence. Don't fake precision.

- **Discovery / validation complete:** _____
- **Design ready:** _____
- **Build start:** _____
- **Internal beta:** _____
- **Public launch:** _____
- **Confidence:** high | medium | low

## 11. Stakeholders

| Role | Person | Their concern |
|---|---|---|
| Sponsor | _____ | _____ |
| Sales / CS | _____ | _____ |
| Support | _____ | _____ |
| Marketing | _____ | _____ |
| Legal / security (if needed) | _____ | _____ |

## 12. What we explicitly considered and rejected

> Brief notes on alternative approaches we considered and chose not to take. Saves future arguments.

- **Alternative A:** _____ — rejected because _____
- **Alternative B:** _____ — rejected because _____

---

## Pre-commitment checklist

Before this PRD becomes a commitment to build:

- [ ] Problem is specific and supported by evidence
- [ ] User is named (not "everyone")
- [ ] Success metric is observable and instrumented
- [ ] Counter-metric is defined
- [ ] Non-goals are explicit
- [ ] Engineering has reviewed and feels they can size it
- [ ] Design has reviewed and feels they have enough to start
- [ ] Stakeholders are aware
- [ ] Timeline is realistic
- [ ] No implementation specified (only what/why)

---

## Sign-off

- [ ] PM (owner): _____ (date)
- [ ] Eng lead: _____ (date)
- [ ] Designer: _____ (date)
- [ ] Sponsor: _____ (date)

> **Reminder**: this PRD is a *hypothesis*, not a *contract*. Update it when reality moves. Mark what changed and why. The most recent version is the truth.
