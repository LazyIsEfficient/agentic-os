# Working With Engineering

The relationship between PM and engineering is the single most consequential relationship a PM has. A PM who works well with engineering ships things; a PM who fights with engineering ships nothing, no matter how good the strategy.

The two failure modes:

- **PM as boss.** The PM dictates what to build, when to build it, and how. Engineering becomes a delivery mechanism. Engineers feel disempowered and resentful. The work suffers.
- **PM as customer.** The PM "files requests" with engineering and waits. Engineering treats the PM as one stakeholder among many. Coordination collapses; nobody owns the outcome.

The right stance is **PM as collaborator**. The PM and engineering are on the same team, working on the same problem, from different angles. The PM owns *what and why*; engineering owns *how*; both own the outcome.

This file is about how to be the kind of PM that engineers want to work with.

## The Foundation: Understanding the Work

A TPM has to understand what engineering is doing well enough to have a real conversation about it. Not to *do* engineering — that's not the job — but to engage with the trade-offs, ask intelligent questions, and not get fooled by hand-waving.

Things a TPM should understand without help:

- The general shape of the system (services, data flow, key dependencies).
- What's changing in this sprint and why.
- What's hard about the current work and what's easy.
- The major risks (technical, integration, performance).
- The team's capacity and how it's being spent.
- The trade-offs in any major design decision (build vs buy, monolith vs service, sync vs async, etc.).
- The state of the codebase: where the cruft is, where the velocity is, where the team is held back.

A TPM who can't read a design doc is not a TPM. A TPM who can read it, ask good questions, and surface trade-offs in product terms is the kind of TPM engineers respect.

The way to develop this: pair with an engineer for an hour every couple of weeks. Read the design docs. Sit in on architecture reviews even when you don't have to speak. Ask "dumb" questions early. The cost is small; the payoff is enormous.

## Estimation Honesty

The most damaging dynamic in the PM-engineering relationship is **estimation as negotiation**. The PM asks "how long?", the engineer says "two weeks," the PM says "can you do it in one?", the engineer says "I guess so" — and the team is now committed to a number nobody actually believes.

The right stance: **estimates are data, not negotiating positions**. When an engineer gives you an estimate, they're telling you what they currently believe is true about the work. The right response is curiosity, not bargaining.

### What to do with an estimate

- **Take it seriously.** The engineer probably knows more about the work than you do.
- **Ask what's driving it.** "What's the hard part? Where's the risk?" — not "can you go faster?"
- **Ask about assumptions.** "What are you assuming about `<X>`? What if that turned out to be different?" Often the assumptions are the place to negotiate, not the number.
- **Ask about scope.** "If we cut `<Y>`, does that change the estimate?" Now you're negotiating *requirements*, not *time*.
- **Accept the uncertainty.** Estimates are estimates. A "two weeks" is really "somewhere between one and four." Plan for the range.

### What to NOT do with an estimate

- **Push for a smaller number.** This trains engineers to give you the smallest number they can defend, which is usually wrong.
- **Treat the estimate as a commitment.** It's a hypothesis about the work, not a contract.
- **Add a buffer in your head and not tell them.** They'll find out and stop being honest with you.
- **Average with another engineer's estimate.** Different engineers see different complexity; the average is meaningless.
- **Compare to "how long it took last time."** Last time was a different problem with a different team in a different state.

The cultural shift: estimates are a tool for *planning*, not for *holding people accountable*. Once you've gone through the curiosity questions and aligned on scope and risk, the estimate is what it is. If you don't like it, change the work.

### When the estimate seems wrong

Sometimes you genuinely think the estimate is off — too high or too low. The right move is *not* to argue, it's to *understand*.

- "Help me understand why this is taking longer than I expected. What am I missing?"
- "I would have guessed this is about a week of work — am I missing complexity here?"

Sometimes you'll learn something that changes your thinking. Sometimes the engineer will, in explaining it, realize they over- or under-estimated and adjust on their own. Sometimes you'll both realize the spec is unclear and the real work is to clarify it.

Almost always, the conversation produces better information than the original estimate did. That's the whole point.

## The Engineer-as-Collaborator Stance

