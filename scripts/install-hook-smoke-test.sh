#!/usr/bin/env bash
# install-hook-smoke-test.sh — merge consumer hook templates into a temp DEST.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/install-hook-settings.sh
source "$REPO/scripts/lib/install-hook-settings.sh"

if ! command -v jq &>/dev/null; then
  echo "install-hook-smoke-test: SKIP (jq not installed)" >&2
  exit 0
fi

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/hooks"
touch "$tmpdir/hooks/session-state-inject.sh"

merge_claude_hook_settings "$REPO" "$tmpdir"

cmd="$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$tmpdir/settings.json")"
if [[ "$cmd" != *"$tmpdir/hooks/session-state-inject.sh"* ]]; then
  echo "FAIL install-hook-smoke: Claude command missing DEST path: $cmd" >&2
  exit 1
fi
if [[ "$cmd" == *'$HOME'* ]]; then
  echo "FAIL install-hook-smoke: Claude command still uses \$HOME template: $cmd" >&2
  exit 1
fi

# Merge preserves unrelated top-level keys.
echo '{"permissions":{"allow":["Edit(foo)"]}}' > "$tmpdir/settings.json"
merge_claude_hook_settings "$REPO" "$tmpdir"
jq -e '.permissions.allow[0] == "Edit(foo)"' "$tmpdir/settings.json" >/dev/null
jq -e '.hooks.SessionStart | length > 0' "$tmpdir/settings.json" >/dev/null

# Unsafe CLAUDE_DIR must abort before copying files.
if CLAUDE_DIR='/tmp/evil;whoami' bash "$REPO/install.sh" 2>/dev/null; then
  echo "FAIL install-hook-smoke: unsafe CLAUDE_DIR should abort" >&2
  exit 1
fi

echo "install-hook-smoke-test: OK"
