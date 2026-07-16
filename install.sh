#!/usr/bin/env bash
# Install AgenticOS for Claude Code (default) or Codex.
#
# Usage — pipe from GitHub (no clone required):
#   curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v3.0.1/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/<release-tag>/install.sh | bash -s -- --codex
#
# Usage — from a local clone:
#   ./install.sh
#
# Options:
#   --codex      Install Codex-compatible surfaces (Claude is the default)
#   --project    With --codex, install into the current Git project
#   --force      Overwrite existing files without prompting
#
# Environment overrides:
#   CLAUDE_DIR       Claude destination (default: ~/.claude)
#   CODEX_HOME       Codex config/agent destination (default: ~/.codex)
#   CODEX_SKILLS_DIR Codex user skill destination (default: ~/.agents/skills)
#   CODEX_PROJECT_DIR  Project root used by --codex --project
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
VERSION="v3.0.1"
EXPECTED_SHA256="7fca2eb60fe898b1eae17975a9d1bbecde21b4c813f42ef9e5ee94a87353eaea"

FORCE=false
PLATFORM="claude"
CODEX_SCOPE="user"

usage() {
  printf '%s\n' \
    'Usage: ./install.sh [--claude|--codex] [--project] [--force]' \
    '' \
    '  --codex    Install Codex-compatible skills, agents, and hooks' \
    '  --project  With --codex, install into the current Git project' \
    '  --force    Overwrite existing AgenticOS files' \
    '  --claude   Install for Claude Code (default)'
}

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --codex) PLATFORM="codex" ;;
    --claude) PLATFORM="claude" ;;
    --project) CODEX_SCOPE="project" ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $arg" >&2
      exit 1
      ;;
  esac
done

if [[ "$PLATFORM" != "codex" && "$CODEX_SCOPE" == "project" ]]; then
  echo "Error: --project is only supported with --codex." >&2
  exit 1
fi

if [[ "$PLATFORM" == "claude" ]]; then
  DEST="${CLAUDE_DIR:-$HOME/.claude}"
  if [[ ! "$DEST" =~ ^[/.a-zA-Z0-9._\ -]+$ ]]; then
    echo "Error: unsafe CLAUDE_DIR/DEST (shell metacharacters not allowed): $DEST" >&2
    exit 1
  fi
else
  if [[ "$CODEX_SCOPE" == "project" ]]; then
    if [[ -n "${CODEX_PROJECT_DIR:-}" ]]; then
      CODEX_PROJECT_ROOT="$CODEX_PROJECT_DIR"
    elif command -v git &>/dev/null && git rev-parse --show-toplevel &>/dev/null; then
      CODEX_PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    else
      CODEX_PROJECT_ROOT="$(pwd)"
    fi
    CODEX_CONFIG_DIR="$CODEX_PROJECT_ROOT/.codex"
    CODEX_SKILLS_DEST="$CODEX_PROJECT_ROOT/.agents/skills"
  else
    CODEX_CONFIG_DIR="${CODEX_HOME:-$HOME/.codex}"
    CODEX_SKILLS_DEST="${CODEX_SKILLS_DIR:-$HOME/.agents/skills}"
  fi
  CODEX_AGENTS_DEST="$CODEX_CONFIG_DIR/agents"
  CODEX_HOOKS_DEST="$CODEX_CONFIG_DIR/hooks"

  for path in "$CODEX_CONFIG_DIR" "$CODEX_SKILLS_DEST"; do
    if [[ ! "$path" =~ ^[/.a-zA-Z0-9._\ -]+$ ]]; then
      echo "Error: unsafe Codex destination (shell metacharacters not allowed): $path" >&2
      exit 1
    fi
  done
fi

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

# shellcheck source=scripts/lib/install-hook-settings.sh
source "$REPO_ROOT/scripts/lib/install-hook-settings.sh"

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

install_tree_to() {
  local src_dir="$1" dest_dir="$2" label="$3"
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
  echo "  ✓ $label → $dest_dir"
}

install_selected_files_to() {
  local src_dir="$1" dest_dir="$2" label="$3"; shift 3
  local copied=0 rel src target
  mkdir -p "$dest_dir"
  for rel in "$@"; do
    src="$src_dir/$rel"
    [[ -f "$src" ]] || continue
    target="$dest_dir/$rel"
    if [[ "$FORCE" == "true" || ! -e "$target" ]]; then
      cp "$src" "$target"
    fi
    copied=$((copied + 1))
  done
  [[ "$copied" -gt 0 ]] && echo "  ✓ $label ($copied compatible) → $dest_dir"
}

