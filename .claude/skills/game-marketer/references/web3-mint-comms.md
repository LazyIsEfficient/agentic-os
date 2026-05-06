# Web3 mint comms

The marketing surface around token launches and NFT mints is regulator-sensitive, community-sensitive, and trust-sensitive. Web3 mint comms screw-ups have killed multiple games. Treat with care.

## Pre-mint phase

### Build allowlist (typically 4–12 weeks pre-mint)

- **Discord-gated** — earn allowlist by joining + activity
- **Quest-based** — complete a series of in-game / off-chain quests
- **Partnership-based** — grant allowlist to holders of partner NFT collections
- **Snapshot-based** — captured at random; minimizes gaming

Coordinate with `web3-smart-contract-engineering` for allowlist mechanism.

### Build narrative
- Why this NFT exists (utility, identity, narrative meaning)
- Total supply (hard cap, disclosed)
- Royalty rate (disclosed)
- Roadmap *post-mint* (what holders get over time)

## Pre-mint comms cadence

### T-30 days
- Reveal: "Mint coming"
- Allowlist signup live
- Initial trailer / art preview
- Discord activity push (gate behind allowlist)

### T-7 days
- Mint mechanics detail (date, time, price, gas estimates, chain)
- Allowlist final close
- Allowlist confirmation comms (so allowlisted users know)

### T-1 day
- Final reminder + step-by-step instructions
- Wallet preparation guide (have ETH ready, gas reserve, etc.)
- Discord countdown

## Mint day comms

### Hour 0
- Mint goes live at announced time
- Live updates on Discord, X
- Live troubleshooting in Discord (gas, transaction failures, network congestion)

### Hours 1–24
- Sell-through updates
- Reveal mechanics (if applicable)
- Secondary market activation comms
- Welcome holders to the game

## Post-mint comms

### T+1 to T+7
- Holders' channel activated in Discord
- Secondary market partnerships activated
- First post-mint update (commitment to roadmap)

### T+30
- Roadmap progress update
- First post-mint event for holders
- Floor price / volume monitored (with `iap-manager`)

### Ongoing
- Quarterly holder updates
- New utility / content for holders
- Annual holder anniversary comms

## Regulator-sensitive copy

### Avoid these framings
- "Investment" — implies security
- "Profit" / "ROI" / "earn" — implies financial return → security regulation risk
- "Guaranteed" anything — never; tokens / NFTs are volatile
- "Risk-free" — no
- "Get rich" — never

### Prefer these framings
- "Own a piece of the game"
- "Collect"
- "Trade"
- "Identity / status"
- "Community membership"
- "Utility in-game"

When in doubt, **get legal review** before publish. Securities regulators read marketing copy.

## Disclosure requirements

Per jurisdiction (and chains' policies):

- **Total supply** — clearly stated
- **Royalty rate** — clearly stated
- **Smart contract address** — published; immutable disclosed
- **Custody model** — custodial vs non-custodial
- **KYC / AML requirements** — if any
- **Risk disclosures** — required in some jurisdictions

## Common scams to warn community about

- **Fake mint links** — proliferate via Twitter / Discord DMs
- **Impersonation accounts** — fake support, fake giveaways
- **Wallet drainers** — disguised as "claim" links
- **Phishing in DMs** — Discord, X
- **Fake secondary market listings** — wash trading, fake floor prices

Train community managers to recognize and respond. Pin warnings in Discord. Coordinate with `security-engineering`.

## Coordinating with the rest of the pipeline

- **`web3-smart-contract-engineering`** — contract design and deployment timeline
- **`security-engineering`** — contract audit
- **`iap-manager`** — mint as part of catalog; secondary market integration
- **`game-monetization-strategist`** — mint event in the larger monetization model
- **`game-systems-designer`** — utility of NFTs in-game
- **Legal / compliance** — every piece of comms reviewed before publish

## Web3 mint anti-patterns

- **Mint and disappear** — primary mint sells out; team's energy drops; secondary collapses; trust gone
- **Manipulated rarity** — claiming "1 of 100" but minting more later
- **Hidden royalty changes** — moving royalty to zero post-mint without comms
- **Treasury sales without comms** — team selling its allocation in market without disclosure
- **Pump-and-dump positioning** — implying speculative gains
- **Allowlist favoritism** — perceived insider allowlist allocations damage community trust

## Output

For mint events:
- Mint event marketing brief (tied to launch-plan-template adapted for mint)
- Allowlist mechanism + comms
- Day-of-mint runbook
- Post-mint roadmap with concrete commitments
- Legal-reviewed copy across all surfaces
- Crisis-comms plan if mint fails (gas spike, contract bug, oversubscription)
