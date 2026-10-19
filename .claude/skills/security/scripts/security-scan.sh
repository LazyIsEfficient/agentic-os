#!/usr/bin/env bash
# security-scan.sh — run whichever deterministic security scanners are installed
# and report their results as reproducible (Tier 0/1) evidence.
#
# Run from the project root (the directory whose files you want scanned):
#   security-scan.sh [--base <ref>] [--paths <path>...] [--json]
#
# Scope (which files are scanned):
#   --base <ref>      files changed between merge-base(<ref>, HEAD) and the working
#                     tree, plus untracked non-ignored files. Deleted files skipped.
#   --paths <p>...    these files; a directory expands to every file under it
#                     (.git pruned). A path that does not exist is a usage error
#                     (exit 2). --paths consumes every following argument until
#                     --json, --base or `--`; everything after `--` is a path.
#                     Prefix a file literally named "--json" as "./--json".
#   (neither)         uncommitted changes vs HEAD plus untracked files.
#   Paths are git-relative to the current directory (`git diff --relative`).
#   Symlinks are resolved; a path whose real location is outside the repo root
#   (git toplevel, else the current directory) is skipped and listed in
#   "skipped", as is a broken symlink.
#
# The scanned tree is UNTRUSTED. Repo-local scanner configuration that could
# suppress findings or redirect network traffic is never honored:
#   gitleaks          `gitleaks dir` per file with --redact (secrets never reach
#                     output), --ignore-gitleaks-allow (inline `gitleaks:allow`
#                     ignored) and an empty --gitleaks-ignore-path (repo
#                     .gitleaksignore ignored). Rules: gitleaks defaults, or
#                     --config "$SECURITY_SCAN_GITLEAKS_CONFIG" when set. A
#                     repo-local .gitleaks.toml / .gitleaksignore is reported in
#                     "notes".
#   semgrep           `semgrep scan` on the in-scope files with --metrics=off and
#                     --disable-nosem (inline `nosemgrep` ignored). Explicit file
#                     targets bypass .semgrepignore (verified semgrep 1.181.0).
#                     Rules come from env SEMGREP_CONFIG (default p/security-audit).
#                     A registry name (p/...) FETCHES RULES FROM THE SEMGREP REGISTRY
#                     over the network. For offline use point it at a local ruleset
#                     you trust: SEMGREP_CONFIG=/path/to/rules.yml (file or dir).
#   dependency audit  over lockfiles in the current directory plus any in-scope
#                     lockfile:
#     osv-scanner     if installed, all lockfiles at once, with --config pointed
#                     at an empty file (repo osv-scanner.toml IgnoredVulns ignored).
#     otherwise:
#     npm audit       package-lock.json / npm-shrinkwrap.json copied with
#                     package.json into a fresh temp dir; run there with empty
#                     --userconfig / --globalconfig and an explicit --registry
#                     (default https://registry.npmjs.org/, override with env
#                     SECURITY_SCAN_NPM_REGISTRY). A repo .npmrc is never read.
#     pip-audit       requirements*.txt, sanitized (option lines such as
#                     --index-url / -r / -c stripped) into a temp copy, run with
#                     --disable-pip --no-deps so no package code is installed or
#                     built — unpinned requirements therefore report `error`.
#     cargo audit     Cargo.lock copied into a fresh temp dir and audited there.
#   osv-scanner and npm audit query online vulnerability databases.
#
# Offline mode (env SECURITY_SCAN_OFFLINE=1 — what the reviewer agents use):
#   semgrep           SEMGREP_CONFIG defaults to the shipped local ruleset
#                     security-scan-semgrep.yml beside this script. A
#                     SEMGREP_CONFIG that is not an existing local file or
#                     directory (e.g. p/security-audit) is reported
#                     `unavailable`, never fetched.
#   dependency audit  every auditor needs an online vulnerability database
#                     (osv-scanner, npm audit, pip-audit, cargo audit), so it is
#                     reported `unavailable` when a lockfile is in scope.
#   gitleaks          unchanged (local rules only).
#
# Tools are looked up on a sanitized PATH: relative entries and entries whose
# real location is inside the repo root or cwd are dropped first, so a planted
# node_modules/.bin/semgrep never runs. A scanner found only there is reported
# `unavailable` ("<tool> found only inside the scanned repo or on a relative
# PATH entry; not run").
#
# Per-scanner status: ran (no findings) | findings | unavailable | error.
#
# --json emits:
#   {"scanners":[{"name","status","reason"?,"notes"?,"findings":[{"file","line",
#                 "rule","severity","message"}]}],
#    "skipped":[{"path","reason"}]}
#   `line` is null for dependency findings; `reason` explains unavailable/error;
#   `notes` lists repo-local config that was deliberately ignored.
#
# Exit codes:
#   0  no findings, and at least one scanner ran
#   1  at least one finding (from any scanner)
#   2  usage error (bad flag, missing --paths entry, --base ref does not resolve,
#      not a git repo, jq missing)
#   3  nothing checked: no file in scope, or no scanner available
#   4  a scanner errored and no scanner produced findings
#
# Requires bash (3.2+ compatible), jq and git (git only for --base / default scope).
# shellcheck disable=SC2016  # single-quoted jq programs use jq variables ($pwd, $file…)
set -euo pipefail

