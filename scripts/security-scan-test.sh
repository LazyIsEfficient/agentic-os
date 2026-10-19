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
for tool in bash env git jq mktemp rm cat head tail dirname basename mv grep sed tr; do
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

echo ""
echo "security-scan-test: $P passed, $F failed."
[ "$F" -eq 0 ]
