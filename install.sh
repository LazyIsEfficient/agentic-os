#!/usr/bin/env bash
# Install Skills Library into your Claude Code global config.
#
# Usage — pipe from GitHub (no clone required):
#   curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v1.4.0/install.sh | bash
#
# Usage — from a local clone:
#   ./install.sh
#
# Options:
#   CLAUDE_DIR   Override the install destination (default: ~/.claude)
#   --force      Overwrite existing files without prompting
#
# Integrity: the remote install path downloads a PINNED release asset and
# verifies its SHA-256 against EXPECTED_SHA256 below before extracting anything.
# A mismatch aborts the install. To install a different state, install from a
# local clone (./install.sh) instead — there is intentionally no "track main"
# remote path. See RELEASING.md for how the pin is produced.

set -euo pipefail

REPO_OWNER="${REPO_OWNER:-LazyIsEfficient}"
REPO_NAME="${REPO_NAME:-agentic-os}"

# Pinned release. Both values are produced together by scripts/release.sh and
# must be updated together — EXPECTED_SHA256 is the digest of the release asset
# built from tag $VERSION.
VERSION="v1.4.0"
EXPECTED_SHA256="a999d63479e20431c6e30c8079f6d9764d080e0dea6981de43dc74dfbdbe16c9"

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

# Compute the SHA-256 of a file using whichever tool is available.
sha256_of() {
  if command -v shasum &>/dev/null; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum &>/dev/null; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "Error: need 'shasum' or 'sha256sum' to verify the download integrity." >&2
    exit 1
  fi
}

if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/.claude/skills" ]]; then
  SRC="$SCRIPT_DIR/.claude"
  echo "Installing from local clone at $SCRIPT_DIR"
else
  ASSET="$REPO_NAME-$VERSION.tar.gz"
  ASSET_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$VERSION/$ASSET"

  echo "Downloading pinned release $VERSION from https://github.com/$REPO_OWNER/$REPO_NAME ..."
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  archive="$TMP/$ASSET"

  if command -v curl &>/dev/null; then
    curl -fsSL -o "$archive" "$ASSET_URL"
  elif command -v wget &>/dev/null; then
    wget -qO "$archive" "$ASSET_URL"
  else
    echo "Error: curl or wget is required." >&2
    exit 1
  fi

  # Verify integrity BEFORE extracting. Fail closed on any mismatch.
  actual_sha="$(sha256_of "$archive")"
  if [[ "$actual_sha" != "$EXPECTED_SHA256" ]]; then
    echo "Error: integrity check FAILED for $ASSET — aborting install." >&2
    echo "  expected: $EXPECTED_SHA256" >&2
    echo "  actual:   $actual_sha" >&2
    echo "Do not proceed. The download may be corrupt or tampered with." >&2
    exit 1
  fi
  echo "  ✓ SHA-256 verified ($actual_sha)"

  if ! tar -xzf "$archive" -C "$TMP"; then
    echo "Error: failed to extract $ASSET — aborting install." >&2
    exit 1
  fi
  SRC="$TMP/$REPO_NAME-$VERSION/.claude"
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
      local rel="${file#"$src_dir"/}"
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
# consumer's global namespace. The author-facing scaffolds plus /state (the
# awareness-harness writer command — its skill + hooks ship alongside) are the
# only consumer commands; maintainer-only commands (audit-library, review-gate,
# triage-findings, eval-harness) stay in-repo and are never installed, to avoid
# polluting the consumer's command namespace.
install_files "commands" "skill-new.md" "agent-new.md" "state.md"
# Workflows: NOTHING ships. The only workflow (audit-skill-library) is a
# maintainer-only tool that stays in-repo and is never installed.
install_dir "hooks"

# Ensure hook scripts are executable
if [[ -d "$DEST/hooks" ]]; then
  find "$DEST/hooks" -name "*.sh" -exec chmod +x {} \;
fi

echo ""
echo "Done. Restart Claude Code to load the new skills, agents, and commands."
echo ""
echo "To update later, re-run this script (add --force to overwrite customisations)."
