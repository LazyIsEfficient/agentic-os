# Strategy Communication

A technical strategy that exists only in a document is decoration. A strategy that the team actually *acts on* is one that's communicated, repeated, and lived. The communication work is most of the value the strategist delivers.

This file is about how to communicate a strategy so the team uses it.

## The Core Principle

> **The strategy is not done when the document is written. It's done when every senior engineer can articulate it in their own words.**

The document is a tool. The shared understanding it produces is the goal. The strategist's job isn't to write a great document; it's to *create that shared understanding*.

The shared understanding lives in the team's heads, not in the doc. The doc is the canonical version that backs up the heads. When the heads drift from the doc, you need to either re-communicate or update the doc.

## Different Audiences Need Different Things

A strategy serves multiple audiences. Each needs a different version.

### To engineers (the people implementing it)

Engineers need:

- **The diagnosis**: why this strategy and not another. Engineers respect strategy that's grounded in real evidence; they're skeptical of strategy that feels arbitrary.
- **The actions**: what specifically they should do differently. Concrete, not abstract.
- **The non-goals**: what they're free to *not* do. This is often the most useful part for an engineer.
- **The kill criteria**: under what conditions the strategy would change.
- **A way to push back**: engineers need to know the strategy is open to challenge with new evidence.

The right format: a written document, walked through in a team meeting, with time for discussion and pushback. Not a one-way presentation.

### To leadership (the people funding and approving it)

Leadership needs:

- **The bottom line**: what's the strategy in one sentence.
- **The investment ask**: how much engineering time, how much money.
- **The expected return**: what the team will accomplish.
- **The risks**: what could go wrong.
- **The timeline**: when major milestones land.

The right format: a one-page summary plus the full document for reference. A 15-minute presentation with most of the time for questions.

### To product management (the people whose work the strategy supports)

Product needs:

- **What the strategy enables**: which product capabilities become possible (or easier) because of this strategic work.
- **What the strategy constrains**: which product directions are now harder or off-limits.
- **The capacity impact**: how much engineering time is committed to strategy work vs feature work.
- **The handoff points**: when product features can build on the new platform / refactor / capability.

The right format: a working session with product leadership where the strategy is discussed alongside the product roadmap. Both should fit together.

### To other engineering teams (the ones not directly involved)

Other teams need:

- **The summary**: enough to know what's happening.
- **What changes for them**: do they need to do anything differently? What about migration support?
- **The timeline**: when the changes affect them.
- **Where to ask questions**: a clear point of contact.

The right format: a one-page summary in the relevant Slack channels or wiki, plus a single all-hands or open-Q&A.

## The First Communication Round

When the strategy is first written, the communication sequence:

### Step 1: Review with the immediate team

Before broader communication, the strategist walks through the draft with the engineering leadership team (architects, senior engineers, team leads). This is the first sanity check: do the people closest to the work see this as right?

What you're looking for:

- **Disagreement on the diagnosis**: if people don't agree on the situation, the strategy won't land.
- **Pushback on the actions**: do the actions actually solve the diagnosed problem?
- **Holes**: what's missing? What did the strategist not consider?

This step usually produces revisions. Welcome them; they make the strategy stronger.

### Step 2: Walk through with the broader engineering team

Once the immediate team is aligned, walk through the strategy with the broader engineering team. This is *not* a one-way presentation; it's a working session.

The format:

- **5 minutes**: context on why this strategy exists right now.
- **10 minutes**: walk through the diagnosis, guiding policy, actions, non-goals.
- **30 minutes**: open discussion. Questions, pushback, clarifications.
- **5 minutes**: wrap up. What happens next; how to engage further.

The discussion is the most important part. Listen for:

- **Misunderstandings**: places where the strategy is being read differently than intended. Clarify in the doc.
- **Concerns**: things people are worried about. Sometimes valid; sometimes addressable with more communication.
- **Alternative interpretations**: places where the strategy could be read as committing to things the strategist didn't mean.
- **Gaps**: things the strategy doesn't address that people expected it to.

After the discussion, revise the doc again. The post-meeting version is usually clearer than the pre-meeting one.

### Step 3: Communicate to leadership

With the team's input incorporated, take the strategy to leadership. The format:

- **One-page executive summary**: top line, investment, return, risks, timeline.
- **The full doc** as backup.
- **A short presentation** if needed: 10 minutes plus questions.

