#!/usr/bin/env bash
# setup-guard-test.sh — deterministic test of the setup-guard PreToolUse(Bash)
# hook (.claude/hooks/setup-guard.sh, issue #233). Proves: it injects a proactive
# additionalContext reminder when a manifest-declared test command is about to run
# against a MISSING generated fixture; stays silent once the fixture exists, on
# non-test commands, and when no manifest is present (fail-open); NEVER denies; is
# deterministic; and emits valid JSON even when the manifest carries JSON-breaking
# bytes (SECURITY.md rule-7 sanitization). Runs in a temp dir via
# CLAUDE_PROJECT_DIR; no live Claude needed.
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
mkdir -p "$T/.claude/hooks"
cp "$REPO/.claude/hooks/setup-guard.sh" "$T/.claude/hooks/"

# Manifest: 3 relative rules + 1 absolute-path rule + 1 injection rule (hint with
# a literal double-quote and backslash to exercise the JSON sanitizer).
{
  printf '# setup-guard test manifest\n'
  printf 'npm test | fixtures/gen.json | npm run gen:fixtures\n'
  printf 'pytest | build/schema.json | make schema\n'
  printf 'abs-run | %s/abs/missing.bin | make abs\n' "$T"
  printf 'inj-cmd | fixtures/inj.json | gen "quoted" back\\slash\n'
} > "$T/.claude/setup-guard.manifest"

export CLAUDE_PROJECT_DIR="$T"
HOOK="$T/.claude/hooks/setup-guard.sh"
P=0; F=0
ok(){ printf 'PASS  %s\n' "$1"; P=$((P+1)); }
no(){ printf 'FAIL  %s — %s\n' "$1" "$2"; F=$((F+1)); }
# run <command>: feed a PreToolUse(Bash) event carrying <command>, print hook stdout.
run(){ printf '%s' "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"$1\"}}" | bash "$HOOK"; }

# 1 — warns when a declared test command's fixture is missing, names it + generator.
out="$(run 'npm test')"
printf '%s' "$out" | grep -q 'additionalContext' \
  && printf '%s' "$out" | grep -q 'fixtures/gen.json' \
  && printf '%s' "$out" | grep -q 'npm run gen:fixtures' \
  && ok "warns on missing fixture (names fixture + generator)" \
  || no "warn missing fixture" "got: $out"

# 2 — silent once the fixture exists (setup already done).
mkdir -p "$T/fixtures"; printf '{}' > "$T/fixtures/gen.json"
out="$(run 'npm test')"
[ -z "$out" ] && ok "silent once fixture exists" || no "silent when present" "got: $out"

# 3 — silent on a command that matches no manifest pattern.
for c in "git status" "ls -la" "echo build the tests" "cargo build"; do
  out="$(run "$c")"
  [ -z "$out" ] && ok "no false-positive: $c" || no "false-positive: $c" "got: $out"
done

# 4 — a DIFFERENT rule (pytest) still warns, names its own generator.
out="$(run 'pytest -q')"
printf '%s' "$out" | grep -q 'build/schema.json' \
  && printf '%s' "$out" | grep -q 'make schema' \
  && ok "warns on second rule (pytest) with its own generator" \
  || no "pytest rule" "got: $out"

# 5 — absolute fixture path is honored (missing -> warns).
out="$(run 'abs-run --now')"
printf '%s' "$out" | grep -qF -- "$T/abs/missing.bin" \
  && ok "absolute fixture path honored" || no "absolute path" "got: $out"

# 6 — never DENIES (advisory/warn-first).
deny="$(for c in 'npm test' 'pytest' 'abs-run'; do run "$c"; done)"
printf '%s' "$deny" | grep -q '"deny"' && no "never denies (warn-first)" "found deny" || ok "never denies (warn-first)"

# 7 — deterministic: identical input yields identical output.
a="$(run 'pytest')"; b="$(run 'pytest')"
[ "$a" = "$b" ] && ok "deterministic (same input -> same output)" || no "determinism" "a=$a b=$b"

# 8 — fail-open: no manifest -> silent.
nomani="$(mktemp -d)"; mkdir -p "$nomani/.claude/hooks"
cp "$REPO/.claude/hooks/setup-guard.sh" "$nomani/.claude/hooks/"
out="$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"npm test"}}' | CLAUDE_PROJECT_DIR="$nomani" bash "$nomani/.claude/hooks/setup-guard.sh")"
[ -z "$out" ] && ok "fail-open: no manifest -> silent" || no "no-manifest fail-open" "got: $out"
rm -rf "$nomani"

# 9 — fail-open: empty command -> silent.
out="$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":""}}' | bash "$HOOK")"
[ -z "$out" ] && ok "fail-open: empty command -> silent" || no "empty command" "got: $out"

# 10 — fail-open: unparseable stdin -> silent (no crash, no output).
out="$(printf '%s' 'not json at all' | bash "$HOOK")"
[ -z "$out" ] && ok "fail-open: unparseable stdin -> silent" || no "unparseable stdin" "got: $out"

# 11 — JSON validity, incl. rule-7 sanitization of a hint with " and \ .
if command -v jq >/dev/null 2>&1; then
  out="$(run 'inj-cmd')"
  printf '%s' "$out" | jq -e . >/dev/null 2>&1 \
    && ok "emits valid JSON despite quote/backslash in manifest hint" \
    || no "JSON validity (sanitizer)" "got: $out"
  # Use a still-missing fixture (pytest's), since npm test's was created in case 2.
  dec="$(run 'pytest' | jq -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)"
  [ "$dec" = "allow" ] && ok "permissionDecision is allow (advisory)" || no "permissionDecision" "got: $dec"
else
  echo "setup-guard-test: jq not found — skipping JSON-validity assertions" >&2
fi

echo "setup-guard-test: $P passed, $F failed."
[ "$F" -eq 0 ]
