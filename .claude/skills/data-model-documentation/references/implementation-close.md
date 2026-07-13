# Implementation close — `G-data-document`

Mandatory session-close contract for **implementation agents**: `engineer`, `rust-engineer`, `web3-engineer`, `godot-engineer`, `devops-engineer`, `phaser-engineer`.

Run this **before** reporting back to the orchestrator. The orchestrator then runs reviewers (`code-reviewer`, `security-reviewer`) in gate Wave 1.

## When

After implementation and local verification pass, **before** reporting back to the orchestrator.

## Steps

1. **Skip** when the diff is docs-only (same allowlist as ship gates — no contract-touching code).
2. Otherwise dispatch a **foreground** subagent spawn — **`Agent`** — with `subagent_type: "data-model-documenter"`: include every changed path (untracked via `git add -N`), what was implemented, and instruction to merge into `DATA_MODEL.md` at project root per [data-model-documentation](../SKILL.md).
3. **Wait** for the documenter to return. Do not report complete until it finishes or you explicitly skip per step 1.

## Completion report

Include: `G-data-document: <updated | no-op | skipped-docs-only>` and the documenter's section summary.

## Review agents

`code-reviewer` and `security-reviewer` are **orchestrator-owned** — implementation agents do not dispatch them.
