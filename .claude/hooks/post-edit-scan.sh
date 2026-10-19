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
#   syntax   bash -n (*.sh), jq empty (*.json, except JSONC files such as
#            tsconfig*.json and .vscode/*.json), python3 py_compile (*.py) with
#            the bytecode redirected to a temp dir, so no __pycache__ lands in
#            the project. Only the line number and error class are reported:
#            checker messages can quote file content (a secret).
#
# Scope: the file in tool_input.file_path only. Skipped silently when it is
# missing, not a regular file, over 1 MB, has an unsafe character in its path
# (a control character such as newline or tab, a Unicode format character such
# as zero-width or bidi, or U+2028/U+2029; such a name could forge or hide
# lines in the model-facing reason), or (after resolving symlinks) is outside the project
# root: $CLAUDE_PROJECT_DIR, else the git toplevel, else cwd.
#
# Output contract (verified at https://code.claude.com/docs/en/hooks#posttooluse):
#   findings -> stdout {"decision":"block","reason":"..."}, exit 0. For
#               PostToolUse, "block" adds the reason next to the tool result;
#               the edit itself already happened and stays. The first hit of
#               every rule is always listed (one flooded rule cannot hide
#               another); repeat hits are capped at MAX_FINDINGS, a rule's
#               scan stops once the cap is hit, and the reason says so.
#   clean    -> no output, exit 0.
# A missing scanner is never reported (no per-edit noise).
#
# FAILS OPEN, unlike block-general-purpose.sh. A PostToolUse hook runs after
# the write and cannot undo it, so failing closed gains nothing and would only
# break editing. Missing jq, malformed stdin, or a scanner error/timeout prints
# one line to stderr and exits 0.

set -uo pipefail

MAX_BYTES=1048576
MAX_FINDINGS=20
GITLEAKS_TIMEOUT=5

note() { printf 'post-edit-scan: %s\n' "$1" >&2; exit 0; }

input=$(< /dev/stdin)
command -v jq >/dev/null 2>&1 || note "jq not installed; skipping scan"

# Characters that could forge or hide lines in the model-facing reason: C0/C1
# controls (Cc), format characters such as zero-width and bidi overrides (Cf),
# and the Unicode line/paragraph separators U+2028/U+2029 (Zl, Zp).
UNSAFE_RE='[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]'

# "skip" for a path holding an unsafe character; it is never echoed.
file=$(printf '%s' "$input" | jq -r --arg re "$UNSAFE_RE" '
  if (.tool_input.file_path | type) != "string" then error("no file_path")
  elif (.tool_input.file_path | test($re)) then "skip"
  else .tool_input.file_path end' 2>/dev/null) || note "could not parse hook payload; skipping scan"
[ -n "$file" ] || note "empty file_path; skipping scan"
[ "$file" = "skip" ] && exit 0

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
# A symlink target or the root itself may carry unsafe characters too. A jq
# error counts as unsafe.
case "$real" in *[[:cntrl:]]*) exit 0 ;; esac
printf '%s' "$real" | jq -Rse --arg re "$UNSAFE_RE" 'test($re) | not' >/dev/null 2>&1 || exit 0
[ -f "$real" ] || exit 0
size=$(wc -c < "$real" | tr -d ' ')
[ "$size" -le "$MAX_BYTES" ] 2>/dev/null || exit 0
rel="${real#"$root"/}"

tmp=$(mktemp -d 2>/dev/null) || note "mktemp failed; skipping scan"
trap 'rm -rf "$tmp"' EXIT
# The first hit of each rule always goes to $first, so a flood of one rule
# cannot hide another. Repeat hits go to $extra, capped at MAX_FINDINGS.
first="$tmp/first"; extra="$tmp/extra"
: > "$first"; : > "$extra"
seen=" "
extras=0
capped=0

# hit <rule> <finding>: returns 1 once this rule can record nothing more, so
# the caller stops reading its matches.
hit() {
  case "$seen" in
    *" $1 "*)
      [ "$extras" -lt "$MAX_FINDINGS" ] || { capped=1; return 1; }
      printf '%s\n' "$2" >> "$extra"; extras=$((extras + 1)) ;;
    *) seen="$seen$1 "; printf '%s\n' "$2" >> "$first" ;;
  esac
  return 0
}

# ── Built-in secret regexes (rule@@@ERE), matched case-sensitively.
RULES=(
  'aws-access-key-id@@@(^|[^0-9A-Z])AKIA[0-9A-Z]{16}([^0-9A-Z]|$)'
  'private-key@@@-----BEGIN ([A-Z0-9]+ )*PRIVATE KEY( BLOCK)?-----'
  'github-token@@@gh[pousr]_[A-Za-z0-9]{36,}'
  'slack-token@@@xox[baprs]-[A-Za-z0-9-]{10,}'
  'stripe-live-key@@@sk_live_[0-9A-Za-z]{16,}'
  'openai-api-key@@@sk-proj-[A-Za-z0-9_-]{20,}'
  'anthropic-api-key@@@sk-ant-[a-z0-9]+-[A-Za-z0-9_-]{20,}'
  'google-api-key@@@AIza[0-9A-Za-z_-]{35}'
  'jwt@@@eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
)
# Generic assignment, matched with -i. The key name must END in the keyword
# (optionally plus _key / _secret), so token_url, secretName, tokenCount,
# api_key_header and passwordHash never match. Value: quoted, or unquoted for
# .env / YAML.
Q="[\"']"
GENERIC_RE="(password|passwd|passphrase|secret|token|api[_-]?key|access[_-]?key|private[_-]?key)([_-]?(key|secret))?${Q}?[[:space:]]*(:=|=>|:|=)[[:space:]]*(${Q}[^\"'[:space:]]{16,}${Q}|[^\"'[:space:]#,;(){}<>]{16,})"

