#!/usr/bin/env bash
# memory-extract-hook-test.sh — deterministic, OFFLINE plumbing test for the
# memory-extraction Stop hook (.claude/hooks/memory-extract.sh, issue #217).
#
# This is the TIER-0 layer of P3's ratchet evidence. It proves the hook's
# mechanical contract WITHOUT a live model: epoch self-gating (N=3), fail-open on
# bad input, path-traversal containment, nudge JSON shape, and garbled-state
# tolerance. The TIER-2 semantic question ("did the model actually persist a
# durable fact?") is inherently stochastic and is proven only by the live dogfood
# run in docs/runbooks/memory-longitudinal-dogfood.md — never in CI.
#
# Every fire runs against an ISOLATED CLAUDE_PROJECT_DIR (mktemp -d), so this test
# never reads or writes the repo's own .claude/memory/. Dependency-light:
# bash + jq + coreutils (jq is already a hard dependency of the hook itself).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO/.claude/hooks/memory-extract.sh"

command -v jq >/dev/null 2>&1 || { echo "memory-extract-hook-test: jq is required" >&2; exit 2; }
[ -f "$HOOK" ] || { echo "memory-extract-hook-test: hook not found at $HOOK" >&2; exit 2; }

# One isolated project dir for the whole run — NEVER the real repo memory.
PROJ="$(mktemp -d)"
trap 'rm -rf "$PROJ"' EXIT
export CLAUDE_PROJECT_DIR="$PROJ"
EXTRACT="$PROJ/.claude/memory/.extract"

P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }

# Fire the hook with a JSON event carrying session_id=$1. Sets OUT (stdout), RC (exit).
fire(){ OUT="$(printf '{"session_id":"%s"}' "$1" | bash "$HOOK")"; RC=$?; }
# Fire with a RAW stdin payload (for the fail-open malformed/empty cases).
fire_raw(){ OUT="$(printf '%s' "$1" | bash "$HOOK")"; RC=$?; }
# Classify hook stdout: NUDGE when .decision==block, else ALLOW ({} -> null -> ALLOW).
verdict(){ printf '%s' "$1" | jq -r 'if .decision == "block" then "NUDGE" else "ALLOW" end' 2>/dev/null; }

# ── 1. Epoch behavior: 6 fires, one fixed session, N=3 ─────────────────────────
# Substance proxy re-nudges every 3 turns; the Stop right after a nudge has
# turns-nudged_at=1 < 3 so it cannot re-fire (loop-safe by construction).
SID="epoch-fixed"
v_seq=""; s_seq=""; rc_all=0
for i in 1 2 3 4 5 6; do
  fire "$SID"
  [ "$RC" -eq 0 ] || rc_all=1
  v_seq="$v_seq $(verdict "$OUT")"
  s_seq="$s_seq|$(cat "$EXTRACT/$SID" 2>/dev/null)"
done
[ "$rc_all" -eq 0 ] \
  && ok "epoch: every Stop invocation exits 0 (never blocks the user)" \
  || no "epoch exit codes" "a call exited nonzero"
exp_v=" ALLOW ALLOW NUDGE ALLOW ALLOW NUDGE"
[ "$v_seq" = "$exp_v" ] \
  && ok "epoch verdict sequence ALLOW,ALLOW,NUDGE,ALLOW,ALLOW,NUDGE (N=3)" \
  || no "epoch verdict sequence" "want='$exp_v' got='$v_seq'"
exp_s="|1 0|2 0|3 3|4 3|5 3|6 6"
[ "$s_seq" = "$exp_s" ] \
  && ok "epoch state advances 1 0 -> 2 0 -> 3 3 -> 4 3 -> 5 3 -> 6 6" \
  || no "epoch state transitions" "want='$exp_s' got='$s_seq'"

# ── 2. Fail-open: any bad input must still ALLOW ({}) and exit 0 ────────────────
fire_raw "not json"
{ [ "$RC" -eq 0 ] && [ "$OUT" = "{}" ]; } \
  && ok "fail-open: malformed stdin -> {} exit 0" \
  || no "fail-open (malformed stdin)" "rc=$RC out=[$OUT]"
