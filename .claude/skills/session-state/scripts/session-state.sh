#!/usr/bin/env bash
# session-state.sh — deterministic writer for the live SESSION-STATE.md.
#
# The /state command calls THIS instead of hand-editing the file, so entries are
# captured by a script rather than by the model remembering to edit a file
# (attention-dependent editing is the failure mode the awareness harness removes).
#
# Usage:
#   session-state.sh init                  # create SESSION-STATE.md from template
#   session-state.sh init-orchestrator     # init + default orchestrator constraints
#   session-state.sh show                  # print current state
#   session-state.sh constraint "<text>"   # add a hard constraint
#   session-state.sh decision   "<text>"   # add a dated settled decision
#   session-state.sh infra      "<text>"   # add an existing-infra (survey) finding
#   session-state.sh thread     "<text>"   # add an open thread / next step
#
# Pure Bash + coreutils. The live doc lives at the PROJECT ROOT (CLAUDE_PROJECT_DIR),
# gitignored and per-developer. The template is SKILL-LOCAL (ships
# resolved relative to this script — so `init` works on a consumer where only the
# skill directory is installed, not the repo root. This script lives at
# .claude/skills/session-state/scripts/, so the project-root fallback is four up.
set -euo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$SELF_DIR/../../../.." && pwd)}"
LIVE="$ROOT/SESSION-STATE.md"
TPL="$SELF_DIR/../assets/SESSION-STATE.template.md"

usage() { echo "usage: session-state.sh {init|init-orchestrator|show|constraint|decision|infra|thread|drop} [<text>]" >&2; exit 2; }

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
  init-orchestrator)
    ensure
    if grep -qF "Orchestrator-only:" "$LIVE"; then
      echo "orchestrator constraints already present in $LIVE"
      exit 0
    fi
    append_under "Constraints" "- Orchestrator-only: main thread must not Write/StrReplace/Delete/EditNotebook for implementation — dispatch Agent(engineer|domain specialist)"
    append_under "Constraints" "- Research >2 file reads/greps on main thread forbidden — dispatch Agent(explore|generalPurpose)"
    append_under "Constraints" "- Skills: identify on main thread; run multi-step skill workflows only in dispatched subagents (brief with skill procedure)"
    append_under "Constraints" "- Complete = Agent(code-reviewer) + Agent(security-reviewer) parallel readonly on current diff before saying done; library-reviewer when skills/agents change"
    echo "initialized $LIVE with orchestrator constraints"
    ;;
  show) ensure; cat "$LIVE" ;;
  drop) [ $# -ge 1 ] || usage; drop_matching "$*" ;;
  constraint) [ $# -ge 1 ] || usage; append_under "Constraints" "- $*" ;;
  decision)   [ $# -ge 1 ] || usage; append_under "Decisions" "- [$(date +%F)] $*" ;;
  infra)      [ $# -ge 1 ] || usage
  text="$*"
  if [[ "$text" =~ ^\[surveyed:[A-Za-z0-9._-]+\] ]]; then
    bullet="- $text"
  elif [[ "$text" =~ ^\[([A-Za-z0-9._-]+)\] ]]; then
    subj="${BASH_REMATCH[1]}"
    rest="${text#\[${subj}\]}"
    rest="${rest# }"
    bullet="- [surveyed:${subj}]${rest:+ $rest}"
  else
    first="${text%% *}"
    if [[ "$first" =~ ^[A-Za-z0-9._-]+$ ]]; then
      rest="${text#"$first"}"
      rest="${rest# }"
      bullet="- [surveyed:${first}]${rest:+ $rest}"
    else
      bullet="- $text"
    fi
  fi
  append_under "Existing infrastructure" "$bullet" ;;
  thread)     [ $# -ge 1 ] || usage; append_under "Open threads" "- $*" ;;
  *) usage ;;
esac
