## Summary

<!-- What changed and why -->

## Ship gates (required — CI enforces checkboxes)

Orchestrator rule: spawn reviewers via `Task` **before** marking work done. Check after dispatch:

- [ ] **code-reviewer** — `Task(subagent_type="code-reviewer", readonly=true)` on this PR diff; Tier 0/1 findings fixed
- [ ] **security-reviewer** — required when diff touches hooks, `install*`, `assets/consumer/`, `SECURITY.md`, release/workflow scripts
- [ ] **library-reviewer** — required when diff touches `.claude/skills/` or `.claude/agents/`

**No direct merge or tag** until this PR is open and `check-pr-ship-gates` is green. Release flow: merge PR → tag on `main` → `gh release create`.

## Test plan

- [ ] `bash scripts/validate.sh`
- [ ] Other relevant tests listed here
