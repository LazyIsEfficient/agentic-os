# Runbook: <Service> — <Symptom>

> **Production response document.** Optimize for a stressed responder at 3am. Every section answers a question they will ask in the order they will ask it. If a section doesn't help them act in the next 10 minutes, delete it.

## Header

- **Service:** _____
- **Alert(s) that link here:** _____
- **Severity:** SEV _ (\_____ tier)
- **Owning team:** _____
- **Last verified:** YYYY-MM-DD by _____
- **Source of truth:** <link to source-controlled file>

> `Last verified` means a human walked through it end-to-end. Editing a typo doesn't change this date. If this date is older than 90 days, the runbook should be re-walked.

## 1. Symptom

What this looks like in *user terms*. One paragraph. No metric names, no internal jargon.

> _____

## 2. Verify the Alert Is Real

A short sequence of checks that confirms the alert isn't a false positive. Each step is a link or a one-line command. This step takes 60 seconds.

1. Open the dashboard: <link>
2. Confirm the symptom is visible in the last 5 minutes: _____
3. If you cannot confirm the symptom, this is likely a false positive. Silence here: <silence link>. Open a ticket to fix the alert: <ticket template link>.

## 3. Immediate Mitigation

The most important section. Listed in order of "try first." Each action is specific enough to execute without further research, with explicit blast radius and reversibility.

### Action 1: <name>

```
<exact command or click path>
```

- **Blast radius:** _____
- **Reversibility:** reversible | one-way (specify)
- **Expected time:** _____
- **What success looks like:** _____

### Action 2: <name>

```
<exact command>
```

- **Blast radius:** _____
- **Reversibility:** _____
- **Expected time:** _____
- **What success looks like:** _____

### Action 3 (last resort): <name>

```
<exact command>
```

- **Blast radius:** _____
- **Reversibility:** _____
- **Consult the IC before executing:** yes | no
- **What success looks like:** _____

## 4. Diagnosis (After Mitigation)

Investigate *after* the bleeding has stopped. This section is longer and less time-critical.

### Confirm the mitigation actually held

- Watch the symptom metric for at least 10 minutes after the action.
- It should drop to baseline within _____ seconds.
- If it doesn't, the mitigation may not be the right one — return to Section 3 with an updated hypothesis.

### Common causes (in order of likelihood)

1. **Recent deploy with a regression** — diff against last known good: `git diff <good>..<bad>`
2. **Dependency outage** — check upstream service status: <dashboard>
3. **Resource exhaustion** — check connection pool, queue depth, memory: <dashboard>
4. **Database lock contention** — check long-running queries: <query link>
5. **Configuration drift** — recent secret/config change: <audit log link>
6. _____

### Useful queries

```promql
# Error rate by endpoint
sum by (route) (rate(http_requests_total{status=~"5..", job="<service>"}[5m]))

# Slow requests
histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket{job="<service>"}[5m])))

# <add the queries you actually use during incidents>
```

### Decision tree

```
Is the deploy log clean for the last 30 min?
├── Yes → check dependencies (Section 4: cause #2)
│   ├── Healthy → check resources (Section 4: cause #3)
│   └── Unhealthy → page dependency owner (Section 5)
└── No → roll back (Section 3, Action 1)
```

## 5. Escalation

The runbook must answer: **who do I call if this is bigger than I can handle?**

- **Primary escalation** (secondary on-call): <link or phone>
- **Subject matter experts for this service:**
  - _____ (deploy / infrastructure)
  - _____ (business logic)
  - _____ (database / data)
- **Dependency teams** (if the cause is upstream):
  - _____ (page link)
  - _____ (page link)
- **Status page owner** (for SEV 1/2 customer comms): <link>
- **For SEV 1**: contact engineering management + post on `#incidents-leadership`

## 6. After the Incident

A short checklist for the responder to do *after* mitigation, before going back to bed.

- [ ] Status page updated to "monitoring" or "resolved"
- [ ] Internal channel updated with mitigation summary
- [ ] Postmortem owner assigned (if SEV 2 or higher)
- [ ] Anything in this runbook that was wrong, missing, or confusing has been noted (and a follow-up ticket filed to fix it)

## 7. Notes for Future Editors

Things the author wants the next editor to know. Add freely; this isn't a contract, it's a workshop.

> _____

---

## Maintenance

This runbook will be **walked end-to-end** during the next quarterly runbook review. Anything that's stale, broken, or missing will be fixed in the same session, and the `Last verified` date in the header will be updated.

If you walk through this runbook for any reason — incident, gameday, or quarterly review — please update the `Last verified` date.
