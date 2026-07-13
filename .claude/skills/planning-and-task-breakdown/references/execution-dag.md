# Execution DAG

The DAG is a top-of-document summary of dependency edges. Dispatchers (CI matrices, parallel agent harnesses) read it first to know what can run when.

## Syntax

Use `→` for "must finish before" and `||` for "may run in parallel."

```yaml
dag:
  - T-schema → T-register, T-login          # both depend on the schema
  - T-register || T-login                   # independent slices, parallel-safe
  - T-register, T-login → T-session         # session needs both verified first
  - T-session → T-history
  - checkpoint: Foundation after [T-session]
  - T-history || T-search                   # parallel after the foundation checkpoint
```

## Dispatcher contract

A parallel runner reads this DAG and:

1. Computes the **ready set** — every task whose `depends_on` is empty or fully verified.
2. Filters out tasks whose `conflicts_with` overlaps with anything currently in flight.
3. Dispatches the remaining tasks in parallel, each on its own branch (`branch_suffix`) or worktree.
4. Waits for verification before marking a task complete.
5. Stops dispatch downstream of any checkpoint until the checkpoint passes.

**Day-zero ready set** = every task with `depends_on: []`. If that list is empty, the plan is malformed — there must be at least one task with no upstream dependencies.

## Checkpoints

Checkpoints are synchronization barriers. No task downstream of a checkpoint dispatches until the checkpoint clears. Use them at:

- Foundation gates (auth, schema, infra) before feature slices fan out
- Pre-merge gates before destructive or globally-scoped changes
- End-of-phase gates where human review is required

Checkpoint clearance is verification + (optional) human approval. The dispatcher pauses and waits — it does not skip.

## Consistency with per-task frontmatter

The DAG is a *summary*, not a source of truth. Per-task `depends_on` is authoritative. The DAG and the per-task fields must match — the verification checklist enforces "the Execution DAG matches the per-task `depends_on` (no orphan IDs, no missing edges)."

If the DAG and the frontmatter disagree, fix the frontmatter first, then regenerate the DAG. Do not patch the DAG to hide a mismatch.

## Worked example

A small auth + history feature decomposed into seven tasks:

```yaml
dag:
  - T-schema → T-register, T-login
  - T-register || T-login                   # parallel-safe — different files
  - T-register, T-login → T-session
  - checkpoint: Foundation after [T-session]
  - T-session → T-history-api
  - T-history-api → T-history-ui || T-history-tests
  - checkpoint: Complete after [T-history-ui, T-history-tests]
```

The dispatcher's behavior on day zero:
- Ready set: `[T-schema]` (only task with empty `depends_on`)
- Dispatches `T-schema` on `feature/<branch>-schema`
- After verification, ready set becomes `[T-register, T-login]`
- Dispatches both in parallel (independent files)
- After both verify, ready set becomes `[T-session]`
- After `T-session` verifies, the Foundation checkpoint runs
- After checkpoint clears, ready set becomes `[T-history-api]`
- Then `[T-history-ui, T-history-tests]` in parallel
- Final checkpoint clears the plan
