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

# ── Invariant 4: claude-imports ────────────────────────────────────────────────
check_claude_imports() {
  local cf="$ROOT/CLAUDE.md"
  [[ -f "$cf" ]] || return 0
  while IFS= read -r line; do
    [[ "$line" =~ ^@ ]] || continue
    local rel="${line#@}"
    rel="${rel%%[[:space:]]*}"
    if [[ ! -f "$ROOT/$rel" ]]; then
      fail claude-imports "$cf" "@-import '$rel' does not resolve to an existing file"
    fi
  done < "$cf"
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
EXPECTED_DIRS="agents hooks skills"                       # sorted
EXPECTED_CMDS="agent-new.md skill-new.md state.md"  # sorted

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
# shipped hook scripts, and forces hook *commands* to call a vendored
# .claude/hooks/ script rather than carry inline shell. The real defenses are
# layered (minimal auditable scripts + no runtime fetch + human security review +
# the workspace-trust gate). See SECURITY.md for the threat model and limits.
#
# Pattern@@@reason. `@@@` is the delimiter (no regex here contains it). Scope is
# deliberately the shipped scripts only — NOT settings.json config — so the scan
# stays meaningful and false-positive-free on JSON config.
HOOK_DENY=(
  '\b(curl|wget|nc|ncat|netcat|telnet|scp|sftp|socat|aria2c)\b@@@network egress in a shipped hook (exfil/fetch vector)'
  '\bopenssl[[:space:]]+s_client\b@@@openssl s_client network connection in a shipped hook'
  '/dev/(tcp|udp)/@@@raw socket via /dev/tcp in a shipped hook'
  '\|[[:space:]]*(ba)?sh\b@@@pipe-to-shell in a shipped hook (remote-code-exec vector)'
  '\bbase64[[:space:]]+(-d|-D|--decode)@@@base64-decode in a shipped hook (obfuscation)'
  '\beval[[:space:]]@@@eval in a shipped hook (dynamic code execution)'
  '\beval["'"'"']@@@no-space eval of a quoted string in a shipped hook (dynamic code execution)'
  '\bsource[[:space:]]+<\(@@@process-substitution source in a shipped hook'
  '\b(python3?|node|perl|ruby)[[:space:]]+-(e|c)\b@@@inline interpreter one-liner in a shipped hook'
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

check_hook_safety() {
  # (a) Shipped hooks must be vendored *.sh shell scripts, scanned for the
  # denylist. The denylist models SHELL idioms, so a non-shell hook (.py/.js)
  # would evade it entirely — restrict shipped hooks to *.sh and reject the rest.
  if [[ -d "$CLAUDE/hooks" ]]; then
    local f entry re reason ln
    while IFS= read -r f; do
      case "$f" in
        *.sh) ;;             # shell hook — scan it below
        *.md) continue ;;    # in-tree docs (e.g. a README) — not executable, skip
        *) fail hook-safety "$f" "non-.sh file in .claude/hooks/ — only vendored *.sh shell hooks may ship (other interpreters evade the shell-idiom denylist)"; continue ;;
      esac
      for entry in "${HOOK_DENY[@]}"; do
        re="${entry%%@@@*}"; reason="${entry##*@@@}"
        if grep -qE "$re" "$f"; then
          ln=$(grep -nE "$re" "$f" | head -1 | cut -d: -f1)
          fail hook-safety "$f" "$reason (line $ln)"
        fi
      done
    done < <(find "$CLAUDE/hooks" -type f | sort)
  fi

  # (b) Every hook "command" in settings.json must invoke a vendored
  # .claude/hooks/ script — no inline shell. Crude line-based JSON scan (no jq),
  # consistent with this script's other crude parses. No-ops when there is no
  # hooks block. Catches an inline `curl … | bash` smuggled into a command field.
  local sj="$CLAUDE/settings.json"
  if [[ -f "$sj" ]]; then
    local cline cmdval
    while IFS= read -r cline; do
      # Extract the JSON string value of "command". The bracket expression
      # [^"\] means "any char that is not a quote or a backslash" (inside an ERE
      # bracket `\` is literal on both BSD and GNU) — paired with \\. to consume
      # escaped chars, this is the standard JSON-string idiom. On no match sed
      # echoes the line UNCHANGED, so guard on cmdval != cline below: only assert
      # the vendored-path rule when extraction actually succeeded — otherwise a
      # line-wrapped/oddly-quoted value would false-positive (block a legit config).
      cmdval="$(printf '%s' "$cline" | sed -E 's/.*"command"[[:space:]]*:[[:space:]]*"(([^"\]|\\.)*)".*/\1/')"
      if [[ "$cmdval" != "$cline" ]] && ! printf '%s' "$cmdval" | grep -q '\.claude/hooks/'; then
        fail hook-safety "$sj" "hook command does not call a vendored .claude/hooks/ script: $cmdval"
      fi
    done < <(grep -E '"command"[[:space:]]*:' "$sj" || true)
  fi
}

# ── Run all checks ─────────────────────────────────────────────────────────────
check_frontmatter_and_names
check_dangling_refs
check_claude_imports
check_memory_length
check_ship_manifest
check_review_tiers
check_hook_safety

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
if [[ "$FAILURES" -gt 0 ]]; then
  echo "validate.sh: $FAILURES failure(s)."
  exit 1
fi
echo "validate.sh: OK — all invariants pass."
exit 0
