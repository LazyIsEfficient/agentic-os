# Cursor hook capability spike (T-cursor-spike)

**Status:** DONE — GO/NO-GO gate for Lane 2 hook port. **Env:** Cursor `3.8.11` (CLI + app), macOS darwin 25.3.0, branch `lane-cursor/cursor-spike`.
**Roadmap:** [V2_DISPATCH.md](../../V2_DISPATCH.md) `T-cursor-spike` / [#152](https://github.com/LazyIsEfficient/agentic-os/issues/152). **Harness:** `eval/spikes/cursor-hook-capability/` + throwaway `.cursor/hooks/*-probe.sh`.

## Verdict: **NO-GO** (narrow v1 scope)

| Spike | Capability | Script contract | Live model surfacing | Gate |
|---|---|---|---|---|
| **A** | `sessionStart` → inject `SESSION-STATE.md` | **PROVEN** (unit + stdout sample) | **NOT PROVEN** (requires new Agent chat; known Cursor injection bugs) | **FAILS gate** |
| **B** | `beforeShellExecution` → warn-and-allow on unsurveyed `docker run` | **PROVEN** (unit + stdout sample) | **NOT PROVEN** (subagent Bash did not fire hook; agent_message surfacing unconfirmed) | Partial — insufficient for GO |

**checkpoint:cursor-go:** **NO-GO.** Do not dispatch full `T-cursor-hooks` / hook-dependent metrics until Spike A live-fire passes in a fresh Agent chat.

**Recommended v1 scope (NO-GO path):** ship `T-cursor-install`, `T-cursor-rules`, `T-cursor-docs` (shared skills/agents + `/state` writer + rules). Ship hook **scripts dormant** (no activation doc). Defer `T-cursor-hooks`, hook parity in `T-cursor-security`, and hook-dependent `T-cursor-metrics`.

### Blockers

1. **Spike A is the explicit gate** (`GO = sessionStart inject proven`). We proved the probe emits valid Cursor JSON with file content + sentinel, but **did not prove the agent reads `additional_context`** in a new session.
2. **No headless runner** — unlike Claude S0 (`claude -p … --include-hook-events`), Cursor has no documented CLI path to regression-test hook→model injection without an interactive Agent chat.
3. **Reported platform gaps** — Cursor forum threads document `sessionStart` hooks executing and returning valid `additional_context` JSON while the model never sees it ([#158452](https://forum.cursor.com/t/sessionstart-hook-additional-context-is-never-injected-into-agents-initial-system-context/158452)); Claude `additionalContext` (camelCase) vs Cursor `additional_context` (snake_case) mismatch ([#153739](https://forum.cursor.com/t/gaps-in-claude-code-sessionstart-support/153739)). Cursor `3.8.11` may have partial fixes, but this spike did not live-confirm.
4. **Spike B live-fire** — `docker run --help` from the engineer subagent shell did **not** append `.cursor/survey-guard.warns` (hook not invoked on that execution path). Interactive Agent shell verification still required.

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
6. Optional: Hooks output channel shows hook executed; compare with agent reply.

**This spike session:** not run — subagent started before probes landed; `sessionStart` cannot retroactively fire.

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
| `SessionStart` | plain stdout **or** `hookSpecificOutput.additionalContext` | `sessionStart` | `additional_context`, `env` | **script ✓**, **live ✗** |
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
| SessionStart inject | **Live proven** (sentinel in stream) | Script only; **live not proven** |
| Shell advisory | PreToolUse deny tested live | beforeShellExecution allow+agent_message script only |
| Gate outcome | **GO** (all capabilities confirmed) | **NO-GO** (gate capability unproven live) |

**Next step to reach GO:** one human runs Spike A live-fire repro in Cursor `3.8.11`; if sentinel appears in the first agent reply, update this doc to **GO** and unblock `T-cursor-hooks`.
