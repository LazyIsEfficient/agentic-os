#!/usr/bin/env bash
# gate-plan-lib.sh — shared path classification and checkbox list for the gate DAG.
# Sourced by gate-plan.sh and check-pr-ship-gates.sh. Do not execute directly.

gate_plan_reset() {
  GATE_IS_CODE_CHANGE=false
  GATE_IS_SENSITIVE=false
  GATE_IS_LIBRARY=false
  GATE_HAS_DATA_MODEL=false
  GATE_SKIP_DOCS_ONLY=true
  GATE_WAVE_1=()
  GATE_WAVE_2=()
  GATE_CHECKBOXES=()
}

gate_plan_normalize_changed() {
  local raw="${1:-}"
  if [[ "$raw" == *$'\n'* ]]; then
    printf '%s' "$raw"
  elif [[ "$raw" == *" "* ]]; then
    printf '%s' "${raw// /$'\n'}"
  else
    printf '%s' "$raw"
  fi
}

gate_plan_classify_paths() {
  local changed
  changed="$(gate_plan_normalize_changed "${1:-}")"
  gate_plan_reset

  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    case "$f" in
      .claude/skills/*|.claude/agents/*) GATE_IS_LIBRARY=true ;;
    esac
    case "$f" in
      install.sh|install.ps1) GATE_IS_SENSITIVE=true ;;
      assets/consumer/*) GATE_IS_SENSITIVE=true ;;
      .claude/hooks/*) GATE_IS_SENSITIVE=true ;;
      SECURITY.md) GATE_IS_SENSITIVE=true ;;
      scripts/lib/install-hook-settings.sh) GATE_IS_SENSITIVE=true ;;
      scripts/validate.sh|scripts/validate-test.sh) GATE_IS_SENSITIVE=true ;;
      scripts/release.sh) GATE_IS_SENSITIVE=true ;;
      .github/workflows/*) GATE_IS_SENSITIVE=true ;;
    esac
    case "$f" in
      DATA_MODEL.md) GATE_IS_CODE_CHANGE=true; GATE_HAS_DATA_MODEL=true; continue ;;
      *.md|LICENSE|NOTICE) continue ;;
      docs/*) continue ;;
      eval/metrics/runs/*) continue ;;
      .claude/memory/*) continue ;;
    esac
    GATE_IS_CODE_CHANGE=true
  done <<< "$changed"

  if [[ "$GATE_IS_CODE_CHANGE" == true || "$GATE_IS_LIBRARY" == true || "$GATE_IS_SENSITIVE" == true ]]; then
    GATE_SKIP_DOCS_ONLY=false
  fi
}

gate_plan_build_waves() {
  GATE_WAVE_1=()
  GATE_WAVE_2=()
  GATE_CHECKBOXES=()

  if [[ "$GATE_SKIP_DOCS_ONLY" == true ]]; then
    return 0
  fi

  if [[ "$GATE_IS_CODE_CHANGE" == true || "$GATE_IS_LIBRARY" == true ]]; then
    GATE_WAVE_1+=("code-reviewer")
  fi
  if [[ "$GATE_IS_CODE_CHANGE" == true || "$GATE_IS_LIBRARY" == true || "$GATE_IS_SENSITIVE" == true ]]; then
    GATE_WAVE_1+=("security-reviewer")
    GATE_WAVE_1+=("data-model-documenter")
  fi
  if [[ "$GATE_IS_LIBRARY" == true ]]; then
    GATE_WAVE_1+=("library-reviewer")
  fi
  if [[ "$GATE_HAS_DATA_MODEL" == true ]]; then
    GATE_WAVE_2+=("data-model-verifier")
  fi

  local agent
  for agent in "${GATE_WAVE_1[@]}"; do
    GATE_CHECKBOXES+=("$agent")
  done
  if ((${#GATE_WAVE_2[@]} > 0)); then
    for agent in "${GATE_WAVE_2[@]}"; do
      GATE_CHECKBOXES+=("$agent")
    done
  fi
}

gate_plan_run() {
  gate_plan_classify_paths "$1"
  gate_plan_build_waves
}
