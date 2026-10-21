#!/usr/bin/env bash
# install-doctrine-test.sh — `install.sh --with-doctrine` (#271): the marked
# doctrine block in CLAUDE.md / AGENTS.md, its manifest record, and its
# lifecycle (idempotent re-run, sticky without the flag, refresh with .bak,
# uninstall byte-restore, dry run, symlink / hard-link refusals), plus proof
# that an install WITHOUT the flag is byte-identical to the pre-#271 installer.
#
# Every run uses a throwaway HOME with CLAUDE_DIR / CODEX_HOME /
# CODEX_SKILLS_DIR / CODEX_PROJECT_DIR inside one mktemp dir; the real
# ~/.claude and ~/.codex are never touched, and the claude CLI is never run.
#
# The no-flag parity case needs the pre-#271 install.sh from git history
# (BASE_REV). In a shallow clone without it, that case is SKIPped locally and
# FAILs when CI is set.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_REV="2f8c0a3"   # #295, the last install.sh before --with-doctrine

if ! command -v jq &>/dev/null; then
  echo "install-doctrine-test: SKIP (jq not installed)" >&2
  exit 0
fi

tmp="$(cd "$(mktemp -d)" && pwd -P)"
[[ -n "$tmp" && "$tmp" == /* && -d "$tmp" ]] || { echo "install-doctrine-test: bad temp dir" >&2; exit 1; }
trap 'rm -rf "$tmp"' EXIT

P=0
SKIPPED=0
fail() { echo "FAIL install-doctrine: $*" >&2; exit 1; }
ok() { printf 'PASS  %s\n' "$1"; P=$((P + 1)); }

if command -v shasum &>/dev/null; then SHA=(shasum -a 256); else SHA=(sha256sum); fi
sha() { "${SHA[@]}" "$1" | awk '{print $1}'; }
mode_of() { ls -l "$1" | awk '{print $1}'; }
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
cp "$SRCREPO/assets/release-hashes.txt" "$rel/assets/release-hashes.txt"
DOCTRINE="$rel/assets/consumer/doctrine.md"
[[ -s "$DOCTRINE" ]] || fail "assets/consumer/doctrine.md missing from the payload"

BEGIN='<!-- agentic-os:doctrine:begin -->'
END='<!-- agentic-os:doctrine:end -->'
claude_block() { printf '%s\n@agentic-os/doctrine.md\n%s\n' "$BEGIN" "$END"; }
codex_block() { printf '%s\n' "$BEGIN"; cat "$DOCTRINE"; printf '%s\n' "$END"; }

# Each case gets its own HOME; every path the installer can reach is inside it.
newhome() { local h="$tmp/h-$1"; mkdir -p "$h"; printf '%s' "$h"; }
IB="${DOCTRINE_TEST_INSTALL_BASH:-bash}"
runc() { local h="$1"; shift; HOME="$h" CLAUDE_DIR="$h/.claude" timeout 300 "$IB" "$rel/install.sh" "$@" 2>&1; }
runx() { local h="$1"; shift; HOME="$h" CODEX_HOME="$h/.codex" CODEX_SKILLS_DIR="$h/.agents/skills" \
  timeout 300 "$IB" "$rel/install.sh" --codex "$@" 2>&1; }
runp() { local h="$1"; shift; HOME="$h" CODEX_HOME="$h/.codex" CODEX_SKILLS_DIR="$h/.agents/skills" CODEX_PROJECT_DIR="$h/proj" \
  timeout 300 "$IB" "$rel/install.sh" --codex --project "$@" 2>&1; }
mf_doctrine() { jq -c '.doctrine // empty' "$1"; }

# ── 1. No flag: byte-identical to the pre-#271 installer ─────────────────────
if [[ -n "${DOCTRINE_TEST_BASH3_REEXEC:-}" ]]; then
  echo "SKIP  no-flag parity (bash 3 re-exec: the outer bash 5 run covers it)"
  SKIPPED=$((SKIPPED + 1))
elif git -C "$REPO" cat-file -e "$BASE_REV:install.sh" 2>/dev/null; then
  relold="$tmp/rel-old"
  cp -R "$rel" "$relold"
  git -C "$REPO" show "$BASE_REV:install.sh" > "$relold/install.sh"
  parity() {  # $1 label, rest: installer args (both runs share one HOME path)
    local label="$1"; shift
    local h="$tmp/parity" a b
    for v in old new; do
      [[ -n "$h" && "$h" == "$tmp"/* ]] || fail "parity home escaped the temp dir"
      rm -rf "$h"; mkdir -p "$h/proj"
      printf 'user notes\n' > "$h/proj/AGENTS.md"
      mkdir -p "$h/.claude"; printf '# mine\n' > "$h/.claude/CLAUDE.md"
      local r="$rel"; [[ "$v" == old ]] && r="$relold"
      : > "$tmp/parity-$v.out"
      for step in install reinstall uninstall; do
        local extra=(); [[ "$step" == uninstall ]] && extra=(--uninstall)
        HOME="$h" CLAUDE_DIR="$h/.claude" CODEX_HOME="$h/.codex" CODEX_SKILLS_DIR="$h/.agents/skills" CODEX_PROJECT_DIR="$h/proj" \
          timeout 300 "$IB" "$r/install.sh" "$@" ${extra[@]+"${extra[@]}"} 2>&1 | sed "s#$r#REL#g; s/[0-9]\{14\}\.[0-9]*/STAMP/g" >> "$tmp/parity-$v.out" \
          || fail "$label: $v $step failed"
        snap "$h" >> "$tmp/parity-$v.out"
      done
    done
    a="$(sha "$tmp/parity-old.out")"; b="$(sha "$tmp/parity-new.out")"
    if [[ "$a" != "$b" ]]; then diff "$tmp/parity-old.out" "$tmp/parity-new.out" | head -20 >&2; fail "$label: no-flag run differs from $BASE_REV"; fi
    ok "no flag, $label: output and every file byte-identical to $BASE_REV (install, re-run, uninstall)"
  }
  parity "Claude"
  parity "Codex global" --codex
  parity "Codex project" --codex --project
else
  if [[ -n "${CI:-}" ]]; then
    fail "no-flag parity: $BASE_REV is not in this clone; CI must run this test with full history (fetch-depth: 0)"
  fi
  echo "SKIP  no-flag parity: $BASE_REV is not in this clone (shallow checkout? run with full history)"
  SKIPPED=$((SKIPPED + 1))
fi

h="$(newhome noflag)"
mkdir -p "$h/.claude"; printf '# my rules\nkeep me' > "$h/.claude/CLAUDE.md"
before="$(sha "$h/.claude/CLAUDE.md")"
runc "$h" > "$tmp/o-noflag" || { cat "$tmp/o-noflag"; fail "no-flag install failed"; }
[[ "$(sha "$h/.claude/CLAUDE.md")" == "$before" ]] || fail "no-flag install changed CLAUDE.md"
[[ ! -e "$h/.claude/agentic-os" ]] || fail "no-flag install wrote agentic-os/"
[[ -z "$(mf_doctrine "$h/.claude/.agentic-os-manifest.json")" ]] || fail "no-flag manifest has a doctrine record"
! grep -q 'agentic-os/' "$h/.claude/.agentic-os-manifest.json" || fail "no-flag manifest tracks agentic-os/"
ok "no flag: CLAUDE.md untouched, no doctrine file, no manifest record"

# ── 2. Flag on a fresh HOME ──────────────────────────────────────────────────
h="$(newhome fresh)"
runc "$h" --with-doctrine > "$tmp/o-fresh" || { cat "$tmp/o-fresh"; fail "fresh --with-doctrine failed"; }
cf="$h/.claude/CLAUDE.md"; mf="$h/.claude/.agentic-os-manifest.json"
cmp -s "$cf" <(claude_block) || fail "fresh CLAUDE.md is not exactly the block"
cmp -s "$h/.claude/agentic-os/doctrine.md" "$DOCTRINE" || fail "doctrine file not installed verbatim"
[[ "$(mode_of "$cf")" == "-rw-r--r--"* ]] || fail "created CLAUDE.md mode is $(mode_of "$cf"), want 0644"
jq -e --arg s "$(sha "$cf")" '.doctrine == {"created": true, "block_sha256": $s}' "$mf" >/dev/null \
  || fail "manifest doctrine record wrong: $(mf_doctrine "$mf")"
jq -e --arg s "$(sha "$DOCTRINE")" '[.files[] | select(.path == "agentic-os/doctrine.md" and .sha256 == $s)] | length == 1' "$mf" >/dev/null \
  || fail "manifest does not track agentic-os/doctrine.md"
ok "fresh HOME: CLAUDE.md created holding only the import block, doctrine file manifest-tracked"

snap "$h" > "$tmp/s-fresh"
runc "$h" --with-doctrine > "$tmp/o-fresh2" || fail "re-run failed"
snap "$h" | cmp -s - "$tmp/s-fresh" || fail "re-run with the flag changed files"
runc "$h" > "$tmp/o-fresh3" || fail "re-run without the flag failed"
snap "$h" | cmp -s - "$tmp/s-fresh" || fail "re-run without the flag changed files (doctrine must be sticky)"
! ls "$h/.claude"/CLAUDE.md.bak.* >/dev/null 2>&1 || fail "idempotent re-run wrote a backup"
ok "re-run is idempotent, with or without the flag (sticky until uninstall)"

runc "$h" --uninstall > "$tmp/o-fresh-u" || { cat "$tmp/o-fresh-u"; fail "uninstall failed"; }
[[ ! -e "$cf" ]] || fail "uninstall left the CLAUDE.md it created"
[[ ! -e "$h/.claude/agentic-os" ]] || fail "uninstall left agentic-os/"
ok "uninstall removes the block, the CLAUDE.md it created, and the doctrine file"

# ── 3. Existing CLAUDE.md full of user content ───────────────────────────────
for variant in nl no-nl; do
  h="$(newhome "user-$variant")"
  mkdir -p "$h/.claude"; cf="$h/.claude/CLAUDE.md"
  printf '# My rules\n\n@~/notes.md\n- be terse\n<!-- my comment -->\n\n' > "$cf"
  [[ "$variant" == no-nl ]] && printf 'last line, no newline' >> "$cf"
  chmod 600 "$cf"
  cp -p "$cf" "$tmp/orig-$variant"
  runc "$h" --with-doctrine > "$tmp/o-user" || { cat "$tmp/o-user"; fail "install into existing CLAUDE.md failed"; }
  cmp -s "$cf" <(claude_block; printf '\n'; cat "$tmp/orig-$variant") || fail "$variant: content is not block + blank line + original bytes"
  [[ "$(mode_of "$cf")" == "-rw-------"* ]] || fail "$variant: mode not kept ($(mode_of "$cf"))"
  jq -e '.doctrine.created == false' "$h/.claude/.agentic-os-manifest.json" >/dev/null || fail "$variant: created should be false"
  runc "$h" --with-doctrine >/dev/null || fail "$variant: re-run failed"
  cmp -s "$cf" <(claude_block; printf '\n'; cat "$tmp/orig-$variant") || fail "$variant: re-run changed CLAUDE.md"
  runc "$h" --uninstall > "$tmp/o-user-u" || { cat "$tmp/o-user-u"; fail "$variant: uninstall failed"; }
  cmp -s "$cf" "$tmp/orig-$variant" || fail "$variant: uninstall did not restore the original bytes"
  [[ "$(mode_of "$cf")" == "-rw-------"* ]] || fail "$variant: uninstall lost the mode"
done
ok "existing CLAUDE.md: block prepended, outside bytes and mode kept, uninstall restores it byte-for-byte"

# An empty existing CLAUDE.md round-trips to empty and is kept (not ours).
h="$(newhome empty)"; mkdir -p "$h/.claude"; : > "$h/.claude/CLAUDE.md"
runc "$h" --with-doctrine >/dev/null || fail "install into empty CLAUDE.md failed"
cmp -s "$h/.claude/CLAUDE.md" <(claude_block) || fail "empty CLAUDE.md: not exactly the block"
runc "$h" --uninstall >/dev/null || fail "uninstall (empty) failed"
[[ -f "$h/.claude/CLAUDE.md" && ! -s "$h/.claude/CLAUDE.md" ]] || fail "uninstall removed or changed the user's empty CLAUDE.md"
ok "an empty CLAUDE.md the user owns comes back empty, and is kept"

# ── 4. User-edited block: refreshed, whole file backed up ───────────────────
h="$(newhome edited)"; mkdir -p "$h/.claude"; cf="$h/.claude/CLAUDE.md"
printf 'mine\n' > "$cf"
runc "$h" --with-doctrine >/dev/null || fail "install (edited case) failed"
awk -v b="$BEGIN" '{ print } $0 == b { print "my extra line" }' "$cf" > "$tmp/edited" && cat "$tmp/edited" > "$cf"
cp "$cf" "$tmp/edited-copy"
runc "$h" --with-doctrine > "$tmp/o-edited" || { cat "$tmp/o-edited"; fail "re-run over an edited block failed"; }
grep -q 'refresh the doctrine block' "$tmp/o-edited" || fail "no warning about the edited block"
cmp -s "$cf" <(claude_block; printf '\nmine\n') || fail "edited block was not refreshed"
bak="$(ls "$h/.claude"/CLAUDE.md.bak.* 2>/dev/null | head -n 1 || true)"
[[ -n "$bak" ]] && cmp -s "$bak" "$tmp/edited-copy" || fail "no byte-exact backup of the edited file"
awk -v b="$BEGIN" '{ print } $0 == b { print "edited again" }' "$cf" > "$tmp/edited" && cat "$tmp/edited" > "$cf"
cp "$cf" "$tmp/edited-again"
runc "$h" --uninstall > "$tmp/o-edited-u" || fail "uninstall over an edited block failed"
grep -q 'matches no block AgenticOS has shipped' "$tmp/o-edited-u" || fail "uninstall did not warn about the edited block"
cmp -s "$cf" "$tmp/edited-again" || fail "uninstall changed an edited block (it must be left for the user)"
[[ -f "$h/.claude/agentic-os/doctrine.md" ]] || fail "hands-off uninstall removed the doctrine file the block still imports"
ok "an edited block is refreshed after a byte-exact .bak with --with-doctrine, and left alone (with a warning) by uninstall"

# ── 5. Refusals: symlink, hard link, malformed markers ──────────────────────
h="$(newhome symlink)"; mkdir -p "$h/.claude" "$h/elsewhere"
printf 'target\n' > "$h/elsewhere/real.md"; ln -s "$h/elsewhere/real.md" "$h/.claude/CLAUDE.md"
snap "$h" > "$tmp/s-sym"
if runc "$h" --with-doctrine > "$tmp/o-sym"; then fail "symlinked CLAUDE.md accepted"; fi
grep -q 'CLAUDE.md is a symlink' "$tmp/o-sym" || { cat "$tmp/o-sym"; fail "no symlink error"; }
snap "$h" | cmp -s - "$tmp/s-sym" || fail "files changed although the symlinked CLAUDE.md was refused"
ok "a symlinked CLAUDE.md is refused before anything is written"

h="$(newhome hardlink)"; mkdir -p "$h/.claude"
printf 'shared\n' > "$h/shared.md"; ln "$h/shared.md" "$h/.claude/CLAUDE.md"
snap "$h" > "$tmp/s-hl"
if runc "$h" --with-doctrine > "$tmp/o-hl"; then fail "hard-linked CLAUDE.md accepted"; fi
grep -q 'hard-linked' "$tmp/o-hl" || { cat "$tmp/o-hl"; fail "no hard-link error"; }
snap "$h" | cmp -s - "$tmp/s-hl" || fail "files changed although the hard-linked CLAUDE.md was refused"
ok "a hard-linked CLAUDE.md is refused before anything is written"

h="$(newhome malformed)"; mkdir -p "$h/.claude"
printf '%s\nno end marker\n' "$BEGIN" > "$h/.claude/CLAUDE.md"
snap "$h" > "$tmp/s-mal"
if runc "$h" --with-doctrine > "$tmp/o-mal"; then fail "malformed markers accepted"; fi
grep -q 'malformed AgenticOS doctrine markers' "$tmp/o-mal" || { cat "$tmp/o-mal"; fail "no malformed-marker error"; }
snap "$h" | cmp -s - "$tmp/s-mal" || fail "files changed although the markers were malformed"
ok "malformed markers are refused before anything is written"

# ── 6. Dry run writes nothing ────────────────────────────────────────────────
h="$(newhome dry)"; mkdir -p "$h/.claude"; printf 'mine\n' > "$h/.claude/CLAUDE.md"
snap "$h" > "$tmp/s-dry"
runc "$h" --with-doctrine --dry-run > "$tmp/o-dry" || { cat "$tmp/o-dry"; fail "dry run failed"; }
grep -q '\[dry-run\] add the AgenticOS doctrine block' "$tmp/o-dry" || fail "dry run does not report the block"
snap "$h" | cmp -s - "$tmp/s-dry" || fail "dry-run install wrote files"
runc "$h" --with-doctrine >/dev/null || fail "install (dry case) failed"
snap "$h" > "$tmp/s-dry2"
runc "$h" --uninstall --dry-run > "$tmp/o-dryu" || fail "uninstall dry run failed"
grep -q '\[dry-run\] remove the AgenticOS doctrine block' "$tmp/o-dryu" || fail "uninstall dry run does not report the block"
snap "$h" | cmp -s - "$tmp/s-dry2" || fail "dry-run uninstall wrote files"
ok "--dry-run reports the doctrine block on install and uninstall and writes nothing"

snap "$h" > "$tmp/s-uflag"
if runc "$h" --uninstall --with-doctrine > "$tmp/o-uflag"; then fail "--uninstall --with-doctrine accepted"; fi
grep -q -- '--with-doctrine does not apply to --uninstall' "$tmp/o-uflag" || { cat "$tmp/o-uflag"; fail "no --uninstall --with-doctrine error"; }
snap "$h" | cmp -s - "$tmp/s-uflag" || fail "files changed although --uninstall --with-doctrine was rejected"
ok "--uninstall rejects --with-doctrine, with nothing changed"

# ── 7. Codex global: inlined in $CODEX_HOME/AGENTS.md ────────────────────────
h="$(newhome codex)"
runx "$h" --with-doctrine > "$tmp/o-cx" || { cat "$tmp/o-cx"; fail "codex --with-doctrine failed"; }
af="$h/.codex/AGENTS.md"
cmp -s "$af" <(codex_block) || fail "codex AGENTS.md is not exactly the inlined block"
jq -e --arg s "$(sha "$af")" '.doctrine == {"created": true, "block_sha256": $s}' "$h/.codex/.agentic-os-manifest.json" >/dev/null \
  || fail "codex manifest doctrine record wrong"
[[ -z "$(mf_doctrine "$h/.agents/skills/.agentic-os-manifest.json")" ]] || fail "doctrine recorded in the skills manifest"
snap "$h" > "$tmp/s-cx"
runx "$h" >/dev/null || fail "codex re-run failed"
snap "$h" | cmp -s - "$tmp/s-cx" || fail "codex re-run changed files"
runx "$h" --uninstall >/dev/null || fail "codex uninstall failed"
[[ ! -e "$af" ]] || fail "codex uninstall left the AGENTS.md it created"
ok "Codex global: doctrine inlined into \$CODEX_HOME/AGENTS.md, idempotent, removed on uninstall"

h="$(newhome codex-user)"; mkdir -p "$h/.codex"; printf '# my codex notes\n' > "$h/.codex/AGENTS.md"
cp "$h/.codex/AGENTS.md" "$tmp/cx-orig"
runx "$h" --with-doctrine >/dev/null || fail "codex install over existing AGENTS.md failed"
cmp -s "$h/.codex/AGENTS.md" <(codex_block; printf '\n'; cat "$tmp/cx-orig") || fail "codex: outside bytes changed"
runx "$h" --uninstall >/dev/null || fail "codex uninstall (user file) failed"
cmp -s "$h/.codex/AGENTS.md" "$tmp/cx-orig" || fail "codex uninstall did not restore AGENTS.md"
ok "Codex global: an existing AGENTS.md is restored byte-for-byte on uninstall"

# ── 8. Codex project scope ───────────────────────────────────────────────────
h="$(newhome proj)"; mkdir -p "$h/proj"; printf 'project rules\n' > "$h/proj/AGENTS.md"
cp "$h/proj/AGENTS.md" "$tmp/p-orig"
runp "$h" --with-doctrine > "$tmp/o-p" || { cat "$tmp/o-p"; fail "codex --project --with-doctrine failed"; }
cmp -s "$h/proj/AGENTS.md" <(codex_block; printf '\n'; cat "$tmp/p-orig") || fail "project AGENTS.md wrong"
[[ -z "$(mf_doctrine "$h/proj/.codex/.agentic-os-manifest.json")" ]] || fail "project scope wrote a doctrine record (it is never read there)"
[[ ! -e "$h/.codex/AGENTS.md" ]] || fail "project install wrote the global AGENTS.md"
cp "$h/proj/AGENTS.md" "$tmp/p-installed"
runp "$h" --with-doctrine > "$tmp/o-p2" || { cat "$tmp/o-p2"; fail "project re-run with the flag failed"; }
cmp -s "$h/proj/AGENTS.md" "$tmp/p-installed" || fail "project re-run changed AGENTS.md"
grep -q 'already holds the current AgenticOS doctrine block' "$tmp/o-p2" || fail "project re-run did not report the current block"
runp "$h" --uninstall > "$tmp/o-pu" || fail "project uninstall failed"
cmp -s "$h/proj/AGENTS.md" "$tmp/p-installed" || fail "project uninstall edited AGENTS.md (the repo manifest authorises nothing)"
grep -q "delete the lines from '<!-- agentic-os:doctrine:begin -->'" "$tmp/o-pu" || fail "project uninstall did not say which lines to delete"
ok "Codex --project: doctrine in the project-root AGENTS.md; re-run is a no-op; uninstall leaves it and names the lines to delete"

h="$(newhome proj-sym)"; mkdir -p "$h/proj" "$h/.codex"
printf 'global\n' > "$h/.codex/AGENTS.md"; ln -s "$h/.codex/AGENTS.md" "$h/proj/AGENTS.md"
snap "$h" > "$tmp/s-psym"
if runp "$h" --with-doctrine > "$tmp/o-psym"; then fail "symlinked project AGENTS.md accepted"; fi
grep -q 'AGENTS.md is a symlink' "$tmp/o-psym" || { cat "$tmp/o-psym"; fail "no symlink error (project)"; }
snap "$h" | cmp -s - "$tmp/s-psym" || fail "files changed although the project AGENTS.md symlink was refused"
ok "Codex --project: a symlinked AGENTS.md (e.g. aimed at ~/.codex) is refused before anything is written"

# ── 9. A user-modified doctrine file is kept; the import still points at it ──
h="$(newhome moddoc)"
runc "$h" --with-doctrine >/dev/null || fail "install (moddoc) failed"
printf '\nmy addition\n' >> "$h/.claude/agentic-os/doctrine.md"
runc "$h" > "$tmp/o-moddoc" || fail "re-run (moddoc) failed"
grep -q 'keep agentic-os/doctrine.md — modified locally' "$tmp/o-moddoc" || fail "modified doctrine file not reported as kept"
grep -q 'my addition' "$h/.claude/agentic-os/doctrine.md" || fail "modified doctrine file overwritten"
cmp -s "$h/.claude/CLAUDE.md" <(claude_block) || fail "block changed when the doctrine file was kept"
ok "a locally modified doctrine file is kept like any manifest file"

# ── 10. A new release's doctrine refreshes silently; a moved block is honoured ─
h="$(newhome upgrade)"; mkdir -p "$h/.codex"; printf 'top\n' > "$h/.codex/AGENTS.md"
runx "$h" --with-doctrine >/dev/null || fail "codex install (upgrade) failed"
rel2="$tmp/rel2"; cp -R "$rel" "$rel2"
printf '\nA rule added in the next release.\n' >> "$rel2/assets/consumer/doctrine.md"
HOME="$h" CODEX_HOME="$h/.codex" CODEX_SKILLS_DIR="$h/.agents/skills" timeout 300 bash "$rel2/install.sh" --codex > "$tmp/o-up" 2>&1 \
  || { cat "$tmp/o-up"; fail "upgrade run failed"; }
grep -q 'update the AgenticOS doctrine block' "$tmp/o-up" || fail "upgrade did not report the block update"
! grep -q 'refresh the doctrine block' "$tmp/o-up" || fail "an unedited block was treated as a user edit"
! ls "$h/.codex"/AGENTS.md.bak.* >/dev/null 2>&1 || fail "an unedited block was backed up"
cmp -s "$h/.codex/AGENTS.md" <(printf '%s\n' "$BEGIN"; cat "$rel2/assets/consumer/doctrine.md"; printf '%s\n\ntop\n' "$END") \
  || fail "upgrade did not inline the new doctrine"
ok "a new release's doctrine replaces an unedited block silently (no .bak)"

h="$(newhome moved)"; mkdir -p "$h/.claude"; printf 'a\nb\n' > "$h/.claude/CLAUDE.md"
runc "$h" --with-doctrine >/dev/null || fail "install (moved) failed"
cmp -s "$h/.claude/CLAUDE.md" <(claude_block; printf '\na\nb\n') || fail "moved: unexpected install layout"
# Cut the 3 block lines (the separator stays at the top), paste them after "a".
{ printf '\na\n'; claude_block; printf 'b\n'; } > "$h/.claude/CLAUDE.md"
runc "$h" --with-doctrine >/dev/null || fail "re-run (moved) failed"
cmp -s "$h/.claude/CLAUDE.md" <(printf '\na\n'; claude_block; printf 'b\n') || fail "re-run moved the user's relocated block"
runc "$h" --uninstall >/dev/null || fail "uninstall (moved) failed"
cmp -s "$h/.claude/CLAUDE.md" <(printf '\na\nb\n') || fail "uninstall of a relocated block changed other lines"
ok "a moved block stays put; uninstall removes only its lines (the separator the user left behind stays, as documented)"

# ── 11. macOS /bin/bash 3.2 (#298 round 2) ───────────────────────────────────
if [[ -x /bin/bash ]] && /bin/bash -c '[[ "${BASH_VERSINFO[0]}" -lt 4 ]]'; then
  for f in install.sh scripts/validate.sh scripts/build-consumer-doctrine.sh scripts/install-doctrine-test.sh \
           scripts/validate-test.sh scripts/lib/install-hook-settings.sh; do
    /bin/bash -n "$SRCREPO/$f" 2> "$tmp/b32.err" || { cat "$tmp/b32.err"; fail "$f does not parse under /bin/bash 3"; }
  done
  (cd "$SRCREPO" && timeout 60 /bin/bash scripts/build-consumer-doctrine.sh --check) > "$tmp/b32.out" 2>&1 \
    || { cat "$tmp/b32.out"; fail "builder --check fails under /bin/bash 3"; }
  h="$(newhome bash32)"; mkdir -p "$h/.claude"; printf 'mine\n' > "$h/.claude/CLAUDE.md"; cp "$h/.claude/CLAUDE.md" "$tmp/b32.orig"
  for a in --with-doctrine --uninstall; do
    HOME="$h" CLAUDE_DIR="$h/.claude" PATH=/usr/bin:/bin "$(command -v timeout)" 300 /bin/bash "$rel/install.sh" "$a" > "$tmp/b32.run" 2>&1 \
      || { tail -5 "$tmp/b32.run"; fail "install.sh $a fails under /bin/bash 3 with PATH=/usr/bin:/bin"; }
  done
  cmp -s "$h/.claude/CLAUDE.md" "$tmp/b32.orig" || fail "bash 3 install + uninstall did not round-trip CLAUDE.md"
  ok "/bin/bash 3: every touched script parses, builder --check passes, install + uninstall round-trip"
  if [[ -z "${DOCTRINE_TEST_BASH3_REEXEC:-}" ]]; then
    # Run this whole harness (minus parity and this case) under /bin/bash 3,
    # with every install also under /bin/bash 3.
    DOCTRINE_TEST_BASH3_REEXEC=1 DOCTRINE_TEST_INSTALL_BASH=/bin/bash timeout 2400 /bin/bash "$SRCREPO/scripts/install-doctrine-test.sh" \
      > "$tmp/b32.harness" 2>&1 || { tail -15 "$tmp/b32.harness"; fail "the harness fails when run under /bin/bash 3"; }
    ok "/bin/bash 3: the whole harness passes ($(tail -1 "$tmp/b32.harness"))"
  fi
else
  echo "SKIP  /bin/bash 3 checks: /bin/bash is not bash 3"
  SKIPPED=$((SKIPPED + 1))
fi

# ── 12. Consent: no flag never adds a block (#298 round 2) ──────────────────
# A. A repo-committed project manifest with a (forged) doctrine record.
h="$(newhome forged)"; mkdir -p "$h/proj/.codex"; printf '# project agents notes\n' > "$h/proj/AGENTS.md"
printf '{\n  "schema": 1,\n  "doctrine": {"created": false, "block_sha256": "%s"},\n  "files": [\n  ]\n}\n' \
  "0000000000000000000000000000000000000000000000000000000000000000" > "$h/proj/.codex/.agentic-os-manifest.json"
runp "$h" > "$tmp/o-forged" || { cat "$tmp/o-forged"; fail "flagless project run (forged record) failed"; }
[[ "$(cat "$h/proj/AGENTS.md")" == "# project agents notes" ]] || fail "a forged project record made a flagless run write AGENTS.md"
! grep -qi 'doctrine' "$tmp/o-forged" || fail "a committed project record made a flagless run act on the doctrine"
[[ -z "$(mf_doctrine "$h/proj/.codex/.agentic-os-manifest.json")" ]] || fail "forged doctrine record kept"
ok "a repo-committed doctrine record never makes a flagless --project run write AGENTS.md"

# B. The user deletes the block by hand: that is an opt-out, not a re-add.
h="$(newhome removed)"; mkdir -p "$h/.claude"; printf '# mine\n' > "$h/.claude/CLAUDE.md"
runc "$h" --with-doctrine >/dev/null || fail "install (removed) failed"
printf '# mine\n' > "$h/.claude/CLAUDE.md"
runc "$h" > "$tmp/o-removed" || { cat "$tmp/o-removed"; fail "flagless run after removing the block failed"; }
[[ "$(cat "$h/.claude/CLAUDE.md")" == "# mine" ]] || fail "a hand-removed block was re-added without the flag"
grep -q 'Re-run with --with-doctrine to add it back' "$tmp/o-removed" || fail "no opt-back-in hint"
[[ -z "$(mf_doctrine "$h/.claude/.agentic-os-manifest.json")" ]] || fail "record kept after opt-out"
[[ ! -e "$h/.claude/agentic-os/doctrine.md" ]] || fail "doctrine file kept after opt-out"
snap "$h" > "$tmp/s-removed"
runc "$h" >/dev/null || fail "second flagless run failed"
snap "$h" | cmp -s - "$tmp/s-removed" || fail "a later flagless run changed files after the opt-out"
runc "$h" --with-doctrine >/dev/null || fail "opt back in failed"
cmp -s "$h/.claude/CLAUDE.md" <(claude_block; printf '\n# mine\n') || fail "opting back in did not add the block"
ok "removing the block by hand opts out (record and file dropped); --with-doctrine opts back in"

# ── 13. A linked target under sticky mode or uninstall: warn, carry on ──────
h="$(newhome stickylink)"; mkdir -p "$h/.claude" "$h/dotfiles"
runc "$h" --with-doctrine >/dev/null || fail "install (stickylink) failed"
mv "$h/.claude/CLAUDE.md" "$h/dotfiles/CLAUDE.md"; ln -s "$h/dotfiles/CLAUDE.md" "$h/.claude/CLAUDE.md"
cp "$h/dotfiles/CLAUDE.md" "$tmp/sl.orig"
runc "$h" > "$tmp/o-sl" || { cat "$tmp/o-sl"; fail "a sticky run with a symlinked CLAUDE.md failed (must warn and carry on)"; }
grep -q 'CLAUDE.md is a symlink — AgenticOS leaves it untouched' "$tmp/o-sl" || { cat "$tmp/o-sl"; fail "no hands-off warning (sticky)"; }
grep -q "delete the lines from '<!-- agentic-os:doctrine:begin -->'" "$tmp/o-sl" || fail "warning does not name the block to remove"
[[ -L "$h/.claude/CLAUDE.md" ]] && cmp -s "$h/dotfiles/CLAUDE.md" "$tmp/sl.orig" || fail "sticky run touched the symlinked CLAUDE.md"
[[ -n "$(mf_doctrine "$h/.claude/.agentic-os-manifest.json")" && -f "$h/.claude/agentic-os/doctrine.md" ]] \
  || fail "sticky hands-off dropped the record or the doctrine file the import points at"
! grep -q 'install without --with-doctrine' "$tmp/o-sl" || fail "sticky warning tells the user to drop a flag they did not pass"
runc "$h" --uninstall > "$tmp/o-slu" || { cat "$tmp/o-slu"; fail "uninstall with a symlinked CLAUDE.md failed (must warn and carry on)"; }
grep -q 'CLAUDE.md is a symlink — AgenticOS leaves it untouched' "$tmp/o-slu" || fail "no hands-off warning (uninstall)"
[[ -L "$h/.claude/CLAUDE.md" ]] && cmp -s "$h/dotfiles/CLAUDE.md" "$tmp/sl.orig" || fail "uninstall touched the symlinked CLAUDE.md"
[[ ! -e "$h/.claude/.agentic-os-manifest.json" ]] || fail "uninstall did not finish"
[[ -f "$h/.claude/agentic-os/doctrine.md" ]] || fail "hands-off uninstall removed the doctrine file the left-behind import points at"
ok "a symlinked CLAUDE.md under sticky mode or uninstall: warned, left untouched, the rest completes"

h="$(newhome stickyhl)"; mkdir -p "$h/.claude"
runc "$h" --with-doctrine >/dev/null || fail "install (stickyhl) failed"
ln "$h/.claude/CLAUDE.md" "$h/other-link.md"; cp "$h/other-link.md" "$tmp/hl.orig"
runc "$h" > "$tmp/o-hls" || { cat "$tmp/o-hls"; fail "sticky run with a hard-linked CLAUDE.md failed"; }
grep -q 'is hard-linked elsewhere — AgenticOS leaves it untouched' "$tmp/o-hls" || fail "no hands-off warning (hard link)"
runc "$h" --uninstall > "$tmp/o-hlu" || { cat "$tmp/o-hlu"; fail "uninstall with a hard-linked CLAUDE.md failed"; }
cmp -s "$h/other-link.md" "$tmp/hl.orig" || fail "the hard-linked file was changed"
ok "a hard-linked CLAUDE.md under sticky mode or uninstall: warned, left untouched"

# ── 14. Fenced / foreign markers are never taken over (poc P3) ──────────────
h="$(newhome fenced)"; mkdir -p "$h/.claude"
printf '# notes\n```\n%s\nmy example text\n%s\n```\n' "$BEGIN" "$END" > "$h/.claude/CLAUDE.md"
snap "$h" > "$tmp/s-fenced"
if runc "$h" --with-doctrine > "$tmp/o-fenced"; then fail "foreign markers accepted"; fi
grep -q 'is not a block AgenticOS shipped, and no install record' "$tmp/o-fenced" || { cat "$tmp/o-fenced"; fail "no foreign-marker error"; }
snap "$h" | cmp -s - "$tmp/s-fenced" || fail "files changed although the foreign markers were refused"
cp "$h/.claude/CLAUDE.md" "$tmp/fenced.orig"
runc "$h" --uninstall > "$tmp/o-fencedu" || fail "uninstall over foreign markers failed"
cmp -s "$h/.claude/CLAUDE.md" "$tmp/fenced.orig" || fail "uninstall removed the user's own marker example"
ok "markers with no install record are refused (install) and left alone (uninstall)"

# ── 15. CRLF files (poc P2) ──────────────────────────────────────────────────
h="$(newhome crlf)"; mkdir -p "$h/.claude"; printf '# mine\n' > "$h/.claude/CLAUDE.md"
runc "$h" --with-doctrine >/dev/null || fail "install (crlf) failed"
LC_ALL=C awk '{ printf "%s\r\n", $0 }' "$h/.claude/CLAUDE.md" > "$tmp/crlf" && cat "$tmp/crlf" > "$h/.claude/CLAUDE.md"
cp "$h/.claude/CLAUDE.md" "$tmp/crlf.installed"
runc "$h" > "$tmp/o-crlf" || fail "re-run (crlf) failed"
cmp -s "$h/.claude/CLAUDE.md" "$tmp/crlf.installed" || fail "re-run changed a CRLF-converted file (second block?)"
! grep -q 'refresh the doctrine block' "$tmp/o-crlf" || fail "a CRLF conversion was treated as a user edit"
runc "$h" --uninstall >/dev/null || fail "uninstall (crlf) failed"
cmp -s "$h/.claude/CLAUDE.md" <(printf '# mine\r\n') || fail "CRLF uninstall left an orphan import or separator"
h="$(newhome crlf2)"; mkdir -p "$h/.claude"; printf '# win\r\nline2\r\n' > "$h/.claude/CLAUDE.md"; cp "$h/.claude/CLAUDE.md" "$tmp/crlf2.orig"
runc "$h" --with-doctrine >/dev/null || fail "install into a CRLF file failed"
cmp -s "$h/.claude/CLAUDE.md" <(claude_block | LC_ALL=C awk '{ printf "%s\r\n", $0 }'; printf '\r\n'; cat "$tmp/crlf2.orig") \
  || fail "block not written in the file's CRLF line ending"
runc "$h" --uninstall >/dev/null || fail "uninstall of a CRLF file failed"
cmp -s "$h/.claude/CLAUDE.md" "$tmp/crlf2.orig" || fail "CRLF file not restored byte-for-byte"
ok "CRLF: markers with a trailing CR are found, the block uses the file's line ending, uninstall restores the bytes"

# ── 16. A created file keeps the user's own leading blank line (poc P4) ─────
h="$(newhome created-blank)"
runc "$h" --with-doctrine >/dev/null || fail "install (created-blank) failed"
printf '\n# my notes\n' >> "$h/.claude/CLAUDE.md"
runc "$h" --uninstall >/dev/null || fail "uninstall (created-blank) failed"
cmp -s "$h/.claude/CLAUDE.md" <(printf '\n# my notes\n') || fail "uninstall stripped a blank line the user wrote in a file the installer created"
ok "uninstall strips the separator only from files the installer did not create"

# ── 17. A forged record never makes foreign markers ours (round 3, 12C) ─────
h="$(newhome forged-markers)"; mkdir -p "$h/proj/.codex"
printf '%s\nREPO-OWNED-CANARY\n%s\n' "$BEGIN" "$END" > "$h/proj/AGENTS.md"
cp "$h/proj/AGENTS.md" "$tmp/canary.orig"
for forged in "$(sha "$h/proj/AGENTS.md")" 0000000000000000000000000000000000000000000000000000000000000000; do
  printf '{\n  "schema": 1,\n  "doctrine": {"created": true, "block_sha256": "%s"},\n  "files": [\n  ]\n}\n' "$forged" \
    > "$h/proj/.codex/.agentic-os-manifest.json"
  runp "$h" > "$tmp/o-fm" || { cat "$tmp/o-fm"; fail "flagless project run over forged markers failed"; }
  cmp -s "$h/proj/AGENTS.md" "$tmp/canary.orig" || fail "a forged record let a flagless run rewrite repo-owned markers"
  printf '{\n  "schema": 1,\n  "doctrine": {"created": true, "block_sha256": "%s"},\n  "files": [\n  ]\n}\n' "$forged" \
    > "$h/proj/.codex/.agentic-os-manifest.json"
  runp "$h" --uninstall > "$tmp/o-fmu" || { cat "$tmp/o-fmu"; fail "uninstall over forged markers failed"; }
  [[ -f "$h/proj/AGENTS.md" ]] || fail "uninstall deleted a repo AGENTS.md on a forged created=true record"
  [[ "$(grep -c REPO-OWNED-CANARY "$h/proj/AGENTS.md")" == 1 ]] || fail "the canary did not survive uninstall"
  ! ls "$h/proj"/AGENTS.md.bak.* >/dev/null 2>&1 || fail "a forged record produced a backup write in the project"
done
ok "12C: a repo-committed record (real or zero sha) never rewrites or deletes repo-owned markers; the canary survives"

# ── 18. A stale created=true is not carried into the user's own file ───────
h="$(newhome stale-created)"
runc "$h" --with-doctrine >/dev/null || fail "install (stale-created) failed"
jq -e '.doctrine.created == true' "$h/.claude/.agentic-os-manifest.json" >/dev/null || fail "stale-created: setup"
printf 'MY OWN RULES\n' > "$h/.claude/CLAUDE.md"
runc "$h" --with-doctrine >/dev/null || fail "re-add into the user's file failed"
jq -e '.doctrine.created == false' "$h/.claude/.agentic-os-manifest.json" >/dev/null || fail "created=true carried into a file the user wrote"
runc "$h" --uninstall >/dev/null || fail "uninstall (stale-created) failed"
cmp -s "$h/.claude/CLAUDE.md" <(printf 'MY OWN RULES\n') || fail "uninstall left a stray separator in the user's file"
h="$(newhome stale-created-empty)"
runc "$h" --with-doctrine >/dev/null || fail "install (stale-created-empty) failed"
: > "$h/.claude/CLAUDE.md"
runc "$h" --with-doctrine >/dev/null || fail "re-add into an empty user file failed"
runc "$h" --uninstall >/dev/null || fail "uninstall (stale-created-empty) failed"
[[ -f "$h/.claude/CLAUDE.md" && ! -s "$h/.claude/CLAUDE.md" ]] || fail "uninstall deleted the user's (empty) CLAUDE.md on a stale created=true"
ok "created is true only when the installer made the file; a re-add into the user's file records false"

# ── 19. TOCTOU: a target swapped for a symlink mid-write is not written ────
h="$(newhome toctou)"; mkdir -p "$h/.claude" "$h/elsewhere" "$h/bin"
printf 'mine\n' > "$h/.claude/CLAUDE.md"; printf 'victim\n' > "$h/elsewhere/victim.md"
realcat="$(command -v cat)"
cat > "$h/bin/cat" <<EOF
#!/bin/bash
# Swap CLAUDE.md for a symlink right after the plan, while the new content is
# being written to the temp file.
if [[ "\${1:-}" == */doctrine.new && ! -L "$h/.claude/CLAUDE.md" ]]; then
  mv "$h/.claude/CLAUDE.md" "$h/.claude/CLAUDE.md.moved"; ln -s "$h/elsewhere/victim.md" "$h/.claude/CLAUDE.md"
fi
exec "$realcat" "\$@"
EOF
chmod +x "$h/bin/cat"
if HOME="$h" CLAUDE_DIR="$h/.claude" PATH="$h/bin:$PATH" timeout 300 bash "$rel/install.sh" --with-doctrine > "$tmp/o-toctou" 2>&1; then
  fail "install wrote through a target swapped for a symlink mid-run"
fi
grep -q 'changed during the install' "$tmp/o-toctou" || { tail -5 "$tmp/o-toctou"; fail "no TOCTOU error"; }
[[ -L "$h/.claude/CLAUDE.md" ]] || fail "the swapped-in symlink was replaced"
[[ "$(cat "$h/elsewhere/victim.md")" == "victim" ]] || fail "the symlink target was written"
ok "the target is re-checked right before mv: a symlink swapped in mid-run is refused, nothing written through it"

# ── 20. A block edited mid-uninstall is left alone (round 4) ────────────────
h="$(newhome toctou-rm)"; mkdir -p "$h/.claude" "$h/bin"; cf="$h/.claude/CLAUDE.md"
printf 'mine\n' > "$cf"
runc "$h" --with-doctrine >/dev/null || fail "install (toctou-rm) failed"
realjq="$(command -v jq)"
cat > "$h/bin/jq" <<EOF
#!/bin/bash
# Fires on the first jq call, i.e. hook unregistration, after doctrine_plan.
if [[ ! -e "$h/fired" ]]; then
  : > "$h/fired"
  awk '{ print } /agentic-os:doctrine:begin/ { print "MY HAND EDIT" }' "$cf" > "$h/edited"; cat "$h/edited" > "$cf"
fi
exec "$realjq" "\$@"
EOF
chmod +x "$h/bin/jq"
HOME="$h" CLAUDE_DIR="$h/.claude" PATH="$h/bin:$PATH" timeout 300 bash "$rel/install.sh" --uninstall > "$tmp/o-trm" 2>&1 \
  || { tail -5 "$tmp/o-trm"; fail "uninstall (toctou-rm) failed"; }
[[ -e "$h/fired" ]] || fail "toctou-rm: the jq wrapper never ran"
grep -q 'changed during the uninstall' "$tmp/o-trm" || { grep -i doctrine "$tmp/o-trm"; fail "no warning for a block edited mid-uninstall"; }
grep -q 'MY HAND EDIT' "$cf" || fail "uninstall removed a block edited after the plan"
[[ -f "$h/.claude/agentic-os/doctrine.md" ]] || fail "the bail-out still removed agentic-os/doctrine.md (dangling import)"
ok "a block edited between the plan and the write is left alone (with a warning), not removed"

# ── 21. A shipped block quoted with no record is not removed (round 4) ──────
h="$(newhome quoted)"; mkdir -p "$h/.claude"
printf '# notes\n```\n%s\n@agentic-os/doctrine.md\n%s\n```\nmine\n' "$BEGIN" "$END" > "$h/.claude/CLAUDE.md"
cp "$h/.claude/CLAUDE.md" "$tmp/quoted.orig"
runc "$h" >/dev/null || fail "install (quoted) failed"
runc "$h" --uninstall > "$tmp/o-quoted" || fail "uninstall (quoted) failed"
cmp -s "$h/.claude/CLAUDE.md" "$tmp/quoted.orig" || fail "uninstall removed a shipped block the user quoted, with no record"
grep -q 'no install record says AgenticOS put it there' "$tmp/o-quoted" || fail "no hands-off warning for a recordless block"
ok "uninstall with no record leaves even a byte-exact shipped block alone (it may be quoted)"

# ── 22. Project scope: a committed record authorises nothing (round 4) ──────
h="$(newhome proj-rec)"; mkdir -p "$h/proj/.codex"
printf '# repo\n%s\nREPO-OWNED CANARY TEXT\n%s\ntail\n' "$BEGIN" "$END" > "$h/proj/AGENTS.md"
printf '{\n  "schema": 1,\n  "doctrine": {"created": false, "block_sha256": "%s"},\n  "files": [\n  ]\n}\n' \
  "0000000000000000000000000000000000000000000000000000000000000000" > "$h/proj/.codex/.agentic-os-manifest.json"
snap "$h" > "$tmp/s-prec"
if runp "$h" --with-doctrine > "$tmp/o-prec"; then fail "project: a committed record let --with-doctrine refresh foreign markers"; fi
grep -q 'and no install record AgenticOS can trust' "$tmp/o-prec" || { cat "$tmp/o-prec"; fail "project: no foreign-marker refusal"; }
snap "$h" | cmp -s - "$tmp/s-prec" || fail "project: files changed although foreign markers were refused"
h="$(newhome proj-created)"; mkdir -p "$h/proj"
runp "$h" --with-doctrine >/dev/null || fail "project install (proj-created) failed"
[[ -f "$h/proj/AGENTS.md" ]] || fail "project install did not create AGENTS.md"
[[ -z "$(mf_doctrine "$h/proj/.codex/.agentic-os-manifest.json")" ]] || fail "project scope wrote a doctrine record"
rm -rf "$h/proj/.codex"; mkdir -p "$h/proj/.codex"
printf '{\n  "schema": 1,\n  "doctrine": {"created": true, "block_sha256": "%s"},\n  "files": [\n  ]\n}\n' \
  "0000000000000000000000000000000000000000000000000000000000000000" > "$h/proj/.codex/.agentic-os-manifest.json"
cp "$h/proj/AGENTS.md" "$tmp/pc.before"
runp "$h" --uninstall > "$tmp/o-pcu" || { cat "$tmp/o-pcu"; fail "project uninstall (committed created) failed"; }
cmp -s "$h/proj/AGENTS.md" "$tmp/pc.before" || fail "project uninstall deleted or edited AGENTS.md on a committed created=true"
ok "project scope: a committed record neither unlocks foreign markers nor lets uninstall delete AGENTS.md"

# ── 23. agentic-os/ allowlists only doctrine.md (round 4) ───────────────────
h="$(newhome allowlist)"
runc "$h" --with-doctrine >/dev/null || fail "install (allowlist) failed"
printf 'not ours\n' > "$h/.claude/agentic-os/x.md"
mf="$h/.claude/.agentic-os-manifest.json"
awk -v s="$(sha "$h/.claude/agentic-os/x.md")" '{ print } /"files": \[/ { printf "    {\"path\": \"agentic-os/x.md\", \"sha256\": \"%s\"},\n", s }' "$mf" > "$tmp/mf" && cat "$tmp/mf" > "$mf"
runc "$h" --uninstall > "$tmp/o-allow" || { cat "$tmp/o-allow"; fail "uninstall (allowlist) failed"; }
grep -q 'skip agentic-os/x.md — unsafe path' "$tmp/o-allow" || { cat "$tmp/o-allow"; fail "a tampered agentic-os/x.md entry was not refused"; }
[[ "$(cat "$h/.claude/agentic-os/x.md")" == "not ours" ]] || fail "uninstall removed agentic-os/x.md from a tampered manifest"
ok "a tampered manifest cannot reach agentic-os/<anything but doctrine.md>"

# ── 24. Project scope: a committed record never authorises a change (round 5)
h="$(newhome proj-quoted)"; mkdir -p "$h/proj/.codex"
{ printf '# Team notes\n```\n'; codex_block; printf '```\nTEAM CANARY\n'; } > "$h/proj/AGENTS.md"
cp "$h/proj/AGENTS.md" "$tmp/pq.orig"
printf '{\n  "schema": 1,\n  "doctrine": {"created": false, "block_sha256": "%s"},\n  "files": [\n  ]\n}\n' \
  "0000000000000000000000000000000000000000000000000000000000000000" > "$h/proj/.codex/.agentic-os-manifest.json"
runp "$h" --uninstall > "$tmp/o-pq" || { cat "$tmp/o-pq"; fail "project uninstall (quoted block) failed"; }
cmp -s "$h/proj/AGENTS.md" "$tmp/pq.orig" || fail "a committed record let project uninstall strip a shipped block the repo quoted"
h="$(newhome proj-oldblock)"; mkdir -p "$h/proj/.codex"
printf '%s\nan older doctrine text\n%s\n' "$BEGIN" "$END" > "$h/proj/AGENTS.md"
oldsha="$(sha "$h/proj/AGENTS.md")"
rel3="$tmp/rel3"; cp -R "$rel" "$rel3"; printf '%s\n' "$oldsha" >> "$rel3/assets/consumer/doctrine-block-shas.txt"
cp "$h/proj/AGENTS.md" "$tmp/po.orig"
printf '{\n  "schema": 1,\n  "doctrine": {"created": false, "block_sha256": "%s"},\n  "files": [\n  ]\n}\n' "$oldsha" \
  > "$h/proj/.codex/.agentic-os-manifest.json"
HOME="$h" CODEX_HOME="$h/.codex" CODEX_SKILLS_DIR="$h/.agents/skills" CODEX_PROJECT_DIR="$h/proj" timeout 300 "$IB" "$rel3/install.sh" --codex --project \
  > "$tmp/o-po" 2>&1 || { cat "$tmp/o-po"; fail "flagless project run (older shipped block) failed"; }
cmp -s "$h/proj/AGENTS.md" "$tmp/po.orig" || fail "a committed record let a flagless project run refresh an older shipped block"
ok "project scope: a committed record lets neither uninstall strip a quoted block nor a flagless run refresh an old one"

# ── 25. --with-doctrine never adopts a quoted shipped block (round 5) ───────
h="$(newhome adopt)"; mkdir -p "$h/.claude"
printf '# notes\n```\n%s\n@agentic-os/doctrine.md\n%s\n```\nmine\n' "$BEGIN" "$END" > "$h/.claude/CLAUDE.md"
snap "$h" > "$tmp/s-adopt"
if runc "$h" --with-doctrine > "$tmp/o-adopt"; then fail "--with-doctrine adopted a quoted shipped block with no record"; fi
grep -q 'holds a shipped AgenticOS doctrine block, but no install record says AgenticOS wrote it' "$tmp/o-adopt" || { cat "$tmp/o-adopt"; fail "no refusal for a recordless shipped block"; }
snap "$h" | cmp -s - "$tmp/s-adopt" || fail "files changed although the recordless block was refused"
ok "--with-doctrine with no record refuses even a byte-exact shipped block (it may be quoted)"

# ── 26. Project scope: --with-doctrine upgrades an older shipped block ──────
h="$(newhome proj-upgrade)"; mkdir -p "$h/proj"
printf '%s\nolder doctrine\n%s\n' "$BEGIN" "$END" > "$tmp/older.blk"
rel4="$tmp/rel4"; cp -R "$rel" "$rel4"; sha "$tmp/older.blk" >> "$rel4/assets/consumer/doctrine-block-shas.txt"
{ cat "$tmp/older.blk"; printf '\n# team notes\n'; } > "$h/proj/AGENTS.md"; cp "$h/proj/AGENTS.md" "$tmp/pu.orig"
run4() { HOME="$h" CODEX_HOME="$h/.codex" CODEX_SKILLS_DIR="$h/.agents/skills" CODEX_PROJECT_DIR="$h/proj" timeout 300 "$IB" "$rel4/install.sh" --codex --project "$@" 2>&1; }
run4 > "$tmp/o-pu0" || { cat "$tmp/o-pu0"; fail "flagless project run (older block) failed"; }
cmp -s "$h/proj/AGENTS.md" "$tmp/pu.orig" || fail "a flagless project run changed the older block"
run4 --with-doctrine > "$tmp/o-pu" || { cat "$tmp/o-pu"; fail "project --with-doctrine could not upgrade an older shipped block"; }
grep -q "to this release's (it held an older shipped block); the whole file was first saved as" "$tmp/o-pu" || fail "no 'update the doctrine block' line"
cmp -s "$h/proj/AGENTS.md" <(codex_block; printf '\n# team notes\n') || fail "project upgrade did not install the current block in place"
pbak="$(ls "$h/proj"/AGENTS.md.bak.* 2>/dev/null | head -n 1 || true)"
[[ -n "$pbak" ]] && cmp -s "$pbak" "$tmp/pu.orig" || fail "project upgrade did not save the whole file first"
h="$(newhome proj-foreign2)"; mkdir -p "$h/proj"
printf '%s\nnot a shipped block\n%s\n' "$BEGIN" "$END" > "$h/proj/AGENTS.md"; snap "$h" > "$tmp/s-pf2"
if run4 --with-doctrine > "$tmp/o-pf2"; then fail "project --with-doctrine replaced a non-shipped block"; fi
grep -q 'AgenticOS-format doctrine block that is not a block AgenticOS shipped' "$tmp/o-pf2" || { cat "$tmp/o-pf2"; fail "imprecise refusal for a non-shipped block"; }
snap "$h" | cmp -s - "$tmp/s-pf2" || fail "files changed although the non-shipped block was refused"
ok "project scope: --with-doctrine upgrades an older shipped block after a .bak; flagless leaves it; a non-shipped block is refused precisely"

# ── 27. A crash before the record lands rolls the doctrine edit back ───────
mkdir -p "$tmp/shim"
cat > "$tmp/shim/mktemp" <<EOF
#!/bin/bash
# Fail only the manifest temp file (disk full / kill between edit and record).
case "\$*" in *.agentic-os-manifest.*) echo "mktemp: simulated failure" >&2; exit 1 ;; esac
exec "$(command -v mktemp)" "\$@"
EOF
chmod +x "$tmp/shim/mktemp"
runshim() { local h="$1"; shift; HOME="$h" CLAUDE_DIR="$h/.claude" PATH="$tmp/shim:$PATH" timeout 300 "$IB" "$rel/install.sh" "$@" 2>&1; }
h="$(newhome crash)"; mkdir -p "$h/.claude"; printf 'my own rules\n' > "$h/.claude/CLAUDE.md"; cp "$h/.claude/CLAUDE.md" "$tmp/crash.orig"
if runshim "$h" --with-doctrine > "$tmp/o-crash"; then fail "the shimmed manifest failure did not fail the install"; fi
grep -q 'restored to how it was before this run' "$tmp/o-crash" || { tail -5 "$tmp/o-crash"; fail "no rollback message"; }
cmp -s "$h/.claude/CLAUDE.md" "$tmp/crash.orig" || fail "a crash before the record left the doctrine edit in CLAUDE.md"
runc "$h" --with-doctrine > "$tmp/o-crash2" || { cat "$tmp/o-crash2"; fail "re-run after the rolled-back crash failed"; }
cmp -s "$h/.claude/CLAUDE.md" <(claude_block; printf '\nmy own rules\n') || fail "re-run after the crash did not finish the install"
h="$(newhome crash-fresh)"
if runshim "$h" --with-doctrine > "$tmp/o-crash3"; then fail "the shimmed manifest failure did not fail a fresh install"; fi
[[ ! -e "$h/.claude/CLAUDE.md" ]] || fail "a crash before the record left a CLAUDE.md the installer had created"
ok "a failure between the doctrine edit and its record restores the target (or removes a file it created); a re-run then succeeds"

