# Technical Strategy: <one-line title>

> Fillable template for a technical strategy document. Aim for 1-3 pages total. The strategy answers *what direction* and *why*, not *what to build* (that's the architecture) and not *how to ship it* (that's the roadmap). If the document is longer than 3 pages, you're hiding from the discipline of choosing.

## Header

- **Owner (Strategist):** _____
- **Date drafted:** YYYY-MM-DD
- **Status:** draft | reviewed | accepted | superseded
- **Time horizon:** _____ (e.g. "next 12 months", "Q2-Q4 2026")
- **Next review:** YYYY-MM-DD
- **Linked documents:** product strategy / org plan / prior version

## 1. One-line summary

> One sentence the team can repeat from memory.

> _____

## 2. Diagnosis

> One paragraph (maybe two). What's the situation? What's the *one* most important thing happening right now? What's the constraint that matters most?
>
> Be specific. Cite evidence. Avoid bromides.

> _____

### Evidence

- _____
- _____
- _____

## 3. Guiding Policy

> One paragraph. The chosen approach in response to the diagnosis. Not a goal, not a metric — a *direction*.
>
> What are we doing differently because of the diagnosis?

> _____

## 4. Coherent Actions

> The specific things we're doing that follow from the policy. 5-10 items. Each one should be testable: you can tell whether it's done.

| # | Action | Owner | Target date | Success criteria |
|---|---|---|---|---|
| 1 | _____ | _____ | _____ | _____ |
| 2 | _____ | _____ | _____ | _____ |
| 3 | _____ | _____ | _____ | _____ |
| 4 | _____ | _____ | _____ | _____ |
| 5 | _____ | _____ | _____ | _____ |

## 5. What We Are Explicitly NOT Doing

> The most important section. Save your future self from re-arguing scope. 3-7 items. Each one with one-line rationale.

- **_____** — not doing because _____
- **_____** — not doing because _____
- **_____** — not doing because _____
- **_____** — not doing because _____

## 6. Capacity Allocation

> How much of the team's engineering time is committed to this strategy?

- **Strategic work**: ___ % of capacity
- **Feature work**: ___ % of capacity
- **Maintenance / on-call / interrupts**: ___ % of capacity

> Total should be 100%. If it doesn't add up, you're lying to yourself about something.

## 7. Load-Bearing DADs Affected

> Which existing DADs does this strategy depend on (or contradict)? See [team-lead](../../team-lead/SKILL.md).

| DAD ID | Title | Status (still load-bearing? deprecated? new?) |
|---|---|---|
| _____ | _____ | _____ |
| _____ | _____ | _____ |

## 8. Kill Criteria

> Under what conditions would we change this strategy? What would make us reconsider?
>
> Without this section, the strategy becomes a loyalty test rather than a hypothesis.

We will reconsider this strategy if:

- _____
- _____
- _____

## 9. Connection to Product Strategy

> How does this technical strategy serve the product strategy and the business?
>
> If you can't fill this in, the technical strategy might be engineering for engineering's sake.

> _____

## 10. Risks

> What could go wrong with this strategy? What are we worried about?

| Risk | Severity | Mitigation |
|---|---|---|
| _____ | high \| medium \| low | _____ |
| _____ | _____ | _____ |
| _____ | _____ | _____ |

## 11. Communication Plan

> Who needs to know about this strategy, and how will they hear about it?

- **Engineering team**: _____ (when, how)
- **Leadership**: _____
- **Product team**: _____
- **Adjacent teams**: _____
- **External (if any)**: _____

## 12. Open Questions

> Things we don't yet know that the strategy needs to address.

- _____
- _____

---

## Changelog

> Track how this strategy evolves over time. Each change is dated with rationale.

### YYYY-MM-DD (current)

- Initial draft.

### YYYY-MM-DD

- _____ (e.g. "Updated action 3 because...")

---

## Sign-off

- [ ] Strategist (owner): _____ (date)
- [ ] Engineering leadership: _____ (date)
- [ ] Technical product manager: _____ (date)
- [ ] CTO / VP Eng (if needed): _____ (date)

---

## Pre-publication checklist

Before this strategy becomes the team's direction:

- [ ] Diagnosis is grounded in evidence (cited above)
- [ ] Guiding policy follows from the diagnosis
- [ ] Actions follow from the policy
- [ ] At least 3 explicit non-goals
- [ ] Kill criteria are concrete and observable
- [ ] Capacity allocation is honest (not aspirational)
- [ ] Connection to product strategy is clear
- [ ] Reviewed by senior engineers and leadership
- [ ] Document is under 3 pages
- [ ] One-line summary is memorable

---

> **Reminder**: this strategy is a *hypothesis*, not a *contract*. It will be revised when reality demands it. The most recent version is the truth. See [strategy-evolution.md](../references/strategy-evolution.md).
