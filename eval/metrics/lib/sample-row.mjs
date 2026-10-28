#!/usr/bin/env node
// sample-row.mjs — build ONE samples.jsonl row for run-release-arms.sh. Values
// come from the environment (never a shell-built JSON string). The auth VALUE
// is never an input here.
//
// Trust model: the PROXY log is authoritative (the proxy is outside the
// model's reach) for tokens, denials and cap stops. The CLI result record
// (LOG) and the transcript metrics (SCORE_JSON) are MODEL-WRITABLE and
// advisory; a disagreement with the proxy is flagged, not trusted. A stop is
// read from STRUCTURED fields only, never by regex over free text.
//
//   SCORE_JSON   score-sample.mjs output (metrics, exploit, scan, transcript_*)
//   LOG          the sample's redacted claude log
//   PROXY_LOG    the sample's redacted proxy log (docker sandbox; absent in none)
//   Prices (all UNVERIFIED; none are built in — without them cost is
//   "price unknown" and only tokens are reported):
//     PRICE_<MODEL>_IN_PER_MTOK, PRICE_<MODEL>_OUT_PER_MTOK  USD per 1e6 tokens,
//       <MODEL> = model id upper-cased, non-alphanumerics -> "_"
//       (claude-sonnet-5-5 -> PRICE_CLAUDE_SONNET_5_5_IN_PER_MTOK)
//     PRICE_CACHE_READ_MULT, PRICE_CACHE_WRITE_MULT  x the input price
import { existsSync, readFileSync } from 'node:fs';

const e = process.env;
const readJson = (p) => {
  if (!p || !existsSync(p)) return null;
  try { return JSON.parse(readFileSync(p, 'utf8')); } catch { return null; }
};
const num = (x) => (typeof x === 'number' && Number.isFinite(x) ? x : null);
const envNum = (k) => (e[k] !== undefined && e[k] !== '' && Number.isFinite(Number(e[k])) && Number(e[k]) >= 0 ? Number(e[k]) : null);
const round6 = (x) => Math.round(x * 1e6) / 1e6;

const exitCodes = (e.EXIT_CODES || '').split(' ').filter(Boolean).map(Number);
const firstNonzero = exitCodes.find((c) => c !== 0);
const prompts = Number(e.PROMPTS);
const score = readJson(e.SCORE_JSON) || {};
const metrics = score.metrics && typeof score.metrics === 'object' ? score.metrics : null;

// ── CLI result records (LOG) — advisory. Only a line that is one JSON object
// with type==="result" counts; a free-text answer is never a result. ──
const cliResults = [];
if (e.LOG && existsSync(e.LOG)) {
  for (const line of readFileSync(e.LOG, 'latin1').split('\n')) {
    const s = line.trim();
    if (!s.startsWith('{') || !s.endsWith('}')) continue;
    let o; try { o = JSON.parse(s); } catch { continue; }
    if (o && typeof o === 'object' && o.type === 'result') cliResults.push(o);
  }
}
let cliCost = null;
for (const r of cliResults) { const c = num(r.total_cost_usd); if (c !== null && c >= 0) cliCost = (cliCost || 0) + c; }
// Advisory stop indicators (model-writable): they DO mark a row incomplete,
// which a model can only use to drop its OWN sample. LAST result's structured
// fields only.
const advisorySignals = [];
const last = cliResults[cliResults.length - 1];
if (last) {
  if (last.is_error === true) advisorySignals.push(`cli result is_error (${String(last.subtype || 'error').slice(0, 60)})`);
  else if (last.subtype && last.subtype !== 'success') advisorySignals.push(`cli result subtype ${String(last.subtype).slice(0, 60)}`);
}
for (const s of Array.isArray(score.transcript_error_results) ? score.transcript_error_results : []) {
  advisorySignals.push(`transcript error result (${s})`);
}

