# Exceptions and Waivers

The most important safety valve in standards enforcement: the exception process. A standard with no exception process gets bypassed silently and loses all force. A standard with a clear exception process stays firm but flexible.

This file is the playbook for handling exceptions: when to grant them, how to document them, who decides, and when to refuse.

## The Premise

Standards exist for good reasons. They encode the team's accumulated lessons. But sometimes the standard doesn't fit the specific case. Sometimes the situation is unusual; sometimes the cost of compliance exceeds the cost of the risk; sometimes there's a legitimate reason to deviate.

When this happens, the team has three options:

1. **Follow the standard anyway.** The right call when the deviation isn't actually necessary, even if compliance is annoying.
2. **Bypass the standard silently.** The wrong call. Erodes the standards over time; the team can't tell which deviations are deliberate and which are mistakes.
3. **File an exception.** The right call when the deviation is necessary and legitimate. Makes the deviation visible, traceable, and reviewable.

The exception process is what enables option 3. Without it, the team has only options 1 and 2 — and option 2 usually wins under pressure.

## What Makes an Exception Legitimate

A legitimate exception meets all of these criteria:

1. **The standard genuinely doesn't fit this case.** Not "the standard is annoying" or "the standard is hard." The standard's underlying concern doesn't apply, or the cost of applying it is disproportionate.
2. **The deviation has been thought through.** Not a panic decision; a deliberate trade-off.
3. **The cost of the deviation is understood.** What risk are we accepting? What might go wrong because of this exception?
4. **There's a mitigation, where possible.** What are we doing to reduce the risk of the exception?
5. **The deviation has an end state.** Either it's permanent (a permanent exception) or it has a clear path to compliance (a temporary exception). Indefinite "we'll fix it later" is not acceptable.
6. **The right decider has approved it.** The strategist for strategic deviations; security for security; the appropriate skill owner for domain-specific exceptions.

If any of these is missing, the exception is not ready to be granted. The enforcer's job is to walk the team through the criteria and either grant the exception or reject it.

## What Makes an Exception Illegitimate

The enforcer should *refuse* exceptions in these cases:

- **The standard is being skipped because of deadline pressure alone.** "We don't have time for it" is not a reason; it's a panic. The fix is to address the deadline (push it, scope down, reduce other commitments), not to skip the standard.
- **The deviation is unbounded.** "We'll fix it later" without a date is not acceptable.
- **The deviation is for a critical security baseline.** SQL injection, committed secrets, plaintext passwords, missing auth on protected endpoints — these don't get exceptions.
- **The deviation is permanent and damages the strategy.** If the exception means the strategy is wrong, the right path is to change the strategy, not to grant a permanent exception.
- **The team is asking the enforcer to override** the source-of-truth skill or the strategy. The enforcer doesn't have that authority.
- **The team is gaming the process.** Filing exceptions for everything to avoid the standards. Pattern of behavior, not single instance.

For these, the enforcer says no and routes the team to address the underlying issue.

## Types of Exceptions

Exceptions come in different shapes. The right format depends on the type.

### Temporary exception

The standard will be met, just not yet. There's a specific reason for the delay and a specific date by which the team will comply.

Example:

> "We are deploying without the new accessibility audit because the audit team is booked until next week. The feature ships now to meet a customer commitment. Audit will be completed by 2026-04-15. If the audit reveals issues, we will address them in a follow-up release within 7 days."

Properties:
- Specific reason for the deviation.
- Specific end date.
- Specific remediation plan.
- Documented as a *temporary* exception, not a permanent one.

### Permanent exception

The standard doesn't apply to this specific case, and that's okay forever (or until the situation changes materially).

Example:

> "Our internal admin tool does not require WCAG AA accessibility compliance. The tool is used only by trained internal staff. The accessibility baseline is intended for user-facing products; this tool is excluded from that baseline."

Properties:
- Specific scope (what the exception covers).
- Reason it doesn't apply.
- Potentially: a re-evaluation date (e.g., "review in 1 year to confirm the rationale still holds").

### Conditional exception

The standard is being deviated from in a specific way, with specific mitigations in place.

Example:

> "We are using a non-standard database (DynamoDB instead of Postgres) for the search index because Postgres full-text search doesn't meet our latency requirements. Mitigations: the data in DynamoDB is derived from Postgres (the source of truth) and is rebuildable from scratch within 30 minutes. Operational concerns are addressed by the SRE runbook for DynamoDB, separate from the Postgres runbook."

Properties:
- Specific deviation.
- Specific mitigations that reduce the risk.
- Cross-references to the related material (alternative runbooks, etc.).

### Scope-limited exception

The standard applies in general, but for this specific feature or service, a different rule applies.

Example:

> "Our public API rate-limits at 100 requests/minute for normal users. The bulk-import endpoint accepts up to 1000 requests/minute for authenticated enterprise users with the bulk-import role. This is a deliberate scope-limited exception to the standard rate limit, in service of a documented customer need."

