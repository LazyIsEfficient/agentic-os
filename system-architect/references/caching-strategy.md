# Caching Strategy

Caching is a power tool for latency and cost. It is also the second-hardest problem in computer science. Decide *why* you're caching before you decide *what* to cache.

## When to Cache

Cache when **all** of the following hold:
- The source of truth is slow or expensive (DB query, third-party API, computation).
- The data tolerates some staleness — define how much, in seconds, before you start.
- The read-to-write ratio is high (rule of thumb: >10:1).
- You can articulate the **invalidation strategy** before adding the cache. If you cannot, do not cache.

Do **not** cache to "make things faster" without a measured baseline. Premature caching hides bugs and creates new ones.

## Strategy Patterns

### Cache-Aside (Lazy Loading)
- App reads from cache; on miss, reads from source and populates cache.
- **Use when**: read-heavy, tolerate first-request latency, simple to reason about.
- **Trade-off**: cold cache penalty; risk of stampede on popular keys.

### Read-Through
- Cache layer itself loads from source on miss. App only talks to the cache.
- **Use when**: you want a uniform interface and your cache library supports it.
- **Trade-off**: tighter coupling to cache library; harder to bypass for debugging.

### Write-Through
- Writes go to cache and source synchronously.
- **Use when**: read consistency matters more than write latency.
- **Trade-off**: every write pays cache + DB cost.

### Write-Behind (Write-Back)
- Writes go to cache, flushed to source asynchronously.
- **Use when**: write throughput matters more than durability.
- **Trade-off**: data loss window on cache failure. Rare in practice — usually a foot-gun.

### Refresh-Ahead
- Cache proactively refreshes hot keys before TTL expires.
- **Use when**: predictable hot keys, latency-sensitive reads, willingness to do background work.
- **Trade-off**: wasted refreshes on cold data.

## TTL and Invalidation

- **Always set a TTL.** A cache without a TTL is a memory leak with extra steps.
- **Pick TTL by tolerance for staleness, not by feel.** "How wrong is the user allowed to be?" If "not at all," reconsider whether you should be caching.
- **Invalidation modes**:
  - **TTL-only** — simplest, eventual freshness, accept the staleness window.
  - **Event-driven invalidation** — publish on writes, consumers evict. Pairs with the [outbox pattern](distributed-patterns.md).
  - **Versioned keys** — embed a version in the key (`user:v3:42`); bump the version to invalidate everything atomically.
- **Never** rely on "I'll DELETE the key when the data changes" as the only mechanism. Some writer will forget. Pair with TTL.

## Stampede Protection

When a hot key expires and N concurrent requests miss the cache, all N hit the source. Mitigations:

- **Singleflight / request coalescing** — only one request to source per key; others wait.
- **Probabilistic early expiration** — refresh a fraction of requests before TTL hits zero (XFetch algorithm).
- **Soft vs hard TTL** — serve stale-but-valid past soft TTL while one request refreshes.
- **Mutex/lease keys** — first miss takes a short lock, others wait or serve stale.

## Key Design

- **Namespace by entity type** — `user:42`, `order:99`. Never bare IDs.
- **Include the version of the schema** if the cached shape can change — `user:v2:42`.
- **Avoid unbounded fan-in keys** — `search:<arbitrary query string>` fills the cache with one-hit wonders. Cap or hash long keys.
- **Hot key mitigation** — replicate a hot key across N suffixes (`leaderboard:0..9`) and pick at random.

## Multi-Tier Caching

| Tier | Latency | Use for |
|---|---|---|
| In-process (LRU) | nanoseconds | Per-instance hot data, config, feature flags |
| Distributed (Redis/Memcached) | sub-millisecond | Shared session, cross-instance state, computed results |
| HTTP / CDN edge | tens of ms | Public assets, anonymous responses, idempotent GETs |
| Database query cache | varies | Last-resort; usually disabled in modern Postgres for correctness |

Push hot data **up** the tiers, not down. The closer the cache is to the consumer, the more it pays for itself.

## HTTP / CDN Caching

- Use `Cache-Control` headers explicitly. Never rely on defaults.
- `public, max-age=N, stale-while-revalidate=M` is the workhorse for read-mostly endpoints.
- `Vary` on every header that changes the response (`Authorization`, `Accept-Language`).
- Authenticated responses default to `private`. Anonymous endpoints default to `public`.
- ETags for conditional GETs; pair with `If-None-Match` to skip body transfer.

## Observability

A cache you can't measure is a cache you don't understand. Track at minimum:

- **Hit ratio** per key namespace. Below 80% is usually a bug, not a cache.
- **Latency p50/p99** for cache GET and source fallback.
- **Eviction rate** — high evictions means cache is undersized or TTLs too long.
- **Stampede counter** — concurrent misses on the same key.

Alert on hit-ratio drops, not absolute hit count.

## Anti-Patterns

- **Caching writes** — almost always wrong. Cache derived reads, not state changes.
- **Caching auth/permission decisions** without tight TTLs — stale auth is a security incident.
- **Caching error responses** — a transient 500 becomes a 5-minute outage.
- **Cache as source of truth** — if losing the cache loses the data, it's a database, not a cache. Treat it like one.
- **Sharing one cache across unrelated services** — noisy neighbors evict each other's hot data.
- **No TTL "because we'll invalidate explicitly"** — see above.

## Related

- [data-architecture.md](data-architecture.md) — single-writer rule, consistency models
- [capacity-planning.md](capacity-planning.md) — sizing the cache tier
- Application Redis patterns: see `typescript-data-engineering/references/caching.md`
- Provisioning: see `cloud-infrastructure/references/elasticache.md`
