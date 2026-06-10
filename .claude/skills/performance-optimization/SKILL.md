---
name: performance-optimization
description: Optimizes application performance — Core Web Vitals (LCP, INP, CLS), N+1 query elimination, bundle size reduction, profiling-driven bottleneck fixes, and response-time SLA enforcement. Use when metrics show regression, users report slow behavior, or profiling reveals a concrete bottleneck.
when_to_use: |
  Use when performance requirements exist in the spec (load time budgets, response time SLAs), when users or monitoring report slow behavior, when Core Web Vitals scores are below thresholds (LCP > 2.5s, INP > 200ms, CLS > 0.1), when a change introduced a suspected regression, or when building features that handle large datasets or high traffic and profiling reveals a concrete bottleneck.

  Not when: there is no evidence of a performance problem — premature optimization adds complexity without benefit. Not when the goal is SLO/SLI tracking, error-budget monitoring, alert tuning, or burn-rate analysis for a production system — use `site-reliability-engineering` for that; use performance-optimization when profiling has identified a code-level bottleneck that needs to be fixed. Not when the issue is a Godot or Phaser frame-budget concern — use `godot-engineer` or `phaser-engineer` for engine-specific profiling first. Not when the task is specifically using Chrome DevTools to measure or observe behavior in a real browser — use `browser-testing-with-devtools`; this skill owns the optimization methodology once a bottleneck is identified.
---

# Performance Optimization

## Overview

Measure before optimizing. Performance work without measurement is guessing — and guessing leads to premature optimization that adds complexity without improving what matters. Profile first, identify the actual bottleneck, fix it, measure again. Optimize only what measurements prove matters.

## Universal Rules

1. Never optimize without a measured baseline — profiling data must exist before any change.
2. Fix the actual bottleneck; identify it from the symptom tree before writing code.
3. Measure again after the fix — confirm the improvement with real numbers.
4. Guard against regression with monitoring or CI budget checks.
5. Paginate all list endpoints; never fetch unbounded data.
6. Parameterize or batch queries — no N+1 patterns in new code.
7. Always include width, height, loading, and format attributes on images.
8. Set a performance budget and enforce it in CI.

## The Workflow

Always run these five steps in order. Skipping straight to a fix is the most common failure mode.

1. **Measure** — establish a baseline with real data. Synthetic (Lighthouse, DevTools Performance tab) for reproducibility; RUM (`web-vitals`, CrUX) to confirm a fix helped real users. Both, not one.
2. **Identify** — find the *actual* bottleneck from the symptom, not an assumed one.
3. **Fix** — change only the thing the measurement implicated.
4. **Verify** — measure again; confirm the improvement with specific before/after numbers.
5. **Guard** — add a CI budget check or monitoring alert so the win does not regress.

Core Web Vitals "Good" thresholds: **LCP ≤ 2.5s**, **INP ≤ 200ms**, **CLS ≤ 0.1**. Default budgets: JS < 200KB gzip initial, API < 200ms p95, Lighthouse ≥ 90.

## Symptom → First Action

Use the symptom to pick where to measure first. This is enough to start; `references/optimization-workflow.md` has the full decision tree and bottleneck tables.

| Symptom | First action |
|---|---|
| LCP > 2.5s | Lighthouse + Network waterfall; check LCP image size/priority and render-blocking CSS/JS |
| INP > 200ms | Record an interaction trace in the DevTools Performance tab; find long tasks (>50ms) on the main thread |
| CLS > 0.1 | Audit layout-shift attribution in DevTools; add `width`/`height` to media, reserve space for late content |
| Slow first load | Measure bundle size; route-split and lazy-load rarely-used modules behind `Suspense` |
| Slow TTFB | Check Network waterfall — split DNS/TLS vs server "Waiting"; if server, profile the backend |
| Slow single API endpoint | Run `EXPLAIN` on its queries; check for N+1 in the query log; add missing indexes |
| All endpoints slow | Check connection-pool sizing, CPU, and memory before touching any single query |
| Memory growth over time | Take heap snapshots and diff; look for leaked references or unbounded caches |
| Sluggish React UI | Profile renders in the React DevTools Profiler; remove inline object/array props, memoize the proven-hot path only |
| Code-level SLA/latency breach | Profile the hot path (flamegraph); fix it; add p99 monitoring. (SLO *tracking/alerting* itself → `site-reliability-engineering`.) |

Fixes for each pattern (N+1, unbounded fetch, image setup, re-renders, bundle splitting, caching) are in `references/anti-patterns.md`.

## References

- [references/optimization-workflow.md](references/optimization-workflow.md) — Core Web Vitals targets, 5-step workflow, symptom-to-measurement decision tree, bottleneck tables
- [references/anti-patterns.md](references/anti-patterns.md) — N+1 queries, unbounded fetching, image optimization, re-renders, bundle size, caching patterns, rationalizations, red flags
- [references/performance-budget.md](references/performance-budget.md) — Budget targets, CI enforcement commands, verification checklist
- [references/performance-checklist.md](references/performance-checklist.md) — Detailed performance checklist and optimization commands
