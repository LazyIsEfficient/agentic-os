---
description: Run the Pattern-3 review gate (code-reviewer + security-reviewer + data-model-documenter + library-reviewer as warranted) on the current diff
allowed-tools: Bash, Agent
---

Run this repo's mandatory **Pattern 3 — Build + review pairing** gate on the current working-tree diff. The routing below is quoted verbatim from ship-gate doctrine and must be encoded exactly:

> - Spawn `code-reviewer` (read-only) on the diff. Always.
> - Spawn `security-reviewer` (read-only) in parallel. Always.
> - Spawn `data-model-documenter` in parallel. Always — updates `DATA_MODEL.md` at the project root.
> - Spawn `library-reviewer` if the diff touches `.claude/skills/` or `.claude/agents/`.

## Steps

1. **See the changes.** Run `git status --porcelain` to list every changed path **including brand-new untracked files** (a plain `git diff` omits untracked files, which would hide a newly-created `.claude/agents/foo.md` and defeat the `library-reviewer` trigger below). Then run `git diff HEAD` for the tracked diff, and `git add -N <untracked paths>` (intent-to-add) so the untracked files also appear in a follow-up `git diff`. Use the combined set of paths from `git status --porcelain` — not just the diff — when deciding whether to dispatch `library-reviewer` in step 2. If `git status --porcelain` is empty, stop and report "no changes to review."

2. **Always dispatch in parallel** via the Agent tool (single message, multiple Agent calls):
   - **`code-reviewer`** — read-only, full diff. Unconditional.
   - **`security-reviewer`** — read-only, full diff. Unconditional.
   - **`data-model-documenter`** — writes/merges `DATA_MODEL.md` at project root. Unconditional (no-op changelog if no contract changes).
   - **`library-reviewer`** — read-only — if ANY changed file is under `.claude/skills/` or `.claude/agents/`.

3. **Brief each agent** with the goal, the exact changed file paths, and the diff to review. Agents start with no context from this conversation — give them the diff explicitly.

4. **Collect verdicts and report them.** Summarize each agent's findings and overall verdict. Per the gate: do NOT mark the work done until every agent has weighed in and the raised verdicts have been addressed. "Addressed" follows the tier rule (`.claude/rules/review-tiers.md`): findings with Tier 0/1 evidence (a failing script, test, or concrete counterexample) must be fixed or explicitly waived by the user before declaring success; unevidenced (Tier 2) findings are advisory — log them to the findings ledger (`findings-ledger` skill) rather than blocking on them, and say in the report which findings went where.
