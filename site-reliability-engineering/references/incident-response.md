# Incident Response

An incident is in progress when something is wrong in production *and someone has been paged about it*. Your job from that moment until the customer stops feeling pain is to **mitigate fast, communicate clearly, and resist the urge to chase root cause before the bleeding stops**.

The two most common failures during an incident:

1. **Diagnosing before mitigating.** "I want to understand it before I touch it." Meanwhile users keep failing.
2. **Communicating poorly.** Internal stakeholders, customers, and the next responder all need to know what's happening; if you don't tell them, they'll interrupt you or escalate over you.

Both are habits, and both are trainable.

## Roles

For anything bigger than a SEV 3, separate the work into roles. Even a single responder can wear multiple hats — but they should *know* which hat they're wearing at each moment.

### Incident Commander (IC)

Owns the incident from start to finish. **Does not fix anything themselves.** Their job is to coordinate.

- Decides severity and escalates if it changes.
- Assigns roles.
- Makes the mitigate-vs-investigate calls.
- Decides when the incident is mitigated and when it's resolved.
- Hands off to the next IC at shift end if the incident is long-running.

If you don't have a designated IC, *the first responder is the IC by default* until they explicitly hand it off.

### Operations / Subject Matter Expert (Ops)

The person actually executing the mitigation: rolling back, draining traffic, scaling up, restarting, applying the runbook step.

Multiple ops people are fine for big incidents, but the IC must coordinate them so they don't conflict.

### Communications Lead

Owns external and internal status updates. Talks to the customer-facing teams, posts to the status page, updates the incident channel. **The IC and ops people should not be writing comms** — they're too busy.

For SEV 3 and below, the IC can absorb this role. For SEV 1, it's a dedicated person.

### Scribe

Writes down what's happening, in real time, with timestamps. The transcript is the basis for the postmortem and for any compliance reporting.

A bot in the incident channel often handles this — every message is timestamped automatically. Otherwise, designate a human.

## Severity (Decided Up Front, Adjusted as You Learn)

See [alerting-and-paging.md](alerting-and-paging.md#severity-tiers) for the full scale. Two rules during the incident:

1. **Start at the highest plausible severity.** It's easier to downgrade than to upgrade. If the dashboard shows 30% errors and you're not sure how big "30%" really is, treat it as SEV 1 until you know.
2. **Severity is decided by impact, not by visibility.** A scary-looking metric that nobody outside engineering can see is not SEV 1; an undetected data corruption affecting one user is not SEV 4 if the data is critical.

## The First Five Minutes

When a page lands, do these things, roughly in this order, regardless of severity:

1. **Acknowledge the page.** Stops escalation; tells the system someone is on it.
2. **Open the linked dashboard.** Confirm the alert is real (not a monitoring artifact).
3. **Confirm severity** by checking the actual user impact, not just the metric.
4. **Open or join the incident channel.** Many teams auto-create one per incident; if not, make one with a known naming convention (`#inc-2026-04-07-checkout-5xx`).
5. **Post an initial status update**:
   ```
   :rotating_light: SEV2 incident opened
   Service: checkout-api
   Symptom: ~5% error rate, ~6 minutes
   IC: <yourself>
   Status: investigating
   Next update: in 10 minutes
   ```
6. **Open the runbook** linked in the alert.

Until step 6, you have not started fixing anything. That's correct. The setup is fast and pays for itself many times over.

## Mitigate First, Diagnose Second

> **Stop the bleeding before you understand it.**

The instinct of every engineer with curiosity is to figure out *why* something is broken before changing anything. This is the wrong instinct in production.

The right sequence:

1. **Is there a known mitigation that works without understanding the cause?** Examples:
   - Rollback the last deploy.
   - Drain the affected region; route to a healthy one.
   - Scale up to absorb load.
   - Restart the misbehaving process.
   - Disable the broken feature flag.
   - Failover to the secondary.

   If yes, do it. *Then* diagnose with the pressure off.

2. **Is the mitigation reversible?** If yes, do it even if you're not sure it'll help.

3. **Is the mitigation worse than the symptom?** Rare, but real — e.g. a rollback might trigger a database migration that's worse than the bug. Use judgment, but bias toward action.

4. **Diagnosing is for after mitigation, or in parallel by a second person.** The IC should be making sure mitigation is happening, not staring at logs.

### Examples of "mitigate first" in practice

| Symptom | Mitigation (try first) | Diagnose (after) |
|---|---|---|
| 5xx rate spike right after deploy | Rollback | What changed in the deploy |
| One region failing, others healthy | Drain that region | What's wrong with that region |
| Latency spike correlated with load | Scale up + rate limit | Why this scale broke |
| One pod misbehaving | Restart it | Why it got stuck |
| Database CPU pegged | Kill long-running queries; failover to replica | Which query / which feature |
| Single user reporting failure | Investigate; don't reach for mitigation | (it's probably SEV 3) |
| Dependency returning errors | Cache last-known-good response, fail open or closed depending on the call | Talk to the dependency's team |

## Communication Cadence

Every SEV 1 or SEV 2 incident needs **regular status updates**, even if the update is "no change." The cadence is part of the contract with the rest of the org.

| Severity | Update frequency |
|---|---|
| SEV 1 | Every 15–30 minutes, plus on every state change |
| SEV 2 | Every 30–60 minutes |
| SEV 3 | At opening, on resolution |

Each update has the same shape:

```
:rotating_light: SEV2 — Checkout API elevated errors
Status: mitigated; observing
Impact: ~3% of checkouts failed between 14:17 and 14:38 UTC.
Mitigation: Rolled back payments-svc to v1.41 at 14:36.
Current state: Error rate normal for the last 6 minutes.
Next steps: Monitoring for 30 minutes; investigating root cause in parallel.
Next update: 15:15 UTC.
IC: Glenn
```

