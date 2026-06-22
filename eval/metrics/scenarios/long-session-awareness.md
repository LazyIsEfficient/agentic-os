# Long-session awareness scenario — batch metrics runner

Designed multi-step scenario for issue #147. A fact established early must be used
correctly **after** at least one compaction boundary. Same scripted prompt sequence for
both arms; only the awareness harness differs (ON vs OFF).

**Protocol:** [AB-PROTOCOL.md](../AB-PROTOCOL.md) · **Pre-register before runs:**
`bash ../pre-register.sh long-session-awareness`

---

## Goal

Extend `eval/metrics/` with a small **batch runner** that compares N ON/OFF transcript
pairs and reports **distribution** statistics (median + spread), not a single delta.
The late step is the probe: it requires three anchor facts recorded early. Losing them
after compaction forces re-work (re-survey, re-read) or produces wrong output.

## Anchor facts (record via `/state` before prompt 1)

Record all three in `SESSION-STATE.md` on the **ON arm only** before the scripted
sequence. The operator reads them aloud on the OFF arm is wrong — on OFF, do **not**
use `/state`; let the model discover facts in prompts 1–2 only.

| Kind | Fact | Why it matters late |
|---|---|---|
| **Constraint** | OFF arm baseline is `claude --settings '{"hooks":{}}'` — **never** `--bare` (also strips LSP/plugins and confounds the comparison). | Prompt 10 docs must cite the correct OFF invocation. |
| **Decision** | All new code in this scenario lives under `eval/metrics/` only; do **not** modify `.claude/hooks/` or `.cursor/hooks/`. | Prompt 9 must not touch hook files. |
| **Infra** | Self-tests for this package run via `bash session-metrics-test.sh && bash compare-test.sh` — do not invent a new runner or npm script. | Prompt 8 wiring must call these exact scripts. |

**Expected late values (manual judge):**

- OFF baseline documented as `'{"hooks":{}}'`, not `--bare`.
- No edits under `.claude/hooks/` or `.cursor/hooks/`.
- Test instructions reference `session-metrics-test.sh` and `compare-test.sh`.

## Prerequisites

- Clean git checkout at a fixed commit (record SHA in pre-registration).
- `node`, `claude` CLI, repo hooks registered in `.claude/settings.json` (ON arm).
- Operator budget for **N ≥ 3** full sessions **per arm** (6+ interactive runs total).
- Compaction: prefer **auto-compaction**; if using manual `/compact`, note it in the
  run log (not identical to auto).

## Scripted prompt sequence

Paste **one prompt at a time**. Wait for the agent to finish each step before sending
the next. Do not paraphrase — wording is part of the control.

### Phase A — establish + fill context (prompts 1–6)

**1 — Survey**

```
Survey eval/metrics/ and summarize: session-metrics.mjs, compare.mjs, run-arms.sh,
the two self-test scripts, and fixtures/. Do not implement anything yet.
```

**2 — Record constraints**

```
We are adding a batch runner under eval/metrics/ only. Record these constraints for
the rest of this session: (a) OFF arm baseline is claude --settings '{"hooks":{}}',
never --bare; (b) do not modify .claude/hooks/ or .cursor/hooks/; (c) self-tests are
bash session-metrics-test.sh && bash compare-test.sh. Confirm you have captured them.
```

*(ON arm: agent should invoke `/state` or the session-state writer. OFF arm: fact lives
only in chat until compaction.)*

**3 — Design stub**

```
Design batch-compare.mjs: accepts multiple ON/OFF jsonl path pairs, runs compare.mjs
logic for each, outputs JSON lines per pair. Write the design as comments only — no
implementation yet.
```

**4 — Refactor compare**

```
Refactor compare.mjs so the core diff logic is exported and reusable by batch-compare.mjs.
Keep CLI behavior identical. Run compare-test.sh when done.
```

**5 — Implement batch**

```
Implement eval/metrics/batch-compare.mjs per your design. Add at least one fixture pair
test to compare-test.sh or a sibling batch-compare-test.sh. Run the self-tests.
```

**6 — README draft**

```
Add a "Batch comparison" subsection to eval/metrics/README.md documenting
batch-compare.mjs usage with a two-pair example. Do not document run-arms.sh OFF arm
invocation yet — that comes later.
```

### Phase B — cross compaction (prompts 7–8)

*Continue until auto-compaction fires, or run `/compact` here if context is not yet
trimmed (log which).*

**7 — Metrics review**

```
Read session-metrics.mjs and list which awareness signals are Tier-0 mechanical vs
Tier-2 judgement. Propose one small improvement (comment or doc only) — no hook changes.
```

**8 — Wire self-tests**

