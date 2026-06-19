#!/usr/bin/env bash
# compare-test.sh — deterministic test of compare.mjs. The fixture arm pair
# encodes a known awareness story: the OFF (baseline) arm re-reads /config.txt and
# takes an extra turn (drift), so it spends more output tokens. The delta must
# reproduce exactly from the fixed transcripts (Tier 0) — the LIVE A/B is a
# separate stochastic sample (see README.md).
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

out="$(node "$DIR/compare.mjs" "$DIR/fixtures/arm-on.jsonl" "$DIR/fixtures/arm-off.jsonl" --json)"
out2="$(node "$DIR/compare.mjs" "$DIR/fixtures/arm-on.jsonl" "$DIR/fixtures/arm-off.jsonl" --json)"
[ "$out" = "$out2" ] && echo "PASS  deterministic (run twice, identical)" || { echo "FAIL  non-deterministic"; exit 1; }

printf '%s' "$out" | node -e '
const r = JSON.parse(require("fs").readFileSync(0, "utf8"));
let fail = 0;
const eq = (n, a, b) => { if (a === b) console.log("PASS  " + n); else { console.log(`FAIL  ${n}: expected ${b}, got ${a}`); fail = 1; } };
// ON: out 100+60=160, 2 turns, 0 repeat reads.  OFF: 100+90+80=270, 3 turns, /config.txt 2x.
eq("ON output tokens", r.metrics.output_tokens.on, 160);
eq("OFF output tokens", r.metrics.output_tokens.off, 270);
eq("Δ output tokens (OFF-ON)", r.delta.output_tokens.abs, 110);
eq("output tokens saved% (110/270)", r.delta.output_tokens.pct_saved, 41);
eq("Δ turns", r.delta.turns.abs, 1);
eq("Δ repeat-read files (OFF re-read config)", r.delta.repeat_read_files.abs, 1);
eq("Δ repeated tool calls", r.delta.repeated_tool_calls.abs, 1);
process.exit(fail);
'
echo "compare-test: OK"
