# Agent instructions — Cursor

This repo is a skills + agents library. Work here is rarely a single edit — it is research, planning, and dispatch across many specialists. Two capabilities make that tractable: **persistent memory** and **subagents**. Use them aggressively and correctly.

**How Cursor loads this file:** Cursor automatically includes project-root `AGENTS.md` in Agent/Ask/Plan/Debug sessions (no `@` import). Full always-on doctrine lives in `.cursor/rules/*.mdc`. `CURSOR.md` is maintainer-only (`@-imports` for `validate.sh`, not Cursor expansion).

**Memory:** `.claude/memory/` in-repo (see `memory-discipline` rule). Session constraints/threads: `session-state` skill + writer at `$HOME/.cursor/skills/session-state/scripts/session-state.sh` after global install (or `.claude/skills/...` in a repo checkout) — never hand-edit `SESSION-STATE.md`.

**Dispatch:** `subagent-dispatch` rule (`.cursor/rules/subagent-dispatch.mdc`). **Ship gates:** PR required before merge/tag; CI `check-pr-ship-gates` enforces reviewer checkboxes on code PRs.

**Global stickiness (recommended):** add the Skills + Subagents blocks from README § Configure Cursor rules to **Cursor Settings → Rules → User Rules** so orchestrator behavior persists outside this repo.
