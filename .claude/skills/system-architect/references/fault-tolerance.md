# Fault Tolerance

Assume every dependency will fail. Design the system so partial failures don't cascade into total outages.

## Core Patterns

### Timeouts
- **Every** network call has an explicit timeout. No defaults, no infinity.
- Timeouts decrease as you move down the call stack (caller > callee).
- Rule of thumb: p99 latency × 2, capped by upstream budget.

### Retries
- Only retry **idempotent** operations or operations with idempotency keys.
- **Exponential backoff with jitter** — never tight loops, never synchronized retries (thundering herd).
- Cap total retries (e.g., 3) and total time (retry budget).
- Do not retry 4xx (except 408/429). Do retry 5xx and connection errors.

### Circuit Breakers
- Track failure rate per dependency; when threshold exceeded, **open** the breaker and fail fast.
- Half-open after a cool-down to probe recovery.
- Prevents cascading failures and gives the dependency room to recover.

### Bulkheads
- Isolate resources per dependency: separate connection pools, thread pools, queues.
- A slow dependency cannot exhaust the resources used by others.

### Backpressure
- When downstream is slow, propagate slowness upstream (bounded queues, rejection, 429s).
- Never buffer unboundedly — that turns latency problems into OOM crashes.

### Load Shedding
- Under overload, drop low-priority requests to protect the system.
- Define request priorities at the edge (gateway).

### Idempotency
- Every mutating endpoint accepts an idempotency key OR is naturally idempotent.
- Required for safe retries across the network.

### Graceful Degradation
- Identify which features are essential vs. nice-to-have.
- When a non-essential dependency is down, return a degraded response (cached, stub, partial), not an error.
- Example: recommendations service down → product page still loads without recommendations.

## Redundancy

### Multi-AZ
- **Default for any production system**. Stateless services across ≥2 AZs behind a load balancer.
- Stateful: managed service with synchronous replication (RDS Multi-AZ, Aurora).

### Multi-Region
- Active/passive for DR (warm standby).
- Active/active when RTO ≈ 0 or you have data-residency requirements.
- **Cost**: doubles infra spend, complicates consistency. Only when justified.

### Replicas & Sharding
- Read replicas for read-heavy workloads.
- Shard when single-node write throughput is insufficient — last resort, not first.

## Data Safety

### RPO / RTO
- **RPO** (recovery point objective): how much data you can lose. Drives backup frequency / replication mode.
- **RTO** (recovery time objective): how long to restore. Drives DR architecture (cold/warm/hot standby).
- State both in the design doc.

### Backups
- Automated, encrypted, **tested restores** on a schedule. An untested backup is not a backup.
- Off-site / cross-region copy.

## Testing for Failure

### Chaos Engineering
- Inject failures in pre-prod (and eventually prod): kill instances, add latency, drop packets, fail dependencies.
- Tools: Chaos Mesh, Gremlin, AWS FIS.
- Start with the dependency you fear the most.

### Game Days
- Practice incident response on staged failures. Rotate facilitators.

### Load Testing
- Test at 2–3x expected peak. Identify the breaking point so you know your headroom.

## Failure Mode Checklist

For each dependency in the design, answer:
- What happens if it's slow?
- What happens if it's unavailable?
- What happens if it returns wrong data?
- What's the blast radius?
- What's the user-visible behavior?
- How do we detect it? How do we recover?