A useful mental model: engineering is *not* a vendor you're hiring, and *not* a team you're managing. Engineering is a *peer team* with their own expertise, judgment, and accountability. The PM and engineering work *together* on the same problem.

Practically, this means:

### Bring problems, not solutions

> "Users keep dropping out at step 3 of onboarding. Here's what we know: `<data>`. I think we should explore this — what would you suggest?"

is much better than

> "Users keep dropping out at step 3. Here's the design: a new modal that explains the step. Can you build it?"

The first invites engineering's expertise; the second cuts them out of the design. Engineers often have ideas the PM didn't think of, including ones that are much cheaper to build.

### Involve engineering in discovery

When research is happening, invite engineering to attend interviews and usability tests. Not all the time — they have other work — but enough that they're not inventing the user from nothing. Engineers who have *seen* a real user struggling with the product build different things than engineers who have only read about it.

### Involve engineering in planning early

The worst pattern: PM finalizes the roadmap, then "consults" engineering about feasibility. Engineering says "we can't do that," PM says "we already committed," conflict ensues. The fix is to bring engineering *into* the roadmap conversation from the start. Their input changes the roadmap before it's locked.

### Show engineering the strategy

Engineering wants to know *why* they're building what they're building. A team that understands the strategy makes better technical decisions on the fly. A team that doesn't builds whatever the spec says, even when the spec is wrong.

Spend time explaining: here's the strategy, here's how this work fits, here's what we're trying to learn. The investment pays off in the dozens of small decisions engineers make every day.

### Defer to engineering on engineering questions

When engineering says "this should be a queue, not a sync API call," the right response is "got it, thanks." Not "can we do it sync because it's simpler for me to think about."

Engineering owns the technical design. Your job is to surface product concerns and constraints that engineering needs to factor in — not to override their technical judgment.

### Be accessible during build

When engineering has a question about the spec, the design, or a trade-off, they need an answer. A PM who's hard to reach blocks the team. A PM who's available — Slack, async, occasional sync — keeps the team unblocked.

A useful default: aim to respond to engineering questions within hours, not days. If you can't, set the expectation explicitly ("I'm in meetings all day; I'll get back to you tomorrow morning").

### Show up to demos

When engineering demos something, show up. Pay attention. Ask questions. Give feedback in real time. The team has put work into building something; the worst signal is a PM who isn't there or isn't paying attention.

### Defend engineering from above

When leadership asks for "just one more thing" that breaks the team's commitments, your job is to push back, not to roll over. "We've committed to X, Y, Z this sprint. Adding W means dropping one of them — which would you like to drop?" — that's the answer, not "sure, we'll fit it in."

Engineers notice which PMs defend them and which don't. The first kind earns loyalty; the second kind earns silence.

## Technical Trade-offs

A TPM is in the room for technical trade-offs because the trade-offs have product consequences. The PM doesn't make the call — engineering does — but the PM has to *understand* it well enough to weigh the product side.

Common trade-offs and the questions they raise:

### Build vs buy

> "Should we build this ourselves or use a vendor?"

Build:
- We control the roadmap, the data, the price, the integrations.
- We pay engineering cost upfront and forever (maintenance).
- We can differentiate.

Buy:
- We pay money instead of engineering time.
- We can ship faster (usually).
- We're at the vendor's mercy for roadmap, pricing, and reliability.
- We're constrained by what they offer.

The PM's contribution: how strategic is this capability? Is it something we want to be uniquely good at, or is it something we want to *not have to think about*? Strategic things are usually built; non-strategic things are usually bought.

### Sync vs async

> "Should this be a real-time API call or a queued message?"

Sync:
- The user (or caller) gets the result immediately.
- Simpler to reason about; harder to scale.
- A failure in the dependency means a failure in the request.

Async:
- The user (or caller) doesn't wait.
- Scales better; recovers from failures.
- More complex; harder to debug; the user has to be told "we're working on it."

The PM's contribution: does the user *need* the result immediately? If not, async is usually better, but the UX has to handle the wait gracefully.

### Monolith vs microservices

