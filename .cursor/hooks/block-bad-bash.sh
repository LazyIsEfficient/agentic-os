#!/usr/bin/env bash
# Cursor beforeShellExecution — block-bad-bash ergonomics nudge.
# Mirrors .claude/hooks/block-bad-bash.sh. Nudges away from two patterns that
# reliably trigger permission prompts:
#   1. `cd <path> && git ...`   — use `git -C <path> ...` instead
#   2. 3+ commands chained with `&&` — split into separate shell calls
#
# NOT A SECURITY CONTROL. Best-effort UX nudge, trivially bypassable.
# See SECURITY.md and scripts/block-bad-bash-test-cursor.sh.
set -uo pipefail

input="$(cat)"

allow_silent() {
  printf '%s\n' '{"permission":"allow"}'
  exit 0
}

deny_with() {
  local msg="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg perm deny --arg msg "$msg" '{permission: $perm, agent_message: $msg}'
  else
    printf '{"permission":"deny","agent_message":"%s"}\n' "$msg"
  fi
  exit 0
}

if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.command // empty' 2>/dev/null)"
else
  cmd="$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
fi
[ -n "$cmd" ] || allow_silent

# Rule 1: `cd <subdir> && git ...`
if printf '%s' "$cmd" | grep -qE '^[[:space:]]*cd[[:space:]]+[^&]+&&[[:space:]]*git([[:space:]]|$)'; then
  deny_with 'block-bad-bash: Pattern `cd <path> && git ...` triggers a permission prompt. Use `git -C <path> <args>` instead, and split into separate shell calls (run independent ones in parallel).'
fi

# Rule 2: 3+ commands chained with `&&` (i.e. 2+ `&&` operators)
amp_count=$(printf '%s' "$cmd" | { grep -oE '&&' || true; } | wc -l | tr -d '[:space:]')
if [ "${amp_count:-0}" -ge 2 ]; then
  deny_with "block-bad-bash: Long \`&&\` chain ($((amp_count + 1)) commands). Long chains trigger permission prompts. Split into separate shell calls. Independent calls should be issued in parallel in a single message."
fi

allow_silent
