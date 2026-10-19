#!/usr/bin/env bash
# gate-plan-test.sh — fixture tests for gate-plan.sh / gate-plan-lib.sh
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAN="$REPO/scripts/gate-plan.sh"

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; exit 1; }

assert_contains() {
  local haystack="$1" needle="$2" msg="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    fail "$msg (missing: $needle)"
  fi
}

assert_not_contains() {
  local haystack="$1" needle="$2" msg="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    fail "$msg (unexpected: $needle)"
  fi
}

out="$(SHIP_GATES_CHANGED_FILES="README.md" bash "$PLAN")"
if printf '%s' "$out" | grep -q 'skip_docs_only=true'; then
  pass "docs-only skip"
else
  fail "docs-only skip"
fi

out="$(SHIP_GATES_CHANGED_FILES="install.sh" bash "$PLAN")"
assert_contains "$out" "code-reviewer" "install.sh wave_1"
assert_contains "$out" "security-reviewer" "install.sh wave_1"
assert_contains "$out" "data-model-documenter" "install.sh wave_1"
assert_not_contains "$out" "library-reviewer" "install.sh no library"
assert_not_contains "$out" "data-model-verifier" "install.sh no verifier"

out="$(SHIP_GATES_CHANGED_FILES=".claude/skills/foo/SKILL.md" bash "$PLAN")"
assert_contains "$out" "library-reviewer" "library path"

out="$(SHIP_GATES_CHANGED_FILES="DATA_MODEL.md" bash "$PLAN")"
assert_contains "$out" "data-model-verifier" "DATA_MODEL wave_2"
assert_contains "$out" "wave_2=data-model-verifier" "DATA_MODEL wave_2 line"
assert_contains "$out" "code-reviewer" "DATA_MODEL wave_1 code-reviewer"
assert_contains "$out" "security-reviewer" "DATA_MODEL wave_1 security"
assert_contains "$out" "data-model-documenter" "DATA_MODEL wave_1 documenter"

out="$(SHIP_GATES_CHANGED_FILES="install.sh DATA_MODEL.md" bash "$PLAN")"
assert_contains "$out" "skip_docs_only=false" "space-separated multi-file"
assert_contains "$out" "data-model-verifier" "space-separated verifier"

out="$(SHIP_GATES_CHANGED_FILES="SECURITY.md" bash "$PLAN")"
assert_not_contains "$out" "wave_1=code-reviewer" "SECURITY sensitive-only no code-reviewer"
assert_contains "$out" "security-reviewer" "SECURITY security-reviewer"
assert_contains "$out" "data-model-documenter" "SECURITY documenter"

# #264: gating-logic markdown and workflows are library, not docs-only.
for f in .claude/commands/foo.md .claude/rules/foo.md .claude/references/foo.md .claude/workflows/foo.js CLAUDE.md AGENTS.md; do
  out="$(SHIP_GATES_CHANGED_FILES="$f" bash "$PLAN")"
  assert_contains "$out" "skip_docs_only=false" "$f not docs-only"
  assert_contains "$out" "is_library=true" "$f is_library"
  assert_contains "$out" "code-reviewer" "$f code-reviewer"
  assert_contains "$out" "security-reviewer" "$f security-reviewer"
  assert_contains "$out" "library-reviewer" "$f library-reviewer"
  pass "$f library"
done

for f in .claude/rules/review-tiers.md .claude/references/gate-dag.md .claude/commands/review-gate.md \
         .claude/references/review-verdict.md scripts/lib/gate-plan-lib.sh scripts/gate-plan.sh \
         scripts/check-pr-ship-gates.sh scripts/parse-verdict.sh .claude/hooks/foo.sh \
         CLAUDE.md AGENTS.md .claude/rules/subagent-dispatch.md scripts/gate-plan-test.sh \
         scripts/check-pr-ship-gates-test.sh; do
  out="$(SHIP_GATES_CHANGED_FILES="$f" bash "$PLAN")"
  assert_contains "$out" "is_sensitive=true" "$f sensitive"
  assert_contains "$out" "security-reviewer" "$f security-reviewer"
  pass "$f sensitive"
done

for f in .claude/commands/foo.md .claude/rules/foo.md; do
  out="$(SHIP_GATES_CHANGED_FILES="$f" bash "$PLAN")"
  assert_contains "$out" "is_sensitive=false" "$f non-gating file not sensitive"
done

out="$(SHIP_GATES_CHANGED_FILES="./.claude/rules/x.md" bash "$PLAN")"
assert_contains "$out" "is_library=true" "leading ./ normalised"
assert_contains "$out" "skip_docs_only=false" "leading ./ not docs-only"
pass "leading ./ normalised"

for f in README.md docs/guide.md CONTRIBUTING.md; do
  out="$(SHIP_GATES_CHANGED_FILES="$f" bash "$PLAN")"
  assert_contains "$out" "skip_docs_only=true" "$f still docs-only"
  pass "$f docs-only"
done

cbs="$(SHIP_GATES_CHANGED_FILES="install.sh" bash "$PLAN" --checkboxes | tr '\n' ' ')"
assert_contains "$cbs" "code-reviewer" "checkboxes install"
assert_not_contains "$cbs" "data-model-verifier" "checkboxes install no verifier"

cbs="$(SHIP_GATES_CHANGED_FILES="DATA_MODEL.md" bash "$PLAN" --checkboxes | tr '\n' ' ')"
assert_contains "$cbs" "data-model-verifier" "checkboxes DATA_MODEL verifier"

skip="$(SHIP_GATES_CHANGED_FILES="README.md" bash "$PLAN" --skip-docs-only)"
if [[ "$skip" == "true" ]]; then
  pass "skip-docs-only flag"
else
  fail "skip-docs-only flag"
fi

json="$(SHIP_GATES_CHANGED_FILES="DATA_MODEL.md" bash "$PLAN" --json)"
if printf '%s' "$json" | python3 -c "import json,sys; d=json.load(sys.stdin); assert d['has_data_model'] and 'data-model-verifier' in d['wave_2']"; then
  pass "json output"
else
  fail "json output"
fi

echo "gate-plan-test: OK"
