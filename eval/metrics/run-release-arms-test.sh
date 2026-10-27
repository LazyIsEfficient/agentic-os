#!/usr/bin/env bash
# run-release-arms-test.sh — Tier 0 test of run-release-arms.sh. A stub
# `claude` first on PATH records argv, HOME, CLAUDE_CONFIG_DIR and the config
# listing, writes a fixture transcript, and in the seeded pilot edits app.js
# (the naive, exploitable route when the arm has no install manifest, i.e. the
# v3.0.1 arm; a safe one otherwise) so the exploit-check plumbing runs both
# ways. Never calls the real API. HOME is a sentinel dir that must stay
# unchanged, with a planted skill in its .claude that no arm may see.
# Runs the harness with the same bash as this test ($BASH), so
# `/bin/bash run-release-arms-test.sh` exercises bash 3.2.
# Conditions are strings run by check(); variables they read look unused to shellcheck.
# shellcheck disable=SC2034
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$DIR/../.." && pwd)"
RUN="$DIR/run-release-arms.sh"
SH="${BASH:-bash}"
# shellcheck source=lib/arm-isolation.sh
source "$DIR/lib/arm-isolation.sh"

T="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$T"' EXIT
FAIL=0
pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; FAIL=1; }
skip() { echo "SKIP  $1"; }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }
# rows <samples.jsonl> <js expression over the array `l`>: prints the result.
rows() { node -e 'const l=require("fs").readFileSync(process.argv[1],"utf8").trim().split("\n").filter(Boolean).map(JSON.parse);console.log(eval(process.argv[2]))' "$1" "$2"; }

CANARY="sk-ant-CANARY-$(node -e 'console.log(crypto.randomUUID())')"
CANARY_SHA="$(printf '%s' "$CANARY" | iso_sha256)"

mkdir -p "$T/bin" "$T/sentinel-home/.claude/skills/operator-only" "$T/arms-tmp"
echo "operator file" > "$T/sentinel-home/keep.txt"
printf -- '---\nname: operator-only\n---\n' > "$T/sentinel-home/.claude/skills/operator-only/SKILL.md"
SENTINEL_BEFORE="$(iso_listing_sha256 "$T/sentinel-home")"
FX="$DIR/fixtures/seeded-path-traversal"

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
sid=""; prev=""; resumed=no
for a in "\$@"; do
  [ "\$prev" = "--session-id" ] && sid="\$a"
  [ "\$prev" = "--resume" ] && { sid="\$a"; resumed=yes; }
  prev="\$a"
done
mkdir -p "\$CLAUDE_CONFIG_DIR/projects/stub"
# One distinct assistant turn per invocation (message ids differ), so turns
# from every resumed prompt must be counted.
n="\$(basename "\$d" | sed 's/^call-//')"
printf '{"type":"assistant","message":{"id":"m-%s","usage":{"input_tokens":100,"output_tokens":10},"content":[{"type":"tool_use","name":"Read","input":{"file_path":"/f%s"}}]}}\n' "\$n" "\$n" >> "\$CLAUDE_CONFIG_DIR/projects/stub/\$sid.jsonl"
[ "\$resumed" = yes ] && echo '{"type":"system","subtype":"compact_boundary"}' >> "\$CLAUDE_CONFIG_DIR/projects/stub/\$sid.jsonl"
if [ -f app.js ] && grep -q createHandler app.js; then
  if [ -f "\$CLAUDE_CONFIG_DIR/.agentic-os-manifest.json" ]; then cp "$FX/safe-app.js" app.js; else cp "$FX/vulnerable-app.js" app.js; fi
  # Model-controlled repo config: must never run when the harness scores the task.
  [ -d .git ] && printf '[core]\n\tfsmonitor = %s\n\thooksPath = %s\n' "$T/evil-hook.sh" "$T/evil-hooks" >> .git/config
fi
if [ -f "$T/fail-on-call" ] && [ "\$(cat "$T/fail-on-call")" = "\$n" ]; then echo "stub: injected failure" >&2; exit 1; fi
echo "stub claude ok"
STUB
chmod +x "$T/bin/claude"
mkdir -p "$T/evil-hooks"
printf '#!/bin/sh\necho ran >> "%s"\n' "$T/fsmonitor-ran" > "$T/evil-hook.sh"
chmod +x "$T/evil-hook.sh"
for h in pre-commit post-commit post-checkout reference-transaction; do cp "$T/evil-hook.sh" "$T/evil-hooks/$h"; done

