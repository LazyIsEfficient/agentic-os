# game-design-shaper — full game

Example of `/game-shape` producing a `full-game-template.md` brief — multi-month commercial project.

---

## User's initial request

> I want to make a mobile city-builder where you're settling a colony on a hostile alien moon. Free-to-play, mobile-first, probably 8–12 month build. Want to validate the loop with a soft launch.

## Shaper's batched questions

Multi-month, commercial, F2P named — routes to `full-game-template.md`. Game-design-shaper *always* asks the payment-rails question.

1. **Core fantasy in one line** — "settle a colony on a hostile alien moon" is the setting; what's the *fantasy* (be a survival commander, be a city planner, be an underdog leader of a desperate colony)?
2. **Player verbs — top 3** — what does the player *do* every minute? Build, dig, defend, scavenge, command, negotiate?
3. **Comp titles** — 2–4 games this draws from or competes with on the App Store / Play Store?
4. **Payment rails — explicit decision needed.** F2P named — IAP only, IAP + ads (rewarded? interstitial?), subscription, hybrid? Any web3 element on the table?
5. **Success bar — pre-launch, launch, long-term** — soft-launch CPI floor and D7 retention floor for go/no-go? Long-term LTV and ROAS targets?
6. **Engine and team** — Unity, Godot, custom? Solo, small team, contractors?

## User's answers

1. Be the underdog leader of a desperate colony — every shift is "we *almost* didn't make it through the night, here's what we'll do tomorrow".
2. Build (place structures), Allocate (assign colonists to jobs), Defend (survive the night cycles).
3. Frostpunk (mood, stakes), Fallout Shelter (mobile cadence, cute-but-grim tone), They Are Billions (night-cycle tension).
4. F2P, IAP-led with rewarded ads as a secondary lever. Battle pass per season. No interstitials. No web3.
5. Soft-launch floors: D1 ≥ 35%, D7 ≥ 12%, CPI ≤ $3 in tier-1. Long-term LTV target $4+, ROAS D90 ≥ 100%.
6. Unity, team of 5 (1 designer, 2 engineers, 1 artist, 1 producer-and-marketing). Contractors for music and additional art.

## Output brief

```markdown
## Working title
Hostile Moon (placeholder)

## One-line pitch
A mobile city-builder where you lead the underdog colony on a hostile alien moon, scraping through each night to plan a slightly-better tomorrow.

## Core fantasy
Be the underdog leader of a desperate colony. Every shift ends with "we *almost* didn't make it; here's what we'll do tomorrow."

## Target player
- Primary: 25–45, mobile-first players who already play city-builder / management games on phone (Fallout Shelter, Township, Clash of Clans descendants), drawn to grim/tense tone over cozy tone.
- Secondary: PC city-builder fans (Frostpunk, They Are Billions) willing to play on phone for a smaller, snackable version of that fantasy.
- Not for: cozy-cottage builder audience, twitch / action-game audience, hardcore 4X strategy audience.

## Player verbs (top 3)
- Build — place structures and infrastructure on the colony grid.
- Allocate — assign colonists to jobs and shifts.
- Defend — survive recurring night cycles (hostile environment events).

## Genre and references
- Primary genre: mobile management / city-builder with survival pressure.
- Closest comp titles: Frostpunk (mood, stakes), Fallout Shelter (mobile cadence, tone), They Are Billions (night-cycle tension).
- One thing different from comps: the *desperation* fantasy on mobile — most mobile city-builders are cozy or aspirational; this one is "just barely making it", and that's the emotional hook.

## Platforms
- Primary: iOS, Android.
- Secondary: none planned at launch.
- Cross-play / cross-save: cross-save (cloud) yes; no cross-play (single-player game).

## Business model
- Model: F2P, IAP-led, rewarded-ads as a secondary lever, seasonal battle pass.
- Price (if premium): N/A.
- Soft currency: yes (likely "scrap" — earned in-game, used for routine costs).
- Hard currency: yes (likely "supplies" — purchased, used for skips and key unlocks).
- Battle pass / season pass: yes — seasonal.
- Ads: rewarded only. No interstitial, no banner.

## Payment rails
- Web2 IAP: yes — App Store, Google Play.
- Web2 subscription: not at launch (potentially via battle pass auto-renew later).
- Web2 ads: yes — rewarded only, network TBD (likely AdMob + ironSource as mediation).
- Web3 tokens: no.
- Web3 NFTs: no.
- Hybrid notes: N/A.
- Constraint: must comply with App Store and Google Play policies on real-money mechanics, loot-box disclosure, and child-safety (rated 12+).

## Scope
- Total dev time: 8–12 months.
- Team size: 5 (1 designer, 2 engineers, 1 artist, 1 producer-and-marketing) + contractors for music and additional art.
- Content target: launch with 30+ structures, 8 night-event types, 3 seasons of battle-pass content prepared.
- What's deliberately out of scope: PvP, multiplayer co-op, alliance/social features, base-raiding, real-time competitive elements.

## Success bar
- Pre-launch: soft-launch in tier-2 markets with floors D1 ≥ 35%, D7 ≥ 12%, CPI ≤ $3 in tier-1 paid tests, ARPDAU ≥ $0.10 in soft-launch geos.
- Launch: hold soft-launch retention floors at scale; review score ≥ 4.3 on both stores in first 30 days.
- Long-term: LTV target $4+, ROAS D90 ≥ 100%, payback within 6 months on tier-1 spend.

## Constraints
- Engine: Unity (team's existing stack).
- Art style: stylized 3D with limited palette — grim, readable on small screens, expressive characters; not realistic.
- Deadline / hard dates: soft launch by month 6, full launch by month 10–12.
- Platform-imposed: App Store / Google Play guidelines on monetization (loot boxes, IAP disclosure, age rating), country-by-country gambling rules for any randomized purchases.
- IP / brand constraints: original IP, no licensed property.

## Source material available
- One internal prototype Unity project with a placeholder grid-build loop.
- Mood board (Frostpunk + Fallout Shelter visual reference).
- No prior live game from this team to leverage.

## Open questions
- Single-resource or multi-resource economy? Frostpunk runs multi (food, fuel, wood, steel); Fallout Shelter runs multi but lighter. Affects systems-design and balance work directly.
- Battle pass: tied to night-cycle progression, seasonal narrative, or both?
- Soft-launch geo set: Philippines + Canada + Norway (common picks), or replace one for closer English-tier-2 fit?
- Live-ops cadence at launch — weekly events, biweekly, monthly only? Affects team load post-launch.
```

---

**Next step:** paste this into a fresh session with `game-concept-creator` available (concept is open — fantasy and verbs named, but the loop tightness is still up for design). Say `go` and the brief is handed to game-concept-creator for one-pager iteration before systems work begins.
