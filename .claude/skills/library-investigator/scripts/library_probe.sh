#!/usr/bin/env bash
#
# library_probe.sh — mechanical, judgment-free probe for the library-investigator.
#
# Probes the four library surfaces (skills/SKILL.md, agents/*.md, commands/*.md,
# workflows/*.js) against the mechanically-checkable subset of RULESET.md and
# emits one machine-readable row per (file, rule) check. It casts NO judgment:
# every row is a FACT plus its evidence. The truthseeker reports counts; it never
# emits an overall verdict.
#
# Pure Bash 3.2 + BSD-safe CLI (grep/sed/awk/find/wc). No node/python/jq/yq.
# Mirrors scripts/validate.sh idioms: set -euo pipefail, LC_ALL=C, fm_block.
#
# Usage:
#   bash library_probe.sh [REPO_ROOT]
#
# REPO_ROOT defaults to four levels up from this script
# (.../skills/library-investigator/scripts/library_probe.sh -> repo root),
# overridable by $1.
#
# Output rows (TAB-separated):
#   STATUS<TAB>TIER<TAB>RULE<TAB>FILE<TAB>DETAIL
# STATUS ∈ CONFORMS | VIOLATES | UNVERIFIABLE | N-A | TIER0
# A trailing counts summary is printed to stdout.
#
# Exit nonzero (1) if any VIOLATES row was emitted; 0 otherwise. (A failing
# Tier-0 validate.sh is reported as a TIER0 row and also forces nonzero exit,
# since a validate.sh failure is itself a deterministic VIOLATES against R6/R7/
# R8/R31/dangling-refs.)

set -euo pipefail
export LC_ALL=C

# ── Resolve repo root (four levels up from this script) ────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
ROOT="${1:-$DEFAULT_ROOT}"

if [[ ! -d "$ROOT/.claude" ]]; then
  printf 'UNVERIFIABLE\t-\tsetup\t%s\tno .claude/ directory at repo root\n' "$ROOT"
  exit 2
fi

CLAUDE="$ROOT/.claude"

# ── Counters ───────────────────────────────────────────────────────────────────
N_CONFORMS=0
N_VIOLATES=0
N_UNVERIFIABLE=0
N_NA=0

emit() {
  # $1 STATUS  $2 TIER  $3 RULE  $4 FILE  $5 DETAIL
  printf '%s\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5"
  case "$1" in
    CONFORMS)     N_CONFORMS=$((N_CONFORMS + 1)) ;;
    VIOLATES)     N_VIOLATES=$((N_VIOLATES + 1)) ;;
    UNVERIFIABLE) N_UNVERIFIABLE=$((N_UNVERIFIABLE + 1)) ;;
    N-A)          N_NA=$((N_NA + 1)) ;;
  esac
}

# ── Frontmatter helpers (mirrors validate.sh) ──────────────────────────────────

# Extract the frontmatter block (lines strictly between the first two `---`).
fm_block() {
  awk '
    { sub(/\r$/, "") }
    NR==1 && $0!="---" { exit }
    NR==1 { inside=1; next }
    inside && $0=="---" { exit }
    inside { print }
  ' "$1"
}

# Given a frontmatter block on stdin and a key, print the FULL value of that key.
# Inline value, OR a block scalar / wrapped value spanning continuation lines up
# to the next top-level `key:` (a line matching ^[A-Za-z0-9_-]+:) or end of block.
# Continuation lines are joined with single spaces. Used for description length.
fm_value_full() {
  local key="$1"
  awk -v key="$key" '
    BEGIN { cap=0 }
    $0 ~ "^"key":" {
      val=$0
      sub("^"key":[ \t]*", "", val)
      gsub(/^[ \t]+|[ \t\r]+$/, "", val)
      # strip a bare block-scalar indicator so it is not counted as content
      if (val == "|" || val == ">" || val == "|-" || val == ">-" || val == "|+" || val == ">+") val=""
      out=val
      cap=1
      next
    }
    cap==1 {
      line=$0
      sub(/\r$/, "", line)
      # a new top-level key ends the value
      if (line ~ /^[A-Za-z0-9_-]+:/) { cap=0; next }
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      if (line == "") next
      out = (out == "") ? line : out " " line
    }
    END { print out }
  '
}

# Print the inline value of a key (single line), like validate.sh fm_value.
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

