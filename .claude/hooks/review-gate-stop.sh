#!/usr/bin/env bash
# Stop hook — Tier 0 review gate (issue #258). Blocks the end of a turn while a
# qualifying diff lacks captured reviewer verdicts for the current HEAD. Keys
# ONLY on reproducible artifacts: the changed-path set and the files
# review-verdict-capture.sh (SubagentStop) writes to .claude/reviews/. It never
# reads or judges LLM output itself.
#
# This is a PROCESS gate against skipped reviews, not an adversarial control:
# the artifacts are unauthenticated, and a diff can edit the planner or the
# reviewer agents (SECURITY.md).
#
# Flow:
#   - AGENTIC_OS_REVIEW_GATE=off in Claude Code's environment → allow (opt-out).
#   - stop_hook_active true → allow. One block per stop attempt, never a loop.
#   - Git root from the payload's `cwd` (worktree-aware), else
#     CLAUDE_PROJECT_DIR. Not a git repo → allow silently.
#   - Changed paths = merge-base(default branch, HEAD)..HEAD + uncommitted +
#     untracked-not-ignored, excluding .claude/reviews/ and .claude/worktrees/.
#     Default branch: first of origin/HEAD, origin/main, origin/master, main,
#     master. If HEAD has no commits beyond it but does beyond another
#     candidate, warn the user (systemMessage) — the ref may have been moved.
#   - Required reviewers = planner(changed) ∩ {code-reviewer, security-reviewer,
#     library-reviewer, data-model-verifier}. data-model-documenter writes
#     DATA_MODEL.md and emits no verdict, so it is not checked here.
#   - None required → allow.
#   - Uncommitted/untracked changes that are themselves qualifying → block:
#     verdicts bind to a HEAD sha.
#   - Each required reviewer needs .claude/reviews/<HEAD>-<agent>.json with
#     matching agent/head. Missing, malformed or `hold` → block, naming the
#     agents to dispatch. `fix-before-merge` does NOT block (a proposal per
#     .claude/rules/review-tiers.md); it is listed as info when blocking.
#
# Planner: scripts/gate-plan.sh of the checkout this hook lives in
# (<x>/.claude/hooks → <x>/scripts/gate-plan.sh), used ONLY when <x> is the same
# repository as the reviewed tree (same git common dir — covers worktrees).
# A globally installed hook (~/.claude/hooks) therefore never executes a script
# from whatever repo it runs in. Otherwise — consumer installs — the fallback
# rule applies: any path other than docs (*.md except DATA_MODEL.md, LICENSE,
# NOTICE, docs/**) requires code-reviewer and security-reviewer.
#
# FAILS OPEN: missing jq/git, unparseable payload, no HEAD, no default branch,
# git or planner errors → allow, with a one-line note (stderr + systemMessage)
# printed once per session (marker keyed by session_id in a private temp dir).
# A broken gate must never trap a session.

set -uo pipefail

REVIEWERS="code-reviewer security-reviewer library-reviewer data-model-verifier"

[[ "${AGENTIC_OS_REVIEW_GATE:-}" == "off" ]] && exit 0

input="$(head -c 4194304)"

# session_id without jq (the jq-missing path needs it too); safe charset only.
sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([A-Za-z0-9_-]\{1,128\}\)".*/\1/p' | head -1)"

# Notes contain only literals and fixed ref names (no quotes/backslashes), so
# they are JSON-safe without jq.
fail_open() {
  local msg="review-gate-stop: $* — gate skipped (fail-open)"
  local mdir="${TMPDIR:-/tmp}/agentic-os-review-gate-$(id -u)"
  if [[ -n "$sid" ]]; then
    mkdir -m 700 -p "$mdir" 2>/dev/null
    if [[ -d "$mdir" && ! -L "$mdir" && -O "$mdir" ]]; then
      [[ -e "$mdir/$sid" ]] && exit 0
      : > "$mdir/$sid" 2>/dev/null
    fi
  fi
  echo "$msg" >&2
  printf '{"systemMessage":"%s"}\n' "$msg"
  exit 0
}

command -v jq >/dev/null 2>&1 || fail_open "jq not found"
command -v git >/dev/null 2>&1 || fail_open "git not found"

active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null)" || fail_open "unparseable payload"
[[ "$active" == "true" ]] && exit 0

dir="$(printf '%s' "$input" | jq -r '.cwd // empty | strings')"
[[ -n "$dir" ]] || dir="${CLAUDE_PROJECT_DIR:-$PWD}"
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || exit 0
g() { git -C "$root" -c core.quotePath=false "$@"; }

