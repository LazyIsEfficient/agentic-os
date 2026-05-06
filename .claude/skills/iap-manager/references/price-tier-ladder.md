# Price-tier ladder

The set of price points a game offers. Each tier serves a segment and a moment. Healthy catalogs populate every tier with at least one compelling SKU; gaps in the ladder leave money on the table.

## The standard tiers (USD)

| Tier | USD | Audience | Common SKU type | Mood |
|---|---|---|---|---|
| T1 | $0.99 | First-touch / tip jar | Tiny currency pack | "Try the IAP path" |
| T2 | $2.99 | Minnow utility | Ad-removal, smallest currency | "Friction removal" |
| T3 | $4.99 | Minnow / starter | Starter pack, small currency, monthly sub | "Easy yes" |
| T4 | $9.99 | Dolphin core | Season pass, mid currency, themed bundle | "Worth it" |
| T5 | $19.99 | Dolphin / whale-bridge | Premium pass, large currency, dolphin bundle | "Treat yourself" |
| T6 | $49.99 | Whale | Whale currency, legendary cosmetic | "I want all the things" |
| T7 | $99.99 | Top whale | Top whale currency, named bundle, founders | "I love this game" |

(Some platforms / regions add $14.99, $29.99, $79.99 intermediate tiers — use them when populating mid-tier bundles.)

## Tier psychology

Different tiers feel different to players:

- **$0.99** — "free-but-paying"; lowest commitment; useful for "try the IAP" moment
- **$2.99 / $4.99** — "small impulse"; feels free relative to a coffee; minimal regret
- **$9.99** — the "premium app price" anchor; people compare to apps and games they've bought
- **$19.99 / $49.99** — "deliberate purchase"; players think before clicking
- **$99.99** — "I'm investing in this game"; serious whale signal

Pricing at $4.99 vs $5.99 isn't 20% — it's the difference between "small impulse" and "I'm thinking about this." Anchor to the psychology, not the linear price.

## Coverage rules

- **Every tier T2–T6 should have at least one SKU.** If T2 is missing, minnows have no entry; if T5 is missing, whales hit a ceiling and stop.
- **No more than 3 SKUs per tier on display at once.** More than that is choice paralysis.
- **The ladder should *progress in value*.** Tier 3 should give better value-per-dollar than Tier 2 *only if it has more content*. Don't punish minnows by making the small pack a worse deal.

## Common gaps

### Mid-tier vacuum

The catalog has $0.99–$4.99 entry SKUs and $49.99+ whale SKUs, but nothing in the $9.99–$19.99 band. Dolphins (the bulk of payers) have nowhere to land. Conversion to dolphin-tier spend stalls.

**Fix:** add 1–2 SKUs at $9.99 (season pass, mid-currency bundle) and 1 at $19.99 (premium bundle).

### Top-tier vacuum

The catalog has $0.99–$19.99 SKUs but nothing above. Whales hit the ceiling and stop spending.

**Fix:** add a $49.99 currency pack and a $99.99 named bundle / founders.

### Bottom-tier vacuum

The catalog starts at $9.99. Free-to-minnow conversion is poor because the entry friction is too high.

**Fix:** add a $2.99 ad-removal or $4.99 starter pack.

## Per-platform tier maps

The platforms do not all use linear prices.

### App Store

App Store tiers are numbered (T1, T3, T5, T10, T20...). Apple maintains a tier-map document that translates between tiers and local prices for each region. The mapping is **not** a flat exchange rate — it's anchored to local price psychology.

- T1: $0.99 / ¥120 / £0.99 / €0.99
- T5: $4.99 / ¥610 / £4.49 / €4.99
- T10: $9.99 / ¥1,220 / £9.99 / €9.99
- T20: $19.99 / ¥2,440 / £18.99 / €19.99

Use Apple's tier — don't invent local prices. Apple's psychology research is doing work for you.

### Google Play

Similar structure (price tier maps); broadly aligned with App Store. Verify the exact mapping for new SKUs.

### Steam

Steam allows custom prices but has regional pricing recommendations. Use the recommendations as a baseline and adjust. Round to .99 / .49 conventions.

### Web (Stripe)

Arbitrary pricing supported. Use the same psychology as platform tiers. Avoid weird prices like $4.27 — players read them as "untrusted."

### Web3 marketplaces

Token-priced SKUs depend on chain-native token. NFT mints are typically priced in chain-native. Disclose any wrapper / fiat conversion clearly.

## Refresh cadence

- **Quarterly:** review tier population; identify gaps; add SKUs as needed
- **On platform tier-map updates:** Apple / Google publish updates periodically
- **On regional events:** holiday-specific SKUs at adjusted tiers (Black Friday, 11.11, golden week)
