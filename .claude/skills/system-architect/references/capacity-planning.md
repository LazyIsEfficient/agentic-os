# Capacity Planning

Designs without numbers are wishes. Every system design includes back-of-envelope estimates.

## Inputs to Estimate

- **Users**: total, DAU, peak concurrent.
- **Requests**: average RPS, peak RPS (typically 3–10x average), read:write ratio.
- **Data**: per-record size, records/day, retention → total storage + growth rate.
- **Egress**: bytes/response × RPS → bandwidth + CDN cost.

## Useful Numbers (latency cheat sheet)

| Operation | Time |
|---|---|
| L1 cache | 0.5 ns |
| Main memory | 100 ns |
| SSD random read | 100 µs |
| Same-region network round trip | 0.5 ms |
| Cross-region (US↔EU) round trip | 80 ms |
| Disk seek (HDD) | 10 ms |
| Postgres point lookup (warm) | <1 ms |
| HTTP call (intra-VPC) | 1–5 ms |

Use these to sanity-check designs. If a request makes 50 sequential cross-service calls, it cannot meet a 100 ms SLO.

## Sizing Math (worked example)

Goal: 1M DAU social feed, peak 10x average.

- DAU 1M, ~10 reads + 1 write per user/day → 11M ops/day → ~127 ops/s avg → **~1.3k ops/s peak**.
- Avg post 1 KB → 1M posts/day × 1 KB = 1 GB/day → ~365 GB/year. Add indexes ×2 → ~750 GB/year.
- Read-heavy → caching wins. With 80% cache hit, DB sees ~250 ops/s peak. One Postgres primary handles this comfortably.

This calculation is the difference between "we need Cassandra and Kafka" and "Postgres + Redis is fine."

## Headroom Rules

- **Steady state ≤ 50%** utilization (CPU, memory, connections).
- **Peak ≤ 70%** — leaves room for traffic spikes and instance failures.
- **Above 80%** → scale up or out before the next traffic event.
- Auto-scaling buys time, not safety. Cold-start lag means you must absorb spikes with existing capacity.

## Load Testing

- Test at **2–3x expected peak** before launch.
- Identify the **knee of the curve** (where latency explodes) — that's your real ceiling.
- Realistic data shapes and cardinalities — synthetic uniform data lies.
- Tools: k6, Locust, Gatling, Vegeta.

## Cost Modeling

Include in every design doc:
- **Compute**: instance type × count × hours.
- **Storage**: GB-months + IOPS.
- **Egress**: GB out (the surprise line item — egress is expensive).
- **Managed services**: per-request, per-GB pricing.
- **Multi-AZ / multi-region multipliers.**

A rough monthly cost belongs in the design before approval. "We'll figure out cost later" is how startups die.

## When to Scale Vertically vs Horizontally

- **Vertical first** (bigger instance, more replicas of stateless) — cheaper, simpler, faster.
- **Horizontal** when vertical hits a wall: single-node CPU/memory limits, write throughput on the primary, or HA requires it.
- **Sharding** is a last resort — operationally expensive and hard to undo.