# run_case <name> [args...]: isolated operator env + stub on PATH, stdin closed.
run_case() {
  local name="$1"; shift
  rm -rf "$T/stub-log"
  HOME="$T/sentinel-home" PATH="$T/bin:$PATH" TMPDIR="$T/arms-tmp" \
    ANTHROPIC_API_KEY="$CANARY" CLAUDECODE=1 CLAUDE_CODE_ENTRYPOINT=cli \
    "$SH" "$RUN" --out "$T/out-$name" "$@" < /dev/null > "$T/$name.stdout" 2> "$T/$name.stderr"
  echo $? > "$T/$name.rc"
}
ncalls() { find "$T/stub-log" -mindepth 1 -maxdepth 1 -name 'call-*' 2>/dev/null | wc -l | tr -d ' '; }

# v3.0.1 must be a local ref; CI checks out shallow without tags.
V301=v3.0.1
if ! git -C "$REPO" rev-parse --verify --quiet "$V301^{commit}" >/dev/null; then
  git -C "$REPO" fetch -q --depth=1 origin "refs/tags/$V301:refs/tags/$V301" 2>/dev/null || true
fi
HAVE_V301=0
git -C "$REPO" rev-parse --verify --quiet "$V301^{commit}" >/dev/null && HAVE_V301=1
[ "$HAVE_V301" = 1 ] || skip "tag $V301 unavailable (no local tag, fetch failed); v3.0.1 arm checks skipped"

# ---- 1. scenario prompt extraction -------------------------------------------
check "long-session-awareness has 10 scripted prompts" \
  '[ "$(node "$DIR/lib/scenario-prompts.mjs" "$DIR/scenarios/long-session-awareness.md" | node -e "console.log(JSON.parse(require(\"fs\").readFileSync(0,\"utf8\")).length)")" = 10 ]'
check "seeded-path-traversal has 1 scripted prompt" \
  '[ "$(node "$DIR/lib/scenario-prompts.mjs" "$DIR/scenarios/seeded-path-traversal/README.md" | node -e "console.log(JSON.parse(require(\"fs\").readFileSync(0,\"utf8\")).length)")" = 1 ]'

# ---- 2. exploit check on fixed inputs -----------------------------------------
XC="$DIR/scenarios/seeded-path-traversal/exploit-check.mjs"
for v in pristine vulnerable safe; do
  cp -R "$DIR/scenarios/seeded-path-traversal/app" "$T/x-$v"
  [ "$v" = pristine ] || cp "$FX/$v-app.js" "$T/x-$v/app.js"
  node "$XC" "$T/x-$v" --json > "$T/x-$v.json"; echo $? > "$T/x-$v.rc"
done
check "exploit check: unimplemented feature -> error (exit 2)" '[ "$(cat "$T/x-pristine.rc")" = 2 ] && grep -q "\"exploit\":\"error\"" "$T/x-pristine.json"'
check "exploit check: naive route -> fail (exit 1)" '[ "$(cat "$T/x-vulnerable.rc")" = 1 ] && grep -q "\"exploit\":\"fail\"" "$T/x-vulnerable.json"'
check "exploit check: contained route -> pass (exit 0)" '[ "$(cat "$T/x-safe.rc")" = 0 ] && grep -q "\"exploit\":\"pass\"" "$T/x-safe.json"'
check "exploit check leaves the task dir untouched" '[ -z "$(find "$T/x-vulnerable" -name "secret.txt" -o -name "outer.txt" -o -name uploads-private)" ]'

# Planted symlinks must not redirect the check's writes (regression: cpSync
# kept absolute links and writeFileSync/mkdirSync followed them).
mkdir -p "$T/victimdir"
echo "victim file" > "$T/victim.txt"; echo "victim dir file" > "$T/victimdir/hello.txt"
VICTIMS_BEFORE="$(cat "$T/victim.txt" "$T/victimdir/hello.txt"; ls -A "$T/victimdir")"
cp -R "$DIR/scenarios/seeded-path-traversal/app" "$T/x-links"
cp "$FX/safe-app.js" "$T/x-links/app.js"
rm -rf "$T/x-links/uploads"
ln -s "$T/victim.txt" "$T/x-links/secret.txt"
ln -s "$T/victimdir" "$T/x-links/uploads"
node "$XC" "$T/x-links" --json > "$T/x-links.json"; echo $? > "$T/x-links.rc"
check "exploit check: planted symlinks -> error (exit 2) with a reason" \
  '[ "$(cat "$T/x-links.rc")" = 2 ] && grep -q "\"exploit\":\"error\"" "$T/x-links.json" && grep -q "symlink" "$T/x-links.json"'
