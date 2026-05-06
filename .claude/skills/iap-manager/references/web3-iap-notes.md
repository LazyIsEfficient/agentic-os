# Web3 IAP notes

When the rails include web3, the catalog has additional complexity. This is an *operational* layer on top of the strategy decisions made by `game-monetization-strategist`.

## Token IAP

Players buy tokens with fiat (typically via on-ramps).

**Catalog patterns:**
- **Token packs** — fixed-amount fiat → token bundles ($4.99 → 500 GAME tokens)
- **Token + bonus** — promotional packs ($9.99 → 1,200 GAME + 100 bonus)
- **Subscription with token grant** — sub tier that grants daily tokens

**Operational concerns:**
- **Volatility** — token's USD value floats; if you peg to USD, the on-chain token amount varies; if you peg to token, the USD amount varies
- **On-ramp fees** — fiat → token typically costs 2–5%; either absorb (margin compression) or pass through (player friction)
- **KYC** — required by jurisdiction and on-ramp; flag in jurisdiction matrix
- **Custodial vs non-custodial** — affects flow (custodial = sign-up creates wallet for player; non-custodial = player connects own)

**Platform restrictions:**
- App Store: strongly restricted; explicit crypto IAP usually not allowed
- Google Play: similar restrictions
- Steam: banned
- Web: typically permitted (route web3 monetization through web)

## NFT mints

Players mint NFT items at primary issuance.

**Catalog patterns:**
- **Single mint** — one item per mint transaction; clear price + chain gas
- **Pack mint** — multiple items per mint (akin to gacha pack)
- **Tiered allowlist** — earlier tiers (with discount) for early supporters
- **Public mint** — open to all after allowlist

**Operational concerns:**
- **Total supply** — declared upfront; do not change after launch (massive trust break)
- **Reveal timing** — reveal at mint vs reveal later (reveal-later is common; reveal mechanism must be unmanipulable)
- **Royalty enforcement** — declining on EVM marketplaces; don't rely on royalty as load-bearing revenue
- **Gas spikes** — mint events congest networks; either schedule for off-peak or use L2

**Coordinate with:**
- `web3-smart-contract-engineering` — contract design and deployment
- `security-engineering` — contract audit
- `game-marketer` — mint event marketing, allowlist comms

## Token-required content

Content gated behind token holdings (staking, holding-required, "must own X tokens").

**Catalog patterns:**
- **Staking unlock** — stake N tokens to access feature; tokens returnable after unstake period
- **Hold-required** — must hold N tokens at snapshot time
- **Spend-to-access** — burn tokens for permanent access

**Operational concerns:**
- **Snapshot mechanics** — when is the holding measured; how is it verified
- **Sybil resistance** — preventing one whale from creating many wallets to qualify
- **Web2 fallback** — what non-wallet players can access

## Secondary market integration

Players trade NFTs / tokens between each other on external marketplaces.

**Catalog patterns:**
- **Display floor price** — show current floor price for an NFT type in-game
- **Marketplace deep-link** — "Buy on OpenSea / Magic Eden / Blur"
- **In-game peer-to-peer market** — own marketplace (operational complexity high)

**Operational concerns:**
- **Royalty rate** — declared up-front; respected by some marketplaces, ignored by others
- **Liquidity monitoring** — if floor price collapses, trust does too
- **Anti-fraud** — wash trading, sybil bidding, scam listings (with `security-engineering`)

## Custodial wallet for IAP

A common pattern for mass-market web3: the game creates a wallet for every player on sign-up; players spend without learning crypto.

**Catalog implications:**
- IAP with fiat (Apple / Google / Stripe) → tokens land in custodial wallet
- Player can claim to a non-custodial wallet later (claim flow has its own UX)
- Custody is the studio's responsibility — security and regulatory burden

**Operational concerns:**
- **Compliance** — custody may classify as money transmission in some jurisdictions
- **Insurance** — custodial assets may need insurance
- **Recovery** — player recovery flow when they forget password / lose access

Coordinate heavily with `security-engineering` and legal.

## Cross-chain considerations

If the game spans multiple chains:

- **Wrapped tokens** — token on chain A bridged to chain B; bridge has security implications
- **Per-chain catalog** — different SKUs per chain
- **Bridge fees** — pass through to player or absorb

Most games stick to a single chain to avoid this complexity. Multi-chain is for scale.

## Reporting

Web3 IAP needs different reporting than web2:

- **On-chain volume** — primary mints, secondary market activity
- **Token velocity** — circulation rate, sink saturation
- **Wallet metrics** — connected wallets, active wallets, wallet age distribution
- **Per-region wallet penetration** — which markets connect wallets vs use web2 fallback

Hand to `revenue-intelligence` for cohort revenue analysis combining web2 + web3 data.

## Anti-patterns

- **Web3-as-decoration** — adding NFTs / tokens because "everyone is doing it" without a design reason. Alienates both web3 and web2 audiences.
- **Hidden custody** — players don't realize the studio holds the wallet; if studio fails, players lose assets
- **Manipulated rarity** — claiming "1 of 100" but minting more later
- **Royalty evasion** — selling NFTs in ways that bypass on-chain royalties
- **Mint-and-abandon** — primary mint sells out; team disappears; secondary collapses
- **Pump-and-dump** — token launched with team allocation; team sells; token collapses; players left holding bag

These are existential trust breaks for web3 games. Avoid them; even the appearance of them damages the studio long-term.
