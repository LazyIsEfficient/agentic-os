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

## The interactive benefit protocol (human-in-the-loop)

### Scenario design rules

1. **One long, multi-step task in a single interactive session** (not `-p`).
2. **An anchor fact established early** that must be **used correctly late** — e.g.
   "the broker already runs at `:5552`, reuse it" or "the contract field is `userId`,
   not `uid`". Pick a fact whose loss is *observable*: losing it forces re-work
   (re-read / re-survey) or causes a wrong value.
3. **Enough intervening steps to cross an auto-compaction boundary** between the
   early establish and the late use. Auto-compaction is the faithful trigger; a
   manual `/compact` at a fixed point is the controlled fallback (note which you used —
   they are not identical conditions).
4. **The late step is the probe:** in the OFF arm, the early fact is gone from context
   after compaction, so the model must re-derive it (re-work) or err; in the ON arm,
   `SESSION-STATE.md` re-injects it, so it shouldn't.
5. **Same scripted prompt sequence for both arms** — same wording, same order, same
   model, same starting repo state. The only variable is the harness.

### Run procedure (per arm, repeat for N)

- **ON arm:** interactive session with `--settings .claude/settings.json` (awareness
  hooks active). Before starting, record the anchor fact via `/state` so it is in
  `SESSION-STATE.md`.
- **OFF arm:** interactive session with `--settings '{"hooks":{}}'` (no awareness
  hooks; everything else equal — *not* `--bare`, which also strips LSP/plugins and
  confounds the comparison).
- Paste the **identical** scripted prompt sequence into each.
- Drive each session until **at least one compaction boundary is crossed** — confirm
  via the compaction event (and, ON arm, the `.claude/session-state.checkpoints`
  marker the PreCompact hook writes).
- Capture each transcript from `~/.claude/projects/<proj>/<session-id>.jsonl`.

### Cursor arms (same scenario, different capture path)

- **ON arm:** interactive Agent session with project `.cursor/hooks.json` active
  (awareness hooks: `sessionStart` inject + `beforeSubmitPrompt` digest).
- **OFF arm:** same setup with awareness hooks disabled — empty/rename project
  `.cursor/hooks.json`, or a throwaway clone without hook registration. Isolate
  the harness; do not change model or rules bundle.
- Paste the **identical** scripted prompt sequence into each.
- Drive each session until **≥ 1 context compaction boundary** (auto-compaction
  preferred; manual compaction is a controlled fallback — log which).
- Capture each transcript from
  `~/.cursor/projects/<workspace-slug>/agent-transcripts/<session-id>/<session-id>.jsonl`.

#### Cursor compaction — honest limit (same structural constraint as #147)

Cursor headless / single-shot agent runs **do not** cross a compaction boundary
any more than `claude -p` does. Headless measurement is **tax only** (inject +
digest per turn), not post-compaction **benefit**. Benefit requires an interactive
multi-turn session crossing a real compaction event (manual procedure or a future
multi-turn driver — same deferral as #147). Do **not** report a headless Cursor
ON−OFF delta as the benefit result.

Cursor transcripts omit token `usage` today; `compare.mjs` still diffs **turns**,
**`repeat_read_files`**, and **`repeated_tool_calls`**. Treat token columns as
**N/A (zero in export)** for Cursor pairs.

### Metrics

Feed each transcript pair to the existing instrument:

```
node compare.mjs <on-session>.jsonl <off-session>.jsonl
```

Read, **comparing the distribution across the N pairs, never a single delta**:

- **output tokens to completion** — total work spent.
- **`repeat_read_files`** and **`repeated_tool_calls`**, weighted toward the
  **post-compaction** region — the raw re-work signal. (These are Tier-0 mechanical
  counts; "wasteful" is a Tier-2 judgement the instrument deliberately does not make —
  a re-read after a file changed is legitimate, so eyeball the cause.)
- **anchor-fact correctness** (manual) — did the late step use the right value?

### N and analysis

- N is a deliberate, expensive, **opt-in** spend (interactive sessions, can't be
  scripted headlessly — see Automation note). Even N=3–5/arm gives a first read;
  report **median + spread**, not a point estimate.
- LLM runs vary; a single pair proves nothing. Look for a **consistent** shift across
  the distribution.

### Pre-registered interpretation (decide before running, to avoid post-hoc spin)

- **BENEFIT CONFIRMED** — ON's post-compaction re-work signals are consistently lower
  than OFF's **and** ON's tokens-to-completion are not worse, across the distribution.
  NORTH_STAR's thesis is supported *on this scenario*.
- **NULL** — no consistent difference beyond run-to-run noise. The tax isn't repaid
  even across compaction; the harness's value is not demonstrated here.
- **COST-DOMINATED** — ON spends consistently more with no re-work reduction. The
  harness is net overhead on this scenario.

The effectiveness investigation found **null** on tractable single tasks; pre-register
because that prior makes motivated reading easy. This apparatus measures; it does not
pre-judge.

## Automation note (the only way to make this headless/repeatable)

This protocol is human-in-the-loop because the benefit requires a real multi-turn
session crossing compaction, and `claude -p` can't. Making it automatable would take
a **multi-turn interactive driver** — a script that feeds a fixed prompt sequence to a
*persistent* session and drives it across an auto-compaction boundary, capturing the
transcript. That is new tooling, not built here, and is the prerequisite for an N-run
*headless* benefit A/B. Until it exists, #147's benefit measurement is by hand.

## Status for #147

- **Apparatus (instruments): done** — `session-metrics.mjs` / `session-metrics-cursor.mjs`
  / `compare.mjs` are Tier-0 and self-tested; `compare.mjs` auto-detects platform per
  file; `run-arms.sh` produces one stochastic sample (Claude Code only).
- **Benefit measurement: not runnable with current headless tooling** — structural
  (`-p` never compacts). This protocol is the by-hand path; the multi-turn driver is
  the automatable path.
- **Executing it (N interactive sessions) is a deliberate, expensive, opt-in spend
  with a null prior** — deferred until someone chooses to invest. The honest deliverable
  for #147 is this protocol + the structural finding, not a biased cost-only number.
