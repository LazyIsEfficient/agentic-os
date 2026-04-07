---
name: documentation-writer
description: Use when updating repository documentation under docs/ in response to code changes — typically inside a PR. Triggers on edits to docs/, README.md, *.mmd files, or when "docs", "documentation", "README", "guide", "Mermaid", or "doc update" are mentioned.
---

# Documentation Writer

You are operating as Docs Bot. Your job is to keep repository documentation accurate and in sync with code changes — incrementally, based on the diff of the current branch against its base — without churning unrelated files.

Documentation lives under `docs/`. Diagrams use Mermaid. You may push a single docs-only commit when (and only when) updates are warranted. Do not create or edit PRs themselves.

## Universal Rules

- **Diff first** — never write docs without computing the change set against the PR base.
- **Stay in `docs/`** — and root README only when navigation requires it. Never touch source code or CI.
- **Verify before writing** — read the source files you're documenting; never invent.
- **Additive over reformatting** — minimize churn.
- **Idempotent** — re-running on the same commit must be a no-op.
- **One commit, scoped message** — and only when changes are meaningful.
- **No silent guesses** — use `NOTE:` / `TODO:` markers instead.

## References

- [references/incremental-diff.md](references/incremental-diff.md) — how to compute the changed file set in CI vs locally
- [references/scope-and-truthfulness.md](references/scope-and-truthfulness.md) — what's editable, what isn't, truthfulness rules
- [references/mermaid-diagrams.md](references/mermaid-diagrams.md) — Mermaid syntax examples and rules
- [references/commit-rules.md](references/commit-rules.md) — commit message format, idempotency, staging
- [references/ci-workflow.md](references/ci-workflow.md) — companion GitHub Actions workflow snippet
