# Cursor awareness hooks — live-fire protocol

**Issue:** [#170](https://github.com/LazyIsEfficient/agentic-os/issues/170)  
**Purpose:** Interactive repro for a human operator to confirm whether production hooks reach the model on Cursor.  
**Cannot be automated:** Cursor has no headless hook runner; this protocol is the acceptance gate for digest and survey surfacing.

---

## Environment pin

| Field | Value |
|---|---|
| **Cursor version** | _fill in: `cursor --version` or Help → About)_ |
| **OS** | _fill in_ |
| **Repo branch** | `main` (or PR branch under test) |
| **Operator** | _fill in_ |
| **Date** | _fill in_ |

Preflight (from repo root):

```bash
bash eval/spikes/cursor-hook-capability/run-automated.sh   # all contracts + evidence log
# or individually:
bash eval/spikes/cursor-hook-capability/unit-test.sh
bash scripts/session-state-test-cursor.sh
cursor --version
```

Confirm **Cursor Settings → Hooks** lists all four production hooks from `.cursor/hooks.json`:

- `sessionStart` → `.cursor/hooks/session-state-inject.sh`
- `beforeSubmitPrompt` → `.cursor/hooks/session-state-digest.sh`
- `preCompact` → `.cursor/hooks/session-state-checkpoint.sh`
- `beforeShellExecution` → `.cursor/hooks/survey-before-act.sh`

---

## Known platform limitation — `beforeSubmitPrompt` digest

