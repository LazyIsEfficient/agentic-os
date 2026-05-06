# Alerting and Paging

An alert is a promise to a human: *something is happening that you need to act on right now*. Every promise the system makes that it doesn't keep — false page, vague page, page with no runbook — erodes the responder's trust until they start ignoring the pager.

The hardest part of alerting is not adding alerts. It's having the discipline to delete the ones that aren't earning their place.

## The Three Tiers

| Tier | Channel | Latency to act | Criterion |
|---|---|---|---|
| **Page** | Phone call, SMS, push notification that bypasses Do Not Disturb | Minutes | A human must intervene *now*, or users will continue to suffer |
| **Ticket / Alert** | Chat channel, email, ticket queue | Hours (next business day) | Something needs attention soon, but not at 3am |
| **Log / Dashboard** | Logged for retrospective analysis | Whenever | Data for investigation; never demands action by itself |

The mistake is to use one tier for everything. "Send it all to Slack and we'll figure it out" trains the team to ignore Slack.

## What to Page On (Symptoms)

> **Page on user pain. Everything else is a ticket or a log line.**

Concretely, paging conditions almost always come from:

- **SLO burn-rate alerts** — see [slis-slos-error-budgets.md](slis-slos-error-budgets.md). This is the gold standard.
- **Total outage** — health check fails, no traffic flowing, dependency completely unreachable.
- **Security incidents** — see [security-engineering](../../security-engineering/SKILL.md).
- **Data integrity** — corruption, divergence, "two services disagree about the truth."

Notice what's *not* on this list:

- CPU > 80%
- Disk > 70%
- A pod restart
- Memory above some threshold
- A specific exception in logs

These are *causes*, not symptoms. They may or may not produce user pain. Page on the user pain; put the cause on a dashboard so you can find it during the incident.

## What to Ticket On (Causes That Aren't Yet Hurting)

Cause-based alerts are still useful — they tell you "something is degrading, look into it before it becomes user pain." They just don't deserve a 3am wake-up.

Examples:

- Disk usage trending toward full in the next 7 days.
- A non-critical background job has been failing for 3 hours.
- Certificate expires in 14 days.
- A dependency's error rate has doubled but is still within budget.
- A canary is showing higher latency than the baseline (block the rollout, ticket the team).

These create *work*, not panic.

## Severity Tiers

A standard severity scale with consistent meaning across services:

| Severity | Customer impact | Response |
|---|---|---|
| **SEV 1** | Major outage, large fraction of users affected, major revenue/safety impact | Wake everyone, page leadership, public status page, war room |
| **SEV 2** | Significant degradation, subset of users or one major feature broken | Page primary on-call, internal status update, IC assigned |
| **SEV 3** | Minor degradation, edge cases, single-customer issue | Ticket for next business day, investigate and fix in normal flow |
| **SEV 4** | Cosmetic, non-impacting, monitoring noise | Log only, fix when convenient |

Two rules:

- **Severity is decided by impact, not by the team's stress level.** A scary-looking metric on an internal service is not SEV 1 if no customer notices.
- **Severity can change during the incident.** Start at the highest plausible level and downgrade as you learn. Going up after starting low is harder than going down.

## Anatomy of a Good Alert

A page that arrives in the middle of the night should answer five questions in the first 30 seconds of reading:

1. **What is broken?** (One sentence in plain English. Not a metric name.)
2. **How bad?** (Affected users / endpoints / regions. Quantified.)
3. **How do I see more?** (Direct link to a dashboard scoped to this incident.)
4. **What do I do next?** (Direct link to the [runbook](runbooks.md). Not "see wiki.")
5. **Who else should know?** (Owning team, escalation path.)

A bad alert: `CRITICAL: NodeMemoryUsageHigh fired on node-prod-7`. Forces the responder to look up what NodeMemoryUsageHigh means, what node-prod-7 does, and whether it matters.

A good alert:

```
[SEV2] Checkout API error rate burning 14× SLO budget (last 5m)

Service:  checkout-api
Region:   us-east-1
Impact:   ~3% of checkout requests failing with 5xx for the last 6 minutes
Owner:    payments-team
Dashboard: https://grafana.example.com/d/checkout-api?from=now-1h
Runbook:   https://runbooks.example.com/checkout-api/elevated-error-rate
Slack:    #incident-channel will be auto-created on ack
```

If your alerting system doesn't let you template all of this, fix the alerting system before fixing the alerts.

## Alert Fatigue and Deletion Criteria

Alert fatigue is a real, measurable phenomenon. When responders are paged too often — especially for things they can't act on — they start to:

1. Acknowledge without reading.
2. Snooze without investigating.
3. Miss real incidents because the noise has trained them to dismiss the channel.

**Treat alert noise as a P0 incident in itself.** A team with 50 pages a week is a team that will miss the one that matters.

### Hard rules