fire_raw ""
{ [ "$RC" -eq 0 ] && [ "$OUT" = "{}" ]; } \
  && ok "fail-open: empty stdin -> {} exit 0" \
  || no "fail-open (empty stdin)" "rc=$RC out=[$OUT]"

# ── 3. Path-traversal containment ──────────────────────────────────────────────
# A hostile session_id must be sanitized so the hook can only ever write under
# .extract/. ../ and / are neutralized, so no traversal write can occur. We check
# the two concrete escape targets a naive join would reach (literal /tmp/PWNED and
# the 4-levels-up parent target) plus a general "nothing written outside .extract".
esc_parent="$(dirname "$PROJ")/tmp/PWNED"
had_tmp=0; [ -e /tmp/PWNED ] && had_tmp=1       # don't blame the hook for a pre-existing file
had_par=0; [ -e "$esc_parent" ] && had_par=1
fire "../../../../tmp/PWNED"
outside="$(find "$PROJ" -type f -not -path "$EXTRACT/*" 2>/dev/null)"
sanitized="$(find "$EXTRACT" -type f -name '*PWNED*' 2>/dev/null)"
trav_ok=1; detail=""
[ "$RC" -eq 0 ] || { trav_ok=0; detail="$detail rc=$RC;"; }
[ -z "$outside" ] || { trav_ok=0; detail="$detail wrote-outside-extract=[$outside];"; }
{ [ "$had_tmp" -eq 0 ] && [ -e /tmp/PWNED ]; } && { trav_ok=0; detail="$detail created /tmp/PWNED;"; }
{ [ "$had_par" -eq 0 ] && [ -e "$esc_parent" ]; } && { trav_ok=0; detail="$detail created $esc_parent;"; }
[ -n "$sanitized" ] || { trav_ok=0; detail="$detail no sanitized state file under .extract;"; }
[ "$trav_ok" -eq 1 ] \
  && ok "traversal: hostile session_id writes only under .extract/ (no /tmp/PWNED, no parent-tree escape)" \
  || no "traversal containment" "$detail"

# ── 4. Nudge content shape ─────────────────────────────────────────────────────
SID="content"
fire "$SID"; fire "$SID"; fire "$SID"   # 3rd fire hits the nudge epoch
valid_json=0; printf '%s' "$OUT" | jq -e . >/dev/null 2>&1 && valid_json=1
dec="$(printf '%s' "$OUT" | jq -r '.decision // ""' 2>/dev/null)"
names_skill=0; printf '%s' "$OUT" | jq -r '.reason // ""' 2>/dev/null | grep -q 'memory-extraction' && names_skill=1
{ [ "$valid_json" -eq 1 ] && [ "$dec" = "block" ] && [ "$names_skill" -eq 1 ]; } \
  && ok "nudge is valid JSON with .decision=block and .reason naming the memory-extraction skill" \
  || no "nudge content shape" "valid_json=$valid_json decision=$dec names_skill=$names_skill out=[$OUT]"

# ── 5. Garbled-state tolerance ─────────────────────────────────────────────────
# A state file that is not "<turns> <nudged_at>" (e.g. a stray ISO timestamp) must
# not crash the hook — it defaults to 0 0 and carries on.
SID="garbled"
mkdir -p "$EXTRACT"
printf '2026-07-13T00:00:00Z\n' > "$EXTRACT/$SID"
fire "$SID"
st="$(cat "$EXTRACT/$SID" 2>/dev/null)"
{ [ "$RC" -eq 0 ] && [ "$OUT" = "{}" ] && [ "$st" = "1 0" ]; } \
  && ok "garbled state (ISO timestamp) tolerated: defaults to 0 0, first fire ALLOW, state -> '1 0'" \
  || no "garbled-state tolerance" "rc=$RC out=[$OUT] state=[$st]"

echo ""
echo "memory-extract-hook-test: $P passed, $F failed."
[ "$F" -eq 0 ]
