#!/usr/bin/env bash
# post-edit-scan-test.sh — deterministic test of the post-edit-scan PostToolUse
# hook (.claude/hooks/post-edit-scan.sh). Proves: each built-in secret rule
# fires and reports file:line rule without the value; placeholders and
# lockfiles are not flagged; symlinks outside the project, missing and oversize
# files are skipped; broken .sh / .json / .py are reported; malformed stdin and
# a missing jq fail OPEN (exit 0, no decision); gitleaks findings are merged
# and a hung gitleaks is killed. gitleaks is always a stub on PATH so results
# do not depend on whether the real one is installed.
#
# Canary secrets are assembled at runtime from fragments so this file never
# contains a scannable secret itself.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="${POST_EDIT_SCAN_HOOK:-$REPO/.claude/hooks/post-edit-scan.sh}"  # override: mutation testing

if ! command -v jq >/dev/null 2>&1; then
  if [ -n "${CI:-}" ]; then
    echo "post-edit-scan-test: jq not found in CI — refusing to skip" >&2
    exit 1
  fi
  echo "post-edit-scan-test: jq not found — needed to build payloads; skipping" >&2
  exit 0
fi

P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PROJ="$WORK/proj"; OUTSIDE="$WORK/outside"; STUB="$WORK/stub"
mkdir -p "$PROJ" "$OUTSIDE" "$STUB"
PROJ="$(cd -P "$PROJ" && pwd -P)"

# gitleaks stub: mode from GL_STUB (empty | finding | hang). Writes the report
# to the --report-path argument like the real binary, and records its argv
# (one per line) and any GITLEAKS_CONFIG* env it received to $GL_LOG.
cat > "$STUB/gitleaks" <<'STUBEOF'
#!/usr/bin/env bash
if [ -n "${GL_LOG:-}" ]; then
  printf 'ARG %s\n' "$@" > "$GL_LOG"
  env | grep '^GITLEAKS_CONFIG' | sed 's/^/ENV /' >> "$GL_LOG"
fi
out=""
while [ "$#" -gt 0 ]; do [ "$1" = "--report-path" ] && out="$2"; shift; done
case "${GL_STUB:-empty}" in
  hang) sleep 30 ;;
  finding) printf '[{"RuleID":"stub-rule","StartLine":7,"Secret":"%s","Match":"%s"}]' "$GL_SECRET" "$GL_SECRET" > "$out" ;;
  *) printf '[]' > "$out" ;;
esac
STUBEOF
chmod +x "$STUB/gitleaks"

# run <file_path> [raw-stdin]: prints the hook's stdout; sets RC and ERR.
run(){
  local payload
  if [ "$#" -ge 2 ]; then payload="$2"; else payload=$(jq -cn --arg f "$1" '{tool_name:"Write", tool_input:{file_path:$f}}'); fi
  local errf="$WORK/stderr"
  OUT=$(printf '%s' "$payload" | (cd "$PROJ" && env PATH="$STUB:$PATH" CLAUDE_PROJECT_DIR="$PROJ" "$BASH" "$HOOK") 2>"$errf"); RC=$?
  ERR=$(cat "$errf")
}
reason(){ printf '%s' "$OUT" | jq -r 'select(.decision == "block") | .reason' 2>/dev/null; }
silent(){ [ "$RC" -eq 0 ] && [ -z "$OUT" ]; }

# expect_rule <name> <rule> <line> <secret> <file-content> [file-name]
expect_rule(){
  local name="$1" rule="$2" line="$3" secret="$4" content="$5" base="${6:-cfg-$2.txt}" r
  printf '%s\n' "$content" > "$PROJ/$base"
  run "$PROJ/$base"; r=$(reason)
  case "$r" in
    *"$base:$line secret $rule"*) ;;
    *) no "$name" "rc=$RC out=$OUT"; return ;;
  esac
  case "$OUT$ERR" in *"$secret"*) no "$name" "secret value leaked into output"; return ;; esac
  ok "$name"
}

