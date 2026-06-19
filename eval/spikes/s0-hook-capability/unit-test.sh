#!/usr/bin/env bash
# S0 spike — deterministic unit test of the hook SCRIPTS (no live Claude needed).
# Proves the hook-authoring mechanics: each script reads an event on stdin and
# emits the correct hookSpecificOutput JSON / side effect. This verifies OUR
# logic; the platform-invocation contract is verified separately by the live run.
set -uo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
H="$D/.claude/hooks"
pass=0; fail=0
ok(){ printf 'PASS  %s\n' "$1"; pass=$((pass+1)); }
no(){ printf 'FAIL  %s — got: %s\n' "$1" "$2"; fail=$((fail+1)); }
has(){ printf '%s' "$2" | grep -q "$3" && ok "$1" || no "$1" "$2"; }
hasnt(){ printf '%s' "$2" | grep -q "$3" && no "$1" "$2" || ok "$1"; }

out=$(printf '%s' '{"hook_event_name":"SessionStart"}' | bash "$H/session-start.sh")
has "SessionStart emits additionalContext field" "$out" '"additionalContext"'
has "SessionStart injects sentinel" "$out" 'S0_SENTINEL_SESSIONSTART_INJECTED'

out=$(printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{}}' | bash "$H/pretooluse-guard.sh")
has "PreToolUse denies Write" "$out" '"permissionDecision":"deny"'
has "PreToolUse deny carries reason" "$out" 'S0_SENTINEL_PRETOOLUSE_DENIED_WRITE'

out=$(printf '%s' '{"hook_event_name":"PreToolUse","tool_name":"Read","tool_input":{}}' | bash "$H/pretooluse-guard.sh")
hasnt "PreToolUse allows non-Write (no deny)" "$out" 'deny'

rm -f "$D/.claude/precompact-evidence.txt"
printf '%s' '{"hook_event_name":"PreCompact","trigger":"manual"}' | CLAUDE_PROJECT_DIR="$D" bash "$H/precompact-flush.sh"
[ -s "$D/.claude/precompact-evidence.txt" ] && ok "PreCompact flush wrote evidence" || no "PreCompact flush" "(empty)"

echo "unit-test: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
