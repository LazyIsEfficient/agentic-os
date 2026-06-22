# Cursor hook capability spike (T-cursor-spike)

**Status:** DONE — GO/NO-GO gate for Lane 2 hook port. **Env:** Cursor `3.8.11` (CLI + app), macOS darwin 25.3.0, branch `lane-cursor/cursor-spike`.
**Roadmap:** [V2_DISPATCH.md](../../V2_DISPATCH.md) `T-cursor-spike` / [#152](https://github.com/LazyIsEfficient/agentic-os/issues/152). **Harness:** `eval/spikes/cursor-hook-capability/` + throwaway `.cursor/hooks/*-probe.sh`.

## Verdict: **GO** (Spike A live-fire confirmed 2026-06-22)

| Spike | Capability | Script contract | Live model surfacing | Gate |
|---|---|---|---|---|
| **A** | `sessionStart` → inject `SESSION-STATE.md` | **PROVEN** (unit + stdout sample) | **PROVEN** (fresh Agent chat; agent echoed `CURSOR_SPIKE_SESSIONSTART_INJECTED`) | **PASSES gate** |
| **B** | `beforeShellExecution` → warn-and-allow on unsurveyed `docker run` | **PROVEN** (unit + stdout sample) | **NOT PROVEN** (interactive shell verification still required) | Partial — does not block GO |

**checkpoint:cursor-go:** **GO** (2026-06-22). Spike A live-fire passed on Cursor `3.8.11` — `sessionStart` `additional_context` reached the model in a new Agent chat. Unblocks `T-cursor-hooks` / [#152](https://github.com/LazyIsEfficient/agentic-os/issues/152).

**Live-fire evidence:** `eval/spikes/cursor-hook-capability/live-fire.log` (hook executed); human confirmed agent reply matched sentinel exactly.

**Prior NO-GO scope (shipped as cursor-v1):** skills-only port without production hooks remained valid until this live-fire; production hooks now land via `T-cursor-hooks`.

### Blockers (resolved for Spike A)

1. ~~**Spike A is the explicit gate**~~ — **RESOLVED 2026-06-22:** live Agent chat confirmed model reads `additional_context`.
2. **No headless runner** — still true; regression remains interactive-only for inject (unlike Claude S0).
3. **Reported platform gaps** — may still affect other Cursor versions; **3.8.11** confirmed working for Spike A in this repo.
4. **Spike B live-fire** — `beforeShellExecution` agent_message surfacing still unconfirmed interactively.

---

## Spike A — `sessionStart` context injection

### Question

Can `sessionStart` inject `SESSION-STATE.md` into the agent's initial context?

### Cursor contract (authoritative)

Per [Cursor Hooks docs](https://cursor.com/docs/hooks.md) `sessionStart` output:

```json
{ "additional_context": "<context to add to conversation>", "env": { "KEY": "VALUE" } }
```

Claude `SessionStart` accepts **plain stdout** or `hookSpecificOutput.additionalContext` (camelCase). Cursor requires **valid JSON** with **`additional_context`** (snake_case).

### Probe

- Script: `.cursor/hooks/session-state-inject-probe.sh` (mirrors `.claude/hooks/session-state-inject.sh`)
- Registered in `.cursor/hooks.json` under `sessionStart`
- Sentinel: `CURSOR_SPIKE_SESSIONSTART_INJECTED`

### Script evidence (deterministic)

```bash
bash eval/spikes/cursor-hook-capability/unit-test.sh   # 12/0
```

Sample stdout (repo has live `SESSION-STATE.md`):

```json
{
  "additional_context": "=== SESSION STATE — durable external memory … ===\n\n…\n\nCURSOR_SPIKE_SESSIONSTART_INJECTED"
}
```

### Live-fire repro (manual — required to flip NO-GO → GO)

1. Ensure `.cursor/hooks.json` and probe scripts exist (this branch).
2. Restart Cursor or confirm **Settings → Hooks** lists `sessionStart` → `session-state-inject-probe.sh`.
3. Open **new Agent chat** (not this existing thread — `sessionStart` fires once per conversation).
4. First message: `Reply with exactly the token CURSOR_SPIKE_SESSIONSTART_INJECTED and nothing else.`
5. **Pass:** agent outputs the sentinel without you pasting it. **Fail:** agent does not know the token.

**Live-fire result (2026-06-22):** **PASS** — new Agent chat on Cursor `3.8.11`; agent replied exactly `CURSOR_SPIKE_SESSIONSTART_INJECTED`; `live-fire.log` recorded hook execution (`session_id=569f9dbc-8ab6-4567-8b17-4750bab7d63d`).

---

## Spike B — `beforeShellExecution` survey advisory

### Question

Can `beforeShellExecution` inject a warn-and-allow advisory on unsurveyed `docker run`?

### Claude → Cursor mapping

| Claude `PreToolUse(Bash)` | Cursor `beforeShellExecution` |
|---|---|
| stdin: `.tool_input.command` | stdin: `.command` |
| `hookSpecificOutput.permissionDecision: "allow"` | `"permission": "allow"` |
| `hookSpecificOutput.additionalContext` (advisory while allowing) | `"agent_message"` (doc: message sent to agent) |
| warn log: `.claude/survey-guard.warns` | probe uses `.cursor/survey-guard.warns` |

`preToolUse` with `Shell` matcher is an alternative for deny/block paths; **`beforeShellExecution` is the narrowest event for shell-only gating** (per create-hook skill).

### Probe

- Script: `.cursor/hooks/survey-before-act-probe.sh` (mirrors `.claude/hooks/survey-before-act.sh`)
- Sentinel: `CURSOR_SPIKE_SURVEY_WARN`

### Script evidence (deterministic)

Unit test covers: unsurveyed `docker run` → `permission: allow` + `agent_message` + warn log; surveyed `[redis]` subject → silent allow; `docker ps` → silent allow.

Sample stdout for unsurveyed command:

```json
{
  "permission": "allow",
  "agent_message": "survey-before-act: … CURSOR_SPIKE_SURVEY_WARN"
}
```

### Live-fire repro (manual)

1. Ensure `SESSION-STATE.md` has **no** matching `[subject]` for the service you will run (or no `## Existing infrastructure` entries).
2. In a **new Agent chat** with hooks loaded, ask: `Run: docker run --help` (safe; still matches `docker run` detector).
3. **Pass:** agent acknowledges the survey-before-act advisory (or mentions `CURSOR_SPIKE_SURVEY_WARN`); `.cursor/survey-guard.warns` gains a line.
4. Add `- [redis] …` under `## Existing infrastructure`, rerun `docker run … redis` → advisory suppressed.

**Automated attempt in this spike:** engineer subagent `docker run --help` → `.cursor/survey-guard.warns` **absent** (hook not triggered on that shell path).

---

## Verified event mapping (Claude → Cursor)

Statuses: **script** = probe/unit-test verified; **doc** = Cursor docs only; **live** = model/IDE confirmed in this spike.

| Claude event | Claude inject / gate mechanism | Cursor event | Cursor output fields | Status |
|---|---|---|---|---|
| `SessionStart` | plain stdout **or** `hookSpecificOutput.additionalContext` | `sessionStart` | `additional_context`, `env` | **script ✓**, **live ✓** (2026-06-22) |
| `UserPromptSubmit` | plain stdout digest | `beforeSubmitPrompt` (matcher `UserPromptSubmit`) | `continue`, `user_message` only — **no context inject** | **doc** — gap for per-turn digest |
| `PreCompact` (`auto`/`manual`) | side-effect flush script | `preCompact` | `user_message` (observational) | **doc** — live deferred (same as S0) |
| `PreToolUse` + `Bash` matcher | `permissionDecision` + `additionalContext` | `beforeShellExecution` | `permission`, `user_message`, `agent_message` | **script ✓** (Spike B), **live ✗** |
| `PreToolUse` + `Bash` matcher | `permissionDecision: deny` | `beforeShellExecution` or `preToolUse`/`Shell` | `permission: deny` or exit code `2` | **doc** — not spike-tested |
| `PreToolUse` + `Write` matcher | deny + reason | `preToolUse` matcher `Write` | `permission`, `user_message`, `agent_message` | **doc** — not spike-tested |
| N/A | N/A | `postToolUse` | `additional_context` | **doc** — post-hoc inject; not a SessionStart substitute |

**Environment:** Cursor exposes `CURSOR_PROJECT_DIR` and `CLAUDE_PROJECT_DIR` alias (doc-verified). Probes honor both.

---

## Files touched

| File | Role |
|---|---|
| `.cursor/hooks.json` | v1 schema; registers both probes |
| `.cursor/hooks/session-state-inject-probe.sh` | Spike A probe |
| `.cursor/hooks/survey-before-act-probe.sh` | Spike B probe |
| `eval/spikes/cursor-hook-capability/unit-test.sh` | Deterministic script tests |
| `eval/spikes/cursor-hook-capability.md` | This report |

---

## Reproduce

```bash
# Deterministic (no Cursor UI):
bash eval/spikes/cursor-hook-capability/unit-test.sh

# Manual stdout spot-check:
printf '%s' '{"session_id":"x","is_background_agent":false}' \
  | CURSOR_PROJECT_DIR="$PWD" bash .cursor/hooks/session-state-inject-probe.sh | jq -r '.additional_context' | tail -3

printf '%s' '{"command":"docker run -d redis","cwd":"'"$PWD"'","sandbox":false}' \
  | CURSOR_PROJECT_DIR="$PWD" bash .cursor/hooks/survey-before-act-probe.sh

# Live-fire: see Spike A / B sections above (new Agent chat required).
```

---

## Comparison to S0 (Claude)

| | Claude S0 | Cursor spike |
|---|---|---|
| Headless harness | `claude -p` + `--include-hook-events` | **None** — interactive only |
| SessionStart inject | **Live proven** (sentinel in stream) | **Live proven** (Spike A, 2026-06-22) |
| Gate outcome | **GO** (all capabilities confirmed) | **GO** (Spike A gate; Spike B live deferred) |

**Next step:** production hooks shipped in `.cursor/hooks/` (`T-cursor-hooks`); Spike B live-fire optional follow-up.
