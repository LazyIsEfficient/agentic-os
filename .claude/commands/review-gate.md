---
description: Run the Pattern-3 review gate (code-reviewer + security/library-reviewer as warranted) on the current diff
allowed-tools: Bash, Task
---

Run this repo's mandatory **Pattern 3 — Build + review pairing** gate on the current working-tree diff. The routing below is quoted verbatim from `CLAUDE.md` and must be encoded exactly:

> - Spawn `code-reviewer` (read-only) on the diff. Always.
> - Spawn `security-reviewer` in parallel if the diff touches auth, sessions, secrets, input validation, crypto, smart contracts, CI/CD, or any user-input-to-sensitive-sink path.
> - Spawn `library-reviewer` if the diff touches `.claude/skills/` or `.claude/agents/`.

## Steps

1. **See the changes.** Run `git status --porcelain` to list every changed path **including brand-new untracked files** (a plain `git diff` omits untracked files, which would hide a newly-created `.claude/agents/foo.md` and defeat the `library-reviewer` trigger below). Then run `git diff HEAD` for the tracked diff, and `git add -N <untracked paths>` (intent-to-add) so the untracked files also appear in a follow-up `git diff`. Use the combined set of paths from `git status --porcelain` — not just the diff — when deciding which reviewers to dispatch in step 3. If `git status --porcelain` is empty, stop and report "no changes to review."

2. **Always dispatch `code-reviewer`** via the Task tool, read-only, on the full diff. This is unconditional.

3. **Inspect the changed paths and conditionally dispatch, in parallel** (single message, multiple Task calls, alongside `code-reviewer` where possible):
   - **`security-reviewer`** — if ANY changed file touches a sensitive sink: auth, sessions, secrets, input validation, crypto, smart contracts, CI/CD (e.g. `.github/workflows/`, deploy scripts), or any user-input-to-sensitive-sink path.
   - **`library-reviewer`** — if ANY changed file is under `.claude/skills/` or `.claude/agents/`.
   - If neither condition matches, dispatch `code-reviewer` alone.

4. **Brief each reviewer** with the goal, the exact changed file paths, and the diff to review. Reviewers start with no context from this conversation — give them the diff explicitly.

5. **Collect verdicts and report them.** Summarize each reviewer's findings and overall verdict. Per the gate: do NOT mark the work done until every reviewer has weighed in and the raised verdicts have been addressed. If any reviewer requests changes, surface them and stop short of declaring success.