(Actually a system-architect concern; the PM is at the table because the choice affects velocity for years.)

The PM's contribution: how many teams will work on this? How fast does it need to evolve? How much coordination cost can we absorb? The answer often points the architect to one or the other.

### Custom vs framework

> "Do we use library X or write our own?"

Custom:
- Fits exactly.
- We own all the bugs.
- Costs ongoing maintenance.

Framework:
- Might not fit perfectly.
- Most bugs are someone else's problem.
- We're constrained by what the framework does.

The PM's contribution: how unique is our problem? If we're solving the same thing as everyone else, use the framework.

### Now vs later

> "Should we ship the perfect version, or ship an imperfect version sooner?"

This is *the* most common trade-off and the one PMs get most wrong. The bias should usually be toward *sooner* — get something in front of users, learn, iterate. The exceptions are: anything user-trust-related (auth, payments, security), anything that's hard to migrate later (data schemas, public APIs), anything where v1 will be used as evidence against the team forever.

The PM's contribution: surface the *cost of delay* and the *cost of a bad first impression*. Compare them honestly. Usually shipping sooner wins; sometimes it doesn't.

## When Engineering Says No

Sometimes engineering says no to something the PM wants. The PM's job is to *understand the no*, not to argue with it.

Common reasons engineering says no:

- **It's harder than it looks.** The PM saw a simple feature; the engineer sees the systems integration, the data migration, the edge cases. Trust this.
- **It conflicts with something else.** It would break feature X; it would slow down service Y; it would invalidate a contract with team Z. Surface and resolve the conflict.
- **It's not actually wanted by users (engineering's view).** Engineering has been hearing user feedback in support tickets and bug reports; sometimes their read is right. Listen.
- **It's the wrong abstraction.** "We could build this, but it would lock us into a worse architecture for years." This is the most important "no" to listen to.
- **The engineer is tired.** They've been doing similar work for months and they can't bring themselves to do another version. This is real, and the answer is to address the root cause (workload, variety, motivation), not to argue them into compliance.

A useful response to a no: "Help me understand. What's driving the no? What would make it a yes?" Often the conversation reveals a path forward that the original "no" closed off.

Sometimes the answer really is "we shouldn't do this at all." That's a valid outcome. A no from engineering is information about reality, not a refusal to work.

## When the PM Says No to Engineering

The reverse also happens. Engineering wants to do something the PM is against:

- **Engineers want to refactor.** Sometimes worth it; sometimes a distraction. The question is "what does this enable?" If the answer is "ship faster on these specific features," it's probably worth it. If the answer is "cleaner code," weigh against opportunity cost.
- **Engineers want to use a new technology.** Often the right call is *not now*. Adopting new tech has hidden costs (learning curve, ecosystem maturity, debugging tooling). Wait for a project where the new tech genuinely fits.
- **Engineers want to scope-creep.** "While we're in there, we should also..." Sometimes a good idea, sometimes scope creep. The PM's job is to ask "does this serve the goal we set?"
- **Engineers want to skip the user research.** "We know what to build." Sometimes they do; sometimes they don't. Push back if the stakes are high.

The same rules apply in this direction: bring curiosity, not refusal. Understand the reasoning. Sometimes change your mind.

## The Sprint Routines

The PM is part of the team's regular cadence — standup, planning, retro, review. Some patterns:

### Standup

The PM shows up. Doesn't dominate. Listens. Surfaces blockers from the product side ("I'll have the spec for X by tomorrow"). Removes ambiguity when needed.

Bad PM standup behavior: turning standup into a status update for the PM. Good PM standup behavior: being part of the team like any other contributor.

### Planning

The PM brings the work, with rationale. Engineering brings the estimates and the technical questions. Together they shape the sprint.

Bad PM planning behavior: arriving with a fixed scope and pushing the team to commit. Good PM planning behavior: arriving with priorities and rationale, and adjusting scope based on the engineering conversation.

### Demos

The PM attends, gives feedback, asks questions. Praises what works.

Bad PM demo behavior: skipping the demo because "I'm too busy." Good PM demo behavior: being the most engaged person in the room.

### Retros

