# Postmortems

A postmortem is the practice of turning an incident into permanent organizational learning. Done well, the same incident never happens twice. Done badly, postmortems are theater: a document gets written, nobody reads it, and the same outage happens again in three months under a different alert.

The single most important thing about postmortems: **they are blameless, or they are useless.** The first time you point a finger at a person, you have stopped collecting the truth. You can have blame, or you can have learning. Pick one.

## What a Postmortem Is For

In priority order:

1. **Generate action items that ship.** Permanent reductions in the chance of this incident happening again.
2. **Spread knowledge.** Other teams learn what broke, what was tried, and what worked, without having to live through it.
3. **Surface contributing factors** that aren't obvious during the incident — process gaps, missing instrumentation, misaligned incentives.
4. **Accountability without blame.** Owners are named for action items; those owners are responsible for *fixing forward*, not for "what they did wrong."

A postmortem is not for:

- Punishing the responder.
- Performing thoroughness for an audit.
- Producing a document nobody will read.
- Closing a ticket so the team can move on.

If you're writing one for any of those reasons, you're producing waste.

## When to Write One

Required:

- Any **SEV 1** or **SEV 2** incident.
- Any incident where the **error budget was significantly burned**.
- Any incident with **customer-visible data loss or corruption**, regardless of severity.
- Any **near-miss** that, if one variable had been slightly different, would have been a SEV 1.

Optional but encouraged:

- A **surprising success** — the system handled something better than expected. Find out why, codify it.
- A **recurring SEV 3** that has happened more than twice. The first occurrence is unlucky; the third is a pattern.

Not required:

- Single-customer SEV 4s with obvious causes and no broader implication.
- Fully-known incidents whose action items are already in flight from a previous postmortem.

## Blameless Culture, Concretely

"Blameless" is easy to *claim* and hard to *practice*. The test:

> Could a junior engineer admit they made the change that caused the incident, in writing, in this document, and expect to be treated as a source of information rather than a source of fault?

If the answer is no, the postmortem is not blameless.

### Concrete rules

- **Use passive or descriptive voice for actions, active voice for systems.**
  - ❌ "Glenn deployed v1.42, which broke checkout."
  - ✅ "Version 1.42 was deployed at 13:00 UTC. The deploy passed CI but introduced a regression in payment processing that was not caught by the existing tests."
- **Never include the word "should have".** Say "the existing process did not require X; we will change the process to require X."
- **Frame human error as a system problem.** "The responder was unaware that the migration had to be run before the deploy." → "The deploy process did not enforce migration ordering."
- **Praise, don't blame.** "The on-call mitigated the incident in 12 minutes by rolling back; the speed of response prevented further impact."
- **Separate the postmortem document from the conversation.** People may be defensive in writing; talk through the harder parts in person before drafting.
- **Senior people set the tone.** If the most senior person in the room is willing to admit they might have made the mistake, everyone else relaxes.

### What blame looks like (avoid)

- "The engineer should have noticed."
- "If only X had double-checked."
- "It was a careless mistake."
- "This was preventable if Y had followed the process."

### What contributing factors look like (use)

- "The migration safety check was disabled in the staging environment, so the failure mode was not exercised before production."
- "The runbook for this alert had not been updated since the architecture change six months earlier."
- "The dashboard that would have shown the underlying queue depth was on a different team's Grafana instance and was not linked from the alert."
- "The deploy pipeline ran the migration after the application was rolled out, leading to a window where the new code expected a column that did not yet exist."

Notice: every contributing factor names a *thing in the system* that can be changed.

## The Five-Whys (Carefully)

The five-whys technique can be useful for surfacing contributing factors, but only if practiced with discipline:

- **Each "why" should target the system or process, not the person.**
  - ❌ "Why did the engineer deploy without testing?" → "Because they were rushed."
  - ✅ "Why did the deploy proceed without the test passing?" → "Because the CI flag was disabled in this branch."
- **Stop when you've found a fixable contributing factor**, not at five exactly. Sometimes you find it at three.
- **Branch when there are multiple causes.** Real incidents usually have several contributing factors, not a single chain.

## Structure of a Postmortem

A useful postmortem has the following sections. (See [assets/postmortem-template.md](../assets/postmortem-template.md) for a fillable version.)

### 1. Summary (one paragraph)

