# Parallelization decisions

The DAG and per-task `parallel_safe` / `conflicts_with` / `files_write` fields are how parallelism is *expressed*. This reference is how you decide what to put in those fields.

## Mark `parallel_safe: true` and leave `conflicts_with` empty when

- The task is an independent feature slice (own files, own tests, own UI surface)
- The task adds tests or docs for already-merged code
- The task touches a leaf module nothing else writes during this plan

## Mark `parallel_safe: false` when

- The task runs a destructive or globally-scoped operation (database migration, schema rename, dependency upgrade, secrets rotation)
- The task mutates shared state that downstream tasks read mid-flight
- The task changes a file that every other task imports (a barrel `index.ts`, a shared types file, a global config)

## Add `conflicts_with: [T-other]` when

- Two tasks would both write the same file. List both directions (T-a in T-b's `conflicts_with` *and* T-b in T-a's) — the dispatcher only checks one side.
- Two tasks share an API contract that's not yet locked. The cleaner fix is contract-first parallelism (below).

## Pattern: contract-first parallelism

When two slices share an interface (an API endpoint shape, a TypeScript type, a Solidity ABI), make the contract its own task with `scope: XS`. Both consumers list it in `depends_on`. Then they parallelize freely.

```
T-api-contract  (XS, no deps)
   ↓
T-frontend-consumer  ||  T-backend-implementation
```

Without contract-first, the two slices either serialize (one waits for the other to settle the shape) or thrash (both edit the contract concurrently and merge-conflict).

## Pattern: barrel-file serialization

A barrel file (`src/index.ts` re-exporting everything) is a parallelization killer — every feature task wants to write to it. Two options:

1. **Aggregator task.** Add a single end-of-phase task `T-update-barrel` that aggregates exports from all the feature slices. It depends on every feature slice; it has no `conflicts_with`. Feature slices do not write to the barrel themselves.
2. **Drop the barrel.** Skip the barrel for the duration of the parallel work; let each consumer import from concrete paths. Reintroduce the barrel later if needed.

## Pattern: migration as solo work

Database migrations and schema renames should be `parallel_safe: false` and have *every* downstream feature task in their `conflicts_with`. They run alone, the dispatcher waits for verification, then everything fans back out. Treat migrations as their own checkpoint:

```yaml
dag:
  - T-prep-feature-a, T-prep-feature-b → T-migration
  - checkpoint: Migration verified after [T-migration]
  - T-migration → T-feature-a || T-feature-b
```

## Pattern: long-running tasks

If a task is expected to run for an unusually long time (e.g. a slow test suite, a data migration), declare it explicitly in the prose so the dispatcher can choose to wait or parallelize differently. This is not a frontmatter field today — it's a callout the dispatcher's operator sees.

## When the parallelism budget is one

If only one agent runs at a time, `parallel_safe` and `conflicts_with` still matter — they let a future operator (or a future you, with more agents) replay the plan in parallel without re-deriving the safety analysis. Fill them out anyway.
