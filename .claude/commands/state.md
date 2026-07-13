---
description: Record a durable session fact (constraint/decision/infra/thread) to SESSION-STATE.md via the deterministic writer so it survives compaction
argument-hint: <constraint|decision|infra|thread|init|init-orchestrator|show> <text>
allowed-tools: Bash
---

The user invoked `/state $ARGUMENTS`.

`SESSION-STATE.md` is the live external-memory doc; hooks re-inject it each session and digest it each turn, so anything recorded here survives context compaction. Write to it **only** through the deterministic helper — never hand-edit the file.

**Hooks are on by default** after install. To turn off, edit `~/.claude/settings.json` or project `.claude/settings.json`.

1. Read `$1` as the entry type. Valid types: `constraint`, `decision`, `infra`, `thread`, `init`, `init-orchestrator`, `show`. If `$1` is empty or not one of these, STOP and list the valid types — do not guess.
2. The remaining arguments (`$2` onward) are the entry text (required for constraint/decision/infra/thread).
3. Run the writer. Resolve its path project-first, then fall back to the global install (the skill ships to `~/.claude/` on a global install). `init`, `init-orchestrator`, and `show` take **no** text; the four entry types take the text as one quoted argument:
   ```
   SS="${CLAUDE_PROJECT_DIR:-.}/.claude/skills/session-state/scripts/session-state.sh"
   [ -f "$SS" ] || SS="$HOME/.claude/skills/session-state/scripts/session-state.sh"
   bash "$SS" init           # or: init-orchestrator | show
   bash "$SS" "$1" "<entry text>"   # constraint | decision | infra | thread
   ```
4. Report the single line that was added (or, for `show`/`init`/`init-orchestrator`, the command's output).

Keep entries terse. **Constraints** and **Open threads** are re-injected every turn, so reserve them for high-value, time-sensitive facts. Use **Decisions** for settled choices (the writer stamps the date) and **Existing infrastructure** for survey-before-act findings (what already exists, so it is reused not rebuilt). For `infra`, put the service name first — e.g. `/state infra "rabbitmq broker on :5552 (docker-compose) — reuse"` — the writer stores `[surveyed:rabbitmq] …` so the guard suppresses only when a command names that surveyed subject.
