# Bundle composition — <bundle name>

## Bundle identity
- **SKU:** `bundle_<name>_v<n>`
- **Price tier:** <e.g. $9.99>
- **Display copy:** <"Halloween Bundle — limited time">
- **Availability:** <always-on / limited-time / segment-targeted / one-time per account>
- **Display window (if limited-time):** <dates>

## Composition

| Item | Type | Qty | Standalone price | Notional value |
|---|---|---|---|---|
| Gems | Currency | 1,200 | (bundle equivalent: $9.99 pack alone) | $9.99 |
| Halloween Skin | Cosmetic | 1 | $4.99 (if sold solo) | $4.99 |
| 5,000 Gold | Currency | 5,000 | (in-game equivalent) | $2.00 |
| 3 Energy Refills | Consumable | 3 | $0.99 each | $2.97 |
| **Total notional** | | | | **$19.95** |

- **Bundle price:** $9.99
- **Discount %:** 50% off notional
- **Honest comp:** Yes — components are sold standalone at the listed prices (or are believable in-game-economy equivalents)

## Segment target
- **Primary:** <e.g. Dolphin>
- **Secondary:** <e.g. Minnow upgrading>

## Anchoring / decoy
- **Anchor SKU:** <which SKU in the catalog this is positioned next to — a decoy or comparison>
- **Decoy effect:** <e.g. "displayed next to a $4.99 small pack to make $9.99 look like 'much more value'">

## Comms
- **Where it's surfaced:** <store front page / event banner / paywall pop-up / push notification>
- **Display copy:** <e.g. "Get 50% off Halloween essentials!">
- **CTAs:** <"Grab the bundle">

## Telemetry
- `iap_view(bundle_<name>)`, `iap_purchase(bundle_<name>)`
- A/B variant: <if any>

## Performance gates
- **D1 conversion target:** <% of viewers who buy>
- **Repeat purchase (if not one-time):** <% of buyers who purchase again>
- **Kill criterion:** <e.g. "if conversion < 0.5% by D14, replace">
