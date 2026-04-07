# Workflow Structure

How to organize `.github/workflows/` and what belongs where.

## File Layout

```
.github/
├── workflows/
│   ├── ci.yml                    # PR validation: lint, type, test
│   ├── deploy-staging.yml        # auto-deploy on merge to main
│   ├── deploy-production.yml     # manual or tag-triggered
│   ├── release.yml               # changelog, version bump, publish
│   └── _reusable-test.yml        # workflow_call, prefixed with _
├── actions/
│   └── setup-node-deps/
│       └── action.yml            # composite action
└── CODEOWNERS
```

Conventions:
- One responsibility per file.
- Reusable workflows prefixed `_` so they sort together.
- Composite actions live under `.github/actions/<name>/action.yml`.

## Triggers

| Trigger | Use for | Notes |
|---|---|---|
| `pull_request` | PR validation | Safe — runs in PR's untrusted context |
| `push` (branches) | Main-branch deploys | Filter to `main` / `release/*` |
| `workflow_dispatch` | Manual deploys, ad-hoc jobs | Always include `inputs:` for parameters |
| `workflow_call` | Reusable workflow | Define `inputs:` and `secrets:` |
| `schedule` | Nightly tasks | Cron in UTC |
| `release` | Post-release tasks | Triggered when a release is published |
| `pull_request_target` | **Avoid** unless you know exactly why | Runs in trusted context with PR data |

## Job Structure

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]

permissions: {}                     # zero by default

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha>
      - uses: ./.github/actions/setup-node-deps
      - run: npm run lint

  test:
    needs: lint                     # gate expensive jobs on cheap ones
    runs-on: ubuntu-24.04
    timeout-minutes: 15
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<sha>
      - uses: ./.github/actions/setup-node-deps
      - run: npm test
```

Required on every job: `runs-on` with pinned OS, `timeout-minutes`, scoped `permissions`.

## Matrices

Use for parallelizing across versions / shards / OSes:

```yaml
strategy:
  fail-fast: false                  # don't cancel siblings on first failure
  matrix:
    node: [20, 22]
    shard: [1, 2, 3, 4]
```

Anti-patterns:
- Matrix that produces 1 combination → just write the job inline.
- Matrix > 20 combinations → you're paying for runners you don't need.

## Reusable Workflows vs Composite Actions

| | Reusable Workflow | Composite Action |
|---|---|---|
| Scope | Shared across repos | Shared within a repo (or vendored) |
| Defines | Whole jobs | A sequence of steps |
| Inputs | `inputs:` + `secrets:` | `inputs:` only |
| Runs on | Caller's runners | Caller's runner (same job) |
| Use when | Standardized pipelines org-wide | DRYing up steps in one repo |

```yaml
# caller
jobs:
  test:
    uses: org/.github/.github/workflows/_reusable-test.yml@<sha>
    with:
      node-version: 22
    secrets: inherit
```

## When to Split a Workflow

Split when ANY of these is true:
- Different triggers (PR vs tag vs schedule).
- Different permission requirements (read vs write vs deploy).
- Different SLOs (CI must be fast; nightly can be slow).
- Different ownership (frontend team owns lint, SRE owns deploy).

Don't split just to feel organized — each workflow file is overhead.

## Anti-Patterns

- **One mega-workflow** with `if:` everywhere. Hard to read, hard to debug.
- **Implicit ordering via `sleep`**. Use `needs:` instead.
- **Hardcoded paths** (`/home/runner/...`). Use `${{ runner.temp }}` or step outputs.
- **`continue-on-error: true`** to silence failures. Fix the failure or remove the step.
- **Workflows that mutate the repo** (auto-format commits) without a clear loop guard.
