# Price-tier ladder — <game title>

> Verifies every price tier has at least one compelling SKU per segment. Re-verified at every catalog refresh.

## Tier table

| USD tier | App Store tier | Google Play tier | Steam pricing | Audience | Min SKUs in tier | SKUs populated |
|---|---|---|---|---|---|---|
| $0.99 | T1 | ¥120 / ₹85 / equiv | $0.99 | Free → first-touch | 0–1 (optional) | <list> |
| $2.99 | T3 | ¥370 / ₹250 / equiv | $2.99 | Minnow utility | 1 | <list — e.g. ad-removal> |
| $4.99 | T5 | ¥610 / ₹400 / equiv | $4.99 | Minnow / starter | 2 | <list — starter pack, small currency> |
| $9.99 | T10 | ¥1,220 / ₹800 / equiv | $9.99 | Dolphin core | 2–3 | <list — season pass, mid currency, themed bundle> |
| $19.99 | T20 | ¥2,440 / ₹1,600 / equiv | $19.99 | Dolphin / whale-bridge | 1–2 | <list — premium pass, large currency> |
| $49.99 | T50 | ¥6,100 / ₹4,000 / equiv | $49.99 | Whale | 1–2 | <list — whale currency, legendary cosmetic> |
| $99.99 | T100 | ¥12,200 / ₹8,000 / equiv | $99.99 | Top whale | 1 | <list — top whale currency / named bundle> |

## Coverage check

- [ ] Every tier has at least the minimum SKU count
- [ ] Each segment (whale / dolphin / minnow / free) has clear paths through the ladder
- [ ] No "mid-tier vacuum" (gap between $4.99 and $19.99 with no SKUs)
- [ ] No "top-tier vacuum" (whale has nowhere to spend after $49.99)
- [ ] Currency packs scale value-per-dollar across tiers (bigger packs are better deals)
- [ ] Per-platform price tier maps verified (App Store T20 ≠ flat USD conversion in some currencies)

## Notes
- App Store / Google Play tier maps change periodically. Re-check the platform documentation when adding new regions.
- Steam allows custom prices but conventional rounding to .99 / .49 is expected.
- Web (Stripe) allows arbitrary prices — use the same psychology rather than odd pricing.
