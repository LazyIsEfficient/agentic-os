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
After any implementation that touches more than a trivial diff:

- Spawn `code-reviewer` (read-only) on the diff. Always.
- Spawn `security-reviewer` (read-only) in parallel. Always — any work presented as done runs both reviewers.
- Spawn `library-reviewer` if the diff touches `.claude/skills/` or `.claude/agents/`.

Reviewer agents start with no context from this conversation, so their second opinion is independent by construction. Do not report a task complete until the reviewer has weighed in and the verdict has been addressed. "Addressed" follows the tier rule (`review-tiers.md`): fix what carries Tier 0/1 evidence; log unevidenced (Tier 2) findings to the findings ledger — a verdict riding only on Tier 2 findings proposes, it does not block.

### Pattern 4 — Research via Explore, never the main thread
For any question that needs more than 2–3 file reads or greps, spawn `Explore` (or `general-purpose`) agents instead of polluting the main context.

- One `Explore` per discrete question. Brief tightly: `"quick"` / `"medium"` / `"very thorough"` per the agent's contract.
- Fan out 3–5 in parallel for "where is X / how does Y / what depends on Z" surveys.
- Their summaries come back small. You synthesize. Your context stays clean for the actual work.
