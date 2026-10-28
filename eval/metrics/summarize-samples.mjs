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
  const v = values.filter((x) => typeof x === 'number'), raw = v.reduce((s, x) => s + x, 0) / v.length; // rawMean: non-enumerable (not in summary.json), for deltas
  return v.length
    ? Object.defineProperty({ n: v.length, mean: round2(raw), min: Math.min(...v), max: Math.max(...v) }, 'rawMean', { value: raw })
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
// The harness-written row's own reason when it has one (rows are written by the
// host, not the model); otherwise recomputed the same way.
function incompleteReason(r) {
  if (typeof r.incomplete_reason === 'string' && r.incomplete_reason) return r.incomplete_reason;
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
        proxy_cache_read_tokens: stats(done.map((r) => r.tokens?.cache_read)),
        proxy_cache_creation_tokens: stats(done.map((r) => r.tokens?.cache_creation)),
        proxy_output_tokens: stats(done.map((r) => r.tokens?.output)),
        proxy_cap_units: stats(done.map((r) => r.tokens?.cap_units)),
        cost_usd_estimate: stats(done.map((r) => r.cost_usd)),
        cli_cost_usd: stats(done.map((r) => r.cli_cost_usd)),
      };
      // Every row (complete or not): how often the proxy refused something.
      const proxyDenials = g.rows.reduce((s, r) => s + (Number(r.proxy?.denials) || 0), 0);
      // How cost was (or was not) derived, and which prices were missing.
      const costSources = {};
      for (const r of g.rows) { const k = clean(r.cost_source ?? 'none'); costSources[k] = (costSources[k] || 0) + 1; }
      const priceMissing = [...new Set(g.rows.flatMap((r) => (Array.isArray(r.price_missing) ? r.price_missing : [])).map(clean))].sort(cmp);
      // The proxy's own 429s (not model denials), over every row: `inflight`
      // = transient concurrency / in-flight spike (older rows: cap_rejected);
      // `budget` = the unit cap was spent.
      const proxyInflight = g.rows.reduce((s, r) => s + (Number(r.proxy?.inflight_rejected ?? r.proxy?.cap_rejected) || 0), 0);
      const proxyBudget = g.rows.reduce((s, r) => s + (Number(r.proxy?.budget_rejected) || 0), 0);
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
        proxy_denials: proxyDenials,
        proxy_inflight_429s: proxyInflight,
        proxy_inflight_429s_per_sample: g.rows.length ? Math.round((proxyInflight / g.rows.length) * 100) / 100 : 0,
        proxy_budget_429s: proxyBudget,
        completion_rate: g.rows.length ? Math.round((done.length / g.rows.length) * 1000) / 1000 : 0,
        run_ids: [...new Set(g.rows.map((r) => clean(r.run_id ?? 'unknown')))].sort(cmp),
        sandboxes: [...new Set(g.rows.map((r) => clean(r.sandbox ?? 'unknown')))].sort(cmp),
        settings: [...new Set(g.rows.map((r) => JSON.stringify(r.settings ?? null)))].sort(cmp),
        cost_sources: Object.fromEntries(Object.entries(costSources).sort(([a], [b]) => cmp(a, b))),
        price_missing: priceMissing,
        models: [...new Set(g.rows.map((r) => clean(r.model ?? 'unknown')))].sort(cmp),
        prompts: [...new Set(g.rows.map((r) => r.prompts))].sort((a, b) => a - b),
        harness: [...new Set(g.rows.map((r) => clean(r.harness_sha ?? 'unknown')))].sort(cmp),
        primary,
        metrics,
        metrics_trust: 'awareness metrics are model-writable (advisory); primary tokens/cost are proxy-authoritative',
        exploit,
      };
    });
  const c = comparable(out);
  return { groups: out, comparable: c, deltas: c.ok ? deltas(out) : null };
}

// Arm-vs-baseline deltas, per scenario and metric: mean(arm) - mean(baseline),
// with the range of possible per-sample differences [min-max, max-min] and n
// on each side. The baseline is the arm named v301 when present (the release
// under comparison), else the first arm by name. Only computed when the arms
// are comparable. Proxy metrics are primary; transcript metrics advisory.
export const BASELINE_ARM = 'v301';
function deltas(groups) {
  const out = [];
  const scen = [...new Set(groups.map((g) => g.scenario))].sort(cmp);
  for (const sc of scen) {
    const gs = groups.filter((g) => g.scenario === sc);
    const base = gs.find((g) => g.arm === BASELINE_ARM) || [...gs].sort((a, b) => cmp(a.arm, b.arm))[0];
    for (const g of gs.filter((x) => x !== base).sort((a, b) => cmp(a.arm, b.arm))) {
      const rows = [];
      for (const [kind, block] of [['primary', 'primary'], ['advisory', 'metrics']]) {
        for (const [name, a] of Object.entries(g[block])) {
          const b = base[block][name];
          if (!b || a.mean === null || b.mean === null) continue;
          rows.push({ kind, metric: name, delta_mean: round2(a.rawMean - b.rawMean), range: [round2(a.min - b.max), round2(a.max - b.min)], n: [a.n, b.n] });
        }
      }
      out.push({ scenario: sc, arm: g.arm, baseline: base.arm, rows });
    }
  }
  return out;
}

