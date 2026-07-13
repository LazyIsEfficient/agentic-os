# S0 — Hook capability spike (result)

**Status:** DONE — de-risks Slice 1. **Env:** Claude Code `2.1.168`, macOS (darwin 25.3.0).
**Roadmap:** Slice 0. **Harness:** `eval/spikes/s0-hook-capability/` (reproducible, throwaway).

## Verdict — all three needed capabilities are confirmed

| Capability | Needed by | Status | Evidence |
|---|---|---|---|
| `SessionStart` → inject context | SESSION-STATE.md re-surfacing | **PROVEN (live)** | sentinel `S0_SENTINEL_SESSIONSTART_INJECTED` appeared in the headless event stream |
| `PreToolUse` → deny + reason | survey-before-act guard | **PROVEN (live)** | Write was **blocked** (`demo.txt` never created) and `S0_SENTINEL_PRETOOLUSE_DENIED_WRITE` carried the reason |
| `PreCompact` exists, fires on auto + manual | flush state at the compaction boundary | **CONFIRMED (authoritative doc) + script unit-tested**; live-fire deferred | see "PreCompact" below |

No fallback is required — the design rests on capabilities that exist.

## The disputed fact, resolved

The `claude-code-guide` agent reported **`PreCompact` does NOT exist** and listed only 7 hook events. That was **wrong**. The official hooks reference documents **32 events**, including **`PreCompact` and `PostCompact`**, both with a `matcher` of `manual`|`auto`, firing on both auto-compaction and manual `/compact`. The earlier prior was correct. Lesson: a single agent's "not supported" is a Tier-2 claim — it needed the authoritative source, which is why S0 exists.

Verbatim contracts (from the doc, used by the harness):
- Inject: `hookSpecificOutput.additionalContext` (under `SessionStart` / `UserPromptSubmit`).
- Deny: `hookSpecificOutput.permissionDecision: "deny"` + `permissionDecisionReason` (values: `allow`/`deny`/`ask`/`defer`).

## Bonus findings (useful for later slices)

- **Test harness for hooks:** `claude -p "<prompt>" --output-format stream-json --verbose --include-hook-events --dangerously-skip-permissions --settings <file>` runs hooks headlessly and streams which events fired — this is how we'll regression-test Slice 1/2 hooks without a live interactive session.
- `--settings <file>` loads a hooks config without tripping the workspace-trust dialog; `--dangerously-skip-permissions` bypasses the *permission* prompts but the **`PreToolUse` hook still fires and is respected** (deny beat skip-permissions).
- `--bare` skips hooks entirely (useful for an A/B "hooks-off" arm in the eval harness, Slice 4).
- `PostCompact` also exists — Slice 1 could checkpoint *after* compaction as well as before.

## PreCompact — why live-fire is deferred (honest status)

A one-shot `claude -p` turn never compacts, so the spike could not make `PreCompact` fire live. It is confirmed by (a) the authoritative event list and (b) the unit-tested flush script. It will be exercised for real when Slice 1 runs in a long interactive session or via `/compact`. This is a *deferred verification*, not an assumption — flagged so Slice 1's first task is to confirm the live fire before depending on it.

## Reproduce

```
bash eval/spikes/s0-hook-capability/unit-test.sh      # deterministic: 6/0, no Claude needed
# live (consumes tokens):
cd eval/spikes/s0-hook-capability && claude -p "Use the Write tool to create demo.txt with 'hello'." \
  --output-format stream-json --verbose --include-hook-events --dangerously-skip-permissions --settings .claude/settings.json
# expect: S0_SENTINEL_SESSIONSTART_INJECTED present, Write denied, demo.txt absent
```
