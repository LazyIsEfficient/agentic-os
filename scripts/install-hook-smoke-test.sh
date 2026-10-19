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

# Canonical (pwd -P): the merge writes canonical DEST paths, and macOS mktemp
# returns /var/... which is a symlink to /private/var/...
tmpdir="$(cd "$(mktemp -d)" && pwd -P)"
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

# Merge preserves consumer hooks (#270): their own PreToolUse Bash hook, an
# event we don't ship, a consumer handler mixed into a group with ours; old-style
# AgenticOS entries (literal $HOME template + DEST-rewritten) are replaced.
cat > "$tmpdir/settings.json" <<EOF
{
  "permissions": {"allow": ["Edit(foo)"]},
  "hooks": {
    "PreToolUse": [
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "bash /opt/my-guard.sh"}]},
      {"matcher": "Bash", "hooks": [
        {"type": "command", "command": "bash \$HOME/.claude/hooks/block-bad-bash.sh"},
        {"type": "command", "command": "bash $tmpdir/hooks/survey-before-act.sh"},
        {"type": "command", "command": "bash $tmpdir/hooks/my-own-hook.sh"}
      ]},
      {"matcher": "Bash", "hooks": [
        {"type": "command", "command": "bash \$HOME/.claude/hooks/block-bad-bash.sh; bash /opt/audit-logger.sh"},
        {"type": "command", "command": "bash $tmpdir/hooks/block-bad-bash.sh | tee /tmp/audit.log"}
      ]}
    ],
    "SessionStart": [
      {"hooks": [{"type": "command", "command": "bash $tmpdir/hooks/session-state-inject.sh"}]}
    ],
    "UserPromptSubmit": [
      {"hooks": [{"type": "command", "command": "bash $tmpdir/hooks/session-state-digest.sh.local"}]}
    ],
    "Notification": [
      {"hooks": [{"type": "command", "command": "say done"}]}
    ]
  }
}
EOF
merge_claude_hook_settings "$REPO" "$tmpdir"
s="$tmpdir/settings.json"
check() { jq -e --arg d "$tmpdir/hooks" "$1" "$s" >/dev/null || { echo "FAIL install-hook-smoke: $2" >&2; jq . "$s" >&2; exit 1; }; }
count() { echo "[.hooks[][] | .hooks[]? | .command | select(. == (\"bash \" + \$d + \"/$1\"))] | length"; }
check '.permissions.allow[0] == "Edit(foo)"' "non-hooks key lost"
check '.hooks.Notification == [{"hooks":[{"type":"command","command":"say done"}]}]' "unshipped consumer event changed"
check '.hooks.PreToolUse[0] == {"matcher":"Bash","hooks":[{"type":"command","command":"bash /opt/my-guard.sh"}]}' "consumer PreToolUse group lost"
check '.hooks.PreToolUse[1] == {"matcher":"Bash","hooks":[{"type":"command","command":("bash " + $d + "/my-own-hook.sh")}]}' "consumer handler in mixed group lost"
check '.hooks.UserPromptSubmit[0].hooks[0].command == ("bash " + $d + "/session-state-digest.sh.local")' "lookalike consumer hook treated as AgenticOS-owned"
check '.hooks.PreToolUse[2] == {"matcher":"Bash","hooks":[
  {"type":"command","command":"bash $HOME/.claude/hooks/block-bad-bash.sh; bash /opt/audit-logger.sh"},
  {"type":"command","command":("bash " + $d + "/block-bad-bash.sh | tee /tmp/audit.log")}]}' \
  "compound / piped consumer command containing our path was treated as AgenticOS-owned"
check '[.. | strings | select(. == "bash $HOME/.claude/hooks/block-bad-bash.sh")] | length == 0' "old \$HOME-style AgenticOS entry not replaced"
for h in block-bad-bash.sh survey-before-act.sh session-state-inject.sh session-state-digest.sh; do
  check "$(count "$h") == 1" "$h not registered exactly once"
done
check "$(count session-state-checkpoint.sh) == 2" "PreCompact auto+manual not registered exactly once each"
# Every event and group in the template is present, in order, at the tail.
template="$(_claude_hooks_json_for_dest "$REPO/assets/consumer/claude-settings.json" "$tmpdir/hooks")"
jq -e --argjson t "$template" '. as $s | all($t | keys_unsorted[]; . as $e | $s.hooks[$e][-($t[$e] | length):] == $t[$e])' "$s" >/dev/null \
  || { echo "FAIL install-hook-smoke: template groups missing from merged settings" >&2; exit 1; }

# Second install is byte-identical.
cp "$s" "$tmpdir/first.json"
merge_claude_hook_settings "$REPO" "$tmpdir"
if ! cmp -s "$s" "$tmpdir/first.json"; then
  echo "FAIL install-hook-smoke: re-install not idempotent" >&2
  diff "$tmpdir/first.json" "$s" >&2 || true
  exit 1
