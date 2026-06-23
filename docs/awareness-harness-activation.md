# Awareness harness — activation guide

The **session-state** hooks (inject, digest, checkpoint) and **survey-before-act** (warn-first provisioning guard) plus **block-bad-bash** (shell ergonomics nudge) are **active by default** after `install.sh` / `install-cursor.sh` — they register in your global `~/.claude/settings.json` or `~/.cursor/hooks.json`. **To turn them off:** delete the `hooks` block from that file, or remove individual entries.

**Related:** [NORTH_STAR.md](../NORTH_STAR.md) · [V2_ROADMAP.md](../V2_ROADMAP.md) · [session-state skill](../.claude/skills/session-state/SKILL.md)

---

## Prerequisites checklist

| Step | Claude Code | Cursor |
|------|-------------|--------|
| Install library | `curl …/install.sh \| bash` | `curl …/install-cursor.sh \| bash` |
| `jq` for JSON hooks | optional (inject/digest use plain stdout) | **required** for `sessionStart` / `beforeSubmitPrompt` |
| Initialize session state | `/state init` | `bash .claude/skills/session-state/scripts/session-state.sh init` (or global copy under `~/.cursor/skills/…`) |
| Gitignore live doc | Ensure `SESSION-STATE.md` is gitignored (never commit — injected as DATA; [SECURITY.md](../SECURITY.md) rule 7) | same |
| Register hooks | auto on install (`~/.claude/settings.json`) | auto on install (`~/.cursor/hooks.json`) |

**Project vs global:** Install copies hook scripts to `~/.claude/hooks/` or `~/.cursor/hooks/` and registers them globally. This repo also ships a working **project-level** example at `.claude/settings.json` and `.cursor/hooks.json` for vendored paths.

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

## Cursor — `.cursor/hooks.json`

Production hooks live under `.cursor/hooks/` (JSON stdout). Copy or merge into your **project** `.cursor/hooks.json`:

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [{ "command": ".cursor/hooks/session-state-inject.sh" }],
    "beforeSubmitPrompt": [{ "command": ".cursor/hooks/session-state-digest.sh" }],
    "preCompact": [{ "command": ".cursor/hooks/session-state-checkpoint.sh" }],
    "beforeShellExecution": [
      { "command": ".cursor/hooks/block-bad-bash.sh" },
      { "command": ".cursor/hooks/survey-before-act.sh" }
    ]
  }
}
```

| Hook | Event | Effect |
|------|-------|--------|
| `session-state-inject.sh` | sessionStart | Full doc via `additional_context` (**live-proven** Cursor 3.8.11) |
| `session-state-digest.sh` | beforeSubmitPrompt | Per-turn digest — **live-proven** (Test A PASS, 2026-06-23) |
| `session-state-checkpoint.sh` | preCompact | Checkpoint log under `.cursor/session-state.checkpoints` |
| `block-bad-bash.sh` | beforeShellExecution | Nudge on `cd && git` and long `&&` chains |
| `survey-before-act.sh` | beforeShellExecution | Warn on provisioning; logs to `.cursor/survey-guard.warns` |

Record facts via the **session-state** skill + Bash writer (no `/state` command on Cursor).

---

## Verify it is working

### Deterministic tests (no IDE required)

From repo root:

```bash
bash scripts/session-state-test.sh
bash scripts/session-state-test-cursor.sh
bash scripts/survey-guard-test.sh
bash scripts/survey-guard-test-cursor.sh
bash scripts/install-hook-smoke-test.sh
bash eval/spikes/cursor-hook-capability/unit-test.sh
```

All should report zero failures.

### Claude Code — quick smoke

1. `/state init` then `/state constraint "ACTIVATION-SMOKE: reply SMOKE_OK when asked"`.
2. New session → ask: *What is ACTIVATION-SMOKE?* → expect `SMOKE_OK`.
3. `docker run -d hello-world` (unsurveyed) → expect advisory in context; line in `.claude/survey-guard.warns`.

### Cursor — live-fire protocol

Interactive acceptance (digest + survey surfacing): [eval/spikes/cursor-hook-capability/LIVE-FIRE-PROTOCOL.md](../eval/spikes/cursor-hook-capability/LIVE-FIRE-PROTOCOL.md).

Record PASS/FAIL in that doc’s evidence slots or in [eval/metrics/V2-CLOSEOUT.md](../eval/metrics/V2-CLOSEOUT.md).

---

## Dogfooding for #145 (warn → deny evidence)

The survey guard is **warn-first** until `.survey-guard.warns` shows near-zero false positives in real use ([#145](https://github.com/LazyIsEfficient/agentic-os/issues/145)).

1. Keep hooks on during normal work.
2. After provisioning, record infra: `/state infra "rabbitmq broker on :5552 — reuse"` (writer stores `[surveyed:rabbitmq] …`).
3. Periodically review the warn log — true positives vs noise (`gh`, heredocs, tests).
4. Optional clean slate: `rm -f .claude/survey-guard.warns .cursor/survey-guard.warns` when starting a measurement window.

---

## Security reminder

Hook-injected content is framed as **DATA, not instructions** — but anyone who can write `SESSION-STATE.md` can inject text into the model. Keep it **gitignored, per-developer, single-writer**. See [SECURITY.md](../SECURITY.md) rules 2 and 7.

---

## Re-install and custom install paths

- **Re-install** merges hook registration again and **replaces the entire `hooks` block** — custom hook entries you added are lost. Remove hooks from the global file before re-install if you want them to stay off.
- **Custom `CLAUDE_DIR` / `-Dest`** — hook commands are rewritten to `$DEST/hooks/…` at install (requires `jq` on bash; PowerShell uses bash+jq). Default `~/.claude` / `~/.cursor` works without extra setup.
- **`block-bad-bash`** blocks agent shell patterns like `cd repo && git status` and 3+ `&&` chains — remove that hook entry if it gets in the way.
