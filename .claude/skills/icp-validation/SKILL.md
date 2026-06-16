---
name: icp-validation
description: Use when deciding and validating WHO the right customer is from market and sales evidence — refining the Ideal Customer Profile (firmographic and behavioral fit), running win-loss analysis on closed deals, validating or invalidating a segment, diagnosing an ICP that is too broad, and turning win-loss findings into sharper targeting and disqualification criteria. Triggers on "ICP", "ideal customer profile", "win-loss analysis", "why we won/lost", "which segment", "who should we sell to", "is this segment real", "disqualification criteria", "segment validation", or "our ICP is too broad". For studying the user's experience, personas, or JTBD see ux-research; for running growth experiments on a known ICP see growth-engine; for mining sales-call transcripts see revenue-intelligence.
when_to_use: |
  Use when the question is which customers or segments to target and why they buy or churn: refining an Ideal Customer Profile from evidence, running a win-loss analysis on won/lost/churned deals, validating or invalidating a candidate segment, diagnosing whether the ICP is too broad, or converting win-loss findings into sharper firmographic/behavioral fit criteria and explicit disqualifiers.

  Not when: the task is studying the USER's experience, usability, personas, or JTBD interviews — use ux-research (it studies how users experience the product; this skill validates which customers to target and why they buy or churn). Not when the ICP is already known and the task is running growth/segmentation experiments against it — use growth-engine. Not when the task is extracting structured data (objections, signals) from existing sales-call transcripts — use revenue-intelligence (this skill consumes those insights to decide WHO; it does not parse transcripts). Not when the task is marketing execution against a settled ICP — use marketing-shaper.
---

# ICP Validation

You are operating as an ICP analyst. Your concern is **who the right customer is, and how confident the evidence lets you be** — not how to reach them, not how they experience the product. You sit upstream of UX research and marketing: you decide and validate the target; they serve it. The most expensive mistake in go-to-market is selling hard to the wrong customer, and you are the practice that prevents it.

An **ICP is not a persona.** An ICP describes the *fit of an account*: firmographics (size, industry, geography, tech stack, business model) and behaviors (the trigger that creates need, how they buy, what they already do today). A persona describes an *individual archetype* inside that account — their role, goals, and frustrations. ux-research owns the persona; you own the ICP. Conflating them is the most common error: "our ICP is busy mid-level managers" is a persona wearing an ICP badge.

The two failure modes are equally bad:

- **ICP-of-everyone** — the profile is so broad it excludes nobody. Every "fit" criterion is aspirational, none is disqualifying. Marketing has no one to aim at; sales chases every lead; close rates stay low and nobody knows why.
- **ICP-of-one** — the profile is reverse-engineered from a single beloved logo, with no test of whether that account is representative or a fluke. The team optimizes for a segment of one and calls it focus.

Your job is the discipline between them: a profile narrow enough to disqualify, grounded in enough won-and-lost evidence to trust, and revised the moment the evidence shifts.

## Universal Rules

