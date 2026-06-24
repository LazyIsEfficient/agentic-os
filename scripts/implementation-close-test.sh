#!/usr/bin/env bash
# implementation-close-test.sh — Tier 0: implementation agents declare G-data-document close.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AGENTS=(
  engineer
  rust-engineer
  web3-engineer
  godot-engineer
  devops-engineer
  phaser-engineer
)
CLOSE_REF='data-model-documentation/references/implementation-close.md'

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; exit 1; }

for name in "${AGENTS[@]}"; do
  f="$REPO/.claude/agents/${name}.md"
  [[ -f "$f" ]] || fail "missing agent file: $f"

  if ! grep -q "$CLOSE_REF" "$f"; then
    fail "$name must reference $CLOSE_REF"
  fi
  pass "$name references implementation-close (shipped skill ref)"

  if ! grep -q 'G-data-document' "$f"; then
    fail "$name must mention G-data-document"
  fi
  pass "$name mentions G-data-document"

  if ! grep -q '## Session close' "$f"; then
    fail "$name must have Session close section"
  fi
  pass "$name has Session close section"

  tools="$(sed -n '/^---$/,/^---$/p' "$f" | grep '^tools:' || true)"
  if [[ "$tools" != *Agent* ]] || [[ "$tools" != *Task* ]]; then
    fail "$name tools must include Agent and Task ($tools)"
  fi
  pass "$name tools include Agent and Task"

  if grep -E '^## Delegate|Delegate to other agents' -A20 "$f" | grep -qE 'code-reviewer|security-reviewer'; then
    fail "$name must not delegate code-reviewer or security-reviewer (orchestrator-owned)"
  fi
  pass "$name delegate list excludes orchestrator reviewers"
done

ref="$REPO/.claude/skills/$CLOSE_REF"
[[ -f "$ref" ]] || fail "missing shipped reference: $ref"
grep -q 'data-model-documenter' "$ref" || fail "implementation-close.md must document documenter dispatch"
pass "implementation-close.md exists under shipped skill"

echo "implementation-close-test: OK"