// ── PROXY log — AUTHORITATIVE. The final {summary:true} line when present;
// otherwise rebuilt from start/end lines, charging any request that started
// but never ended its reservation (fail closed). ──
const stopSignals = [];
let proxy = null;
if (e.PROXY_LOG && existsSync(e.PROXY_LOG)) {
  const byModel = {}; const started = new Map(); let committed = 0, requests = 0, unparsed = 0, unfinished = 0;
  const denials = []; let summary = null; let drainRejected = 0, qwTotal = 0, qwMax = 0;
  const add = (m, u) => {
    const t = byModel[m] || (byModel[m] = { input: 0, cache_read: 0, cache_creation: 0, output: 0 });
    for (const k of Object.keys(t)) t[k] += num(u[k]) || 0;
  };
  for (const line of readFileSync(e.PROXY_LOG, 'latin1').split('\n')) {
    const s = line.trim();
    if (!s.startsWith('{')) continue;
    let o; try { o = JSON.parse(s); } catch { continue; }
    if (!o || typeof o !== 'object') continue;
    if (o.summary === true) summary = o;
    else if (o.denied !== undefined && o.cause === 'drain') drainRejected++;
    else if (o.denied !== undefined) denials.push(`${o.status} ${String(o.denied).slice(0, 100)}`);
    else if (o.phase === 'start') {
      requests++; started.set(o.id, o);
      const w = num(o.queue_wait_ms); if (w !== null) { qwTotal += w; qwMax = Math.max(qwMax, w); }
    }
    else if (o.phase === 'end') {
      started.delete(o.id);
      committed = Math.max(committed, num(o.committed) || 0);
      if (o.usage_parsed === false && o.status >= 200 && o.status < 300) unparsed++;
      if (o.usage && o.model) add(o.model, o.usage);
    }
  }
  if (summary) {
    proxy = { summary: true, requests: num(summary.requests) || 0, committed_units: num(summary.committed_units) || 0,
      unparsed: num(summary.unparsed) || 0, unfinished: num(summary.unfinished) || 0, by_model: summary.by_model || {} };
  } else {
    for (const o of started.values()) { unfinished++; committed += num(o.reserved) || 0; }
    proxy = { summary: false, requests, committed_units: committed, unparsed, unfinished, by_model: byModel };
  }
  proxy.denials = denials.length;
  proxy.drain_rejected = summary ? (num(summary.drain_rejected) ?? drainRejected) : drainRejected;
  proxy.dropped = summary ? (num(summary.dropped) || 0) : 0;
  proxy.client_aborted = summary ? (num(summary.client_aborted) || 0) : 0;
  // Time requests spent waiting for the single slot: serialization can slow an
  // arm that fans out parallel subagents, so it is reported, not hidden.
  proxy.queue_wait_ms = { total: summary ? (num(summary.queue_wait_ms_total) ?? qwTotal) : qwTotal, max: summary ? (num(summary.queue_wait_ms_max) ?? qwMax) : qwMax };
  if (denials.length) { proxy.denied = denials.slice(0, 5); stopSignals.push(`proxy denied: ${denials[0]}`); }
  // Not model-caused: the sample was still sending when the harness shut the
  // proxy down. Its own reason, still incomplete (work was cut off).
  if (proxy.drain_rejected) stopSignals.push(`proxy rejected ${proxy.drain_rejected} request(s) while shutting down (not model-caused)`);
  if (proxy.unparsed || proxy.unfinished) stopSignals.push(`proxy charged worst case (unparsed ${proxy.unparsed}, unfinished ${proxy.unfinished})`);
}

// ── Tokens (proxy) and cost (derived estimate; prices must be supplied) ──
let tokens = null, cost = null, costSource = null, costMismatch = null, priceMissing = [];
if (proxy) {
  const t = { input: 0, cache_read: 0, cache_creation: 0, output: 0 };
  for (const m of Object.values(proxy.by_model)) for (const k of Object.keys(t)) t[k] += num(m[k]) || 0;
  tokens = { ...t, by_model: proxy.by_model, cap_units: proxy.committed_units, source: 'proxy' };
  const cr = envNum('PRICE_CACHE_READ_MULT'), cw = envNum('PRICE_CACHE_WRITE_MULT');
  let total = 0;
  for (const [model, u] of Object.entries(proxy.by_model)) {
    const key = model.toUpperCase().replace(/[^A-Z0-9]/g, '_');
    const pin = envNum(`PRICE_${key}_IN_PER_MTOK`), pout = envNum(`PRICE_${key}_OUT_PER_MTOK`);
    if (pin === null) priceMissing.push(`PRICE_${key}_IN_PER_MTOK`);
    if (pout === null) priceMissing.push(`PRICE_${key}_OUT_PER_MTOK`);
    if (u.cache_read && cr === null) priceMissing.push('PRICE_CACHE_READ_MULT');
    if (u.cache_creation && cw === null) priceMissing.push('PRICE_CACHE_WRITE_MULT');
    if (pin !== null && pout !== null) {
      total += (u.input * pin + u.output * pout + u.cache_read * pin * (cr || 0) + u.cache_creation * pin * (cw || 0)) / 1e6;
    }
  }
  priceMissing = [...new Set(priceMissing)];
  if (!Object.keys(proxy.by_model).length) {
    // $0 only when nothing at all was charged; units reserved but never
    // attributed to a model (an unfinished request, no summary) are unknown.
    if (proxy.committed_units > 0) { costSource = `unknown: ${proxy.committed_units} cap units charged with no usage attributed`; }
    else { cost = 0; costSource = 'proxy: no billable requests'; }
  }
  else if (priceMissing.length) { costSource = 'price unknown'; }
  else {
    cost = round6(total);
    costSource = proxy.unparsed || proxy.unfinished ? 'proxy tokens x supplied prices (estimate; includes worst-case charges)' : 'proxy tokens x supplied prices (estimate)';
    if (cliCost !== null) costMismatch = round6(cliCost - cost);
  }
} else if (cliCost !== null) {
  cost = cliCost; costSource = 'cli-only (model-writable)';
}

