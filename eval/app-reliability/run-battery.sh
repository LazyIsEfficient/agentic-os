#!/usr/bin/env bash
# Deterministic measurement battery for the app-reliability experiment.
#
# Scores ONE app and emits ONE JSON line on stdout:
#   {"app":"<dir>","build":bool,"contract":bool,"chaos":bool,"chaos_detail":"...",
#    "completeness":{...booleans...},"score":<#checks passed>}
#
# Score = number of headline checks passed: build + contract + chaos + each
# completeness boolean. The chaos check is the headline: a genuinely
# fault-tolerant app passes it; a plausible-but-fake one fails it.
#
# Usage:
#   run-battery.sh <app_dir>     score one app (provisions the broker if needed)
#   run-battery.sh --teardown    remove the shared RabbitMQ container and exit
#
# Bash + node only. No Python. Every wait is bounded; processes are killed on
# exit via a trap so the battery can never hang or leave orphans.

set -u
# Job control ON so each backgrounded host process (`npm run worker`, `npm start`)
# becomes its own process-group leader (PGID == its PID). We then signal the whole
# group with `kill -SIG -PGID`, which reliably reaps the npm-spawned child (tsx /
# next) even if npm does not forward the signal. Without this, killing only the
# npm PID can orphan the real worker/web child and corrupt the chaos result.
set -m

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
RMQ_CONTAINER="${RMQ_CONTAINER:-rabbitmq}"   # default: the user's running broker (docker-compose.yml at repo root)
EXTERNAL_BROKER="${EXTERNAL_BROKER:-1}"      # 1 = NEVER create/destroy the container; it is externally managed
RMQ_IMAGE="rabbitmq:3.13-management"
PORT="${PORT:-3000}"
BASE_URL="http://localhost:${PORT}"
STREAM_PORT=5552

# Monotonic counter so concurrent-ish invocations get distinct stream names even
# within the same PID-second. Stored next to the script.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COUNTER_FILE="${SCRIPT_DIR}/.battery-counter"

# ---------------------------------------------------------------------------
# Logging — everything diagnostic goes to stderr so stdout stays a clean single
# JSON line.
# ---------------------------------------------------------------------------
log() { printf '[battery] %s\n' "$*" >&2; }

# ---------------------------------------------------------------------------
# Process / temp tracking for the trap.
# ---------------------------------------------------------------------------
WORKER_PID=""
WEB_PID=""
WORKER_LOG=""
WEB_LOG=""
APP_DIR_ABS=""

# Kill a backgrounded job by its PGID (== the job-leader PID under `set -m`):
# TERM the group, wait up to ~10s for it to die, then KILL the group. Targets the
# negative PID so the npm-spawned child (tsx / next) goes down with the leader.
kill_group() {
  local pid="$1"
  [ -z "$pid" ] && return 0
  kill -0 "$pid" 2>/dev/null || return 0
  kill -TERM "-${pid}" 2>/dev/null || kill -TERM "$pid" 2>/dev/null || true
  local w=0
  while kill -0 "$pid" 2>/dev/null && [ "$w" -lt 20 ]; do sleep 0.5; w=$((w + 1)); done
  if kill -0 "$pid" 2>/dev/null; then
    kill -KILL "-${pid}" 2>/dev/null || kill -KILL "$pid" 2>/dev/null || true
  fi
}

