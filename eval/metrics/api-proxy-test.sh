#!/usr/bin/env bash
# api-proxy-test.sh — Tier 0 test of lib/api-proxy.mjs against a fake HTTP
# upstream (fixtures/proxy/upstream.mjs). No docker, no network, no real key.
# Covers: concurrent admission + reservation (the cap cannot be raced), identity
# encoding + gzip parsed anyway, fail-closed on unparseable usage, in-flight
# requests at SIGTERM, duplicate JSON keys, tool / model / beta allowlists,
# and separate cache accounting with weighted cache reads.
# Conditions are strings run by check(); variables they read look unused to shellcheck.
# shellcheck disable=SC2034
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY="${PROXY_UNDER_TEST:-$DIR/lib/api-proxy.mjs}"   # override only to replay against an old proxy
FX="$DIR/fixtures/proxy"
T="$(cd "$(mktemp -d)" && pwd -P)"
PIDS=()
cleanup() { local p; for p in ${PIDS[@]+"${PIDS[@]}"}; do kill "$p" 2>/dev/null; done; rm -rf "$T"; }
trap cleanup EXIT
FAIL=0
pass() { echo "PASS  $1"; }
fail() { echo "FAIL  $1"; FAIL=1; }
check() { if eval "$2"; then pass "$1"; else fail "$1"; fi; }

BASE=$(( 20000 + ($$ % 20000) ))
SONNET=claude-sonnet-5-5
HAIKU=claude-haiku-5-5
CANARY="sk-ant-CANARY-proxytest"
UPPORT=0; PXPORT=0; UPPID=0; PXPID=0

