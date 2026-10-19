#!/usr/bin/env bash
# review-gate-stop-test.sh — Tier 0 tests for .claude/hooks/review-gate-stop.sh
# (issue #258) against throwaway git repos.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$REPO/.claude/hooks/review-gate-stop.sh"
BASH_BIN="$(command -v bash)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# Fail-open session markers land under $TMPDIR; keep them inside this run.
export TMPDIR="$TMP/tmpdir"
mkdir -p "$TMPDIR"

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1"; exit 1; }

# new_repo <dir> — repo with an initial commit on main, then branch `feat`.
new_repo() {
  local d="$1"
  mkdir -p "$d"
  git -C "$d" init -q -b main
  git -C "$d" config user.email t@example.com
  git -C "$d" config user.name t
  echo "# readme" > "$d/README.md"
  git -C "$d" add -A
  git -C "$d" commit -q -m init
  git -C "$d" checkout -q -b feat
}

commit_file() {
  local d="$1" f="$2"
  mkdir -p "$(dirname "$d/$f")"
  echo "x $RANDOM" >> "$d/$f"
  git -C "$d" add -A
  git -C "$d" commit -q -m "change $f"
}

# verdict <dir> <agent> <verdict> [head] — write a captured artifact.
verdict() {
  local d="$1" a="$2" v="$3" h="${4:-$(git -C "$1" rev-parse HEAD)}"
  mkdir -p "$d/.claude/reviews"
  printf '*\n' > "$d/.claude/reviews/.gitignore"
  jq -cn --arg a "$a" --arg v "$v" --arg h "$h" \
    '{schema: "agentic-os/review-verdict@1", agent: $a, base: "main", head: $h, verdict: $v, findings: []}' \
    > "$d/.claude/reviews/$h-$a.json"
}

# run <dir> [payload] [hook] — sets $out, $err.
run() {
  local d="$1" payload="${2:-{\"stop_hook_active\":false\}}" hook="${3:-$HOOK}" errf
  errf="$(mktemp)"
  out="$(cd "$d" && printf '%s' "$payload" | CLAUDE_PROJECT_DIR="$d" "$BASH_BIN" "$hook" 2>"$errf")" \
    || fail "hook exited nonzero (stderr: $(cat "$errf"))"
  err="$(cat "$errf")"; rm -f "$errf"
}

# Allow = no stdout, or JSON without a decision (e.g. a systemMessage warning).
expect_allow() {
  [[ -z "$out" ]] || printf '%s' "$out" | jq -e 'has("decision") | not' >/dev/null 2>&1 \
    || fail "$1: expected allow, got: $out"
  pass "$1"
}
expect_silent() { [[ -z "$out" ]] || fail "$1: expected no output, got: $out"; pass "$1"; }
# expect_block <label> [needle...] — block JSON whose reason contains each needle.
expect_block() {
  local label="$1" needle; shift
  printf '%s' "$out" | jq -e '.decision == "block" and (.reason | type) == "string"' >/dev/null \
    || fail "$label: expected block, got: '$out'"
  for needle in "$@"; do
    printf '%s' "$out" | jq -e --arg n "$needle" '.reason | contains($n)' >/dev/null \
      || fail "$label: reason lacks '$needle': $out"
  done
  pass "$label"
}
reason_lacks() {
  printf '%s' "$out" | jq -e --arg n "$2" '.reason | contains($n) | not' >/dev/null \
    || fail "$1: reason should not contain '$2': $out"
}

# 1. Not a git repo.
mkdir -p "$TMP/nogit"
run "$TMP/nogit"; expect_allow "not a git repo passes"

# 2. Clean branch, no diff vs main.
new_repo "$TMP/clean"
run "$TMP/clean"; expect_allow "no diff passes"

# 3. Docs-only diff.
new_repo "$TMP/docs"
commit_file "$TMP/docs" docs/guide.md
commit_file "$TMP/docs" NOTES.md
run "$TMP/docs"; expect_allow "docs-only diff passes"

# 4. Code diff, no verdicts → block naming both reviewers (fallback planner).
new_repo "$TMP/code"
commit_file "$TMP/code" src/app.ts
run "$TMP/code"
expect_block "missing verdict blocks, naming reviewers" "code-reviewer" "security-reviewer"
echo "  sample reason: $(printf '%s' "$out" | jq -r .reason)"

# 5. One verdict present → block names only the missing one.
verdict "$TMP/code" code-reviewer pass
run "$TMP/code"
expect_block "partial verdicts block on the missing reviewer" "security-reviewer"
reason_lacks "partial verdicts" "from: code-reviewer"
printf '%s' "$out" | jq -e '.reason | test("from: security-reviewer\\.")' >/dev/null \
  || fail "missing list is exactly security-reviewer: $out"

