#!/usr/bin/env bash
# check-pr-ship-gates-test.sh — fixture tests for ship-gate checkbox logic.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$REPO/scripts/check-pr-ship-gates.sh"

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; exit 1; }

BODY_OK=$'- [x] code-reviewer — dispatched\n- [x] security-reviewer — dispatched\n- [x] data-model-documenter — dispatched'
BODY_NO_SEC='- [x] code-reviewer\n- [x] data-model-documenter'
BODY_NO_DATA='- [x] code-reviewer\n- [x] security-reviewer'
BODY_LIB_OK=$'- [x] code-reviewer\n- [x] security-reviewer\n- [x] data-model-documenter\n- [x] library-reviewer'
BODY_DATA_MODEL_OK=$'- [x] code-reviewer\n- [x] security-reviewer\n- [x] data-model-documenter\n- [x] data-model-verifier'
BODY_SENSITIVE_OK=$'- [x] security-reviewer\n- [x] data-model-documenter'

if SHIP_GATES_CHANGED_FILES="install.sh" PR_BODY="$BODY_OK" bash "$GATE"; then
  pass "code change + all three agents"
else
  fail "code change + all three agents"
fi

if SHIP_GATES_CHANGED_FILES="install.sh" PR_BODY="$BODY_NO_SEC" bash "$GATE" 2>/dev/null; then
  fail "missing security-reviewer should trip"
else
  pass "missing security-reviewer trips"
fi

if SHIP_GATES_CHANGED_FILES="install.sh" PR_BODY="$BODY_NO_DATA" bash "$GATE" 2>/dev/null; then
  fail "missing data-model-documenter should trip"
else
  pass "missing data-model-documenter trips"
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
  fail "skill SKILL.md library-only should trip (needs code+security+data-model)"
else
  pass "skill SKILL.md library-only trips"
fi

if SHIP_GATES_CHANGED_FILES="DATA_MODEL.md" PR_BODY="$BODY_DATA_MODEL_OK" bash "$GATE"; then
  pass "DATA_MODEL.md requires verifier checkbox"
else
  fail "DATA_MODEL.md requires verifier checkbox"
fi

if SHIP_GATES_CHANGED_FILES="DATA_MODEL.md" PR_BODY="$BODY_OK" bash "$GATE" 2>/dev/null; then
  fail "DATA_MODEL.md missing verifier should trip"
else
  pass "DATA_MODEL.md missing verifier trips"
fi

if SHIP_GATES_CHANGED_FILES="DATA_MODEL.md" PR_BODY='- [x] not-data-model-documenter' bash "$GATE" 2>/dev/null; then
  fail "negated checkbox label should trip"
else
  pass "negated checkbox label trips"
fi

if SHIP_GATES_CHANGED_FILES="SECURITY.md" PR_BODY="$BODY_SENSITIVE_OK" bash "$GATE"; then
  pass "SECURITY.md sensitive-only skips code-reviewer"
else
  fail "SECURITY.md sensitive-only skips code-reviewer"
fi

if SHIP_GATES_CHANGED_FILES=".claude/skills/session-state/SKILL.md" PR_BODY="$BODY_NO_SEC" bash "$GATE" 2>/dev/null; then
  fail "skill SKILL.md missing security-reviewer should trip"
else
  pass "skill SKILL.md missing security-reviewer trips"
fi

echo "check-pr-ship-gates-test: OK"
