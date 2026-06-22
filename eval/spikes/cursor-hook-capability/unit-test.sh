#!/usr/bin/env bash
# Cursor hook spike — deterministic unit test of probe SCRIPTS (no live Cursor needed).
# Proves hook-authoring mechanics: each script reads mock Cursor event JSON on stdin
# and emits the documented Cursor stdout contract. Platform invocation is verified
# separately via interactive live-fire in cursor-hook-capability.md.
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
R="$(cd "$D/../../.." && pwd)"
SS="$R/.cursor/hooks/session-state-inject-probe.sh"
SB="$R/.cursor/hooks/survey-before-act-probe.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0; fail=0
ok(){ printf 'PASS  %s\n' "$1"; pass=$((pass+1)); }
no(){ printf 'FAIL  %s — got: %s\n' "$1" "$2"; fail=$((fail+1)); }
has(){ printf '%s' "$2" | grep -q "$3" && ok "$1" || no "$1" "$2"; }
hasnt(){ printf '%s' "$2" | grep -q "$3" && no "$1" "$2" || ok "$1"; }
perm_allow(){ printf '%s' "$1" | grep -Eq '"permission"[[:space:]]*:[[:space:]]*"allow"' && ok "$2" || no "$2" "$1"; }

# Spike A — sessionStart probe
out=$(printf '%s' '{"session_id":"test","is_background_agent":false,"composer_mode":"agent"}' \
  | CURSOR_PROJECT_DIR="$TMP" bash "$SS")
has "sessionStart emits additional_context JSON field" "$out" '"additional_context"'
has "sessionStart injects sentinel when no state file" "$out" 'CURSOR_SPIKE_SESSIONSTART_INJECTED'

printf '%s\n' '## Constraints' '- spike constraint' > "$TMP/SESSION-STATE.md"
out=$(printf '%s' '{"session_id":"test","is_background_agent":false}' \
  | CURSOR_PROJECT_DIR="$TMP" bash "$SS")
has "sessionStart includes SESSION STATE banner" "$out" 'SESSION STATE'
has "sessionStart includes file body" "$out" 'spike constraint'

# Spike B — beforeShellExecution probe (unsurveyed docker run)
rm -f "$TMP/.cursor/survey-guard.warns"
mkdir -p "$TMP/.cursor"
out=$(printf '%s' '{"command":"docker run -d redis","cwd":"'"$TMP"'","sandbox":false}' \
  | CURSOR_PROJECT_DIR="$TMP" bash "$SB")
perm_allow "$out" "beforeShellExecution warns on unsurveyed docker run"
has "beforeShellExecution agent_message carries advisory" "$out" 'survey-before-act'
has "beforeShellExecution agent_message carries sentinel" "$out" 'CURSOR_SPIKE_SURVEY_WARN'
[ -s "$TMP/.cursor/survey-guard.warns" ] && ok "beforeShellExecution appends warn log" \
  || no "beforeShellExecution appends warn log" "(missing)"

# Surveyed subject suppresses warn
printf '%s\n' '## Existing infrastructure' '- [redis] running on 6379' > "$TMP/SESSION-STATE.md"
out=$(printf '%s' '{"command":"docker run -d redis","cwd":"'"$TMP"'","sandbox":false}' \
  | CURSOR_PROJECT_DIR="$TMP" bash "$SB")
perm_allow "$out" "beforeShellExecution allows surveyed docker run"
hasnt "beforeShellExecution suppresses advisory when surveyed" "$out" 'CURSOR_SPIKE_SURVEY_WARN'

# Non-provisioning command is silent allow
out=$(printf '%s' '{"command":"docker ps","cwd":"'"$TMP"'","sandbox":false}' \
  | CURSOR_PROJECT_DIR="$TMP" bash "$SB")
perm_allow "$out" "beforeShellExecution allows docker ps"
hasnt "beforeShellExecution ignores docker ps" "$out" 'CURSOR_SPIKE_SURVEY_WARN'

echo "unit-test: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
