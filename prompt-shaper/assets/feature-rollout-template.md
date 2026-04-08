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

## Open questions to investigate first
- <thing 1>
- <thing 2>
