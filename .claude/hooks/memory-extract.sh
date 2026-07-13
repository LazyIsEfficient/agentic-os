#!/usr/bin/env bash
# Stop hook — reliable memory encoding (issue #217). Claude Code fires Stop at the
# end of EVERY assistant turn. This hook deterministically drives the LLM-side
# `memory-extraction` skill: it steers the still-live main agent (which holds the
# transcript in context) to persist durable facts before the session closes.
#
# Contract with .claude/skills/memory-extraction/SKILL.md: the nudge passes the
# session_id and the exact completion-marker path .claude/memory/.extract/<id>;
# the skill writes that marker when done, which self-gates this hook next turn.
#
# NON-NEGOTIABLE: fail-open on every path. An extraction hook must NEVER block a
# user's session — any error (no jq, malformed/empty stdin, unwritable fs) emits
# ALLOW ({}) and exits 0. Loop-safety is the ledger marker plus a hard nudge cap;
# `stop_hook_active` from the input is unreliable so we never depend on it.
set -uo pipefail

allow() { printf '%s\n' '{}'; exit 0; }

dir="${CLAUDE_PROJECT_DIR:-.}"
event="$(cat 2>/dev/null || true)"

# Fail-open: no jq (needed to parse input and safely build the steer JSON).
command -v jq >/dev/null 2>&1 || allow
# Fail-open: empty or malformed stdin is not valid JSON.
printf '%s' "$event" | jq -e . >/dev/null 2>&1 || allow

# Extract session_id; fall back to a stable default so the mechanism still
# self-limits when no id is present (matches SKILL.md's `.extract/last`).
sid="$(printf '%s' "$event" | jq -r '.session_id // empty' 2>/dev/null || true)"
[ -n "$sid" ] || sid="last"
# Sanitize to a safe filename charset and neutralize path traversal (`..`).
sid="$(printf '%s' "$sid" | tr -c 'A-Za-z0-9_.-' '_' | tr -s '.' '.')"
case "$sid" in ''|.|..) sid="last" ;; esac

extract_dir="$dir/.claude/memory/.extract"
marker="$extract_dir/$sid"

# Self-gate: extraction already ran this session -> allow, stop nudging.
[ -e "$marker" ] && allow

# Hard loop cap (fail-safe if the skill never writes the marker): after N nudges
# for this session, allow completion regardless. Guarantees termination.
mkdir -p "$extract_dir" 2>/dev/null || allow
nudges_file="$extract_dir/$sid.nudges"
count=0
[ -r "$nudges_file" ] && count="$(tr -dc '0-9' < "$nudges_file" 2>/dev/null || true)"
[ -n "$count" ] || count=0
[ "$count" -ge 2 ] && allow
printf '%s\n' "$((count + 1))" > "$nudges_file" 2>/dev/null || true

# Nudge: block the stop and re-enter the agent with an instruction to run the
# skill now. Include session_id + the exact marker path so the skill writes the
# completion marker where this hook looks for it next turn.
reason="Before ending this session, run the memory-extraction skill now as your FINAL action. Read this session's transcript (already in your context) plus existing .claude/memory/, apply the durable-fact predicate in .claude/skills/memory-extraction/SKILL.md, and persist qualifying facts (append-or-update, never clobber). This session_id is \"$sid\". When done, refresh the completion marker at .claude/memory/.extract/$sid with an ISO-8601 UTC timestamp and the facts count (e.g. 2026-07-13T00:00:00Z facts=2) so this hook stops nudging. If nothing qualifies, still write the marker."

jq -n --arg r "$reason" '{decision:"block", reason:$r}'
exit 0
