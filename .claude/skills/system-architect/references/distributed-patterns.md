# Distributed Systems Patterns

Each pattern lists **when to use** and **when NOT to use**. Distributed patterns are tools, not goals.

## Service Decomposition Strategies

### Decompose by Business Capability
- Split along bounded contexts (DDD). Each service owns a capability end-to-end.
- **Use when**: clear domain boundaries, independent teams.
- **Avoid when**: domain is still in flux — premature boundaries are expensive to move.

### Decompose by Subdomain (DDD)
- Core / supporting / generic subdomains. Invest most in core.
- **Use when**: complex domain with clear strategic differentiation.

### Strangler Fig
- Incrementally replace a monolith by routing new functionality to new services.
- **Use when**: migrating away from a legacy system you can't rewrite.

## Communication Patterns

### Synchronous (REST/gRPC)
- Simple, easy to debug, request/response semantics.
- **Use when**: caller needs the result immediately, low call depth (<3 hops).
- **Avoid when**: long call chains (cascading failures), high fan-out.

### Asynchronous (Events / Messages)
- Producer publishes, consumers react. Decouples services in time and space.
- **Use when**: fan-out, workflows that span services, smoothing load spikes.
- **Avoid when**: caller needs an immediate answer or strong consistency.

### Event-Driven Architecture
- Services communicate primarily via events on a broker (Kafka, Kinesis, NATS).
- **Use when**: many consumers per event, audit/replay needed, eventual consistency acceptable.
- **Avoid when**: small system — broker ops cost > benefit.

## Broker Selection

Pick the broker by the **delivery semantics and access pattern** the workload needs, not by familiarity.

| Broker | Model | Ordering | Retention | Best for |
|---|---|---|---|---|
| **RabbitMQ** | Queue + exchange (push) | Per-queue FIFO | Until ack | Work queues, RPC-over-broker, complex routing topologies |
| **Kafka / Redpanda** | Distributed log (pull) | Per-partition | Days–forever | Event streaming, replay, fan-out to many consumer groups, CDC |
| **AWS SQS** | Queue (pull) | FIFO queues only | Up to 14d | Decoupled background work, AWS-native, near-zero ops |
| **AWS SNS → SQS** | Pub/sub fan-out | Per-queue | Up to 14d | Fan-out to multiple SQS subscribers |
| **Google Pub/Sub** | Pub/sub (pull or push) | Per-key (ordering keys) | 7d default | GCP-native, large fan-out, low ops |
| **NATS / NATS JetStream** | Subject-based pub/sub | Per-stream | Configurable | Low-latency edge messaging, microservices mesh |
| **Redis Streams / BullMQ** | Stream / job queue | Per-stream | Bounded | In-process job queues piggybacking on existing Redis |
| **DB-as-queue (outbox)** | Polled rows | Per-row | DB lifetime | When you already have a transactional DB and don't want broker ops |

**Decision shortcuts**:

- Need replay or many independent consumers reading the same events? → **Kafka**.
- Need flexible routing (topic exchanges, headers, RPC)? → **RabbitMQ**.
- On AWS and want zero ops? → **SQS** (+ SNS for fan-out).
- Already have Postgres + low scale? → **outbox + a polling worker** before introducing a broker.
- "We use Redis already" → **BullMQ** for jobs, but treat it as a job queue, not an event bus.

## Delivery Semantics

| Guarantee | What it means | Cost | When acceptable |
|---|---|---|---|
| **At-most-once** | Fire and forget. May lose messages. | Cheapest | Telemetry, metrics, non-critical signals |
| **At-least-once** | Will be delivered ≥1 time. **Consumers must be idempotent.** | Default for most brokers | Almost everything — pair with idempotency |
| **Exactly-once** | Delivered and processed exactly once. | Expensive, often a marketing claim | Rare. Usually achieved as "at-least-once + idempotent consumer" |

**Rules of thumb**:

- Default to **at-least-once + idempotent consumer**. "Exactly-once" claims usually mean "exactly-once write within one broker boundary"; once you cross to your DB or a third party, you own idempotency.
- Make every consumer **idempotent on a stable key** (event ID, business key). Use an inbox table or a deduping cache.
- Pair every producer with the **outbox pattern** when the producing write must atomically commit with the message.

## Ordering Guarantees

- **Global ordering is rare and expensive.** Don't ask for it unless the business requires it.
- **Per-key ordering** (Kafka partitions, SQS FIFO group ID, Pub/Sub ordering keys) is usually sufficient: order events for one user/order/account, not across all of them.
- Choose the partition key by the entity whose causality you must preserve. Wrong partition key → ordering bugs that only show up under load.

## DLQs and Poison Messages

- **Always configure a DLQ** before going to production. Without one, a poison message blocks the queue indefinitely.
- **Bound retries** (e.g. 5 attempts with exponential backoff + jitter), then route to DLQ.
- DLQs need their own **alerting and replay tooling** — a DLQ no one watches is data loss with extra steps.

## Coordination Patterns

### Saga (Orchestration vs Choreography)
- Manage distributed transactions via a sequence of local transactions + compensations.
- **Orchestration**: central coordinator. Easier to reason about, single point of logic.
- **Choreography**: services react to events. More decoupled, harder to debug.
- **Use when**: business process spans multiple services and you need eventual atomicity.
- **Avoid when**: a single ACID transaction in one service would suffice.

### Two-Phase Commit
- Almost never. Slow, blocking, fragile. Prefer sagas.

## Data Patterns

### CQRS (Command Query Responsibility Segregation)
- Separate write model from read model(s).
- **Use when**: read and write workloads have very different shapes/scale.
- **Avoid when**: simple CRUD — adds complexity for no win.

### Event Sourcing
- Store the sequence of events; derive state by replay.
- **Use when**: full audit trail required, temporal queries, complex domain logic.
- **Avoid when**: you don't need the audit trail. Operational complexity is high.

### Outbox Pattern
- Write event + state change in the same DB transaction; relay to broker async.
- **Use when**: you need at-least-once event publishing with state changes. **Almost always pair with event-driven systems.**

### CDC (Change Data Capture)
- Stream DB changes (Debezium, RDS streams) into the event backbone.
- **Use when**: need to derive read models or feed analytics without app changes.

## Infrastructure Patterns

### API Gateway
- Single entry point: auth, rate limit, routing, request shaping.
- **Use when**: multiple backend services need consistent edge concerns.
- **Avoid when**: only one backend — direct routing is simpler.

### Backend for Frontend (BFF)
- Per-client gateway tailored to mobile/web/partner needs.
- **Use when**: client shapes diverge significantly.

### Service Mesh (Istio, Linkerd)
- Sidecar handles mTLS, retries, traffic shifting, observability.
- **Use when**: many services (>20), polyglot, need uniform L7 policy.
- **Avoid when**: small fleet — managed gateways and libraries are cheaper to operate.

### Sidecar
- Co-locate cross-cutting concerns next to the app process.
- **Use when**: polyglot fleet needs the same capability (logging, secrets, mesh).

## Anti-Patterns to Recognize

- **Distributed monolith** — services deploy together, share a DB, call each other in deep chains.
- **Chatty services** — N+1 over the network. Aggregate in the producer or use BFF.
- **Shared mutable state** — two services writing the same row. Pick one owner.
- **Event soup** — events without schema, ownership, or versioning. Treat events as APIs.
