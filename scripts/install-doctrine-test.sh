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
grep -q 'treating that as an opt-out' "$tmp/o-forged" || fail "no opt-out note"
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
[[ ! -e "$h/.claude/.agentic-os-manifest.json" && ! -e "$h/.claude/agentic-os" ]] || fail "uninstall did not finish"
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
grep -q 'around text AgenticOS did not write' "$tmp/o-fenced" || { cat "$tmp/o-fenced"; fail "no foreign-marker error"; }
snap "$h" | cmp -s - "$tmp/s-fenced" || fail "files changed although the foreign markers were refused"
cp "$h/.claude/CLAUDE.md" "$tmp/fenced.orig"
runc "$h" --uninstall > "$tmp/o-fencedu" || fail "uninstall over foreign markers failed"
cmp -s "$h/.claude/CLAUDE.md" "$tmp/fenced.orig" || fail "uninstall removed the user's own marker example"
ok "markers around text AgenticOS did not write are refused (install) and left alone (uninstall)"

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

if [[ "$SKIPPED" -gt 0 ]]; then
  echo "install-doctrine-test: OK ($P checks, $SKIPPED skipped)"
else
  echo "install-doctrine-test: OK ($P checks)"
fi
