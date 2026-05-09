## Goal
<1 paragraph: the user-visible outcome. What changes for the end user or operator when this is done?>

## Repos in scope
- <path> — <role in the feature>
- <path> — <role in the feature>

## Constraints
- <compatibility, perf, security, deadline, or "do not touch" items>
- <explicitly out of scope>

## Approach
1. Spawn an Explore subagent per repo to map current state and report back.
2. Produce an integrated plan (schema/contracts/rollout order). Stop and wait for approval.
3. On approval, implement repo-by-repo. One PR per repo. Tests required.

## Deliverables
- Plan doc (inline)
- PRs: one per repo, linked
- Migration / rollout notes
- Test plan

## Assumptions
<list each `[Assumed: <value>]` tag from the brief here so they are inspectable in one place. Reader can override any of them with one line.>
- <e.g. "Rollout order: producer-then-consumer; schema-then-code — say if wrong">
- <e.g. "Compatibility: backwards-compatible during rollout — say if wrong">

## Open questions
- <load-bearing items still unresolved after round 2 — block execution until answered>
- <`<TBD — to investigate>` items the brief deferred — investigate before the integrated plan in step 2>
