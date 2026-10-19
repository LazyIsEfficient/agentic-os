#!/usr/bin/env bash
# install-lifecycle-test.sh — manifest, update, prune, retired hooks, uninstall
# and --dry-run for install.sh (#272). Every run uses a throwaway HOME and
# CLAUDE_DIR / CODEX_HOME / CODEX_SKILLS_DIR under one mktemp dir; the real
# ~/.claude and ~/.codex are never touched.
#
# Releases are simulated with a temp copy of the repo ("rel") that is mutated
# between installs: state A adds a dropped file and a soon-retired hook; state B
# changes a shipped file, drops both, and lists the hook in RETIRED_HOOKS.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v jq &>/dev/null; then
  echo "install-lifecycle-test: SKIP (jq not installed)" >&2
  exit 0
fi

tmp="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT
home="$tmp/home"
dest="$home/.claude"
mkdir -p "$home"

P=0
fail() { echo "FAIL install-lifecycle: $*" >&2; exit 1; }
ok() { printf 'PASS  %s\n' "$1"; P=$((P + 1)); }

if command -v shasum &>/dev/null; then sha() { shasum -a 256 "$1" | awk '{print $1}'; }
else sha() { sha256sum "$1" | awk '{print $1}'; }; fi

# Content snapshot of a tree (paths + hashes + dirs) for no-change assertions.
snap() {
  local f
  (cd "$1" && find . -type d | LC_ALL=C sort)
  while IFS= read -r f; do printf '%s %s\n' "$(sha "$1/$f")" "$f"; done \
    < <(cd "$1" && find . -type f | LC_ALL=C sort)
}

# ── Build release A ───────────────────────────────────────────────────────────
rel="$tmp/rel"
mkdir -p "$rel/scripts/lib" "$rel/assets"
cp "$REPO/install.sh" "$REPO/install.ps1" "$REPO/CLAUDE.md" "$rel/"
cp "$REPO/scripts/validate.sh" "$REPO/scripts/build-claude-md.sh" "$rel/scripts/"
cp "$REPO/scripts/lib/install-hook-settings.sh" "$rel/scripts/lib/"
cp -R "$REPO/.claude" "$rel/.claude"
rm -rf "$rel/.claude/memory" "$rel/.claude/ledger" "$rel/.claude/worktrees"
cp -R "$REPO/docs" "$rel/docs"
cp -R "$REPO/assets/consumer" "$rel/assets/consumer"

