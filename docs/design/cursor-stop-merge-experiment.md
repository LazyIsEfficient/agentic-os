# Ready-to-run probe: Cursor two-hook `stop` merge semantics

**Status:** NOT APPLIED. This is a copy-paste, fully-reversible spike the operator runs in ONE live
Cursor session to observe how Cursor reconciles a second `stop`-hook `followup_message` alongside
`dispatch-gate-stop.sh`. It exists because the merge rule for two same-source `followup_message`
outputs is **undocumented** (see `cursor-stop-merge-findings.md`). With the mutual-exclusion design
in that doc, running this is **confirmatory, not blocking** — do it before shipping to consumers (P4),
not as a P2b blocker.

**Naming note (grounding):** the probe is named `stop-probe.sh`, **not** `_probe-stop-b.sh`. This
repo's `validate.sh` exempts only files matching `*-probe.sh` from hook-registration/parity/safety
checks (`scripts/validate.sh:702,763,855`). A name like `_probe-stop-b.sh` ends in `-b.sh`, would be
treated as a production script, and would fail `check_hook_parity` (it isn't in the consumer manifest).
`stop-probe.sh` keeps `bash scripts/validate.sh` **fully green** throughout the experiment.

---

## Step 1 — create the probe script

Write `/.cursor/hooks/stop-probe.sh` (chmod +x) with exactly this body:

```bash
#!/usr/bin/env bash
# stop-probe.sh — THROWAWAY spike fixture (dev-only; *-probe.sh is validate-exempt).
# Observes how Cursor reconciles a SECOND stop-hook followup_message alongside
# dispatch-gate-stop.sh. Logs stdin (incl. loop_count) + emits a distinctive followup.
# REMOVE after the experiment (see cursor-stop-merge-experiment.md, Step 5).
set -uo pipefail
dir="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
log="$dir/.cursor/stop-probe.log"
input="$(cat)"
{
  printf '=== stop-probe fired %s ===\n' "$(date -u +%FT%TZ)"
  printf 'STDIN: %s\n' "$input"
} >> "$log" 2>/dev/null || true
printf '%s\n' '{"followup_message":"PROBE-B: second stop hook fired"}'
exit 0
```

```bash
chmod +x .cursor/hooks/stop-probe.sh
```

## Step 2 — register it as a SECOND `stop` entry

Edit `.cursor/hooks.json` so the `stop` array holds both entries (probe registered AFTER
dispatch-gate, mirroring the intended P2b order):

```json
    "stop": [
      { "command": ".cursor/hooks/dispatch-gate-stop.sh", "loop_limit": 8, "timeout": 120 },
      { "command": ".cursor/hooks/stop-probe.sh", "loop_limit": 2, "timeout": 30 }
    ]
```

Confirm Tier 0 still passes (it will — probes are exempt):

```bash
bash scripts/validate.sh
```

## Step 3 — the ONE operator action

Two variants, pick per what you want to learn:

- **(A) "Does the 2nd stop hook fire at all + independent loop budget?"** — In a Cursor **Agent-mode**
  session in this repo, send any prompt and let the agent finish one turn (Stop fires). The probe
  always emits `PROBE-B`.
- **(B) "The real collision"** — first arm the dispatch-gate so it *also* wants to emit a followup on
  the same Stop: set `"enabled": true` in `.cursor/dispatch-gate.json`, make one **uncommitted code
  edit** (e.g. touch a line in any `scripts/*.sh`) so `dispatch_gate_missing_reviewers_for_worktree`
  is true, then finish a turn **without** dispatching reviewers. Now BOTH stop hooks emit a
  `followup_message` on the same event — this is the exact P2b collision.

## Step 4 — what to read afterward

- **`.cursor/stop-probe.log`** — confirms the probe ran and captures its stdin. Inspect the
  `loop_count` field in the logged STDIN: if it increments independently of dispatch-gate's re-entries,
  `loop_limit` is per-hook (as the docs claim).
- **The agent's next user message (in the Cursor chat)** — the decisive observation:
  - Only `PROBE-B` → last-wins (probe, registered second, overwrote dispatch-gate). **Bad for the
    reviewer gate** — validates why the yield rule (findings doc) is load-bearing.
  - Only the dispatch-gate reviewer text → first-wins (dispatch-gate, registered first). Safe ordering.
  - Both texts (concatenated / two messages) → data-merge. Safe.
- **`.cursor/dispatch-ledger.json`** — unchanged shape; sanity that the probe didn't corrupt state.

## Step 5 — revert (fully reversible)

```bash
git checkout .cursor/hooks.json .cursor/dispatch-gate.json   # if you toggled variant B
rm -f .cursor/hooks/stop-probe.sh .cursor/stop-probe.log
bash scripts/validate.sh                                     # green
```

Nothing here touches production hooks, the memory mechanism, or consumer manifests.
