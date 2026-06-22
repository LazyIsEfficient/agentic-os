#!/usr/bin/env bash
# Cursor preCompact — checkpoint before context compression (side-effect log only).
# Mirrors .claude/hooks/session-state-checkpoint.sh; re-injection after compact is
# handled by sessionStart + digest hooks, not this event.
set -uo pipefail
dir="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
log="$dir/.cursor/session-state.checkpoints"
event="$(cat)"
trigger="$(printf '%s' "$event" | sed -n 's/.*"trigger"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
present="no"; [ -r "$dir/SESSION-STATE.md" ] && present="yes"
mkdir -p "$(dirname "$log")" 2>/dev/null || true
printf 'compaction-checkpoint trigger=%s state_present=%s\n' "${trigger:-unknown}" "$present" >>"$log" 2>/dev/null || true
exit 0