AWS="AKIA""Q3EGRJ7XK2MZ5TBW"
PEM="-----BEGIN RSA ""PRIVATE KEY-----"
GH="ghp""_$(printf 'a1B2c3D4e5%.0s' 1 2 3 4)"
SLACK="xox""b-1234567890-abcdefghij"
STRIPE="sk_""live_4eC39HqLyjWDarjtT1zdp7dc"
GOOG="AI""zaSyD3x9QmK7vB2nL5pR8tW1yZ4cF6hJ0aBcD"
JWT="ey""JhbGciOiJIUzI1NiJ9.ey""JzdWIiOiIxMjM0NTY3ODkwIn0.dBjftJeZ4CVPmB92K27uhbUJU1p1r_wW1gFWFOEjXk"
PW="Zr8qL2vX9mN4kT7wB1"

expect_rule "aws-access-key-id"          aws-access-key-id 2 "$AWS"    "# cfg
aws_key: $AWS"
expect_rule "private-key header"         private-key 1 "$PEM"          "$PEM"
expect_rule "github-token"               github-token 1 "$GH"          "GH=$GH"
expect_rule "slack-token"                slack-token 1 "$SLACK"        "slack=$SLACK"
expect_rule "stripe-live-key"            stripe-live-key 1 "$STRIPE"   "stripe=$STRIPE"
expect_rule "google-api-key"             google-api-key 1 "$GOOG"      "key=$GOOG"
expect_rule "jwt"                        jwt 1 "$JWT"                  "auth=$JWT"
expect_rule "generic-secret-assignment"  generic-secret-assignment 3 "$PW" "a = 1
b = 2
db_password = \"$PW\""
OPENAI="sk-""proj-Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z"
ANTHROPIC="sk-""ant-api03-Zx9Cv8Bn7Mq6Wl5Ek4Rj3Th2Yg1Uf0Id"
expect_rule "openai-api-key (sk-proj-)"  openai-api-key 1 "$OPENAI"    "OPENAI_API_KEY=$OPENAI"
expect_rule "anthropic-api-key (sk-ant-)" anthropic-api-key 1 "$ANTHROPIC" "key: $ANTHROPIC"
expect_rule "generic unquoted in .env"   generic-secret-assignment 2 "$PW" "HOST=db
DB_PASSWORD=$PW" ".env"
expect_rule "generic unquoted YAML"      generic-secret-assignment 3 "$PW" "db:
  user: app
  password: $PW" "config.yml"

# Generic-rule false positives from review (each must stay silent).
BCRYPT='$2b$12$'"R9h/cIPz0gi.URNNX3kh2OPST9/PgBkqquzi.Ss7KIUgO2t0jWMUW"
printf '%s\n' \
  'token_url = "/api/v1/oauth2/token"' \
  'secretName = "prod-db-credentials-v2"' \
  'tokenCount = "1234567890abcdef1234"' \
  'api_key_header = "X-Api-Key-Version2"' \
  "passwordHash = \"$BCRYPT\"" \
  "password = \"$BCRYPT\"" \
  'password: process.env.DB_PASSWORD_V2' \
  > "$PROJ/not-secrets.ts"
run "$PROJ/not-secrets.ts"
silent && ok "generic rule ignores names/paths/hashes from review" || no "generic rule ignores names/paths/hashes from review" "out=$OUT"

# Placeholders / non-secrets stay silent.
printf 'aws_key: %s\ntoken = "%s"\napi_key = "<your-api-key-goes-here>"\nsecret: "${SECRET_FROM_ENV_VAR}"\npassword = "ACCESS_TOKEN_STORAGE_KEY"\nAPI_KEY=REPLACE_WITH_REAL_KEY_123\n' \
  "AKIA""IOSFODNN7EXAMPLE" "ghp""_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" > "$PROJ/placeholders.yml"
run "$PROJ/placeholders.yml"
silent && ok "placeholders not flagged" || no "placeholders not flagged" "rc=$RC out=$OUT"

printf '{"name":"x","integrity":"%s"}\n' "$AWS" > "$PROJ/package-lock.json"
run "$PROJ/package-lock.json"
silent && ok "lockfile skips regex set" || no "lockfile skips regex set" "rc=$RC out=$OUT"

printf 'echo ok\n' > "$PROJ/clean.sh"
run "$PROJ/clean.sh"
silent && ok "clean file is silent" || no "clean file is silent" "rc=$RC out=$OUT"

