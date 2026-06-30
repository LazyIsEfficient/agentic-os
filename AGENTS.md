# Agent instructions — Cursor

This repo is a skills + agents library. Work here is rarely a single edit — it is research, planning, and dispatch across many specialists. Two capabilities make that tractable: **persistent memory** and **subagents**. Use them aggressively and correctly.

**How Cursor loads this file:** Cursor automatically includes project-root `AGENTS.md` in Agent/Ask/Plan/Debug sessions (no `@` import). Full always-on doctrine lives in `.cursor/rules/*.mdc`. `CURSOR.md` is maintainer-only (enumerated `@`-imports of `.mdc` rules — not expanded at runtime).

**Memory:** `.claude/memory/` in-repo (see `memory-discipline` rule). Session constraints/threads: in a checkout use `.claude/skills/session-state/scripts/session-state.sh`; after global install use `$HOME/.cursor/skills/session-state/scripts/session-state.sh` (or `$HOME/.claude/skills/…` on Claude Code) — never hand-edit `SESSION-STATE.md`. Full chain: [install-paths.md](.claude/skills/findings-ledger/references/install-paths.md).

**Dispatch (orchestrator-only):** Main thread **decomposes, briefs, reviews, integrates** — it does **not** implement. Non-trivial work → `Task` (`engineer`, domain specialists, `explore`). Forbidden on main thread: `Write`/`StrReplace`/`Delete` for implementation (trivial one-line fixes excepted). Skills: route on main thread; **execute via dispatched subagent** briefed with the skill procedure. Full doctrine: `subagent-dispatch` rule (`.cursor/rules/subagent-dispatch.mdc`). **Mechanical enforcement:** [docs/dispatch-enforcement.md](docs/dispatch-enforcement.md) — Cursor dispatch-gate hooks block main-thread research/impl/stop when dispatch is skipped (ship **disabled** by default). **Activation guide:** [cursor-orchestrator-gap.md](docs/cursor-orchestrator-gap.md). **Ship gates:** [gate-dag.md](.claude/references/gate-dag.md) — Wave 1 + conditional Wave 2; PR checkboxes enforced by CI.

**Global stickiness (recommended):** add the **Skills + orchestration** blocks from README § Configure Cursor rules to **Cursor Settings → Rules → User Rules**. Run `session-state.sh init-orchestrator` at session start for per-turn constraint injection.
