#!/usr/bin/env bash
#
# check-library-artifact.sh — Tier-0 checker for kind=validate-library-artifact.
#
# Staging approach: copy the repo's live .claude tree into a fresh staging dir,
# drop the PRODUCED artifact (a SKILL.md or an agent .md) under
# <stage>/.claude/skills/<validated-slug>/ (or agents/<validated-name>), then run
# `bash scripts/validate.sh <stage>`. PASS iff validate.sh exits 0.
#
# !! SECURITY — UNTRUSTED ARTIFACT STAGED ONTO A .claude COPY !!
# The artifact is model-generated. Two escapes are defended against here:
#   - symlink/overlay traversal: a symlink in the artifact tree (or `cp -R`
#     following one) could write THROUGH the staged copy into the LIVE repo
#     .claude. We reject any artifact containing a symlink and assert every
#     destination realpath stays under <stage>/.claude before copying.
#   - slug/basename injection: the destination dir is derived from untrusted
#     frontmatter `name:` / filename. We reject any slug or basename that is not
#     a strict DNS-style label (no slashes, no `..`, no dots) before any mkdir/cp.
#
# Usage:
#   check-library-artifact.sh <artifact_dir_or_file>
#
# <artifact_dir_or_file> is one of:
#   - a directory whose layout already mirrors a .claude subtree, e.g.
#       <dir>/skills/<slug>/SKILL.md     or     <dir>/agents/<name>.md
#     (the directory's contents are overlaid onto <stage>/.claude)
#   - a single SKILL.md file: staged as <stage>/.claude/skills/<slug>/SKILL.md
#     where <slug> is taken from the artifact's own `name:` frontmatter
#   - a single agent <name>.md file: staged as <stage>/.claude/agents/<name>.md
#
# Contract: exit 0 = PASS, 1 = FAIL (validate.sh found a regression),
#           2 = could-not-run (missing artifact / no repo .claude tree).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# eval/checkers -> eval -> repo root
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
VALIDATE="$REPO_ROOT/scripts/validate.sh"
LIVE_CLAUDE="$REPO_ROOT/.claude"

