# Postmortem: <one-line title>

> **Blameless.** Frame contributing factors, not culprits. Use passive voice for actions, active voice for systems. If a sentence names a person as the cause, rewrite it.

## Header

- **Incident ID:** INC-_____
- **Date of incident:** YYYY-MM-DD
- **Severity:** SEV _
- **Duration:** _____ (start → mitigated)
- **Author:** _____
- **Reviewers:** _____
- **Postmortem review meeting:** YYYY-MM-DD
- **Status:** draft | reviewed | published

## 1. Summary

Three or four plain-English sentences. A non-technical reader should understand what broke, who was affected, and how it was resolved.

> _____

## 2. Impact

- **Users affected:** _____
- **Duration of user impact:** _____
- **Quantified business impact:** _____
- **SLO impact:** ___ % of monthly error budget consumed
- **Data integrity impact:** none | suspected | confirmed (describe)
- **Security implications:** none | yes (describe; loop in security-engineering)

## 3. Timeline

All times in UTC. Pull from the incident channel where possible.

| Time | Event |
|---|---|
| HH:MM | Deploy of `service` v1.42 to production. |
| HH:MM | Burn-rate alert fires (5m window, rate 22×). |
| HH:MM | On-call ack'd page; opened incident channel. |
| HH:MM | IC declared SEV2; first internal status update. |
| HH:MM | Initial hypothesis (dependency outage); investigation began in parallel with mitigation. |
| HH:MM | Hypothesis updated to deploy correlation; rollback initiated. |
| HH:MM | Rollback complete. |
| HH:MM | Error rate returned to baseline. |
| HH:MM | Mitigation declared in channel and on status page. |
| HH:MM | Underlying cause identified (see Contributing Factors). |
| HH:MM | Incident closed. |

## 4. Contributing Factors

Resist a single "root cause." List every factor that combined to produce the incident, and for each one say what would have prevented it.

### 4.1 _____

- **What it was:** _____
- **Why it was there:** _____
- **What would have prevented it from contributing:** _____

### 4.2 _____

- **What it was:** _____
- **Why it was there:** _____
- **What would have prevented it from contributing:** _____

### 4.3 _____

- **What it was:** _____
- **Why it was there:** _____
- **What would have prevented it from contributing:** _____

## 5. What Went Well

Mandatory section. Name what worked. Postmortems that only enumerate failures train teams to expect blame.

- _____
- _____
- _____

## 6. What Could Have Gone Better

The honest counterpart to "what went well." Specific things that made the incident harder, longer, or more stressful.

- _____
- _____
- _____

## 7. Action Items

Each item must be **specific, owned, prioritized, and tracked as a real ticket**. "TBD" owner = "never." Vague items = won't ship.

| # | Action item | Owner | Priority | Ticket | Status |
|---|---|---|---|---|---|
| 1 | _____ | _____ | P0 \| P1 \| P2 | _____ | open |
| 2 | _____ | _____ | P0 \| P1 \| P2 | _____ | open |
| 3 | _____ | _____ | P0 \| P1 \| P2 | _____ | open |
| 4 | _____ | _____ | P0 \| P1 \| P2 | _____ | open |
| 5 | _____ | _____ | P0 \| P1 \| P2 | _____ | open |

**Priority key:**
- **P0** — must ship before the next normal sprint. Blocks new feature work for the owning team.
- **P1** — must ship this quarter.
- **P2** — backlog with intent to ship within 6 months.

## 8. Lessons Learned

Things that don't fit cleanly as action items but are worth remembering. Free-form prose, two or three short paragraphs.

> _____

## 9. Glossary (if needed)

For readers outside the immediate team. Define any acronyms or service names that aren't obvious.

- _____ — _____
- _____ — _____

## 10. Related Postmortems

Link any previous postmortems with overlapping causes. If three incidents share a contributing factor, that pattern matters.

- INC-_____ — _____
- INC-_____ — _____

---

## Pre-Publication Checklist

Before sharing:

- [ ] No sentence names a person as the cause.
- [ ] Every action item has an owner and a ticket.
- [ ] The timeline is in UTC and matches the incident channel.
- [ ] "What went well" is filled in (not just failures).
- [ ] A non-technical reader can understand the summary.
- [ ] If this postmortem identifies a recurring pattern, related postmortems are linked.
- [ ] The postmortem review meeting has been scheduled.
