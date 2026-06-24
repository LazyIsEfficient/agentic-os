## Summary

<!-- What changed and why -->

## Ship gates (required — CI enforces checkboxes)

Run locally: `bash scripts/gate-plan.sh` (or set `SHIP_GATES_CHANGED_FILES` to your changed paths) — check every agent listed under `checkboxes=`.

**Wave 1** (parallel, triggered nodes only):

- [ ] **code-reviewer** — when non-docs code or library paths changed (`readonly: true`)
- [ ] **security-reviewer** — on any non-docs-only PR (`readonly: true`)
- [ ] **data-model-documenter** — on any non-docs-only PR (writes `DATA_MODEL.md` at project root)
- [ ] **library-reviewer** — when diff touches `.claude/skills/` or `.claude/agents/` (`readonly: true`)

**Wave 2** (after Wave 1, when `DATA_MODEL.md` changed):

- [ ] **data-model-verifier** — adversarial property check against Source files (`readonly: true`)

Canonical DAG: `.claude/references/gate-dag.md`

**No direct merge or tag** until this PR is open and `check-pr-ship-gates` is green. Release flow: merge PR → tag on `main` → `gh release create`.

## Test plan

- [ ] `bash scripts/validate.sh`
- [ ] `bash scripts/gate-plan-test.sh`
- [ ] Other relevant tests listed here
