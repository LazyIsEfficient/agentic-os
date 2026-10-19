#!/usr/bin/env bash
# SubagentStop hook — captures a gate reviewer's agentic-os/review-verdict@1
# block as a deterministic artifact (issue #258). Reviewers are read-only (no
# Write tool); this hook, not the LLM, writes the file.
#
# For agent_type in {code-reviewer, security-reviewer, library-reviewer,
# data-model-verifier} (exact match; anything else is ignored):
#   1. Take the final message from `last_assistant_message` (documented on
#      SubagentStop). If absent, fall back to the last assistant text entry of
#      `agent_transcript_path` (the subagent's own JSONL), only when it resolves
#      under ${CLAUDE_CONFIG_DIR:-~/.claude}/projects/ and reading at most the
#      last MAX_BYTES.
#   2. Run lib/parse-verdict.sh --expect-head "$(git rev-parse HEAD)".
#   3. Exit 0/2/3 (pass / hold / fix-before-merge) and a verdict whose `agent`
#      equals agent_type: write the normalized JSON atomically (mktemp + mv) to
#      <git-root>/.claude/reviews/<HEAD>-<agent_type>.json. Exit 1 (invalid,
#      stale head) writes nothing. The filename uses only the allowlisted
#      agent_type and a hex SHA from git, so it cannot leave .claude/reviews/.
#
# .claude/reviews/ gets a `*` .gitignore on creation so artifacts never show up
# as changes in any repo (review-gate-stop.sh also excludes the dir).
#
# FAILS OPEN on every path: this hook never blocks a subagent. Errors print a
# one-line stderr note and exit 0 with no stdout.

set -uo pipefail

MAX_BYTES=1048576

note() { echo "review-verdict-capture: $*" >&2; exit 0; }

command -v jq >/dev/null 2>&1 || note "jq not found; verdict not captured"
command -v git >/dev/null 2>&1 || note "git not found; verdict not captured"

hook_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || note "cannot resolve hook dir"
parser="$hook_dir/lib/parse-verdict.sh"
[[ -f "$parser" ]] || note "lib/parse-verdict.sh not found next to the hook; verdict not captured"

input="$(head -c $((MAX_BYTES * 4)))"
agent="$(printf '%s' "$input" | jq -r '.agent_type // empty | strings' 2>/dev/null)" || note "unparseable payload"

case "$agent" in
  code-reviewer|security-reviewer|library-reviewer|data-model-verifier) ;;
  *) exit 0 ;;
esac

dir="${CLAUDE_PROJECT_DIR:-}"
[[ -n "$dir" ]] || dir="$(printf '%s' "$input" | jq -r '.cwd // empty | strings')"
[[ -n "$dir" ]] || dir="$PWD"
root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || note "not a git repository; verdict not captured"
head="$(git -C "$root" rev-parse --verify -q HEAD 2>/dev/null)" || note "no HEAD commit; verdict not captured"
[[ "$head" =~ ^([0-9a-f]{40}|[0-9a-f]{64})$ ]] || note "unexpected HEAD format"

msg="$(printf '%s' "$input" | jq -r '.last_assistant_message // empty | strings')"

if [[ -z "$msg" ]]; then
  tpath="$(printf '%s' "$input" | jq -r '.agent_transcript_path // empty | strings')"
  [[ -n "$tpath" ]] || note "no last_assistant_message or agent_transcript_path"
  tpath="${tpath/#\~/$HOME}"
  [[ "$tpath" == *.jsonl && -f "$tpath" && ! -L "$tpath" ]] || note "agent transcript is not a regular .jsonl file"
  allowed="$(cd "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects" 2>/dev/null && pwd -P)" || note "no projects dir for transcript containment"
  tdir="$(cd "$(dirname "$tpath")" 2>/dev/null && pwd -P)" || note "cannot resolve transcript dir"
  [[ "$tdir/" == "$allowed/"* ]] || note "agent transcript outside $allowed; ignored"
  msg="$(tail -c "$MAX_BYTES" "$tpath" | jq -R -r -n '
    [inputs | fromjson? | select(type == "object" and .type == "assistant")
     | .message.content
     | if type == "string" then . elif type == "array"
       then (map(select(type == "object" and .type == "text") | .text) | join("\n"))
       else "" end
     | select(length > 0)]
    | last // empty' 2>/dev/null)"
fi

[[ -n "$msg" ]] || note "$agent: empty final message; verdict not captured"
(( ${#msg} <= MAX_BYTES )) || note "$agent: final message over $MAX_BYTES bytes; verdict not captured"

out="$(bash "$parser" --expect-head "$head" 2>/dev/null <<< "$msg")"
rc=$?
case "$rc" in
  0|2|3) ;;
  *) note "$agent: no valid review-verdict@1 block for HEAD $head (parse-verdict exit $rc); not captured" ;;
esac

[[ "$(printf '%s' "$out" | jq -r '.agent')" == "$agent" ]] \
  || note "$agent: verdict block names a different agent; not captured"

reviews="$root/.claude/reviews"
[[ ! -L "$reviews" ]] || note ".claude/reviews is a symlink; refusing to write"
mkdir -p "$reviews" 2>/dev/null || note "cannot create $reviews"
[[ -e "$reviews/.gitignore" ]] || printf '*\n' > "$reviews/.gitignore" 2>/dev/null || true

tmp="$(mktemp "$reviews/.tmp.XXXXXX" 2>/dev/null)" || note "cannot create temp file in $reviews"
if printf '%s\n' "$out" > "$tmp" && mv -f "$tmp" "$reviews/$head-$agent.json"; then
  exit 0
fi
rm -f "$tmp"
note "failed to write $reviews/$head-$agent.json"
