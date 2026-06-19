#!/usr/bin/env bash
# PreToolUse(Bash) hook — survey-before-act guard (NORTH_STAR Lever 4).
#
# Service-provisioning commands (docker/podman/nerdctl run, docker compose up) are
# the canonical "did I check whether this already exists?" failure (the broker
# lesson). When one is seen and SESSION-STATE.md shows no prior survey of the
# thing being provisioned, inject a reminder to check-first and record the finding.
#
# WARN-FIRST (this iteration): always ALLOW the action; only inject the advisory
# and append to a warn-log so the false-positive rate can be measured before we
# ratchet to a hard deny. Flipping to block later = change permissionDecision
# "allow" -> "deny" and word the reason as a block. Scope is deliberately narrow
# (container provisioning) to keep false positives near zero; it intentionally
# does NOT name service-manager or scheduler commands by their literal names,
# since those are Invariant-8 denylist tokens that must not appear in a shipped
# hook's source (even in a comment — the scanner can't tell comment from code).
set -uo pipefail
dir="${CLAUDE_PROJECT_DIR:-.}"
input="$(cat)"
# Prefer jq for an EXACT command (handles embedded escaped quotes); fall back to
# a crude sed capture when jq is absent. Exact extraction also de-risks the future
# ratchet to a hard deny, where a truncated command would be an evasion surface.
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
else
  cmd="$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
fi
[ -n "$cmd" ] || exit 0

# Provisioning detector (narrow). 'docker ps' / 'compose ls' are surveys, not
# provisioning, so they are deliberately NOT matched.
case "$cmd" in
  *"docker run"*|*"docker compose up"*|*"docker-compose up"*|*"podman run"*|*"nerdctl run"*) ;;
  *) exit 0 ;;
esac

# Already surveyed? If the Existing-infrastructure section names a subject token
# from the command, assume the survey happened and allow silently.
state="$dir/SESSION-STATE.md"
surveyed=0
if [ -r "$state" ]; then
  infra="$(awk '/^## Existing infrastructure/{s=1;next} /^## /{s=0} s&&/^- /&&!/<!--/{print}' "$state")"
  if [ -n "$infra" ]; then
    for tok in $(printf '%s\n' "$cmd" | tr -cs 'A-Za-z0-9' ' '); do
      case "$tok" in
        docker|compose|podman|nerdctl|run|exec|build|image|images|container|name|port|ports|detach|env|volume|volumes|network|networks|restart|always|pull) continue ;;
      esac
      [ "${#tok}" -ge 4 ] || continue
      if printf '%s' "$infra" | grep -qiF -- "$tok"; then surveyed=1; break; fi
    done
  fi
fi

[ "$surveyed" -eq 1 ] && exit 0

# Not surveyed → warn (allow) + log for measurement (best-effort; never noisy).
if [ -d "$dir/.claude" ]; then
  # Strip CR/LF so a command containing a real newline can't forge log records.
  safe_cmd="$(printf '%s' "$cmd" | tr -d '\n\r')"
  printf 'survey-warn cmd=%s\n' "$safe_cmd" >> "$dir/.claude/survey-guard.warns" 2>/dev/null || true
fi
printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","additionalContext":"survey-before-act: this looks like service provisioning. Before creating it, check whether it ALREADY exists (docker ps / docker compose ls / read the compose file). If it does, reuse it; either way record what you found with /state infra \"...\". Advisory for now, not blocking."}}'
exit 0
