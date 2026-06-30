#!/usr/bin/env bash
# afterFileEdit — thin entry: record ungated code edits as a stop-hook safety net.
# All logic lives in scripts/lib/dispatch-gate-lib.sh.
set -uo pipefail
ROOT="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
source "$ROOT/scripts/lib/dispatch-gate-lib.sh"
input="$(cat)"
dispatch_gate_handle_after_file_edit "$input"
exit 0
