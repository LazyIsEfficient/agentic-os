#!/usr/bin/env bash
# Cursor beforeShellExecution — survey-before-act guard (NORTH_STAR Lever 4).
# Structured survey record design (S5-D deny prep): eval/spikes/survey-structured-record.md
# Mirrors .claude/hooks/survey-before-act.sh. WARN-FIRST: always allow; agent_message
# carries the advisory. See SECURITY.md and survey-guard-test-cursor.sh.
set -uo pipefail
dir="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}"
input="$(cat)"
advisory='survey-before-act: this looks like service provisioning. Before creating it, check whether it ALREADY exists (docker ps / docker compose ls / read the compose file). If it does, reuse it; either way record what you found with the session-state writer (session-state skill on Cursor). Advisory for now, not blocking.'

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
looks_like_provisioning || allow_silent

state="$dir/SESSION-STATE.md"
surveyed=0
if [ -r "$state" ]; then
  subjects="$(awk '/^## Existing infrastructure/{s=1;next} /^## /{s=0} s&&/^- /&&!/<!--/{print}' "$state" \
    | grep -oE '\[surveyed:[A-Za-z0-9._-]+\]' | sed 's/^\[surveyed://;s/\]$//' | tr 'A-Z' 'a-z' | sort -u)"
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
    --arg msg "$advisory" \
    '{permission: $perm, agent_message: $msg}'
else
  printf '{"permission":"allow","agent_message":"%s"}\n' "$advisory"
fi
exit 0
