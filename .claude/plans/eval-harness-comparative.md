# Plan — Comparative eval harness (library ON vs OFF)

**Status:** in-progress

<!-- DONE: T-eval-schema (✓CP-contract), T-fixtures, T-checkers, T-judge, T-aggregator,
     T-runner, T-readme. Wave 1 passed code+security review; 3 Tier-0 security findings
     (untrusted cargo exec, symlink staging escape, slug path injection) fixed + verified.
     ✓CP-integration PASSED: ran skill-authoring-slugify end-to-end (eval/results/cp-int.jsonl,
     report-cp-int.md) — deterministic library +100%, judge thin/baseline-leaning on 1 fixture.
     REMAINING: T-corpus-run — the full 5-fixture proof run. Blocked live by the new-workflow
     registration gotcha (eval-harness not invokable by `name` until session reload); runs via
     scriptPath or, after reload, `/eval-harness`. Pinned sub-contract: checker kinds =
     validate-library-artifact | cargo-test | schema-match via eval/checkers/run-checker.sh. -->


Local, re-runnable harness that proves whether this library produces better outcomes than
not using it. Per fixture: produce BOTH arms (library-ON specialist/pod, library-OFF vanilla
agent) → Tier-0 deterministic check on both → blind position-randomized pairwise judge panel
(N=3, median, default-reject, per-dimension winner+margin) → aggregate into a per-dimension ×
output-type comparison report. All under `eval/`. No CI. Builds on the existing prototype.

## Execution DAG

```
T-eval-schema → ✓CP-contract → ( T-fixtures || T-checkers || T-judge || T-aggregator )
              → T-runner → ✓CP-integration → ( T-readme || T-corpus-run )
```

- Day-zero ready set: `T-eval-schema` (depends_on []).
- `✓CP-contract` — the fixture/result contract is frozen before the middle fans out.
- `✓CP-integration` — the runner works end-to-end on ONE fixture before the full corpus run.

---

## T-eval-schema — shared fixture + result contract (the spine)

```yaml
id: T-eval-schema
depends_on: []
parallel_safe: false
conflicts_with: []
files_write:
  - eval/SCHEMA.md
  - eval/schema/fixture.schema.json
  - eval/schema/result.schema.json
  - eval/fixtures/skill-authoring-slugify.json
files_read:
  - eval/fixtures/skill-authoring-slugify.json
  - eval/results/skill-authoring-slugify.jsonl
branch_suffix: eval-schema
scope: S
```

Define the contract everything else binds to. `fixture.schema.json`: id, description, task,
output_type, **two arms** (`library` and `baseline`, each `{ kind, agentType|prompt, note }`),
`deterministic_check` (`{ kind, tier, gates }`), and a typed `rubric` (dimensions + max).
`result.schema.json`: per fixture+run — each arm's deterministic `{pass}`, the blind pairwise
judge output (`per_dimension: {winner: A|B|tie, margin}`, `overall`, panel votes), and the
**arm↔label blinding map** recorded for audit. Upgrade the existing `skill-authoring-slugify`
fixture to the two-arm shape as the worked reference example. `SCHEMA.md` documents both with
one filled example each.

- **Acceptance:** both JSON Schemas validate against themselves; the upgraded fixture conforms;
  SCHEMA.md shows a filled fixture + a filled result.
- **Verification:** `node -e` (or a JSON-schema validator) asserts the upgraded fixture passes
  `fixture.schema.json`; no other `eval/fixtures/*.json` touched.

---

## T-fixtures — the 4–6 two-arm fixture corpus

```yaml
id: T-fixtures
depends_on: [T-eval-schema]
parallel_safe: true
conflicts_with: []
files_write:
  - eval/fixtures/code-slugify-rust.json
  - eval/fixtures/claims-drop-rate-ev.json
  - eval/fixtures/pod-deliverable-page.json
  - eval/fixtures/skill-routing-cache.json
files_read:
  - eval/schema/fixture.schema.json
  - eval/SCHEMA.md
branch_suffix: eval-fixtures
scope: M
```

