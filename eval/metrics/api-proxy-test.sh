#!/usr/bin/env bash
# api-proxy-test.sh — Tier 0 test of lib/api-proxy.mjs against a fake HTTP
# upstream (fixtures/proxy/upstream.mjs). No docker, no network, no real key.
# Covers: one-at-a-time + reservation (the cap cannot be raced), identity
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
start par UP_IN=190000 UP_OUT=32000 -- PROXY_MAX_UNITS=2000000
send 100 "$(body $SONNET 32000)" > "$T/par/client.out"
stop
check "parallel: committed units stay within cap + one request (222000)" \
  '[ "$(sj par "o.committed_units")" -le $((2000000 + 222000)) ]'
check "parallel: upstream saw at most ceil(cap/request)+1 requests, the rest got 429 or 503 (queue full)" \
  '[ "$(received par)" -le 10 ] && grep -qE "\"(429|503)\"" "$T/par/client.out"'
check "parallel: never more than one request in flight (start/end strictly alternate)" \
  '[ "$(grep -o "\"phase\":\"[a-z]*\"" "$T/par/proxy.log" | tr -d "\"" | sed "s/phase://" | tr "\n" " " | grep -c "start start")" = 0 ]'

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
  '[ "$(sj drain "o.requests")" = "$(received drain)" ] && [ "$(sj drain "o.committed_units")" = $(( 20 * $(received drain) )) ]'
check "drain: a start line is logged for each forwarded request; queued ones get 503" \
  '[ "$(grep -c "\"phase\":\"start\"" "$T/drain/proxy.log")" = "$(received drain)" ] && grep -q "\"503\"" "$T/drain/client.out"'
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

# ---- 7. tool / mcp / model / beta allowlists -----------------------------------
start allow --
code() { send 1 "$1" ${2:+"$2"} | node -e "console.log(Object.keys(JSON.parse(require('fs').readFileSync(0,'utf8')))[0])"; }
OKTOOL=',"tools":[{"name":"Read","description":"read","input_schema":{"type":"object"}}]'
check "a plain client-side tool is allowed" '[ "$(code "$(body $SONNET 10 "$OKTOOL")")" = 200 ]'
check "server tool web_search is rejected" '[ "$(code "$(body $SONNET 10 ",\"tools\":[{\"type\":\"web_search_20250305\",\"name\":\"web_search\"}]")")" = 400 ]'
check "any non-custom tool type is rejected (allowlist, not denylist)" '[ "$(code "$(body $SONNET 10 ",\"tools\":[{\"type\":\"some_new_server_tool\",\"name\":\"x\",\"input_schema\":{}}]")")" = 400 ]'
check "a tool with an unknown key is rejected" '[ "$(code "$(body $SONNET 10 ",\"tools\":[{\"name\":\"x\",\"input_schema\":{},\"server_url\":\"http://e\"}]")")" = 400 ]'
check "mcp_servers is rejected" '[ "$(code "$(body $SONNET 10 ",\"mcp_servers\":[{\"url\":\"http://e\"}]")")" = 400 ]'
check "the background model claude-haiku-5-5 is allowed" '[ "$(code "$(body $HAIKU 10)")" = 200 ]'
check "claude-sonnet-4-5 is no longer allowed" '[ "$(code "$(body claude-sonnet-4-5 10)")" = 400 ]'
check "the 1M-context beta is rejected" '[ "$(code "$(body $SONNET 10)" context-1m-2025-08-07)" = 400 ]'
stop
check "every rejection is logged with its reason" '[ "$(grep -c "\"denied\"" "$T/allow/proxy.log")" -ge 6 ]'

# ---- 8. cache accounting: separate fields, cache reads weighted 0.1 ------------
start cache UP_MODE=sse UP_IN=12 UP_CC=1000 UP_CR=50000 UP_OUT=300 --
send 1 "$(body $SONNET 400)" > /dev/null
stop
check "cache tokens are recorded separately per model" \
  '[ "$(sj cache "JSON.stringify(o.by_model[\"$SONNET\"])")" = "{\"input\":12,\"cache_read\":50000,\"cache_creation\":1000,\"output\":300}" ]'
check "cap units = input + cache_creation + output + cache_read*0.1 (6312)" '[ "$(sj cache "o.committed_units")" = 6312 ]'
check "the key canary never appears in the proxy log" '! grep -rqF "$CANARY" "$T"/*/proxy.log'

