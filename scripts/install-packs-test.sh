#!/usr/bin/env bash
# install-packs-test.sh — opt-in install packs (#278): a default install is
# core only; --with-<pack> adds a pack and the manifest's "packs" array keeps
# it; an install made before packs existed keeps the packs whose files it has;
# --without-<pack> drops a pack through the normal prune (unmodified files go,
# edited ones stay); Claude, Codex user and --codex --project roots; dry run;
# uninstall; usage errors.
#
# Every run uses a throwaway HOME with CLAUDE_DIR / CODEX_HOME /
# CODEX_SKILLS_DIR / CODEX_PROJECT_DIR / TMPDIR inside one mktemp dir; the real
# ~/.claude and ~/.codex are never touched, and the claude CLI is never run.
#
# The upgrade case installs with the pre-#278 install.sh from git history
# (BASE_REV). In a shallow clone without it, that case is SKIPped locally and
# FAILs when CI is set.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_REV="3dd4570"   # #298, the last install.sh before opt-in packs
# The git repo that holds BASE_REV (and the v3.0.1 tag). The /bin/bash 3
# re-run executes from a snapshot without .git, so it is handed the real repo.
GITREPO="${PACKS_TEST_GIT_REPO:-$REPO}"

if ! command -v jq &>/dev/null; then
  echo "install-packs-test: SKIP (jq not installed)" >&2
  exit 0
fi

