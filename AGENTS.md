# Agent instructions — Cursor

This repo is a skills + agents library. Work here is rarely a single edit — it is research, planning, and dispatch across many specialists. Two capabilities make that tractable: **persistent memory** and **subagents**. Use them aggressively and correctly.

**How Cursor loads this file:** Cursor automatically includes project-root `AGENTS.md` in Agent/Ask/Plan/Debug sessions (no `@` import). Full always-on doctrine lives in `.cursor/rules/*.mdc`. `CURSOR.md` is maintainer-only (enumerated `@`-imports of `.mdc` rules — not expanded at runtime).

**Memory:** `.claude/memory/` in-repo (see `memory-discipline` rule). Session constraints/threads: in a checkout use `.claude/skills/session-state/scripts/session-state.sh`; after global install use `$HOME/.cursor/skills/session-state/scripts/session-state.sh` (or `$HOME/.claude/skills/…` on Claude Code) — never hand-edit `SESSION-STATE.md`. Full chain: [install-paths.md](.claude/skills/findings-ledger/references/install-paths.md).

**Dispatch:** `subagent-dispatch` rule (`.cursor/rules/subagent-dispatch.mdc`). **Ship gates:** [gate-dag.md](.claude/references/gate-dag.md) — Wave 1 + conditional Wave 2; PR checkboxes enforced by CI.

**Global stickiness (recommended):** add the Skills + Subagents blocks from README § Configure Cursor rules to **Cursor Settings → Rules → User Rules** so orchestrator behavior persists outside this repo.
