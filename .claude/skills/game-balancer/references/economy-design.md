# Economy design

A game economy is **sources, sinks, and the flows between them**. If sources outpace sinks over the player's lifetime, the world inflates. If sinks outpace sources, the player feels gated and quits. Both fail.

## Vocabulary

- **Source / faucet** — anywhere a currency or resource enters the player's possession
- **Sink / drain** — anywhere a currency or resource leaves the player's possession
- **Velocity** — rate of accumulation or depletion per unit time, per player profile
- **Stock** — current balance held by the player
- **Flow** — net change in stock per unit time
- **Conversion** — exchange between currencies / resources
- **Pity** — guarantees that mitigate variance in random outcomes

## Faucet design

Sources should:
- **Connect to a verb.** Earning gold by killing a monster connects to combat. Earning gold by clicking a button connects to nothing.
- **Vary by activity.** A single source dominates the economy and creates a grind. Multiple sources feed into multiple verbs and produce variety.
- **Have caps for live ops.** Daily / weekly caps prevent botting and rate-limit abusive playstyles.
- **Differ across player profiles.** Whales should not earn 10× soft currency from playing 10× as much — the *paid* faucet is what scales for whales, not the playtime faucet.

## Drain design

Sinks should:
- **Produce meaningful choice.** "Buy item X or Y" is a sink. "Pay this fee to continue" is a tax — it removes currency without giving the player a decision.
- **Vary in size.** Mix of small frequent sinks (repair, snacks) and large rare sinks (tier-up, prestige) keeps the economy active.
- **Match the design's aesthetic.** Cozy games rarely have repair sinks (frustrating). Survival games depend on them (consequential).
- **Include luxury sinks for whales.** A whale with no place to spend their excess currency leaves the game. Cosmetics, status items, named rewards.

## Stock-vs-flow

Players think in *stocks* ("I have 5,000 gold") but the economy lives in *flows* ("I net +700 gold per day"). Both matter:

- **Stock matters for friction.** A player who can never afford the next tier feels gated. A player who saves up for a goal and reaches it feels rewarded.
- **Flow matters for sustainability.** A flow that's positive for everyone forever produces inflation; a flow that's negative produces churn.

Healthy designs target *small positive flow* for most profiles, with periodic large sinks (tier-ups, prestige resets) that bring stock down without bringing flow negative.

## Multi-currency hygiene

When the design has more than one currency:

- **Each currency must have a clear role.** Soft (earnable) for routine purchases, hard (paid or rare) for premium goods, time-gated for engagement loops.
- **No cross-conversion in the wrong direction.** Soft → hard is a paywall avoidance and breaks the model. Hard → soft is fine (whales accelerating).
- **Currency count discipline.** 1–2 is normal; 3 is workable; 4+ is almost always broken. Each additional currency multiplies the cognitive load and the spreadsheet rows.

## Soft / hard / time-gated

| Currency type | Source | Sink | Role |
|---|---|---|---|
| Soft | Earned through play | Routine purchases (consumables, repairs, common items) | Constant low-stakes engagement |
| Hard | Paid (IAP) or rare reward | Premium / status purchases (cosmetics, skips) | Whale lever; aspirational free-player goal |
| Time-gated (energy / stamina) | Regenerates on a clock; refillable with hard currency | Each play session costs N | Limits per-day engagement; produces buy-out points |

A game with all three needs to specify the *role of each*. A game with two of three is more common and easier to balance.

## Inflation and deflation

**Inflation** — sources > sinks over time. Symptoms: prices stay the same but earnings grow, so things feel free; whales hoard; world content devalues; new content feels weak relative to accumulated stock.

**Deflation** — sinks > sources over time. Symptoms: players run out of currency between activities; new content gets ignored because it's unaffordable; player choice contracts.

Both are usually fixable by adjusting *flow*, not *stock*:
- Inflation → add a luxury sink, raise prices on expansion content, or introduce a sink event
- Deflation → reduce sink rates, increase source rates, or introduce a source event

## Sink events vs source events

Live ops uses these as economy levers:

- **Sink events** — limited-time goods that absorb excess stock (limited cosmetics, special tier-ups). Used when the economy is inflating.
- **Source events** — bonus weekend, double XP, free pack. Used when retention is dropping or to re-engage lapsed players.

These are intentional levers; they should be planned with `game-monetization-strategist` (commercial impact) and `iap-manager` (catalog impact).

## Web3 economy notes

If the rails include web3 tokens or NFTs, additional concerns:

- **Token sources without sinks collapse the economy.** "Play to earn" without sinks → token price collapses → players leave.
- **NFT'd content is hard to nerf.** If the legendary sword is an NFT and you nerf it, owners revolt. Plan for *content addition* over *content rebalance*.
- **Secondary markets are a liquidity lever.** Active markets keep the economy interesting; dead markets make assets feel worthless.
- **On-chain transactions have cost.** Gas, latency, and finality concerns affect what economy operations are even feasible at runtime.
- **Speculation as gameplay.** Some players' primary verb is *trading*, not *playing*. Either embrace this in the design or design against it; ignoring it doesn't make it go away.

## Anti-patterns

- **The pure-grind economy** — only one source (kill enemies); only one sink (buy upgrades). Players feel like wage-slaves.
- **The whale-gated economy** — whale-tier content is locked behind hard paywalls with no aspirational free path. Free players quit; whales cap; population collapses.
- **The phantom currency** — a currency exists but the player has nothing to do with it. Cut it.
- **The double-spend** — a sink lets the player buy what they could earn by playing. Choice removed.
- **The token economy with no sinks** — see above. The single most common web3 economy failure.

## Output

Capture in the spreadsheet model:
- Currency table (one row per currency, with role)
- Sources sheet (per-currency, per-source)
- Sinks sheet (per-currency, per-sink)
- Velocities sheet (computed flows per profile)
- KPI rollup (predicted ARPDAU, retention shape, time-to-content)
- Sensitivity sheet (top 3–5 levers ±20%)
- Telemetry contract (what to instrument live to validate)
