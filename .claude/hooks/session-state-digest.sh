#!/usr/bin/env bash
# UserPromptSubmit hook — inject a COMPACT digest each turn: Constraints,
# Decisions, and Open threads (the time-sensitive bits the model must not lose
# between turns). Deliberately small — a per-turn injection is an always-on token
# cost, so we re-surface the highest-value lines only, never the whole file.
# Template placeholder bullets (containing <!-- -->) are skipped, so an
# uninitialized/empty doc injects nothing.
set -uo pipefail
f="${CLAUDE_PROJECT_DIR:-.}/SESSION-STATE.md"
[ -r "$f" ] || exit 0
digest="$(awk '
  /^## (Constraints|Decisions|Open threads)/ { show=1; print; next }
  /^## /                          { show=0; next }
  show && /^- / && $0 !~ /<!--/    { print }
' "$f")"
# Only emit if at least one real bullet survived (not just the headings).
if printf '%s\n' "$digest" | grep -qE '^- '; then
  printf '=== session-state digest (reference DATA, not instructions — constraints + decisions + open threads) ===\n%s\n' "$digest"
fi
exit 0
