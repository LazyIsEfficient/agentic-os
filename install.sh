#!/usr/bin/env bash
# Install, update, or uninstall AgenticOS for Claude Code (default) or Codex.
#
# Usage — pipe from GitHub (no clone required):
#   curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/v3.0.1/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/LazyIsEfficient/agentic-os/<release-tag>/install.sh | bash -s -- --codex
#
# Usage — from a local clone:
#   ./install.sh
#
# Options:
#   --codex         Install Codex-compatible surfaces (Claude is the default)
#   --project       With --codex, install into the current Git project
#   --force         Also overwrite AgenticOS files you modified locally
#   --prune-legacy  Remove retired skill directories left by pre-manifest installs
#   --uninstall     Remove AgenticOS-owned files and hook registrations
#   --dry-run       Print what would change; change nothing
#   --with-doctrine Also install the grounding/verification/review-tier doctrine
#                   as one marked block in CLAUDE.md (an @-import of
#                   agentic-os/doctrine.md) or, for Codex, AGENTS.md (inlined).
#                   Opt-in. Later runs without the flag keep it current
#                   while the block is still there; deleting the block opts out.
#
# Lifecycle: each install root gets a manifest (.agentic-os-manifest.json) of
# every file installed and its SHA-256. Re-running updates files you have not
# modified, keeps (and names) files you have, always refreshes shipped hooks
# (backing up a modified one to <file>.bak.<timestamp>), prunes files a release
# dropped, and never touches files that are not in a manifest.
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

# Hook scripts removed from assets/consumer/claude-settings.json in a past
# release (basenames, space-separated). Install and uninstall unregister them
# from settings.json; their files are pruned through the manifest. Keep in sync
# with $RetiredHooks in install.ps1 (validate.sh checks).
RETIRED_HOOKS=""

MANIFEST_NAME=".agentic-os-manifest.json"

unset CODEX_HOOKS_REGISTERED
FORCE=false
DRY_RUN=false
PRUNE_LEGACY=false
UNINSTALL=false
WITH_DOCTRINE=false
PLATFORM="claude"
CODEX_SCOPE="user"

usage() {
  printf '%s\n' \
    'Usage: ./install.sh [--claude|--codex] [--project] [--force] [--prune-legacy] [--with-doctrine] [--dry-run]' \
    '       ./install.sh [--claude|--codex] [--project] --uninstall [--dry-run]' \
    '' \
    '  --codex         Install Codex-compatible skills, agents, and hooks' \
    '  --project       With --codex, install into the current Git project' \
    '  --force         Also overwrite AgenticOS files you modified locally' \
    '  --prune-legacy  Remove retired skill directories left by pre-manifest installs' \
    '  --uninstall     Remove AgenticOS-owned files and hook registrations' \
    '  --dry-run       Print what would change; change nothing' \
    '  --with-doctrine Also add the AgenticOS doctrine block to CLAUDE.md (Codex: AGENTS.md)' \
    '  --claude        Install for Claude Code (default)'
}

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --dry-run) DRY_RUN=true ;;
    --prune-legacy) PRUNE_LEGACY=true ;;
    --uninstall) UNINSTALL=true ;;
    --with-doctrine) WITH_DOCTRINE=true ;;
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
if [[ "$UNINSTALL" == "true" && ( "$FORCE" == "true" || "$PRUNE_LEGACY" == "true" ) ]]; then
  echo "Error: --force and --prune-legacy do not apply to --uninstall (modified files are always kept)." >&2
  exit 1