shopt -s nocasematch
is_placeholder() {
  case "$1" in
    *example*|*xxxx*|*changeme*|*change_me*|*replace*|*placeholder*|*your_*|*your-*|*redacted*|*dummy*) return 0 ;;
    *'<'*'>'*|*'${'*|*'{{'*|*'://'*) return 0 ;;
  esac
  return 1
}

# Values that look like a real secret: letters AND digits, no path, no
# reference ($VAR, bcrypt/argon hashes), not a dotted identifier (a.b.c).
looks_secret() {
  case "$1" in
    *[0-9]*) ;; *) return 1 ;;
  esac
  case "$1" in
    *[A-Za-z]*) ;; *) return 1 ;;
  esac
  case "$1" in
    *[/[:space:]]*|'$'*) return 1 ;;
  esac
  [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)+$ ]] && return 1
  return 0
}

case "$(basename "$real")" in
  package-lock.json|npm-shrinkwrap.json|yarn.lock|pnpm-lock.yaml|bun.lock|Cargo.lock|poetry.lock|Pipfile.lock|Gemfile.lock|composer.lock|go.sum|uv.lock|flake.lock|packages.lock.json) is_lock=1 ;;
  *) is_lock=0 ;;
esac

if [ "$is_lock" -eq 0 ]; then
  for entry in "${RULES[@]}"; do
    rule="${entry%%@@@*}"; re="${entry#*@@@}"
    while IFS=: read -r ln m; do
      is_placeholder "$m" && continue
      hit "$rule" "$rel:$ln secret $rule" || break
    done < <(grep -noIE -- "$re" "$real" 2>/dev/null)
  done
  while IFS=: read -r ln m; do
    val="${m#*[:=]}"; val="${val#[=>]}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val#[\"\']}"; val="${val%[\"\']}"
    is_placeholder "$val" && continue
    if ! looks_secret "$val"; then
      # AWS secret access keys are 40 base64 chars and often contain / or +,
      # which looks_secret rejects as path-like. The match starts at the
      # keyword, so read the full line to check the key name.
      [[ "$val" =~ ^[A-Za-z0-9/+]{40}$ && "$val" == *[0-9]* ]] || continue
      case "$(sed -n "${ln}p" "$real")" in
        *aws_secret*|*secret_access_key*) ;;
        *) continue ;;
      esac
    fi
    hit generic-secret-assignment "$rel:$ln secret generic-secret-assignment" || break
  done < <(grep -inoIE -- "$GENERIC_RE" "$real" 2>/dev/null)
fi
shopt -u nocasematch

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
    while IFS=$'\t' read -r grule gline; do
      hit "gitleaks:$grule" "$gline" || true
    done < <(jq -r --arg f "$rel" '.[] | "\(.RuleID)\t\($f):\(.StartLine) secret gitleaks:\(.RuleID)"' "$tmp/gl.json")
  else
    printf 'post-edit-scan: gitleaks failed or timed out on %s; regex scan still ran\n' "$rel" >&2
  fi
fi

# ── Syntax checks. Only "line N" and the error class are kept; checker
# messages are never echoed (they can quote the offending source).
line_of() { grep -oE 'line [0-9]+(, column [0-9]+)?' | head -n 1; }
is_jsonc=0
case "$real" in
  *.jsonc|*/.vscode/*.json) is_jsonc=1 ;;
esac
case "$(basename "$real")" in
  tsconfig*.json|jsconfig*.json|devcontainer.json|.devcontainer.json|.eslintrc*.json|biome.json) is_jsonc=1 ;;
esac
case "$real" in
  *.sh)
    if err=$(bash -n "$real" 2>&1 >/dev/null); then :; else
      pl=$(printf '%s\n' "$err" | line_of)
      printf '%s\n' "$rel syntax bash -n: ${pl:+$pl: }syntax error" >> "$first"
    fi ;;
  *.json)
    if [ "$is_jsonc" -eq 0 ] && ! err=$(jq empty "$real" 2>&1 >/dev/null); then
      pl=$(printf '%s\n' "$err" | line_of)
      printf '%s\n' "$rel syntax jq: ${pl:+$pl: }invalid JSON" >> "$first"
    fi ;;
  *.py)
    if command -v python3 >/dev/null 2>&1 && ! err=$(python3 -I -X pycache_prefix="$tmp/pyc" -m py_compile "$real" 2>&1 >/dev/null); then
      pl=$(printf '%s\n' "$err" | line_of)
      pm=$(printf '%s\n' "$err" | grep -oE '^[A-Za-z]+(Error|Exception)' | tail -n 1)
      printf '%s\n' "$rel syntax python: ${pl:+$pl: }${pm:-compile failed}" >> "$first"
    fi ;;
esac

[ -s "$first" ] || exit 0

{
  printf 'post-edit-scan found problems in the file you just edited (%s). The edit was applied; fix these now:\n' "$rel"
  sort -u "$first" | sed 's/^/- /'
  sort -u "$extra" | grep -vxF -f "$first" | sed 's/^/- /'
  if [ "$capped" -eq 1 ]; then
    printf -- '- ...stopped after %s repeat findings (the first hit of every rule is always listed); more may exist. Fix these, and the next edit rescans the file.\n' "$MAX_FINDINGS"
  fi
  if grep -q ' secret ' "$first"; then
    printf 'For secrets: remove the value from the file (read it from an env var or secret store); if it was ever real, treat it as leaked and rotate it. Values are redacted here on purpose.\n'
  fi
} > "$tmp/reason"
jq -Rsc '{decision:"block", reason:rtrimstr("\n")}' < "$tmp/reason"
exit 0
