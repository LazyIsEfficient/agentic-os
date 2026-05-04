# Exercise progression

Exercises come in a ladder. Each rung reduces the scaffolding and increases the learner's autonomy. Most lessons climb two or three rungs; few need all four. The spec picks the types; this reference explains how to design each one so the rung actually does its job.

## The ladder

1. **Parsons problem** — correct steps are given; the learner puts them in order (with one or two distractors).
2. **Fill-in** — the solution is mostly written; the learner completes the one load-bearing piece.
3. **Modify** — a working solution is given; the learner changes it to satisfy a new constraint.
4. **From-scratch** — the learner solves a new instance of the same class of problem, unaided.

The ladder corresponds to the faded-guidance progression inside the lesson. Worked example first; then one or two faded exercises (Parsons or fill-in); then modify; then from-scratch as the independent practice.

## When each rung is right

### Parsons — use when order is the hard part

Good for topics where the steps themselves are simple but the sequence matters and has non-obvious dependencies. Examples:
- The order of operations in a retry + timeout + circuit-breaker stack.
- The order of a multi-step prompt with tool use.
- The order of database migration steps during a schema change.

Bad for topics where each step is itself hard; the learner will get the order right and still not understand what the steps do.

### Fill-in — use when the mechanism is local

Good for topics where the learner must produce one specific line or function that demonstrates mastery of the mechanism, and the surrounding code is scaffolding. Examples:
- Write the cache-invalidation clause given the surrounding cache-aside logic.
- Write the success-criteria portion of a prompt given the rest of the prompt.
- Write the backpressure handler given the surrounding queue consumer.

The key design choice: what to leave for the learner. It should be exactly the part that exercises the primary objective. If the fill-in is trivial ("add a semicolon") the rung isn't doing work; if it's most of the solution, it's actually from-scratch with extra noise.

### Modify — use when transferable application is the point

Good for topics where the learner has to apply the mechanism to a changed situation. Examples:
- Given a rate limiter for a single instance, modify it to work across a fleet.
- Given a prompt tuned for summarization, modify it to do structured extraction while preserving the pattern.
- Given a service-to-service retry policy, modify it for a dependency with different failure characteristics.

The modify exercise is the highest-value rung for skill transfer. Don't skip it. If the spec has only "Parsons" and "from-scratch", the jump between them is usually too large; push back on the spec.

### From-scratch — use as independent practice, not introduction

Good for topics where the learner is ready to produce a novel solution to a new instance of the class of problem. Examples:
- Design a rate limiter for a different kind of traffic (after modifying the worked-example one).
- Write a context-engineered prompt for a new task (after rewriting the lesson's prompt).
- Draft a migration plan for a different schema change (after planning the lesson's one).

From-scratch is never the first exercise in a lesson. If the spec puts it first, flag it.

## Design rules for any rung

### Each exercise has acceptance criteria

The learner needs to know when they're done. "Make it work" isn't acceptance criteria. Name observable conditions:
- The function returns `<shape>` for input `<shape>`.
- The prompt produces an output that includes `<fields>` and avoids `<failure mode>`.
- The design handles `<failure scenario>` with `<expected behavior>`.

### Reference solutions live behind `<details>`

The learner should try before peeking. `<details><summary>Reference solution</summary>...</details>` gives them the choice. Never show the solution directly; it removes the pedagogical purpose of the exercise.

### Reference solutions are explained

A reference solution with no explanation is just code. A reference solution with a 1–2 line "why this works" ties the solution back to the mechanism and lets the learner self-assess even if their code is byte-different.

### Distractors are plausible

For Parsons problems, a distractor is only useful if the learner could plausibly insert it and believe it belongs. A distractor from a different domain is noise. A distractor that *looks* right but subtly breaks the invariant is gold.

### Difficulty climbs monotonically

Within a lesson, the second exercise is not easier than the first. The third is not easier than the second. If it is, the lesson will feel like it's ping-ponging difficulty. The monotonic climb is what gives the learner confidence that they're progressing.

### Ship a stretch only if it's actually optional

A stretch exercise is for the learner who finished early. It should extend the mechanism to a harder case or connect it to the next lesson. It should *not* be a mandatory piece labeled "stretch" because the author couldn't fit it. Mandatory material is mandatory; optional material is optional; be honest about which.

## AI-topic exercise specifics

For exercises in AI-usage lessons:
- Show the prompt the learner should start from (Parsons/fill-in/modify) or the task they're prompting for (from-scratch).
- State the expected output shape as acceptance criteria — fields, format, constraints.
- When possible, give the learner a way to verify: a small eval set, a reference completion, or a checklist.
- Acknowledge non-determinism: the reference solution is one plausible answer, not the only one. Learners should compare against the acceptance criteria, not exact string match.

## System-design exercise specifics

For exercises in system-design lessons:
- State the constraints (load, latency, failure tolerance, cost ceiling) as acceptance criteria. Designs without constraints are all "correct".
- Prefer "design and defend" over "design". The defense step (name the rejected alternatives and why) is where most of the learning happens.
- Reference solutions should show the rejected alternatives, not only the chosen design. Design is the art of saying no.
