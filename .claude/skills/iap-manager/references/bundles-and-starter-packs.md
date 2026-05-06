# Bundles and starter packs

The two highest-leverage SKU types in F2P. A catalog with strong bundles and a strong starter pack outperforms a catalog with great currency packs alone.

## Why bundles work

- **Perceived value** — a bundle of 3 things at 30% off feels like *more* than 3 separate purchases at single price
- **Anchoring** — the "regular price" comparison primes the discount
- **Decoy effect** — placing a small SKU next to the bundle makes the bundle look like the better deal
- **Decision economy** — players don't have to choose between "should I buy currency or cosmetic"; the bundle gives them both

## Bundle composition principles

A good bundle:

1. **Mixes value types.** Currency + cosmetic + utility hits more player motivations than 3 currency packs.
2. **Includes a "hero" item.** One thing in the bundle that's genuinely desirable on its own (the legendary cosmetic, the season pass).
3. **Has an honest comp.** The "$50 of value for $20" claim must reflect actual prices. Inflated comps are detected and trust drops.
4. **Targets a segment.** A bundle for whales has different composition than a bundle for minnows.
5. **Carries a theme.** Thematic bundles (Halloween, anniversary, season opening) feel curated; arbitrary bundles feel like inventory clearance.

## Bundle pricing

- **30–50% off notional** is the sweet spot. Less feels stingy; more makes the comp look manipulated.
- **Bundle should land at a clear tier** ($9.99 / $19.99 / $49.99) — not $11.99 (looks weird).
- **Limited-time** versions can carry higher prices if the limited-time is real.

## Starter pack

The single highest-leverage SKU in F2P. A well-designed starter pack converts 5–15% of free players into payers within their first week.

### Starter pack rules

1. **Surface early** — D1–D3 of play, after the first wow moment, before any other paywall.
2. **One-time per account** — buying it removes the offer; no "v2" replacement.
3. **Heavy discount** — 70–90% off equivalent value (justified by lifetime value of converting a free player into a payer).
4. **Tier 2 ($4.99)** — low friction; minnow-level commitment.
5. **Mix of value types** — currency + cosmetic + utility (mirrors a good bundle).
6. **Time-limited** — 48–72 hours after first surface.
7. **Honest content** — no hidden caveats, no "valid only on certain levels."

### Starter pack composition example (mobile RPG)

| Item | Equivalent value | Notes |
|---|---|---|
| 500 gems | $4.99 | (a small pack alone costs $4.99) |
| 5,000 gold | $2.00 | in-game equivalent |
| Hero crystal × 5 | $5.00 | (each is 1/10 of a $9.99 hero pull) |
| Energy refill × 3 | $2.97 | |
| Exclusive cosmetic | $4.99 | starter-pack-only — never sold elsewhere |
| **Total notional** | **~$20** | |
| **Bundle price** | **$4.99** | |
| **Discount** | **75%** | |

That's "$20 for $5" — a *real* deal that converts.

## Themed bundles

Themed bundles (Halloween, Christmas, Lunar New Year, anniversary, world events, character birthdays) carry narrative weight and feel less transactional.

### Theme bundle rules

1. **Theme connects to game world** — Halloween in a fantasy game lands; Halloween in a sci-fi game requires more effort.
2. **Limited-time is real** — typically 1–4 weeks.
3. **Includes themed cosmetic** — ideally only available in this bundle.
4. **Returns annually** — players know the Halloween bundle comes back, which both creates anticipation and reduces FOMO.

## Decoy effect

Placing a low-value SKU next to a bundle makes the bundle look better:

- Bundle (1,200 gems + skin + 5,000 gold) at $9.99
- Decoy SKU: 500 gems alone at $4.99

The bundle reads as "for $5 more I get a skin and 5,000 gold AND more gems." Conversion to bundle goes up.

This is **not** dark pattern — both SKUs are real and honest. The decoy just shapes the perceived value of the bundle.

## Per-segment bundles

| Segment | Bundle shape | Tier | Hero item |
|---|---|---|---|
| Minnow | Starter pack (one-time) | $4.99 | Cosmetic + currency |
| Dolphin | Themed bundle (weekly) | $9.99 | Themed cosmetic + 1,200 gems |
| Whale | Premium bundle (limited) | $49.99 | Legendary cosmetic + huge currency |

## Anti-patterns

- **Bundle stacking** — 5 active bundles at once. Choice paralysis. Conversion drops despite more options.
- **Bundle re-runs as "limited-time"** — players notice repetition. Trust drops.
- **Inflated value comps** — "$200 of value for $20!" with the parts not actually sold at the listed prices. Players reverse-engineer this.
- **Starter pack v2 after the first one is bought** — same offer, different name. Detected; trust drops.
- **Bundles that cost more than the sum of parts** — sometimes happens with currency + sub bundles where the math is bad. Insulting; conversion drops.

## Telemetry

Per bundle:
- **View rate** — % of DAU who saw the offer
- **Conversion rate** — % of viewers who bought
- **Repeat purchase** — % of buyers who buy the bundle again (when applicable)
- **Per-bundle ARPDAU contribution**
- **Downstream LTV** — buyers' D30 / D90 LTV vs non-buyers' (validates the bundle is *acquiring* spending behavior, not just shifting it)

Hand the telemetry contract to `godot-engineer` for instrumentation.
