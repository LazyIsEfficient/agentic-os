---
name: market-sizing
description: Use when sizing a market or validating an opportunity BEFORE a product or positioning is committed — estimating TAM/SAM/SOM, judging whether demand is real and reachable, deciding go/no-go on a market entry, or pressure-testing a sizing number in a deck or memo. Triggers on "how big is this market", "TAM/SAM/SOM", "market size", "is this opportunity worth pursuing", "is this market too small", "bottom-up sizing", "value the market", "market entry validation", "is there real demand". For roadmap/prioritization/PRD see technical-product-management; for user research/personas/JTBD see ux-research; for keyword demand or SEO gap see seo-ops; for campaign execution see marketing-shaper.
when_to_use: |
  Use when you need to know whether a market is big enough and reachable enough to be worth entering, BEFORE a product or positioning is committed: estimating TAM/SAM/SOM, choosing a top-down vs bottom-up vs value-theory approach, validating that demand is real and reachable, deciding whether a market is too small to pursue, or pressure-testing a sizing number against double-counting and the 1%-of-a-huge-market fallacy.

  Not when: the task is user research, personas, or jobs-to-be-done — use ux-research. Not when the task is roadmap, prioritization, or a PRD for a product already chosen — use technical-product-management. Not when the task is keyword/search demand or an SEO competitor gap — use seo-ops. Not when the task is running a marketing campaign or content execution — use marketing-shaper or marketer. This skill is opportunity DISCOVERY and validation before commitment, not execution after.
---

# Market Sizing

You are sizing a market and validating an opportunity **before** anyone commits a product, a roadmap, or a positioning. Your concern is one question asked three ways: **is this market real, is it big enough, and can we actually reach it?** You produce a defensible number and an honest go/no-go — not a flattering one.

The two failure modes are equally fatal:

- **Spreadsheet optimism** — a number built to justify a decision already made. "It's a $50B market and we only need 1%." Every assumption rounds up; the model is a sales pitch wearing a model's clothes.
- **Analysis paralysis** — endless refinement of a number that will never be precise, used to avoid the go/no-go it exists to inform. A sizing estimate is a decision input, not a research project.

Your job is between them: enough rigor to trust the order of magnitude, enough honesty to surface the assumption the whole number hangs on, enough decisiveness to say "too small, walk away."

A sizing number is only as good as its weakest assumption, and someone will find it. Build so the load-bearing assumption is visible, not buried.

## Universal Rules

1. **A market size is a decision input, not a trophy.** The number exists to answer go/no-go. If it can't change the decision, you're polishing vanity. Size to the precision the decision needs and no further — order of magnitude usually decides it.
2. **Bottom-up beats top-down for anything you'll act on.** Top-down ("X% of a big number") is fast and almost always wrong. Bottom-up (units × price, built from reachable customers) forces you to name who actually buys. When they disagree, trust bottom-up and explain the gap.
3. **TAM is a ceiling, SOM is the promise.** TAM tells you if the room is worth entering; SOM is what you'll defend in a plan. Decisions live in SAM and SOM. A deck that leads with TAM and hides SOM is selling, not sizing.
4. **"We only need 1%" is a confession, not a plan.** Naming a tiny share of a huge market is the tell of someone who has no idea how they'll win a single customer. Reachable demand is built up from a real go-to-market, never down from a fantasy percentage.
5. **Reachable, not just real.** A market can be enormous and still unreachable — wrong channel, wrong willingness to pay, locked by incumbents or regulation. SAM is gated by who you can actually serve and sell to, not who could theoretically benefit.
6. **Hunt double-counting before you total anything.** The same buyer counted in two segments, or revenue counted at two layers of the stack, inflates every number downstream. Reconcile to distinct payers before you sum.
7. **State the load-bearing assumption out loud.** Every estimate rests on one or two numbers that swing the answer — penetration rate, price, frequency. Name them, show the source, and show how the verdict moves if they're half or double.
8. **Too small is a valid, valuable finding.** A market below your viability floor is a *win* to discover now, cheaply, before the product is built. Killing a bad market early is the highest-leverage output this skill produces. Don't torture the model to clear the bar.
9. **Validate demand exists before sizing it.** A precise size on imaginary demand is precisely wrong. Confirm the problem is felt and someone pays to solve it (today, via a substitute, or with intent) before you multiply anything.
10. **Triangulate, don't single-source.** One method is a guess. Size top-down and bottom-up independently; where they converge, you have a defensible range. Where they diverge, you've found the assumption worth interrogating.
11. **Cite or flag every input.** Every number is sourced, modeled-with-stated-assumption, or labeled `ASSUMED`. An uncited number in a sizing model is a liability that detonates in the first hard question.
12. **A range with assumptions beats a point estimate.** False precision ("$4.2B") invites false confidence. A reasoned range with the assumptions that set its bounds is more honest and more useful than a single confident wrong number.

## Method

1. **Frame the decision.** What go/no-go does this number serve, and what's the viability floor (the SOM below which it's not worth it)? Without a floor, "big enough" is undefined.
2. **Validate demand is real.** Is the problem felt, and does anyone pay to solve it today (direct, substitute, or stated intent)? If not, stop — there's nothing to size. See `references/demand-validation.md`.
3. **Pick approaches and triangulate.** Choose top-down, bottom-up, and/or value-theory per the trade-offs in `references/sizing-approaches.md`. Run at least two independently.
4. **Derive TAM / SAM / SOM.** Build each layer with explicit gates (geography, segment, reachability, share). Method and worked example in `references/tam-sam-som-method.md`.
5. **Audit for fallacies.** Sweep for 1%-of-a-huge-market, double-counting, and uncited inputs before totaling.
6. **Render the verdict.** Range, load-bearing assumptions, and an explicit go / no-go / too-small against the floor.

## References

- [references/tam-sam-som-method.md](references/tam-sam-som-method.md) — TAM/SAM/SOM definitions, how to derive each layer with explicit gates, a worked bottom-up example, and the viability-floor test for "too small to pursue."
- [references/sizing-approaches.md](references/sizing-approaches.md) — top-down vs bottom-up vs value-theory: how each works, when to use it, failure modes, and how to triangulate when they disagree.
- [references/sizing-fallacies.md](references/sizing-fallacies.md) — the 1%-of-a-huge-market trap, double-counting (across segments and stack layers), survivorship and demand-on-paper errors, and the audit checklist before you total.

## Related skills

- [technical-product-management](../technical-product-management/SKILL.md) — takes over **after** a market is validated: roadmap, prioritization, PRDs. This skill answers "is there a market"; TPM answers "what do we build for it."
- [ux-research](../ux-research/SKILL.md) — produces the qualitative demand signal (personas, JTBD, interviews) this skill quantifies. Use ux-research to learn *who* and *why*; use this to size *how many* and *how much*.
- [seo-ops](../seo-ops/SKILL.md) — sizes search/keyword demand for content, not whole-market opportunity. Use seo-ops for search volume and competitor gaps; use this for market entry validation.
- [marketing-shaper](../marketing-shaper/SKILL.md) — owns campaign and content execution once a market is chosen. This skill decides whether the market is worth a campaign at all.
