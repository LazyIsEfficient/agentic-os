# Enforcer Anti-Patterns

A catalogue of the most common ways the standards enforcer role goes wrong. Each pattern is real, observable, and recoverable. The point of naming them is to recognize them in your own work so they can be addressed.

The other reference files in this skill have anti-pattern sections specific to their topic. This file collects the *cross-cutting* failure modes — the ones that can corrupt the enforcer role regardless of which specific standard is being enforced.

## Gatekeeping for Its Own Sake

**The pattern:** the enforcer blocks things to feel important. Reviews are slow; the bar is unclear; engineers learn that the enforcer is a problem to be navigated around. Eventually, work routes around the enforcer entirely.

**Why it happens:**

- The enforcer has been burned by previous bad work and is overcorrecting.
- The role is treated as personal authority, not as service to the team.
- The enforcer enjoys the power and resists relinquishing any of it.
- The enforcer doesn't trust the team and reviews everything in detail.

**Symptoms:**

- The enforcer's queue is always backed up.
- Engineers complain (privately) about the enforcer.
- Approvals come with many small comments and few substantive ones.
- Engineers start working around the enforcer ("don't tell them about this").
- Standards are followed, but the team is unhappy and slow.

**The fix:**

- **Ask: what's the team trying to achieve?** Align with their goal, not against it.
- **Lighter touch on small things.** Reserve the heavy review for high-impact work.
- **Offer options, not just blocks.** A path to compliance is better than a wall.
- **Trust the team by default.** Verify at the gates; don't surveil between them.

## Restating the Rules

**The pattern:** the enforcer re-implements what the source-of-truth skills already say. They write their own version of "how to do code review," "the security baseline," "the operational readiness checklist." Eventually, the enforcer's version drifts from the canonical version, and engineers don't know which is right.

**Why it happens:**

- The enforcer wants to be the authority, not just an applier of someone else's rules.
- The source-of-truth skill is hard to find or hard to read; the enforcer makes a "simpler" version.
- The enforcer thinks the source-of-truth skill is incomplete and fills the gaps with their own opinions.

**Symptoms:**

- The enforcer's checklist is different from the source-of-truth skill's.
- When engineers cite the source-of-truth skill, the enforcer cites their own version.
- The two versions drift over time.
- New team members are confused about which to follow.

**The fix:**

- **The enforcer cites; doesn't invent.** Always reference the source-of-truth skill.
- **If the source-of-truth skill is unclear**, push it to be clearer; don't write a competing version.
- **If the source-of-truth skill has gaps**, surface them to the skill owner; don't fill them yourself.
- **Periodically audit** the enforcer's references against the source-of-truth skills to catch drift.

## Becoming a Bottleneck

**The pattern:** the enforcer reviews everything continuously. Every PR; every commit; every design discussion. The enforcer's queue is always full; the team is always waiting. The enforcer becomes the rate-limiting step in the team's velocity.

**Why it happens:**

- No clear gates; the enforcer engages whenever something looks worth checking.
- The enforcer is the only person trusted to enforce the standards.
- The team can't make decisions without the enforcer's approval.
- The enforcer is in too few people's heads to be replaceable.

**Symptoms:**

- Velocity drops noticeably.
- Engineers wait days for review.
- Work gets batched up because the review is so slow.
- The enforcer is constantly busy and never caught up.
- When the enforcer is on vacation, work stops.

**The fix:**

- **Engage at clear gates only.** Kickoff, pre-merge, pre-release, post-release. Not every commit.
- **Automate where possible.** CI checks, lint rules, automated security scans.
- **Distribute the role.** Multiple enforcers; not just one.
- **Trust the team with most decisions.** The enforcer engages on the things that matter, not on everything.

## Unfair Application

**The pattern:** the enforcer applies the standard inconsistently. Strict on some teams, loose on others. Strict on junior engineers, loose on senior ones. Strict on unloved projects, loose on favored ones. The team learns the bar is political, not principled.