check "exploit check: symlink victims untouched" '[ "$(cat "$T/victim.txt" "$T/victimdir/hello.txt"; ls -A "$T/victimdir")" = "$VICTIMS_BEFORE" ]'

# The app's process group dies with the check, on the normal path and on the
# overall-timeout path (regression: only the direct child was killed).
gc_app() { # gc_app <dir> <pidfile> <respond yes|no>
  cp -R "$DIR/scenarios/seeded-path-traversal/app" "$1"
  { printf "require('node:fs').writeFileSync(%s, String(require('node:child_process').spawn(process.execPath, ['-e', 'setInterval(()=>{},1000)'], {stdio:'ignore'}).pid));\n" "'$2'"
    if [ "$3" = yes ]; then cat "$FX/safe-app.js"; else echo "module.exports = { createHandler: () => () => {} };"; fi
  } > "$1/app.js"
}
gone() { local i; for i in $(seq 1 30); do kill -0 "$1" 2>/dev/null || return 0; sleep 0.1; done; return 1; }
gc_app "$T/x-gc" "$T/gc.pid" yes
node "$XC" "$T/x-gc" --json > "$T/x-gc.json"; echo $? > "$T/x-gc.rc"
check "exploit check: grandchild of the app is killed (normal path)" '[ "$(cat "$T/x-gc.rc")" = 0 ] && [ -s "$T/gc.pid" ] && gone "$(cat "$T/gc.pid")"'
mkdir -p "$T/xc-tmp"
gc_app "$T/x-gc2" "$T/gc2.pid" no
TMPDIR="$T/xc-tmp" EXPLOIT_CHECK_TIMEOUT_MS=2000 node "$XC" "$T/x-gc2" --json > "$T/x-gc2.json"; echo $? > "$T/x-gc2.rc"
check "exploit check: overall timeout -> error, grandchild killed, work dir removed" \
  '[ "$(cat "$T/x-gc2.rc")" = 2 ] && grep -q timeout "$T/x-gc2.json" && [ -s "$T/gc2.pid" ] && gone "$(cat "$T/gc2.pid")" && [ -z "$(ls -A "$T/xc-tmp")" ]'

# ---- 2b. summary counts only complete samples ---------------------------------
printf '%s\n' \
  '{"scenario":"s","arm":"a","ref":"r","repo_sha":"x","prompts":1,"exit_codes":[0],"exit_code":0,"metrics":{"turns":40,"tokens":{"output":1}}}' \
  '{"scenario":"s","arm":"a","ref":"r","repo_sha":"x","prompts":1,"exit_codes":[1],"exit_code":1,"metrics":{"turns":4,"tokens":{"output":1}}}' \
  '{"scenario":"s","arm":"a","ref":"r","repo_sha":"x","prompts":3,"exit_codes":[0],"exit_code":0,"metrics":{"turns":2,"tokens":{"output":1}}}' \
  > "$T/mixed.jsonl"
node "$DIR/summarize-samples.mjs" "$T/mixed.jsonl" --json > "$T/mixed.json"
check "summary: metrics over complete samples only (turns mean 40, n=1)" \
  '[ "$(node -e "const g=require(process.argv[1]).groups[0];console.log(g.metrics.turns.mean+\",\"+g.metrics.turns.n+\",\"+g.complete)" "$T/mixed.json")" = "40,1,1" ]'
check "summary: incomplete samples counted with reasons" \
  '[ "$(node -e "const g=require(process.argv[1]).groups[0];console.log(JSON.stringify(g.incomplete))" "$T/mixed.json")" = "{\"count\":2,\"reasons\":{\"1 of 3 prompts ran\":1,\"prompt 1 of 1 exited 1\":1}}" ]'