Properties:
- Specific scope where the exception applies.
- Specific authentication or context required.
- Standard still applies elsewhere.

## The Exception Workflow

When the enforcer identifies a deviation that needs an exception, the workflow:

### Step 1: The team files the exception request

The team writes up the exception using the [assets/exception-request-template.md](../assets/exception-request-template.md). The request includes:

- **What standard is being deviated from**, cited from the source-of-truth skill.
- **What the deviation is.**
- **Why the deviation is necessary** (the reasoning).
- **What the cost / risk of the deviation is.**
- **What mitigations are in place.**
- **What type of exception** (temporary, permanent, conditional, scope-limited).
- **For temporary**: when compliance will happen.
- **The decision-maker** (who needs to approve).

### Step 2: The right decider reviews

Different types of exceptions have different approvers:

| Exception type | Approver |
|---|---|
| Strategic deviation | [technical-strategist](../../technical-strategist/SKILL.md) |
| Security exception | Security specialist (or security team) — never the enforcer alone |
| Quality exception (testing, code design) | The relevant skill owner or senior engineer |
| Operational readiness exception | SRE specialist |
| Accessibility exception | Accessibility specialist (or [ux-design](../../ux-design/SKILL.md) owner) |
| ADR/DAD violation | The team-lead and the strategist together |

The enforcer routes the request to the right approver. The enforcer does *not* grant exceptions personally for any of the above categories — the approval comes from the relevant authority.

### Step 3: The approver decides

The decider reviews the request:

- **Approve as filed**: the exception is granted; the work proceeds.
- **Approve with modifications**: the exception is granted, but with additional mitigations or a tighter scope.
- **Reject**: the exception isn't legitimate; the work must come into compliance.
- **Defer for more information**: the request is incomplete; more details needed.

The decision is documented in the exception request itself, with the decider's name and date.

### Step 4: The exception is filed as an ADR

If approved, the exception becomes an ADR (managed by [team-lead](../../team-lead/SKILL.md)). The ADR captures:

- The deviation.
- The reason.
- The mitigations.
- The decider.
- The expiration (for temporary exceptions).

This makes the exception part of the team's permanent record. Future engineers reading the codebase can see *why* something deviates from the standard.

### Step 5: The work proceeds

With the exception approved and documented, the work proceeds. The enforcer marks the gate as approved with the exception cited.

### Step 6: For temporary exceptions, follow up

Temporary exceptions have an expiration. The enforcer (or the team) tracks the expiration and follows up:

- **Has the team complied by the deadline?** If yes, mark the exception as resolved.
- **If not**, what's the new plan? Renew the exception with a new deadline, or escalate.

Temporary exceptions that drift past their expiration become permanent by default — and that's the worst kind of exception, because the team committed to fixing it and didn't.

## The Difference Between Exception and Update

A subtle but important distinction:

- **Exception**: a one-off deviation from a standard that still applies in general.
- **Update**: a change to the standard itself.

If the team finds itself filing exceptions repeatedly for the same reason, the standard is wrong. The right response isn't more exceptions; it's to update the standard.

The enforcer surfaces this pattern: "We've granted three exceptions for X in the last quarter. The standard might need to be revisited." Routes to the source-of-truth skill or the strategist for a real update.

The opposite trap: changing the standard for a single case without a real reason. The standard should change because the team has *learned* something, not because one team lobbied for it.

## When Exceptions Aren't Granted

The enforcer should refuse the exception in these cases:

### "We need to ship Friday"

The deadline is not a reason. The fix is to address the deadline. The enforcer's response:

> "I understand the deadline. I can't grant the exception for this reason alone. Here are your options: (1) push the deadline, (2) scope the feature down so the standard can be met, (3) escalate to leadership to make a deliberate trade-off decision, or (4) file an exception with a different rationale that meets the criteria."

### "Everyone does it this way"

Cargo-culting is not a reason. The team's standards are the team's standards.

> "I hear you. The team's standard is X. If you want to change the standard, here's how to file a change with the source-of-truth skill. If you want a one-off exception, file one with a specific case-based rationale."

### "It's just this one time"

If it's just this one time, file the exception. If it can't be filed because the reasoning is weak, it shouldn't be granted.

> "If the rationale is real, file it. If the rationale is just 'this once,' I can't grant it without a real case."

### "The standard is wrong"

Maybe. The fix is to *change the standard*, not to grant a permanent exception.

> "If you think the standard is wrong, let's surface it to the source-of-truth skill or the strategist. We can change the standard if there's a real reason. In the meantime, the standard applies."

### "The PM said we can skip it"

The PM doesn't have the authority to waive technical standards. The enforcer escalates if necessary.

