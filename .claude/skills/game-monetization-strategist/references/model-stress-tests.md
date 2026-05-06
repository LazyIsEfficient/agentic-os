# Model stress tests

Run the strategy through these scenarios. Each tests whether the model survives an adverse condition. A model that breaks on any of them is a model that will break in live ops.

## 1. Retention shortfall (-30%)

D7 retention comes in 30% below target.

**Predicted impact:**
- DAU 30% smaller
- LTV scales linearly with retention → 30% lower
- ROAS payback extends ~40% (math compounds)
- Whale concentration may rise (whales retain better than dolphins/minnows)

**Action:**
- Re-tune onboarding (route to `game-systems-designer` for first-hour design)
- Re-tune early-game economy (route to `game-balancer` for source/sink rates)
- Reduce CPI (raise UA quality bar; route to `game-marketer`)
- If retention floor is breached → re-tune or kill

## 2. IAP conversion shortfall (-50%)

Conversion to first IAP comes in 50% below target.

**Predicted impact:**
- ARPDAU drops ~50% (assuming repeat-purchase rate holds)
- LTV drops 50%
- ROAS payback may extend 2× — ad spend becomes unprofitable

**Action:**
- Re-price entry tier (route to `iap-manager` — usually drop the entry tier price)
- Improve store-page conversion (route to `iap-manager` and `ux-design`)
- Strengthen the "first wow" reward (route to `game-systems-designer` and `game-balancer`)
- Add starter-pack offer at first paywall touch
- Re-evaluate target audience (UA may be acquiring the wrong segment)

## 3. Whale concentration shock

Top 1% of revenue drops from 40% to 25% (whales churn or migrate).

**Predicted impact:**
- 15pp of revenue evaporated
- Single-segment business model is now vulnerable
- May indicate end-game content drought, status-perception loss, or competitor migration

**Action:**
- Diagnose whale churn (exit interviews, telemetry analysis)
- Add aspirational endgame content (route to `game-systems-designer`)
- Add status SKUs (route to `iap-manager` — VIP tier, founders pack)
- Diversify the model (lean harder on dolphins / minnows / ads if applicable)

## 4. Platform fee change (+10%)

Apple / Google / Steam raises platform fee from 30% to 40%, or removes a previous discount tier.

**Predicted impact:**
- Effective revenue per IAP drops ~14% (10pp on net)
- ROAS payback extends ~16%
- Margin compression flows directly to studio P&L

**Action:**
- Raise prices (carefully — may reduce conversion)
- Push more revenue through subscription / web routes (where permitted)
- Re-evaluate platform mix (if iOS becomes much less profitable, can mobile UA shift to Android?)
- For web3 hybrid games: re-evaluate the web3 storefront economics

## 5. Regulatory change

Loot boxes get banned in target market. Crypto IAP gets restricted further. Age rating tightens (e.g. 18+ ratings on monetization-heavy content).

**Predicted impact:**
- Specific SKUs become unsellable in regulated markets
- Reachable market shrinks
- Compliance work / re-architecture required

**Action:**
- Assess affected catalog with `iap-manager`
- Adjust catalog by region (gacha → guarantee-based; loot box → odds-disclosed; etc.)
- For web3: check if rails are still permitted; have web2 fallback path ready
- Communicate transparently with affected players (route to `game-marketer`)

## 6. Adblock / ad-revenue drop

Ad revenue drops 40% (post-IDFA-style change, network policy shift, or adblocker uptake).

**Predicted impact:**
- For ad-supported model: ARPDAU drops 40%, ROAS collapses
- For hybrid: free segment becomes less valuable; whale dependency rises
- For pure premium: no impact

**Action:**
- For ad-supported: shift more aggressively into IAP, sub, or premium model
- Re-tune ad placement (more rewarded video, fewer interstitials)
- Re-evaluate non-ad acquisition channels
- For hybrid: probably acceptable; lean harder into IAP segments

## 7. Token velocity collapse (web3)

Token sources outpaced sinks; price collapses; players' earnings devalue; new players' ROI is poor.

**Predicted impact:**
- Player retention drops sharply (the implicit "play to earn" contract broke)
- New player acquisition fails (no compelling earn ROI)
- Treasury / team holdings devalue

**Action:**
- Emergency sink injection (high-utility content priced in token)
- Source rate reduction (carefully — players hate this; coordinate comms)
- Protocol-level changes (token burn, buyback, staking incentives)
- Honest communication: "we underestimated supply; here's the plan"
- Long-term: rebuild the model with the actual demand curve, not the speculative one

## 8. NFT secondary market dry-up

The secondary market goes from active to inactive. NFTs feel illiquid and unsellable.

**Predicted impact:**
- Royalty revenue drops to near-zero
- Players who own NFTs feel locked in or stranded
- Primary mint demand likely also drops (no liquidity to exit)

**Action:**
- Add utility to NFTs that doesn't depend on secondary market (in-game effects, social status)
- Consider buyback programs (if treasury can support)
- Re-evaluate: is the model NFT-dependent, or is the NFT a feature on top of a working web2 model?

## 9. Seasonal / content drought

Content cadence slips. Battle pass weak. New content delayed.

**Predicted impact:**
- Retention drops (no reason to return)
- Pass conversion drops (pass perceived as weak)
- ARPDAU drops 20–40% during the drought

**Action:**
- Soft launch a temporary event or limited-time content
- Acknowledge with comms ("content delayed because X; here's the plan")
- For live ops teams: rebuild content pipeline capacity (route to studio leadership / `team-lead`)

## 10. Whale revolt (silent nerf / NFT nerf / store change)

A monetized item is changed in a way whales perceive as a bait-and-switch.

**Predicted impact:**
- Whale churn spike (immediate)
- Refund storm
- Community trust drop; review-bombing
- Long-term: future paid items face skepticism

**Action:**
- Restore the original behavior or compensate concretely
- Public apology with specifics (route to `game-marketer`)
- Document the failure for next time
- For studios: invest in the trust contract (transparency, advance notice, compensation policies)

## 11. Acquisition channel collapse

The dominant UA channel (Meta, Google Ads, TikTok, etc.) becomes dramatically less effective.

**Predicted impact:**
- CPI rises 50%+; ROAS drops below profitable
- DAU growth stalls
- Long-term: the game shrinks

**Action:**
- Diversify acquisition (route to `game-marketer`)
- Shift creative concepts; old creative decays
- Lean on organic / community / influencer (slower but more durable)
- Re-evaluate the model — if UA economics permanently degrade, the model may need to shift toward longer LTV (subscription, premium)

## 12. Competitive launch

A direct competitor launches with similar concept, similar audience.

**Predicted impact:**
- UA costs rise (auction competition)
- Retention may drop (audience attention split)
- Press / influencer coverage harder to land

**Action:**
- Lean into differentiation (route to `game-marketer` for positioning refresh)
- Don't chase the competitor's monetization tactics — defend yours
- Consider a content drop / event that recaptures attention
- Long-term: the audience may settle into 1–2 winners; play for that position

## Output

For each scenario the strategy shows resilience:
- Predicted impact magnitude
- Action plan with the responsible skill / team
- Whether the floor is breached (if yes, this is a failure-mode the strategy must avoid)

The point of stress-testing isn't to predict the future; it's to identify *which scenarios kill the model* and surface them as risks before they happen.
