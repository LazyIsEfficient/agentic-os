# Application Caching (Redis + In-Process)

Implementation patterns for caching at the application tier in TypeScript services. For caching strategy and trade-offs see the `engineer` agent.

## Universal Rules

1. **Always set a TTL.** No exceptions. A cache without a TTL is a memory leak.
2. **Namespace every key** by entity type and schema version: `user:v2:42`. Never bare IDs.
3. **Idempotent reads, atomic writes.** Use `SET key value EX ttl NX` (or library equivalent) to avoid lost updates.
4. **Serialize once at the boundary** — JSON for shared state, MessagePack if you measure and care.
5. **Validate cached values with Zod on read.** Stale schemas creep in; fail loudly, fall through to source.
6. **Wrap, don't sprinkle.** Caching belongs in a thin repository layer, not littered across services.
7. **Never cache auth/permission decisions** beyond a few seconds. Stale auth is a security incident.
8. **Never cache error responses.** A transient 500 becomes a 5-minute outage.
9. **Singleflight on hot keys.** Coalesce concurrent misses; don't stampede the source.
10. **Observe hit ratio per namespace.** Below ~80% is usually a misuse, not a cache.

## Cache-Aside with `ioredis`

```typescript
import Redis from 'ioredis'
import { z } from 'zod'

const redis = new Redis(process.env.REDIS_URL!)

const UserSchema = z.object({ id: z.string(), email: z.string(), tier: z.enum(['free', 'pro']) })
type User = z.infer<typeof UserSchema>

const TTL_SECONDS = 300

async function getUser(id: string): Promise<User> {
  const key = `user:v2:${id}`
  const cached = await redis.get(key)

  if (cached) {
    const parsed = UserSchema.safeParse(JSON.parse(cached))
    if (parsed.success) return parsed.data
    // Schema drift — drop and refetch.
    await redis.del(key)
  }

  const user = await prisma.user.findUniqueOrThrow({ where: { id } })
  await redis.set(key, JSON.stringify(user), 'EX', TTL_SECONDS)
  return user
}
```

## Singleflight (Stampede Protection)

When N concurrent requests miss the same key, only one should hit the source. Pattern using a short-lived lock key:

```typescript
async function getWithSingleflight<T>(
  key: string,
  ttlSec: number,
  loader: () => Promise<T>,
): Promise<T> {
  const cached = await redis.get(key)
  if (cached) return JSON.parse(cached)

  const lockKey = `${key}:lock`
  const gotLock = await redis.set(lockKey, '1', 'EX', 10, 'NX')

  if (gotLock) {
    try {
      const fresh = await loader()
      await redis.set(key, JSON.stringify(fresh), 'EX', ttlSec)
      return fresh
    } finally {
      await redis.del(lockKey)
    }
  }

  // Another request is loading. Brief poll/backoff for the populated value.
  for (let i = 0; i < 20; i++) {
    await new Promise((r) => setTimeout(r, 50))
    const val = await redis.get(key)
    if (val) return JSON.parse(val)
  }

  // Lock holder failed — fall through to direct load.
  return loader()
}
```

For higher-traffic systems, prefer a library that implements XFetch or stale-while-revalidate (`async-cache-dedupe`, `cachified`).

## Stale-While-Revalidate

Serve a stale value past TTL while one background request refreshes it:

```typescript
type Cached<T> = { value: T; freshUntil: number; staleUntil: number }

async function swr<T>(
  key: string,
  freshSec: number,
  staleSec: number,
  loader: () => Promise<T>,
): Promise<T> {
  const raw = await redis.get(key)
  const now = Date.now()

  if (raw) {
    const entry = JSON.parse(raw) as Cached<T>
    if (now < entry.freshUntil) return entry.value
    if (now < entry.staleUntil) {
      // Background refresh; do not await.
      void refresh(key, freshSec, staleSec, loader)
      return entry.value
    }
  }

  return refresh(key, freshSec, staleSec, loader)
}

async function refresh<T>(key: string, freshSec: number, staleSec: number, loader: () => Promise<T>): Promise<T> {
  const value = await loader()
  const now = Date.now()
  const entry: Cached<T> = {
    value,
    freshUntil: now + freshSec * 1000,
    staleUntil: now + (freshSec + staleSec) * 1000,
  }
  await redis.set(key, JSON.stringify(entry), 'EX', freshSec + staleSec)
  return value
}
```

