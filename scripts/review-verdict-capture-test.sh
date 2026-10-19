#!/usr/bin/env bash
# review-verdict-capture-test.sh — Tier 0 tests for
# .claude/hooks/review-verdict-capture.sh (issue #258) against throwaway repos.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$REPO/.claude/hooks/review-verdict-capture.sh"
BASH_BIN="$(command -v bash)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; exit 1; }

R="$TMP/repo"
mkdir -p "$R"
git -C "$R" init -q -b main
git -C "$R" config user.email t@example.com
git -C "$R" config user.name t
echo x > "$R/a.ts"
git -C "$R" add -A
git -C "$R" commit -q -m init
HEAD_SHA="$(git -C "$R" rev-parse HEAD)"
REVIEWS="$R/.claude/reviews"

# msg <agent> <verdict> [head] — reviewer final message ending in a verdict block.
msg() {
  local a="$1" v="$2" h="${3:-$HEAD_SHA}" findings="[]"
  [[ "$v" == hold ]] && findings='[{"tier":1,"severity":"high","file":"a.ts","line":1,"summary":"s","evidence":"bash t.sh exits 1"}]'
  printf 'Review done.\n\n```json\n{"schema":"agentic-os/review-verdict@1","agent":"%s","base":"main","head":"%s","verdict":"%s","findings":%s}\n```\n' \
    "$a" "$h" "$v" "$findings"
}

# fire <agent_type> <last_assistant_message> [extra jq object] — run the hook.
fire() {
  local payload errf
  payload="$(jq -cn --arg t "$1" --arg m "$2" --argjson x "${3:-{\}}" \
    '{hook_event_name: "SubagentStop", stop_hook_active: false, agent_id: "a1", agent_type: $t, last_assistant_message: $m} + $x')"
  errf="$(mktemp)"
  out="$(printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$R" "$BASH_BIN" "$HOOK" 2>"$errf")" \
    || fail "hook exited nonzero (stderr: $(cat "$errf"))"
  err="$(cat "$errf")"; rm -f "$errf"
  [[ -z "$out" ]] || fail "hook must not print to stdout (never blocks a subagent): $out"
}

artifact() { printf '%s' "$REVIEWS/$HEAD_SHA-$1.json"; }
count_files() { find "$REVIEWS" -name '*.json' 2>/dev/null | wc -l | tr -d ' '; }

# 1. pass → written, normalized.
fire code-reviewer "$(msg code-reviewer pass)"
jq -e --arg h "$HEAD_SHA" '.verdict == "pass" and .agent == "code-reviewer" and .head == $h' "$(artifact code-reviewer)" >/dev/null \
  || fail "pass artifact"
pass "pass verdict captured"
[[ "$(cat "$REVIEWS/.gitignore")" == "*" ]] || fail "reviews dir self-ignores"
[[ -z "$(git -C "$R" status --porcelain)" ]] || fail "artifacts must not dirty the tree: $(git -C "$R" status --porcelain)"
pass "reviews dir is self-gitignored"

# 2. hold (evidenced) → written; 3. fix-before-merge → written.
fire security-reviewer "$(msg security-reviewer hold)"
jq -e '.verdict == "hold"' "$(artifact security-reviewer)" >/dev/null || fail "hold artifact"
pass "hold verdict captured"
fire library-reviewer "$(msg library-reviewer fix-before-merge)"
jq -e '.verdict == "fix-before-merge"' "$(artifact library-reviewer)" >/dev/null || fail "fbm artifact"
pass "fix-before-merge verdict captured"

# 4. Re-review overwrites (hold → pass).
fire security-reviewer "$(msg security-reviewer pass)"
jq -e '.verdict == "pass"' "$(artifact security-reviewer)" >/dev/null || fail "overwrite"
pass "re-review overwrites the artifact"

# 5. Invalid blocks write nothing.
n="$(count_files)"
fire data-model-verifier "no verdict block here"
[[ ! -e "$(artifact data-model-verifier)" ]] || fail "missing block wrote a file"
[[ "$err" == *"not captured"* ]] || fail "invalid verdict stderr note: $err"
fire data-model-verifier "$(msg data-model-verifier pass ffffffffffffffffffffffffffffffffffffffff)"
[[ ! -e "$(artifact data-model-verifier)" ]] || fail "stale head wrote a file"
fire data-model-verifier "$(msg data-model-verifier pass) trailing text"
[[ ! -e "$(artifact data-model-verifier)" ]] || fail "trailing text wrote a file"
[[ "$(count_files)" == "$n" ]] || fail "invalid verdicts changed the file count"
pass "invalid / stale-head verdicts are not written"