# Scope.
printf 'k=%s\n' "$AWS" > "$OUTSIDE/leak.txt"
ln -s "$OUTSIDE/leak.txt" "$PROJ/link.txt"
run "$PROJ/link.txt"
silent && ok "symlink outside project skipped" || no "symlink outside project skipped" "rc=$RC out=$OUT"
run "$OUTSIDE/leak.txt"
silent && ok "path outside project skipped" || no "path outside project skipped" "rc=$RC out=$OUT"
run "$PROJ/does-not-exist.txt"
silent && ok "missing file skipped" || no "missing file skipped" "rc=$RC out=$OUT"
{ printf 'k=%s\n' "$AWS"; head -c 1100000 /dev/zero | tr '\0' 'a'; } > "$PROJ/big.txt"
run "$PROJ/big.txt"
silent && ok "file over 1 MB skipped" || no "file over 1 MB skipped" "rc=$RC out=$OUT"

# Control characters in the path: skipped, never echoed, never reach sed.
# This exact name once made BSD sed write CANARY_PWNED into the project.
evil="$PROJ/"$'a#b#\nw CANARY_PWNED\n#.sh'
printf 'if then\n' > "$evil"
run "$evil"
silent && ok "newline path skipped silently" || no "newline path skipped silently" "rc=$RC out=$OUT"
if [ -z "$(find "$WORK" -name 'CANARY_PWNED*' -print)" ]; then ok "crafted filename creates no file"; else no "crafted filename creates no file" "CANARY_PWNED exists"; fi
tabbed="$PROJ/"$'tab\tname.sh'
printf 'if then\n' > "$tabbed"
run "$tabbed"
silent && ok "tab path skipped silently" || no "tab path skipped silently" "rc=$RC out=$OUT"

# Syntax checks.
printf 'if then\n' > "$PROJ/bad.sh"
run "$PROJ/bad.sh"
case "$(reason)" in *"bad.sh syntax bash -n"*) ok "broken .sh reported" ;; *) no "broken .sh reported" "out=$OUT" ;; esac
printf '{"a":\n' > "$PROJ/bad.json"
run "$PROJ/bad.json"
case "$(reason)" in *"bad.json syntax jq"*) ok "broken .json reported" ;; *) no "broken .json reported" "out=$OUT" ;; esac

# bash -n quotes the offending token; the hook must not.
printf 'foo() %s\n' "$PW" > "$PROJ/tok.sh"
case "$(bash -n "$PROJ/tok.sh" 2>&1)" in *"$PW"*) ;; *) no "bash -n canary precondition" "bash -n did not echo the token" ;; esac
run "$PROJ/tok.sh"
case "$(reason)" in *"tok.sh syntax bash -n: line 1: syntax error"*) ok "broken .sh reported with line" ;; *) no "broken .sh reported with line" "out=$OUT" ;; esac
case "$OUT$ERR" in *"$PW"*) no "bash -n error omits token" "leaked" ;; *) ok "bash -n error omits token" ;; esac

# JSONC files (comments allowed) skip the jq check; plain .json still checked.
mkdir -p "$PROJ/.vscode"
printf '{\n  // comment\n  "a": 1,\n}\n' > "$PROJ/tsconfig.json"
printf '{\n  // comment\n  "a": 1\n}\n' > "$PROJ/tsconfig.build.json"
printf '{\n  // comment\n}\n' > "$PROJ/.vscode/settings.json"
printf '{\n  // comment\n}\n' > "$PROJ/devcontainer.json"
jsonc_ok=1
for j in tsconfig.json tsconfig.build.json .vscode/settings.json devcontainer.json; do
  run "$PROJ/$j"; silent || { jsonc_ok=0; no "JSONC $j skipped" "out=$OUT"; }
done
[ "$jsonc_ok" -eq 1 ] && ok "JSONC files skip jq check"

# Many matches: capped, fast, and the reason says it stopped.
yes "k=$AWS" | head -n 40000 > "$PROJ/many.txt"   # ~920 KB, 40k matches
start=$(date +%s)
run "$PROJ/many.txt"
elapsed=$(( $(date +%s) - start ))
r=$(reason); listed=$(printf '%s\n' "$r" | grep -c 'secret aws-access-key-id')
case "$r" in
  *"stopped after 20 findings"*) [ "$listed" -eq 20 ] && [ "$elapsed" -lt 10 ] && ok "many matches capped at 20 (${elapsed}s)" || no "many matches capped" "listed=$listed elapsed=${elapsed}s" ;;
  *) no "many matches capped" "rc=$RC elapsed=${elapsed}s out=$(printf '%s' "$OUT" | head -c 300)" ;;
