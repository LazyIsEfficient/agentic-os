#!/usr/bin/env bash
# preToolUse (no matcher) — thin entry: route research/write tools to the gate.
# All logic lives in scripts/lib/dispatch-gate-lib.sh. failClosed in hooks.json,
# so the handler guarantees a {permission:...} object on every path.
set -uo pipefail
ROOT="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
source "$ROOT/scripts/lib/dispatch-gate-lib.sh"
input="$(cat)"
dispatch_gate_handle_pre_tool "$input"
exit 0
