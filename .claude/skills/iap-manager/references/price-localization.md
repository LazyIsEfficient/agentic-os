# Price localization

Pricing for non-USD regions. The wrong way: convert USD to local currency at today's exchange rate. The right way: anchor to local price psychology and platform tier maps.

## Why flat conversion fails

A flat conversion of $4.99 USD to JPY today might be ¥740 — but Japanese players price-anchor on round numbers like ¥600, ¥1,000, ¥1,200. ¥740 reads as "untrusted / weird," ¥610 reads as "small."

The platforms (Apple, Google) maintain region-anchored tier maps that already encode this psychology. Use them.

## Apple App Store tier map

App Store has numbered tiers (T1, T3, T5, T10...). Each tier maps to a specific price per region. Apple's tier map handles:
- Local price psychology (round numbers, .99 endings)
- Local tax inclusion (VAT in EU, GST in AU)
- Platform fees
- Currency volatility (Apple periodically revises)

**Use Apple's tier system unless you have a specific reason to override.**

Reference: Apple's "Choose a Pricing Tier" documentation in App Store Connect (changes periodically).

## Google Play tier map

Similar to Apple. Google publishes their pricing recommendations per region. Mostly aligned with Apple but minor differences exist.

**Use Google's recommendations unless overriding for a specific reason.**

## Steam pricing

Steam allows custom prices but provides regional pricing recommendations (USD → local with PPP-style adjustments). The recommendations are sensible defaults; deviating without reason often loses revenue.

Round to .99 / .49 conventions. Don't price at $4.27 or €5.13.

## Web (Stripe / direct)

Custom pricing supported. Anchor to local platform conventions (use App Store / Google Play pricing as a guide even on web).

## Web3 marketplaces

Token-priced SKUs depend on the chain-native token's value. Display fiat equivalent at purchase time; otherwise volatility leaves players confused. NFT mints typically priced in chain-native (ETH, SOL, MATIC).

## Per-region notes

### Tier-1 markets (US, EU, UK, JP, KR, AU, CA, etc.)

- Use platform tier maps directly
- High ARPPU but high CPA
- Tier 1–6 SKUs all populated

### Tier-2 markets (BR, MX, RU, TR, AR, etc.)

- PPP-adjusted prices (platform tier maps already do this)
- High install volume; lower per-install ARPU
- Tier 1–4 dominate; whale conversion is rare

### Tier-3 markets (IN, ID, VN, PH, MY, TH, etc.)

- Heavy PPP discount
- Very price-sensitive
- Low-tier SKUs ($0.99 / $2.99 / $4.99) drive most revenue
- Local payment rails (UPI in IN, GoPay in ID) outperform Western IAP — coordinate with `godot-engineer`

### High-inflation markets (TR, AR, sometimes others)

- Price tier maps update frequently — check quarterly
- Players adapt fast; perceived "fair" prices shift
- Consider local-currency-pegged pricing (rare; overhead high)

### Restricted markets

- **CN:** iOS only (App Store China); Google Play unavailable; consider local Android stores (Tencent, Huawei, Xiaomi)
- **KR:** age verification required for some IAP categories
- **JP:** loot box / gacha disclosure required (probability rates)
- **EU:** GDPR + tax inclusivity (VAT)
- **Web3:** check per-region crypto policy; may exclude EU (MiCA requirements), US (state-by-state), CN (banned)

## Cross-border arbitrage

Players use VPNs / alt-region accounts to buy at lower-PPP prices. Mitigations:

- Apple / Google enforce regional billing reasonably (alt-region accounts are flagged on payment method mismatch)
- Steam has gift-region restrictions
- Stripe / web — geolocate at checkout (IP-based or shipping/billing address verification)

A small amount of arbitrage is normal; large amounts indicate prices are too far apart and revenue is being lost. Tighten the gap.

## Localization beyond price

- **SKU names** — translate to local language; not just the price changes
- **Display copy** — "Halloween Bundle" doesn't land in markets where Halloween isn't common; use local equivalents (e.g. "Spooky Festival Bundle" in less-Halloween markets, or skip)
- **Cosmetic themes** — Lunar New Year for CN/KR/VN, Diwali for IN, etc. Coordinate with `game-marketer` for content production
- **Holiday timing** — region-specific timing for sales (Black Friday US, 11.11 CN, Golden Week JP/KR, etc.)

## Refresh cadence

- **Quarterly:** review prices vs platform tier-map updates and high-inflation regions
- **On platform tier-map updates:** Apple / Google publish updates periodically
- **On regional event windows:** Black Friday / 11.11 / Golden Week / etc.
- **On significant currency shifts:** if local currency moves >15% against USD over a quarter, re-evaluate

## Output

- Filled `region-price-table-template.md` per major region
- Per-region SKU display copy (translated)
- Local payment rails plan (with `godot-engineer`)
- Region-specific bundles (with `game-marketer` for theming)
