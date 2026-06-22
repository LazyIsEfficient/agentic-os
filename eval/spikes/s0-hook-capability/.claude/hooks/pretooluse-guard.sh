#!/usr/bin/env bash
# S0 spike — PreToolUse hook: DENY a Write with a reason the model receives.
# Conditional on tool_name so non-Write tools pass (demonstrates selective gating).
set -uo pipefail
input="$(cat)"
if printf '%s' "$input" | grep -q '"tool_name"[[:space:]]*:[[:space:]]*"Write"'; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"S0_SENTINEL_PRETOOLUSE_DENIED_WRITE"}}'
fi
exit 0