# ── 28. The rollback itself never aborts cleanup (round 7) ─────────────────
# Shim modes, at the moment the manifest temp file is requested:
#   edit      the user edits the target  -> warn "changed since", keep bytes
#   hardlink  the target gains a hard link -> warn, keep bytes
#   rbfail    the rollback's own temp file fails -> warn "could not restore"
#   mvfail    (mv shim) the doctrine write's mv fails -> no warning, original kept
#   term      SIGTERM twice to the installer -> restored, cleanup completes
# Every WORK dir the installer makes is logged (macOS mktemp -d ignores
# TMPDIR) and must be gone afterwards: it holds doctrine.pre, a copy of the
# user's file.
realmk="$(command -v mktemp)"; realmv="$(command -v mv)"
mkdir -p "$tmp/shim2"
cat > "$tmp/shim2/mktemp" <<EOF
#!/bin/bash
case "\$*" in
  *.agentic-os-manifest.*)
    case "\${SHIM_MODE:-}" in
      edit) printf 'user edit mid-run\n' >> "\$SHIM_TGT" ;;
      hardlink) ln "\$SHIM_TGT" "\$SHIM_H/hl" ;;
      rbfail) : > "\$SHIM_H/manifest-failed" ;;
      term) kill -TERM \$PPID; kill -TERM \$PPID; /bin/sleep 1 ;;
    esac
    echo "mktemp: simulated failure" >&2; exit 1 ;;
  */.agentic-os.*)
    if [[ "\${SHIM_MODE:-}" == rbfail && -e "\$SHIM_H/manifest-failed" ]]; then echo "mktemp: simulated failure" >&2; exit 1; fi ;;
