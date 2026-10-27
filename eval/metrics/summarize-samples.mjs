#!/usr/bin/env node
// summarize-samples.mjs — per (scenario, arm) mean / min / max of the token and
// awareness metrics in a run-release-arms.sh samples.jsonl, plus exploit and
// exit-code counts. Deterministic (Tier 0): the output depends only on the
// rows' values, not their order or timestamps; groups are sorted by scenario,
// then arm (code-point order); means are rounded to 2 decimals.
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
      const withMetrics = g.rows.filter((r) => r.metrics && typeof r.metrics === 'object');
      const metrics = {};
      for (const [name, get] of METRICS) {
        const v = withMetrics.map((r) => get(r.metrics)).filter((x) => typeof x === 'number');
        metrics[name] = v.length
          ? { n: v.length, mean: round2(v.reduce((s, x) => s + x, 0) / v.length), min: Math.min(...v), max: Math.max(...v) }
          : { n: 0, mean: null, min: null, max: null };
      }
      const cb = g.rows.map((r) => r.compact_boundaries).filter((x) => typeof x === 'number');
      metrics.compact_boundaries = cb.length
        ? { n: cb.length, mean: round2(cb.reduce((s, x) => s + x, 0) / cb.length), min: Math.min(...cb), max: Math.max(...cb) }
        : { n: 0, mean: null, min: null, max: null };
      const exploit = { pass: 0, fail: 0, error: 0, not_applicable: 0 };
      for (const r of g.rows) {
        if (r.exploit === 'pass' || r.exploit === 'fail' || r.exploit === 'error') exploit[r.exploit]++;
        else exploit.not_applicable++;
      }
      return {
        scenario: g.scenario,
        arm: g.arm,
        refs: [...g.refs].sort(cmp),
        samples: g.rows.length,
        missing_metrics: g.rows.length - withMetrics.length,
        nonzero_exit: g.rows.filter((r) => r.exit_code !== 0).length,
        metrics,
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
      console.log(`${g.scenario} / ${g.arm}  (${g.refs.join(', ')})  samples=${g.samples} missing_metrics=${g.missing_metrics} nonzero_exit=${g.nonzero_exit}`);
      for (const [k, v] of Object.entries(g.metrics)) console.log(`  ${k.padEnd(22)} mean ${f(v.mean).padStart(10)}  min ${f(v.min).padStart(8)}  max ${f(v.max).padStart(8)}  (n=${v.n})`);
      if (g.exploit.not_applicable < g.samples) console.log(`  exploit                pass ${g.exploit.pass}  fail ${g.exploit.fail}  error ${g.exploit.error}`);
    }
  }
}
