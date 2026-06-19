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

Use the `/state` command, which calls the deterministic writer in this skill's `scripts/session-state.sh`. Writing via a script — not by editing the file from memory — is the point: it captures the fact even when attention is full.

| Type | Use for | Re-injected each turn? |
|---|---|---|
| `constraint` | hard rules in force (e.g. "Rust only, no Python") | **yes** |
| `decision` | settled choices, date-stamped (so they're not re-litigated) | no (session start only) |
| `infra` | survey-before-act findings — what already exists, to reuse | no |
| `thread` | in-flight items / next steps | **yes** |

## When to reach for it (proactively, not only on /state)

- You just established a hard constraint, or the user gave one → `/state constraint`.
- You made or were given a settled decision → `/state decision`.
- You surveyed and found existing infrastructure (a running service, an existing config) → `/state infra`, so a later step reuses it instead of rebuilding.
- You are leaving a thread unfinished → `/state thread`.

## Activation (opt-in — hooks ship dormant)

The `/state` command and writer work as soon as the skill is installed. The **hooks that auto-surface the file ship dormant** — the scripts land in `.claude/hooks/` but nothing registers them, so they never run until you opt in. To activate, add this to your project `.claude/settings.json` (the commands invoke the vendored scripts — no inline shell):

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

**Security (untrusted data).** `SESSION-STATE.md` is injected into the model's context every session/turn with no tool call — whoever can write it controls injected text. So keep it **gitignored and per-developer** (never commit it, never use it in a shared/multi-writer checkout); the inject hook frames the block as DATA, not instructions. See `SECURITY.md` rule 7.

## Discipline

Keep entries terse — Constraints and Open threads are re-injected every turn, so bloat re-creates the token tax. Prune stale lines. Do not duplicate `.claude/memory/` (cross-session) or facts derivable from the repo.
