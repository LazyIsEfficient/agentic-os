#!/usr/bin/env bash
# session-metrics-test.sh — deterministic test of session-metrics.mjs against a
# fixed fixture transcript. Same input must yield the same numbers (Tier 0).
#
# The fixture deliberately includes message id "m2" emitted as TWO assistant
# records with the SAME usage block (the real Claude Code shape: one turn split
# across thinking/text/tool_use records). A parser that does not dedupe by
# message.id reports turns=4 / output=230; the correct parser reports 3 / 150.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

out="$(node "$DIR/session-metrics.mjs" "$DIR/fixtures/sample-transcript.jsonl" --json)"
out2="$(node "$DIR/session-metrics.mjs" "$DIR/fixtures/sample-transcript.jsonl" --json)"
[ "$out" = "$out2" ] && echo "PASS  deterministic (run twice, identical)" || { echo "FAIL  non-deterministic"; exit 1; }

printf '%s' "$out" | node -e '
const r = JSON.parse(require("fs").readFileSync(0, "utf8"));
let fail = 0;
const eq = (n, a, b) => { if (a === b) console.log("PASS  " + n); else { console.log(`FAIL  ${n}: expected ${b}, got ${a}`); fail = 1; } };
eq("turns deduped by message.id (4 records, m2 twice -> 3)", r.turns, 3);
eq("output tokens deduped (50 + 80 once + 20)", r.tokens.output, 150);
eq("input tokens deduped (100 + 200 once + 50)", r.tokens.input, 350);
eq("cache_read deduped (10 + 20 once + 5)", r.tokens.cache_read, 35);
eq("cache_creation (5 + 0 + 0)", r.tokens.cache_creation, 5);
eq("output tokens/turn (150/3)", r.output_tokens_per_turn, 50);
eq("files read >1x (/a.txt in m1 + m2)", r.awareness_signals.repeat_read_files, 1);
eq("repeated tool calls (Read /a.txt + Bash echo x)", r.awareness_signals.repeated_tool_calls, 2);
eq("no lines skipped", r.skipped_lines, 0);
process.exit(fail);
'
echo "session-metrics-test: OK"
