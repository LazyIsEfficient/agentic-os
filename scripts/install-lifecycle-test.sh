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

# Snapshot the checkout once: tracked + untracked files, minus ignored ones
# (runtime files that concurrent sessions' hooks write into .claude/, such as
# reviews/, session-state.checkpoints, survey-guard.warns). Every install below
# runs from this copy, so nothing editing the checkout mid-run can change what
# this run tests. Only read-only git queries (tags, archive) use $REPO.
SRCREPO="$tmp/src"
mkdir -p "$SRCREPO"
if git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  (cd "$REPO" && git ls-files -z -co --exclude-standard \
     | while IFS= read -r -d '' f; do if [[ -e "$f" || -L "$f" ]]; then printf '%s\0' "$f"; fi; done \
     | tar --null -T - -cf -) | tar -xf - -C "$SRCREPO"
else
  cp -R "$REPO/." "$SRCREPO/"
fi

P=0
fail() { echo "FAIL install-lifecycle: $*" >&2; exit 1; }
ok() { printf 'PASS  %s\n' "$1"; P=$((P + 1)); }

if command -v shasum &>/dev/null; then SHA=(shasum -a 256); else SHA=(sha256sum); fi
sha() { "${SHA[@]}" "$1" | awk '{print $1}'; }

# Content snapshot of a tree (dirs, symlinks, file hashes) for no-change
# assertions. NUL-safe: the tree holds a file whose name contains a newline.
snap() {
  (cd "$1" && find . -type d -print0 | LC_ALL=C sort -z | tr '\0' '\n'
   find . -type l -print0 | LC_ALL=C sort -z | tr '\0' '\n'
   find . -type f -print0 | LC_ALL=C sort -z | xargs -0 "${SHA[@]}")
}

# Add a raw entry to a manifest's files array (simulates a hostile or older manifest).
inject_manifest_entry() {
  local m="$1" path="$2" h="$3"
  awk -v p="$path" -v h="$h" '{ print } /"files": \[/ { printf "    {\"path\": \"%s\", \"sha256\": \"%s\"},\n", p, h }' \
    "$m" > "$m.tmp" && mv "$m.tmp" "$m"
}

# ── Build release A ───────────────────────────────────────────────────────────
rel="$tmp/rel"
mkdir -p "$rel/scripts/lib" "$rel/assets"
cp "$SRCREPO/install.sh" "$SRCREPO/install.ps1" "$SRCREPO/CLAUDE.md" "$rel/"
cp "$SRCREPO/scripts/validate.sh" "$SRCREPO/scripts/build-claude-md.sh" "$rel/scripts/"
cp "$SRCREPO/scripts/lib/install-hook-settings.sh" "$rel/scripts/lib/"
cp -R "$SRCREPO/.claude" "$rel/.claude"
rm -rf "$rel/.claude/memory" "$rel/.claude/ledger" "$rel/.claude/worktrees"
cp -R "$SRCREPO/docs" "$rel/docs"
cp -R "$SRCREPO/assets/consumer" "$rel/assets/consumer"
cp "$SRCREPO/assets/release-hashes.txt" "$rel/assets/release-hashes.txt"

printf 'dropped in release B\n' > "$rel/.claude/skills/autoresearch/zz-dropped.txt"
printf 'dropped in release B, edited locally\n' > "$rel/.claude/skills/autoresearch/zz-dropped-edited.txt"
# A skill release B retires (and tombstones), so --prune-legacy meets a tracked dir.
mkdir -p "$rel/.claude/skills/zz-tomb"
printf '%s\n' '---' 'name: zz-tomb' \
  'description: Lifecycle-test fixture skill that release B retires. Use only in the installer test.' \
  'when_to_use: |' '  Never; it exists only so the installer test can retire it.' '---' '' '# zz-tomb' '' 'Fixture.' \
  > "$rel/.claude/skills/zz-tomb/SKILL.md"