**Why it happens:**

- Personal relationships influence the enforcer's reviews.
- Senior engineers are intimidating; the enforcer doesn't push back as hard.
- Some projects have leadership attention; the enforcer is reluctant to delay them.
- The enforcer doesn't track decisions and inadvertently applies different bars over time.

**Symptoms:**

- Engineers privately complain about double standards.
- Some PRs get nitpicked; others get rubber-stamped.
- The enforcer's decisions feel arbitrary or political.
- Trust in the enforcer (and in the standards generally) erodes.

**The fix:**

- **Document every decision.** Reusable as precedent; visible to others; harder to be inconsistent.
- **Apply the same checklist** to every review of similar shape.
- **Hold seniors to the same bar.** Especially seniors — if they can deviate, juniors will too.
- **Audit your own reviews quarterly.** Look for inconsistency; correct it.

## Pure No

**The pattern:** the enforcer blocks work without offering options. "This isn't good enough." "You can't do this." "We don't allow that." No path to yes; no way forward.

**Why it happens:**

- The enforcer thinks their job is to say no, not to help.
- The enforcer doesn't have time to engage deeply with each block.
- The enforcer is frustrated and wants to vent.
- The enforcer assumes the team can figure out the path themselves.

**Symptoms:**

- Engineers leave reviews frustrated and stuck.
- Same problems show up repeatedly because the team didn't know how to address them.
- Engineers start working around the enforcer because going to them is unproductive.
- The enforcer is seen as obstructive.

**The fix:**

- **Always offer options when blocking.** "Here's what would make this OK."
- **Cite the source-of-truth skill** so the team can read the rule for themselves.
- **Suggest a fix** when the fix is small.
- **Route to the exception process** when the fix is hard.
- **Be specific.** "This is too vague" vs "Here are three things that need to change."

## Capitulation

**The pattern:** the enforcer folds under pressure. When leadership pushes for a deviation, the enforcer waves it through. When deadlines loom, the enforcer relaxes the bar. When senior engineers push back, the enforcer agrees.

**Why it happens:**

- The enforcer doesn't have organizational backing.
- The enforcer is afraid of conflict.
- The enforcer thinks compromise is always the right answer.
- The enforcer doesn't have a clear philosophy of when to hold the line.

**Symptoms:**

- Standards get waived under pressure.
- Engineers learn that resistance to enforcement works.
- The enforcer becomes ineffective; their approval is meaningless.
- Standards exist on paper but not in practice.

**The fix:**

- **Have a clear philosophy** of what's negotiable and what isn't (security baseline isn't; operational readiness isn't; quality nice-to-haves are).
- **Document the disagreement** when forced to ship under protest.
- **Escalate** when leadership is the problem.
- **Practice saying no.** It gets easier with reps.
- **Be prepared to leave** if the org doesn't actually want enforcement.

## Performance Art

**The pattern:** the enforcer goes through the motions of reviewing without actually catching anything. Reviews happen on schedule; checkboxes get checked; nothing changes. The enforcer is busy but ineffective.

**Why it happens:**

- The enforcer is overwhelmed and reviews superficially.
- The enforcer doesn't have the technical depth to catch real issues.
- The enforcer is rubber-stamping to clear the queue.
- The team has stopped flagging real problems because the enforcer always approves.

**Symptoms:**

- Lots of "approved" stamps; few "needs revision" or "blocked" outcomes.
- Things ship that the enforcer would have blocked if they'd actually looked.
- Engineers stop bringing real concerns to the enforcer.
- Post-launch incidents reveal problems the review should have caught.

**The fix:**

- **Take fewer reviews more seriously.** Quality over quantity.
- **Skip the routine ones; deepen the high-stakes ones.**
- **Track outcomes**: how many incidents trace back to things you approved? Use it to recalibrate.
- **Build deeper technical expertise** in the relevant areas.
- **Be willing to block.** A reviewer who never blocks isn't a reviewer.

