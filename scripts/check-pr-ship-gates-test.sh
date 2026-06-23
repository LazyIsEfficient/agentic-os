#!/usr/bin/env bash
# check-pr-ship-gates-test.sh — fixture tests for ship-gate checkbox logic.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$REPO/scripts/check-pr-ship-gates.sh"

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; exit 1; }

BODY_OK=$'- [x] code-reviewer — dispatched\n- [x] security-reviewer — dispatched'
BODY_NO_SEC='- [x] code-reviewer'
BODY_LIB_OK=$'- [x] code-reviewer\n- [x] security-reviewer\n- [x] library-reviewer'

if SHIP_GATES_CHANGED_FILES="install.sh" PR_BODY="$BODY_OK" bash "$GATE"; then
  pass "code change + both reviewers"
else
  fail "code change + both reviewers"
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

if SHIP_GATES_CHANGED_FILES=".claude/skills/session-state/SKILL.md" PR_BODY="$BODY_LIB_OK" bash "$GATE"; then
  pass "skill SKILL.md + all reviewers"
else
  fail "skill SKILL.md + all reviewers"
fi

if SHIP_GATES_CHANGED_FILES=".claude/skills/session-state/SKILL.md" PR_BODY='- [x] library-reviewer' bash "$GATE" 2>/dev/null; then
  fail "skill SKILL.md library-only should trip (needs code+security)"
else
  pass "skill SKILL.md library-only trips"
fi

if SHIP_GATES_CHANGED_FILES=".claude/skills/session-state/SKILL.md" PR_BODY="$BODY_NO_SEC" bash "$GATE" 2>/dev/null; then
  fail "skill SKILL.md missing security-reviewer should trip"
else
  pass "skill SKILL.md missing security-reviewer trips"
fi

echo "check-pr-ship-gates-test: OK"
