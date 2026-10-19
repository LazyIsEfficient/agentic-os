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

FORCE=false
DRY_RUN=false
PRUNE_LEGACY=false
UNINSTALL=false
PLATFORM="claude"
CODEX_SCOPE="user"

usage() {
  printf '%s\n' \
    'Usage: ./install.sh [--claude|--codex] [--project] [--force] [--prune-legacy] [--dry-run]' \
    '       ./install.sh [--claude|--codex] [--project] --uninstall [--dry-run]' \
    '' \
    '  --codex         Install Codex-compatible skills, agents, and hooks' \
    '  --project       With --codex, install into the current Git project' \
    '  --force         Also overwrite AgenticOS files you modified locally' \
    '  --prune-legacy  Remove retired skill directories left by pre-manifest installs' \
    '  --uninstall     Remove AgenticOS-owned files and hook registrations' \
    '  --dry-run       Print what would change; change nothing' \
    '  --claude        Install for Claude Code (default)'
}

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --dry-run) DRY_RUN=true ;;
    --prune-legacy) PRUNE_LEGACY=true ;;
    --uninstall) UNINSTALL=true ;;
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
WORK=""
cleanup() {
  if [[ -n "$TMP" ]]; then rm -rf "$TMP"; fi
  if [[ -n "$WORK" ]]; then rm -rf "$WORK"; fi
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

# shellcheck source=scripts/lib/install-hook-settings.sh
source "$REPO_ROOT/scripts/lib/install-hook-settings.sh"

# Retired skill slugs: the validator's TOMBSTONES list is the single source.
TOMBSTONES="$(sed -n 's/^TOMBSTONES="\(.*\)"$/\1/p' "$REPO_ROOT/scripts/validate.sh")"

WORK="$(mktemp -d)"
STAMP="$(date +%Y%m%d%H%M%S)"
P=""
[[ "$DRY_RUN" == "true" ]] && P="[dry-run] "
N_WARN=0

note() { printf '  %s%s\n' "$P" "$*"; }
warn() { printf '  ⚠ %s%s\n' "$P" "$*"; N_WARN=$((N_WARN + 1)); }

# ── Manifest ──────────────────────────────────────────────────────────────────

# Hash NUL-separated paths (list file $2, relative to dir $1) into "<rel>\t<sha>"
# lines in $3, sorted by path.
hash_into() {
  local dir="$1" list="$2" out="$3"
  : > "$out"
  [[ -s "$list" ]] || return 0
  (cd "$dir" && xargs -0 "${SHA_CMD[@]}" < "$list") \
    | LC_ALL=C awk '{ p = substr($0, 67); sub(/^\.\//, "", p); print p "\t" substr($0, 1, 64) }' \
    | LC_ALL=C sort > "$out"
}

# "<rel>\t<sha>" for each entry of manifest $1. An absolute or `..` path is
# ignored, so a tampered manifest can never aim removal outside its root.
read_manifest() {
  [[ -f "$1" ]] || return 0
  LC_ALL=C awk '
    match($0, /"path": "[^"]*", "sha256": "[0-9a-f]+"/) {
      s = substr($0, RSTART, RLENGTH)
      p = s; sub(/^"path": "/, "", p); sub(/", "sha256".*$/, "", p)
      h = s; sub(/.*"sha256": "/, "", h); sub(/"$/, "", h)
      if (length(h) != 64 || p !~ /^[A-Za-z0-9._@+\/-]+$/ || p ~ /^\// || p ~ /(^|\/)\.\.(\/|$)/) next
      print p "\t" h
    }' "$1" | LC_ALL=C sort -u
}

# Release paths are restricted to [A-Za-z0-9._@+-] segments, so manifest JSON
# needs no escaping and every path survives a tab/newline-delimited plan.
write_manifest() {
  local root="$1" tsv="$2" platform="$3" out="$1/$MANIFEST_NAME"
  {
    printf '{\n  "schema": 1,\n  "name": "agentic-os",\n  "version": "%s",\n' "$VERSION"
    printf '  "source": "%s",\n  "platform": "%s",\n  "files": [\n' "$SOURCE_KIND" "$platform"
    LC_ALL=C awk -F'\t' '
      NR > 1 { printf ",\n" }
      { printf "    {\"path\": \"%s\", \"sha256\": \"%s\"}", $1, $2 }
      END { if (NR) printf "\n" }' "$tsv"
    printf '  ]\n}\n'
  } > "$out.tmp"
  mv "$out.tmp" "$out"
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
sync_place() {
  local id="$1" stage="$2" root="$3" hookp="$4" skillp="$5"
  local w="$WORK/$id" rel nsha osha csha
  local added=0 updated=0 same=0 legacy_kept=0
  mkdir -p "$w"

  if [[ -n "$(LC_ALL=C find "$stage" -name '*[!A-Za-z0-9._@+-]*' -print)" ]]; then
    echo "Error: release contains a path outside [A-Za-z0-9._@+-] — refusing to install:" >&2
    LC_ALL=C find "$stage" -name '*[!A-Za-z0-9._@+-]*' -print >&2
    exit 1
  fi

  (cd "$stage" && find . -type f -print0) > "$w/new.lst"
  hash_into "$stage" "$w/new.lst" "$w/new.tsv"
  read_manifest "$root/$MANIFEST_NAME" > "$w/old.tsv"
  cut -f1 "$w/old.tsv" > "$w/old.paths"
  cut -f1 "$w/new.tsv" "$w/old.tsv" | LC_ALL=C sort -u | while IFS= read -r rel; do
    if [[ -f "$root/$rel" ]]; then printf '%s\0' "$rel"; fi
  done > "$w/cur.lst"
  hash_into "$root" "$w/cur.lst" "$w/cur.tsv"

  LC_ALL=C awk -F'\t' -v OFS='\t' '
    FILENAME == ARGV[1] { n[$1] = $2; k[$1] = 1; next }
    FILENAME == ARGV[2] { o[$1] = $2; k[$1] = 1; next }
    { c[$1] = $2 }
    END { for (p in k) print p, (p in n ? n[p] : "-"), (p in o ? o[p] : "-"), (p in c ? c[p] : "-") }
  ' "$w/new.tsv" "$w/old.tsv" "$w/cur.tsv" | LC_ALL=C sort > "$w/plan.tsv"

  : > "$w/manifest.tsv"
  : > "$w/remove.tsv"
  while IFS=$'\t' read -r rel nsha osha csha; do
    if [[ "$nsha" == "-" ]]; then
      # Tracked by the old manifest, dropped by this release.
      if [[ "$csha" == "-" ]]; then
        :
      elif [[ -n "$hookp" && "$rel" == "$hookp"* ]] && ! command -v jq &>/dev/null; then
        # Without jq the merge cannot unregister it; never delete a hook that
        # may still be registered. Stays tracked so a later run prunes it.
        printf '%s\t%s\n' "$rel" "$osha" >> "$w/manifest.tsv"
        warn "keep retired hook $rel — jq is required to unregister it first"
      elif [[ "$csha" == "$osha" ]]; then
        printf '%s\tno longer shipped\n' "$rel" >> "$w/remove.tsv"
      else
        warn "keep $rel — no longer shipped, but modified locally (now yours)"
      fi
      continue
    fi
    printf '%s\t%s\n' "$rel" "$nsha" >> "$w/manifest.tsv"
    if [[ "$csha" == "-" ]]; then
      place "$stage/$rel" "$root/$rel"
      added=$((added + 1))
    elif [[ "$csha" == "$nsha" ]]; then
      same=$((same + 1))
    elif [[ "$osha" != "-" && "$csha" == "$osha" ]]; then
      place "$stage/$rel" "$root/$rel"
      note "update $rel"
      updated=$((updated + 1))
    elif [[ -n "$hookp" && "$rel" == "$hookp"* ]]; then
      # Shipped hooks are security-relevant: always take the release copy.
      [[ "$DRY_RUN" == "true" ]] || cp -p "$root/$rel" "$root/$rel.bak.$STAMP"
      place "$stage/$rel" "$root/$rel"
      warn "refresh hook $rel — it differed from the release copy; yours is saved as $rel.bak.$STAMP"
      updated=$((updated + 1))
    elif [[ "$FORCE" == "true" ]]; then
      place "$stage/$rel" "$root/$rel"
      note "overwrite $rel (--force)"
      updated=$((updated + 1))
    elif [[ "$osha" == "-" ]]; then
      warn "keep $rel — differs from the release copy and predates the manifest (--force overwrites)"
      legacy_kept=$((legacy_kept + 1))
    else
      warn "keep $rel — modified locally (--force overwrites)"
    fi
  done < "$w/plan.tsv"

  # Retired skills from pre-manifest installs: files the old manifest does not
  # track are removed only with --prune-legacy, listed one by one first.
  local t d f frel names="$TOMBSTONES"
  [[ "$skillp" == "-" ]] && names=""   # "-": this root holds no skills
  for t in $names; do
    d="$skillp$t"
    [[ -d "$root/$d" && ! -e "$stage/$d" ]] || continue
    : > "$w/legacy.lst"
    while IFS= read -r -d '' f; do
      frel="${f#"$root"/}"
      if ! grep -qxF -- "$frel" "$w/old.paths"; then printf '%s\n' "$frel" >> "$w/legacy.lst"; fi
    done < <(find "$root/$d" ! -type d -print0)
    [[ -s "$w/legacy.lst" ]] || continue
    if [[ "$PRUNE_LEGACY" == "true" ]]; then
      while IFS= read -r frel; do
        printf '%s\tretired skill %s (--prune-legacy)\n' "$frel" "$t" >> "$w/remove.tsv"
      done < "$w/legacy.lst"
    else
      warn "retired skill directory $d is still installed (predates the manifest) — re-run with --prune-legacy to remove it"
    fi
  done

  printf '%s\n' "$added" "$updated" "$same" "$legacy_kept" > "$w/counts"
}

sync_finish() {
  local id="$1" root="$3" platform="$6" label="$7"
  local w="$WORK/$id" rel why added updated same legacy_kept
  : > "$w/dirs.lst"
  while IFS=$'\t' read -r rel why; do
    note "remove $rel ($why)"
    [[ "$DRY_RUN" == "true" ]] || rm -f "$root/$rel"
    dirname "$rel" >> "$w/dirs.lst"
  done < "$w/remove.tsv"
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

place() {
  [[ "$DRY_RUN" == "true" ]] && return 0
  mkdir -p "$(dirname "$2")"
  cp "$1" "$2"
}

# Remove now-empty directories from each listed dir up to (never including) root.
prune_empty_dirs() {
  local root="$1" list="$2" d
  [[ "$DRY_RUN" == "true" ]] && return 0
  LC_ALL=C sort -ru "$list" | while IFS= read -r d; do
    while [[ -n "$d" && "$d" != "." && "$d" != "/" ]]; do
      rmdir "$root/$d" 2>/dev/null || break
      d="$(dirname "$d")"
    done
  done
}

# Remove every unmodified manifest file under $1; keep (and name) modified ones.
uninstall_root() {
  local id="$1" root="$2" label="$3"
  local w="$WORK/$id" mf="$2/$MANIFEST_NAME" rel osha csha removed=0 kept=0
  mkdir -p "$w"
  echo ""
  echo "$label: $root"
  if [[ ! -f "$mf" ]]; then
    echo "  · no $MANIFEST_NAME — nothing tracked to remove (a pre-manifest install: run the installer once to adopt it, then uninstall)"
    return 0
  fi
  read_manifest "$mf" > "$w/old.tsv"
  cut -f1 "$w/old.tsv" | while IFS= read -r rel; do
    if [[ -f "$root/$rel" ]]; then printf '%s\0' "$rel"; fi
  done > "$w/cur.lst"
  hash_into "$root" "$w/cur.lst" "$w/cur.tsv"
  LC_ALL=C awk -F'\t' -v OFS='\t' '
    FILENAME == ARGV[1] { o[$1] = $2; next }
    { c[$1] = $2 }
    END { for (p in o) print p, o[p], (p in c ? c[p] : "-") }
  ' "$w/old.tsv" "$w/cur.tsv" | LC_ALL=C sort > "$w/plan.tsv"

  : > "$w/dirs.lst"
  while IFS=$'\t' read -r rel osha csha; do
    if [[ "$csha" == "-" ]]; then
      continue
    elif [[ "$csha" == "$osha" ]]; then
      note "remove $rel"
      [[ "$DRY_RUN" == "true" ]] || rm -f "$root/$rel"
      dirname "$rel" >> "$w/dirs.lst"
      removed=$((removed + 1))
    else
      warn "keep $rel — modified locally"
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

if [[ "$UNINSTALL" == "true" ]]; then
  echo ""
  echo "${P}Uninstalling AgenticOS ($PLATFORM)"
  # Unregister hooks BEFORE deleting files: if the settings rewrite fails, the
  # hook scripts it still points at are left in place.
  if [[ "$PLATFORM" == "claude" ]]; then
    echo ""
    echo "Hook registration: ${DEST%/}/settings.json"
    unregister_claude_hook_settings "$REPO_ROOT" "$DEST" "$RETIRED_HOOKS" "$DRY_RUN"
    uninstall_root claude "$DEST" "Claude Code"
  else
    echo ""
    echo "Hook registration: $CODEX_CONFIG_DIR/hooks.json"
    unregister_codex_hook_settings "$CODEX_CONFIG_DIR" "$DRY_RUN"
    uninstall_root codex-skills "$CODEX_SKILLS_DEST" "Codex skills"
    uninstall_root codex-config "$CODEX_CONFIG_DIR" "Codex agents + hooks"
  fi
  echo ""
  echo "${P}Uninstall complete: $N_WARN file(s) kept with a warning. Hook backups (*.bak.*) and files you created were not touched."
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

  CLAUDE_ARGS=(claude "$STAGE" "$DEST" "hooks/" "skills/" claude "skills, agents, commands, hooks")
  sync_place "${CLAUDE_ARGS[@]}"
  if [[ "$DRY_RUN" == "true" ]]; then
    note "merge AgenticOS hook registration into ${DEST%/}/settings.json"
  else
    if [[ -d "$DEST/hooks" ]]; then
      find "$DEST/hooks" -name "*.sh" -exec chmod +x {} \;
    fi
    merge_claude_hook_settings "$REPO_ROOT" "$DEST" "$RETIRED_HOOKS"
  fi
  sync_finish "${CLAUDE_ARGS[@]}"

  echo ""
  echo "${P}Done. Restart Claude Code to load the new skills, agents, commands, and hooks."
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

  SKILLS_ARGS=(codex-skills "$STAGE/skills" "$CODEX_SKILLS_DEST" "" "" codex "skills")
  CONFIG_ARGS=(codex-config "$STAGE/config" "$CODEX_CONFIG_DIR" "hooks/" "-" codex "agents (Codex TOML) + hooks")
  sync_place "${SKILLS_ARGS[@]}"
  sync_place "${CONFIG_ARGS[@]}"
  if [[ "$DRY_RUN" == "true" ]]; then
    note "merge AgenticOS hook registration into $CODEX_CONFIG_DIR/hooks.json"
  else
    if [[ -d "$CODEX_HOOKS_DEST" ]]; then
      find "$CODEX_HOOKS_DEST" -name "*.sh" -exec chmod +x {} \;
    fi
    merge_codex_hook_settings "$REPO_ROOT" "$CODEX_CONFIG_DIR"
  fi
  sync_finish "${SKILLS_ARGS[@]}"
  sync_finish "${CONFIG_ARGS[@]}"

  echo ""
  echo "${P}Done. Restart Codex to load the skills and agents. Review and trust the new hooks with /hooks."
  echo "Claude slash commands and custom .claude/memory hooks were not installed; Codex uses skills/custom agents and its native memory system instead."
fi

echo ""
if [[ "$N_WARN" -gt 0 ]]; then
  echo "$N_WARN warning(s) above. Files you modified were kept; --force overwrites them."
fi
echo "To update later, re-run this script. To remove AgenticOS, re-run it with --uninstall."
