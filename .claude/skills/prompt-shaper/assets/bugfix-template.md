## Symptom
<what the user / system observes that is wrong>

## Expected behavior
<what should happen instead>

## Reproduction
<steps, inputs, environment — or "not yet known">

## Repo
<path>

## Scope of fix
- In: <the bug itself>
- Out: <adjacent cleanup, refactors, "while we're in there" — explicitly deferred>

## Approach
1. Reproduce and confirm root cause. Report findings.
2. Propose fix. Stop for approval.
3. Implement minimal fix with regression test.

## Deliverables
- Root-cause writeup
- One PR with fix + regression test

## Constraints
- <e.g. must ship before X, must not change public API>

## Assumptions
<list each `[Assumed: <value>]` tag from the brief here so they are inspectable in one place. Reader can override any of them with one line.>
- <e.g. "Blast radius: papercut — say if wrong">

## Open questions
- <load-bearing items still unresolved after round 2 — block execution until answered>
- <`<TBD — to investigate>` items the brief deferred (e.g. unknown repro, unknown first-seen)>
