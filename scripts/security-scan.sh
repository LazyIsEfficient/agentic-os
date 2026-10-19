#!/usr/bin/env bash
# security-scan.sh — run whichever deterministic security scanners are installed
# and report their results as reproducible (Tier 0/1) evidence.
#
# Run from the project root (the directory whose files you want scanned):
#   security-scan.sh [--base <ref>] [--paths <file>...] [--json]
#
# Scope (which files are scanned):
#   --base <ref>      files changed between merge-base(<ref>, HEAD) and the working
#                     tree, plus untracked non-ignored files. Deleted files skipped.
#   --paths <f>...    exactly these files. --paths consumes every following argument
#                     until --json, --base or `--`; everything after `--` is a path.
#                     Prefix a file literally named "--json" as "./--json".
#   (neither)         uncommitted changes vs HEAD plus untracked files.
#   Paths are git-relative to the current directory (`git diff --relative`).
#
# Scanners (each runs only if installed; absence is reported, never skipped):
#   gitleaks          `gitleaks dir` on each in-scope file, --redact (secrets never
#                     reach output). Honors ./.gitleaks.toml and ./.gitleaksignore.
#   semgrep           `semgrep scan` on the in-scope files with --metrics=off.
#                     Rules come from env SEMGREP_CONFIG (default p/security-audit).
#                     A registry name (p/...) FETCHES RULES FROM THE SEMGREP REGISTRY
#                     over the network. For offline use point it at a local ruleset:
#                     SEMGREP_CONFIG=./semgrep-rules.yml (file or directory).
#   dependency audit  over lockfiles in the current directory plus any in-scope
#                     lockfile: osv-scanner if installed (all lockfiles at once),
#                     otherwise npm audit (package-lock.json / npm-shrinkwrap.json),
#                     pip-audit (requirements*.txt, run with --disable-pip --no-deps
#                     so no package code is installed or built — unpinned
#                     requirements therefore report `error`), cargo audit
#                     (Cargo.lock). osv-scanner and npm audit query online
#                     vulnerability databases.
#
# Per-scanner status: ran (no findings) | findings | unavailable | error.
#
# --json emits:
#   {"scanners":[{"name","status","reason"?,"findings":[{"file","line","rule",
#                 "severity","message"}]}]}
#   `line` is null for dependency findings; `reason` explains unavailable/error
#   (and a `ran` with nothing to scan, e.g. "no files in scope").
#
# Exit codes:
#   0  no findings, and at least one scanner ran
#   1  at least one finding (from any scanner)
#   2  usage error (bad flag, --base ref does not resolve, not a git repo)
#   3  no scanner was available (nothing ran)
#   4  a scanner errored and no scanner produced findings
#
# Requires bash (3.2+ compatible), jq and git (git only for --base / default scope).
set -euo pipefail

SEMGREP_CONFIG="${SEMGREP_CONFIG:-p/security-audit}"

usage() {
  echo "usage: security-scan.sh [--base <ref>] [--paths <file>...] [--json]" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || { echo "security-scan: jq is required" >&2; exit 2; }

BASE=""
JSON=false
PATHS_GIVEN=false
FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      [[ $# -ge 2 ]] || usage
      BASE="$2"; shift 2 ;;
    --json) JSON=true; shift ;;
    --paths)
      PATHS_GIVEN=true; shift
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --json|--base) break ;;
          --) shift; while [[ $# -gt 0 ]]; do FILES+=("$1"); shift; done ;;
          *) FILES+=("$1"); shift ;;
        esac
      done ;;
    -h|--help) usage ;;
    *) echo "security-scan: unknown argument: $1" >&2; usage ;;
  esac
done

if [[ "$PATHS_GIVEN" == true && -n "$BASE" ]]; then
  echo "security-scan: --base and --paths are mutually exclusive" >&2; exit 2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Collect in-scope files NUL-safely (git paths are untrusted: spaces, newlines,
# leading dashes). Only existing regular files are kept.
if [[ "$PATHS_GIVEN" == false ]]; then
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "security-scan: not a git work tree (use --paths)" >&2; exit 2; }
  if [[ -n "$BASE" ]]; then
    [[ "$BASE" != -* ]] || { echo "security-scan: invalid --base ref: $BASE" >&2; exit 2; }
    git rev-parse --verify --quiet "${BASE}^{commit}" >/dev/null || {
      echo "security-scan: --base ref does not resolve: $BASE" >&2; exit 2; }
    DIFF_FROM="$(git merge-base "$BASE" HEAD)"
  else
    DIFF_FROM="HEAD"
  fi
  {
    git diff --name-only -z --diff-filter=d --relative "$DIFF_FROM" --
    git ls-files -z --others --exclude-standard --
  } > "$TMP/files.z"
  while IFS= read -r -d '' f; do FILES+=("$f"); done < "$TMP/files.z"
