#!/usr/bin/env bash
# postToolUse (no matcher) — thin entry: track research, Task, and write tools.
# All logic lives in scripts/lib/dispatch-gate-lib.sh.
set -uo pipefail
ROOT="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
source "$ROOT/scripts/lib/dispatch-gate-lib.sh"
input="$(cat)"
dispatch_gate_handle_post_tool "$input"
exit 0
