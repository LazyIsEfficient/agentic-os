# Escalation

Sometimes the enforcer encounters a situation where the team won't comply with a standard and the exception process isn't producing a resolution. The team is determined to ship the deviation; the enforcer is determined to block it; somebody has to break the deadlock.

This file is the playbook for escalation: when to escalate, how to do it without burning the relationship, and what to do when escalation doesn't go the way the enforcer wants.

## When to Escalate

Escalation is the *last* option, not the first. Most disagreements get resolved at the enforcer-team level. The enforcer escalates when:

### 1. The team refuses to comply

The standard is clear; the team understands it; they've decided to ship the deviation anyway. The exception process didn't apply (or they refused to file one).

This is the most common escalation case. The enforcer can't unilaterally allow the deviation; the team isn't going to back down on their own. The escalation surfaces the conflict to a higher decider.

### 2. The exception process is blocked

The team filed an exception request; the approver hasn't responded; the work is in limbo. The enforcer can't approve the exception personally and the team can't ship the deviation without approval.

The enforcer escalates the *blockage*, not the underlying disagreement. The goal is to get a decision, not to overrule the approver.

### 3. The deviation has high impact

The standard being violated is a high-stakes one (security, compliance, load-bearing strategy) and the team is pushing to skip it. The enforcer can't approve such things personally and shouldn't let the team ship without escalation.

For these, the enforcer escalates *quickly* — not after weeks of stalemate, but as soon as the impact is clear.

### 4. There's a pattern

Not a single deviation, but a recurring pattern. The team is repeatedly ignoring the same standard. The enforcer has flagged it multiple times; nothing has changed.

The escalation here isn't about one PR — it's about the pattern. The enforcer's role is to surface the pattern to leadership for systemic intervention.

### 5. Leadership is the source of pressure

The team wants to comply with the standard but leadership is pushing them to skip it. The enforcer escalates to *leadership above the source of pressure*, or to the strategist, to break the pressure.

This is the moment when the enforcer's job is most valuable. The enforcer protects the team from its own leadership when leadership is asking them to skip standards.

## When NOT to Escalate

Escalation is expensive. It consumes leadership attention, damages team relationships, and creates conflict. Don't escalate when:

- **The disagreement is small.** A trivial gap can be flagged and accepted; not every disagreement needs escalation.
- **The team has a reasonable point.** Maybe the enforcer is wrong; consider that possibility.
- **The exception process hasn't been tried.** Always offer the exception process first.
- **You're tired or frustrated.** Escalation under emotion produces bad outcomes; sleep on it.
- **The standard is genuinely vague.** If the rule isn't clear, the fix is to clarify the rule, not to escalate the violation.
- **Leadership is unlikely to support the standard.** Sometimes the answer is to fix the standard or the org rather than escalate to a leader who'll just say "ship it."

The enforcer who escalates everything quickly loses credibility. Escalation is a serious move; use it for serious cases.

## How to Escalate Well

When escalation is necessary, do it well. The wrong way creates lasting damage; the right way produces a decision and preserves relationships.

### Step 1: Document the situation

Before escalating, write up the situation:

- **What's the work?** Brief description.
- **What standard is being violated?** Cite the specific source-of-truth skill and reference file.
- **What's the team's position?** State it fairly, even if you disagree.
- **What's the enforcer's position?** State it clearly.
- **What's been tried?** Compliance? Exception process? Why didn't they work?
- **What's the cost of the deviation?** What might go wrong?
- **What's the cost of compliance?** What does the team have to give up to comply?
- **What's the recommended path?** From the enforcer's view.

This becomes the escalation document. It's short — half a page to a page. It's factual and balanced, not advocacy.

### Step 2: Identify the right escalation target

Different escalations go to different people:

| Escalation type | Target |
|---|---|
| Strategic deviation | [technical-strategist](../../technical-strategist/SKILL.md), then engineering leadership |
| Security baseline violation | Security specialist, then CISO/security lead, then engineering leadership |
| Operational readiness | SRE lead, then engineering leadership |
| Cross-team coordination failure | Both teams' leads, then a shared higher authority |
| Leadership pressure to skip standards | The leadership above the source of pressure |
| Pattern of non-compliance | Engineering leadership, with a request for systemic intervention |