# zz-retired.sh is retired via RETIRED_HOOKS; zz-retired2.sh is dropped WITHOUT
# being listed (the installer must derive it from the manifest).
add_hook_reg() {
  jq --arg c "$2" '.hooks.Stop = ((.hooks.Stop // []) + [{"hooks":[{"type":"command","command":$c}]}])' \
    "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
for h in zz-retired.sh zz-retired2.sh; do
  printf '#!/usr/bin/env bash\nexit 0\n' > "$rel/.claude/hooks/$h"
  add_hook_reg "$rel/assets/consumer/claude-settings.json" "bash \$HOME/.claude/hooks/$h"
  add_hook_reg "$rel/.claude/settings.json" "bash .claude/hooks/$h"
done

run() { HOME="$home" CLAUDE_DIR="$dest" bash "$rel/install.sh" "$@" 2>&1; }
runat() { local d="$1"; shift; HOME="$home" CLAUDE_DIR="$d" bash "$rel/install.sh" "$@" 2>&1; }

# Pre-manifest leftovers: a retired (tombstoned) skill from an old install.
mkdir -p "$dest/skills/security-and-hardening/references"
printf 'old\n' > "$dest/skills/security-and-hardening/SKILL.md"
printf 'old\n' > "$dest/skills/security-and-hardening/references/x.md"
# Those two are (simulated) earlier-release copies; the note is the user's.
for f in skills/security-and-hardening/SKILL.md skills/security-and-hardening/references/x.md; do
  printf '%s  %s\n' "$(sha "$dest/$f")" "$f" >> "$rel/assets/release-hashes.txt"
done
printf 'my own notes\n' > "$dest/skills/security-and-hardening/my-notes.md"

# ── 1. Fresh install writes the manifest ─────────────────────────────────────
run > "$tmp/out1" || { cat "$tmp/out1"; fail "fresh install failed"; }
mf="$dest/.agentic-os-manifest.json"
[[ -f "$mf" ]] || fail "fresh install wrote no manifest"
jq -e . "$mf" >/dev/null || fail "manifest is not valid JSON"
want_ver="$(sed -nE 's/^VERSION="([^"]*)".*/\1/p' "$SRCREPO/install.sh")"
jq -e --arg v "$want_ver" '.schema == 1 and .version == $v and .platform == "claude" and .source == "local-clone"' "$mf" >/dev/null \
  || fail "manifest header wrong: $(jq -c 'del(.files)' "$mf")"
want_n="$( (cd "$rel/.claude" && find skills agents hooks -type f; ls commands/skill-new.md commands/agent-new.md commands/state.md) | wc -l | tr -d ' ')"
[[ "$(jq '.files | length' "$mf")" == "$want_n" ]] || fail "manifest lists $(jq '.files | length' "$mf") files, release has $want_n"
jq -e '.files | all(.path | test("^(skills|agents|hooks|commands)/"))' "$mf" >/dev/null || fail "manifest path outside install surfaces"
eng_sha="$(jq -r '.files[] | select(.path == "agents/engineer.md") | .sha256' "$mf")"
[[ "$eng_sha" == "$(sha "$dest/agents/engineer.md")" ]] || fail "manifest sha256 does not match installed file"
jq -e '[.files[].path] | index(["skills/security-and-hardening/SKILL.md"]) == null' "$mf" >/dev/null || fail "legacy skill adopted into manifest"
grep -q 'retired skill directory skills/security-and-hardening still holds 2 AgenticOS file' "$tmp/out1" || fail "no --prune-legacy hint for tombstoned skill"
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
chmod 600 "$dest/hooks/my-hook.sh"
jq '.hooks.Stop += [{"hooks":[{"type":"command","command":"bash /opt/consumer-stop.sh"}]}]
    | .hooks.PreToolUse += [{"matcher":"Bash","hooks":[{"type":"command","command":"bash /opt/consumer-guard.sh"}]}]
    | .permissions = {"allow":["Edit(foo)"]}' "$dest/settings.json" > "$dest/settings.json.tmp"
mv "$dest/settings.json.tmp" "$dest/settings.json"
user_sums="$(sha "$dest/skills/my-own-skill/SKILL.md") $(sha "$dest/agents/my-agent.md") $(sha "$dest/hooks/my-hook.sh")"
printf '\nedited\n' >> "$dest/skills/autoresearch/zz-dropped-edited.txt"
printf '\nedited\n' >> "$dest/skills/zz-tomb/SKILL.md"
printf 'mine\n' > "$dest/skills/zz-tomb/extra.md"

# Hostile manifest entries (path-traversal + root files), each with the
# file's current hash, so only the path checks stand between them and rm.
printf 'canary\n' > "$dest/CANARY.md"
inject_manifest_entry "$mf" "settings.json" "$(sha "$dest/settings.json")"
inject_manifest_entry "$mf" "skills/../CANARY.md" "$(sha "$dest/CANARY.md")"
inject_manifest_entry "$mf" "CLAUDE.md" "$(sha "$dest/CANARY.md")"
mkdir -p "$dest/memory"
printf 'canary\n' > "$dest/memory/MEMORY.md"
inject_manifest_entry "$mf" "memory/MEMORY.md" "$(sha "$dest/memory/MEMORY.md")"
printf 'canary\n' > "$dest/CLAUDE.md"
# Reviewer PoC: a newline in a legacy file name must not aim rm at $dest/CANARY2.md.
printf 'canary\n' > "$dest/CANARY2.md"
touch "$dest/skills/security-and-hardening/x"$'\n'"CANARY2.md"

# ── Release B ─────────────────────────────────────────────────────────────────
printf '\n<!-- lifecycle-test: release B -->\n' >> "$rel/.claude/agents/engineer.md"
rm "$rel/.claude/skills/autoresearch/zz-dropped.txt" "$rel/.claude/skills/autoresearch/zz-dropped-edited.txt" \
  "$rel/.claude/hooks/zz-retired.sh" "$rel/.claude/hooks/zz-retired2.sh"
rm -r "$rel/.claude/skills/zz-tomb"
for f in "$rel/assets/consumer/claude-settings.json" "$rel/.claude/settings.json"; do
  jq '.hooks.Stop |= map(select(any(.hooks[]; .command | test("zz-retired2?\\.sh$")) | not))
      | if .hooks.Stop == [] then del(.hooks.Stop) else . end' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
done
sed -e 's/^TOMBSTONES="/TOMBSTONES="zz-tomb /' "$rel/scripts/validate.sh" > "$rel/scripts/validate.sh.tmp"
mv "$rel/scripts/validate.sh.tmp" "$rel/scripts/validate.sh"
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
[[ "$(ls -l "$dest/hooks/my-hook.sh" | cut -c1-10)" == "-rw-------" ]] || fail "update changed the mode of a user's own hook file"
ok "a user's own file in hooks/ keeps its mode (no blanket chmod +x)"

[[ ! -e "$dest/skills/autoresearch/zz-dropped.txt" ]] || fail "file dropped from release not pruned"
grep -q 'remove skills/autoresearch/zz-dropped.txt (no longer shipped)' "$tmp/out2" || fail "prune not reported"
grep -q 'edited' "$dest/skills/autoresearch/zz-dropped-edited.txt" || fail "user-edited file dropped by the release was deleted"
grep -q 'keep skills/autoresearch/zz-dropped-edited.txt — no longer shipped, but modified locally' "$tmp/out2" \
  || fail "kept dropped file not named"
jq -e '[.files[].path] | index(["skills/autoresearch/zz-dropped-edited.txt"]) != null' "$mf" >/dev/null \
  || fail "kept dropped file no longer tracked"
ok "a dropped file the user edited is kept, named, and stays tracked"

for c in CANARY.md CLAUDE.md settings.json memory/MEMORY.md; do [[ -f "$dest/$c" ]] || fail "hostile manifest entry deleted $c"; done
grep -q "skip settings.json — unsafe path" "$tmp/out2" || fail "hostile root entry not reported"
grep -q "skip skills/../CANARY.md — unsafe path" "$tmp/out2" || fail "hostile .. entry not reported"
grep -q "skip memory/MEMORY.md — unsafe path" "$tmp/out2" || fail "entry outside the shipped dirs not reported"
jq -e '[.files[].path] | (index(["settings.json"]) == null) and (index(["CLAUDE.md"]) == null)' "$mf" >/dev/null \
  || fail "hostile entries re-recorded in the manifest"
ok "manifest entries outside the shipped dirs (root files, ..) are never removed"
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
jq -e '[.. | .command? | strings | select(endswith("zz-retired2.sh"))] | length == 0' "$s" >/dev/null \
  || fail "hook dropped without a RETIRED_HOOKS entry still registered"
[[ ! -e "$dest/hooks/zz-retired2.sh" ]] || fail "unlisted retired hook file not pruned"
jq -e '[.hooks.Stop[]?.hooks[].command] | index(["bash /opt/consumer-stop.sh"]) != null' "$s" >/dev/null || fail "consumer Stop hook not preserved: $(jq -c .hooks.Stop "$s")"
jq -e '[.hooks.PreToolUse[].hooks[].command] | index(["bash /opt/consumer-guard.sh"]) != null' "$s" >/dev/null || fail "consumer PreToolUse hook lost"
jq -e '.permissions.allow == ["Edit(foo)"]' "$s" >/dev/null || fail "non-hook settings key lost"
ok "a retired hook is unregistered and pruned; consumer hooks are preserved"

# ── 4. --prune-legacy removes tombstoned pre-manifest skill dirs ─────────────
run --prune-legacy > "$tmp/out3" || { cat "$tmp/out3"; fail "--prune-legacy failed"; }
[[ ! -e "$dest/skills/security-and-hardening/SKILL.md" && ! -e "$dest/skills/security-and-hardening/references" ]] \
  || fail "--prune-legacy left tombstoned files (or an empty references/ dir)"
grep -q 'remove skills/security-and-hardening/references/x.md (retired skill security-and-hardening (--prune-legacy))' "$tmp/out3" \
  || fail "--prune-legacy did not list each file"
[[ -f "$dest/skills/my-own-skill/SKILL.md" ]] || fail "--prune-legacy touched a non-tombstoned user skill"
ok "--prune-legacy lists and removes retired skill dirs, then empty dirs"

[[ -f "$dest/CANARY2.md" ]] || fail "newline file name in a tombstoned dir deleted \$DEST/CANARY2.md"
[[ -e "$dest/skills/security-and-hardening/x"$'\n'"CANARY2.md" ]] || fail "odd-named legacy file was removed instead of skipped"
grep -qF "skip $(printf '%q' "skills/security-and-hardening/x"$'\n'"CANARY2.md") — unsafe path" "$tmp/out3" \
  || fail "odd-named legacy file not reported"
ok "--prune-legacy never acts on a newline-bearing file name (reviewer PoC 1)"

grep -q 'edited' "$dest/skills/zz-tomb/SKILL.md" || fail "--prune-legacy deleted a tracked, user-edited file"
grep -q 'mine' "$dest/skills/zz-tomb/extra.md" || fail "--prune-legacy deleted a user file that is not an AgenticOS release copy"
grep -q 'keep skills/zz-tomb/extra.md — not an AgenticOS release file' "$tmp/out3" || fail "kept non-release legacy file not named"
grep -q 'my own notes' "$dest/skills/security-and-hardening/my-notes.md" || fail "--prune-legacy deleted the user's notes in a retired dir"
grep -q 'keep skills/security-and-hardening/my-notes.md — not an AgenticOS release file' "$tmp/out3" || fail "kept user note not named"
grep -q 'are not AgenticOS release files and were left alone' "$tmp/out3" || fail "summary does not report the kept non-release files"
ok "--prune-legacy removes only earlier-release copies; tracked edits and user files survive"

# ── 5. --force overwrites a user-modified file ───────────────────────────────
run --force > "$tmp/out4" || { cat "$tmp/out4"; fail "--force failed"; }
cmp -s "$dest/skills/autoresearch/SKILL.md" "$rel/.claude/skills/autoresearch/SKILL.md" || fail "--force did not overwrite"
grep -q 'overwrite skills/autoresearch/SKILL.md (--force)' "$tmp/out4" || fail "--force overwrite not reported"
ok "--force overwrites a user-modified file"
if grep -q 'skills/security-and-hardening still holds' "$tmp/out4"; then fail "keeps asking for --prune-legacy when only the user's files remain"; fi
grep -q 'retired skill directory skills/security-and-hardening holds only files that are not AgenticOS release files' "$tmp/out4" \
  || fail "no note that the remaining files are the user's"
ok "after a prune, a retired dir holding only the user's files is not flagged again"

# ── 6. Uninstall ─────────────────────────────────────────────────────────────
printf '\nmodified again\n' >> "$dest/skills/autoresearch/SKILL.md"
before="$(snap "$dest")"
run --uninstall --dry-run > "$tmp/out-udry" || { cat "$tmp/out-udry"; fail "uninstall --dry-run failed"; }
[[ "$(snap "$dest")" == "$before" ]] || fail "uninstall --dry-run modified the destination"
grep -q '\[dry-run\] remove agents/engineer.md' "$tmp/out-udry" || fail "uninstall dry-run did not list removals"
grep -q '\[dry-run\] unregister hook: bash .*/hooks/block-bad-bash.sh' "$tmp/out-udry" || fail "uninstall dry-run did not list hook entries"
ok "uninstall --dry-run reports and changes nothing"

# Hostile entries again, now aimed at uninstall's own path gates.
inject_manifest_entry "$mf" "settings.json" "$(sha "$dest/settings.json")"
inject_manifest_entry "$mf" "skills/../CANARY.md" "$(sha "$dest/CANARY.md")"
inject_manifest_entry "$mf" "memory/MEMORY.md" "$(sha "$dest/memory/MEMORY.md")"
run --uninstall > "$tmp/out5" || { cat "$tmp/out5"; fail "uninstall failed"; }
for c in CANARY.md settings.json memory/MEMORY.md; do [[ -f "$dest/$c" ]] || fail "uninstall followed a hostile manifest entry and deleted $c"; done
grep -q "skip skills/../CANARY.md — unsafe path" "$tmp/out5" || fail "uninstall did not report the hostile .. entry"
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
chmod 640 "$cx/hooks.json"
runx > "$tmp/outx1b" || { cat "$tmp/outx1b"; fail "codex reinstall failed"; }
[[ "$(ls -l "$cx/hooks.json" | cut -c1-10)" == "-rw-r-----" ]] || fail "codex hooks.json mode not preserved by the merge"
# Hostile entries under the Codex skills root (shared with other tools):
# a single-component name of a known (tombstoned) skill, another tool's dir,
# and memory/.
printf 'other tool\n' > "$cs/route"
mkdir -p "$cs/other-vendor-skill" "$cs/memory"
printf 'other tool\n' > "$cs/other-vendor-skill/SKILL.md"
printf 'canary\n' > "$cs/memory/MEMORY.md"
for e in route other-vendor-skill/SKILL.md memory/MEMORY.md; do
  inject_manifest_entry "$cs/.agentic-os-manifest.json" "$e" "$(sha "$cs/$e")"
done
# Another tool's skill under a retired name in the shared skills dir.
mkdir -p "$cs/standards-enforcer"
printf 'another vendor\n' > "$cs/standards-enforcer/SKILL.md"
runx --prune-legacy > "$tmp/outx1c" || { cat "$tmp/outx1c"; fail "codex --prune-legacy failed"; }
grep -q 'another vendor' "$cs/standards-enforcer/SKILL.md" || fail "codex --prune-legacy deleted another tool's skill"
grep -q 'keep standards-enforcer/SKILL.md — not an AgenticOS release file' "$tmp/outx1c" || fail "codex: kept foreign skill not named"
runx --uninstall > "$tmp/outx2" || { cat "$tmp/outx2"; fail "codex uninstall failed"; }
for e in route other-vendor-skill/SKILL.md memory/MEMORY.md; do
  [[ -f "$cs/$e" ]] || fail "codex uninstall followed a hostile manifest entry and deleted $e"
done
[[ ! -e "$cx/agents/engineer.toml" && ! -e "$cs/autoresearch/SKILL.md" ]] || fail "codex owned files not removed"
[[ -f "$cs/zz-user-note.md" ]] || fail "codex uninstall removed a user file"
jq -e '.hooks == {"Stop":[{"hooks":[{"type":"command","command":"bash /opt/user-stop.sh"}]}]}' "$cx/hooks.json" >/dev/null \
  || fail "codex uninstall: wrong hooks.json $(jq -c . "$cx/hooks.json")"
ok "codex install writes per-root manifests; uninstall removes owned files and AgenticOS hook groups only"
ok "codex merge keeps hooks.json's mode; hostile entries under the skills root are never removed"

cx2="$tmp/codex-bad/.codex"; cs2="$tmp/codex-bad/skills"
mkdir -p "$cx2"
printf '{not json' > "$cx2/hooks.json"
if HOME="$home" CODEX_HOME="$cx2" CODEX_SKILLS_DIR="$cs2" bash "$rel/install.sh" --codex > "$tmp/outx3" 2>&1; then
  fail "codex install passed on an unmergeable hooks.json"
fi
[[ ! -e "$cs2" && "$(cd "$cx2" && find . -type f)" == "./hooks.json" ]] || fail "codex install copied files before failing on hooks.json"
ok "an unmergeable Codex hooks.json fails before anything is copied"

# ── 9. Symlinks never lead writes or removals outside the root (PoC 3) ─────
d5="$tmp/symlinked/.claude"
runat "$d5" > "$tmp/out9" || { cat "$tmp/out9"; fail "install for symlink case failed"; }
outside="$tmp/outside"
mkdir -p "$outside"
mv "$d5/skills/autoresearch" "$outside/autoresearch"
ln -s "$outside/autoresearch" "$d5/skills/autoresearch"
printf '\nedited outside\n' >> "$outside/autoresearch/SKILL.md"
printf 'my own hook\n' > "$outside/hook.sh"
rm "$d5/hooks/block-bad-bash.sh"
ln -s "$outside/hook.sh" "$d5/hooks/block-bad-bash.sh"
before="$(snap "$outside")"
settings_before="$(sha "$d5/settings.json")"
manifest_before="$(sha "$d5/.agentic-os-manifest.json")"
# A shipped hook that cannot be placed at the release SHA must not be
# registered: the run fails, settings.json and the manifest stay as they were.
if runat "$d5" --force > "$tmp/out9b"; then fail "--force succeeded though a shipped hook could not be placed"; fi
[[ "$(snap "$outside")" == "$before" ]] || fail "update/--force wrote through a symlink outside the root"
grep -q 'skip skills/autoresearch/SKILL.md — unsafe path' "$tmp/out9b" || fail "symlinked skill dir not reported"
grep -q 'skip hooks/block-bad-bash.sh — unsafe path' "$tmp/out9b" || fail "symlinked hook file not reported"
grep -q 'hook hooks/block-bad-bash.sh is not installed at the release version' "$tmp/out9b" || fail "unplaced hook not named"
[[ "$(sha "$d5/settings.json")" == "$settings_before" ]] || fail "hooks registered although a shipped hook was not installed"
[[ "$(sha "$d5/.agentic-os-manifest.json")" == "$manifest_before" ]] || fail "manifest rewritten after a failed hook install"
if runat "$d5" --dry-run > "$tmp/out9d"; then fail "dry run succeeded though a shipped hook would be skipped"; fi
grep -q 'hook hooks/block-bad-bash.sh would be skipped' "$tmp/out9d" || fail "dry run did not name the hook it would skip"
runat "$d5" --uninstall > "$tmp/out9c" || { cat "$tmp/out9c"; fail "uninstall with symlinks failed"; }
[[ "$(snap "$outside")" == "$before" ]] || fail "uninstall removed files through a symlink"
ok "update, --force and uninstall never write or delete through a symlink"

# ── 9b. A symlinked shipped top-level dir (stow-style) fails once, loudly ─
d12="$tmp/stowed/.claude"
runat "$d12" >/dev/null || fail "install for stow case failed"
mv "$d12/hooks" "$outside/stowed-hooks"
ln -s "$outside/stowed-hooks" "$d12/hooks"
before="$(snap "$d12")"; before_out="$(snap "$outside/stowed-hooks")"
for mode in "" --dry-run --uninstall; do
  # shellcheck disable=SC2086  # $mode is empty or one flag
  if runat "$d12" $mode > "$tmp/out12"; then fail "run ${mode:-install} succeeded with a symlinked hooks/"; fi
  grep -q "Error: $d12/hooks is a symlink" "$tmp/out12" || fail "${mode:-install}: no single error naming hooks/"
  if grep -q 'unsafe path' "$tmp/out12"; then fail "${mode:-install}: per-file skips instead of one error"; fi
  [[ "$(snap "$d12")" == "$before" && "$(snap "$outside/stowed-hooks")" == "$before_out" ]] || fail "${mode:-install} changed files despite the error"
done
ok "a symlinked shipped dir is refused once, up front, for install, dry run and uninstall"

# Only unsafe skips (no edits): the summary must not claim files were kept.
d13="$tmp/summary/.claude"
runat "$d13" >/dev/null || fail "install for summary case failed"
mv "$d13/skills/autoresearch" "$outside/autoresearch-13"
ln -s "$outside/autoresearch-13" "$d13/skills/autoresearch"
runat "$d13" > "$tmp/out13s" || { cat "$tmp/out13s"; fail "install with a symlinked skill dir failed"; }
grep -q 'path(s) were skipped as unsafe' "$tmp/out13s" || fail "summary does not report unsafe skips"
if grep -q 'you modified were kept' "$tmp/out13s"; then fail "summary claims modified files were kept for unsafe skips"; fi
ok "the closing summary reports unsafe skips, not kept edits"

# ── 10. Without jq: retired hooks are kept, uninstall fails closed ──────────
nojq="$tmp/nojq-bin"
mkdir -p "$nojq"
for bindir in /usr/bin /bin; do
  for f in "$bindir"/*; do
    b="${f##*/}"
    [[ "$b" == jq || -e "$nojq/$b" ]] || ln -s "$f" "$nojq/$b"
  done
done
d6="$tmp/nojq/.claude"
runat "$d6" >/dev/null || fail "install for no-jq case failed"
printf '#!/usr/bin/env bash\nexit 0\n' > "$d6/hooks/zz-old.sh"
inject_manifest_entry "$d6/.agentic-os-manifest.json" "hooks/zz-old.sh" "$(sha "$d6/hooks/zz-old.sh")"
PATH="$nojq" HOME="$home" CLAUDE_DIR="$d6" "$BASH" "$rel/install.sh" > "$tmp/out10" 2>&1 \
  || { cat "$tmp/out10"; fail "no-jq update failed"; }
[[ -f "$d6/hooks/zz-old.sh" ]] || fail "no-jq update deleted a retired hook it could not unregister"
grep -q 'keep retired hook hooks/zz-old.sh — jq is required' "$tmp/out10" || fail "no-jq retired hook not reported"
grep -q '"hooks/zz-old.sh"' "$d6/.agentic-os-manifest.json" || fail "no-jq kept hook dropped from the manifest"
if PATH="$nojq" HOME="$home" CLAUDE_DIR="$d6" "$BASH" "$rel/install.sh" --uninstall > "$tmp/out10b" 2>&1; then
  fail "no-jq uninstall should fail closed"
fi
[[ -f "$d6/agents/engineer.md" && -f "$d6/.agentic-os-manifest.json" ]] || fail "no-jq uninstall removed files"
ok "without jq, retired hooks are kept and uninstall fails closed"

cx6="$tmp/nojq-codex/.codex"; cs6="$tmp/nojq-codex/skills"
mkdir -p "$cx6"
printf '{"hooks":{}}\n' > "$cx6/hooks.json"
CODEX_HOOKS_REGISTERED=true PATH="$nojq" HOME="$home" CODEX_HOME="$cx6" CODEX_SKILLS_DIR="$cs6" "$BASH" "$rel/install.sh" --codex > "$tmp/out10c" 2>&1 \
  || { cat "$tmp/out10c"; fail "no-jq codex install failed"; }
grep -q 'Hooks were NOT registered' "$tmp/out10c" || fail "no-jq codex install did not say hooks were not registered"
if grep -q 'Review and trust the new hooks' "$tmp/out10c"; then fail "no-jq codex install claims new hooks to trust"; fi
ok "a Codex install that could not register hooks says so"

# ── 11. A settings.json the merge rejects fails fast, before any copy ────────
d7="$tmp/badsettings/.claude"
mkdir -p "$d7"
printf '{not json' > "$d7/settings.json"
if runat "$d7" --dry-run > "$tmp/out11a"; then fail "dry run passed on an unmergeable settings.json"; fi
if runat "$d7" > "$tmp/out11b"; then fail "install passed on an unmergeable settings.json"; fi
[[ "$(cd "$d7" && find . -type f)" == "./settings.json" && "$(cat "$d7/settings.json")" == '{not json' ]] \
  || fail "install changed the destination before failing on settings.json: $(cd "$d7" && find . | head -5)"
ok "an unmergeable settings.json fails dry-run and install before anything is copied"

# ── 12. Hook backups never collide ───────────────────────────────────────────
d8="$tmp/baks/.claude"
runat "$d8" >/dev/null || fail "install for backup case failed"
for i in 1 2; do
  printf '\n# tweak %s\n' "$i" >> "$d8/hooks/survey-before-act.sh"
  runat "$d8" >/dev/null || fail "backup run $i failed"
done
[[ "$(find "$d8/hooks" -name 'survey-before-act.sh.bak.*' | wc -l | tr -d ' ')" == 2 ]] || fail "hook backups collided"
ok "each hook refresh writes its own backup"

# ── 13. Writes never follow a planted link (round-2 PoC) ────────────────────
d9="$tmp/links/.claude"
runat "$d9" >/dev/null || fail "install for link case failed"
printf 'CANARY\n' > "$outside/canaryA"
ln -s "$outside/canaryA" "$d9/.agentic-os-manifest.json.tmp"
runat "$d9" >/dev/null || fail "reinstall with a planted .tmp link failed"
[[ "$(cat "$outside/canaryA")" == "CANARY" ]] || fail "manifest write followed a planted .tmp symlink"
[[ -f "$d9/.agentic-os-manifest.json" && ! -L "$d9/.agentic-os-manifest.json" ]] || fail "manifest is not a regular file"
h9="$d9/hooks/survey-before-act.sh"
printf 'USER-CANARY-B\n' > "$outside/canaryB"
rm "$h9"
ln "$outside/canaryB" "$h9"
runat "$d9" > "$tmp/out13" || { cat "$tmp/out13"; fail "reinstall with a hard-linked hook failed"; }
[[ "$(cat "$outside/canaryB")" == "USER-CANARY-B" ]] || fail "hook refresh wrote through a hard link"
cmp -s "$h9" "$rel/.claude/hooks/survey-before-act.sh" || fail "hard-linked hook not refreshed"
grep -q 'hooks/survey-before-act.sh was hard-linked elsewhere' "$tmp/out13" || fail "hard link not reported"
mv "$d9/.agentic-os-manifest.json" "$outside/manifest-real"
ln -s "$outside/manifest-real" "$d9/.agentic-os-manifest.json"
if runat "$d9" >/dev/null; then fail "install accepted a symlinked manifest"; fi
rm "$d9/.agentic-os-manifest.json"
printf '{}\n' > "$outside/settings-real"
mv "$d9/settings.json" "$outside/settings-old"
ln -s "$outside/settings-real" "$d9/settings.json"
if runat "$d9" >/dev/null; then fail "install rewrote a symlinked settings.json"; fi
[[ "$(cat "$outside/settings-real")" == "{}" ]] || fail "symlinked settings.json target was written"
ok "manifest, hook and settings writes never go through a planted symlink or hard link"

# ── 14. Adoption recognises earlier-release copies (no spurious keeps) ──────
# Simulated prior release: an install whose files are older AgenticOS copies
# listed in assets/release-hashes.txt, plus one genuine user edit.
d10="$tmp/prior/.claude"
mkdir -p "$d10"
cp -R "$rel/.claude/skills" "$rel/.claude/agents" "$rel/.claude/hooks" "$d10/"
printf '\n<!-- an older AgenticOS release -->\n' >> "$d10/agents/engineer.md"
printf '\n<!-- an older AgenticOS release -->\n' >> "$d10/skills/autoresearch/SKILL.md"
printf '\nmy own edit\n' >> "$d10/agents/code-reviewer.md"
for f in agents/engineer.md skills/autoresearch/SKILL.md; do
  printf '%s  %s\n' "$(sha "$d10/$f")" "$f" >> "$rel/assets/release-hashes.txt"
done
runat "$d10" > "$tmp/out14" || { cat "$tmp/out14"; fail "prior-release adoption failed"; }
cmp -s "$d10/agents/engineer.md" "$rel/.claude/agents/engineer.md" || fail "earlier-release copy kept instead of updated"
grep -q 'update agents/engineer.md' "$tmp/out14" || fail "earlier-release copy not reported as updated"
grep -q 'my own edit' "$d10/agents/code-reviewer.md" || fail "a genuine user edit was overwritten on adoption"
[[ "$(grep -c '⚠ keep ' "$tmp/out14")" == 1 ]] || fail "spurious keeps on adoption: $(grep '⚠ keep ' "$tmp/out14")"
runat "$d10" > "$tmp/out14b" || fail "second run after adoption failed"
[[ "$(grep -c '⚠ keep ' "$tmp/out14b")" == 1 ]] || fail "spurious keeps on the run after adoption: $(grep '⚠ keep ' "$tmp/out14b")"
ok "adoption updates earlier-release copies and keeps only genuine edits, on both runs"

# Real upgrade from the v3.0.1 release, when the tag is available locally.
if git -C "$REPO" rev-parse -q --verify 'refs/tags/v3.0.1' >/dev/null; then
  old="$tmp/v3.0.1"
  mkdir -p "$old"
  git -C "$REPO" archive v3.0.1 | tar -x -C "$old"
  d11="$tmp/from-v301/.claude"
  HOME="$home" CLAUDE_DIR="$d11" bash "$old/install.sh" > "$tmp/out15a" 2>&1 || { tail -5 "$tmp/out15a"; fail "v3.0.1 install failed"; }
  HOME="$home" CLAUDE_DIR="$d11" bash "$SRCREPO/install.sh" > "$tmp/out15b" 2>&1 || { tail -5 "$tmp/out15b"; fail "upgrade from v3.0.1 failed"; }
  HOME="$home" CLAUDE_DIR="$d11" bash "$SRCREPO/install.sh" > "$tmp/out15c" 2>&1 || { tail -5 "$tmp/out15c"; fail "second run after v3.0.1 upgrade failed"; }
  for o in "$tmp/out15b" "$tmp/out15c"; do
    if grep -q '⚠ keep ' "$o"; then fail "spurious keeps upgrading from v3.0.1: $(grep -c '⚠ keep ' "$o") e.g. $(grep -m1 '⚠ keep ' "$o")"; fi
  done
  ok "upgrade from the v3.0.1 release keeps nothing it should update (both runs)"
else
  echo "SKIP  upgrade from v3.0.1 (tag not available; git fetch --tags)"
fi

# ── 15. A new installer refuses an older release's library payload ─────────
if git -C "$REPO" rev-parse -q --verify 'refs/tags/v3.0.1' >/dev/null; then
  pay="$tmp/old-payload"
  mkdir -p "$pay"
  git -C "$REPO" archive v3.0.1 .claude assets/consumer scripts/validate.sh \
    scripts/lib/install-hook-settings.sh docs/awareness-harness-activation.md | tar -x -C "$pay"
  cp "$SRCREPO/install.sh" "$pay/install.sh"
  d14="$tmp/old-payload-home/.claude"
  mkdir -p "$d14"
  printf '{"permissions":{"allow":["Edit(foo)"]}}\n' > "$d14/settings.json"
  before="$(snap "$d14")"
  for mode in "" --dry-run --uninstall --codex; do
    # shellcheck disable=SC2086  # $mode is empty or one flag
    if HOME="$home" CLAUDE_DIR="$d14" CODEX_HOME="$d14/codex" CODEX_SKILLS_DIR="$d14/agents-skills" \
        bash "$pay/install.sh" $mode > "$tmp/out15" 2>&1; then
      fail "new install.sh ran ${mode:-install} over the v3.0.1 library"
    fi
    grep -q 'install-hook-settings.sh is older than this installer' "$tmp/out15" || fail "${mode:-install}: no clear library-mismatch error: $(tail -2 "$tmp/out15")"
    [[ "$(snap "$d14")" == "$before" ]] || fail "${mode:-install} over the v3.0.1 library wrote to the destination"
  done
  ok "a new install.sh over the v3.0.1 payload fails closed for install, dry run, uninstall and codex"
else
  echo "SKIP  new installer over the v3.0.1 payload (tag not available; git fetch --tags)"
fi

# ── 16. Project-scope Codex roots must be real dirs inside the project ─────
gx="$tmp/global-codex"
mkdir -p "$gx/.codex" "$gx/.agents/skills"
printf '{"hooks":{}}\n' > "$gx/.codex/hooks.json"
gbefore="$(snap "$gx")"
for case in codex agents skills; do
  pj="$tmp/proj-$case"
  mkdir -p "$pj"
  case "$case" in
    codex)  ln -s "$gx/.codex" "$pj/.codex" ;;
    agents) ln -s "$gx/.agents" "$pj/.agents" ;;
    skills) mkdir -p "$pj/.agents"; ln -s "$gx/.agents/skills" "$pj/.agents/skills" ;;
  esac
  for mode in "" --uninstall; do
    # shellcheck disable=SC2086  # $mode is empty or one flag
    if HOME="$gx" CODEX_PROJECT_DIR="$pj" bash "$rel/install.sh" --codex --project $mode > "$tmp/out16" 2>&1; then
      fail "project-scope ${mode:-install} followed a symlinked .$case"
    fi
    grep -q 'is a symlink. In project scope' "$tmp/out16" || fail "project-scope ${mode:-install}: no clear error for .$case: $(tail -1 "$tmp/out16")"
    [[ "$(snap "$gx")" == "$gbefore" ]] || fail "project-scope ${mode:-install} with a symlinked .$case touched the global Codex dirs"
  done
