#!/usr/bin/env bash
# Install Skills Library into your Cursor global config.
#
# Shared skill/agent content lives in the repo's .claude/ tree; this script
# copies the consumer allowlist into ~/.cursor/ (skills, agents, dormant hooks).
# Hooks land as scripts only — no hooks.json activation doc ships yet
# (checkpoint:cursor-go NO-GO; register hooks manually when T-cursor-hooks lands).
#
# Usage — pipe from GitHub (no clone required):
#   curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v1.4.0/install-cursor.sh | bash
#
# Usage — from a local clone:
#   ./install-cursor.sh
#
# Options:
#   CURSOR_DIR   Override the install destination (default: ~/.cursor)
#   --force      Overwrite existing files without prompting
#
# Session-state writer resolution (project-first, then global — mirror #143):
#   SS="${CURSOR_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}/.cursor/skills/session-state/scripts/session-state.sh"
#   [ -f "$SS" ] || SS="$HOME/.cursor/skills/session-state/scripts/session-state.sh"
#   bash "$SS" init
#
# Windows: use install-cursor.ps1 for parity. If PowerShell is unavailable,
# install from Git Bash/WSL with this script.
#
# Integrity: the remote install path downloads a PINNED release asset and
# verifies its SHA-256 against EXPECTED_SHA256 below before extracting anything.
# A mismatch aborts the install. To install a different state, install from a
# local clone (./install-cursor.sh) instead — there is intentionally no "track main"
# remote path. See RELEASING.md for how the pin is produced.

set -euo pipefail

REPO_OWNER="${REPO_OWNER:-LazyIsEfficient}"
REPO_NAME="${REPO_NAME:-agentic-os}"

# Pinned release. Both values are produced together by scripts/release.sh and
# must be updated together — EXPECTED_SHA256 is the digest of the release asset
# built from tag $VERSION.
VERSION="v1.4.0"
EXPECTED_SHA256="a999d63479e20431c6e30c8079f6d9764d080e0dea6981de43dc74dfbdbe16c9"

DEST="${CURSOR_DIR:-$HOME/.cursor}"
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

echo ""
echo "Installing to $DEST"

install_dir "skills"
install_dir "agents"
# Hooks: ship scripts dormant — awareness harness scripts land in ~/.cursor/hooks/
# but no hooks.json activation doc ships (opt-in registration is a follow-up task).
install_dir "hooks"

if [[ -d "$DEST/hooks" ]]; then
  find "$DEST/hooks" -name "*.sh" -exec chmod +x {} \;
fi

echo ""
echo "Done. Restart Cursor to load the new skills and agents."
echo ""
echo "Session-state writer (after install):"
echo "  SS=\"\${CURSOR_PROJECT_DIR:-\${CLAUDE_PROJECT_DIR:-.}}/.cursor/skills/session-state/scripts/session-state.sh\""
echo "  [ -f \"\$SS\" ] || SS=\"\$HOME/.cursor/skills/session-state/scripts/session-state.sh\""
echo "  bash \"\$SS\" init"
echo ""
echo "To update later, re-run this script (add --force to overwrite customisations)."