# 6. Agent mismatch: code-reviewer emitting a security-reviewer verdict.
rm -f "$(artifact security-reviewer)"
fire code-reviewer "$(msg security-reviewer pass)"
[[ ! -e "$(artifact security-reviewer)" ]] || fail "mismatched agent wrote security-reviewer artifact"
pass "verdict naming a different agent is not written"

# 7. Non-reviewer subagents are ignored.
n="$(count_files)"
fire Explore "$(msg code-reviewer pass)"
fire engineer "$(msg code-reviewer pass)"
fire "" "$(msg code-reviewer pass)"
[[ "$(count_files)" == "$n" ]] || fail "non-reviewer wrote a file"
[[ -z "$err" ]] || fail "non-reviewer should be silent: $err"
pass "non-reviewer subagents ignored"

# 8. Malicious agent names cannot escape .claude/reviews/.
for bad in "../x" "../../code-reviewer" "code-reviewer/../../x" "code-reviewer security-reviewer" $'code-reviewer\n../x'; do
  fire "$bad" "$(msg code-reviewer pass)"
done
[[ -z "$(find "$TMP" -name '*x.json' -o -name '*-..*' | head -1)" ]] || fail "traversal wrote outside"
[[ ! -e "$R/.claude/x.json" && ! -e "$R/x.json" ]] || fail "traversal artifact"
[[ "$(count_files)" == "$n" ]] || fail "malicious agent name wrote a file"
pass "malicious agent name cannot escape .claude/reviews/"

# 9. Transcript fallback when last_assistant_message is absent.
CFG="$TMP/cfg"
mkdir -p "$CFG/projects/p/s/subagents"
T="$CFG/projects/p/s/subagents/agent-a1.jsonl"
{
  jq -cn '{type: "user", message: {content: "review"}}'
  jq -cn --arg m "$(msg data-model-verifier hold)" '{type: "assistant", message: {content: [{type: "text", text: "draft"}]}}'
  jq -cn --arg m "$(msg data-model-verifier pass)" '{type: "assistant", message: {content: [{type: "text", text: $m}]}}'
} > "$T"
payload="$(jq -cn --arg p "$T" '{agent_type: "data-model-verifier", agent_transcript_path: $p}')"
printf '%s' "$payload" | CLAUDE_CONFIG_DIR="$CFG" CLAUDE_PROJECT_DIR="$R" "$BASH_BIN" "$HOOK" 2>/dev/null
jq -e '.verdict == "pass" and .agent == "data-model-verifier"' "$(artifact data-model-verifier)" >/dev/null \
  || fail "transcript fallback"
pass "transcript fallback reads the last assistant text entry"

# 10. Transcript outside the projects dir is refused.
rm -f "$(artifact data-model-verifier)"
cp "$T" "$TMP/evil.jsonl"
payload="$(jq -cn --arg p "$TMP/evil.jsonl" '{agent_type: "data-model-verifier", agent_transcript_path: $p}')"
err="$(printf '%s' "$payload" | CLAUDE_CONFIG_DIR="$CFG" CLAUDE_PROJECT_DIR="$R" "$BASH_BIN" "$HOOK" 2>&1 >/dev/null)"
[[ ! -e "$(artifact data-model-verifier)" ]] || fail "uncontained transcript was read"
[[ "$err" == *"outside"* ]] || fail "uncontained transcript note: $err"
pass "transcript outside the projects dir is refused"

# 11. Symlinked reviews dir is refused.
R2="$TMP/repo2"
git clone -q "$R" "$R2"
mkdir -p "$R2/.claude" "$TMP/elsewhere"
ln -s "$TMP/elsewhere" "$R2/.claude/reviews"
payload="$(jq -cn --arg m "$(msg code-reviewer pass)" '{agent_type: "code-reviewer", last_assistant_message: $m}')"
printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$R2" "$BASH_BIN" "$HOOK" 2>/dev/null
[[ -z "$(ls -A "$TMP/elsewhere")" ]] || fail "wrote through a symlinked reviews dir"
pass "symlinked .claude/reviews is refused"