- **Every page must be actionable.** If the on-call cannot do something specific in response, the alert is broken — fix it or delete it.
- **Every page must have a runbook.** No runbook → no alert.
- **Every page must have an owner.** If nobody owns it, it goes to nobody, which is the same as not existing.
- **Track page volume per rotation per week.** If a single rotation is paged more than once per shift on average, the rotation is unsustainable; reduce the alerts before the people break.

### The four reasons to delete an alert

1. **It hasn't fired in 6 months and nobody can remember why it exists.** Delete.
2. **It fires regularly and the response is always "ack and move on."** Delete or rewrite the threshold.
3. **It fires, the responder looks at the runbook, and the runbook says "wait 15 minutes; usually self-resolves."** Delete.
4. **It's redundant with another alert that already pages.** Delete the noisier one.

Hold a monthly "alert review" meeting. The agenda is one item: which alerts deserve to live for another month?

## Escalation and Acknowledgment

A page that nobody acknowledges within X minutes must escalate automatically. Defaults:

- **Page primary on-call** → 5 minutes to ack.
- If unacked: **page secondary on-call** → another 5 minutes.
- If still unacked: **page the team lead or a separate escalation rotation**.
- Eventually: **wake the engineering manager or the directly responsible individual**.

The escalation chain is *the alerting system's responsibility*, not the responder's. Build it once into PagerDuty / Opsgenie / your tool of choice; do not rely on responders to "call someone."

## Multi-Window, Multi-Burn-Rate (the only pattern that mostly works)

For SLO-based alerts, see [slis-slos-error-budgets.md](slis-slos-error-budgets.md#burn-rate-alerting-the-only-alert-pattern-that-actually-works) for the precise patterns. The short version:

- A single threshold ("error rate > 1%") is too noisy or too late.
- A single window ("error rate over the last hour") is either too laggy (long window) or too jittery (short window).
- Combine **two windows** (long for stability, short for speed) and **two burn rates** (one fast, page severity; one slow, ticket severity).

This pattern is the most important alerting innovation of the last decade. Use it.

## Page-Worthy vs Ticket-Worthy: Worked Examples

| Symptom | Tier | Why |
|---|---|---|
| 5% of users seeing 5xx errors right now | **Page (SEV2)** | Active user pain |
| Health check failing for one of three pods | **Ticket** | No user impact yet (load balancer routing around) |
| Disk on the database will be full in 12 hours | **Page (SEV2)** | Will become user pain before business hours |
| Disk on a worker node will be full in 5 days | **Ticket** | Plenty of time |
| Background job hasn't completed in 6 hours; SLO is "fresh within 30 min" | **Page (SEV2)** | Freshness SLO will be breached soon |
| Background job hasn't completed in 6 hours; no freshness SLO | **Ticket** | Suspicious but not user-visible |
| Certificate expires in 14 days | **Ticket** | Long lead time |
| Certificate expires in 12 hours | **Page (SEV2)** | Will cause an outage; nothing else qualifies as actionable in this window |
| Memory usage at 90% on one node | **Log only** | Cause, not symptom |
| Memory usage at 90% on one node *and* requests to that node failing | **Page (SEV2)** | Now it's a symptom |
| Single user reports broken checkout | **Ticket** | Not yet a pattern; investigate, escalate if real |
| 50 users in 5 minutes report broken checkout | **Page (SEV1)** | Pattern; SLO probably breached |

## Anti-Patterns

- **The "informational" page.** "Just letting you know." There is no such thing. If it doesn't need action, it's not a page.
- **The dashboard alert.** "Page on `cpu_seconds_total > X`." CPU is a cause, not a symptom. Move it to a dashboard.
- **The team-wide page.** Pages everyone in a team channel. Diffuses responsibility; ensures nobody owns it.
- **The page chain reaction.** One symptom causes ten correlated alerts to fire. Fix by adding an inhibition rule, or by alerting on the upstream cause only.
- **The unsnoozable.** Alert that can't be silenced during planned maintenance. Maintenance window support is non-negotiable.
- **The "we'll fix it later" alert.** Known false positive that everyone agrees to dismiss "until we have time." That time never comes; meanwhile responders learn to ignore the alert and miss real incidents.
- **The page that depends on the system being up.** Health check that fails when monitoring fails. Independent monitoring infrastructure or you're flying blind exactly when you need to see.
- **The vague page.** `Something is wrong with billing`. Forces the responder to start from zero. Be specific.
- **The page with no link.** No dashboard, no runbook. The responder spends ten minutes finding context before they can act.

## Related

- [slis-slos-error-budgets.md](slis-slos-error-budgets.md) — burn-rate alerting in detail
- [runbooks.md](runbooks.md) — what every page must link to
- [incident-response.md](incident-response.md) — what happens after a page is acknowledged
- [on-call.md](on-call.md) — protecting the humans who respond to pages
- [system-architect/references/observability.md](../../system-architect/references/observability.md) — designing the metrics the alerts run on