Three things this format gives you:

- **Stakeholders can ignore the rest of the channel** and still stay informed.
- **The next IC can pick up** by reading the most recent update.
- **The postmortem timeline** writes itself from these updates.

For SEV 1, also update the **public status page** on the same cadence. Acknowledging an incident publicly is uncomfortable but the alternative — customers finding out from each other — is much worse for trust.

## "Mitigated" vs "Resolved"

These are different, and conflating them is one of the most common failure modes.

- **Mitigated**: the user pain has stopped. The symptom is no longer occurring. The incident is no longer SEV 1/2 from a user perspective.
- **Resolved**: the underlying problem has been fixed. The mitigation is no longer needed; the system is back to normal operating mode.

A rollback is mitigation. The actual bug is still in the code; the next deploy that contains it will reintroduce the incident. The rollback doesn't *resolve* anything — it buys time.

The IC declares mitigation explicitly:

```
:white_check_mark: INCIDENT MITIGATED at 14:38 UTC.
Symptom no longer occurring. Service is operating normally.
Underlying cause not yet fixed; rollback is in place.
Postmortem: Glenn will own. Action items to follow.
This channel will remain open for 30 minutes for additional observations.
```

The incident is *resolved* later, often in a separate ticket, when the underlying fix has shipped through normal release.

## When to Call for Help

Call for more help **earlier than feels comfortable**. The cost of pulling someone in unnecessarily is tiny; the cost of struggling solo through a SEV 1 because you didn't want to wake anyone is enormous.

Specific triggers:

- The incident has been going for **15 minutes with no clear mitigation path**.
- You're **not the right SME** for what's broken.
- You're **tired or stressed** and your judgment is starting to slip.
- The **blast radius is growing** and you can't keep up with comms while ops-ing.
- You're approaching the **end of your shift** and the incident isn't done.

The escalation path should be in the runbook. If it isn't, it's the IC's job to find someone — by phone if necessary.

## Handing Off an Incident

Long incidents (more than a few hours) span shifts. The handoff is the most error-prone moment in the incident. Do it carefully:

1. **Designate the new IC explicitly.** Old IC says "Alex is now IC, effective now." New IC ack'd.
2. **Walk through the current state.** Old IC briefs new IC on:
   - What's broken, in plain English.
   - What's been tried.
   - What's currently mitigating it.
   - What's currently being investigated.
   - What hasn't been tried yet.
3. **Update the channel.** "IC handoff complete. Alex is now IC."
4. **Old IC stays available for ~15 minutes** to answer questions, then explicitly disconnects.

Don't hand off mid-action. Finish the action you're in, then hand off cleanly.

## Customer Communication

For SEV 1 and SEV 2 incidents that touch external users, the customer needs to hear from you. Three rules:

1. **Acknowledge fast, even with limited information.** Silence is worse than uncertainty.
2. **Be specific about what's affected.** Customers can't act on "we're seeing some issues."
3. **Don't promise a timeline you can't keep.** "We're investigating; next update in 30 minutes" is honest. "Should be fixed in 10 minutes" is a hostage to fortune.

A good first public update:

> We are investigating reports of failed payments on our Checkout API affecting some customers in the EU region. Our team is engaged. We will update at 14:45 UTC.

That's it. No speculation, no causes, no apologies that sound like deflections. The next update will be more informative.

## After Mitigation

The incident isn't *over*; it's mitigated. The IC's checklist for the cooldown:

- [ ] Confirm mitigation is holding (watch metrics for 15–30 minutes).
- [ ] Update the channel and status page that mitigation is in place.
- [ ] Note that root cause investigation continues separately.
- [ ] Schedule the postmortem (within 5 business days; sooner for SEV 1).
- [ ] Assign a postmortem owner.
- [ ] Tag the incident channel with `mitigated`.
- [ ] Send the team home; the on-call now resumes normal duties or hands off.

The IC then writes the **incident summary** while it's fresh: a short paragraph for the postmortem template that captures what happened, when, how it was mitigated, and the impact. See [postmortems.md](postmortems.md).

## Anti-Patterns

- **Diagnose-first.** Spending 40 minutes reading logs while the error rate stays at 30%.
- **Lone wolf.** Never asks for help, fixes everything personally, and burns out. Or worse — gets it wrong because nobody was checking the work.
- **Silent operator.** Doing fixes without telling the channel. Other responders try the same things in parallel; comms team has no idea what to tell customers.
- **Premature all-clear.** Declaring mitigation before the metric has actually recovered. The incident "comes back" five minutes later, much louder.
- **No IC.** Several people fixing things in parallel, no coordination, conflicting actions. Inevitable when the team hasn't agreed on the IC role.
- **The IC who fixes things.** IC tries to debug *and* coordinate *and* communicate. All three suffer; the incident drags.
- **"It's resolved"** when it's really mitigated. The fix never lands; the incident reoccurs in two weeks under new alert noise.
- **Postmortem skipped because "we know what happened."** Then the action items never ship and the same incident happens again.
- **Skipping severity escalation** because "we don't want to scare leadership." Leadership being scared is the *point* — they fund reliability work.
- **Customer communication delayed** until you have the full picture. By then customers are tweeting about the outage.

## Related

- [alerting-and-paging.md](alerting-and-paging.md) — what wakes you up in the first place
- [postmortems.md](postmortems.md) — what happens after the dust settles
- [runbooks.md](runbooks.md) — the document you open in step 6 above
- [on-call.md](on-call.md) — the rotation that makes this sustainable
- [security-engineering](../../security-engineering/SKILL.md) — security incidents follow the same playbook with extra care around comms and chain-of-custody
- [assets/incident-template.md](../assets/incident-template.md) — fillable template for use during a live incident
