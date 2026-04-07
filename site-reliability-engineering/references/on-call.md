# On-Call

On-call is a system, not a list of names. Designed well, it produces fast incident response and a sustainable team. Designed badly, it produces missed pages, burnout, and quiet attrition. The single best predictor of "is this engineering org healthy" is whether on-call is something engineers tolerate or actively dread.

This file is the playbook for designing and running a rotation that respects both **production** and **the people**.

## Primary Goals of an On-Call Rotation

In priority order:

1. **Pages get answered** — primary always, escalation always works, no silent failure.
2. **The team stays healthy** — sleep is protected, work is bounded, fairness is enforced.
3. **Incident knowledge spreads** — every shift produces learning, not just heroics.
4. **The system gets better** — the on-call's first job after the page is to make the page not happen again.

If the rotation produces fast pages but burns out the team, it has failed. If the team is happy but the pages don't get answered, it has failed. Both must hold.

## Rotation Patterns

### Single primary

One person on call at a time. Rotates by week (most common), day, or shift.

- **Use when**: small team (3–6 engineers), low page volume, single timezone.
- **Avoid when**: page volume exceeds ~2 per shift, team has fewer than 4 people (no fair rotation possible), or team spans timezones.

### Primary + secondary

A primary handles pages; a secondary takes over if the primary doesn't ack within the escalation window, and is the escalation for hard incidents.

- **Use when**: any team where missing a single page is unacceptable.
- **The secondary is not a backup pager**; they exist to *prevent* missed pages and to share load on multi-page incidents.

### Follow-the-sun

Rotation hands off between geographic regions every ~8 hours so nobody is on call overnight.