tmp="$(cd "$(mktemp -d)" && pwd -P)"
[[ -n "$tmp" && "$tmp" == /* && -d "$tmp" ]] || { echo "install-packs-test: bad temp dir" >&2; exit 1; }
trap 'rm -rf "$tmp"' EXIT

P=0
SKIPPED=0
fail() { echo "FAIL install-packs: $*" >&2; exit 1; }
ok() { printf 'PASS  %s\n' "$1"; P=$((P + 1)); }

if command -v shasum &>/dev/null; then SHA=(shasum -a 256); else SHA=(sha256sum); fi
snap() {
  (cd "$1" && find . -type d -print0 | LC_ALL=C sort -z | tr '\0' '\n'
   find . -type l -print0 | LC_ALL=C sort -z | tr '\0' '\n'
   find . -type f -print0 | LC_ALL=C sort -z | xargs -0 "${SHA[@]}")
}

# Snapshot the checkout (tracked + untracked, minus ignored) so concurrent
# edits cannot change what this run tests.
SRCREPO="$tmp/src"
mkdir -p "$SRCREPO"
if git -C "$REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  (cd "$REPO" && git ls-files -z -co --exclude-standard \
     | while IFS= read -r -d '' f; do if [[ -e "$f" || -L "$f" ]]; then printf '%s\0' "$f"; fi; done \
     | tar --null -T - -cf -) | tar -xf - -C "$SRCREPO"
else
  cp -R "$REPO/." "$SRCREPO/"
fi

rel="$tmp/rel"
mkdir -p "$rel/scripts/lib" "$rel/assets"
cp "$SRCREPO/install.sh" "$SRCREPO/install.ps1" "$SRCREPO/CLAUDE.md" "$rel/"
cp "$SRCREPO/scripts/validate.sh" "$rel/scripts/"
cp "$SRCREPO/scripts/lib/install-hook-settings.sh" "$rel/scripts/lib/"
cp -R "$SRCREPO/.claude" "$rel/.claude"
rm -rf "$rel/.claude/memory" "$rel/.claude/ledger" "$rel/.claude/worktrees" "$rel/.claude/reviews"
cp -R "$SRCREPO/docs" "$rel/docs"
cp -R "$SRCREPO/assets/consumer" "$rel/assets/consumer"
cp -R "$SRCREPO/assets/packs" "$rel/assets/packs"
cp "$SRCREPO/assets/release-hashes.txt" "$rel/assets/release-hashes.txt"

# Pack entries, from the payload's own lists.
entries() { grep -vE '^[[:space:]]*(#|$)' "$rel/assets/packs/$1.txt"; }
[[ -n "$(entries marketing)" && -n "$(entries games)" ]] || fail "assets/packs/{marketing,games}.txt missing or empty"
for pk in marketing games; do
  entries "$pk" | grep -q '^skills/' || fail "$pk pack has no skill entry"
  entries "$pk" | grep -q '^agents/' || fail "$pk pack has no agent entry"
done

# Each case gets its own HOME; every path the installer can reach is inside it.
newhome() {
  local h="$tmp/h-$1"
  [[ -n "$1" && "$h" == "$tmp"/h-* ]] || fail "newhome: bad name"
  mkdir -p "$h/tmp" "$h/proj"
  printf '%s' "$h"
}
IB="${PACKS_TEST_INSTALL_BASH:-bash}"
envh() {  # $1 home, rest: command
  local h="$1"; shift
  [[ -n "$h" && "$h" == "$tmp"/* ]] || fail "home escaped the temp dir: '$h'"
  HOME="$h" CLAUDE_DIR="$h/.claude" CODEX_HOME="$h/.codex" CODEX_SKILLS_DIR="$h/.agents/skills" \
    CODEX_PROJECT_DIR="$h/proj" TMPDIR="$h/tmp" "$@"
}
runc() { local h="$1"; shift; envh "$h" timeout 300 "$IB" "$rel/install.sh" "$@" 2>&1; }
runx() { local h="$1"; shift; envh "$h" timeout 300 "$IB" "$rel/install.sh" --codex "$@" 2>&1; }
runp() { local h="$1"; shift; envh "$h" timeout 300 "$IB" "$rel/install.sh" --codex --project "$@" 2>&1; }
mf_packs() { jq -c '.packs' "$1"; }

# Every item of pack $2 is present ("in") / absent ("out") under a root of
# kind $3: claude ($1 = ~/.claude), codex ($1 = home: skills dir + agents TOML).
pack_is() {
  local root="$1" pk="$2" state="$3" kind="$4" e p n
  while IFS= read -r e; do
    n="${e#*/}"; n="${n%.md}"
    case "$kind:$e" in
      claude:*) p="$root/$e" ;;
      codex:skills/*) p="$root/.agents/skills/$n" ;;
      codex:agents/*) p="$root/.codex/agents/$n.toml" ;;
      project:skills/*) p="$root/proj/.agents/skills/$n" ;;
      project:agents/*) p="$root/proj/.codex/agents/$n.toml" ;;
    esac
    if [[ "$state" == in ]]; then
      [[ -e "$p" ]] || fail "$kind: $pk item $e missing ($p)"
    else
      [[ ! -e "$p" && ! -L "$p" ]] || fail "$kind: $pk item $e present but must not be ($p)"
    fi
  done < <(entries "$pk")
}
# No manifest under $1 tracks a file of pack $2 (claude paths only).
untracked() {
  local mf="$1" pk="$2" e
  while IFS= read -r e; do
    if [[ "$e" == skills/* ]]; then
      jq -e --arg p "$e/" '[.files[].path | select(startswith($p))] | length == 0' "$mf" >/dev/null || fail "$mf still tracks files of $e"
    else
      jq -e --arg p "$e" '[.files[].path | select(. == $p)] | length == 0' "$mf" >/dev/null || fail "$mf still tracks $e"
    fi
  done < <(entries "$pk")
}

# ── 1. Fresh default install: core only ──────────────────────────────────────
h="$(newhome fresh)"
runc "$h" > "$tmp/o-fresh" || { cat "$tmp/o-fresh"; fail "fresh default install failed"; }
mf="$h/.claude/.agentic-os-manifest.json"
pack_is "$h/.claude" marketing out claude; pack_is "$h/.claude" games out claude
[[ "$(mf_packs "$mf")" == '[]' ]] || fail "fresh manifest packs is $(mf_packs "$mf"), want []"
untracked "$mf" marketing; untracked "$mf" games
grep -q '  marketing: not installed (add it with --with-marketing)' "$tmp/o-fresh" || fail "fresh install does not say how to add marketing"
grep -q '  games: not installed (add it with --with-games)' "$tmp/o-fresh" || fail "fresh install does not say how to add games"
want_core="$( (cd "$rel/.claude" && find skills agents -type f) \
  | awk 'NR == FNR { if ($0 !~ /^[[:space:]]*(#|$)/) p[$0] = 1; next }
         { k = $0; if (k ~ /^skills\//) { split(k, a, "/"); k = "skills/" a[2] } if (!(k in p)) n++ }
         END { print n + 0 }' <(cat "$rel"/assets/packs/*.txt) -)"
got_core="$(jq '[.files[].path | select(test("^(skills|agents)/"))] | length' "$mf")"
[[ "$got_core" == "$want_core" && "$want_core" -gt 0 ]] || fail "fresh install tracks $got_core skill/agent files, core has $want_core"
[[ -f "$h/.claude/agents/engineer.md" && -f "$h/.claude/skills/prompt-shaper/SKILL.md" ]] || fail "core files missing"
ok "fresh default install is core only: no pack files, manifest packs [], every core file tracked"

# ── 2. Each --with flag, and stickiness ──────────────────────────────────────
for pk in marketing games; do
  other=games; [[ "$pk" == games ]] && other=marketing
  h="$(newhome "with-$pk")"
  runc "$h" "--with-$pk" > "$tmp/o-with" || { cat "$tmp/o-with"; fail "--with-$pk failed"; }
  mf="$h/.claude/.agentic-os-manifest.json"
  pack_is "$h/.claude" "$pk" in claude; pack_is "$h/.claude" "$other" out claude
  [[ "$(mf_packs "$mf")" == "[\"$pk\"]" ]] || fail "--with-$pk: manifest packs is $(mf_packs "$mf")"
  grep -q "  $pk: installed (--with-$pk)" "$tmp/o-with" || fail "--with-$pk not reported"
  ! grep -q "re-run with --without-$pk" "$tmp/o-with" || fail "--with-$pk run printed the keep hint"
  snap "$h/.claude" > "$tmp/s-with"
  runc "$h" > "$tmp/o-with2" || fail "plain re-run after --with-$pk failed"
  snap "$h/.claude" | cmp -s - "$tmp/s-with" || fail "plain re-run after --with-$pk changed files (pack must be sticky)"
  [[ "$(grep -c "re-run with --without-$pk to remove it" "$tmp/o-with2")" == 1 ]] || fail "sticky $pk: no single hint naming --without-$pk"
  grep -q "  $pk: kept, as recorded in the install manifest" "$tmp/o-with2" || fail "sticky $pk: reason not given"
done
ok "--with-marketing / --with-games each add exactly that pack; a plain re-run keeps it and prints one --without hint"

h="$(newhome both)"
runc "$h" --with-games --with-marketing > "$tmp/o-both" || { cat "$tmp/o-both"; fail "both packs failed"; }
mf="$h/.claude/.agentic-os-manifest.json"
pack_is "$h/.claude" marketing in claude; pack_is "$h/.claude" games in claude
[[ "$(mf_packs "$mf")" == '["games","marketing"]' ]] || fail "both: manifest packs is $(mf_packs "$mf")"
want_all="$( (cd "$rel/.claude" && find skills agents -type f) | wc -l | tr -d ' ')"
[[ "$(jq '[.files[].path | select(test("^(skills|agents)/"))] | length' "$mf")" == "$want_all" ]] || fail "both packs: not every skill/agent file tracked"
ok "both packs: the whole library is installed and tracked"

# ── 3. --without: unmodified files removed, an edited one kept ───────────────
mkdir -p "$h/.claude/skills/seo-ops/notes"; printf 'mine\n' > "$h/.claude/skills/seo-ops/notes/user.md"
edited="$h/.claude/skills/seo-ops/SKILL.md"
printf '\nmy seo tweak\n' >> "$edited"
runc "$h" --without-marketing > "$tmp/o-without" || { cat "$tmp/o-without"; fail "--without-marketing failed"; }
grep -q 'my seo tweak' "$edited" || fail "--without-marketing deleted a locally edited pack file"
grep -q 'keep skills/seo-ops/SKILL.md — no longer shipped, but modified locally' "$tmp/o-without" || fail "edited pack file not named"
grep -q 'mine' "$h/.claude/skills/seo-ops/notes/user.md" || fail "--without-marketing deleted a user file in a pack dir"
[[ ! -e "$h/.claude/agents/marketer.md" && ! -e "$h/.claude/skills/autoresearch" ]] || fail "unmodified marketing files not removed"
grep -q 'remove agents/marketer.md (no longer shipped)' "$tmp/o-without" || fail "removal not reported"
jq -e '[.files[].path] | index(["skills/seo-ops/SKILL.md"]) != null' "$mf" >/dev/null || fail "edited pack file no longer tracked"
[[ "$(mf_packs "$mf")" == '["games"]' ]] || fail "--without-marketing: manifest packs is $(mf_packs "$mf")"
pack_is "$h/.claude" games in claude
grep -q '  marketing: not installed (--without-marketing)' "$tmp/o-without" || fail "--without not reported"
runc "$h" > "$tmp/o-without2" || fail "plain run after --without failed"
[[ ! -e "$h/.claude/agents/marketer.md" ]] || fail "plain run after --without-marketing brought marketing back"
grep -q 'my seo tweak' "$edited" || fail "plain run after --without lost the edited file"
[[ "$(mf_packs "$mf")" == '["games"]' ]] || fail "plain run after --without: manifest packs is $(mf_packs "$mf")"
ok "--without-marketing removes unmodified pack files, keeps an edited one (still tracked) and user files; the opt-out sticks"

# ── 4. Upgrade from a pre-#278 install keeps both packs ──────────────────────
if git -C "$GITREPO" cat-file -e "$BASE_REV:install.sh" 2>/dev/null; then
  relold="$tmp/rel-old"
  cp -R "$rel" "$relold"
  git -C "$GITREPO" show "$BASE_REV:install.sh" > "$relold/install.sh"
  # The payload as BASE_REV shipped it: no pack lists, and no install.ps1 newer
  # than its install.sh (validate.sh checks both installers' pack lists).
  rm -rf "$relold/assets/packs" "$relold/install.ps1"
  for kind in claude codex; do
    h="$(newhome "upgrade-$kind")"
    xa=(); [[ "$kind" == codex ]] && xa=(--codex)
    envh "$h" timeout 300 "$IB" "$relold/install.sh" ${xa[@]+"${xa[@]}"} > "$tmp/o-up0" 2>&1 || { tail -5 "$tmp/o-up0"; fail "$kind: $BASE_REV install failed"; }
    if [[ "$kind" == claude ]]; then mfs=("$h/.claude/.agentic-os-manifest.json"); root="$h/.claude"
    else mfs=("$h/.agents/skills/.agentic-os-manifest.json" "$h/.codex/.agentic-os-manifest.json"); root="$h"; fi
    for m in "${mfs[@]}"; do
      jq -e 'has("packs") | not' "$m" >/dev/null || fail "$kind: $BASE_REV manifest already has a packs key"
    done
    pack_is "$root" marketing in "$kind"; pack_is "$root" games in "$kind"
    snap "$h" > "$tmp/s-up0"
    for run in 1 2; do
      if [[ "$kind" == claude ]]; then runc "$h" > "$tmp/o-up$run" || { cat "$tmp/o-up$run"; fail "$kind upgrade run $run failed"; }
      else runx "$h" > "$tmp/o-up$run" || { cat "$tmp/o-up$run"; fail "$kind upgrade run $run failed"; }; fi
      pack_is "$root" marketing in "$kind"; pack_is "$root" games in "$kind"
      ! grep -qE '^  remove ' "$tmp/o-up$run" || fail "$kind upgrade run $run removed files: $(grep -m1 -E '^  remove ' "$tmp/o-up$run")"
      ! grep -q '⚠ keep ' "$tmp/o-up$run" || fail "$kind upgrade run $run: spurious keep $(grep -m1 '⚠ keep ' "$tmp/o-up$run")"
      for m in "${mfs[@]}"; do
        [[ "$(mf_packs "$m")" == '["games","marketing"]' ]] || fail "$kind upgrade run $run: $m packs is $(mf_packs "$m")"
      done
      for pk in marketing games; do
        [[ "$(grep -c "re-run with --without-$pk to remove it" "$tmp/o-up$run")" == 1 ]] || fail "$kind upgrade run $run: no single --without-$pk hint"
      done
    done
    grep -q 'marketing: kept, because the install manifest (written before packs existed) tracks its files' "$tmp/o-up1" || fail "$kind upgrade: legacy reason not given"
    grep -q 'marketing: kept, as recorded in the install manifest' "$tmp/o-up2" || fail "$kind second run: recorded reason not given"
    # Only the manifests may differ from the base install.
    diff <(grep -v 'agentic-os-manifest.json$' "$tmp/s-up0") <(snap "$h" | grep -v 'agentic-os-manifest.json$') >/dev/null \
      || fail "$kind upgrade changed installed files"
  done
  ok "upgrade from a $BASE_REV install (Claude, Codex) keeps both packs on the first and the second plain run, with a --without hint each"

  # A legacy manifest that tracks only one pack keeps only that pack.
  h="$(newhome upgrade-one)"
  envh "$h" timeout 300 "$IB" "$relold/install.sh" > "$tmp/o-one0" 2>&1 || fail "$BASE_REV install failed"
  m="$h/.claude/.agentic-os-manifest.json"
  # Line-wise, keeping the installer's one-entry-per-line format.
  games_re="$(entries games | sed -E 's#^(skills/.*)$#\1/#; s#\.#\\.#g' | paste -sd '|' -)"
  grep -vE "\"path\": \"($games_re)" "$m" > "$m.tmp" && mv "$m.tmp" "$m"
  ! grep -qE 'godot-engineer|game-balancer' "$m" || fail "one-pack fixture: games entries still in the manifest"
  grep -q '"path": "agents/marketer.md"' "$m" || fail "one-pack fixture: marketing entries lost"
  # Those files are now untracked: the user's, as far as the manifest knows.
  runc "$h" > "$tmp/o-one" || { cat "$tmp/o-one"; fail "one-pack upgrade failed"; }
  [[ "$(mf_packs "$m")" == '["marketing"]' ]] || fail "one-pack upgrade: packs is $(mf_packs "$m")"
  grep -q '  games: not installed' "$tmp/o-one" || fail "one-pack upgrade kept games"
  [[ -f "$h/.claude/agents/godot-engineer.md" ]] || fail "one-pack upgrade deleted untracked files"
  ok "a legacy manifest tracking only marketing keeps marketing, adds nothing else, and deletes no untracked file"
else
  if [[ -n "${CI:-}" ]]; then
    fail "upgrade: $BASE_REV is not in this clone; CI must run this test with full history (fetch-depth: 0)"
  fi
  echo "SKIP  upgrade from $BASE_REV: not in this clone (shallow checkout? run with full history)"
  SKIPPED=$((SKIPPED + 1))
fi

# Pre-manifest install (the v3.0.1 release wrote no manifest): pack items on
# disk are kept, a root without any is core only.
h="$(newhome premanifest)"
mkdir -p "$h/.claude"
cp -R "$rel/.claude/skills" "$rel/.claude/agents" "$rel/.claude/hooks" "$h/.claude/"
runc "$h" > "$tmp/o-pre" || { cat "$tmp/o-pre"; fail "pre-manifest adoption failed"; }
pack_is "$h/.claude" marketing in claude; pack_is "$h/.claude" games in claude
[[ "$(mf_packs "$h/.claude/.agentic-os-manifest.json")" == '["games","marketing"]' ]] || fail "pre-manifest adoption: packs is $(mf_packs "$h/.claude/.agentic-os-manifest.json")"
jq -e '[.files[].path] | index(["agents/marketer.md"]) != null' "$h/.claude/.agentic-os-manifest.json" >/dev/null || fail "pre-manifest pack files not adopted into the manifest"
grep -q 'marketing: kept, because AgenticOS copies of its files are installed here with no manifest (e.g. ' "$tmp/o-pre" || fail "pre-manifest: evidence not named"
ok "pre-manifest install with pack files on disk keeps and adopts both packs"

# --without on a pre-manifest install removes the pack's AgenticOS copies
# through the normal prune; an edited file and a user file in the pack dir stay.
h="$(newhome premanifest-without)"
mkdir -p "$h/.claude"
cp -R "$rel/.claude/skills" "$rel/.claude/agents" "$h/.claude/"
printf '\nmy seo edit\n' >> "$h/.claude/skills/seo-ops/SKILL.md"
printf 'mine\n' > "$h/.claude/skills/autoresearch/my-notes.md"
printf '\nmy marketer edit\n' >> "$h/.claude/agents/marketer.md"
runc "$h" --without-marketing > "$tmp/o-prew" || { cat "$tmp/o-prew"; fail "pre-manifest --without-marketing failed"; }
[[ ! -e "$h/.claude/skills/content-ops" && ! -e "$h/.claude/skills/autoresearch/SKILL.md" ]] \
  || fail "pre-manifest --without-marketing left AgenticOS copies on disk"
grep -q '^  remove skills/content-ops/SKILL.md (no longer shipped)$' "$tmp/o-prew" || fail "pre-manifest removal not reported"
grep -q 'my seo edit' "$h/.claude/skills/seo-ops/SKILL.md" || fail "pre-manifest --without deleted an edited pack file"
grep -q 'mine' "$h/.claude/skills/autoresearch/my-notes.md" || fail "pre-manifest --without deleted a user file in a pack dir"
grep -q 'my marketer edit' "$h/.claude/agents/marketer.md" || fail "pre-manifest --without deleted an edited pack agent"
for f in skills/seo-ops/SKILL.md skills/autoresearch/my-notes.md agents/marketer.md; do
  grep -q "⚠ keep $f — in the marketing pack's dirs but not an AgenticOS release copy (edited, or yours), and no manifest tracks it; left in place" "$tmp/o-prew" \
    || fail "pre-manifest --without did not name the file it left in place: $f"
done
untracked "$h/.claude/.agentic-os-manifest.json" marketing
pack_is "$h/.claude" games in claude
[[ "$(mf_packs "$h/.claude/.agentic-os-manifest.json")" == '["games"]' ]] || fail "pre-manifest --without: packs is $(mf_packs "$h/.claude/.agentic-os-manifest.json")"
ok "pre-manifest --without-marketing removes its AgenticOS copies, keeps an edited file and a user file"

h="$(newhome codex-premanifest-without)"
runx "$h" --with-marketing >/dev/null || fail "codex install for the pre-manifest --without case failed"
rm -f "$h/.agents/skills/.agentic-os-manifest.json" "$h/.codex/.agentic-os-manifest.json"
printf '\nmine\n' >> "$h/.agents/skills/seo-ops/SKILL.md"
printf 'mine\n' > "$h/.agents/skills/autoresearch/my-notes.md"
runx "$h" --without-marketing > "$tmp/o-xprew" || { cat "$tmp/o-xprew"; fail "codex pre-manifest --without-marketing failed"; }
[[ ! -e "$h/.agents/skills/content-ops" && ! -e "$h/.agents/skills/autoresearch/SKILL.md" ]] || fail "codex pre-manifest --without left skill copies"
grep -q 'mine' "$h/.agents/skills/seo-ops/SKILL.md" && grep -q 'mine' "$h/.agents/skills/autoresearch/my-notes.md" || fail "codex pre-manifest --without deleted an edited or user file"
grep -q '^  remove content-ops/SKILL.md (no longer shipped)$' "$tmp/o-xprew" || fail "codex pre-manifest removal not reported"
for f in seo-ops/SKILL.md autoresearch/my-notes.md; do
  grep -q "⚠ keep $f — in the marketing pack's dirs but not an AgenticOS release copy" "$tmp/o-xprew" \
    || fail "codex pre-manifest --without did not name the file it left in place: $f"
done
[[ -f "$h/.codex/agents/marketer.toml" ]] || fail "codex: an unprovable agent TOML was deleted"
grep -q "left in place: $h/.codex/agents/marketer.toml" "$tmp/o-xprew" || fail "codex: leftover pack agent TOML not named"
ok "codex pre-manifest --without-marketing removes skill copies, keeps edited/user files, names the agent TOML it cannot prove"

# Only AgenticOS copies count as evidence: the user's own skill that shares a
# pack skill's name, an empty pack dir, or a dangling symlink pull in nothing.
h="$(newhome own-skill)"
mkdir -p "$h/.claude/skills/autoresearch" "$h/.claude/skills/seo-ops" "$h/.claude/agents"
printf 'my own autoresearch notes\n' > "$h/.claude/skills/autoresearch/SKILL.md"
cp "$rel/.claude/skills/growth-engine/SKILL.md" "$h/outside-growth.md"
ln -s "$h/outside-growth.md" "$h/.claude/agents/marketer.md"
ln -s "$h/nowhere" "$h/.claude/skills/growth-engine"
cp "$h/.claude/skills/autoresearch/SKILL.md" "$tmp/own.orig"
runc "$h" > "$tmp/o-own" || { cat "$tmp/o-own"; fail "install over a user's same-named skill failed"; }
[[ "$(mf_packs "$h/.claude/.agentic-os-manifest.json")" == '[]' ]] || fail "user's own skill pulled in a pack: $(mf_packs "$h/.claude/.agentic-os-manifest.json")"
grep -q '  marketing: not installed (add it with --with-marketing)' "$tmp/o-own" || fail "own-skill: marketing not reported as not installed"
cmp -s "$h/.claude/skills/autoresearch/SKILL.md" "$tmp/own.orig" || fail "the user's own skill file was changed"
[[ ! -e "$h/.claude/skills/content-ops" && ! -e "$h/.claude/skills/seo-ops/SKILL.md" ]] || fail "own-skill: marketing files installed"
[[ -L "$h/.claude/agents/marketer.md" && -L "$h/.claude/skills/growth-engine" ]] || fail "own-skill: symlinks touched"
untracked "$h/.claude/.agentic-os-manifest.json" marketing
ok "no manifest: a user's own same-named skill, an empty pack dir and symlinks (even to a shipped copy) give core only and stay untouched"

# A v3.0.1-shaped install: pack files that byte-match an earlier release (not
# this one) keep the pack, and are updated to this release's copy.
h="$(newhome v301-shaped)"
relv="$tmp/rel-v301"
cp -R "$rel" "$relv"
mkdir -p "$h/.claude/skills/seo-ops"
printf '\n<!-- an older AgenticOS release -->\n' | cat "$rel/.claude/skills/seo-ops/SKILL.md" - > "$h/.claude/skills/seo-ops/SKILL.md"
printf '%s  %s\n' "$("${SHA[@]}" "$h/.claude/skills/seo-ops/SKILL.md" | awk '{print $1}')" skills/seo-ops/SKILL.md >> "$relv/assets/release-hashes.txt"
envh "$h" timeout 300 "$IB" "$relv/install.sh" > "$tmp/o-v301" 2>&1 || { cat "$tmp/o-v301"; fail "v3.0.1-shaped adoption failed"; }
grep -q 'marketing: kept, because AgenticOS copies of its files are installed here with no manifest (e.g. skills/seo-ops/SKILL.md)' "$tmp/o-v301" || { grep -A3 Opt-in "$tmp/o-v301"; fail "v3.0.1-shaped: marketing not kept by its release file"; }
pack_is "$h/.claude" marketing in claude; pack_is "$h/.claude" games out claude
cmp -s "$h/.claude/skills/seo-ops/SKILL.md" "$rel/.claude/skills/seo-ops/SKILL.md" || fail "v3.0.1-shaped: earlier-release copy not updated"
ok "no manifest: a pack file matching an earlier release's hash keeps that pack (only), and is updated"

# A pack file that matches only this release's source (no earlier release has
# it) counts too.
h="$(newhome cur-src)"
relc="$tmp/rel-cur"
cp -R "$rel" "$relc"
printf '\n<!-- only in this release -->\n' >> "$relc/.claude/skills/seo-ops/SKILL.md"
mkdir -p "$h/.claude/skills/seo-ops"
cp "$relc/.claude/skills/seo-ops/SKILL.md" "$h/.claude/skills/seo-ops/SKILL.md"
envh "$h" timeout 300 "$IB" "$relc/install.sh" > "$tmp/o-cur" 2>&1 || { cat "$tmp/o-cur"; fail "current-source adoption failed"; }
grep -q 'marketing: kept, because AgenticOS copies of its files are installed here with no manifest (e.g. skills/seo-ops/SKILL.md)' "$tmp/o-cur" \
  || { grep -A3 Opt-in "$tmp/o-cur"; fail "a pack file matching this release's source did not keep the pack"; }
ok "no manifest: a pack file matching this release's source (and no earlier release) keeps the pack"

# Evidence is never read through a link: a symlinked skills/ dir holding real
# copies is not evidence (and the install is then refused as before).
h="$(newhome linked-skills)"
mkdir -p "$h/.claude" "$h/elsewhere"
cp -R "$rel/.claude/skills" "$h/elsewhere/skills"
ln -s "$h/elsewhere/skills" "$h/.claude/skills"
if runc "$h" > "$tmp/o-lnk"; then fail "install accepted a symlinked skills/ dir"; fi
! grep -q 'kept, because' "$tmp/o-lnk" || fail "a pack was kept on evidence read through a symlinked skills/ dir: $(grep -m1 'kept, because' "$tmp/o-lnk")"
grep -q 'skills is a symlink' "$tmp/o-lnk" || fail "symlinked skills/ not refused"
ok "no manifest: files behind a symlinked skills/ dir are not evidence"

if git -C "$GITREPO" rev-parse -q --verify 'refs/tags/v3.0.1' >/dev/null; then
  old="$tmp/v3.0.1"; mkdir -p "$old"
  git -C "$GITREPO" archive v3.0.1 | tar -x -C "$old"
  h="$(newhome real-v301)"
  envh "$h" timeout 300 "$IB" "$old/install.sh" > "$tmp/o-r301a" 2>&1 || { tail -5 "$tmp/o-r301a"; fail "v3.0.1 install failed"; }
  [[ ! -e "$h/.claude/.agentic-os-manifest.json" ]] || fail "v3.0.1 wrote a manifest (test assumption broken)"
  runc "$h" > "$tmp/o-r301b" || { tail -5 "$tmp/o-r301b"; fail "upgrade from a real v3.0.1 install failed"; }
  [[ "$(mf_packs "$h/.claude/.agentic-os-manifest.json")" == '["games","marketing"]' ]] || fail "real v3.0.1 upgrade: packs is $(mf_packs "$h/.claude/.agentic-os-manifest.json")"
  pack_is "$h/.claude" marketing in claude; pack_is "$h/.claude" games in claude
  ok "upgrade from a real v3.0.1 install (no manifest) keeps both packs"
else
  echo "SKIP  real v3.0.1 upgrade: tag not available (git fetch --tags)"
  SKIPPED=$((SKIPPED + 1))
fi

# ── 5. Codex user scope ──────────────────────────────────────────────────────
h="$(newhome codex)"
runx "$h" > "$tmp/o-x0" || { cat "$tmp/o-x0"; fail "codex default failed"; }
pack_is "$h" marketing out codex; pack_is "$h" games out codex
[[ -f "$h/.codex/agents/engineer.toml" && -f "$h/.agents/skills/prompt-shaper/SKILL.md" ]] || fail "codex core missing"
for m in "$h/.agents/skills/.agentic-os-manifest.json" "$h/.codex/.agentic-os-manifest.json"; do
  [[ "$(mf_packs "$m")" == '[]' ]] || fail "codex default: $m packs is $(mf_packs "$m")"
done
runx "$h" --with-games > "$tmp/o-x1" || { cat "$tmp/o-x1"; fail "codex --with-games failed"; }
pack_is "$h" games in codex; pack_is "$h" marketing out codex
grep -q "^name = 'godot-engineer'$" "$h/.codex/agents/godot-engineer.toml" || fail "codex pack agent not converted"
runx "$h" > "$tmp/o-x2" || fail "codex plain re-run failed"
pack_is "$h" games in codex
grep -q 'games: kept, as recorded' "$tmp/o-x2" || fail "codex: games not kept as recorded"
printf '\nmine\n' >> "$h/.agents/skills/iap-manager/SKILL.md"
runx "$h" --without-games > "$tmp/o-x3" || { cat "$tmp/o-x3"; fail "codex --without-games failed"; }
[[ ! -e "$h/.codex/agents/godot-engineer.toml" && ! -e "$h/.agents/skills/game-balancer" ]] || fail "codex --without-games left unmodified files"
grep -q 'mine' "$h/.agents/skills/iap-manager/SKILL.md" || fail "codex --without-games deleted an edited file"
grep -q 'keep iap-manager/SKILL.md — no longer shipped, but modified locally' "$tmp/o-x3" || fail "codex: edited file not named"
for m in "$h/.agents/skills/.agentic-os-manifest.json" "$h/.codex/.agentic-os-manifest.json"; do
  [[ "$(mf_packs "$m")" == '[]' ]] || fail "codex --without-games: $m packs is $(mf_packs "$m")"
done
ok "codex user scope: core by default, --with-games adds skills + agent TOML, sticky, --without-games prunes (edited file kept)"

# ── 6. Codex project scope ───────────────────────────────────────────────────
h="$(newhome project)"
runp "$h" --with-marketing > "$tmp/o-p1" || { cat "$tmp/o-p1"; fail "project --with-marketing failed"; }
pack_is "$h" marketing in project; pack_is "$h" games out project
[[ ! -e "$h/.agents" && ! -e "$h/.codex" ]] || fail "project install wrote into the user Codex dirs"
runp "$h" > "$tmp/o-p2" || fail "project plain re-run failed"
pack_is "$h" marketing in project
[[ "$(mf_packs "$h/proj/.codex/.agentic-os-manifest.json")" == '["marketing"]' ]] || fail "project manifest packs wrong"
grep -q 'marketing: kept, because AgenticOS copies of its files are installed in this project' "$tmp/o-p2" || fail "project: evidence for keeping marketing not named"
runp "$h" --without-marketing > "$tmp/o-p3" || fail "project --without-marketing failed"
pack_is "$h" marketing out project
ok "codex --project: --with-marketing installs into the project, kept by its installed files, --without-marketing removes it"

h="$(newhome project-games)"
runp "$h" --with-games >/dev/null || fail "project --with-games failed"
rm -f "$h/proj/.codex/.agentic-os-manifest.json" "$h/proj/.agents/skills/.agentic-os-manifest.json"
runp "$h" > "$tmp/o-pg" || { cat "$tmp/o-pg"; fail "project flagless run after --with-games failed"; }
pack_is "$h" games in project; pack_is "$h" marketing out project
grep -q 'games: kept, because AgenticOS copies of its files are installed in this project' "$tmp/o-pg" || fail "project games not kept by its files"
ok "codex --project: a real --with-games install is kept by a flagless run (even with its manifests gone)"

# Repository content decides nothing in project scope: a committed record, a
# legacy manifest tracking pack files, an empty pack dir or a dangling symlink
# all give core only on a flagless run.
forge() {  # $1 home, $2 shape
  local h="$1"
  mkdir -p "$h/proj/.codex/agents" "$h/proj/.agents/skills"
  case "$2" in
    record)
      printf '{\n  "schema": 1,\n  "name": "agentic-os",\n  "version": "v3.0.1",\n  "source": "release",\n  "platform": "codex",\n  "packs": ["games", "marketing"],\n  "files": [\n  ]\n}\n' \
        | tee "$h/proj/.codex/.agentic-os-manifest.json" > "$h/proj/.agents/skills/.agentic-os-manifest.json" ;;
    tracked)
      printf '{\n  "schema": 1,\n  "files": [\n    {"path": "agents/marketer.toml", "sha256": "%s"}\n  ]\n}\n' "$(printf '%064d' 0)" > "$h/proj/.codex/.agentic-os-manifest.json"
      printf '{\n  "schema": 1,\n  "files": [\n    {"path": "game-balancer/SKILL.md", "sha256": "%s"}\n  ]\n}\n' "$(printf '%064d' 0)" > "$h/proj/.agents/skills/.agentic-os-manifest.json" ;;
    emptydir) mkdir -p "$h/proj/.agents/skills/seo-ops" "$h/proj/.agents/skills/game-balancer" ;;
    symlink)
      ln -s "$h/nowhere.toml" "$h/proj/.codex/agents/marketer.toml"
      ln -s "$rel/.claude/skills/iap-manager" "$h/proj/.agents/skills/iap-manager" ;;
  esac
}
for shape in record tracked emptydir symlink; do
  h="$(newhome "forge-$shape")"
  forge "$h" "$shape"
  runp "$h" > "$tmp/o-forge" || { cat "$tmp/o-forge"; fail "project $shape: flagless run failed"; }
  grep -q '  games: not installed (add it with --with-games)' "$tmp/o-forge" || { grep -A3 Opt-in "$tmp/o-forge"; fail "project $shape: games selected by repository content"; }
  grep -q '  marketing: not installed (add it with --with-marketing)' "$tmp/o-forge" || { grep -A3 Opt-in "$tmp/o-forge"; fail "project $shape: marketing selected by repository content"; }
  for m in "$h/proj/.codex/.agentic-os-manifest.json" "$h/proj/.agents/skills/.agentic-os-manifest.json"; do
    [[ "$(mf_packs "$m")" == '[]' ]] || fail "project $shape: $m packs is $(mf_packs "$m")"
  done
  [[ ! -e "$h/proj/.agents/skills/content-ops" && ! -e "$h/proj/.codex/agents/godot-engineer.toml" ]] || fail "project $shape: pack files installed"
done
ok "codex --project: a committed packs record, a tracked-files manifest, empty pack dirs and symlinks select no pack"

# ── 7. Dry run changes nothing and reports the decisions ─────────────────────
h="$(newhome dry)"
snap "$h" > "$tmp/s-dry0"
runc "$h" --dry-run --with-games > "$tmp/o-dry0" || { cat "$tmp/o-dry0"; fail "fresh dry run failed"; }
snap "$h" | cmp -s - "$tmp/s-dry0" || fail "dry run on a fresh HOME changed files"
grep -q '\[dry-run\] games: installed (--with-games)' "$tmp/o-dry0" || fail "dry run did not report the games decision"
runc "$h" --with-marketing --with-games >/dev/null || fail "install for dry-run case failed"
snap "$h" > "$tmp/s-dry1"
runc "$h" --dry-run --without-marketing > "$tmp/o-dry1" || { cat "$tmp/o-dry1"; fail "--dry-run --without-marketing failed"; }
snap "$h" | cmp -s - "$tmp/s-dry1" || fail "--dry-run --without-marketing changed files"
grep -q '\[dry-run\] marketing: not installed (--without-marketing)' "$tmp/o-dry1" || fail "dry run did not report the marketing decision"
grep -q '\[dry-run\] remove agents/marketer.md (no longer shipped)' "$tmp/o-dry1" || fail "dry run did not list the removals"
grep -q '\[dry-run\] games: kept, as recorded' "$tmp/o-dry1" || fail "dry run did not report the games decision"
ok "--dry-run reports every pack decision and planned removal, and changes nothing"

# ── 8. Uninstall leaves nothing behind ───────────────────────────────────────
h="$(newhome uninstall)"
runc "$h" --with-marketing --with-games >/dev/null || fail "install for uninstall case failed"
runc "$h" --uninstall > "$tmp/o-u" || { cat "$tmp/o-u"; fail "uninstall failed"; }
jq -e '. == {}' "$h/.claude/settings.json" >/dev/null || fail "uninstall left hook entries"
[[ -z "$(find "$h/.claude" ! -type d ! -name settings.json)" ]] || fail "uninstall left files: $(find "$h/.claude" ! -type d ! -name settings.json | head -5)"
runx "$h" --with-games >/dev/null || fail "codex install for uninstall case failed"
runx "$h" --uninstall > "$tmp/o-ux" || { cat "$tmp/o-ux"; fail "codex uninstall failed"; }
[[ -z "$(find "$h/.agents" "$h/.codex" -type f ! -name hooks.json)" ]] || fail "codex uninstall left files: $(find "$h/.agents" "$h/.codex" -type f ! -name hooks.json | head -5)"
ok "uninstall removes pack files with everything else (Claude and Codex)"

# ── 9. Usage errors change nothing ───────────────────────────────────────────
h="$(newhome usage)"
snap "$h" > "$tmp/s-usage"
usage_err() {  # $1 expected message, rest: installer args
  local want="$1"; shift
  if runc "$h" "$@" > "$tmp/o-usage"; then fail "accepted: $*"; fi
  grep -qF -- "$want" "$tmp/o-usage" || { cat "$tmp/o-usage"; fail "$*: no '$want'"; }
  snap "$h" | cmp -s - "$tmp/s-usage" || fail "$*: changed files"
}
usage_err 'Error: --with-games and --without-games contradict each other' --with-games --without-games
usage_err 'Error: --with-marketing and --without-marketing contradict each other' --without-marketing --codex --with-marketing
usage_err 'do not apply to --uninstall' --uninstall --with-games
usage_err 'do not apply to --uninstall' --uninstall --without-marketing
usage_err 'Error: unknown option: --with-sales' --with-sales
usage_err 'Error: unknown option: --without-' --without-
ok "conflicting with/without flags, pack flags with --uninstall, and unknown packs are usage errors that change nothing"

# A payload whose pack list is missing is refused before anything is written.
rel_nopack="$tmp/rel-nopack"
cp -R "$rel" "$rel_nopack"
rm -f "$rel_nopack/assets/packs/games.txt"
h="$(newhome nopack)"
snap "$h" > "$tmp/s-nopack"
if envh "$h" timeout 300 "$IB" "$rel_nopack/install.sh" > "$tmp/o-nopack" 2>&1; then fail "install ran with a missing pack list"; fi
snap "$h" | cmp -s - "$tmp/s-nopack" || fail "missing pack list: files changed"
ok "a payload with a missing pack list is refused and nothing is written"

# ── 10. /bin/bash 3 ──────────────────────────────────────────────────────────
if [[ -z "${PACKS_TEST_BASH3_REEXEC:-}" && -x /bin/bash ]] && /bin/bash -c '[[ ${BASH_VERSINFO[0]} -eq 3 ]]'; then
  PACKS_TEST_BASH3_REEXEC=1 PACKS_TEST_INSTALL_BASH=/bin/bash PACKS_TEST_GIT_REPO="$GITREPO" \
    timeout 2400 /bin/bash "$SRCREPO/scripts/install-packs-test.sh" \
    > "$tmp/b32.harness" 2>&1 || { tail -15 "$tmp/b32.harness"; fail "the harness fails when run under /bin/bash 3"; }
  ok "/bin/bash 3: the whole harness passes ($(tail -1 "$tmp/b32.harness"))"
elif [[ -z "${PACKS_TEST_BASH3_REEXEC:-}" ]]; then
  echo "SKIP  /bin/bash 3 re-run: /bin/bash is not bash 3"
  SKIPPED=$((SKIPPED + 1))
fi

if [[ "$SKIPPED" -gt 0 ]]; then
  echo "install-packs-test: OK ($P checks, $SKIPPED skipped)"
else
  echo "install-packs-test: OK ($P checks)"
fi