```
Ensure batch-compare.mjs is invoked by the self-test scripts exactly as: bash
session-metrics-test.sh && bash compare-test.sh (extend compare-test.sh if needed).
Show the exact commands you ran.
```

### Phase C — late probe (prompts 9–10)

**9 — Operator checklist (PROBE: decision + infra)**

```
Add eval/metrics/BATCH-OPERATOR.md: step-by-step for an operator running N ON/OFF
pairs. Must include: how to capture transcripts from ~/.claude/projects/, how to run
batch-compare.mjs on a directory of pairs, and the exact self-test commands to verify
the package. Do not modify any hook scripts.
```

**10 — OFF arm documentation (PROBE: constraint)**

```
In BATCH-OPERATOR.md, add an "Arms" section that states the exact claude invocations
for ON arm (--settings .claude/settings.json) and OFF arm. The OFF baseline must match
our settled constraint from step 2.
```

## Scoring each run pair

After both arms complete the sequence:

```bash
node eval/metrics/compare.mjs <on-session>.jsonl <off-session>.jsonl --json
```

Record per pair:

| Signal | Source |
|---|---|
| `output_tokens` delta | `compare.mjs` (Claude Code transcripts) |
| `repeat_read_files` delta | post-compaction region — eyeball transcript |
| `repeated_tool_calls` delta | post-compaction region |
| Anchor-fact correctness | Manual vs expected late values above |

Aggregate **N pairs** — median and range for each metric. Never report one pair alone.

Example aggregation (after N runs):

```bash
# hypothetical: collect compare --json outputs into results.jsonl, then:
node -e '
const rows = require("fs").readFileSync("results.jsonl","utf8").trim().split("\n").map(JSON.parse);
const med = (k) => { const v = rows.map(r=>r.delta[k].abs).sort((a,b)=>a-b); return v[Math.floor(v.length/2)]; };
console.log({ n: rows.length, median_delta: { output_tokens: med("output_tokens"), repeat_read_files: med("repeat_read_files") } });
'
```

---

## Pre-registration interpretation template

**Copy into your hypothesis file** (`eval/metrics/runs/<date>-long-session-awareness/hypothesis.md`)
via `pre-register.sh` **before** reading any transcripts or running `compare.mjs`.

```markdown
# Pre-registration — long-session-awareness

- **Date / operator:**
- **Repo SHA:**
- **N per arm:**
- **Compaction trigger:** auto | manual `/compact` at prompt __
- **Scenario:** eval/metrics/scenarios/long-session-awareness.md

## Null prior (from effectiveness investigation)

[eval/INVESTIGATION.md](../../INVESTIGATION.md) found **null** on tractable single-task
work — the library did not measurably improve correctness where the base model already
one-shotted. For awareness, the analogous prior is: **compaction-boundary benefit is
not guaranteed**; re-work signals may not differ beyond noise. Pre-register to avoid
motivated reading.

## What would CONFIRM harness benefit

- Across **≥ N/2 pairs**, ON arm shows **lower** post-compaction `repeat_read_files`
  and/or `repeated_tool_calls` vs OFF (consistent direction, not one outlier).
- ON **anchor-fact correctness** on prompts 9–10: all three facts used without
  re-deriving wrong values (no `--bare`, no hook edits, correct self-test commands).
- ON `output_tokens` **not worse** than OFF median (benefit − tax ≥ 0 on tokens).

## What would DISPROVE / null

- **NULL:** metric deltas swing sign across pairs; anchor facts sometimes wrong on
  **both** arms; no consistent post-compaction re-work difference.
- **COST-DOMINATED:** ON consistently higher tokens/re-work with no anchor advantage.

## Decision rule (fill before runs)

| Outcome | Condition |
|---|---|
| BENEFIT CONFIRMED | ≥ 2 of 3 confirm signals above, ≤ 1 pair contradicts |
| NULL | No consistent direction on re-work; anchor correctness ties or noise |
| COST-DOMINATED | ON worse on tokens AND no re-work reduction |

## Post-run (do not edit pre-registration)

- Verdict: ___
- Median deltas: ___
- Anchor notes: ___
```

---

## What success looks like (ON vs OFF)

| Observation | ON arm (hooks) | OFF arm (no hooks) |
|---|---|---|
| After compaction | `SESSION-STATE.md` re-injected; anchor facts available | Facts only in compacted-away chat |
| Prompt 10 | Documents `'{"hooks":{}}'` from state | May revert to `--bare` or re-read README |
| Prompt 9 | Uses exact self-test commands from state | May re-survey or invent `npm test` |
| Transcript | Fewer repeat reads of `AB-PROTOCOL.md`, `README.md` post-compaction | Re-reads or wrong paths |

This scenario is intentionally **repo-local** so runs are reproducible without external
infra. Swap anchor facts for your project if needed; keep the early-establish / late-probe
structure.