install_codex_agents() {
  local src_dir="$SRC/agents" dest_dir="$CODEX_AGENTS_DEST"
  local src name description tools sandbox target target_tmp
  [[ -d "$src_dir" ]] || return 0
  mkdir -p "$dest_dir"

  while IFS= read -r -d '' src; do
    name="$(awk '/^name:/{sub(/^name:[[:space:]]*/, ""); print; exit}' "$src")"
    description="$(awk '/^description:/{sub(/^description:[[:space:]]*/, ""); print; exit}' "$src")"
    tools="$(awk '/^tools:/{sub(/^tools:[[:space:]]*/, ""); print; exit}' "$src")"
    [[ -n "$name" && -n "$description" ]] || continue
    if grep -qF "'''" "$src"; then
      echo "Error: cannot safely convert Codex agent $src (contains TOML literal delimiter)." >&2
      exit 1
    fi
    target="$dest_dir/$name.toml"
    if [[ "$FORCE" != "true" && -e "$target" ]]; then
      continue
    fi
    sandbox="read-only"
    if [[ "$tools" == *Edit* || "$tools" == *Write* ]]; then
      sandbox="workspace-write"
    fi
    target_tmp="$target.tmp"
    if ! {
      printf "name = '%s'\n" "$name"
      printf "description = '''\n%s\n'''\n" "$description"
      printf "sandbox_mode = '%s'\n" "$sandbox"
      printf "developer_instructions = '''\n"
      printf "Use Codex-native tools and skill discovery when these role instructions use Claude-specific capability names or relative skill links.\n\n"
      awk '
        NR == 1 && $0 == "---" { fm=1; next }
        fm && $0 == "---" { fm=0; body=1; next }
        body { print }
      ' "$src" \
        | sed -E 's#\$PROJ/\.claude/skills/#$PROJ/.agents/skills/#g; s#\$HOME/\.claude/skills/#$HOME/.agents/skills/#g' \
        | sed -E "s#\(\.\./skills/([^)]+)\)#(<$CODEX_SKILLS_DEST/\1>)#g; s#\(([a-z0-9-]+)\.md\)#(<$CODEX_AGENTS_DEST/\1.toml>)#g"
      printf "\n'''\n"
    } > "$target_tmp"; then
      rm -f "$target_tmp"
      echo "Error: failed to convert Codex agent $src." >&2
      exit 1
    fi
    mv "$target_tmp" "$target"
  done < <(find "$src_dir" -maxdepth 1 -name '*.md' -type f -print0)
  echo "  ✓ agents (Codex TOML) → $dest_dir"
}

if [[ "$PLATFORM" == "claude" ]]; then
  echo ""
  echo "Installing Claude Code surfaces to $DEST"

  install_dir "skills"
  install_dir "agents"
  # Commands: ship-tagged allowlist ONLY — list each file that installs into a
  # consumer's global namespace. The author-facing scaffolds plus /state (the
  # awareness-harness writer command — its skill + hooks ship alongside) are the
  # only consumer commands; maintainer-only commands stay in-repo.
  install_files "commands" "skill-new.md" "agent-new.md" "state.md"
  # Workflows: NOTHING ships. The only workflow is maintainer-only.
  install_dir "hooks"

  if [[ -d "$DEST/hooks" ]]; then
    find "$DEST/hooks" -name "*.sh" -exec chmod +x {} \;
  fi
  merge_claude_hook_settings "$REPO_ROOT" "$DEST"

  echo ""
  echo "Done. Restart Claude Code to load the new skills, agents, commands, and hooks."
else
  echo ""
  echo "Installing Codex skills to $CODEX_SKILLS_DEST"
  echo "Installing Codex config surfaces to $CODEX_CONFIG_DIR"

  install_tree_to "$SRC/skills" "$CODEX_SKILLS_DEST" "skills"
  install_codex_agents
  install_selected_files_to "$SRC/hooks" "$CODEX_HOOKS_DEST" "hooks" \
    "session-state-inject.sh" "session-state-checkpoint.sh"
  find "$CODEX_HOOKS_DEST" -name "*.sh" -exec chmod +x {} \;
  merge_codex_hook_settings "$REPO_ROOT" "$CODEX_CONFIG_DIR"

  echo ""
  echo "Done. Restart Codex to load the skills and agents. Review and trust the new hooks with /hooks."
  echo "Claude slash commands and custom .claude/memory hooks were not installed; Codex uses skills/custom agents and its native memory system instead."
fi

echo ""
echo "To update later, re-run this script (add --force to overwrite customisations)."