// "Arms comparable?": one verdict for the whole run, with every reason it is
// NO. Comparable only when:
//   - every row comes from ONE run (same run_id) in ONE sandbox mode, with the
//     same model, harness and per-run settings (max_tokens cap, unit cap,
//     in-flight limit, cache-read weight, beta allowlist hash, models);
//   - every arm ran each scenario with the same prompt count;
//   - COUNT RULE (maintainer decision): with R = the most samples any
//     (scenario, arm) has (= --runs), every (scenario, arm) has at least
//     max(2, R - 1) complete samples — one failure per arm per scenario is
//     tolerated, and 2 is the fewest that give any spread — and for each
//     scenario the arms' complete counts differ by at most 1.
// With --runs 1 no arm can reach 2 complete samples, so it is always NO.
// A WARNING (not a NO) is printed when the arms' inflight-429 rates per
// sample are far apart: whether the CLI retries those transparently is
// UNVERIFIED, so a fan-out arm may have been slowed.
export const MIN_COMPLETE = 2;
function comparable(groups) {
  const reasons = [];
  const warnings = [];
  const all = (k) => new Set(groups.flatMap((g) => g[k]));
  for (const [k, label] of [['run_ids', 'run ids'], ['sandboxes', 'sandbox modes'], ['models', 'models'], ['harness', 'harness shas'], ['settings', 'per-run settings']]) {
    const v = all(k);
    if (v.size !== 1) reasons.push(`${label} differ (${v.size})`);
  }
  const runs = groups.reduce((m, g) => Math.max(m, g.samples), 0);
  const need = Math.max(MIN_COMPLETE, runs - 1);
  const byScenario = new Map();
  for (const g of groups) {
    const s = byScenario.get(g.scenario) || { prompts: new Set(), arms: new Map(), inflight: [] };
    for (const p of g.prompts) s.prompts.add(p);
    s.arms.set(g.arm, g.complete); s.inflight.push([g.arm, g.proxy_inflight_429s_per_sample]);
    byScenario.set(g.scenario, s);
  }
  const allArms = new Set(groups.map((g) => g.arm));
  for (const [sc, s] of [...byScenario.entries()].sort(([a], [b]) => cmp(a, b))) {
    if (s.prompts.size !== 1) reasons.push(`${sc}: prompt counts differ across arms`);
    for (const a of [...allArms].sort(cmp)) if (!s.arms.has(a)) reasons.push(`${sc}: arm ${a} has no samples`);
    const counts = [...s.arms.entries()].sort(([a], [b]) => cmp(a, b));
    const lo = Math.min(...counts.map(([, c]) => c)), hi = Math.max(...counts.map(([, c]) => c));
    if (hi - lo > 1) reasons.push(`${sc}: complete counts differ by ${hi - lo} (> 1): ${counts.map(([a, c]) => `${a}=${c}`).join(', ')}`);
    const rates = s.inflight.map(([, r]) => r);
    const rlo = Math.min(...rates), rhi = Math.max(...rates);
    if (rhi > 10 && rhi > 3 * rlo) warnings.push(`${sc}: inflight 429s per sample far apart (${s.inflight.map(([a, r]) => `${a}=${r}`).join(', ')}); a fan-out arm may have been throttled (UNVERIFIED whether the CLI retries transparently)`);
  }
  for (const g of groups) {
    if (g.complete < need) reasons.push(`${g.scenario}/${g.arm}: ${g.complete} of ${g.samples} complete < ${need} required (rule: max(2, runs-1) with runs=${runs})${runs < MIN_COMPLETE ? '; with --runs 1 this is always NO' : ''}`);
  }
  return { ok: reasons.length === 0, rule: `each (scenario, arm) >= max(2, runs-1) complete; complete counts per scenario differ by <= 1`, runs, required_complete: need, reasons, warnings };
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
      console.log(`${g.scenario} / ${g.arm}  (${g.refs.join(', ')})  samples=${g.samples} complete=${g.complete} incomplete=${g.incomplete.count} completion=${Math.round(g.completion_rate * 100)}% proxy_denials=${g.proxy_denials} inflight_429s=${g.proxy_inflight_429s} budget_429s=${g.proxy_budget_429s}`);
      console.log(`  cost: ${Object.entries(g.cost_sources).map(([k, n]) => `${n} x ${k}`).join('; ')}${g.price_missing.length ? `; missing ${g.price_missing.join(' ')}` : ''}`);
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
    const c = s.comparable;
    console.log(`ARMS COMPARABLE? ${c.ok ? 'yes' : 'NO'} (one run and sandbox, same model/harness/settings, same prompt counts; ${c.rule}; runs=${c.runs}, required=${c.required_complete})`);
    for (const r of c.reasons) console.log(`  NO because: ${clean(r)}`);
    for (const w of c.warnings) console.log(`  WARNING: ${clean(w)}`);
    if (!s.deltas) {
      console.log(`DELTAS: not comparable: ${c.reasons.map(clean).join('; ')}`);
    } else {
      console.log('DELTAS (arm - baseline; mean, [range of per-sample differences], n arm/baseline):');
      for (const d of s.deltas) {
        console.log(`  ${clean(d.scenario)}: ${clean(d.arm)} - ${clean(d.baseline)}`);
        for (const r of d.rows) console.log(`    ${r.kind === 'primary' ? 'primary ' : 'advisory'} ${r.metric.padEnd(28)} ${String(r.delta_mean).padStart(12)}  [${r.range[0]}, ${r.range[1]}]  n=${r.n[0]}/${r.n[1]}`);
      }
      console.log(`  primary = proxy-authoritative; advisory = model-writable transcript.${s.deltas.some((d) => d.rows.some((r) => r.metric === 'compact_boundaries')) ? ' compact_boundaries: the record shape and whether headless --resume compacts are UNVERIFIED.' : ''}`);
    }
  }
}
