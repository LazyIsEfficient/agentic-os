#!/usr/bin/env bash
# check-pr-ship-gates.sh — Tier 0 PR gate: reviewer checkboxes + sensitive-path rules.
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
  changed="$(git -C "$REPO_ROOT" diff --name-only "$BASE_SHA" "$HEAD_SHA" 2>/dev/null || true)"
fi
if [[ -z "$changed" ]]; then
  echo "check-pr-ship-gates: no file changes between $BASE_SHA and $HEAD_SHA — OK"
  exit 0
fi

# Code change = anything outside pure doc-only allowlist (still requires code-reviewer).
is_code_change=false
is_sensitive=false
is_library=false

while IFS= read -r f; do
  [[ -n "$f" ]] || continue
  case "$f" in
    *.md|*.mdc|LICENSE|NOTICE) continue ;;
    docs/*) continue ;;
    eval/metrics/runs/*) continue ;;
    .claude/memory/*) continue ;;
  esac
  is_code_change=true
  case "$f" in
    install.sh|install.ps1|install-cursor.sh|install-cursor.ps1) is_sensitive=true ;;
    assets/consumer/*) is_sensitive=true ;;
    .claude/hooks/*|.cursor/hooks/*) is_sensitive=true ;;
    SECURITY.md) is_sensitive=true ;;
    scripts/lib/install-hook-settings.sh) is_sensitive=true ;;
    scripts/release.sh) is_sensitive=true ;;
    .github/workflows/*) is_sensitive=true ;;
  esac
  case "$f" in
    .claude/skills/*|.claude/agents/*) is_library=true ;;
  esac
done <<< "$changed"

if [[ "$is_code_change" == false ]]; then
  echo "check-pr-ship-gates: docs-only diff — OK"
  exit 0
fi

if [[ -z "$PR_BODY" ]]; then
  echo "FAIL [ship-gates]: code change requires PR body with reviewer checkboxes (PR_BODY unset)" >&2
  exit 1
fi

body_check() {
  local label="$1"
  printf '%s' "$PR_BODY" | grep -qiE "^[[:space:]]*-[[:space:]]*\[[xX]\][[:space:]].*${label}"
}

fail() {
  echo "FAIL [ship-gates]: $1" >&2
  echo "Edit the PR description — template: .github/pull_request_template.md" >&2
  exit 1
}

if ! body_check 'code-reviewer'; then
  fail "check [x] code-reviewer (readonly Task dispatched; Tier 0/1 findings addressed)"
fi

if [[ "$is_sensitive" == true ]] && ! body_check 'security-reviewer'; then
  fail "sensitive paths in diff — check [x] security-reviewer (hook/install/SECURITY/workflow)"
fi

if [[ "$is_library" == true ]] && ! body_check 'library-reviewer'; then
  fail "library paths in diff — check [x] library-reviewer"
fi

echo "check-pr-ship-gates: OK (code=$is_code_change sensitive=$is_sensitive library=$is_library)"
exit 0
