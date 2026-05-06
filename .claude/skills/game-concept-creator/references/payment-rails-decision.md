# Payment-rails decision

The rails decision constrains what concepts can ship and what KPIs are realistic. Surface this **before** expanding any concept.

This is a *concept-time* filter, not a deep monetization design — that lives in [`game-monetization-strategist`](../../game-monetization-strategist/SKILL.md). Here we just check that the concept and the rails are not in obvious conflict.

## The rails

| Rail | What it is | Concepts it fits | Concepts it fights |
|---|---|---|---|
| **None (premium one-time)** | Buy once, play forever | Story-driven, finite, replayable indie; high-craft single-player | Live ops; long-tail revenue games; F2P-attention-budget concepts |
| **Web2 IAP (App Store / Google Play / Steam DLC)** | Players buy items, currency, content inside the game | F2P with grind/skip loops; cosmetic-rich games; expandable content; gacha | Concepts with strict pay-to-win sensitivity (e.g. competitive PvP without skill differentiation); single-session jam games |
| **Web2 ads (rewarded / interstitial / banner)** | Ad networks pay for impressions / completions | Casual mobile, hyper-casual, idle, puzzle, lifestyle | Premium-feel games; concepts where flow-state is the value prop; web/PC/console |
| **Web2 subscription** | Recurring fee for access or perks | Service-shaped games (MMO, GaaS); ad-free tier on top of F2P; battle-pass-like content drips | Concepts without continuous content cadence; concepts where one-time mastery is the appeal |
| **Web3 tokens** | In-game currency on-chain, often with secondary market | Trading / market verbs; player-driven economies; speculation as gameplay; loops where value transfer between players is the fantasy | Concepts where the fantasy is *not* commercial; players uncomfortable with money-shaped UX; jurisdictions hostile to crypto; players without wallets |
| **Web3 NFTs** | Items / characters / land as transferable tokens | Collector-as-fantasy; identity-through-items; persistent-world stakes; community-curated content | Concepts where item iteration / nerfs / rebalances are gameplay-critical; concepts with frequent character resets |
| **Hybrid** | Mix of the above (e.g. premium + cosmetic IAP, or web3 + traditional IAP) | Mature studios with capacity to manage two storefronts; bridging web2 audiences into web3 | Solo / small teams; concepts where the simplicity of "buy and play" is part of the appeal |

## Decision questions

When a rails decision is unclear, work the user through these:

1. **What is the player's relationship with money in the fantasy?** If money/trade is *part of the fantasy*, web3 tokens or IAP economy are natural. If money is *invisible to the fantasy*, premium or non-intrusive ads are natural.
2. **What's the session length and cadence?** 3-min sessions × 4× day → ad-friendly. 30-min sessions × 3× week → IAP / sub. One-and-done 20-hour story → premium.
3. **Where does the player live?** Mobile-only audience → IAP/ads dominant. PC/Steam → premium dominant. Web → ads or premium-via-Stripe. Console → premium + DLC.
4. **What's the platform's policy?** App Store and Google Play restrict crypto IAP heavily. Steam restricts NFT/crypto. Web is freer but loses storefront discovery.
5. **What's the team's capacity for live ops?** Live ops is a *team commitment*, not a feature. F2P, subscription, web3-with-secondary-market all imply ongoing operation. Premium does not.
6. **What's the regulatory floor in target jurisdictions?** Loot boxes are restricted/banned in some markets. Crypto IAP is restricted in others. Subscription auto-renew rules vary.
7. **What's the web2 fallback?** If the answer is "web3", how does the game work for a player without a wallet? If the answer is "they can't play", the concept's reachable market shrinks dramatically.

## Concept-vs-rails red flags

Surface these in the one-pager's `Risks` section if they apply.

- **"Cosmetic-only IAP" with single-player game**: cosmetics monetize because *other players see them*. Single-player cosmetic IAP rarely works.
- **"Free-to-play" with no daily-engagement loop**: F2P depends on retention compounding ARPDAU. Concepts without a daily reason to return cap out fast.
- **"Web3" with no buyer for the player's assets**: secondary markets require liquidity. A concept where 99% of players are net buyers and 1% sell will collapse.
- **"Premium" with planned live ops**: premium games can do DLC and seasons, but if the design *requires* ongoing content to retain, the model is service-shaped and pricing will fight against it.
- **"Subscription" with no recurring value**: subscriptions need ongoing reasons to stay. A subscription on a finite, completable experience will churn fast.

## Output

Capture the answer in the one-pager:
- The chosen rails (one or hybrid)
- One sentence on **why these rails fit this concept**
- One sentence on **where these rails fight this concept** — this is honesty, not pessimism

Hand the deeper trade-offs (LTV target, KPI floors, soft launch plan) to `game-monetization-strategist`.