# ── Probe: R13 — no angle brackets in frontmatter CONTENT (.md surfaces) ────────
# R13 bans XML angle brackets as a prompt-injection vector in frontmatter
# content. A YAML block-scalar indicator (`key: |`, `key: >`, `key: >-`, etc.)
# is structural YAML, not injected content, and validate.sh already treats it as
# legal — so the indicator char immediately after `key:` is stripped before the
# scan. Per RULESET R13, a command's `argument-hint` value is also exempt — the
# `<placeholder>`/`[optional]` syntax is a rendered CLI usage hint, not injected
# instruction text — so that line's value is blanked before the scan. Any `<` or
# `>` that survives elsewhere is genuine content and a true violation.
probe_r13() {
  local f="$1" block scrubbed
  block="$(fm_block "$f")"
  if [[ -z "$block" ]]; then
    emit UNVERIFIABLE 1 R13 "$f" "no frontmatter block found"
    return
  fi
  # Remove a trailing block-scalar indicator on any `key:` line:
  # `key: >`, `key: |`, `key: >-`, `key: |+`, `key: >2`, etc. (indicator only,
  # nothing else after it). This never touches `<`/`>` that appear in values.
  scrubbed="$(printf '%s\n' "$block" \
    | sed -E 's/^([A-Za-z0-9_-]+:[ \t]*)[|>]([+-]?[0-9]*)[ \t]*$/\1/' \
    | sed -E 's/^(argument-hint:).*$/\1/')"
  if printf '%s\n' "$scrubbed" | grep -q '[<>]'; then
    local line
    line="$(printf '%s\n' "$scrubbed" | grep -n '[<>]' | head -1)"
    emit VIOLATES 1 R13 "$f" "frontmatter content contains angle bracket: $line"
  else
    emit CONFORMS 1 R13 "$f" "no angle brackets in frontmatter content"
  fi
}

# ── Probe: R9 — name must not contain claude/anthropic (skills + agents) ────────
probe_r9() {
  local f="$1" block name
  block="$(fm_block "$f")"
  name="$(printf '%s\n' "$block" | fm_value name)"
  if [[ -z "$name" ]]; then
    emit UNVERIFIABLE 1 R9 "$f" "no name key in frontmatter"
    return
  fi
  if printf '%s' "$name" | grep -qiE 'claude|anthropic'; then
    emit VIOLATES 1 R9 "$f" "name '$name' contains reserved token claude/anthropic"
  else
    emit CONFORMS 1 R9 "$f" "name '$name' free of reserved tokens"
  fi
}

# ── Probe: R12/R32(desc) — description length > 800 chars (.md surfaces) ────────
probe_desc_len() {
  local f="$1" block desc len
  block="$(fm_block "$f")"
  if [[ -z "$block" ]]; then
    emit UNVERIFIABLE 1 R12/R32-desc "$f" "no frontmatter block found"
    return
  fi
  desc="$(printf '%s\n' "$block" | fm_value_full description)"
  if [[ -z "$desc" ]]; then
    emit UNVERIFIABLE 1 R12/R32-desc "$f" "no description value found"
    return
  fi
  len="$(printf '%s' "$desc" | wc -c | tr -d ' ')"
  if [[ "$len" -gt 800 ]]; then
    emit VIOLATES 1 R12/R32-desc "$f" "description is $len chars (local cap 800)"
  else
    emit CONFORMS 1 R12/R32-desc "$f" "description is $len chars (<= 800)"
  fi
}

# ── Probe: R32(body) — SKILL.md line count > 100 (skills only) ──────────────────
probe_skill_lines() {
  local f="$1" lines
  lines="$(wc -l < "$f" | tr -d ' ')"
  if [[ "$lines" -gt 100 ]]; then
    emit VIOLATES 1 R32-body "$f" "SKILL.md is $lines lines (local cap 100)"
  else
    emit CONFORMS 1 R32-body "$f" "SKILL.md is $lines lines (<= 100)"
  fi
}

# ── Probe: R33 — in-skill README.md present (skills only) ───────────────────────
probe_r33() {
  local skill_dir="$1" readme
  readme="$skill_dir/README.md"
  if [[ -f "$readme" ]]; then
    # RULESET R33: in-skill README.md is an accepted repo convention, not a
    # violation. Reported as CONFORMS so the file is accounted for without
    # inflating the VIOLATES count.
    emit CONFORMS 2 R33 "$readme" "in-skill README.md present — accepted repo convention (RULESET R33)"
  else
    emit CONFORMS 2 R33 "$skill_dir/SKILL.md" "no in-skill README.md"
  fi
}

