# Does this skills/agents library add measurable value? — an investigation

**Question:** does using this library (its specialist agents + the multi-agent review
"pod") produce *measurably better outcomes* than not using it — i.e. than a single
capable model in one pass?

**Short answer:** The library is a **convention / conformance + process-scaffolding
layer**, not a **correctness or reliability multiplier** — for the current model
(Opus 4.8) on tasks within its one-shot competence, which turned out to be very wide.
It reliably produces artifacts that meet *this repo's standards* (which a vanilla agent
can't know); it did **not** measurably improve correctness or fault-tolerance on any
task we could get the base model to fail on first.

All numbers below are from deterministic checks (scripts, tests, a real chaos test),
not from an LLM judge, except where explicitly labelled "judge."

---

## How it was measured

A comparative harness under `eval/` runs the same task through two (or three) arms and
scores them identically:

- **baseline (library OFF)** — a vanilla `general-purpose` agent told to use no skills,
  subagents, or commands; one pass.
- **pod (library ON)** — the `v2-collab` multi-agent review loop (PM → builder →
  reviewer, iterate to a gate), roster **auto-composed** by the v1.5 `pod-architect`.
- **self-review (control)** — a single agent told to produce, critique its own work, and
  revise once. Isolates "independent reviewer" from "just iterate."

> Note: the **`pod` arm was retired** after the v2 prune removed the `v2-collab` pod; the
> harness now runs **agent-vs-baseline** (and reliability runs **baseline-vs-self-review**).
> This section records the investigation as originally run.

Two measurement layers, per the repo's tier doctrine:
- **Deterministic (Tier 0, gates):** the produced artifact must pass `validate.sh` /
  compile / a hidden test suite / a chaos test. Reproducible; this is the headline.
- **Judge (Tier 2, informs only):** a blind, position-randomized pairwise panel. Used
  for the comparative-quality run; deliberately *excluded* from the reliability claims.

---

## Experiment 1 — comparative quality across output types (`corpus-2`)

5 fixtures (library-skill ×2, code, claims-doc, pod-deliverable page), library-ON vs
baseline, blind pairwise judge + deterministic checks. Files: `eval/results/corpus-2.jsonl`,
`eval/results/report-corpus-2.md`.

- **Deterministic / conformance: library 5/5 valid, baseline 3/5 (+40%).** The baseline
  failed both *library-skill* fixtures — it omitted the repo-required `when_to_use`
  frontmatter key, every time, because a vanilla agent has no way to know that
  convention. For code/claims/page, both arms produced valid output (no conformance gap).
- **Blind quality (judge): library won 4/5 fixtures, baseline 1/5, margins modest
  (0.09–0.35).** A slim, fairly consistent edge — not a blowout.

**Read:** the library's clear, reproducible win is **conformance to its own standards**.
On raw content quality the base model is strong enough that the margins are thin.

---

## Experiment 2 — reliability on hard traps (`rel-1`)

To test the *review loop* (not just a system prompt), 3 arms × 3 Rust functions with
**deliberately catchable traps** (multibyte-UTF-8 boundary, path-traversal+symlink,
unsorted-interval merge) × 5 repeats, scored by **hidden held-out test suites** the
producers never saw (validated against known-correct and known-trap reference impls).
Files: `eval/reliability/results-rel-1.jsonl`, `report-rel-1.md`.

| Arm | clean runs | defects | floor |
|---|---|---|---|
| baseline (one pass) | 15/15 | 0 | 1.00 |
| pod (review loop) | 15/15 | 0 | 1.00 |
| self-review | 14/15 | **1** | 0.57 |

**Read:** Opus 4.8 **one-shot every trap, perfectly**. The classic failure modes that
wreck weaker models are inside its competence. The pod matched the baseline because there
were no defects to catch. The one defect in 45 runs came from **self-review** — naive
"revise once" *regressed* a correct solution; the independent reviewer (pod) never did.

This run did **not** test the loop's value — the precondition (baseline defects to catch)
never occurred. We hadn't reached the model's failure frontier.

---

## Experiment 3 — a complex distributed app, measured by a real chaos test

The hardest, fairest test: build a **fault-tolerant Next.js + RabbitMQ-Streams note app**
(durable publisher-confirm writes, consumer offset-resume, idempotent replay), scored by a
**chaos test** that POSTs notes, **kills the worker mid-write**, POSTs more, restarts the
worker, and asserts **no acknowledged note is lost or duplicated**. Apparatus under
`eval/app-reliability/`, validated to pass a genuinely-correct reference app (20/20) and
fail a plausible fake that loses 10/20.

| Arm | build | contract | **chaos** | completeness | score |
|---|---|---|---|---|---|
| **baseline** (one pass, no library) | ✓ | ✓ | **PASS 20/20** | 6/6 | **9/9** |
| **pod** (auto-composed review loop) | ✓ | ✓ | **PASS 20/20** | 6/6 | **9/9** |

**Read: dead heat.** A single capable agent, one pass, produced an equally
fault-tolerant app. The pod **approved in 1 round** — the reviewer found nothing to fix.
Even on a complex distributed-systems task with real fault-tolerance traps, the base model
one-shots it, so the review loop has nothing to catch.

*v1.5 note:* `pod-architect` auto-composed a **generalist** trio (technical-pm → engineer →
code-reviewer) for this task — not the DevOps/QA/security specialists the infra/distributed
nature arguably warranted. It still scored 9/9, but the composer didn't reach for specialists.

---

## Conclusions

1. **Measurable value: conformance, reproducibly.** The library produces artifacts that
   meet this repo's standards where a vanilla agent fails (+40%). Real value if you care
   about valid, routable, CI-passing artifacts — but it is conformance to *the library's
   own rules*, not generic quality.
2. **No measurable correctness/reliability lift** from the review loop on tasks within the
   model's one-shot competence — and that competence spans from trivial Rust to a
   fault-tolerant streaming backend. We never found a task where the baseline failed and
   the pod rescued it.
3. **Counter-intuitive:** forcing *self*-review can hurt (1 regression in 45 runs);
   independent review didn't hurt, but also didn't help when there was nothing to catch.
4. **Where the loop would pay off** is *past* the model's frontier (much larger /
   multi-service / genuinely novel work) or on a **weaker model**.

## What was NOT measured (honest limits)
- **Routing accuracy** (does the right skill/agent get picked) — not tested here.
- **The weaker-model rescue test** (same harness on Haiku, where the baseline *would* fail
  and you could measure whether the pod rescues it) — **not run**. This is the single
  cleanest way to prove the review mechanism works *at all*, separate from whether Opus
  needs it.
- Several runs are single-shot or small-N; treat margins as indicative, not definitive.
- The conformance win is partly circular ("the library conforms to the library's rules").

## The apparatus (reusable)
- `eval/` — comparative harness (`eval-harness.js` + `/eval-harness`), fixtures, schema,
  checkers, blind judge, aggregator.
- `eval/reliability/` — hidden-test reliability harness for trap tasks.
- `eval/app-reliability/` — the chaos-test battery (`run-battery.sh`) + reference apps; runs
  against a RabbitMQ-Streams broker (a working `docker-compose.yml` is at the repo root).
- Run results live alongside each (`*.jsonl` + `report-*.md`).
