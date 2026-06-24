## Subagent usage — non-negotiable habits

The default for any non-trivial work in this repo is **dispatch, don't do**. The orchestrator (you) decomposes, briefs, reviews, integrates. Subagents do the work.

### Pattern 1 — Shaper → planner → fan-out
Any vague request goes through a shaper before code is touched.

- Engineering work → `/shape` (`prompt-shaper`)
- Marketing work → `/mshape` (`marketing-shaper`)
- Game work → `/game-shape` (`game-design-shaper`)

The shaper produces a scoped brief. Feed the brief to `planning-and-task-breakdown` to produce a DAG with stable task IDs, declared file writes, conflict edges, and branch suffixes. Dispatch the DAG in parallel waves. Skip the shaper only when the request is already a fully-scoped brief — and say so explicitly when you skip.

### Pattern 2 — Parallel fan-out with worktree isolation
When tasks have no conflict edge between them, dispatch in a **single message with multiple `Agent` tool calls**. Sequential dispatch when work is independent is a bug.

- Use `isolation: "worktree"` whenever two or more agents may touch overlapping files. The harness creates a temporary worktree on its own branch and reports back the path.
- Use `run_in_background: true` only when you have genuinely independent main-thread work to do. Otherwise foreground — you need the result before the next decision.
- Cap concurrent waves at ~3–5 agents. Beyond that you cannot supervise quality.

### Pattern 3 — Build + review pairing (mandatory gate)

After any implementation that touches more than a trivial diff, run the **gate DAG** in [gate-dag.md](../references/gate-dag.md):

1. `checkpoint:impl-verified` — verification passes
2. **Implementation close:** when dispatch used an implementation agent (`engineer`, stack specialists — see [implementation-close.md](../skills/data-model-documentation/references/implementation-close.md)), that agent runs `G-data-document` before returning
3. **Wave 1 (parallel):** triggered reviewer nodes — always `G-security-review` on non-docs-only diffs; `G-code-review` when code/library; `G-library-review` when `is_library`; **`G-data-document` only if** the implementation agent did not already run it
4. **Wave 2 (conditional):** `data-model-verifier` when `DATA_MODEL.md` changed after Wave 1
5. `checkpoint:ship-ready` — Tier 0/1 addressed

Do not run verifier in parallel with documenter. Do not re-dispatch documenter if an implementation agent already reported `G-data-document`. Full node table and triggers: [gate-dag.md](../references/gate-dag.md).

### Pattern 4 — Research via Explore, never the main thread
For any question that needs more than 2–3 file reads or greps, spawn `Explore` (or `general-purpose`) agents instead of polluting the main context.

- One `Explore` per discrete question. Brief tightly: `"quick"` / `"medium"` / `"very thorough"` per the agent's contract.
- Fan out 3–5 in parallel for "where is X / how does Y / what depends on Z" surveys.
- Their summaries come back small. You synthesize. Your context stays clean for the actual work.