printf 'dropped in release B\n' > "$rel/.claude/skills/autoresearch/zz-dropped.txt"
printf '#!/usr/bin/env bash\nexit 0\n' > "$rel/.claude/hooks/zz-retired.sh"
add_retired_reg() {
  jq '.hooks.Stop = ((.hooks.Stop // []) + [{"hooks":[{"type":"command","command":"bash $HOME/.claude/hooks/zz-retired.sh"}]}])' \
    "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
add_retired_reg "$rel/assets/consumer/claude-settings.json"
jq '.hooks.Stop = ((.hooks.Stop // []) + [{"hooks":[{"type":"command","command":"bash .claude/hooks/zz-retired.sh"}]}])' \
  "$rel/.claude/settings.json" > "$rel/.claude/settings.json.tmp" && mv "$rel/.claude/settings.json.tmp" "$rel/.claude/settings.json"

run() { HOME="$home" CLAUDE_DIR="$dest" bash "$rel/install.sh" "$@" 2>&1; }

# Pre-manifest leftovers: a retired (tombstoned) skill from an old install.
mkdir -p "$dest/skills/security-and-hardening/references"
printf 'old\n' > "$dest/skills/security-and-hardening/SKILL.md"
printf 'old\n' > "$dest/skills/security-and-hardening/references/x.md"

# ── 1. Fresh install writes the manifest ─────────────────────────────────────
run > "$tmp/out1" || { cat "$tmp/out1"; fail "fresh install failed"; }
mf="$dest/.agentic-os-manifest.json"
[[ -f "$mf" ]] || fail "fresh install wrote no manifest"
jq -e . "$mf" >/dev/null || fail "manifest is not valid JSON"
want_ver="$(sed -nE 's/^VERSION="([^"]*)".*/\1/p' "$REPO/install.sh")"
jq -e --arg v "$want_ver" '.schema == 1 and .version == $v and .platform == "claude" and .source == "local-clone"' "$mf" >/dev/null \
  || fail "manifest header wrong: $(jq -c 'del(.files)' "$mf")"
want_n="$( (cd "$rel/.claude" && find skills agents hooks -type f; ls commands/skill-new.md commands/agent-new.md commands/state.md) | wc -l | tr -d ' ')"
[[ "$(jq '.files | length' "$mf")" == "$want_n" ]] || fail "manifest lists $(jq '.files | length' "$mf") files, release has $want_n"
jq -e '.files | all(.path | test("^(skills|agents|hooks|commands)/"))' "$mf" >/dev/null || fail "manifest path outside install surfaces"
eng_sha="$(jq -r '.files[] | select(.path == "agents/engineer.md") | .sha256' "$mf")"
[[ "$eng_sha" == "$(sha "$dest/agents/engineer.md")" ]] || fail "manifest sha256 does not match installed file"
jq -e '[.files[].path] | index(["skills/security-and-hardening/SKILL.md"]) == null' "$mf" >/dev/null || fail "legacy skill adopted into manifest"
grep -q 'retired skill directory skills/security-and-hardening is still installed' "$tmp/out1" || fail "no --prune-legacy hint for tombstoned skill"
[[ -f "$dest/skills/security-and-hardening/SKILL.md" ]] || fail "tombstoned legacy skill removed without --prune-legacy"
jq -e '[.. | .command? | strings | select(endswith("/hooks/zz-retired.sh"))] | length == 1' "$dest/settings.json" >/dev/null \
  || fail "release-A hook not registered"
ok "fresh install writes a valid manifest (version, paths, sha256)"

# ── Local state: user edits, user-created files, consumer hooks ──────────────
printf '\nmy local tweak\n' >> "$dest/skills/autoresearch/SKILL.md"
printf '\n# my hook tweak\n' >> "$dest/hooks/block-bad-bash.sh"
user_hook_content="$(cat "$dest/hooks/block-bad-bash.sh")"
mkdir -p "$dest/skills/my-own-skill"
printf 'mine\n' > "$dest/skills/my-own-skill/SKILL.md"
printf 'mine\n' > "$dest/agents/my-agent.md"
printf 'mine\n' > "$dest/hooks/my-hook.sh"
jq '.hooks.Stop += [{"hooks":[{"type":"command","command":"bash /opt/consumer-stop.sh"}]}]
    | .hooks.PreToolUse += [{"matcher":"Bash","hooks":[{"type":"command","command":"bash /opt/consumer-guard.sh"}]}]
    | .permissions = {"allow":["Edit(foo)"]}' "$dest/settings.json" > "$dest/settings.json.tmp"
mv "$dest/settings.json.tmp" "$dest/settings.json"
user_sums="$(sha "$dest/skills/my-own-skill/SKILL.md") $(sha "$dest/agents/my-agent.md") $(sha "$dest/hooks/my-hook.sh")"

# ── Release B ─────────────────────────────────────────────────────────────────
printf '\n<!-- lifecycle-test: release B -->\n' >> "$rel/.claude/agents/engineer.md"
rm "$rel/.claude/skills/autoresearch/zz-dropped.txt" "$rel/.claude/hooks/zz-retired.sh"
for f in "$rel/assets/consumer/claude-settings.json" "$rel/.claude/settings.json"; do
  jq '.hooks.Stop |= map(select(any(.hooks[]; .command | endswith("zz-retired.sh")) | not))
      | if .hooks.Stop == [] then del(.hooks.Stop) else . end' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
sed -e 's/^RETIRED_HOOKS=""/RETIRED_HOOKS="zz-retired.sh"/' "$rel/install.sh" > "$rel/install.sh.tmp" && mv "$rel/install.sh.tmp" "$rel/install.sh"
sed -e 's/^\$RetiredHooks = @()/$RetiredHooks = @("zz-retired.sh")/' "$rel/install.ps1" > "$rel/install.ps1.tmp" && mv "$rel/install.ps1.tmp" "$rel/install.ps1"
grep -q '^RETIRED_HOOKS="zz-retired.sh"' "$rel/install.sh" || fail "test setup: RETIRED_HOOKS not set"

# ── 2. --dry-run changes nothing ─────────────────────────────────────────────
before="$(snap "$dest")"
run --dry-run --prune-legacy > "$tmp/out-dry" || { cat "$tmp/out-dry"; fail "dry-run install failed"; }
[[ "$(snap "$dest")" == "$before" ]] || fail "install --dry-run modified the destination"
grep -q '\[dry-run\] update agents/engineer.md' "$tmp/out-dry" || fail "dry-run did not report the pending update"
grep -q '\[dry-run\] remove skills/security-and-hardening/SKILL.md' "$tmp/out-dry" || fail "dry-run did not list the legacy prune"
ok "install --dry-run reports changes and leaves the destination byte-identical"

# ── 3. Update without --force ────────────────────────────────────────────────
run > "$tmp/out2" || { cat "$tmp/out2"; fail "update failed"; }
cmp -s "$dest/agents/engineer.md" "$rel/.claude/agents/engineer.md" || fail "unmodified file not refreshed on update"
grep -q 'update agents/engineer.md' "$tmp/out2" || fail "update not reported"
ok "update refreshes an unmodified file"

grep -q 'my local tweak' "$dest/skills/autoresearch/SKILL.md" || fail "user-modified skill file overwritten without --force"
grep -q 'keep skills/autoresearch/SKILL.md — modified locally' "$tmp/out2" || fail "no warning naming the kept skill file"
ok "update keeps a user-modified skill file and warns"

cmp -s "$dest/hooks/block-bad-bash.sh" "$rel/.claude/hooks/block-bad-bash.sh" || fail "modified hook not refreshed"
bak="$(find "$dest/hooks" -name 'block-bad-bash.sh.bak.*' | head -1)"
[[ -n "$bak" && "$(cat "$bak")" == "$user_hook_content" ]] || fail "modified hook not backed up"
grep -q 'refresh hook hooks/block-bad-bash.sh' "$tmp/out2" || fail "no warning for refreshed hook"
[[ -x "$dest/hooks/block-bad-bash.sh" ]] || fail "refreshed hook not executable"
ok "update always refreshes a hook and backs up the user-modified copy"

[[ ! -e "$dest/skills/autoresearch/zz-dropped.txt" ]] || fail "file dropped from release not pruned"
grep -q 'remove skills/autoresearch/zz-dropped.txt (no longer shipped)' "$tmp/out2" || fail "prune not reported"
jq -e '[.files[].path] | (index(["skills/autoresearch/zz-dropped.txt"]) == null) and (index(["hooks/zz-retired.sh"]) == null)' "$mf" >/dev/null \
  || fail "pruned files still in manifest"
ok "a file removed from the release is pruned"

[[ "$(sha "$dest/skills/my-own-skill/SKILL.md") $(sha "$dest/agents/my-agent.md") $(sha "$dest/hooks/my-hook.sh")" == "$user_sums" ]] \
  || fail "user-created file changed"
jq -e '[.files[].path] | (index(["skills/my-own-skill/SKILL.md"]) == null) and (index(["agents/my-agent.md"]) == null)' "$mf" >/dev/null \
  || fail "user-created file adopted into manifest"
ok "user-created files are untouched and untracked"

[[ ! -e "$dest/hooks/zz-retired.sh" ]] || fail "retired hook file not pruned"
s="$dest/settings.json"
jq -e . "$s" >/dev/null || fail "settings.json invalid after update"
jq -e '[.. | .command? | strings | select(endswith("zz-retired.sh"))] | length == 0' "$s" >/dev/null || fail "retired hook still registered"
jq -e '[.hooks.Stop[]?.hooks[].command] == ["bash /opt/consumer-stop.sh"]' "$s" >/dev/null || fail "consumer Stop hook not preserved: $(jq -c .hooks.Stop "$s")"
jq -e '[.hooks.PreToolUse[].hooks[].command] | index(["bash /opt/consumer-guard.sh"]) != null' "$s" >/dev/null || fail "consumer PreToolUse hook lost"
jq -e '.permissions.allow == ["Edit(foo)"]' "$s" >/dev/null || fail "non-hook settings key lost"
ok "a retired hook is unregistered and pruned; consumer hooks are preserved"

# ── 4. --prune-legacy removes tombstoned pre-manifest skill dirs ─────────────
run --prune-legacy > "$tmp/out3" || { cat "$tmp/out3"; fail "--prune-legacy failed"; }
[[ ! -e "$dest/skills/security-and-hardening" ]] || fail "--prune-legacy left the tombstoned dir (or an empty parent)"
grep -q 'remove skills/security-and-hardening/references/x.md (retired skill security-and-hardening (--prune-legacy))' "$tmp/out3" \
  || fail "--prune-legacy did not list each file"
[[ -f "$dest/skills/my-own-skill/SKILL.md" ]] || fail "--prune-legacy touched a non-tombstoned user skill"
ok "--prune-legacy lists and removes retired skill dirs, then empty dirs"

# ── 5. --force overwrites a user-modified file ───────────────────────────────
run --force > "$tmp/out4" || { cat "$tmp/out4"; fail "--force failed"; }
cmp -s "$dest/skills/autoresearch/SKILL.md" "$rel/.claude/skills/autoresearch/SKILL.md" || fail "--force did not overwrite"
grep -q 'overwrite skills/autoresearch/SKILL.md (--force)' "$tmp/out4" || fail "--force overwrite not reported"
ok "--force overwrites a user-modified file"

# ── 6. Uninstall ─────────────────────────────────────────────────────────────
printf '\nmodified again\n' >> "$dest/skills/autoresearch/SKILL.md"
before="$(snap "$dest")"
run --uninstall --dry-run > "$tmp/out-udry" || { cat "$tmp/out-udry"; fail "uninstall --dry-run failed"; }
[[ "$(snap "$dest")" == "$before" ]] || fail "uninstall --dry-run modified the destination"
grep -q '\[dry-run\] remove agents/engineer.md' "$tmp/out-udry" || fail "uninstall dry-run did not list removals"
grep -q '\[dry-run\] unregister hook: bash .*/hooks/block-bad-bash.sh' "$tmp/out-udry" || fail "uninstall dry-run did not list hook entries"
ok "uninstall --dry-run reports and changes nothing"

run --uninstall > "$tmp/out5" || { cat "$tmp/out5"; fail "uninstall failed"; }
[[ ! -e "$mf" ]] || fail "manifest not removed"
[[ ! -e "$dest/agents/engineer.md" && ! -e "$dest/hooks/block-bad-bash.sh" && ! -e "$dest/commands/state.md" ]] || fail "owned files not removed"
grep -q 'modified again' "$dest/skills/autoresearch/SKILL.md" || fail "modified file removed by uninstall"
grep -q 'keep skills/autoresearch/SKILL.md — modified locally' "$tmp/out5" || fail "uninstall did not name the kept file"
grep -q '^  remove agents/engineer.md$' "$tmp/out5" || fail "uninstall did not list removed files"
[[ "$(sha "$dest/skills/my-own-skill/SKILL.md") $(sha "$dest/agents/my-agent.md") $(sha "$dest/hooks/my-hook.sh")" == "$user_sums" ]] \
  || fail "uninstall touched user-created files"
[[ -n "$(find "$dest/hooks" -name 'block-bad-bash.sh.bak.*')" ]] || fail "uninstall removed the hook backup"
left="$(cd "$dest" && find skills -type d -empty)"
[[ -z "$left" ]] || fail "empty directories left behind: $left"
jq -e . "$s" >/dev/null || fail "settings.json invalid after uninstall"
jq -e '[.. | .command? | strings] | sort == ["bash /opt/consumer-guard.sh", "bash /opt/consumer-stop.sh"]' "$s" >/dev/null \
  || fail "uninstall left AgenticOS hooks or removed consumer ones: $(jq -c .hooks "$s")"
jq -e '.permissions.allow == ["Edit(foo)"]' "$s" >/dev/null || fail "uninstall lost a non-hook settings key"
grep -q 'unregister hook: bash .*/hooks/session-state-inject.sh' "$tmp/out5" || fail "uninstall did not list unregistered hooks"
ok "uninstall removes owned files + hook entries only, keeps modified/user files, leaves valid JSON"

# Uninstall of a settings.json holding only AgenticOS hooks leaves `{}`.
dest2="$tmp/only-ours/.claude"
HOME="$home" CLAUDE_DIR="$dest2" bash "$rel/install.sh" >/dev/null 2>&1 || fail "second install failed"
HOME="$home" CLAUDE_DIR="$dest2" bash "$rel/install.sh" --uninstall >/dev/null 2>&1 || fail "second uninstall failed"
jq -e '. == {}' "$dest2/settings.json" >/dev/null || fail "AgenticOS-only settings.json not reduced to {}: $(cat "$dest2/settings.json")"
[[ -z "$(find "$dest2" -type f ! -name settings.json)" ]] || fail "uninstall left files: $(find "$dest2" -type f)"
ok "uninstall of a pure AgenticOS install leaves only an empty settings.json"

# ── 7. Pre-manifest install adoption ─────────────────────────────────────────
dest3="$tmp/legacy/.claude"
mkdir -p "$dest3"
cp -R "$rel/.claude/skills" "$dest3/skills"
cp -R "$rel/.claude/hooks" "$dest3/hooks"
printf '\nlegacy edit\n' >> "$dest3/skills/autoresearch/SKILL.md"
printf '\n# legacy hook edit\n' >> "$dest3/hooks/survey-before-act.sh"
HOME="$home" CLAUDE_DIR="$dest3" bash "$rel/install.sh" > "$tmp/out6" 2>&1 || { cat "$tmp/out6"; fail "legacy adoption failed"; }
grep -q 'legacy edit' "$dest3/skills/autoresearch/SKILL.md" || fail "legacy differing file overwritten"
grep -q 'keep skills/autoresearch/SKILL.md — differs from the release copy and predates the manifest' "$tmp/out6" \
  || fail "legacy differing file not named"
cmp -s "$dest3/hooks/survey-before-act.sh" "$rel/.claude/hooks/survey-before-act.sh" || fail "legacy hook not refreshed"
[[ -f "$dest3/.agentic-os-manifest.json" ]] || fail "legacy install not adopted into a manifest"
ok "pre-manifest install is adopted: differing files kept + named, hooks refreshed"

# ── 8. Codex roots ───────────────────────────────────────────────────────────
cx="$home/.codex"; cs="$home/.agents/skills"
runx() { HOME="$home" CODEX_HOME="$cx" CODEX_SKILLS_DIR="$cs" bash "$rel/install.sh" --codex "$@" 2>&1; }
runx > "$tmp/outx1" || { cat "$tmp/outx1"; fail "codex install failed"; }
for m in "$cx/.agentic-os-manifest.json" "$cs/.agentic-os-manifest.json"; do
  jq -e '.platform == "codex" and (.files | length) > 0' "$m" >/dev/null || fail "codex manifest missing/invalid: $m"
done
jq -e '[.files[].path] | index(["agents/engineer.toml"]) != null and index(["hooks/session-state-inject.sh"]) != null' \
  "$cx/.agentic-os-manifest.json" >/dev/null || fail "codex config manifest incomplete"
jq -e '[.files[].path] | index(["autoresearch/SKILL.md"]) != null' "$cs/.agentic-os-manifest.json" >/dev/null \
  || fail "codex skills manifest not relative to the skills dir"
jq '.hooks.Stop = [{"hooks":[{"type":"command","command":"bash /opt/user-stop.sh"}]}]' "$cx/hooks.json" > "$cx/hooks.json.tmp"
mv "$cx/hooks.json.tmp" "$cx/hooks.json"
printf 'mine\n' > "$cs/zz-user-note.md"
runx --uninstall > "$tmp/outx2" || { cat "$tmp/outx2"; fail "codex uninstall failed"; }
[[ ! -e "$cx/agents/engineer.toml" && ! -e "$cs/autoresearch/SKILL.md" ]] || fail "codex owned files not removed"
[[ -f "$cs/zz-user-note.md" ]] || fail "codex uninstall removed a user file"
jq -e '.hooks == {"Stop":[{"hooks":[{"type":"command","command":"bash /opt/user-stop.sh"}]}]}' "$cx/hooks.json" >/dev/null \
  || fail "codex uninstall: wrong hooks.json $(jq -c . "$cx/hooks.json")"
ok "codex install writes per-root manifests; uninstall removes owned files and AgenticOS hook groups only"

# ── 9. Argument guards ───────────────────────────────────────────────────────
if run --uninstall --force >/dev/null; then fail "--uninstall --force should be rejected"; fi
ok "--uninstall rejects --force"

echo "install-lifecycle-test: OK ($P checks)"
