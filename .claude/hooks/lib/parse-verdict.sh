#!/usr/bin/env bash
# parse-verdict.sh — Tier 0 parser for the agentic-os/review-verdict@1 contract.
#
# Contract: .claude/references/review-verdict.md
#
# Canonical location: .claude/hooks/lib/ — it ships with the hooks so the
# SubagentStop capture hook (review-verdict-capture.sh) can run it on consumer
# installs. scripts/parse-verdict.sh is a thin wrapper that execs this file.
#
# Usage:
#   bash scripts/parse-verdict.sh [--expect-head <sha>] [FILE]
#   bash scripts/parse-verdict.sh [--expect-head <sha>] < reviewer-output.txt
#
# Requires exactly one ```json fenced block, at the very end of the output
# (only whitespace may follow its closing fence). Validates schema / enums /
# required fields / agent name with jq, rejects duplicate JSON keys (jq --stream),
# demotes tier 0/1 findings lacking evidence to tier 2, downgrades an
# unevidenced `hold` to `fix-before-merge`, and prints the normalized verdict
# as compact JSON on stdout.
#
# Exit codes:
#   0  valid; verdict is pass
#   1  invalid: block count/position, bad JSON, duplicate keys, contract
#      violation, or --expect-head mismatch (reasons on stderr)
#   2  valid; verdict is hold (backed by at least one tier 0/1 finding)
#   3  valid; verdict is fix-before-merge

set -euo pipefail

die() { echo "parse-verdict: $*" >&2; exit 1; }
usage() { die "usage: parse-verdict.sh [--expect-head <sha>] [FILE]  (reads stdin when FILE is omitted)"; }

command -v jq >/dev/null 2>&1 || die "jq is required"

expect_head=""
file=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --expect-head)
      [[ $# -ge 2 && -n "$2" ]] || usage
      expect_head="$2"; shift 2 ;;
    -*) usage ;;
    *)
      [[ -z "$file" ]] || usage
      file="$1"; shift ;;
  esac
done

if [[ -n "$file" ]]; then
  [[ -f "$file" && -r "$file" ]] || die "cannot read file: $file"
  input="$(cat -- "$file")"
else
  input="$(cat)"
fi

# awk exits: 3 no block; 4 unterminated block; 5 more than one block;
# 6 non-whitespace after the closing fence.
set +e
block="$(printf '%s\n' "$input" | awk '
  /^[[:space:]]*```json[[:space:]]*$/ { n++; inb = 1; buf = ""; trail = 0; next }
  inb && /^[[:space:]]*```[[:space:]]*$/ { inb = 0; last = buf; next }
  inb { buf = buf $0 "\n"; next }
  n > 0 && /[^[:space:]]/ { trail = 1 }
  END {
    if (n == 0) exit 3
    if (inb) exit 4
    if (n > 1) exit 5
    if (trail) exit 6
    printf "%s", last
  }')"
rc=$?
set -e
case "$rc" in
  0) ;;
  3) die "no \`\`\`json block found" ;;
  4) die "unterminated \`\`\`json block" ;;
  5) die "more than one \`\`\`json block — the verdict block must be the only one" ;;
  6) die "content after the verdict block's closing fence — it must end the output" ;;
  *) die "block extraction failed (awk exit $rc)" ;;
esac

slurped="$(printf '%s' "$block" | jq -s '.' 2>/dev/null)" || die "json block is not valid JSON"

# Duplicate-key check in jq (no python: this file ships under .claude/hooks/,
# where Invariant 8 bans inline interpreters). --stream sees raw tokens before
# jq's last-key-wins collapse. A value at path P is "closed" once complete; any
# later event under P means its key was repeated. Single-value input only — the
# multi-value case is rejected below with its own message.
if [[ "$(printf '%s' "$slurped" | jq 'length')" == 1 ]]; then
  dup="$(printf '%s' "$block" | jq -n -r --stream '
    reduce inputs as $e ({closed: {}, dup: null};
      if .dup != null then .
      elif ($e | length) == 2 then
        ($e[0]) as $p
        | . as $s
        | ([range(1; ($p | length) + 1) as $i | $p[:$i] | tojson]
           | map(select($s.closed[.] == true))) as $hit
        | if ($hit | length) > 0 then .dup = ($hit[0] | fromjson | map(tostring) | join("."))
          else .closed[$p | tojson] = true end
      else .closed[($e[0][:-1]) | tojson] = true
      end)
    | .dup // empty')" || die "duplicate-key scan failed"
  [[ -z "$dup" ]] || die "duplicate JSON key: $dup"
fi

result="$(printf '%s' "$slurped" | jq -c --arg expect_head "$expect_head" '
  def nonempty: type == "string" and (test("^\\s*$") | not);
  def is_int: type == "number" and . == floor;
  def agents: ["code-reviewer", "security-reviewer", "library-reviewer", "data-model-verifier"];

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
        (if (.agent | IN(agents[])) then empty
         else "agent must be one of: \(agents | join(", "))" end),
        (if (.base | nonempty) then empty else "base must be a non-empty string" end),
        (if (.head | type) == "string" and (.head | test("^([0-9a-f]{40}|[0-9a-f]{64})$")) then empty
         else "head must be a full commit SHA (40 or 64 lowercase hex)" end),
        (if $expect_head == "" or .head == $expect_head then empty
         else "head \(.head | tostring) does not match --expect-head \($expect_head)" end),
        (if (.verdict | IN("pass", "fix-before-merge", "hold")) then empty
         else "verdict must be pass|fix-before-merge|hold" end),
        (if .agent == "data-model-verifier" and .verdict == "fix-before-merge"
         then "data-model-verifier may only emit pass|hold" else empty end),
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

  # Checks that need demotion applied first.
  def post_errors:
    ([.findings[] | select(.tier <= 1)] | length) as $evidenced
    | [
        (if .verdict == "pass" and $evidenced > 0
         then "verdict pass contradicts \($evidenced) evidenced tier 0/1 finding(s)" else empty end),
        (if .agent == "data-model-verifier" and .verdict == "hold" and $evidenced == 0
         then "data-model-verifier hold needs an evidenced tier 0/1 finding" else empty end)
      ];

  errors as $e
  | if ($e | length) > 0 then {ok: false, errors: $e}
    else .[0]
      | {schema, agent, base, head, verdict, findings: (.findings | map(normalize_finding))}
      | post_errors as $pe
      | if ($pe | length) > 0 then {ok: false, errors: $pe}
        else
          (if .verdict == "hold" and ([.findings[] | select(.tier <= 1)] | length) == 0
           then .verdict = "fix-before-merge" | .verdict_demoted_from = "hold"
           else . end)
          | {ok: true, verdict: .}
        end
    end
')" || die "jq validation failed"

if [[ "$(printf '%s' "$result" | jq -r '.ok')" != "true" ]]; then
  printf '%s' "$result" | jq -r '.errors[] | "parse-verdict: " + .' >&2
  exit 1
fi

normalized="$(printf '%s' "$result" | jq -c '.verdict')"
printf '%s\n' "$normalized"

case "$(printf '%s' "$normalized" | jq -r '.verdict')" in
  pass) exit 0 ;;
  hold) exit 2 ;;
  fix-before-merge) exit 3 ;;
esac
die "unreachable: unknown normalized verdict"
