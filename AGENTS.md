# Agent instructions — Cursor

This repo is a skills + agents library. Work here is rarely a single edit — it is research, planning, and dispatch across many specialists. Two capabilities make that tractable: **persistent memory** and **subagents**. Use them aggressively and correctly.

**Memory (Cursor):** `.claude/memory/` in-repo (see `memory-discipline` rule). Session constraints/threads: `session-state` skill + writer — not hand-edited `SESSION-STATE.md`.

**Other doctrine** (grounding, verification, review tiers, communication): `.cursor/rules/*.mdc` (`alwaysApply: true`). Maintainer index: `CURSOR.md`.

## Subagents — mandatory operating mode

You are the **orchestrator**. Subagents do the work. You decompose, brief, review, and integrate. The main thread is for orchestration, not implementation.

- **Spawn with `Task`** in Agent mode (`subagent_type` = agent name). Built-ins include `explore`, `generalPurpose`, `best-of-n-runner`; custom agents live in `~/.cursor/agents/` and `.claude/agents/` — match each agent's `description` frontmatter.
- **If `CLAUDE.md` mentions the `Agent` tool:** ignore — in Cursor use **`Task`** with `subagent_type`.
- **Vague request:** read a shaper skill (`prompt-shaper`, `marketing-shaper`, or `game-design-shaper`) → `planning-and-task-breakdown` → parallel `Task` fan-out.
- **Implementation:** dispatch `engineer` or a domain specialist (`rust-engineer`, `web3-engineer`, …) — not main-thread multi-file edits.
- **Before reporting done:** `code-reviewer` (`readonly: true`) always; `security-reviewer` in parallel if auth/secrets/crypto/CI; `library-reviewer` if `.claude/skills/` or `.claude/agents/` changed.
- **Research:** more than 2–3 file reads/greps → `explore` (or `generalPurpose`), not the main thread.
- **Parallel:** independent tasks in one message with multiple `Task` calls. Sequential dispatch when work is parallelizable is a bug.
- **Overlapping file writes:** `subagent_type: "best-of-n-runner"`. Cap concurrent waves at ~3–5 agents.
