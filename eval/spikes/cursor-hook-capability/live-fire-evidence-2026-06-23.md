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
| Agent reply in fresh chat | **NOT RUN** | Requires new Agent chat; Cursor may ignore `additional_context` on `beforeSubmitPrompt` (undocumented field) |

**Interpretation:** Script layer proven. Model surfacing remains **PENDING** until a human opens a new chat and asks for `LIVEFIRE-DIGEST-TOKEN` without pasting it — or Cursor documents/fixes `additional_context` on digest.

## Test B — survey model surfacing

| Check | Result | Notes |
|-------|--------|-------|
| Hook pipe + warn log | **PASS** | `.cursor/survey-guard.warns` gains `survey-warn cmd=docker run hello-world` |
| Agent sees `agent_message` when agent runs shell | **NOT RUN** | Cursor agent shell path may not invoke `beforeShellExecution` consistently |

## Test C — sessionStart inject

**PROVEN** (prior spike 2026-06-22, Cursor 3.8.11). Reconfirmed: inject JSON includes full `SESSION-STATE.md` + live-fire tokens.

## Operator sign-off (automated partial)

```
Digest Test A:  [ ] PASS  [x] FAIL/INCONCLUSIVE (contract only)  [ ] NOT RUN (model)
Survey Test B:  [ ] PASS  [x] INCONCLUSIVE (hook yes, model not verified)  [ ] NOT RUN
Cursor version tested: ___
Signed: automated preflight  Date: 2026-06-23
```