## Invalidation Patterns

### TTL only
Simplest. Accept the staleness window. Default choice unless something else is needed.

### Event-driven eviction
On write, publish an invalidation message; consumers `DEL` the affected keys. Pairs with the [outbox pattern](event-sourcing.md):

```typescript
await prisma.$transaction(async (tx) => {
  await tx.user.update({ where: { id }, data })
  await tx.outbox.create({ data: { topic: 'cache.invalidate', payload: { keys: [`user:v2:${id}`] } } })
})
```

### Versioned keys (cache-busting)
Embed a version in the key; bump the version to invalidate everything matching that prefix atomically:

```typescript
const version = await redis.get('user:version') ?? '1'
const key = `user:v${version}:${id}`
// To invalidate everything: redis.incr('user:version')
```

No `KEYS *` or `SCAN`-then-delete. Versioning is O(1).

### Tag-based invalidation
Maintain a set of keys per tag; invalidate the tag, then delete all keys in the set. Useful for "invalidate everything for user 42":

```typescript
await redis.sadd(`tag:user:42`, key)
await redis.expire(`tag:user:42`, ttl)
// To invalidate:
const keys = await redis.smembers('tag:user:42')
if (keys.length) await redis.del(...keys, 'tag:user:42')
```

## In-Process LRU

For per-instance hot data (config, feature flags, small lookup tables) where Redis round-trips dominate:

```typescript
import { LRUCache } from 'lru-cache'

const flagCache = new LRUCache<string, boolean>({
  max: 1000,
  ttl: 1000 * 30, // 30s
})

async function isEnabled(flag: string, userId: string): Promise<boolean> {
  const key = `${flag}:${userId}`
  const hit = flagCache.get(key)
  if (hit !== undefined) return hit
  const value = await loadFlag(flag, userId)
  flagCache.set(key, value)
  return value
}
```

Rules:
- **Cap by `max`**, not just `ttl` — unbounded LRUs OOM.
- **Don't share LRU across instances' assumptions** — each pod has its own copy. Eventual consistency only.
- **Invalidate on deploy** by giving the cache a process-scoped version key.

## Hot Key Mitigation

A single key receiving thousands of QPS will saturate one Redis shard. Replicate across N suffixes and pick at random:

```typescript
const SHARDS = 10

async function getLeaderboard(): Promise<Entry[]> {
  const shard = Math.floor(Math.random() * SHARDS)
  const key = `leaderboard:${shard}`
  // ... cache-aside on key
}
```

On write, update all shards (or accept slightly stale shards if you can).

## Observability

Track per-namespace metrics:

```typescript
import { Counter, Histogram } from 'prom-client'

const cacheOps = new Counter({
  name: 'cache_ops_total',
  help: 'Cache operations',
  labelNames: ['namespace', 'op', 'result'], // result: hit | miss | error
})

const cacheLatency = new Histogram({
  name: 'cache_latency_seconds',
  help: 'Cache operation latency',
  labelNames: ['namespace', 'op'],
})
```

Alert on hit-ratio drops in a namespace, not on absolute miss count.

## Anti-Patterns

- **No TTL** — leak.
- **`KEYS *`** — blocks Redis. Use `SCAN` only for ops, never request path. Prefer versioned keys.
- **Caching writes** — cache derived reads, not state changes.
- **One huge JSON blob** that callers all parse — split by access pattern.
- **Caching at every layer** without measuring — multi-tier amplifies invalidation bugs.
- **Using Redis as the source of truth** without persistence + backup — that's a database, not a cache.
- **Sharing one Redis across unrelated services** — noisy neighbors evict each other.

## Related

- the `engineer` agent — strategy patterns, TTL design, multi-tier
- [event-sourcing.md](event-sourcing.md) — outbox-driven cache invalidation
- the `devops-engineer` agent — provisioning Redis