Leadership's job at this stage isn't to invent the strategy; it's to fund and approve it. Most of the work has already happened.

If leadership pushes back significantly on the strategy itself, that's a sign the upstream alignment was missing. Either the strategy needs to change to fit the larger context, or the larger context needs to be brought in line with the strategy. Both directions are fine; what's not fine is having a strategy that contradicts the larger direction.

### Step 4: Communicate to adjacent teams

Once the strategy is approved, communicate it to the teams it affects but who weren't in the drafting process: product, support, sales, other engineering teams.

The format depends on the audience but the principle is the same: tell them what's changing for them, when, and how to engage.

### Step 5: Make the strategy discoverable

The strategy lives somewhere persistent — usually `docs/strategy/` in the project repo, or a wiki page, or a dedicated strategy doc. The location should be:

- **Findable**: searchable by name; linked from the team's main wiki page.
- **Versioned**: prior versions are accessible (in git or wiki history).
- **Owned**: a clear maintainer (the strategist) is named.
- **Linked from places that matter**: design doc templates, ADR templates, the team's onboarding doc.

A strategy nobody can find is one that nobody references.

## Ongoing Communication

Communicating the strategy once isn't enough. The team forgets; new people join; the situation evolves. Ongoing communication keeps the strategy alive.

### Cite the strategy in design reviews

When a design is being reviewed, cite the relevant parts of the strategy. "This design serves part 2 of the strategy: extracting the payments service." Or, "This design touches one of our load-bearing DADs (`Postgres for OLTP`); how does it honor that?"

This does two things: it reinforces that the strategy is real and being applied, and it gives engineers a concrete example of using the strategy in a decision.

### Mention the strategy in 1:1s

In 1:1s with engineers, especially senior ones, talk about the strategy. How are they seeing it land? What's working? What isn't? This is how the strategist gets feedback from the people closest to the work.

### Mention the strategy in PR reviews

Where relevant, reference the strategy in code reviews. "This change introduces a new database; that's outside the strategy. Can we discuss?" Or, conversely: "This refactor follows the extraction pattern from our strategy; LGTM."

### Bring the strategy to all-hands

