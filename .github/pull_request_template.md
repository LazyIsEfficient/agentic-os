## Summary

<!-- What changed and why -->

## Ship gates (required — CI enforces checkboxes)

Before marking work **complete**, dispatch via `Task` (parallel, `readonly: true`) and check boxes after dispatch:

- [ ] **code-reviewer** — always, on this PR diff; Tier 0/1 findings fixed
- [ ] **security-reviewer** — always, in parallel with code-reviewer — not only for hook/install paths
- [ ] **library-reviewer** — when diff touches `.claude/skills/` or `.claude/agents/`

**No direct merge or tag** until this PR is open and `check-pr-ship-gates` is green. Release flow: merge PR → tag on `main` → `gh release create`.

## Test plan

- [ ] `bash scripts/validate.sh`
- [ ] Other relevant tests listed here