## Skipping the Source-of-Truth

**The pattern:** the enforcer cites personal preference, common sense, or vague "best practices" instead of the team's agreed standards. "This isn't how we do things." Without a citation.

**Why it happens:**

- The enforcer hasn't read the source-of-truth skills carefully.
- The enforcer is making it up as they go.
- The enforcer thinks their judgment is enough.
- The source-of-truth skill is hard to find or hard to use.

**Symptoms:**

- Engineers ask "where does this rule come from?" and the enforcer can't answer.
- Different enforcers (or the same enforcer over time) apply different rules.
- The standards feel arbitrary to the team.
- Disagreements escalate because there's no shared reference point.

**The fix:**

- **Always cite.** Every block or approval references the specific source skill (and ideally the specific reference file).
- **Read the source skills.** The enforcer is the layer that applies them; you can't apply what you haven't read.
- **If the source skill doesn't say something**, surface it; don't make it up.
- **Build the habit.** "Per [skill]/[file], we require X."

## Inventing New Standards

**The pattern:** the enforcer adds new requirements that aren't in any source-of-truth skill. "I'd like to also see Y." The enforcer's preferences become de facto standards.

**Why it happens:**

- The enforcer has opinions; opinions feel like standards.
- The enforcer wants to make the work better; nudging beyond the standard is appealing.
- The enforcer mistakes their personal taste for the team's bar.

**Symptoms:**

- Reviews include requests for things that aren't in any skill.
- Different reviews from the same enforcer apply different ad-hoc rules.
- Engineers get frustrated by moving targets.
- The enforcer's "standards" don't survive a different enforcer.

**The fix:**

- **The enforcer enforces; doesn't author.** New standards go through the source-of-truth skill, not through PR comments.
- **Distinguish "blocking"** (citing a real standard) from "suggestion"** (personal opinion).
- **Mark suggestions as optional** so engineers know they can decline.
- **If you find yourself wanting a new standard**, propose it to the source-of-truth skill — don't enforce it ad-hoc.

## Personal Authority

**The pattern:** the enforcer's authority comes from *being the enforcer*, not from the agreed standards. "I said so." The team learns to comply with the enforcer, not with the standards.

**Why it happens:**

- The enforcer is a strong personality.
- The enforcer is technically respected and uses that respect as authority.
- The standards aren't well-documented, so the enforcer's word fills the gap.
- The enforcer enjoys the authority.

**Symptoms:**

- The team complies when the enforcer is in the room; deviates otherwise.
- Decisions can't be made without the enforcer.
- When the enforcer is sick or on vacation, enforcement collapses.
- The team is afraid of the enforcer rather than respectful of the standards.

**The fix:**

- **The enforcer's authority is the standards', not personal.** Cite always.
- **Make the standards independently usable.** A new engineer should be able to apply them without needing the enforcer.
- **Test by leaving.** When you're on vacation, do the standards still hold? If yes, the system works. If no, you're a bottleneck.
- **Train others.** Multiple enforcers; not a cult of personality.

## Hidden Reasoning

**The pattern:** the enforcer makes decisions in their head without writing them down. "I approved that PR." Why? Nobody knows; the enforcer might not even remember.

**Why it happens:**

- Documentation feels like overhead.
- The enforcer is in a hurry.
- Decisions feel obvious in the moment.
- There's no system for tracking enforcement decisions.

**Symptoms:**

- Engineers can't tell why one PR was approved and another wasn't.
- Inconsistent decisions go unnoticed because there's no record.
- New enforcers can't learn from past decisions.
- Disagreements escalate because there's no shared history.

**The fix:**

- **Document every non-trivial decision.** PR comments; review notes; the strategic alignment form.
- **Build a precedent base.** Past decisions inform future ones.
- **Track outcomes.** When a decision turns out to be wrong, learn from it.
- **Make reasoning visible** so the team can engage with it.

