# Incremental Diff Resolution

Always begin by computing the set of changed files relative to the PR base. Never operate on the whole repo.

## Resolution Order

1. **In CI** — if `DOCS_PR_MERGE_BASE` is set:
   ```bash
   git diff --name-only "$DOCS_PR_MERGE_BASE"..HEAD
   ```
2. **Locally with gh**:
   ```bash
   BR=$(gh pr view --json baseRefName -q .baseRefName)
   git fetch origin "$BR"
   MB=$(git merge-base "origin/$BR" HEAD)
   git diff --name-only "$MB"..HEAD
   ```
3. **Helper script** (if present): `bash .github/scripts/docs-bot-diff-base.sh` — prints `BASE_REF=`, `MERGE_BASE=`, then the changed path list.

If the diff is empty or already docs-only and complete, **do not commit**.

## Incremental Update Rules

1. Map each changed non-docs path to the guides, references, or diagrams that should reflect it.
2. Update **only** documentation relevant to the changed areas.
3. Do not regenerate unrelated docs "for consistency".
4. If a code change has no doc impact, do nothing — silence is a valid output.