fi

# Normalize: keep regular files, prefix relative paths with ./ so a leading dash
# can never be parsed as a flag, and de-duplicate.
SCAN=()
for f in ${FILES[@]+"${FILES[@]}"}; do
  [[ -f "$f" ]] || continue
  case "$f" in /*|./*) ;; *) f="./$f" ;; esac
  dup=false
  for s in ${SCAN[@]+"${SCAN[@]}"}; do [[ "$s" == "$f" ]] && { dup=true; break; }; done
  [[ "$dup" == true ]] || SCAN+=("$f")
done

: > "$TMP/results.jsonl"

# emit <name> <status> <reason> <findings-json-array>
emit() {
  jq -cn --arg name "$1" --arg status "$2" --arg reason "$3" --argjson findings "$4" \
    '{name:$name, status:$status, findings:$findings} + (if $reason == "" then {} else {reason:$reason} end)' \
    >> "$TMP/results.jsonl"
}

# Strip a leading "./" or "$PWD/" so findings report project-relative paths.
# shellcheck disable=SC2016  # $pwd is a jq variable, bound via --arg
REL_FILTER='def rel: if type == "string" then (ltrimstr($pwd + "/") | ltrimstr("./")) else . end;'

status_for() { if [[ "$1" -gt 0 ]]; then echo findings; else echo ran; fi; }

# ── gitleaks ──────────────────────────────────────────────────────────────────
scan_gitleaks() {
  if ! command -v gitleaks >/dev/null 2>&1; then
    emit gitleaks unavailable "gitleaks not installed" '[]'; return
  fi
  if [[ ${#SCAN[@]} -eq 0 ]]; then
    emit gitleaks ran "no files in scope" '[]'; return
  fi
  local cfg=()
  [[ -f ./.gitleaks.toml ]] && cfg=(--config ./.gitleaks.toml)
  local f i=0 all="$TMP/gitleaks-all.json"
  echo '[]' > "$all"
  for f in "${SCAN[@]}"; do
    i=$((i + 1))
    local report="$TMP/gitleaks-$i.json"
    # --exit-code 0: leaks exit 0, so any nonzero exit is a genuine error.
    if ! gitleaks dir --no-banner --redact --exit-code 0 --log-level error \
        ${cfg[@]+"${cfg[@]}"} --report-format json --report-path "$report" -- "$f" \
        >/dev/null 2>"$TMP/gitleaks.err"; then
      emit gitleaks error "gitleaks failed on $f: $(head -c 300 "$TMP/gitleaks.err")" '[]'; return
    fi
    if ! jq -e 'type == "array"' "$report" >/dev/null 2>&1; then
      emit gitleaks error "gitleaks produced unparseable report for $f" '[]'; return
    fi
    jq -s '.[0] + .[1]' "$all" "$report" > "$all.new" && mv "$all.new" "$all"
  done
  local findings
  findings="$(jq -c --arg pwd "$PWD" "$REL_FILTER"'
    [.[] | {file: (.File | rel), line: .StartLine, rule: .RuleID,
            severity: "HIGH", message: .Description}]' "$all")"
  emit gitleaks "$(status_for "$(jq 'length' <<<"$findings")")" "" "$findings"
}

# ── semgrep ───────────────────────────────────────────────────────────────────
scan_semgrep() {
  if ! command -v semgrep >/dev/null 2>&1; then
    emit semgrep unavailable "semgrep not installed" '[]'; return
  fi
  if [[ ${#SCAN[@]} -eq 0 ]]; then
    emit semgrep ran "no files in scope" '[]'; return
  fi
  local out="$TMP/semgrep.json" rc=0
  # Without --error, semgrep exits 0 even with findings; nonzero means failure.
  semgrep scan --config "$SEMGREP_CONFIG" --json --quiet --metrics=off \
    --disable-version-check -- "${SCAN[@]}" >"$out" 2>"$TMP/semgrep.err" || rc=$?
  if [[ "$rc" -ne 0 ]] || ! jq -e '.results | type == "array"' "$out" >/dev/null 2>&1; then
    local msg
    msg="$(jq -r '[.errors[]?.message] | join("; ")' "$out" 2>/dev/null || true)"
    [[ -n "$msg" ]] || msg="$(head -c 300 "$TMP/semgrep.err")"
    emit semgrep error "semgrep exited $rc: $msg" '[]'; return
  fi
  local findings
  findings="$(jq -c --arg pwd "$PWD" "$REL_FILTER"'
    [.results[] | {file: (.path | rel), line: .start.line, rule: .check_id,
                   severity: (.extra.severity // "UNKNOWN"), message: .extra.message}]' "$out")"
  emit semgrep "$(status_for "$(jq 'length' <<<"$findings")")" "" "$findings"
}

# ── dependency audit ──────────────────────────────────────────────────────────
is_lockfile() {
  case "$(basename -- "$1")" in
    package-lock.json|npm-shrinkwrap.json|yarn.lock|pnpm-lock.yaml|Cargo.lock|\
    poetry.lock|Pipfile.lock|uv.lock|go.mod|Gemfile.lock|composer.lock|requirements*.txt) return 0 ;;
  esac
  return 1
}

LOCKS=()
add_lock() {
  local l
  for l in ${LOCKS[@]+"${LOCKS[@]}"}; do [[ "$l" == "$1" ]] && return 0; done
  LOCKS+=("$1")
}

collect_lockfiles() {
  local f
  for f in ./* ./.[!.]*; do
    [[ -f "$f" ]] && is_lockfile "$f" && add_lock "$f"
  done
  for f in ${SCAN[@]+"${SCAN[@]}"}; do
    is_lockfile "$f" && add_lock "$f"
  done
  return 0
}

audit_osv() {
  local args=() l out="$TMP/osv.json" rc=0
  for l in "${LOCKS[@]}"; do args+=(-L "$l"); done
  # `scan` defaults to the `source` subcommand (osv-scanner v2).
  # Exit: 0 clean, 1 vulns, 128 no packages found, anything else is an error.
  osv-scanner scan --format json --verbosity error "${args[@]}" >"$out" 2>"$TMP/osv.err" || rc=$?
  if [[ "$rc" -eq 128 ]]; then emit osv-scanner ran "no packages found in lockfiles" '[]'; return; fi
  if [[ "$rc" -ne 0 && "$rc" -ne 1 ]] || ! jq -e '.results | type == "array"' "$out" >/dev/null 2>&1; then
    emit osv-scanner error "osv-scanner exited $rc: $(head -c 300 "$TMP/osv.err")" '[]'; return
  fi
  local findings
  findings="$(jq -c --arg pwd "$PWD" "$REL_FILTER"'
    [.results[] | (.source.path | rel) as $file | .packages[]? |
      .package as $p | .vulnerabilities[]? |
      {file: $file, line: null, rule: .id,
       severity: (.database_specific.severity // "UNKNOWN"),
       message: ("\($p.name)@\($p.version): \(.summary // .details // "vulnerability")")}]' "$out")"
  emit osv-scanner "$(status_for "$(jq 'length' <<<"$findings")")" "" "$findings"
}

audit_npm() {
  local lock="$1" dir out rc=0
  dir="$(dirname -- "$lock")"; out="$TMP/npm-audit.json"
  # npm audit exits 1 when vulnerabilities exist; trust the JSON shape instead.
  (cd -- "$dir" && npm audit --json --package-lock-only) >"$out" 2>"$TMP/npm.err" || rc=$?
  if ! jq -e '.vulnerabilities | type == "object"' "$out" >/dev/null 2>&1; then
    emit npm-audit error "npm audit exited $rc on $lock: $(jq -r '.error.summary? // empty' "$out" 2>/dev/null || head -c 300 "$TMP/npm.err")" '[]'; return
  fi
  local findings
  findings="$(jq -c --arg file "$lock" --arg pwd "$PWD" "$REL_FILTER"'
    [.vulnerabilities[] | . as $v |
      ([.via[] | objects] | first) as $adv |
      {file: ($file | rel), line: null,
       rule: (if $adv then ($adv.url // ($adv.source | tostring)) else "npm-audit" end),
       severity: ($v.severity // "UNKNOWN" | ascii_upcase),
       message: ("\($v.name): \(if $adv then $adv.title else "vulnerable via \($v.via | join(", "))" end)")}]' "$out")"
  emit npm-audit "$(status_for "$(jq 'length' <<<"$findings")")" "" "$findings"
}

audit_pip() {
  local lock="$1" out="$TMP/pip-audit.json" rc=0
  # --disable-pip --no-deps: never install/build packages from an untrusted file.
  pip-audit -r "$lock" -f json --progress-spinner off --disable-pip --no-deps \
    >"$out" 2>"$TMP/pip.err" || rc=$?
  if ! jq -e '.dependencies | type == "array"' "$out" >/dev/null 2>&1; then
    emit pip-audit error "pip-audit exited $rc on $lock: $(tail -c 300 "$TMP/pip.err")" '[]'; return
  fi
  local findings
  findings="$(jq -c --arg file "$lock" --arg pwd "$PWD" "$REL_FILTER"'
    [.dependencies[] | . as $d | .vulns[]? |
      {file: ($file | rel), line: null, rule: .id, severity: "UNKNOWN",
       message: ("\($d.name)@\($d.version): \(.description // .id)")}]' "$out")"
  emit pip-audit "$(status_for "$(jq 'length' <<<"$findings")")" "" "$findings"
}

audit_cargo() {
  local lock="$1" out="$TMP/cargo-audit.json" rc=0
  # UNVERIFIED: `cargo audit --json` output shape (.vulnerabilities.list[] with
  # .advisory and .package) is taken from rustsec conventions, not run locally.
  # A shape mismatch reports `error`, never a silent pass.
  cargo audit --json --file "$lock" >"$out" 2>"$TMP/cargo.err" || rc=$?
  if ! jq -e '.vulnerabilities.list | type == "array"' "$out" >/dev/null 2>&1; then
    emit cargo-audit error "cargo audit exited $rc on $lock: $(tail -c 300 "$TMP/cargo.err")" '[]'; return
  fi
  local findings
  findings="$(jq -c --arg file "$lock" --arg pwd "$PWD" "$REL_FILTER"'
    [.vulnerabilities.list[] |
      {file: ($file | rel), line: null, rule: (.advisory.id // "cargo-audit"),
       severity: "UNKNOWN",
       message: ("\(.package.name)@\(.package.version): \(.advisory.title // "vulnerability")")}]' "$out")"
  emit cargo-audit "$(status_for "$(jq 'length' <<<"$findings")")" "" "$findings"
}

scan_dependencies() {
  collect_lockfiles
  if [[ ${#LOCKS[@]} -eq 0 ]]; then
    emit dependency-audit unavailable "no supported lockfile found" '[]'; return
  fi
  if command -v osv-scanner >/dev/null 2>&1; then audit_osv; return; fi
  local l
  for l in "${LOCKS[@]}"; do
    case "$(basename -- "$l")" in
      package-lock.json|npm-shrinkwrap.json)
        if command -v npm >/dev/null 2>&1; then audit_npm "$l"
        else emit dependency-audit unavailable "no audit tool for $l (install osv-scanner or npm)" '[]'; fi ;;
      requirements*.txt)
        if command -v pip-audit >/dev/null 2>&1; then audit_pip "$l"
        else emit dependency-audit unavailable "no audit tool for $l (install osv-scanner or pip-audit)" '[]'; fi ;;
      Cargo.lock)
        if command -v cargo-audit >/dev/null 2>&1 && command -v cargo >/dev/null 2>&1; then audit_cargo "$l"
        else emit dependency-audit unavailable "no audit tool for $l (install osv-scanner or cargo-audit)" '[]'; fi ;;
      *) emit dependency-audit unavailable "no audit tool for $l (install osv-scanner)" '[]' ;;
    esac
  done
}

scan_gitleaks
scan_semgrep
scan_dependencies

RESULT="$(jq -cs '{scanners: .}' "$TMP/results.jsonl")"

if [[ "$JSON" == true ]]; then
  printf '%s\n' "$RESULT"
else
  jq -r '.scanners[] |
    "\(.name): \(.status)\(if .reason then " (\(.reason))" else "" end)\(if (.findings|length) > 0 then " — \(.findings|length) finding(s)" else "" end)",
    (.findings[] | "  \(.file):\(.line // "-") [\(.rule)] \(.severity): \(.message)")' <<<"$RESULT"
fi

n_findings="$(jq '[.scanners[].findings | length] | add // 0' <<<"$RESULT")"
n_error="$(jq '[.scanners[] | select(.status == "error")] | length' <<<"$RESULT")"
n_ran="$(jq '[.scanners[] | select(.status == "ran" or .status == "findings")] | length' <<<"$RESULT")"

if [[ "$n_findings" -gt 0 ]]; then exit 1; fi
if [[ "$n_error" -gt 0 ]]; then exit 4; fi
if [[ "$n_ran" -eq 0 ]]; then exit 3; fi
exit 0
