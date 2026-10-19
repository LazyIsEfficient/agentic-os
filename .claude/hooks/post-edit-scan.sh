#!/usr/bin/env bash
# PostToolUse hook on Edit|Write|MultiEdit: scans the ONE file Claude just
# edited for committed-looking secrets and broken syntax, and feeds findings
# straight back to the model (issue #259).
#
# Checks (each only when its tool is installed; no network, no project linters):
#   secrets  gitleaks (if installed) on that file with --redact, the repo's
#            .gitleaksignore and inline `gitleaks:allow` ignored, GITLEAKS_CONFIG*
#            env unset (the edited tree is untrusted), killed after
#            GITLEAKS_TIMEOUT seconds. PLUS, always, a built-in high-signal
#            regex set (below) so consumers without gitleaks get coverage.
#            Lockfiles skip the regex set. Values are never printed: only
#            `file:line rule`.
#   syntax   bash -n (*.sh), jq empty (*.json), python3 py_compile (*.py) with
#            the bytecode redirected to a temp dir, so no __pycache__ lands in
#            the project.
#
# Scope: the file in tool_input.file_path only. Skipped silently when it is
# missing, not a regular file, over 1 MB, or (after resolving symlinks) outside
# the project root: $CLAUDE_PROJECT_DIR, else the git toplevel, else cwd.
#
# Output contract (verified at https://code.claude.com/docs/en/hooks#posttooluse):
#   findings -> stdout {"decision":"block","reason":"..."}, exit 0. For
#               PostToolUse, "block" adds the reason next to the tool result;
#               the edit itself already happened and stays.
#   clean    -> no output, exit 0.
# A missing scanner is never reported (no per-edit noise).
#
# FAILS OPEN, unlike block-general-purpose.sh. A PostToolUse hook runs after
# the write and cannot undo it, so failing closed gains nothing and would only
# break editing. Missing jq, malformed stdin, or a scanner error/timeout prints
# one line to stderr and exits 0.

set -uo pipefail

MAX_BYTES=1048576
GITLEAKS_TIMEOUT=5

note() { printf 'post-edit-scan: %s\n' "$1" >&2; exit 0; }

input=$(< /dev/stdin)
command -v jq >/dev/null 2>&1 || note "jq not installed; skipping scan"