# ---- 9. fail closed on a bad weight and on network errors ----------------------
start nanw UP_MODE=sse UP_IN=12 UP_CC=1000 UP_CR=50000 UP_OUT=300 -- PROXY_CACHE_READ_WEIGHT=abc
send 1 "$(body $SONNET 400)" > /dev/null
stop
check "an invalid cache-read weight counts cache reads in full (51312 units, not NaN)" '[ "$(sj nanw "o.committed_units")" = 51312 ]'
start neterr -- PROXY_RESERVE_OVERHEAD=100
kill "$UPPID" 2>/dev/null; wait "$UPPID" 2>/dev/null
B="$(body $SONNET 200)"; send 1 "$B" > /dev/null
stop
check "a network error to upstream is charged its reservation and flagged (fail closed)" \
  '[ "$(sj neterr "o.committed_units+\"|\"+o.unparsed")" = "$(( $(printf "%s" "$B" | wc -c | tr -d " ") + 100 + 200 ))|1" ]'

check "PROXY_CACHE_READ_WEIGHT=0 is rejected too (falls back to 1, never skips cache reads)" \
  'start w0 UP_MODE=sse UP_IN=12 UP_CC=1000 UP_CR=50000 UP_OUT=300 -- PROXY_CACHE_READ_WEIGHT=0 >/dev/null; send 1 "$(body $SONNET 400)" >/dev/null; stop; [ "$(sj w0 "o.committed_units")" = 51312 ]'

# ---- 10. abandoned requests (PoC: 3 of 4 aborted after 200 ms, upstream got 4) --
AC="$FX/abort-client.mjs"
start aband UP_DELAY=1000 UP_IN=10 UP_OUT=10 --
node "$AC" "$PXPORT" "$(body $SONNET 100)" 0 200 200 200 > "$T/aband/client.out"
sleep 0.3
stop
check "abandoned queued requests are dropped: upstream received only the one that stayed" '[ "$(received aband)" = 1 ]'
check "dropped requests are logged and counted, not charged (committed = 20 units)" \
  '[ "$(sj aband "o.dropped+\"|\"+o.committed_units")" = "3|20" ]'
check "queue wait is logged per request and totalled in the summary" \
  'grep -q "\"queue_wait_ms\":" "$T/aband/proxy.log" && [ "$(sj aband "typeof o.queue_wait_ms_total")" = number ]'
start abpre UP_DELAY=1500 --
node "$AC" "$PXPORT" "$(body $SONNET 100)" 300 > /dev/null
sleep 0.2; stop
check "client gone before upstream responded: upstream aborted, charged 0" \
  '[ "$(sj abpre "o.client_aborted+\"|\"+o.committed_units")" = "1|0" ]'
start abpost UP_MODE=stall UP_STALL=2000 -- PROXY_RESERVE_OVERHEAD=100
B="$(body $SONNET 100)"; node "$AC" "$PXPORT" "$B" 400 > /dev/null
sleep 0.2; stop
check "client gone after upstream started responding: charged its reservation (fail closed)" \
  '[ "$(sj abpost "o.client_aborted+\"|\"+o.committed_units")" = "1|$(( $(printf "%s" "$B" | wc -c | tr -d " ") + 100 + 100 ))" ]'

# ---- 11. bounded queue: length and wait ---------------------------------------
start qlen UP_DELAY=800 -- PROXY_MAX_QUEUE=1
send 4 "$(body $SONNET 50)" > "$T/qlen/client.out"
stop
check "queue length bound: 1 in flight + 1 queued, the other 2 get 503" \
  '[ "$(node -e "console.log(JSON.parse(require(\"fs\").readFileSync(process.argv[1],\"utf8\"))[\"503\"])" "$T/qlen/client.out")" = 2 ] && [ "$(received qlen)" = 2 ]'
start qwait UP_DELAY=1200 -- PROXY_MAX_QUEUE_WAIT_MS=300
send 3 "$(body $SONNET 50)" > "$T/qwait/client.out"
stop
check "queue wait bound: requests waiting past 300 ms get 503 and are never forwarded" \
  '[ "$(node -e "console.log(JSON.parse(require(\"fs\").readFileSync(process.argv[1],\"utf8\"))[\"503\"])" "$T/qwait/client.out")" = 2 ] && [ "$(received qwait)" = 1 ]'

