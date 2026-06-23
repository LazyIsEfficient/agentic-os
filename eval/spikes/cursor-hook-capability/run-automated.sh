#!/usr/bin/env bash
# run-automated.sh — deterministic live-fire preflight (no IDE required).
# Interactive Tests A/B model surfacing still need a fresh Agent chat; this script
# proves hook contracts + records evidence to live-fire.log.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"
LOG="$ROOT/eval/spikes/cursor-hook-capability/live-fire.log"
SS="$ROOT/.claude/skills/session-state/scripts/session-state.sh"
STAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
P=0; F=0
ok(){ printf 'OK   %s\n' "$1"; P=$((P+1)); }
bad(){ printf 'FAIL %s — %s\n' "$1" "$2"; F=$((F+1)); }

printf '\n=== live-fire automated %s ===\n' "$STAMP" | tee -a "$LOG"

bash "$ROOT/scripts/session-state-test-cursor.sh" >/dev/null && ok "session-state-test-cursor" || bad "session-state-test-cursor" "see above"
bash "$ROOT/scripts/survey-guard-test-cursor.sh" >/dev/null && ok "survey-guard-test-cursor" || bad "survey-guard-test-cursor" "see above"
bash "$ROOT/eval/spikes/cursor-hook-capability/unit-test.sh" >/dev/null && ok "unit-test" || bad "unit-test" "see above"

bash "$SS" constraint "LIVEFIRE-DIGEST-TOKEN: reply with exactly CURSOR_LIVEFIRE_DIGEST_OK when asked" >/dev/null 2>&1 || true
bash "$SS" constraint "LIVEFIRE-INJECT-TOKEN: reply with exactly CURSOR_LIVEFIRE_INJECT_OK when asked about inject token" >/dev/null 2>&1 || true

if printf '%s' '{"prompt":"live-fire"}' \
  | CURSOR_PROJECT_DIR="$ROOT" bash "$ROOT/.cursor/hooks/session-state-digest.sh" \
  | jq -r '.additional_context // empty' | grep -qF 'LIVEFIRE-DIGEST-TOKEN'; then
  ok "digest emits LIVEFIRE-DIGEST-TOKEN"
else
  bad "digest emits LIVEFIRE-DIGEST-TOKEN" "missing from additional_context"
fi

if printf '%s' '{"session_id":"auto","is_background_agent":false}' \
  | CURSOR_PROJECT_DIR="$ROOT" bash "$ROOT/.cursor/hooks/session-state-inject.sh" \
  | jq -r '.additional_context // empty' | grep -qF 'LIVEFIRE-DIGEST-TOKEN'; then
  ok "sessionStart inject includes LIVEFIRE-DIGEST-TOKEN"
else
  bad "sessionStart inject includes LIVEFIRE-DIGEST-TOKEN" "missing from additional_context"
fi

printf '%s' '{"command":"docker run hello-world","cwd":"'"$ROOT"'","sandbox":false}' \
  | CURSOR_PROJECT_DIR="$ROOT" bash "$ROOT/.cursor/hooks/survey-before-act.sh" >/dev/null
if grep -qF 'docker run hello-world' "$ROOT/.cursor/survey-guard.warns" 2>/dev/null; then
  ok "survey hook logs docker run hello-world"
else
  bad "survey hook logs docker run hello-world" "no line in .cursor/survey-guard.warns"
fi

printf '%s' '{"trigger":"manual"}' | CURSOR_PROJECT_DIR="$ROOT" bash "$ROOT/.cursor/hooks/session-state-checkpoint.sh" >/dev/null
[ -s "$ROOT/.cursor/session-state.checkpoints" ] && ok "preCompact checkpoint side-effect" || bad "preCompact checkpoint" "no log"

if command -v docker >/dev/null 2>&1; then
  docker run --rm hello-world >/dev/null 2>&1 && ok "docker hello-world runnable" || bad "docker hello-world" "docker failed"
else
  printf 'SKIP docker hello-world (not installed)\n'
fi

bash "$ROOT/eval/metrics/pre-register.sh" long-session-awareness >/dev/null && ok "A/B pre-register" || bad "A/B pre-register" "failed"

printf 'automated: %d ok, %d fail (stamp %s)\n' "$P" "$F" "$STAMP" | tee -a "$LOG"
[ "$F" -eq 0 ]
