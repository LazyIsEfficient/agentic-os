#!/usr/bin/env bash
#
# check-schema-match.sh — Tier-0 checker for kind=schema-match.
#
# Asserts that a text / HTML / Markdown artifact contains every required
# structural pattern. Generic by design so it serves both the claims-doc and the
# pod-deliverable output types: the caller supplies the required patterns.
#
# Each "pattern" is an extended-regex (grep -E) matched against the WHOLE file.
# PASS iff every required pattern matches at least once.
#
# Patterns come from EITHER:
#   - extra CLI args:    check-schema-match.sh <artifact> <pat1> <pat2> ...
#   - a sidecar file:    check-schema-match.sh <artifact> --patterns <file>
#       (one pattern per line; blank lines and #-comment lines ignored)
#   - a sidecar default: if no patterns are given, look for
#       <artifact>.patterns (file) or <dir>/.patterns (directory).
#
# If the artifact is a .json file and `jq` is available, patterns of the form
#   jq:<filter>  are evaluated as jq existence checks (truthy, non-null result)
# instead of regex — lets a JSON deliverable assert structural keys precisely.
#
# Contract: exit 0 = PASS (all patterns present), 1 = FAIL (>=1 missing),
#           2 = could-not-run (missing artifact / no patterns supplied).

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "SKIP check-schema-match: no artifact path given"
  exit 2
fi
ARTIFACT="$1"; shift || true

if [[ ! -e "$ARTIFACT" ]]; then
  echo "SKIP check-schema-match: artifact '$ARTIFACT' does not exist"
  exit 2
fi

# ── Gather the required patterns ─────────────────────────────────────────────
PATTERNS=()

read_sidecar() {
  # $1 = sidecar file. Append non-blank, non-comment lines as patterns.
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "${line//[[:space:]]/}" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    PATTERNS+=("$line")
  done < "$1"
}

if [[ "${1:-}" == "--patterns" ]]; then
  shift
  sidecar="${1:-}"
  if [[ -z "$sidecar" || ! -f "$sidecar" ]]; then
    echo "SKIP check-schema-match: --patterns given but sidecar '$sidecar' not found"
    exit 2
  fi
  read_sidecar "$sidecar"
elif [[ $# -gt 0 ]]; then
  PATTERNS=("$@")
else
  # No explicit patterns — try conventional sidecars.
  if [[ -f "$ARTIFACT" && -f "$ARTIFACT.patterns" ]]; then
    read_sidecar "$ARTIFACT.patterns"
  elif [[ -d "$ARTIFACT" && -f "$ARTIFACT/.patterns" ]]; then
    read_sidecar "$ARTIFACT/.patterns"
  fi
fi

if [[ ${#PATTERNS[@]} -eq 0 ]]; then
  echo "SKIP check-schema-match: no required patterns supplied (pass them as args, --patterns <file>, or a sidecar)"
  exit 2
fi

# Collect the files to search into an array. For a directory artifact, every
# file under it; for a single file, just it. Read NUL-delimited so paths with
# spaces or newlines survive intact (xargs/word-splitting would corrupt them).
SEARCH_FILES=()
if [[ -d "$ARTIFACT" ]]; then
  while IFS= read -r -d '' f; do SEARCH_FILES+=("$f"); done \
    < <(find "$ARTIFACT" -type f -print0)
else
  SEARCH_FILES=("$ARTIFACT")
fi

have_jq=0
command -v jq >/dev/null 2>&1 && have_jq=1
is_json=0
case "$ARTIFACT" in *.json) [[ -f "$ARTIFACT" ]] && is_json=1 ;; esac

# Patterns are attacker-influenced (they may come from a sidecar shipped with an
# untrusted artifact). Bound each grep so a pathological regex can't pin a CPU
# (ReDoS). `timeout` is optional; degrade to running grep unwrapped if absent.
# Use `env` (not an empty array) as the no-op prefix: expanding an empty array
# under `set -u` is an "unbound variable" error on bash 3.2 (macOS).
GREP_TIMEOUT="${SCHEMA_GREP_TIMEOUT:-10}"
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT=(timeout "$GREP_TIMEOUT")
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT=(gtimeout "$GREP_TIMEOUT")
else
  TIMEOUT=(env)
fi

MISSING=()
for pat in "${PATTERNS[@]}"; do
  if [[ "$pat" == jq:* ]]; then
    filter="${pat#jq:}"
    if [[ "$have_jq" -ne 1 || "$is_json" -ne 1 ]]; then
      echo "SKIP check-schema-match: jq-pattern '$pat' needs jq + a .json artifact (have_jq=$have_jq is_json=$is_json)"
      exit 2
    fi
    result="$(jq -r "$filter // empty" "$ARTIFACT" 2>/dev/null || true)"
    [[ -z "$result" ]] && MISSING+=("$pat")
  else
    # grep -E across the collected files. Properly quoted array expansion so
    # paths containing spaces/newlines are passed as single arguments.
    if ! "${TIMEOUT[@]}" grep -lE -- "$pat" "${SEARCH_FILES[@]}" >/dev/null 2>&1; then
      MISSING+=("$pat")
    fi
  fi
done

if [[ ${#MISSING[@]} -eq 0 ]]; then
  echo "PASS check-schema-match: all ${#PATTERNS[@]} required pattern(s) present in $(basename "$ARTIFACT")"
  exit 0
fi

echo "FAIL check-schema-match: ${#MISSING[@]}/${#PATTERNS[@]} pattern(s) missing in $(basename "$ARTIFACT") — first missing: '${MISSING[0]}'"
exit 1