file=$(printf '%s' "$input" | jq -r '
  if (.tool_input.file_path | type) == "string" then .tool_input.file_path
  else error("no file_path") end' 2>/dev/null) || note "could not parse hook payload; skipping scan"
[ -n "$file" ] || note "empty file_path; skipping scan"

# Physical path with every symlink followed (bash 3.2 safe; no realpath).
resolve() {
  local p="$1" n=0 link dir
  while [ -L "$p" ]; do
    n=$((n + 1)); [ "$n" -le 40 ] || return 1
    link=$(readlink "$p") || return 1
    case "$link" in /*) p="$link" ;; *) p="$(dirname "$p")/$link" ;; esac
  done
  dir=$(cd -P -- "$(dirname "$p")" 2>/dev/null && pwd -P) || return 1
  printf '%s/%s\n' "$dir" "$(basename "$p")"
}

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  root=$(cd -P -- "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)
fi
if [ -z "$root" ]; then
  root=$(git rev-parse --show-toplevel 2>/dev/null) && root=$(cd -P -- "$root" && pwd -P)
fi
[ -n "$root" ] || root=$(pwd -P)

real=$(resolve "$file") || exit 0
case "$real" in "$root"/*) ;; *) exit 0 ;; esac
[ -f "$real" ] || exit 0
size=$(wc -c < "$real" | tr -d ' ')
[ "$size" -le "$MAX_BYTES" ] 2>/dev/null || exit 0
rel="${real#"$root"/}"

tmp=$(mktemp -d 2>/dev/null) || note "mktemp failed; skipping scan"
trap 'rm -rf "$tmp"' EXIT
findings="$tmp/findings"
: > "$findings"

# ── Built-in secret regexes (rule@@@ERE). Matched case-sensitively except the
# generic assignment rule, which is matched with -i.
RULES=(
  'aws-access-key-id@@@(^|[^0-9A-Z])AKIA[0-9A-Z]{16}([^0-9A-Z]|$)'
  'private-key@@@-----BEGIN ([A-Z0-9]+ )*PRIVATE KEY( BLOCK)?-----'
  'github-token@@@gh[pousr]_[A-Za-z0-9]{36,}'
  'slack-token@@@xox[baprs]-[A-Za-z0-9-]{10,}'
  'stripe-live-key@@@sk_live_[0-9A-Za-z]{16,}'
  'google-api-key@@@AIza[0-9A-Za-z_-]{35}'
  'jwt@@@eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
)
GENERIC_RE='(password|passwd|secret|token|api[_-]?key)[a-z0-9_-]*["'"'"']?[[:space:]]*(:|=|:=)[[:space:]]*["'"'"'][^"'"'"'[:space:]]{16,}["'"'"']'

is_placeholder() {
  local m
  m=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$m" in
    *example*|*xxxx*|*changeme*|*change_me*|*placeholder*|*your_*|*your-*|*redacted*|*dummy*) return 0 ;;
    *'<'*'>'*|*'${'*|*'{{'*|*'://'*) return 0 ;;
  esac
  return 1
}

case "$(basename "$real")" in
  package-lock.json|npm-shrinkwrap.json|yarn.lock|pnpm-lock.yaml|bun.lock|Cargo.lock|poetry.lock|Pipfile.lock|Gemfile.lock|composer.lock|go.sum|uv.lock|flake.lock|packages.lock.json) is_lock=1 ;;
  *) is_lock=0 ;;
esac

if [ "$is_lock" -eq 0 ]; then
  for entry in "${RULES[@]}"; do
    rule="${entry%%@@@*}"; re="${entry#*@@@}"
    grep -noIE -- "$re" "$real" 2>/dev/null | while IFS=: read -r ln m; do
      is_placeholder "$m" || printf '%s:%s secret %s\n' "$rel" "$ln" "$rule" >> "$findings"
    done
  done
  grep -inoIE -- "$GENERIC_RE" "$real" 2>/dev/null | while IFS=: read -r ln m; do
    val="${m%[\"\']}"; val="${val##*[\"\']}"
    is_placeholder "$val" && continue
    # Real secrets mix letters and digits; ALL_CAPS_CONSTANT names don't.
    case "$val" in *[0-9]*) ;; *) continue ;; esac
    case "$val" in *[A-Za-z]*) ;; *) continue ;; esac
    printf '%s:%s secret generic-secret-assignment\n' "$rel" "$ln" >> "$findings"
  done
fi

if command -v gitleaks >/dev/null 2>&1; then
  mkdir -p "$tmp/gl-ignore"
  env -u GITLEAKS_CONFIG -u GITLEAKS_CONFIG_TOML gitleaks dir --no-banner --redact \
    --exit-code 0 --log-level error --ignore-gitleaks-allow \
    --gitleaks-ignore-path "$tmp/gl-ignore" --report-format json \
    --report-path "$tmp/gl.json" -- "$real" >/dev/null 2>&1 &
  gl_pid=$!
  # Watchdog fds go to /dev/null so a lingering sleep never holds the hook's stdout.
  ( sleep "$GITLEAKS_TIMEOUT"; kill "$gl_pid" 2>/dev/null ) >/dev/null 2>&1 &
  wd_pid=$!
  wait "$gl_pid"; gl_rc=$?
  kill "$wd_pid" 2>/dev/null
  if [ "$gl_rc" -eq 0 ] && jq -e 'type == "array"' "$tmp/gl.json" >/dev/null 2>&1; then
    jq -r --arg f "$rel" '.[] | "\($f):\(.StartLine) secret gitleaks:\(.RuleID)"' "$tmp/gl.json" >> "$findings"
  else
    printf 'post-edit-scan: gitleaks failed or timed out on %s; regex scan still ran\n' "$rel" >&2
  fi
fi

# ── Syntax checks. Only the first error line is kept; the full path is
# replaced by the project-relative one.
first_line() { head -n 1 | sed "s#$real#$rel#g" | cut -c1-200; }
case "$real" in
  *.sh)
    if command -v bash >/dev/null 2>&1; then
      err=$(bash -n "$real" 2>&1 >/dev/null) || printf '%s syntax bash -n: %s\n' "$rel" "$(printf '%s' "$err" | first_line)" >> "$findings"
    fi ;;
  *.json)
    err=$(jq empty "$real" 2>&1 >/dev/null) || printf '%s syntax jq: %s\n' "$rel" "$(printf '%s' "$err" | first_line)" >> "$findings" ;;
  *.py)
    if command -v python3 >/dev/null 2>&1; then
      # Report only "line N" and the final error line: py_compile echoes the
      # offending source line, which could itself hold a secret.
      if ! err=$(python3 -I -X pycache_prefix="$tmp/pyc" -m py_compile "$real" 2>&1 >/dev/null); then
        pl=$(printf '%s\n' "$err" | grep -oE 'line [0-9]+' | tail -n 1)
        pm=$(printf '%s\n' "$err" | grep -E '^[A-Za-z]+(Error|Exception)' | tail -n 1 | cut -c1-200)
        printf '%s syntax python: %s %s\n' "$rel" "${pl:-}" "${pm:-compile failed}" >> "$findings"
      fi
    fi ;;
esac

[ -s "$findings" ] || exit 0

reason="post-edit-scan found problems in the file you just edited ($rel). The edit was applied; fix these now:
$(sort -u "$findings" | sed 's/^/- /')"
if grep -q ' secret ' "$findings"; then
  reason="$reason
For secrets: remove the value from the file (read it from an env var or secret store); if it was ever real, treat it as leaked and rotate it. Values are redacted here on purpose."
fi
jq -cn --arg r "$reason" '{decision:"block", reason:$r}'
exit 0
