#!/usr/bin/env node
// scenario-prompts.mjs — the scripted prompts of a scenario doc, in order, as
// a JSON array of strings. Deterministic (Tier 0).
//
// Rule: inside the `## Scripted prompt sequence` section (up to the next `## `
// heading), every fenced block whose opening fence is a bare ``` (no info
// string) is one prompt, sent verbatim minus the trailing newline. Fences with
// an info string (```bash, ```markdown) are not prompts.
//
// Usage: node scenario-prompts.mjs <scenario.md>
import { readFileSync } from 'node:fs';

const path = process.argv[2];
if (!path) {
  console.error('usage: scenario-prompts.mjs <scenario.md>');
  process.exit(2);
}
const lines = readFileSync(path, 'utf8').split('\n');
const prompts = [];
let inSection = false, inFence = false, isPrompt = false, buf = [];
for (const line of lines) {
  if (!inFence && /^## /.test(line)) { inSection = /^## Scripted prompt sequence\s*$/.test(line); continue; }
  if (!inSection) continue;
  const fence = /^```(.*)$/.exec(line);
  if (fence && !inFence) { inFence = true; isPrompt = fence[1].trim() === ''; buf = []; continue; }
  if (fence && inFence && fence[1].trim() === '') {
    if (isPrompt) prompts.push(buf.join('\n'));
    inFence = false;
    continue;
  }
  if (inFence) buf.push(line);
}
if (inFence) { console.error(`${path}: unterminated fence in the prompt section`); process.exit(1); }
if (prompts.length === 0) { console.error(`${path}: no prompts under "## Scripted prompt sequence"`); process.exit(1); }
console.log(JSON.stringify(prompts));
