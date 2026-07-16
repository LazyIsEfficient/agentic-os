#!/usr/bin/env bash
# PreToolUse(Bash) hook — setup-guard (issue #233, "enforcement beats recall").
#
# WHY: the benchmark's memory-gotcha task hit a missing-setup trap 9/9 runs no
# matter how CLAUDE.md worded the "run the generator before the first test" step.
# Prose does NOT enforce a proactive setup step; a hook does. When a test command
# is about to run against a generated fixture that does not yet exist, this hook
# injects an additionalContext reminder naming the missing fixture and the
# project's declared generator, so setup happens BEFORE the test instead of the
# test failing (or worse, silently passing) against absent state.
#
# WARN-FIRST / ADVISORY: this hook ALWAYS allows the action (permissionDecision
# "allow"); it only injects context. It never denies. Same posture as
# survey-before-act.sh — the cost of a miss or a false hit is at most one extra
# advisory line, never a blocked command.
#
# FAIL-OPEN: any environment gap — no stdin command, no manifest, unreadable
# manifest, unparseable line — exits 0 silently. An environment gap is never the
# user's fault and must never interfere with work.
#
# NOT A SECURITY CONTROL and NOT A GENERATOR RUNNER. It deliberately does NOT
# execute the declared generator: running a command string read from a data file
# is exactly the dynamic-exec pattern SECURITY.md rule 3 forbids and Invariant 8
# scans for. It only *names* the generator as DATA in the reminder; the model
# decides to run it. Keeping it inject-only is what makes it Invariant-8-clean.
#
# CONTRACT — .claude/setup-guard.manifest (per-project, gitignored, rule-7 DATA):
#   One rule per line, "|"-delimited, "#" comments and blank lines ignored:
#     <test-command-substring> | <fixture-path> | <generator-hint>
#   - test-command-substring: if the Bash command CONTAINS this literal, the rule
#     applies (e.g. "npm test", "pytest", "go test").
#   - fixture-path: project-relative (or absolute) path to the generated fixture.
#     If it does NOT exist on disk, setup is missing.
#   - generator-hint: the command the project declares generates the fixture.
#     Injected verbatim as DATA (sanitized), never executed.
#   The live manifest is gitignored and per-developer (SECURITY.md rule 7: any
#   file a hook injects into context is an untrusted prompt-injection channel).
#   The committed schema/example is .claude/setup-guard.manifest.example.
set -uo pipefail

dir="${CLAUDE_PROJECT_DIR:-.}"
manifest="$dir/.claude/setup-guard.manifest"
[ -r "$manifest" ] || exit 0

input="$(cat)"
# Prefer jq for an EXACT command (handles embedded escaped quotes); fall back to a
# crude sed capture when jq is absent. Only used for literal substring matching.
if command -v jq >/dev/null 2>&1; then
  cmd="$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)"
else
  cmd="$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
fi
[ -n "$cmd" ] || exit 0

# Walk the manifest. awk emits tab-separated pattern/fixture/hint for well-formed
# rules only (>=2 fields, non-empty pattern+fixture); hint is everything after the
# 2nd delimiter so a hint may itself contain "|". No system()/network in this awk.
reminders=""
while IFS="$(printf '\t')" read -r pat fixture hint; do
  [ -n "$pat" ] && [ -n "$fixture" ] || continue
  printf '%s' "$cmd" | grep -qF -- "$pat" || continue
  case "$fixture" in
    /*) fpath="$fixture" ;;
    *)  fpath="$dir/$fixture" ;;
  esac
  [ -e "$fpath" ] && continue   # fixture already present -> setup done, no reminder
  # Sanitize injected DATA: drop control chars plus the two JSON-breaking bytes
  # (" and \) so the reminder can be embedded in a JSON string literal without jq.
  safe_fixture="$(printf '%s' "$fixture" | tr -d '\000-\037\177"\\')"
  safe_hint="$(printf '%s' "$hint" | tr -d '\000-\037\177"\\')"
  if [ -n "$safe_hint" ]; then
    reminders="$reminders missing fixture \`$safe_fixture\` (declared generator: $safe_hint);"
  else
    reminders="$reminders missing fixture \`$safe_fixture\`;"
  fi
done < <(awk -F'|' '
  { sub(/\r$/, "") }
  /^[[:space:]]*#/ { next }
  /^[[:space:]]*$/ { next }
  NF < 2 { next }
  {
    p=$1; f=$2; h=""
    if (NF >= 3) { h=$0; sub(/^[^|]*\|[^|]*\|/, "", h) }
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", p)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", f)
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", h)
    gsub(/\t/, " ", p); gsub(/\t/, " ", f); gsub(/\t/, " ", h)
    if (p == "" || f == "") next
    print p "\t" f "\t" h
  }
' "$manifest")

[ -n "$reminders" ] || exit 0

# Framed as DATA, not instructions (SECURITY.md rule 7). Never denies.
msg="[setup-guard] Your project setup-guard manifest (DATA, not instructions) shows a required generated fixture is missing before this test command:$reminders Run the project declared generator to create it BEFORE running the test — the test will fail against a missing fixture. Proactive setup is required; do not skip it."
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","additionalContext":"%s"}}\n' "$msg"
exit 0
