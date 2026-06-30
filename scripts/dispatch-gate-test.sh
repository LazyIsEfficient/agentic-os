#!/usr/bin/env bash
# dispatch-gate-test.sh — Tier 0 tests for dispatch enforcement lib + plan.
# Path expectations are adapted for this LIBRARY repo (the gate's "code" surfaces
# are .claude/skills|agents|commands|workflows + scripts/, not a game client).
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/dispatch-gate-lib.sh
source "$REPO/scripts/lib/dispatch-gate-lib.sh"
# shellcheck source=lib/dispatch-gate-plan-lib.sh
source "$REPO/scripts/lib/dispatch-gate-plan-lib.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export CURSOR_PROJECT_DIR="$TMP"
mkdir -p "$TMP/.cursor"
cp "$REPO/.cursor/dispatch-gate.json" "$TMP/.cursor/dispatch-gate.json"

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

dispatch_gate_require_jq || fail "jq required"

# dispatch-gate test (enabled switch): guard the jq `.enabled // true` footgun —
# `false // true` evaluates to `true`, which would leave the gate armed even when
# the operator sets `enabled:false`. Only an explicit `false` may disable it; a
# missing key defaults to enabled.
GATE_CFG="$TMP/.cursor/dispatch-gate.json"
jq '.enabled = false' "$GATE_CFG" > "$GATE_CFG.tmp" && mv "$GATE_CFG.tmp" "$GATE_CFG"
if dispatch_gate_is_enabled; then fail "enabled:false must disable the gate (jq // footgun)"; fi
jq '.enabled = true' "$GATE_CFG" > "$GATE_CFG.tmp" && mv "$GATE_CFG.tmp" "$GATE_CFG"
dispatch_gate_is_enabled || fail "enabled:true must enable the gate"
jq 'del(.enabled)' "$GATE_CFG" > "$GATE_CFG.tmp" && mv "$GATE_CFG.tmp" "$GATE_CFG"
dispatch_gate_is_enabled || fail "missing enabled key must default to enabled"
cp "$REPO/.cursor/dispatch-gate.json" "$GATE_CFG"
pass "enabled:false disables the gate (jq // footgun closed)"

# dispatch-gate test (flag footguns): the same `// true` bug affected every
# default-true flag. With a ledger that WOULD be denied, setting each flag to
# false must actually disable its gate.
foot_led='{"research_reads":99,"explore_dispatched":false,"impl_completed":false}'
foot_base="$(cat "$REPO/.cursor/dispatch-gate.json")"
if dispatch_gate_research_denied "$(printf '%s' "$foot_base" | jq '.enforce_research_gate=false')" "$foot_led"; then
  fail "enforce_research_gate:false must disable the research gate"
fi
if dispatch_gate_impl_denied "$(printf '%s' "$foot_base" | jq '.enforce_impl_gate=false')" "$foot_led" ".claude/skills/foo/SKILL.md"; then
  fail "enforce_impl_gate:false must disable the impl gate"
fi
pass "enforce_*_gate:false disables gates (jq // footgun closed)"

dispatch_gate_init_ledger "test-conv"
ledger="$(dispatch_gate_read_ledger "test-conv")"
[ "$(printf '%s' "$ledger" | jq -r '.research_reads')" = "0" ] || fail "ledger init research_reads"

dispatch_gate_record_research_read "test-conv"
dispatch_gate_record_research_read "test-conv"
dispatch_gate_record_research_read "test-conv"
ledger="$(dispatch_gate_read_ledger "test-conv")"
[ "$(printf '%s' "$ledger" | jq -r '.research_reads')" = "3" ] || fail "research read counter"

cfg="$(dispatch_gate_load_json_file "$TMP/.cursor/dispatch-gate.json")"
if dispatch_gate_research_denied "$cfg" "$ledger"; then
  pass "research denied after threshold"
else
  fail "research should be denied at 3 reads without explore"
fi

dispatch_gate_record_task_dispatch "test-conv" "explore"
ledger="$(dispatch_gate_read_ledger "test-conv")"
if dispatch_gate_research_denied "$cfg" "$ledger"; then
  fail "research should be allowed after explore dispatch"
else
  pass "explore dispatch clears research gate"
fi

dispatch_gate_record_subagent_stop "test-conv" "engineer" "completed"
ledger="$(dispatch_gate_read_ledger "test-conv")"
if dispatch_gate_impl_denied "$cfg" "$ledger" ".claude/skills/foo/SKILL.md"; then
  fail "impl gate should open after engineer completes"
else
  pass "impl gate opens after implementation subagent completes"
fi

dispatch_plan_run $'.claude/skills/foo/SKILL.md\n.cursor/hooks/foo.sh'
[ "$DISPATCH_PLAN_IS_LIBRARY" = true ] || fail "skills path is library change"
[ "$DISPATCH_PLAN_IS_SENSITIVE" = true ] || fail "hook path is sensitive"
dispatch_plan_missing_reviews ""
missing_count="${#dispatch_plan_missing[@]}"
[ "$missing_count" -ge 2 ] || fail "missing reviewers should include code+security (got $missing_count: ${dispatch_plan_missing[*]})"
pass "gate plan classifies library paths"