The enforcer routes the escalation to the right person, not just up the chain blindly.

### Step 3: Pre-brief the relevant parties

Before bringing the escalation to the decision-maker, talk to the people involved:

- **The team**: "I'm going to escalate this. Here's the document I'm bringing. Anything you want to add or correct?"
- **The strategist or skill owner**: "I'm escalating this to leadership. Here's where we are. Any input?"

This isn't asking permission; it's making sure nobody is blindsided. Surprise escalations damage relationships even when they're necessary.

### Step 4: Bring the escalation to the decider

Set up a brief meeting (or send a clear message) with:

- **The escalation document.**
- **The clear ask**: a decision about how to proceed.
- **The options**: typically 2-4 paths forward.
- **A recommended path**: the enforcer's view, with reasoning.

The format isn't a debate. It's a structured surfacing of the issue with a request for a decision.

### Step 5: Accept the decision

The decider decides. The enforcer has options:

- **Decision goes the enforcer's way**: the team complies; the enforcer documents the resolution.
- **Decision goes against the enforcer**: the work proceeds with the deviation; the enforcer documents the disagreement and the reasoning for the decision; the standard is updated if the decision implies it should be; the enforcer doesn't sulk.
- **No decision**: the decider punts. Push for a decision; if you can't get one, escalate further.

The enforcer who escalates and gets overruled doesn't get to override the decision. The decision was made by the right authority; the enforcer applies it.

### Step 6: Update the standards if appropriate

If the decision implies the standard is wrong, surface that to the source-of-truth skill or the strategist. Don't let the standard stand if the team's authority has effectively waived it.

If the decision implies the standard is right and the team should have complied, surface *that* — the team has been told they need to follow the standard going forward; track whether they do.

## Escalating Without Burning Relationships

Escalation is inherently confrontational. Done badly, it damages the enforcer's relationship with the team for months. Done well, the team understands and respects it.

### Pre-warn the team

Don't surprise the team with an escalation. Tell them what's happening and why:

> "I can't approve this as filed. I'm going to escalate to [person] for a decision. Here's the document I'm bringing. I want to be transparent about what I'm doing."

### Be factual, not adversarial

The escalation document is balanced. The team's position is stated fairly. The enforcer's recommendation is reasoned, not emotional.

The wrong tone: "The team is being reckless and won't listen."

The right tone: "The team and I disagree about whether the security baseline applies in this case. Here's their reasoning and mine. I think the deviation has high enough risk to warrant escalation."

### Leave room for the team to be right

The enforcer might be wrong. Maybe the team has context the enforcer doesn't. Maybe the standard doesn't actually apply. The escalation document should acknowledge this:

> "It's possible I'm being too strict here. The team has more context on this specific feature. I want to surface the disagreement to a decider who can evaluate both sides."

This isn't weakness; it's honesty. The enforcer who frames every escalation as "I'm right, they're wrong" loses credibility over time.

### Don't escalate to embarrass

The escalation should produce a decision, not a humiliation. Don't escalate publicly when private would do. Don't drag the team's name through leadership channels. Don't use escalation as a weapon.

If the team did something wrong, address it privately first. Escalate only the unresolved disagreement.

### Follow up after the decision

After the decision is made — whichever way it went — talk to the team:

- **If the decision favored the enforcer**: don't gloat. Acknowledge the team's position; thank them for engaging in the process.
- **If the decision favored the team**: don't sulk. Accept the decision; document it; move on. Avoid passive-aggressive enforcement on the next PR.

The relationship after the escalation should be at least as good as before. If it's worse, the escalation was handled badly.

## Escalating Leadership Pressure

The hardest escalation: when *leadership* is the source of the pressure to skip standards.

The pattern:

1. Engineering leadership says "we have to ship this Friday, even if it skips the security review."
2. The team is willing but flags the concern to the enforcer.
3. The enforcer can't approve the deviation.
4. The enforcer needs to escalate, but leadership *is* the source of pressure.

The escalation paths:

### Path 1: Leadership above the source of pressure

If a director is pushing to skip a standard, escalate to the VP. If a VP is pushing, escalate to the C-level. The principle: there's almost always someone above the source of pressure who has more accountability for the consequences.

### Path 2: The strategist

If the strategy says one thing and leadership is pushing another, the strategist is the right person to engage. They can make the case for the standard with leadership in a way the enforcer can't.