The PM participates. Owns their share of what went wrong. Listens to engineering's frustrations without defensiveness.

Bad PM retro behavior: defending the PM role; making it about the team's mistakes. Good PM retro behavior: asking "what could I have done differently?"

### 1:1s with engineers

The PM should have occasional 1:1s with engineers — especially the engineering lead or architect, but also individual contributors. Not to manage them (their manager does that) but to build relationship and surface concerns that don't fit in group settings.

A useful 1:1 question: "What's frustrating you right now that I could help with?" — listen to the answer, do something about it.

## Refusing Unrealistic Asks From Above

Sometimes leadership pushes for a commitment the team can't make. The PM is in the awkward position of being asked to commit *for* the team to something the team didn't agree to.

The wrong move: agree, then come back to the team and say "leadership wants X by Y; sorry, we have to."

The right move: push back in the moment.

> "I want to be honest about what's possible. With the current team, I think X by Y is unrealistic. Here are the trade-offs: we could ship a smaller version, we could ship later, we could pull engineers from another project, or we could push back the deadline. Which of those works?"

This frames the conversation as a trade-off, not a refusal. Leadership usually responds well to it because it gives them options instead of resistance.

If leadership insists despite the trade-offs, the PM has a harder choice: commit and set the team up to fail, or push back harder. A PM who *always* commits when pressured is a PM the team will eventually leave. A PM who *often* pushes back honestly is a PM the team trusts and the leadership grows to respect.

## Anti-Patterns

- **PM as boss.** Dictates what to build, when, and how. Engineering disempowered.
- **PM as customer.** Files requests, waits. No co-ownership.
- **PM dictates implementation.** "Build it as a Redux store with these reducers." That's engineering's call.
- **Estimate negotiation.** "Can you do it in half the time?" Trains engineers to lie.
- **Buffer in the PM's head.** Adds 50% silently; engineers find out, lose trust.
- **Skipping demos.** Tells the team their work doesn't matter.
- **Skipping standups.** Tells the team you're not part of it.
- **Hiding from retros.** Refusing to take responsibility for the PM share of problems.
- **Defending the spec instead of updating it.** Spec wrong; engineers know it; PM clings.
- **Hand-waving on technical questions.** "I don't really get it, just figure it out." Engineers stop bringing them up.
- **Promising leadership things engineering didn't agree to.** Setup for blame.
- **Failing to defend the team from above.** Engineers see it; trust collapses.
- **Treating engineers as interchangeable.** They aren't; each one knows different things; the team is more than a sum.
- **Building "engineering buffer" into estimates without telling them.** Same problem as the personal buffer.
- **Skipping the design doc.** "I don't have time to read it." Then ask questions in build that the design doc would have answered.
- **Not understanding the architecture.** Producing PRDs that don't match what's possible to build.
- **"Trust me, it's important"** instead of explaining why. Engineers want to *understand*, not just to comply.
- **Asking for estimates on under-specified work.** Then treating the estimate as a commitment. Should have specified first.
- **Conflict avoidance.** Two engineers disagree about the design; PM doesn't mediate; resentment builds.
- **PM as proxy buyer.** PM filters everything from the user; engineering never talks to a real user.
- **Over-promising to compensate for under-shipping.** Makes the next round worse.
- **Demoing other people's work as your own.**
- **Taking credit for engineering wins; blaming engineers for losses.** Inversion of the right stance.

## Related

- [working-with-engineering.md](working-with-engineering.md) — yes, this file
- [prds-and-specs.md](prds-and-specs.md) — the artifact engineers consume
- [stakeholder-management.md](stakeholder-management.md) — engineering is the most important stakeholder
- [system-architect](../../system-architect/SKILL.md) — engineering's view of the design conversation
- [software-design](../../software-design/SKILL.md) — code-quality concerns engineers raise
- [site-reliability-engineering](../../site-reliability-engineering/SKILL.md) — operate-time concerns engineers raise
- [team-lead](../../team-lead/SKILL.md) — team-lead handles tactical team rhythms; PM handles product
- [pm-anti-patterns.md](pm-anti-patterns.md) — many PM anti-patterns are engineering-relationship failures
