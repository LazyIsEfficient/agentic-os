#!/usr/bin/env bash
# Stop hook — Tier 0 review gate (issue #258). Blocks the end of a turn while a
# qualifying diff lacks captured reviewer verdicts for the current HEAD. Keys
# ONLY on reproducible artifacts: the changed-path set and the files
# review-verdict-capture.sh (SubagentStop) writes to .claude/reviews/. It never
# reads or judges LLM output itself.
#
# Flow:
#   - AGENTIC_OS_REVIEW_GATE=off in Claude Code's environment → allow (opt-out).
#   - stop_hook_active true → allow. One block per stop attempt, never a loop.
#   - Not a git repo → allow silently.
#   - Changed paths = merge-base(default branch, HEAD)..HEAD + uncommitted +
#     untracked (excluding .claude/reviews/). Default branch: origin/HEAD, else
#     origin/main, else main.
#   - Required reviewers = planner(changed) ∩ {code-reviewer, security-reviewer,
#     library-reviewer, data-model-verifier}. data-model-documenter writes
#     DATA_MODEL.md and emits no verdict, so it is not checked here.
#   - None required → allow.
#   - Uncommitted/untracked changes that are themselves qualifying → block:
#     verdicts bind to a HEAD sha, so commit first, then review.
#   - Each required reviewer needs .claude/reviews/<HEAD>-<agent>.json with
#     matching agent/head. Missing, malformed or `hold` → block, naming the
#     agents to dispatch. `fix-before-merge` does NOT block (a proposal per
#     .claude/rules/review-tiers.md); it is listed as info when blocking.
#
# Planner: this repo's scripts/gate-plan.sh is used ONLY when this hook runs
# from the same project's .claude/hooks/ (so a globally installed hook never
# executes a script from whatever repo it happens to run in). Otherwise —
# consumer installs — the fallback rule applies: any path other than docs
# (*.md except DATA_MODEL.md, LICENSE, NOTICE, docs/**) requires code-reviewer
# and security-reviewer.
#
# FAILS OPEN: missing jq/git, unparseable payload, no HEAD, no default branch,
# git or planner errors → one-line stderr note, exit 0. A broken gate must
# never trap a session.

set -uo pipefail

REVIEWERS="code-reviewer security-reviewer library-reviewer data-model-verifier"

fail_open() { echo "review-gate-stop: $* — gate skipped (fail-open)" >&2; exit 0; }

[[ "${AGENTIC_OS_REVIEW_GATE:-}" == "off" ]] && exit 0
command -v jq >/dev/null 2>&1 || fail_open "jq not found"
command -v git >/dev/null 2>&1 || fail_open "git not found"

input="$(head -c 4194304)"
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" || fail_open "unparseable payload"
[[ "$active" == "true" ]] && exit 0

dir="${CLAUDE_PROJECT_DIR:-}"
[[ -n "$dir" ]] || dir="$(printf '%s' "$input" | jq -r '.cwd // empty | strings')"
[[ -n "$dir" ]] || dir="$PWD"
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
g() { git -C "$root" -c core.quotePath=false "$@"; }

head="$(g rev-parse --verify -q HEAD)" || fail_open "no HEAD commit"
ref=""
for r in origin/HEAD origin/main main; do
  if g rev-parse --verify -q "$r^{commit}" >/dev/null; then ref="$r"; break; fi
done
[[ -n "$ref" ]] || fail_open "no default branch (origin/HEAD, origin/main, main)"
base="$(g merge-base "$ref" HEAD)" || fail_open "no merge-base with $ref"

strip_reviews() { grep -v '^\.claude/reviews/' || true; }
committed="$(g diff --name-only "$base" HEAD)" || fail_open "git diff failed"
tracked_dirty="$(g diff --name-only HEAD)" || fail_open "git diff failed"
untracked="$(g ls-files --others --exclude-standard)" || fail_open "git ls-files failed"
dirty="$(printf '%s\n%s\n' "$tracked_dirty" "$untracked" | strip_reviews | sed '/^$/d' | sort -u)"
changed="$(printf '%s\n%s\n' "$committed" "$dirty" | strip_reviews | sed '/^$/d' | sort -u)"
[[ -n "$changed" ]] || exit 0

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
planner=""
if [[ "$hook_dir" == "$(cd "$root" && pwd -P)/.claude/hooks" && -f "$root/scripts/gate-plan.sh" ]]; then
  planner="$root/scripts/gate-plan.sh"
fi

# required <newline-separated paths> → reviewer names, one per line.
required() {
  local paths="$1" out a
  if [[ -n "$planner" ]]; then
    out="$(SHIP_GATES_CHANGED_FILES="$paths" bash "$planner" --checkboxes 2>/dev/null)" || return 1
    for a in $out; do
      case " $REVIEWERS " in *" $a "*) echo "$a" ;; esac
    done
    return 0
  fi
  while IFS= read -r a; do
    case "$a" in
      DATA_MODEL.md) ;;
      ''|*.md|LICENSE|NOTICE|docs/*) continue ;;
    esac
    printf '%s\n' code-reviewer security-reviewer
    return 0
  done <<< "$paths"
  return 0
}

need="$(required "$changed")" || fail_open "planner failed"
[[ -n "$need" ]] || exit 0

block() { jq -cn --arg r "review-gate: $1" '{decision: "block", reason: $r}'; exit 0; }
list() { printf '%s' "$*" | sed 's/^ *//; s/  */, /g'; }
how="with only the base ref ($ref) and the changed paths; each must end with its agentic-os/review-verdict@1 block, which the SubagentStop hook records in .claude/reviews/"

if [[ -n "$dirty" ]]; then
  dirty_need="$(required "$dirty")" || fail_open "planner failed"
  if [[ -n "$dirty_need" ]]; then
    # shellcheck disable=SC2086  # word-split the agent list on purpose
    block "uncommitted changes need review ($(printf '%s\n' "$dirty" | head -5 | paste -sd, - | sed 's/,/, /g')). Review verdicts bind to a HEAD sha: commit first, then dispatch $(list $need) $how."
  fi
fi

missing="" holds="" fbm=""
for a in $need; do
  f="$root/.claude/reviews/$head-$a.json"
  v="$(jq -r --arg a "$a" --arg h "$head" '
    select(.agent == $a and .head == $h) | .verdict
    | select(IN("pass", "fix-before-merge", "hold"))' "$f" 2>/dev/null)"
  case "$v" in
    pass) ;;
    fix-before-merge) fbm="$fbm $a" ;;
    hold) holds="$holds $a" ;;
    *) missing="$missing $a" ;;
  esac
done

[[ -z "$missing" && -z "$holds" ]] && exit 0

msg="HEAD ${head:0:12} has changes vs $ref that require review."
# shellcheck disable=SC2086
[[ -n "$missing" ]] && msg="$msg No captured verdict for this HEAD from: $(list $missing). Dispatch exactly these agents (subagent_type as named) $how."
# shellcheck disable=SC2086
[[ -n "$holds" ]] && msg="$msg Evidenced hold from: $(list $holds) — fix the tier 0/1 findings, commit, and re-dispatch those agents."
# shellcheck disable=SC2086
[[ -n "$fbm" ]] && msg="$msg Info (advisory, not blocking): fix-before-merge from: $(list $fbm)."
block "$msg"