### Path 3: The team's own voice

Sometimes the right escalation is to *empower the team* to push back themselves. The enforcer provides the rationale, the documentation, and the air cover; the team brings the concern to leadership in their own voice.

This works because leadership often listens to the engineers themselves more than to a process role.

### Path 4: Document and ship under protest

When all else fails, and the deviation is going to ship despite the enforcer's objection, document the protest:

- **In writing**, with the date and the specific concern.
- **Visible to leadership**, so the decision is on the record.
- **Without sabotaging the work**. The enforcer doesn't withhold help; they just don't pretend to approve.

If the deviation causes a problem later, the protest is on the record. The enforcer's job was done; the decision was made by the right authority; the consequences belong to the decider.

## When the Enforcer Is Overridden

Sometimes the escalation goes against the enforcer. The decider says "ship it anyway." The enforcer's response:

1. **Accept the decision.** Don't fight it.
2. **Document the disagreement.** Future reference.
3. **Apply the decision.** Don't sabotage; don't sulk; don't be passive-aggressive on the next PR.
4. **Track the outcome.** If the decision causes a problem, it's on the record.
5. **Don't take it personally.** The enforcer is part of a process; the process produced a decision; that's how it works.

The enforcer who takes overrides personally becomes ineffective. The enforcer who accepts them gracefully maintains credibility.

## Repeated Overrides

If the enforcer is *repeatedly* overridden — every time they escalate, the decision goes against them — something is wrong. Possibilities:

- **The enforcer is too strict.** Maybe the standards are being applied with more rigor than the org wants.
- **The standards are wrong.** They don't fit the actual situation; the org is voting with its decisions.
- **The enforcer has lost the support of leadership.** Politically, they've lost the ability to enforce.
- **The org doesn't actually want enforcement.** It wants the appearance of enforcement without the reality.

The right response depends on which of these is true:

- **Too strict**: recalibrate. The enforcer's job is to be reasonable, not perfect.
- **Standards wrong**: surface to the strategist; the standards need to change.
- **Lost support**: rebuild trust with leadership; understand their concerns; adjust.
- **Org doesn't want enforcement**: this is a fundamental problem. The enforcer's role is performative, not real. Either the role needs to change or the enforcer needs to leave.

The last case is the most concerning. An enforcer in a non-enforcing org is a frustrated person doing decoration. Sometimes the right move is to step away from the role.

## Anti-Patterns

- **Escalating everything.** Loss of credibility; teams stop bringing things to the enforcer.
- **Escalating nothing.** Standards collapse; the enforcer becomes a rubber stamp.
- **Surprise escalations.** Damage to relationships; team feels ambushed.
- **Escalation as personal attack.** "The team is being reckless." Adversarial; counterproductive.
- **Escalation without documentation.** Verbal complaints to leadership; no record; no resolution.
- **Escalation to the wrong person.** Going to a leader who doesn't have authority over the decision.
- **Escalation as a threat.** "If you don't comply, I'll escalate." Coercive; damages trust.
- **Refusing to accept the decision.** Sulking, sabotaging, passive-aggression after losing.
- **Repeated escalations on the same pattern.** Without addressing the root cause.
- **Escalating for personal preference** rather than standards violations.
- **Giving up after one override.** The enforcer should still enforce; one override doesn't change the standard.
- **Not following up after the decision.** The decision is made; nobody tracks whether it played out as expected.
- **Letting leadership pressure go unchallenged.** The enforcer's job is to push back; folding is failure.
- **Not having a path for "leadership is the problem."** Sometimes leadership is wrong; the enforcer needs to know how to address that.

## Related

- [enforcement-philosophy.md](enforcement-philosophy.md) — the why
- [the-gates.md](the-gates.md) — where escalations come from
- [exceptions-and-waivers.md](exceptions-and-waivers.md) — the safety valve before escalation
- [strategic-alignment-check.md](strategic-alignment-check.md) — strategic deviations escalate to the strategist
- [technical-strategist](../../technical-strategist/SKILL.md) — partner in escalation
- [team-lead](../../team-lead/SKILL.md) — captures the resolution as an ADR
- [technical-product-management/references/saying-no.md](../../technical-product-management/references/saying-no.md) — parallel patterns from TPM
