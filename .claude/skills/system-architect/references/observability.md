# Observability

Observability = the ability to ask new questions of the system without shipping new code. It is a **design requirement**, not an afterthought.

## Three Pillars

### Logs
- **Structured** (JSON), not free text. Searchable fields: `timestamp`, `level`, `service`, `trace_id`, `user_id`, `request_id`.
- Log at **boundaries**: incoming request, outgoing dependency call, errors. Avoid logging in tight loops.
- **Sanitize** secrets, PII, auth headers before they hit the log pipeline.
- Standard levels: `error` (page-worthy), `warn` (anomaly), `info` (lifecycle), `debug` (off in prod).

### Metrics
- Cheap, aggregatable, low-cardinality. Use for dashboards and alerts.
- Two methodologies:
  - **RED** (request-driven services): **R**ate, **E**rrors, **D**uration.
  - **USE** (resources): **U**tilization, **S**aturation, **E**rrors.
- Histograms for latency (never just averages — p50/p95/p99).
- Tag carefully — high cardinality blows up cost (don't tag with `user_id`).

### Traces
- Distributed tracing (OpenTelemetry) propagates a `trace_id` across service boundaries.
- Capture spans for: incoming requests, outgoing calls, DB queries, queue ops.
- Sample intelligently — head-based for cost, tail-based to keep all errors.

## SLI / SLO / Error Budget

Define these **with the design**, not after launch.

- **SLI** (Service Level Indicator): the metric you measure. Examples: `(successful requests) / (total requests)`, `requests served < 300ms / total`.
- **SLO** (Service Level Objective): the target. Example: 99.9% availability over 30 days.
- **Error budget**: `1 - SLO`. The amount of unreliability you can spend on shipping changes. When the budget is gone, freeze risky deploys.

### SLI Selection
- Pick SLIs that **users feel**: success rate, latency, freshness.
- Avoid SLIs that don't correlate with user pain (CPU usage is not an SLI).

### SLO Targets by Tier
| Availability | Downtime/30d | Use case |
|---|---|---|
| 99% | 7h 12m | Internal tools |
| 99.9% | 43m | Most user-facing |
| 99.95% | 22m | Critical paths |
| 99.99% | 4m | Payments, auth |

Each extra 9 roughly **10x's the cost**. Don't chase 9s you don't need.

## Alert Design

- **Alert on symptoms, not causes** — alert when users hurt (SLO burn), not when CPU is high.
- **Page only on actionable, urgent issues**. Everything else → ticket / dashboard.
- **Burn-rate alerts**: page when error budget is being consumed too fast (e.g., 2% of monthly budget in 1 hour).
- Every alert has a runbook link.
- Test alerts. Silently broken alerts are worse than no alerts.

## Dashboards

- One **service overview** dashboard per service: RED metrics, dependency health, recent deploys.
- One **business** dashboard per product area: user-visible KPIs.
- Avoid dashboard sprawl. If a dashboard isn't viewed in 90 days, delete it.

## Correlation

- Propagate `trace_id` into logs so you can pivot logs ↔ traces.
- Tag metrics with `service`, `version`, `region` to slice incidents by deploy.
- Deploy markers on dashboards — most outages correlate with the last deploy.

## Tooling Baseline

A reasonable starter stack:
- **Logs**: Loki, CloudWatch, Datadog, or ELK
- **Metrics**: Prometheus + Grafana, or Datadog
- **Traces**: OpenTelemetry SDK → Tempo / Jaeger / Honeycomb / Datadog
- **Errors**: Sentry for exception aggregation
- Use **OpenTelemetry** as the instrumentation API regardless of backend — keeps you portable.

## Observability in the Design Doc

Every system design must include:
1. SLIs and SLO targets.
2. Key metrics (RED + business).
3. Critical traces / spans of interest.
4. Top 5 alerts and their runbooks.
5. Dashboard sketch.
