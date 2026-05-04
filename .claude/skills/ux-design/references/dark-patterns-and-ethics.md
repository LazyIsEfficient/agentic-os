# Dark Patterns and Ethics

A dark pattern is a design that manipulates users into doing something they wouldn't have done if they understood the choice clearly. It works in the short term — metrics improve, signups go up, retention numbers tick — and corrodes in the long term. Users notice eventually. Trust collapses. Regulators arrive. Reputation, once lost, is expensive to rebuild.

The case against dark patterns isn't just ethical (though it is). It's also pragmatic: **dark patterns produce metrics, not customers**. The user who was tricked into a subscription cancels with rage. The user who couldn't find the unsubscribe link unsubscribes from the brand entirely. The user who got bait-and-switched warns their friends. Short-term wins, long-term loss.

This file is the catalog of common dark patterns, why they backfire, and the ethical alternatives. Read it as a guide both to spotting them in others' work and to refusing to ship them in your own.

## What Makes a Pattern "Dark"

A useful test: would the user, fully informed and unhurried, *consent* to what's happening? If yes, the pattern is fine — it might still be aggressive marketing or hard-sell, but it's not deceptive. If no, it's a dark pattern.

Three properties usually present:

1. **The product benefits at the user's expense.** The user gives up money, time, attention, or autonomy.
2. **The user wouldn't have chosen this if it were presented neutrally.**
3. **The design relies on the user being inattentive, hurried, or confused.**

Single-property cases are sometimes acceptable (showing a price prominently is "the product benefits" but the user knew). All three together is a dark pattern.

## The Catalog

The following are the most common dark patterns. Each one has a name, a description, why teams use it, why it backfires, and the ethical alternative.

### Roach Motel

**What it is:** Easy to get into, hard to get out of. Common in subscription services where signing up is a one-click affair and canceling requires an email, a phone call, navigating a maze of menus, and a cooling-off period.

**Why teams use it:** Reduces churn metrics in the short term.

**Why it backfires:** Users who manage to cancel hate the brand. Users who don't manage cancel via their bank, which produces chargebacks, which costs more than the saved subscription. Regulators (FTC, EU) increasingly fine companies for it.

**Ethical alternative:** Make canceling at least as easy as signing up. The user who wants to leave will leave; making it hard just makes them angry on the way out.

### Confirmshaming

**What it is:** Framing the "no" option as embarrassing or self-deprecating. "No thanks, I don't want to save money." "Maybe later, I prefer to lose customers." "No, I hate productivity."

**Why teams use it:** Pressures users into clicking "yes" through guilt.

**Why it backfires:** Users notice the manipulation. It's annoying, condescending, and tells users they're being treated as marks. Damages brand trust. Increasingly mocked publicly.

**Ethical alternative:** A neutral "no" or "skip" or "not now" button. Don't characterize the user's choice; just let them choose.

### Hidden Costs

**What it is:** A price that grows during the checkout flow. Final total includes service fees, processing fees, taxes, and "convenience charges" not visible until the last screen.

**Why teams use it:** Looks cheaper in search results and ads; users have psychological investment by checkout.

**Why it backfires:** Massive cart abandonment at the final step. Trust collapses. Word spreads. Some jurisdictions now require all-in pricing by law.

**Ethical alternative:** Show the full price up front, including all required fees. Let the user decide with full information.

### Forced Continuity

**What it is:** A free trial automatically converts to a paid subscription with no warning. The user who forgot is now charged.

**Why teams use it:** Maximizes accidental conversions.

**Why it backfires:** Chargebacks. Customer support volume. Public complaints. Strong negative emotional association with the brand. Regulatory action increasingly frequent.

**Ethical alternative:** Email the user before the conversion. Make the cancellation path obvious. Better: opt-in conversion (the user has to actively choose to continue) instead of opt-out.

### Disguised Ads

**What it is:** Ads that look like part of the product — a "post" in a feed that's actually sponsored, a "search result" that's actually paid placement, a "recommended" item that's actually advertising.

**Why teams use it:** Higher click-through than clearly-labeled ads.

**Why it backfires:** Users feel deceived when they realize. Regulators (FTC) require clear ad labeling. Erodes the trust that the entire feed depends on.

**Ethical alternative:** Label ads clearly. "Sponsored" in clear, contrasting text. The user can still click; they just know what they're clicking.

### Friend Spam

**What it is:** Asking for access to the user's contacts, then sending invitations or marketing to those contacts as if from the user, often without the user fully understanding what they agreed to.

**Why teams use it:** Free user acquisition with a built-in social proof signal.

**Why it backfires:** Users who realize feel betrayed; friends spammed with invitations resent both the user and the product. LinkedIn famously paid $13M settling a class action over this.

