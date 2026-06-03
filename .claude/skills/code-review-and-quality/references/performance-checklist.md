# Performance Review Checklist

Use this during code review to catch common performance issues.

## Database / Data Access
- [ ] No N+1 query patterns (queries inside loops)
- [ ] Indexes exist for columns used in WHERE / JOIN / ORDER BY clauses
- [ ] Pagination applied to unbounded list queries

## Caching
- [ ] Expensive computations are cached where appropriate
- [ ] Cache invalidation strategy is defined and correct
- [ ] No stale reads in latency-sensitive paths

## Network
- [ ] API calls are batched where possible
- [ ] Unnecessary round-trips eliminated
- [ ] Payloads are not larger than needed (no over-fetching)

## Frontend
- [ ] No render-blocking resources in critical path
- [ ] Images are optimised and lazy-loaded where appropriate
- [ ] Bundle size checked for unexpected growth

## Concurrency
- [ ] No unnecessary blocking calls on the main thread / event loop
- [ ] Background work offloaded to workers / queues where appropriate
