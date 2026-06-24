---
description: Run the Pattern-3 review gate (gate DAG waves) on the current diff
allowed-tools: Bash, Agent
---

Run the mandatory **Pattern 3 — Build + review pairing** gate on the current working-tree diff.

**Canonical spec:** [gate-dag.md](../references/gate-dag.md) — node IDs, triggers, waves, checkpoints. Encode that DAG exactly; do not invent parallel shortcuts that skip Wave 2 when `DATA_MODEL.md` changes.

## Step 0 — `checkpoint:impl-verified`

1. Run `git status --porcelain`. If empty, stop: **no changes to review.**
2. List every changed path **including untracked files** (plain `git diff` omits them). Use `git add -N <untracked>` so contract/agent files appear in the diff.
3. Run local verification: `bash scripts/validate.sh` on any non-docs-only diff; plus task-specific checks. If verification fails, stop — do not dispatch gate agents.

## Step 1 — Compute triggered nodes

From the changed path set, classify flags the same way as `scripts/check-pr-ship-gates.sh` (`is_code_change`, `is_library`, `is_sensitive`). Then include nodes per [gate-dag.md](../references/gate-dag.md) § Gate nodes:

| Node | Include when |
|---|---|
| `G-code-review` | `is_code_change \|\| is_library` |
| `G-security-review` | `is_code_change \|\| is_library \|\| is_sensitive` |
| `G-data-document` | `is_code_change \|\| is_library \|\| is_sensitive` |
| `G-library-review` | `is_library` |
| `G-data-verify` | **After Wave 1** — if `DATA_MODEL.md` is in the post-documenter diff ([#191](https://github.com/LazyIsEfficient/agentic-os/issues/191); until shipped, require human catalog review) |

If the diff is docs-only per ship-gate allowlist, stop: **gates skipped.**

## Step 2 — Wave 1 (parallel)

Dispatch **only triggered Wave 1 nodes** in a **single message, multiple Agent calls** — wait for **all** to return before Wave 2. Typical mapping:

- **`code-reviewer`** — if `G-code-review` triggered
- **`security-reviewer`** — if `G-security-review` triggered
- **`data-model-documenter`** — if `G-data-document` triggered
- **`library-reviewer`** — if `G-library-review` triggered

Brief each agent with goal, exact changed paths, and diff. Agents start with no context from this conversation.

## Step 3 — Wave 2 (conditional)

After Wave 1 completes:

1. Re-check whether `DATA_MODEL.md` changed (`git diff HEAD -- DATA_MODEL.md` or status).
2. If yes and `data-model-verifier` exists: dispatch **`data-model-verifier`** (`G-data-verify`) read-only on the catalog diff + cited Source files.
3. If yes and verifier not shipped yet: report **manual catalog review required** in PR; do not mark ship-ready without calling it out.

## Step 4 — `checkpoint:ship-ready`

1. Summarize every gate agent verdict.
2. Fix Tier 0/1 findings; log Tier 2 to findings ledger ([findings-ledger](../skills/findings-ledger/SKILL.md)).
3. Do **not** mark work complete until all required nodes ran and findings are addressed.

Per [review-tiers](../rules/review-tiers.md): Tier 2 alone does not block; Tier 1 requires evidence to block.