# 11b. Committed dangling .gitignore symlink must not create a file outside
#      the repo (F1), and a symlinked .claude/ is refused.
R3="$TMP/repo3"
git clone -q "$R" "$R3"
mkdir -p "$R3/.claude/reviews"
ln -s "$TMP/outside-gitignore" "$R3/.claude/reviews/.gitignore"
printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$R3" "$BASH_BIN" "$HOOK" 2>/dev/null
[[ ! -e "$TMP/outside-gitignore" ]] || fail "wrote through a dangling .gitignore symlink"
[[ -z "$(find "$R3/.claude/reviews" -name '*.json')" ]] || fail "wrote a verdict despite a symlinked .gitignore"
pass "dangling .gitignore symlink is refused"
R4="$TMP/repo4"
git clone -q "$R" "$R4"
mkdir -p "$TMP/outside-claude"
ln -s "$TMP/outside-claude" "$R4/.claude"
printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$R4" "$BASH_BIN" "$HOOK" 2>/dev/null
[[ -z "$(ls -A "$TMP/outside-claude")" ]] || fail "wrote through a symlinked .claude"
pass "symlinked .claude is refused"

# 11c. Transcript fallback refuses a symlink (even inside projects/) and
#      non-.jsonl files.
rm -f "$(artifact data-model-verifier)"
ln -s "$TMP/evil.jsonl" "$CFG/projects/p/s/subagents/link.jsonl"
cp "$T" "$CFG/projects/p/s/subagents/agent-a1.txt"
for p in "$CFG/projects/p/s/subagents/link.jsonl" "$CFG/projects/p/s/subagents/agent-a1.txt"; do
  payload2="$(jq -cn --arg p "$p" '{agent_type: "data-model-verifier", agent_transcript_path: $p}')"
  err="$(printf '%s' "$payload2" | CLAUDE_CONFIG_DIR="$CFG" CLAUDE_PROJECT_DIR="$R" "$BASH_BIN" "$HOOK" 2>&1 >/dev/null)"
  [[ ! -e "$(artifact data-model-verifier)" ]] || fail "transcript $p was read"
  [[ "$err" == *"not a regular .jsonl"* ]] || fail "transcript $p note: $err"
done
pass "symlinked / non-.jsonl transcripts are refused"

# 11d. Size cap: a valid verdict after > MAX_BYTES of text is not captured.
rm -f "$(artifact code-reviewer)"
{ head -c 1100000 /dev/zero | tr '\0' 'a'; printf '\n\n'; msg code-reviewer pass; } > "$TMP/big.txt"
jq -Rs '{agent_type: "code-reviewer", last_assistant_message: .}' < "$TMP/big.txt" > "$TMP/big.json"
err="$(CLAUDE_PROJECT_DIR="$R" "$BASH_BIN" "$HOOK" < "$TMP/big.json" 2>&1 >/dev/null)"
[[ ! -e "$(artifact code-reviewer)" ]] || fail "oversized message was captured"
[[ "$err" == *"over 1048576 bytes"* ]] || fail "size cap note: $err"
pass "final message over the size cap is not captured"

# 11e. Worktree: payload cwd wins over CLAUDE_PROJECT_DIR.
git -C "$R" worktree add -q -b wt "$TMP/wt"
echo y > "$TMP/wt/b.ts"
git -C "$TMP/wt" add -A
git -C "$TMP/wt" commit -q -m wt
WT_HEAD="$(git -C "$TMP/wt" rev-parse HEAD)"
payload3="$(jq -cn --arg m "$(msg code-reviewer pass "$WT_HEAD")" --arg c "$TMP/wt" \
  '{agent_type: "code-reviewer", last_assistant_message: $m, cwd: $c}')"
printf '%s' "$payload3" | CLAUDE_PROJECT_DIR="$R" "$BASH_BIN" "$HOOK" 2>/dev/null
jq -e --arg h "$WT_HEAD" '.head == $h' "$TMP/wt/.claude/reviews/$WT_HEAD-code-reviewer.json" >/dev/null \
  || fail "worktree verdict not captured in the worktree"
[[ ! -e "$REVIEWS/$WT_HEAD-code-reviewer.json" ]] || fail "worktree verdict landed in the main checkout"
pass "worktree review binds to the worktree HEAD via payload cwd"

# 12. Missing jq fails open.
mkdir -p "$TMP/nojq-bin"
err="$(printf '{}' | PATH="$TMP/nojq-bin" CLAUDE_PROJECT_DIR="$R" "$BASH_BIN" "$HOOK" 2>&1)" || fail "missing jq exit nonzero"
[[ "$err" == *"jq not found"* ]] || fail "missing jq note: $err"
pass "missing jq fails open"

echo "review-verdict-capture-test: OK"
