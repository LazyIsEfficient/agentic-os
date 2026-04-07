# Performance and Cost

CI minutes are money and developer time. Both matter.

## Concurrency Groups

Cancel superseded runs on the same ref:

```yaml
concurrency:
  group: ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

For deploys, **don't cancel in progress** — let the in-flight deploy finish:

```yaml
concurrency:
  group: deploy-production
  cancel-in-progress: false
```

This also serializes deploys so two runs don't race.

## Path Filters

Skip workflows when irrelevant files change:

```yaml
on:
  pull_request:
    paths:
      - 'src/**'
      - 'package.json'
      - 'package-lock.json'
      - '.github/workflows/ci.yml'
    paths-ignore:
      - 'docs/**'
      - '**/*.md'
```

Caveat: required status checks + `paths` is a known footgun — a skipped workflow shows as "expected" not "passing", blocking merge. Workarounds:
- Use a final aggregating job that always runs and reports overall status.
- Use the `dorny/paths-filter` action to gate steps inside a workflow that always runs.

## Fail Fast on Cheap Checks

Order jobs cheapest → most expensive, gating with `needs:`:

```
lint (30s) ──► type-check (1m) ──► unit (3m) ──► integration (10m) ──► e2e (15m)
```

A type error shouldn't burn 15 minutes of e2e runner time.

## Parallelization

### Matrix sharding for slow test suites

```yaml
strategy:
  fail-fast: false
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npm test -- --shard=${{ matrix.shard }}/4
```

Sweet spot: shard count ≈ ceil(serial_time / 5 minutes). More than that and runner spin-up dominates.

### Job-level parallelism

Independent jobs run in parallel automatically. Don't `needs:` them unnecessarily.

## Runner Sizing

| Workload | Runner |
|---|---|
| Lint, type-check, format | `ubuntu-24.04` (2-core) |
| Unit tests | `ubuntu-24.04` (2-core) |
| Integration / e2e | `ubuntu-24.04` (4-core) or larger |
| Container builds | larger runner; buildx with cache |
| ML / heavy compilation | self-hosted or large runner SKU |

Bigger runners cost more per minute but finish faster. Test the trade-off — `ubuntu-latest-8-core` finishing a 2× faster job costs the same as the small runner. Faster CI is worth more than the difference.

## Caching → see [caching-and-artifacts.md](caching-and-artifacts.md)

## Cost Reduction Checklist

- [ ] `concurrency` cancels superseded PR runs
- [ ] Doc-only PRs don't trigger full CI (path filters)
- [ ] Cheap checks gate expensive ones (`needs:`)
- [ ] Test suite is sharded if it runs > 5 min serially
- [ ] Setup action caching is enabled for language toolchains
- [ ] Artifact retention right-sized (not 90d default everywhere)
- [ ] Self-hosted runners only where they're cheaper than hosted at your volume
- [ ] No `sleep` in workflows (use `needs:` or polling actions)
- [ ] Workflow runtime tracked over time — regressions get treated like prod regressions

## Measure

GitHub provides usage data per workflow. Look at **monthly minutes per workflow**, not just total. The single workflow eating 70% of your minutes is where your optimization belongs.

For PR latency, track **median time from push → all checks green**. That's the developer-experience number that matters more than total minutes.