> "The PM has authority over scope and prioritization. They don't have authority to waive technical standards. If we genuinely need to deviate, the right path is an exception ADR with the right approver."

### "I'll file the exception after we ship"

After we ship is too late. The exception has to be filed *before* the gate is passed, not after.

> "The exception process exists to make deliberate decisions before they ship. After-the-fact exceptions are how the team gets into trouble. Let's file it now; if it's straightforward, the approval is fast."

## Exception Fatigue

A common failure mode: the exception process becomes a routine. The team files exceptions for everything; the enforcer rubber-stamps them; the standards become decoration.

Signs of exception fatigue:

- **Most reviews include exceptions.** If exceptions are normal, the standards aren't standards.
- **Exception requests are short and unspecific.** "We need to deviate because reasons."
- **Exception approvals are fast and unconsidered.** Nobody actually reviews the rationale.
- **Exceptions never expire.** Temporary exceptions become permanent silently.
- **The same exceptions get filed repeatedly.** The team is working around a standard that doesn't fit.

The cure: **periodic exception audit**. The strategist (or the enforcer) reviews all open exceptions:

- Are they still necessary?
- Have temporary exceptions expired?
- Are there patterns suggesting the standards need to change?
- Are the exceptions being granted thoughtfully or rubber-stamped?

A team with healthy exception hygiene has *few* open exceptions, *each one well-justified*, *each one tracked*. A team with rotted exception hygiene has dozens of open exceptions, mostly forgotten, mostly representing standards that are de facto dead.

## When the Enforcer Disagrees with the Approver

Sometimes the enforcer thinks an exception shouldn't be granted, but the approver grants it anyway. What then?

1. **Document the disagreement.** The enforcer's concerns are part of the exception record.
2. **Don't override the approver.** The enforcer applies the process; doesn't have the authority to override the strategist or security specialist.
3. **Escalate if the approver is wrong** in a way that creates real risk. The enforcer can go up the chain to the next level.
4. **Track the outcome.** If the exception turns out to cause a problem, the disagreement is on the record and informs future decisions.
5. **Don't sulk.** The decision was made by the right authority; the enforcer's job is to apply it.

The enforcer is part of a process, not the final word. Disagreement is fine; insubordination is not.

## When the Approver Refuses to Engage

A different failure: the team files an exception request and the approver doesn't respond. The exception is in limbo; the work is blocked.

The enforcer's response:

1. **Set a clear timeline** for the approver to respond. "If we don't hear back by Friday, we'll escalate."
2. **Escalate** if the timeline passes. To the approver's manager, or to leadership.
3. **Don't let the team ship the deviation** without approval. Without approval, the deviation is unauthorized.
4. **If the situation is urgent**, the team might need to find an alternative — an interim workaround that meets the standard, or a different approach entirely.

The enforcer's job is to surface the blockage and route it. Not to ignore it, and not to grant the exception personally.

## Anti-Patterns

- **No exception process at all.** Standards become rigid; the team bypasses them silently; standards lose all force.
- **Exception as default.** Exceptions for everything; standards become decoration.
- **The enforcer grants exceptions personally** without the right approver.
- **Exceptions without expiration** for things that should be temporary.
- **Exceptions that never get reviewed for compliance.** Temporary becomes permanent silently.
- **No audit of open exceptions.** The team accumulates dozens; nobody knows which are still relevant.
- **Exception requests without specifics.** "We need to deviate because reasons."
- **Approval without consideration.** Rubber-stamp.
- **Refusing all exceptions** because "the standard is the standard." Gatekeeping.
- **Granting exceptions for security baselines** without specialist review.
- **Granting exceptions for things the enforcer finds inconvenient.** Personal preference, not legitimate reasoning.
- **Inconsistent exception application.** Some teams get exceptions, others don't.
- **Hidden exceptions.** Granted in chat; never filed as ADRs; nobody else knows.
- **No follow-up on temporary exceptions.** They drift past expiration.
- **Exceptions that contradict each other.** Two exceptions for similar cases reach different conclusions.
- **Exception requests filed after-the-fact.** "We already shipped; let's document it."
- **Exception requests as a workaround for not changing the standard.** If you're filing the same exception repeatedly, the standard is wrong; fix the standard.

## Related

- [enforcement-philosophy.md](enforcement-philosophy.md) — why exceptions exist
- [the-gates.md](the-gates.md) — when exception requests come up
- [strategic-alignment-check.md](strategic-alignment-check.md) — strategic deviations
- [security-baseline-check.md](security-baseline-check.md) — security exceptions are constrained
- [escalation.md](escalation.md) — when exceptions can't be granted
- [team-lead](../../team-lead/SKILL.md) — exceptions are filed as ADRs
- [technical-strategist](../../technical-strategist/SKILL.md) — strategic exception approval
- [assets/exception-request-template.md](../assets/exception-request-template.md) — fillable template
