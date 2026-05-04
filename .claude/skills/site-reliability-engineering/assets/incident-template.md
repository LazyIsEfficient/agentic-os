# Incident: <one-line summary>

> Fillable template. Update *during* the incident, not after. The IC owns this document.

## Header

- **Incident ID:** INC-_____
- **Severity:** SEV _ (started as SEV _)
- **Status:** investigating | mitigating | mitigated | resolved
- **Started:** YYYY-MM-DD HH:MM UTC
- **Mitigated:** YYYY-MM-DD HH:MM UTC
- **Resolved:** YYYY-MM-DD HH:MM UTC
- **Incident channel:** #inc-_____
- **Public status page:** <link or "not yet posted">

## Roles

- **Incident Commander:** _____
- **Operations / SME:** _____
- **Comms lead:** _____
- **Scribe:** _____
- **Observer / shadow:** _____

## Current State (update continuously)

**One-paragraph summary** of what is currently happening, what has been tried, and what is being tried next. Rewrite this section every time the situation changes.

> _____

## Impact

- **Services affected:** _____
- **User-visible symptom:** _____
- **Estimated affected users:** _____
- **Affected regions:** _____
- **Business impact (if known):** _____
- **SLO budget consumed (estimated):** _____ %

## Hypotheses

A running list of what we *think* is happening, with status. Update as we learn.

- [ ] Hypothesis 1: _____ — status: _____
- [ ] Hypothesis 2: _____ — status: ruled out at HH:MM because _____
- [ ] Hypothesis 3: _____ — status: confirmed at HH:MM via _____

## Actions Taken

A real-time log of what we've actually done. Each entry has a timestamp, an actor, and a result.

| Time (UTC) | Actor | Action | Result |
|---|---|---|---|
| HH:MM | Glenn | Acknowledged page; opened incident channel | — |
| HH:MM | Glenn | Confirmed alert real via dashboard | error rate 3.2% over 5 min |
| HH:MM | Alex | Joined as ops; initiated rollback of payments-svc to v1.41 | rollback completed at HH:MM |
| HH:MM | Glenn | Posted status update to channel and stakeholders | — |
| HH:MM | Sam | Confirmed error rate dropping after rollback | back to baseline within 90s |

## Asks (what we need from others)

If we need help, list it here so people scrolling the channel can see at a glance.

- [ ] Need DBA to confirm no schema lock from the rollback — _owner:_ _____
- [ ] Need comms team to update public status page — _owner:_ _____
- [ ] Need product to confirm impact estimate — _owner:_ _____

## Communications Log

A copy (or summary) of every status update sent, with audience and time.

| Time (UTC) | Audience | Channel | Summary |
|---|---|---|---|
| HH:MM | Internal eng | #incidents | Initial SEV2 declaration |
| HH:MM | Customers | Status page | "We are investigating reports of failed checkouts in the EU region." |
| HH:MM | Internal eng | #incidents | Mitigation in progress: rollback initiated |
| HH:MM | Customers | Status page | "We have identified the issue and are deploying a fix." |
| HH:MM | Internal eng | #incidents | Mitigation confirmed; service stable |
| HH:MM | Customers | Status page | "The issue has been resolved. We are continuing to monitor." |

## Decision Log

Significant calls made during the incident — for the postmortem.

- HH:MM — IC decided to roll back rather than wait for diagnosis. Rationale: visible customer impact + recent deploy correlation. Alternative considered: scale up first; rejected because deploy was the most likely cause.
- HH:MM — IC decided not to escalate to SEV1 despite SLO burn. Rationale: scope was contained to one region; mitigation was already in flight.

## Mitigation Confirmation

- [ ] Symptom no longer observed
- [ ] Watched for at least 15 minutes after mitigation
- [ ] Status page updated to "mitigated" / "monitoring"
- [ ] Internal channel updated
- [ ] Customer-impacting comms closed out

## Cooldown / Handoff

- [ ] Postmortem owner assigned: _____
- [ ] Postmortem scheduled for: _____
- [ ] Incident channel tagged `mitigated`
- [ ] Outgoing IC has briefed any incoming responders
- [ ] On-call has resumed normal duties or handed off

## Notes for the Postmortem

Things the IC notices during the incident that would otherwise be lost. Add to this freely; the postmortem author will use them.

> _____
