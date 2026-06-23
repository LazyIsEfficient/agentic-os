#!/usr/bin/env bash
# PreToolUse(Bash) hook — survey-before-act guard (NORTH_STAR Lever 4).
# Structured survey record design (S5-D deny prep): eval/spikes/survey-structured-record.md
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
#
# FAIL POSTURE (governs the future warn->deny ratchet, S5-D):
#  - Detector/environment failure — jq missing, SESSION-STATE.md unreadable, or
#    the command unparseable — FAILS OPEN (allow, silently). An environment gap is
#    not the user's fault and must never block work, in warn OR deny mode.
#  - Guard POSITIVE — provisioning detected AND no recorded [subject] matches the
#    command — is the ONLY condition that escalates: warn now, deny after the
#    evidence gate. Blocking is tied strictly to the guard's real signal, never to
#    incidental failure, so a future deny can never fail closed on a missing tool.
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

# Provisioning detector: match only when a shell *segment* starts with container
# provisioning — not when "docker run" appears inside gh/heredocs/printf strings.
looks_like_provisioning() {
  local normalized part
  normalized="$(printf '%s' "$cmd" | sed 's/&&/;/g; s/||/;/g')"
  IFS=';' read -ra parts <<< "$normalized" || true
  for part in "${parts[@]}"; do
    part="${part#"${part%%[![:space:]]*}"}"
    part="${part%"${part##*[![:space:]]}"}"
    [ -z "$part" ] && continue
    case "$part" in
      docker\ run\ --help*|docker\ run\ -h|docker\ run\ -h\ *|docker\ run\ --version*)
        continue
        ;;
      docker\ run\ *|docker\ compose\ up*|docker-compose\ up*|podman\ run\ *|nerdctl\ run\ *)
        return 0
        ;;
    esac
  done
  return 1
}
looks_like_provisioning || exit 0

# Already surveyed? Suppress ONLY when a recorded [surveyed:name] token in an
# Existing-infrastructure entry appears as a whole token in the command.
state="$dir/SESSION-STATE.md"
surveyed=0
if [ -r "$state" ]; then
  subjects="$(awk '/^## Existing infrastructure/{s=1;next} /^## /{s=0} s&&/^- /&&!/<!--/{print}' "$state" \
    | grep -oE '\[surveyed:[A-Za-z0-9._-]+\]' | sed 's/^\[surveyed://;s/\]$//' | tr 'A-Z' 'a-z' | sort -u)"
  if [ -n "$subjects" ]; then
    cmdtokens="$(printf '%s' "$cmd" | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9._-' '\n')"
    # Word-split is safe: subjects are charset-filtered to [a-z0-9._-] above, so a
    # token can hold no whitespace or glob metacharacter. A for-loop keeps the
    # match in the current shell (no pipe-to-while subshell that would lose the flag).
    for subj in $subjects; do
      if printf '%s\n' "$cmdtokens" | grep -qxF -- "$subj"; then surveyed=1; break; fi
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