# The caller's PATH may reach into the untrusted tree (node_modules/.bin, ./bin,
# .venv/bin), where a planted gitleaks/semgrep/jq would run and report clean.
# Keep only absolute PATH entries whose real location is outside every given
# dir, so no tool, and nothing a tool execs via PATH, comes from the tree.
# Applied to the cwd now and to the repo root once it is known.
ORIG_PATH="$PATH"
safe_path() { # safe_path <dir>... → $PATH minus relative entries and entries inside a <dir>
  local e real d out="" inside
  local -a entries
  IFS=: read -r -a entries <<<"$PATH"
  for e in ${entries[@]+"${entries[@]}"}; do
    case "$e" in /*) ;; *) continue ;; esac
    real="$(cd -P -- "$e" 2>/dev/null && pwd -P)" || continue
    inside=false
    for d in "$@"; do case "$real/" in "$d"/*) inside=true ;; esac; done
    [[ "$inside" == true ]] || out="${out:+$out:}$e"
  done
  printf '%s' "$out"
}
PATH="$(safe_path "$(pwd -P)")"
# not_found <tool> → the `unavailable` reason for a tool missing from the safe PATH.
not_found() {
  if PATH="$ORIG_PATH" command -v "$1" >/dev/null 2>&1; then
    printf '%s found only inside the scanned repo or on a relative PATH entry; not run' "$1"
  else
    printf '%s not installed' "$1"
  fi
}

OFFLINE=false
[[ "${SECURITY_SCAN_OFFLINE:-}" == 1 ]] && OFFLINE=true
if [[ "$OFFLINE" == true ]]; then
  SEMGREP_CONFIG="${SEMGREP_CONFIG:-$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/security-scan-semgrep.yml}"
else
  SEMGREP_CONFIG="${SEMGREP_CONFIG:-p/security-audit}"
fi
NPM_REGISTRY="${SECURITY_SCAN_NPM_REGISTRY:-https://registry.npmjs.org/}"
GITLEAKS_CONFIG_OVERRIDE="${SECURITY_SCAN_GITLEAKS_CONFIG:-}"

usage() {
  echo "usage: security-scan.sh [--base <ref>] [--paths <path>...] [--json]" >&2
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

IN_GIT=false
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && IN_GIT=true
PWDP="$(pwd -P)"
if [[ "$IN_GIT" == true ]]; then
  ROOT="$(cd -P -- "$(git rev-parse --show-toplevel)" && pwd -P)"
else
  ROOT="$PWDP"
fi
PATH="$(safe_path "$ROOT" "$PWDP")"

# Collect candidate paths NUL-safely (git paths are untrusted: spaces, newlines,
# leading dashes).
if [[ "$PATHS_GIVEN" == false ]]; then
  [[ "$IN_GIT" == true ]] || { echo "security-scan: not a git work tree (use --paths)" >&2; exit 2; }
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
else
  # Missing paths are a usage error; directories expand to the files under them.
  EXPANDED=()
  for f in ${FILES[@]+"${FILES[@]}"}; do
    case "$f" in /*|./*) ;; *) f="./$f" ;; esac
    if [[ ! -e "$f" && ! -L "$f" ]]; then
      echo "security-scan: --paths entry does not exist: ${f#./}" >&2; exit 2
    fi
    if [[ -d "$f" && ! -L "$f" ]]; then
      while IFS= read -r -d '' g; do EXPANDED+=("$g"); done < <(
        find "$f" -name .git -prune -o \( -type f -o -type l \) -print0)
    else
      EXPANDED+=("$f")
    fi
  done
  FILES=(${EXPANDED[@]+"${EXPANDED[@]}"})
fi

# Physical absolute path of $1 with every symlink followed; fails on loops or
# a missing parent directory. $1 always starts with "./" or "/".
resolve() {
  local p="$1" n=0 link dir
  while [[ -L "$p" ]]; do
    n=$((n + 1)); [[ "$n" -le 40 ]] || return 1
    link="$(readlink "$p")" || return 1
    case "$link" in /*) p="$link" ;; *) p="$(dirname "$p")/$link" ;; esac
  done
  dir="$(cd -P -- "$(dirname "$p")" 2>/dev/null && pwd -P)" || return 1
  printf '%s/%s\n' "$dir" "$(basename "$p")"
}

# in_root <path>: true when <path> exists and its real location is inside ROOT.
in_root() {
  local r
  r="$(resolve "$1")" || return 1
  [[ -e "$r" ]] || return 1
  case "$r" in "$ROOT"/*) return 0 ;; esac
  return 1
}

: > "$TMP/skipped.jsonl"
skip() {
  jq -cn --arg path "${1#./}" --arg reason "$2" '{path:$path, reason:$reason}' >> "$TMP/skipped.jsonl"
}

# Normalize: resolve symlinks, keep regular files inside the repo root, express
# them as ./relative (leading-dash safe) when under the current dir, de-duplicate.
SCAN=()
for f in ${FILES[@]+"${FILES[@]}"}; do
  case "$f" in /*|./*) ;; *) f="./$f" ;; esac
  if ! real="$(resolve "$f")" || [[ ! -e "$real" ]]; then
    skip "$f" "broken symlink or unresolvable path"; continue
  fi
  case "$real" in
    "$ROOT"/*) ;;
    *) skip "$f" "resolves outside the repo root"; continue ;;
  esac
  [[ -f "$real" ]] || continue
  case "$real" in "$PWDP"/*) real="./${real#"$PWDP"/}" ;; esac
  dup=false
  for s in ${SCAN[@]+"${SCAN[@]}"}; do [[ "$s" == "$real" ]] && { dup=true; break; }; done
  [[ "$dup" == true ]] || SCAN+=("$real")
done

: > "$TMP/results.jsonl"

# emit <name> <status> <reason> <findings-json-array> [notes-json-array]
# Reasons quote scanner stderr, which can name absolute paths. Literal
# substitutions, longest first: temp dir → <tmp>, repo root / cwd → relative,
# $HOME → ~. Empty and "/" values are skipped (a HOME=/ must not rewrite every "/").
SCRUB_SUBS="$(jq -cn --arg t "$TMP" --arg tp "$(cd -P -- "$TMP" && pwd -P)" --arg r "$ROOT" \
  --arg p "$PWDP" --arg l "$PWD" --arg h "${HOME:-}" '
  def ok: length > 1;
  [ (if ($t|ok) then [$t, "<tmp>"] else empty end), (if ($tp|ok) then [$tp, "<tmp>"] else empty end),
    (if ($r|ok) then [$r + "/", ""], [$r, "."] else empty end),
    (if ($p|ok) then [$p + "/", ""] else empty end), (if ($l|ok) then [$l + "/", ""] else empty end),
    (if ($h|ok) then [$h, "~"] else empty end) ]')"

emit() {
  jq -cn --arg name "$1" --arg status "$2" --arg reason "$3" --argjson findings "$4" \
    --argjson notes "${5:-[]}" --argjson subs "$SCRUB_SUBS" \
    'def scrub: reduce $subs[] as $s (.; split($s[0]) | join($s[1]));
     {name:$name, status:$status, findings:$findings}
     + (if $reason == "" then {} else {reason:($reason | scrub)} end)
     + (if ($notes | length) == 0 then {} else {notes:$notes} end)' \
    >> "$TMP/results.jsonl"
}

notes_json() { # notes_json <note>... → JSON array (de-duplicated)
  if [[ $# -eq 0 ]]; then echo '[]'; else printf '%s\n' "$@" | jq -R . | jq -cs 'unique'; fi
}

# in_dir <dir> <name> → "name" for ".", else "dir/name" (no leading ./)
in_dir() { case "$1" in .|"") printf '%s' "$2" ;; *) printf '%s/%s' "${1#./}" "$2" ;; esac; }

# Strip the current dir (logical or physical) or "./" so findings report
# project-relative paths.
REL_FILTER='def rel: if type == "string" then (ltrimstr($pwd + "/") | ltrimstr($pwdp + "/") | ltrimstr("./")) else . end;'
jqr() { jq -c --arg pwd "$PWD" --arg pwdp "$PWDP" "$@"; }

status_for() { if [[ "$1" -gt 0 ]]; then echo findings; else echo ran; fi; }

# jq: escape control characters (C0, DEL, C1) as \xNN.
TEXT_ESC='def hex2: [(. / 16 | floor), (. % 16)] | map("0123456789abcdef"[.:(. + 1)]) | add;
  def esc: tostring | [explode[] | if (. < 32) or (. >= 127 and . < 160)
    then ("\\x" + hex2 | explode[]) else . end] | implode;'

finish() {
  local result
  result="$(jq -cn --slurpfile s "$TMP/results.jsonl" --slurpfile k "$TMP/skipped.jsonl" \
    '{scanners: $s, skipped: $k}')"
  if [[ "$JSON" == true ]]; then
    printf '%s\n' "$result"
  else
    # Repo-controlled text (paths, messages) is escaped: C0/C1 control chars and
    # DEL become \xNN, so no newline/CR/ESC reaches the terminal, and every line
    # starts with "security-scan: " so none can begin with a `::` workflow command.
    jq -r "$TEXT_ESC"'
      (.scanners[] |
        "\(.name | esc): \(.status)\(if .reason then " (\(.reason | esc))" else "" end)\(if (.findings|length) > 0 then " — \(.findings|length) finding(s)" else "" end)",
        (.notes[]? | "  note: \(esc)"),
        (.findings[] | "  \(.file | esc):\(.line // "-") [\(.rule | esc)] \(.severity | esc): \(.message | esc)")),
      (.skipped[] | "skipped: \(.path | esc) (\(.reason | esc))"),
      (if (.scanners | length) == 0 then "nothing in scope — no files checked" else empty end)
      | "security-scan: " + .' <<<"$result"
  fi
  local n_findings n_error n_ran
  n_findings="$(jq '[.scanners[].findings | length] | add // 0' <<<"$result")"
  n_error="$(jq '[.scanners[] | select(.status == "error")] | length' <<<"$result")"
  n_ran="$(jq '[.scanners[] | select(.status == "ran" or .status == "findings")] | length' <<<"$result")"
  if [[ "$n_findings" -gt 0 ]]; then exit 1; fi
  if [[ "$n_error" -gt 0 ]]; then exit 4; fi
  if [[ "$n_ran" -eq 0 ]]; then exit 3; fi
  exit 0
}

# Nothing in scope → nothing checked (exit 3), distinct from "clean" (exit 0).
[[ ${#SCAN[@]} -gt 0 ]] || finish

# ── gitleaks ──────────────────────────────────────────────────────────────────
scan_gitleaks() {
  if ! command -v gitleaks >/dev/null 2>&1; then
    emit gitleaks unavailable "$(not_found gitleaks)" '[]'; return
  fi
  local cfg=() notes=() d rel n
  [[ -n "$GITLEAKS_CONFIG_OVERRIDE" ]] && cfg=(--config "$GITLEAKS_CONFIG_OVERRIDE")
  for d in "$ROOT" "$PWDP"; do
    rel="${d#"$ROOT"}"; rel="${rel#/}"
    for n in .gitleaks.toml .gitleaksignore; do
      [[ -f "$d/$n" ]] && notes+=("ignored repo-local $(in_dir "$rel" "$n")")
    done
  done
  local nj; nj="$(notes_json ${notes[@]+"${notes[@]}"})"
  mkdir -p "$TMP/gitleaks-ignore"
  local f i=0 all="$TMP/gitleaks-all.json"
  echo '[]' > "$all"
  for f in "${SCAN[@]}"; do
    i=$((i + 1))
    local report="$TMP/gitleaks-$i.json"
    # --exit-code 0: leaks exit 0, so any nonzero exit is a genuine error.
    if ! gitleaks dir --no-banner --redact --exit-code 0 --log-level error \
        --ignore-gitleaks-allow --gitleaks-ignore-path "$TMP/gitleaks-ignore" \
        ${cfg[@]+"${cfg[@]}"} --report-format json --report-path "$report" -- "$f" \
        >/dev/null 2>"$TMP/gitleaks.err"; then
      emit gitleaks error "gitleaks failed on $f: $(head -c 300 "$TMP/gitleaks.err")" '[]' "$nj"; return
    fi
    if ! jq -e 'type == "array"' "$report" >/dev/null 2>&1; then
      emit gitleaks error "gitleaks produced unparseable report for $f" '[]' "$nj"; return
    fi
    jq -s '.[0] + .[1]' "$all" "$report" > "$all.new" && mv "$all.new" "$all"
  done
  local findings
  findings="$(jqr "$REL_FILTER"'
    [.[] | {file: (.File | rel), line: .StartLine, rule: .RuleID,
            severity: "HIGH", message: .Description}]' "$all")"
  emit gitleaks "$(status_for "$(jq 'length' <<<"$findings")")" "" "$findings" "$nj"
}

# ── semgrep ───────────────────────────────────────────────────────────────────
scan_semgrep() {
  if ! command -v semgrep >/dev/null 2>&1; then
    emit semgrep unavailable "$(not_found semgrep)" '[]'; return
  fi
  if [[ "$OFFLINE" == true && ! -e "$SEMGREP_CONFIG" ]]; then
    emit semgrep unavailable "offline mode: SEMGREP_CONFIG is not a local file or directory ($SEMGREP_CONFIG)" '[]'; return
  fi
  local out="$TMP/semgrep.json" rc=0
  # Without --error, semgrep exits 0 even with findings; nonzero means failure.
  semgrep scan --config "$SEMGREP_CONFIG" --json --quiet --metrics=off \
    --disable-version-check --disable-nosem -- "${SCAN[@]}" >"$out" 2>"$TMP/semgrep.err" || rc=$?
  if [[ "$rc" -ne 0 ]] || ! jq -e '.results | type == "array"' "$out" >/dev/null 2>&1; then
    local msg
    msg="$(jq -r '[.errors[]?.message] | join("; ")' "$out" 2>/dev/null || true)"
    [[ -n "$msg" ]] || msg="$(head -c 300 "$TMP/semgrep.err")"
    emit semgrep error "semgrep exited $rc: $msg" '[]'; return
  fi
  # semgrep prefixes rule ids from a local ruleset with a mangled form of its
  # directory path ("/" → ".", spaces dropped; verified semgrep 1.181.0), so the
  # prefix cannot be rebuilt reliably. For a local config, keep only the shipped
  # ruleset's own id, `aos.<lang>.<rule>` — the final three dot-segments — so
  # ids are stable across install locations and never leak the home path.
  local local_cfg=false
  [[ -e "$SEMGREP_CONFIG" ]] && local_cfg=true
  local findings
  findings="$(jqr --argjson lc "$local_cfg" "$REL_FILTER"'
    [.results[] | {file: (.path | rel), line: .start.line,
                   rule: (.check_id as $id
                          | if $lc then ($id | capture("(?:^|\\.)(?<r>aos\\.[a-z0-9-]+\\.[a-z0-9-]+)$").r // $id)
                            else $id end),
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
  local f real
  for f in ./* ./.[!.]*; do
    { [[ -f "$f" ]] && is_lockfile "$f"; } || continue
    # Same symlink rule as in-scope files: never read outside the repo root.
    real="$(resolve "$f")" || continue
    case "$real" in "$ROOT"/*) add_lock "$f" ;; *) skip "$f" "lockfile resolves outside the repo root" ;; esac
  done
  for f in "${SCAN[@]}"; do
    is_lockfile "$f" && add_lock "$f"
  done
  return 0
}

# Last non-empty error text: npm JSON .error.summary/.message, else stderr tail.
npm_reason() {
  local r
  r="$(jq -r '[.error.summary?, .error.detail?, .message?] | map(select(type == "string" and . != "")) | first // empty' "$1" 2>/dev/null || true)"
  [[ -n "$r" ]] || r="$(tail -c 300 "$2")"
  printf '%s' "$r"
}

audit_osv() {
  local args=() l out="$TMP/osv.json" rc=0 notes=()
  : > "$TMP/osv-empty.toml"
  for l in "${LOCKS[@]}"; do
    args+=(-L "$l")
    [[ -f "$(dirname -- "$l")/osv-scanner.toml" ]] &&
      notes+=("ignored repo-local $(in_dir "$(dirname -- "$l")" osv-scanner.toml)")
  done
  local nj; nj="$(notes_json ${notes[@]+"${notes[@]}"})"
  # `scan` defaults to the `source` subcommand (osv-scanner v2). --config forces
  # an empty config so a repo osv-scanner.toml cannot ignore vulnerabilities.
  # Exit: 0 clean, 1 vulns, 128 no packages found, anything else is an error.
  osv-scanner scan --format json --verbosity error --config "$TMP/osv-empty.toml" "${args[@]}" \
    >"$out" 2>"$TMP/osv.err" || rc=$?
  if [[ "$rc" -eq 128 ]]; then emit osv-scanner ran "no packages found in lockfiles" '[]' "$nj"; return; fi
  if [[ "$rc" -ne 0 && "$rc" -ne 1 ]] || ! jq -e '.results | type == "array"' "$out" >/dev/null 2>&1; then
    emit osv-scanner error "osv-scanner exited $rc: $(head -c 300 "$TMP/osv.err")" '[]' "$nj"; return
  fi
  local findings
  findings="$(jqr "$REL_FILTER"'
    [.results[] | (.source.path | rel) as $file | .packages[]? |
      .package as $p | .vulnerabilities[]? |
      {file: $file, line: null, rule: .id,
       severity: (.database_specific.severity // "UNKNOWN"),
       message: ("\($p.name)@\($p.version): \(.summary // .details // "vulnerability")")}]' "$out")"
  emit osv-scanner "$(status_for "$(jq 'length' <<<"$findings")")" "" "$findings" "$nj"
}

audit_npm() {
  local lock="$1" dir out rc=0 iso notes=()
  dir="$(dirname -- "$lock")"; out="$TMP/npm-audit.json"
  # Isolate from the untrusted tree: only package.json + lockfile are copied, and
  # npm gets empty user/global configs and an explicit registry, so no repo or
  # user .npmrc (registry redirects, ${ENV} token interpolation) is ever read.
  iso="$(mktemp -d "$TMP/npm.XXXXXX")"
  [[ -f "$dir/.npmrc" ]] && notes+=("ignored repo-local $(in_dir "$dir" .npmrc)")
  local nj; nj="$(notes_json ${notes[@]+"${notes[@]}"})"
  # Every copied manifest passes the same symlink containment check as lockfiles.
  if [[ -e "$dir/package.json" || -L "$dir/package.json" ]]; then
    if ! in_root "$dir/package.json"; then
      skip "$dir/package.json" "manifest resolves outside the repo root"
      emit npm-audit error "$(in_dir "$dir" package.json) resolves outside the repo root; not copied" '[]' "$nj"; return
    fi
    if ! cp -- "$dir/package.json" "$iso/package.json" 2>"$TMP/cp.err"; then
      emit npm-audit error "cannot copy $(in_dir "$dir" package.json): $(head -c 300 "$TMP/cp.err")" '[]' "$nj"; return
    fi
  fi
  if ! cp -- "$lock" "$iso/$(basename -- "$lock")" 2>"$TMP/cp.err"; then
    emit npm-audit error "cannot copy $lock: $(head -c 300 "$TMP/cp.err")" '[]' "$nj"; return
  fi
  : > "$TMP/npm-userconfig"; : > "$TMP/npm-globalconfig"
  # npm audit exits 1 when vulnerabilities exist; trust the JSON shape instead.
  (cd -- "$iso" && npm audit --json --package-lock-only \
     --userconfig "$TMP/npm-userconfig" --globalconfig "$TMP/npm-globalconfig" \
     --registry "$NPM_REGISTRY") >"$out" 2>"$TMP/npm.err" || rc=$?
  if ! jq -e '.vulnerabilities | type == "object"' "$out" >/dev/null 2>&1; then
    emit npm-audit error "npm audit exited $rc on $lock: $(npm_reason "$out" "$TMP/npm.err")" '[]' "$nj"; return
  fi
  local findings
  findings="$(jqr --arg file "$lock" "$REL_FILTER"'
    [.vulnerabilities[] | . as $v |
      ([.via[] | objects] | first) as $adv |
      {file: ($file | rel), line: null,
       rule: (if $adv then ($adv.url // ($adv.source | tostring)) else "npm-audit" end),
       severity: ($v.severity // "UNKNOWN" | ascii_upcase),
       message: ("\($v.name): \(if $adv then $adv.title else "vulnerable via \($v.via | join(", "))" end)")}]' "$out")"
  emit npm-audit "$(status_for "$(jq 'length' <<<"$findings")")" "" "$findings" "$nj"
}

audit_pip() {
  local lock="$1" out="$TMP/pip-audit.json" rc=0 iso stripped nj
  # pip-audit 2.10.1 in --disable-pip --no-deps mode was observed NOT to contact
  # an --index-url / --extra-index-url given inside the requirements file; option
  # lines are stripped anyway (defense in depth, and so -r / -c includes cannot
  # pull in files from outside the repo).
  iso="$(mktemp -d "$TMP/pip.XXXXXX")"
  if ! awk '{ t = $0; sub(/^[ \t]+/, "", t) } t ~ /^-/ { next } { print }' "$lock" > "$iso/requirements.txt" 2>"$TMP/cp.err"; then
    emit pip-audit error "cannot read $lock: $(head -c 300 "$TMP/cp.err")" '[]'; return
  fi
  stripped="$(awk '{ t = $0; sub(/^[ \t]+/, "", t) } t ~ /^-/ { n++ } END { print n + 0 }' "$lock")"
  if [[ "$stripped" -gt 0 ]]; then
    nj="$(notes_json "stripped $stripped option line(s) (e.g. --index-url, -r) from ${lock#./}")"
  else
    nj='[]'
  fi
  # --disable-pip --no-deps: never install/build packages from an untrusted file.
  (cd -- "$iso" && pip-audit -r ./requirements.txt -f json --progress-spinner off --disable-pip --no-deps) \
    >"$out" 2>"$TMP/pip.err" || rc=$?
  if ! jq -e '.dependencies | type == "array"' "$out" >/dev/null 2>&1; then
    emit pip-audit error "pip-audit exited $rc on $lock: $(tail -c 300 "$TMP/pip.err")" '[]' "$nj"; return
  fi
  local findings
  findings="$(jqr --arg file "$lock" "$REL_FILTER"'
    [.dependencies[] | . as $d | .vulns[]? |
      {file: ($file | rel), line: null, rule: .id, severity: "UNKNOWN",
       message: ("\($d.name)@\($d.version): \(.description // .id)")}]' "$out")"
  emit pip-audit "$(status_for "$(jq 'length' <<<"$findings")")" "" "$findings" "$nj"
}

audit_cargo() {
  local lock="$1" out="$TMP/cargo-audit.json" rc=0 iso
  # UNVERIFIED: `cargo audit --json` output shape (.vulnerabilities.list[] with
  # .advisory and .package) is taken from rustsec conventions, not run locally.
  # A shape mismatch reports `error`, never a silent pass. The lockfile is audited
  # from a fresh temp dir so no repo .cargo/ config is in reach (UNVERIFIED
  # whether cargo-audit would read one).
  iso="$(mktemp -d "$TMP/cargo.XXXXXX")"
  if ! cp -- "$lock" "$iso/Cargo.lock" 2>"$TMP/cp.err"; then
    emit cargo-audit error "cannot copy $lock: $(head -c 300 "$TMP/cp.err")" '[]'; return
  fi
  (cd -- "$iso" && cargo audit --json --file ./Cargo.lock) >"$out" 2>"$TMP/cargo.err" || rc=$?
  if ! jq -e '.vulnerabilities.list | type == "array"' "$out" >/dev/null 2>&1; then
    emit cargo-audit error "cargo audit exited $rc on $lock: $(tail -c 300 "$TMP/cargo.err")" '[]'; return
  fi
  local findings
  findings="$(jqr --arg file "$lock" "$REL_FILTER"'
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
  if [[ "$OFFLINE" == true ]]; then
    emit dependency-audit unavailable "offline mode: dependency audits query online vulnerability databases" '[]'; return
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
finish