**Official Cursor docs** ([hooks.md](https://cursor.com/docs/hooks.md) `beforeSubmitPrompt` section) document only two output fields:

- `continue` (boolean)
- `user_message` (string, when blocked)

There is **no documented `additional_context` field** for `beforeSubmitPrompt` in official Cursor docs ([hooks.md](https://cursor.com/docs/hooks.md)). Our production script emits `{continue: true, additional_context: "…"}`. **Live-fire Test A PASS (2026-06-23)** shows it reaches the model on at least one current Cursor build — docs may lag implementation (same class of gap as historical `updated_input` stripping — see [forum thread](https://forum.cursor.com/t/bug-beforesubmitprompt-hook-updated-input-is-silently-stripped-modified-prompt-never-reaches-the-model/158883)).

**If live-fire FAILS for digest:** treat per-turn digest as **non-functional on Cursor today**. Fallback strategy:

1. **`sessionStart` inject** — full `SESSION-STATE.md` at conversation start (**PROVEN** on Cursor `3.8.11`; see spike A).
2. **Decisions in digest** — once [#158](https://github.com/LazyIsEfficient/agentic-os/issues/158) merges, settled decisions will appear in the session-start doc body; until then, record decisions via the session-state writer and rely on inject.
3. **Do not assume per-turn re-surfacing** on Cursor until this protocol records a PASS with evidence.

Record PASS/FAIL honestly below — a FAIL with evidence is a valid outcome that documents the limitation.

---

## Test A — `beforeSubmitPrompt` digest (per-turn)

### Setup

1. Ensure `SESSION-STATE.md` exists (`bash .claude/skills/session-state/scripts/session-state.sh init` if needed).
2. Add a **unique constraint** the model cannot guess:

   ```bash
   bash .claude/skills/session-state/scripts/session-state.sh constraint \
     "LIVEFIRE-DIGEST-TOKEN: reply with exactly CURSOR_LIVEFIRE_DIGEST_OK when asked"
   ```

3. Confirm digest script would emit it (deterministic sanity check):

   ```bash
   printf '%s' '{"prompt":"test"}' \
     | CURSOR_PROJECT_DIR="$PWD" bash .cursor/hooks/session-state-digest.sh \
     | jq -r '.additional_context // empty' | grep -F 'LIVEFIRE-DIGEST-TOKEN'
   ```

4. Open a **new Agent chat** (digest fires each turn, but a fresh chat avoids stale context). Do **not** paste the token into your prompt.

### Prompt to send

```
What is the LIVEFIRE-DIGEST-TOKEN constraint? Reply with only the value after the colon, nothing else.
```

### Pass criteria

| Check | Pass | Fail |
|---|---|---|
| Agent reply | Exactly `CURSOR_LIVEFIRE_DIGEST_OK` (or quotes the full constraint line including token) | Agent says it doesn't know / asks you to provide it |
| Hook fired (optional) | **Output → Hooks** (or Hooks log channel) shows `beforeSubmitPrompt` → `session-state-digest.sh` executed | No hook entry (may still pass if model saw injected context via another path — note which) |

### Evidence slot — Test A

```
Result: [ ] PASS  [ ] FAIL  [ ] INCONCLUSIVE

Agent reply (paste):
---

Hooks log excerpt (paste, if available):
---

Screenshot path or attachment ID:
---
```

---

## Test B — `beforeShellExecution` survey (provisioning advisory)

Uses production `.cursor/hooks/survey-before-act.sh` (no spike sentinel). Verifies hook fires on real provisioning commands and whether `agent_message` reaches the agent.

### Setup

1. Ensure `SESSION-STATE.md` has **no** `[hello-world]` (or similar) entry under `## Existing infrastructure`, or remove matching subjects.
2. Clear prior warn log: `rm -f .cursor/survey-guard.warns`
3. Open a **new Agent chat** with hooks loaded.

### Prompt to send

```
Run this command exactly: docker run hello-world
```

Approve shell execution if Cursor prompts. The command is safe (pulls/runs the hello-world image and exits).

### Pass criteria

| Check | Pass | Fail |
|---|---|---|
| `.cursor/survey-guard.warns` | New line: `survey-warn cmd=docker run hello-world` (or similar) | File missing or unchanged |
| Agent behavior | Agent mentions checking existing infrastructure / survey-before-act / reusing before provisioning | Agent runs command with no awareness of advisory |
| Hooks log (optional) | `beforeShellExecution` → `survey-before-act.sh` with `permission: allow` and `agent_message` in output | Hook not listed |

**Note:** Prior spike work reported that some agent shell paths did not trigger `beforeShellExecution`. If the warn log updates but the agent ignores the advisory, record **hook fires, model surfacing FAIL**. If neither log nor hook channel fires, record **hook invocation FAIL**.

### Suppression check (optional)

```bash
bash .claude/skills/session-state/scripts/session-state.sh infra "[hello-world] already surveyed for live-fire"
```

Repeat `docker run hello-world` in the same or a new chat → warn log should **not** gain a duplicate line for that surveyed subject.

### Evidence slot — Test B

```
Result: [ ] PASS  [ ] FAIL  [ ] INCONCLUSIVE

.cursor/survey-guard.warns contents (paste):
---

Agent reply excerpt (paste):
---

Hooks log excerpt (paste, if available):
---

Screenshot path or attachment ID:
---
```

---

## Test C — `sessionStart` inject (regression sanity)

Already **PROVEN** (2026-06-22, Cursor `3.8.11`). Optional quick re-check if upgrading Cursor version.

1. New Agent chat.
2. Prompt: `Reply with exactly the token CURSOR_SPIKE_SESSIONSTART_INJECTED and nothing else.`  
   (Requires spike probe in hooks.json, or use a unique constraint only in SESSION-STATE.md injected at start.)
3. **Pass:** agent outputs sentinel without you pasting it.

Evidence: `eval/spikes/cursor-hook-capability/live-fire.log`

---

## Summary checklist

| Hook | Event | Script contract | Live model surfacing | Evidence |
|---|---|---|---|---|
| Session inject | `sessionStart` | unit + `session-state-test-cursor.sh` ✓ | **PROVEN** (3.8.11, 2026-06-22) | `live-fire.log` |
| Per-turn digest | `beforeSubmitPrompt` | unit + `session-state-test-cursor.sh` ✓ | **PROVEN** — Test A PASS (2026-06-23) | [live-fire-evidence-2026-06-23.md](live-fire-evidence-2026-06-23.md) |
| Survey guard | `beforeShellExecution` | unit-test.sh ✓ | **PENDING** — Test B | Test B slot above |
| Checkpoint | `preCompact` | side-effect log ✓ | deferred (observational) | n/a |

**Operator sign-off:**

```
Digest Test A:  [x] PASS  [ ] FAIL  [ ] NOT RUN
Survey Test B:  [ ] PASS  [ ] FAIL  [ ] NOT RUN
Cursor version tested: ___________
Signed: ___________  Date: ___________
```

After completing Tests A and B, update [cursor-hook-capability.md](../cursor-hook-capability.md) mapping table and [README](../../../README.md) awareness section with confirmed status or documented limitation.