Author 4 NET-NEW fixtures (with the upgraded slugify one → 5 total) spanning output types:
**code+compile** (a small Rust util — `cargo test` is the deterministic check; honors the
no-Python rule), **claims doc** (an EV-derivation + simulation, checker = structural, gate =
adversarial judge), **pod deliverable** (a small web page/spec via `v2-collab`), **library
skill** (a second skill-authoring task). Each declares both arms, the deterministic check, and
a per-dimension rubric. Does NOT touch `skill-authoring-slugify.json`.

- **Acceptance:** every new fixture validates against `fixture.schema.json`; each names a
  distinct `output_type` and a checker that exists (or is specified for T-checkers).
- **Verification:** schema-validate all `eval/fixtures/*.json`; confirm ≥4 distinct output types.

---

## T-checkers — per-output-type deterministic checkers (Tier 0)

```yaml
id: T-checkers
depends_on: [T-eval-schema]
parallel_safe: true
conflicts_with: []
files_write:
  - eval/checkers/check-library-artifact.sh
  - eval/checkers/check-code-compiles.sh
  - eval/checkers/check-schema-match.sh
  - eval/checkers/README.md
files_read:
  - eval/schema/fixture.schema.json
  - scripts/validate.sh
branch_suffix: eval-checkers
scope: M
```

