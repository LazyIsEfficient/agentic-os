#!/usr/bin/env bash
# block-bad-bash-test.sh — deterministic test of the block-bad-bash PreToolUse
# nudge (.claude/hooks/block-bad-bash.sh). Proves: Rule 1 (`cd <path> && git …`)
# and Rule 2 (3+ `&&`-chained commands) exit 2 with a nudge; ordinary and
# single-`&&` commands, the recommended `git -C`, and `cd && <non-git>` pass
# (exit 0). No live Claude needed — the hook only reads .tool_input.command from
# stdin. The hook is a no-op without jq (matches its own fail-open), so this test
# skips cleanly when jq is unavailable.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO/.claude/hooks/block-bad-bash.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "block-bad-bash-test: jq not found — hook is a no-op without jq; skipping" >&2
  exit 0
fi

P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }
# rc <command>: prints the hook's exit code for that command string.
# JSON is built with jq (safe for any metacharacters in the command).
rc(){ jq -cn --arg c "$1" '{tool_input:{command:$c}}' | bash "$HOOK" >/dev/null 2>&1; printf '%s' "$?"; }
blocks(){ [ "$(rc "$2")" = "2" ] && ok "$1" || no "$1" "expected block (exit 2) for: $2"; }
allows(){ [ "$(rc "$2")" = "0" ] && ok "$1" || no "$1" "expected allow (exit 0) for: $2"; }

# Rule 1 — `cd <path> && git …`
blocks "Rule1 blocks cd && git"               'cd foo && git status'
blocks "Rule1 blocks cd nested && git"        'cd sub/dir && git commit -m x'
# Rule 2 — 3+ commands chained with && (>= 2 operators)
blocks "Rule2 blocks 3-command && chain"      'mkdir a && cd a && touch b'
blocks "Rule2 blocks long chain (no git)"     'a && b && c && d'
# Negatives — must pass (exit 0)
allows "allows recommended git -C form"       'git -C foo status'
allows "allows plain command"                 'echo hello'
allows "allows single && (2 commands)"        'make && ./run'
allows "allows cd && non-git command"         'cd foo && ls'

printf 'block-bad-bash-test: %d passed, %d failed.\n' "$P" "$F"
[ "$F" -eq 0 ]
