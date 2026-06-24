## Summary

<!-- What changed and why -->

## Ship gates (required — CI enforces checkboxes)

Before marking work **complete**, dispatch via `Task` (parallel) and check boxes after dispatch:

- [ ] **code-reviewer** — always, on this PR diff; Tier 0/1 findings fixed (`readonly: true`)
- [ ] **security-reviewer** — always, in parallel with code-reviewer — not only for hook/install paths (`readonly: true`)
- [ ] **data-model-documenter** — always, in parallel; writes/updates `DATA_MODEL.md` at project root (not read-only)
- [ ] **library-reviewer** — when diff touches `.claude/skills/` or `.claude/agents/` (`readonly: true`)

**No direct merge or tag** until this PR is open and `check-pr-ship-gates` is green. Release flow: merge PR → tag on `main` → `gh release create`.

## Test plan

- [ ] `bash scripts/validate.sh`
- [ ] Other relevant tests listed here
