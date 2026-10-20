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
# (BASE_REV); in a shallow clone without it, that case is reported as SKIP.
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
runc() { local h="$1"; shift; HOME="$h" CLAUDE_DIR="$h/.claude" timeout 300 bash "$rel/install.sh" "$@" 2>&1; }
runx() { local h="$1"; shift; HOME="$h" CODEX_HOME="$h/.codex" CODEX_SKILLS_DIR="$h/.agents/skills" \
  timeout 300 bash "$rel/install.sh" --codex "$@" 2>&1; }
runp() { local h="$1"; shift; HOME="$h" CODEX_HOME="$h/.codex" CODEX_SKILLS_DIR="$h/.agents/skills" CODEX_PROJECT_DIR="$h/proj" \
  timeout 300 bash "$rel/install.sh" --codex --project "$@" 2>&1; }
mf_doctrine() { jq -c '.doctrine // empty' "$1"; }

# ── 1. No flag: byte-identical to the pre-#271 installer ─────────────────────
if git -C "$REPO" cat-file -e "$BASE_REV:install.sh" 2>/dev/null; then
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
          timeout 300 bash "$r/install.sh" "$@" "${extra[@]}" 2>&1 | sed "s#$r#REL#g; s/[0-9]\{14\}\.[0-9]*/STAMP/g" >> "$tmp/parity-$v.out" \
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
runc "$h" --uninstall > "$tmp/o-edited-u" || fail "uninstall over an edited block failed"
[[ "$(cat "$cf")" == "mine" ]] || fail "uninstall over an edited block did not restore the user content"
[[ "$(ls "$h/.claude"/CLAUDE.md.bak.* | wc -l | tr -d ' ')" == 2 ]] || fail "uninstall did not back up the edited block"
ok "a user-edited block is refreshed (install) or removed (uninstall) only after a byte-exact .bak"

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

if runc "$h" --uninstall --with-doctrine >/dev/null; then fail "--uninstall --with-doctrine accepted"; fi
ok "--uninstall rejects --with-doctrine"

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
jq -e '.doctrine.created == false' "$h/proj/.codex/.agentic-os-manifest.json" >/dev/null || fail "project manifest record missing"
[[ ! -e "$h/.codex/AGENTS.md" ]] || fail "project install wrote the global AGENTS.md"
runp "$h" --uninstall >/dev/null || fail "project uninstall failed"
cmp -s "$h/proj/AGENTS.md" "$tmp/p-orig" || fail "project uninstall did not restore AGENTS.md"
ok "Codex --project: doctrine in the project-root AGENTS.md, recorded in .codex, restored on uninstall"

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
{ printf 'a\n'; claude_block; printf 'b\n'; } > "$h/.claude/CLAUDE.md"
runc "$h" --with-doctrine >/dev/null || fail "re-run (moved) failed"
cmp -s "$h/.claude/CLAUDE.md" <(printf 'a\n'; claude_block; printf 'b\n') || fail "re-run moved the user's relocated block"
runc "$h" --uninstall >/dev/null || fail "uninstall (moved) failed"
cmp -s "$h/.claude/CLAUDE.md" <(printf 'a\nb\n') || fail "uninstall of a relocated block changed other lines"
ok "a block the user moved stays where it is, and uninstall removes only its lines"

if [[ "$SKIPPED" -gt 0 ]]; then
  echo "install-doctrine-test: OK ($P checks, $SKIPPED skipped)"
else
  echo "install-doctrine-test: OK ($P checks)"
fi
