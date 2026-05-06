# Segment economics

The classic spender pyramid: whales / dolphins / minnows / non-spenders. The model must work for *each tier* — not just the average — because the average hides the dynamics that drive revenue and churn.

## The pyramid (rough F2P benchmarks)

| Segment | % of installs | % of payers | % of revenue | ARPU/month | Notes |
|---|---|---|---|---|---|
| Whale | 0.5–1% | 8–15% | 30–50% | $200+ | Top concentration in mid-core RPG / strategy / gacha |
| Dolphin | 3–5% | 40–60% | 30–40% | $20–$200 | Most consistent payer base |
| Minnow | 10–20% | 30–50% | 10–20% | $1–$20 | Often single-purchase (starter pack, ad removal) |
| Free | 70–85% | 0% | 0% (or via ads) | $0 | Population that whales play with; ad inventory; virality |

**Casual / hyper-casual** has flatter distribution (less whale concentration). **Mid-core** and **gacha** have steeper concentration.

## Whales

**What they want:**
- **Speed** — accelerate progression past time gates
- **Status** — exclusive cosmetics, leaderboard placements, named ranks
- **Completion** — own everything, finish every collection
- **Power** (in pay-to-progression games)
- **VIP treatment** — better support, early access, recognition

**What they need to keep paying:**
- Ongoing content at their pace (whales burn through normal content fast)
- Status that's recognized (whales need other players to *see* their status)
- Aspirational targets (something to spend toward)
- Trust that paid items won't be silently nerfed

**Failure modes:**
- Run out of content; quit
- Status diluted by inflation; quit
- Paid item nerfed without compensation; quit and tell others
- Free players outpace whales' status (whale-perceived); quit

## Dolphins

**What they want:**
- Meaningful upgrades they can afford (battle pass, mid-tier bundles)
- Occasional luxury (the "I deserve this" purchase)
- Season completion
- Predictable spend pattern (not pressured into impulse)

**What they need to keep paying:**
- Clear value at the mid-tier (the $9.99 / $19.99 SKUs feel *worth it*)
- Battle pass content cadence
- Themed bundles around content drops

**Failure modes:**
- Perceives the high-tier as paywall; can't reach without converting to whale
- Battle pass burnout from too-frequent passes
- Content slowdown → drops to minnow

## Minnows

**What they want:**
- The "removed friction" purchase (ad removal, starter pack, season pass)
- A one-time validation that the game is worth supporting
- Often a single purchase the entire lifetime

**What they need to keep paying (or to repeat-purchase):**
- A clear next-step purchase (minnow → dolphin path)
- Time-bound offers that re-engage (returning-player bundle, anniversary pack)

**Failure modes:**
- Buys once, never again — many minnows are *one-purchase players*; that's fine, expected, and modeled
- Never converts up — usually because there's no clear upgrade path

## Free players

**Roles in the model:**
- **Population for whales' multiplayer** — whales need someone to play with
- **Ad inventory** — if rails include ads
- **Virality** — free players invite friends, post screenshots, generate social proof
- **Conversion pool** — small % become payers; the % matters at scale

**What they want:**
- A real game (not a paywall demo)
- Aspirational free goals (reach endgame eventually, even if slowly)
- Daily / weekly hooks that don't feel like paywalled jail

**Failure modes:**
- Frustrated by paywalls → uninstall and review-bomb
- Ad fatigue → uninstall
- No social loop to keep them engaged → uninstall

## Lapsed-then-return

A segment that overlaps with all the others — players who churned and came back. They behave differently:
- More likely to spend on a "welcome back" bundle than a fresh install
- Re-engagement event timing matters (within 30–90 days of lapse is the sweet spot)
- Seasonal narratives are strong re-engagement hooks

## Per-segment tactics

### For whales:
- Premium-tier battle pass (with whale-only content)
- Top-tier currency packs ($49.99 / $99.99)
- Exclusive cosmetics behind named-tier purchases
- VIP or "Founders" tiers
- Personal account managers (in mid-core, common over a certain spend threshold)

### For dolphins:
- Standard battle pass
- Mid-tier bundles ($4.99 / $9.99 / $19.99)
- Themed limited-time content
- Conversion paths from "complete the pass" to "buy the next pass" automatically

### For minnows:
- One-time starter pack (heavily over-valued; ~80% off equivalent value)
- Ad-removal SKU (if rails include ads)
- Season pass at low tier
- "Re-engagement bundle" after 14+ days of absence

### For free:
- Rewarded video ads
- Free track on the battle pass
- Daily login rewards
- Referral bonuses (friend invites)
- Generous F2P progression to endgame (slow but reachable)

## Whale-resilience check

If the top 1% of revenue evaporates (whale churn event, regulatory action, segment migration), does the game still ship a sustainable P&L?

- **Yes** — the model is healthy; whales are bonus, not life-support
- **No** — the model is whale-concentrated; one bad month at the top destroys the business

Most F2P games have some whale concentration. The risk threshold is: **when top 1% > 50% of revenue**, the game is a single-segment business, and that segment can move fast.

## Per-segment ROAS

Acquisition cost should be priced per segment, not blanket:
- Whale-shaped install (high IAP signal in the first 24h): can afford CPI of $50+
- Dolphin install: CPI of $5–$15
- Minnow install: CPI of $1–$5
- Free install: CPI ≤ $0.50

Most ad networks support optimized acquisition (UA optimized for purchase events, IAP value, ROAS). Coordinate with `game-marketer` on which signals to optimize.

## Output

In the strategy doc:
- Per-segment % of installs, payers, revenue
- Per-segment ARPU/month and retention assumption
- Per-segment primary tactics (which SKUs, which experiences)
- Conversion funnel between segments
- Whale-resilience check result
