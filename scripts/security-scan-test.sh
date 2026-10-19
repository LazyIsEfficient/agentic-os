#!/usr/bin/env bash
# security-scan-test.sh — deterministic, OFFLINE fixture tests for
# scripts/security-scan.sh. No real scanner is needed: fake gitleaks / semgrep /
# osv-scanner executables on a controlled PATH emit canned output, switched by
# FAKE_GITLEAKS / FAKE_SEMGREP / FAKE_OSV (findings | clean | error). Covers every
# exit code (0, 1, 2, 3, 4), a path with spaces and a leading dash, --base scope,
# and SEMGREP_CONFIG pass-through.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAN="$SCRIPT_DIR/security-scan.sh"
[ -f "$SCAN" ] || { echo "security-scan-test: $SCAN not found" >&2; exit 2; }

T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }

# ── Controlled PATH: only the tools the script needs, so real scanners (or npm /
# pip-audit / cargo) installed on the host can never leak into a test. ─────────
SYS="$T/sysbin"; FAKE="$T/fakebin"; mkdir -p "$SYS" "$FAKE"
for tool in bash env git jq mktemp rm cat head tail dirname basename mv grep sed tr \
            awk cp find mkdir readlink ln wc ls; do
  src="$(command -v "$tool")" || { echo "security-scan-test: missing host tool $tool" >&2; exit 2; }
  ln -s "$src" "$SYS/$tool"
done
LOG="$T/calls.log"

cat > "$FAKE/gitleaks" <<'EOF'
#!/usr/bin/env bash
# fake gitleaks: `gitleaks dir ... --report-path R -- FILE`
printf 'gitleaks' >> "$FAKE_LOG"; printf ' <%s>' "$@" >> "$FAKE_LOG"; echo >> "$FAKE_LOG"
report=""; file=""
while [ $# -gt 0 ]; do
  case "$1" in
    --report-path) report="$2"; shift 2 ;;
    --) file="$2"; shift 2 ;;
    *) shift ;;
  esac
done
case "${FAKE_GITLEAKS:-clean}" in
  error) echo "fake gitleaks exploded" >&2; exit 1 ;;
  findings)
    if grep -q 'SECRET' "$file"; then
      printf '[{"RuleID":"generic-api-key","Description":"Detected a Generic API Key","StartLine":2,"File":"%s","Secret":"REDACTED"}]\n' "$file" > "$report"
    else
      echo '[]' > "$report"
    fi ;;
  *) echo '[]' > "$report" ;;
esac
exit 0
EOF

cat > "$FAKE/semgrep" <<'EOF'
#!/usr/bin/env bash
# fake semgrep: `semgrep scan --config C --json ... -- FILES...`
printf 'semgrep' >> "$FAKE_LOG"; printf ' <%s>' "$@" >> "$FAKE_LOG"; echo >> "$FAKE_LOG"
while [ $# -gt 0 ] && [ "$1" != "--" ]; do shift; done
shift
case "${FAKE_SEMGREP:-clean}" in
  error) echo '{"results":[],"errors":[{"level":"error","message":"invalid configuration file found"}]}'; exit 7 ;;
  findings) printf '{"results":[{"path":"%s","start":{"line":1},"check_id":"javascript.lang.security.eval","extra":{"severity":"ERROR","message":"eval detected"}}],"errors":[]}\n' "$1" ;;
  *) echo '{"results":[],"errors":[]}' ;;
esac
exit 0
EOF

cat > "$FAKE/osv-scanner" <<'EOF'
#!/usr/bin/env bash
# fake osv-scanner: `osv-scanner scan --format json ... -L LOCK`
printf 'osv-scanner' >> "$FAKE_LOG"; printf ' <%s>' "$@" >> "$FAKE_LOG"; echo >> "$FAKE_LOG"
case "${FAKE_OSV:-clean}" in
  error) echo "fake osv failure" >&2; exit 127 ;;
  findings)
    echo '{"results":[{"source":{"path":"'"$PWD"'/package-lock.json","type":"lockfile"},"packages":[{"package":{"name":"lodash","version":"4.17.15","ecosystem":"npm"},"vulnerabilities":[{"id":"GHSA-35jh-r3h4-6jhm","summary":"Command Injection in lodash","database_specific":{"severity":"HIGH"}}]}]}]}'
    exit 1 ;;
  *) echo '{"results":[]}'; exit 0 ;;