esac
out="\$("$realmk" "\$@")"; rc=\$?
if [[ "\${1:-}" == -d ]]; then printf '%s\n' "\$out" >> "\$SHIM_H/workdirs"; fi
printf '%s\n' "\$out"; exit \$rc
EOF
cat > "$tmp/shim2/mv" <<EOF
#!/bin/bash
last="\${@: -1}"
if [[ "\${SHIM_MODE:-}" == mvfail && "\$last" == "\$SHIM_TGT" && ! -e "\$SHIM_H/mvfailed" ]]; then
  : > "\$SHIM_H/mvfailed"; echo "mv: No space left on device" >&2; exit 1
fi
exec "$realmv" "\$@"
EOF
chmod +x "$tmp/shim2/mktemp" "$tmp/shim2/mv"
for mode in edit hardlink rbfail mvfail term; do
  h="$(newhome "rb-$mode")"; mkdir -p "$h/.claude" "$h/tmp"; t="$h/.claude/CLAUDE.md"
  printf 'my own rules\r\nsecond line\n' > "$t"; cp "$t" "$tmp/rb.orig"
  if SHIM_MODE="$mode" SHIM_TGT="$t" SHIM_H="$h" HOME="$h" CLAUDE_DIR="$h/.claude" TMPDIR="$h/tmp" PATH="$tmp/shim2:$PATH" \
       timeout 300 "$IB" "$rel/install.sh" --with-doctrine > "$tmp/o-rb" 2>&1; then
    fail "rollback $mode: the install did not fail"
  fi
  [[ -s "$h/workdirs" ]] || fail "rollback $mode: the mktemp shim logged no WORK dir"
  while IFS= read -r wd; do
    [[ -n "$wd" && ! -e "$wd" ]] || fail "rollback $mode: WORK dir $wd (with the doctrine.pre copy of CLAUDE.md) was left behind"
  done < "$h/workdirs"
  [[ -z "$(ls -A "$h/.claude" | grep '^\.agentic-os\.' || true)" ]] || fail "rollback $mode: a temp file was left beside CLAUDE.md"
  case "$mode" in
    edit)
      grep -q 'which has changed since (or is now a link); left as it is' "$tmp/o-rb" || { tail -5 "$tmp/o-rb"; fail "rollback edit: no 'changed since' warning"; }
      cmp -s "$t" <(claude_block | LC_ALL=C awk '{ printf "%s\r\n", $0 }'; printf '\r\n'; cat "$tmp/rb.orig"; printf 'user edit mid-run\n') \
        || fail "rollback edit: the user's mid-run bytes were not kept" ;;
    hardlink)
      grep -q 'which has changed since (or is now a link); left as it is' "$tmp/o-rb" || { tail -5 "$tmp/o-rb"; fail "rollback hardlink: no warning"; }
      cmp -s "$t" "$h/hl" || fail "rollback hardlink: the hard-linked file was rewritten" ;;
    rbfail)
      grep -q 'could not restore' "$tmp/o-rb" || { tail -5 "$tmp/o-rb"; fail "rollback rbfail: no 'could not restore' warning"; } ;;
    mvfail)
      ! grep -q 'changed since' "$tmp/o-rb" || fail "rollback mvfail: a 'changed since' warning although the write never landed"
      cmp -s "$t" "$tmp/rb.orig" || fail "rollback mvfail: CLAUDE.md is not the original" ;;
    term)
      grep -q 'restored to how it was before this run' "$tmp/o-rb" || { tail -5 "$tmp/o-rb"; fail "rollback term: not restored after SIGTERM"; }
      cmp -s "$t" "$tmp/rb.orig" || fail "rollback term: CLAUDE.md is not the original" ;;
  esac
done
ok "rollback: a mid-window edit or hard link is kept with a warning, a failed restore warns, a failed write is silent, SIGTERM (twice) restores; WORK and the target dir are always cleaned"

if [[ "$SKIPPED" -gt 0 ]]; then
  echo "install-doctrine-test: OK ($P checks, $SKIPPED skipped)"
else
  echo "install-doctrine-test: OK ($P checks)"
fi
