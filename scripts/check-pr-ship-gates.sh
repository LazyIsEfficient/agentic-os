#!/usr/bin/env bash
# check-pr-ship-gates.sh — Tier 0 PR gate: reviewer checkboxes via gate-plan-lib.sh.
#
# Usage (CI — pull_request):
#   PR_BODY set, BASE_SHA and HEAD_SHA set (or GITHUB_EVENT_PATH for file list)
#
# Usage (local):
#   bash scripts/check-pr-ship-gates.sh --base origin/main --head HEAD --body-file pr.md
#
# Exit 0 = gates satisfied; exit 1 = fail with message on stderr.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/gate-plan-lib.sh
source "$REPO_ROOT/scripts/lib/gate-plan-lib.sh"

BASE_SHA="${BASE_SHA:-}"
HEAD_SHA="${HEAD_SHA:-}"
PR_BODY="${PR_BODY:-}"
BODY_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE_SHA="$2"; shift 2 ;;
    --head) HEAD_SHA="$2"; shift 2 ;;
    --body-file) BODY_FILE="$2"; shift 2 ;;
    *) echo "usage: check-pr-ship-gates.sh [--base SHA] [--head SHA] [--body-file path]" >&2; exit 1 ;;
  esac
done

if [[ -n "$BODY_FILE" ]]; then
  PR_BODY="$(cat "$BODY_FILE")"
fi

if [[ -z "$BASE_SHA" || -z "$HEAD_SHA" ]]; then
  BASE_SHA="$(git -C "$REPO_ROOT" rev-parse origin/main 2>/dev/null || git -C "$REPO_ROOT" rev-parse main)"
  HEAD_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD)"
fi

if [[ -n "${SHIP_GATES_CHANGED_FILES:-}" ]]; then
  changed="$SHIP_GATES_CHANGED_FILES"
else
  if ! changed="$(git -C "$REPO_ROOT" diff --name-only "$BASE_SHA" "$HEAD_SHA" 2>/dev/null)"; then
    echo "check-pr-ship-gates: FAILED to compute diff between $BASE_SHA and $HEAD_SHA (fail-closed)" >&2
    exit 1
  fi
fi
if [[ -z "$changed" ]]; then
  echo "check-pr-ship-gates: no file changes between $BASE_SHA and $HEAD_SHA — OK"
  exit 0
fi

gate_plan_run "$changed"

if [[ "$GATE_SKIP_DOCS_ONLY" == true ]]; then
  echo "check-pr-ship-gates: docs-only diff — OK"
  exit 0
fi

if [[ -z "$PR_BODY" ]]; then
  echo "FAIL [ship-gates]: code change requires PR body with reviewer checkboxes (PR_BODY unset)" >&2
  echo "Run: bash scripts/gate-plan.sh — required checkboxes listed under checkboxes=" >&2
  exit 1
fi

body_check() {
  local label="$1"
  printf '%s' "$PR_BODY" | grep -qiE "^[[:space:]]*-[[:space:]]*\[[xX]\][[:space:]]+(\*\*)?${label}(\*\*)?([[:space:]]|$|—|-)"
}

fail() {
  echo "FAIL [ship-gates]: $1" >&2
  echo "Edit the PR description — template: .github/pull_request_template.md" >&2
  echo "Planner: bash scripts/gate-plan.sh (SHIP_GATES_CHANGED_FILES=…)" >&2
  exit 1
}

for agent in "${GATE_CHECKBOXES[@]}"; do
  if ! body_check "$agent"; then
    case "$agent" in
      code-reviewer) fail "check [x] code-reviewer (readonly Task dispatched; Tier 0/1 findings addressed)" ;;
      security-reviewer) fail "check [x] security-reviewer (readonly Task dispatched before marking done)" ;;
      data-model-documenter) fail "check [x] data-model-documenter (Task dispatched; updates DATA_MODEL.md at project root)" ;;
      data-model-verifier) fail "check [x] data-model-verifier (Wave 2 after DATA_MODEL.md changes; readonly Task)" ;;
      library-reviewer) fail "library paths in diff — check [x] library-reviewer" ;;
      *) fail "check [x] $agent" ;;
    esac
  fi
done

echo "check-pr-ship-gates: OK (code=$GATE_IS_CODE_CHANGE sensitive=$GATE_IS_SENSITIVE library=$GATE_IS_LIBRARY data_model=$GATE_HAS_DATA_MODEL)"
exit 0
