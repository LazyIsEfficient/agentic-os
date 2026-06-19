#!/usr/bin/env bash
# session-state.sh — deterministic writer for the live SESSION-STATE.md.
#
# The /state command calls THIS instead of hand-editing the file, so entries are
# captured by a script rather than by the model remembering to edit a file
# (attention-dependent editing is the failure mode the awareness harness removes).
#
# Usage:
#   session-state.sh init                  # create SESSION-STATE.md from template
#   session-state.sh show                  # print current state
#   session-state.sh constraint "<text>"   # add a hard constraint
#   session-state.sh decision   "<text>"   # add a dated settled decision
#   session-state.sh infra      "<text>"   # add an existing-infra (survey) finding
#   session-state.sh thread     "<text>"   # add an open thread / next step
#
# Pure Bash + coreutils. Repo root resolves from CLAUDE_PROJECT_DIR or this
# script's location, so it works in-session and from install targets.
set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LIVE="$ROOT/SESSION-STATE.md"
TPL="$ROOT/SESSION-STATE.template.md"

usage() { echo "usage: session-state.sh {init|show|constraint|decision|infra|thread|drop} [<text>]" >&2; exit 2; }

ensure() {
  if [ ! -f "$LIVE" ]; then
    [ -f "$TPL" ] || { echo "session-state.sh: no SESSION-STATE.md and no template at $TPL" >&2; exit 1; }
    cp "$TPL" "$LIVE"
  fi
}

append_under() {  # $1 = section heading text (without '## '), $2 = full bullet line
  ensure
  local heading="## $1" bullet="$2"
  if ! grep -qF -- "$heading" "$LIVE"; then
    echo "session-state.sh: section '$heading' not found in $LIVE (corrupted? re-init)" >&2
    exit 1
  fi
  # Pass the bullet via ENVIRON, not `awk -v`: -v processes backslash escapes,
  # which would mangle entry text containing '\' (e.g. a Windows path or a regex).
  SS_BULLET="$bullet" awk -v sec="$heading" '
    { print }
    $0 == sec && !inserted { print ENVIRON["SS_BULLET"]; inserted=1 }
  ' "$LIVE" > "$LIVE.tmp" && mv "$LIVE.tmp" "$LIVE"
  printf 'added under %s: %s\n' "$1" "$bullet"
}

drop_matching() {  # $1 = literal substring; remove bullet lines containing it
  ensure
  local needle="$1"
  # NOTE: awk stdout is redirected INTO the file, so the summary must go to
  # stderr — otherwise the "dropped N" line gets written into SESSION-STATE.md.
  SS_NEEDLE="$needle" awk '
    /^- / && index($0, ENVIRON["SS_NEEDLE"]) { dropped++; next }
    { print }
    END { printf "dropped %d bullet(s) matching: %s\n", dropped+0, ENVIRON["SS_NEEDLE"] > "/dev/stderr" }
  ' "$LIVE" > "$LIVE.tmp" && mv "$LIVE.tmp" "$LIVE"
}

cmd="${1:-}"; [ $# -gt 0 ] && shift || true
case "$cmd" in
  init) ensure; echo "initialized $LIVE" ;;
  show) ensure; cat "$LIVE" ;;
  drop) [ $# -ge 1 ] || usage; drop_matching "$*" ;;
  constraint) [ $# -ge 1 ] || usage; append_under "Constraints" "- $*" ;;
  decision)   [ $# -ge 1 ] || usage; append_under "Decisions" "- [$(date +%F)] $*" ;;
  infra)      [ $# -ge 1 ] || usage; append_under "Existing infrastructure" "- $*" ;;
  thread)     [ $# -ge 1 ] || usage; append_under "Open threads" "- $*" ;;
  *) usage ;;
esac
