#!/usr/bin/env node
// aggregate.mjs — results JSONL -> per-dimension x output-type comparison report.
//
// CLI:  node aggregate.mjs <results.jsonl> [--out report.md]
//
// Reads one result record per line (eval/schema/result.schema.json), DE-BLINDS
// every judge verdict through that record's blinding_map, and emits a Markdown
// report: per-dimension win-rates, per-output-type win-rates, and per-arm Tier-0
// deterministic pass-rates with the library-minus-baseline delta. No single
// overall pass/fail verdict — an explicit product decision (a legible breakdown).
//
// No Python anywhere in this repo: this is Node ESM, zero dependencies.

import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const TEMPLATE_PATH = join(
  dirname(fileURLToPath(import.meta.url)),
  "report-template.md",
);

// --- arg parsing -----------------------------------------------------------

function parseArgs(argv) {
  let input = null;
  let out = null;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--out") {
      out = argv[++i];
      if (out == null) die("--out requires a path");
    } else if (a.startsWith("--out=")) {
      out = a.slice("--out=".length);
    } else if (a === "-h" || a === "--help") {
      printUsage();
      process.exit(0);
    } else if (a.startsWith("-")) {
      die(`unknown flag: ${a}`);
    } else if (input == null) {
      input = a;
    } else {
      die(`unexpected extra argument: ${a}`);
    }
  }
  if (input == null) die("missing <results.jsonl>");
  return { input, out };
}

function printUsage() {
  process.stderr.write(
    "usage: node aggregate.mjs <results.jsonl> [--out report.md]\n",
  );
}

function die(msg) {
  process.stderr.write(`aggregate: ${msg}\n`);
  printUsage();
  process.exit(2);
}

// --- de-blinding -----------------------------------------------------------

// Translate a blind A/B/tie winner into a canonical arm name (library|baseline)
// or "tie", using THIS record's blinding_map. This is the crux of the proof:
// judges only ever saw neutral A/B; the map is the only way to know which arm
// each label was. Get it wrong and the entire comparison inverts.
function deblindWinner(blindWinner, blindingMap) {
  if (blindWinner === "tie") return "tie";
  if (blindWinner === "A" || blindWinner === "B") {
    const arm = blindingMap[blindWinner];
    if (arm !== "library" && arm !== "baseline") {
      throw new Error(
        `blinding_map.${blindWinner} must be "library" or "baseline", got ${JSON.stringify(arm)}`,
      );
    }
    return arm;
  }
  throw new Error(`winner must be A|B|tie, got ${JSON.stringify(blindWinner)}`);
}

// --- tally machinery -------------------------------------------------------

function newTally() {
  return { library: 0, baseline: 0, tie: 0, total: 0, marginSum: 0 };
}

function recordVerdict(tally, verdict, blindingMap) {
  const arm = deblindWinner(verdict.winner, blindingMap);
  const margin = typeof verdict.margin === "number" ? verdict.margin : 0;
  tally[arm] += 1;
  tally.total += 1;
  // Ties carry margin 0 by contract; sum the de-blinded margin regardless so the
  // mean is over ALL scored verdicts (ties pull it toward 0, which is correct).
  tally.marginSum += arm === "tie" ? 0 : margin;
}

function rate(n, total) {
  return total === 0 ? 0 : n / total;
}

function pct(x) {
  return `${(x * 100).toFixed(0)}%`;
}

function num3(x) {
  return x.toFixed(3);
}

// --- aggregation -----------------------------------------------------------

function aggregate(records) {
  const perDimension = new Map(); // dimension -> tally (insertion-ordered)
  const perOutputType = new Map(); // output_type -> tally
  // Deterministic: count passes and runs per arm.
  const det = {
    library: { pass: 0, runs: 0 },
    baseline: { pass: 0, runs: 0 },
  };
  const fixtures = new Set();

  for (const [lineNo, rec] of records) {
    const where = `line ${lineNo} (fixture ${rec.fixture ?? "?"})`;
    if (!rec.blinding_map) throw new Error(`${where}: missing blinding_map`);
    if (!rec.judge || !Array.isArray(rec.judge.per_dimension)) {
      throw new Error(`${where}: missing judge.per_dimension`);
    }
    if (rec.fixture) fixtures.add(rec.fixture);

    const outType = rec.output_type ?? "unknown";
    if (!perOutputType.has(outType)) perOutputType.set(outType, newTally());
    const otTally = perOutputType.get(outType);

    for (const dv of rec.judge.per_dimension) {
      if (!dv || typeof dv.dimension !== "string") {
        throw new Error(`${where}: per_dimension entry missing 'dimension'`);
      }
      if (!perDimension.has(dv.dimension)) {
        perDimension.set(dv.dimension, newTally());
      }
      recordVerdict(perDimension.get(dv.dimension), dv, rec.blinding_map);
      recordVerdict(otTally, dv, rec.blinding_map);
    }

    // Deterministic pass-rates per arm. Both arms are always recorded.
    for (const arm of ["library", "baseline"]) {
      const d = rec.deterministic?.[arm];
      if (d && typeof d.pass === "boolean") {
        det[arm].runs += 1;
        if (d.pass) det[arm].pass += 1;
      }
    }
  }

  return { perDimension, perOutputType, det, fixtures, runCount: records.length };
}

