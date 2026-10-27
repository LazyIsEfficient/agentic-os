#!/usr/bin/env node
// sample-row.mjs — build ONE samples.jsonl row for run-release-arms.sh. Values
// come from the environment (never from a shell-built JSON string); the
// metric / exploit / scan inputs are paths to files the harness wrote, and a
// missing or unparseable file becomes null (metrics) or an explicit error.
// The auth VALUE is never an input here.
import { readFileSync, existsSync } from 'node:fs';

const e = process.env;
const readJson = (p) => {
  if (!p || !existsSync(p)) return undefined;
  try { return JSON.parse(readFileSync(p, 'utf8')); } catch { return null; }
};

const exitCodes = (e.EXIT_CODES || '').split(' ').filter(Boolean).map(Number);
const firstNonzero = exitCodes.find((c) => c !== 0);

let compactBoundaries = null;
if (e.TRANSCRIPT && existsSync(e.TRANSCRIPT)) {
  // Claude Code marks a compaction with a {"type":"system","subtype":"compact_boundary"}
  // record. UNVERIFIED against a live headless transcript; 0 means none seen.
  compactBoundaries = 0;
  for (const line of readFileSync(e.TRANSCRIPT, 'utf8').split('\n')) {
    if (!line) continue;
    try { if (JSON.parse(line).subtype === 'compact_boundary') compactBoundaries++; } catch { /* skipped */ }
  }
}

let metrics = readJson(e.METRICS_JSON);
if (metrics === undefined) metrics = null;

let exploit = null, exploitDetail = null;
if (e.EXPLOIT_JSON) {
  const x = readJson(e.EXPLOIT_JSON);
  if (x && ['pass', 'fail', 'error'].includes(x.exploit)) {
    exploit = x.exploit;
    const { exploit: _, ...rest } = x;
    exploitDetail = { exit: Number(e.EXPLOIT_RC), ...rest };
  } else {
    exploit = 'error';
    exploitDetail = { exit: Number(e.EXPLOIT_RC), reason: 'exploit check produced no verdict' };
  }
}

// Per scanner: finding count when it ran, else its status (unavailable / error).
// gitleaks and semgrep are always present; a scanner the wrapper did not
// report is "unavailable".
let scan = null;
if (e.SCAN_JSON) {
  const s = readJson(e.SCAN_JSON);
  scan = { exit: Number(e.SCAN_RC) };
  if (s && Array.isArray(s.scanners)) {
    scan.gitleaks = 'unavailable';
    scan.semgrep = 'unavailable';
    for (const sc of s.scanners) {
      scan[sc.name] = sc.status === 'ran' || sc.status === 'findings' ? (sc.findings || []).length : sc.status;
    }
  } else {
    scan.error = 'security-scan.sh produced no JSON report';
  }
}

process.stdout.write(JSON.stringify({
  run_id: e.RUN_ID,
  recorded_utc: new Date().toISOString(),
  harness_sha: e.HARNESS_SHA,
  harness_dirty: e.HARNESS_DIRTY === 'true',
  arm: e.ARM,
  ref: e.REF,
  flags: (e.FLAGS || '').split(',').filter(Boolean),
  repo_sha: e.REPO_SHA,
  scenario: e.SCENARIO,
  prompts: Number(e.PROMPTS),
  sample: Number(e.SAMPLE),
  order: Number(e.ORDER),
  session_id: e.SID,
  exit_code: firstNonzero === undefined ? 0 : firstNonzero,
  exit_codes: exitCodes,
  transcript_found: Boolean(e.TRANSCRIPT && existsSync(e.TRANSCRIPT)),
  metrics,
  compact_boundaries: compactBoundaries,
  task_base: e.TASK_BASE || null,
  exploit,
  exploit_detail: exploitDetail,
  scan,
}) + '\n');
