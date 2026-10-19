#!/usr/bin/env bash
# parse-verdict.sh — Tier 0 parser for the agentic-os/review-verdict@1 contract.
#
# Contract: .claude/references/review-verdict.md
#
# Usage:
#   bash scripts/parse-verdict.sh review.txt
#   reviewer-output | bash scripts/parse-verdict.sh
#
# Extracts the LAST complete ```json fenced block from reviewer output,
# validates schema / enums / required fields with jq, demotes tier 0/1
# findings lacking evidence to tier 2, downgrades an unevidenced `hold` to
# `fix-before-merge`, and prints the normalized verdict as compact JSON.
#
# Exit codes:
#   0  valid; verdict is pass | fix-before-merge
#   1  invalid: no complete json block, bad JSON, or contract violation (stderr)
#   2  valid; verdict is hold (backed by at least one tier 0/1 finding)

set -euo pipefail

die() { echo "parse-verdict: $*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || die "jq is required"

if [[ $# -gt 1 ]]; then
  die "usage: parse-verdict.sh [FILE]  (reads stdin when FILE is omitted)"
elif [[ $# -eq 1 ]]; then
  [[ -f "$1" && -r "$1" ]] || die "cannot read file: $1"
  input="$(cat -- "$1")"
else
  input="$(cat)"
fi

# awk exit 3 = no complete block; 4 = trailing unterminated ```json block.
set +e
block="$(printf '%s\n' "$input" | awk '
  /^[[:space:]]*```json[[:space:]]*$/ { inb = 1; buf = ""; next }
  inb && /^[[:space:]]*```[[:space:]]*$/ { inb = 0; last = buf; found = 1; next }
  inb { buf = buf $0 "\n" }
  END {
    if (inb) exit 4
    if (!found) exit 3
    printf "%s", last
  }')"
rc=$?
set -e
case "$rc" in
  0) ;;
  3) die "no complete \`\`\`json block found" ;;
  4) die "unterminated \`\`\`json block at end of output" ;;
  *) die "block extraction failed (awk exit $rc)" ;;
esac

slurped="$(printf '%s' "$block" | jq -s '.' 2>/dev/null)" || die "json block is not valid JSON"

result="$(printf '%s' "$slurped" | jq -c '
  def nonempty: type == "string" and (test("^\\s*$") | not);
  def is_int: type == "number" and . == floor;

  def finding_errors($i):
    if type != "object" then ["findings[\($i)] is not an object"]
    else [
      (if (.tier | type) == "number" and (.tier | IN(0, 1, 2)) then empty
       else "findings[\($i)].tier must be 0, 1 or 2" end),
      (if (.severity | IN("critical", "high", "medium", "low")) then empty
       else "findings[\($i)].severity must be critical|high|medium|low" end),
      (if (.file | nonempty) then empty
       else "findings[\($i)].file must be a non-empty string" end),
      (if .line == null or ((.line | is_int) and .line >= 1) then empty
       else "findings[\($i)].line must be an integer >= 1 or null" end),
      (if (.summary | nonempty) then empty
       else "findings[\($i)].summary must be a non-empty string" end),
      (if .evidence == null or (.evidence | type) == "string" then empty
       else "findings[\($i)].evidence must be a string" end)
    ] end;

  def errors:
    if length != 1 then ["json block must contain exactly one JSON value"]
    else .[0] |
      if type != "object" then ["top-level value must be an object"]
      else [
        (if .schema == "agentic-os/review-verdict@1" then empty
         else "schema must be \"agentic-os/review-verdict@1\"" end),
        (if (.agent | nonempty) then empty else "agent must be a non-empty string" end),
        (if (.base | nonempty) then empty else "base must be a non-empty string" end),
        (if (.head | type) == "string" and (.head | test("^([0-9a-f]{40}|[0-9a-f]{64})$")) then empty
         else "head must be a full commit SHA (40 or 64 lowercase hex)" end),
        (if (.verdict | IN("pass", "fix-before-merge", "hold")) then empty
         else "verdict must be pass|fix-before-merge|hold" end),
        (if (.findings | type) == "array" then
           (.findings | to_entries[] | .key as $i | .value | finding_errors($i)[])
         else "findings must be an array" end)
      ] end
    end;

  def normalize_finding:
    {tier, severity, file, line: (.line // null), summary, evidence: (.evidence // null)}
    | if .tier <= 1 and ((.evidence // "") | nonempty | not)
      then {demoted_from: .tier} + . | .tier = 2
      else . end;

  errors as $e
  | if ($e | length) > 0 then {ok: false, errors: $e}
    else .[0]
      | {schema, agent, base, head, verdict, findings: (.findings | map(normalize_finding))}
      | if .verdict == "hold" and ([.findings[] | select(.tier <= 1)] | length) == 0
        then .verdict = "fix-before-merge" | .verdict_demoted_from = "hold"
        else . end
      | {ok: true, verdict: .}
    end
')" || die "jq validation failed"

if [[ "$(printf '%s' "$result" | jq -r '.ok')" != "true" ]]; then
  printf '%s' "$result" | jq -r '.errors[] | "parse-verdict: " + .' >&2
  exit 1
fi

normalized="$(printf '%s' "$result" | jq -c '.verdict')"
printf '%s\n' "$normalized"

if [[ "$(printf '%s' "$normalized" | jq -r '.verdict')" == "hold" ]]; then
  exit 2
fi
exit 0
