# Task sizing and red flags

## Sizing table

| Size | Files | Scope | Example |
|------|-------|-------|---------|
| **XS** | 1 | Single function or config change | Add a validation rule |
| **S** | 1-2 | One component or endpoint | Add a new API endpoint |
| **M** | 3-5 | One feature slice | User registration flow |
| **L** | 5-8 | Multi-component feature | Search with filtering and pagination |
| **XL** | 8+ | **Too large — break it down further** | — |

If a task is L or larger, split it before dispatch. An agent performs best on S and M. XS is for contract tasks (types, interfaces, schemas) that unblock parallel work.

## When to break a task down further

- It would take more than one focused session (roughly 2+ hours of agent work)
- You cannot describe the acceptance criteria in 3 or fewer bullet points
- It touches two or more independent subsystems (e.g. auth and billing)
- You find yourself writing "and" in the task title (a sign it is two tasks)
- The `files_write` list has more than ~5 entries
- The verification step has more than 3 distinct checks

## Common rationalizations

| Rationalization | Reality |
|---|---|
| "I'll figure it out as I go" | That's how you end up with a tangled mess and rework. 10 minutes of planning saves hours. |
| "The tasks are obvious" | Write them down anyway. Explicit tasks surface hidden dependencies and forgotten edge cases. |
| "Planning is overhead" | Planning is the task. Implementation without a plan is just typing. |
| "I can hold it all in my head" | Context windows are finite. Written plans survive session boundaries and compaction. |
| "It's only one repo, I don't need a DAG" | The DAG is also conflict metadata. Even single-repo work benefits from declared `files_write`. |
| "Parallel is too risky for this work" | Then mark `parallel_safe: false`. The DAG still serializes correctly — it's a partial order, not a parallelism mandate. |

## Red flags

- Starting implementation without a written task list
- Tasks that say "implement the feature" without acceptance criteria
- No verification steps in the plan
- All tasks are XL-sized
- No checkpoints between phases
- Dependency order isn't considered
- Same task ID reused after a rename or removal (breaks every reference)
- DAG and per-task `depends_on` disagree
- `files_write` is empty on a non-trivial task (under-declared → parallel collisions)
- Every task is `parallel_safe: false` (over-declared → no parallelism budget)
- Plan has no day-zero ready set (every task depends on something) — circular or malformed
