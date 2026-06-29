#!/usr/bin/env bash
# session-metrics-cursor-test.sh — Tier 0 deterministic test of Cursor transcript
# parsing in session-metrics-cursor.mjs. Mirrors session-metrics-test.sh.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

out="$(node "$DIR/session-metrics-cursor.mjs" "$DIR/fixtures/sample-cursor-transcript.jsonl" --json)"
out2="$(node "$DIR/session-metrics-cursor.mjs" "$DIR/fixtures/sample-cursor-transcript.jsonl" --json)"
[ "$out" = "$out2" ] && echo "PASS  deterministic (run twice, identical)" || { echo "FAIL  non-deterministic"; exit 1; }

printf '%s' "$out" | node -e '
const r = JSON.parse(require("fs").readFileSync(0, "utf8"));
let fail = 0;
const eq = (n, a, b) => { if (a === b) console.log("PASS  " + n); else { console.log(`FAIL  ${n}: expected ${b}, got ${a}`); fail = 1; } };
eq("platform is cursor", r.platform, "cursor");
eq("turns (one per role:assistant record)", r.turns, 3);
eq("output tokens absent in Cursor transcripts", r.tokens.output, 0);
eq("input tokens absent in Cursor transcripts", r.tokens.input, 0);
eq("output tokens/turn with zero usage", r.output_tokens_per_turn, 0);
eq("files read >1x (/a.txt in turn 1 + 2)", r.awareness_signals.repeat_read_files, 1);
eq("repeated tool calls (Read /a.txt + Shell echo x)", r.awareness_signals.repeated_tool_calls, 2);
eq("turn_ended + user lines skipped without error", r.skipped_lines, 0);
process.exit(fail);
' || exit 1

collapse="$(node "$DIR/session-metrics-cursor.mjs" "$DIR/fixtures/orchestrator-collapse-cursor-transcript.jsonl" --json)"
printf '%s' "$collapse" | node -e '
const r = JSON.parse(require("fs").readFileSync(0, "utf8"));
let fail = 0;
const eq = (n, a, b) => { if (a === b) console.log("PASS  " + n); else { console.log(`FAIL  ${n}: expected ${b}, got ${a}`); fail = 1; } };
const o = r.orchestration_signals;
eq("collapse transcript: task_dispatches", o.task_dispatches, 0);
eq("collapse transcript: main_thread_edit_tools", o.main_thread_edit_tools, 3);
eq("collapse transcript: orchestrator_collapse", o.orchestrator_collapse, true);
process.exit(fail);
' || exit 1

healthy="$(node "$DIR/session-metrics-cursor.mjs" "$DIR/fixtures/orchestrator-healthy-cursor-transcript.jsonl" --json)"
printf '%s' "$healthy" | node -e '
const r = JSON.parse(require("fs").readFileSync(0, "utf8"));
let fail = 0;
const eq = (n, a, b) => { if (a === b) console.log("PASS  " + n); else { console.log(`FAIL  ${n}: expected ${b}, got ${a}`); fail = 1; } };
const o = r.orchestration_signals;
eq("healthy transcript: task_dispatches", o.task_dispatches, 1);
eq("healthy transcript: main_thread_edit_tools", o.main_thread_edit_tools, 0);
eq("healthy transcript: orchestrator_collapse", o.orchestrator_collapse, false);
process.exit(fail);
' || exit 1

nested="$(node "$DIR/session-metrics-cursor.mjs" "$DIR/fixtures/nested-input-cursor-transcript.jsonl" --json)"
printf '%s' "$nested" | node -e '
const r = JSON.parse(require("fs").readFileSync(0, "utf8"));
let fail = 0;
const eq = (n, a, b) => { if (a === b) console.log("PASS  " + n); else { console.log(`FAIL  ${n}: expected ${b}, got ${a}`); fail = 1; } };
eq("distinct nested Edits not counted as repeat; key-order-equal pair is (=> 1)", r.awareness_signals.repeated_tool_calls, 1);
process.exit(fail);
' || exit 1

echo "session-metrics-cursor-test: OK"
