# Complexity Triage

Right-size the architecture to the problem. Over-engineering kills velocity; under-engineering kills reliability.

## Sizing Heuristics

Classify on the **highest** matching signal — if any one dimension is "complex", the system is complex.

| Dimension | Simple | Moderate | Complex |
|---|---|---|---|
| Peak RPS | <10 | 10–1k | >1k |
| Availability target | 99% | 99.9% | 99.95%+ |
| Teams contributing | 1 | 2–4 | 5+ |
| Deploy cadence | weekly | daily | many/day, independent |
| Data volume | <100 GB | <10 TB | >10 TB or unbounded growth |
| Geographic scope | single region | single region + DR | multi-region active/active |
| Regulatory | none | basic (GDPR) | PCI/HIPAA/data residency |

## Default Architectures

### Simple → Monolith
- One deployable, one Postgres, one cache.
- Background jobs in-process or via a single worker.
- Vertical scale first; add read replicas before splitting.

### Moderate → Modular Monolith
- Single deployable with enforced module boundaries (separate schemas, no cross-module imports).
- Queue (SQS/RabbitMQ) for async work.
- Read replicas, CDN, managed cache.
- This is the **sweet spot** for most products. Resist the microservices urge.

### Complex → Distributed
- Microservices split along independent scale axes or team boundaries.
- Event-driven backbone (Kafka/Kinesis) for cross-service communication.
- API gateway, service mesh for L7 concerns.
- Polyglot persistence where justified (search → Elastic, time-series → Timescale).
- Multi-AZ minimum; multi-region if RTO/RPO demands it.

## When to Split a Monolith

Split a service out of the monolith **only** when at least one is true:

1. **Independent scale axis** — one component needs 10x the resources of the rest (e.g., image processing).
2. **Independent deploy cadence** — a team is blocked on the monolith's release train.
3. **Fault isolation** — a flaky component is dragging down unrelated features.
4. **Compliance boundary** — PCI/PHI data must be physically isolated.
5. **Team ownership at scale** — Conway's Law: >5 teams on one codebase becomes coordination hell.

If none apply, **do not split**.

## Anti-Patterns

- **Microservices by default** — splitting before the monolith hurts. You inherit network failures, eventual consistency, and distributed debugging for no benefit.
- **Distributed monolith** — services that must deploy together, share a database, or call each other synchronously in long chains. Worst of both worlds.
- **Nano-services** — one service per endpoint. Operational overhead crushes velocity.
- **Shared database across services** — couples services invisibly; schema changes become cross-team negotiations.
- **Resume-driven architecture** — Kafka, Kubernetes, and service mesh because they're trendy, not because the load demands them.
- **Premature multi-region** — adds latency, consistency headaches, and 2x cost. Only justified by RTO/RPO or data residency.
- **Custom infra over managed** — running your own Kafka/Postgres/Redis when RDS/MSK/ElastiCache exist. Pay the managed-service tax.

## Escalation Triggers

Document the **specific signal** that justifies escalating a tier. Examples:

- "Image processing peaks at 5k RPS while API is 200 RPS → split image service" ✅
- "We might need to scale someday → microservices" ❌
- "Payments team needs PCI isolation → separate VPC + service" ✅
- "The codebase feels big → microservices" ❌