done
ok "project-scope Codex refuses a symlinked .codex / .agents / .agents/skills (install and uninstall)"

# ── 17. Whitespace in the Claude dir is refused before any write ─────────────
ws="$tmp/white space"
mkdir -p "$ws"
if HOME="$home" CLAUDE_DIR="$ws/.claude" bash "$rel/install.sh" > "$tmp/out17" 2>&1; then fail "install accepted a Claude dir with a space"; fi
grep -q 'resolves to a path with whitespace or shell metacharacters' "$tmp/out17" || fail "no clear whitespace error"
grep -q 'run with --uninstall and the same CLAUDE_DIR' "$tmp/out17" || fail "whitespace error does not say how to move an install"
[[ ! -e "$ws/.claude" ]] || fail "install wrote into a Claude dir with a space"
ln -s "$ws" "$tmp/nospace-link"
if HOME="$home" CLAUDE_DIR="$tmp/nospace-link/.claude" bash "$rel/install.sh" > "$tmp/out17b" 2>&1; then
  fail "install accepted a Claude dir that resolves to a path with a space"
fi
grep -q 'resolves to a path with whitespace or shell metacharacters' "$tmp/out17b" || fail "no clear error for a canonical path with a space"
[[ ! -e "$ws/.claude" ]] || fail "install wrote through a link into a path with a space"
ok "a Claude dir containing (or resolving to) whitespace is refused before any write"

