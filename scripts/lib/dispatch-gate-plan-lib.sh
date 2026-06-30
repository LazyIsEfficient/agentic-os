#!/usr/bin/env bash
# dispatch-gate-plan-lib.sh — classify changed paths → required reviewer Tasks.
#
# This is the RUNTIME twin of scripts/lib/gate-plan-lib.sh (the CI ship-gate
# planner). It MIRRORS that classifier exactly so the stop-hook's reviewer demand
# agrees with the PR ship-gate checkboxes — a path that CI considers code/library/
# sensitive must trigger the same reviewer set at runtime, and a docs-only diff
# must skip reviewers in both. Keep the two in sync when either changes.
#
# Sourced by dispatch-gate hooks and tests. Do not execute directly.

dispatch_plan_reset() {
  DISPATCH_PLAN_IS_CODE_CHANGE=false
  DISPATCH_PLAN_IS_SENSITIVE=false
  DISPATCH_PLAN_IS_LIBRARY=false
  DISPATCH_PLAN_HAS_DATA_MODEL=false
  DISPATCH_PLAN_SKIP_DOCS_ONLY=true
  DISPATCH_PLAN_WAVE_1=()
  DISPATCH_PLAN_WAVE_2=()
}

dispatch_plan_normalize_changed() {
  local raw="${1:-}"
  if [[ "$raw" == *$'\n'* ]]; then
    printf '%s' "$raw"
  elif [[ "$raw" == *" "* ]]; then
    printf '%s' "${raw// /$'\n'}"
  else
    printf '%s' "$raw"
  fi
}

dispatch_plan_classify_paths() {
  local changed
  changed="$(dispatch_plan_normalize_changed "${1:-}")"
  dispatch_plan_reset

  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    # Non-reviewable churn skipped FIRST so it can never be reclassified as code
    # below: the dispatch ledger, machine-local memory, and eval metric runs.
    case "$f" in
      .cursor/dispatch-ledger.json) continue ;;
      .claude/memory/*) continue ;;
      eval/metrics/runs/*) continue ;;
    esac
    case "$f" in
      .claude/skills/*|.claude/agents/*) DISPATCH_PLAN_IS_LIBRARY=true ;;
    esac
    case "$f" in
      install.sh|install.ps1|install-cursor.sh|install-cursor.ps1) DISPATCH_PLAN_IS_SENSITIVE=true ;;
      assets/consumer/*) DISPATCH_PLAN_IS_SENSITIVE=true ;;
      .claude/hooks/*|.cursor/hooks/*) DISPATCH_PLAN_IS_SENSITIVE=true ;;
      .cursor/dispatch-gate.json|.cursor/hooks.json) DISPATCH_PLAN_IS_SENSITIVE=true ;;
      scripts/lib/dispatch-gate*|scripts/dispatch-gate*) DISPATCH_PLAN_IS_SENSITIVE=true ;;
      SECURITY.md) DISPATCH_PLAN_IS_SENSITIVE=true ;;
      scripts/lib/install-hook-settings.sh) DISPATCH_PLAN_IS_SENSITIVE=true ;;
      scripts/validate.sh|scripts/validate-test.sh) DISPATCH_PLAN_IS_SENSITIVE=true ;;
      scripts/release.sh) DISPATCH_PLAN_IS_SENSITIVE=true ;;
      .github/workflows/*) DISPATCH_PLAN_IS_SENSITIVE=true ;;
    esac
    # DATA_MODEL.md is a code-equivalent change AND triggers the Wave 2 verifier.
    case "$f" in
      DATA_MODEL.md) DISPATCH_PLAN_IS_CODE_CHANGE=true; DISPATCH_PLAN_HAS_DATA_MODEL=true; continue ;;
    esac
    # Pure docs/markup do not require code review on their own. (SKILL.md / agent
    # .md still set IS_LIBRARY above before being skipped here.)
    case "$f" in
      *.md|*.mdc|LICENSE|NOTICE) continue ;;
      docs/*) continue ;;
    esac
    DISPATCH_PLAN_IS_CODE_CHANGE=true
  done <<< "$changed"

  if [[ "$DISPATCH_PLAN_IS_CODE_CHANGE" == true || "$DISPATCH_PLAN_IS_LIBRARY" == true || "$DISPATCH_PLAN_IS_SENSITIVE" == true ]]; then
    DISPATCH_PLAN_SKIP_DOCS_ONLY=false
  fi
}

dispatch_plan_build_waves() {
  DISPATCH_PLAN_WAVE_1=()
  DISPATCH_PLAN_WAVE_2=()

  if [[ "$DISPATCH_PLAN_SKIP_DOCS_ONLY" == true ]]; then
    return 0
  fi

  if [[ "$DISPATCH_PLAN_IS_CODE_CHANGE" == true || "$DISPATCH_PLAN_IS_LIBRARY" == true ]]; then
    DISPATCH_PLAN_WAVE_1+=("code-reviewer")
  fi
  if [[ "$DISPATCH_PLAN_IS_CODE_CHANGE" == true || "$DISPATCH_PLAN_IS_LIBRARY" == true || "$DISPATCH_PLAN_IS_SENSITIVE" == true ]]; then
    DISPATCH_PLAN_WAVE_1+=("security-reviewer")
    DISPATCH_PLAN_WAVE_1+=("data-model-documenter")
  fi
  if [[ "$DISPATCH_PLAN_IS_LIBRARY" == true ]]; then
    DISPATCH_PLAN_WAVE_1+=("library-reviewer")
  fi
  if [[ "$DISPATCH_PLAN_HAS_DATA_MODEL" == true ]]; then
    DISPATCH_PLAN_WAVE_2+=("data-model-verifier")
  fi
}

dispatch_plan_run() {
  dispatch_plan_classify_paths "$1"
  dispatch_plan_build_waves
}

dispatch_plan_missing_reviews() {
  local completed_csv="${1:-}"
  local required agent
  dispatch_plan_missing=()
  local agents=()
  if ((${#DISPATCH_PLAN_WAVE_1[@]} > 0)); then
    agents+=("${DISPATCH_PLAN_WAVE_1[@]}")
  fi
  if ((${#DISPATCH_PLAN_WAVE_2[@]} > 0)); then
    agents+=("${DISPATCH_PLAN_WAVE_2[@]}")
  fi
  for agent in "${agents[@]}"; do
    case ",$completed_csv," in
      *",$agent,"*) continue ;;
    esac
    dispatch_plan_missing+=("$agent")
  done
}
