# Eval contract — fixture + result schemas

This is the spine of the comparative eval harness. Every downstream task binds to the two
schemas here:

- [`schema/fixture.schema.json`](schema/fixture.schema.json) — the **input** contract: one
  comparative eval case.
- [`schema/result.schema.json`](schema/result.schema.json) — the **output** contract: one
  fixture's run result.

Both are JSON Schema **draft 2020-12** and validate against the meta-schema. Per the workflow
constraint, **neither schema uses `allOf` / `oneOf` / `anyOf` at the top level** (composition,
where present, lives inside `$defs`).

## What the harness does (why the contract is shaped this way)

Each fixture runs through **two arms**:

- **`library`** (library-ON) — a specialist agent or an auto-composed `v2-collab` pod, with the
  full skills + subagents library available.
- **`baseline`** (library-OFF) — a vanilla `general-purpose` agent explicitly instructed to use
  **no** skills, subagents, or workflows.

Both artifacts get the **same Tier-0 deterministic check** (the only tier that may gate). Then a
**blind, position-randomized pairwise judge panel** (N judges) labels the two artifacts as
neutral `A` / `B` and picks a **per-dimension winner + margin** plus an overall winner. The
`blinding_map` records which label was which arm so results can be de-blinded for audit — the
judges never see it.

---

## Fixture schema

A fixture is a single object with these top-level fields:

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string (kebab-case) | Stable id; also the filename stem and the join key into results. |
| `description` | string | One line: the capability this fixture probes. |
| `task` | string | The verbatim instruction handed to **both** arms. |
| `output_type` | enum | `library-skill` \| `code` \| `claims-doc` \| `pod-deliverable`. Drives checker choice and report bucketing. |
| `arms` | object | `{ library, baseline }`, each an **arm** (below). Both required. |
| `deterministic_check` | object | `{ kind, tier:0, gates }` (+ optional `spec`). Applied identically to both arms. |
| `rubric` | object | `{ dimensions: [...] }` (+ optional `note`). The judge's per-dimension axes. |

An **arm** = `{ kind, agentType?, prompt?, note? }`:

- `kind` — `agent` (dispatch one named agent) or `pod` (run a `v2-collab` pod).
- `agentType` — for `kind: agent`, the agent to dispatch (`engineer` for library-ON,
  `general-purpose` for baseline). Omit for `kind: pod`.
- `prompt` — optional arm-specific instruction prepended to the shared `task`. The baseline arm
  uses this to forbid skills/subagents.
- `note` — maintainer rationale; **not** handed to the producer.

A **dimension** = `{ key, max, asks }`:

- `key` — snake_case id; the join key into the judge's `per_dimension` output.
- `max` — max points; used to normalize margins.
- `asks` — the concrete discriminating question the judge answers for this axis.

### `deterministic_check`

| Field | Type | Notes |
| --- | --- | --- |
| `kind` | string | Checker id the runner dispatches (`validate.sh`, `cargo-test`, `schema-match`, …); resolves to a checker in `eval/checkers/`. |
| `tier` | const `0` | Deterministic checks are Tier 0 — the only tier permitted to gate. |
| `gates` | boolean | Whether a deterministic failure disqualifies the arm. The report still records both arms' pass/fail regardless. |
| `spec` | string (optional) | Human-readable staging + PASS description. |

### Filled fixture example

This is the worked reference fixture, [`fixtures/skill-authoring-slugify.json`](fixtures/skill-authoring-slugify.json):

```json
{
  "id": "skill-authoring-slugify",
  "description": "Library can author a small, well-formed, well-routed library skill from a one-line ask.",
  "task": "Author a minimal library skill `slugify-text` (a single SKILL.md, no reference files) that documents how to convert arbitrary text into a URL-safe slug: lowercase, replace runs of non-alphanumerics with a single hyphen, trim leading/trailing hyphens. The skill teaches the technique and when to reach for it; it is not code to execute.",
  "output_type": "library-skill",
  "arms": {
    "library": {
      "kind": "agent",
      "agentType": "engineer",
      "note": "Library-ON. Pluggable: the harness can swap this for a v2-collab pod (kind=pod) to measure the pod's output quality instead of a single agent's."
    },
    "baseline": {
      "kind": "agent",
      "agentType": "general-purpose",
      "prompt": "Author the SKILL.md directly from your own knowledge. Do NOT read, load, or invoke any library skills. Do NOT dispatch subagents or use any /-commands or workflows. Produce the file yourself in this turn.",
      "note": "Library-OFF baseline. Instruction-suppressed: a vanilla agent told to use none of the library's machinery."
    }
  },
  "deterministic_check": {
    "kind": "validate.sh",
    "tier": 0,
    "gates": true,
    "spec": "Stage the produced SKILL.md into a copy of the live .claude tree at <stage>/.claude/skills/slugify-text/SKILL.md, then run `bash scripts/validate.sh <stage>`. PASS iff exit code 0. This is the Tier-0 spine — it GATES."
  },
  "rubric": {
    "note": "Tier-2 judge layer — INFORMS only, never gates. Pairwise per-dimension winner+margin; default-reject posture (judge conservatively when evidence for a dimension is weak).",
    "dimensions": [
      { "key": "frontmatter_quality", "max": 25, "asks": "name matches; description carries concrete triggers AND 'For X see Y' cross-refs; tools allowlist coherent for a teaching skill." },
      { "key": "routing_clarity", "max": 25, "asks": "Unambiguous when-to-use and not-when; a router could pick this correctly and reject look-alikes. No vague trigger soup." },
      { "key": "body_actionability", "max": 25, "asks": "Concrete, usable guidance (the actual slugify steps, edge cases) vs generic filler an LLM could emit about anything." },
      { "key": "single_responsibility", "max": 25, "asks": "Focused on slugify; no scope creep into unrelated string ops, i18n essays, or code dumps." }
    ]
  }
}
```

