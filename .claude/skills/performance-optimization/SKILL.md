---
name: performance-optimization
description: Optimizes application performance — Core Web Vitals (LCP, INP, CLS), N+1 query elimination, bundle size reduction, profiling-driven bottleneck fixes, and response-time SLA enforcement. Use when metrics show regression, users report slow behavior, or profiling reveals a concrete bottleneck.
when_to_use: |
  Use when performance requirements exist in the spec (load time budgets, response time SLAs), when users or monitoring report slow behavior, when Core Web Vitals scores are below thresholds (LCP > 2.5s, INP > 200ms, CLS > 0.1), when a change introduced a suspected regression, or when building features that handle large datasets or high traffic and profiling reveals a concrete bottleneck.

  Not when: there is no evidence of a performance problem — premature optimization adds complexity without benefit. Not when the goal is SLO/SLI tracking, error-budget monitoring, alert tuning, or burn-rate analysis for a production system — use `site-reliability-engineering` for that; use performance-optimization when profiling has identified a code-level bottleneck that needs to be fixed. Not when the issue is a Godot or Phaser frame-budget concern — use `godot-engineer` or `phaser-engineer` for engine-specific profiling first.
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

## References

- [references/optimization-workflow.md](references/optimization-workflow.md) — Core Web Vitals targets, 5-step workflow, symptom-to-measurement decision tree, bottleneck tables
- [references/anti-patterns.md](references/anti-patterns.md) — N+1 queries, unbounded fetching, image optimization, re-renders, bundle size, caching patterns, rationalizations, red flags
- [references/performance-budget.md](references/performance-budget.md) — Budget targets, CI enforcement commands, verification checklist
- [references/performance-checklist.md](references/performance-checklist.md) — Detailed performance checklist and optimization commands
