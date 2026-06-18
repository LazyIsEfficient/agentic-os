#!/usr/bin/env bash
#
# validate-test.sh — self-test for scripts/validate.sh.
#
# Proves two things:
#   1. validate.sh exits 0 on a clean copy of the repo.
#   2. Each of the six invariants actually trips: for each invariant we seed
#      exactly one violation in a fresh temp copy and assert validate.sh exits
#      non-zero AND names the right invariant tag.
#
# Pure Bash. Temp dirs via mktemp -d, cleaned via trap.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATE="$SCRIPT_DIR/validate.sh"

TMPDIRS=()
cleanup() { for d in "${TMPDIRS[@]:-}"; do [[ -n "$d" && -d "$d" ]] && rm -rf "$d"; done; }
trap cleanup EXIT

# Make a fresh temp copy of the parts validate.sh needs. MEMORY.md is gitignored
# and therefore absent from the working tree, so it is NOT copied here; cases
# that need it create it explicitly.
make_copy() {
  local dst; dst="$(mktemp -d)"
  TMPDIRS+=("$dst")
  mkdir -p "$dst/scripts"
  cp "$VALIDATE" "$dst/scripts/validate.sh"
  cp -R "$REPO_ROOT/.claude" "$dst/.claude"
  # memory/ is gitignored; drop any local copy so the baseline matches CI/tarball
  rm -rf "$dst/.claude/memory"
  cp "$REPO_ROOT/CLAUDE.md" "$dst/CLAUDE.md"
  cp "$REPO_ROOT/install.sh" "$dst/install.sh"
  cp "$REPO_ROOT/install.ps1" "$dst/install.ps1"
  printf '%s' "$dst"
}

PASS=0
FAIL=0

report() {
  # $1 = label, $2 = "pass"|"fail", $3 = detail
  if [[ "$2" == "pass" ]]; then
    printf 'PASS  %s\n' "$1"
    PASS=$((PASS + 1))
  else
    printf 'FAIL  %s — %s\n' "$1" "$3"
    FAIL=$((FAIL + 1))
  fi
}

# Run validate.sh against a tmp root; capture output + exit code into globals.
run_validate() {
  VOUT="$(bash "$1/scripts/validate.sh" "$1" 2>&1)"; VRC=$?
}

# ── Case 0: clean copy passes ──────────────────────────────────────────────────
clean="$(make_copy)"
run_validate "$clean"
if [[ "$VRC" -eq 0 ]]; then
  report "clean copy exits 0" pass
else
  report "clean copy exits 0" fail "exit=$VRC; output:\n$VOUT"
fi

# Assert: validate trips, non-zero exit, output contains the expected tag.
assert_trips() {
  local label="$1" root="$2" tag="$3"
  run_validate "$root"
  if [[ "$VRC" -ne 0 ]] && grep -q "FAIL \[$tag\]" <<<"$VOUT"; then
    report "$label" pass
  else
    report "$label" fail "exit=$VRC, missing tag [$tag]; output:\n$VOUT"
  fi
}

# ── Case 1: frontmatter — blank out description in one SKILL.md ─────────────────
c1="$(make_copy)"
skill1="$(find "$c1/.claude/skills" -name SKILL.md -type f | sort | head -1)"
# Replace the description line with an empty key.
awk '
  done2 { print; next }
  /^description:/ { print "description:"; done2=1; next }
  { print }
' "$skill1" > "$skill1.tmp" && mv "$skill1.tmp" "$skill1"
assert_trips "case 1 frontmatter (empty description)" "$c1" frontmatter

# ── Case 2: names — break a skill name to NotKebab + mismatch ───────────────────
c2="$(make_copy)"
skill2="$(find "$c2/.claude/skills" -name SKILL.md -type f | sort | head -1)"
awk '
  done2 { print; next }
  /^name:/ { print "name: NotKebab"; done2=1; next }
  { print }
' "$skill2" > "$skill2.tmp" && mv "$skill2.tmp" "$skill2"
assert_trips "case 2 names (NotKebab / mismatch)" "$c2" names

