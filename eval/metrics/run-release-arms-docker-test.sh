#!/usr/bin/env bash
# run-release-arms-docker-test.sh — containment test of run-release-arms-docker.sh.
# Builds the image (network: base image + pinned packages), then runs a short
# experiment with a STUB claude mounted over the pinned CLI (no API calls).
# The stub tries to write outside the container's writable mount: to /repo, to
# the read-only git dir, and to a host canary file by its absolute host path.
# Skips (exit 0) when no docker daemon is reachable.
# Conditions are strings run by check(); variables they read look unused to shellcheck.
# shellcheck disable=SC2034
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$DIR/../.." && pwd -P)"
WRAP="$DIR/run-release-arms-docker.sh"

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "SKIP  run-release-arms-docker-test: no docker daemon reachable"
  exit 0
fi

T="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$T"' EXIT
FAIL=0
pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; FAIL=1; }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

CANARY="sk-ant-CANARY-$(node -e 'console.log(crypto.randomUUID())')"
GC="$(cd "$(git -C "$REPO" rev-parse --path-format=absolute --git-common-dir)" && pwd -P)"
mkdir -p "$T/bin" "$T/out"
echo "host canary" > "$T/host-canary.txt"

cat > "$T/bin/claude" <<STUB
#!/usr/bin/env bash
R=/out/stub-results; mkdir -p "\$R"
try() { if ( eval "\$2" ) 2>/dev/null; then echo "\$1 WROTE" >> "\$R/writes"; else echo "\$1 blocked" >> "\$R/writes"; fi; }
try repo 'echo pwned > /repo/PWNED-by-stub'
try gitdir 'echo pwned > "$GC/PWNED-by-stub"'
try host-canary 'echo pwned > "$T/host-canary.txt"'
try host-home 'mkdir -p "$T/fake-home" && echo pwned > "$T/fake-home/x"'
echo "\$HOME" > "\$R/home"; id -u > "\$R/uid"
sid=""; prev=""
for a in "\$@"; do { [ "\$prev" = --session-id ] || [ "\$prev" = --resume ]; } && sid="\$a"; prev="\$a"; done
mkdir -p "\$CLAUDE_CONFIG_DIR/projects/stub"
printf '{"type":"assistant","message":{"id":"m1","usage":{"input_tokens":100,"output_tokens":10},"content":[]}}\n' >> "\$CLAUDE_CONFIG_DIR/projects/stub/\$sid.jsonl"
[ -f app.js ] && cp /repo/eval/metrics/fixtures/seeded-path-traversal/safe-app.js app.js
exit 0
STUB
chmod +x "$T/bin/claude"

# ---- 1. no TTY and no --yes: refuses before building or running ---------------
"${BASH:-bash}" "$WRAP" --out "$T/out-gate" --claude-bin-dir "$T/bin" --scenario seeded-path-traversal main=HEAD < /dev/null > "$T/gate.log" 2>&1
rc=$?
check "no TTY, no --yes -> refuses" '[ "$rc" != 0 ] && grep -q "pass --yes" "$T/gate.log"'

# ---- 2. stub experiment in the container ---------------------------------------
ANTHROPIC_API_KEY="$CANARY" "${BASH:-bash}" "$WRAP" --out "$T/out" --claude-bin-dir "$T/bin" \
  --yes --scenario seeded-path-traversal main=HEAD < /dev/null > "$T/run.log" 2>&1
rc=$?
check "containerised run exits 0" '[ "$rc" = 0 ]'
[ "$rc" = 0 ] || tail -30 "$T/run.log"
check "(a) samples.jsonl lands in the host output dir" \
  '[ "$(node -e "const l=require(\"fs\").readFileSync(process.argv[1],\"utf8\").trim().split(\"\n\").map(JSON.parse);console.log(l.length===1&&l[0].status===\"complete\"&&l[0].exploit===\"pass\")" "$T/out/samples.jsonl")" = true ]'
check "scanners ran in the container (gitleaks / semgrep counted, not unavailable)" \
  '[ "$(node -e "const r=JSON.parse(require(\"fs\").readFileSync(process.argv[1],\"utf8\").trim());console.log(Number.isInteger(r.scan.gitleaks)&&Number.isInteger(r.scan.semgrep))" "$T/out/samples.jsonl")" = true ]'
check "(b) stub could not write the read-only repo mount" 'grep -qx "repo blocked" "$T/out/stub-results/writes" && [ ! -e "$REPO/PWNED-by-stub" ]'
check "(b) stub could not write the read-only git dir" 'grep -qx "gitdir blocked" "$T/out/stub-results/writes" && [ ! -e "$GC/PWNED-by-stub" ]'
check "(b) host canary untouched (its host path is not reachable)" '[ "$(cat "$T/host-canary.txt")" = "host canary" ]'
check "(b) nothing created at host paths outside /out" '[ ! -e "$T/fake-home" ]'
check "stub ran as non-root with a container HOME" '[ "$(cat "$T/out/stub-results/uid")" != 0 ] && case "$(cat "$T/out/stub-results/home")" in /tmp/*) true ;; *) false ;; esac'
check "(c) key canary never in the output dir" '! grep -rqF "$CANARY" "$T/out"'
check "(c) key canary never in the wrapper output" '! grep -qF "$CANARY" "$T/run.log"'

[ "$FAIL" = 0 ] && echo "run-release-arms-docker-test: OK" || { echo "run-release-arms-docker-test: FAILED"; exit 1; }
