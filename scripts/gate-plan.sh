#!/usr/bin/env bash
# gate-plan.sh — Tier 0 gate planner: diff paths → waves + PR checkboxes.
#
# Usage (CI fixture):
#   SHIP_GATES_CHANGED_FILES="src/a.ts DATA_MODEL.md" bash scripts/gate-plan.sh
#
# Usage (local git diff):
#   bash scripts/gate-plan.sh --base origin/main --head HEAD
#
# Flags:
#   --json          Machine-readable JSON on stdout
#   --checkboxes    One required agent label per line (for scripting)
#   --skip-docs-only  Print true|false only (exit 0)
#
# Exit 0 always (planner does not gate); check-pr-ship-gates.sh enforces checkboxes.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/gate-plan-lib.sh
source "$REPO_ROOT/scripts/lib/gate-plan-lib.sh"

BASE_SHA=""
HEAD_SHA=""
FORMAT="text"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE_SHA="$2"; shift 2 ;;
    --head) HEAD_SHA="$2"; shift 2 ;;
    --json) FORMAT=json; shift ;;
    --checkboxes) FORMAT=checkboxes; shift ;;
    --skip-docs-only) FORMAT=skip; shift ;;
    -h|--help)
      sed -n '2,16p' "$0"
      exit 0
      ;;
    *) echo "usage: gate-plan.sh [--base SHA] [--head SHA] [--json|--checkboxes|--skip-docs-only]" >&2; exit 1 ;;
  esac
done

if [[ -n "${SHIP_GATES_CHANGED_FILES:-}" ]]; then
  changed="$SHIP_GATES_CHANGED_FILES"
elif [[ -n "$BASE_SHA" && -n "$HEAD_SHA" ]]; then
  changed="$(git -C "$REPO_ROOT" diff --name-only "$BASE_SHA" "$HEAD_SHA" 2>/dev/null || true)"
else
  BASE_SHA="$(git -C "$REPO_ROOT" rev-parse origin/main 2>/dev/null || git -C "$REPO_ROOT" rev-parse main)"
  HEAD_SHA="$(git -C "$REPO_ROOT" rev-parse HEAD)"
  changed="$(git -C "$REPO_ROOT" diff --name-only "$BASE_SHA" "$HEAD_SHA" 2>/dev/null || true)"
fi

gate_plan_run "$changed"

case "$FORMAT" in
  skip)
    if [[ "$GATE_SKIP_DOCS_ONLY" == true ]]; then echo "true"; else echo "false"; fi
    ;;
  checkboxes)
    if [[ "$GATE_SKIP_DOCS_ONLY" == true ]]; then
      exit 0
    fi
    printf '%s\n' "${GATE_CHECKBOXES[@]}"
    ;;
  json)
    w1="${GATE_WAVE_1[*]-}"
    w2="${GATE_WAVE_2[*]-}"
    cbs="${GATE_CHECKBOXES[*]-}"
    python3 - "$GATE_SKIP_DOCS_ONLY" "$GATE_IS_CODE_CHANGE" "$GATE_IS_SENSITIVE" "$GATE_IS_LIBRARY" "$GATE_HAS_DATA_MODEL" "$w1" "$w2" "$cbs" <<'PY'
import json, sys
skip, code, sens, lib, dm = sys.argv[1:6]
w1 = sys.argv[6].split() if sys.argv[6] else []
w2 = sys.argv[7].split() if sys.argv[7] else []
cbs = sys.argv[8].split() if sys.argv[8] else []
print(json.dumps({
    "skip_docs_only": skip == "true",
    "is_code_change": code == "true",
    "is_sensitive": sens == "true",
    "is_library": lib == "true",
    "has_data_model": dm == "true",
    "wave_1": w1,
    "wave_2": w2,
    "checkboxes": cbs,
}, indent=2))
PY
    ;;
  text)
    if [[ -z "$changed" ]]; then
      echo "gate-plan: no file changes — skip all gates"
      exit 0
    fi
    echo "skip_docs_only=$GATE_SKIP_DOCS_ONLY"
    echo "is_code_change=$GATE_IS_CODE_CHANGE"
    echo "is_sensitive=$GATE_IS_SENSITIVE"
    echo "is_library=$GATE_IS_LIBRARY"
    echo "has_data_model=$GATE_HAS_DATA_MODEL"
    if [[ "$GATE_SKIP_DOCS_ONLY" == true ]]; then
      echo "wave_1="
      echo "wave_2="
      echo "checkboxes="
      exit 0
    fi
    echo "wave_1=${GATE_WAVE_1[*]-}"
    if ((${#GATE_WAVE_2[@]} > 0)); then
      echo "wave_2=${GATE_WAVE_2[*]}"
    else
      echo "wave_2="
    fi
    echo "checkboxes=${GATE_CHECKBOXES[*]-}"
    ;;
esac
