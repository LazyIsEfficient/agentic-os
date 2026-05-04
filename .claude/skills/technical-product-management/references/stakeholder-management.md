# Stakeholder Management

A PM with no stakeholder skill ships nothing, no matter how good the strategy. The work depends on engineering to build it, design to shape it, leadership to fund it, sales and support to communicate it, customers to use it, and adjacent teams not to block it. Each of those is a stakeholder, and each requires a different relationship maintained over time.

The instinct to call this "managing" is slightly wrong. You don't manage stakeholders the way you manage a project. You **build trust with them** so that when you need to make a hard call (deprioritize their feature, change direction, ship something imperfect), they trust that you have a reason and don't fight you on it.

## Mapping the Stakeholders

Before doing any "stakeholder management," know who your stakeholders actually are. A useful exercise: list everyone who *cares about, depends on, or is affected by* your team's work. For each, note:

- **Their role and their incentive.** What are they measured on? What do they care about?
- **What they need from you.** Information? Decisions? Reassurance? Visibility?
- **What you need from them.** Resources? Decisions? Approvals? Collaboration?
- **Their power and influence.** Can they block you? Fund you? Veto you?
- **Their current trust level.** How much rope have they given you?

Most teams find ~10–20 stakeholders this way. The mistake is treating them as a uniform group; they're not. Different stakeholders need different communication, at different cadences, in different formats.

A useful split:

| Quadrant | Effort |
|---|---|
| **High power, high interest** | Manage closely. Frequent 1:1s, proactive updates, real consultation on big decisions. |
| **High power, low interest** | Keep satisfied. Less-frequent updates, hit the highlights, don't burn their attention. |
| **Low power, high interest** | Keep informed. Regular updates, accept their input, but don't let them block you. |
| **Low power, low interest** | Monitor. Don't waste your or their time. |

This is a simplification, but it forces you to *not treat all stakeholders the same way*. The CEO, an engineering peer, and a customer success rep all care about your work — but in very different amounts and for different reasons. Communicate accordingly.

## The Direction of the Communication

Stakeholder communication moves in three directions, each with different rules.

### Managing Up

Communication with leadership above you — your manager, the VP of product, the executive team, sometimes the board.

What leadership wants:

- **Confidence that you know what you're doing.**
- **Honest signal about what's working and what isn't.**
- **Early warning of problems**, not late surprises.
- **Decisions framed as decisions**, not dumps of information.
- **Brevity.** Their attention is finite; the longer your update, the less of it lands.

What leadership doesn't want:

- **Status reports without conclusions.** "Here's what happened this week" without "here's what it means."
- **Surprises at the deadline.** A miss revealed early is salvageable; a miss revealed at the end is a crisis.
- **Tactical detail.** They can't and don't want to follow which API call broke. They want "a key dependency slipped; here's the impact and our response."
- **Credit-grabbing or blame-shifting.** Both erode trust. Be honest about what your team did and didn't do.
- **Optimism that doesn't match reality.** Leaders get a sixth sense for it. The PM who "always says we're on track" stops being trusted.

The single most useful skill in managing up: **lead with the decision, not the data**. "We're going to deprioritize feature X because Y. Here's our reasoning. Want to push back?" — not "Here's a 12-slide deck about feature X; what should we do?"

### Managing Across

Communication with peer teams — adjacent engineering teams, design, research, marketing, sales, support, legal, security.

What peers want:

- **Predictability.** They're planning their own work around yours. Surprises hurt them.
- **Clear ownership.** Who owns what? Where do their boundaries end and yours begin?
- **Honest dependencies.** When you need something from them, when do you need it?
- **Reciprocal visibility.** They tell you their roadmap; you tell them yours.
- **Conflict surfaced early.** When their goals and yours conflict, address it directly. Avoiding it creates worse conflict later.

The single most common failure here: PMs operating as if they're the only team in the company. They commit their team's roadmap without checking dependencies, then expect peer teams to drop their work to support them. This breaks trust fast.

The fix is structural, not interpersonal: a regular cross-team alignment meeting (monthly is often enough) where adjacent teams share their plans and surface dependencies before they become problems.

### Managing Out

Communication with external stakeholders — customers, partners, the public.

What external stakeholders want:

- **Truthfulness about what's coming.** They're making decisions based on what you tell them.
- **Reasonable lead time** on changes that affect them.
- **A clear way to give feedback** and to be heard.
- **Honesty when things go wrong.** Apology, explanation, fix, follow-up.
- **No marketing-speak from a person they trust.** A PM who suddenly shifts to corporate copy loses the personal trust they had.

What they don't want:

- **Promises you can't keep.** Once is forgivable; twice is reputational.
- **Silence.** A customer whose request disappeared into a black hole becomes an angry customer.
- **Surprise changes** that affect their work without warning.
- **Defensiveness when they raise problems.** Their problems are signal; receive them as gifts.

The hard part of managing out: when the answer is "no, we're not building that," you have to communicate it without making the customer feel ignored or dismissed. The right framing is empathy + reasoning, not deflection.

> "I hear that's important to you. Let me explain where we are. We've decided not to build this in the next quarter because we're focused on `<X>`, which we think is more impactful for most of our customers. We've noted your specific request and we revisit our priorities each quarter. I'll keep you updated."

That's an honest no. It respects the customer; it's clear; it leaves the door open. It's also harder than just saying "we'll consider it" — but "we'll consider it" is the lie that erodes trust.

## The Trust Account

A useful mental model: every stakeholder relationship is a *trust account*. You make deposits and withdrawals over time. Withdrawing from an empty account creates conflict; making deposits when you don't strictly need to builds the balance.

### Deposits

- Delivering on what you said you'd deliver.
- Being transparent about misses and risks before they're forced.
- Listening to their concerns and addressing them, even when you disagree.
- Doing favors that aren't strictly your job (giving an early heads-up, sharing context, connecting them to a teammate).
- Being honest, including when honesty is uncomfortable.
- Showing up to their meetings, reading their docs, paying attention to their work.
- Defending them when they're not in the room.

### Withdrawals

- Saying no to something they want.
- Asking for more time on a deadline.
- Surprising them with a change.
- Pushing back on their priorities.
- Telling them their idea is wrong.
- Being unavailable when they need you.

The withdrawals are *necessary* — a PM who never says no, never pushes back, and never disappoints anyone is not actually managing anything. The point is to *make the deposits first*, so the withdrawals don't bankrupt the account.

A new PM joining a team has zero trust balance. The first few months are mostly deposit work: deliver on small commitments, listen, be visible, build a reputation. Only after the balance is healthy can you start making withdrawals comfortably.

## Communicating Bad News

Nothing tests stakeholder relationships like bad news. Some patterns:

### Communicate it early

The single most important rule. A miss reported a month before the deadline is salvageable; the same miss reported the day of is a crisis.

Bad news has a half-life: the longer you sit on it, the worse it lands. The instinct is to wait until you have a complete picture before telling anyone — that instinct is wrong. Tell them as soon as you have a credible signal that something's off, even if you don't yet know how off.

### Communicate it directly

Don't hide the news inside a longer document; lead with it. "Update: feature X is at risk of slipping. Here's why, and here are our options."

Stakeholders who have to hunt for the bad news in an otherwise optimistic update lose trust faster than stakeholders who get told straight.

### Bring options

Don't just say "we have a problem." Say "we have a problem; here are three things we could do; this is the one we recommend and why." This turns the conversation from "what now?" to "is this the right call?"

### Take responsibility, share credit

When something goes wrong, the PM owns it ("here's what we missed, and here's how we'll do better"). When something goes right, the team gets credit ("the team shipped this; here's what made it work"). Inverting this is the fastest way to lose your team's trust.

### Don't catastrophize

Bad news is bad news, not the end of the world. State the facts, state the impact, state the response, move on. PMs who panic make their stakeholders panic.

### Don't sugarcoat

The opposite failure: presenting a real problem as "actually a great opportunity to learn." Stakeholders see through it. Be straight; the situation is what it is; the framing should match.

## The Executive Update

Most TPMs have to write some form of executive update — weekly, biweekly, monthly. The same patterns apply, with extra emphasis on brevity and decision-orientation.

A useful executive update format:

```
## TL;DR
One sentence. The single most important thing leadership should know this period.

## Key updates
3-5 bullets. What shipped, what's at risk, what's changed.

## Decisions needed from leadership
Specific asks. "We need X by Y."

## Risks and concerns
What could derail us.

## Open questions
Things we're still figuring out.
```

That's it. A good executive update fits in one page or one Slack message. A bad one is a 12-slide deck that nobody reads.

The TL;DR is the most important section. It's the only section a busy executive will read. Spend disproportionate effort on it.

## Saying Hard Things

Some stakeholder conversations are hard by nature: telling a leader their pet feature is being deprioritized; telling a peer team their dependency is slipping; telling a customer their request isn't on the roadmap.

A few patterns that help:

### Lead with respect, then deliver the message

> "I really appreciate the work you've put into thinking about this. I want to be straight with you about where we landed."

This isn't softness; it's *acknowledging the relationship before challenging it*. The message that follows lands better.

### Name the trade-off

Don't pretend the choice is obvious. "We chose A over B; here's why; the cost of A is `<X>`. We thought it was the right call but I want to be honest that it's not free."

