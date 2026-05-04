# Capacity and Load Management

The architect plans capacity at design time (see [system-architect/references/capacity-planning.md](../../system-architect/references/capacity-planning.md)). This file covers what happens *at runtime*: how to scale, how to shed load, how to degrade gracefully, and how to keep the system from cascading into total failure when something breaks.

The defining property of a well-managed system under load: **it gets slower or smaller before it falls over**, and it gets back up cleanly after the load passes.

## The Two Failure Modes

Every overload incident is one of two things:

1. **The system can't keep up.** Demand exceeds capacity; queues fill, latency spirals, eventually nothing succeeds. The cure is either more capacity or less demand.
2. **The system *almost* keeps up but gets into a bad state from which it can't recover.** "Death spiral": a single slow component causes timeouts upstream, which causes retries, which causes more load, which makes the slow component slower. The cure is breaking the feedback loop.

Most production overloads start as type 1 and become type 2 if not addressed quickly. The death spiral is the dangerous one.

## Autoscaling — The Limits

Autoscaling is the first answer most teams reach for, and it's the right answer in many cases. But it has well-known limits:

### Where autoscaling works

- **Stateless services** with quick startup times.
- **Predictable scale-up signals** (CPU, request queue depth, latency).
- **Capacity that can grow horizontally** without coordination (no shard rebalancing required).
- **Backed by infrastructure that can actually provide more capacity** (cloud, not bare metal).

### Where autoscaling fails

- **Slow startup.** A service that takes 5 minutes to be ready can't autoscale fast enough to handle a real surge — by the time the new instance is ready, the surge is over (or the existing instances have already collapsed).
- **Bad scaling signal.** CPU is a poor proxy for load on I/O-bound services. Request queue depth or latency is usually better.
- **Downstream bottleneck.** Scaling the API up doesn't help if the database is the bottleneck. You scale the API to ten times its size and now the database is even more overloaded.
- **Correlated scale-up across many services.** A traffic spike causes ten services to scale up at the same time, all hammering the same database during their warmup. The cure becomes the new failure.
- **Cost runaway.** A misconfigured autoscaler that responds to a runaway loop by adding more instances will happily produce a $50k/day cloud bill. Always set max replicas.

### Rules for autoscaling that doesn't bite back

- **Always set max replicas.** The cost ceiling is non-negotiable.
- **Set scale-up thresholds aggressively** (scale up at 60% utilization, not 90%) so you have time before the system is overwhelmed.
- **Set scale-down thresholds conservatively** (don't scale down for at least 10 minutes after scaling up) so you don't oscillate.
- **Pre-warm before predictable surges.** If you know traffic spikes at 9am, scale up at 8:55, not at 9:01.
- **Test the warmup path.** A new instance that takes 90 seconds to be ready is *not* "responsive" autoscaling — measure the warmup explicitly and account for it.

## Load Shedding

When demand exceeds capacity and you can't scale fast enough (or shouldn't), the right answer is to **serve fewer requests, deliberately**, while keeping the ones you do serve fast and successful.

The opposite — accepting every request and slowly failing all of them — is the death spiral.

### Shedding strategies, in order of preference

1. **Reject at the edge.** Return 429 ("Too Many Requests") or 503 with a `Retry-After` at the load balancer or API gateway, before the request consumes any backend resources. Cheapest possible failure.
2. **Reject by priority.** Drop low-priority traffic first. Read-only health checks for monitoring should never fail; user reads should fall before user writes; bot traffic should fall before human traffic.
3. **Reject by cost.** Drop requests that would consume the most resources (large search queries, expensive joins) before cheap ones.
4. **Degrade features.** Serve a stripped-down version of the response — recommendations skipped, related items skipped, fewer paginated rows. The page works; it just shows less.
5. **Queue with a deadline.** If a request is willing to wait, make it wait, but with a maximum queue time. Past that, reject. Never queue indefinitely.

### Hard rules

- **Fail fast, not slow.** A 429 in 5ms is better than a 200 in 30 seconds. Slow success starves capacity.
- **Health checks bypass shedding.** If your monitoring is being shed, you're flying blind during the incident.
- **Tell the client to retry with backoff.** A `Retry-After` header that the client respects is the difference between recovery and stampede.
- **Don't shed silently.** Emit metrics for what you shed, by class. The shedding rate is itself an SLI.

## Queue Depth as a Vital Sign

Queues are the most underused leading indicator in production. By the time CPU is high or latency has spiked, the queue has already been filling for a while.

- **Every async pipeline has a queue.** Brokers, work queues, request queues inside services, even the OS socket accept queue. Each one has a depth.
- **Alert on queue depth growing**, not on absolute queue depth. A consistently 200-message queue is fine; a queue that has tripled in the last 5 minutes is the warning shot before an outage.
- **Alert on the *age* of the oldest item in the queue.** This is sometimes more useful than depth; it tells you how stale the freshest delivered work is.
- **Bound queues.** An unbounded queue is unbounded latency. When the bound is hit, shed (preferably) or backpressure to the producer.

## Backpressure

Backpressure is the practice of *propagating* the "I can't handle more" signal *upstream* so the producer slows down instead of overwhelming you.

The simplest backpressure: a fixed-size connection pool. When the pool is exhausted, the next request waits (or fails fast). The caller learns that you're saturated and either retries with backoff or fails up its own chain.

### Implementations

- **Bounded thread pools** that reject when full instead of queuing forever.
- **Bounded HTTP connection pools** with explicit `maxConnections` and a `failFast` policy.
- **Rate limiting at the producer**, not just the consumer — token buckets, sliding windows.
- **HTTP 429 / 503 responses** with `Retry-After` (the simplest cross-service backpressure protocol).
- **gRPC `RESOURCE_EXHAUSTED`** with retry hints.
- **Reactive streams** in JVM/JS land, with explicit demand signals.

