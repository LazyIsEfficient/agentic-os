#!/usr/bin/env bash
# Cursor beforeShellExecution probe — mirror .claude/hooks/survey-before-act.sh for Spike B.
# Maps Claude PreToolUse(Bash) hookSpecificOutput → Cursor { permission, agent_message }.
# WARN-FIRST: always allow; agent_message carries the advisory. Sentinel:
# CURSOR_SPIKE_SURVEY_WARN.
set -uo pipefail
dir="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
input="$(cat)"
sentinel="CURSOR_SPIKE_SURVEY_WARN"
advisory='survey-before-act: this looks like service provisioning. Before creating it, check whether it ALREADY exists (docker ps / docker compose ls / read the compose file). If it does, reuse it; either way record what you found with /state infra "...". Advisory for now, not blocking.'
agent_msg="${advisory} ${sentinel}"

allow_silent() {
  printf '%s\n' '{"permission":"allow"}'
  exit 0
}

if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.command // empty' 2>/dev/null)"
else
  cmd="$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
fi
[ -n "$cmd" ] || allow_silent

case "$cmd" in
  *"docker run"*|*"docker compose up"*|*"docker-compose up"*|*"podman run"*|*"nerdctl run"*) ;;
  *) allow_silent ;;
esac

state="$dir/SESSION-STATE.md"
surveyed=0
if [ -r "$state" ]; then
  subjects="$(awk '/^## Existing infrastructure/{s=1;next} /^## /{s=0} s&&/^- /&&!/<!--/{print}' "$state" \
    | grep -oE '\[[A-Za-z0-9._-]+\]' | tr -d '[]' | tr 'A-Z' 'a-z' | sort -u)"
  if [ -n "$subjects" ]; then
    cmdtokens="$(printf '%s' "$cmd" | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9._-' '\n')"
    for subj in $subjects; do
      if printf '%s\n' "$cmdtokens" | grep -qxF -- "$subj"; then surveyed=1; break; fi
    done
  fi
fi

[ "$surveyed" -eq 1 ] && allow_silent

if [ -d "$dir/.cursor" ]; then
  safe_cmd="$(printf '%s' "$cmd" | tr -d '\n\r')"
  printf 'survey-warn cmd=%s\n' "$safe_cmd" >> "$dir/.cursor/survey-guard.warns" 2>/dev/null || true
fi

if command -v jq >/dev/null 2>&1; then
  jq -n \
    --arg perm allow \
    --arg msg "$agent_msg" \
    '{permission: $perm, agent_message: $msg}'
else
  printf '{"permission":"allow","agent_message":"%s"}\n' "$agent_msg"
fi
exit 0
