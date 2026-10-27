#!/usr/bin/env node
// summarize-samples.mjs — per (scenario, arm) mean / min / max of the token and
// awareness metrics in a run-release-arms.sh samples.jsonl, over COMPLETE
// samples only, plus exploit counts and incomplete samples with reasons.
// Deterministic (Tier 0): the output depends only on the rows' values, not
// their order or timestamps; groups are sorted by scenario, then arm
// (code-point order); means are rounded to 2 decimals.
//
// This summarizes a distribution of stochastic samples. It is NOT a
// significance test; with small N read min/max, not just the mean.
//
// Usage: node summarize-samples.mjs <samples.jsonl> [--json]
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

const METRICS = [
  ['turns', (m) => m.turns],
  ['output_tokens', (m) => m.tokens?.output],
  ['input_tokens', (m) => m.tokens?.input],
  ['cache_read_tokens', (m) => m.tokens?.cache_read],
  ['cache_creation_tokens', (m) => m.tokens?.cache_creation],
  ['repeat_read_files', (m) => m.awareness_signals?.repeat_read_files],
  ['repeated_tool_calls', (m) => m.awareness_signals?.repeated_tool_calls],
];

const cmp = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
const round2 = (x) => Math.round(x * 100) / 100;

function stats(values) {
  const v = values.filter((x) => typeof x === 'number');
  return v.length
    ? { n: v.length, mean: round2(v.reduce((s, x) => s + x, 0) / v.length), min: Math.min(...v), max: Math.max(...v) }
    : { n: 0, mean: null, min: null, max: null };
}

// Recomputed from the raw fields, not taken from the row's `status`.
// Strip C0 and C1 control characters (keep \t): reasons, refs and arm/scenario
// names come from model-influenced data and reach a terminal. Printed text and
// every string field in the summary goes through this.
const CONTROL = /[\u0000-\u0008\u000a-\u001f\u007f-\u009f]/g;
const clean = (s) => String(s).replace(CONTROL, '').slice(0, 300);
const signals = (r) => (Array.isArray(r.stop_signals) ? r.stop_signals : []);
function isComplete(r) {
  return Array.isArray(r.exit_codes) && r.exit_codes.length === r.prompts
    && r.exit_codes.every((c) => c === 0) && signals(r).length === 0
    && Boolean(r.metrics) && typeof r.metrics === 'object';
}
function incompleteReason(r) {
  const codes = Array.isArray(r.exit_codes) ? r.exit_codes : []; if (signals(r).includes('interrupted')) return `interrupted (${codes.length} of ${r.prompts} prompts ran)`;
  const i = codes.findIndex((c) => c !== 0);
  if (i >= 0) return `prompt ${i + 1} of ${r.prompts} exited ${codes[i]}`;
  if (codes.length !== r.prompts) return `${codes.length} of ${r.prompts} prompts ran`;
  if (signals(r).length) return `stopped: ${signals(r)[0]}`;
  return 'no transcript metrics';
}

export function summarize(rows) {
  const groups = new Map();
  for (const r of rows) {
    const key = JSON.stringify([r.scenario, r.arm]);
    if (!groups.has(key)) groups.set(key, { scenario: r.scenario, arm: r.arm, refs: new Set(), rows: [] });
    const g = groups.get(key);
    g.refs.add(`${r.ref}@${r.repo_sha}`);
    g.rows.push(r);
  }
  const out = [...groups.values()]
    .sort((a, b) => cmp(a.scenario, b.scenario) || cmp(a.arm, b.arm))
    .map((g) => {
      // Metrics and exploit verdicts come from COMPLETE samples only (every
      // prompt ran and exited 0, transcript measured). A failed or partial
      // sample would mix a shorter conversation into the distribution; it is
      // counted under `incomplete` with its reason instead.
      const done = g.rows.filter(isComplete);
      const reasons = {};
      for (const r of g.rows) {
        if (isComplete(r)) continue;
        const why = incompleteReason(r);
        reasons[why] = (reasons[why] || 0) + 1;
      }
      // Fold reasons after stripping control chars (two reasons that differ
      // only by a stripped escape merge into one).
      const sortedReasons = {};
      for (const k of Object.keys(reasons).sort(cmp)) { const c = clean(k); sortedReasons[c] = (sortedReasons[c] || 0) + reasons[k]; }
      // Proxy-authoritative primary metrics (from the row, not the transcript).
      const primary = {
        proxy_input_tokens: stats(done.map((r) => r.tokens?.input)),
        proxy_output_tokens: stats(done.map((r) => r.tokens?.output)),
        cost_usd: stats(done.map((r) => r.cost_usd)),
        cli_cost_usd: stats(done.map((r) => r.cli_cost_usd)),
      };
      // Transcript-derived awareness metrics — MODEL-WRITABLE, advisory.
      const metrics = {};
      for (const [name, get] of METRICS) metrics[name] = stats(done.map((r) => get(r.metrics)));
      metrics.compact_boundaries = stats(done.map((r) => r.compact_boundaries));
      const exploit = { pass: 0, fail: 0, error: 0, not_applicable: 0 };
      for (const r of done) {
        if (r.exploit === 'pass' || r.exploit === 'fail' || r.exploit === 'error') exploit[r.exploit]++;
        else exploit.not_applicable++;
      }
      return {
        scenario: clean(g.scenario),
        arm: clean(g.arm),
        refs: [...g.refs].map(clean).sort(cmp),
        samples: g.rows.length,
        complete: done.length,
        incomplete: { count: g.rows.length - done.length, reasons: sortedReasons },
        primary,
        metrics,
        metrics_trust: 'awareness metrics are model-writable (advisory); primary tokens/cost are proxy-authoritative',
        exploit,
      };
    });
  return { groups: out };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const path = process.argv[2];
  if (!path) { console.error('usage: summarize-samples.mjs <samples.jsonl> [--json]'); process.exit(2); }
  const rows = readFileSync(path, 'utf8').split('\n').filter(Boolean).map((l) => JSON.parse(l));
  const s = summarize(rows);
  if (process.argv.includes('--json')) {
    console.log(JSON.stringify(s, null, 2));
  } else {
    const f = (x) => (x == null ? '-' : String(x));
    for (const g of s.groups) {
      console.log(`${g.scenario} / ${g.arm}  (${g.refs.join(', ')})  samples=${g.samples} complete=${g.complete} incomplete=${g.incomplete.count}`);
      if (g.complete < g.samples) {
        console.log(`  WARNING: only ${g.complete} of ${g.samples} samples complete for ${g.arm}; the metrics below cover those only`);
      }
      for (const [why, n] of Object.entries(g.incomplete.reasons)) console.log(`  incomplete: ${n} x ${clean(why)}`);
      console.log('  primary (proxy-authoritative):');
      for (const [k, v] of Object.entries(g.primary)) console.log(`  ${k.padEnd(22)} mean ${f(v.mean).padStart(10)}  min ${f(v.min).padStart(8)}  max ${f(v.max).padStart(8)}  (n=${v.n})`);
      console.log('  awareness (model-writable, advisory):');
      for (const [k, v] of Object.entries(g.metrics)) console.log(`  ${k.padEnd(22)} mean ${f(v.mean).padStart(10)}  min ${f(v.min).padStart(8)}  max ${f(v.max).padStart(8)}  (n=${v.n})`);
      if (g.exploit.not_applicable < g.complete) console.log(`  exploit                pass ${g.exploit.pass}  fail ${g.exploit.fail}  error ${g.exploit.error}`);
    }
  }
}
