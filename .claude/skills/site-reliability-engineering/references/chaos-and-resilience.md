# Chaos Engineering and Resilience Testing

The premise of chaos engineering is simple and uncomfortable: **the only way to know whether your system handles a failure is to cause one.** Every untested failure mode is a future incident.

The mature form of this practice is *not* "let's break things in production and see what happens." It's a disciplined experiment: a hypothesis, a contained blast radius, instrumentation to confirm or refute the hypothesis, and a clear stop condition.

The central tension: chaos exercises produce the most learning when they're closest to real production conditions, *and* they produce the most damage when the system isn't ready. Get the readiness right before you turn on the chaos.

## The Spectrum

There are five levels of resilience testing, from least invasive to most:

| Level | What it is | When to use |
|---|---|---|
| **Tabletop** | Walk through a failure scenario in a meeting | Always start here |
| **Gameday** | Simulate a failure in a controlled environment with the on-call team | Before any real chaos |
| **Fault injection in staging** | Actually break things in a non-production environment | Once gameday has been clean |
| **Fault injection in production, with a small blast radius** | Targeted, observed, with stop conditions | Once staging chaos is routine |
| **Continuous chaos in production** | Automated, ambient, always running | Mature org with strong observability |

**Most teams should not be running continuous production chaos.** They should be running tabletops and gamedays. The hierarchy is for a reason: each level requires more confidence in the layers below.

## Tabletop Exercises

A tabletop is the cheapest, safest, and most underused form of resilience testing. Pick a failure scenario, walk through it in a meeting, ask the team how they would respond.

### Format

1. **Pick a scenario.** "Region us-east-1 becomes completely unreachable for 2 hours starting at 14:00 UTC." Or: "Our payment processor stops returning successful responses but still accepts requests."
2. **Pick the participants.** The on-call rotation, an SRE, and ideally someone from a dependent team or product.
3. **Walk through it minute by minute.** Someone facilitates ("You get the page at 14:02. What does it say?"). The team narrates what they would do, what alerts would fire, what runbooks they'd open, what they'd communicate.
4. **Note every gap.** Things the team can't answer, runbooks that don't exist, dashboards they couldn't find, escalation paths nobody knew. These are the action items.
5. **Don't fix things in the meeting.** Capture the gaps; assign owners; schedule the fixes; re-run the tabletop later.

### What you learn

- Which alerts would fire and which wouldn't.
- Whether the runbooks for the relevant alerts exist and are accurate.
- Whether the dashboard the responder needs is findable.
- Whether the escalation path is clear.
- Whether the team has a shared mental model of the system, or multiple inconsistent ones.
- Whether the right *external* communication would happen on the right cadence.

A tabletop costs an hour and finds problems that would otherwise be discovered at 3am during a real incident. It is the cheapest possible resilience investment.

## Gamedays

A gameday is a step up: an *actually staged* incident in a controlled environment, with the on-call team responding as if it were real.

### Setup

- **Pick a target environment**: usually a full staging environment or a production cell that's been drained of real traffic.
- **Pick a scenario.** Specific and bounded: "Inject 50% packet loss between the API gateway and the payments service for 20 minutes."
- **Define hypotheses up front.** "We expect: alerts X and Y to fire within 3 minutes; the on-call to follow runbook Z; the system to remain up via the failover path."
- **Define stop conditions.** "If real customers are affected, stop. If the on-call gets stuck for more than 15 minutes without a path forward, stop. If anyone in the room thinks something is genuinely wrong, stop."
- **Brief the team.** Everyone knows it's a gameday, but they respond as if it were real. (For more advanced gamedays, you can run *unannounced* exercises — but only when the team has been doing announced ones successfully for a while.)
- **Have an observer.** Someone who is not responding, just watching and taking notes for the postmortem.

### Run the gameday

The exercise looks like a real incident: pages fire, runbooks open, IC declares roles, comms happen. The observer watches for:

- Time from injection to first page.
- Time from page to first action.
- Time from first action to mitigation.
- Whether the runbook was correct.
- Whether the diagnosis was correct.
- Communication clarity.
- Anything the responder said out loud that revealed a gap ("wait, where's the dashboard for this?").

### Postmortem the gameday

A gameday produces a real postmortem. The action items are usually concrete: fix this runbook, add this dashboard, automate this manual step, change this alert threshold.

The team gets the same lessons they'd get from a real incident, without the user impact.

## Fault Injection in Staging

Once gamedays are routine, the next level is *automated* fault injection in staging: tools like Chaos Mesh, Gremlin, AWS Fault Injection Simulator, or Litmus that programmatically introduce failures.

### What to inject

In rough order of value-per-effort:

1. **Network latency** between services. Most production incidents look like "everything got slower"; can your system tolerate a real version of that?
2. **Network partition** — completely block traffic between two services. Does the system fall over, or degrade gracefully?
3. **Pod / process kill** — kill a random instance. Does the load balancer route around it? Do new instances start cleanly?
4. **Disk full** on a node. Does the system handle it without corruption?
5. **Clock skew** between nodes. (Surprisingly common cause of subtle bugs.)
6. **Dependency outage** — kill the database, the cache, the broker. Does the rest of the system handle it as designed?
7. **DNS failure** — block the resolver. (Most services fail in spectacular ways here.)
8. **Slow disk** — add latency to disk operations. Surfaces a lot of buried timeout assumptions.

### Rules

