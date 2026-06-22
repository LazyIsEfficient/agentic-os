---
name: session-state
description: Maintain SESSION-STATE.md, the durable within-session memory that survives context compaction. Use when a constraint, settled decision, existing-infrastructure (survey) finding, or open thread must persist across a long session so it is not re-derived or re-litigated. Triggers on /state, "remember this for the session", "record this constraint/decision", or after surveying what already exists. For cross-session/personal memory use .claude/memory/ instead; for repo-derivable facts, do not record at all.
when_to_use: A fact must survive context compaction WITHIN this session — a hard constraint, a settled decision, a survey result (existing infra to reuse), or an open thread/next step. Not for cross-session memory (.claude/memory/) and not for anything derivable from the repo.
---

# Session State

`SESSION-STATE.md` (project root, gitignored; schema in this skill's `assets/SESSION-STATE.template.md`) is the harness's live external memory — NORTH_STAR Lever 3. A model's context compresses over a long session and settled facts drift; this file is the durable copy, re-surfaced by hooks:

- **SessionStart** injects the whole file (turn one of every session).
- **UserPromptSubmit** injects a compact digest — **Constraints + Open threads** — each turn.
- **PreCompact** checkpoints before context is compressed.

## How to record (never hand-edit)

Writing via a script — not by editing the file from memory — is the point: it captures the fact even when attention is full. Resolve the writer project-first, then fall back to the global install:

```
PROJ="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
SS="$PROJ/.claude/skills/session-state/scripts/session-state.sh"
[ -f "$SS" ] || SS="$HOME/.cursor/skills/session-state/scripts/session-state.sh"
[ -f "$SS" ] || SS="$HOME/.claude/skills/session-state/scripts/session-state.sh"
```

| Type | Use for | Re-injected each turn? |
|---|---|---|
| `constraint` | hard rules in force (e.g. "Rust only, no Python") | **yes** |
| `decision` | settled choices, date-stamped (so they're not re-litigated) | no (session start only) |
| `infra` | survey-before-act findings — what already exists, to reuse (lead with a `[subject]` token, e.g. `[rabbitmq]`) | no |
| `thread` | in-flight items / next steps | **yes** |

### Claude Code — `/state` slash command

In Claude Code, use the `/state` command (`.claude/commands/state.md`), which invokes the writer above:

```
bash "$SS" init           # or: show
bash "$SS" constraint "<entry text>"   # constraint | decision | infra | thread
```

Valid types: `constraint`, `decision`, `infra`, `thread`, `init`, `show`. If the type is empty or invalid, list the valid types — do not guess. `init` and `show` take no text; the four entry types take the text as one quoted argument.

### Cursor — skill-triggered workflow (no `/state` command)

Cursor has no `/state` slash command. When this skill is relevant (triggers below, or the user asks to remember something for the session), **read this skill and run the writer via Bash**:

1. Read `$1` as the entry type (`constraint`, `decision`, `infra`, `thread`, `init`, `show`). If empty or invalid, STOP and list the valid types.
2. Remaining args are entry text (required for the four entry types).
3. Run:

```
bash "$SS" init
bash "$SS" show
bash "$SS" constraint "<entry text>"
bash "$SS" decision   "<entry text>"
bash "$SS" infra      "<entry text>"
bash "$SS" thread     "<entry text>"
```

4. Report the single line the script prints (or, for `show`/`init`, the command output).

Keep entries terse. Lead `infra` with a `[subject]` token — e.g. `"[rabbitmq] broker on :5552 (docker-compose) — reuse"` — so survey-before-act guards suppress warnings only when a command names that exact subject.

## When to reach for it (proactively)

- You just established a hard constraint, or the user gave one → record a `constraint`.
- You made or were given a settled decision → record a `decision`.
- You surveyed and found existing infrastructure (a running service, an existing config) → record `infra`, so a later step reuses it instead of rebuilding.
- You are leaving a thread unfinished → record a `thread`.

## Activation (opt-in — hooks ship dormant)

The writer works as soon as the skill is installed (Claude: `/state`; Cursor: skill-triggered Bash above). The **hooks that auto-surface the file ship dormant** — scripts land on disk but nothing registers them until you opt in.

### Claude Code

Add this to your project `.claude/settings.json` (commands invoke vendored scripts — no inline shell):

```json
{
  "hooks": {
    "SessionStart":     [{ "hooks": [{ "type": "command", "command": "bash .claude/hooks/session-state-inject.sh" }] }],
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "bash .claude/hooks/session-state-digest.sh" }] }],
    "PreCompact":       [{ "matcher": "auto",   "hooks": [{ "type": "command", "command": "bash .claude/hooks/session-state-checkpoint.sh" }] },
                         { "matcher": "manual", "hooks": [{ "type": "command", "command": "bash .claude/hooks/session-state-checkpoint.sh" }] }]
  }
}
```

### Cursor — project hooks (opt-in)

Production hooks live under `.cursor/hooks/` in a project checkout (JSON stdout; requires `jq` at runtime). Copy or merge this into your project `.cursor/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [{ "command": ".cursor/hooks/session-state-inject.sh" }],
    "beforeSubmitPrompt": [{ "command": ".cursor/hooks/session-state-digest.sh" }],
    "preCompact": [{ "command": ".cursor/hooks/session-state-checkpoint.sh" }],
    "beforeShellExecution": [{ "command": ".cursor/hooks/survey-before-act.sh" }]
  }
}
```

**Live-proven:** `sessionStart` injection (Spike A GO, Cursor `3.8.11`, 2026-06-22). Per-turn digest via `beforeSubmitPrompt` is wired but live surfacing is not yet confirmed — see [cursor hook capability spike](https://github.com/LazyIsEfficient/agentic-os/blob/main/eval/spikes/cursor-hook-capability.md).

Global `install-cursor.sh` still copies shared `.claude/hooks/` scripts dormant to `~/.cursor/hooks/`; use the project `.cursor/hooks/` scripts above for Cursor-native JSON hooks.

**Security (untrusted data).** `SESSION-STATE.md` is injected into the model's context every session/turn with no tool call — whoever can write it controls injected text. So keep it **gitignored and per-developer** (never commit it, never use it in a shared/multi-writer checkout); the inject hook frames the block as DATA, not instructions. See `SECURITY.md` rule 7.

## Discipline

Keep entries terse — Constraints and Open threads are re-injected every turn, so bloat re-creates the token tax. Prune stale lines. Do not duplicate `.claude/memory/` (cross-session) or facts derivable from the repo.