cleanup() {
  kill_group "$WORKER_PID"
  kill_group "$WEB_PID"
  # Belt-and-suspenders: reap any next dev-server child still bound to our port.
  pkill -f "next start -p ${PORT}" 2>/dev/null || true
  [ -n "$WORKER_LOG" ] && rm -f "$WORKER_LOG" 2>/dev/null || true
  [ -n "$WEB_LOG" ] && rm -f "$WEB_LOG" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# ---------------------------------------------------------------------------
# Teardown mode
# ---------------------------------------------------------------------------
if [ "${1:-}" = "--teardown" ]; then
  if [ "$EXTERNAL_BROKER" = 1 ]; then
    log "EXTERNAL_BROKER=1 — leaving externally-managed container ${RMQ_CONTAINER} untouched"
  else
    log "tearing down container ${RMQ_CONTAINER}"
    docker rm -fv "$RMQ_CONTAINER" >/dev/null 2>&1 || true
  fi
  rm -f "$COUNTER_FILE" 2>/dev/null || true
  log "teardown complete"
  exit 0
fi

APP_DIR="${1:-}"
if [ -z "$APP_DIR" ]; then
  echo "usage: $0 <app_dir> | --teardown" >&2
  exit 2
fi
if [ ! -d "$APP_DIR" ]; then
  echo "error: app_dir not a directory: $APP_DIR" >&2
  exit 2
fi
APP_DIR_ABS="$(cd "$APP_DIR" && pwd)"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Wait until `cmd` exits 0 or timeout (seconds). Returns 0 on success, 1 on timeout.
wait_until() {
  local timeout="$1"; shift
  local deadline=$(( $(date +%s) + timeout ))
  while [ "$(date +%s)" -lt "$deadline" ]; do
    if "$@" >/dev/null 2>&1; then return 0; fi
    sleep 1
  done
  return 1
}

# POST a note; echo the HTTP status code. Bounded by curl --max-time.
post_note() {
  local title="$1" body="$2"
  curl -s -o /dev/null -w '%{http_code}' --max-time 10 \
    -X POST "${BASE_URL}/api/notes" \
    -H 'content-type: application/json' \
    -d "{\"title\":$(json_str "$title"),\"body\":$(json_str "$body")}"
}

# JSON-encode a string safely via node (handles quotes/special chars).
json_str() {
  node -e 'process.stdout.write(JSON.stringify(process.argv[1]))' "$1"
}

# Fetch GET /api/notes and print the persisted count, or "ERR".
get_count() {
  local out
  out="$(curl -s --max-time 10 "${BASE_URL}/api/notes")" || { echo "ERR"; return 1; }
  node -e '
    let raw="";
    process.stdin.on("data",d=>raw+=d);
    process.stdin.on("end",()=>{
      try { const a=JSON.parse(raw); process.stdout.write(String(Array.isArray(a)?a.length:"ERR")); }
      catch { process.stdout.write("ERR"); }
    });
  ' <<<"$out"
}

# True (exit 0) when the API is answering GET with a JSON array.
api_ready() {
  local out
  out="$(curl -s --max-time 5 "${BASE_URL}/api/notes")" || return 1
  node -e '
    let raw="";
    process.stdin.on("data",d=>raw+=d);
    process.stdin.on("end",()=>{ try { process.exit(Array.isArray(JSON.parse(raw))?0:1);} catch { process.exit(1);} });
  ' <<<"$out"
}

# ---------------------------------------------------------------------------
# 1. Provision RabbitMQ (stream plugin) if not already up.
# ---------------------------------------------------------------------------
provision_broker() {
  if docker ps --format '{{.Names}}' | grep -qx "$RMQ_CONTAINER"; then
    log "container ${RMQ_CONTAINER} already running"
  elif [ "$EXTERNAL_BROKER" = 1 ]; then
    log "FATAL: EXTERNAL_BROKER=1 but ${RMQ_CONTAINER} is not running — start it first (docker compose up -d)"
    return 1
  else
    # Remove any stopped container of the same name first, INCLUDING its anonymous
    # volumes (-v). A leftover /var/lib/rabbitmq volume from a prior aborted run can
    # carry a bad-permission .erlang.cookie that makes the node fail to boot
    # ("Error when reading ... .erlang.cookie: eacces"). Starting clean avoids it.
    docker rm -fv "$RMQ_CONTAINER" >/dev/null 2>&1 || true
    log "starting ${RMQ_CONTAINER} (${RMQ_IMAGE})"
    docker run -d --name "$RMQ_CONTAINER" \
      -p ${STREAM_PORT}:${STREAM_PORT} -p 5672:5672 \
      -e RABBITMQ_SERVER_ADDITIONAL_ERL_ARGS='-rabbitmq_stream advertised_host localhost' \
      "$RMQ_IMAGE" >/dev/null
  fi

  # Wait for the node to be up enough to run rabbitmqctl, then enable the plugin.
  log "waiting for broker node to come up..."
  if ! wait_until 90 docker exec "$RMQ_CONTAINER" rabbitmq-diagnostics -q ping; then
    log "FATAL: broker did not respond to ping within timeout"
    return 1
  fi
  docker exec "$RMQ_CONTAINER" rabbitmq-plugins enable rabbitmq_stream >/dev/null 2>&1 || true

  # Wait until the stream listener on 5552 is actually live.
  log "waiting for stream listener on ${STREAM_PORT}..."
  stream_listener_up() {
    docker exec "$RMQ_CONTAINER" rabbitmq-diagnostics listeners 2>/dev/null \
      | grep -i stream | grep -q "${STREAM_PORT}"
  }
  if ! wait_until 60 stream_listener_up; then
    log "FATAL: stream listener on ${STREAM_PORT} not live within timeout"
    return 1
  fi
  log "broker ready; stream listener live on ${STREAM_PORT}"
  return 0
}

# ---------------------------------------------------------------------------
# Per-invocation environment: unique stream name, clean persistence.
# ---------------------------------------------------------------------------
next_counter() {
  local n=0
  if [ -f "$COUNTER_FILE" ]; then n="$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)"; fi
  n=$((n + 1))
  echo "$n" >"$COUNTER_FILE"
  echo "$n"
}

# ---------------------------------------------------------------------------
# Completeness checks (static inspection of the app source).
# Each echoes "true" or "false".
# ---------------------------------------------------------------------------
# Search source files only (skip node_modules / .next / data).
src_grep() {
  grep -rIl --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=data \
    "$1" "$APP_DIR_ABS" >/dev/null 2>&1 && echo true || echo false
}
src_grep_e() {
  grep -rIlE --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=data \
    "$1" "$APP_DIR_ABS" >/dev/null 2>&1 && echo true || echo false
}

check_uses_stream_client() {
  # package.json dependency AND an actual import in source.
  local in_pkg in_src
  in_pkg=$(node -e '
    try {
      const p=require(process.argv[1]+"/package.json");
      const d={...(p.dependencies||{}),...(p.devDependencies||{})};
      process.stdout.write(d["rabbitmq-stream-js-client"]?"true":"false");
    } catch { process.stdout.write("false"); }
  ' "$APP_DIR_ABS")
  in_src=$(src_grep_e 'rabbitmq-stream-js-client')
  [ "$in_pkg" = "true" ] && [ "$in_src" = "true" ] && echo true || echo false
}

check_declares_stream() {
  # Declares a STREAM as the write path (createStream / declarePublisher) AND does
  # NOT use amqplib assertQueue as the write path.
  local has_stream has_amqp_queue
  has_stream=$(src_grep_e 'createStream|declarePublisher|declareConsumer')
  has_amqp_queue=$(src_grep_e 'amqplib|assertQueue')
  [ "$has_stream" = "true" ] && [ "$has_amqp_queue" = "false" ] && echo true || echo false
}

check_offset_tracking() {
  # Worker stores/commits or queries an offset.
  src_grep_e 'storeOffset|queryOffset'
}

check_post_awaits_confirm() {
  # POST path awaits a publisher confirm (publish_confirm listener or a
  # confirming publish helper) somewhere in the source.
  src_grep_e 'publish_confirm|publishingId|ConfirmingPublisher'
}

check_on_disk_persistence() {
  # Persistence is on-disk under ./data (writes a file there).
  local writes_disk references_data
  writes_disk=$(src_grep_e 'writeFile|writeFileSync|sqlite|better-sqlite3|fs\.rename|renameSync')
  references_data=$(src_grep_e 'dataDir|/data|data/|NOTES_DATA_DIR')
  [ "$writes_disk" = "true" ] && [ "$references_data" = "true" ] && echo true || echo false
}

check_scripts_exist() {
  node -e '
    try {
      const p=require(process.argv[1]+"/package.json");
      const s=p.scripts||{};
      process.stdout.write((s.worker && s.start)?"true":"false");
    } catch { process.stdout.write("false"); }
  ' "$APP_DIR_ABS"
}

# ---------------------------------------------------------------------------
# Emit the final JSON line and exit.
# ---------------------------------------------------------------------------
emit() {
  local build="$1" contract="$2" chaos="$3" chaos_detail="$4"
  local c_client="$5" c_stream="$6" c_offset="$7" c_confirm="$8" c_disk="$9" c_scripts="${10}"

  # Score = count of true among build, contract, chaos, and 6 completeness checks.
  local score=0
  for v in "$build" "$contract" "$chaos" "$c_client" "$c_stream" "$c_offset" "$c_confirm" "$c_disk" "$c_scripts"; do
    [ "$v" = "true" ] && score=$((score + 1))
  done

  APP_REL="$APP_DIR" \
  BUILD="$build" CONTRACT="$contract" CHAOS="$chaos" CHAOS_DETAIL="$chaos_detail" \
  C_CLIENT="$c_client" C_STREAM="$c_stream" C_OFFSET="$c_offset" \
  C_CONFIRM="$c_confirm" C_DISK="$c_disk" C_SCRIPTS="$c_scripts" SCORE="$score" \
  node -e '
    const b=v=>process.env[v]==="true";
    const o={
      app: process.env.APP_REL,
      build: b("BUILD"),
      contract: b("CONTRACT"),
      chaos: b("CHAOS"),
      chaos_detail: process.env.CHAOS_DETAIL,
      completeness: {
        uses_stream_client: b("C_CLIENT"),
        declares_stream: b("C_STREAM"),
        offset_tracking: b("C_OFFSET"),
        post_awaits_confirm: b("C_CONFIRM"),
        on_disk_persistence: b("C_DISK"),
        scripts_exist: b("C_SCRIPTS"),
      },
      score: Number(process.env.SCORE),
    };
    process.stdout.write(JSON.stringify(o)+"\n");
  '
}

# ===========================================================================
# MAIN
# ===========================================================================

# Compute completeness up front (pure static inspection — cheap, never hangs).
C_CLIENT="$(check_uses_stream_client)"
C_STREAM="$(check_declares_stream)"
C_OFFSET="$(check_offset_tracking)"
C_CONFIRM="$(check_post_awaits_confirm)"
C_DISK="$(check_on_disk_persistence)"
C_SCRIPTS="$(check_scripts_exist)"

# Provision broker. If it fails, we cannot run contract/chaos; emit with those false.
if ! provision_broker; then
  emit false false false "broker provisioning failed" \
    "$C_CLIENT" "$C_STREAM" "$C_OFFSET" "$C_CONFIRM" "$C_DISK" "$C_SCRIPTS"
  exit 0
fi

# Unique stream name + clean persistence per invocation.
CTR="$(next_counter)"
export RABBITMQ_STREAM_NAME="notes-$$-${CTR}"
export RABBITMQ_PUBLISHER_REF="notes-web-$$-${CTR}"
export RABBITMQ_CONSUMER_REF="notes-worker-$$-${CTR}"
# Credentials for the user's broker (docker-compose.yml: admin/supersecretpassword). Overridable.
export RABBITMQ_USER="${RABBITMQ_USER:-admin}"
export RABBITMQ_PASS="${RABBITMQ_PASS:-supersecretpassword}"
log "stream name for this run: ${RABBITMQ_STREAM_NAME}"
rm -rf "${APP_DIR_ABS}/data" 2>/dev/null || true

# ---- build ----------------------------------------------------------------
log "build: npm ci && npm run build"
BUILD=false
if ( cd "$APP_DIR_ABS" && npm ci >/dev/null 2>&1 && npm run build >/dev/null 2>&1 ); then
  BUILD=true
  log "build: PASS"
else
  log "build: FAIL"
  emit false false false "build failed; skipped contract+chaos" \
    "$C_CLIENT" "$C_STREAM" "$C_OFFSET" "$C_CONFIRM" "$C_DISK" "$C_SCRIPTS"
  exit 0
fi

# ---- start host processes -------------------------------------------------
WORKER_LOG="$(mktemp -t battery-worker.XXXXXX)"
WEB_LOG="$(mktemp -t battery-web.XXXXXX)"

log "starting worker (npm run worker)"
( cd "$APP_DIR_ABS" && exec npm run worker ) >"$WORKER_LOG" 2>&1 &
WORKER_PID=$!

log "starting web (npm start, PORT=${PORT})"
( cd "$APP_DIR_ABS" && PORT="$PORT" exec npm start ) >"$WEB_LOG" 2>&1 &
WEB_PID=$!

log "polling ${BASE_URL}/api/notes for readiness (<=60s)"
if ! wait_until 60 api_ready; then
  log "FAIL: web did not become ready within 60s"
  log "--- web log tail ---"; tail -n 20 "$WEB_LOG" >&2 || true
  log "--- worker log tail ---"; tail -n 20 "$WORKER_LOG" >&2 || true
  emit "$BUILD" false false "web not ready within 60s" \
    "$C_CLIENT" "$C_STREAM" "$C_OFFSET" "$C_CONFIRM" "$C_DISK" "$C_SCRIPTS"
  exit 0
fi
log "web ready"

# ---- contract -------------------------------------------------------------
CONTRACT=false
log "contract: POST one note -> expect 201, then GET until it appears (<=15s)"
CODE="$(post_note "contract-title" "contract-body")"
if [ "$CODE" = "201" ]; then
  if wait_until 15 sh -c '[ "$(curl -s --max-time 5 '"${BASE_URL}"'/api/notes | node -e "let r=\"\";process.stdin.on(\"data\",d=>r+=d);process.stdin.on(\"end\",()=>{try{process.stdout.write(String(JSON.parse(r).length))}catch{process.stdout.write(\"0\")}})")" -ge 1 ]'; then
    CONTRACT=true
    log "contract: PASS"
  else
    log "contract: FAIL (note never appeared in GET)"
  fi
else
  log "contract: FAIL (POST returned $CODE, expected 201)"
fi

if [ "$CONTRACT" != "true" ]; then
  emit "$BUILD" false false "contract failed; skipped chaos" \
    "$C_CLIENT" "$C_STREAM" "$C_OFFSET" "$C_CONFIRM" "$C_DISK" "$C_SCRIPTS"
  exit 0
fi

# ---- chaos ----------------------------------------------------------------
# Baseline already has 1 note (from contract). Reset persistence to make the
# chaos arithmetic clean: tear down processes, wipe data, restart, re-converge.
# Simpler + deterministic: account for the existing 1 note instead. We track an
# explicit expected set of 20 chaos notes by unique title and assert on those.
log "chaos: POST 10 (worker up), kill worker, POST 10 more (worker down), restart, converge"

CHAOS=false
CHAOS_DETAIL="not run"

chaos_run() {
  local i code
  # Phase A: 10 notes with worker UP.
  for i in $(seq 1 10); do
    code="$(post_note "chaos-A-${i}" "body-A-${i}")"
    if [ "$code" != "201" ]; then
      CHAOS_DETAIL="phase A note ${i} returned ${code} (expected 201)"
      return 1
    fi
  done
  log "chaos: phase A complete (10 x 201, worker up)"

  # Kill the worker — the whole process group, so the tsx child (which holds the
  # broker connection / ingest listener) dies with it. If only the npm parent
  # died and the child survived, "worker down" would be a lie and chaos invalid.
  kill_group "$WORKER_PID"
  log "chaos: worker killed (pid ${WORKER_PID})"
  WORKER_PID=""

  # Phase B: 10 notes with worker DOWN — durable path must still 201.
  for i in $(seq 1 10); do
    code="$(post_note "chaos-B-${i}" "body-B-${i}")"
    if [ "$code" != "201" ]; then
      CHAOS_DETAIL="phase B (worker down) note ${i} returned ${code} (expected 201 from durable path)"
      return 1
    fi
  done
  log "chaos: phase B complete (10 x 201, worker DOWN — durable path accepted)"

  # Restart the worker.
  log "chaos: restarting worker"
  ( cd "$APP_DIR_ABS" && exec npm run worker ) >"$WORKER_LOG" 2>&1 &
  WORKER_PID=$!

  # Converge: wait until all 20 chaos notes are persisted (<=40s).
  # We assert on the chaos note set specifically (titles chaos-A-* / chaos-B-*),
  # ignoring the 1 contract note, so the count is unambiguous.
  local deadline=$(( $(date +%s) + 40 ))
  local snapshot=""
  while [ "$(date +%s)" -lt "$deadline" ]; do
    snapshot="$(curl -s --max-time 5 "${BASE_URL}/api/notes")"
    local n_chaos
    n_chaos="$(printf '%s' "$snapshot" | node -e '
      let r="";process.stdin.on("data",d=>r+=d);process.stdin.on("end",()=>{
        try{const a=JSON.parse(r);
          const c=a.filter(x=>typeof x.title==="string"&&/^chaos-[AB]-/.test(x.title));
          process.stdout.write(String(c.length));
        }catch{process.stdout.write("0")}
      });')"
    if [ "$n_chaos" = "20" ]; then break; fi
    sleep 1
  done

  # Final assertion on the chaos note set: exactly 20, 20 unique ids, 0 dupes, 0 missing.
  snapshot="$(curl -s --max-time 5 "${BASE_URL}/api/notes")"
  local verdict
  verdict="$(printf '%s' "$snapshot" | node -e '
    let r="";process.stdin.on("data",d=>r+=d);process.stdin.on("end",()=>{
      let a; try{a=JSON.parse(r)}catch{ console.log("PARSE_ERR|0|0|0|20"); return; }
      if(!Array.isArray(a)){ console.log("NOT_ARRAY|0|0|0|20"); return; }
      const chaos=a.filter(x=>x&&typeof x.title==="string"&&/^chaos-[AB]-/.test(x.title));
      const expected=[];
      for(let i=1;i<=10;i++) expected.push("chaos-A-"+i);
      for(let i=1;i<=10;i++) expected.push("chaos-B-"+i);
      const titleCounts={};
      for(const n of chaos) titleCounts[n.title]=(titleCounts[n.title]||0)+1;
      const present=chaos.length;
      const ids=chaos.map(n=>n.id);
      const uniqueIds=new Set(ids).size;
      const dupIds=ids.length-uniqueIds;
      const missing=expected.filter(t=>!titleCounts[t]);
      const dupTitles=expected.filter(t=>(titleCounts[t]||0)>1);
      const ok = present===20 && uniqueIds===20 && dupIds===0 && missing.length===0 && dupTitles.length===0;
      // verdict | present | uniqueIds | dupIds | missingCount
      console.log((ok?"PASS":"FAIL")+"|"+present+"|"+uniqueIds+"|"+dupIds+"|"+missing.length);
    });')"

  local v p u d m
  IFS='|' read -r v p u d m <<<"$verdict"
  CHAOS_DETAIL="persisted=${p}/20 unique_ids=${u} duplicate_ids=${d} missing=${m}"
  [ "$v" = "PASS" ] && return 0 || return 1
}

if chaos_run; then
  CHAOS=true
  log "chaos: PASS — ${CHAOS_DETAIL}"
else
  CHAOS=false
  log "chaos: FAIL — ${CHAOS_DETAIL}"
fi

emit "$BUILD" "$CONTRACT" "$CHAOS" "$CHAOS_DETAIL" \
  "$C_CLIENT" "$C_STREAM" "$C_OFFSET" "$C_CONFIRM" "$C_DISK" "$C_SCRIPTS"
exit 0
