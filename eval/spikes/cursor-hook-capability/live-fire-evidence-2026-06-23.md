# Live-fire evidence — automated run 2026-06-23

**Operator:** agent (automated preflight + hook pipe)  
**Branch:** `docs/v2-closeout-182` (PR #183)  
**Cursor version:** not pinned in CLI (`cursor --version` available)

## Automated (script contract) — PASS

Run: `bash eval/spikes/cursor-hook-capability/run-automated.sh`

| Check | Result |
|-------|--------|
| `session-state-test-cursor.sh` | PASS |
| `survey-guard-test-cursor.sh` | PASS (19/19 incl. gh/printf false-positive fixes) |
| `unit-test.sh` | PASS |
| Digest emits `LIVEFIRE-DIGEST-TOKEN` in `additional_context` | PASS |
| sessionStart inject includes `LIVEFIRE-DIGEST-TOKEN` | PASS |
| Survey hook logs `docker run hello-world` | PASS |
| preCompact checkpoint side-effect | PASS |
| `docker run --rm hello-world` | PASS |
| A/B pre-register | `eval/metrics/runs/20260623T012738Z-long-session-awareness/` |

## Test A — per-turn digest model surfacing

| Check | Result | Notes |
|-------|--------|-------|
| Hook output contract | **PASS** | Digest JSON contains token |
| Agent reply in fresh chat | **PASS** | Operator confirmed 2026-06-23 — model returned `CURSOR_LIVEFIRE_DIGEST_OK` without token pasted in prompt |

**Interpretation:** `beforeSubmitPrompt` + `additional_context` **reaches the model** on operator's Cursor build (docs may lag; see [LIVE-FIRE-PROTOCOL.md](LIVE-FIRE-PROTOCOL.md) limitation note).

## Test B — survey model surfacing

| Check | Result | Notes |
|-------|--------|-------|
| Hook pipe + warn log | **PASS** | `.cursor/survey-guard.warns` gains `survey-warn cmd=docker run hello-world` |
| Agent sees `agent_message` when agent runs shell | **NOT RUN** | Cursor agent shell path may not invoke `beforeShellExecution` consistently |

## Test C — sessionStart inject

**PROVEN** (prior spike 2026-06-22, Cursor 3.8.11). Reconfirmed: inject JSON includes full `SESSION-STATE.md` + live-fire tokens.

## Operator sign-off (automated partial)

```
Digest Test A:  [x] PASS  [ ] FAIL/INCONCLUSIVE  [ ] NOT RUN (model)
Survey Test B:  [ ] PASS  [x] INCONCLUSIVE (hook yes, model not verified)  [ ] NOT RUN
Cursor version tested: operator build (2026-06-23)
Signed: operator (digest PASS)  Date: 2026-06-23
```
