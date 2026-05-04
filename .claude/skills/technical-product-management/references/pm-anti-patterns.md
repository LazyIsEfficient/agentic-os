# PM Anti-Patterns

A catalogue of the most common ways product management goes wrong. Each pattern is real, observable, and recoverable. The point of naming them is not to shame anyone — every PM has done some of these — but to recognize them in your own work and in your team's so they can be addressed.

The other reference files in this skill all have anti-pattern sections specific to their topic. This file collects the *cross-cutting* patterns — the ones that are about how the PM operates as a whole.

## The Feature Factory

**The pattern:** the team ships features constantly. Every sprint produces visible output. The roadmap is full. Velocity metrics look healthy. But almost nothing the team ships moves the underlying metrics, and most of what's shipped is barely used. Engineers grow weary; users don't notice.

**Why it happens:**

- The PM has no editorial voice and approves everything.
- Stakeholders treat the team as a vending machine: requests in, features out.
- Leadership measures the team on output (features shipped) instead of outcomes (impact achieved).
- The team has no time to validate; everything goes from idea to ship.
- Saying no is harder than saying yes.

**Why it's dangerous:**

- The team ships things nobody wants.
- Users feel the product is bloated, not better.
- Engineers feel their work is meaningless.
- The codebase accumulates features that have to be maintained forever.
- The team's morale collapses over a year or two.
- Eventually a competitor with sharper focus eats the lunch.

**The fix:**

- **Optimize for outcomes, not output.** Replace "features shipped" metrics with "metric moved" metrics.
- **Validate before building.** Make discovery a precondition for delivery.
- **Kill features that aren't earning their place.** Public deprecations.
- **Defend the team's time.** Push back on stakeholders; ship less but ship better.
- **Let the PM say no.** Build a culture where editorial judgment is valued.

The shift from feature factory to outcome-driven team is one of the hardest cultural shifts in product management. It often takes a year or more, and it requires leadership buy-in. But it's the difference between a team that ships and a team that matters.

## Roadmap as Commitment

**The pattern:** the team writes a roadmap. The roadmap becomes a commitment. Defending the roadmap becomes the PM's main job. When new evidence arrives — usability tests, market shifts, technical surprises — the team ignores it because "we said we would do this."

**Why it happens:**

- Leadership treats roadmap deviation as a failure to deliver.
- The PM is evaluated on plan-faithfulness instead of outcomes.
- Stakeholders use the roadmap to plan their own work and resist changes.
- The team fears looking incompetent if they change direction.
- Sunk-cost fallacy compounds.

**Why it's dangerous:**

- The team ships things they no longer believe in.
- New learning is wasted because the team won't act on it.
- Engineers see the team is building the wrong thing and lose trust in the PM.
- Outcomes suffer; the team is "on track" but going the wrong way.

**The fix:**

- **Frame the roadmap as a hypothesis, not a commitment.** Use language like "what we currently believe is the right work."
- **Mark confidence levels.** Distinguish "shipping in 4 weeks" from "exploring whether this is the right direction."
- **Update the roadmap regularly and visibly.** Make changes feel normal, not like failures.
- **Evaluate on outcomes, not delivery.** Did the team move the metric? That's the question.
- **Talk to leadership about it.** Often this is a leadership culture problem the PM has to renegotiate.

## PM as Project Manager

**The pattern:** the PM spends their week scheduling meetings, updating tickets, chasing status, writing reports. They're busy. The team is moving. But the PM isn't doing *product* work — they're not deciding what to build, why, for whom. They're a project manager wearing a PM title.

**Why it happens:**

- The role is genuinely unclear.
- Status-tracking work is urgent and visible; product work is important but not urgent.
- The PM hasn't built the relationship to push back on routine work.
- The org doesn't have a real project manager and the PM gets the role by default.
- It's easier to run meetings than to make decisions.

**Why it's dangerous:**

- Nobody is doing the product work; the team builds whatever comes through the door.
- The PM's voice is administrative, not editorial. Stakeholders learn to ignore them on strategic matters.
- The PM burns out doing low-leverage work and never gets to the high-leverage work.
- The team thinks of the PM as overhead.

