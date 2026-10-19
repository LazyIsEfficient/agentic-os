#!/usr/bin/env bash
# run-arms-isolation-test.sh — Tier 0 test of run-arms.sh arm isolation.
# Puts a stub `claude` first on PATH: it records argv, env NAMES, HOME,
# CLAUDE_CONFIG_DIR and the config dir listing, writes a fixture transcript,
# and never calls the real API. HOME is a sentinel dir that must stay unchanged.
# Conditions are strings run by check(); variables they read look unused to shellcheck.
# shellcheck disable=SC2034
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$DIR/../.." && pwd)"
RUN_ARMS="$DIR/run-arms.sh"
# shellcheck source=lib/arm-isolation.sh
source "$DIR/lib/arm-isolation.sh"

T="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$T"' EXIT
FAIL=0
pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; FAIL=1; }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

CANARY="sk-ant-CANARY-$(node -e 'console.log(crypto.randomUUID())')"
CANARY_SHA="$(printf '%s' "$CANARY" | iso_sha256)"

mkdir -p "$T/bin" "$T/sentinel-home" "$T/arms-tmp"
echo "operator file" > "$T/sentinel-home/keep.txt"
SENTINEL_BEFORE="$(iso_listing_sha256 "$T/sentinel-home")"

cat > "$T/bin/claude" <<STUB
#!/usr/bin/env bash
LOGDIR="$T/stub-log"
mkdir -p "\$LOGDIR"
d="\$LOGDIR/call-\$(find "\$LOGDIR" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
mkdir -p "\$d"
printf '%s\n' "\$@" > "\$d/argv"
env | cut -d= -f1 | LC_ALL=C sort > "\$d/env-names"
echo "\$HOME" > "\$d/home"
echo "\$CLAUDE_CONFIG_DIR" > "\$d/config"
pwd -P > "\$d/cwd"
( cd "\$CLAUDE_CONFIG_DIR" && find . -mindepth 1 | LC_ALL=C sort ) > "\$d/config-listing"
got="\$(printf '%s' "\${ANTHROPIC_API_KEY:-}" | shasum -a 256 | awk '{print \$1}')"
[ "\$got" = "$CANARY_SHA" ] && echo yes > "\$d/auth-match" || echo no > "\$d/auth-match"
sid=""; prev=""
for a in "\$@"; do [ "\$prev" = "--session-id" ] && sid="\$a"; prev="\$a"; done
fx=arm-off; [ -f "\$CLAUDE_CONFIG_DIR/settings.json" ] && fx=arm-on
mkdir -p "\$CLAUDE_CONFIG_DIR/projects/stub"
cp "$DIR/fixtures/\$fx.jsonl" "\$CLAUDE_CONFIG_DIR/projects/stub/\$sid.jsonl"
echo "stub claude ok"
STUB
chmod +x "$T/bin/claude"

# run_case <name> [run-arms args...]: isolated operator env + stub on PATH.
run_case() {
  local name="$1"; shift
  rm -rf "$T/stub-log"
  HOME="$T/sentinel-home" PATH="$T/bin:$PATH" TMPDIR="$T/arms-tmp" \
    ANTHROPIC_API_KEY="$CANARY" CLAUDECODE=1 CLAUDE_CODE_ENTRYPOINT=cli \
    ANTHROPIC_BASE_URL=https://example.invalid \
    bash "$RUN_ARMS" --out "$T/out-$name" "$@" "test prompt" > "$T/$name.stdout" 2> "$T/$name.stderr"
  echo $? > "$T/$name.rc"
}

# ---- 1. full run, roots kept for inspection --------------------------------
run_case keep --keep
check "kept run exits 0" '[ "$(cat "$T/keep.rc")" = 0 ]'
check "stub called once per arm" '[ -d "$T/stub-log/call-0" ] && [ -d "$T/stub-log/call-1" ] && [ ! -d "$T/stub-log/call-2" ]'
ON="$T/stub-log/call-0"; OFF="$T/stub-log/call-1"
cp -R "$T/stub-log" "$T/stub-log-keep"
ON_HOME="$(cat "$ON/home")"; OFF_HOME="$(cat "$OFF/home")"
check "arms get distinct HOME" '[ "$ON_HOME" != "$OFF_HOME" ]'
check "arms get distinct CLAUDE_CONFIG_DIR" '[ "$(cat "$ON/config")" != "$(cat "$OFF/config")" ]'
check "CLAUDE_CONFIG_DIR is HOME/.claude in each arm" '[ "$(cat "$ON/config")" = "$ON_HOME/.claude" ] && [ "$(cat "$OFF/config")" = "$OFF_HOME/.claude" ]'
check "arm HOMEs are under the temp base, not the operator HOME" \
  'case "$ON_HOME$OFF_HOME" in *sentinel-home*) false ;; esac && case "$ON_HOME" in "$T/arms-tmp/"*) true ;; *) false ;; esac'
check "cwd is the arm's own task dir" '[ "$(cat "$ON/cwd")" = "$(dirname "$ON_HOME")/task" ] && [ "$(cat "$OFF/cwd")" = "$(dirname "$OFF_HOME")/task" ]'
check "OFF config dir was empty at launch" '[ ! -s "$OFF/config-listing" ]'
check "ON config has library skills, agents, hooks, settings" \
  'grep -qx "./hooks/block-general-purpose.sh" "$ON/config-listing" && grep -q "^./skills/[^/]*/SKILL.md$" "$ON/config-listing" && grep -q "^./agents/.*\.md$" "$ON/config-listing" && grep -qx "./settings.json" "$ON/config-listing"'
