# Performance Checklist

## Before Optimizing

- [ ] Measured baseline exists (Lighthouse score, profiler trace, or APM data)
- [ ] Bottleneck is identified from measurement, not assumption
- [ ] Target metric and threshold are defined (e.g., LCP < 2.5s, p99 API < 200ms)
- [ ] Regression guard is in place (CI budget check or monitoring alert)

## Web / Frontend

- [ ] Images: `width`, `height`, `loading="lazy"`, and modern format (`webp`/`avif`) set
- [ ] Largest Contentful Paint element identified and preloaded if off-screen
- [ ] No render-blocking scripts in `<head>` without `defer`/`async`
- [ ] Bundle analyzed (`webpack-bundle-analyzer` / `vite --analyze`); no unexpectedly large deps
- [ ] Code-split at route boundaries; dynamic `import()` for rarely-used modules
- [ ] Fonts loaded with `font-display: swap`; subset if full charset not needed
- [ ] Third-party scripts loaded with `async` or via Partytown
- [ ] React: memoize expensive computations with `useMemo`; stable callback refs with `useCallback`
- [ ] React: list items have stable `key` props; avoid inline object/array literals in JSX props

## Database / API

- [ ] N+1 queries eliminated — use `SELECT ... IN (...)` or eager-loading
- [ ] Query explains reviewed for full-table scans; indexes added where needed
- [ ] Paginated all list endpoints; no unbounded `SELECT *`
- [ ] Cached hot read paths (Redis / CDN / HTTP `Cache-Control`); TTL matches staleness tolerance
- [ ] Database connection pool sized correctly; no pool exhaustion under load
- [ ] Slow query log reviewed; any query > 100ms investigated

## Node / Server

- [ ] CPU-bound work moved off event loop (worker threads or queue)
- [ ] Streaming responses for large payloads instead of buffering in memory
- [ ] Response compression enabled (`gzip`/`brotli`)
- [ ] HTTP keep-alive enabled; connection overhead verified in profiler

## Optimization Commands

```bash
# Lighthouse CI (Node)
npx lhci autorun

# Bundle size analysis (Vite)
npx vite build --mode production && npx vite-bundle-visualizer

# Bundle size analysis (Next.js)
ANALYZE=true next build

# React render profiler (DevTools)
# Open Chrome DevTools → Profiler → Record → interact → Stop

# Postgres slow query log
SELECT query, mean_exec_time, calls FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 20;

# Node heap snapshot
node --inspect your-server.js  # then DevTools → Memory → Take Heap Snapshot
```

## After Optimizing

- [ ] Metric measured again — confirms improvement against baseline
- [ ] No regressions introduced in other metrics
- [ ] CI budget check updated if thresholds changed
- [ ] PR description includes before/after numbers
