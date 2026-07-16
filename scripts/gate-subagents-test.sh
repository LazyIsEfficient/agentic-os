#!/usr/bin/env bash
# gate-subagents-test.sh — deterministic, OFFLINE test for the v4 dispatch gate
# (.claude/hooks/gate-subagents.sh, #230). Builds an isolated git project with a
# copy of gate-plan-lib.sh, then fires the hook with various subagent_types over
# various diffs and asserts allow (no output) vs deny (permissionDecision:deny).
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK="$REPO/.claude/hooks/gate-subagents.sh"
LIB="$REPO/scripts/lib/gate-plan-lib.sh"

command -v jq >/dev/null 2>&1 || { echo "gate-subagents-test: jq required" >&2; exit 2; }
{ [ -f "$HOOK" ] && [ -f "$LIB" ]; } || { echo "gate-subagents-test: hook or lib missing" >&2; exit 2; }

PROJ="$(mktemp -d)"
trap 'rm -rf "$PROJ"' EXIT
export CLAUDE_PROJECT_DIR="$PROJ"
mkdir -p "$PROJ/scripts/lib"
cp "$LIB" "$PROJ/scripts/lib/gate-plan-lib.sh"
git -C "$PROJ" init -q
git -C "$PROJ" config user.email t@t
git -C "$PROJ" config user.name t
# Baseline tracked files so modifications produce numstat LOC.
printf 'base\n' > "$PROJ/README.md"
printf '#!/usr/bin/env bash\necho install\n' > "$PROJ/install.sh"
printf 'model\n' > "$PROJ/DATA_MODEL.md"
printf 'x\n' > "$PROJ/code.sh"
git -C "$PROJ" add -A >/dev/null 2>&1
git -C "$PROJ" commit -qm base
git -C "$PROJ" branch -M main   # name the base branch 'main' for the branch-diff fallback

P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }
clean(){ git -C "$PROJ" checkout -q -- . 2>/dev/null; git -C "$PROJ" clean -qfdx -e scripts 2>/dev/null; }
fire(){ OUT="$(printf '{"tool_input":{"subagent_type":"%s"}}' "$1" | bash "$HOOK" 2>/dev/null)"; RC=$?; }
raw(){ OUT="$(printf '%s' "$1" | bash "$HOOK" 2>/dev/null)"; RC=$?; }
# Parse with jq (harness parses JSON; hook output is jq-pretty-printed with spaces).
verdict(){ printf '%s' "$OUT" | jq -e '.hookSpecificOutput.permissionDecision=="deny"' >/dev/null 2>&1 && echo DENY || echo ALLOW; }
expect(){ # $1 label $2 want
  if [ "$RC" -eq 0 ] && [ "$(verdict)" = "$2" ]; then ok "$1"; else no "$1" "rc=$RC verdict=$(verdict) want=$2"; fi; }

# 1. Non-gated type always allowed, even with a large diff.
clean; printf 'a\n%.0s' $(seq 1 60) > "$PROJ/code.sh"
fire engineer; expect "engineer always ALLOW (never gated)" ALLOW

# 2. security-reviewer: DENY on a non-sensitive diff, ALLOW on a sensitive surface.
clean; printf 'edit\n' >> "$PROJ/README.md"
fire security-reviewer; expect "security-reviewer DENY on docs-only diff" DENY
clean; printf 'edit\n' >> "$PROJ/install.sh"
fire security-reviewer; expect "security-reviewer ALLOW on install.sh (sensitive)" ALLOW

# 3. library-reviewer: ALLOW on .claude/agents change, DENY otherwise.
clean; mkdir -p "$PROJ/.claude/agents"; printf 'x\n' > "$PROJ/.claude/agents/new.md"
fire library-reviewer; expect "library-reviewer ALLOW on .claude/agents/ (untracked)" ALLOW
clean; printf 'edit\n' >> "$PROJ/README.md"
fire library-reviewer; expect "library-reviewer DENY on non-library diff" DENY

# 4. data-model-documenter: ALLOW iff DATA_MODEL.md changed.
clean; printf 'edit\n' >> "$PROJ/DATA_MODEL.md"
fire data-model-documenter; expect "data-model-documenter ALLOW on DATA_MODEL.md" ALLOW
clean; printf 'edit\n' >> "$PROJ/README.md"
fire data-model-documenter; expect "data-model-documenter DENY without a data-model change" DENY

# 5. code-reviewer: DENY on a trivial code change, ALLOW on a non-trivial one.
clean; printf 'one line\n' >> "$PROJ/code.sh"
fire code-reviewer; expect "code-reviewer DENY on trivial (<30 LOC) code change" DENY
clean; printf 'x\n%.0s' $(seq 1 40) >> "$PROJ/code.sh"
fire code-reviewer; expect "code-reviewer ALLOW on non-trivial (>=30 LOC) code change" ALLOW
clean; printf 'x\n%.0s' $(seq 1 40) > "$PROJ/newbig.sh"   # UNTRACKED new file — numstat omits it
fire code-reviewer; expect "code-reviewer ALLOW on a large UNTRACKED new code file" ALLOW

# 6. Fail-open when the classifier lib is unavailable (even on a sensitive diff).
clean; printf 'edit\n' >> "$PROJ/install.sh"
mv "$PROJ/scripts/lib/gate-plan-lib.sh" "$PROJ/scripts/lib/_off"
fire security-reviewer; expect "fail-open: missing gate-plan-lib -> ALLOW on sensitive diff" ALLOW
mv "$PROJ/scripts/lib/_off" "$PROJ/scripts/lib/gate-plan-lib.sh"

# 7. Fail-open: missing subagent_type, and malformed input.
clean; raw '{"tool_input":{}}'; expect "fail-open: no subagent_type -> ALLOW" ALLOW
clean; raw 'not json'; expect "fail-open: malformed input -> ALLOW" ALLOW

# 8. Branch-diff fallback: clean working tree but a COMMITTED change vs base → warranted.
clean
git -C "$PROJ" checkout -qb work >/dev/null 2>&1   # work on a branch; 'main' stays at base
mkdir -p "$PROJ/.claude/agents"; printf 'committed\n' > "$PROJ/.claude/agents/committed.md"
git -C "$PROJ" add -A >/dev/null 2>&1; git -C "$PROJ" commit -qm "committed library change" >/dev/null 2>&1
fire library-reviewer; expect "branch-fallback: committed .claude/agents change on a clean tree -> ALLOW" ALLOW

echo ""
echo "gate-subagents-test: $P passed, $F failed."
[ "$F" -eq 0 ]
