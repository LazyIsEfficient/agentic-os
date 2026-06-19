#!/usr/bin/env node
// session-metrics.mjs — deterministic measurement over a Claude Code transcript
// (.jsonl). Emits token accounting + mechanically-detectable awareness-failure
// signals. Same input -> same numbers (Tier 0). The fuzzy signals NORTH_STAR
// also names — "re-derivation of settled facts", "ignored existing state" —
// require LLM judgment (Tier 2) and live in the comparative eval (S4), NOT here.
//
// IMPORTANT: one logical assistant turn is emitted as SEVERAL `type:"assistant"`
// records (thinking / text / each tool_use), and the SAME usage block is repeated
// on every one. Tokens/turns are therefore counted once per `message.id`; tool
// calls are counted across ALL records (their content blocks are split, not
// duplicated). Without the dedupe, totals inflate ~2-4x.
//
// The repeat-read / repeated-tool-call signals are RAW mechanical counts (a path
// Read >1, an identical tool call >1). "Wasteful" is a Tier-2 judgment, not
// asserted here — a re-read after the file changed is legitimate.
//
// Usage: node session-metrics.mjs <transcript.jsonl> [--json]
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

// Parse a transcript into the deterministic metric report. Exported so the
// comparative harness (compare.mjs) reuses the EXACT same accounting.
export function computeMetrics(path) {
  const lines = readFileSync(path, 'utf8').split('\n').filter(Boolean);

  let turns = 0, inTok = 0, outTok = 0, cacheRead = 0, cacheCreate = 0, skipped = 0;
  const seenTurns = new Set();      // message id -> already counted
  const readCounts = new Map();     // file_path -> times Read
  const toolCallCounts = new Map(); // "name <stable json input>" -> count

  for (const line of lines) {
    let o;
    try { o = JSON.parse(line); } catch { skipped++; continue; }
    if (o.type !== 'assistant' || !o.message) continue;

    const u = o.message.usage;
    if (u) {
      const id = o.message.id || o.requestId || o.uuid;
      if (!seenTurns.has(id)) {
        seenTurns.add(id);
        turns++;
        inTok       += u.input_tokens || 0;
        outTok      += u.output_tokens || 0;
        cacheRead   += u.cache_read_input_tokens || 0;
        cacheCreate += u.cache_creation_input_tokens || 0;
      }
    }

    const content = o.message.content;
    if (!Array.isArray(content)) continue;
    for (const c of content) {
      if (c.type !== 'tool_use') continue;
      const inp = c.input || {};
      const key = c.name + ' ' + JSON.stringify(inp, Object.keys(inp).sort());
      toolCallCounts.set(key, (toolCallCounts.get(key) || 0) + 1);
      if (c.name === 'Read' && inp.file_path) {
        readCounts.set(inp.file_path, (readCounts.get(inp.file_path) || 0) + 1);
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
    turns,
    skipped_lines: skipped,
    tokens: { output: outTok, input: inTok, cache_read: cacheRead, cache_creation: cacheCreate },
    output_tokens_per_turn: turns ? Math.round(outTok / turns) : 0,
    awareness_signals: {
      repeat_read_files: repeatReads.length, // raw "read >1" count (Tier-2 wasteful judgment excluded)
      repeat_reads: repeatReads,
      repeated_tool_calls: repeatedToolCalls,
    },
  };
}

// ── CLI ────────────────────────────────────────────────────────────────────────
// Only run when invoked directly (not when imported by compare.mjs).
// pathToFileURL normalizes both sides — robust to relative argv[1], spaces, and
// percent-encoding (a hand-built `file://${argv[1]}` silently fails on those).
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const path = process.argv[2];
  if (!path) {
    console.error('usage: session-metrics.mjs <transcript.jsonl> [--json]');
    process.exit(2);
  }
  const report = computeMetrics(path);

  if (process.argv.includes('--json')) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    const r = report;
    console.log(`session-metrics: ${path}`);
    console.log(`  turns (inferences):     ${r.turns}${r.skipped_lines ? `  (skipped ${r.skipped_lines} unparseable lines)` : ''}`);
    console.log(`  output tokens:          ${r.tokens.output}  (${r.output_tokens_per_turn}/turn)`);
    console.log(`  input tokens:           ${r.tokens.input}`);
    console.log(`  cache read / creation:  ${r.tokens.cache_read} / ${r.tokens.cache_creation}`);
    console.log(`  awareness signals (Tier 0, raw repeat counts):`);
    console.log(`    files read >1x:       ${r.awareness_signals.repeat_read_files}`);
    for (const rr of r.awareness_signals.repeat_reads.slice(0, 10)) console.log(`      ${rr.reads}x  ${rr.file}`);
    console.log(`    repeated tool calls:  ${r.awareness_signals.repeated_tool_calls}`);
  }
}