The goal is the same in all of these: **the upstream knows when to slow down**, not because of a clever heuristic but because the downstream told it.

## Graceful Degradation

A degraded system is much better than a down system. Degradation is the practice of choosing, ahead of time, *what to give up* when the system is under stress.

### Examples

| Component | Healthy mode | Degraded mode |
|---|---|---|
| Recommendations | Personalized recommendations | Top-10 globally popular |
| Search | Real-time search index | Cached search results, slightly stale |
| Pricing | Live currency conversion | Last-known conversion rate |
| Profile page | Full profile + activity feed | Profile only; activity feed omitted |
| Checkout | Full payment options | Card-only; alternative methods disabled |
| Image processing | Original + 4 thumbnail sizes | Original only; thumbnails generated lazily |

The choice of "what to give up" is not made during the incident — it's designed in advance, with explicit code paths and feature flags. During the incident, the SRE flips the flag.

### Hard rules

- **Decide degradation paths in design, not in production.** The architect picks them; the SRE operates them.
- **Test the degraded path.** Run a gameday where you turn it on and confirm the system actually works in that mode. Untested degradation is decoration.
- **Make degradation visible to users when appropriate.** A small "limited functionality" banner is honest and prevents support volume.
- **Have a clear restore path.** Going back to full operation should be a single command, and tested.

## Circuit Breakers and Bulkheads

These are *design-time* patterns documented in [system-architect/references/fault-tolerance.md](../../system-architect/references/fault-tolerance.md). At runtime, the SRE owns:

- **Tuning the thresholds.** Trip rate, half-open trial frequency, recovery window. These need adjustment based on real production data.
- **Monitoring the breakers.** A breaker that's open is a signal — if a breaker is *always* open, the dependency is broken or the threshold is wrong.
- **Acting on tripped breakers.** A tripped breaker isn't a fix — it's a signal that something is wrong with a dependency. Investigate and either fix the dependency or accept and document the degraded mode.
- **Bulkhead sizing.** Connection pools, thread pools, and queue limits per dependency.

## Retry Storms

Retries are the most common cause of cascading failures. A simple "retry on error" policy across multiple services creates a feedback loop:

1. Service A is briefly slow.
2. Its callers retry, doubling load.
3. Service A is now slower because of the retry traffic.
4. More retries.
5. Total collapse.

### Hard rules for retries

- **Exponential backoff with jitter.** Constant backoff produces synchronized retry storms; jitter spreads them out.
- **Bounded retries.** Three is usually enough. Above that, you're not retrying — you're hammering.
- **Retry budgets.** A maximum percentage of requests that may be retries. Above that, retries are dropped. (Envoy and other modern proxies support this.)
- **Don't retry idempotent-only operations.** Retrying a non-idempotent POST is how you create duplicate orders.
- **Respect `Retry-After`.** A 429 with a 30-second hint and you retry in 1 second is misbehavior.
- **Circuit-break the retries themselves.** When the dependency is clearly down, *stop* retrying and fail fast.

The general pattern: **retries should be the exception, not the policy**. Most successful operations succeed on the first try. If you're seeing a high retry rate, the dependency is broken, not slow — fix it.

## Cost vs. Capacity

A useful framing: **provision for the load you can predict; absorb spikes with degradation, not with capacity.**

- Capacity for the steady-state load + reasonable headroom (~30%) → cheap and reliable.
- Capacity for the worst-case spike → expensive and rarely needed.
- Mechanisms to *handle* the spike (autoscaling + load shedding + degradation) → the right place to invest.

A team that responds to every overload incident by buying more capacity will eventually have an enormous cloud bill *and* still get knocked over by the next surprise. A team that invests in load management will run cheaper and more reliably.

## Anti-Patterns

- **"Just add more capacity."** Sometimes right; usually a tax on the budget that doesn't fix the underlying fragility.
- **No max replicas.** A misconfigured autoscaler producing a $30k cloud bill in 12 hours.
- **Unbounded queues.** Latency spiral every time a consumer hiccups.
- **Retry without backoff.** Self-DoS at scale.
- **Health checks behind the same shedding logic as user requests.** You stop seeing the system you're trying to manage.
- **Degradation paths that have never been tested.** They don't work when you need them; the production traffic finds the bugs.
- **Autoscaling on CPU for I/O-bound services.** Wrong signal; service falls over while CPU sits at 30%.
- **The death spiral that nobody saw coming because queue-depth alerts didn't exist.** Add them.
- **Capacity provisioned for the absolute peak.** Cheap during the peak, very expensive every other minute of the year.
- **Manual scaling as the only mitigation strategy.** Works until the spike is faster than the on-call's reaction time.
- **Restart-as-mitigation for memory leaks** that nobody fixes. The pod restart becomes load-bearing.

## Related

- [system-architect/references/capacity-planning.md](../../system-architect/references/capacity-planning.md) — design-time sizing math
- [system-architect/references/fault-tolerance.md](../../system-architect/references/fault-tolerance.md) — circuit breakers, bulkheads, timeouts as design patterns
- [slis-slos-error-budgets.md](slis-slos-error-budgets.md) — capacity SLIs and headroom budgets
- [chaos-and-resilience.md](chaos-and-resilience.md) — exercising degradation paths before you need them
- [incident-response.md](incident-response.md) — what to do when load management fails
- [typescript-data-engineering/references/message-brokers.md](../../typescript-data-engineering/references/message-brokers.md) — broker-specific backpressure patterns
- [typescript-data-engineering/references/caching.md](../../typescript-data-engineering/references/caching.md) — caching as a load-shedding tool
