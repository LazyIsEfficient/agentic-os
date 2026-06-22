#!/usr/bin/env bash
# S0 spike — PreCompact hook: flush a sentinel to disk to prove it fired
# (this is the mechanism Slice 1 uses to checkpoint SESSION-STATE.md before
# compaction drifts awareness).
set -uo pipefail
dir="${CLAUDE_PROJECT_DIR:-.}"
printf 'S0_SENTINEL_PRECOMPACT_FIRED %s\n' "$(cat)" >> "$dir/.claude/precompact-evidence.txt"
exit 0
