# Exception Request

> Fillable template for requesting a deliberate deviation from a standard, DAD, or ADR. This is the safety valve: standards exist for good reasons, but sometimes the specific case warrants deviation. This form makes the deviation visible, traceable, and reviewable.
>
> An exception that's approved through this process is *fine*. An exception that's not filed is *silent deviation*, and that's the failure mode the enforcer is preventing.

## Header

- **Requester:** _____
- **Date:** YYYY-MM-DD
- **Status:** draft | submitted | under review | approved | rejected | expired
- **Linked work:** _____ (PR / ticket / design doc)
- **Linked standard / DAD / ADR being deviated from:** _____

---

## 1. The Standard

> What standard, DAD, or ADR is this exception requesting deviation from?

- **Source:** _____ (e.g., "security-engineering / api-security.md", "DAD-0042 Postgres for OLTP", "ADR-0103 hexagonal architecture for service X")
- **Specific rule:** _____
- **Quote** (if helpful): _____

---

## 2. The Deviation

> What specifically does this work do that violates the standard?

> _____

---

## 3. Why the Deviation Is Necessary

> Make the case. Why can't this work comply with the standard? Be specific.
>
> Note: "we don't have time" is not a sufficient reason on its own. The fix for "no time" is to address the deadline (push it, scope down, escalate), not to skip the standard.

> _____

---

## 4. Cost of Compliance

> What would it cost to comply with the standard? What does the team have to give up?
>
> Be specific. "It would take a long time" is not specific. "It would require ~3 engineer-weeks of work that we don't have in this quarter, and would push the launch by 4 weeks" is.

> _____

---

## 5. Cost of the Deviation

> What's the risk we're accepting by deviating? What might go wrong?
>
> Be honest. The exception is granted on the basis that the team has thought about this, not that the team has dismissed it.

> _____

---

## 6. Mitigations

> What are we doing to reduce the risk of the deviation?
>
> A pure "we accept the risk" without mitigations is rarely the right answer. There's almost always *something* the team can do to reduce the risk while the exception is in effect.

- _____
- _____
- _____

---

## 7. Type of Exception

Choose one:

- [ ] **Temporary** — the standard will be met, just not yet. Specify when:
  - **Compliance date:** _____
  - **Plan:** _____

- [ ] **Permanent** — the standard doesn't apply to this case. Specify scope:
  - **Scope:** _____
  - **Re-evaluation date** (when we'll review whether this still applies): _____

- [ ] **Conditional** — the deviation is acceptable under specific conditions. Specify:
  - **Conditions:** _____

- [ ] **Scope-limited** — the standard applies in general, but a different rule applies to this specific case. Specify:
  - **Scope of the exception:** _____
  - **Different rule that applies:** _____

---

## 8. Approver

> Who needs to approve this exception?
>
> Different exceptions need different approvers:
>
> - Strategic deviation → [technical-strategist](../../technical-strategist/SKILL.md)
> - Security exception → security specialist (never the enforcer alone)
> - Operational readiness exception → SRE specialist
> - Quality / code design exception → relevant skill owner or senior engineer
> - Accessibility exception → accessibility specialist or [ux-design](../../ux-design/SKILL.md) owner
> - ADR/DAD violation → team-lead and strategist together

- **Approver:** _____
- **Reasoning** (why this approver): _____

---

## 9. Alternatives Considered

> What other options did the team consider? Why didn't they work?

- **Option A** (full compliance): _____ — rejected because _____
- **Option B** (different approach): _____ — rejected because _____
- **Option C** (this exception): the proposed path

---

## 10. Decision

> Filled in by the approver.

- **Decision:** approved | approved with modifications | rejected | needs more information
- **Decided by:** _____
- **Date:** _____
- **Modifications (if any):** _____
- **Reasoning:** _____

---

## 11. ADR Reference

> When approved, this exception becomes (or links to) an ADR via [team-lead](../../team-lead/SKILL.md).

- **ADR ID:** ADR-_____
- **ADR title:** _____
- **Linked location:** _____

---

## 12. Tracking and Follow-up

For temporary exceptions:

- **Tracked in:** _____ (ticket, calendar, etc.)
- **Reviewer for compliance:** _____
- **Action if not complied with by deadline:** _____

For permanent exceptions:

- **Re-evaluation date:** _____
- **Reviewer:** _____

---

## 13. Notes

> Anything else worth recording.

> _____

---

> **Reminder**: this exception is part of the team's permanent record. Future engineers will read it to understand why this code deviates from the standard. Be specific, honest, and complete. A vague or weak exception is worse than no exception, because it teaches the team that the process is meaningless.

> **Reminder for the approver**: don't rubber-stamp. Read the request carefully. Reject it if the rationale is weak. Approve it with modifications if the rationale is good but the scope is too broad. Grant approvals deliberately, not as a courtesy.
