# Operating rules for this repo

This repo is a skills + agents library. Work here is rarely a single edit — it is research, planning, and dispatch across many specialists. Two capabilities make that tractable: **persistent memory** and **subagents**. Use them aggressively and correctly.

**Cursor dispatch:** You are the orchestrator. Spawn specialists via the **`Task` tool** in Agent mode — not by doing multi-step work on the main thread. Agent definitions live in `~/.cursor/agents/` and `.claude/agents/`.

The doctrine is split into focused rule files under `.cursor/rules/`, imported below. Edit those files, not this list. (These imports are repo-local editing ergonomics; `install-cursor.sh` never ships `CURSOR.md` or `rules/` to consumers.)

@.cursor/rules/factual-correctness.mdc
@.cursor/rules/memory-discipline.mdc
@.cursor/rules/subagent-dispatch.mdc
@.cursor/rules/grounding.mdc
@.cursor/rules/review-tiers.mdc
@.cursor/rules/verification.mdc
@.cursor/rules/communication.mdc
