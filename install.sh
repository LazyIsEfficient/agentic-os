#!/usr/bin/env bash
set -euo pipefail

# Install skills from YieldGuildGames/skills-directory into the current project.
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/YieldGuildGames/skills-directory/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/YieldGuildGames/skills-directory/main/install.sh | bash -s -- --cursor
#   curl -fsSL https://raw.githubusercontent.com/YieldGuildGames/skills-directory/main/install.sh | bash -s -- --both

REPO="YieldGuildGames/skills-directory"
BRANCH="main"
TARGET="claude"  # default: install to .claude/skills/

for arg in "$@"; do
  case "$arg" in
    --cursor) TARGET="cursor" ;;
    --both)   TARGET="both" ;;
    --claude) TARGET="claude" ;;
    *)        echo "Unknown option: $arg"; exit 1 ;;
  esac
done

ARCHIVE_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Downloading skills from ${REPO}@${BRANCH}..."
curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$TMPDIR"

# The archive extracts to a directory named <repo>-<branch>
SRC="${TMPDIR}/skills-directory-${BRANCH}"

install_skills() {
  local dest="$1"
  mkdir -p "$dest"

  for skill_dir in "$SRC"/*/; do
    # Skip if not a directory or if it's a dotfile/metadata
    [ -d "$skill_dir" ] || continue

    skill_name=$(basename "$skill_dir")

    # Only copy directories that contain a SKILL.md (actual skills)
    [ -f "${skill_dir}/SKILL.md" ] || continue

    echo "  Installing ${skill_name}..."
    rm -rf "${dest}/${skill_name}"
    cp -R "$skill_dir" "${dest}/${skill_name}"
  done
}

if [ "$TARGET" = "claude" ] || [ "$TARGET" = "both" ]; then
  echo "Installing to .claude/skills/..."
  install_skills ".claude/skills"
fi

if [ "$TARGET" = "cursor" ] || [ "$TARGET" = "both" ]; then
  echo "Installing to .cursor/skills/..."
  install_skills ".cursor/skills"
fi

echo "Done. Skills installed successfully."