esac
EOF
chmod +x "$FAKE/gitleaks" "$FAKE/semgrep" "$FAKE/osv-scanner"

# Fallback auditors live in their own dir so osv-scanner is absent when used.
FAKE2="$T/fakebin2"; mkdir -p "$FAKE2"
cat > "$FAKE2/npm" <<'EOF'
#!/usr/bin/env bash
# fake npm: records its cwd, args, and what config it could see.
{
  printf 'npm cwd=<%s>' "$PWD"; printf ' <%s>' "$@"; echo
  [ -e .npmrc ] && echo "npm saw-npmrc-in-cwd"
  while [ $# -gt 0 ]; do
    case "$1" in --userconfig|--globalconfig) [ -s "$2" ] && echo "npm nonempty-config $2"; shift 2 ;; *) shift ;; esac
  done
  ls -A
} >> "$FAKE_LOG"
case "${FAKE_NPM:-clean}" in
  error) echo '{"message":"request to http://evil failed","error":{"summary":"","detail":""}}'; exit 1 ;;
  findings) echo '{"vulnerabilities":{"lodash":{"name":"lodash","severity":"high","via":[{"source":1106913,"title":"Command Injection in lodash","url":"https://github.com/advisories/GHSA-35jh-r3h4-6jhm"}]}}}'; exit 1 ;;
  *) echo '{"vulnerabilities":{},"metadata":{}}'; exit 0 ;;
