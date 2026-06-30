#!/usr/bin/env bash
# beforeReadFile — thin entry: research gate on main-thread file reads.
# All logic lives in scripts/lib/dispatch-gate-lib.sh. failClosed in hooks.json,
# so the handler guarantees a {permission:...} object on every path.
set -uo pipefail
ROOT="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
source "$ROOT/scripts/lib/dispatch-gate-lib.sh"
input="$(cat)"
dispatch_gate_handle_before_read "$input"
exit 0
