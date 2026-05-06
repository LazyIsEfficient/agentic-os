# Region price table — <game title>

> One row per SKU × region. Anchored to local price psychology, not flat USD conversion.

## Per-SKU price localization

### Example SKU: `starter_pack_v1` (USD $4.99)

| Region | Currency | Local price | Anchor psychology | Platform tier mapping |
|---|---|---|---|---|
| US | USD | $4.99 | "small impulse" | App Store T5 / Google Play tier 5 |
| EU | EUR | €4.99 | "small impulse" | App Store T5 EU |
| UK | GBP | £4.49 | "small impulse — slight discount vs EU" | App Store T5 UK |
| JP | JPY | ¥610 | "small price; 100s feel cheap" | App Store T5 JP |
| KR | KRW | ₩6,500 | "small bundle" | App Store T5 KR |
| BR | BRL | R$24.90 | "moderate — local PPP adjusted" | App Store T5 BR |
| MX | MXN | $99 | "moderate" | App Store T5 MX |
| IN | INR | ₹399 | "moderate; rupee psychology" | App Store T5 IN |
| TR | TRY | ₺149 | "moderate; aggressive PPP — high inflation" | App Store T5 TR |
| RU | RUB | ₽449 | "moderate" | (verify availability) |
| CN | CNY | ¥35 | "moderate; iOS only — Google Play unavailable" | App Store T5 CN |
| ID | IDR | Rp75,000 | "moderate" | App Store T5 ID |
| TH | THB | ฿179 | "moderate" | App Store T5 TH |

## Notes per region

- **JP:** users price-anchor on ¥. ¥610 reads as "small," ¥1,220 as "medium." Don't price at ¥600 (looks generic).
- **KR:** similar to JP but slightly lower yen/won mapping. ₩6,500 is App Store T5.
- **BR / MX / TR:** PPP-adjusted prices. Apple / Google's tier maps already do this; verify the ratio.
- **IN:** very price-sensitive; ad-supported and low-tier IAP dominate.
- **CN:** iOS-only; Google Play unavailable; consider local PRC stores (Tencent, Huawei) for separate distribution.
- **EU:** VAT inclusive. Some markets show price ex-VAT and add at checkout (Amazon style); games typically show inclusive.

## Cross-border arbitrage
- **Risk:** users buying via low-price-region accounts (VPN, alt-region accounts).
- **Mitigation:** Apple / Google enforce regional locks reasonably; for Steam DLC, regional gifting limits help. For Stripe / web, geolocate at checkout.

## Web3 pricing notes (if applicable)
- **Token price:** floats; pricing in USD anchor + on-chain conversion at purchase time
- **NFT mint:** typically priced in chain-native token (ETH / SOL / etc.), not in fiat
- **Royalty:** displayed clearly in marketplace listings; separate from price

## Refresh cadence
- **Quarterly review** of all region prices vs local PPP shifts (especially high-inflation markets)
- **On platform tier-map updates** (App Store / Google Play change tier maps periodically)
- **On regional events** (Black Friday in US, 11.11 in CN, golden weeks in JP / KR, etc.) — coordinate with `game-marketer`