- **Define the experiment as a hypothesis.** "When we inject 200ms latency on the payments-service to db connection, we expect the circuit breaker to trip within 30 seconds and the service to return cached responses for the next 5 minutes."
- **Have a kill switch.** A single command stops the experiment immediately. Test it before you start the experiment.
- **Run during business hours** the first several times. The team should be awake and watching.
- **Start small** and expand the blast radius gradually. First injection: one pod, 30 seconds. Tenth injection: an entire service, 30 minutes.
- **Have observability ready before you inject.** If you can't tell what the experiment is doing to the system, you're not learning anything; you're just damaging things.

## Production Chaos

Production chaos is the most controversial form of resilience testing, and the most valuable when done right. The reason: **staging never fully reproduces production**, so some failure modes only exist in production. Chaos in production finds them.

### Prerequisites

Before running any chaos in production:

1. **Mature observability.** You can see what's happening in real time, on every service involved.
2. **Tested mitigation paths.** Rollback, drain, scale-up — all known to work in non-chaos contexts.
3. **An incident response process the team has practiced.** This is not the time to discover that your IC role isn't defined.
4. **Strong on-call rotation** — see [on-call.md](on-call.md).
5. **Stakeholder buy-in.** Product, customer success, and leadership know production chaos is happening, and have agreed to the blast radius limits.
6. **Insurance:** SLOs are healthy, error budget is well above zero, and no major launches are in flight.

If any of these are missing, **you are not ready for production chaos**. Stay in staging.

### Rules

- **Smallest possible blast radius.** A single pod, a single AZ, a small percentage of users. Never the whole fleet.
- **Defined stop conditions in advance.** "If error rate exceeds 0.5%, abort." Automated where possible.
- **A human watching.** Not a script, not a dashboard refresh — a person whose job during the experiment is to abort if something looks wrong.
- **Daytime, weekday.** Never on Friday afternoon. Never during a holiday weekend.
- **Communicated.** The relevant teams (on-call, comms, leadership) know it's running.
- **Reversible.** You can undo it instantly.
- **Logged.** Every parameter, every observation, every action. The postmortem of a chaos experiment is as valuable as the postmortem of a real incident.

### What's worth running in production

- **Single-instance kills** to verify health checks and autoscaling.
- **Latency injection on a single dependency** to verify circuit breakers and timeouts.
- **Region failover tests** (drain a region, route to another, drain back).
- **Canary deploys** as a form of gentle, continuous chaos — every release is an experiment with a built-in rollback.

## Continuous / Ambient Chaos

The most mature form: a tool like Chaos Monkey running continuously, randomly killing instances during business hours. This is *not* an experiment per kill; it's a *baseline* that forces the team to design every service to handle instance loss as a non-event.

This works only when:

- Instance loss is genuinely a non-event for every service.
- Observability catches anything that *isn't* a non-event immediately.
- The team has been running gamedays and bounded chaos for at least a year and gotten clean results.

Most teams will never get here. That's fine.

## When Chaos Is Malpractice

Chaos engineering is not always appropriate. **Skip it (or postpone it) when**:

- You don't have observability good enough to tell what's happening when you break things.
- The on-call team isn't trained on incident response.
- There are unaddressed action items from previous incidents.
- The system has known reliability problems that haven't been fixed yet — chaos tells you "things are broken," which you already know.
- A major launch, regulatory deadline, or critical business event is in flight.
- The error budget is exhausted.
- You're proposing chaos in production without first running it in staging.
- Stakeholders haven't agreed.

The point of chaos engineering is to *find* unknown problems. If you have known problems, fix them first. Chaos is not therapy.

## Building a Resilience Practice

A practical roadmap for a team starting from zero:

| Quarter | Activity |
|---|---|
| Q1 | Run a tabletop exercise once a month. No real failures. Pure walkthrough. |
| Q2 | Run a gameday in staging once per quarter. Bounded scenario, observed by SRE. |
| Q3 | Add automated fault injection in staging on a recurring schedule. Minor incidents. |
| Q4 | Run a single bounded production chaos experiment. One pod, one minute, full observation. |
| Year 2 | Expand production chaos to dependency failures and regional drills. |
| Year 3 | Continuous chaos in production for the most critical services. |

Most of the value comes in the first two quarters. Don't skip ahead.

## Anti-Patterns

- **Chaos for theater.** Run because someone read a blog post; no hypothesis, no learning, no action items. Just damage.
- **Production chaos before staging chaos.** Skipping the cheaper, safer practice and going straight for the dramatic one.
- **No stop condition.** "Let's see what happens." What happens is an unmitigated outage.
- **No observer.** Nobody is watching the experiment; the team finds out about the damage from the alert queue.
- **Chaos targeting things you already know are broken.** You're just causing the incident you've been avoiding.
- **Friday chaos.** Or weekend chaos. Or holiday chaos. The team that has to clean up isn't there.
- **Chaos as a substitute for fixing things.** "We injected the failure and it worked!" No it didn't — it produced an incident, which you then mitigated. The system is still fragile.
- **Untested kill switch.** The "abort" command has never actually been verified. When you need it, it doesn't work.
- **No postmortem of the chaos experiment.** You learn less than half of what you would have learned with a postmortem.
- **Expanding blast radius too fast.** First experiment is one pod for 30 seconds; second experiment is the whole region for an hour. Mature gradually.

## Related

- [incident-response.md](incident-response.md) — chaos exercises practice incident response
- [postmortems.md](postmortems.md) — gameday and chaos postmortems use the same template as real incidents
- [capacity-and-load-management.md](capacity-and-load-management.md) — degradation paths discovered by chaos exercises
- [system-architect/references/fault-tolerance.md](../../system-architect/references/fault-tolerance.md) — the design-time patterns chaos verifies
- [on-call.md](on-call.md) — chaos exercises double as training for new on-call
