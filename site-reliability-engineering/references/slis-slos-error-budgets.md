# SLIs, SLOs, and Error Budgets — In Production

The architect picks SLO *targets* (see [system-architect/references/observability.md](../../system-architect/references/observability.md)). This file is about *operationalizing* them: how to measure, alert, report, and use them as a contract with the product team.

## Vocabulary, Precisely

| Term | Definition | Example |
|---|---|---|
| **SLI** (Service Level Indicator) | A *measurement* of some aspect of service behavior | "Fraction of HTTP requests that return a 2xx/3xx response within 500ms" |
| **SLO** (Service Level Objective) | A *target* for an SLI over a window | "99.9% of requests succeed within 500ms over a rolling 28 days" |
| **SLA** (Service Level Agreement) | A *contract* with users that has consequences (refunds, credits) when violated | "If we miss 99.5% in a month, customer gets 10% credit" |
| **Error Budget** | `1 - SLO` over the window — how much unreliability is *allowed* | At 99.9% over 28 days: 40 minutes 19 seconds of failure budget |

The most common confusion: **SLOs are not SLAs.** Always set the internal SLO *tighter* than any external SLA — give yourself headroom to detect and respond before the contract triggers.

## Picking SLIs That Matter

A good SLI:

1. **Reflects user experience.** "Did the user get the thing they asked for, in time?" — not "did the server's CPU stay below 80%."
2. **Is a ratio of "good events" over "valid events"**, expressed as a percentage. Easy to reason about and to combine across services.
3. **Has clear "good" and "valid" definitions** that survive a code review.
4. **Comes from data you already collect** — don't introduce new instrumentation just to satisfy SRE.

### The four golden signals (Google SRE)

For most user-facing services, start here:

- **Latency** — how long requests take (split successful vs failed; failed requests can be misleadingly fast).
- **Traffic** — how much demand the service is experiencing (RPS, concurrent users).
- **Errors** — fraction of requests that fail (explicitly errored, returned wrong content, took too long).
- **Saturation** — how "full" the service is (queue depth, thread pool utilization, connection pool).

Latency and errors usually become SLIs. Traffic and saturation usually become *capacity signals* and dashboard/alert inputs, not SLOs themselves.

### RED and USE — alternatives for different lenses

- **RED** (Tom Wilkie) — *Rate, Errors, Duration*. For request-driven services. Effectively the golden signals minus saturation.
- **USE** (Brendan Gregg) — *Utilization, Saturation, Errors*. For resources (CPU, disk, network).

Use RED for services, USE for the resources underneath them. Together they give you "is the service working" and "is the substrate healthy."

## Defining an SLO Concretely

A complete SLO statement contains six things:

1. **The SLI** (the ratio).
2. **The threshold** (99.9%).
3. **The window** (rolling 28 days).
4. **The user perspective** (which clients/endpoints are included).
5. **The exclusions** (planned maintenance windows, requests with malformed input).
6. **The owner** (a team that will respond when it's at risk).

Example:

> **Checkout API availability SLO**
> 99.9% of HTTP requests to `/api/v1/checkout/*` from clients other than the synthetic monitoring system, excluding requests that return `400` due to client-side validation errors, will complete with a 2xx response within 800ms, measured over a rolling 28-day window. Owned by the Payments team.

If you can't write the statement in one paragraph, the SLO isn't crisp enough yet.

## The Error Budget

`Error budget = 100% - SLO target`, expressed as time, requests, or both.

| SLO | Budget per 28 days (time) |
|---|---|
| 99% | ~6h 43m |
| 99.5% | ~3h 21m |
| 99.9% | ~40m |
| 99.95% | ~20m |
| 99.99% | ~4m |
| 99.999% | ~24s |

Two practical lessons from this table:

- **Each "9" is roughly 10× more expensive.** Going from 99.9% to 99.99% is the same effort multiple as going from 99% to 99.9%. Don't add nines without a reason a CFO would accept.
- **Above 99.99% you can't even *deploy*.** Most CI/CD pipelines take longer than 4 minutes; a single bad deploy blows a month of budget. If you genuinely need 4 nines or better, your release strategy must account for it (canaries, automatic rollback under tens of seconds).

## Burn-Rate Alerting (the only alert pattern that actually works)

A naive alert ("if budget remaining < 0%") fires too late. A naive threshold alert ("error rate > 1%") is too noisy. The right pattern is **multi-window, multi-burn-rate alerts**.

The idea: alert when the error budget is being burned through *fast enough that, if the current rate continued, the budget would be exhausted before the team could respond*.

### Burn rate

> `Burn rate = (current error rate) / (SLO error rate)`

A burn rate of 1.0 means you're using budget exactly as fast as the SLO allows. A burn rate of 14.4 means you'd burn the entire 30-day budget in ~50 hours.

### Two-window alert (Google SRE workbook)

| Severity | Long window | Short window | Burn rate threshold | Budget consumed if not fixed |
|---|---|---|---|---|
| **Page** | 1 hour | 5 min | ≥ 14.4 | 2% of monthly budget per hour |
| **Page** | 6 hours | 30 min | ≥ 6 | ~5% per 6h |
| **Ticket** | 24 hours | 2 hours | ≥ 1 | "we are over our SLO budget pace, fix during business hours" |
| **Ticket** | 72 hours | 6 hours | ≥ 1 | slow burn that will eventually matter |

The **two windows** prevent false positives: the long window confirms the burn is sustained; the short window ensures the alert fires quickly when the burn starts. An alert only fires if *both* are above the threshold.

### Example PromQL

```promql
# Page severity (fast burn)
(
  sum(rate(http_requests_total{job="checkout", status=~"5.."}[1h]))
  /
  sum(rate(http_requests_total{job="checkout"}[1h]))
) > (14.4 * 0.001)  # 0.001 = 1 - 0.999 SLO
AND
(
  sum(rate(http_requests_total{job="checkout", status=~"5.."}[5m]))
  /
  sum(rate(http_requests_total{job="checkout"}[5m]))
) > (14.4 * 0.001)
```

## Error Budget Policy

The error budget is a *contract*. Without an explicit policy, the budget is just a metric on a dashboard.

A useful policy is one paragraph that everyone — engineering, product, leadership — has signed off on, in writing, **before the budget is ever exhausted**:

> **Checkout API Error Budget Policy**
>
> When the rolling 28-day error budget for the Checkout API is between 100% and 25% remaining, normal release cadence applies. Between 25% and 0%, only changes that improve reliability or fix the root cause are released; feature work pauses. When the budget is exhausted, all non-reliability releases are halted and a dedicated reliability sprint begins until the budget is restored to ≥ 50%. The Payments team lead and the product manager for Checkout jointly approve any deviation from this policy.

The hard part is not writing the policy. It's the first time you have to enforce it against pressure to ship a feature. The policy is what protects you from that pressure.

## How Many SLOs?

A common mistake is having an SLO for every endpoint and every dependency. The tax of maintaining them exceeds the value.

**Defaults:**

- **One availability SLO and one latency SLO per user-facing service.** Not per endpoint.
- **Group endpoints by user journey**, not by URL. "Browse," "search," "checkout" — each is a journey with its own criticality.
- **Background/batch jobs have *freshness* SLOs**, not availability — "data is no more than 30 minutes stale 99% of the time."
- **Internal-only services may not need SLOs at all** — or they have SLOs that are *consumed* by their callers' SLOs.

If you find yourself with more than ~3 SLOs per service, you're modeling implementation, not user experience.

## Reporting

The error budget needs visibility, not just for the SRE team but for product. Two artifacts:

1. **A real-time dashboard** showing remaining budget, burn rate over the last hour/day/week, and the recent incidents that consumed budget.
2. **A weekly or monthly review** in which the SRE team and product walk through every SLO that's at risk and decide whether to invest in reliability work or accept the risk. This conversation is where the budget actually does its job.

## Anti-Patterns

- **SLO as vanity metric** — published on a dashboard, never enforced. Worse than no SLO; gives false confidence.
- **Aspirational SLO** — set to a number nobody believes, then ignored when missed. Set the SLO to the actual user expectation, not your hopes.
- **Per-endpoint SLO** — death by a thousand SLOs. Group by user journey.
- **Burn alerts on the long window only** — alert is hours late; budget is gone by the time it fires. Always pair long with short.
- **No exclusions for synthetic traffic** — the synthetic monitor itself burns the budget when it fires too aggressively.
- **SLA = SLO** — the contractual SLA leaves no headroom for the team to react before it's breached. Internal SLO must be tighter.
- **"We don't have an error budget policy yet"** — then you don't have an SLO. You have a graph.
- **Changing the SLO when it's missed.** This is the SRE equivalent of moving the goalposts. The right response is to spend the budget on fixing the cause or to renegotiate with product, not to lower the bar.

## Related

- [alerting-and-paging.md](alerting-and-paging.md) — the alert philosophy that burn-rate alerts implement
- [incident-response.md](incident-response.md) — what happens when an alert fires
- [postmortems.md](postmortems.md) — how SLO breaches feed back into reliability work
- [system-architect/references/observability.md](../../system-architect/references/observability.md) — designing the instrumentation that produces the SLI data
- [system-architect/references/capacity-planning.md](../../system-architect/references/capacity-planning.md) — sizing decisions that determine whether you can hit the SLO
