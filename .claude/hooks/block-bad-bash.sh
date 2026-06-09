#!/usr/bin/env bash
# PreToolUse hook on Bash: nudges away from two patterns that reliably trigger
# permission prompts.
#   1. `cd <path> && git ...`   — use `git -C <path> ...` instead
#   2. 3+ commands chained with `&&` — split into separate Bash calls (parallel where independent)
# Exits 2 with stderr message so Claude sees feedback and rewrites the call.
#
# NOT A SECURITY CONTROL. This is a best-effort ergonomics/UX nudge, not a
# sandbox or a command filter. It does plain substring/regex matching, so it is
# trivially and intentionally bypassable — `;`, `|`, `pushd`, subshells, and
# command substitution all slip past, and Rule 2 counts `&&` literally so a
# quoted `echo "a && b"` can false-positive. That is acceptable: the only cost
# of a miss or a false hit is one extra (or one skipped) permission prompt.
# Do NOT extend this pattern-by-pattern chasing completeness — anything that
# needs real guarantees belongs in the permission system, not here.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

cmd=$(jq -r '.tool_input.command // ""')

# Rule 1: `cd <subdir> && git ...`
if printf '%s' "$cmd" | grep -qE '^[[:space:]]*cd[[:space:]]+[^&]+&&[[:space:]]*git([[:space:]]|$)'; then
  {
    echo "Blocked by .claude/hooks/block-bad-bash.sh:"
    echo "  Pattern \`cd <path> && git ...\` triggers a permission prompt."
    echo "  Use \`git -C <path> <args>\` instead, and split into separate Bash calls (run independent ones in parallel)."
  } >&2
  exit 2
fi

# Rule 2: 3+ commands chained with `&&` (i.e. 2+ `&&` operators)
amp_count=$(printf '%s' "$cmd" | { grep -oE '&&' || true; } | wc -l | tr -d '[:space:]')
if [ "${amp_count:-0}" -ge 2 ]; then
  {
    echo "Blocked by .claude/hooks/block-bad-bash.sh:"
    echo "  Long \`&&\` chain ($((amp_count + 1)) commands). Long chains trigger permission prompts."
    echo "  Split into separate Bash tool calls. Independent calls should be issued in parallel in a single message."
  } >&2
  exit 2
fi

exit 0