- **Use when**: team has people in 2–3 well-distributed timezones.
- **Hard requirement**: explicit handoff at every shift change. See [handoff rituals](#handoff-rituals).
- **Trap**: doesn't work with two timezones eight hours apart — there's still a six-hour overlap with no coverage. You need three regions or a timezone gap small enough to absorb.

### Tier 1 / tier 2

Tier 1 (often a dedicated ops or SRE team) handles initial triage; tier 2 (the dev team) is escalated to for hard problems.

- **Use when**: very large org, very high volume of routine alerts.
- **Trap**: insulates dev teams from the consequences of their alerts and code, weakening incentive to fix root causes. Cap the percentage of incidents tier 1 can resolve without escalation, or accept that quality will rot.

## Sizing the Rotation

**Minimum:** 4 people. Below this, fairness breaks down — one person being on vacation puts the entire rotation on the remaining members. 5–8 is the sweet spot.

**Page load:** if average pages per shift exceed ~2, the rotation is unsustainable. The fix is **always to reduce pages**, not to add people. (Adding people without reducing pages is the same problem distributed.)

**Sleep nights expected:** assume the on-call will lose sleep on roughly 1 in 3 shifts. If you're losing sleep more often than that, your alerting is broken; see [alerting-and-paging.md](alerting-and-paging.md).

## Handoff Rituals

The most error-prone moment in any rotation is the handoff between shifts. The outgoing on-call has context the incoming one needs:

- **Open incidents** and current state.
- **Recently mitigated** issues that might reignite.
- **Known degraded dependencies** and what to expect.
- **Planned maintenance** during the upcoming shift.
- **Anything weird** that didn't quite cross the alert threshold but is worth watching.

A handoff template (whether posted in a chat channel or done synchronously):

```markdown
## On-Call Handoff — 2026-04-07 09:00 → 16:00

**Outgoing:** Glenn
**Incoming:** Alex

### Open incidents
- INC-2031: checkout 5xx spike, mitigated by rollback at 14:23. Postmortem owner: payments team.
- (none other)

### Watch list
- API gateway p99 trending up over the last 4 hours; not yet over SLO. Dashboard: <link>
- Cache fleet running on warmup after this morning's deploy; expect higher origin load until ~10:00.

### Recent changes
- Deploy of payments-svc v1.42 at 13:00. Observed clean.
- Pulumi update on prod cluster scheduled for 11:00 by infra team.

### Anything else
- Customer X is testing a load scenario from 10:00–12:00; expect ~5x normal traffic on /api/v1/search.

### Acknowledged?
- [ ] Incoming has read this and questions answered.
```

The incoming person **must explicitly acknowledge** the handoff. Silent handoff is no handoff.

## Compensation

On-call is work. Compensate for it. The cultural mistakes here are expensive:

- **Unpaid on-call burns the team out and produces attrition.** Eventually the people who can leave do leave.
- **"Voluntary" rotations skew toward the same few volunteers** until they break.
- **Comp time, paid stipends, or hourly rates** all work; the right one depends on local laws and norms. Pick *something* explicit and apply it consistently.

A reasonable default in tech: a stipend per week of primary on-call, doubled or tripled for being paged outside business hours, plus comp time for any night that involved active incident response. Document it; don't make people negotiate.

## Sleep Protection

Sleep loss is cumulative and expensive. Protect it:

- **Anyone paged after midnight gets the next morning off.** Not optional. Their work the next day is worth less than their sleep.
- **No on-call shift longer than 12 hours of "active" coverage** when page volume is high. Split it.
- **No on-call shift the day before or after vacation.** Hand off cleanly.
- **Track lost-sleep incidents** as a team metric. They are a leading indicator of attrition.
- **The on-call should not be expected to do project work during the shift** if page volume is non-trivial. Trying to do both produces neither.

The team lead's job is to enforce these protections *for* the team, not to make them earn them.

## Onboarding to On-Call

Nobody goes on-call solo on their first rotation. The standard onboarding sequence:

1. **Shadow** an experienced on-call for a full shift. Read every incident, ask questions.
2. **Reverse-shadow**: take pages with the experienced on-call observing and ready to take over.
3. **First solo shift** is paired with a designated escalation buddy, *not* the secondary.
4. After 2–3 solo shifts, the new on-call is fully integrated.

For an engineer who has never done on-call before, a week of reading runbooks and incident archives is useful prep. So is a tabletop exercise — see [chaos-and-resilience.md](chaos-and-resilience.md).

## What the On-Call Does (Beyond Answering Pages)

A productive on-call shift looks like:

- **Watching dashboards** during business hours, especially around deploys.
- **Triaging the alert queue** — silencing what's noise, fixing what's been pending.
- **Improving runbooks** — every page that involves "wait, what does this mean?" produces a runbook edit.
- **Writing or scheduling postmortems** for any incident that hit user pain.
- **Owning the on-call backlog** — the toil that the team has agreed to chip away at during slow shifts.
- **Doing the handoff well**.

Notice what's not on this list: shipping features. The on-call is the team's *operational* shield this week; their feature work is paused or background.

## Wellbeing Check-Ins

After every nontrivial incident, the on-call's manager checks in. Two questions:

1. "How are you feeling about that one?"
2. "Is there anything you need?"

This is not therapy; it's pattern recognition. An engineer who answers "fine, nothing" three incidents in a row when they're clearly worn down is signaling — listen.

## Anti-Patterns

- **The hero rotation.** One person handles the hard incidents because they're the only one who knows the system. They burn out, leave, and the team is now blind. Fix by deliberately rotating responsibility and writing the things they know into runbooks.
- **No secondary, no backup.** A single missed ack becomes a missed incident.
- **Punitive on-call.** Used as a tool to make people "pay attention to quality" by inflicting pain. This produces attrition, not quality.
- **Silent rotation.** Engineers don't know who's on call this week. Fix by surfacing it in the team channel topic.
- **No pager test.** Engineers go on call without ever confirming the pager works. The first real page is at 3am.
- **Manager-immune rotation.** Managers are exempt. The team learns that on-call is something junior people do. Fix by including the manager (in a low-traffic seat if needed).
- **No compensation.** See above. Burnout, attrition, and a long-term reputation problem.
- **24/7 single-region rotation with 3 people.** Each person on call ⅓ of the time, sleep destroyed in rotation. Either grow the team or change the page severity until follow-the-sun works or the rotation shrinks.
- **"Everyone is always on call."** Ambient guilt for everyone, accountability for nobody.
- **Page volume hidden from leadership.** If the people deciding budget don't see the page-per-week graph, they don't fund the work to reduce it.

## Related

- [alerting-and-paging.md](alerting-and-paging.md) — fewer/better pages is the most effective on-call improvement
- [incident-response.md](incident-response.md) — what to do once a page is acked
- [postmortems.md](postmortems.md) — turning incidents into permanent improvements
- [toil-and-automation.md](toil-and-automation.md) — recurring on-call work is toil; reduce it
- [runbooks.md](runbooks.md) — the on-call's most-used document
