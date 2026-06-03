---
name: shipping-and-launch
description: Prepares production launches. Use when preparing to deploy to production. Use when you need a pre-launch checklist, when setting up monitoring, when planning a staged rollout, or when you need a rollback strategy.
when_to_use: |
  Use when deploying a feature to production for the first time, releasing a
  significant change to users, migrating data or infrastructure, opening a beta
  or early access program, or any deployment that carries meaningful risk. Covers
  pre-launch checklists (code, security, performance, accessibility,
  infrastructure, documentation), feature flag lifecycle, staged rollout decision
  thresholds, monitoring setup, and rollback planning.

  Not when: the concern is CI/CD pipeline mechanics or canary deployment
  automation — use deployment-pipelines instead. For ongoing production
  operations, SLO tracking, and incident response after launch use
  site-reliability-engineering.
---

# Shipping and Launch

## Overview

Ship with confidence. The goal is not just to deploy — it's to deploy safely, with monitoring in place, a rollback plan ready, and a clear understanding of what success looks like. Every launch should be reversible, observable, and incremental.

## Universal Rules

1. Complete the full pre-launch checklist before any production deployment — no partial passes.
2. Every deployment needs a documented rollback plan written before the deploy starts.
3. Ship behind feature flags to decouple deployment from release; every flag has an owner and expiration.
4. Use a staged rollout (internal → 5% → 25% → 50% → 100%); advance only when all thresholds are green.
5. Have monitoring and error reporting configured before the first user sees the feature.
6. Monitor actively for the first hour after every production deploy.
7. Clean up feature flags within 2 weeks of full rollout.

## References

- [references/pre-launch-checklist.md](references/pre-launch-checklist.md) — Full checklist: code quality, security, performance, accessibility, infrastructure, documentation
- [references/rollout-strategy.md](references/rollout-strategy.md) — Feature flag lifecycle, staged rollout sequence, decision thresholds table, rollback plan template
- [references/monitoring-setup.md](references/monitoring-setup.md) — What to monitor, error reporting code, post-launch verification steps, rationalizations, red flags, verification checklist
- [references/security-checklist.md](references/security-checklist.md) — Security pre-launch checks
- [references/performance-checklist.md](references/performance-checklist.md) — Performance pre-launch checklist
- [references/accessibility-checklist.md](references/accessibility-checklist.md) — Accessibility verification before launch