# ---- 3. per-ref manifest: preflight is exact for each ref and flag set --------
SRC_HEAD="$T/src-head"; mkdir -p "$SRC_HEAD"; iso_export_ref "$REPO" HEAD "$SRC_HEAD"
ROOT="$(TMPDIR="$T/arms-tmp" iso_make_root)"
iso_install_library "$SRC_HEAD" "$ROOT" "$T/i1.log" --with-games
check "HEAD + --with-games passes preflight with packs=games" 'iso_preflight on "$ROOT" "$SRC_HEAD" games'
check "HEAD + --with-games fails a core-only preflight" '! iso_preflight on "$ROOT" "$SRC_HEAD" ""'
check "core-only preflight names the games pack files" 'printf "%s\n" "${ISO_FAILS[@]}" | grep -q "outside the install manifest: .*skills/game-balancer"'
rm -rf "$ROOT"
if [ "$HAVE_V301" = 1 ]; then
  SRC_V="$T/src-v301"; mkdir -p "$SRC_V"; iso_export_ref "$REPO" "$V301" "$SRC_V"
  ROOT="$(TMPDIR="$T/arms-tmp" iso_make_root)"
  iso_install_library "$SRC_V" "$ROOT" "$T/i2.log"
  check "v3.0.1 install passes its own per-ref preflight" 'iso_preflight on "$ROOT" "$SRC_V" ""'
  check "v3.0.1 manifest: no installer manifest in the allowlist" '! iso_on_allowlist "$SRC_V" | grep -q agentic-os-manifest'
  check "v3.0.1 install fails a preflight computed from HEAD" '! iso_preflight on "$ROOT" "$SRC_HEAD" ""'
  rm -rf "$ROOT"
fi
check "HEAD shipped commands come from its installer" \
  '[ "$(iso_shipped_commands "$SRC_HEAD" | tr "\n" " ")" = "commands/skill-new.md commands/agent-new.md commands/state.md " ]'

# ---- 4. cost gate: no --yes on a non-tty stdin sends nothing -------------------
ARMS=(main=HEAD "mainall=HEAD:--with-marketing,--with-games")
[ "$HAVE_V301" = 1 ] && ARMS=("v301=$V301" "${ARMS[@]}")
NA="${#ARMS[@]}"
run_case gate --runs 2 --scenario seeded-path-traversal --scenario long-session-awareness "${ARMS[@]}"
check "no --yes -> non-zero exit" '[ "$(cat "$T/gate.rc")" != 0 ]'
check "no --yes -> stub never called" '[ ! -d "$T/stub-log" ]'
check "plan prints the total invocation count (arms x runs x prompts)" \
  'grep -qF "TOTAL: $((NA * 2 * 11)) claude -p invocations ($NA arms x 2 runs x 11 prompts" "$T/gate.stdout"'
check "cost gate prints the default per-invocation budget and its ceiling" \
  'grep -qF "BUDGET: --max-budget-usd 5 per invocation; ceiling if every invocation hit it: \$$((NA * 2 * 11 * 5)).00" "$T/gate.stdout"'
check "no --yes -> temp base empty" '[ -z "$(ls -A "$T/arms-tmp")" ]'

# ---- 5. bad specs fail before anything is set up -------------------------------
run_case badflag --yes --scenario seeded-path-traversal main=HEAD:--force
check "non-pack install flag rejected" '[ "$(cat "$T/badflag.rc")" != 0 ] && grep -q "only --with-<pack>" "$T/badflag.stderr" && [ ! -d "$T/stub-log" ]'
run_case badref --yes --scenario seeded-path-traversal x=refs/heads/no-such-branch-xyz
check "unresolvable ref rejected" '[ "$(cat "$T/badref.rc")" != 0 ] && grep -q "does not resolve" "$T/badref.stderr" && [ ! -d "$T/stub-log" ]'
run_case badpack --yes --scenario seeded-path-traversal main=HEAD:--with-nosuchpack
check "unknown pack rejected" '[ "$(cat "$T/badpack.rc")" != 0 ] && grep -q "no pack" "$T/badpack.stderr"'
check "rejected specs leave the temp base empty" '[ -z "$(ls -A "$T/arms-tmp")" ]'

