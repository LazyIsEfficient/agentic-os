#!/usr/bin/env bash
# review-gate-stop-test.sh — Tier 0 tests for .claude/hooks/review-gate-stop.sh
# (issue #258) against throwaway git repos.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$REPO/.claude/hooks/review-gate-stop.sh"
BASH_BIN="$(command -v bash)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

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

expect_allow() { [[ -z "$out" ]] || fail "$1: expected allow, got: $out"; pass "$1"; }
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
expect_block "dirty tracked file blocks" "commit first"
git -C "$TMP/code" checkout -q -- src/app.ts
echo "new" > "$TMP/code/src/new.ts"
run "$TMP/code"
expect_block "untracked qualifying file blocks" "commit first" "src/new.ts"
rm -f "$TMP/code/src/new.ts"

# 13. Dirty docs-only changes do not trigger the commit-first block.
echo "draft" > "$TMP/code/DRAFT.md"
run "$TMP/code"; expect_allow "dirty docs-only change passes when HEAD is reviewed"
rm -f "$TMP/code/DRAFT.md"

# 14. Dirty-only qualifying change on an otherwise clean branch blocks.
new_repo "$TMP/dirtyonly"
echo "x" > "$TMP/dirtyonly/main.py"
run "$TMP/dirtyonly"
expect_block "dirty-only qualifying change blocks" "commit first"

# 15. stop_hook_active passes.
run "$TMP/dirtyonly" '{"stop_hook_active":true}'
expect_allow "stop_hook_active passes"

# 16. Opt-out passes.
errf="$(mktemp)"
out="$(cd "$TMP/dirtyonly" && printf '{}' | AGENTIC_OS_REVIEW_GATE=off CLAUDE_PROJECT_DIR="$TMP/dirtyonly" "$BASH_BIN" "$HOOK" 2>"$errf")"
rm -f "$errf"
expect_allow "AGENTIC_OS_REVIEW_GATE=off passes"

# 17. Missing jq fails open with a stderr note.
mkdir -p "$TMP/nojq-bin"
errf="$(mktemp)"
set +e
out="$(cd "$TMP/dirtyonly" && printf '{}' | PATH="$TMP/nojq-bin" CLAUDE_PROJECT_DIR="$TMP/dirtyonly" "$BASH_BIN" "$HOOK" 2>"$errf")"
rc=$?
set -e
err="$(cat "$errf")"; rm -f "$errf"
[[ "$rc" == 0 ]] || fail "missing jq exit $rc"
[[ "$err" == *"jq not found"*"fail-open"* ]] || fail "missing jq stderr note: $err"
expect_allow "missing jq fails open"

# 18. Malformed payload fails open.
run "$TMP/dirtyonly" 'not json'
expect_allow "malformed payload fails open"
[[ "$err" == *"fail-open"* ]] || fail "malformed payload stderr note: $err"

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

echo "review-gate-stop-test: OK"
