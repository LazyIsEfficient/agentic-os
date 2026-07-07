#!/usr/bin/env bash
#
# build-claude-md.sh — regenerate the flat CLAUDE.md from .claude/rules/*.md.
#
# CLAUDE.md ships the doctrine as ONE flat file, no @-imports: Claude Code loads
# a single contiguous doc (imports proved fragile in practice and are invisible
# to non-Claude-Code consumers), while .claude/rules/*.md stay canonical because
# agents, RULESET.md, and validate.sh cite them by path.
#
# Each rule is embedded verbatim between marker comments:
#   <!-- BEGIN RULE: .claude/rules/<name>.md -->
#   ...file content, with ](../ links rebased to ](.claude/ ...
#   <!-- END RULE -->
# validate.sh invariant `claude-flat-sync` re-derives each block and fails on
# drift, so it must apply the SAME link rebase (LINK_REBASE below).
#
# Usage:
#   bash scripts/build-claude-md.sh            # rewrite CLAUDE.md in place
#   bash scripts/build-claude-md.sh --check    # exit 1 + diff if CLAUDE.md is stale
#
# Pure Bash + standard CLI (cat/sed/diff/mktemp). Runs on macOS and Linux.

set -euo pipefail
export LC_ALL=C   # byte-literal text processing, same as validate.sh

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RULES_DIR="$ROOT/.claude/rules"
TARGET="$ROOT/CLAUDE.md"

# Rule files in ../-relative links resolve from .claude/rules/; rebase them to
# repo-root-relative so they stay clickable from the root-level CLAUDE.md.
# BRE on purpose: literal parens portable across BSD and GNU sed. The second
# expression normalizes rules links that climbed to repo root (../../docs/X
# becomes .claude/../docs/X after the first pass — collapse it to docs/X).
LINK_REBASE='s#](\.\./#](.claude/#g; s#](\.claude/\.\./#](#g'
rebase_links() { sed "$LINK_REBASE"; }

# Fixed section order (pre-razor doctrine order). Every file in .claude/rules/
# must appear here, and every entry must exist on disk — the build fails on
# either mismatch so the flat file can never silently drop or invent a section.
ORDER=(
  factual-correctness
  memory-discipline
  subagent-dispatch
  briefing
  grounding
  review-tiers
  verification
  anti-patterns
  communication
)

err() { printf 'build-claude-md: %s\n' "$*" >&2; exit 1; }

[[ -d "$RULES_DIR" ]] || err "missing $RULES_DIR"

# Set-equality between ORDER and the files on disk.
for name in "${ORDER[@]}"; do
  [[ -f "$RULES_DIR/$name.md" ]] || err "ORDER names '$name' but $RULES_DIR/$name.md does not exist"
done
while IFS= read -r f; do
  base="$(basename "$f" .md)"
  found=0
  for name in "${ORDER[@]}"; do [[ "$name" == "$base" ]] && found=1; done
  [[ "$found" == 1 ]] || err "$f exists but is not in ORDER — add it (or remove the file)"
done < <(find "$RULES_DIR" -maxdepth 1 -name '*.md' -type f | sort)

generate() {
  cat <<'EOF'
# Operating rules for this repo

<!-- GENERATED FILE — do not edit rule sections here. Source of truth is
     .claude/rules/*.md; rebuild with `bash scripts/build-claude-md.sh`.
     validate.sh invariant `claude-flat-sync` fails the build on drift.
     This file is deliberately FLAT (no @-imports): one contiguous doc for
     Claude Code, same text visible to non-import-aware consumers.
     install.sh never ships CLAUDE.md or rules/ to consumers. -->

This repo is a skills + agents library. Work here is rarely a single edit — it is research, planning, and dispatch across many specialists. Two capabilities make that tractable: **persistent memory** and **subagents**. Use them aggressively and correctly.
EOF
  local name src
  for name in "${ORDER[@]}"; do
    src="$RULES_DIR/$name.md"
    [[ -z "$(tail -c1 "$src")" ]] || err "$src lacks a trailing newline — add one"
    # A literal marker line inside a source would desync the validator's awk
    # block extraction from the builder's output — reject at build time.
    if grep -qE '^<!-- (BEGIN RULE:|END RULE)' "$src"; then
      err "$src contains a literal BEGIN/END RULE marker line — not allowed in rule sources"
    fi
    printf '\n<!-- BEGIN RULE: .claude/rules/%s.md -->\n' "$name"
    rebase_links < "$src"
    printf '<!-- END RULE -->\n'
  done
}

if [[ "${1:-}" == "--check" ]]; then
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  generate > "$tmp"
  if ! diff -u "$TARGET" "$tmp"; then
    err "CLAUDE.md is out of sync with .claude/rules/ — run: bash scripts/build-claude-md.sh"
  fi
  echo "build-claude-md: CLAUDE.md is in sync"
else
  # Refuse to write through a symlinked CLAUDE.md (a hostile PR could otherwise
  # aim a maintainer's local rebuild at an arbitrary path).
  [[ -L "$TARGET" ]] && err "$TARGET is a symlink — refusing to overwrite"
  generate > "$TARGET"
  echo "build-claude-md: wrote $TARGET"
fi