**The fix:**

- **Audit your week.** What % is product work (strategy, prioritization, validation, decisions) vs project work (status, scheduling, reports)? If it's not at least 60% product, something's wrong.
- **Push back on routine status work.** Tools and rituals can replace much of it.
- **Delegate or eliminate non-essential meetings.**
- **Get a project manager** if the team is large enough to need one.
- **Reset expectations** with stakeholders about what you do and don't do.

## PM as Proxy Buyer

**The pattern:** the PM is the team's only contact with users. Engineers and designers never talk to a real user; their entire understanding is filtered through the PM. The PM becomes a single point of failure for user understanding, and their biases shape everything.

**Why it happens:**

- The PM "owns" customer relationships and doesn't share them.
- Research is treated as a PM/researcher activity that engineers don't attend.
- The team is structured so engineers never see user pain directly.
- The PM enjoys the power of being the user expert.

**Why it's dangerous:**

- Engineers and designers build for an imagined user (the PM's interpretation).
- The PM's biases compound; nobody catches them because nobody else has direct contact.
- The team builds things that don't match real users' needs.
- The PM becomes a bottleneck.

**The fix:**

- **Bring engineers and designers to user research.** Even one interview per quarter changes how they think.
- **Share user feedback directly.** Forward the actual messages, don't summarize them.
- **Run team-wide user contact rituals.** Quarterly user days, weekly support shadowing, etc.
- **Don't gatekeep customer relationships.** Introduce engineers to friendly customers; let them have direct conversations.

## PM-as-CEO

**The pattern:** the PM behaves as the team's boss. Tells engineers what to build and how. Overrides design decisions. Demands status reports. Treats the team as resources to be deployed.

**Why it happens:**

- The "PM is the CEO of the product" trope (popularized by Ben Horowitz, badly misinterpreted).
- The PM doesn't understand they're a peer to engineering, not their boss.
- The PM has authority issues.
- The org is structured to give the PM hierarchical authority over engineers.

**Why it's dangerous:**

- Engineers feel disempowered; their judgment is dismissed.
- The team's collective intelligence is wasted because only the PM's voice matters.
- Good engineers leave; the team gets weaker.
- The PM's blind spots become the team's blind spots.

**The fix:**

- **Recalibrate the stance.** PM is a collaborator, not a boss. Engineering owns *how*; the PM owns *what and why*; both own outcomes.
- **Explicitly invite engineering judgment.** "What would you suggest?" is the question that matters.
- **Defer on technical decisions.** Even when you disagree, engineering's call is engineering's call.
- **Take feedback in retros seriously.** If engineers are complaining about the PM stance, the PM is the problem.

## The Golden Child PM

**The pattern:** there's one PM on the team who's leadership's favorite. They get the high-profile projects, the most resources, the protection from accountability. Other PMs get the cleanup work and the less-visible projects. The dynamics distort the org for everyone.

**Why it happens:**

- Leadership has a personal preference.
- The golden child is genuinely good at managing up (regardless of their actual product work).
- Politics rather than performance.

**Why it's dangerous for the org:**

- Resources are misallocated.
- Other PMs become demoralized; they get less support, less credit, harder problems.
- The team builds a culture of favoritism, not merit.
- The golden child often *isn't* actually the best PM — they're the best self-promoter.

**The fix (if you're the golden child):**

- Be aware of it. Don't take credit for resources others would have made better use of.
- Advocate for peers when their work is invisible.
- Call out when the favoritism is producing bad decisions.

**The fix (if you're not):**

- Don't try to compete on the same axis (you'll lose).
- Build trust with your team and your immediate stakeholders; that's where the work actually pays off.
- Seek visibility by shipping things that matter.
- Sometimes the right answer is finding a new team or a new company.

## Demo-Driven Development

**The pattern:** the team builds for the next demo, not for the user. The features are designed to look impressive in a 5-minute presentation. The actual user experience suffers because the features were optimized for visual appeal in a controlled setting.

**Why it happens:**

- Stakeholders evaluate the team based on demos.
- Leadership reviews are demo-heavy.
- Sales gets quoted on "what we just demo'd."
- The team learns that demos are how they get credit.

**Why it's dangerous:**

- The product accumulates features that demo well and use poorly.
- Real user pain is ignored because it doesn't fit a demo.
- The team's energy goes into polish, not function.
- Customers notice the gap between the demo and the product.

**The fix:**

- **Evaluate features by user behavior, not by demos.** Did real users use the feature? Did it move the metric?
- **Demo the boring things too.** The unsexy reliability work, the bug fixes, the deletions. They're real product work.
- **Don't demo until it works for real users.** Internal beta first; demo after.
- **Push back when leadership demands a demo for something not ready.** "We can demo the rough version, but it's not where we want it; we'd rather show you in two weeks."

## Vanity Metric Reporting

**The pattern:** the PM reports impressive-sounding numbers in updates. Total registered users. Total downloads. Pageviews. The numbers sound big; they say nothing about whether the product is actually working.

**Why it happens:**

- Leadership wants big numbers.
- Real metrics (retention, conversion, engagement) are smaller and harder to celebrate.
- The PM doesn't want to deliver bad news.
- Vanity metrics are easier to game.

**Why it's dangerous:**

- The team optimizes for the vanity metric and ignores real value.
- Leadership thinks the product is doing better than it is.
- When reality eventually arrives (churn, lost deals, dropping growth), it's a surprise.
- Trust erodes; future numbers from the same PM are discounted.

**The fix:**

- **Pair every vanity metric with an actionable one.** Total users + active users + retention.
- **Lead with the actionable metric.** Vanity goes in the appendix, not the headline.
- **Be honest in updates.** "Total users grew but active users were flat." This is more useful than "huge growth!"
- **Revisit what's reported.** If the report's numbers are all vanity, the team is hiding from the real story.

## Strategy by Quote

**The pattern:** the PM cites famous CEOs and product gurus as if quoting them counted as strategy work. "Steve Jobs would have said..." "Marty Cagan teaches..." "First principles, like Elon Musk..." The team gets quotes instead of decisions.

**Why it happens:**

- The PM is unsure of their own judgment and seeks authority by association.
- Reading PM books is easier than doing PM work.
- Quotes feel substantive without requiring commitment.

**Why it's dangerous:**

- The team can't act on quotes; they need decisions.
- The PM's actual judgment doesn't develop.
- Quoting different gurus produces contradictory advice (every guru says different things).
- Stakeholders eventually learn to discount PMs who can't speak in their own voice.

**The fix:**

- **Read widely** but don't outsource your thinking.
- **Make your own arguments.** "I think we should X because Y" — not "Marty Cagan says we should X."
- **Cite the principle, not the person.** The principle stands or falls on its own; the person is irrelevant.
- **Be willing to disagree with the gurus.** They're often wrong about your specific situation.

## Asking Permission for Things You Should Decide

**The pattern:** the PM asks leadership (or peer stakeholders) for approval on decisions that are clearly within the PM's scope. Every prioritization, every roadmap change, every spec — escalated for blessing.

**Why it happens:**

- The PM is risk-averse and wants cover.
- The PM doesn't trust their own judgment.
- The PM has been burned for making unilateral decisions in the past.
- The org's culture rewards deference.

**Why it's dangerous:**

- Leadership's time is wasted on decisions that should have been made at the team level.
- Decisions become slow because they wait for the next leadership review.
- The PM doesn't develop judgment.
- Stakeholders learn to dismiss the PM as someone who doesn't make decisions.

**The fix:**

- **Make the call.** Most decisions belong to the PM. Make them.
- **Communicate, don't ask.** "Here's what we're doing. Here's why. Push back if you disagree." — instead of "what do you think we should do?"
- **Be wrong sometimes.** Wrong decisions are recoverable; chronically deferring decisions isn't.
- **Develop judgment by exercising it.** The PMs with the strongest judgment are the ones who've made the most decisions, not the ones who've avoided them.

## Failing to Ask Permission for Things You Should

**The opposite pattern:** the PM makes unilateral decisions on things that affect other teams or that need stakeholder buy-in. Surprises everyone. Ships things nobody knew about.

**Why it happens:**

- The PM is in a hurry.
- The PM thinks consulting others is slow.
- The PM is trying to assert authority.
- The PM doesn't understand the org's dependencies.

**Why it's dangerous:**

- Other teams' work is disrupted.
- Stakeholders feel ignored; trust erodes.
- The decisions are often worse because they didn't include the perspectives of the affected parties.
- The next time the PM tries to move fast, they're slowed down by stakeholders who don't trust them anymore.

**The fix:**

- **Map who's affected** before making a decision.
- **Consult — briefly — when others are affected.** Not to ask permission, but to surface concerns.
- **Be transparent about decisions you've already made.** "I've decided X; here's why; let me know if you see a problem I'm missing."
- **Develop a sense of which decisions are unilateral and which need consultation.** Most are unilateral; some aren't.

## Conflict Avoidance

**The pattern:** the PM avoids hard conversations. Won't push back on stakeholders, won't deliver bad news, won't tell the team a feature isn't working. Conflict gets deferred until it explodes.

**Why it happens:**

- The PM doesn't like confrontation.
- Saying difficult things feels unsafe.
- The org has a "be nice" culture that punishes directness.
- The PM hasn't learned to disagree productively.

**Why it's dangerous:**

- Problems compound while they're being avoided.
- Stakeholders aren't surprised by the truth — they suspected — and they lose trust in the PM who couldn't tell them.
- Decisions get made on bad information because nobody surfaced the bad news.
- The PM becomes ineffective because they can't have the conversations the role requires.

**The fix:**

- **Practice the hard conversations.** They get easier with reps.
- **Lead with respect, then deliver the message.** Acknowledging the relationship before the disagreement helps.
- **Be specific.** Vague concerns are easy to dismiss; specific concerns are hard to argue with.
- **Don't apologize for the message** if it's necessary.
- **If you really can't have the conversation, find someone who can** — your manager, a peer PM, a trusted mentor.

## Promising What You Can't Deliver

**The pattern:** the PM makes commitments — to leadership, to customers, to sales — that the team can't actually meet. The commitments are usually optimistic estimates, given to keep people happy in the moment.

**Why it happens:**

- The PM wants to keep the requester happy.
- Saying no is hard; saying maybe is easy.
- The PM is overoptimistic about the team's velocity.
- The PM hasn't checked with engineering before committing.
- The PM thinks the next round of negotiation will sort it out.

**Why it's dangerous:**

- The team is set up to fail.
- The PM's credibility erodes when promises aren't kept.
- Stakeholders learn to discount promises ("they always say 4 weeks; it's always 8").
- Engineering loses trust in the PM as their representative.
- A pattern of broken promises is cumulative; eventually the PM can't be trusted at all.

**The fix:**

- **Don't commit on the spot.** "Let me check with the team and get back to you."
- **Build in honest buffer.** When engineering says 4 weeks, communicate "4-6 weeks, depending on what we find."
- **Update the commitment** as soon as the estimate changes. Don't sit on bad news.
- **Apologize and reset** when you've over-promised. "I committed to X; I was wrong about the scope. Here's where we actually are. I'm sorry."

## Spec Writing as Avoidance

**The pattern:** the PM spends most of their week writing increasingly elaborate specs. The specs get longer, more detailed, more polished. The team waits. Real product work doesn't happen because the PM is buried in documents.

**Why it happens:**

- Writing feels productive even when it's not.
- Specs are something the PM can do alone, without the discomfort of stakeholder conversations.
- The PM has a perfectionist streak.
- The PM hasn't built the relationship to ship anything without a complete spec.

**Why it's dangerous:**

- The team is starved of decisions.
- The specs themselves become outdated as reality moves.
- The PM never has time for the conversations that matter.
- The team learns the PM is a writer, not a decider.

**The fix:**

- **Time-box specs.** A one-pager gets one day; a longer spec gets a week. Past that, ship what you have.
- **Use the simplest spec format that works.** Most decisions need a paragraph, not 30 pages.
- **Get specs reviewed quickly.** Don't polish in solitude.
- **Spend more time talking, less time writing.** The conversation is often more valuable than the document.

## Hiding Behind Frameworks

**The pattern:** the PM uses a framework (RICE, MoSCoW, OKRs, Jobs-to-be-Done) as the answer to every question. Every prioritization is a RICE score; every decision cites a framework; the PM never just says "I think we should do X because Y."

**Why it happens:**

- Frameworks feel objective and defensible.
- The PM is unsure of their judgment and wants cover.
- Frameworks give the PM a script to fall back on.
- Saying "I think" feels exposing.

**Why it's dangerous:**

- Frameworks are tools, not answers; treating them as answers produces wrong calls.
- The PM never develops judgment.
- The team can't get direct decisions; everything is mediated by a framework score.
- Stakeholders learn the PM is hiding behind process.

**The fix:**

- **Use frameworks for thinking, not for deciding.** They surface trade-offs; you make the call.
- **Be willing to override the framework** when your judgment says otherwise — and explain why.
- **State your opinion in your own voice.** "I think X because Y" — not "the score says X."
- **Develop judgment by exercising it.** The PM's value is in the judgment, not in the framework execution.

## "Above My Pay Grade"

**The pattern:** the PM defers difficult decisions upward. "That's above my pay grade." "I'd need to check with leadership." "I can't make that call." The PM refuses to own the things that fall within their role.

**Why it happens:**

- Risk aversion.
- The PM thinks deference is appropriate humility.
- The PM has been burned for making unilateral decisions.
- The org's culture rewards passing decisions up.

**Why it's dangerous:**

- Decisions get made by people further from the work, with less context.
- The team is slow because every decision requires escalation.
- The PM doesn't develop judgment.
- Leadership becomes a bottleneck.
- Stakeholders learn the PM doesn't have authority and start going around them.

**The fix:**

- **Identify what's actually within your role.** Most things are. Decide them.
- **Take ownership of decisions** even when you're nervous about them.
- **Bring decisions to leadership only when they're genuinely above your role.** Most aren't.
- **Build the muscle.** Decision-making gets easier with practice.

## The Disengaged PM

**The pattern:** the PM goes through the motions. Shows up to meetings, files tickets, sends updates, doesn't engage. Nothing is wrong; nothing is good either. The team is on autopilot.

**Why it happens:**

- Burnout.
- The PM isn't motivated by the product.
- The PM is in a job they don't want.
- The org culture has worn them down.
- The PM is checked out for personal reasons.

**Why it's dangerous:**

- The team feels the disengagement and matches it.
- Decisions don't get made.
- Stakeholder relationships atrophy.
- The product drifts.
- It compounds: the longer it goes on, the harder it is to recover.

**The fix:**

- **Honest self-assessment.** What's actually wrong?
- **Address the root cause** if you can — burnout (rest), wrong job (change), wrong company (move).
- **Talk to your manager** if it's recoverable.
- **Sometimes the right answer is leaving.** A disengaged PM helps nobody, including themselves.

A note: occasional disengagement is normal. Sustained disengagement is a signal that something needs to change.

## Related

- [product-strategy.md](product-strategy.md) — strategy failures are the root of many anti-patterns
- [prioritization.md](prioritization.md) — most feature factory issues are prioritization failures
- [saying-no.md](saying-no.md) — many anti-patterns come from inability to say no
- [working-with-engineering.md](working-with-engineering.md) — PM-as-CEO and similar patterns
- [stakeholder-management.md](stakeholder-management.md) — communication and trust failures
- [metrics-and-evidence.md](metrics-and-evidence.md) — vanity metrics, data abuse
- [team-lead](../../team-lead/SKILL.md) — many of these have parallels in team leadership anti-patterns