# ── Case 3: dangling-ref — add a [[does-not-exist]] wikilink to a memory file ───
c3="$(make_copy)"
mkdir -p "$c3/.claude/memory"
# MEMORY.md is gitignored; create a minimal valid one, then a sibling with a bad wikilink.
printf -- '- [Seed](seed.md) — hook\n' > "$c3/.claude/memory/MEMORY.md"
printf 'seed\n' > "$c3/.claude/memory/seed.md"
printf 'See [[does-not-exist]] for more.\n' > "$c3/.claude/memory/note.md"
assert_trips "case 3 dangling-ref (bad wikilink)" "$c3" dangling-ref

# ── Case 4: claude-imports — append a nonexistent @-import ──────────────────────
c4="$(make_copy)"
printf '@.claude/rules/nonexistent.md\n' >> "$c4/CLAUDE.md"
assert_trips "case 4 claude-imports (missing import)" "$c4" claude-imports

# ── Case 5: memory-length — write a 201-line MEMORY.md ─────────────────────────
c5="$(make_copy)"
mkdir -p "$c5/.claude/memory"
# awk loop (not `yes`): GNU `yes` parses a leading-dash argument as options and
# errors out, leaving an empty file so the invariant never trips (BSD `yes` does not).
awk 'BEGIN { for (i = 0; i < 201; i++) print "- [x](x.md) — y" }' > "$c5/.claude/memory/MEMORY.md"
printf 'x\n' > "$c5/.claude/memory/x.md"   # keep links resolving so only memory-length trips
assert_trips "case 5 memory-length (201 lines)" "$c5" memory-length

# ── Case 6: ship-manifest — append install_dir "rules" to install.sh ───────────
c6="$(make_copy)"
printf 'install_dir "rules"\n' >> "$c6/install.sh"
assert_trips "case 6 ship-manifest (unexpected dir)" "$c6" ship-manifest

# ── Case 7: dangling-ref — bad markdown link in MEMORY.md (sub-check a) ─────────
c7="$(make_copy)"
mkdir -p "$c7/.claude/memory"
printf -- '- [Gone](nope.md) — hook\n' > "$c7/.claude/memory/MEMORY.md"
assert_trips "case 7 dangling-ref (bad MEMORY link)" "$c7" dangling-ref

# ── Case 8: dangling-ref — bad relative link inside a SKILL.md (sub-check c) ────
c8="$(make_copy)"
skill8="$(find "$c8/.claude/skills" -name SKILL.md -type f | sort | head -1)"
printf '\nSee [the helper](references/does-not-exist-xyz.md) for details.\n' >> "$skill8"
assert_trips "case 8 dangling-ref (bad SKILL relative link)" "$c8" dangling-ref

# ── Case 9: ship-manifest — drop a ship-tagged command (missing expected) ──────
c9="$(make_copy)"
sed -E 's/[[:space:]]*"route\.md"//' "$c9/install.sh" > "$c9/install.sh.tmp" && mv "$c9/install.sh.tmp" "$c9/install.sh"
assert_trips "case 9 ship-manifest (missing command)" "$c9" ship-manifest

# ── Case 10: ship-manifest — line-continuation reflow must STAY clean ───────────
# Regression guard for the whole-file token scan: rewriting the single-line
# install_files into a backslash-continued multi-line form must not false-abort.
c10="$(make_copy)"
awk '
  /^install_files "commands"/ {
    print "install_files \"commands\" \\"
    print "  \"skill-new.md\" \\"
    print "  \"agent-new.md\" \\"
    print "  \"route.md\" \\"
    print "  \"v2-collab.md\""
    next
  }
  { print }
' "$c10/install.sh" > "$c10/install.sh.tmp" && mv "$c10/install.sh.tmp" "$c10/install.sh"
run_validate "$c10"
if [[ "$VRC" -eq 0 ]]; then
  report "case 10 ship-manifest (continuation reflow stays clean)" pass
else
  report "case 10 ship-manifest (continuation reflow stays clean)" fail "exit=$VRC; output:\n$VOUT"
fi

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo "validate-test.sh: $PASS passed, $FAIL failed."
[[ "$FAIL" -eq 0 ]] || exit 1
exit 0
