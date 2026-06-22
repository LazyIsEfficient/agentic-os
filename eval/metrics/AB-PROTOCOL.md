# Long-session A/B protocol — measuring awareness *benefit*, not just cost

This is the runnable-by-hand procedure for issue #147. It exists because the
**headless** harness (`run-arms.sh` + `compare.mjs`) **cannot** answer #147's core
question on its own — and pretending otherwise would produce a confidently wrong
number. Read the structural constraint first; it is the whole reason this doc exists.

## The structural constraint (why `run-arms.sh` alone can't answer #147)

> **A one-shot `claude -p` turn never compacts** — authoritative, from
> [eval/spikes/s0-hook-capability.md](../spikes/s0-hook-capability.md) (S0), and
> reconfirmed by the #146 live-fire test (PreCompact fires only on a real
> interactive `/compact` or auto-compaction in a long session).

`run-arms.sh` drives each arm with a single `claude -p` invocation. Therefore:

- **Neither arm ever crosses a compaction boundary.** No `PreCompact`, no
  post-compaction `SessionStart` re-injection — the events the harness exists to
  exploit never fire.
- **The awareness *benefit* lives only across that boundary.** It is precisely the
  moment the OFF arm loses a settled fact and the ON arm re-injects it. With no
  boundary, that benefit is **structurally absent from the measurement** — not
  small, not noisy: absent by construction.
- **What a headless N-run A/B *would* measure is the cost half only** — the per-turn
  token *tax* of injecting `SESSION-STATE.md` at SessionStart and the digest each
  turn, in a session where compaction never fires to pay it back. The ON arm can
  only look **equal-or-worse**, because the test excludes its upside.

So **do not** run `run-arms.sh` N times and report the ON−OFF delta as "the #147
result." It answers a benefit question with a cost-only instrument. The honest
headline of #147 is this limitation itself; this protocol is the path that can
actually measure the benefit.

## Cost vs benefit — what each instrument can and can't see

| Quantity | Definition | Measurable headless? | Instrument |
|---|---|---|---|
| **Tax (cost)** | extra input/cache tokens the ON arm spends per turn on inject + digest | **Yes** — but it's an *upper bound* in a no-compaction run (all cost, no payback) | `compare.mjs` input/cache deltas |
| **Re-work avoided (benefit)** | work the OFF arm repeats after compaction that the ON arm doesn't (re-reads a file, re-runs a survey, re-derives a settled fact) | **No** — needs a real compaction boundary → interactive session | `repeat_read_files`, `repeated_tool_calls` (from `session-metrics.mjs`), post-compaction |
| **Anchor-fact correctness** | did the arm *use the early fact correctly* late, or re-derive / get it wrong | **No** — same reason; also needs a human/script judge | manual judgement against the scenario's expected late value |

The net verdict NORTH_STAR cares about is `benefit − tax`. Headless gives you only
`tax`; you must reach a compaction boundary to see `benefit`.

## Interactive long-session procedure

Operator runbook for the benefit A/B. **Do not start runs until pre-registered.**

**Canonical scenario:** [scenarios/long-session-awareness.md](scenarios/long-session-awareness.md)
— multi-step batch-metrics task with three anchor facts (constraint, decision, infra)
established early and probed on prompts 9–10 after compaction.

**Pre-register:** `bash pre-register.sh long-session-awareness` writes
`runs/<timestamp>-long-session-awareness/hypothesis.md` with the interpretation template.
Fill N, compaction trigger, and decision rule **before** any session or `compare.mjs` run.

### 1. Choose N and arms

| Arm | Invocation | Harness |
|---|---|---|
| **ON** | `claude --settings .claude/settings.json` (interactive, not `-p`) | SessionStart inject + UserPromptSubmit digest + PreCompact checkpoint |
| **OFF** | `claude --settings '{"hooks":{}}'` (interactive, not `-p`) | No awareness hooks; **not** `--bare` (confounds LSP/plugins) |

- **N ≥ 3** sessions per arm (6+ runs total). N is an expensive, opt-in spend.
- Same model, same repo SHA, same scripted prompts — only the harness differs.
- ON arm: record anchor facts via `/state` before prompt 1 (see scenario).

### 2. Run each session (repeat N times per arm)

1. Start a **fresh interactive** session with the arm's settings from the repo root.
2. Paste the scenario's scripted prompts **one at a time** — identical wording for both arms.
3. Drive until **≥ 1 compaction boundary** (auto-compaction preferred; manual `/compact`
   is a controlled fallback — log which).