# ---- 6. named arms, --runs 2, seeded pilot, kept roots -------------------------
run_case main --yes --keep --runs 2 --scenario seeded-path-traversal "${ARMS[@]}"
S="$T/out-main/samples.jsonl"
check "named-arm run exits 0" '[ "$(cat "$T/main.rc")" = 0 ]'
[ "$(cat "$T/main.rc")" = 0 ] || tail -20 "$T/main.stderr" "$T/main.stdout"
check "stub called once per sample ($((NA * 2)))" '[ "$(ncalls)" = $((NA * 2)) ]'
check "samples.jsonl: 2 rows per arm" \
  '[ "$(rows "$S" "Object.values(l.reduce((a,r)=>(a[r.arm]=(a[r.arm]||0)+1,a),{})).join(\",\")")" = "$(printf "2,%.0s" $(seq 1 "$NA") | sed "s/,$//")" ]'
check "samples are interleaved: each round of $NA rows holds every arm once" \
  '[ "$(rows "$S" "[0,1].every(k=>new Set(l.slice(k*$NA,(k+1)*$NA).map(r=>r.arm)).size===$NA && l.slice(k*$NA,(k+1)*$NA).every(r=>r.sample===k+1))")" = true ]'
check "arm order rotates between rounds" \
  '[ "$NA" -lt 2 ] || [ "$(rows "$S" "l[0].arm!==l[$NA].arm")" = true ]'
check "row order field is the run sequence" '[ "$(rows "$S" "l.every((r,i)=>r.order===i)")" = true ]'
HEAD_SHA="$(git -C "$REPO" rev-parse HEAD)"
check "repo_sha is the full sha of each arm's ref" \
  '[ "$(rows "$S" "l.filter(r=>r.ref===\"HEAD\").every(r=>r.repo_sha===\"$HEAD_SHA\")")" = true ]'
check "flags recorded as an array" \
  '[ "$(rows "$S" "JSON.stringify(l.find(r=>r.arm===\"mainall\").flags)")" = "[\"--with-marketing\",\"--with-games\"]" ] && [ "$(rows "$S" "JSON.stringify(l.find(r=>r.arm===\"main\").flags)")" = "[]" ]'
check "every row has session id, metrics, exit_code 0, a task base" \
  '[ "$(rows "$S" "l.every(r=>/^[0-9a-f-]{36}$/.test(r.session_id)&&r.metrics&&r.metrics.tokens.output>0&&r.exit_code===0&&/^[0-9a-f]{40}$/.test(r.task_base)&&r.scenario===\"seeded-path-traversal\"&&r.prompts===1)")" = true ]'
check "main and mainall rows: exploit pass (stub wrote the contained route)" \
  '[ "$(rows "$S" "l.filter(r=>r.arm!==\"v301\").every(r=>r.exploit===\"pass\")")" = true ]'
if [ "$HAVE_V301" = 1 ]; then
  check "v301 rows: exploit fail (stub wrote the naive route)" \
    '[ "$(rows "$S" "l.filter(r=>r.arm===\"v301\").every(r=>r.exploit===\"fail\"&&r.exploit_detail.leaked.length>0)")" = true ]'
fi
check "every row has a scan record: gitleaks/semgrep are a count, unavailable, or error" \
  '[ "$(rows "$S" "l.every(r=>r.scan&&Number.isInteger(r.scan.exit)&&[r.scan.gitleaks,r.scan.semgrep].every(v=>Number.isInteger(v)||v===\"unavailable\"||v===\"error\"))")" = true ]'
check "scoring never ran the task's model-written .git/config (fsmonitor / hooksPath)" \
  '[ ! -e "$T/fsmonitor-ran" ] && grep -q fsmonitor "$(dirname "$(cat "$T/stub-log/call-0/home")")/task/.git/config"'
check "default per-invocation budget reaches claude" '[ "$(grep -lx -- "--max-budget-usd" "$T"/stub-log/call-*/argv | wc -l | tr -d " ")" = $((NA * 2)) ]'
check "isolation.jsonl: one pass record per sample" \
  '[ "$(rows "$T/out-main/isolation.jsonl" "l.length===$((NA * 2))&&l.every(r=>r.preflight===\"pass\")")" = true ]'

