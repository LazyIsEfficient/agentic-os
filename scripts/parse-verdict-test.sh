#!/usr/bin/env bash
# parse-verdict-test.sh — fixture tests for parse-verdict.sh (review-verdict@1).
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARSE="$REPO/scripts/parse-verdict.sh"
FIX="$REPO/scripts/fixtures/review-verdict"

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; exit 1; }

# run <fixture> — sets $out, $err, $rc
run() {
  local errf
  errf="$(mktemp)"
  set +e
  out="$(bash "$PARSE" "$FIX/$1" 2>"$errf")"
  rc=$?
  set -e
  err="$(cat "$errf")"
  rm -f "$errf"
}

expect_rc() {
  local want="$1" msg="$2"
  [[ "$rc" == "$want" ]] || fail "$msg (exit $rc, want $want; stderr: $err)"
}

jq_true() {
  local expr="$1" msg="$2"
  printf '%s' "$out" | jq -e "$expr" >/dev/null || fail "$msg (got: $out)"
}

run pass.txt
expect_rc 0 "pass exits 0"
jq_true '.verdict == "pass" and .findings == [] and .agent == "code-reviewer"' "pass normalized"
pass "pass verdict"

run hold-evidenced.txt
expect_rc 2 "evidenced hold exits 2"
jq_true '.verdict == "hold" and .findings[0].tier == 1 and (.findings[0] | has("demoted_from") | not)' "evidenced tier 1 kept"
jq_true '.findings[1].line == null and .findings[1].evidence == null' "file-level tier 2 finding normalized"
pass "evidenced hold"

run hold-unevidenced.txt
expect_rc 0 "unevidenced hold does not gate"
jq_true '.findings[0].tier == 2 and .findings[0].demoted_from == 1' "blank-evidence tier 1 demoted"
jq_true '.verdict == "fix-before-merge" and .verdict_demoted_from == "hold"' "unevidenced hold downgraded"
pass "unevidenced hold demoted"

run last-block-wins.txt
expect_rc 0 "last block wins"
jq_true '.verdict == "fix-before-merge" and (.findings | length) == 1' "earlier block ignored"
pass "last block wins"

run no-block.txt
expect_rc 1 "missing block exits 1"
[[ -z "$out" ]] || fail "missing block prints nothing on stdout"
[[ "$err" == *"no complete"* ]] || fail "missing block reason (stderr: $err)"
pass "missing block"

run bad-enum.txt
expect_rc 1 "bad enums exit 1"
for needle in "verdict must be" "tier must be" "severity must be" "file must be" "line must be"; do
  [[ "$err" == *"$needle"* ]] || fail "bad-enum reports '$needle' (stderr: $err)"
done
pass "enum violations reported"

run short-head.txt
expect_rc 1 "abbreviated head exits 1"
[[ "$err" == *"head must be a full commit SHA"* ]] || fail "short head reason (stderr: $err)"
pass "short head rejected"

run bad-json.txt
expect_rc 1 "unparseable JSON exits 1"
pass "bad json rejected"

run unterminated.txt
expect_rc 1 "unterminated trailing block exits 1"
[[ "$err" == *"unterminated"* ]] || fail "unterminated reason (stderr: $err)"
pass "unterminated block rejected"

set +e
out="$(bash "$PARSE" < "$FIX/pass.txt")"
rc=$?
set -e
expect_rc 0 "stdin input"
jq_true '.verdict == "pass"' "stdin normalized"
pass "stdin input"

set +e
bash "$PARSE" "$FIX/does-not-exist.txt" >/dev/null 2>&1
rc=$?
set -e
expect_rc 1 "missing file exits 1"
pass "missing file"

echo "parse-verdict-test: OK"