4. Confirm compaction: compaction event in transcript; ON arm may show
   `.claude/session-state.checkpoints` from the PreCompact hook.
5. **Capture transcript** when the session ends:

   ```text
   ~/.claude/projects/<proj-slug>/<session-id>.jsonl
   ```

   `<proj-slug>` is derived from the absolute repo path. Save each file under
   `eval/metrics/runs/<run-id>/` as `on-01.jsonl`, `off-01.jsonl`, etc.

### 3. Compare pairs with `compare.mjs`

For each run index *i* (same scenario completion, different arms):

```bash
node eval/metrics/compare.mjs runs/<run-id>/on-0i.jsonl runs/<run-id>/off-0i.jsonl --json \
  >> runs/<run-id>/compare-results.jsonl
```

Positive `delta.*.abs` / `saved%` = ON arm spent less (harness helped). One pair is
**one stochastic sample** — never the headline result.

### 4. Analyze the **distribution**, not a point estimate

Across all N pairs:

- **Median + spread** (min/max or IQR) for `output_tokens`, `repeat_read_files`,
  `repeated_tool_calls` deltas.
- Weight re-work signals toward the **post-compaction** region (eyeball transcripts).
- **Anchor-fact correctness** (manual) — late prompts vs scenario expected values.

```bash
# Example: median output-token delta from collected --json lines
node -e '
const rows = require("fs").readFileSync("runs/<run-id>/compare-results.jsonl","utf8")
  .trim().split("\n").map(JSON.parse);
const med = k => { const v = rows.map(r=>r.delta[k].abs).sort((a,b)=>a-b);
  return v[Math.floor(v.length/2)]; };
console.log({ n: rows.length, median: {
  output_tokens: med("output_tokens"),
  repeat_read_files: med("repeat_read_files"),
  repeated_tool_calls: med("repeated_tool_calls"),
}});
'
```

Look for a **consistent direction** across pairs. LLM variance means a single ON/OFF
pair proves nothing.

### 5. Pre-registered interpretation (decide before running)

| Verdict | Condition |
|---|---|
| **BENEFIT CONFIRMED** | ON post-compaction re-work consistently lower **and** tokens-to-completion not worse, across the distribution. NORTH_STAR thesis supported *on this scenario*. |
| **NULL** | No consistent difference beyond run-to-run noise. Tax not repaid across compaction. |
| **COST-DOMINATED** | ON consistently spends more with no re-work reduction. |

The [effectiveness investigation](../INVESTIGATION.md) found **null** on tractable
single tasks — the honest null prior for this A/B. Pre-register because that prior
makes motivated reading easy. This apparatus measures; it does not pre-judge.

Full template: scenario doc § Pre-registration interpretation template, or output of
`pre-register.sh`.

### Scenario design rules (when authoring new scenarios)

1. **One long, multi-step task** in a single interactive session (not `-p`).
2. **Anchor fact(s) established early**, used correctly late — loss is *observable*
   (re-work or wrong value).
3. **Enough intervening steps** to cross auto-compaction between establish and probe.
4. **Late step is the probe** — OFF must re-derive or err; ON re-injects via
   `SESSION-STATE.md`.
5. **Identical scripted sequence** for both arms.

## Automation note (the only way to make this headless/repeatable)

This protocol is human-in-the-loop because the benefit requires a real multi-turn
session crossing compaction, and `claude -p` can't. Making it automatable would take
a **multi-turn interactive driver** — a script that feeds a fixed prompt sequence to a
*persistent* session and drives it across an auto-compaction boundary, capturing the
transcript. That is new tooling, not built here, and is the prerequisite for an N-run
*headless* benefit A/B. Until it exists, #147's benefit measurement is by hand.

## Status for #147

- **Apparatus (instruments): done** — `session-metrics.mjs` / `compare.mjs` are Tier-0
  and self-tested for **Claude Code and Cursor** JSONL (`--platform auto` default);
  `run-arms.sh` produces one stochastic sample (Claude Code only).
- **Benefit measurement: not runnable with current headless tooling** — structural
  (`-p` never compacts). This protocol is the by-hand path; the multi-turn driver is
  the automatable path.
- **Scenario doc: done** — [scenarios/long-session-awareness.md](scenarios/long-session-awareness.md)
  + `pre-register.sh` for hypothesis stamping.
- **Executing N interactive sessions** is a deliberate, expensive, opt-in spend with a
  [null prior](../INVESTIGATION.md) — **operator follow-up**, not part of this PR.
  The honest deliverable for #147 is protocol + scenario + structural finding, not a
  biased cost-only number from headless runs.
