#!/usr/bin/env bash
# install-paths-test.sh — deterministic path resolution for shipped skill scripts.
# Exercises the PROJ → ~/.claude/skills fallback chain documented in
# .claude/skills/findings-ledger/references/install-paths.md
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
REL="findings-ledger/scripts/ledger.py"
TMP_BASE="$REPO/.tmp/install-paths-test"
mkdir -p "$TMP_BASE"
P=0
F=0

ok() { printf 'PASS  %s\n' "$1"; P=$((P + 1)); }
no() { printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F + 1)); }

resolve_ledger() {
  local proj="${CLAUDE_PROJECT_DIR:-.}"
  local ledger="$proj/.claude/skills/$REL"
  if [ ! -f "$ledger" ]; then
    ledger="${HOME}/.claude/skills/$REL"
  fi
  printf '%s' "$ledger"
}

# 1 — repo checkout (project-first)
export CLAUDE_PROJECT_DIR="$REPO"
export HOME="$TMP_BASE/empty-home"
mkdir -p "$HOME"
got="$(resolve_ledger)"
exp="$REPO/.claude/skills/$REL"
[ "$got" = "$exp" ] && ok "project .claude/skills wins in repo checkout" || no "repo checkout" "got=$got want=$exp"

# 2 — Claude global fallback (no project tree)
empty="$(mktemp -d "$TMP_BASE/empty-proj-XXXXXX")"
export CLAUDE_PROJECT_DIR="$empty"
fake_home="$(mktemp -d "$TMP_BASE/claude-home-XXXXXX")"
mkdir -p "$fake_home/.claude/skills/findings-ledger/scripts"
cp "$REPO/.claude/skills/findings-ledger/scripts/ledger.py" "$fake_home/.claude/skills/findings-ledger/scripts/"
export HOME="$fake_home"
got="$(resolve_ledger)"
exp="$fake_home/.claude/skills/$REL"
[ "$got" = "$exp" ] && ok "falls back to ~/.claude/skills when project has no .claude tree" || no "claude global" "got=$got want=$exp"

rm -rf "$empty" "$fake_home"
unset CLAUDE_PROJECT_DIR HOME

echo "install-paths-test: $P passed, $F failed."
[ "$F" -eq 0 ]
