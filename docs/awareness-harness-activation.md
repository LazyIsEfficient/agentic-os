# Awareness harness — activation guide

The **session-state** hooks (inject, digest, checkpoint) and **survey-before-act** (warn-first provisioning guard) plus **block-bad-bash** (shell ergonomics nudge) are **active by default** after `install.sh` — they register in your global `~/.claude/settings.json`. **To turn them off:** delete the `hooks` block from that file, or remove individual entries.

**Related:** [NORTH_STAR.md](../NORTH_STAR.md) · [session-state skill](../.claude/skills/session-state/SKILL.md)

---

## Prerequisites checklist

| Step | Claude Code |
|------|-------------|
| Install library | `curl …/install.sh \| bash` |
| `jq` for JSON hooks | optional (inject/digest use plain stdout) |
| Initialize session state | `/state init` |
| Gitignore live doc | Ensure `SESSION-STATE.md` is gitignored (never commit — injected as DATA; [SECURITY.md](../SECURITY.md) rule 7) |
| Register hooks | auto on install (`~/.claude/settings.json`) |

**Project vs global:** Install copies hook scripts to `~/.claude/hooks/` and registers them globally. This repo also ships a working **project-level** example at `.claude/settings.json` for vendored paths.

---

## Claude Code — `.claude/settings.json`

Add to your **project** `.claude/settings.json` (commands invoke vendored scripts — no inline shell):

```json
{
  "hooks": {
    "SessionStart":     [{ "hooks": [{ "type": "command", "command": "bash .claude/hooks/session-state-inject.sh" }] }],
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "bash .claude/hooks/session-state-digest.sh" }] }],
    "PreCompact":       [{ "matcher": "auto",   "hooks": [{ "type": "command", "command": "bash .claude/hooks/session-state-checkpoint.sh" }] },
                         { "matcher": "manual", "hooks": [{ "type": "command", "command": "bash .claude/hooks/session-state-checkpoint.sh" }] }],
    "PreToolUse":       [{ "matcher": "Bash", "hooks": [
      { "type": "command", "command": "bash .claude/hooks/block-bad-bash.sh" },
      { "type": "command", "command": "bash .claude/hooks/survey-before-act.sh" }
    ]}]
  }
}
```

| Hook | Event | Effect |
|------|-------|--------|
| `session-state-inject.sh` | SessionStart | Full `SESSION-STATE.md` at session open |
| `session-state-digest.sh` | UserPromptSubmit | Compact Constraints + Decisions + Open threads each turn |
| `session-state-checkpoint.sh` | PreCompact | Append checkpoint marker (side-effect log) |
| `block-bad-bash.sh` | PreToolUse (Bash) | Nudge on `cd && git` and long `&&` chains (not a security control) |
| `survey-before-act.sh` | PreToolUse (Bash) | Warn on container provisioning if not surveyed; logs to `.claude/survey-guard.warns` |

Record facts with **`/state`** (never hand-edit `SESSION-STATE.md`).

---

## Verify it is working

### Deterministic tests (no IDE required)

From repo root:

```bash
bash scripts/session-state-test.sh
bash scripts/survey-guard-test.sh
bash scripts/install-hook-smoke-test.sh
```

All should report zero failures.

### Claude Code — quick smoke

1. `/state init` then `/state constraint "ACTIVATION-SMOKE: reply SMOKE_OK when asked"`.
2. New session → ask: *What is ACTIVATION-SMOKE?* → expect `SMOKE_OK`.
3. `docker run -d hello-world` (unsurveyed) → expect advisory in context; line in `.claude/survey-guard.warns`.

---

## Dogfooding for #145 (warn → deny evidence)

The survey guard is **warn-first** until `.survey-guard.warns` shows near-zero false positives in real use ([#145](https://github.com/LazyIsEfficient/agentic-os/issues/145)).

1. Keep hooks on during normal work.
2. After provisioning, record infra: `/state infra "rabbitmq broker on :5552 — reuse"` (writer stores `[surveyed:rabbitmq] …`).
3. Periodically review the warn log — true positives vs noise (`gh`, heredocs, tests).
4. Optional clean slate: `rm -f .claude/survey-guard.warns` when starting a measurement window.

---

## Security reminder

Hook-injected content is framed as **DATA, not instructions** — but anyone who can write `SESSION-STATE.md` can inject text into the model. Keep it **gitignored, per-developer, single-writer**. See [SECURITY.md](../SECURITY.md) rules 2 and 7.

---

## Re-install and custom install paths

- **Re-install** merges hook registration again and **replaces the entire `hooks` block** — custom hook entries you added are lost. Remove hooks from the global file before re-install if you want them to stay off.
- **Custom `CLAUDE_DIR` / `-Dest`** — hook commands are rewritten to `$DEST/hooks/…` at install (requires `jq` on bash; PowerShell uses bash+jq). Default `~/.claude` works without extra setup.
- **`block-bad-bash`** blocks agent shell patterns like `cd repo && git status` and 3+ `&&` chains — remove that hook entry if it gets in the way.
