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
expect_rc 3 "unevidenced hold exits 3 (fix-before-merge)"
jq_true '.findings[0].tier == 2 and .findings[0].demoted_from == 1' "blank-evidence tier 1 demoted"
jq_true '.verdict == "fix-before-merge" and .verdict_demoted_from == "hold"' "unevidenced hold downgraded"
pass "unevidenced hold demoted"

# Scanner evidence end to end: scanner-evidence.json is real security-scan.sh
# --json output (SECURITY_SCAN_OFFLINE=1, semgrep 1.181.0, shipped ruleset). The
# reviewer cites that hit as tier 0, and the parser keeps it, so the verdict
# exits 3 (fix-before-merge). Unavailable scanners are explicit tier 2 findings.
run fix-before-merge-scanner.txt
expect_rc 3 "scanner-evidenced finding exits 3 (fix-before-merge)"
jq_true '.verdict == "fix-before-merge" and (has("verdict_demoted_from") | not)' "scanner verdict kept"
jq_true '.findings[0].tier == 0 and (.findings[0] | has("demoted_from") | not)' "scanner hit kept at tier 0"
jq_true '[.findings[] | select(.tier == 2) | .summary] == ["scanner unavailable: gitleaks", "scanner unavailable: dependency-audit"]' \
  "unavailable scanners reported as tier 2"
cited="$(printf '%s' "$out" | jq -c '.findings[0].evidence | capture("semgrep finding (?<j>\\{.*\\})$").j | fromjson')" \
  || fail "evidence embeds the scanner finding JSON"
hit="$(jq -c '.scanners[] | select(.name == "semgrep") | .findings[0]' "$FIX/scanner-evidence.json")"
[[ -n "$cited" && "$cited" == "$hit" ]] || fail "evidence matches scanner-evidence.json (cited=$cited hit=$hit)"
printf '%s' "$out" | jq -e --argjson h "$hit" '.findings[0] | .file == $h.file and .line == $h.line' >/dev/null \
  || fail "finding file:line matches the scanner hit"
grep -qxF "$(jq -c . "$FIX/scanner-evidence.json")" "$FIX/fix-before-merge-scanner.txt" \
  || fail "report quotes the full scanner output"
pass "scanner evidence → fix-before-merge"

# expect_reject <fixture> <stderr needle> <label>
expect_reject() {
  run "$1"
  expect_rc 1 "$3"
  [[ -z "$out" ]] || fail "$3 prints nothing on stdout"
  [[ "$err" == *"$2"* ]] || fail "$3 reason (stderr: $err)"
  pass "$3"
}

expect_reject multiple-blocks.txt "more than one" "multiple json blocks rejected"
expect_reject nested-quote-override.txt "more than one" "nested 4-backtick pass cannot override hold"
expect_reject trailing-text.txt "content after" "trailing text after block rejected"
expect_reject pass-contradiction.txt "contradicts" "pass with evidenced tier 0 rejected"
expect_reject unknown-agent.txt "agent must be one of" "unknown agent rejected"
expect_reject verifier-fix-before-merge.txt "only emit pass|hold" "verifier fix-before-merge rejected"
expect_reject verifier-unevidenced-hold.txt "needs an evidenced" "verifier unevidenced hold rejected"

expect_reject duplicate-key.txt "duplicate JSON key: verdict" "duplicate key rejected"
expect_reject duplicate-key-nested.txt "duplicate JSON key: findings.0.tier" "nested duplicate key rejected"
expect_reject duplicate-key-container.txt "duplicate JSON key: findings" "duplicate key with array/object values rejected"

set +e
out="$(bash "$PARSE" --expect-head 0123456789abcdef0123456789abcdef01234567 "$FIX/pass.txt")"
rc=$?
set -e
expect_rc 0 "--expect-head match"
pass "--expect-head match"

set +e
err="$(bash "$PARSE" --expect-head ffffffffffffffffffffffffffffffffffffffff "$FIX/pass.txt" 2>&1 >/dev/null)"
rc=$?
set -e
expect_rc 1 "--expect-head mismatch"
[[ "$err" == *"does not match --expect-head"* ]] || fail "--expect-head mismatch reason (stderr: $err)"
pass "--expect-head mismatch"

run no-block.txt
expect_rc 1 "missing block exits 1"
[[ -z "$out" ]] || fail "missing block prints nothing on stdout"
[[ "$err" == *"no \`\`\`json block"* ]] || fail "missing block reason (stderr: $err)"
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