# ---- 12. content blocks: no url/file sources, block-type allowlist -----------
start blocks --
msg() { printf '{"model":"%s","max_tokens":10,"messages":[{"role":"user","content":%s}]}' "$SONNET" "$1"; }
blk() { send 1 "$(msg "$1")" | node -e "console.log(Object.keys(JSON.parse(require('fs').readFileSync(0,'utf8')))[0])"; }
IMG64='{"type":"image","source":{"type":"base64","media_type":"image/png","data":"iVBORw0KGgo="}}'
check "a base64 image block is allowed" '[ "$(blk "[$IMG64]")" = 200 ]'
check "an image with a url source is rejected" '[ "$(blk "[{\"type\":\"image\",\"source\":{\"type\":\"url\",\"url\":\"http://e/x.png\"}}]")" = 400 ]'
check "a file source is rejected" '[ "$(blk "[{\"type\":\"image\",\"source\":{\"type\":\"file\",\"file_id\":\"f1\"}}]")" = 400 ]'
check "a url image nested in tool_result.content is rejected" \
  '[ "$(blk "[{\"type\":\"tool_result\",\"tool_use_id\":\"t\",\"content\":[{\"type\":\"image\",\"source\":{\"type\":\"url\",\"url\":\"http://e\"}}]}]")" = 400 ]'
check "a document block is rejected (even base64: compressed PDFs break the byte bound)" \
  '[ "$(blk "[{\"type\":\"document\",\"source\":{\"type\":\"base64\",\"media_type\":\"application/pdf\",\"data\":\"JVBERi0=\"}}]")" = 400 ]'
check "an unknown block type is rejected" '[ "$(blk "[{\"type\":\"server_tool_use\",\"id\":\"x\",\"name\":\"web_search\",\"input\":{}}]")" = 400 ]'
check "text, tool_use and tool_result blocks are allowed" \
  '[ "$(blk "[{\"type\":\"text\",\"text\":\"hi\"},{\"type\":\"tool_result\",\"tool_use_id\":\"t\",\"content\":[{\"type\":\"text\",\"text\":\"ok\"}]}]")" = 200 ]'
check "service_tier priority and a container field are rejected" \
  '[ "$(code "$(body $SONNET 10 ",\"service_tier\":\"priority\"")")" = 400 ] && [ "$(code "$(body $SONNET 10 ",\"container\":\"c1\"")")" = 400 ]'
check "a tool whose input_schema is an array is rejected" '[ "$(code "$(body $SONNET 10 ",\"tools\":[{\"name\":\"x\",\"input_schema\":[]}]")")" = 400 ]'
stop
check "each content-block rejection is logged" '[ "$(grep -c "content block type not allowed\|content source type not allowed" "$T/blocks/proxy.log")" -ge 5 ]'
start imgres -- PROXY_RESERVE_OVERHEAD=100 PROXY_IMAGE_RESERVE=1600
B="$(msg "[$IMG64,$IMG64]")"; send 1 "$B" > /dev/null; stop
check "an image block adds its own reservation (bytes + overhead + max_tokens + 2 x 1600)" \
  'grep -q "\"reserved\":$(( $(printf "%s" "$B" | wc -c | tr -d " ") + 100 + 10 + 3200 ))," "$T/imgres/proxy.log"'

# ---- 13. a 503 while draining is not a model-caused denial -------------------
start drain2 UP_DELAY=700 --
send 2 "$(body $SONNET 10)" > "$T/drain2/client.out" &
CPID=$!
sleep 0.2
kill -TERM "$PXPID"; wait "$PXPID" 2>/dev/null; wait "$CPID" 2>/dev/null; kill "$UPPID" 2>/dev/null
check "a queued request rejected while draining is counted apart from denials (drain 1, denials 0)" \
  '[ "$(sj drain2 "o.denials+\"|\"+o.drain_rejected")" = "0|1" ] && grep -q "\"cause\":\"drain\"" "$T/drain2/proxy.log"'

[ "$FAIL" = 0 ] && echo "api-proxy-test: OK" || { echo "api-proxy-test: FAILED"; exit 1; }