esac
if command -v python3 >/dev/null 2>&1; then
  printf 'x = 1\ndef broken(:\n    pass  # %s\n' "$PW" > "$PROJ/bad.py"
  run "$PROJ/bad.py"
  case "$(reason)" in *"bad.py syntax python: line 2"*) ok "broken .py reported with line" ;; *) no "broken .py reported with line" "out=$OUT" ;; esac
  case "$OUT$ERR" in *"$PW"*|*"def broken"*) no "py error omits source text" "out=$OUT" ;; *) ok "py error omits source text" ;; esac
  [ -n "${VERBOSE:-}" ] && printf '%s\n' "$(reason)"
  [ ! -e "$PROJ/__pycache__" ] && ok "py_compile wrote no __pycache__" || no "py_compile wrote no __pycache__" "found $PROJ/__pycache__"
  printf 'x = 1\n' > "$PROJ/good.py"
  run "$PROJ/good.py"
  silent && ok "valid .py is silent" || no "valid .py is silent" "out=$OUT"
else
  printf 'SKIP  python3 not installed\n'
fi

# Fail open.
run "" '{"tool_name":"Write", "tool_input": {'
[ "$RC" -eq 0 ] && [ -z "$OUT" ] && [ -n "$ERR" ] && ok "malformed stdin fails open" || no "malformed stdin fails open" "rc=$RC out=$OUT err=$ERR"
run "" ''
silent && ok "empty stdin fails open" || no "empty stdin fails open" "rc=$RC out=$OUT"
run "" '{"tool_name":"Write","tool_input":{"file_path":42}}'
silent && ok "non-string file_path fails open" || no "non-string file_path fails open" "rc=$RC out=$OUT"
nojq="$WORK/nojq"; mkdir -p "$nojq"
OUT=$(jq -cn --arg f "$PROJ/bad.sh" '{tool_input:{file_path:$f}}' | env PATH="$nojq" "$BASH" "$HOOK" 2>/dev/null); RC=$?
silent && ok "missing jq fails open" || no "missing jq fails open" "rc=$RC out=$OUT"

# gitleaks integration (stub).
printf 'nothing here\n' > "$PROJ/gl.txt"
export GL_SECRET="$AWS"
GL_STUB=finding run "$PROJ/gl.txt"
case "$(reason)" in *"gl.txt:7 secret gitleaks:stub-rule"*) ok "gitleaks finding merged" ;; *) no "gitleaks finding merged" "out=$OUT" ;; esac
case "$OUT$ERR" in *"$AWS"*) no "gitleaks secret never echoed" "leaked" ;; *) ok "gitleaks secret never echoed" ;; esac

# The untrusted-config posture SECURITY.md claims: flags present, env unset.
export GL_LOG="$WORK/gl.log"
GITLEAKS_CONFIG=/evil.toml GITLEAKS_CONFIG_TOML='x' run "$PROJ/gl.txt"
for flag in --redact --ignore-gitleaks-allow --gitleaks-ignore-path --no-banner; do
  grep -qx "ARG $flag" "$GL_LOG" && ok "gitleaks called with $flag" || no "gitleaks called with $flag" "argv: $(tr '\n' ' ' < "$GL_LOG")"
done
ign=$(grep -A1 -x 'ARG --gitleaks-ignore-path' "$GL_LOG" | tail -n 1); ign="${ign#ARG }"
case "$ign" in "$PROJ"*|"") no "gitleaks ignore path is outside the project" "got '$ign'" ;; *) ok "gitleaks ignore path is outside the project" ;; esac
grep -q '^ENV ' "$GL_LOG" && no "GITLEAKS_CONFIG* unset for gitleaks" "$(grep '^ENV ' "$GL_LOG")" || ok "GITLEAKS_CONFIG* unset for gitleaks"
unset GL_LOG
start=$(date +%s)
GL_STUB=hang run "$PROJ/gl.txt"
elapsed=$(( $(date +%s) - start ))
if [ "$RC" -eq 0 ] && [ -z "$OUT" ] && [ "$elapsed" -lt 15 ]; then ok "hung gitleaks killed, fails open (${elapsed}s)"; else no "hung gitleaks killed" "rc=$RC out=$OUT elapsed=${elapsed}s"; fi

printf 'post-edit-scan-test: %d passed, %d failed.\n' "$P" "$F"
[ "$F" -eq 0 ]
