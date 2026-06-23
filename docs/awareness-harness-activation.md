# Awareness harness — activation guide

Turn on the **session-state** hooks (inject, digest, checkpoint) and **survey-before-act** (warn-first provisioning guard). Hook scripts install via `install.sh` / `install-cursor.sh` but stay **dormant** until you register them — see [SECURITY.md](../SECURITY.md) § Shipping the awareness harness.

**Related:** [NORTH_STAR.md](../NORTH_STAR.md) · [V2_ROADMAP.md](../V2_ROADMAP.md) · [session-state skill](../.claude/skills/session-state/SKILL.md)

---

## Prerequisites checklist

| Step | Claude Code | Cursor |
|------|-------------|--------|
| Install library | `curl …/install.sh \| bash` | `curl …/install-cursor.sh \| bash` |
| `jq` for JSON hooks | optional (inject/digest use plain stdout) | **required** for `sessionStart` / `beforeSubmitPrompt` |
| Initialize session state | `/state init` | `bash .claude/skills/session-state/scripts/session-state.sh init` (or global copy under `~/.cursor/skills/…`) |
| Gitignore live doc | Ensure `SESSION-STATE.md` is gitignored (never commit — injected as DATA; [SECURITY.md](../SECURITY.md) rule 7) | same |
| Register hooks | project `.claude/settings.json` | project `.cursor/hooks.json` |

**Project vs global:** Install copies hook scripts to `~/.claude/hooks/` or `~/.cursor/hooks/`. The snippets below use **project-relative** paths (`.claude/hooks/…`, `.cursor/hooks/…`) in a repo checkout — recommended so paths stay vendored. Global copies use the same script names under `$HOME`.

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
    "PreToolUse":       [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "bash .claude/hooks/survey-before-act.sh" }] }]
  }
}
```

| Hook | Event | Effect |
|------|-------|--------|
| `session-state-inject.sh` | SessionStart | Full `SESSION-STATE.md` at session open |
| `session-state-digest.sh` | UserPromptSubmit | Compact Constraints + Decisions + Open threads each turn |
| `session-state-checkpoint.sh` | PreCompact | Append checkpoint marker (side-effect log) |
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
    "beforeShellExecution": [{ "command": ".cursor/hooks/survey-before-act.sh" }]
  }
}
```

| Hook | Event | Effect |
|------|-------|--------|
| `session-state-inject.sh` | sessionStart | Full doc via `additional_context` (**live-proven** Cursor 3.8.11) |
| `session-state-digest.sh` | beforeSubmitPrompt | Per-turn digest — **live surfacing not confirmed** (see live-fire) |
| `session-state-checkpoint.sh` | preCompact | Checkpoint log under `.cursor/session-state.checkpoints` |
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

## What we deliberately do not ship active

No consumer gets auto-registered hooks from the tarball alone. Opt-in registration stays a **project-level** choice until a separate security-gated step ships active `settings.json` / `hooks.json` on install.
