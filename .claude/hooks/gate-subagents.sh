#!/usr/bin/env bash
# PreToolUse(Agent) hook — v4 deterministic sub-agent DISPATCH GATE (#230).
#
# The benchmark showed always-on reviewer dispatch is the top token cost and fires
# stochastically (one run spawned 5 sub-agents, another 0 — both passed). Prose
# doctrine did not enforce restraint. This hook makes it deterministic: it denies a
# reviewer/documenter sub-agent spawn that the CURRENT diff does not warrant, reusing
# the SAME path classifier that drives the PR ship-gate (scripts/lib/gate-plan-lib.sh)
# as the single source of truth. Engineer / Explore / general-purpose and every other
# type are ALWAYS allowed — only the five review/document types are gated.
#
# Empirically verified surface (claude 2.1.202): PreToolUse fires on the `Agent`
# spawn tool; tool_input carries `subagent_type`; permissionDecision:"deny" blocks the
# spawn and hands the reason back to the model, which then proceeds without it.
#
# NON-NEGOTIABLE: FAIL OPEN. A dispatch gate must never block real work — every error
# path (no jq, no git, unclassifiable diff, unreadable lib) ALLOWS the spawn.
set -uo pipefail

allow() { exit 0; }   # emit nothing → Claude Code defaults to allow

command -v jq >/dev/null 2>&1 || allow
input="$(cat 2>/dev/null)" || allow
st="$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // empty' 2>/dev/null || true)"
[ -n "$st" ] || allow

# Only these review/document types are gated. Anything else (engineer, Explore,
# general-purpose, stack specialists, …) is always allowed.
case "$st" in
  code-reviewer|security-reviewer|library-reviewer|data-model-documenter|data-model-verifier) ;;
  *) allow ;;
esac

dir="${CLAUDE_PROJECT_DIR:-.}"
lib="$dir/scripts/lib/gate-plan-lib.sh"
[ -r "$lib" ] || allow
# shellcheck source=/dev/null
# NOTE: sources a lib UNDER scripts/lib/ — outside the .claude/hooks/ tree that
# validate.sh Invariant 8(a) scans. Safe today: this hook is wired ONLY in the repo's
# own .claude/settings.json (dev), never the consumer template, and install.sh ships
# skills/agents/hooks (not scripts/). If ever added to the consumer template, bring
# gate-plan-lib.sh under the Invariant 8(a) scan or an equivalent review gate (SECURITY.md).
. "$lib" 2>/dev/null || allow
command -v gate_plan_classify_paths >/dev/null 2>&1 || allow   # lib didn't define it → allow
git -C "$dir" rev-parse HEAD >/dev/null 2>&1 || allow           # no repo/HEAD → can't classify → allow

# The changes a reviewer would examine: UNCOMMITTED work (tree + staged + untracked)
# if any; ELSE the committed branch diff vs its base. This repo commits work on a
# branch and reviews it vs main, so a clean tree here means "review the committed
# branch," not "nothing to review" — without this fallback the gate under-triggers on
# already-committed work. `diffbase` drives both the classifier and the LOC count.
diffbase="HEAD"
changed="$(
  { git -C "$dir" diff --name-only HEAD 2>/dev/null
    git -C "$dir" diff --name-only --cached 2>/dev/null
    git -C "$dir" ls-files --others --exclude-standard 2>/dev/null; } | sort -u
)"
if [ -z "$changed" ]; then
  for b in origin2/main origin/main main; do
    if git -C "$dir" rev-parse --verify -q "$b" >/dev/null 2>&1; then
      mb="$(git -C "$dir" merge-base HEAD "$b" 2>/dev/null || true)"
      [ -n "${mb:-}" ] && { diffbase="$mb"; changed="$(git -C "$dir" diff --name-only "$mb" HEAD 2>/dev/null || true)"; }
      break
    fi
  done
fi
# Sets GATE_IS_SENSITIVE / GATE_IS_LIBRARY / GATE_HAS_DATA_MODEL / GATE_IS_CODE_CHANGE.
# Do NOT gate on its exit code — gate_plan_run legitimately returns non-zero when a
# wave is empty; gate_plan_reset (first line of classify) guarantees the flags are set.
gate_plan_classify_paths "$changed" 2>/dev/null || true

# Tight v4 dispatch policy — which reviewer a diff actually warrants.
warranted=false
case "$st" in
  security-reviewer)                          [ "${GATE_IS_SENSITIVE:-false}" = true ] && warranted=true ;;
  library-reviewer)                           [ "${GATE_IS_LIBRARY:-false}" = true ] && warranted=true ;;
  data-model-documenter|data-model-verifier)  [ "${GATE_HAS_DATA_MODEL:-false}" = true ] && warranted=true ;;
  code-reviewer)
    # Only for a non-trivial code/library change (skip trivial diffs — a green
    # deterministic suite + validate.sh are the cheaper reviewer). Threshold tuned by
    # the ablation (v4-1).
    if [ "${GATE_IS_CODE_CHANGE:-false}" = true ] || [ "${GATE_IS_LIBRARY:-false}" = true ]; then
      # Total change size = tracked numstat + untracked new-file line counts. numstat
      # OMITS untracked files, but the classifier counts them (ls-files --others) — keep
      # the two in agreement so a large brand-new file isn't silently skipped.
      loc="$(git -C "$dir" diff "$diffbase" --numstat 2>/dev/null | awk '{a+=$1+$2} END{print a+0}')"
      untracked_loc="$(
        git -C "$dir" ls-files --others --exclude-standard 2>/dev/null |
          while IFS= read -r uf; do [ -n "$uf" ] && wc -l < "$dir/$uf" 2>/dev/null; done |
          awk '{a+=$1} END{print a+0}'
      )"
      loc=$(( ${loc:-0} + ${untracked_loc:-0} ))
      [ "${loc:-0}" -ge 30 ] && warranted=true
    fi
    ;;
esac

[ "$warranted" = true ] && allow

# Not warranted → deny, with a reason the model can act on.
reason="v4 dispatch gate: a '$st' sub-agent is not warranted by the current diff (no matching trigger — a sensitive/library/data-model surface or sufficient code complexity). Skip it to save tokens; the deterministic validate.sh checks and the CI ship-gate still cover this diff at PR time. Proceed without this sub-agent."
jq -n --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
