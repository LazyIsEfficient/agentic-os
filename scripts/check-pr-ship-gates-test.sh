#!/usr/bin/env bash
# check-pr-ship-gates-test.sh — fixture tests for ship-gate checkbox logic.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$REPO/scripts/check-pr-ship-gates.sh"

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; exit 1; }

BODY_OK=$'- [x] code-reviewer — dispatched\n- [x] security-reviewer — dispatched'
BODY_NO_SEC='- [x] code-reviewer'

if SHIP_GATES_CHANGED_FILES="install.sh" PR_BODY="$BODY_OK" bash "$GATE"; then
  pass "sensitive file + both reviewers"
else
  fail "sensitive file + both reviewers"
fi

if SHIP_GATES_CHANGED_FILES="install.sh" PR_BODY="$BODY_NO_SEC" bash "$GATE" 2>/dev/null; then
  fail "missing security-reviewer should trip"
else
  pass "missing security-reviewer trips"
fi

if SHIP_GATES_CHANGED_FILES="README.md" PR_BODY="$BODY_OK" bash "$GATE"; then
  pass "docs-only skip"
else
  fail "docs-only skip"
fi

echo "check-pr-ship-gates-test: OK"
