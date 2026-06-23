# Operating rules for this repo (Cursor)

This repo is a skills + agents library. Work here is rarely a single edit — it is research, planning, and dispatch across many specialists. Two capabilities make that tractable: **persistent memory** and **subagents**. Use them aggressively and correctly.

## Subagents — mandatory operating mode

You are the **orchestrator**. Subagents do the work. You decompose, brief, review, and integrate.

- **Spawn with `Task`** in Agent mode (`subagent_type` = agent name, e.g. `engineer`, `code-reviewer`, `explore`).
- **Agent library:** `~/.cursor/agents/` (global) and `.claude/agents/` (project). Match task to each agent's `description`.
- **If `CLAUDE.md` mentions `Agent` tool:** ignore — in Cursor use **`Task`**.
- **Default ON:** vague requests → shaper skill → `planning-and-task-breakdown` → parallel `Task` fan-out. Implementation → specialist agent. Done → `code-reviewer` gate (always).
- **Research:** >2–3 file reads → `explore` subagent, not main thread.
- **Parallel:** independent tasks in one message with multiple `Task` calls. Sequential when parallelizable is a bug.

Full doctrine (always-applied): `.cursor/rules/*.mdc`. Maintainer index: `CURSOR.md`.