**Ethical alternative:** Let the user invite specific people they choose, with the message they want, after seeing exactly what will be sent.

### Misdirection

**What it is:** Drawing user attention to one thing while another, more consequential thing happens in the background. Bright "yes" button, gray "no" button, hidden "decline all cookies" link.

**Why teams use it:** Shapes the choice without literally removing it.

**Why it backfires:** Users feel manipulated when they notice. EU GDPR and ePrivacy increasingly require equal prominence for accept and decline options.

**Ethical alternative:** Give equally prominent treatment to both choices. Let the user decide based on the choice, not based on which button is shinier.

### Privacy Zuckering

**What it is:** Tricking the user into sharing more personal information than they intended through confusing settings, pre-checked boxes, or "agree to continue" prompts that bundle privacy concessions with the desired action.

**Why teams use it:** More data, fewer privacy controls.

**Why it backfires:** Privacy regulations now have teeth. Reputation damage when caught is severe.

**Ethical alternative:** Granular consent. Default to less sharing. Make the privacy choices visible and meaningful, not buried in a 30-page policy.

### Bait and Switch

**What it is:** The user takes one action expecting one result; the actual result is different and harder to undo. Click "X" to close an ad → opens the ad. Press "save" → gets enrolled in marketing emails.

**Why teams use it:** Forces actions the user wouldn't take voluntarily.

**Why it backfires:** Users learn distrust. They start avoiding your product.

**Ethical alternative:** Buttons do what they say. The "X" closes; the "Save" saves; the "Cancel" cancels. Words have meanings; respect them.

### Trick Questions

**What it is:** Survey or form questions written to confuse — double negatives, opt-out phrasings, inverted scales. Sometimes deliberately, sometimes by sloppiness.

**Why teams use it:** Steers responses or compliance choices.

**Why it backfires:** Users who notice feel insulted. Data quality is bad.

**Ethical alternative:** Plain questions. "Do you want to receive our newsletter?" not "Don't you not want to opt out of receiving our newsletter?"

### Sneak into Basket

**What it is:** A product the user didn't ask for is added to their cart, often with a pre-checked option deep in the flow.

**Why teams use it:** Boosts average order value.

**Why it backfires:** Some buyers notice and abandon; some don't notice and complain after; chargebacks; reputation damage.

**Ethical alternative:** Suggest related products clearly, let the user opt in.

### Fake Urgency / Scarcity

**What it is:** "Only 2 left!" "Sale ends in 3 hours!" — when neither is true.

**Why teams use it:** Pressures impulse purchases.

**Why it backfires:** Sophisticated users learn to ignore. Less sophisticated users feel cheated when they discover. Some jurisdictions now penalize false scarcity claims.

**Ethical alternative:** If something is genuinely scarce or time-limited, say so accurately. If not, sell on the merits.

### Dark Pattern by Default

**What it is:** Pre-checked boxes, opt-out (instead of opt-in) for things the user wouldn't actively choose. "Send me marketing emails" pre-checked at signup; "Make my profile public" turned on by default.

**Why teams use it:** Most users never change defaults; defaults that favor the company maximize compliance.

**Why it backfires:** Users who discover feel manipulated. GDPR specifically requires opt-in for many categories of data.

**Ethical alternative:** Defaults that respect the user's likely preference. When in doubt, default to less sharing, less notification, less commitment.

## Spotting Dark Patterns in Your Own Work

It's easier to spot them in someone else's design. Spotting them in your own requires *deliberate* questioning. A useful set of questions to apply to any design:

1. **Would I be okay with my parent / friend / partner using this and being treated this way?**
2. **If a journalist wrote about this design tomorrow, would the story be flattering?**
3. **What is the user being optimized *for*?** Their success at their job? Or some metric on a dashboard?
4. **Is the easy path the one that benefits the user, or the one that benefits the business?**
5. **Could a hurried, distracted user accidentally make a choice they'd regret?**
6. **Is anything pre-checked, pre-selected, or hidden in a sub-menu that affects the user's privacy or money?**
7. **Is the "no" option as visible and as easy as the "yes" option?**
8. **Are claims (price, scarcity, urgency) accurate?**

A "no" or "uncomfortable" answer to any of these is a flag. The flag isn't "automatic dark pattern" — sometimes there are good reasons. But each flag is a reason to think harder about the ethics before shipping.

## When the Pressure Comes from Above

Many dark patterns are not designed by malicious designers. They're designed by good designers under pressure to hit metrics. The PM says "users aren't subscribing; can we make the cancellation flow harder?" The growth team says "the signup conversion is too low; can we hide the price?" The exec says "we need 10% more retention by Q3."

