#!/usr/bin/env bash
# PreCompact hook — checkpoint just before context is compressed (the exact
# boundary where awareness drifts). Reliable action: append a dated marker to a
# gitignored log so we can SEE that compaction fired and that the durable doc was
# present. Re-surfacing the state into post-compaction context is already handled
# by the SessionStart/UserPromptSubmit hooks; injecting from PreCompact itself
# depends on its output contract, confirmed as Slice 1's first follow-up.
set -uo pipefail
dir="${CLAUDE_PROJECT_DIR:-.}"
log="$dir/.claude/session-state.checkpoints"
event="$(cat)"
trigger="$(printf '%s' "$event" | sed -n 's/.*"trigger"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
present="no"; [ -r "$dir/SESSION-STATE.md" ] && present="yes"
printf 'compaction-checkpoint trigger=%s state_present=%s\n' "${trigger:-unknown}" "$present" >> "$log"
exit 0
