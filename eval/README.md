# eval/ — comparative library-effectiveness harness

Proves whether this library produces **better outcomes than not using it**, locally, on
demand. For each fixture the harness runs the same task through two arms — **library-ON**
(a specialist agent) and **library-OFF baseline** (a
vanilla `general-purpose` agent told to use no skills/subagents) — applies a Tier-0
deterministic check to each, then a **blind pairwise judge panel** picks a per-dimension
winner. The output is a per-dimension × output-type comparison report.

## Run it

```
/eval-harness                 # run the whole corpus
/eval-harness <fixture-id>... # run only named fixtures
```

The command reads the fixtures, runs the `eval-harness` workflow, writes results to
`eval/results/<runId>.jsonl`, and renders `eval/results/report-<runId>.md` via the
aggregator. **Cost:** each fixture = 2 produce + 2 check + 3 judge dispatches. Run a
single fixture first if cost-sensitive.

To exercise the `cargo-test` checker you must opt in (it compiles/runs model-generated
code — see Security): `EVAL_ALLOW_CODE_EXEC=1 /eval-harness code-slugify-rust`.

## How it fits together

| Piece | File | Role |
|---|---|---|
| Contract | `schema/fixture.schema.json`, `schema/result.schema.json` | input/output shapes |
| Fixtures | `fixtures/*.json` | two-arm cases across output types |
| Checkers | `checkers/run-checker.sh <kind> <artifact>` | Tier-0 deterministic gate (0 PASS / 1 FAIL / 2 skip) |
| Judge | `judge/pairwise-judge-protocol.md`, `judge/judge-output.schema.json` | blind pairwise panel protocol |
| Runner | `eval-harness.js` (workflow) + `.claude/commands/eval-harness.md` | produce → check → judge → record |
| Aggregator | `aggregate/aggregate.mjs` | de-blinds and renders the report |

## Reading the report

Three tables: **per-dimension** and **per-output-type** library/baseline/tie win-rates +
mean margin, and a **deterministic pass-rate** table with the library−baseline delta.
There is no single pass/fail verdict — it's a breakdown you read to decide adoption.
Judge verdicts are recorded blind (`A`/`B`); the aggregator de-blinds via each record's
`blinding_map`.

## Add a fixture

Copy an existing `fixtures/*.json`, set a distinct `id`/`output_type`, both `arms`
(baseline is always `general-purpose` with a no-skills prompt), a `deterministic_check.kind`
from `{validate-library-artifact, cargo-test, schema-match}`, and a typed `rubric`. Validate
against `schema/fixture.schema.json` (Node + ajv). Add a checker under `checkers/` if a new
`kind` is needed.

## Known limitations

- **Baseline fidelity** — "library OFF" is instruction-suppressed, not a hard sandbox; the
  vanilla agent still has general capability. The harness measures the value of the
  library's *specialization + collaboration structure*, not raw model access.
- **Judge stochasticity** — the panel (N=3, position-randomized, majority/median,
  default-reject) reduces but does not remove variance; trust the *trend*, not one run.
- **Code execution** — `check-code-compiles.sh` runs untrusted model code; it is opt-in
  (`EVAL_ALLOW_CODE_EXEC=1`) with best-effort containment (offline, throwaway CARGO_HOME,
  timeout). Full isolation needs an OS sandbox.
