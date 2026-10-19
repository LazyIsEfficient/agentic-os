---
description: Run the Pattern-3 review gate (gate DAG waves) on the current diff
allowed-tools: Bash, Agent
---

Run the mandatory **Pattern 3 — Build + review pairing** gate on the current branch diff.

**Canonical spec:** [gate-dag.md](../references/gate-dag.md) — node IDs, triggers, waves, checkpoints. Encode that DAG exactly; do not invent parallel shortcuts that skip Wave 2 when `DATA_MODEL.md` changes.

## Step 0 — `checkpoint:impl-verified`

1. Run `git diff --name-only origin/main...HEAD` and `git status --porcelain`. If both are empty, stop: **no changes to review.**
2. List every changed path: the branch diff plus uncommitted and untracked files you intend to ship. Do not include unrelated user work in progress.
3. Run local verification: `bash scripts/validate.sh` on any non-docs-only diff; plus task-specific checks. If verification fails, stop — do not dispatch gate agents. Optional: `bash scripts/gate-plan.sh` to list required gate nodes.

## Step 1 — Compute triggered nodes

From the changed path set, run `bash scripts/gate-plan.sh` (or classify flags the same way as `scripts/lib/gate-plan-lib.sh`). Include nodes per [gate-dag.md](../references/gate-dag.md) § Gate nodes and § Implementation close:

| Node | Include when |
|---|---|
| `G-code-review` | `is_code_change \|\| is_library` |
| `G-security-review` | `is_code_change \|\| is_library \|\| is_sensitive` |
| `G-data-document` | Same triggers. **Wave 0**, and only if implementation did not already run it at session close (no `G-data-document:` in the implementation agent's report) |
| `G-library-review` | `is_library` |
| `G-data-verify` | **Wave 2.** Include if `DATA_MODEL.md` is in the committed diff |

If the diff is docs-only per ship-gate allowlist, stop: **gates skipped.**

## Step 2 — Wave 0: document, then commit

1. If `G-data-document` is triggered and was not run at implementation close, dispatch **`data-model-documenter`** and wait for it.
2. **Commit** the changes you intend to ship, including `DATA_MODEL.md`. Never commit files you did not create for this task. Verdicts bind to `git rev-parse HEAD`, and the Stop gate ([gate-dag.md](../references/gate-dag.md) § Stop gate) only accepts artifacts for the current HEAD. Any commit after Wave 1 discards Wave 1's verdicts.

## Step 3 — Wave 1 (parallel)

Dispatch **only the triggered Wave 1 reviewers** in a **single message, multiple Agent calls**. Wait for **all** of them to return:

- **`code-reviewer`**, if `G-code-review` is triggered
- **`security-reviewer`**, if `G-security-review` is triggered
- **`library-reviewer`**, if `G-library-review` is triggered

Brief each agent with **only** the base ref (e.g. `origin/main`) and the exact changed paths — no goal, no rationale, no pasted diff. Each reviewer runs `git diff <base>...HEAD` itself (cold-context invariant in its agent file) and ends with an `agentic-os/review-verdict@1` block ([review-verdict.md](../references/review-verdict.md)).

## Step 4 — Wave 2 (conditional)

1. Check whether `DATA_MODEL.md` is in the committed diff: `git diff --name-only <base>...HEAD -- DATA_MODEL.md`.
2. If it is, dispatch **`data-model-verifier`** (`G-data-verify`) with `readonly: true`. Give it only the base ref, the changed section names and the Source paths (cold context).
3. If it returns **hold** (REFUTED > 0), fix the catalog or source and commit. That moves HEAD, so re-dispatch **every** required reviewer (Steps 3–4) until all pass.

## Step 5 — `checkpoint:ship-ready`

1. Do **not** hand-record verdicts. The `SubagentStop` hook (`review-verdict-capture.sh`) has already parsed each reviewer's block and written `.claude/reviews/<HEAD>-<agent>.json`. List them with `jq .verdict .claude/reviews/"$(git rev-parse HEAD)"-*.json`.
   - A reviewer with no artifact emitted a malformed or stale-head block. Re-dispatch it.
   - `hold` means an evidenced tier 0/1 finding.
   - `fix-before-merge` is advisory.
2. Fix Tier 0/1 findings. Each fix is a new commit, so re-run Waves 1–2 for the new HEAD. Log Tier 2 findings to the findings ledger ([findings-ledger](../skills/findings-ledger/SKILL.md)).
3. Do **not** mark work complete until all required nodes have run on the final HEAD and findings are addressed.

Per [review-tiers](../rules/review-tiers.md): Tier 2 alone does not block; Tier 1 requires evidence to block.