---

## Result schema

One result object per fixture run; the runner appends one per line to a results JSONL.

| Field | Type | Notes |
| --- | --- | --- |
| `fixture` | string (kebab-case) | Fixture id; joins back to the fixture. |
| `run` | string | Run id — distinguishes repeated runs (timestamp or corpus-run id). |
| `output_type` | enum | Copied from the fixture so the aggregator buckets without re-reading fixtures. |
| `commit` | string (optional) | Git commit the run was produced against. |
| `ts` | string (optional) | ISO-8601 `date-time` of the run. |
| `deterministic` | object | `{ library, baseline }`, each `{ pass, check?, note? }`. Recorded for **both** arms even when the check gates one out. |
| `judge` | object | The blind pairwise panel output (below). |
| `blinding_map` | object | `{ A, B }`, each `library` \| `baseline`. The audit record of which label was which arm this run. |

The **`judge`** block:

| Field | Type | Notes |
| --- | --- | --- |
| `per_dimension` | array | One aggregated verdict per rubric dimension: `{ dimension, winner, margin }`. |
| `overall` | object | Panel-aggregated `{ winner, margin }` across dimensions. |
| `panel_votes` | integer ≥ 1 | Number of independent judges (e.g. 3); aggregation is median/majority over them. |

A **verdict** (`per_dimension[*]` and `overall`):

- `winner` — `A` \| `B` \| `tie`. Blind A/B terms; de-blind via `blinding_map`. Ties are
  **recorded, never broken**.
- `margin` — number `0..1`, normalized strength of the win; `0` for a tie.

`per_dimension[*]` additionally carries `dimension` (the rubric `key` it scores).

### Filled result example

A result for the slugify fixture (the same shape the runner's recorder emits as one JSONL line):

```json
{
  "fixture": "skill-authoring-slugify",
  "run": "2026-06-18T18:52:36Z",
  "output_type": "library-skill",
  "commit": "36c844b",
  "ts": "2026-06-18T18:52:36Z",
  "deterministic": {
    "library": { "pass": true, "check": "validate.sh" },
    "baseline": { "pass": true, "check": "validate.sh", "note": "frontmatter present; routing thin" }
  },
  "judge": {
    "panel_votes": 3,
    "per_dimension": [
      { "dimension": "frontmatter_quality", "winner": "A", "margin": 0.33 },
      { "dimension": "routing_clarity", "winner": "A", "margin": 0.5 },
      { "dimension": "body_actionability", "winner": "tie", "margin": 0 },
      { "dimension": "single_responsibility", "winner": "B", "margin": 0.17 }
    ],
    "overall": { "winner": "A", "margin": 0.28 }
  },
  "blinding_map": { "A": "library", "B": "baseline" }
}
```

De-blinding via `blinding_map`: `A` = `library`, `B` = `baseline`. So the library arm won
frontmatter and routing, tied on body actionability, and lost single-responsibility to the
baseline — overall a 0.28-margin library win.

---

## Validating

There is no `package.json` in this repo; validate from a scratch dir using `ajv` (Node only —
this repo forbids Python). The 2020-12 meta-schema ships with `ajv/dist/2020`:

```bash
mkdir -p /tmp/eval-validate && cd /tmp/eval-validate
npm install ajv@8 ajv-formats
node --input-type=module -e '
import Ajv2020 from "ajv/dist/2020.js";
import addFormats from "ajv-formats";
import { readFileSync } from "node:fs";
const R = "/path/to/skills-db/eval";
const j = p => JSON.parse(readFileSync(p, "utf8"));
const ajv = new Ajv2020({ allErrors: true, strict: true });
addFormats(ajv);
const fx = ajv.compile(j(`${R}/schema/fixture.schema.json`));   // self-validates
ajv.compile(j(`${R}/schema/result.schema.json`));               // self-validates
if (!fx(j(`${R}/fixtures/skill-authoring-slugify.json`))) throw fx.errors;
console.log("ok");
'
```
