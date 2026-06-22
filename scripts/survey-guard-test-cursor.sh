#!/usr/bin/env bash
# survey-guard-test-cursor.sh — deterministic test of Cursor survey-before-act hook.
# Mirrors scripts/survey-guard-test.sh using beforeShellExecution JSON stdin.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/.cursor/hooks"
cp "$REPO/.cursor/hooks/survey-before-act.sh" "$T/.cursor/hooks/"
cat > "$T/SESSION-STATE.md" <<'MD'
# Session State
## Constraints
## Decisions
## Existing infrastructure
- [surveyed:rabbitmq] broker runs via docker-compose at repo root (ports 5552/5672)
## Open threads
MD
export CURSOR_PROJECT_DIR="$T"
HOOK="$T/.cursor/hooks/survey-before-act.sh"
P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }
run(){ printf '%s' "{\"command\":\"$1\",\"cwd\":\"$T\",\"sandbox\":false}" | bash "$HOOK"; }

out="$(run 'docker run -d postgres:16')"
printf '%s' "$out" | grep -q 'agent_message' && ok "warns on UNsurveyed provisioning (postgres)" || no "warn unsurveyed" "got: $out"

out="$(run 'docker run -d rabbitmq:3.13-management')"
if printf '%s' "$out" | grep -q 'survey-before-act'; then
  no "silent surveyed" "got: $out"
else
  ok "silent on SURVEYED provisioning ([surveyed:rabbitmq] matches)"
fi

out="$(run 'docker run -d --name kafka-broker apache/kafka:latest')"
printf '%s' "$out" | grep -q 'agent_message' \
  && ok "warns on coincidental token (kafka-broker != [surveyed:rabbitmq])" \
  || no "false-negative regression" "coincidental 'broker' wrongly suppressed: $out"

out="$(run 'docker ps')"
if printf '%s' "$out" | grep -q 'survey-before-act'; then
  no "docker ps" "got: $out"
else
  ok "no warn on a survey command (docker ps)"
fi

legacy="$(mktemp -d)"; mkdir -p "$legacy/.cursor/hooks"
cp "$REPO/.cursor/hooks/survey-before-act.sh" "$legacy/.cursor/hooks/"
printf '# Session State\n## Existing infrastructure\n- [rabbitmq] legacy subject without surveyed prefix\n## Open threads\n' > "$legacy/SESSION-STATE.md"
lout="$(printf '%s' "{\"command\":\"docker run -d rabbitmq:3.13\",\"cwd\":\"$legacy\",\"sandbox\":false}" | CURSOR_PROJECT_DIR="$legacy" bash "$legacy/.cursor/hooks/survey-before-act.sh")"
printf '%s' "$lout" | grep -q 'agent_message' \
  && ok "Option B: plain [rabbitmq] without surveyed prefix warns (no suppress)" \
  || no "legacy [subject] suppression" "plain bracket wrongly suppressed: $lout"
rm -rf "$legacy"

legacy2="$(mktemp -d)"; mkdir -p "$legacy2/.cursor/hooks"
cp "$REPO/.cursor/hooks/survey-before-act.sh" "$legacy2/.cursor/hooks/"
printf '# Session State\n## Existing infrastructure\n- rabbitmq broker, no subject token\n## Open threads\n' > "$legacy2/SESSION-STATE.md"
lout2="$(printf '%s' "{\"command\":\"docker run -d rabbitmq:3.13\",\"cwd\":\"$legacy2\",\"sandbox\":false}" | CURSOR_PROJECT_DIR="$legacy2" bash "$legacy2/.cursor/hooks/survey-before-act.sh")"
printf '%s' "$lout2" | grep -q 'agent_message' \
  && ok "fail-open: bracket-less infra warns, never silently suppresses" \
  || no "legacy suppression" "bracket-less infra wrongly suppressed: $lout2"
rm -rf "$legacy2"

for c in "git status" "ls -la" "npm install left-pad" "cargo build --release" "echo hello world"; do
  out="$(run "$c")"
  if printf '%s' "$out" | grep -q 'survey-before-act'; then
    no "false-positive: $c" "got: $out"
  else
    ok "no false-positive: $c"
  fi
done

deny="$(for c in 'docker run x' 'docker compose up' 'docker-compose up -d'; do run "$c"; done)"
printf '%s' "$deny" | grep -q '"deny"' && no "never denies (warn-first)" "found deny" || ok "never denies (warn-first)"

[ -s "$T/.cursor/survey-guard.warns" ] && ok "warn-log records interceptions (ratchet measurement)" || no "warn-log" "empty"

out="$(printf '%s' '{"command":"docker run -e GREETING=\"hi there\" postgres:16","cwd":"'"$T"'","sandbox":false}' | bash "$HOOK")"
printf '%s' "$out" | grep -q 'agent_message' && ok "warns despite embedded quotes in command" || no "embedded quotes" "got: $out"

before="$(wc -l < "$T/.cursor/survey-guard.warns")"
printf '%s' '{"command":"docker run x\nsurvey-warn cmd=FORGED","cwd":"'"$T"'","sandbox":false}' | bash "$HOOK" >/dev/null
after="$(wc -l < "$T/.cursor/survey-guard.warns")"
[ "$((after - before))" -eq 1 ] && ok "newline in command does not forge log records" || no "log-injection" "added $((after-before)) lines"

echo "survey-guard-test-cursor: $P passed, $F failed."
[ "$F" -eq 0 ]
