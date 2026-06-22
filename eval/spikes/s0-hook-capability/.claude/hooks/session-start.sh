#!/usr/bin/env bash
# S0 spike — SessionStart hook: inject context the model will read.
set -uo pipefail
_=$(cat)  # consume the event JSON on stdin
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"S0_SENTINEL_SESSIONSTART_INJECTED"}}'
exit 0