How to push back:

- **Name the pattern.** "What you're describing is a roach motel. Here's what tends to happen when companies do that."
- **Show the long-term cost.** "This will boost the metric short-term and create chargebacks / complaints / regulatory exposure long-term."
- **Bring an alternative.** "Here's a different way to address the same problem that doesn't have those downsides."
- **Cite precedent.** "LinkedIn / Equifax / X paid $X million for this. Here's the case."
- **Document the disagreement** if you can't win the argument. A written record protects you and the team if the pattern blows up later.
- **Don't ship something you'll be ashamed of.** Sometimes the right answer is to refuse, even at career cost. Most patterns aren't worth it.

If the pressure is constant and the answer is always "ship the dark pattern," that's a signal about the org. Some teams aren't fixable from within.

## Consent Flows Done Right

The most common ethical design challenge: consent. Users need to agree to data collection, terms, marketing, cookies, etc. The easy thing is to make consent hard to refuse. The right thing is to make refusal real.

Principles for honest consent:

- **Granular.** Different consents for different things. "Functional cookies" is one consent; "marketing tracking" is another. Users can accept some and refuse others.
- **Equally prominent.** "Accept" and "Refuse" should be visually equivalent. Same size, same color, same effort to choose.
- **Reversible.** The user can change their mind later through visible settings.
- **Specific.** "We will send you marketing emails about our products" not "We may communicate with you about things you might find relevant."
- **Pre-defaulted to less.** If the user hasn't explicitly chosen, assume they didn't consent.
- **Independent of the core function.** Refusing marketing should not break the product. Refusing cookies should at least leave the basic experience usable.

The cookie consent banner is the most-violated example. Done wrong, it's a giant "Accept all" button next to a tiny "Manage preferences" link that buries the off-switches under three levels of toggles. Done right, it's a clear "Accept all" / "Reject all" / "Manage" with all three equally prominent.

## Anti-Patterns Beyond the Catalog

Some patterns aren't classic dark patterns but live in the same neighborhood:

- **Notification spam.** Notifying the user about things they didn't ask to know.
- **Engagement traps.** Designing for time-on-app over user well-being.
- **FOMO triggers.** "Sarah just signed up!" pop-ups. Manufactured social proof.
- **Loss aversion exploitation.** "If you cancel now, you'll lose all your data and the discount and your achievements and your friends." Manipulative.
- **Manufactured habit loops.** Notification-based reward cycles designed to create compulsion.
- **Asymmetric power.** Features that benefit the platform at the expense of the user (algorithmic ranking the user can't override, opaque content moderation).

These aren't always wrong — products have legitimate interests — but they're worth questioning. The line between "engaging product" and "manipulative product" is the line between *the user's interests being served* and *the user being used*.

## The Long Game

Good design is also good business. The companies that built durable, valued products over decades didn't do it by tricking users. They did it by being genuinely useful, honest about trade-offs, and treating users as adults.

Dark patterns are a tax on the future. Every dark pattern shipped is a small withdrawal from the trust account. Most users don't notice individually. Eventually, the account is empty and the trust is gone.

Refuse to ship them. The metrics will be slightly worse for a quarter or two and better for a decade.

## Anti-Patterns

- **"It's industry standard."** The industry has bad practices. Doing what others do is not an ethics defense.
- **"Users don't notice."** Some don't. Some do. The ones who do tell their friends.
- **"It's not technically illegal."** Legality is the floor, not the ceiling.
- **"We need this to hit our targets."** The targets are wrong if they require dark patterns to hit.
- **"It's just a small thing."** Many small things accumulate into a hostile product.
- **"The PM made me do it."** Designers have professional ethics. Push back.
- **"We can A/B test it."** A/B tests measure short-term metrics; dark patterns produce long-term harm. The test will look like a win, the long-term cost is invisible until it's huge.
- **"We'll fix it later."** You won't.
- **Treating dark patterns as creative cleverness.** They're not. They're harm.

## Related

- [interaction-design.md](interaction-design.md) — confirmation flows, error handling, intent-revealing actions
- [content-and-ux-writing.md](content-and-ux-writing.md) — honest microcopy is the antidote to confirmshaming and trick questions
- [accessibility.md](accessibility.md) — many dark patterns are also accessibility violations
- [security-engineering](../../security-engineering/SKILL.md) — consent flows, privacy decisions, data handling
- [ux-research/references/ethics-and-bias.md](../../ux-research/references/ethics-and-bias.md) — research ethics share principles with design ethics
- [team-lead](../../team-lead/SKILL.md) — pushing back on stakeholders and documenting disagreements