# Per-call config listings, matched to arms through the session id.
ARMS_OK=1
for d in "$T"/stub-log/call-*; do
  sid="$(awk 'p{print; exit} $0=="--session-id"{p=1}' "$d/argv")"
  arm="$(rows "$S" "l.find(r=>r.session_id===\"$sid\").arm")"
  L="$d/config-listing"
  case "$arm" in
    v301) grep -qx "./skills/seo-ops/SKILL.md" "$L" && ! grep -qx "./.agentic-os-manifest.json" "$L" || ARMS_OK=0 ;;
    main) ! grep -q "^./skills/seo-ops" "$L" && ! grep -q "^./skills/game-balancer" "$L" && grep -qx "./.agentic-os-manifest.json" "$L" || ARMS_OK=0 ;;
    mainall) grep -qx "./skills/seo-ops/SKILL.md" "$L" && grep -qx "./skills/game-balancer/SKILL.md" "$L" || ARMS_OK=0 ;;
    *) ARMS_OK=0 ;;
  esac
done
check "each arm's config is its own ref's install (v301: seo-ops, no manifest; main: core only; mainall: both packs)" '[ "$ARMS_OK" = 1 ]'
if [ "$HAVE_V301" = 1 ]; then
  ONLY_V301="$(LC_ALL=C comm -23 <(git -C "$REPO" ls-tree -r --name-only "$V301" .claude/skills .claude/agents | sed 's|^\.claude/||' | LC_ALL=C sort) \
    <(git -C "$REPO" ls-tree -r --name-only HEAD .claude/skills .claude/agents | sed 's|^\.claude/||' | LC_ALL=C sort) | head -1)"
  if [ -n "$ONLY_V301" ]; then
    V301_CALL="$(for d in "$T"/stub-log/call-*; do grep -qx "./.agentic-os-manifest.json" "$d/config-listing" || { echo "$d"; break; }; done)"
    check "v301 config holds a file only v3.0.1 ships ($ONLY_V301)" '[ -n "$V301_CALL" ] && grep -qxF "./$ONLY_V301" "$V301_CALL/config-listing"'
  else
    skip "no file is in v3.0.1 but not HEAD; the no-manifest check above stands in"
  fi
fi
check "every call has its own HOME under the temp base, CLAUDE_CONFIG_DIR = HOME/.claude" \
  '[ "$(cat "$T"/stub-log/call-*/home | sort -u | wc -l | tr -d " ")" = $((NA * 2)) ] && ( for d in "$T"/stub-log/call-*; do h="$(cat "$d/home")"; case "$h" in "$T/arms-tmp/"?*) ;; *) exit 1 ;; esac; [ "$(cat "$d/config")" = "$h/.claude" ] || exit 1; done )'
check "no arm sees the operator's ~/.claude (planted skill absent everywhere)" '! grep -q "operator-only" "$T"/stub-log/call-*/config-listing'
check "auth reached every call; operator CLAUDECODE / CLAUDE_* dropped" \
  '! grep -L yes "$T"/stub-log/call-*/auth-match | grep -q . && ! grep -qE "^(CLAUDECODE|CLAUDE_CODE_ENTRYPOINT)$" "$T"/stub-log/call-*/env-names'
check "summary.json written" '[ -s "$T/out-main/summary.json" ]'
check "summary has one group per arm with n=2 metrics" \
  '[ "$(node -e "const s=require(process.argv[1]);console.log(s.groups.length===$NA&&s.groups.every(g=>g.samples===2&&g.metrics.output_tokens.n===2))" "$T/out-main/summary.json")" = true ]'

# ---- 7. the summary is deterministic --------------------------------------------
node "$DIR/summarize-samples.mjs" "$S" --json > "$T/sum1.json"
node "$DIR/summarize-samples.mjs" "$S" --json > "$T/sum2.json"
node -e 'const fs=require("fs");const l=fs.readFileSync(process.argv[1],"utf8").trim().split("\n").reverse().map(JSON.parse).map(r=>({...r,recorded_utc:"1999-01-01T00:00:00.000Z"}));fs.writeFileSync(process.argv[2],l.map(r=>JSON.stringify(r)).join("\n")+"\n")' "$S" "$T/shuffled.jsonl"
node "$DIR/summarize-samples.mjs" "$T/shuffled.jsonl" --json > "$T/sum3.json"
check "summary: same input -> byte-identical output" 'cmp -s "$T/sum1.json" "$T/sum2.json"'
check "summary: row order and timestamps do not change it" 'cmp -s "$T/sum1.json" "$T/sum3.json"'
check "summary.json from the run matches a re-run" 'cmp -s "$T/sum1.json" "$T/out-main/summary.json"'
check "canary never in output, artifacts, stub log, or kept roots" \
  '! grep -rqF "$CANARY" "$T/main.stdout" "$T/main.stderr" "$T/out-main" "$T/stub-log" "$T/arms-tmp"'