wait_line() { local f="$1" pat="$2" i; for i in $(seq 1 100); do grep -q "$pat" "$f" 2>/dev/null && return 0; sleep 0.05; done; return 1; }
# start <name> [upstream env...] -- [proxy env...]
start() {
  local name="$1"; shift
  local upenv=() pxenv=()
  while [ $# -gt 0 ] && [ "$1" != -- ]; do upenv+=("$1"); shift; done
  [ $# -gt 0 ] && shift
  while [ $# -gt 0 ]; do pxenv+=("$1"); shift; done
  BASE=$((BASE + 2)); UPPORT=$BASE; PXPORT=$((BASE + 1))
  mkdir -p "$T/$name"; : > "$T/$name/received.log"
  env ${upenv[@]+"${upenv[@]}"} node "$FX/upstream.mjs" "$T/$name" "$UPPORT" > "$T/$name/up.out" 2>&1 &
  UPPID=$!; PIDS+=("$UPPID")
  wait_line "$T/$name/up.out" '^up' || echo "upstream did not start ($name)"
  env ANTHROPIC_API_KEY="$CANARY" PROXY_UPSTREAM="http://127.0.0.1:$UPPORT" PROXY_HOST=127.0.0.1 PROXY_PORT="$PXPORT" \
    PROXY_MODELS="$SONNET $HAIKU" PROXY_BETAS="claude-code-20250219" ${pxenv[@]+"${pxenv[@]}"} \
    node "$PROXY" > "$T/$name/proxy.log" 2>&1 &
  PXPID=$!; PIDS+=("$PXPID")
  wait_line "$T/$name/proxy.log" '"listening"' || echo "proxy did not start ($name)"
}
stop() { kill -TERM "$PXPID" 2>/dev/null; wait "$PXPID" 2>/dev/null; kill "$UPPID" 2>/dev/null; wait "$UPPID" 2>/dev/null; }
send() { node "$FX/client.mjs" "$PXPORT" "$@"; }
summary() { grep '"summary":true' "$T/$1/proxy.log" | tail -1; }
sj() { summary "$1" | node -e "const o=JSON.parse(require('fs').readFileSync(0,'utf8'));console.log(eval(process.argv[1]))" "$2"; }
received() { wc -l < "$T/$1/received.log" | tr -d ' '; }
body() { printf '{"model":"%s","max_tokens":%s,"messages":[]%s}' "$1" "$2" "${3:-}"; }

# ---- 1. 100 parallel requests cannot race the cap (PoC: 22.2M vs a 2M cap) ----
# Honest upstream (usage <= reservation): concurrent admission counts every
# in-flight reservation, so the cap is a true bound.
start par UP_DELAY=150 UP_IN=1000 UP_OUT=30000 -- PROXY_MAX_UNITS=400000
send 100 "$(body $SONNET 32000)" > "$T/par/client.out"
stop
check "parallel: committed units never exceed the cap" '[ "$(sj par "o.committed_units")" -le 400000 ]'
check "parallel: requests run concurrently, never more than 8 in flight" \
  '[ "$(sj par "o.max_inflight_seen")" -gt 1 ] && [ "$(sj par "o.max_inflight_seen")" -le 8 ]'
check "parallel: the excess gets an immediate 429 (cause inflight or budget), not a model denial" \
  'grep -q "\"429\"" "$T/par/client.out" && [ "$(sj par "o.denials")" = 0 ] && [ "$(sj par "o.inflight_rejected+o.budget_rejected")" -gt 0 ] && grep -qE "\"cause\":\"(inflight|budget)\"" "$T/par/proxy.log"'
check "parallel: no queue — nothing waits (no queue or dropped fields remain)" '! grep -q "queue_wait\|\"dropped\"" "$T/par/proxy.log"'

# ---- 2. honest upstream: reservation keeps the total under the cap exactly ----
start resv UP_IN=60 UP_OUT=900 -- PROXY_MAX_UNITS=5000 PROXY_RESERVE_OVERHEAD=100
send 20 "$(body $SONNET 1000)" > /dev/null
stop
check "reservation: an honest upstream never pushes committed units past the cap" \
  '[ "$(sj resv "o.committed_units")" -le 5000 ] && [ "$(sj resv "o.committed_units")" -gt 0 ]'

# ---- 3. accept-encoding forced to identity; a gzip reply is still counted -----
start gz UP_MODE=gzip UP_IN=10 UP_OUT=20 --
send 3 "$(body $SONNET 100)" > /dev/null
stop
check "upstream is always asked for identity encoding" '[ "$(grep -c "\"ae\":\"identity\"" "$T/gz/received.log")" = 3 ]'
check "a gzip reply sent anyway is decompressed and counted (90 units, 0 unparsed)" \
  '[ "$(sj gz "o.committed_units+\"|\"+o.unparsed")" = "90|0" ]'

# ---- 4. fail closed: unparseable 2xx usage is charged the full reservation ----
start bad UP_MODE=garbage -- PROXY_RESERVE_OVERHEAD=100
B="$(body $SONNET 500)"; send 1 "$B" > /dev/null
stop
check "unparseable 2xx: charged its reservation (bytes + overhead + max_tokens) and flagged" \
  '[ "$(sj bad "o.committed_units+\"|\"+o.unparsed")" = "$(( $(printf "%s" "$B" | wc -c | tr -d " ") + 100 + 500 ))|1" ]'
start err UP_MODE=error --
send 1 "$(body $SONNET 500)" > /dev/null
stop
check "upstream error body: charged 0 (not billed), not flagged" '[ "$(sj err "o.committed_units+\"|\"+o.unparsed")" = "0|0" ]'

# ---- 5. SIGTERM with requests in flight (PoC: 50 answered, summary 0) ---------
start drain UP_DELAY=700 UP_IN=10 UP_OUT=10 --
send 5 "$(body $SONNET 100)" > "$T/drain/client.out" &
CPID=$!
sleep 0.3
kill -TERM "$PXPID"; wait "$PXPID" 2>/dev/null; wait "$CPID" 2>/dev/null
kill "$UPPID" 2>/dev/null
check "drain: every request the upstream received is counted in the summary" \
  '[ "$(sj drain "o.requests")" = "$(received drain)" ] && [ "$(received drain)" = 5 ] && [ "$(sj drain "o.committed_units")" = 100 ]'
check "drain: a start line is logged for each forwarded request" '[ "$(grep -c "\"phase\":\"start\"" "$T/drain/proxy.log")" = 5 ]'
start slow UP_DELAY=3000 UP_IN=10 UP_OUT=10 -- PROXY_DRAIN_MS=200 PROXY_RESERVE_OVERHEAD=100
send 1 "$(body $SONNET 300)" > /dev/null &
CPID=$!
sleep 0.3
kill -TERM "$PXPID"; wait "$PXPID" 2>/dev/null; kill "$CPID" 2>/dev/null; kill "$UPPID" 2>/dev/null
check "drain timeout: the unfinished request is charged its reservation (fail closed)" \
  '[ "$(sj slow "o.unfinished")" = 1 ] && [ "$(sj slow "o.committed_units")" -gt 300 ]'

# ---- 6. duplicate keys: what is validated is what is forwarded ----------------
start dup --
send 1 '{"model":"claude-opus-9","model":"'"$SONNET"'","max_tokens":999999,"max_tokens":10,"messages":[]}' > /dev/null
stop
check "duplicate keys: the upstream receives the re-serialized validated body only" \
  'grep -q "\"model\\\\\":\\\\\"$SONNET\\\\\"" "$T/dup/received.log" && ! grep -q "claude-opus-9" "$T/dup/received.log" && ! grep -q 999999 "$T/dup/received.log"'

# ---- 7. tool / field / model / beta allowlists ---------------------------------
start allow --
code() { send 1 "$1" ${2:+"$2"} | node -e "console.log(Object.keys(JSON.parse(require('fs').readFileSync(0,'utf8')))[0])"; }
OKTOOL=',"tools":[{"name":"Read","description":"read","input_schema":{"type":"object"}}]'
check "a plain client-side tool is allowed" '[ "$(code "$(body $SONNET 10 "$OKTOOL")")" = 200 ]'
check "server tool web_search is rejected" '[ "$(code "$(body $SONNET 10 ",\"tools\":[{\"type\":\"web_search_20250305\",\"name\":\"web_search\"}]")")" = 400 ]'
check "any non-custom tool type is rejected (allowlist, not denylist)" '[ "$(code "$(body $SONNET 10 ",\"tools\":[{\"type\":\"some_new_server_tool\",\"name\":\"x\",\"input_schema\":{}}]")")" = 400 ]'
check "a tool with an unknown key is rejected" '[ "$(code "$(body $SONNET 10 ",\"tools\":[{\"name\":\"x\",\"input_schema\":{},\"server_url\":\"http://e\"}]")")" = 400 ]'
check "a tool whose input_schema is an array is rejected" '[ "$(code "$(body $SONNET 10 ",\"tools\":[{\"name\":\"x\",\"input_schema\":[]}]")")" = 400 ]'
check "the background model claude-haiku-5-5 is allowed" '[ "$(code "$(body $HAIKU 10)")" = 200 ]'
check "claude-sonnet-4-5 is no longer allowed" '[ "$(code "$(body claude-sonnet-4-5 10)")" = 400 ]'
check "the 1M-context beta is rejected" '[ "$(code "$(body $SONNET 10)" context-1m-2025-08-07)" = 400 ]'
# Top-level fields: an ALLOWLIST (PoC: inference_geo and speed passed).
for f in inference_geo speed mcp_servers container service_tier context_management; do
  V="$(body $SONNET 10 ",\"$f\":\"x\"")"
  check "request field $f is rejected (top-level allowlist)" '[ "$(code "$V")" = 400 ]'
done
V_OKF="$(body $SONNET 10 ',"system":"s","stream":true,"temperature":0.5,"metadata":{"user_id":"u"},"stop_sequences":["x"],"top_p":0.9,"top_k":5,"tool_choice":{"type":"auto"},"thinking":{"type":"enabled","budget_tokens":5}')"
check "the allowlisted fields pass together" '[ "$(code "$V_OKF")" = 200 ]'
stop
check "every rejection is logged with its reason" '[ "$(grep -c "\"denied\"" "$T/allow/proxy.log")" -ge 12 ] && grep -q "request field not allowed: inference_geo" "$T/allow/proxy.log"'

# ---- 8. cache accounting: separate fields, cache reads weighted 0.1 ------------
start cache UP_MODE=sse UP_IN=12 UP_CC=1000 UP_CR=50000 UP_OUT=300 --
send 1 "$(body $SONNET 400)" > /dev/null
stop
check "cache tokens are recorded separately per model" \
  '[ "$(sj cache "JSON.stringify(o.by_model[\"$SONNET\"])")" = "{\"input\":12,\"cache_read\":50000,\"cache_creation\":1000,\"output\":300}" ]'
check "cap units = input + cache_creation + output + cache_read*0.1 (6312)" '[ "$(sj cache "o.committed_units")" = 6312 ]'
check "the key canary never appears in the proxy log" '! grep -rqF "$CANARY" "$T"/*/proxy.log'

# ---- 9. fail closed on a bad weight; network error before the body is sent ----
start nanw UP_MODE=sse UP_IN=12 UP_CC=1000 UP_CR=50000 UP_OUT=300 -- PROXY_CACHE_READ_WEIGHT=abc
send 1 "$(body $SONNET 400)" > /dev/null
stop
check "an invalid cache-read weight counts cache reads in full (51312 units, not NaN)" '[ "$(sj nanw "o.committed_units")" = 51312 ]'
start w0 UP_MODE=sse UP_IN=12 UP_CC=1000 UP_CR=50000 UP_OUT=300 -- PROXY_CACHE_READ_WEIGHT=0
send 1 "$(body $SONNET 400)" > /dev/null
stop
check "PROXY_CACHE_READ_WEIGHT=0 is rejected too (falls back to 1, never skips cache reads)" '[ "$(sj w0 "o.committed_units")" = 51312 ]'
start neterr --
kill "$UPPID" 2>/dev/null; wait "$UPPID" 2>/dev/null
send 1 "$(body $SONNET 200)" > /dev/null
stop
check "upstream unreachable (body never sent): charged 0, not flagged" '[ "$(sj neterr "o.committed_units+\"|\"+o.unparsed")" = "0|0" ]'

# ---- 10. client aborts: charged once the body reached upstream ----------------
AC="$FX/abort-client.mjs"
start prehdr UP_DELAY=1500 -- PROXY_RESERVE_OVERHEAD=100
B="$(body $SONNET 100)"; R1=$(( $(printf "%s" "$B" | wc -c | tr -d " ") + 100 + 100 ))
node "$AC" "$PXPORT" "$B" 300 300 300 > /dev/null
sleep 0.2; stop
check "abort before upstream headers (PoC: 10 sent upstream, charged 0): each charged its reservation" \
  '[ "$(received prehdr)" = 3 ] && [ "$(sj prehdr "o.client_aborted+\"|\"+o.committed_units")" = "3|$((3 * R1))" ]'
check "a client abort is logged with note 'client aborted request'" '[ "$(grep -c "client aborted request" "$T/prehdr/proxy.log")" = 3 ]'
start posthdr UP_MODE=stall UP_STALL=2000 -- PROXY_RESERVE_OVERHEAD=100
node "$AC" "$PXPORT" "$B" 400 > /dev/null
sleep 0.2; stop
check "abort after upstream started responding: charged its reservation" '[ "$(sj posthdr "o.client_aborted+\"|\"+o.committed_units")" = "1|$R1" ]'

# ---- 11. concurrency limit: immediate 429, not a denial ------------------------
start conc UP_DELAY=800 -- PROXY_MAX_INFLIGHT=2
send 5 "$(body $SONNET 50)" > "$T/conc/client.out"
stop
check "with 2 in flight allowed: 2 forwarded, 3 get an immediate 429 (cause inflight, denials 0)" \
  '[ "$(received conc)" = 2 ] && [ "$(node -e "console.log(JSON.parse(require(\"fs\").readFileSync(process.argv[1],\"utf8\"))[\"429\"])" "$T/conc/client.out")" = 3 ] && [ "$(sj conc "o.inflight_rejected+\"|\"+o.budget_rejected+\"|\"+o.denials")" = "3|0|0" ]'

# ---- 12. content blocks: inline base64 only, block-type allowlist, depth limit --
start blocks --
msg() { printf '{"model":"%s","max_tokens":10,"messages":[{"role":"user","content":%s}]}' "$SONNET" "$1"; }
blk() { send 1 "$(msg "$1")" | node -e "console.log(Object.keys(JSON.parse(require('fs').readFileSync(0,'utf8')))[0])"; }
IMG64='{"type":"image","source":{"type":"base64","media_type":"image/png","data":"iVBORw0KGgo="}}'
# Bodies in variables: bash 3.2 mis-parses escaped quotes nested in $( ).
V_URLIMG='[{"type":"image","source":{"type":"url","url":"http://e/x.png"}}]'
V_FILE='[{"type":"image","source":{"type":"file","file_id":"f1"}}]'
V_TEXTSRC='[{"type":"image","source":{"type":"text","data":"x"}}]'
V_NESTED='[{"type":"tool_result","tool_use_id":"t","content":[{"type":"image","source":{"type":"url","url":"http://e"}}]}]'
V_DOC='[{"type":"document","source":{"type":"base64","media_type":"application/pdf","data":"JVBERi0="}}]'
V_UNKNOWN='[{"type":"server_tool_use","id":"x","name":"web_search","input":{}}]'
V_OK='[{"type":"text","text":"hi"},{"type":"tool_result","tool_use_id":"t","content":[{"type":"text","text":"ok"}]}]'
check "a base64 image block is allowed" '[ "$(blk "[$IMG64]")" = 200 ]'
check "an image with a url source is rejected" '[ "$(blk "$V_URLIMG")" = 400 ]'
check "a file source is rejected" '[ "$(blk "$V_FILE")" = 400 ]'
check "a text source is rejected (only base64 remains)" '[ "$(blk "$V_TEXTSRC")" = 400 ]'
check "a url image nested in tool_result.content is rejected" '[ "$(blk "$V_NESTED")" = 400 ]'
check "a document block is rejected (even base64: compressed PDFs break the byte bound)" '[ "$(blk "$V_DOC")" = 400 ]'
check "an unknown block type is rejected" '[ "$(blk "$V_UNKNOWN")" = 400 ]'
check "text, tool_use and tool_result blocks are allowed" '[ "$(blk "$V_OK")" = 200 ]'
DC="$FX/deep-client.mjs"
check "tool_result nested 20000 deep (PoC crashed the proxy) -> 400" '[ "$(node "$DC" "$PXPORT" "$SONNET" 20000)" = 400 ]'
check "the proxy is still up after the deep request" '[ "$(blk "$V_OK")" = 200 ]'
check "nesting within the 32 limit passes; past it is rejected" '[ "$(node "$DC" "$PXPORT" "$SONNET" 30)" = 200 ] && [ "$(node "$DC" "$PXPORT" "$SONNET" 40)" = 400 ]'
stop
check "each content-block rejection is logged" '[ "$(grep -c "content block type not allowed\|content source type not allowed\|nested deeper" "$T/blocks/proxy.log")" -ge 7 ]'
start imgres -- PROXY_RESERVE_OVERHEAD=100 PROXY_IMAGE_RESERVE=1600
B="$(msg "[$IMG64,$IMG64]")"; send 1 "$B" > /dev/null; stop
check "an image block adds its own reservation (bytes + overhead + max_tokens + 2 x 1600)" \
  'grep -q "\"reserved\":$(( $(printf "%s" "$B" | wc -c | tr -d " ") + 100 + 10 + 3200 ))," "$T/imgres/proxy.log"'

# ---- 13. 429 retries do not use up the request cap (PoC retry.sh) -----------
start retry UP_DELAY=400 -- PROXY_MAX_INFLIGHT=1 PROXY_MAX_REQUESTS=3
send 6 "$(body $SONNET 50)" > /dev/null      # 1 admitted, 5 get inflight 429s
sleep 0.6
send 1 "$(body $SONNET 50)" > /dev/null; sleep 0.6
send 1 "$(body $SONNET 50)" > "$T/retry/last.out"
stop
check "inflight 429s are not counted against PROXY_MAX_REQUESTS: the 2nd and 3rd admitted requests still pass" \
  '[ "$(received retry)" = 3 ] && grep -q "\"200\"" "$T/retry/last.out" && ! grep -q "request cap" "$T/retry/proxy.log"'

# ---- 14. budget exhaustion is its own cause ---------------------------------
start budget UP_IN=10 UP_OUT=10 -- PROXY_MAX_UNITS=300 PROXY_RESERVE_OVERHEAD=100
send 1 "$(body $SONNET 400)" > /dev/null
stop
check "a request that would exceed the unit cap gets 429 cause budget (not inflight, not a denial)" \
  '[ "$(sj budget "o.budget_rejected+\"|\"+o.inflight_rejected+\"|\"+o.denials")" = "1|0|0" ] && grep -q "unit budget exhausted" "$T/budget/proxy.log"'

# ---- 15. a mid-pipe upstream failure ends the client response -----------------
start midfail UP_MODE=midfail -- PROXY_RESERVE_OVERHEAD=100
B="$(body $SONNET 100)"; R1=$(( $(printf "%s" "$B" | wc -c | tr -d " ") + 100 + 100 ))
t0=$(date +%s)
node "$AC" "$PXPORT" "$B" 0 > "$T/midfail/client.out"
t1=$(date +%s)
stop
check "mid-pipe upstream error: the client is not left hanging (PoC: CLIENT-HUNG-3s)" '[ $((t1 - t0)) -le 2 ] && grep -q "aborted" "$T/midfail/client.out"'
check "mid-pipe upstream error: charged its reservation and flagged" '[ "$(sj midfail "o.committed_units+\"|\"+o.unparsed")" = "$R1|1" ]'

# ---- 16. an SSE stream with no message_delta is charged the reservation -------
start nodelta UP_MODE=nodelta UP_IN=10 -- PROXY_RESERVE_OVERHEAD=100
send 1 "$B" > /dev/null
stop
check "SSE without message_delta: charged its reservation (not just message_start usage) and flagged" \
  '[ "$(sj nodelta "o.committed_units+\"|\"+o.unparsed")" = "$R1|1" ]'

# ---- 17. a transient in-flight spike is not "budget" (both round-8 repros) ----
# rv300-r8/budget.sh: 2 parallel requests, cap 6000, each reserving ~4200 —
# the 2nd fits on committed alone, so it is `inflight` (transient), not budget.
B='{"model":"claude-sonnet-5-5","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}'
start spike UP_DELAY=800 UP_IN=10 UP_OUT=10 -- PROXY_MAX_UNITS=6000
send 2 "$B" > /dev/null
send 1 "$B" > "$T/spike/after.out"
stop
check "parallel spike within budget -> inflight 429, never budget; later requests 200" \
  '[ "$(sj spike "o.budget_rejected+\"|\"+(o.inflight_rejected>=1)")" = "0|true" ] && grep -q "\"200\"" "$T/spike/after.out"'
# sec300r8 s8.sh fanout: a healthy fan-out at a small fraction of the budget
# must never be labelled budget.
start fanout UP_DELAY=500 UP_IN=10 UP_OUT=10 -- PROXY_MAX_UNITS=60000 PROXY_RESERVE_OVERHEAD=4096
send 30 "$(body $SONNET 4000)" > /dev/null
stop
check "fan-out at ~1% spend: only inflight 429s, no budget 429 (sample would stay complete)" \
  '[ "$(sj fanout "o.budget_rejected")" = 0 ] && [ "$(sj fanout "o.committed_units")" -lt 6000 ]'
# Over budget on committed alone, even while in flight is full -> budget, not inflight.
start over UP_DELAY=600 UP_IN=10 UP_OUT=10 -- PROXY_MAX_UNITS=5000 PROXY_RESERVE_OVERHEAD=100 PROXY_MAX_INFLIGHT=1
send 1 "$(body $SONNET 1000)" > /dev/null &
CPID=$!
sleep 0.2
send 1 "$(body $SONNET 9000)" > /dev/null    # its reservation alone exceeds the cap
wait "$CPID" 2>/dev/null
stop
check "an over-budget request is budget even when the in-flight slot is full (checked first)" \
  '[ "$(sj over "o.budget_rejected+\"|\"+o.inflight_rejected")" = "1|0" ]'

[ "$FAIL" = 0 ] && echo "api-proxy-test: OK" || { echo "api-proxy-test: FAILED"; exit 1; }
