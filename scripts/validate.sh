#!/usr/bin/env bash
#
# validate.sh — deterministic, LLM-free static validator for the skills-db library.
#
# Catches STRUCTURAL regressions for free on every commit/PR/install. Semantic
# quality (routing collisions, rubric adherence) is the job of the expensive
# LLM `audit-library` workflow — this script never touches that.
#
# Pure Bash + standard CLI only (grep/sed/awk/find/wc). No node/python/jq/yq.
# Runs on macOS (dev) and ubuntu-latest (CI).
#
# Usage:
#   bash scripts/validate.sh [REPO_ROOT]
#
# REPO_ROOT defaults to this script's own repo root (parent of scripts/),
# computed from BASH_SOURCE so it works when called from install.sh against a
# downloaded tarball directory.
#
# Exit 0 if clean, non-zero if any invariant fails. Each failure prints:
#   FAIL [<invariant>]: <path> — <reason>
#
# ── Frontmatter parsing assumptions (documented per spec) ──────────────────────
# Frontmatter is the block between the first two lines that are exactly "---".
# Keys are parsed line-by-line as `^key:` at column 0. A key is considered
# "present and non-empty" if either:
#   - it has an inline value:  `key: some text`  (value after the colon is non-blank), OR
#   - it opens a block scalar:  `key: |` or `key: >` followed by at least one
#     non-blank indented continuation line.
# This crude line-oriented parse is sufficient for the library's flat
# frontmatter (no nested maps inside frontmatter, no anchors).

set -euo pipefail

# macOS ships bash 3.2.57 (pre-GPLv3, frozen forever) as /bin/bash, which does
# not reliably close process-substitution (`<(...)`) pipe fds until the whole
# script exits — repeated `<(...)` inside loops (one grep per file, across the
# invariant checks below) leaks fds. macOS's default per-process open-file
# soft limit is 256 (`launchctl limit maxfiles`), which a real library run
# (100+ skill/agent/command files) can exceed, dying with "cannot duplicate
# fd: Too many open files" or "ambiguous redirect". Raise this process's own
# soft limit before doing any of that work — but only up, never down: a caller
# whose shell already has a higher soft limit than 4096 must keep it, since
# clamping to 4096 would needlessly shrink headroom for its whole process tree.
# No-ops harmlessly if the hard limit is already lower than 4096.
if [[ "$(ulimit -Sn)" != "unlimited" && "$(ulimit -Sn)" -lt 4096 ]]; then
  ulimit -n 4096 2>/dev/null || true
fi

# Byte-literal matching everywhere. BSD grep/sed (macOS) mis-count offsets around
# multibyte UTF-8 (e.g. the em-dash in MEMORY.md) under a UTF-8 locale, which
# truncates `grep -oE` captures. C locale makes macOS and Linux behave identically.
export LC_ALL=C

# ── Resolve repo root ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="${1:-$DEFAULT_ROOT}"

if [[ ! -d "$ROOT/.claude" ]]; then
  echo "FAIL [setup]: $ROOT — no .claude/ directory found at repo root" >&2
  exit 2
fi

CLAUDE="$ROOT/.claude"

# ── Failure accumulation ───────────────────────────────────────────────────────
FAILURES=0
fail() {
  # $1 = invariant tag, $2 = path, $3 = reason
  printf 'FAIL [%s]: %s — %s\n' "$1" "$2" "$3"
  FAILURES=$((FAILURES + 1))
}

# ── Frontmatter helpers ────────────────────────────────────────────────────────

# Extract the frontmatter block (lines strictly between the first two `---`).
# Prints nothing if there is no well-formed block.
fm_block() {
  awk '
    { sub(/\r$/, "") }               # tolerate CRLF line endings
    NR==1 && $0!="---" { exit }      # no frontmatter at all
    NR==1 { inside=1; next }
    inside && $0=="---" { exit }
    inside { print }
  ' "$1"
}

# Given a frontmatter block on stdin and a key name, decide if the key is
# present AND non-empty (inline value OR non-empty block scalar). Prints "1"
# if satisfied, "0" otherwise.
fm_has_key() {
  local key="$1"
  awk -v key="$key" '
    BEGIN { found=0; ok=0 }
    # Match the key at column 0: "key:" optionally followed by a value.
    $0 ~ "^"key":" {
      found=1
      # strip "key:" prefix, then trim surrounding whitespace
      val=$0
      sub("^"key":[ \t]*", "", val)
      gsub(/[ \t\r]+$/, "", val)
      if (val != "" && val != "|" && val != ">" && val != "|-" && val != ">-" && val != "|+" && val != ">+") {
        ok=1; exit
      }
      # block scalar opener — look ahead for a non-blank continuation line
      block=1
      next
    }
    block==1 {
      line=$0
      gsub(/[ \t\r]+$/, "", line)
      if (line ~ /^[ \t]/ && line !~ /^[ \t]*$/) { ok=1; exit }   # indented, non-blank
      if (line !~ /^[ \t]/ && line !~ /^[ \t]*$/) { block=0 }     # de-dented: block ended
    }
    END { print (found && ok) ? "1" : "0" }
  '
}

# Extract the inline (single-line) value of a frontmatter key. Empty if block scalar.
fm_value() {
  local key="$1"
  awk -v key="$key" '
    $0 ~ "^"key":" {
      val=$0
      sub("^"key":[ \t]*", "", val)
      gsub(/^[ \t]+|[ \t\r]+$/, "", val)
      print val
      exit
    }
  '
}

