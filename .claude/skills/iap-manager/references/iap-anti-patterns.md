# IAP anti-patterns

Patterns that hurt revenue, retention, or trust. Many show up "by accident" when teams optimize a single SKU's conversion without thinking about the catalog as a whole.

## 1. Mid-tier vacuum

Catalog has $0.99–$4.99 entry SKUs and $49.99+ whale SKUs but nothing in $9.99–$19.99. Dolphins (the bulk of payers) have nowhere to land.

**Fix:** populate the ladder. Season pass at $9.99. Mid-bundle at $19.99.

## 2. Bundle bloat

8+ active bundles at once. Choice paralysis. Conversion drops despite more options.

**Fix:** rotate bundles weekly. Display 2–3 active at once. Retire low-performers.

## 3. Fake scarcity

"23:59:58" countdown that resets every load. "Limited stock!" with no actual stock limit. Players reverse-engineer this within days.

**Fix:** make limited-time real. End the offer when the timer hits zero. Honest scarcity converts; fake scarcity destroys trust.

## 4. Hidden subscription cost

Sub price displayed in tiny text. "Free trial!" with the recurring cost buried. Cancellation flow with friction.

**Fix:** display recurring cost clearly. Free trial mentions when billing starts. Cancellation is simple. (Apple / Google policy require some of this; do *more* than minimum.)

## 5. Confused currencies

Multiple soft currencies that look the same (gold + silver + bronze + medal). Players can't tell what costs what.

**Fix:** 1–3 currencies, clearly distinct in role and visual identity. Strict catalog hygiene.

## 6. Inflated value comparisons

"$50 of value for $20!" when the parts aren't actually worth $50. Players reverse-engineer comps.

**Fix:** comp must reflect actual prices in the catalog (or believable in-game equivalents). Never inflate.

## 7. Predatory paywalls

Hard pop-ups every 30 seconds. Forced paywalls (no dismiss). Whale-targeted high-pressure offers.

**Fix:** dismissibility is mandatory. Hard pop-up frequency capped. Whales don't need pressure; they want clarity and value.

## 8. Starter pack v2

Player buys the starter pack; an "upgraded" starter pack appears with the same shape. Players catch on within hours.

**Fix:** starter pack is *one-time per account*. Subsequent offers can exist (returning-player bundle, anniversary bundle) but should have different identities.

## 9. Bait-and-switch composition

Bundle composition changes after launch ("we removed item X from this SKU"). Players who haven't bought it yet don't notice; players who already bought feel betrayed.

**Fix:** never silently change a live SKU's composition. Retire the SKU and launch a new one with the new composition.

## 10. Silent re-pricing

Live SKU's price changes without comms. Players notice; community erupts.

**Fix:** announce price changes in advance (1–2 weeks). Compensate buyers who paid the old price near the change. Coordinate with `game-marketer`.

## 11. Subscription that gates content

Sub that locks gameplay (not just enhances it). Non-subscribers feel paywalled out of their game.

**Fix:** subs enhance experience. Cosmetics, ad removal, daily currency. Don't gate gameplay behind sub unless the entire model is sub-based (MMO).

## 12. Battle pass burnout

Back-to-back passes with no breaks; weak free track; pass length wrong.

**Fix:** 1–2 week gaps between seasons. Free track has meaningful rewards. Pass length 4–12 weeks.

## 13. Discount erosion

Premium / DLC discounted aggressively at first sale. Players learn to wait. Long-tail revenue collapses.

**Fix:** hold full price for first 6–12 months. Sales are events, not the default state.

## 14. Whale-specific dark patterns

Targeting whales with "spend $1,000 in 24 hours to unlock X" pressure tactics. Some convert; many burn out and leave.

**Fix:** whales want clear aspirational targets and steady supply, not pressure. Status tiers, named SKUs, "founders" recognition. Treat whales as long-term relationships, not extraction targets.

## 15. Ad-network targeting hostility

Showing high-frequency ads to paying users. "I paid to remove ads, why am I seeing them?" Ad-removal SKU should remove *all* ads, including in promotional placements.

**Fix:** segment-aware ad serving. Payers see fewer ads; ad-removal SKU is universal.

## 16. Region price arbitrage gap

Prices in tier-3 regions are dramatically lower than tier-1 (legitimate, PPP-based) but the gap is so large that VPN arbitrage becomes worthwhile.

**Fix:** keep PPP discounts reasonable (typically 30–60% off tier-1 USD, not 90%). Geolocate strictly.

## 17. Restore-purchases buried

Players who reinstall can't find the restore button. Trust drops; refund requests rise.

**Fix:** prominent restore button in store / settings. Test the restore flow for every SKU type before launch.

## 18. Cross-platform inventory mismatch

Players buy on iOS; play on Android; the SKU isn't there. Or vice versa. Refund requests; community uproar.

**Fix:** account-bind purchases. Receipt validation server is single source of truth across platforms.

## 19. Web3 mint-and-disappear

Primary mint sells out; the team's energy moves elsewhere; secondary market collapses; assets feel worthless.

**Fix:** plan for *post-mint* operations as carefully as the mint itself. Roadmap of utility, content, events. NFT projects are long-term commitments.

## 20. KYC surprises

Web3 game requires KYC at certain thresholds (regulatory) but players aren't told upfront. Player invests, hits the threshold, gets gated.

**Fix:** disclose KYC requirements at sign-up. Map the restrictions clearly per jurisdiction.

## 21. Loot box opacity

Drop rates not disclosed. Pity timer hidden. Players reverse-engineer; in some markets, this violates regulation.

**Fix:** disclose drop rates. Document pity timers. Comply with regional rules (JP, KR, EU all have rules).

## 22. The "monetization-as-feature" reflex

Adding monetization elements late in development as a way to "increase revenue." The bolt-on feels bolted-on; conversion is poor; team is mystified.

**Fix:** monetization is part of the design. The catalog matches the game's verbs and aesthetics, not a separate stack.
