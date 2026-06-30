#!/usr/bin/env bash
# subagentStop — thin entry: record completed implementation / reviewer Tasks.
# All logic lives in scripts/lib/dispatch-gate-lib.sh.
set -uo pipefail
ROOT="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
source "$ROOT/scripts/lib/dispatch-gate-lib.sh"
input="$(cat)"
dispatch_gate_handle_subagent_stop "$input"
exit 0