# Reviewer PoC: a symlinked parent whose target name carries `;` and `$`
# would put an injected command into every registered hook.
inj="$tmp/"'x;echo${IFS}CANARY>f;y'
mkdir -p "$inj"
ln -s "$inj" "$tmp/plain-link"
if (cd "$tmp" && HOME="$home" CLAUDE_DIR="$tmp/plain-link/.claude" bash "$rel/install.sh" > "$tmp/out17i" 2>&1); then
  fail "install accepted a Claude dir that resolves to a path with shell metacharacters"
fi
grep -q 'resolves to a path with whitespace or shell metacharacters' "$tmp/out17i" || fail "no clear error for a canonical path with metacharacters"
[[ -z "$(ls -A "$inj")" && ! -e "$tmp/f" ]] || fail "install wrote into the metacharacter path"
ok "a Claude dir resolving to a path with ; or \$ is refused before any write (no hook-command injection)"

# An install made in a spaced dir before this check can still be uninstalled.
d17="$tmp/nsp/.claude"
runat "$d17" >/dev/null || fail "install for spaced-uninstall case failed"
mkdir -p "$tmp/sp ace"
mv "$tmp/nsp/.claude" "$tmp/sp ace/.claude"
sed "s#$tmp/nsp/.claude#$tmp/sp ace/.claude#g" "$tmp/sp ace/.claude/settings.json" > "$tmp/settings17"
mv "$tmp/settings17" "$tmp/sp ace/.claude/settings.json"
HOME="$home" CLAUDE_DIR="$tmp/sp ace/.claude" bash "$rel/install.sh" --uninstall > "$tmp/out17c" 2>&1 \
  || { tail -5 "$tmp/out17c"; fail "uninstall refused a Claude dir with a space"; }
