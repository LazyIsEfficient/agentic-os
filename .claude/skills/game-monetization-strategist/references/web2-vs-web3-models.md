# Web2 vs Web3 monetization models

The monetization math is the same; the constants and constraints differ. Treat web3 as a *rails decision* (per `game-concept-creator`) and a *model dimension*, not a free pass.

## When web3 makes monetization sense

Web3 monetization fits when one or more is true:

- **Trading is the verb.** Players' core enjoyment is buying / selling / market-making. Web3's secondary markets serve this.
- **Identity through items is the fantasy.** Owned, transferable assets carry social status. NFTs serve this.
- **Persistent consequence is the design.** Player choices propagate and persist. On-chain provenance serves this.
- **Cross-game / cross-app value matters.** Same asset travels between products. NFTs serve this (with all the platform politics).

Web3 monetization fights the design when:

- The fantasy is *not* commercial. Adding money-shaped UX disrupts immersion.
- Items need frequent rebalance. NFTs are hard to nerf without revolt.
- The audience doesn't have wallets. Conversion friction kills the funnel.
- The platform is hostile. App Store and Google Play restrict crypto IAP heavily; Steam restricts NFT/crypto.

## Web3 model variants

### Token-only

Players earn / hold / trade an in-game token. Token has real-money value via DEXes / CEXes.

**Revenue:**
- Token sale (primary issuance — often pre-launch via presale)
- Marketplace transaction fees (when players trade)
- Tokens held by treasury / team
- IAP for token packs (where allowed by platform)

**Risks:**
- Token velocity collapse if sources outpace sinks (the most common failure)
- Speculative crash decoupled from gameplay
- Regulatory reclassification (security token)
- Players treat earnings as wages, not gameplay → quit when ROI drops

### NFT-only

Items / characters / land are NFTs. Players own and trade them.

**Revenue:**
- Primary mint
- Secondary market royalties (1–10% per trade, where chain enforces)
- Premium content packs

**Risks:**
- Floor-price collapse if minting outpaces demand
- NFT'd items can't be balanced (owners revolt at nerfs)
- Secondary market dries up; assets feel worthless
- Royalty enforcement weakening (recent EVM marketplace shifts)

### Hybrid web3 (token + NFT)

Both. Players have currencies (token) and items (NFTs). Common in "AAA web3" attempts.

**Revenue:**
- Both above
- Plus: cross-asset interaction fees (use token to upgrade NFT, etc.)

**Risks:**
- Both above, compounded
- Operational complexity (two on-chain systems to monitor)

### Hybrid web2 + web3

Web2 storefront (App Store / Google Play / Steam) for mass market + optional web3 layer for crypto-native players.

**Revenue:**
- Web2 IAP (majority for most launches)
- Web3 token / NFT sales (minority, for crypto-curious segment)

**Risks:**
- Platform hostility (App Store / Google Play restrict crypto coexistence)
- Segments cannibalize each other
- Messaging confusion ("is this a crypto game or not?")

## Token economy fundamentals

Three rules for any token economy:

1. **Sinks before sources.** Plan how the token *leaves* the player's possession before you plan how it enters. Sources without sinks = inflation = collapse.
2. **Velocity discipline.** Token velocity (how fast tokens cycle) determines price stability. Low velocity (people hold) → price holds. High velocity (people sell immediately) → price falls.
3. **Demand drivers.** Tokens need *reasons to want them* — usually: required for content access, status, governance, or staking rewards. "Speculation" alone is a fragile demand driver.

## NFT design fundamentals

Three rules for NFT-as-content:

1. **Don't NFT what you'll need to balance.** Combat-effective items, characters in PvP, anything with a "meta" → keep web2. NFT cosmetics, identity items, collection items, narrative artifacts.
2. **Plan for additions, not subtractions.** New content rebalances the meta naturally; nerfing existing NFTs creates owner revolt.
3. **Royalty fragility.** Recent EVM marketplaces have weakened royalty enforcement. Don't bet the model on secondary royalties; treat them as bonus.

## Web2 fallback

If the rails include web3, the game *must* answer: "How does the game work for a player who can't or won't connect a wallet?"

Options:
- **Custodial wallet on signup** — game creates a wallet for the player; they can claim later. Friction-low; trust-low (custody question).
- **Optional wallet** — game is fully playable without; on-chain features are optional. Friction-low; ROI-on-web3 is also low.
- **Required wallet** — game won't run without one. Friction-high; reachable market shrinks dramatically.

The choice constrains acquisition cost and reachable market. Capture in the strategy.

## Platform constraints (web2 vs web3)

| Platform | Web2 IAP | Web3 token IAP | Web3 NFT mint | Notes |
|---|---|---|---|---|
| App Store | Allowed | Restricted (esp. crypto rails) | Restricted (no in-app NFT mint allowed in many cases) | Apple takes 30%; web3 features must comply |
| Google Play | Allowed | Restricted | Restricted (similar) | Google takes 15–30%; web3 IAP-adjacent flagged |
| Steam | Allowed | Banned | Banned | Steam disallows crypto in published games |
| Epic | Allowed | Allowed (case-by-case) | Allowed (case-by-case) | More open than Steam |
| Web (desktop) | Allowed | Allowed | Allowed | No platform tax; weaker discovery |
| Console (PS / Xbox / Switch) | Allowed (per platform) | Effectively banned | Effectively banned | Console policies block web3 currently |

If the rails include web3, document the platform exclusions in the strategy. They constrain reachable market significantly.

## Jurisdictional constraints

Crypto regulation varies by region:

- **US** — securities scrutiny on tokens; state-level restrictions (e.g. NY)
- **EU** — MiCA framework; KYC requirements; NFT classification varies
- **UK** — FCA registration requirements
- **China / Korea / Japan** — restrictive on crypto IAP
- **Tier-3 markets** — often web3-friendly but lower paying capacity

Check before model lock. Excluded geos shrink the reachable market and change the LTV math.

## Output for the strategy

If the rails include web3:
- **Token role:** currency / governance / reward / speculation
- **NFT role:** cosmetic / collection / identity / gameplay (the last with a nerf-risk note)
- **Sinks plan:** what absorbs token supply
- **Secondary market policy:** royalty rate, allowlist
- **Web2 fallback:** what non-wallet players can do
- **Platform / jurisdictional exclusions:** documented
- **Risk register:** token velocity, NFT illiquidity, regulatory action — with mitigations
