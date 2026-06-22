# Blind pairwise judge protocol (Tier 2 — informs, never gates)

The comparative harness produces two artifacts per fixture — one from the **library** arm, one
from the **baseline** arm — and gives both the same Tier-0 deterministic check. This protocol is
the **Tier-2 layer** that compares the two artifacts on quality the deterministic checker cannot
see. It is **advisory only**: per [`review-tiers.md`](../../.claude/rules/review-tiers.md) a
pure-LLM-judgment layer NEVER gates a commit, install, or merge. Its output informs the
per-dimension × output-type report; it does not disqualify an arm.

The judge is **blind**: it sees two artifacts labelled `Output A` and `Output B` and never learns
which arm produced which. Blinding is **load-bearing** — if the arm identity leaks into the judge
prompt, every downstream number is contaminated and the comparison is worthless.

One judge returns the StructuredOutput defined in
[`judge-output.schema.json`](judge-output.schema.json). The runner dispatches **N = 3** such
judges and aggregates them (see [Panel aggregation](#panel-aggregation)) into the `judge` block of
[`result.schema.json`](../schema/result.schema.json).

---

## What one judge receives

The runner hands each judge exactly four things, and **nothing that identifies an arm**:

1. **The fixture task** — the verbatim `task` string both arms were given (so the judge knows
   what "good" means for this case).
2. **The rubric dimensions** — `fixture.rubric.dimensions[]`, each `{ key, max, asks }`. The
   `asks` is the concrete discriminating question the judge answers for that axis.
3. **Output A** — one arm's artifact, presented neutrally.
4. **Output B** — the other arm's artifact, presented neutrally.

The judge is **NOT** given: which arm is `library` vs `baseline`, the arm `note` fields, the
arm `prompt` fields, the deterministic verdicts, the producing agent type, or anything else that
correlates with arm identity. The runner constructs the prompt from `task` + `rubric.dimensions`
+ the two artifact bodies only.

### Prompt template

> You are an impartial judge comparing two outputs for the same task. You do not know who or
> what produced either output, and you must not speculate about it.
>
> **Task that both outputs were asked to satisfy:**
> `{{fixture.task}}`
>
> **Rubric — score each dimension independently. For each, `asks` is the question you answer:**
> {{for each dimension}} - `{{key}}` (max {{max}}): {{asks}}
>
> **Output A:**
> ```
> {{artifact shown in position A}}
> ```
>
> **Output B:**
> ```
> {{artifact shown in position B}}
> ```
>
> For EACH rubric dimension, decide whether **A**, **B**, or **tie** is better on that axis, give
> a **margin** in `0..1` (how decisive the win is; `0` for a tie), and a one-line **evidence**
> justification that **quotes the deciding text** from the output you picked. Then give an
> **overall** winner + margin across all dimensions.
>
> Posture: **adversarial / default-reject.** When the evidence for a dimension is weak,
> ambiguous, or roughly even, answer **tie** — do not invent a winner. Quote before you assert:
> a verdict with no quote from the artifact is an unevidenced verdict, so record it as a tie.
>
> Return ONLY the StructuredOutput object (`per_dimension[]` + `overall`).

### Default-reject posture (the bar to declare a winner)

The judge's standing instruction is to **lean tie**. A dimension verdict of `A` or `B` is a
claim that demands evidence; `tie` is the null hypothesis. Concretely:

- **Quote or tie.** Every non-tie dimension verdict MUST quote the specific text in the winning
  output that decides it. If the judge cannot point to a deciding quote, the honest answer is
  `tie`. The `evidence` field is required for ties too (quote what makes the two roughly even).
- **Weak evidence → tie.** Stylistic preference, "feels more thorough", or a difference that
  doesn't touch the dimension's `asks` is not enough. Reserve a winner for a concrete,
  quotable gap on that axis.
- **Margins are honest, not flattering.** A barely-ahead dimension gets a small margin
  (`<= 0.2`); a decisive one a large margin. A tie is always `margin: 0`.
- **No arm reasoning.** The judge must not reason about which output "looks like" a library or a
  vanilla agent produced it. Judging the producer instead of the artifact defeats the blind.

This posture biases the panel toward `tie` and toward small margins. That is intended: an
informs-only Tier-2 layer should under-claim, so the only confident signals that survive
aggregation are the ones backed by quotable evidence.

---

## What one judge returns

Exactly the shape in [`judge-output.schema.json`](judge-output.schema.json):

```json
{
  "per_dimension": [
    { "dimension": "<rubric key>", "winner": "A|B|tie", "margin": 0.0, "evidence": "<quoted one-liner>" }
  ],
  "overall": { "winner": "A|B|tie", "margin": 0.0 }
}
```

- `per_dimension` has **one entry per rubric dimension**, keyed by the dimension `key`.
- `winner` is `A | B | tie` in **blind position terms** — what this judge saw as A vs B (which is
  randomized per judge, below). It is NOT an arm name.
- `margin` is `0..1`; `0` whenever `winner` is `tie`.
- `evidence` is the per-dimension quoted justification. It exists at the single-judge layer only;
  the panel aggregator drops it when collapsing to `result.schema.json`'s `dimensionVerdict`
  (which carries just `dimension`, `winner`, `margin`).

`per_dimension[*].{dimension,winner,margin}` binds **exactly** to
`result.schema.json#/$defs/dimensionVerdict`; `overall` binds to `#/$defs/verdict`. The only
addition at this layer is the `evidence` string.

---

## Position randomization (per judge)

Blinding hides arm identity; **position randomization** cancels position bias (the well-known
tendency to favor whichever artifact is shown first). The runner shuffles **independently for
each of the N judges** which arm occupies position A vs position B:

- For each judge `i`, the runner draws an independent coin: either
  `(A = library, B = baseline)` or `(A = baseline, B = library)`.
- Because the draw is per judge, across the panel each arm appears in position A roughly half the
  time and position B roughly half the time. Any systematic first-position advantage therefore
  averages out instead of accruing to one arm.
- Each judge runs in isolation and never sees the other judges' assignments or verdicts —
  independence is what makes majority/median meaningful.

The judges always answer in **A/B terms**. Only the runner knows, per judge, what A and B mapped
to. The runner translates each judge's blind A/B verdict back to arm terms using **that judge's**
assignment before aggregating, so a `winner: A` from a judge who saw `A = baseline` is counted as
a baseline win. (Equivalently: aggregate in arm space, then re-label the aggregate to the run's
canonical A/B in the final result — see de-blinding below.)

---

## Panel aggregation

Inputs: **N = 3** independent judge outputs, each already translated from its own blind A/B
assignment into **arm space** (`library` / `baseline` / `tie`) using that judge's position
assignment.

Aggregate **per dimension**, and again for `overall`:

1. **Winner — MAJORITY.** Among the 3 arm-space votes for this dimension, the winner is the arm
   with the most votes (≥ 2 of 3). If no arm reaches a majority — i.e. the three votes are some
   permutation of `library`, `baseline`, `tie` with no repeat, or any 1-1-1 split — the
   aggregated winner is **`tie`**. **Ties are recorded, never broken**: there is no
   tie-breaking rule, no "most senior judge wins", no margin-based fallback. A non-majority is a
   tie, full stop.
2. **Margin — MEDIAN.** Take the **median** of the 3 per-judge margins for this dimension. With
   N = 3 the median is the middle value after sorting. Median (not mean) so one outlier judge
   cannot inflate or deflate the aggregate. If the aggregated winner is `tie`, the aggregated
   margin is forced to `0` regardless of the median.
3. **panel_votes = 3.** The result records `panel_votes: 3` (the number of independent judges).
   If the panel size is ever changed, `panel_votes` must reflect the actual N and the majority
   threshold (`floor(N/2) + 1`) and median recompute accordingly.

> **Worked example (one dimension).** Three judges, after translation to arm space, vote
> `library (margin 0.4)`, `library (margin 0.2)`, `tie (margin 0)`. Majority → `library` (2 of
> 3). Median of `[0, 0.2, 0.4]` → `0.2`. Aggregated dimension verdict: winner `library`, margin
> `0.2`. If instead the three votes were `library`, `baseline`, `tie` (1-1-1, no majority) →
> winner `tie`, margin forced to `0`.

The `overall` block aggregates the three judges' `overall` votes by the same majority/median
rule.

---

## De-blinding (downstream, after judging)

De-blinding happens **only in the runner, only after every judge has returned.** The judges never
see the map and the map is never injected into a judge prompt.

- The aggregated per-dimension and overall verdicts are computed in arm space (above), then the
  runner records them in the result's `judge` block in the result's canonical **A/B** terms and
  writes the single source of truth for that run's labels into
  `result.blinding_map` = `{ "A": "<arm>", "B": "<arm>" }`.
- `blinding_map` is the **only** way to de-blind: it states which arm the result's canonical `A`
  and `B` correspond to for this run. The aggregator and any human reader join through it to turn
  `winner: A` into `winner: library` (or `baseline`).
- Per the per-judge randomization above, the result's canonical A/B is a runner choice recorded
  in `blinding_map`; it is independent of any individual judge's position assignment, which is
  internal to the runner and not persisted per judge.

**Do not** leak arm identity into the judge prompt to "save a step." The blind is the entire
value of this layer. The map is recorded once, at the end, for audit — never consulted during
judging.

---

## Where this binds

| This protocol | Result schema |
| --- | --- |
| one judge's `per_dimension[*]` `{dimension,winner,margin}` | `result.schema.json#/$defs/dimensionVerdict` (after panel aggregation; `evidence` dropped) |
| one judge's `overall` `{winner,margin}` | `result.schema.json#/$defs/verdict` (after panel aggregation) |
| `panel_votes = 3` | `result.judge.panel_votes` |
| runner's post-judging A/B↔arm record | `result.blinding_map` |

This layer is **Tier 2**. It populates the report; it does not gate. Only the Tier-0
deterministic checker may stop the line.
