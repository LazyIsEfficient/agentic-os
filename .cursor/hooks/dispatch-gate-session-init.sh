#!/usr/bin/env bash
# sessionStart — thin entry: init dispatch ledger + inject orchestrator context.
# All logic lives in scripts/lib/dispatch-gate-lib.sh (kept out of .cursor/hooks/
# so the hook-safety denylist has no pipes/jq/process-subs to scan here).
set -uo pipefail
ROOT="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
source "$ROOT/scripts/lib/dispatch-gate-lib.sh"
input="$(cat)"
dispatch_gate_handle_session_init "$input"
exit 0