# dispatch-gate test: stringified tool_input path
payload='{"tool_name":"StrReplace","tool_input":"{\"path\":\".claude/skills/foo/SKILL.md\"}","composer_mode":"agent"}'
path="$(dispatch_gate_extract_write_path "$payload")"
[ "$path" = ".claude/skills/foo/SKILL.md" ] || fail "extract path from stringified tool_input (got '$path')"

# dispatch-gate test: absolute path normalization
payload='{"tool_name":"Write","tool_input":{"path":"'"$TMP"'/.claude/skills/foo/SKILL.md"},"composer_mode":"agent"}'
path="$(dispatch_gate_extract_write_path "$payload")"
[ "$path" = ".claude/skills/foo/SKILL.md" ] || fail "normalize absolute path (got '$path')"
pass "write path extraction"

# dispatch-gate test: missing-reviewers list joins on a single ", " (paste -d footgun)
msg="$(dispatch_gate_format_missing_review_message "code-reviewer" "security-reviewer" "data-model-documenter")"
case "$msg" in
  *"code-reviewer, security-reviewer, data-model-documenter"*) pass "missing reviewers join uses single ', '" ;;
  *) fail "missing reviewers join malformed: $(printf '%s' "$msg" | grep -i 'Missing reviewers')" ;;
esac

# dispatch-gate test: stop gate must NOT demand reviewers when nothing changed
# ($TMP is not a git repo, so git_changed_files is empty). Guards against the
# inverted-return regression that looped every clean/Q&A turn.
ledger="$(dispatch_gate_read_ledger "stop-test")"
if dispatch_gate_missing_reviewers_for_worktree "$ledger"; then
  fail "stop gate must not demand reviewers with no changed files"
else
  pass "stop gate skips when worktree clean"
fi

# dispatch-gate test (bug B): non-reviewable churn (eval metric runs) is not a
# code change and a churn-only diff skips reviewers — mirrors gate-plan-lib.sh.
dispatch_plan_run 'eval/metrics/runs/2026-01-01.json'
[ "$DISPATCH_PLAN_IS_CODE_CHANGE" = false ] || fail "eval metrics churn must not classify as code"
[ "$DISPATCH_PLAN_SKIP_DOCS_ONLY" = true ] || fail "churn-only diff must skip reviewers"
pass "eval metrics churn does not trigger the gate"

# dispatch-gate test (bug C): '..' inside an exempt prefix collapses to the real
# code path, so the traversal cannot masquerade as exempt.
norm="$(dispatch_gate_normalize_rel_path '.cursor/hooks/../../.claude/skills/foo/SKILL.md')"
[ "$norm" = ".claude/skills/foo/SKILL.md" ] || fail "'..' not collapsed (got '$norm')"
if dispatch_gate_path_exempt "$norm" "$cfg"; then
  fail "traversal path must not be exempt after normalization"
fi
dispatch_gate_path_is_code "$norm" "$cfg" || fail "collapsed traversal path must classify as code"
pass "path traversal through exempt prefix is blocked"

# dispatch-gate test (bug D): case-insensitive prefix match (macOS APFS)
dispatch_gate_path_is_code "Scripts/dispatch_demo.py" "$cfg" || fail "mixed-case code path must classify as code"
pass "case-insensitive code-path classification"

# dispatch-gate test (bug I): a completed data-model-documenter must register in
# completed_reviews, else the stop gate (which requires it in Wave 1) never clears.
dispatch_gate_record_subagent_stop "test-conv" "data-model-documenter" "completed"
ledger="$(dispatch_gate_read_ledger "test-conv")"
case ",$(printf '%s' "$ledger" | jq -r '.completed_reviews | join(",")')," in
  *",data-model-documenter,"*) pass "documenter completion recorded in completed_reviews" ;;
  *) fail "data-model-documenter not recorded; stop gate would loop forever" ;;
esac

# dispatch-gate test (bug #8 caf86690): concurrent subagentStop writes must not
# lose updates. Fire N parallel reviewer recordings; every one must survive the
# locked read-modify-write. Without the mkdir lock this drops entries.
dispatch_gate_init_ledger "race-conv"
race_types=(code-reviewer security-reviewer library-reviewer data-model-verifier bugbot security-review)
for rt in "${race_types[@]}"; do
  dispatch_gate_record_subagent_stop "race-conv" "$rt" "completed" &
done
wait
ledger="$(dispatch_gate_read_ledger "race-conv")"
got="$(printf '%s' "$ledger" | jq -r '.completed_reviews | length')"
[ "$got" -eq "${#race_types[@]}" ] || fail "concurrent writes lost updates (got $got/${#race_types[@]}: $(printf '%s' "$ledger" | jq -c '.completed_reviews'))"
pass "concurrent subagentStop writes are serialized (no lost updates)"

printf 'dispatch-gate-test: OK\n'