fi

# Unmergeable input fails closed and leaves the file untouched: invalid JSON,
# a non-object hooks key, a non-array value for an event we ship.
for bad in '{not json' '{"hooks":[]}' '{"hooks":{"PreToolUse":{"matcher":"Bash"}}}'; do
  printf '%s' "$bad" > "$s"
  if merge_claude_hook_settings "$REPO" "$tmpdir" 2>/dev/null; then
    echo "FAIL install-hook-smoke: merge should fail closed on: $bad" >&2
    exit 1
  fi
  [[ "$(cat "$s")" == "$bad" ]] || { echo "FAIL install-hook-smoke: unmergeable settings.json was modified: $bad" >&2; exit 1; }
done

# File mode survives the rewrite (settings.json can hold env secrets).
echo '{"env":{"TOKEN":"x"}}' > "$s"
chmod 600 "$s"
merge_claude_hook_settings "$REPO" "$tmpdir" >/dev/null
mode="$(ls -l "$s" | cut -c1-10)"
[[ "$mode" == "-rw-------" ]] || { echo "FAIL install-hook-smoke: settings.json mode changed to $mode" >&2; exit 1; }

# DEST is canonicalised: a trailing slash, then a symlinked alias, then the
# plain path all register once. An old install that wrote the as-given
# (`dir//hooks`, alias) forms is also recognised and replaced.
total() { jq '[.hooks[][] | .hooks[]?] | length' "$1"; }
want="$(jq '[.hooks[][] | .hooks[]?] | length' "$REPO/assets/consumer/claude-settings.json")"
d2="$tmpdir/canon"
mkdir -p "$d2"
ln -s "$d2" "$tmpdir/alias"
echo '{}' > "$d2/settings.json"
merge_claude_hook_settings "$REPO" "$d2/" >/dev/null
merge_claude_hook_settings "$REPO" "$tmpdir/alias" >/dev/null
merge_claude_hook_settings "$REPO" "$d2" >/dev/null
[[ "$(total "$d2/settings.json")" == "$want" ]] \
  || { echo "FAIL install-hook-smoke: DEST spellings double-registered ($(total "$d2/settings.json") != $want)" >&2; exit 1; }
cat > "$d2/settings.json" <<EOF
{"hooks":{"SessionStart":[
  {"hooks":[{"type":"command","command":"bash $d2//hooks/session-state-inject.sh"}]},
  {"hooks":[{"type":"command","command":"  bash $tmpdir/alias/hooks/session-state-inject.sh "}]}]}}
EOF
merge_claude_hook_settings "$REPO" "$d2/" >/dev/null
merge_claude_hook_settings "$REPO" "$tmpdir/alias" >/dev/null
[[ "$(total "$d2/settings.json")" == "$want" ]] \
  || { echo "FAIL install-hook-smoke: as-given DEST forms from older installs not replaced" >&2; jq . "$d2/settings.json" >&2; exit 1; }

# Unsafe CLAUDE_DIR must abort before copying files.
if CLAUDE_DIR='/tmp/evil;whoami' bash "$REPO/install.sh" 2>/dev/null; then
  echo "FAIL install-hook-smoke: unsafe CLAUDE_DIR should abort" >&2
  exit 1
fi

# Full install into a throwaway HOME ships the reviewer scanners (#261/#262):
# reviewers run in consumer projects, where repo scripts/ does not exist.
fake_home="$tmpdir/home"
mkdir -p "$fake_home"
HOME="$fake_home" CLAUDE_DIR="$fake_home/.claude" bash "$REPO/install.sh" >/dev/null \
  || { echo "FAIL install-hook-smoke: full install into temp HOME failed" >&2; exit 1; }
for f in skills/security/scripts/security-scan.sh skills/security/scripts/security-scan-semgrep.yml \
         skills/code-review-and-quality/scripts/check-imports.sh; do
  [[ -f "$fake_home/.claude/$f" ]] || { echo "FAIL install-hook-smoke: $f not installed" >&2; exit 1; }
done
# The installed scanners run standalone: outside a git repo the default scope is
# a usage error (exit 2) for both — proves they parse and execute, nothing more.
for f in skills/security/scripts/security-scan.sh skills/code-review-and-quality/scripts/check-imports.sh; do
  rc=0; (cd "$fake_home" && bash "$fake_home/.claude/$f" --json >/dev/null 2>&1) || rc=$?
  [[ "$rc" == 2 ]] || { echo "FAIL install-hook-smoke: installed $f exit $rc, want 2" >&2; exit 1; }
done

echo "install-hook-smoke-test: OK"
