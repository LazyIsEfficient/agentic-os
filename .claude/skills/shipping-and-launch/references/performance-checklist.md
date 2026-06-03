# Pre-Launch Performance Checklist

Performance checks to complete before any production launch.

## Core Web Vitals (web apps)
- [ ] LCP (Largest Contentful Paint) < 2.5s on mobile
- [ ] CLS (Cumulative Layout Shift) < 0.1
- [ ] INP (Interaction to Next Paint) < 200ms

## Load Testing
- [ ] Load test run at 2× expected peak traffic
- [ ] P95 response time within SLO
- [ ] No memory leaks observed under sustained load

## Database
- [ ] Slow query log reviewed; no queries > 100ms on hot paths
- [ ] Connection pool sized correctly for expected concurrency
- [ ] Indexes verified on all foreign keys and filter columns

## Caching & CDN
- [ ] Static assets served from CDN
- [ ] Cache-Control headers set correctly on static and API responses
- [ ] Cache hit rate > 80% on static assets

## Bundle / Assets (web apps)
- [ ] JS bundle size benchmarked; no unexpected growth from baseline
- [ ] Images optimised and served in modern formats (WebP/AVIF)
- [ ] Critical CSS inlined or preloaded
