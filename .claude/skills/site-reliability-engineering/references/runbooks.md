# Runbooks

A runbook is the document the on-call opens at 3am. Its purpose is to make the next 30 minutes survivable: confirm what's happening, take the right action, escalate if needed, leave the system better than before.

A runbook is **not** a manual, a design doc, or an architectural overview. It is a *production response document*. Treat anything that doesn't directly help a stressed responder act as noise — and delete it.

## The Hard Rule

> **Every alert that pages a human links to a runbook. No runbook → no alert.**

This is non-negotiable. The cost of authoring a runbook is much smaller than the cost of one responder fumbling through diagnosis at 3am. If you're tempted to add an alert without a runbook, *delete the alert until the runbook exists.*

## Anatomy of a Useful Runbook

Every runbook has the same six sections, in the same order. Consistency matters: the responder knows where to find each thing without thinking.

### 1. Header

- **Service:** which service this runbook is for
- **Alert(s):** the names of the alerts that link here
- **Severity:** the severity these alerts fire at
- **Owning team:** who maintains this runbook (and is accountable when it's stale)
- **Last verified:** date a human last actually walked through it (not "last edited" — that's a lie people game)

### 2. Symptom

A plain-English description of what the alert *means in user terms*. One paragraph.

> "The Checkout API is returning 5xx errors at a rate that will exhaust our error budget within an hour if it continues. Customers attempting to complete a purchase will see an error message and their cart will not be processed."

Notice: this is about the *user*, not the metric. The metric details belong in the dashboards.

### 3. Verify the Alert Is Real

A short list of checks that confirm the alert isn't a false positive. Two or three items, each a link or a one-line command.

- Open the dashboard: <link>
- Confirm error rate visible in the last 5 minutes: should be > 1%
- If error rate is < 0.1%, the alert is a false positive. Silence and ticket: <silence link>

This step takes 60 seconds and saves the responder from chasing a phantom incident.

### 4. Immediate Mitigation

The single most important section. **What does the responder do *first*, before they understand anything?**

- Bullet list of mitigation actions, in order of "try first."
- Each action specific enough to execute without further research: command, link to a runbook button, or specific UI path.
- Each action notes its **blast radius** and **reversibility**.

```
1. Check the deploy log for any release in the last 30 minutes.
   - If yes: roll back via `make rollback SERVICE=checkout-api`. Reversible. Takes ~3 minutes.

2. If no recent deploy, check upstream dependency health: <dashboard link>.
   - If a dependency is unhealthy, check that team's status page. If the dependency owner is unaware, page them: <escalation link>.

3. If neither: scale up the service to 2x current replicas via `make scale SERVICE=checkout-api COUNT=20`.
   - Reversible. Takes ~90s. Costs ~$X/hour.

4. If still failing: drain the affected region and route traffic to standby region. <link to drain command>
   - Higher blast radius. Use only after steps 1-3.
```

The responder should be able to execute step 1 within 60 seconds of opening the runbook. If they can't, the runbook is wrong.

### 5. Diagnosis (After Mitigation)

How to investigate *once the bleeding has stopped*. This section is longer and less time-critical:

- Where to look in logs / traces / metrics.
- Common causes and their fingerprints.
- Useful queries (PromQL, BigQuery, log search) that the responder can copy-paste.
- Decision tree for common branching paths.

```
## Diagnosis after mitigation

### Confirm what the rollback (or other action) actually fixed
- Watch the error rate for 10 minutes after mitigation. It should drop to baseline within 60 seconds.
- If it doesn't, mitigation may not have been the right one — return to mitigation steps.

### Common causes
1. **Recent deploy with a regression** — most common. Compare last good and current versions: `git diff <good>..<bad> -- src/`
2. **Dependency failure** — check upstream service status and our retry/circuit-breaker metrics: <dashboard>
3. **Resource exhaustion** — check connection pool saturation, queue depth, memory: <dashboard>
4. **Database lock contention** — check pg_stat_activity: <query link>
5. **Configuration drift** — recent secrets/config change: <audit log link>

### Useful queries
- Error breakdown by endpoint: `sum by (route) (rate(http_requests_total{status=~"5..", job="checkout"}[5m]))`
- Slow requests: `histogram_quantile(0.99, sum by (le) (rate(http_request_duration_seconds_bucket{job="checkout"}[5m])))`
```

### 6. Escalation

Who to call when the runbook isn't enough.

- **Primary escalation** (on-call's secondary or team lead): <link or phone>
- **Subject matter experts** for this service: <names + how to reach>
- **Dependency teams** in case the cause is upstream: <list of dependency teams>
- **Status page owner** for SEV 1 communications: <link>

This section exists so the responder doesn't have to make a judgment call about who to wake up. The runbook tells them.

## What Belongs in a Runbook (and What Doesn't)

| Belongs | Doesn't belong |
|---|---|
| The exact command to run | The history of why the service was built |
| Direct links to dashboards | A list of every dashboard the team has |
| The escalation phone number / chat handle | A complete org chart |
| Common causes with concrete diagnostic queries | A theoretical taxonomy of failure modes |
| What to tell customers (for customer-impact alerts) | The full content of the marketing FAQ |
| When to wake the team lead | A debate about whether the team lead should be on call |

The test for any runbook content: **does this help the responder act in the next 10 minutes?** If yes, keep it. If no, move it to a design doc, an architecture doc, or a wiki.

## Keeping Runbooks Alive

Runbooks rot. The system changes; the runbook lags; eventually it's wrong, and the responder following it makes things worse. Three practices prevent this:

### 1. Verify after every incident that used the runbook

After any incident where the responder opened the runbook, the IC notes (in the postmortem) whether the runbook helped, was wrong, or was missing steps. The runbook owner has 5 business days to update.

### 2. Schedule a "runbook walkthrough" exercise

Once per quarter (or per major architecture change), pick a runbook and have someone *walk through it on a non-production environment*. They run the commands, click the links, confirm the dashboards exist. Anything broken gets fixed in the same session.

This is the one thing that catches link rot, command-flag drift, dashboard renames, and stale URLs before they bite a real responder.

### 3. Track "last verified" honestly

The header field is `Last verified: 2026-04-07`, not "Last edited." If you tweak a typo, the verified date doesn't change. If you walk through it end to end, it does.

A monthly report lists every runbook whose `Last verified` date is more than 90 days old. The owning team is responsible for re-verifying.

## When to Write a New Runbook

Required:

- Whenever a new alert is added that pages humans.
- After any **incident with no runbook** — the postmortem creates one as an action item.
- After any **incident where the existing runbook was wrong** — the postmortem fixes it.

Optional but good:

- For complex *operations* the team does manually, even if not alert-driven (database failover, secret rotation, region drain). These are operational runbooks; they prevent toil-induced mistakes.

## When to Delete a Runbook

A runbook should be deleted if:

- The alert it serves has been deleted.
- The service it serves has been retired.
- The "last verified" date is more than a year old and nobody can be found who knows what it does.
- The runbook tells the responder to "wait and see if it self-resolves" (in which case, delete the *alert* too — it's not actionable).

A short, accurate runbook beats a long, stale one every time.

## Runbook Hygiene Rules

- **One alert ⇒ one runbook.** Don't share a runbook across alerts that have meaningfully different responses. If two alerts deserve the same response, merge the alerts.
- **Linked from the alert text itself.** Not "see the wiki." Not "find it in Confluence." A clickable link in the page payload that opens the runbook.
- **Versioned.** A runbook lives in source control next to the code it describes. Reviewable in PRs. Changes have history.
- **Searchable.** Indexed; the responder can find it by service name, alert name, or symptom.
- **Idempotent commands.** Mitigation commands should be safe to run twice. The responder *will* run them twice when they're stressed.

## A Worked Example

```markdown
# Runbook: Checkout API — Elevated Error Rate

**Service:** checkout-api
**Alert(s):** CheckoutAPIErrorRateBurnRateFast, CheckoutAPIErrorRateBurnRateSlow
**Severity:** SEV 2 (fast burn) / SEV 3 (slow burn)
**Owning team:** payments
**Last verified:** 2026-03-22

## Symptom

The Checkout API is returning 5xx errors faster than our SLO budget allows.
Customers trying to complete a purchase will see an error and their cart
will not be processed.

## Verify the Alert Is Real

1. Open the dashboard: https://grafana.example.com/d/checkout-api
2. Confirm 5xx rate > 1% over the last 5 minutes
3. If rate < 0.1%, this is a false positive. Silence: https://alerts.example.com/silence/checkoutapi

## Immediate Mitigation

1. **Check for a recent deploy** (last 30 min): https://deploys.example.com/checkout-api
   - If yes: `make rollback SERVICE=checkout-api`. Takes ~3 min, reversible.
   - Confirm error rate drops within 60s after rollback completes.

2. **Check upstream dependencies:** https://grafana.example.com/d/checkout-deps
   - If `payment-gateway` shows red, page that team: https://pages.example.com/team/gateway
   - If `inventory-service` shows red, page that team: https://pages.example.com/team/inventory

3. **Scale up** if no clear cause:
   - `make scale SERVICE=checkout-api COUNT=20`
   - Doubles capacity. Reversible. Costs ~$8/hour at this scale.

4. **Drain affected region:**
   - Only if steps 1–3 don't work and impact is region-correlated.
   - `make drain REGION=us-east-1 SERVICE=checkout-api`
   - Higher blast radius; consult IC before executing.

## Diagnosis After Mitigation

### Confirm mitigation held
- Watch error rate for 10 minutes after the action.
- If it doesn't drop to baseline, return to mitigation steps.

### Common causes
1. **Recent deploy regression** (most common) — diff the deploys, look for changes in `src/payment/`.
2. **Payment gateway outage** — check vendor status: https://status.payment-gateway.com
3. **Database connection pool exhaustion** — check `pgbouncer_pools`: <dashboard>
4. **Inventory service slow** — check upstream p99: <dashboard>

### Useful queries
- Error rate by endpoint: `sum by (route) (rate(http_requests_total{status=~"5..", job="checkout"}[5m]))`
- Top failing routes: `topk(5, sum by (route) (rate(http_requests_total{status=~"5..", job="checkout"}[5m])))`

## Escalation

- **Primary escalation:** payments team secondary on-call → https://pages.example.com/payments-secondary
- **SMEs:** Glenn (deploy/infra), Alex (payment logic), Sam (database)
- **For SEV 1:** contact the engineering manager + post on #incidents-leadership
- **Status page:** https://status.example.com/admin (post if customer-facing for > 5 minutes)
```

## Anti-Patterns

- **Wiki-as-runbook.** Pages of background, no clear action steps. The responder reads for 10 minutes and still doesn't know what to do.
- **Linkfarm runbook.** Just a list of dashboards with no guidance. "Look at these and figure it out."
- **Stale runbook.** Commands that no longer work, dashboards that have been renamed, escalation paths to people who left the company.
- **The "see code" runbook.** "If the alert fires, look at the source code." Useless under stress.
- **The runbook that requires a runbook.** Steps assume context the responder doesn't have. Test by giving the runbook to someone unfamiliar with the service.
- **No `Last verified` field.** Or worse: a `Last verified` field that nobody updates honestly.
- **Escalation that says "ask the team."** Which team? Whose phone? Be specific.
- **Speculation in the runbook.** "It might be the database, or possibly the cache, or maybe..." A diagnostic decision tree, not a list of guesses.
- **Mitigation steps that aren't reversible** without warning. The responder needs to know the blast radius before they execute.
- **"Wait 15 minutes; usually self-resolves."** Then the alert isn't actionable. Delete the alert.

## Related

- [alerting-and-paging.md](alerting-and-paging.md) — every alert links to a runbook
- [incident-response.md](incident-response.md) — the runbook is opened in step 6 of the first five minutes
- [postmortems.md](postmortems.md) — runbook improvements are common action items
- [toil-and-automation.md](toil-and-automation.md) — runbook step 1 done twice → runbook step 1 becomes a script
- [assets/runbook-template.md](../assets/runbook-template.md) — fillable runbook template
