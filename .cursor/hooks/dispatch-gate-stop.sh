#!/usr/bin/env bash
# stop — thin entry: block turn completion until required reviewer Tasks ran.
# All logic lives in scripts/lib/dispatch-gate-lib.sh. Emits {} or a
# {followup_message:...} object.
set -uo pipefail
ROOT="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
source "$ROOT/scripts/lib/dispatch-gate-lib.sh"
input="$(cat)"
dispatch_gate_handle_stop "$input"
exit 0
