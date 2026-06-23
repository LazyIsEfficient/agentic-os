# Agent instructions — Cursor

This repo is a skills + agents library. Work here is rarely a single edit — it is research, planning, and dispatch across many specialists. Two capabilities make that tractable: **persistent memory** and **subagents**. Use them aggressively and correctly.

**Memory:** `.claude/memory/` in-repo (see `memory-discipline` rule). Session constraints/threads: `session-state` skill + writer at `$PROJ/.claude/skills/session-state/scripts/session-state.sh` (then `~/.cursor/skills/…`) — never hand-edit `SESSION-STATE.md`.

**Dispatch and other doctrine:** `.cursor/rules/*.mdc` (`alwaysApply: true`). Maintainer index: `CURSOR.md`. Awareness harness activation: [docs/awareness-harness-activation.md](docs/awareness-harness-activation.md).
