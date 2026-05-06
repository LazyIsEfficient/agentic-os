# planning-and-task-breakdown examples

Worked examples of `planning-and-task-breakdown` consuming a multi-slice brief from `/shape` and producing a parallel-dispatchable plan: per-task YAML frontmatter, an Execution DAG, and self-contained task blocks ready for a Cursor Background Agents runner, a CI matrix, or single-agent execution.

## Layout

| File | Source brief | Shape |
|------|--------------|-------|
| [`feature-rollout-okta-sso.md`](feature-rollout-okta-sso.md) | [`../prompt-shaper/feature-rollout.md`](../prompt-shaper/feature-rollout.md) | Multi-repo (3 repos), 11 tasks, contract-first parallelism |
| [`single-repo-feature-csv-export.md`](single-repo-feature-csv-export.md) | [`../prompt-shaper/single-repo-feature.md`](../prompt-shaper/single-repo-feature.md) | Single repo, 8 tasks, vertical slices with infra/code parallelism |

## How to read these

Each file shows:

1. **The input brief** — what the planner consumes (pasted from the shaper output).
2. **The planner's read-only investigation** — what it learned by reading the codebase before writing tasks.
3. **The output plan** — full plan document with Execution DAG, presentational task list, and per-task blocks.

The plan document is the only deliverable. Investigation context is shown here for clarity; in real use it lives in the planner's session memory and is summarized in the plan's Architecture Decisions section.

## What to pattern-match

- **The Execution DAG block** — how `→` (must finish before) and `||` (parallel-safe) express the partial order and parallelism budget. Checkpoints are explicit synchronization barriers.
- **Per-task YAML frontmatter** — stable IDs, `depends_on`, `parallel_safe`, `conflicts_with`, `files_write`, `branch_suffix`. This is what a dispatcher consumes.
- **Conflict edges** — when two tasks both write the same file, `conflicts_with` is set on both sides (the dispatcher only checks one side).
- **Contract-first parallelism** — an XS contract task (types, schema, interface) unblocks parallel consumers in the next layer.
- **Self-contained task blocks** — each block has enough context (description + acceptance + verification + files) to hand to a fresh agent without the rest of the document.

## What comes next

The plan feeds execution. Two options:

- **Cursor Background Agents (parallel).** A dispatcher reads the DAG, computes the ready set, filters by `conflicts_with`, and spawns one agent per ready task on its own branch (`branch_suffix`). The agent receives the single task block as its prompt. Verification gates each task before the next layer dispatches.
- **Single-agent execution (serial).** Hand the whole plan to `incremental-implementation`, which lands tasks in dependency order with verification at each step. Slower than parallel but simpler to operate.

Either way, the plan is the contract. The shaper produced the brief; the planner produced the plan; the executor consumes the plan and ships code.
