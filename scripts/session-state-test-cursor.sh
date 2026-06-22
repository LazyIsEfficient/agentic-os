#!/usr/bin/env bash
# session-state-test-cursor.sh — deterministic test of Cursor SESSION-STATE hooks.
# Mirrors scripts/session-state-test.sh using CURSOR_PROJECT_DIR and JSON stdout.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
SKILL_SRC="$REPO/.claude/skills/session-state"
SKILL="$T/.cursor/skills/session-state"
mkdir -p "$T/.cursor/hooks" "$SKILL/scripts" "$SKILL/assets"
cp "$SKILL_SRC/assets/SESSION-STATE.template.md" "$SKILL/assets/"
cp "$SKILL_SRC/scripts/session-state.sh" "$SKILL/scripts/"
cp "$REPO/.cursor/hooks/session-state-inject.sh" "$T/.cursor/hooks/"
cp "$REPO/.cursor/hooks/session-state-digest.sh" "$T/.cursor/hooks/"
cp "$REPO/.cursor/hooks/session-state-checkpoint.sh" "$T/.cursor/hooks/"

export CURSOR_PROJECT_DIR="$T"
SS="$SKILL/scripts/session-state.sh"
P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }
has(){ printf '%s' "$2" | grep -q -- "$3" && ok "$1" || no "$1" "got: $2"; }
hasnt(){ printf '%s' "$2" | grep -q -- "$3" && no "$1" "unexpected: $3" || ok "$1"; }

json_field() {
  local json="$1" key="$2"
  printf '%s' "$json" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get(sys.argv[1],""))' "$key" 2>/dev/null
}

bash "$SS" init >/dev/null
[ -f "$T/SESSION-STATE.md" ] && ok "init creates live doc from template" || no "init" "no file"

bash "$SS" constraint "No Python — Rust only" >/dev/null
bash "$SS" decision "Awareness via deterministic hooks" >/dev/null
bash "$SS" infra "RabbitMQ broker already running on :5552" >/dev/null
bash "$SS" thread "Confirm PreCompact live-fire" >/dev/null

live="$(cat "$T/SESSION-STATE.md")"
has "constraint recorded under its section" "$live" "No Python — Rust only"
has "decision is date-stamped" "$live" "$(printf '\\[%s\\]' "$(date +%F)")"
has "infra finding recorded" "$live" "RabbitMQ broker already running"

inj_json="$(printf '%s' '{"session_id":"t","is_background_agent":false}' | bash "$T/.cursor/hooks/session-state-inject.sh")"
inj="$(json_field "$inj_json" additional_context)"
has "inject emits constraint" "$inj" "No Python — Rust only"
has "inject emits infra" "$inj" "RabbitMQ broker already running"
has "inject emits SESSION STATE banner" "$inj" "SESSION STATE"

dig_json="$(printf '%s' '{"prompt":"hi"}' | bash "$T/.cursor/hooks/session-state-digest.sh")"
dig="$(json_field "$dig_json" additional_context)"
has "digest includes constraint" "$dig" "No Python — Rust only"
has "digest includes open thread" "$dig" "Confirm PreCompact live-fire"
hasnt "digest EXCLUDES decisions (token discipline)" "$dig" "Awareness via deterministic hooks"
hasnt "digest EXCLUDES infra (token discipline)" "$dig" "RabbitMQ broker already running"

fresh="$(mktemp -d)"; cp "$SKILL_SRC/assets/SESSION-STATE.template.md" "$fresh/SESSION-STATE.md"
empty_json="$(printf '%s' '{"prompt":"hi"}' | CURSOR_PROJECT_DIR="$fresh" bash "$T/.cursor/hooks/session-state-digest.sh")"
empty_ctx="$(json_field "$empty_json" additional_context)"
[ -z "$empty_ctx" ] && ok "digest is empty on uninitialized template (no placeholder noise)" || no "empty digest" "got: $empty_ctx"
rm -rf "$fresh"

printf '%s' '{"trigger":"manual"}' | bash "$T/.cursor/hooks/session-state-checkpoint.sh"
[ -s "$T/.cursor/session-state.checkpoints" ] && ok "checkpoint writes marker" || no "checkpoint" "no log"
has "checkpoint records trigger" "$(cat "$T/.cursor/session-state.checkpoints")" "trigger=manual"

printf '%s' '{"trigger":"Manual"}' | bash "$T/.cursor/hooks/session-state-checkpoint.sh"
has "checkpoint captures mixed-case trigger" "$(cat "$T/.cursor/session-state.checkpoints")" "trigger=Manual"

bash "$SS" constraint 'Windows path C:\Users\dev stays literal' >/dev/null
if grep -qF 'C:\Users\dev' "$T/SESSION-STATE.md"; then
  ok "backslashes in entry text preserved verbatim"
else
  no "backslash preservation" "got: $(grep -i windows "$T/SESSION-STATE.md")"
fi

bash "$SS" thread "TEMP-DROP-ME stale thread" >/dev/null
bash "$SS" drop "TEMP-DROP-ME" >/dev/null
dropped="$(cat "$T/SESSION-STATE.md")"
hasnt "drop removes the matching bullet" "$dropped" "TEMP-DROP-ME"
has "drop leaves other bullets intact" "$dropped" "Confirm PreCompact live-fire"

echo "session-state-test-cursor: $P passed, $F failed."
[ "$F" -eq 0 ]
