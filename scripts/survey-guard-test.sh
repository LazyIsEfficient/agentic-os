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
- [surveyed:rabbitmq] broker runs via docker-compose at repo root (ports 5552/5672)
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
[ -z "$out" ] && ok "silent on SURVEYED provisioning ([surveyed:rabbitmq] matches)" || no "silent surveyed" "got: $out"

# Structured-subject fix (the false-negative the fuzzy substring scan had): a
# DIFFERENT service whose name coincidentally contains a word from the surveyed
# entry's free text ("broker") must still WARN — it is not the [rabbitmq] subject.
out="$(run 'docker run -d --name kafka-broker apache/kafka:latest')"
printf '%s' "$out" | grep -q 'additionalContext' \
  && ok "warns on coincidental token (kafka-broker != [surveyed:rabbitmq])" \
  || no "false-negative regression" "coincidental 'broker' wrongly suppressed: $out"

out="$(run 'docker ps')"
[ -z "$out" ] && ok "no warn on a survey command (docker ps)" || no "docker ps" "got: $out"

# Legacy / fail-open: a free-text infra entry with NO [subject] token records no
# survey subject, so provisioning warns (degrades safe, never silently suppresses).
legacy="$(mktemp -d)"; mkdir -p "$legacy/.claude/hooks"
cp "$REPO/.claude/hooks/survey-before-act.sh" "$legacy/.claude/hooks/"
printf '# Session State\n## Existing infrastructure\n- [rabbitmq] legacy subject without surveyed prefix\n## Open threads\n' > "$legacy/SESSION-STATE.md"
lout="$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"docker run -d rabbitmq:3.13"}}' | CLAUDE_PROJECT_DIR="$legacy" bash "$legacy/.claude/hooks/survey-before-act.sh")"
printf '%s' "$lout" | grep -q 'additionalContext' \
  && ok "Option B: plain [rabbitmq] without surveyed prefix warns (no suppress)" \
  || no "legacy [subject] suppression" "plain bracket wrongly suppressed: $lout"
rm -rf "$legacy"

legacy2="$(mktemp -d)"; mkdir -p "$legacy2/.claude/hooks"
cp "$REPO/.claude/hooks/survey-before-act.sh" "$legacy2/.claude/hooks/"
printf '# Session State\n## Existing infrastructure\n- rabbitmq broker, no subject token\n## Open threads\n' > "$legacy2/SESSION-STATE.md"
lout2="$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"docker run -d rabbitmq:3.13"}}' | CLAUDE_PROJECT_DIR="$legacy2" bash "$legacy2/.claude/hooks/survey-before-act.sh")"
printf '%s' "$lout2" | grep -q 'additionalContext' \
  && ok "fail-open: bracket-less infra warns, never silently suppresses" \
  || no "legacy suppression" "bracket-less infra wrongly suppressed: $lout2"
rm -rf "$legacy2"

for c in "git status" "ls -la" "npm install left-pad" "cargo build --release" "echo hello world"; do
  out="$(run "$c")"
  [ -z "$out" ] && ok "no false-positive: $c" || no "false-positive: $c" "got: $out"
done

out="$(run 'gh pr create --title x --body docker run hello-world')"
[ -z "$out" ] && ok "no false-positive: gh with docker run in body" || no "gh body false-positive" "got: $out"

out="$(run 'printf docker run nginx')"
[ -z "$out" ] && ok "no false-positive: printf mentioning docker run" || no "printf false-positive" "got: $out"

out="$(run 'docker run --help')"
[ -z "$out" ] && ok "no warn on docker run --help (survey not provision)" || no "docker run --help" "got: $out"

out="$(run 'cd /tmp && docker run -d nginx')"
printf '%s' "$out" | grep -q 'additionalContext' && ok "warns when docker run follows && chain" || no "&& chain provisioning" "got: $out"

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
