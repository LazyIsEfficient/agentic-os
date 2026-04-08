# Tech Bet Proposal: <one-line title>

> Fillable template for proposing a major technical investment. Use this when you're considering a build/buy/adopt decision, a refactor that crosses multiple sprints, a platform investment, or any work that commits the team to a direction for months.

## Header

- **Proposer:** _____
- **Date:** YYYY-MM-DD
- **Status:** draft | under review | approved | rejected | in progress | completed | abandoned
- **Linked strategy:** _____ (which strategy doc this bet supports)
- **Linked ADR (if approved):** _____

## 1. The Problem

> One paragraph. What's the current pain? What evidence do we have that the pain is real and worth fixing?
>
> Be specific. Vague problems produce vague bets.

> _____

### Evidence

- _____
- _____
- _____

## 2. The Desired Outcome

> One paragraph. What's different in the world after this bet pays off? Concrete, observable.
>
> Not the deliverable. The *outcome*.

> _____

## 3. The Options

> List several options. The discipline is to enumerate alternatives, not just present the one you want.

### Option A: <name> (the proposed bet)

- **Description:** _____
- **Cost (engineering):** _____ engineer-months
- **Cost (other):** _____ (vendor, infrastructure, license)
- **Time to value:** _____
- **Strengths:** _____
- **Weaknesses:** _____

### Option B: <alternative>

- **Description:** _____
- **Cost:** _____
- **Why we're not picking it:** _____

### Option C: <alternative>

- **Description:** _____
- **Cost:** _____
- **Why we're not picking it:** _____

### Option D: Do nothing

- **Description:** Continue the current approach.
- **Cost:** Whatever we're paying today.
- **Why we're not picking it:** _____

## 4. The Recommendation

> Which option are we proposing, and why?

> _____

## 5. Cost

### Engineering cost

- **Up-front:** _____ engineer-months over _____ calendar months
- **Ongoing maintenance:** _____ engineer-months per year, indefinitely
- **Estimate confidence:** high | medium | low (engineering estimates are usually 1.5-3x what was first proposed; what's your honest estimate after applying that multiplier?)

### Other cost

- **Vendor / license:** _____
- **Infrastructure:** _____
- **Training:** _____
- **Migration:** _____

### Opportunity cost

- **What this displaces:** _____ (what the team won't do because they're doing this)

## 6. Success Criteria

> How will we know the bet paid off? Specific, measurable, with a deadline.

Within _____ days of completion:

- [ ] _____ (e.g. "median deploy time under 15 minutes")
- [ ] _____
- [ ] _____

We will evaluate at: _____ (date)

## 7. Kill Criteria

> When would we stop this bet? Be explicit. Without this, we'll keep investing past the point of usefulness.

We will stop or pivot if:

- [ ] _____ (e.g. "after 30 days, we have not been able to migrate even one service")
- [ ] _____
- [ ] _____

## 8. Risks

| Risk | Severity | Probability | Mitigation |
|---|---|---|---|
| _____ | high \| med \| low | high \| med \| low | _____ |
| _____ | _____ | _____ | _____ |
| _____ | _____ | _____ | _____ |

## 9. Cost of Delay

> What's the cost of not doing this bet right now?
>
> Some bets get more expensive over time (migrations, debt paydown, security upgrades). Others stay flat. Which is this?

> _____

## 10. Strategic Fit

> How does this bet fit the technical strategy?
>
> Cite the relevant strategy doc and the specific section it supports.

> _____

## 11. Dependencies

> What does this bet depend on? What needs to happen first?

- **Technical dependencies:** _____
- **Team dependencies:** _____
- **External dependencies:** _____

## 12. Team Impact

- **Who's working on this?** _____
- **For how long?** _____
- **What's their normal work being deprioritized?** _____
- **Is the team capable of executing this?** (skills, experience, capacity)

## 13. Communication Plan

> Who needs to know about this bet, and how?

- **Engineering team:** _____
- **Leadership:** _____
- **Product team:** _____
- **Customers (if relevant):** _____

## 14. Tracking and Milestones

> How will we track progress on this bet?

| Milestone | Target date | Indicator |
|---|---|---|
| _____ | _____ | _____ |
| _____ | _____ | _____ |
| _____ | _____ | _____ |

## 15. Post-Bet Review

> When and how will we evaluate whether the bet paid off?

- **Review date:** _____
- **What we'll measure:** _____
- **What success looks like:** _____
- **What failure looks like:** _____

---

## Approval

- [ ] Strategist: _____ (date)
- [ ] Eng leadership: _____ (date)
- [ ] TPM (if relevant): _____ (date)

---

## Pre-approval checklist

Before this bet is committed:

- [ ] The problem is supported by evidence
- [ ] At least 2 alternative options were considered
- [ ] The cost estimate is honest (multiplied for safety)
- [ ] Success criteria are concrete
- [ ] Kill criteria are concrete
- [ ] Engineering team has reviewed and feels capable
- [ ] Strategic fit is documented
- [ ] Opportunity cost is acknowledged
- [ ] An owner is named
- [ ] A review date is set

---

## Notes

> Anything specific about this bet that doesn't fit the template.

> _____
