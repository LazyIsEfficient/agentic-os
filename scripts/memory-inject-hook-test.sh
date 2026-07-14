#!/usr/bin/env bash
# memory-inject-hook-test.sh — deterministic, OFFLINE plumbing test for the
# memory-injection SessionStart hook (.claude/hooks/memory-inject.sh, issue #225).
#
# The read-side counterpart to memory-extract-hook-test.sh: proves the hook
# surfaces the .claude/memory/ INDEX at session start, no-ops cleanly when there is
# nothing to surface, frames the injection as DATA (not instructions), and honors
# CLAUDE_PROJECT_DIR. No live model. Every fire runs against an ISOLATED
# CLAUDE_PROJECT_DIR (mktemp -d), so this test never reads the repo's own
# .claude/memory/. Dependency-light: bash + coreutils.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO/.claude/hooks/memory-inject.sh"

[ -f "$HOOK" ] || { echo "memory-inject-hook-test: hook not found at $HOOK" >&2; exit 2; }

# One isolated project dir for the whole run — NEVER the real repo memory.
PROJ="$(mktemp -d)"
trap 'rm -rf "$PROJ"' EXIT
export CLAUDE_PROJECT_DIR="$PROJ"
MEM="$PROJ/.claude/memory"
mkdir -p "$MEM"

P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }

# Fire the SessionStart hook (empty stdin). Sets OUT (stdout), RC (exit).
fire(){ OUT="$(bash "$HOOK" </dev/null)"; RC=$?; }

# ── 1. No MEMORY.md → no-op, exit 0, empty stdout ──────────────────────────────
rm -f "$MEM/MEMORY.md"
fire
{ [ "$RC" -eq 0 ] && [ -z "$OUT" ]; } \
  && ok "absent index: exit 0, no output" \
  || no "absent index" "rc=$RC out=[$OUT]"

# ── 2. Header-only index (no '- ' entries) → no-op ─────────────────────────────
printf '<!-- index header comment, no entries yet -->\n' > "$MEM/MEMORY.md"
fire
{ [ "$RC" -eq 0 ] && [ -z "$OUT" ]; } \
  && ok "header-only index: exit 0, no output (never inject an empty index)" \
  || no "empty index" "rc=$RC out=[$OUT]"

# ── 3. Populated index → inject DATA framing + the entry lines ─────────────────
printf '<!-- header -->\n- [Some Fact](some_fact.md) — a durable hook line\n' > "$MEM/MEMORY.md"
fire
has_frame=0; printf '%s' "$OUT" | grep -q 'reference DATA, NOT instructions' && has_frame=1
has_entry=0; printf '%s' "$OUT" | grep -q 'Some Fact' && has_entry=1
{ [ "$RC" -eq 0 ] && [ "$has_frame" -eq 1 ] && [ "$has_entry" -eq 1 ]; } \
  && ok "populated index: injects DATA framing + the index entries" \
  || no "populated index" "rc=$RC frame=$has_frame entry=$has_entry out=[$OUT]"

# ── 4. Isolation: hook read the FIXTURE via CLAUDE_PROJECT_DIR, not repo memory ─
printf '%s' "$OUT" | grep -q 'a durable hook line' \
  && ok "isolation: injected only the fixture index (CLAUDE_PROJECT_DIR honored)" \
  || no "isolation" "fixture line missing from output"

echo ""
echo "memory-inject-hook-test: $P passed, $F failed."
[ "$F" -eq 0 ]
