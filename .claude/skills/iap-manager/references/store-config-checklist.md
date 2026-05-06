# Store config checklist

Storefront configuration is operational glue. The catalog is right; the model is right; if the store config is wrong, none of it ships. Walk this checklist before any launch.

## App Store Connect (iOS)

- [ ] **In-App Purchases registered** — every SKU created in App Store Connect with correct product ID
- [ ] **Localizations** — display name and description per supported language
- [ ] **Pricing tier** — selected per SKU; cross-checked vs the price-tier ladder
- [ ] **Subscription group** (if applicable) — sub SKUs in the right group; auto-renewable settings correct
- [ ] **Free trial / introductory offer** (if applicable) — eligibility rules set
- [ ] **Sandbox testers** — internal test accounts can complete purchases in sandbox
- [ ] **Receipt validation** server-side ready — App Store server-to-server notification endpoint configured (with `godot-engineer`)
- [ ] **App review screenshots** — for SKUs that need review
- [ ] **Promotional offers** (if applicable) — set up and tested
- [ ] **Restore-purchases** flow tested — players who reinstall can recover purchases
- [ ] **Cross-region currency** — verified in 3+ markets

## Google Play Console (Android)

- [ ] **In-app products** — every SKU created with correct SKU ID (matching iOS naming convention if cross-platform)
- [ ] **Subscriptions** — base plans, offers, and pricing phases configured
- [ ] **Country availability** — explicit per-region; default deny for restricted markets
- [ ] **License testers** — internal accounts for closed track testing
- [ ] **Real-time developer notifications** — Pub/Sub endpoint receiving purchase events
- [ ] **Receipt validation** — server-side via Google Play Developer API
- [ ] **Closed track tested** — closed beta tested all SKUs
- [ ] **Promo codes** (if applicable) — generated and tested
- [ ] **Restore flow** tested for reinstalls
- [ ] **Subscription cancellation flow** tested (a hostile cancel flow gets you delisted)

## Steam Partner

- [ ] **DLC entries created** — each as a separate AppID linked to the base game
- [ ] **DLC pricing** — set per region (Steam recommendations or custom)
- [ ] **Microtransaction items** (if F2P) — registered in Steamworks
- [ ] **Cross-platform inventory** (if applicable) — Steam Inventory Service or custom
- [ ] **Refund policy compliance** — Steam's 2-hour / 14-day rule respected
- [ ] **Family sharing** — settings reviewed
- [ ] **Region restrictions** — no crypto in Steam (banned); check policy

## Stripe / web (direct billing)

- [ ] **Products registered** in Stripe Dashboard with correct prices
- [ ] **Webhooks configured** — `checkout.session.completed`, `invoice.payment_succeeded`, `customer.subscription.deleted`
- [ ] **Tax handling** — Stripe Tax enabled for EU VAT, US sales tax, etc.
- [ ] **3D Secure** — enabled for EU compliance (SCA)
- [ ] **Refund flow** tested
- [ ] **Subscription cancel flow** tested
- [ ] **Receipt → entitlement** server-side ready
- [ ] **Restore flow** for users switching devices

## Web3 marketplaces

- [ ] **Smart contract deployed** to target chain (with `web3-smart-contract-engineering`)
- [ ] **Contract audited** — see `security-engineering`
- [ ] **NFT metadata** — IPFS or storage gateway configured; metadata immutable (or upgradable as designed)
- [ ] **Royalty configuration** — on-chain royalty + marketplace registration (OpenSea operator filter, etc.)
- [ ] **Allowlist / mint config** — primary mint settings
- [ ] **Secondary market integration** — listed on relevant marketplaces
- [ ] **Wallet UX** — connect / sign / pay flow tested for major wallets (MetaMask, WalletConnect, Phantom)
- [ ] **Custodial wallet** path (if used) — sign-up flow tested
- [ ] **Web2 fallback** — non-wallet players have a clear path
- [ ] **Token pack config** — fiat-on-ramp configured (if applicable)
- [ ] **Jurisdictional gating** — KYC / restricted markets handled

## Cross-platform considerations

- [ ] **Cross-progress** — purchases on iOS surface on Android (and vice versa) for the same account
- [ ] **Account-binding** — players link to a shared account (game ID, social login, web3 wallet) before paying
- [ ] **Receipt validation server** — single source of truth for entitlements across platforms (with `godot-engineer`)
- [ ] **Anti-fraud** — duplicate-receipt detection, jailbreak detection, anomaly detection (with `security-engineering`)

## Pre-launch verification

- [ ] **End-to-end purchase test** in sandbox / closed track for *every* SKU
- [ ] **End-to-end restore test** (uninstall, reinstall, restore purchase)
- [ ] **Subscription auto-renew tested** (sandbox accelerated time)
- [ ] **Subscription cancel tested** (immediate access loss vs end-of-period)
- [ ] **Refund tested** (purchase → refund → entitlement removed)
- [ ] **Offline / weak-network purchase** tested
- [ ] **Locale switching** tested (player changes app language; prices update)

## Post-launch monitoring

- [ ] **Receipt validation success rate** monitored (alert at <99%)
- [ ] **Purchase failure rate** monitored (alert at >2%)
- [ ] **Restore success rate** monitored
- [ ] **Anti-fraud alerts** active (anomalous spend, repeated refunds)
- [ ] **Per-platform revenue mix** dashboarded

Hand alerts to `site-reliability-engineering`. Hand fraud to `security-engineering`.
