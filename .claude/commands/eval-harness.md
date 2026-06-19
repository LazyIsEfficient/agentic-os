---
description: Run the comparative eval harness over one or more fixtures — produce both arms, run the Tier-0 checker on each, run a blind pairwise judge panel, then materialize results and an aggregated report.
argument-hint: "[fixture-id ...] (empty = run every fixture in eval/fixtures/)"
allowed-tools: Workflow, Read, Write, Bash
---

You are running the **eval-harness** comparative evaluation. It takes two-arm
fixtures (library-ON vs library-OFF baseline), produces both arms, applies the
Tier-0 deterministic checker to each, runs a blind position-randomized pairwise
judge panel, and writes a results JSONL plus an aggregated Markdown report.

This spends **real subscription tokens**. Per fixture the workflow dispatches
**2 produce + 2 check + 3 judge** subagent turns (7 minimum). State the rough
cost to the user before launching, especially when running the whole corpus.

## Step 1 — resolve which fixtures to run

List the fixture files:

```
ls -1 eval/fixtures/*.json
```

- If `$ARGUMENTS` is **empty**, run **every** fixture in `eval/fixtures/`.
- Otherwise treat each token in `$ARGUMENTS` as a fixture **id** (the filename
  stem) and run only those. For each requested id, the file is
  `eval/fixtures/<id>.json`; if any requested id has no matching file, STOP and
  tell the user which ids were not found — do not silently drop them.

`Read` each selected fixture file and parse it as a JSON **object**. Collect the
parsed objects into an array (the workflow sandbox has no filesystem access — it
relies on you having read the fixtures for it).

## Step 2 — run the workflow

Pick a short **runId** matching `^[a-z0-9-]+$` (e.g. a date + short tag like
`2026-06-18-a`). Then invoke the **Workflow** tool:

- `name: "eval-harness"`
- `args: { fixtures: [<the parsed fixture objects>], runId: "<runId>", judges: 3 }`

The workflow returns an **array of result objects**, one per fixture, each
conforming to `eval/schema/result.schema.json`.

## Step 3 — materialize the results JSONL (sanitize the runId)

The result keys come from the workflow, but the **filename** is yours to build —
sanitize the runId before it touches a path. **Reject** the runId (STOP, do not
write) if it does not match `^[a-z0-9-]+$`. Never interpolate an unsanitized
runId into a path.

Write the returned result objects **one JSON object per line** to:

```
eval/results/<runId>.jsonl
```

Before writing each line, confirm it serializes to valid JSON (one object per
line, no trailing commas, no pretty-printing). One line per fixture result.

## Step 4 — aggregate and show the report

Run the aggregator (Node ESM, zero deps, no Python):

```
node eval/aggregate/aggregate.mjs eval/results/<runId>.jsonl --out eval/results/report-<runId>.md
```

Then `Read` `eval/results/report-<runId>.md` and show it to the user. The
aggregator de-blinds every judge verdict through each record's `blinding_map`,
so the report is in arm terms (library / baseline) even though the judges were
blind.

## Step 5 — report which arm won

Summarize from the report:

- The per-arm **Tier-0 deterministic pass-rates** and the
  **library − baseline** delta.
- The per-dimension and per-output-type **judge win-rates** (library vs baseline
  vs tie), and which arm came out ahead overall.
- Name the two files written: `eval/results/<runId>.jsonl` and
  `eval/results/report-<runId>.md`.

Keep it tight: which arm won on the deterministic spine, which won on the
judged dimensions, and where they tied. The judge layer is **Tier-2** —
informs, never gates; only the deterministic checker is a hard verdict.