fi
if [[ "$UNINSTALL" == "true" && "$WITH_DOCTRINE" == "true" ]]; then
  echo "Error: --with-doctrine does not apply to --uninstall (uninstall always removes the doctrine block)." >&2
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

  for path in "$CODEX_CONFIG_DIR" "$CODEX_SKILLS_DEST"; do
    if [[ ! "$path" =~ ^[/.a-zA-Z0-9._\ -]+$ ]]; then
      echo "Error: unsafe Codex destination (shell metacharacters not allowed): $path" >&2
      exit 1
    fi
  done

  # Project scope: .codex / .agents / .agents/skills come from the repo, so a
  # committed symlink could aim every write (and uninstall's deletes) at the
  # user's global ~/.codex or anywhere else. Each must be a real directory
  # (or absent) that resolves inside the project root.
  if [[ "$CODEX_SCOPE" == "project" ]]; then
    if [[ ! -d "$CODEX_PROJECT_ROOT" ]]; then
      echo "Error: Codex project root does not exist: $CODEX_PROJECT_ROOT" >&2
      exit 1
    fi
    proj_canon="$(cd "$CODEX_PROJECT_ROOT" && pwd -P)"
    for rel in .codex .agents .agents/skills; do
      p="$CODEX_PROJECT_ROOT/$rel"
      if [[ -L "$p" ]]; then
        echo "Error: $p is a symlink. In project scope AgenticOS only writes into real directories inside the project; replace it with a directory, then re-run. Nothing was changed." >&2
        exit 1
      fi
      if [[ -d "$p" ]]; then
        c="$(cd "$p" && pwd -P)"
        if [[ "$c" != "$proj_canon"/* ]]; then
          echo "Error: $p resolves outside the project ($c). Nothing was changed." >&2
          exit 1
        fi
      fi
    done
  fi
fi

# ── Resolve source ────────────────────────────────────────────────────────────

SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "/dev/stdin" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

TMP=""
WORK=""
PREFLIGHT_DIRS=""
cleanup() {
  if [[ -n "$TMP" ]]; then rm -rf "$TMP"; fi
  if [[ -n "$WORK" ]]; then rm -rf "$WORK"; fi
  local d
  for d in $PREFLIGHT_DIRS; do rm -rf "$d"; done
}
trap cleanup EXIT

if command -v shasum &>/dev/null; then
  SHA_CMD=(shasum -a 256)
elif command -v sha256sum &>/dev/null; then
  SHA_CMD=(sha256sum)
else
  echo "Error: need 'shasum' or 'sha256sum' to verify integrity and track installed files." >&2
  exit 1
fi

sha256_of() {
  "${SHA_CMD[@]}" "$1" | awk '{print $1}'
}

if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/.claude/skills" ]]; then
  SRC="$SCRIPT_DIR/.claude"
  SOURCE_KIND="local-clone"
  echo "Using local clone at $SCRIPT_DIR"
else
  SOURCE_KIND="release"
  ASSET="$REPO_NAME-$VERSION.tar.gz"
  ASSET_URL="https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$VERSION/$ASSET"

  echo "Downloading pinned release $VERSION from https://github.com/$REPO_OWNER/$REPO_NAME ..."
  TMP="$(mktemp -d)"
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
# fails the structural invariants. (Uninstall copies nothing, so it skips this.)
REPO_ROOT="$(cd "$(dirname "$SRC")" && pwd)"
if [[ ! -f "$REPO_ROOT/scripts/validate.sh" ]]; then
  echo "Error: scripts/validate.sh not found at $REPO_ROOT — aborting." >&2
  exit 1
fi
if [[ "$UNINSTALL" != "true" ]]; then
  echo ""
  echo "Validating library structure ..."
  if ! bash "$REPO_ROOT/scripts/validate.sh" "$REPO_ROOT"; then
    echo "Error: library failed structural validation — aborting install." >&2
    exit 1
  fi
fi

# The caller's environment must not be able to satisfy the API gate below.
unset AGENTIC_OS_HOOK_LIB_API
# shellcheck source=scripts/lib/install-hook-settings.sh
source "$REPO_ROOT/scripts/lib/install-hook-settings.sh"

# The hook library comes from the payload, this script from wherever it was
# fetched. A mismatched pair (e.g. this install.sh over an older pinned
# tarball) would silently run the old library's behaviour (a dry run that
# writes, unregister functions that do not exist), so refuse it before
# anything is written.
REQUIRED_LIB_API=2
lib_api="${AGENTIC_OS_HOOK_LIB_API:-0}"
for fn in merge_claude_hook_settings unregister_claude_hook_settings \
          merge_codex_hook_settings unregister_codex_hook_settings; do
  declare -F "$fn" >/dev/null || lib_api=0
done
if [[ ! "$lib_api" =~ ^[0-9]+$ || "$lib_api" -lt "$REQUIRED_LIB_API" ]]; then
  echo "Error: $REPO_ROOT/scripts/lib/install-hook-settings.sh is older than this installer" >&2
  echo "  (hook-library API ${AGENTIC_OS_HOOK_LIB_API:-none}, need $REQUIRED_LIB_API)." >&2
  echo "  Use the install.sh from the same release as the payload (the pinned one-liner URL), or install from a local clone. Nothing was changed." >&2
  exit 1
fi

# Install/update: the CANONICAL Claude dir (symlinked parents resolved, plus
# the not-yet-created tail of DEST) goes into hook commands, so it must pass
# the library's hook-path gate, before anything is written. Uninstall is
# exempt: it runs no hook command, only string-compares registered commands
# (as jq data) and deletes quoted manifest paths, and it is the only way to
# clean up an install made into such a path before this check existed.
if [[ "$PLATFORM" == "claude" && "$UNINSTALL" != "true" ]]; then
  dest_anc="$DEST"; dest_tail=""
  while [[ ! -d "$dest_anc" ]]; do
    dest_tail="/$(basename "$dest_anc")$dest_tail"
    dest_anc="$(dirname "$dest_anc")"
  done
  _validate_hook_dir "$DEST"
  _validate_hook_dir "$(cd "$dest_anc" && pwd -P)$dest_tail"
fi

# Retired skill slugs: the validator's TOMBSTONES list is the single source.
TOMBSTONES="$(sed -n 's/^TOMBSTONES="\(.*\)"$/\1/p' "$REPO_ROOT/scripts/validate.sh")"

# "<sha256>  <path>" of every file in every earlier release (path relative to
# .claude/), generated by scripts/gen-release-hashes.sh. Lets adoption of a
# pre-manifest install tell an untouched old-release file from a user edit.
RELEASE_HASHES="$REPO_ROOT/assets/release-hashes.txt"

WORK="$(mktemp -d)"
STAMP="$(date +%Y%m%d%H%M%S).$$"
P=""
[[ "$DRY_RUN" == "true" ]] && P="[dry-run] "
N_WARN=0
N_KEPT=0
N_UNSAFE=0
N_FOREIGN=0

note() { printf '  %s%s\n' "$P" "$*"; }
warn() { printf '  ⚠ %s%s\n' "$P" "$*"; N_WARN=$((N_WARN + 1)); }
kept() { warn "$@"; N_KEPT=$((N_KEPT + 1)); }

# ── Manifest ──────────────────────────────────────────────────────────────────

# Hash NUL-separated paths (list file $2, relative to dir $1) into "<rel>\t<sha>"
# lines in $3, sorted by path. Callers only pass paths that are already
# charset-checked (no tab/newline), so the TSV is unambiguous.
hash_into() {
  local dir="$1" list="$2" out="$3"
  : > "$out"
  [[ -s "$list" ]] || return 0
  (cd "$dir" && xargs -0 "${SHA_CMD[@]}" < "$list") \
    | LC_ALL=C awk '{ p = substr($0, 67); sub(/^\.\//, "", p); print p "\t" substr($0, 1, 64) }' \
    | LC_ALL=C sort > "$out"
}

# "<rel>\t<sha>" for each well-formed entry of manifest $1 (path charset
# [A-Za-z0-9._@+/-], 64-hex sha). This is a parse filter only; containment is
# enforced by safe_rel before anything is written or removed.
read_manifest() {
  [[ -f "$1" ]] || return 0
  LC_ALL=C awk '
    match($0, /"path": "[^"]*", "sha256": "[0-9a-f]+"/) {
      s = substr($0, RSTART, RLENGTH)
      p = s; sub(/^"path": "/, "", p); sub(/", "sha256".*$/, "", p)
      h = s; sub(/.*"sha256": "/, "", h); sub(/"$/, "", h)
      if (length(h) != 64 || p !~ /^[A-Za-z0-9._@+\/-]+$/) next
      print p "\t" h
    }' "$1" | LC_ALL=C sort -u
}

# Release paths are restricted to [A-Za-z0-9._@+-] segments, so manifest JSON
# needs no escaping.
write_manifest() {
  local root="$1" tsv="$2" platform="$3" out="$1/$MANIFEST_NAME"
  local tmpf
  if [[ -L "$out" ]]; then
    echo "Error: $out is a symlink — refusing to write the manifest through it. Remove it and re-run." >&2
    exit 1
  fi
  # mktemp (O_EXCL, beside the target) so a planted link at a fixed .tmp name
  # can never redirect the write; mv then replaces the directory entry.
  tmpf="$(mktemp "$root/.agentic-os-manifest.XXXXXX")"
  {
    printf '{\n  "schema": 1,\n  "name": "agentic-os",\n  "version": "%s",\n' "$VERSION"
    printf '  "source": "%s",\n  "platform": "%s",\n' "$SOURCE_KIND" "$platform"
    if [[ -n "$DOC_CREATED" && "$root" == "$DOC_MF_ROOT" ]]; then
      printf '  "doctrine": {"created": %s, "block_sha256": "%s"},\n' "$DOC_CREATED" "$DOC_BLOCK_SHA"
    fi
    printf '  "files": [\n'
    LC_ALL=C awk -F'\t' '
      NR > 1 { printf ",\n" }
      { printf "    {\"path\": \"%s\", \"sha256\": \"%s\"}", $1, $2 }
      END { if (NR) printf "\n" }' "$tsv"
    printf '  ]\n}\n'
  } > "$tmpf"
  chmod 644 "$tmpf"
  mv -f "$tmpf" "$out"
}

# ── Path safety ───────────────────────────────────────────────────────────────

# Canonical (symlink-resolved) form of the root being processed; set by
# set_root before any safe_rel call. Empty while the root does not exist yet.
ROOT_CANON=""
set_root() {
  ROOT_CANON=""
  if [[ -d "$1" ]]; then ROOT_CANON="$(cd "$1" && pwd -P)"; fi
}

# Succeeds only when "$1/$2" may be written or removed. The single gate in
# front of every write, backup, and rm:
#   - every component is [A-Za-z0-9._@+-], none is `.`/`..`, and there are at
#     least two (nothing at the root itself: never the manifest, settings.json,
#     hooks.json, CLAUDE.md, AGENTS.md);
#   - the first component is a shipped prefix from $3 ("*" = a Codex skills
#     root, whose first component is the skill name);
#   - a skill path (Claude `skills/<name>/...`, or a Codex skills root) names a
#     skill AgenticOS ships or has shipped (SKILL_NAMES), so a tampered manifest
#     cannot reach another vendor's skills;
#   - no component from the root down to the file is a symlink, and the parent
#     resolves (pwd -P) inside the canonical root.
safe_rel() {
  local root="$1" rel="$2" allow="$3" first skill p c dir canon
  [[ "$rel" =~ ^[A-Za-z0-9._@+-]+(/[A-Za-z0-9._@+-]+)+$ ]] || return 1
  case "/$rel/" in */./*|*/../*) return 1 ;; esac
  first="${rel%%/*}"
  skill=""
  if [[ "$allow" == "*" ]]; then
    skill="$first"
  else
    case " $allow " in *" $first "*) ;; *) return 1 ;; esac
    # agentic-os/ holds exactly one AgenticOS file.
    if [[ "$first" == "agentic-os" && "$rel" != "$DOCTRINE_REL" ]]; then return 1; fi
    if [[ "$first" == "skills" ]]; then skill="${rel#skills/}"; skill="${skill%%/*}"; fi
  fi
  if [[ -n "$skill" ]]; then
    case " $SKILL_NAMES " in *" $skill "*) ;; *) return 1 ;; esac
  fi
  p="$root"
  local IFS=/
  for c in $rel; do
    p="$p/$c"
    [[ -L "$p" ]] && return 1
  done
  dir="${p%/*}"
  if [[ -d "$dir" ]]; then
    # A fresh root only appears once the first file is placed.
    [[ -n "$ROOT_CANON" ]] || set_root "$root"
    [[ -n "$ROOT_CANON" ]] || return 1
    canon="$(cd "$dir" && pwd -P)"
    [[ "$canon" == "$ROOT_CANON" || "$canon" == "$ROOT_CANON"/* ]] || return 1
  fi
  return 0
}

# Known earlier-release copies for this root, "<rel>\t<sha>" (see
# RELEASE_HASHES). $1 = skills prefix of the root ("skills/", "" for a Codex
# skills root whose paths drop it, "-" for a root holding no skills).
load_known() {
  local skillp="$1" out="$2"
  : > "$out"
  [[ -f "$RELEASE_HASHES" ]] || return 0
  LC_ALL=C awk -v sp="$skillp" '
    /^#/ || NF != 2 || length($1) != 64 { next }
    { p = $2 }
    sp == "" { if (p !~ /^skills\//) next; sub(/^skills\//, "", p) }
    { print p "\t" $1 }' "$RELEASE_HASHES" | LC_ALL=C sort -u > "$out"
}

# True when on-disk sha $3 of $2 is an AgenticOS copy: the one the manifest
# recorded ($4), or any earlier release's copy of that path (known list $1).
unmodified() {
  local known="$1" rel="$2" csha="$3" osha="$4"
  [[ "$csha" == "$osha" ]] && return 0
  grep -qxF -- "$rel"$'\t'"$csha" "$known"
}

# Replace "$2" with a copy of "$1" via a temp file in the same directory, so the
# write never goes through an existing hard link or symlink at the target.
place() {
  [[ "$DRY_RUN" == "true" ]] && return 0
  local dir tmpf
  dir="$(dirname "$2")"
  mkdir -p "$dir"
  tmpf="$(mktemp "$dir/.agentic-os.XXXXXX")"
  cp -p "$1" "$tmpf"
  mv -f "$tmpf" "$2"
}

unsafe() {
  warn "skip $(printf '%q' "$1") — unsafe path (outside the shipped dirs, unusual characters, or through a symlink); not touched"
  N_UNSAFE=$((N_UNSAFE + 1))
  printf '%s\n' "$1" >> "$WORK/unsafe.lst"
}

# A shipped top-level dir that is itself a symlink (stow-style dotfiles) would
# turn every file in it into an unsafe-path skip. Refuse it once, up front.
refuse_linked_dirs() {
  local root="$1" d
  shift
  for d in "$@"; do
    if [[ -L "$root/$d" ]]; then
      echo "Error: $root/$d is a symlink. AgenticOS never writes or deletes through a symlink, so it cannot manage that directory." >&2
      echo "  Replace it with a real directory (copy the link target's contents into it), then re-run. Nothing was changed." >&2
      exit 1
    fi
  done
}

# Prove an existing settings file will merge before anything is copied (dry
# run included), without trusting the library to honour a dry-run flag: run
# the real merge against a scratch copy.
preflight_hook_settings() {
  local kind="$1" dir="$2" name="$3" scratch
  if [[ -L "$dir/$name" ]]; then
    echo "Error: $dir/$name is a symlink — AgenticOS will not rewrite it. Merge the hooks by hand, or replace it with a regular file. Nothing was changed." >&2
    exit 1
  fi
  [[ -f "$dir/$name" ]] || return 0
  # $TMPDIR only if it passes the library's destination charset, else /tmp;
  # unique via mktemp, cleaned up by the EXIT trap.
  local base="${TMPDIR:-/tmp}"
  [[ "$base" =~ ^[/.a-zA-Z0-9._-]+$ ]] || base=/tmp
  scratch="$(mktemp -d "${base%/}/agentic-os-preflight.XXXXXX")"
  PREFLIGHT_DIRS="$PREFLIGHT_DIRS $scratch"
  cp "$dir/$name" "$scratch/$name"
  local ok=true
  # Subshell: a library `exit` must fail this check, not kill the installer
  # silently.
  if [[ "$kind" == "claude" ]]; then
    (merge_claude_hook_settings "$REPO_ROOT" "$scratch" "$RETIRED_HOOKS") >/dev/null 2>"$scratch/err" || ok=false
  else
    (merge_codex_hook_settings "$REPO_ROOT" "$scratch") >/dev/null 2>"$scratch/err" || ok=false
  fi
  if [[ "$ok" != "true" ]]; then
    sed 's/^/  /' "$scratch/err" >&2
    echo "Error: $dir/$name cannot be merged (it must be valid JSON with an object \"hooks\") — fix it first. Nothing was changed." >&2
    exit 1
  fi
}

# Every shipped hook must be on disk as a regular file at the release SHA
# before it is registered; otherwise settings.json would run whatever is
# there. A dry run fails on hooks it would have had to skip. Exits non-zero
# (registering nothing, writing no manifest) on any miss.
verify_hooks() {
  local stage="$1" root="$2" rel bad=0
  while IFS= read -r rel; do
    if [[ "$DRY_RUN" == "true" ]]; then
      if [[ -f "$WORK/unsafe.lst" ]] && grep -qxF -- "$rel" "$WORK/unsafe.lst"; then bad=1; echo "  ✗ hook $rel would be skipped" >&2; fi
    elif [[ ! -f "$root/$rel" || -L "$root/$rel" ]] || [[ "$(sha256_of "$root/$rel")" != "$(sha256_of "$stage/$rel")" ]]; then
      bad=1
      echo "  ✗ hook $rel is not installed at the release version" >&2
    fi
  done < <(cd "$stage" && find hooks -type f | LC_ALL=C sort)
  if [[ "$bad" -ne 0 ]]; then
    echo "Error: not every AgenticOS hook could be installed at the release version. Files that could be placed were already copied; only hook registration and the manifest update were withheld (planned removals were skipped too). Fix the paths reported above, then re-run to finish." >&2
    exit 1
  fi
  # Executable bit on the verified shipped hooks only (never on a user's own
  # files in hooks/, nor through a hard link).
  if [[ "$DRY_RUN" != "true" ]]; then
    while IFS= read -r rel; do
      if [[ "$rel" == *.sh && -n "$(find "$root/$rel" -links 1 -print)" ]]; then chmod +x "$root/$rel"; fi
    done < <(cd "$stage" && find hooks -type f | LC_ALL=C sort)
  fi
}

# ── Doctrine block (--with-doctrine) ─────────────────────────────────────────
#
# One marked block in CLAUDE.md (Claude: an @-import of the manifest-tracked
# agentic-os/doctrine.md, resolved relative to CLAUDE.md) or AGENTS.md (Codex:
# no import syntax, so the doctrine is inlined). Lines outside the block are
# never changed; the one exception is the blank separator line the installer
# adds after a new block at the top of a non-empty file, which uninstall takes
# out again. The block is written with the file's own line ending (CRLF files
# get CRLF), and markers are matched with an optional trailing CR.
#
# The manifest of DOC_MF_ROOT records whether the installer created the file
# and the sha of the block it wrote (LF-normalised, so a CRLF conversion is not
# an edit). The plan (doctrine_plan) is made before anything is written:
#   write    manage the block (add / refresh on install, remove on uninstall)
#   handsoff a sticky or uninstall run meets a target it must not rewrite
#            (symlink, hard link, not a regular file, broken or foreign
#            markers): warn, leave it alone, carry on
#   optout   no flag, a record, but no block in the target: the user removed
#            it, so stop managing it and drop the record
#   off      nothing to do
# An explicit --with-doctrine turns every handsoff case into a hard refusal.

# Unquoted on purpose: validate.sh's ship-manifest check reads every
# double-quoted token ending in .md in this file as a shipped command.
DOCTRINE_REL=agentic-os/doctrine.md
CLAUDE_MD=CLAUDE.md
AGENTS_MD=AGENTS.md
AGENTS_OVERRIDE_MD=AGENTS.override.md
DOC_BEGIN="<!-- agentic-os:doctrine:begin -->"
DOC_END="<!-- agentic-os:doctrine:end -->"
DOC_TARGET=""     # CLAUDE.md / AGENTS.md the block lives in
DOC_MF_ROOT=""    # install root whose manifest records the block
DOC_MODE=off
DOC_WHY=""        # handsoff / refusal reason
DOC_CREATED=""    # "true"/"false" once recorded for the new manifest; empty = no record
DOC_BLOCK_SHA=""
DOC_OLD_CREATED=""
DOC_OLD_SHA=""

# "<created> <sha>" from manifest $1's doctrine record, if any.
read_doctrine_record() {
  [[ -f "$1" && ! -L "$1" ]] || return 0
  LC_ALL=C sed -nE 's/^  "doctrine": \{"created": (true|false), "block_sha256": "([0-9a-f]{64})"\},$/\1 \2/p' "$1" | head -n 1
}

# Scan $1 for markers (a trailing CR is ignored). Sets DOC_NB / DOC_NE (counts),
# DOC_B / DOC_E (first line numbers, 0 = none) and DOC_CRLF (1 when the file's
# first line ends in CR).
doc_scan() {
  local out
  out="$(LC_ALL=C awk -v b="$DOC_BEGIN" -v e="$DOC_END" '
    { l = $0; cr = sub(/\r$/, "", l); if (NR == 1) crlf = cr
      if (l == b) { nb++; if (!fb) fb = NR }
      if (l == e) { ne++; if (!fe) fe = NR } }
    END { printf "%d %d %d %d %d\n", nb, ne, fb, fe, crlf }' "$1")"
  read -r DOC_NB DOC_NE DOC_B DOC_E DOC_CRLF <<< "$out"
}

# Why $1 may not be rewritten ("" when it may: absent, or one regular, singly
# linked file).
doc_unsafe_reason() {
  local f="$1"
  if [[ -L "$f" ]]; then echo "is a symlink"; return 0; fi
  [[ -e "$f" ]] || return 0
  if [[ ! -f "$f" ]]; then echo "is not a regular file"; return 0; fi
  if [[ -n "$(find "$f" -links +1 -print)" ]]; then echo "is hard-linked elsewhere"; fi
  return 0
}

# The block this release writes, LF line endings.
doctrine_block() {
  printf '%s\n' "$DOC_BEGIN"
  if [[ "$PLATFORM" == "claude" ]]; then printf '@agentic-os/doctrine.md\n'; else cat "$DOCTRINE_SRC"; fi
  printf '%s\n' "$DOC_END"
}

# LF-normalised sha of lines DOC_B..DOC_E of $1.
doc_cur_sha() {
  sed -n "${DOC_B},${DOC_E}p" "$1" | LC_ALL=C awk '{ sub(/\r$/, ""); print }' > "$WORK/doctrine.curnorm"
  sha256_of "$WORK/doctrine.curnorm"
}

# True when LF-normalised sha $1 is a block this release writes, or one an
# earlier release wrote (Codex inlines the doctrine, so each doctrine version
# is a different block; scripts/build-consumer-doctrine.sh appends every
# version's sha to DOC_KNOWN_FILE and never removes one).
doc_known_block() {
  [[ "$1" == "$DOC_BLOCK_SHA" ]] && return 0
  [[ "$PLATFORM" != "claude" && -f "$DOC_KNOWN_FILE" ]] || return 1
  grep -qxF -- "$1" "$DOC_KNOWN_FILE"
}

# Decide DOC_MODE before anything is written. Exits (nothing changed) on an
# explicit --with-doctrine whose target cannot be managed.
doctrine_plan() {
  local f="$DOC_TARGET" why="" state cur=""
  [[ "$WITH_DOCTRINE" == "true" || "$UNINSTALL" == "true" || -n "$DOC_OLD_SHA" ]] || return 0
  if [[ "$UNINSTALL" != "true" && ! -f "$DOCTRINE_SRC" ]]; then
    echo "Error: $DOCTRINE_SRC is missing from this release — cannot install the doctrine. Nothing was changed." >&2
    exit 1
  fi
  doctrine_block > "$WORK/doctrine.lf"
  DOC_BLOCK_SHA="$(sha256_of "$WORK/doctrine.lf")"
  why="$(doc_unsafe_reason "$f")"
  if [[ -n "$why" ]]; then
    state=unsafe
  elif [[ ! -e "$f" ]]; then
    state=absent
  else
    doc_scan "$f"
    if [[ "$DOC_NB" != "$DOC_NE" || "$DOC_NB" -gt 1 ]] || [[ "$DOC_NB" == 1 && "$DOC_B" -ge "$DOC_E" ]]; then
      state=malformed; why="has malformed AgenticOS doctrine markers ($DOC_NB begin, $DOC_NE end)"
    elif [[ "$DOC_NB" == 0 ]]; then
      state=none
    else
      state=block
      cur="$(doc_cur_sha "$f")"
      # Ours only if it is a block this or an earlier release writes. A
      # manifest record is no proof: in project scope the repository ships it.
      if ! doc_known_block "$cur"; then
        state=foreign
        why="holds an AgenticOS doctrine block that matches no block AgenticOS has shipped (edited by hand, or not written by AgenticOS)"
      fi
    fi
  fi

  if [[ "$WITH_DOCTRINE" == "true" ]]; then
    case "$state" in
      unsafe)
        echo "Error: $f $why — AgenticOS will not rewrite it. Replace it with a regular file, or install without --with-doctrine. Nothing was changed." >&2
        exit 1 ;;
      malformed)
        echo "Error: $f $why. Fix or remove the $DOC_BEGIN ... $DOC_END lines by hand. Nothing was changed." >&2
        exit 1 ;;
      foreign)
        # The user asked for the doctrine: an edited block of an install they
        # recorded is refreshed (after a .bak); markers with no record are not.
        # In --codex --project the manifest is repository content, so its
        # record authorises nothing.
        if [[ -z "$DOC_OLD_SHA" || "$DOC_PROJECT" == true ]]; then
          echo "Error: $f has AgenticOS doctrine markers around text AgenticOS did not write (e.g. an example in a code fence), and no install record. Fix or remove the $DOC_BEGIN ... $DOC_END lines by hand. Nothing was changed." >&2
          exit 1
        fi ;;
    esac
    DOC_MODE=write
  elif [[ "$UNINSTALL" == "true" ]]; then
    case "$state" in
      # Unsafe with no record: nothing says AgenticOS ever wrote there, so a
      # user who never used the flag sees no doctrine output at all (off).
      unsafe) if [[ -n "$DOC_OLD_SHA" ]]; then DOC_MODE=handsoff; DOC_WHY="$why"; fi ;;
      malformed|foreign) DOC_MODE=handsoff; DOC_WHY="$why" ;;
      # A shipped block with no install record may be the user quoting it
      # (e.g. in a code fence): only a record makes it ours to remove.
      block)
        if [[ -n "$DOC_OLD_SHA" ]]; then DOC_MODE=write
        else DOC_MODE=handsoff; DOC_WHY="holds an AgenticOS doctrine block, but no install record says AgenticOS put it there (it may be quoted text)"; fi ;;
    esac
  else
    case "$state" in
      unsafe|malformed|foreign) DOC_MODE=handsoff; DOC_WHY="$why" ;;
      block) DOC_MODE=write ;;
      none|absent) DOC_MODE=optout ;;
    esac
  fi
  return 0
}

# Fail closed if the target turned into a link or another file since the plan.
doc_recheck() {
  local why
  why="$(doc_unsafe_reason "$1")"
  if [[ -n "$why" ]]; then
    echo "Error: $1 $why (it changed during the install) — not written. Re-run to finish." >&2
    exit 1
  fi
}

# Replace $2 with the bytes of $1 via a temp file beside it, keeping $2's mode
# (a new file gets 0644).
doc_write() {
  local new="$1" f="$2" dir tmpf
  dir="$(dirname "$f")"
  mkdir -p "$dir"
  doc_recheck "$f"
  tmpf="$(mktemp "$dir/.agentic-os.XXXXXX")"
  if [[ -f "$f" ]]; then cp -p "$f" "$tmpf"; else chmod 644 "$tmpf"; fi
  cat "$new" > "$tmpf"
  doc_recheck "$f"
  mv -f "$tmpf" "$f"
}

# Copy $1 to a fresh <file>.bak.<stamp>[.<n>] and print the backup's name.
doc_backup() {
  local bak="$1.bak.$STAMP" n=1
  while [[ -e "$bak" || -L "$bak" ]]; do bak="$1.bak.$STAMP.$n"; n=$((n + 1)); done
  [[ "$DRY_RUN" == "true" ]] || cp -p "$1" "$bak"
  printf '%s' "$bak"
}

# The block in the line ending of the file it goes into.
doc_block_eol() {
  if [[ "${DOC_CRLF:-0}" == 1 ]]; then LC_ALL=C awk '{ printf "%s\r\n", $0 }' "$WORK/doctrine.lf"; else cat "$WORK/doctrine.lf"; fi
}

doc_handsoff_warning() {
  warn "$DOC_TARGET $DOC_WHY — AgenticOS leaves it untouched. If it holds the AgenticOS doctrine block, delete the lines from '$DOC_BEGIN' to '$DOC_END' by hand."
}

# Install: act on DOC_MODE; sets DOC_CREATED / DOC_BLOCK_SHA for the manifest.
doctrine_apply() {
  local f="$DOC_TARGET" blk="$WORK/doctrine.block" new="$WORK/doctrine.new" cur bak
  case "$DOC_MODE" in
    handsoff)
      doc_handsoff_warning
      # Keep the record (and, for Claude, the doctrine file an existing import
      # may still point at) until the user removes the block or uninstalls.
      DOC_CREATED="${DOC_OLD_CREATED:-false}"; DOC_BLOCK_SHA="$DOC_OLD_SHA"
      return 0 ;;
    optout)
      note "no AgenticOS doctrine block in $f — treating that as an opt-out: the doctrine is no longer installed or kept current. Re-run with --with-doctrine to add it back."
      return 0 ;;
    write) ;;
    *) return 0 ;;
  esac
  if [[ ! -e "$f" ]]; then
    DOC_CREATED=true; DOC_CRLF=0
    note "create $f with the AgenticOS doctrine block"
    [[ "$DRY_RUN" == "true" ]] || doc_write "$WORK/doctrine.lf" "$f"
    return 0
  fi
  doc_scan "$f"
  doc_block_eol > "$blk"
  # The file existed: "created" survives only for a block this install put in
  # a file it created (a re-add into the user's own file is not a creation).
  DOC_CREATED=false
  if [[ "$DOC_B" != 0 && "$DOC_OLD_CREATED" == "true" ]]; then DOC_CREATED=true; fi
  if [[ "$DOC_B" == 0 ]]; then
    {
      cat "$blk"
      if [[ -s "$f" ]]; then
        if [[ "$DOC_CRLF" == 1 ]]; then printf '\r\n'; else printf '\n'; fi
        cat "$f"
      fi
    } > "$new"
    note "add the AgenticOS doctrine block to the top of $f"
  else
    sed -n "${DOC_B},${DOC_E}p" "$f" > "$WORK/doctrine.cur"
    if cmp -s "$WORK/doctrine.cur" "$blk"; then
      return 0
    fi
    cur="$(doc_cur_sha "$f")"
    # (BSD head rejects -n 0.)
    { if [[ "$DOC_B" -gt 1 ]]; then head -n "$((DOC_B - 1))" "$f"; fi; cat "$blk"; tail -n "+$((DOC_E + 1))" "$f"; } > "$new"
    if doc_known_block "$cur"; then
      note "update the AgenticOS doctrine block in $f"
    else
      bak="$(doc_backup "$f")"
      warn "refresh the doctrine block in $f — it differed from what AgenticOS wrote; the whole file is saved as $bak"
    fi
  fi
  [[ "$DRY_RUN" == "true" ]] || doc_write "$new" "$f"
}

# Uninstall: remove the block. Deletes the file only when the installer
# created it and nothing else is left in it.
doctrine_remove() {
  local f="$DOC_TARGET" rest="$WORK/doctrine.rest" new="$WORK/doctrine.new"
  case "$DOC_MODE" in
    handsoff) doc_handsoff_warning; return 0 ;;
    write) ;;
    *) return 0 ;;
  esac
  # Re-check right before writing: the block may have been edited since
  # doctrine_plan (hooks were unregistered in between).
  doc_scan "$f"
  if [[ "$DOC_NB" != 1 || "$DOC_NE" != 1 || "$DOC_B" -ge "$DOC_E" ]] || ! doc_known_block "$(doc_cur_sha "$f")"; then
    DOC_WHY="changed during the uninstall and no longer holds a block AgenticOS shipped"
    doc_handsoff_warning
    return 0
  fi
  tail -n "+$((DOC_E + 1))" "$f" > "$rest"
  if [[ "$DOC_B" == 1 && "$DOC_OLD_CREATED" != "true" ]]; then
    # Drop the one blank separator line the installer put after the block (a
    # file the installer created never got one).
    if [[ "$(head -c 2 "$rest" | od -An -tx1 | tr -d ' \n')" == 0d0a ]]; then tail -c +3 "$rest" > "$new"
    elif [[ "$(head -c 1 "$rest" | wc -l | tr -d ' ')" == 1 ]]; then tail -c +2 "$rest" > "$new"
    else cp "$rest" "$new"; fi
  elif [[ "$DOC_B" == 1 ]]; then
    cp "$rest" "$new"
  else
    { head -n "$((DOC_B - 1))" "$f"; cat "$rest"; } > "$new"
  fi
  if [[ ! -s "$new" && "$DOC_OLD_CREATED" == "true" ]]; then
    note "remove $f (created by AgenticOS, now empty)"
    if [[ "$DRY_RUN" != "true" ]]; then doc_recheck "$f"; rm -f "$f"; fi
  else
    note "remove the AgenticOS doctrine block from $f"
    [[ "$DRY_RUN" == "true" ]] || doc_write "$new" "$f"
  fi
}

# ── Sync one install root against its staged release tree ───────────────────
#
# Phase 1 (sync_place) adds/updates files and plans removals; phase 2
# (sync_finish) removes, prunes empty dirs and writes the manifest. Hook
# registration is merged between the two, so settings.json never points at a
# hook file that is not on disk, even if the merge fails.
#
#   $1 id (work-dir name)  $2 stage dir  $3 install root
#   $4 hook prefix ("hooks/" or "")  $5 skills prefix ("skills/", or "" when the
#   root IS the skills dir, "-" when it holds no skills)  $6 platform  $7 label
#   $8 shipped first-component allowlist (see safe_rel)
sync_place() {
  local id="$1" stage="$2" root="$3" hookp="$4" skillp="$5" allow="$8"
  local w="$WORK/$id" rel nsha osha csha bak n
  local added=0 updated=0 same=0 legacy_kept=0
  mkdir -p "$w"
  set_root "$root"

  if [[ -n "$(LC_ALL=C find "$stage" -name '*[!A-Za-z0-9._@+-]*' -print)" ]]; then
    echo "Error: release contains a path outside [A-Za-z0-9._@+-] — refusing to install:" >&2
    LC_ALL=C find "$stage" -name '*[!A-Za-z0-9._@+-]*' -print >&2
    exit 1
  fi

  (cd "$stage" && find . -type f -print0) > "$w/new.lst"
  hash_into "$stage" "$w/new.lst" "$w/new.tsv"
  if [[ -L "$root/$MANIFEST_NAME" ]]; then
    echo "Error: $root/$MANIFEST_NAME is a symlink — refusing to use it. Remove it and re-run." >&2
    exit 1
  fi
  read_manifest "$root/$MANIFEST_NAME" > "$w/old.tsv"
  cut -f1 "$w/old.tsv" > "$w/old.paths"
  load_known "$skillp" "$w/known.tsv"
  cut -f1 "$w/new.tsv" "$w/old.tsv" | LC_ALL=C sort -u | while IFS= read -r rel; do
    if [[ -f "$root/$rel" ]] && safe_rel "$root" "$rel" "$allow"; then printf '%s\0' "$rel"; fi
  done > "$w/cur.lst"
  hash_into "$root" "$w/cur.lst" "$w/cur.tsv"

  LC_ALL=C awk -F'\t' -v OFS='\t' '
    FILENAME == ARGV[1] { n[$1] = $2; k[$1] = 1; next }
    FILENAME == ARGV[2] { o[$1] = $2; k[$1] = 1; next }
    { c[$1] = $2 }
    END { for (p in k) print p, (p in n ? n[p] : "-"), (p in o ? o[p] : "-"), (p in c ? c[p] : "-") }
  ' "$w/new.tsv" "$w/old.tsv" "$w/cur.tsv" | LC_ALL=C sort > "$w/plan.tsv"

  : > "$w/manifest.tsv"
  : > "$w/remove.lst"
  while IFS=$'\t' read -r rel nsha osha csha; do
    if ! safe_rel "$root" "$rel" "$allow"; then
      unsafe "$rel"
      continue
    fi
    if [[ "$nsha" == "-" ]]; then
      # Tracked by the old manifest, dropped by this release.
      if [[ -n "$hookp" && "$rel" =~ ^hooks/[A-Za-z0-9._-]+\.sh$ ]]; then
        # Unregister it from settings.json even if RETIRED_HOOKS forgot it.
        printf '%s\n' "${rel##*/}" >> "$WORK/retired.derived"
      fi
      if [[ "$csha" == "-" ]]; then
        :
      elif [[ -n "$hookp" && "$rel" == "$hookp"* ]] && ! command -v jq &>/dev/null; then
        # Without jq the merge cannot unregister it; never delete a hook that
        # may still be registered. Stays tracked so a later run prunes it.
        printf '%s\t%s\n' "$rel" "$osha" >> "$w/manifest.tsv"
        warn "keep retired hook $rel — jq is required to unregister it first"
      elif unmodified "$w/known.tsv" "$rel" "$csha" "$osha"; then
        printf '%s\0%s\0' "$rel" "no longer shipped" >> "$w/remove.lst"
      else
        # Stays tracked, so uninstall and --prune-legacy still see it as modified.
        printf '%s\t%s\n' "$rel" "$osha" >> "$w/manifest.tsv"
        kept "keep $rel — no longer shipped, but modified locally"
      fi
      continue
    fi
    printf '%s\t%s\n' "$rel" "$nsha" >> "$w/manifest.tsv"
    if [[ "$csha" == "-" ]]; then
      place "$stage/$rel" "$root/$rel"
      added=$((added + 1))
    elif [[ "$csha" == "$nsha" ]]; then
      same=$((same + 1))
    elif unmodified "$w/known.tsv" "$rel" "$csha" "$osha"; then
      # The manifest's copy, or (pre-manifest install) an earlier release's.
      place "$stage/$rel" "$root/$rel"
      note "update $rel"
      updated=$((updated + 1))
    elif [[ -n "$hookp" && "$rel" == "$hookp"* ]]; then
      # Shipped hooks are security-relevant: always take the release copy.
      bak="$rel.bak.$STAMP"
      n=1
      while [[ -e "$root/$bak" || -L "$root/$bak" ]]; do bak="$rel.bak.$STAMP.$n"; n=$((n + 1)); done
      if [[ -n "$(find "$root/$rel" -links +1 -print)" ]]; then
        # place() swaps in a new inode, so the other links keep their content.
        warn "hook $rel was hard-linked elsewhere; the link is replaced, the other copies are not changed"
      fi
      [[ "$DRY_RUN" == "true" ]] || cp -p "$root/$rel" "$root/$bak"
      place "$stage/$rel" "$root/$rel"
      warn "refresh hook $rel — it differed from the release copy; yours is saved as $bak"
      updated=$((updated + 1))
    elif [[ "$FORCE" == "true" ]]; then
      place "$stage/$rel" "$root/$rel"
      note "overwrite $rel (--force)"
      updated=$((updated + 1))
    elif [[ "$osha" == "-" ]]; then
      kept "keep $rel — differs from the release copy and predates the manifest (--force overwrites)"
      legacy_kept=$((legacy_kept + 1))
    else
      kept "keep $rel — modified locally (--force overwrites)"
    fi
  done < "$w/plan.tsv"

  # Retired skills from pre-manifest installs: files the old manifest does not
  # track are removed only with --prune-legacy, listed one by one first. Every
  # name is validated before use; anything odd is reported and left alone.
  local t d f frel names="$TOMBSTONES"
  [[ "$skillp" == "-" ]] && names=""   # "-": this root holds no skills
  for t in $names; do
    d="$skillp$t"
    [[ ! -e "$stage/$d" ]] || continue
    if [[ -L "$root/$d" ]]; then
      warn "skip retired skill $d — it is a symlink; not touched"
      continue
    fi
    [[ -d "$root/$d" ]] || continue
    : > "$w/legacy.lst"
    while IFS= read -r -d '' f; do
      frel="${f#"$root"/}"
      if [[ "$frel" != "$d"/* ]] || ! safe_rel "$root" "$frel" "$allow"; then
        unsafe "$frel"
        continue
      fi
      if ! grep -qxF -- "$frel" "$w/old.paths"; then printf '%s\0' "$frel" >> "$w/legacy.lst"; fi
    done < <(find "$root/$d" ! -type d -print0)
    [[ -s "$w/legacy.lst" ]] || continue
    # Only a byte-exact copy of an earlier AgenticOS release of that path is
    # ours to delete; notes the user added, edits, or another tool's files of
    # the same name stay (and so does the dir).
    local prunable=0 foreign=0
    while IFS= read -r -d '' frel; do
      if unmodified "$w/known.tsv" "$frel" "$(sha256_of "$root/$frel")" "-"; then
        prunable=$((prunable + 1))
        if [[ "$PRUNE_LEGACY" == "true" ]]; then
          printf '%s\0%s\0' "$frel" "retired skill $t (--prune-legacy)" >> "$w/remove.lst"
        fi
      else
        foreign=$((foreign + 1))
        if [[ "$PRUNE_LEGACY" == "true" ]]; then
          warn "keep $frel — not an AgenticOS release file (retired skill $t); it is yours to keep or remove"
          N_FOREIGN=$((N_FOREIGN + 1))
        fi
      fi
    done < "$w/legacy.lst"
    if [[ "$PRUNE_LEGACY" != "true" ]]; then
      if [[ "$prunable" -gt 0 ]]; then
        warn "retired skill directory $d still holds $prunable AgenticOS file(s) from an earlier release — re-run with --prune-legacy to remove them"
      elif [[ "$foreign" -gt 0 ]]; then
        note "retired skill directory $d holds only files that are not AgenticOS release files; they are yours to keep or remove"
      fi
    fi
  done

  printf '%s\n' "$added" "$updated" "$same" "$legacy_kept" > "$w/counts"
}

sync_finish() {
  local id="$1" root="$3" platform="$6" label="$7" allow="$8"
  local w="$WORK/$id" rel why added updated same legacy_kept
  set_root "$root"
  : > "$w/dirs.lst"
  while IFS= read -r -d '' rel && IFS= read -r -d '' why; do
    # Re-checked at the point of deletion: the tree may have changed since
    # the plan was made (e.g. the hook merge ran in between).
    if ! safe_rel "$root" "$rel" "$allow"; then
      unsafe "$rel"
      continue
    fi
    note "remove $rel ($why)"
    [[ "$DRY_RUN" == "true" ]] || rm -f "$root/$rel"
    dirname "$rel" >> "$w/dirs.lst"
  done < "$w/remove.lst"
  prune_empty_dirs "$root" "$w/dirs.lst"

  { read -r added; read -r updated; read -r same; read -r legacy_kept; } < "$w/counts"
  if [[ "$DRY_RUN" != "true" ]]; then
    write_manifest "$root" "$w/manifest.tsv" "$platform"
  fi
  echo "  ✓ $P$label → $root ($added added, $updated updated, $same unchanged)"
  if [[ "$legacy_kept" -gt 0 ]]; then
    echo "    $legacy_kept file(s) predate the manifest and differ from this release; kept. Re-run with --force to take the release copies."
  fi
}

# Remove now-empty directories from each listed dir up to (never including)
# root. Inputs are dirnames of safe_rel-checked paths; rmdir never follows a
# symlink and only removes empty directories.
prune_empty_dirs() {
  local root="$1" list="$2" d
  [[ "$DRY_RUN" == "true" ]] && return 0
  LC_ALL=C sort -ru "$list" | while IFS= read -r d; do
    while [[ -n "$d" && "$d" != "." && "$d" != "/" ]]; do
      [[ -L "$root/$d" ]] && break
      rmdir "$root/$d" 2>/dev/null || break
      d="$(dirname "$d")"
    done
  done
}

# Basenames of the hook scripts a manifest tracks (all AgenticOS-owned), so
# uninstall unregisters them even if a later release forgot RETIRED_HOOKS.
manifest_hook_names() {
  read_manifest "$1" | cut -f1 | sed -n 's#^hooks/\([A-Za-z0-9._-]*\.sh\)$#\1#p' | tr '\n' ' '
}

# Remove every unmodified manifest file under $2; keep (and name) modified ones.
#   $1 id  $2 root  $3 label  $4 shipped first-component allowlist
#   $5 skills prefix (as for sync_place: "skills/", "", or "-")
uninstall_root() {
  local id="$1" root="$2" label="$3" allow="$4" skillp="$5"
  local w="$WORK/$id" mf="$2/$MANIFEST_NAME" rel osha csha removed=0 kept=0
  mkdir -p "$w"
  set_root "$root"
  echo ""
  echo "$label: $root"
  if [[ ! -f "$mf" ]]; then
    echo "  · no $MANIFEST_NAME — nothing tracked to remove (a pre-manifest install: run the installer once to adopt it, then uninstall)"
    return 0
  fi
  read_manifest "$mf" > "$w/old.tsv"
  load_known "$skillp" "$w/known.tsv"
  cut -f1 "$w/old.tsv" | while IFS= read -r rel; do
    if [[ -f "$root/$rel" ]] && safe_rel "$root" "$rel" "$allow"; then printf '%s\0' "$rel"; fi
  done > "$w/cur.lst"
  hash_into "$root" "$w/cur.lst" "$w/cur.tsv"
  LC_ALL=C awk -F'\t' -v OFS='\t' '
    FILENAME == ARGV[1] { o[$1] = $2; next }
    { c[$1] = $2 }
    END { for (p in o) print p, o[p], (p in c ? c[p] : "-") }
  ' "$w/old.tsv" "$w/cur.tsv" | LC_ALL=C sort > "$w/plan.tsv"

  : > "$w/dirs.lst"
  while IFS=$'\t' read -r rel osha csha; do
    if ! safe_rel "$root" "$rel" "$allow"; then
      unsafe "$rel"
    elif [[ "$csha" == "-" ]]; then
      continue
    elif [[ "$id" == claude && "$DOC_MODE" == handsoff && "$rel" == "$DOCTRINE_REL" ]]; then
      # The CLAUDE.md block left in place may still import it.
      warn "keep $rel — the CLAUDE.md block AgenticOS could not remove may still import it; delete it after removing that block"
    elif unmodified "$w/known.tsv" "$rel" "$csha" "$osha"; then
      note "remove $rel"
      [[ "$DRY_RUN" == "true" ]] || rm -f "$root/$rel"
      dirname "$rel" >> "$w/dirs.lst"
      removed=$((removed + 1))
    else
      kept "keep $rel — modified locally"
      kept=$((kept + 1))
    fi
  done < "$w/plan.tsv"
  prune_empty_dirs "$root" "$w/dirs.lst"
  note "remove $MANIFEST_NAME"
  [[ "$DRY_RUN" == "true" ]] || rm -f "$mf"
  echo "  $P$removed removed, $kept kept (modified)"
}

# ── Stage the release ─────────────────────────────────────────────────────────

STAGE="$WORK/stage"
mkdir -p "$STAGE"

install_dir() {
  local name="$1"
  [[ -d "$SRC/$name" ]] || return 0
  mkdir -p "$STAGE/$name"
  cp -R "$SRC/$name/." "$STAGE/$name/"
}

# Ship-tagged allowlist: stage ONLY the named files from $SRC/$name, never the
# whole directory. Used for surfaces (commands) where some files are
# maintainer-only and must not pollute a consumer's global namespace.
install_files() {
  local name="$1"; shift
  local rel
  for rel in "$@"; do
    [[ -f "$SRC/$name/$rel" ]] || continue
    mkdir -p "$STAGE/$name"
    cp "$SRC/$name/$rel" "$STAGE/$name/$rel"
  done
}

install_codex_agents() {
  local src_dir="$SRC/agents" dest_dir="$1"
  local src name description tools sandbox target
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
    sandbox="read-only"
    if [[ "$tools" == *Edit* || "$tools" == *Write* ]]; then
      sandbox="workspace-write"
    fi
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
    } > "$target"; then
      echo "Error: failed to convert Codex agent $src." >&2
      exit 1
    fi
  done < <(find "$src_dir" -maxdepth 1 -name '*.md' -type f -print0)
}

# ── Uninstall ─────────────────────────────────────────────────────────────────

# First path components each root ships (safe_rel's allowlist). Nothing
# outside these is ever written or removed.
CLAUDE_ALLOW="skills agents commands hooks agentic-os"
# Skill names a skills path may name (safe_rel): shipped now, tombstoned, or
# shipped by any earlier release.
SKILL_NAMES="$TOMBSTONES $(find "$SRC/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | tr '\n' ' ')"
if [[ -f "$RELEASE_HASHES" ]]; then
  SKILL_NAMES="$SKILL_NAMES $(sed -n 's#^[0-9a-f]\{64\}  skills/\([A-Za-z0-9._@+-]*\)/.*#\1#p' "$RELEASE_HASHES" | sort -u | tr '\n' ' ')"
fi
CODEX_CONFIG_ALLOW="agents hooks"
: > "$WORK/retired.derived"

# Doctrine target. Opt-in with --with-doctrine; afterwards a run without the
# flag keeps the block current only while the target still holds it (see
# doctrine_plan).
DOCTRINE_SRC="$REPO_ROOT/assets/consumer/${DOCTRINE_REL#*/}"
DOC_KNOWN_FILE="$REPO_ROOT/assets/consumer/doctrine-block-shas.txt"
if [[ "$PLATFORM" == "claude" ]]; then
  DOC_TARGET="${DEST%/}/$CLAUDE_MD"; DOC_MF_ROOT="$DEST"
elif [[ "$CODEX_SCOPE" == "project" ]]; then
  DOC_TARGET="$CODEX_PROJECT_ROOT/$AGENTS_MD"; DOC_MF_ROOT="$CODEX_CONFIG_DIR"
else
  DOC_TARGET="$CODEX_CONFIG_DIR/$AGENTS_MD"; DOC_MF_ROOT="$CODEX_CONFIG_DIR"
fi
doc_rec="$(read_doctrine_record "$DOC_MF_ROOT/$MANIFEST_NAME")"
if [[ -n "$doc_rec" ]]; then DOC_OLD_CREATED="${doc_rec%% *}"; DOC_OLD_SHA="${doc_rec#* }"; fi
# Project scope: the repository can commit the manifest, so "created" is never
# trusted there (uninstall strips the block and leaves AGENTS.md).
DOC_PROJECT=false
if [[ "$PLATFORM" == "codex" && "$CODEX_SCOPE" == "project" ]]; then DOC_PROJECT=true; DOC_OLD_CREATED=false; fi
doctrine_plan
# Stage (Claude) and record the doctrine while it is managed or left hands-off.
DOCTRINE=false
case "$DOC_MODE" in write|handsoff) DOCTRINE=true ;; esac

if [[ "$UNINSTALL" == "true" ]]; then
  echo ""
  echo "${P}Uninstalling AgenticOS ($PLATFORM)"
  # Unregister hooks BEFORE deleting files: if the settings rewrite fails, the
  # hook scripts it still points at are left in place.
  if [[ "$PLATFORM" == "claude" ]]; then
    refuse_linked_dirs "$DEST" skills agents commands hooks
    echo ""
    echo "Hook registration: ${DEST%/}/settings.json"
    unregister_claude_hook_settings "$REPO_ROOT" "$DEST" \
      "$RETIRED_HOOKS $(manifest_hook_names "$DEST/$MANIFEST_NAME")" "$DRY_RUN"
    # The block goes before the doctrine file it imports.
    if [[ "$DOC_MODE" != off ]]; then echo ""; echo "Doctrine: $DOC_TARGET"; doctrine_remove; fi
    uninstall_root claude "$DEST" "Claude Code" "$CLAUDE_ALLOW" "skills/"
  else
    refuse_linked_dirs "$CODEX_CONFIG_DIR" agents hooks
    echo ""
    echo "Hook registration: $CODEX_CONFIG_DIR/hooks.json"
    unregister_codex_hook_settings "$CODEX_CONFIG_DIR" "$DRY_RUN"
    if [[ "$DOC_MODE" != off ]]; then echo ""; echo "Doctrine: $DOC_TARGET"; doctrine_remove; fi
    uninstall_root codex-skills "$CODEX_SKILLS_DEST" "Codex skills" "*" ""
    uninstall_root codex-config "$CODEX_CONFIG_DIR" "Codex agents + hooks" "$CODEX_CONFIG_ALLOW" "-"
  fi
  echo ""
  echo "${P}Uninstall complete: $N_KEPT modified file(s) kept, $N_UNSAFE unsafe path(s) skipped. Hook backups (*.bak.*) and files you created were not touched."
  exit 0
fi

# ── Install / update ──────────────────────────────────────────────────────────

if [[ "$PLATFORM" == "claude" ]]; then
  echo ""
  echo "${P}Installing Claude Code surfaces to $DEST"

  install_dir "skills"
  install_dir "agents"
  # Commands: ship-tagged allowlist ONLY — list each file that installs into a
  # consumer's global namespace. The author-facing scaffolds plus /state (the
  # awareness-harness writer command — its skill + hooks ship alongside) are the
  # only consumer commands; maintainer-only commands stay in-repo.
  install_files "commands" "skill-new.md" "agent-new.md" "state.md"
  # Workflows: NOTHING ships. The only workflow is maintainer-only.
  install_dir "hooks"
  CLAUDE_LABEL="skills, agents, commands, hooks"
  if [[ "$DOCTRINE" == "true" ]]; then
    mkdir -p "$STAGE/agentic-os"
    cp "$DOCTRINE_SRC" "$STAGE/$DOCTRINE_REL"
    CLAUDE_LABEL="$CLAUDE_LABEL, doctrine"
  fi

  # Fail fast, before anything is copied (dry run included).
  refuse_linked_dirs "$DEST" skills agents commands hooks
  [[ "$DOCTRINE" != "true" ]] || refuse_linked_dirs "$DEST" agentic-os
  preflight_hook_settings claude "$DEST" settings.json
  CLAUDE_ARGS=(claude "$STAGE" "$DEST" "hooks/" "skills/" claude "$CLAUDE_LABEL" "$CLAUDE_ALLOW")
  sync_place "${CLAUDE_ARGS[@]}"
  verify_hooks "$STAGE" "$DEST"
  if [[ "$DOC_MODE" == write && "$DRY_RUN" != "true" ]] && [[ ! -f "$DEST/$DOCTRINE_REL" || -L "$DEST/$DOCTRINE_REL" ]]; then
    echo "Error: $DEST/agentic-os/doctrine.md could not be installed, so CLAUDE.md was not given an import of it; hook registration and the manifest update were withheld. Fix the path reported above, then re-run." >&2
    exit 1
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    note "merge AgenticOS hook registration into ${DEST%/}/settings.json"
  else
    merge_claude_hook_settings "$REPO_ROOT" "$DEST" "$RETIRED_HOOKS $(tr '\n' ' ' < "$WORK/retired.derived")"
  fi
  doctrine_apply
  sync_finish "${CLAUDE_ARGS[@]}"

  echo ""
  echo "${P}Done. Restart Claude Code to load the new skills, agents, commands, and hooks."
  if [[ "$DOC_MODE" == write ]]; then
    echo "${P}The AgenticOS doctrine is imported from ${DOC_TARGET}; it is kept current while the block is there, until --uninstall."
  fi
else
  echo ""
  echo "${P}Installing Codex skills to $CODEX_SKILLS_DEST"
  echo "${P}Installing Codex config surfaces to $CODEX_CONFIG_DIR"

  mkdir -p "$STAGE/skills" "$STAGE/config/hooks"
  cp -R "$SRC/skills/." "$STAGE/skills/"
  install_codex_agents "$STAGE/config/agents"
  for hook in session-state-inject.sh session-state-checkpoint.sh; do
    cp "$SRC/hooks/$hook" "$STAGE/config/hooks/$hook"
  done

  refuse_linked_dirs "$CODEX_CONFIG_DIR" agents hooks
  preflight_hook_settings codex "$CODEX_CONFIG_DIR" hooks.json
  SKILLS_ARGS=(codex-skills "$STAGE/skills" "$CODEX_SKILLS_DEST" "" "" codex "skills" "*")
  CONFIG_ARGS=(codex-config "$STAGE/config" "$CODEX_CONFIG_DIR" "hooks/" "-" codex "agents (Codex TOML) + hooks" "$CODEX_CONFIG_ALLOW")
  sync_place "${SKILLS_ARGS[@]}"
  sync_place "${CONFIG_ARGS[@]}"
  verify_hooks "$STAGE/config" "$CODEX_CONFIG_DIR"
  if [[ "$DRY_RUN" == "true" ]]; then
    note "merge AgenticOS hook registration into $CODEX_CONFIG_DIR/hooks.json"
  else
    merge_codex_hook_settings "$REPO_ROOT" "$CODEX_CONFIG_DIR"
  fi
  doctrine_apply
  if [[ "$DOC_MODE" == write ]]; then
    if [[ -e "$(dirname "$DOC_TARGET")/$AGENTS_OVERRIDE_MD" ]]; then
      warn "$(dirname "$DOC_TARGET")/AGENTS.override.md exists; Codex reads it instead of AGENTS.md there, so the doctrine block will not load"
    fi
  fi
  sync_finish "${SKILLS_ARGS[@]}"
  sync_finish "${CONFIG_ARGS[@]}"

  echo ""
  if [[ "$DRY_RUN" == "true" || "${CODEX_HOOKS_REGISTERED:-false}" == "true" ]]; then
    echo "${P}Done. Restart Codex to load the skills and agents. Review and trust the new hooks with /hooks."
  else
    echo "Done. Restart Codex to load the skills and agents. Hooks were NOT registered: jq is needed to merge them into the existing $CODEX_CONFIG_DIR/hooks.json. Install jq and re-run."
  fi
  echo "Claude slash commands and custom .claude/memory hooks were not installed; Codex uses skills/custom agents and its native memory system instead."
fi

echo ""
if [[ "$N_KEPT" -gt 0 ]]; then
  echo "$N_KEPT file(s) you modified were kept; --force overwrites them."
fi
if [[ "$N_FOREIGN" -gt 0 ]]; then
  echo "$N_FOREIGN file(s) in retired skill directories are not AgenticOS release files and were left alone; they are yours to keep or remove."
fi
if [[ "$N_UNSAFE" -gt 0 ]]; then
  echo "$N_UNSAFE path(s) were skipped as unsafe and left untouched (see the 'skip' lines above)."
fi
echo "To update later, re-run this script. To remove AgenticOS, re-run it with --uninstall."
