# Implementation close — `G-data-document`

Mandatory session-close contract for **implementation agents**: `engineer`, `rust-engineer`, `web3-engineer`, `godot-engineer`, `devops-engineer`, `phaser-engineer`.

Run this **before** reporting back to the orchestrator. The documenter's `DATA_MODEL.md` changes are then **committed** with the implementation (by you if your brief says to commit, otherwise by the orchestrator) before reviewers (`code-reviewer`, `security-reviewer`) run in gate Wave 1. Reviewer verdicts bind to that commit's HEAD, and the verifier runs on the committed diff.

## When

After implementation and local verification pass, **before** reporting back to the orchestrator.

## Steps

1. **Skip** when the diff is docs-only (same allowlist as ship gates — no contract-touching code).
2. Otherwise dispatch a **foreground** subagent spawn — **`Agent`** — with `subagent_type: "data-model-documenter"`: include every changed path (committed, uncommitted and new files — list new files explicitly), what was implemented, and instruction to merge into `DATA_MODEL.md` at project root per [data-model-documentation](../SKILL.md).
3. **Wait** for the documenter to return. Do not report complete until it finishes or you explicitly skip per step 1.

## Completion report

Include: `G-data-document: <updated | no-op | skipped-docs-only>` and the documenter's section summary.

## Review agents

`code-reviewer` and `security-reviewer` are **orchestrator-owned** — implementation agents do not dispatch them.