esac
EOF
cat > "$FAKE2/pip-audit" <<'EOF'
#!/usr/bin/env bash
# fake pip-audit: records the requirements content it was handed.
req=""
while [ $# -gt 0 ]; do case "$1" in -r) req="$2"; shift 2 ;; *) shift ;; esac; done
{ echo "pip-audit cwd=<$PWD> req=<$req>"; sed 's/^/pip-req: /' "$req"; } >> "$FAKE_LOG"
echo '{"dependencies":[{"name":"requests","version":"2.19.0","vulns":[]}],"fixes":[]}'
EOF
chmod +x "$FAKE2/npm" "$FAKE2/pip-audit"

# ── Fixture project: a path with spaces + leading dash, a lockfile. ───────────
PROJ="$T/proj"
mkdir -p "$PROJ/dir with space"
printf 'const a = 1;\nconst k = "SECRET-abc123";\n' > "$PROJ/dir with space/-leading.js"
printf 'eval(x);\n' > "$PROJ/app.js"
echo '{"lockfileVersion":3,"packages":{}}' > "$PROJ/package-lock.json"

export FAKE_LOG="$LOG"
FULL_PATH="$FAKE:$SYS"

# run <PATH> [args...] — runs the scanner in $PROJ. Sets OUT, RC.
run(){ local p="$1"; shift; OUT="$(cd "$PROJ" && PATH="$p" bash "$SCAN" "$@" 2>"$T/stderr")"; RC=$?; }
jqo(){ printf '%s' "$OUT" | jq -r "$1" 2>/dev/null; }

# ── exit 1: findings from every scanner ───────────────────────────────────────
: > "$LOG"
FAKE_GITLEAKS=findings FAKE_SEMGREP=findings FAKE_OSV=findings \
  run "$FULL_PATH" --json --paths "dir with space/-leading.js" app.js
[ "$RC" -eq 1 ] && ok "findings → exit 1" || no "findings → exit 1" "rc=$RC out=$OUT"
[ "$(jqo '[.scanners[] | select(.status=="findings") | .name] | join(",")')" = "gitleaks,semgrep,osv-scanner" ] \
  && ok "findings: gitleaks, semgrep, osv-scanner all report findings" \
  || no "findings statuses" "$(jqo '.scanners | map({name,status})')"
[ "$(jqo '.scanners[] | select(.name=="gitleaks") | .findings[0] | "\(.file)|\(.line)|\(.rule)"')" = "dir with space/-leading.js|2|generic-api-key" ] \
  && ok "gitleaks finding keeps the spaced, dash-led path intact (normalized)" \
  || no "gitleaks finding path" "$(jqo '.scanners[0]')"
[ "$(jqo '.scanners[] | select(.name=="osv-scanner") | .findings[0] | "\(.file)|\(.line)|\(.rule)|\(.severity)"')" = "package-lock.json|null|GHSA-35jh-r3h4-6jhm|HIGH" ] \
  && ok "osv finding: project-relative lockfile, null line, advisory id, severity" \
  || no "osv finding" "$(jqo '.scanners[2]')"
grep -qF -- '<--> <./dir with space/-leading.js>' "$LOG" \
  && ok "path passed after -- and ./-prefixed (leading dash never parsed as a flag)" \
  || no "-- / ./ prefix" "$(cat "$LOG")"
grep -qF -- '<--config> <p/security-audit>' "$LOG" \
  && ok "semgrep defaults to p/security-audit" || no "semgrep default config" "$(grep semgrep "$LOG")"

# ── exit 0: scanners ran clean ────────────────────────────────────────────────
: > "$LOG"
SEMGREP_CONFIG=./local-rules.yml run "$FULL_PATH" --json --paths app.js
[ "$RC" -eq 0 ] && ok "clean → exit 0" || no "clean → exit 0" "rc=$RC out=$OUT"
[ "$(jqo '[.scanners[].status] | join(",")')" = "ran,ran,ran" ] \
  && ok "clean: every scanner status is ran" || no "clean statuses" "$OUT"
grep -qF -- '<--config> <./local-rules.yml>' "$LOG" \
  && ok "SEMGREP_CONFIG overrides the rule config (offline ruleset)" || no "SEMGREP_CONFIG" "$(grep semgrep "$LOG")"

# ── exit 3: no scanner available (and never a silent skip) ────────────────────
rm -f "$PROJ/package-lock.json"
run "$SYS" --json --paths app.js
[ "$RC" -eq 3 ] && ok "no scanner installed → exit 3" || no "no scanner → exit 3" "rc=$RC out=$OUT"
[ "$(jqo '[.scanners[] | "\(.name)=\(.status)"] | join(",")')" = "gitleaks=unavailable,semgrep=unavailable,dependency-audit=unavailable" ] \
  && ok "absent scanners each reported unavailable" || no "unavailable report" "$OUT"
run "$SYS" --paths app.js
printf '%s' "$OUT" | grep -q '^gitleaks: unavailable (gitleaks not installed)' \
  && ok "human output names unavailable scanners" || no "human output" "$OUT"
echo '{"lockfileVersion":3,"packages":{}}' > "$PROJ/package-lock.json"

# ── exit 4: a scanner errored, no findings ────────────────────────────────────
FAKE_SEMGREP=error run "$FULL_PATH" --json --paths app.js
[ "$RC" -eq 4 ] && ok "scanner error → exit 4" || no "error → exit 4" "rc=$RC out=$OUT"
[ "$(jqo '.scanners[] | select(.name=="semgrep") | .status')" = "error" ] \
  && jqo '.scanners[] | select(.name=="semgrep") | .reason' | grep -q 'invalid configuration' \
  && ok "semgrep error status carries the scanner's reason" || no "semgrep error reason" "$OUT"
FAKE_OSV=error run "$FULL_PATH" --json --paths app.js
[ "$RC" -eq 4 ] && [ "$(jqo '.scanners[] | select(.name=="osv-scanner") | .status')" = "error" ] \
  && ok "osv-scanner unexpected exit code → error / exit 4" || no "osv error" "rc=$RC out=$OUT"
FAKE_GITLEAKS=findings FAKE_SEMGREP=error run "$FULL_PATH" --json --paths "dir with space/-leading.js"
[ "$RC" -eq 1 ] && ok "findings outrank errors (exit 1, error still visible)" || no "findings+error" "rc=$RC"

# ── exit 2: usage errors ──────────────────────────────────────────────────────
run "$FULL_PATH" --bogus
[ "$RC" -eq 2 ] && ok "unknown flag → exit 2" || no "unknown flag" "rc=$RC"
run "$FULL_PATH" --json
[ "$RC" -eq 2 ] && ok "default scope outside a git repo → exit 2" || no "non-git default" "rc=$RC"

# ── --base scope in a real git repo: changed + untracked, deleted skipped ─────
G="$T/repo"; mkdir -p "$G"
(
  cd "$G" || exit 1
  git init -q
  printf 'old\n' > keep.js; printf 'gone\n' > deleted.js
  git add . && git -c user.name=t -c user.email=t@t commit -qm base
) || { echo "security-scan-test: git fixture setup failed" >&2; exit 2; }
BASE_SHA="$(git -C "$G" rev-parse HEAD)"
(
  cd "$G" || exit 1
  mkdir -p "sub dir"; printf 'x\nSECRET\n' > "sub dir/new file.js"
  git rm -q deleted.js
  git add . && git -c user.name=t -c user.email=t@t commit -qm change
  printf 'SECRET\n' > untracked.js
) || { echo "security-scan-test: git fixture change failed" >&2; exit 2; }
: > "$LOG"
OUT="$(cd "$G" && FAKE_GITLEAKS=findings PATH="$FULL_PATH" bash "$SCAN" --json --base "$BASE_SHA" 2>"$T/stderr")"; RC=$?
[ "$RC" -eq 1 ] && ok "--base: findings in changed files → exit 1" || no "--base rc" "rc=$RC $(cat "$T/stderr")"
[ "$(jqo '[.scanners[] | select(.name=="gitleaks") | .findings[].file] | sort | join(",")')" = "sub dir/new file.js,untracked.js" ] \
  && ok "--base scans committed + untracked changes" || no "--base files" "$OUT"
grep -q 'deleted.js\|keep.js' "$LOG" \
  && no "--base scope" "scanned an unchanged or deleted file: $(cat "$LOG")" \
  || ok "--base skips unchanged and deleted files"
OUT="$(cd "$G" && PATH="$FULL_PATH" bash "$SCAN" --base no-such-ref 2>/dev/null)"; RC=$?
[ "$RC" -eq 2 ] && ok "--base unresolvable ref → exit 2" || no "bad ref" "rc=$RC"
OUT="$(cd "$G" && PATH="$FULL_PATH" bash "$SCAN" --base --output=/tmp/x 2>"$T/stderr")"; RC=$?
{ [ "$RC" -eq 2 ] && grep -q 'invalid --base ref' "$T/stderr"; } \
  && ok "dash-led --base ref rejected before reaching git → exit 2" || no "dash base" "rc=$RC $(cat "$T/stderr")"
git -C "$G" add -A >/dev/null; git -C "$G" -c user.name=t -c user.email=t@t commit -qm tidy
: > "$LOG"
OUT="$(cd "$G" && PATH="$FULL_PATH" bash "$SCAN" --json 2>"$T/stderr")"; RC=$?
{ [ "$RC" -eq 3 ] && [ "$(jqo '.scanners | length')" = "0" ] && [ ! -s "$LOG" ]; } \
  && ok "no changes in scope → exit 3 (nothing checked), not 0" || no "empty scope" "rc=$RC out=$OUT"

# ── --paths: missing entry is a usage error; directories expand ───────────────
run "$FULL_PATH" --json --paths app.js does-not-exist.js
{ [ "$RC" -eq 2 ] && grep -q 'does not exist: does-not-exist.js' "$T/stderr"; } \
  && ok "--paths typo → exit 2 (never a silent clean)" || no "--paths missing" "rc=$RC $(cat "$T/stderr")"
mkdir -p "$PROJ/emptydir"
run "$FULL_PATH" --json --paths emptydir
[ "$RC" -eq 3 ] && ok "--paths on an empty directory → exit 3" || no "empty dir" "rc=$RC out=$OUT"
: > "$LOG"
FAKE_GITLEAKS=findings run "$FULL_PATH" --json --paths "dir with space"
{ [ "$RC" -eq 1 ] && grep -qF -- '<--> <./dir with space/-leading.js>' "$LOG"; } \
  && ok "--paths <dir> expands to the files under it" || no "dir expansion" "rc=$RC $(cat "$LOG")"

# ── symlinks: never followed out of the repo root ─────────────────────────────
mkdir -p "$T/outside"; printf 'SECRET outside\n' > "$T/outside/creds.txt"
ln -s "$T/outside/creds.txt" "$PROJ/escape.txt"
ln -s "app.js" "$PROJ/inside-link.js"
: > "$LOG"
FAKE_GITLEAKS=findings run "$FULL_PATH" --json --paths escape.txt
{ [ "$RC" -eq 3 ] && [ "$(jqo '.skipped[0] | "\(.path)|\(.reason)"')" = "escape.txt|resolves outside the repo root" ] \
  && ! grep -q 'creds.txt\|escape.txt' "$LOG"; } \
  && ok "symlink to a file outside the repo is skipped and reported, never scanned" \
  || no "symlink escape" "rc=$RC out=$OUT log=$(cat "$LOG")"
: > "$LOG"
run "$FULL_PATH" --json --paths inside-link.js
{ [ "$RC" -eq 0 ] && grep -qF -- '<--> <./app.js>' "$LOG"; } \
  && ok "in-repo symlink is scanned at its real path" || no "in-repo symlink" "rc=$RC $(cat "$LOG")"
rm -f "$PROJ/escape.txt" "$PROJ/inside-link.js"

# ── untrusted repo config: gitleaks / semgrep / osv ───────────────────────────
printf '[allowlist]\npaths = [".*"]\n' > "$PROJ/.gitleaks.toml"
printf 'dir with space/-leading.js:generic-api-key:2\n' > "$PROJ/.gitleaksignore"
printf '[[IgnoredVulns]]\nid = "GHSA-35jh-r3h4-6jhm"\n' > "$PROJ/osv-scanner.toml"
: > "$LOG"
FAKE_GITLEAKS=findings FAKE_OSV=findings run "$FULL_PATH" --json --paths "dir with space/-leading.js"
gl_line="$(grep '^gitleaks' "$LOG" | head -n 1)"
ign_dir="$(printf '%s' "$gl_line" | sed -E 's/.*<--gitleaks-ignore-path> <([^>]*)>.*/\1/')"
{ printf '%s' "$gl_line" | grep -qF '<--ignore-gitleaks-allow>' \
  && [ -n "$ign_dir" ] && [ "$ign_dir" != "$gl_line" ] \
  && ! printf '%s' "$gl_line" | grep -qF '.gitleaks.toml'; } \
  && ok "gitleaks: inline allow + repo .gitleaksignore disabled, repo .gitleaks.toml not passed" \
  || no "gitleaks untrusted config" "$gl_line"
[ "$(jqo '.scanners[] | select(.name=="gitleaks") | .notes | join(",")')" = "ignored repo-local .gitleaks.toml,ignored repo-local .gitleaksignore" ] \
  && ok "gitleaks JSON notes report the ignored repo-local config" || no "gitleaks notes" "$OUT"
grep '^semgrep' "$LOG" | grep -qF '<--disable-nosem>' \
  && ok "semgrep: inline nosemgrep suppressions disabled" || no "semgrep nosem" "$(grep '^semgrep' "$LOG")"
osv_line="$(grep '^osv-scanner' "$LOG")"
{ printf '%s' "$osv_line" | grep -qF '<--config>' && ! printf '%s' "$osv_line" | grep -qF 'osv-scanner.toml' \
  && [ "$(jqo '.scanners[] | select(.name=="osv-scanner") | .notes[0]')" = "ignored repo-local osv-scanner.toml" ]; } \
  && ok "osv-scanner: forced empty --config, repo osv-scanner.toml ignored and reported" || no "osv config" "$osv_line $OUT"
: > "$LOG"
SECURITY_SCAN_GITLEAKS_CONFIG=/trusted/gitleaks.toml run "$FULL_PATH" --json --paths app.js
grep '^gitleaks' "$LOG" | grep -qF '<--config> </trusted/gitleaks.toml>' \
  && ok "SECURITY_SCAN_GITLEAKS_CONFIG supplies the gitleaks rules" || no "gitleaks override" "$(cat "$LOG")"
rm -f "$PROJ/.gitleaks.toml" "$PROJ/.gitleaksignore" "$PROJ/osv-scanner.toml"

# ── npm audit fallback: a hostile .npmrc is never honored ─────────────────────
printf 'registry=http://evil.invalid/\n//evil.invalid/:_authToken=${ENV_SECRET}\n' > "$PROJ/.npmrc"
echo '{"name":"proj","dependencies":{"lodash":"4.17.15"}}' > "$PROJ/package.json"
NPM_PATH="$FAKE2:$SYS"
: > "$LOG"
FAKE_NPM=findings run "$NPM_PATH" --json --paths app.js
npm_line="$(grep '^npm cwd=' "$LOG")"
npm_cwd="$(printf '%s' "$npm_line" | sed -E 's/^npm cwd=<([^>]*)>.*/\1/')"
{ [ "$RC" -eq 1 ] && [ -n "$npm_cwd" ] && [ "$npm_cwd" != "$PROJ" ] && [ "$npm_cwd" != "$(cd "$PROJ" && pwd -P)" ] \
  && ! grep -q 'saw-npmrc-in-cwd\|nonempty-config' "$LOG" \
  && printf '%s' "$npm_line" | grep -qF '<--registry> <https://registry.npmjs.org/>' \
  && printf '%s' "$npm_line" | grep -qF '<--userconfig>' \
  && printf '%s' "$npm_line" | grep -qF '<--globalconfig>'; } \
  && ok "npm audit runs in an isolated temp dir: no .npmrc, empty user/global config, explicit registry" \
  || no "npm isolation" "rc=$RC $(cat "$LOG")"
[ "$(grep -v '^npm' "$LOG" | sort | tr '\n' ' ')" = "package-lock.json package.json " ] \
  && ok "npm sandbox holds only package.json + lockfile" || no "npm sandbox contents" "$(cat "$LOG")"
[ "$(jqo '.scanners[] | select(.name=="npm-audit") | "\(.status)|\(.notes[0])"')" = "findings|ignored repo-local .npmrc" ] \
  && ok "npm finding reported; ignored .npmrc noted" || no "npm notes" "$OUT"
: > "$LOG"
SECURITY_SCAN_NPM_REGISTRY=https://mirror.example/ run "$NPM_PATH" --json --paths app.js
grep -qF '<--registry> <https://mirror.example/>' "$LOG" \
  && ok "SECURITY_SCAN_NPM_REGISTRY overrides the registry" || no "npm registry override" "$(cat "$LOG")"
FAKE_NPM=error run "$NPM_PATH" --json --paths app.js
{ [ "$RC" -eq 4 ] && jqo '.scanners[] | select(.name=="npm-audit") | .reason' | grep -q 'request to http://evil failed'; } \
  && ok "npm error keeps its reason (empty summary does not swallow message)" || no "npm reason" "rc=$RC $OUT"
rm -f "$PROJ/.npmrc" "$PROJ/package.json" "$PROJ/package-lock.json"

# ── pip-audit fallback: option lines never reach pip-audit ────────────────────
printf -- '--index-url http://evil.invalid/simple\n  -r ../../outside.txt\nrequests==2.19.0\n' > "$PROJ/requirements.txt"
: > "$LOG"
run "$NPM_PATH" --json --paths app.js
{ [ "$RC" -eq 0 ] && grep -q '^pip-req: requests==2.19.0$' "$LOG" && ! grep -q 'index-url\|outside.txt' "$LOG" \
  && ! grep -qF "req=<./requirements.txt> " "$LOG" && grep -q "pip-audit cwd=<" "$LOG" \
  && [ "$(grep '^pip-audit cwd=' "$LOG" | sed -E 's/^pip-audit cwd=<([^>]*)>.*/\1/')" != "$PROJ" ] \
  && jqo '.scanners[] | select(.name=="pip-audit") | .notes[0]' | grep -q 'stripped 2 option line'; } \
  && ok "pip-audit gets a sanitized copy (no --index-url / -r lines) and a note" \
  || no "pip sanitize" "rc=$RC $(cat "$LOG") $OUT"
rm -f "$PROJ/requirements.txt"
echo '{"lockfileVersion":3,"packages":{}}' > "$PROJ/package-lock.json"

echo ""
echo "security-scan-test: $P passed, $F failed."
[ "$F" -eq 0 ]