A non-technical reader should understand what broke, who it affected, and how it was resolved. Three or four sentences.

### 2. Impact

- Which users were affected?
- How many?
- For how long?
- Quantified if possible: "approximately 2,400 checkouts failed between 14:17 and 14:38, an estimated $14k in lost gross revenue."
- SLO impact: "consumed 65% of the monthly error budget for checkout availability."

### 3. Timeline

A bulleted list with timestamps in UTC. Pull from the incident channel where possible.

```
14:17 UTC — Deploy of payments-svc v1.42 to production completes.
14:19 UTC — Burn-rate alert fires (5m window, rate 22x).
14:21 UTC — On-call (Glenn) acknowledges page; opens incident channel.
14:22 UTC — IC declares SEV 2; comms posts internal status update.
14:25 UTC — Initial hypothesis: dependency outage. Investigation starts in parallel with mitigation.
14:32 UTC — Hypothesis updated: deploy correlation suspected; rollback initiated.
14:36 UTC — Rollback complete.
14:38 UTC — Error rate returns to normal. Mitigation confirmed.
14:40 UTC — Mitigation declared in channel and on status page.
15:10 UTC — Underlying cause identified (see Root Cause section).
```

### 4. Root Cause / Contributing Factors

**Resist the urge to name a single root cause.** Real incidents usually have multiple contributing factors that combined to produce the failure. List them.

For each factor:

- What it was.
- Why it was there.
- What would have prevented it from contributing.

Example:

> **Contributing factor 1: Migration ordering not enforced by the deploy pipeline.** The deploy pipeline runs the application rollout in parallel with database migrations, with no dependency between them. Version 1.42 added a new column reference; the migration to add the column had not yet completed when v1.42 began serving traffic. Enforcing migration-before-rollout in the pipeline would have prevented the window of inconsistency.
>
> **Contributing factor 2: Test gap.** The test suite for payments-svc mocks the database schema rather than running against a real migration. The missing column was therefore not detected by CI. Running integration tests against a freshly migrated test database would have caught this.
>
> **Contributing factor 3: Alert lag.** The error rate alert fired 2 minutes after the symptom began. This is within budget for SEV 2, but a faster (1m short window) alert would have shaved time off mitigation.

### 5. What Went Well

This section is mandatory. Postmortems that *only* enumerate failures train teams to expect blame. Name the things that worked:

- "The burn-rate alert fired within 2 minutes of the symptom; previous configuration would have taken 15 minutes."
- "The on-call's first action was to open the runbook, which contained the rollback command they ended up using."
- "Communication cadence was clear; the customer success team had the information they needed without having to ask."
- "The rollback was clean and reversible; v1.41 had not had any database state migrations applied since."

### 6. What Could Have Gone Better

The honest counterpart to "what went well." Things that delayed mitigation, made the incident harder to diagnose, or made the response stressful.

- "The dashboard for payments-svc was not linked from the alert; the responder spent ~3 minutes finding it."
- "There was no clear escalation path documented; the responder hesitated before paging the secondary."
- "The customer-facing status page was updated 12 minutes after the public-facing incident channel; customers had already noticed."

These items often become action items.

### 7. Action Items

This is the most important section. Action items must be:

- **Specific.** "Add migration ordering enforcement to the deploy pipeline" — not "improve deploy safety."
- **Owned.** A named individual or team. "TBD" is the same as "never."
- **Tracked.** A ticket reference. The action item exists in the team's backlog, not just in the postmortem document.
- **Prioritized.** Each item gets a priority (P0/P1/P2). P0 means "before the next normal sprint"; P1 means "this quarter"; P2 means "on the backlog with intent to ship."
- **Bounded.** A 6-month epic is not an action item. Break it down.

Example:

| # | Action item | Owner | Priority | Ticket |
|---|---|---|---|---|
| 1 | Add migration-before-rollout enforcement to the deploy pipeline | platform team | P0 | INFRA-2031 |
| 2 | Update payments-svc tests to run against a real migrated DB | payments team | P1 | PAY-1842 |
| 3 | Link the payments-svc dashboard from the alert template | SRE | P0 | SRE-512 |
| 4 | Tighten the burn-rate alert short window from 5m to 1m | SRE | P1 | SRE-513 |
| 5 | Document the escalation path for the payments-svc rotation | payments team | P0 | PAY-1843 |
| 6 | Add automatic status page update on incident-channel creation for SEV 1/2 | comms team | P2 | COMMS-44 |

