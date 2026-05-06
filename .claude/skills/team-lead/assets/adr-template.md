# ADR Template

Architecture Decision Records capture **significant, non-default** choices that were not obvious and that future engineers will want to understand.

## File Conventions

- Path: `docs/adr/ADR-NNNN-kebab-title.md`
- Numbering: zero-padded, sequential, never reused.
- Filename never changes after creation.
- Status changes via a new ADR (Supersedes / Superseded by).

## Template

```markdown
# ADR-NNNN: [Short title of the decision]

- **Status:** Proposed | Accepted | Deprecated | Superseded by ADR-XXXX
- **Date:** YYYY-MM-DD
- **Deciders:** [names / roles]
- **Consulted:** [names]
- **Supersedes:** ADR-XXXX (if any)

## Context

What is the situation that forces a decision? What constraints, requirements, or pain points exist? Reference incidents, tickets, metrics — concrete signals, not abstract concerns.

State the **default** we are deviating from, citing the relevant DAD if one exists.

## Decision

The choice, in one or two sentences. Active voice: "We will use X for Y."

## Options Considered

For each option (at least two, ideally three):

### Option A — [name]
- **Summary:** one paragraph
- **Pros:** ...
- **Cons:** ...
- **Cost / effort:** ...

### Option B — [name]
...

### Option C — [name]
...

## Rationale

Why the chosen option won. Tie back to the requirements in Context — what did this option uniquely satisfy?

## Consequences

- **Positive:** capabilities unlocked, problems solved.
- **Negative:** new costs, new complexity, new things to operate.
- **Follow-ups:** tickets created (link them), migrations needed, monitoring to add.

## Compliance & Review

- How will we know this decision is working? (metric, deadline)
- When should we revisit it?
```

## Worked Example (abbreviated)

```markdown
# ADR-0042: Use Temporal for long-running order workflows

- **Status:** Accepted
- **Date:** 2026-03-12
- **Deciders:** Team Lead, Backend Lead, SRE
- **Supersedes:** —

## Context
Our order pipeline has 6 steps spanning payment, inventory, fulfillment, and notification. Currently implemented as a chain of SQS handlers with custom retry logic. We had three production incidents in Q1 from inconsistent state on partial failures. **DAD-0011** says async work uses SQS by default; this ADR justifies deviating for workflows that need durable state across steps.

## Decision
We will adopt Temporal (self-hosted) for order workflows. SQS remains the default for fire-and-forget jobs.

## Options Considered
### A — Keep SQS, add a state machine table
Pros: no new infra. Cons: we are reinventing Temporal poorly; the Q1 incidents prove this.
### B — AWS Step Functions
Pros: managed. Cons: vendor lock, hard local dev, expensive at our volume.
### C — Temporal (chosen)
Pros: durable workflows, built-in retries, local dev story, polyglot SDKs. Cons: new infra to operate, learning curve.

## Rationale
Option C uniquely solves the durable-state-across-steps problem without locking us to AWS, and the operational cost is acceptable given SRE bandwidth.

## Consequences
- **Positive:** atomic-feeling workflows, clear retry semantics, replayable history.
- **Negative:** Temporal cluster to operate, team training required.
- **Follow-ups:** ENG-512 (cluster setup), ENG-513 (training), ENG-514 (migrate first workflow).

## Compliance & Review
Revisit after 6 months. Success = zero state-inconsistency incidents, p95 workflow latency unchanged.
```
