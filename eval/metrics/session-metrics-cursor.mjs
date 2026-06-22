#!/usr/bin/env node
// session-metrics-cursor.mjs — Cursor agent-transcript JSONL metrics (issue #154).
// Shares accounting semantics with session-metrics.mjs; Cursor shape differs:
//   role:"assistant" (not type:"assistant"), Read input.path (not file_path),
//   no usage/token fields in export as of Cursor 3.8.x.
//
// Usage: node session-metrics-cursor.mjs <transcript.jsonl> [--json]
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

function canonicalize(v) {
  if (Array.isArray(v)) return v.map(canonicalize);
  if (v && typeof v === 'object') {
    const out = {};
    for (const k of Object.keys(v).sort()) out[k] = canonicalize(v[k]);
    return out;
  }
  return v;
}

function readPath(inp) {
  return inp.file_path || inp.path;
}

export function detectCursorTranscript(lines) {
  for (const line of lines) {
    let o;
    try { o = JSON.parse(line); } catch { continue; }
    if (o.role === 'assistant') return true;
    if (o.type === 'assistant') return false;
  }
  return false;
}

export function computeMetrics(path) {
  const lines = readFileSync(path, 'utf8').split('\n').filter(Boolean);

  let turns = 0, skipped = 0;
  const seenTurns = new Set();
  const readCounts = new Map();
  const toolCallCounts = new Map();

  for (const line of lines) {
    let o;
    try { o = JSON.parse(line); } catch { skipped++; continue; }
    if (o.role !== 'assistant' || !o.message) continue;

    const msg = o.message;
    const turnId = msg.id || o.requestId || o.uuid;
    const u = msg.usage;
    if (u) {
      if (turnId == null || !seenTurns.has(turnId)) {
        if (turnId != null) seenTurns.add(turnId);
        turns++;
      }
    } else if (turnId == null || !seenTurns.has(turnId)) {
      if (turnId != null) seenTurns.add(turnId);
      turns++;
    }

    const content = msg.content;
    if (!Array.isArray(content)) continue;
    for (const c of content) {
      if (c.type !== 'tool_use') continue;
      const name = c.name;
      const inp = c.input || {};
      const key = name + ' ' + JSON.stringify(canonicalize(inp));
      toolCallCounts.set(key, (toolCallCounts.get(key) || 0) + 1);
      if (name === 'Read') {
        const fp = readPath(inp);
        if (fp) readCounts.set(fp, (readCounts.get(fp) || 0) + 1);
      }
    }
  }

  const repeatReads = [...readCounts.entries()]
    .filter(([, n]) => n > 1)
    .map(([file, reads]) => ({ file, reads }))
    .sort((a, b) => b.reads - a.reads || a.file.localeCompare(b.file));
  const repeatedToolCalls = [...toolCallCounts.values()].filter(n => n > 1).length;

  return {
    transcript: path,
    platform: 'cursor',
    turns,
    skipped_lines: skipped,
    tokens: { output: 0, input: 0, cache_read: 0, cache_creation: 0 },
    output_tokens_per_turn: 0,
    awareness_signals: {
      repeat_read_files: repeatReads.length,
      repeat_reads: repeatReads,
      repeated_tool_calls: repeatedToolCalls,
    },
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const path = process.argv[2];
  if (!path) {
    console.error('usage: session-metrics-cursor.mjs <transcript.jsonl> [--json]');
    process.exit(2);
  }
  const report = computeMetrics(path);
  if (process.argv.includes('--json')) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    const r = report;
    console.log(`session-metrics (cursor): ${path}`);
    console.log(`  turns (inferences):     ${r.turns}${r.skipped_lines ? `  (skipped ${r.skipped_lines} unparseable lines)` : ''}`);
    console.log(`  output tokens:          ${r.tokens.output}  (not in Cursor export)`);
    console.log(`  awareness signals (Tier 0, raw repeat counts):`);
    console.log(`    files read >1x:       ${r.awareness_signals.repeat_read_files}`);
    for (const rr of r.awareness_signals.repeat_reads.slice(0, 10)) console.log(`      ${rr.reads}x  ${rr.file}`);
    console.log(`    repeated tool calls:  ${r.awareness_signals.repeated_tool_calls}`);
  }
}
