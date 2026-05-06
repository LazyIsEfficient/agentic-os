# IAP catalog — <game title>

> The complete SKU list. One row per SKU. Re-issued at major catalog changes.

## Catalog summary
- **Number of SKUs:** <total — typically 12–30 for F2P, fewer for premium with DLC>
- **Catalog refresh cadence:** <weekly bundles / monthly themed / seasonal pass / event-driven>
- **Storefronts targeted:** <App Store / Google Play / Steam / Stripe / web3 marketplace>

## SKU table

| SKU ID | Name | Category | Segment | Tier | USD price | Composition | Active | Notes |
|---|---|---|---|---|---|---|---|---|
| `starter_pack_v1` | Starter Pack | Bundle | Minnow / Free→Minnow conversion | Tier 2 | $4.99 | 500 gems + 5,000 gold + Hat A | Yes | Limited to 1 purchase per account; offered on D2 |
| `gem_pack_small` | 500 Gems | Currency | Minnow | Tier 2 | $4.99 | 500 gems | Yes | Always-on |
| `gem_pack_medium` | 1,200 Gems | Currency | Dolphin | Tier 3 | $9.99 | 1,200 gems (20% bonus) | Yes | Always-on |
| `gem_pack_large` | 2,800 Gems | Currency | Dolphin | Tier 4 | $19.99 | 2,800 gems (40% bonus) | Yes | Always-on |
| `gem_pack_huge` | 8,000 Gems | Currency | Whale | Tier 5 | $49.99 | 8,000 gems (60% bonus) | Yes | Always-on |
| `gem_pack_mega` | 20,000 Gems | Currency | Whale | Tier 6 | $99.99 | 20,000 gems (100% bonus) | Yes | Always-on |
| `season_pass` | Season N Pass | Pass | Dolphin / minnow conversion | Tier 3 | $9.99 | 50-tier paid track | Yes | Refreshed every season |
| `season_pass_premium` | Season N Premium Pass | Pass | Whale | Tier 4 | $19.99 | 50-tier paid track + 10 levels skip | Yes | Refreshed every season |
| `cosmetic_legendary_a` | Dragon Skin | Cosmetic | Whale | Tier 5 | $49.99 | Legendary cosmetic | Yes | Limited-time first month |
| `bundle_themed_a` | Halloween Bundle | Bundle | All | Tier 3 | $9.99 | 1,200 gems + Halloween skin + 3,000 gold | No (event ended) | Returns next year |
| `ad_removal` | Remove Ads | Utility | Free→Minnow | Tier 2 | $2.99 | Permanent ad removal | Yes | Always-on |
| `sub_basic` | Monthly Pass | Subscription | Dolphin | n/a | $4.99/mo | 100 gems/day + ad-free + cosmetic | Yes | Auto-renew |
| ... | ... | ... | ... | ... | ... | ... | ... | ... |

## Coverage check
- **Tier 1 ($0.99):** <SKU(s) at low-friction entry tier — often a small one-time bundle or "tip jar">
- **Tier 2 ($4.99):** <starter pack, ad removal, smallest currency pack, monthly sub>
- **Tier 3 ($9.99):** <season pass, mid-currency, themed bundle>
- **Tier 4 ($19.99):** <premium season pass, large currency, dolphin bundle>
- **Tier 5 ($49.99):** <whale currency pack, legendary cosmetic>
- **Tier 6 ($99.99):** <top whale pack, named bundle>

## Segment-targeted SKU map
- **Whale:** Gem packs L-XL, Premium pass, Legendary cosmetics
- **Dolphin:** Gem packs M-L, Season pass, Themed bundles
- **Minnow:** Starter pack, Ad removal, Tier 1–2 SKUs, Season pass entry
- **Free → Minnow conversion:** Starter pack (most important), Ad removal
- **Subscriber:** Monthly pass

## Bundle compositions
> See [bundle-composition-template.md](bundle-composition-template.md) per bundle.

- **Starter Pack** — high perceived value (~80% off equivalent)
- **Halloween Bundle** — themed, limited-time
- **Anniversary Bundle** — annual, event-driven

## A/B price tests planned
> See [price-test-plan-template.md](price-test-plan-template.md) per test.

- **Test 1:** Starter Pack price ($2.99 vs $4.99 vs $7.99) — 4-week duration, primary metric: starter pack conversion + downstream LTV
- **Test 2:** Season Pass price ($7.99 vs $9.99 vs $14.99) — 8-week duration (one full season)

## Region price tables
> See [region-price-table-template.md](region-price-table-template.md) per region.

## Store config status

| Storefront | Configured | Verified | Notes |
|---|---|---|---|
| App Store Connect | ☐ | ☐ | Sandbox tested |
| Google Play Console | ☐ | ☐ | Closed track tested |
| Steam Partner | ☐ | ☐ | DLC config verified |
| Stripe (web) | ☐ | ☐ | Webhook tested |
| Web3 marketplace | ☐ | ☐ | Testnet validated |

## Telemetry contract

Per-SKU events:
- `iap_view(sku, source_screen)` — paywall view
- `iap_consider(sku)` — opens detail / tap
- `iap_purchase_init(sku)` — purchase started
- `iap_purchase_success(sku, price, region)` — purchase completed
- `iap_purchase_fail(sku, error)` — purchase failed
- `iap_dismiss(sku)` — dismissed without purchase

Funnel report per SKU: view → consider → init → success → repeat.

## Live ops cadence
- **Weekly:** new bundle / themed offer
- **Monthly:** catalog review (kill bottom-decile SKUs, add replacements)
- **Seasonal:** new battle pass; cosmetic catalog refresh
- **Annual:** anniversary event with limited-time SKUs returning

## Hand-off
- **`game-marketer`:** store-page screenshots, paywall comms, sale messaging, segment-targeted ad creative
- **`godot-engineer`:** SKU IDs, store SDKs, receipt validation, restore-purchases, IAP-event telemetry
- **`game-monetization-strategist`:** monthly read on actual ARPDAU vs predicted ARPDAU; flag if model assumptions break
- **`growth-engine`:** running the A/B tests with proper stats
- **`security-engineering`:** receipt validation, anti-fraud, web3 wallet security if applicable
