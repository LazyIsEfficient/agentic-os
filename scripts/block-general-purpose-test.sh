#!/usr/bin/env bash
# block-general-purpose-test.sh — deterministic test of the block-general-purpose
# PreToolUse hook (.claude/hooks/block-general-purpose.sh). Proves: untyped,
# whitespace-only, general-purpose, generalPurpose, and General_Purpose spawns
# are denied (permissionDecision "deny" on stdout); Explore / engineer spawns and
# non-Agent tools are allowed silently; malformed JSON and a missing jq both fail
# CLOSED. No live Claude needed — the hook only reads the payload from stdin.
# Requires jq to build payloads and read decisions (the no-jq case is simulated
# by running the hook with an empty PATH).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO/.claude/hooks/block-general-purpose.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "block-general-purpose-test: jq not found — needed to build payloads; skipping" >&2
  exit 0
fi

P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }

# decision <raw-stdin> [env-prefix...]: prints "deny", "allow" (exit 0 + empty
# stdout), or "other:<rc>:<stdout>" for anything unexpected.
decision(){
  local input="$1"; shift
  local out rc
  out=$(printf '%s' "$input" | "$@" "$BASH" "$HOOK" 2>/dev/null); rc=$?
  if [ "$rc" -eq 0 ] && [ -z "$out" ]; then printf 'allow'; return; fi
  if [ "$rc" -eq 0 ] && [ "$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // empty' 2>/dev/null)" = "deny" ]; then
    printf 'deny'; return
  fi
  printf 'other:%s:%s' "$rc" "$out"
}
# payload <tool_name> [subagent_type]: JSON built with jq; omit $2 for "absent".
payload(){
  if [ "$#" -ge 2 ]; then
    jq -cn --arg t "$1" --arg s "$2" '{tool_name:$t, tool_input:{subagent_type:$s, prompt:"x", description:"x"}}'
  else
    jq -cn --arg t "$1" '{tool_name:$t, tool_input:{prompt:"x", description:"x"}}'
  fi
}
expect(){ local want="$1" name="$2" got; shift 2; got=$(decision "$@"); [ "$got" = "$want" ] && ok "$name" || no "$name" "expected $want, got $got"; }

# Denied
expect deny  "denies untyped Agent (subagent_type absent)"   "$(payload Agent)"
expect deny  "denies empty subagent_type"                    "$(payload Agent '')"
expect deny  "denies whitespace-only subagent_type"          "$(payload Agent '   ')"
expect deny  "denies general-purpose"                        "$(payload Agent general-purpose)"
expect deny  "denies generalPurpose"                         "$(payload Agent generalPurpose)"
expect deny  "denies General_Purpose (normalized)"           "$(payload Agent General_Purpose)"
expect deny  "denies general-purpose via Task tool"          "$(payload Task general-purpose)"
# Allowed
expect allow "allows Explore"                                "$(payload Agent Explore)"
expect allow "allows engineer"                               "$(payload Agent engineer)"
expect allow "allows engineer via Task tool"                 "$(payload Task engineer)"
expect allow "allows non-Agent tool (Bash)"                  "$(jq -cn '{tool_name:"Bash", tool_input:{command:"ls"}}')"
# Fail closed
expect deny  "denies malformed JSON"                         '{"tool_name":"Agent", "tool_input": {'
expect deny  "denies empty payload"                          ''
expect deny  "denies payload without tool_name"              '{"tool_input":{"subagent_type":"engineer"}}'
expect deny  "denies non-string subagent_type"               '{"tool_name":"Agent","tool_input":{"subagent_type":42}}'
empty_path="$(mktemp -d)"
expect deny  "denies when jq is missing (empty PATH)"        "$(payload Agent engineer)" env PATH="$empty_path"
rmdir "$empty_path"

# The deny reason must route the caller to the specialists.
reason=$(payload Agent general-purpose | "$BASH" "$HOOK" | jq -r '.hookSpecificOutput.permissionDecisionReason')
missing=""
for s in Explore Plan engineer code-reviewer security-reviewer; do
  case "$reason" in *"$s"*) ;; *) missing="$missing $s" ;; esac
done
[ -z "$missing" ] && ok "deny reason names the specialists" || no "deny reason names the specialists" "missing:$missing"

printf 'block-general-purpose-test: %d passed, %d failed.\n' "$P" "$F"
[ "$F" -eq 0 ]