[[ ! -e "$tmp/sp ace/.claude/agents/engineer.md" && ! -e "$tmp/sp ace/.claude/.agentic-os-manifest.json" ]] || fail "spaced uninstall left owned files"
jq -e '. == {}' "$tmp/sp ace/.claude/settings.json" >/dev/null || fail "spaced uninstall left hook entries: $(cat "$tmp/sp ace/.claude/settings.json")"
ok "an existing install in a dir with a space can still be uninstalled"

# ── 18. Preflight: odd TMPDIR, library exits, and a spoofed API marker ──────
shim="$tmp/gnu-mktemp"
mkdir -p "$shim" "$tmp/tmp@odd"
cat > "$shim/mktemp" <<'SHIM'
#!/bin/bash
# GNU semantics: bare mktemp [-d] honours TMPDIR.
if [[ $# -eq 0 ]]; then exec /usr/bin/mktemp "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX"; fi
if [[ $# -eq 1 && "$1" == "-d" ]]; then exec /usr/bin/mktemp -d "${TMPDIR:-/tmp}/tmp.XXXXXXXXXX"; fi
exec /usr/bin/mktemp "$@"
SHIM
chmod +x "$shim/mktemp"
d18="$tmp/oddtmp/.claude"
mkdir -p "$d18"
printf '{"hooks":{}}\n' > "$d18/settings.json"
PATH="$shim:$PATH" TMPDIR="$tmp/tmp@odd" HOME="$home" CLAUDE_DIR="$d18" bash "$rel/install.sh" > "$tmp/out18" 2>&1 \
  || { tail -5 "$tmp/out18"; fail "install with an @ in TMPDIR failed"; }
[[ -f "$d18/.agentic-os-manifest.json" ]] || fail "install with an @ in TMPDIR wrote no manifest"
ok "an unusual TMPDIR does not trip the settings preflight"

relx="$tmp/rel-exiting-lib"
cp -R "$rel" "$relx"
printf '%s\n' 'merge_claude_hook_settings() { echo "LIB-EXIT-MARKER" >&2; exit 3; }' >> "$relx/scripts/lib/install-hook-settings.sh"
d18b="$tmp/libexit/.claude"
mkdir -p "$d18b"
printf '{"hooks":{}}\n' > "$d18b/settings.json"
if HOME="$home" CLAUDE_DIR="$d18b" bash "$relx/install.sh" > "$tmp/out18b" 2>&1; then fail "install passed with a library that exits"; fi
grep -q 'LIB-EXIT-MARKER' "$tmp/out18b" || fail "the library's error was swallowed by the preflight"
grep -q 'settings.json cannot be merged' "$tmp/out18b" || fail "no preflight error when the library exits"
[[ "$(cd "$d18b" && find . -type f)" == "./settings.json" ]] || fail "files copied although the preflight failed"
ok "a library exit during preflight is reported, not silent, and nothing is copied"

rely="$tmp/rel-no-marker"
cp -R "$rel" "$rely"
grep -v '^AGENTIC_OS_HOOK_LIB_API=' "$rel/scripts/lib/install-hook-settings.sh" > "$rely/scripts/lib/install-hook-settings.sh"
d18c="$tmp/spoof/.claude"
if AGENTIC_OS_HOOK_LIB_API=2 HOME="$home" CLAUDE_DIR="$d18c" bash "$rely/install.sh" > "$tmp/out18c" 2>&1; then
  fail "the caller's AGENTIC_OS_HOOK_LIB_API satisfied the library gate"
fi
grep -q 'is older than this installer' "$tmp/out18c" || fail "no library-mismatch error with a spoofed marker"
[[ ! -e "$d18c" ]] || fail "install wrote with a spoofed library marker"
ok "the library API gate ignores a marker set in the caller's environment"

# ── 19. Argument guards ──────────────────────────────────────────────────────
if run --uninstall --force >/dev/null; then fail "--uninstall --force should be rejected"; fi
ok "--uninstall rejects --force"

echo "install-lifecycle-test: OK ($P checks)"
