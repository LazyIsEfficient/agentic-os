# Design Doc Template

Use this structure for any non-trivial system design or architecture RFC. Keep it short — a great design doc fits in 3–6 pages.

---

# [Title]

**Author:** [name] · **Status:** Draft / In Review / Approved · **Date:** YYYY-MM-DD · **Reviewers:** [names]

## 1. Context

What problem are we solving? Why now? What's the user/business impact? Link to product brief, incident, or ticket.

## 2. Goals & Non-Goals

**Goals** (what success looks like — measurable):
- ...

**Non-goals** (explicitly out of scope so reviewers don't expand the conversation):
- ...

## 3. Requirements

**Functional**
- ...

**Non-functional**
- Peak RPS: ...
- p99 latency: ...
- Availability target (SLO): ...
- Consistency: strong / read-your-writes / eventual
- RPO / RTO: ...
- Compliance: ...

**Constraints**
- Team size, deadline, budget, existing tech, regulatory.

## 4. Current State

How does the system look today? What are the limits we're hitting? Diagram if helpful (Mermaid).

## 5. Proposed Design

High-level diagram + walk-through. Include:
- Service boundaries and ownership
- Data model and storage choices (and **who owns each table**)
- Sync vs async communication paths
- Failure modes and fallbacks
- Observability: SLIs, SLOs, key metrics, alerts

## 6. Alternatives Considered

For each alternative: 1-paragraph description + why rejected. **At least two alternatives.** A design with no rejected options has not been thought through.

## 7. Capacity & Cost

- Back-of-envelope: RPS, storage growth, bandwidth.
- Estimated monthly cost.
- Headroom: at what scale does this design break?

## 8. Fault Tolerance

For each external dependency:
| Dependency | Failure mode | Detection | Mitigation | User impact |
|---|---|---|---|---|

Timeouts, retries, circuit breakers, bulkheads, graceful degradation paths.

## 9. Observability

- SLIs and SLO targets.
- Top 5 metrics + 5 alerts (with runbook links).
- Trace points of interest.
- Dashboard sketch.

## 10. Security & Privacy

- Authn/authz model.
- PII / sensitive data handling.
- Threat model (top 3 threats + mitigations).
- Data residency / compliance notes.

## 11. Rollout Plan

- Phases (dark launch, percentage rollout, kill switch).
- Migration / backfill strategy.
- Rollback procedure.
- Success criteria for each phase.

## 12. Risks & Open Questions

- Risks with likelihood × impact.
- Open questions needing reviewer input — **call them out explicitly**.

## 13. Appendix

Links to related docs, prior art, research.