# 6. All pass → allow; artifacts in .claude/reviews/ don't count as changes.
verdict "$TMP/code" security-reviewer pass
run "$TMP/code"; expect_allow "pass verdicts for all required reviewers pass"

# 7. hold blocks.
verdict "$TMP/code" security-reviewer hold
run "$TMP/code"
expect_block "hold blocks" "Evidenced hold from: security-reviewer"

# 8. fix-before-merge passes.
verdict "$TMP/code" security-reviewer fix-before-merge
run "$TMP/code"; expect_allow "fix-before-merge passes"

# 9. fix-before-merge is info when something else blocks.
rm -f "$TMP/code/.claude/reviews/"*-code-reviewer.json
run "$TMP/code"
expect_block "fix-before-merge listed as info alongside a block" \
  "from: code-reviewer" "Info (advisory, not blocking): fix-before-merge from: security-reviewer"

# 10. Stale verdicts (old HEAD) block.
verdict "$TMP/code" code-reviewer pass
verdict "$TMP/code" security-reviewer pass
commit_file "$TMP/code" src/app.ts
run "$TMP/code"
expect_block "stale verdict for an old HEAD blocks" "code-reviewer" "security-reviewer"

# 11. Artifact with mismatched head content is treated as missing.
h="$(git -C "$TMP/code" rev-parse HEAD)"
verdict "$TMP/code" code-reviewer pass ffffffffffffffffffffffffffffffffffffffff
mv "$TMP/code/.claude/reviews/ffffffffffffffffffffffffffffffffffffffff-code-reviewer.json" \
  "$TMP/code/.claude/reviews/$h-code-reviewer.json"
verdict "$TMP/code" security-reviewer pass
run "$TMP/code"
expect_block "artifact whose head field mismatches is ignored" "code-reviewer"

# 12. Dirty tree with qualifying changes blocks, even with verdicts for HEAD.
verdict "$TMP/code" code-reviewer pass
run "$TMP/code"; expect_allow "precondition: reviewed HEAD passes"
echo "dirty" >> "$TMP/code/src/app.ts"
run "$TMP/code"
expect_block "dirty tracked file blocks" "Verdicts bind to a HEAD sha"
git -C "$TMP/code" checkout -q -- src/app.ts
echo "new" > "$TMP/code/src/new.ts"
run "$TMP/code"
expect_block "untracked qualifying file blocks" "Verdicts bind to a HEAD sha" "src/new.ts"
rm -f "$TMP/code/src/new.ts"

# 13. Dirty docs-only changes do not trigger the commit-first block.
echo "draft" > "$TMP/code/DRAFT.md"
run "$TMP/code"; expect_allow "dirty docs-only change passes when HEAD is reviewed"
rm -f "$TMP/code/DRAFT.md"

# 14. Dirty-only qualifying change on an otherwise clean branch blocks.
new_repo "$TMP/dirtyonly"
echo "x" > "$TMP/dirtyonly/main.py"
run "$TMP/dirtyonly"
expect_block "dirty-only qualifying change blocks" "Verdicts bind to a HEAD sha"

# 15. stop_hook_active passes.
run "$TMP/dirtyonly" '{"stop_hook_active":true}'
expect_allow "stop_hook_active passes"

# 16. Opt-out passes.
errf="$(mktemp)"
out="$(cd "$TMP/dirtyonly" && printf '{}' | AGENTIC_OS_REVIEW_GATE=off CLAUDE_PROJECT_DIR="$TMP/dirtyonly" "$BASH_BIN" "$HOOK" 2>"$errf")"
rm -f "$errf"
expect_allow "AGENTIC_OS_REVIEW_GATE=off passes"

# 17. Missing jq fails open with a stderr note (PATH has every tool but jq).
mkdir -p "$TMP/nojq-bin"
for t in git head sed id mkdir cat dirname grep sort paste; do
  ln -sf "$(command -v "$t")" "$TMP/nojq-bin/$t"
done
errf="$(mktemp)"
set +e
out="$(cd "$TMP/dirtyonly" && printf '{}' | PATH="$TMP/nojq-bin" CLAUDE_PROJECT_DIR="$TMP/dirtyonly" "$BASH_BIN" "$HOOK" 2>"$errf")"
rc=$?
set -e
err="$(cat "$errf")"; rm -f "$errf"
[[ "$rc" == 0 ]] || fail "missing jq exit $rc"
[[ "$err" == "review-gate-stop: jq not found — gate skipped (fail-open)" ]] || fail "missing jq stderr note: $err"
printf '%s' "$out" | jq -e '.systemMessage | contains("jq not found")' >/dev/null || fail "missing jq systemMessage: $out"
expect_allow "missing jq fails open"

