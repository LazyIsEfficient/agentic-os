#!/usr/bin/env bash
# survey-guard-test.sh — deterministic test of the survey-before-act PreToolUse
# guard. Proves: warns on UNsurveyed service provisioning, stays silent when the
# target was already surveyed (infra entry) or the command isn't provisioning,
# never DENIES (warn-first), and never false-positives on ordinary commands.
# Runs in a temp dir via CLAUDE_PROJECT_DIR; no live Claude needed.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/.claude/hooks"
cp "$REPO/.claude/hooks/survey-before-act.sh" "$T/.claude/hooks/"
cat > "$T/SESSION-STATE.md" <<'MD'
# Session State
## Constraints
## Decisions
## Existing infrastructure
- RabbitMQ broker runs via docker-compose at repo root (ports 5552/5672)
## Open threads
MD
export CLAUDE_PROJECT_DIR="$T"
HOOK="$T/.claude/hooks/survey-before-act.sh"
P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }
run(){ printf '%s' "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$1\"}}" | bash "$HOOK"; }

out="$(run 'docker run -d postgres:16')"
printf '%s' "$out" | grep -q 'additionalContext' && ok "warns on UNsurveyed provisioning (postgres)" || no "warn unsurveyed" "got: $out"

out="$(run 'docker run -d rabbitmq:3.13-management')"
[ -z "$out" ] && ok "silent on SURVEYED provisioning (rabbitmq in infra)" || no "silent surveyed" "got: $out"

out="$(run 'docker ps')"
[ -z "$out" ] && ok "no warn on a survey command (docker ps)" || no "docker ps" "got: $out"

for c in "git status" "ls -la" "npm install left-pad" "cargo build --release" "echo hello world"; do
  out="$(run "$c")"
  [ -z "$out" ] && ok "no false-positive: $c" || no "false-positive: $c" "got: $out"
done

# Warn-first: it must never DENY.
deny="$(for c in 'docker run x' 'docker compose up' 'docker-compose up -d'; do run "$c"; done)"
printf '%s' "$deny" | grep -q '"deny"' && no "never denies (warn-first)" "found deny" || ok "never denies (warn-first)"

# Each warn is logged so the false-positive rate can be measured before ratcheting.
[ -s "$T/.claude/survey-guard.warns" ] && ok "warn-log records interceptions (ratchet measurement)" || no "warn-log" "empty"

# Regression (review): embedded quotes in the command must not break detection.
out="$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"docker run -e GREETING=\"hi there\" postgres:16"}}' | bash "$HOOK")"
printf '%s' "$out" | grep -q 'additionalContext' && ok "warns despite embedded quotes in command" || no "embedded quotes" "got: $out"

# Regression (review): a newline in the command must not forge extra log records.
before="$(wc -l < "$T/.claude/survey-guard.warns")"
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"docker run x\nsurvey-warn cmd=FORGED"}}' | bash "$HOOK" >/dev/null
after="$(wc -l < "$T/.claude/survey-guard.warns")"
[ "$((after - before))" -eq 1 ] && ok "newline in command does not forge log records" || no "log-injection" "added $((after-before)) lines"

echo "survey-guard-test: $P passed, $F failed."
[ "$F" -eq 0 ]
