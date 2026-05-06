# prompt-shaper — bugfix

Example of `/shape` producing a `bugfix-template.md` brief — known broken behavior, need a fix.

---

## User's initial request

> Customers on the Pro plan are getting double-charged when they upgrade mid-cycle. Started Friday. Need this fixed before Monday's billing run.

## Shaper's batched questions

Known symptom, time pressure, billing — clearly a bugfix. Routes to `bugfix-template.md`.

1. **Repro steps?** Or do we only have customer reports — what's the exact sequence?
2. **Repo path?**
3. **Expected behavior — proration only, or full new charge with credit, or something else?**
4. **Started Friday — anything shipped Thursday or Friday that touches billing?**
5. **Scope of fix — strictly the double-charge, or also the affected customer refunds?**
6. **Constraints — must ship before Monday's billing run; anything else (no public-API changes, no schema migrations on a Friday, etc.)?**

## User's answers

1. Customer on Basic plan upgrades to Pro mid-cycle. Stripe charges them the prorated Pro amount (correct), then ~30 seconds later charges them the *full* Pro amount again.
2. `billing-service`.
3. Prorated charge for the rest of the cycle. One charge, not two. Existing behavior since 2024.
4. We shipped a webhook-handler refactor on Thursday — moving subscription-updated logic from a controller into a job.
5. Strictly the double-charge. Refunds will be handled separately by ops once the bleeding stops.
6. Must merge by Sunday EOD. No schema migrations. Public API surface (Stripe webhook handlers) must not change shape.

## Output brief

```markdown
## Symptom
Customers upgrading from Basic to Pro mid-cycle are charged twice: once at the correct prorated amount, then again ~30 seconds later at the full Pro amount.

## Expected behavior
A single prorated charge for the remainder of the cycle. This was the behavior before Thursday's webhook-handler refactor.

## Reproduction
1. Customer on Basic plan, mid-cycle.
2. Customer upgrades to Pro via the dashboard.
3. Stripe issues the prorated charge (correct).
4. ~30 seconds later, Stripe issues a second charge for the full Pro amount (bug).

(Repro confirmed in production logs; not yet reproduced in staging.)

## Repo
`billing-service`

## Scope of fix
- In: stop the second charge.
- Out: refunding affected customers (ops will handle out-of-band), broader audit of the webhook-handler refactor, schema migrations.

## Approach
1. Reproduce in staging by replaying the production webhook sequence. Confirm the second charge originates in the new job, not in Stripe. Report findings.
2. Propose minimal fix. Stop for approval.
3. Implement minimal fix with regression test that walks the upgrade path and asserts exactly one charge.

## Deliverables
- Root-cause writeup naming the line in the Thursday refactor
- One PR with fix + regression test

## Constraints
- Must merge by Sunday EOD (Monday billing run).
- No schema migrations.
- Public webhook-handler surface must not change shape.
- Strong suspicion: the Thursday refactor moved subscription-updated logic into a job, and either the controller path is still firing (double-handling) or the job is double-firing.
```

---

**Next step:** paste this into a fresh session, or say `go` and the executor reproduces in staging, finds the duplicate code path, and proposes the fix before changing anything.