head="$(g rev-parse --verify -q HEAD)" || fail_open "no HEAD commit"
refs=""
for r in origin/HEAD origin/main origin/master main master; do
  g rev-parse --verify -q "$r^{commit}" >/dev/null && refs="$refs $r"
done
read -r ref _ <<< "$refs"
[[ -n "${ref:-}" ]] || fail_open "no default branch (origin/HEAD, origin/main, origin/master, main, master)"
base="$(g merge-base "$ref" HEAD)" || fail_open "no merge-base with $ref"

warn=""
if [[ "$base" == "$head" ]]; then
  for r in $refs; do
    [[ "$r" == "$ref" ]] && continue
    if [[ "$(g rev-list --count "$r..HEAD" 2>/dev/null)" =~ ^[1-9] ]]; then
      warn="review-gate: HEAD has no commits beyond $ref but has commits beyond $r — if $ref was moved, the gate is checking the wrong base."
      break
    fi
  done
fi

strip_noise() { grep -v -e '^\.claude/reviews/' -e '^\.claude/worktrees/' || true; }
committed="$(g diff --name-only "$base" HEAD)" || fail_open "git diff failed"
tracked_dirty="$(g diff --name-only HEAD)" || fail_open "git diff failed"
untracked="$(g ls-files --others --exclude-standard)" || fail_open "git ls-files failed"
dirty="$(printf '%s\n%s\n' "$tracked_dirty" "$untracked" | strip_noise | sed '/^$/d' | sort -u)"
changed="$(printf '%s\n%s\n' "$committed" "$dirty" | strip_noise | sed '/^$/d' | sort -u)"

allow() {
  [[ -n "$warn" ]] && jq -cn --arg m "$warn" '{systemMessage: $m}'
  exit 0
}
[[ -n "$changed" ]] || allow

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
planner=""
if [[ "$hook_dir" == */.claude/hooks ]]; then
  hook_proj="${hook_dir%/.claude/hooks}"
  common_of() {
    local c
    c="$(git -C "$1" rev-parse --git-common-dir 2>/dev/null)" && [[ -n "$c" ]] || return 0
    (cd "$1" && cd "$c" 2>/dev/null && pwd -P)
  }
  hc="$(common_of "$hook_proj")"
  rc_="$(common_of "$root")"
  if [[ -n "$hc" && "$hc" == "$rc_" && -f "$hook_proj/scripts/gate-plan.sh" ]]; then
    planner="$hook_proj/scripts/gate-plan.sh"
  fi
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
[[ -n "$need" ]] || allow

block() {
  local r="review-gate: $1"
  [[ -n "$warn" ]] && r="$r Warning: ${warn#review-gate: }"
  jq -cn --arg r "$r" '{decision: "block", reason: $r}'
  exit 0
}
list() { printf '%s' "$*" | sed 's/^ *//; s/  */, /g'; }
how="with only the base ref ($ref) and the changed paths; each must end with its agentic-os/review-verdict@1 block, which the SubagentStop hook records in .claude/reviews/"

if [[ -n "$dirty" ]]; then
  dirty_need="$(required "$dirty")" || fail_open "planner failed"
  if [[ -n "$dirty_need" ]]; then
    # shellcheck disable=SC2086  # word-split the agent list on purpose
    block "uncommitted or untracked changes need review ($(printf '%s\n' "$dirty" | head -5 | paste -sd, - | sed 's/,/, /g')). Verdicts bind to a HEAD sha, so commit only the changes you intend to ship, then dispatch $(list $need) $how. Never commit files you did not create for this task (user work in progress, build output); if such files are what remains, tell the user instead of committing them."
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

[[ -z "$missing" && -z "$holds" ]] && allow

msg="HEAD ${head:0:12} has changes vs $ref that require review."
# shellcheck disable=SC2086
[[ -n "$missing" ]] && msg="$msg No captured verdict for this HEAD from: $(list $missing). Dispatch exactly these agents (subagent_type as named) $how."
# shellcheck disable=SC2086
[[ -n "$holds" ]] && msg="$msg Evidenced hold from: $(list $holds) — fix the tier 0/1 findings, commit, and re-dispatch those agents."
# shellcheck disable=SC2086
[[ -n "$fbm" ]] && msg="$msg Info (advisory, not blocking): fix-before-merge from: $(list $fbm)."
block "$msg"