This treats the stakeholder as a peer who can engage with trade-offs, not a customer who needs to be sold.

### Don't apologize for legitimate decisions

Apologizing for things you should apologize for is great. Apologizing for legitimate prioritization calls is corrosive — it makes the call feel illegitimate and invites the stakeholder to push back.

> "We decided to deprioritize feature X." (correct)
> "We're so sorry to have to deprioritize feature X." (signals weakness; invites argument)

If you'd make the same call again, don't apologize for making it the first time.

### Don't make the conversation about feelings if it's about decisions

Stakeholders sometimes get emotional about deprioritized work. Respond with empathy *and* with the facts. Don't let the conversation become entirely about feelings; the underlying decision still has to be made.

### Don't backchannel

When you have a hard message to deliver, deliver it directly, not through a third party. Backchanneling produces the worst of both worlds: the stakeholder feels betrayed *and* doesn't get the actual message clearly.

## Building the Long-Term Relationship

The day-to-day stakeholder work is one thing. The longer-term relationship is another, and it pays compound interest.

Things that build long-term relationships:

- **Showing up consistently.** Regular 1:1s with key stakeholders, even when there's nothing on the agenda.
- **Listening more than talking.** Especially in the early months of a relationship.
- **Being curious about their world.** What's hard for them right now? What are they worried about?
- **Helping when you don't have to.** Giving them context they didn't ask for, pointing them to a person who can solve their problem, sharing a relevant article.
- **Being available.** Returning Slack messages within a reasonable time. Showing up to meetings on time. Honoring commitments.
- **Honesty over the long arc.** Stakeholders forgive mistakes from a PM who's been honest with them for years; they don't forgive deception even once from a new PM.

Things that erode long-term relationships:

- **Inconsistency.** Showing up when you need something, going silent when you don't.
- **Asymmetric attention.** Treating high-power stakeholders well and ignoring everyone else.
- **Hidden agendas.** Trying to maneuver them into supporting your position without telling them why.
- **Promises you can't keep.** "Yes, we'll do that" when you have no intention of doing it.
- **Defensiveness.** Treating their concerns as attacks instead of input.
- **Going around them.** Talking to their boss instead of to them.
- **Taking credit for their work.**

The PMs with the best long-term relationships are not the most charismatic; they're the most *consistent and honest*. The relationship is built one small interaction at a time, over years.

## Anti-Patterns

- **Treating all stakeholders the same.** Different people, different needs, different cadences.
- **Communication only when you need something.** Stakeholders learn that your messages are bills.
- **Optimism that doesn't match reality.** Leaders develop a sixth sense for it.
- **Bad news delayed.** Half-life of bad news is short; delay is corrosive.
- **Bad news without options.** "Things are bad" without "here's what we can do."
- **Status reports without conclusions.** "Here's what happened" without "here's what it means."
- **The dump.** A 12-page email expecting the stakeholder to figure out what matters.
- **Marketing-speak when stakeholders are used to direct talk.** Trust collapses.
- **Backchanneling.** Saying things behind people's backs that you wouldn't say to their face.
- **Going around someone.** Talking to their boss; making them look bad.
- **Asking permission for things you should just decide.** Wastes the stakeholder's time and signals weakness.
- **Not asking permission for things you should.** Surprises them; erodes trust.
- **Apologizing for legitimate decisions.** Signals the decision was wrong.
- **Defensiveness about feedback.** Trains stakeholders to stop giving you any.
- **Promising what you can't deliver.** Once is forgivable; twice loses the relationship.
- **Hiding misses until the deadline.** The single most damaging stakeholder pattern.
- **PM as gatekeeper.** Stakeholders can't get information without going through you. They route around you.
- **PM as proxy.** Stakeholders' opinions filtered through the PM's interpretation. Loses signal.
- **PM as mouthpiece.** PM delivers leadership's messages without filtering or context. Becomes a courier; loses authority.
- **Conflict avoided.** Two stakeholders disagree; PM lets it fester instead of surfacing it.
- **Trust account at zero.** PM tries to make withdrawals (deprioritize, push back, change direction) without ever making deposits.

## Related

- [saying-no.md](saying-no.md) — saying no to stakeholders is the core test of the relationship
- [working-with-engineering.md](working-with-engineering.md) — engineering is a stakeholder with special importance
- [launches-and-rollouts.md](launches-and-rollouts.md) — launch communication is stakeholder work
- [product-strategy.md](product-strategy.md) — communicating strategy to stakeholders
- [team-lead](../../team-lead/SKILL.md) — team-lead handles tactical communication; TPM handles product-level
- [pm-anti-patterns.md](pm-anti-patterns.md) — many PM anti-patterns are stakeholder failures
