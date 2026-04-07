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