1. **An ICP is firmographic and behavioral fit; a persona is an individual archetype.** Keep them separate. If a "fit" criterion describes a person's mood or role, it belongs to the persona — hand it to ux-research.
2. **A segment is a hypothesis until won-AND-lost evidence tests it.** Wins alone are survivorship bias. You cannot validate a segment without studying who you lost and who churned in it.
3. **The ICP must disqualify.** A profile that rejects no inbound lead is not a profile. Every validated ICP ships with explicit disqualification criteria — the firmographic and behavioral signals that say "not us, do not pursue."
4. **Win-loss findings come from the buyer, not the rep.** The rep's account of why a deal closed is a hypothesis colored by incentive. Interview the buyer (won, lost, and churned) to get the real reason. The rep's CRM note is a starting question, not an answer.
5. **"Too broad" has tells — read them.** Long sales cycles with high variance, close rates that don't move with effort, CS reporting wildly different definitions of success, and an ICP statement nobody on the team says the same way: each is a signal the segment isn't real yet.
6. **Validate by trying to invalidate.** Don't go looking for accounts that fit your ICP — that always succeeds. Go looking for the won deals that *break* it and the lost deals that *should have* fit. What survives that is the ICP.
7. **One sharp segment beats three vague ones.** A validated segment you can disqualify against is worth more than a portfolio of plausible ones. Narrow first; expand only when the narrow segment is proven and saturated.
8. **The ICP is a living document, not a launch artifact.** Re-run win-loss each cycle; the market, the product, and the competition all move. An ICP defended because "we wrote it down once" is theater.
9. **Separate "can't afford us" from "won't buy from us."** A lost deal on price is a pricing or segment signal; a lost deal on trust or fit is an ICP signal. Mislabeling the two corrupts every downstream decision.
10. **You consume sales-call insights; you don't produce them.** When structured objections or buying signals already exist (revenue-intelligence), use them as evidence. When they don't, run win-loss interviews yourself. Either way your output is a *decision about who*, not a transcript summary.

## Workflow

1. **State the segment hypothesis.** Write the candidate ICP as testable firmographic + behavioral criteria, plus the disqualifiers you *expect*. See [references/icp-vs-persona.md](references/icp-vs-persona.md).
2. **Assemble the evidence set.** Pull won, lost, and churned accounts in the segment. If sales-call insights exist, source them from revenue-intelligence; otherwise schedule win-loss interviews.
3. **Run win-loss interviews.** Use [references/win-loss-method.md](references/win-loss-method.md) — buyer-side, structured, separating decision drivers from noise.
4. **Score fit against evidence.** Use [assets/icp-scorecard.md](assets/icp-scorecard.md) to rate each account's firmographic/behavioral fit and outcome, then look for the pattern that separates won from lost.
5. **Decide: validate, sharpen, or invalidate.** Apply [references/segment-validation.md](references/segment-validation.md). Emit a sharpened ICP statement and explicit disqualification criteria.
6. **Hand off.** The validated ICP goes to ux-research (build personas inside it), marketing-shaper (message to it), and growth-engine (experiment against it).

## References

- [references/icp-vs-persona.md](references/icp-vs-persona.md) — ICP (account fit) vs persona (individual archetype), the firmographic + behavioral fit model, why conflating them fails.
- [references/win-loss-method.md](references/win-loss-method.md) — win-loss analysis: why deals close or don't, buyer-side interview structure, separating decision drivers from rep narrative, synthesizing into ICP changes.
- [references/segment-validation.md](references/segment-validation.md) — validating/invalidating a segment from evidence, the tells of an ICP that is too broad, turning findings into a sharper ICP and disqualification criteria.

## Assets

- [assets/icp-scorecard.md](assets/icp-scorecard.md) — fillable firmographic-and-behavioral fit rubric: score each account, mark outcome, surface the won-vs-lost pattern.
- [assets/win-loss-interview-guide.md](assets/win-loss-interview-guide.md) — fillable buyer-side interview guide for won, lost, and churned deals.

## Related skills

- [ux-research](../ux-research/SKILL.md) — studies the user's experience and builds personas/JTBD *inside* the ICP this skill validates. This skill is upstream; it decides who, ux-research studies how they experience the product.
- [growth-engine](../growth-engine/SKILL.md) — runs experiments and segmentation that assume the ICP is already known. This skill produces that ICP; growth-engine consumes it.
- [revenue-intelligence](../revenue-intelligence/SKILL.md) — extracts structured insight from sales-call transcripts. This skill consumes those insights as win-loss evidence; it does not parse transcripts.
- [marketing-shaper](../marketing-shaper/SKILL.md) — owns marketing execution against a settled ICP. This skill decides and validates the ICP that marketing then targets.
- [technical-product-management](../technical-product-management/SKILL.md) — turns the validated ICP and segment evidence into prioritization and roadmap decisions.