# ── Invariant 1 + 2: frontmatter presence & names ──────────────────────────────
KEBAB_RE='^[a-z0-9]+(-[a-z0-9]+)*$'

check_frontmatter_and_names() {
  # Skills: name, description, when_to_use ; name == parent dir
  if [[ -d "$CLAUDE/skills" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      local block; block="$(fm_block "$f")"
      local k
      for k in name description when_to_use; do
        if [[ "$(printf '%s\n' "$block" | fm_has_key "$k")" != "1" ]]; then
          fail frontmatter "$f" "missing or empty frontmatter key: $k"
        fi
      done
      local name; name="$(printf '%s\n' "$block" | fm_value name)"
      local dir; dir="$(basename "$(dirname "$f")")"
      if [[ -n "$name" ]]; then
        if ! [[ "$name" =~ $KEBAB_RE ]]; then
          fail names "$f" "name '$name' is not kebab-case"
        fi
        if [[ "$name" != "$dir" ]]; then
          fail names "$f" "name '$name' != parent dir '$dir'"
        fi
      fi
    done < <(find "$CLAUDE/skills" -name SKILL.md -type f | sort)
  fi

  # Agents: name, description, tools ; name == filename minus .md
  if [[ -d "$CLAUDE/agents" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      local block; block="$(fm_block "$f")"
      local k
      for k in name description tools; do
        if [[ "$(printf '%s\n' "$block" | fm_has_key "$k")" != "1" ]]; then
          fail frontmatter "$f" "missing or empty frontmatter key: $k"
        fi
      done
      local name; name="$(printf '%s\n' "$block" | fm_value name)"
      local base; base="$(basename "$f" .md)"
      if [[ -n "$name" ]]; then
        if ! [[ "$name" =~ $KEBAB_RE ]]; then
          fail names "$f" "name '$name' is not kebab-case"
        fi
        if [[ "$name" != "$base" ]]; then
          fail names "$f" "name '$name' != filename '$base'"
        fi
      fi
    done < <(find "$CLAUDE/agents" -maxdepth 1 -name '*.md' -type f | sort)
  fi

  # Commands: description, allowed-tools (argument-hint optional)
  if [[ -d "$CLAUDE/commands" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      local block; block="$(fm_block "$f")"
      local k
      for k in description allowed-tools; do
        if [[ "$(printf '%s\n' "$block" | fm_has_key "$k")" != "1" ]]; then
          fail frontmatter "$f" "missing or empty frontmatter key: $k"
        fi
      done
    done < <(find "$CLAUDE/commands" -maxdepth 1 -name '*.md' -type f | sort)
  fi

  # Workflows: meta object with name, description, phases ; meta.name == filename minus .js
  if [[ -d "$CLAUDE/workflows" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      # Isolate the `export const meta = { ... };` block by braces.
      local meta; meta="$(awk '
        /export[ \t]+const[ \t]+meta[ \t]*=/ { capture=1 }
        capture {
          print
          n=gsub(/{/,"{"); o+=n
          n=gsub(/}/,"}"); o-=n
          if (started && o<=0) exit
          if (o>0) started=1
        }
      ' "$f")"
      if [[ -z "$meta" ]]; then
        fail frontmatter "$f" "no 'export const meta = {...}' block found"
        continue
      fi
      local k
      for k in name description phases; do
        if ! printf '%s\n' "$meta" | grep -Eq "(^|[ \t,{])$k[ \t]*:"; then
          fail frontmatter "$f" "meta object missing key: $k"
        fi
      done
      # meta.name value: first `name:` line, strip to the quoted/unquoted token.
      local mname; mname="$(printf '%s\n' "$meta" | grep -E '(^|[ \t,{])name[ \t]*:' | head -1 \
        | sed -E 's/.*name[ \t]*:[ \t]*//; s/[",]+//g; s/[ \t\r]+$//')"
      local base; base="$(basename "$f" .js)"
      if [[ -n "$mname" ]]; then
        if ! [[ "$mname" =~ $KEBAB_RE ]]; then
          fail names "$f" "meta.name '$mname' is not kebab-case"
        fi
        if [[ "$mname" != "$base" ]]; then
          fail names "$f" "meta.name '$mname' != filename '$base'"
        fi
      fi
    done < <(find "$CLAUDE/workflows" -maxdepth 1 -name '*.js' -type f | sort)
  fi
}

# ── Invariant 3: dangling-ref ──────────────────────────────────────────────────

# Normalize a path containing ../ and ./ segments (lexical, no filesystem).
normalize_path() {
  awk '
    {
      abs = ($0 ~ /^\//) ? 1 : 0
      n=split($0, parts, "/")
      top=0
      for (i=1;i<=n;i++) {
        p=parts[i]
        if (p=="" || p==".") continue
        if (p=="..") { if (top>0 && stack[top]!="..") top--; else stack[++top]=p; continue }
        stack[++top]=p
      }
      out=""
      for (i=1;i<=top;i++) out = out "/" stack[i]
      if (abs) print out
      else { sub(/^\//, "", out); print out }
    }
  ' <<<"$1"
}

# Print a file with HTML comment blocks (<!-- ... -->) removed, so example
# link syntax inside comments isn't mistaken for a real link.
strip_html_comments() {
  awk '
    { line=$0 }
    incomment {
      if (line ~ /-->/) { sub(/.*-->/, "", line); incomment=0; print line }
      next
    }
    {
      while (match(line, /<!--/)) {
        pre=substr(line, 1, RSTART-1)
        rest=substr(line, RSTART)
        if (match(rest, /-->/)) {           # comment opens and closes on same line
          line = pre substr(rest, RSTART+3)
        } else {                            # comment runs to a later line
          print pre; incomment=1; line=""; break
        }
      }
      if (!incomment) print line
    }
  ' "$1"
}

check_dangling_refs() {
  local mem="$CLAUDE/memory"

  # (a) MEMORY.md [t](file.md) links resolve to siblings.
  if [[ -f "$mem/MEMORY.md" ]]; then
    while IFS= read -r target; do
      [[ -n "$target" ]] || continue
      [[ "$target" == *"://"* ]] && continue
      [[ "$target" == \#* ]] && continue
      if [[ ! -f "$mem/$target" ]]; then
        fail dangling-ref "$mem/MEMORY.md" "link target '$target' does not resolve to a sibling"
      fi
    done < <(strip_html_comments "$mem/MEMORY.md" \
              | grep -oE '\]\([^)]+\)' | sed -E 's/^\]\(//; s/\)$//; s/[[:space:]].*$//')
  fi

  # (b) [[name]] wikilinks inside any .claude/memory/*.md resolve to sibling name.md
  if [[ -d "$mem" ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      while IFS= read -r wl; do
        [[ -n "$wl" ]] || continue
        if [[ ! -f "$mem/$wl.md" ]]; then
          fail dangling-ref "$f" "wikilink [[$wl]] does not resolve to sibling '$wl.md'"
        fi
      done < <(grep -oE '\[\[[^]]+\]\]' "$f" | sed -E 's/^\[\[//; s/\]\]$//')
    done < <(find "$mem" -maxdepth 1 -name '*.md' -type f | sort)
  fi

  # (c) relative markdown file-links inside SKILL.md / agent .md files resolve
  #     relative to that file's dir. Skip ://, pure #anchor, mailto:, and any
  #     target without a file extension.
  local files=()
  [[ -d "$CLAUDE/skills" ]] && while IFS= read -r f; do files+=("$f"); done < <(find "$CLAUDE/skills" -name 'SKILL.md' -type f | sort)
  [[ -d "$CLAUDE/agents" ]] && while IFS= read -r f; do files+=("$f"); done < <(find "$CLAUDE/agents" -maxdepth 1 -name '*.md' -type f | sort)

  # Guard empty-array expansion: bash 3.2 (macOS) errors on "${arr[@]}" under
  # `set -u` when the array is empty (e.g. a tarball with no skills/ or agents/).
  [[ ${#files[@]} -eq 0 ]] && return 0
  local f
  for f in "${files[@]}"; do
    local fdir; fdir="$(dirname "$f")"
    while IFS= read -r raw; do
      [[ -n "$raw" ]] || continue
      # strip a trailing #anchor from the path part
      local target="${raw%%#*}"
      [[ -z "$target" ]] && continue                 # pure #anchor
      [[ "$target" == *"://"* ]] && continue          # URL
      [[ "$target" == mailto:* ]] && continue         # mailto
      # only check things that look like a path with a file extension
      [[ "$target" =~ \.[A-Za-z0-9]+$ ]] || continue
      local resolved; resolved="$(normalize_path "$fdir/$target")"
      if [[ ! -e "$resolved" ]]; then
        fail dangling-ref "$f" "relative link '$target' does not resolve to $resolved"
      fi
    done < <(grep -oE '\]\([^)]+\)' "$f" | sed -E 's/^\]\(//; s/\)$//; s/[[:space:]].*$//')
  done
}

# ── Invariant 4: claude-flat-sync ───────────────────────────────────────────────
# CLAUDE.md is a GENERATED flat file (scripts/build-claude-md.sh): every
# .claude/rules/<name>.md is embedded verbatim — with `](../` links rebased to
# `](.claude/` — between marker comments:
#   <!-- BEGIN RULE: .claude/rules/<name>.md --> ... <!-- END RULE -->
# Gates (self-contained so it also runs against fixtures/tarballs lacking scripts/):
#   (a) any @-import line must still resolve (generic; tag claude-imports)
#   (b) no @-import of .claude/rules at all — flat means flat
#   (c) every rules file on disk has a block whose body matches its source
#   (d) no BEGIN marker cites a rules file that is not on disk
# CLAUDE_LINK_REBASE must stay identical to LINK_REBASE in build-claude-md.sh.
CLAUDE_LINK_REBASE='s#](\.\./#](.claude/#g; s#](\.claude/\.\./#](#g'
check_claude_flat_sync() {
  local cf="$ROOT/CLAUDE.md"
  [[ -f "$cf" ]] || return 0
  local line rel
  while IFS= read -r line; do
    [[ "$line" =~ ^@ ]] || continue
    rel="${line#@}"
    rel="${rel%%[[:space:]]*}"
    if [[ ! -f "$ROOT/$rel" ]]; then
      fail claude-imports "$cf" "@-import '$rel' does not resolve to an existing file"
    fi
    if [[ "$rel" == .claude/rules/* ]]; then
      fail claude-flat-sync "$cf" "@-import of '$rel' — CLAUDE.md is flat/generated; run scripts/build-claude-md.sh"
    fi
  done < "$cf"
  local rules_dir="$ROOT/.claude/rules"
  [[ -d "$rules_dir" ]] || return 0
  local f name
  for f in "$rules_dir"/*.md; do
    [[ -f "$f" ]] || continue
    name="$(basename "$f")"
    if ! grep -qF "<!-- BEGIN RULE: .claude/rules/$name -->" "$cf"; then
      fail claude-flat-sync "$cf" "rule '.claude/rules/$name' has no embedded block — run scripts/build-claude-md.sh"
      continue
    fi
    if ! cmp -s <(awk -v m="<!-- BEGIN RULE: .claude/rules/$name -->" '
          $0 == "<!-- END RULE -->" { found = 0 }
          found { print }
          $0 == m { found = 1 }' "$cf") \
        <(sed "$CLAUDE_LINK_REBASE" "$f"); then
      fail claude-flat-sync "$cf" "embedded block for '$name' differs from source — run scripts/build-claude-md.sh"
    fi
  done
  # (d) blocks citing rules files that no longer exist
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    if [[ ! -f "$rules_dir/$name" ]]; then
      fail claude-flat-sync "$cf" "embedded block cites missing rule '.claude/rules/$name' — run scripts/build-claude-md.sh"
    fi
  done < <(sed -n 's#^<!-- BEGIN RULE: \.claude/rules/\(.*\) -->$#\1#p' "$cf")
  # (e) whole-file regeneration diff, when the builder is available. The block
  # checks above are self-contained for fixtures/tarballs without scripts/, but
  # they cannot see drift OUTSIDE marker blocks (preamble edits, sections
  # injected between blocks, reordering) — the builder --check can.
  local builder="$ROOT/scripts/build-claude-md.sh"
  if [[ -f "$builder" ]]; then
    if ! bash "$builder" --check >/dev/null 2>&1; then
      fail claude-flat-sync "$cf" "CLAUDE.md differs from build-claude-md.sh output (drift outside rule blocks?) — run scripts/build-claude-md.sh"
    fi
  fi
  return 0
}

# ── Invariant 5: memory-length ─────────────────────────────────────────────────
check_memory_length() {
  local mf="$CLAUDE/memory/MEMORY.md"
  [[ -f "$mf" ]] || return 0   # gitignored → absent in CI/tarball; skip gracefully
  local lines; lines="$(wc -l < "$mf" | tr -d ' ')"
  if [[ "$lines" -gt 200 ]]; then
    fail memory-length "$mf" "MEMORY.md is $lines lines (max 200)"
  fi
}

# ── Invariant 6: ship-manifest ─────────────────────────────────────────────────
# Allowlist of what install scripts MUST ship — exact equality, any drift fails.
EXPECTED_DIRS="agents hooks skills"                       # sorted (Claude)
EXPECTED_CMDS="agent-new.md skill-new.md state.md"  # sorted (Claude)

check_ship_manifest() {
  local sh="$ROOT/install.sh"
  local ps="$ROOT/install.ps1"

  # ---- install.sh ----
  if [[ -f "$sh" ]]; then
    # install_dir "name"
    local got_dirs; got_dirs="$(grep -oE '^[[:space:]]*install_dir[[:space:]]+"[^"]+"' "$sh" \
      | sed -E 's/.*install_dir[[:space:]]+"([^"]+)".*/\1/' | sort -u | tr '\n' ' ' | sed -E 's/ +$//')"
    # Ship-tagged command files are the ONLY quoted "*.md" tokens in install.sh
    # (maintainer-command names in comments are unquoted and extensionless), so a
    # whole-file scan tolerates line-continuation / reflow of the install_files call.
    local got_cmds; got_cmds="$(grep -oE '"[^"]+\.md"' "$sh" \
      | tr -d '"' | sort -u | tr '\n' ' ' | sed -E 's/ +$//')"
    compare_manifest "$sh" "$got_dirs" "$got_cmds"
  fi

  # ---- install.ps1 ----
  if [[ -f "$ps" ]]; then
    # Install-Dir "name"  PLUS the manual hooks copy block (ps1 ships hooks via a
    # bespoke block, not Install-Dir) — detect the literal "hooks" install there.
    local got_dirs; got_dirs="$(grep -oE 'Install-Dir[[:space:]]+"[^"]+"' "$ps" \
      | sed -E 's/.*Install-Dir[[:space:]]+"([^"]+)".*/\1/' | sort -u)"
    if grep -Eq 'Join-Path[[:space:]]+\$Src[[:space:]]+"hooks"' "$ps"; then
      got_dirs="$got_dirs"$'\n'"hooks"
    fi
    got_dirs="$(printf '%s\n' "$got_dirs" | grep -v '^$' | sort -u | tr '\n' ' ' | sed -E 's/ +$//')"
    # As with install.sh: command files are the only quoted "*.md" tokens, so a
    # whole-file scan tolerates a multi-line @(...) array reflow.
    local got_cmds; got_cmds="$(grep -oE '"[^"]+\.md"' "$ps" \
      | tr -d '"' | sort -u | tr '\n' ' ' | sed -E 's/ +$//')"
    compare_manifest "$ps" "$got_dirs" "$got_cmds"
  fi
}

# Exact whole-token membership. `grep -w` treats '.' as a word character, so it
# would let "route.md" match "routeXmd" — wrong for a manifest equality check.
# -x (whole line) + -F (literal, no regex) against a newline-split haystack gives
# true exact matching. Haystack tokens never contain spaces (dir/file names).
in_set() {
  local needle="$1"; shift
  printf '%s\n' "$@" | grep -qxF -- "$needle"
}

compare_manifest() {
  local file="$1" got_dirs="$2" got_cmds="$3"
  # dirs
  if [[ "$got_dirs" != "$EXPECTED_DIRS" ]]; then
    local d
    for d in $got_dirs;      do in_set "$d" $EXPECTED_DIRS || fail ship-manifest "$file" "ships unexpected dir: $d"; done
    for d in $EXPECTED_DIRS; do in_set "$d" $got_dirs      || fail ship-manifest "$file" "missing expected dir: $d"; done
  fi
  # commands
  if [[ "$got_cmds" != "$EXPECTED_CMDS" ]]; then
    local c
    for c in $got_cmds;      do in_set "$c" $EXPECTED_CMDS || fail ship-manifest "$file" "ships unexpected command: $c"; done
    for c in $EXPECTED_CMDS; do in_set "$c" $got_cmds      || fail ship-manifest "$file" "missing expected command: $c"; done
  fi
}

# ── Invariant 7: review-tiers ──────────────────────────────────────────────────
# The tier doctrine policing itself (.claude/rules/review-tiers.md):
#   (a) any skill/agent that declares a "Tier discipline" section must reference
#       review-tiers.md, so tier claims always trace back to the doctrine;
#   (b) the findings ledger (gitignored → usually absent in CI; skip gracefully)
#       must be line-wise JSON objects with valid status values. This is a crude
#       shape check, not a JSON parse — no python/jq per this script's
#       constraints: each non-blank line must look like {...} and carry a
#       "status" field with one of the five allowed values.
VALID_LEDGER_STATUSES='NEW|RECURRING|INVESTIGATING|PROMOTED|RETIRED-NOISE'

check_review_tiers() {
  # (a) Tier discipline sections reference the doctrine. Scan every markdown
  # file under skills/ (SKILL.md AND references/), agents/, and commands/ so a
  # heading can't dodge the check by living in a reference or command file.
  # Heading match is case-insensitive for the same reason.
  local files=()
  [[ -d "$CLAUDE/skills" ]] && while IFS= read -r f; do files+=("$f"); done < <(find "$CLAUDE/skills" -name '*.md' -type f | sort)
  [[ -d "$CLAUDE/agents" ]] && while IFS= read -r f; do files+=("$f"); done < <(find "$CLAUDE/agents" -maxdepth 1 -name '*.md' -type f | sort)
  [[ -d "$CLAUDE/commands" ]] && while IFS= read -r f; do files+=("$f"); done < <(find "$CLAUDE/commands" -maxdepth 1 -name '*.md' -type f | sort)
  if [[ ${#files[@]} -gt 0 ]]; then
    local f
    for f in "${files[@]}"; do
      if grep -Eiq '^##+[ \t]+Tier discipline' "$f"; then
        if ! grep -q 'review-tiers\.md' "$f"; then
          fail review-tiers "$f" "declares a 'Tier discipline' section but never references review-tiers.md"
        fi
      fi
    done
  fi

  # (b) ledger shape
  local lf="$CLAUDE/ledger/findings.jsonl"
  [[ -f "$lf" ]] || return 0
  local n=0 line
  while IFS= read -r line || [[ -n "$line" ]]; do
    n=$((n+1))
    [[ -z "${line//[[:space:]]/}" ]] && continue
    if ! [[ "$line" =~ ^\{.*\}[[:space:]]*$ ]]; then
      fail ledger "$lf" "line $n is not a JSON object"
      continue
    fi
    if ! grep -Eq '"status"[[:space:]]*:[[:space:]]*"('"$VALID_LEDGER_STATUSES"')"' <<<"$line"; then
      fail ledger "$lf" "line $n missing or invalid \"status\" (want one of: $VALID_LEDGER_STATUSES)"
    fi
  done < "$lf"
}

# ── Invariant 8: hook-safety ───────────────────────────────────────────────────
# Shipped hooks are the library's ONE piece of distributed executable code:
# install.sh runs `install_dir "hooks"` and `chmod +x` on .claude/hooks/*.sh, so
# they land and run on CONSUMER machines. That is a supply-chain surface — a bug
# or an upstream compromise in a shipped hook executes arbitrary shell downstream.
#
# This invariant is a TRIPWIRE, not a sandbox. A static scan cannot PROVE a hook
# is safe; it denies the obvious exfil / destructive / obfuscation patterns in
# shipped hook scripts, and forces hook *commands* to call a vendored hooks/
# script rather than carry inline shell. Surfaces: `.claude/hooks/` + optional
# dev `settings.json` (Claude Code). The real defenses are layered (minimal
# auditable scripts + no runtime fetch + human security review + the
# workspace-trust gate). See SECURITY.md for the threat model and limits.
#
# Pattern@@@reason. `@@@` is the delimiter (no regex here contains it). Scope is
# deliberately the shipped scripts only — NOT settings.json config — so the scan
# stays meaningful and false-positive-free on JSON config.
HOOK_DENY=(
  '\b(curl|wget|nc|ncat|netcat|telnet|scp|sftp|ssh|rsync|socat|aria2c|getent|nslookup|dig|drill|kdig)\b@@@network egress or DNS-resolver exfil in a shipped hook (exfil/fetch vector)'
  '\bopenssl[[:space:]]+s_client\b@@@openssl s_client network connection in a shipped hook'
  '\bopenssl[[:space:]]+enc\b@@@openssl enc (encode/encrypt obfuscation) in a shipped hook'
  '/dev/(tcp|udp)/@@@raw socket via /dev/tcp in a shipped hook'
  '\|[[:space:]]*(ba)?sh\b@@@pipe-to-shell in a shipped hook (remote-code-exec vector)'
  '\b(ba|da|z)?sh[[:space:]]*<<@@@here-string/heredoc fed to a shell in a shipped hook (remote-code-exec vector)'
  '\bbase64[[:space:]]+(-d|-D|--decode)@@@base64-decode in a shipped hook (obfuscation)'
  '\beval[[:space:]]@@@eval in a shipped hook (dynamic code execution)'
  '\beval["'"'"']@@@no-space eval of a quoted string in a shipped hook (dynamic code execution)'
  '\bsource[[:space:]]+<\(@@@process-substitution source in a shipped hook'
  '\b(python[0-9.]*|node[0-9.]*|perl[0-9.]*|ruby[0-9.]*)[[:space:]]+-(e|c)\b@@@inline interpreter one-liner in a shipped hook'
  '\bpython[0-9.]*[[:space:]]+-m@@@python -m module execution in a shipped hook (e.g. http.server; matches -m with or without a space)'
  '\b(ba|da|z)?sh[[:space:]]+-c\b@@@dynamic shell exec (sh -c) in a shipped hook'
  '\bphp[[:space:]]+-r\b@@@inline php one-liner in a shipped hook'
  '\b(g?awk)\b[^#]*system[[:space:]]*\(@@@awk system() shell-out in a shipped hook'
  '\b(g?awk)\b[^#]*/inet/(tcp|udp)/@@@awk /inet/ network egress in a shipped hook'
  'rm[[:space:]]+-[a-z]*r[a-z]*f?[[:space:]]+(/|~|\$HOME|\$\{HOME)@@@recursive delete of HOME/root in a shipped hook'
  '\bsudo[[:space:]]@@@privilege escalation (sudo) in a shipped hook'
  '\bchmod[[:space:]]+([a-z-]+[[:space:]]+)*777\b@@@chmod 777 in a shipped hook'
  '\b(crontab|launchctl|systemctl)\b@@@persistence mechanism in a shipped hook'
  'LaunchAgents|LaunchDaemons@@@macOS persistence path in a shipped hook'
  '(~|\$HOME|\$\{HOME\})/\.(ssh|aws|gnupg)/@@@credential-store access in a shipped hook'
  '\b(id_rsa|\.git-credentials|\.npmrc)\b@@@credential-file access in a shipped hook'
)

# Scan a hooks directory for denylisted shell idioms (Invariant 8(a)). $2 is a
# human label for error messages (e.g. the relative path ".claude/hooks/").
# install.sh ships .claude/hooks/*.sh onto consumer machines, so a bug or upstream
# compromise there executes arbitrary shell downstream — this denies the obvious
# exfil / destructive / obfuscation idioms.
scan_hook_scripts_dir() {
  local hooks_dir="$1" label="$2"
  [[ -d "$hooks_dir" ]] || return 0
  local f entry re reason ln
  while IFS= read -r f; do
    case "$f" in
      *.sh) ;;
      *.md) continue ;;
      *) fail hook-safety "$f" "non-.sh file in $label — only vendored *.sh shell hooks may ship (other interpreters evade the shell-idiom denylist)"; continue ;;
    esac
    for entry in "${HOOK_DENY[@]}"; do
      re="${entry%%@@@*}"; reason="${entry##*@@@}"
      if grep -qE "$re" "$f"; then
        ln=$(grep -nE "$re" "$f" | head -1 | cut -d: -f1)
        fail hook-safety "$f" "$reason (line $ln)"
      fi
    done
  done < <(find "$hooks_dir" -type f | sort)
}

# Crude line-based JSON scan (no jq): extract "command" string values, require a
# vendored hooks/ path prefix, then assert strict-shape allowlist match.
check_hook_commands_in_file() {
  local json_file="$1" path_needle="$2" shape_re="$3" shape_desc="$4"
  [[ -f "$json_file" ]] || return 0
  local cline cmdval
  while IFS= read -r cline; do
    cmdval="$(printf '%s' "$cline" | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\]|\\.)*)".*/\1/')"
    if [[ "$cmdval" == "$cline" ]]; then
      continue
    fi
    if ! printf '%s' "$cmdval" | grep -qF "$path_needle"; then
      fail hook-safety "$json_file" "hook command does not call a vendored ${path_needle} script: $cmdval"
    elif ! printf '%s' "$cmdval" | grep -qE "$shape_re"; then
      fail hook-safety "$json_file" "hook command is not a single strict-shape vendored-script call ($shape_desc) — no chaining/newlines/subshells/traversal: $cmdval"
    fi
  done < <(grep -E '"command"[[:space:]]*:' "$json_file" || true)
}

check_hook_safety() {
  # (a) Shipped hooks must be vendored *.sh shell scripts, scanned for the
  # denylist. The denylist models SHELL idioms, so a non-shell hook (.py/.js)
  # would evade it entirely — restrict shipped hooks to *.sh and reject the rest.
  scan_hook_scripts_dir "$CLAUDE/hooks" ".claude/hooks/"

  # (b) Every hook "command" must invoke a vendored hooks/ script — no inline shell.
  check_hook_commands_in_file "$CLAUDE/settings.json" \
    '.claude/hooks/' \
    '^[a-z][a-z0-9]* \.claude/hooks/[A-Za-z0-9_-]+\.sh( [A-Za-z0-9_./=-]+)*$' \
    '<interpreter> .claude/hooks/<name>.sh [simple args]'

  # Consumer global install template (Invariant 8(b)).
  check_hook_commands_in_file "$ROOT/assets/consumer/claude-settings.json" \
    '.claude/hooks/' \
    '^bash \$HOME/.claude/hooks/[A-Za-z0-9_-]+\.sh$' \
    'bash $HOME/.claude/hooks/<name>.sh'
}

# ── Invariant 8(d): Claude hook-registration parity (consumer ⊆ dev) ────────────
# 8(a)/8(b) only prove Claude command SHAPES are benign — nothing asserts the
# consumer global template (assets/consumer/claude-settings.json) stays in step
# with the dev tree (.claude/settings.json). So a hook could be registered for
# consumers that dev never wired, or point at a script that was never vendored,
# shipping a DEAD MECHANISM (the memory-extraction spike finding, issue #217).
#
# This is the Tier-0 ratchet that closes the gap, in the SUBSET direction — every
# (event, script) the consumer manifest registers MUST:
#   (a) resolve to a script that exists in .claude/hooks/, AND
#   (b) be registered on the SAME event in .claude/settings.json (the dev tree).
# Dev MAY register MORE than the consumer (e.g. a dev-only hook mid-rollout), so
# the check is one-directional (consumer ⊆ dev), NOT set-equality. It is satisfied
# in Phase 1 — the consumer manifest registers no memory-extract hook, so there is
# nothing to violate — and catches the real drift at P4, when the consumer starts
# registering memory-extract on Stop but the dev registration or the vendored
# script disagrees. Guarded on both files existing, so it is inert until then.
#
# Parsing note: Claude's settings schema nests each event's commands inside an
# inner "hooks": [ ] wrapper and may place "matcher"/"hooks"/"command" on one
# physical line, so a naive parser that treats the first "<key>": [ on a line as
# the event would mis-attribute them. We therefore treat a "<key>": [ opener as an
# event ONLY when <key> is a known Claude Code hook event name — robust for the
# real, closed event set (a new event would need adding here, same maintenance
# contract as the TOMBSTONES list).
CLAUDE_HOOK_EVENTS="PreToolUse PostToolUse Notification UserPromptSubmit Stop SubagentStop PreCompact SessionStart SessionEnd"
claude_hook_event_script_pairs() {
  local json_file="$1"
  [[ -f "$json_file" ]] || return 0
  awk -v events=" $CLAUDE_HOOK_EVENTS " '
    # Event opener: "<event>": [  — only when <event> is a known Claude hook event,
    # so the inner "hooks": [ wrapper (and inline "matcher": ...) never reset it.
    /"[A-Za-z][A-Za-z0-9]*"[[:space:]]*:[[:space:]]*\[/ {
      ev=$0
      sub(/^[^"]*"/, "", ev); sub(/".*/, "", ev)
      if (index(events, " " ev " ") > 0) event=ev
    }
    # Command value -> script basename (drop path prefix + trailing args + probes).
    /"command"[[:space:]]*:[[:space:]]*"/ {
      cmd=$0
      sub(/.*"command"[[:space:]]*:[[:space:]]*"/, "", cmd); sub(/".*/, "", cmd)
      sub(/.*\//, "", cmd)   # strip path prefix -> basename
      sub(/ .*/, "", cmd)    # strip trailing args, keep the script name
      if (event != "" && cmd !~ /-probe\.sh$/) print event "\t" cmd
    }
  ' "$json_file" | sort -u
}

check_claude_hook_registration() {
  local dev="$CLAUDE/settings.json"
  local consumer="$ROOT/assets/consumer/claude-settings.json"
  # Only meaningful when both registration files exist.
  [[ -f "$dev" && -f "$consumer" ]] || return 0
  local dev_pairs consumer_pairs p base
  dev_pairs="$(claude_hook_event_script_pairs "$dev")"
  consumer_pairs="$(claude_hook_event_script_pairs "$consumer")"

  # (b) consumer ⊆ dev: any (event, script) the consumer registers that is NOT
  # registered on the same event in dev is drift (a consumer-only hook).
  while IFS= read -r p; do
    [[ -n "$p" ]] && fail claude-hook-registration "$consumer" \
      "(event, script) registered in assets/consumer/claude-settings.json but not on the same event in .claude/settings.json: ${p//$'\t'/ } — consumer hook set must be a subset of the dev tree"
  done < <(comm -23 <(printf '%s\n' "$consumer_pairs") <(printf '%s\n' "$dev_pairs"))

  # (a) every consumer-registered hook must resolve to a vendored .claude/hooks/
  # script, else install would merge a command whose target never shipped.
  while IFS= read -r p; do
    [[ -n "$p" ]] || continue
    base="${p##*$'\t'}"
    [[ -f "$CLAUDE/hooks/$base" ]] || fail claude-hook-registration "$consumer" \
      "consumer registers hook '$base' but no .claude/hooks/$base is vendored — install would wire a dead command"
  done <<< "$consumer_pairs"
}

# ── Invariant 9: tombstones ────────────────────────────────────────────────────
# Bare-name PROSE references to a pruned skill/agent/command route to a target that
# no longer exists. Invariant 3 only sees markdown LINKS; a backtick `slug`, a
# `/command`, or a `slug/path` ref is invisible to it — that gap let ~30 dead refs
# survive a prune with validate green (PR #143 review). This is the deterministic
# ratchet for that class: an explicit TOMBSTONES list of removed artifact slugs;
# fail if any appears as `slug` / `/slug` / slug/path / slug.md in a shipped body.
#
# MAINTENANCE: when you delete a skill/agent/command, add its slug here. When you
# (re)add one, remove it. The list is exact slugs — no enumeration of idioms — so
# it is FP-free except for a deleted name reused as ordinary backticked prose
# (reword it: don't backtick a removed artifact's name).
TOMBSTONES="api-and-interface-design bigquery-ai-agent blog-post-author blog-post-shaper ci-cd-and-automation cloud-infrastructure code-simplification competitive-positioning context-engineering course-author course-design course-shaper debugging-and-error-recovery deck-generator deprecation-and-migration documentation-and-adrs documentation-writer elevenlabs-tts finance-ops frontend-ui-engineering game-concept-creator game-marketer game-monetization-strategist git-workflow-and-versioning icp-validation idea-refine incremental-implementation market-sizing meeting-intelligence ops-analyst performance-optimization plan-clean podcast-ops pricing-and-packaging route security-and-hardening shipping-and-launch site-reliability-engineering social-growth software-design source-driven-development spec-driven-development standards-enforcer system-architect team-lead team-ops technical-product-management technical-strategist test-driven-development typescript-quality-engineering using-agent-skills ux-design ux-research ux-specialist v2-collab x-longform-post yt-competitive-analysis yt-shorts-pipeline yt-shorts-script"

check_tombstones() {
  local alt; alt="$(printf '%s' "$TOMBSTONES" | tr ' ' '|')"
  # Forms a library cross-reference takes: `slug` / `/slug` (backtick), slug/ (dir
  # path), slug.md (file path). Plain prose without one of these is NOT matched, so
  # an English word that happens to collide (e.g. "route") is not flagged.
  local re="\`/?(${alt})\`|\b(${alt})/|\b(${alt})\.md\b"
  local f ln
  for dir in skills agents commands; do
    [[ -d "$CLAUDE/$dir" ]] || continue
    # One recursive grep per directory instead of one process substitution per
    # file: with 50-100+ files per dir, the per-file version stacks that many
    # `<(...)` pipes, which bash 3.2 (macOS's /bin/bash) doesn't reclaim
    # promptly — see the ulimit note near the top of this script.
    while IFS=: read -r f ln _; do
      [[ -n "$f" && -n "$ln" ]] && fail tombstone "$f" "reference to a pruned artifact (line $ln) — repoint to a live successor or drop"
    done < <(grep -rnE --include='*.md' "$re" "$CLAUDE/$dir" 2>/dev/null)
  done
}

# ── Invariant 10: test-ci-coverage ─────────────────────────────────────────────
# Convention: every scripts/*-test.sh is wired into the CI workflow so it actually
# runs. A test that exists but is never invoked is a DEAD test — it gives false
# assurance and rots silently (the exact recall-vs-enforcement failure #233 targets:
# an intended check that nothing executes). This is the Tier-0 ratchet for that
# class — add a scripts/*-test.sh and forget to reference it in
# .github/workflows/validate.yml, and validate fails until it is wired in.
#
# Deterministic + FP-free: it only asserts the test's basename appears somewhere
# in the workflow file (grep -F, literal). Guarded on BOTH files existing, so it
# is inert in a shipped tarball/fixture (which carries neither scripts/ nor
# .github/) and only ever runs in the source checkout.
check_test_ci_coverage() {
  local wf="$ROOT/.github/workflows/validate.yml"
  local scripts_dir="$ROOT/scripts"
  [[ -f "$wf" && -d "$scripts_dir" ]] || return 0
  local t base
  while IFS= read -r t; do
    [[ -n "$t" ]] || continue
    base="$(basename "$t")"
    if ! grep -qF -- "$base" "$wf"; then
      fail test-ci-coverage "$t" "test script not referenced in .github/workflows/validate.yml — wire it into CI or it never runs"
    fi
  done < <(find "$scripts_dir" -maxdepth 1 -name '*-test.sh' -type f | sort)
}

# ── Run all checks ─────────────────────────────────────────────────────────────
check_frontmatter_and_names
check_dangling_refs
check_claude_flat_sync
check_memory_length
check_ship_manifest
check_review_tiers
check_hook_safety
check_claude_hook_registration
check_tombstones
check_test_ci_coverage

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "validate.sh: $FAILURES failure(s)."
  exit 1
fi
echo "validate.sh: OK — all invariants pass."
exit 0
