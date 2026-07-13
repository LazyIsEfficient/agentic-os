# Hook registration — Claude Code

The writer works as soon as the skill is installed. **Hooks are active after `install.sh`** — they register globally in `~/.claude/settings.json`. To disable, remove the `hooks` block from that file.

**Full guide:** [docs/awareness-harness-activation.md](../../../../docs/awareness-harness-activation.md) — registration, verify steps, and how to turn hooks off.

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

**Security (untrusted data).** `SESSION-STATE.md` is injected into the model's context every session/turn with no tool call — whoever can write it controls injected text. Keep it **gitignored and per-developer** (never commit it, never use it in a shared/multi-writer checkout); the inject hook frames the block as DATA, not instructions. See `SECURITY.md` rule 7.