if (e.INTERRUPTED === '1') stopSignals.push('interrupted');
if (e.SAMPLE_ERROR) stopSignals.push(String(e.SAMPLE_ERROR).slice(0, 120));
const allSignals = [...new Set([...stopSignals, ...advisorySignals])];
let incompleteReason = null;
if (stopSignals.includes('interrupted')) incompleteReason = `interrupted (${exitCodes.length} of ${prompts} prompts ran)`;
else if (e.SAMPLE_ERROR) incompleteReason = String(e.SAMPLE_ERROR).slice(0, 120);
else if (firstNonzero !== undefined) incompleteReason = `prompt ${exitCodes.indexOf(firstNonzero) + 1} of ${prompts} exited ${firstNonzero}`;
else if (exitCodes.length !== prompts) incompleteReason = `${exitCodes.length} of ${prompts} prompts ran`;
else if (allSignals.length) incompleteReason = `stopped: ${allSignals[0]}`;
else if (!metrics) incompleteReason = 'no transcript metrics';

let exploit = null, exploitDetail = null;
if (score.exploit) {
  const x = score.exploit.json;
  if (x && ['pass', 'fail', 'error'].includes(x.exploit)) {
    exploit = x.exploit;
    const { exploit: _, ...rest } = x;
    exploitDetail = { exit: Number(score.exploit.rc), ...rest };
  } else {
    exploit = 'error';
    exploitDetail = { exit: Number(score.exploit.rc), reason: 'exploit check produced no verdict' };
  }
}

let scan = null;
if (score.scan) {
  const s = score.scan.json;
  scan = { exit: Number(score.scan.rc) };
  if (s && Array.isArray(s.scanners)) {
    scan.gitleaks = 'unavailable';
    scan.semgrep = 'unavailable';
    for (const sc of s.scanners) scan[sc.name] = sc.status === 'ran' || sc.status === 'findings' ? (sc.findings || []).length : sc.status;
  } else {
    scan.error = 'security-scan.sh produced no JSON report';
  }
}

process.stdout.write(JSON.stringify({
  run_id: e.RUN_ID,
  recorded_utc: new Date().toISOString(),
  harness_sha: e.HARNESS_SHA,
  harness_dirty: e.HARNESS_DIRTY === 'true',
  sandbox: e.SANDBOX,
  arm: e.ARM,
  ref: e.REF,
  flags: (e.FLAGS || '').split(',').filter(Boolean),
  repo_sha: e.REPO_SHA,
  model: e.MODEL || null,
  scenario: e.SCENARIO,
  prompts,
  prompts_run: exitCodes.length,
  status: incompleteReason ? 'incomplete' : 'complete',
  incomplete_reason: incompleteReason,
  stop_signals: allSignals,
  advisory_stop_signals: [...new Set(advisorySignals)],
  sample: Number(e.SAMPLE),
  order: Number(e.ORDER),
  session_id: e.SID,
  exit_code: firstNonzero === undefined ? 0 : firstNonzero,
  exit_codes: exitCodes,
  cli_results: cliResults.length,
  tokens,
  cost_usd: cost,
  cost_source: costSource,
  price_missing: priceMissing,
  cli_cost_usd: cliCost,
  cost_mismatch_usd: costMismatch,
  proxy,
  transcript_found: score.transcript_found === true,
  metrics,
  metrics_trust: 'model-writable (advisory)',
  compact_boundaries: typeof score.compact_boundaries === 'number' ? score.compact_boundaries : null,
  task_base: e.TASK_BASE || null,
  exploit,
  exploit_detail: exploitDetail,
  scan,
}) + '\n');