### 8. Lessons Learned

A short prose section for the things that don't fit cleanly as action items but are worth remembering:

- "Mocks of the database schema in tests can produce false confidence; integration tests against a real migrated DB are worth the runtime cost."
- "Burn-rate alerts work; the speed of detection here justified the effort to set them up."
- "Our incident comms cadence is good but the public side lags the internal side by ~10 minutes — worth automating."

## The Postmortem Review

A draft is not a postmortem. The document must be **reviewed in a meeting** with the team, the IC, the on-call, and ideally a representative from the affected stakeholder group (product, customer success).

### What the review meeting is for

- **Sanity-check the timeline and contributing factors.** Often someone in the room has context the writer missed.
- **Pressure-test the action items.** Are they specific enough? Owned? Realistic?
- **Spread the learning.** People who weren't in the incident learn from those who were.
- **Catch blame leakage.** A reader from outside the immediate team may notice phrasing the writer didn't.

### What the review meeting is *not* for

- Litigating who's at fault.
- Re-opening decisions made during the incident.
- Adding speculative action items the team has no intent to ship.

### Cadence

A SEV 1 review is a dedicated meeting; usually within five business days. SEV 2 reviews can be combined into a weekly "ops review" where multiple postmortems are walked through.

## Action Item Follow-Through

The single biggest failure mode of postmortem programs is that **action items don't ship**. They get filed, forgotten, and the same incident happens again.

### What works

- **Action items are tickets in the team's normal backlog**, not in a separate postmortem tool nobody looks at.
- **A standing review** (monthly is fine) walks through all open postmortem action items and re-prioritizes any that haven't moved.
- **P0 action items block** the team's next sprint. No new feature work until they ship.
- **The team's reliability investment percentage** explicitly funds postmortem follow-through. Not "if there's time" — *if there isn't time, the work is the wrong shape*.
- **Stalled action items become incidents themselves.** After 90 days unmoved, the SRE lead escalates.

### What doesn't work

- Action items in a wiki nobody owns.
- Action items assigned to "the team" instead of an individual.
- Action items that depend on someone else's roadmap with no commitment from that team.
- "Improve testing" as an action item.

## Postmortems for Near-Misses

A near-miss is an incident that almost happened but didn't, because of luck or because someone caught it. These are gold:

- The cost is low (no actual user pain).
- The lesson is the same as a real incident.
- People are less defensive, so the discussion is honest.

Treat near-misses as full postmortems. The action items are usually cheap and high-impact: "we got lucky here, let's not get lucky next time."

## Anti-Patterns

- **The blame postmortem.** Names a person or team as the cause. Produces fear, hides truth, recurs.
- **The sanitized postmortem.** Written defensively for an audience of executives or auditors. The real lessons are in a private document the team uses instead.
- **The single-root-cause postmortem.** Lists exactly one cause. Real incidents have several; you missed some.
- **The action-item-free postmortem.** "We talked about it." Nothing changes. Same incident in two months.
- **The postmortem nobody reads.** Filed, never opened. Reading and *citing* postmortems in design discussions is how the lessons travel.
- **Postmortem gatekeeping.** "We didn't write a postmortem because the cause was obvious." If it had been obvious *before* the incident, the incident wouldn't have happened. Write it.
- **The "unowned" action item.** "Eventually we'll fix this." Eventually means never.
- **The boilerplate postmortem.** Same template fields filled in by reflex with no real content. Worse than no postmortem because it crowds out the real work.
- **Postmortems that never reference each other.** Three separate incidents have the same contributing factor; nobody notices because the postmortems live in isolation. Build an index. Search them.

## Related

- [incident-response.md](incident-response.md) — the data the postmortem draws from
- [alerting-and-paging.md](alerting-and-paging.md) — alert improvements are common postmortem action items
- [runbooks.md](runbooks.md) — runbook improvements are also common
- [toil-and-automation.md](toil-and-automation.md) — recurring incidents become automation work
- [team-lead](../../team-lead/SKILL.md) — action items become tickets
- [assets/postmortem-template.md](../assets/postmortem-template.md) — fillable template