if [[ $# -lt 1 ]]; then
  echo "SKIP check-library-artifact: no artifact path given"
  exit 2
fi
ARTIFACT="$1"

if [[ ! -e "$ARTIFACT" ]]; then
  echo "SKIP check-library-artifact: artifact '$ARTIFACT' does not exist"
  exit 2
fi
if [[ ! -f "$VALIDATE" ]]; then
  echo "SKIP check-library-artifact: validator not found at $VALIDATE"
  exit 2
fi
if [[ ! -d "$LIVE_CLAUDE" ]]; then
  echo "SKIP check-library-artifact: live .claude tree not found at $LIVE_CLAUDE"
  exit 2
fi

# Reject any symlink in (or as) the artifact BEFORE staging: `cp -R` would follow
# it and could write through it into the live repo .claude. A symlink in an
# untrusted artifact is never legitimate here.
if [[ -L "$ARTIFACT" ]]; then
  echo "SKIP check-library-artifact: artifact '$ARTIFACT' is a symlink — rejected (staging escape risk)"
  exit 2
fi
if [[ -d "$ARTIFACT" ]] && [[ -n "$(find "$ARTIFACT" -type l -print -quit 2>/dev/null)" ]]; then
  echo "SKIP check-library-artifact: artifact tree contains a symlink — rejected (staging escape risk)"
  exit 2
fi

# --- destination-path guards -------------------------------------------------

# A slug/basename derived from untrusted input must be a strict DNS-style label:
# starts+ends alphanumeric, lowercase, hyphens allowed between. No slashes, no
# '..', no dots — so it cannot escape its parent dir or smuggle a traversal.
valid_slug() {
  [[ "$1" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]
}

# After composing a destination path, assert its realpath stays under
# <stage>/.claude. realpath the existing parent (the path itself may not exist
# yet) and confirm the prefix. Aborts (exit 2) on escape.
assert_under_stage() {
  local dest="$1" parent canon stage_canon
  parent="$(cd "$(dirname "$dest")" 2>/dev/null && pwd -P)" || {
    echo "SKIP check-library-artifact: destination parent for '$dest' is unresolvable — rejected"
    exit 2
  }
  canon="$parent/$(basename "$dest")"
  stage_canon="$(cd "$STAGE/.claude" && pwd -P)"
  case "$canon/" in
    "$stage_canon"/*) : ;;
    *)
      echo "SKIP check-library-artifact: destination '$canon' escapes staging root '$stage_canon' — rejected"
      exit 2
      ;;
  esac
}

# Fresh staging dir with a copy of the live .claude tree.
STAGE="$(mktemp -d "${TMPDIR:-/tmp}/check-lib-artifact.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
cp -R "$LIVE_CLAUDE" "$STAGE/.claude"

# Read a frontmatter `name:` value from a markdown file (crude, matches validate.sh
# parsing assumptions: `^name:` at column 0 inside the first --- block).
fm_name() {
  awk '
    { sub(/\r$/, "") }
    NR==1 && $0!="---" { exit }
    NR==1 { inside=1; next }
    inside && $0=="---" { exit }
    inside && /^name:/ {
      val=$0; sub(/^name:[ \t]*/, "", val); gsub(/^[ \t]+|[ \t]+$/, "", val)
      print val; exit
    }
  ' "$1"
}

# Overlay the produced artifact onto the staged .claude tree.
if [[ -d "$ARTIFACT" ]]; then
  # Directory: overlay its contents onto <stage>/.claude (mirrors a subtree).
  # `cp -R .../.` with --no-dereference (-P would copy symlinks; we already
  # rejected them above, so no symlink survives to be followed).
  cp -R "$ARTIFACT"/. "$STAGE/.claude/"
else
  base="$(basename "$ARTIFACT")"
  if [[ "$base" == "SKILL.md" ]]; then
    slug="$(fm_name "$ARTIFACT")"
    if [[ -z "$slug" ]]; then
      echo "FAIL check-library-artifact: SKILL.md has no 'name:' frontmatter to derive its slug"
      exit 1
    fi
    if ! valid_slug "$slug"; then
      echo "SKIP check-library-artifact: frontmatter name '$slug' is not a valid skill slug (^[a-z0-9]([a-z0-9-]*[a-z0-9])?$) — rejected"
      exit 2
    fi
    mkdir -p "$STAGE/.claude/skills"
    dest="$STAGE/.claude/skills/$slug"
    assert_under_stage "$dest"
    mkdir -p "$dest"
    cp "$ARTIFACT" "$dest/SKILL.md"
  else
    # Treat as an agent definition: <name>.md under agents/. The basename (minus
    # .md) must be a valid slug; reject traversal via the filename.
    name="${base%.md}"
    if [[ "$base" != *.md ]] || ! valid_slug "$name"; then
      echo "SKIP check-library-artifact: agent basename '$base' is not a valid '<slug>.md' name — rejected"
      exit 2
    fi
    mkdir -p "$STAGE/.claude/agents"
    dest="$STAGE/.claude/agents/$base"
    assert_under_stage "$dest"
    cp "$ARTIFACT" "$dest"
  fi
fi

# Run the deterministic validator against the staged tree.
out="$(bash "$VALIDATE" "$STAGE" 2>&1)" && rc=0 || rc=$?

if [[ "$rc" -eq 0 ]]; then
  echo "PASS check-library-artifact: validate.sh clean on staged artifact"
  exit 0
fi

# validate.sh exits 2 only on its own setup error (no .claude) — we guaranteed
# one, so any nonzero here is a genuine FAIL. Surface the first failing line.
firstfail="$(printf '%s\n' "$out" | grep -m1 '^FAIL ' || true)"
echo "FAIL check-library-artifact: validate.sh rejected staged artifact — ${firstfail:-see validator output}"
exit 1