for h in $(cat "$T"/stub-log/call-*/home); do
  case "$h" in "$T/arms-tmp/"?*) rm -rf "$(dirname "$h")" ;; *) fail "refusing to remove root outside $T/arms-tmp: $h" ;; esac
done

# ---- 8. multi-prompt scenario continues one session ------------------------------
run_case long --yes --max-turns 7 --max-budget-usd 0.5 --scenario long-session-awareness main=HEAD
check "long-session run exits 0" '[ "$(cat "$T/long.rc")" = 0 ]'
check "one invocation per scripted prompt (10)" '[ "$(ncalls)" = 10 ]'
SID0="$(awk 'p{print; exit} $0=="--session-id"{p=1}' "$T/stub-log/call-0/argv")"
check "prompt 1 starts the session, prompts 2-10 --resume the same id" \
  '[ -n "$SID0" ] && ( for n in 1 2 3 4 5 6 7 8 9; do [ "$(awk '"'"'p{print; exit} $0=="--resume"{p=1}'"'"' "$T/stub-log/call-$n/argv")" = "$SID0" ] || exit 1; done )'
check "--max-turns and --max-budget-usd reach every invocation" \
  '[ "$(grep -lx -- "--max-turns" "$T"/stub-log/call-*/argv | wc -l | tr -d " ")" = 10 ] && [ "$(grep -lx -- "--max-budget-usd" "$T"/stub-log/call-*/argv | wc -l | tr -d " ")" = 10 ] && grep -qx 7 "$T/stub-log/call-9/argv"'
check "prompts are the scenario's own text" 'grep -q "^Survey eval/metrics/" "$T/stub-log/call-0/argv" && grep -q "^In BATCH-OPERATOR.md" "$T/stub-log/call-9/argv"'
check "repo-local task is a scrubbed HEAD export" 'grep -qx "$(cat "$T/stub-log/call-0/home" | xargs dirname)/task" "$T/stub-log/call-0/cwd"'
check "long-session row: 10 prompts, 10 exit codes, compaction counted, no exploit/scan" \
  '[ "$(rows "$T/out-long/samples.jsonl" "const r=l[0];l.length===1&&r.prompts===10&&r.exit_codes.length===10&&r.compact_boundaries===9&&r.exploit===null&&r.scan===null&&r.task_base===null&&r.status===\"complete\"")" = true ]'
check "turns from every resumed prompt are counted (10 distinct turns, 100 output tokens)" \
  '[ "$(rows "$T/out-long/samples.jsonl" "l[0].metrics.turns+\",\"+l[0].metrics.tokens.output")" = "10,100" ]'
check "default run removes every sample root and scratch dir" '[ -z "$(ls -A "$T/arms-tmp")" ]'

# ---- 8b. a failed prompt stops the sample: no --resume past it -------------------
echo 2 > "$T/fail-on-call"
run_case stop --yes --no-max-budget --scenario long-session-awareness main=HEAD
rm -f "$T/fail-on-call"
check "failed prompt 3 -> exactly 3 invocations, none resumed after it" '[ "$(ncalls)" = 3 ]'
check "--no-max-budget passes no budget flag" '! grep -qx -- "--max-budget-usd" "$T"/stub-log/call-*/argv'
check "stopped sample row: incomplete, 3 of 10 prompts run, reason names the prompt" \
  '[ "$(rows "$T/out-stop/samples.jsonl" "const r=l[0];[r.status,r.prompts_run,r.exit_code,r.incomplete_reason].join(\"|\")")" = "incomplete|3|1|prompt 3 of 10 exited 1" ]'
check "stopped sample is excluded from summary metrics and counted as incomplete" \
  '[ "$(node -e "const g=require(process.argv[1]).groups[0];console.log(g.complete+\",\"+g.metrics.turns.n+\",\"+g.incomplete.count)" "$T/out-stop/summary.json")" = "0,0,1" ]'

# ---- 9. operator HOME untouched --------------------------------------------------
check "sentinel HOME unchanged" '[ "$(iso_listing_sha256 "$T/sentinel-home")" = "$SENTINEL_BEFORE" ]'

[ "$FAIL" = 0 ] && echo "run-release-arms-test: OK" || { echo "run-release-arms-test: FAILED"; exit 1; }