A small library of deterministic checkers, each a script taking `(artifact_dir)` and exiting
0/1 with a one-line verdict on stdout — a uniform CLI contract the runner calls for either arm.
`check-library-artifact.sh` stages the artifact into a copy of `.claude` and runs `validate.sh`
(the prototype's proven approach). `check-code-compiles.sh` runs `cargo test` (or `rustc`).
`check-schema-match.sh` asserts required sections/structure via grep/jq. README documents the
contract so new checkers slot in.

- **Acceptance:** each checker exits 0 on a known-good sample and 1 on a known-bad one.
- **Verification:** run each checker against a tiny inline good/bad pair; assert exit codes.

---

## T-judge — blind pairwise judge protocol (Tier 2, informs)

```yaml
id: T-judge
depends_on: [T-eval-schema]
parallel_safe: true
conflicts_with: []
files_write:
  - eval/judge/pairwise-judge-protocol.md
  - eval/judge/judge-output.schema.json
files_read:
  - eval/schema/result.schema.json
branch_suffix: eval-judge
scope: M
```

The blind pairwise judge the runner dispatches. `pairwise-judge-protocol.md`: the prompt
template (neutral "Output A / Output B", per-dimension winner + margin, overall, default-reject
posture, must-quote-evidence) plus the **panel aggregation rule** (N=3, position randomized per
judge, median/majority per dimension, ties recorded not broken). `judge-output.schema.json`: the
StructuredOutput shape one judge returns (binds to `result.schema.json`'s judge block).

- **Acceptance:** protocol fully specifies blinding, panel size, aggregation, and tie handling;
  the output schema is a flat object (no top-level allOf/oneOf/anyOf — workflow constraint).
- **Verification:** schema self-validates; protocol names blinding + randomization explicitly.

---

## T-aggregator — results → per-dimension × output-type report

```yaml
id: T-aggregator
depends_on: [T-eval-schema]
parallel_safe: true
conflicts_with: []
files_write:
  - eval/aggregate/aggregate.mjs
  - eval/aggregate/report-template.md
files_read:
  - eval/schema/result.schema.json
branch_suffix: eval-aggregate
scope: M
```

`aggregate.mjs` (Node — no Python) reads a results JSONL and emits the comparison report:
per-dimension AND per-output-type, library-vs-baseline **pairwise win-rate + mean margin**, plus
**deterministic-pass-rate delta** per arm. No single pass/fail verdict — a legible breakdown
table. `report-template.md` is the Markdown skeleton it fills.

- **Acceptance:** given a hand-authored sample results JSONL, `node aggregate.mjs` emits a
  Markdown table with a row per (dimension) and per (output_type) and both arms' numbers.
- **Verification:** run it on a 2-fixture sample JSONL; assert the table has the expected rows.

---

## ✓CP-contract — contract frozen
Barrier: `T-eval-schema` complete and reviewed before `T-fixtures || T-checkers || T-judge ||
T-aggregator` dispatch. The four middle tasks bind to the schema; a late contract change forces
rework across all four.

---

## T-runner — the eval-harness Workflow (integration)

```yaml
id: T-runner
depends_on: [T-fixtures, T-checkers, T-judge, T-aggregator]
parallel_safe: false
conflicts_with: []
files_write:
  - eval/eval-harness.js
  - .claude/commands/eval-harness.md
files_read:
  - eval/schema/fixture.schema.json
  - eval/schema/result.schema.json
  - eval/judge/pairwise-judge-protocol.md
  - .claude/workflows/v2-collab.js
branch_suffix: eval-runner
scope: M
```

The local runner as a Workflow: `pipeline(fixtures, produceBothArms, checkBoth, blindJudgePanel,
record)`. Library arm dispatches the specialist agent / `v2-collab` pod; baseline arm dispatches
a `general-purpose` agent instructed to use no skills/subagents. Sub-agents do the FS work
(stage + run checkers — the workflow sandbox can't). Returns structured results; the
`eval-harness.md` command materializes the results JSONL + invokes `aggregate.mjs` for the
report (path-sanitized, mirrors the v2-collab materialize pattern).

- **Acceptance:** running the workflow on ONE fixture produces both arms, both deterministic
  verdicts, a blind panel comparison, and a recorded result line.
- **Verification:** dispatch on `skill-authoring-slugify` only; inspect the result JSONL line
  for both arms + judge block + blinding map.

---

## ✓CP-integration — runner proven on one fixture
Barrier: `T-runner` produces a valid single-fixture result (both arms, check, blind judge,
record) before the full corpus run. Catches wiring bugs before spending the full corpus's tokens.

---

## T-readme — operator docs

```yaml
id: T-readme
depends_on: [T-runner]
parallel_safe: true
conflicts_with: []
files_write:
  - eval/README.md
files_read:
  - eval/eval-harness.js
  - .claude/commands/eval-harness.md
  - eval/aggregate/aggregate.mjs
branch_suffix: eval-readme
scope: S
```

How to run locally, how to read the report, how to add a fixture/checker, and the known
limitation (instruction-suppressed baseline, judge-blinding caveats).

- **Acceptance:** a reader can run the harness and add a fixture from the README alone.
- **Verification:** the documented invocation matches the actual command/workflow interface.

---

## T-corpus-run — first full comparison report (execution, not code)

```yaml
id: T-corpus-run
depends_on: [T-runner]
parallel_safe: true
conflicts_with: []
files_write:
  - eval/results/corpus-run.jsonl
  - eval/results/report-corpus.md
files_read:
  - eval/eval-harness.js
  - eval/aggregate/aggregate.mjs
branch_suffix: eval-corpus-run
scope: M
```

Run the full 4–6 fixture corpus once; produce the first real library-vs-baseline comparison
report. Token-heavy but mechanical. THIS is the proof artifact the stakeholder reads.

- **Acceptance:** a report exists covering every fixture, both arms, per-dimension and
  per-output-type, with the blinding map auditable in the JSONL.
- **Verification:** every corpus fixture appears in the JSONL with both arms; report renders.

---

## Verification checklist
- [x] Status line present (`proposed`)
- [x] Stable slug IDs
- [x] Every task has acceptance + verification
- [x] Every task declares depends_on / parallel_safe / files_write
- [x] No files_write overlap → no conflicts_with needed (disjoint dirs/files)
- [x] Day-zero ready set non-empty (`T-eval-schema`)
- [x] No `scope: L`; no task > 5 files
- [x] DAG matches per-task depends_on; checkpoints placed between phases
- [ ] Human approval
```
