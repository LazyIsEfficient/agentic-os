# Hook registration — Claude Code and Cursor

The writer works as soon as the skill is installed. **Hooks are active after `install.sh` / `install-cursor.sh`** — they register globally in `~/.claude/settings.json` or `~/.cursor/hooks.json`. To disable, remove the `hooks` block from that file.

**Full guide:** [docs/awareness-harness-activation.md](../../../../docs/awareness-harness-activation.md) (verify steps, dogfooding for #145).

## Claude Code — project `.claude/settings.json`

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

## Cursor — project `.cursor/hooks.json` (this repo)

This checkout ships a **project-level** `.cursor/hooks.json` (vendored `.cursor/hooks/` paths). Global install uses `~/.cursor/hooks.json` with `hooks/` paths instead.

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

**Live-proven (historical):** `sessionStart` injection confirmed on Cursor `3.8.11` (2026-06-22). **Acceptance gate today:** automated CI scripts only — see [LIVE-FIRE-PROTOCOL.md](https://github.com/LazyIsEfficient/agentic-os/blob/main/eval/spikes/cursor-hook-capability/LIVE-FIRE-PROTOCOL.md).

Global `install-cursor.sh` copies production `.cursor/hooks/` scripts (excluding spike `*-probe.sh`) to `~/.cursor/hooks/` — same JSON contract as project hooks above.

**Security (untrusted data).** `SESSION-STATE.md` is injected into the model's context every session/turn with no tool call — whoever can write it controls injected text. Keep it **gitignored and per-developer** (never commit it, never use it in a shared/multi-writer checkout); the inject hook frames the block as DATA, not instructions. See `SECURITY.md` rule 7.