# 18. Malformed payload fails open; the note prints once per session.
run "$TMP/dirtyonly" 'not json'
expect_allow "malformed payload fails open"
[[ "$err" == *"fail-open"* ]] || fail "malformed payload stderr note: $err"
run "$TMP/dirtyonly" '{"session_id":"sess-1", broken'
[[ "$err" == *"fail-open"* ]] || fail "first fail-open of a session must note: $err"
run "$TMP/dirtyonly" '{"session_id":"sess-1", broken'
[[ -z "$err" ]] || fail "second fail-open of the same session must be silent: $err"
expect_silent "fail-open note printed once per session"
run "$TMP/dirtyonly" '{"session_id":"sess-2", broken'
[[ "$err" == *"fail-open"* ]] || fail "a new session notes again: $err"
pass "fail-open note repeats for a new session"

# 19. No resolvable default branch fails open.
new_repo "$TMP/nomain"
git -C "$TMP/nomain" branch -q -m main trunk
commit_file "$TMP/nomain" src/a.go
git -C "$TMP/nomain" branch -q -D main 2>/dev/null || true
run "$TMP/nomain"
expect_allow "no default branch fails open"
[[ "$err" == *"no default branch"* ]] || fail "no default branch stderr note: $err"

# 20. origin/main is preferred over a stale local main.
new_repo "$TMP/remote-up"
git -C "$TMP/remote-up" checkout -q main
commit_file "$TMP/remote-up" src/shipped.ts
git -C "$TMP/remote-up" update-ref refs/remotes/origin/main HEAD
git -C "$TMP/remote-up" reset -q --hard HEAD~1
git -C "$TMP/remote-up" checkout -q feat
git -C "$TMP/remote-up" reset -q --hard refs/remotes/origin/main
commit_file "$TMP/remote-up" README.md
run "$TMP/remote-up"; expect_allow "diff is computed against origin/main"

# 21. In-repo planner: hook running from the project's own .claude/hooks uses
#     scripts/gate-plan.sh (library paths require library-reviewer; the
#     documenter checkbox is not a verdict and is not required).
new_repo "$TMP/planner"
mkdir -p "$TMP/planner/.claude/hooks/lib" "$TMP/planner/scripts/lib"
cp "$HOOK" "$TMP/planner/.claude/hooks/"
cp "$REPO/scripts/gate-plan.sh" "$TMP/planner/scripts/"
cp "$REPO/scripts/lib/gate-plan-lib.sh" "$TMP/planner/scripts/lib/"
git -C "$TMP/planner" add -A
git -C "$TMP/planner" commit -q -m "tooling"
commit_file "$TMP/planner" .claude/skills/x/SKILL.md
run "$TMP/planner" '{"stop_hook_active":false}' "$TMP/planner/.claude/hooks/review-gate-stop.sh"
expect_block "in-repo planner requires library-reviewer" "library-reviewer" "code-reviewer" "security-reviewer"
reason_lacks "in-repo planner" "data-model-documenter"
for a in code-reviewer security-reviewer library-reviewer; do verdict "$TMP/planner" "$a" pass; done
run "$TMP/planner" '{"stop_hook_active":false}' "$TMP/planner/.claude/hooks/review-gate-stop.sh"
expect_allow "in-repo planner: all required verdicts pass"

# 22. DATA_MODEL.md is not docs-only (fallback planner).
new_repo "$TMP/dm"
commit_file "$TMP/dm" DATA_MODEL.md
run "$TMP/dm"
expect_block "DATA_MODEL.md change requires review" "code-reviewer"

# 23. Artifacts are excluded from the change set even without the dir's own
#     .gitignore (a consumer repo that doesn't ignore .claude/reviews/).
rm -f "$TMP/dm/.claude/reviews/.gitignore"
verdict "$TMP/dm" code-reviewer pass
verdict "$TMP/dm" security-reviewer pass
rm -f "$TMP/dm/.claude/reviews/.gitignore"
run "$TMP/dm"; expect_allow "un-ignored .claude/reviews/ artifacts are not changes"

# 24. Untracked .claude/worktrees/ content is excluded; other untracked noise
#     blocks with a reason that forbids committing unrelated files.
mkdir -p "$TMP/dm/.claude/worktrees/agent-1"
echo "x" > "$TMP/dm/.claude/worktrees/agent-1/app.ts"
run "$TMP/dm"; expect_allow "untracked .claude/worktrees/ is not a change"
echo "log" > "$TMP/dm/build.log"
run "$TMP/dm"
expect_block "untracked noise blocks without telling the model to commit it" \
  "commit only the changes you intend to ship" "Never commit files you did not create" "tell the user"