## No Improvement Loop

**The pattern:** the enforcer reviews and reviews; standards are applied; nothing changes. Recurring issues come up repeatedly. The enforcer flags them; the team fixes them; new ones replace them; nobody addresses the underlying patterns.

**Why it happens:**

- The enforcer is in firefighting mode.
- There's no time to step back and look at patterns.
- The enforcer doesn't track recurring issues.
- The team isn't in feedback loops with the enforcer.

**Symptoms:**

- Same kinds of issues come up again and again.
- The enforcer never gets ahead of the work.
- Engineers don't learn from their reviews.
- Standards feel like a tax instead of a system that's getting better.

**The fix:**

- **Quarterly review of patterns.** What kinds of issues are recurring? What's the root cause?
- **Feed patterns back into the source-of-truth skills.** "We see X repeatedly; let's add it to the skill's anti-patterns."
- **Educate the team.** Workshops, documentation, examples. Catch problems before they reach the enforcer.
- **Track velocity of issues.** Are things getting better over time?

## Treating the Team as Adversaries

**The pattern:** the enforcer sees the team as opponents. The team wants to ship; the enforcer wants to block; it's a zero-sum game. Reviews are confrontations.

**Why it happens:**

- The enforcer has been burned by bad work.
- The enforcer's role is framed as gatekeeping rather than service.
- The team is often resistant; the enforcer becomes defensive.
- The enforcer takes problems personally.

**Symptoms:**

- Reviews feel hostile.
- Engineers prepare for battle when sending PRs to the enforcer.
- The enforcer's tone is sharp.
- Trust is low both ways.

**The fix:**

- **Reframe: the enforcer is on the team's side.** The enemy is bad work shipped under pressure, not the engineer.
- **Lead with respect.** Acknowledge the work; engage with the substance; offer help.
- **Find wins together.** When something is good, say so.
- **Take breaks** when frustrated. Adversarial reviews come from emotion.
- **Build relationships outside reviews.** It's harder to be adversarial with someone you talk to about non-work things.

## Approving What You Don't Understand

**The pattern:** the enforcer doesn't understand the technical content but approves it anyway. "Looks good to me." Without actually evaluating it.

**Why it happens:**

- The enforcer doesn't have the depth to evaluate this specific area.
- The enforcer doesn't want to admit ignorance.
- The team is impatient and the enforcer doesn't want to delay them.

**Symptoms:**

- Reviews of complex changes are short and superficial.
- Approvals come quickly even for hard changes.
- Issues that the enforcer should have caught make it to production.
- Engineers learn that the enforcer is a rubber stamp for technical depth.

**The fix:**

- **Admit when you don't have the depth.** "I don't understand this well enough to approve. Who's the right reviewer?"
- **Route to the right specialist.** The enforcer is a generalist; deep technical reviews go to specialists.
- **Build depth over time.** Read the source-of-truth skills carefully; learn the relevant parts of the codebase.
- **Approve only what you can evaluate.** It's better to delay than to wave through.

## Related

- [enforcement-philosophy.md](enforcement-philosophy.md) — the right mental model
- [the-gates.md](the-gates.md) — the structure that prevents bottleneck pattern
- [exceptions-and-waivers.md](exceptions-and-waivers.md) — the right way to handle deviations
- [escalation.md](escalation.md) — what to do when things go wrong
- [strategic-alignment-check.md](strategic-alignment-check.md) — how to apply the strategic check
- [security-baseline-check.md](security-baseline-check.md) — how to apply the security check
- [quality-baseline-check.md](quality-baseline-check.md) — how to apply the quality check
- [operational-readiness-check.md](operational-readiness-check.md) — how to apply the readiness check
- [technical-product-management/references/pm-anti-patterns.md](../../technical-product-management/references/pm-anti-patterns.md) — many parallels