Quarterly (or whenever there's a significant update), present the strategy at engineering all-hands. Not a 30-minute deck — 5 minutes of "here's where we are, here's what's next." Reinforces the strategy in the broader team's awareness.

### Update the team on progress

Monthly or quarterly, post a "strategy progress" update. What's been accomplished. What's been delayed. What's been learned. What's coming next. This prevents the strategy from becoming stale and forgotten.

### Onboard new engineers with the strategy

New engineers should read the strategy as part of onboarding. Include it in the onboarding doc. Test (informally) that they understand it. The strategy that new engineers don't know is one that will erode as the team turns over.

## Communicating Changes to the Strategy

When the strategy changes (which it should, when reality demands it), the change itself needs communication. Strategies that change silently lose all force.

The pattern:

1. **Draft the change** with rationale: what's different, why, what's the new direction.
2. **Discuss with the immediate team** as in the original drafting. Let them see the change before the broader team does.
3. **Update the document** visibly. Mark what changed and why.
4. **Communicate the change** to all the audiences that received the original strategy. Same audiences, same channels.
5. **Cite the change in upcoming decisions** so the team sees it being applied.
6. **Update derived artifacts**: the load-bearing DADs, the roadmap implications, any open ADRs that referenced the previous strategy.

The communication is symmetric to the original: if you walked through the strategy in a meeting, walk through the change in a meeting. If you sent a one-pager, send a one-pager update.

For more on when to update vs. when to leave alone, see [strategy-evolution.md](strategy-evolution.md).

## Handling Disagreement

Disagreement with the strategy is *expected* and *welcome*. The strategist's job isn't to win every argument; it's to surface the disagreements and either incorporate them or explain why not.

### Productive disagreement

Productive disagreement looks like:

- "I think the diagnosis misses X. Have we considered..."
- "The action in part 3 won't work because Y. Could we try Z instead?"
- "I'm worried about the kill criteria. How will we know if this is failing fast enough?"

The strategist's response:

- **Listen completely**. Don't defend prematurely.
- **Ask questions** to understand the disagreement.
- **Acknowledge the parts you agree with**.
- **Explain the parts you don't agree with** with reasoning, not authority.
- **Adjust the strategy** if the disagreement reveals something you missed.
- **Document the discussion** somewhere — the strategy doc or its changelog — so future readers see the reasoning.

Disagreement that produces a better strategy is the goal. A strategist who never updates a strategy in response to feedback is either always right (unlikely) or not listening.

### Unproductive disagreement

Unproductive disagreement looks like:

- "I just don't like this."
- "This is too much change."
- "I'd rather do it the old way."

These don't engage with the substance. The strategist's response:

- **Probe for the underlying concern**. "What specifically would you prefer? What problem is the current approach solving that you're worried we'll lose?"
- **Be patient**. Sometimes engineers need time to process change; the disagreement softens once they've worked through it.
- **Don't capitulate** to vague resistance. If there's no substantive concern, the strategy stays.

Some disagreement isn't fixable. A senior engineer who deeply disagrees with the direction may need to be brought into the strategy work itself, or may need to find a different team. The strategist doesn't have to make everyone happy; the strategist has to make the strategy *right* and *sustained*.

### Disagreement from leadership

When leadership disagrees with the strategy, the dynamic is different. The strategist usually can't override leadership; they have to engage.

The pattern:

1. **Understand the disagreement**. What specifically does leadership see differently? What's their context?
2. **Bring options**, not just defense. "Here's the strategy. Here's what we'd lose if we changed it in the direction you're suggesting. Here are three alternatives."
3. **Don't capitulate immediately**, but don't stonewall either. Leadership has context the strategist doesn't always see.
4. **Document the resolution**. If the strategy changes in response, write it down. If the strategy stays, also write down why.
5. **If forced to ship a strategy you disagree with, document the disagreement**. Future you will want to know what you thought at the time.

For more on this dynamic, see [technical-product-management/references/saying-no.md](../../technical-product-management/references/saying-no.md).

## Communicating the Strategy Externally

Sometimes the technical strategy is communicated outside the company — to investors, to customers, to the broader engineering community (blog posts, conference talks).

The rules are different:

- **Less detail**. External audiences need the high-level direction, not the implementation specifics.
- **More polish**. External communication represents the company; it should be well-written.
- **Lag the internal version**. External audiences shouldn't hear the strategy before the internal team does.
- **Don't reveal sensitive details**: vendor switches before they're public, security details, anything that competitors could exploit.
- **Watch for contradictions**: an external version that contradicts internal reality damages trust both ways.

External communication is the strategist's choice; not every strategy needs to be public. Often, internal-only is the right choice.

## Anti-Patterns

- **Strategy as a one-way memo**. Sent out; never discussed; nobody reads it.
- **Strategy in someone's head**. Not written; impossible to communicate.
- **Strategy with no review**. The strategist drafts it alone; no one else has input; predictable failure.
- **Strategy presented and never discussed**. The team has questions but no opportunity to ask them.
- **Strategy that's never referenced after the launch meeting**. Dead within a quarter.
- **Different versions for different audiences that contradict each other**. Trust collapses when audiences compare notes.
- **Strategy communicated by mandate only**. "Leadership has decided." Engineers resent the lack of reasoning.
- **Strategy with no kill criteria**. Sounds rigid; people resist.
- **Strategy that's reviewed but never updated**. The reviews become rituals.
- **Strategy where pushback is treated as disloyalty**. Engineers stop pushing back; problems hide.
- **Public strategy that contradicts internal reality**. Embarrassing when revealed.
- **Strategy doc nobody can find**. Lives in someone's Drive folder; not linked anywhere.
- **Strategy nobody can recite in one sentence**. Too long; too vague; too specific.
- **Strategy that's communicated once, then forgotten**. Needs ongoing reinforcement.
- **Strategy meetings that are status updates**. The meeting exists; the strategy doesn't get refined.
- **Strategy without follow-up**. Communicated; not tracked; not debugged when it doesn't work.

## Related

- [what-technical-strategy-is.md](what-technical-strategy-is.md) — the strategy itself
- [strategy-as-constraint.md](strategy-as-constraint.md) — what's being communicated
- [strategy-evolution.md](strategy-evolution.md) — communicating changes
- [technical-product-management/references/stakeholder-management.md](../../technical-product-management/references/stakeholder-management.md) — broader stakeholder principles
- [team-lead](../../team-lead/SKILL.md) — the ADR/DAD layer that captures the strategy in practical terms
- [documentation-writer](../../documentation-writer/SKILL.md) — the strategy lives in `docs/`
