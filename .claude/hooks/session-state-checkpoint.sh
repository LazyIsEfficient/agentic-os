#!/usr/bin/env bash
# PreCompact hook — checkpoint just before context is compressed (the exact
# boundary where awareness drifts). Reliable action: append a dated marker to a
# gitignored log so we can SEE that compaction fired and that the durable doc was
# present. Re-surfacing the state into post-compaction context is already handled
# by the SessionStart/UserPromptSubmit hooks; injecting from PreCompact itself
# depends on its output contract, confirmed as Slice 1's first follow-up.
set -uo pipefail
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  dir="$CLAUDE_PROJECT_DIR"
  checkpoint_dir="$dir/.claude"
elif command -v git >/dev/null 2>&1 && git rev-parse --show-toplevel >/dev/null 2>&1; then
  dir="$(git rev-parse --show-toplevel)"
  checkpoint_dir="$dir/.codex"
else
  dir="$(pwd)"
  checkpoint_dir="$dir/.codex"
fi
log="$checkpoint_dir/session-state.checkpoints"
event="$(cat)"
trigger="$(printf '%s' "$event" | sed -n 's/.*"trigger"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
present="no"; [ -r "$dir/SESSION-STATE.md" ] && present="yes"
if ! mkdir -p "$checkpoint_dir"; then
  echo "session-state-checkpoint: cannot create checkpoint directory: $checkpoint_dir" >&2
  exit 1
fi
if ! printf 'compaction-checkpoint trigger=%s state_present=%s\n' "${trigger:-unknown}" "$present" >> "$log"; then
  echo "session-state-checkpoint: cannot write checkpoint: $log" >&2
  exit 1
fi
exit 0