rm -f "$TMP/dm/build.log"

# 25. Planner failure fails open with a note (not silently "nothing required").
new_repo "$TMP/pfail"
mkdir -p "$TMP/pfail/.claude/hooks" "$TMP/pfail/scripts"
cp "$HOOK" "$TMP/pfail/.claude/hooks/"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP/pfail/scripts/gate-plan.sh"
git -C "$TMP/pfail" add -A
git -C "$TMP/pfail" commit -q -m tooling
run "$TMP/pfail" '{"stop_hook_active":false}' "$TMP/pfail/.claude/hooks/review-gate-stop.sh"
expect_allow "planner failure fails open"
[[ "$err" == *"planner failed"* ]] || fail "planner failure note: $err"

# 26. A hook outside the repo never runs the repo's scripts/gate-plan.sh.
new_repo "$TMP/evilplan"
mkdir -p "$TMP/evilplan/scripts"
printf '#!/usr/bin/env bash\ntouch "%s"\n' "$TMP/evil-ran" > "$TMP/evilplan/scripts/gate-plan.sh"
git -C "$TMP/evilplan" add -A
git -C "$TMP/evilplan" commit -q -m planner
run "$TMP/evilplan"
[[ ! -e "$TMP/evil-ran" ]] || fail "hook outside the repo executed the repo's gate-plan.sh"
expect_block "outside hook uses the fallback planner, not the repo's script" "code-reviewer" "security-reviewer"

# 27. Worktrees: the payload cwd wins over CLAUDE_PROJECT_DIR; the planner of
#     the hook's own checkout is used for a worktree of the same repo.
new_repo "$TMP/wtmain"
mkdir -p "$TMP/wtmain/.claude/hooks" "$TMP/wtmain/scripts/lib"
cp "$HOOK" "$TMP/wtmain/.claude/hooks/"
cp "$REPO/scripts/gate-plan.sh" "$TMP/wtmain/scripts/"
cp "$REPO/scripts/lib/gate-plan-lib.sh" "$TMP/wtmain/scripts/lib/"
git -C "$TMP/wtmain" add -A
git -C "$TMP/wtmain" commit -q -m tooling
git -C "$TMP/wtmain" checkout -q main
git -C "$TMP/wtmain" merge -q --ff-only feat
git -C "$TMP/wtmain" worktree add -q -b wtfeat "$TMP/wt"
commit_file "$TMP/wt" .claude/agents/x.md
wt_payload="$(jq -cn --arg c "$TMP/wt" '{stop_hook_active: false, cwd: $c}')"
errf="$(mktemp)"
out="$(printf '%s' "$wt_payload" | CLAUDE_PROJECT_DIR="$TMP/wtmain" "$BASH_BIN" "$TMP/wtmain/.claude/hooks/review-gate-stop.sh" 2>"$errf")"
rm -f "$errf"
expect_block "worktree diff is gated via payload cwd, with the repo planner" "library-reviewer"
for a in code-reviewer security-reviewer library-reviewer; do verdict "$TMP/wt" "$a" pass; done
out="$(printf '%s' "$wt_payload" | CLAUDE_PROJECT_DIR="$TMP/wtmain" "$BASH_BIN" "$TMP/wtmain/.claude/hooks/review-gate-stop.sh" 2>/dev/null)"
expect_allow "worktree verdicts for the worktree HEAD pass"

# 28. A repo with only `master` (no origin) still has a base.
mkdir -p "$TMP/master"
git -C "$TMP/master" init -q -b master
git -C "$TMP/master" config user.email t@example.com
git -C "$TMP/master" config user.name t
echo "# r" > "$TMP/master/README.md"
git -C "$TMP/master" add -A
git -C "$TMP/master" commit -q -m init
git -C "$TMP/master" checkout -q -b feat
commit_file "$TMP/master" src/a.rs
run "$TMP/master"
expect_block "master is a default-branch fallback" "vs master" "code-reviewer"

# 29. origin/HEAD moved onto HEAD: no silent pass — the user is warned.
new_repo "$TMP/moved"
commit_file "$TMP/moved" src/a.ts
git -C "$TMP/moved" update-ref refs/remotes/origin/HEAD HEAD
run "$TMP/moved"
expect_allow "moved origin/HEAD allows"
printf '%s' "$out" | jq -e '.systemMessage | contains("no commits beyond origin/HEAD") and contains("main")' >/dev/null \
  || fail "moved origin/HEAD must warn via systemMessage: '$out'"
pass "moved origin/HEAD warns the user"

echo "review-gate-stop-test: OK"
