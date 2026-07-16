#!/usr/bin/env bash
# PreToolUse(Agent) hook — v4 deterministic sub-agent DISPATCH GATE (#230).
#
# The benchmark showed always-on reviewer dispatch is the top token cost and fires
# stochastically (one run spawned 5 sub-agents, another 0 — both passed). Prose
# doctrine did not enforce restraint. This hook makes it deterministic: it denies a
# reviewer/documenter sub-agent spawn that the CURRENT diff does not warrant, reusing
# the SAME path classifier that drives the PR ship-gate (scripts/lib/gate-plan-lib.sh)
# as the single source of truth. Engineer / Explore / general-purpose and every other
# type are ALWAYS allowed — only the four review/document types are gated.
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
. "$lib" 2>/dev/null || allow
command -v gate_plan_classify_paths >/dev/null 2>&1 || allow   # lib didn't define it → allow
git -C "$dir" rev-parse HEAD >/dev/null 2>&1 || allow           # no repo/HEAD → can't classify → allow

# The changes a reviewer would examine: working tree + staged + untracked.
changed="$(
  { git -C "$dir" diff --name-only HEAD 2>/dev/null
    git -C "$dir" diff --name-only --cached 2>/dev/null
    git -C "$dir" ls-files --others --exclude-standard 2>/dev/null; } | sort -u
)"
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
      loc="$(git -C "$dir" diff HEAD --numstat 2>/dev/null | awk '{a+=$1+$2} END{print a+0}')"
      [ "${loc:-0}" -ge 30 ] && warranted=true
    fi
    ;;
esac

[ "$warranted" = true ] && allow

# Not warranted → deny, with a reason the model can act on.
reason="v4 dispatch gate: a '$st' sub-agent is not warranted by the current diff (no matching trigger — a sensitive/library/data-model surface or sufficient code complexity). Skip it to save tokens; the deterministic validate.sh checks and the CI ship-gate still cover this diff at PR time. Proceed without this sub-agent."
jq -n --arg r "$reason" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
