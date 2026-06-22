#!/usr/bin/env bash
# Preflight for Spike A live-fire (checkpoint:cursor-go). Run from repo root.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"
REPO="$ROOT"

echo "=== Cursor sessionStart GO test — preflight ==="
echo "Repo: $REPO"
echo "Cursor: $(cursor --version 2>/dev/null | head -1 || echo 'unknown')"
echo

fail=0
check() {
  local label="$1" path="$2"
  if [[ -e "$path" ]]; then
    echo "OK   $label — $path"
  else
    echo "FAIL $label — missing: $path"
    fail=1
  fi
}

check "hooks.json" ".cursor/hooks.json"
check "sessionStart probe" ".cursor/hooks/session-state-inject-probe.sh"
check "SESSION-STATE.md" "SESSION-STATE.md"

if [[ ! -x ".cursor/hooks/session-state-inject-probe.sh" ]]; then
  echo "FAIL probe not executable — run: chmod +x .cursor/hooks/session-state-inject-probe.sh"
  fail=1
fi

echo
echo "=== Deterministic probe check ==="
bash eval/spikes/cursor-hook-capability/unit-test.sh || fail=1

echo
echo "=== Live-fire steps (human — new Agent chat required) ==="
cat <<'EOF'
1. Confirm Cursor Settings → Hooks lists sessionStart → session-state-inject-probe.sh
   (project hooks from .cursor/hooks.json in this repo).
2. Open a NEW Agent chat (Cmd+L or Agent panel → New Chat). Do NOT reuse this thread.
3. First message only:
   Reply with exactly the token CURSOR_SPIKE_SESSIONSTART_INJECTED and nothing else.
4. PASS (GO): agent reply is exactly CURSOR_SPIKE_SESSIONSTART_INJECTED
   FAIL (NO-GO): agent does not know the token / asks you to paste it
5. Evidence: eval/spikes/cursor-hook-capability/live-fire.log gains a line when the hook runs.

Optional: Cursor Hooks output channel should show sessionStart hook executed.
EOF

exit "$fail"