check "auth value reached both arms" '[ "$(cat "$ON/auth-match")" = yes ] && [ "$(cat "$OFF/auth-match")" = yes ]'
check "operator CLAUDECODE / CLAUDE_* / other ANTHROPIC_* dropped" \
  '! grep -E "^(CLAUDECODE|CLAUDE_CODE_ENTRYPOINT|ANTHROPIC_BASE_URL)$" "$ON/env-names" "$OFF/env-names"'
check "no general-purpose / agent flags in argv" '! grep -qi "general-purpose" "$ON/argv" "$OFF/argv"'
check "isolation.jsonl has a pass record per arm" \
  '[ "$(node -e '"'"'const l=require("fs").readFileSync(process.argv[1],"utf8").trim().split("\n").map(JSON.parse);console.log(l.map(r=>r.arm+":"+r.preflight+":"+(r.config_dir_listing_sha256.length===64)).join(","))'"'"' "$T/out-keep/isolation.jsonl")" = "on:pass:true,off:pass:true" ]'
check "compare ran" 'grep -q "output" "$T/keep.stdout"'
check "kept roots still exist" '[ -d "$ON_HOME" ] && [ -d "$OFF_HOME" ]'
check "canary never in output, artifacts, stub log, or kept roots" \
  '! grep -rqF "$CANARY" "$T/keep.stdout" "$T/keep.stderr" "$T/out-keep" "$T/stub-log-keep" "$ON_HOME/.." "$OFF_HOME/.."'
rm -rf "$(dirname "$ON_HOME")" "$(dirname "$OFF_HOME")"

# ---- 2. default run cleans up ------------------------------------------------
run_case clean
check "default run exits 0" '[ "$(cat "$T/clean.rc")" = 0 ]'
check "default run removes both arm roots" \
  '[ ! -e "$(dirname "$(cat "$T/stub-log/call-0/home")")" ] && [ ! -e "$(dirname "$(cat "$T/stub-log/call-1/home")")" ]'
check "temp base empty after cleanup" '[ -z "$(ls -A "$T/arms-tmp")" ]'

# ---- 3. missing auth fails before anything runs ------------------------------
rm -rf "$T/stub-log"
HOME="$T/sentinel-home" PATH="$T/bin:$PATH" TMPDIR="$T/arms-tmp" \
  env -u ANTHROPIC_API_KEY -u CLAUDE_CODE_OAUTH_TOKEN \
  bash "$RUN_ARMS" --out "$T/out-noauth" "test prompt" > "$T/noauth.out" 2>&1
rc=$?
check "no auth -> non-zero exit" '[ "$rc" -ne 0 ]'
check "no auth -> explains how to provide it" 'grep -q "export ANTHROPIC_API_KEY" "$T/noauth.out"'
check "no auth -> stub never called" '[ ! -d "$T/stub-log" ]'

# ---- 4. contaminated ancestor aborts the whole run ---------------------------
mkdir -p "$T/contam/base"
echo "# planted" > "$T/contam/CLAUDE.md"
rm -rf "$T/stub-log"
HOME="$T/sentinel-home" PATH="$T/bin:$PATH" TMPDIR="$T/contam/base" ANTHROPIC_API_KEY="$CANARY" \
  bash "$RUN_ARMS" --out "$T/out-contam" "test prompt" > "$T/contam.out" 2>&1
rc=$?
check "ancestor CLAUDE.md -> non-zero exit" '[ "$rc" -ne 0 ]'
check "ancestor CLAUDE.md -> stub never called" '[ ! -d "$T/stub-log" ]'
check "ancestor CLAUDE.md -> fail record written" 'grep -q "\"preflight\":\"fail\"" "$T/out-contam/isolation.jsonl"'
check "aborted run still cleans up" '[ -z "$(ls -A "$T/contam/base")" ]'

# ---- 5. planted library skill in OFF config (preflight unit) -----------------
ROOT="$(TMPDIR="$T/arms-tmp" iso_make_root)"
iso_export_task "$REPO" "$ROOT/task"
check "clean OFF root passes preflight" 'iso_preflight off "$ROOT" "$REPO"'
SKILL_DIR="$(find "$REPO/.claude/skills" -mindepth 1 -maxdepth 1 -type d | head -1)"
mkdir -p "$ROOT/home/.claude/skills"
cp -R "$SKILL_DIR" "$ROOT/home/.claude/skills/"
check "planted skill in OFF config fails preflight" '! iso_preflight off "$ROOT" "$REPO"'
check "failure names the OFF config dir" 'printf "%s\n" "${ISO_FAILS[@]}" | grep -q "OFF config dir is not empty"'
rm -rf "$ROOT/home/.claude/skills"
mkdir -p "$ROOT/task/sub/.claude"
check "nested .claude in task tree fails preflight" '! iso_preflight off "$ROOT" "$REPO"'
rm -rf "$ROOT"

# ---- 6. operator HOME untouched across every case ----------------------------
check "sentinel HOME unchanged" '[ "$(iso_listing_sha256 "$T/sentinel-home")" = "$SENTINEL_BEFORE" ]'

[ "$FAIL" = 0 ] && echo "run-arms-isolation-test: OK" || { echo "run-arms-isolation-test: FAILED"; exit 1; }