# ── Probe: R5 — runnable script at skill ROOT (not under scripts/) (skills only) ─
probe_r5() {
  local skill_dir="$1" hit found=0
  # runnables directly in the skill folder (maxdepth 1), excluding scripts/
  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    found=1
    emit VIOLATES 2 R5 "$hit" "runnable at skill root (belongs under scripts/)"
  done < <(find "$skill_dir" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' -o -name '*.js' \) | sort)
  if [[ "$found" -eq 0 ]]; then
    emit CONFORMS 2 R5 "$skill_dir/SKILL.md" "no runnable at skill root"
  fi
}

# ── Probe: judgment rules → N-A, defer to library-reviewer (per surface) ────────
emit_judgment_deferrals() {
  local f="$1"
  emit N-A - R11/R15-R17 "$f" "description what+when / specificity is judgment; see library-reviewer"
  emit N-A - R22 "$f" "use-case design is judgment; see library-reviewer"
  emit N-A - routing "$f" "routing specificity is judgment; see library-reviewer"
  emit N-A - single-responsibility "$f" "one-role/one-concern is judgment; see library-reviewer"
}

# ── Surface: skills (SKILL.md) ─────────────────────────────────────────────────
probe_skills() {
  [[ -d "$CLAUDE/skills" ]] || return 0
  local f dir
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    dir="$(dirname "$f")"
    probe_r13 "$f"
    probe_r9 "$f"
    probe_desc_len "$f"
    probe_skill_lines "$f"
    probe_r33 "$dir"
    probe_r5 "$dir"
    emit_judgment_deferrals "$f"
  done < <(find "$CLAUDE/skills" -name SKILL.md -type f | sort)
}

# ── Surface: agents (.md) ──────────────────────────────────────────────────────
probe_agents() {
  [[ -d "$CLAUDE/agents" ]] || return 0
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    probe_r13 "$f"
    probe_r9 "$f"
    probe_desc_len "$f"
    emit_judgment_deferrals "$f"
  done < <(find "$CLAUDE/agents" -maxdepth 1 -name '*.md' -type f | sort)
}

# ── Surface: commands (.md) ────────────────────────────────────────────────────
probe_commands() {
  [[ -d "$CLAUDE/commands" ]] || return 0
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    probe_r13 "$f"
    probe_desc_len "$f"
    emit N-A - routing "$f" "command routing/arg-hint coherence is judgment; see library-reviewer"
  done < <(find "$CLAUDE/commands" -maxdepth 1 -name '*.md' -type f | sort)
}

# ── Surface: workflows (.js) ───────────────────────────────────────────────────
# Workflows carry their contract in an `export const meta = {...}` literal, not
# YAML frontmatter; their structural rules (meta presence, name match) are
# Tier-0 validate.sh territory. The investigator defers them rather than
# re-implementing a JS parser.
probe_workflows() {
  [[ -d "$CLAUDE/workflows" ]] || return 0
  local f
  while IFS= read -r f; do
    [[ -n "$f" ]] || continue
    emit N-A - meta-structure "$f" "workflow meta/phase structure is Tier-0; see validate.sh"
    emit N-A - routing "$f" "workflow meta/phase coherence is judgment; see library-reviewer"
  done < <(find "$CLAUDE/workflows" -maxdepth 1 -name '*.js' -type f | sort)
}

# ── Tier-0 line: run validate.sh and report its exit (R6/R7/R8/R31/dangling) ────
run_validate() {
  local vs="$ROOT/scripts/validate.sh" rc out
  if [[ ! -f "$vs" ]]; then
    emit UNVERIFIABLE 0 "R6/R7/R8/R31/dangling-refs" "$vs" "validate.sh not found"
    return 0
  fi
  set +e
  out="$(bash "$vs" "$ROOT" 2>&1)"
  rc=$?
  set -e
  if [[ "$rc" -eq 0 ]]; then
    printf 'TIER0\t0\tR6/R7/R8/R31/dangling-refs\t%s\tvalidate.sh exit 0 (OK)\n' "$vs"
  else
    # A validate.sh failure is a deterministic VIOLATES against its Tier-0 rules.
    local lastfail
    lastfail="$(printf '%s\n' "$out" | grep -E '^FAIL ' | head -1)"
    printf 'TIER0\t0\tR6/R7/R8/R31/dangling-refs\t%s\tvalidate.sh exit %s: %s\n' "$vs" "$rc" "${lastfail:-see output}"
    VALIDATE_FAILED=1
  fi
}

# ── Run ────────────────────────────────────────────────────────────────────────
VALIDATE_FAILED=0
probe_skills
probe_agents
probe_commands
probe_workflows
run_validate

# ── Counts summary ─────────────────────────────────────────────────────────────
echo ""
echo "── library_probe counts ──"
printf 'CONFORMS %d / VIOLATES %d / UNVERIFIABLE %d / N-A %d\n' \
  "$N_CONFORMS" "$N_VIOLATES" "$N_UNVERIFIABLE" "$N_NA"
echo "(Tier-0 validate.sh reported separately above as TIER0 row.)"
echo "No overall verdict is emitted — counts are the headline."

if [[ "$N_VIOLATES" -gt 0 || "$VALIDATE_FAILED" -eq 1 ]]; then
  exit 1
fi
exit 0
