#!/usr/bin/env bash
# PreToolUse hook on Agent|Task: denies subagent spawns that would run as the
# catch-all `general-purpose` agent. The library promises that work is always
# dispatched to a named specialist; this makes that promise mechanical.
#
# Denied when tool_input.subagent_type is:
#   - absent, empty, or whitespace-only (Claude Code defaults these to general-purpose)
#   - `general-purpose` / `generalPurpose` (compared case-insensitively with all
#     non-alphanumerics stripped, so `General_Purpose` etc. are caught too)
# Everything else is allowed silently (exit 0, no output).
#
# Deny = exit 0 with hookSpecificOutput.permissionDecision "deny" on stdout.
# Mechanism verified in issue #230: PreToolUse fires on Agent spawns, the payload
# carries subagent_type, and permissionDecision "deny" blocks the spawn.
#
# FAILS CLOSED on failures INSIDE this script, unlike the ergonomics hooks
# (block-bad-bash.sh, survey-before-act.sh), which fail open. This hook
# enforces a policy, so a missing jq or an unparseable payload denies the spawn
# with a message saying why, instead of letting an unchecked spawn through. The
# settings matcher already limits this hook to Agent|Task calls, so failing
# closed cannot block any other tool. Failures OUTSIDE the script (it can't
# start, or it times out) are non-blocking errors in Claude Code. Only the
# hook entry's `"onFailure": "block"` (v2.1.295+) closes that gap.
#
# There is deliberately no bypass switch (env var, flag file): anything the
# model could set itself would defeat the ban. To exempt a session, run it
# without this repo's project settings (see eval/README.md).

set -uo pipefail

SPECIALISTS="Set subagent_type to a specialist instead: Explore for read-only search, Plan for read-only design, engineer or a stack engineer (rust-engineer, web3-engineer, devops-engineer; godot-engineer and phaser-engineer with the games pack, install.sh --with-games) for implementation, code-reviewer / security-reviewer / library-reviewer for review."

# $1 must be JSON-string-safe (no double quotes or backslashes): it is only
# ever a literal from this file, so this path needs no jq.
deny_static() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

input=$(< /dev/stdin)

if ! command -v jq >/dev/null 2>&1; then
  deny_static "block-general-purpose: jq is not installed, so subagent_type cannot be checked. This hook fails closed for Agent/Task spawns; install jq to dispatch subagents. $SPECIALISTS"
fi

# Emits one of: "skip" (not an Agent/Task call), "deny" (general-purpose or
# untyped), "ok" (named specialist). Any jq error — invalid JSON, non-object
# payload, non-string subagent_type — leaves $verdict empty and denies below.
verdict=$(printf '%s' "$input" | jq -r '
  if (.tool_name | type) != "string" or .tool_name == "" then error("no tool_name")
  elif (.tool_name != "Agent" and .tool_name != "Task") then "skip"
  else
    ((.tool_input.subagent_type // "") | ascii_downcase | gsub("[^a-z0-9]"; "")) as $t
    | if ($t == "" or $t == "generalpurpose") then "deny" else "ok" end
  end
' 2>/dev/null)

case "$verdict" in
  skip|ok) exit 0 ;;
  deny)
    jq -cn --arg r "block-general-purpose: general-purpose subagents are not allowed in this library (an omitted subagent_type defaults to general-purpose). $SPECIALISTS" \
      '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    exit 0
    ;;
  *)
    deny_static "block-general-purpose: could not parse the hook payload, so subagent_type cannot be checked. This hook fails closed for Agent/Task spawns. $SPECIALISTS"
    ;;
esac
