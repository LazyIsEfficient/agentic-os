#!/usr/bin/env node
// compare.mjs — comparative measurement for the awareness harness (S4).
// Diffs two transcripts over the SAME scenario: the ON arm (awareness hooks
// active) vs the OFF arm (no awareness hooks — empty-hooks settings). Reports per-metric
// delta (OFF - ON): a positive delta means the harness arm spent LESS / drifted
// less. Re-aims eval/ from single-task correctness to tokens-per-outcome +
// long-session coherence.
//
// DETERMINISTIC over fixed transcripts (same files -> same delta). A single live
// A/B is ONE stochastic sample, not a reproducible number — see ./README.md.
//
// Usage: node compare.mjs <on.jsonl> <off.jsonl> [--json]
import { computeMetrics } from './session-metrics.mjs';

const onPath = process.argv[2], offPath = process.argv[3];
if (!onPath || !offPath) {
  console.error('usage: compare.mjs <on.jsonl> <off.jsonl> [--json]');
  process.exit(2);
}

const on = computeMetrics(onPath);
const off = computeMetrics(offPath);

const pctSaved = (offV, onV) => (offV === 0 ? 0 : Math.round(((offV - onV) / offV) * 100));
const metrics = {
  output_tokens:       { on: on.tokens.output,                          off: off.tokens.output },
  turns:               { on: on.turns,                                  off: off.turns },
  repeat_read_files:   { on: on.awareness_signals.repeat_read_files,    off: off.awareness_signals.repeat_read_files },
  repeated_tool_calls: { on: on.awareness_signals.repeated_tool_calls,  off: off.awareness_signals.repeated_tool_calls },
};
const delta = {};
for (const [k, v] of Object.entries(metrics)) delta[k] = { abs: v.off - v.on, pct_saved: pctSaved(v.off, v.on) };

const report = { on: onPath, off: offPath, metrics, delta };

if (process.argv.includes('--json')) {
  console.log(JSON.stringify(report, null, 2));
  process.exit(0);
}

console.log('comparative metrics — ON (awareness harness) vs OFF (no-hooks baseline)');
console.log(`  ON : ${onPath}`);
console.log(`  OFF: ${offPath}`);
console.log(`  ${'metric'.padEnd(20)} ${'ON'.padStart(9)} ${'OFF'.padStart(10)} ${'Δ(OFF-ON)'.padStart(11)} ${'saved%'.padStart(7)}`);
const row = (name, m, d) => console.log(
  `  ${name.padEnd(20)} ${String(m.on).padStart(9)} ${String(m.off).padStart(10)} ${String(d.abs).padStart(11)} ${String(d.pct_saved).padStart(7)}`);
row('output tokens', metrics.output_tokens, delta.output_tokens);
row('turns', metrics.turns, delta.turns);
row('repeat-read files', metrics.repeat_read_files, delta.repeat_read_files);
row('repeated tool calls', metrics.repeated_tool_calls, delta.repeated_tool_calls);
console.log('  (positive Δ / saved% = harness arm used less; ONE live run = ONE stochastic sample)');
