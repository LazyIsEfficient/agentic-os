#!/usr/bin/env bash
# Install Skills Library into your Claude Code global config.
#
# Usage — pipe from GitHub (no clone required):
#   curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/main/install.sh | bash
#
# Usage — from a local clone:
#   ./install.sh
#
# Options:
#   CLAUDE_DIR   Override the install destination (default: ~/.claude)
#   --force      Overwrite existing files without prompting

set -euo pipefail

REPO_OWNER="${REPO_OWNER:-LazyIsEfficient}"
REPO_NAME="${REPO_NAME:-agentic-os}"
BRANCH="main"
DEST="${CLAUDE_DIR:-$HOME/.claude}"
FORCE=false

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
  esac
done

# ── Resolve source ────────────────────────────────────────────────────────────

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "/dev/stdin" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

TMP=""

if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/.claude/skills" ]]; then
  SRC="$SCRIPT_DIR/.claude"
  echo "Installing from local clone at $SCRIPT_DIR"
else

  echo "Downloading from https://github.com/$REPO_OWNER/$REPO_NAME ..."
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT

  if command -v curl &>/dev/null; then
    curl -fsSL "https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$BRANCH.tar.gz" \
      | tar -xz -C "$TMP"
  elif command -v wget &>/dev/null; then
    wget -qO- "https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$BRANCH.tar.gz" \
      | tar -xz -C "$TMP"
  else
    echo "Error: curl or wget is required." >&2
    exit 1
  fi

  SRC="$TMP/$REPO_NAME-$BRANCH/.claude"
fi

# ── Validate before copying ───────────────────────────────────────────────────
# Repo root is the parent of $SRC (which points at .../<root>/.claude) for both
# the local clone and the downloaded tarball. The validator lives at repo-root
# scripts/validate.sh in both cases. Fail closed: never copy from a library that
# fails the structural invariants.
REPO_ROOT="$(cd "$(dirname "$SRC")" && pwd)"
if [[ -f "$REPO_ROOT/scripts/validate.sh" ]]; then
  echo ""
  echo "Validating library structure ..."
  if ! bash "$REPO_ROOT/scripts/validate.sh" "$REPO_ROOT"; then
    echo "Error: library failed structural validation — aborting install." >&2
    exit 1
  fi
else
  echo "Error: scripts/validate.sh not found at $REPO_ROOT — aborting install." >&2
  exit 1
fi

# ── Install ───────────────────────────────────────────────────────────────────

install_dir() {
  local name="$1"
  local src_dir="$SRC/$name"
  local dest_dir="$DEST/$name"

  [[ -d "$src_dir" ]] || return 0

  mkdir -p "$dest_dir"

  if [[ "$FORCE" == "true" ]]; then
    cp -r "$src_dir/." "$dest_dir/"
  else
    # Copy files individually so we never overwrite existing files on any platform
    while IFS= read -r -d '' file; do
      local rel="${file#$src_dir/}"
      local target="$dest_dir/$rel"
      if [[ ! -e "$target" ]]; then
        mkdir -p "$(dirname "$target")"
        cp "$file" "$target"
      fi
    done < <(find "$src_dir" -type f -print0)
  fi

  echo "  ✓ $name → $dest_dir"
}

# Ship-tagged allowlist: copy ONLY the named files from $SRC/$name, never the
# whole directory. Used for surfaces (commands) where some files are
# maintainer-only and must not pollute a consumer's global namespace.
install_files() {
  local name="$1"; shift
  local src_dir="$SRC/$name"
  local dest_dir="$DEST/$name"

  [[ -d "$src_dir" ]] || return 0

  local copied=0
  for rel in "$@"; do
    local src="$src_dir/$rel"
    [[ -f "$src" ]] || continue
    local target="$dest_dir/$rel"
    if [[ "$FORCE" == "true" || ! -e "$target" ]]; then
      mkdir -p "$(dirname "$target")"
      cp "$src" "$target"
    fi
    copied=$((copied + 1))
  done

  [[ "$copied" -gt 0 ]] && echo "  ✓ $name ($copied ship-tagged) → $dest_dir"
}

echo ""
echo "Installing to $DEST"

install_dir "skills"
install_dir "agents"
# Commands: ship-tagged allowlist ONLY — list each file that installs into a
# consumer's global namespace. Author-facing scaffolds and the router ship;
# maintainer-only commands (audit-library, review-gate, plan-clean) and ALL
# workflows stay in-repo and are never installed, to avoid polluting the
# consumer's command namespace.
install_files "commands" "skill-new.md" "agent-new.md" "route.md"
install_dir "hooks"

# Ensure hook scripts are executable
if [[ -d "$DEST/hooks" ]]; then
  find "$DEST/hooks" -name "*.sh" -exec chmod +x {} \;
fi

echo ""
echo "Done. Restart Claude Code to load the new skills, agents, and commands."
echo ""
echo "To update later, re-run this script (add --force to overwrite customisations)."
