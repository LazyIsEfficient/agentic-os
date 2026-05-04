# DAD Template

Default Architectural Decisions capture the **everyday patterns the team follows by convention**. They are the baseline ADRs deviate from. New joiners should be able to read all DADs in an afternoon and understand "how we do things here."

## When to Write a DAD vs an ADR

- **DAD**: "This is what we always do unless there's a reason not to." No specific incident triggered it; it's just the house style backed by experience.
- **ADR**: "We deviated from the default because of [specific reason]."

If you keep explaining the same default in code reviews, it's a DAD waiting to be written.

## File Conventions

- Path: `docs/dad/DAD-NNNN-kebab-title.md`
- Numbering: zero-padded, sequential, never reused.
- DADs are short — half a page is typical, two pages is the ceiling.
- Updated in place when the default evolves; preserve a brief changelog at the bottom.

## Template

```markdown
# DAD-NNNN: [The default, stated as a rule]

- **Status:** Active | Deprecated | Superseded by DAD-XXXX
- **Owner:** [team or role]
- **Last reviewed:** YYYY-MM-DD

## Default

One sentence stating the rule. "We use X for Y."

## Scope

When this default applies. Be specific about the boundary — services, layers, or contexts where it does NOT apply.

## Rationale

A short paragraph: why this is our default. Reference experience, not theory. Cite incidents or trade-offs that made this the obvious choice.

## How to Apply

Concrete guidance for engineers:
- Library / version
- Repo location / file pattern
- Configuration template or link
- Linter rule that enforces it (if any)

## When to Deviate

The legitimate reasons to break this default. Each deviation requires an ADR that references this DAD.

## Related

- ADRs that deviate from this default
- Other DADs in the same area

## Changelog

- YYYY-MM-DD — Created
- YYYY-MM-DD — [what changed]
```

## Worked Example

```markdown
# DAD-0011: Use SQS for async, fire-and-forget background work

- **Status:** Active
- **Owner:** Backend Guild
- **Last reviewed:** 2026-02-01

## Default
We use AWS SQS (standard queues) as the default broker for asynchronous background work.

## Scope
Applies to all backend services running in our AWS accounts. Does NOT apply to:
- Long-running multi-step workflows with durable state (see ADR-0042 → Temporal)
- High-throughput event streaming with multiple consumers (use Kinesis — see DAD-0017)

## Rationale
SQS is managed, cheap at our scale, supports DLQs out of the box, and integrates with our existing IAM/OIDC story. We tried RabbitMQ in 2024; the operational burden wasn't worth it for our throughput. Standard queues are sufficient — we have not needed FIFO ordering in the default case.

## How to Apply
- Producer: `@org/sqs-client` (versioned)
- Consumer: lambda or ECS worker via the shared `sqs-consumer` template in `infra/templates/sqs-consumer/`
- Always configure a DLQ with `maxReceiveCount: 5`
- Always set a visibility timeout ≥ 6 × p99 handler latency
- Idempotency key required on every message

## When to Deviate
- Need ordered processing per key → SQS FIFO (still SQS, document inline)
- Need durable workflows across steps → Temporal (ADR-0042)
- Need fan-out to many consumers → Kinesis (DAD-0017)
- Need <10ms publish latency → consider in-memory or Redis Streams (write an ADR)

## Related
- ADR-0042 — Temporal for order workflows
- DAD-0017 — Kinesis for analytics event streams

## Changelog
- 2025-08-14 — Created
- 2026-02-01 — Added idempotency-key requirement after INC-198
```
