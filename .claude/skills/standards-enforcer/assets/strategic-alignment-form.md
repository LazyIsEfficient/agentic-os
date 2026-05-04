# Strategic Alignment Form

> Fillable form for documenting how a piece of work aligns with the technical strategy. Filled out at the kickoff gate (before significant code is written) and referenced at later gates. The form is a contract: it's the team's statement of how the work fits the strategy, and it becomes the precedent for similar work in the future.

## Header

- **Feature / project:** _____
- **Author:** _____
- **Reviewer (enforcer / strategist):** _____
- **Date:** YYYY-MM-DD
- **Status:** draft | under review | approved | approved with conditions | needs revision | blocked
- **Linked PRD / brief:** _____
- **Linked design doc:** _____

---

## 1. Strategy Reference

> Cite the technical strategy document and the specific section that this work serves.

- **Strategy doc:** _____ (link)
- **Relevant section:** _____ (e.g., "Q2 monolith extraction", "platform-vs-product Q3", "search performance bet")
- **Quote** (optional): _____

> If you can't find a strategy section that this work serves, surface that to the strategist before proceeding.

---

## 2. Strategic Fit

> How does this work serve the chosen strategy section? Be specific.

> _____

---

## 3. Relevant DADs

> List the load-bearing DADs that this work touches.

| DAD ID | Title | This work conforms? | Notes |
|---|---|---|---|
| _____ | _____ | ✅ ⚠️ ❌ | _____ |
| _____ | _____ | ✅ ⚠️ ❌ | _____ |
| _____ | _____ | ✅ ⚠️ ❌ | _____ |

> If the work touches an area with no relevant DADs, note: _____ (and consider whether a new DAD is needed)

---

## 4. Relevant ADRs

> List the ADRs that this work touches or builds on.

| ADR ID | Title | This work conforms? | Notes |
|---|---|---|---|
| _____ | _____ | ✅ ⚠️ ❌ | _____ |
| _____ | _____ | ✅ ⚠️ ❌ | _____ |

---

## 5. Strategic Non-Goals

> Does this work touch any of the strategy's explicit non-goals?

| Non-goal | This work touches it? | If yes, why? |
|---|---|---|
| _____ | yes / no | _____ |
| _____ | yes / no | _____ |

> If this work touches a non-goal, an exception ADR is needed.

---

## 6. Capacity Impact

> Does this work fit within the team's capacity allocation for strategic work?

- **Team strategic capacity (per the strategy doc):** ___ %
- **This work's estimated cost:** _____ engineer-months
- **Other strategic work in flight:** _____
- **Does this fit within capacity?** yes / no / requires deprioritizing _____

---

## 7. Deviation (if any)

> If this work deviates from the strategy, the load-bearing DADs, the ADRs, or the non-goals, explain.

### What's the deviation?

> _____

### Why is the deviation necessary?

> _____

### What's the cost of the deviation?

> What's at stake if we deviate? What might go wrong?

> _____

### What's the cost of compliance?

> What does the team have to give up to comply? Is the cost reasonable?

> _____

### What's the mitigation?

> If we deviate, what are we doing to reduce the risk?

> _____

### Type of exception needed

- [ ] Temporary exception (specify expiration: _____)
- [ ] Permanent exception (specify scope: _____)
- [ ] Conditional exception (specify conditions: _____)
- [ ] Strategy update (the strategy itself should change)
- [ ] No exception — the work will be brought into compliance

### Approver

> Who needs to approve this exception? (Strategist for strategic deviations; security specialist for security; etc.)

> _____

---

## 8. Risks

> What could go wrong with this work, from a strategic standpoint?

| Risk | Severity | Mitigation |
|---|---|---|
| _____ | high \| med \| low | _____ |
| _____ | _____ | _____ |
| _____ | _____ | _____ |

---

## 9. Verdict

- [ ] **Approved** — work fits strategy; proceed to next gate
- [ ] **Approved with conditions** — fits with adjustments: _____
- [ ] **Needs exception ADR** — file as ADR-_____ before proceeding
- [ ] **Needs revision** — re-scope or change approach
- [ ] **Blocked** — significant strategic conflict; discuss with leadership

---

## 10. If Approved With Conditions

> Specific conditions that must be met before the next gate.

- [ ] _____
- [ ] _____
- [ ] _____

---

## 11. Sign-off

- [ ] Author: _____ (date)
- [ ] Enforcer: _____ (date)
- [ ] Strategist (if strategic deviation): _____ (date)
- [ ] Other approver (if applicable): _____ (date)

---

## Notes

> Anything else worth recording.

> _____

---

> **Reminder**: this form is part of the team's permanent record. Future enforcers, strategists, and engineers will read it to understand how this work was reviewed. Be specific and honest.