// --- rendering -------------------------------------------------------------

function tallyRow(label, t) {
  const meanMargin = t.total === 0 ? 0 : t.marginSum / t.total;
  return (
    `| ${label} ` +
    `| ${pct(rate(t.library, t.total))} ` +
    `| ${pct(rate(t.baseline, t.total))} ` +
    `| ${pct(rate(t.tie, t.total))} ` +
    `| ${num3(meanMargin)} ` +
    `| ${t.total} |`
  );
}

function renderWinTable(firstColHeader, map) {
  const header =
    `| ${firstColHeader} | Library win | Baseline win | Tie | Mean margin | Verdicts |\n` +
    `| --- | ---: | ---: | ---: | ---: | ---: |`;
  if (map.size === 0) return `${header}\n| _(none)_ |  |  |  |  |  |`;
  const rows = [...map.entries()].map(([k, t]) => tallyRow(k, t));
  return [header, ...rows].join("\n");
}

function renderDeterministicTable(det) {
  const lib = rate(det.library.pass, det.library.runs);
  const base = rate(det.baseline.pass, det.baseline.runs);
  const delta = lib - base;
  const sign = delta > 0 ? "+" : delta < 0 ? "−" : "±";
  const deltaCell = `${sign}${pct(Math.abs(delta))}`;
  return [
    "| Arm | Pass-rate | Passed | Runs |",
    "| --- | ---: | ---: | ---: |",
    `| library | ${pct(lib)} | ${det.library.pass} | ${det.library.runs} |`,
    `| baseline | ${pct(base)} | ${det.baseline.pass} | ${det.baseline.runs} |`,
    "",
    "Library − baseline pass-rate delta: " + `**${deltaCell}**`,
  ].join("\n");
}

function fillTemplate(template, tokens) {
  // Drop leading HTML comment blocks (the template's own token docs) so their
  // {{TOKEN}} examples don't get substituted into the rendered report.
  const body = template.replace(/^\s*<!--[\s\S]*?-->\s*/g, "");
  return body.replace(/\{\{([A-Z_]+)\}\}/g, (_, name) =>
    Object.prototype.hasOwnProperty.call(tokens, name) ? String(tokens[name]) : "",
  );
}

function renderReport(agg, sourcePath) {
  let template;
  try {
    template = readFileSync(TEMPLATE_PATH, "utf8");
  } catch (err) {
    die(`cannot read report template at ${TEMPLATE_PATH}: ${err.message}`);
  }
  return fillTemplate(template, {
    GENERATED_AT: new Date().toISOString(),
    SOURCE: sourcePath,
    RUN_COUNT: agg.runCount,
    FIXTURE_COUNT: agg.fixtures.size,
    PER_DIMENSION_TABLE: renderWinTable("Dimension", agg.perDimension),
    PER_OUTPUT_TYPE_TABLE: renderWinTable("Output type", agg.perOutputType),
    DETERMINISTIC_TABLE: renderDeterministicTable(agg.det),
  });
}

// --- IO --------------------------------------------------------------------

function readRecords(path) {
  let raw;
  try {
    raw = readFileSync(path, "utf8");
  } catch (err) {
    die(`cannot read ${path}: ${err.message}`);
  }
  const records = [];
  const lines = raw.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
    if (line === "") continue;
    let rec;
    try {
      rec = JSON.parse(line);
    } catch (err) {
      die(`line ${i + 1}: invalid JSON — ${err.message}`);
    }
    records.push([i + 1, rec]);
  }
  if (records.length === 0) die(`no result records found in ${path}`);
  return records;
}

function main() {
  const { input, out } = parseArgs(process.argv.slice(2));
  const records = readRecords(input);
  let agg;
  try {
    agg = aggregate(records);
  } catch (err) {
    die(err.message);
  }
  const report = renderReport(agg, input);
  if (out) {
    // Write synchronously so a failure routes through die() (exit 2) like every
    // other error path — a floating promise here would reject AFTER main()
    // returned, escaping the exit-2 convention.
    try {
      writeFileSync(out, report);
    } catch (err) {
      die(`cannot write ${out}: ${err.message}`);
    }
    process.stderr.write(`aggregate: wrote ${out}\n`);
  } else {
    process.stdout.write(report);
  }
}

main();
