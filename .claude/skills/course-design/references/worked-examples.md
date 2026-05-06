# Worked examples

A worked example is the author solving the problem in front of the learner, narrating the reasoning. It is the single highest-leverage artifact in any technical lesson. This reference tells you how to plan one at the design stage so `course-author` can execute cleanly.

## What a worked example is (and isn't)

A worked example **is** a complete solution to one concrete problem, with the reasoning exposed at each step.

A worked example **is not**:
- A finished code listing the learner reads top to bottom.
- A demo where the author types fast and says "as you can see…".
- A summary of "how you would solve this".

The difference is reasoning-per-step. The learner needs to see *why* each step, not just what step.

## Planning fields in the lesson spec

The lesson spec's worked-example plan has five fields; each matters:

1. **Scenario** — a concrete problem. Not "an example of rate limiting" but "Twitter's public timeline gets 10× its normal traffic during a news event; design a limiter that keeps the fleet healthy without starving the legitimate traffic."
2. **Starting state** — what the learner sees at t=0. Inputs, code skeleton, prompt, diagram. No surprise context reveals mid-example.
3. **Target state** — what exists at the end. Be precise: "a function that accepts X and returns Y, tested with these three cases."
4. **Size budget** — how many lines of code, or how many prompt turns, or how many diagram nodes. Budgets force focus. A worked example that blows its budget is teaching two concepts.
5. **What it demonstrates** — the *one* mechanism this example exists to show. If you can't compress this to one sentence, the example is a tour, not a worked example.

## Faded-guidance progression

A single lesson should include a worked → faded → independent arc. The design spec names all three.

- **Worked**: author solves the whole thing.
- **Faded**: author solves most of it; learner completes 1–2 steps. The steps to fade are the ones that demonstrate the *core mechanism*, not setup or boilerplate.
- **Independent**: learner solves a new instance of the same class of problem. A reference solution is revealed after they attempt it.

This is where most online courses fail: they have worked and independent, but no faded. The learner goes from "watching" to "swimming", and many drown.

## Choosing the scenario

Good worked-example scenarios have three properties:
- **Concrete.** A named system, a real number, a specific failure. "A 10k-row table" beats "a table".
- **Representative.** The pattern generalizes. If you have to construct a contrived situation, the learner will sense it.
- **Failure-aware.** Most teachable moments live in what goes wrong. Scenarios that have at least one "…and here's the thing that bites" beat scenarios that succeed cleanly.

Avoid: toy scenarios the learner already solved (fizzbuzz territory) and scenarios so rich they obscure the mechanism.

## AI-usage worked examples

When the topic is prompting, agent design, or context engineering:
- The "starting state" should include the full original prompt or context setup, warts and all.
- The "target state" should include the revised prompt/context and a paired sample of the model's output before and after.
- The "what it demonstrates" should name the one mechanism — e.g. "added explicit success criteria", not "improved the prompt".

Avoid examples where the improvement is a vibes-based rewrite with no isolated mechanism; the learner can't generalize.

## System-design worked examples

When the topic is architecture, reliability, or data modeling:
- The "starting state" should include constraints (QPS, latency, failure tolerance, cost ceiling) — otherwise every design is "correct".
- The "target state" should include a named decision and its rejected alternatives, not just a final diagram.
- The "what it demonstrates" should name the one trade-off — e.g. "choosing eventual consistency to meet the latency target", not "designing the system".

Avoid examples that present The Solution as if it were the only option; worked examples should show thinking, not certainty.

## Hand-off to course-author

The lesson spec describes the example; `course-author` writes it. The design job is to guarantee that:
- The scenario is concrete and sized.
- The mechanism is named and singular.
- The faded step is specified (what the learner fills in).
- Citations or sources are identified where the example makes a technical claim.

If the spec is thin on any of these, the author will either ask or guess. Both cost more than writing it properly now.
