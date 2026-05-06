# Comms cadence — <game title>

> The live-ops comms calendar. Updated monthly. The cadence is what makes a live game *feel alive*; gaps in comms read as "team is gone."

## Channels active

- [ ] Discord — primary community
- [ ] X / Twitter — broad reach, news
- [ ] Reddit — community discussion (subreddit if exists)
- [ ] TikTok / Shorts — viral / discovery
- [ ] YouTube — long-form (dev diaries, recap)
- [ ] Email — wishlist / lapsed / paying players
- [ ] In-game banner / popup — most direct
- [ ] Patch notes (in-game + web) — primary docs

## Weekly cadence

### Monday
- **In-game:** week-start banner (new event / pass tier / featured bundle)
- **Discord:** week ahead summary (events, drops, patches expected)
- **X / Twitter:** "this week in <game>" thread

### Tuesday-Thursday
- **TikTok / Shorts:** 1–2 short clips (player highlights, gameplay moments, dev quick-tips)
- **Discord:** dev-in-channel time (community Q&A, screenshot share)

### Friday
- **Discord:** weekend events kickoff
- **X:** highlight reel of community content
- **YouTube:** weekly dev diary (short — 3–5 min)

### Sunday
- **Discord:** weekly recap

## Monthly cadence

- **First week of month:** patch / content drop with full patch notes
- **Mid-month:** community spotlight (player-of-the-month, fan art highlight, community event)
- **Last week:** preview of next month's content

## Seasonal cadence (4–12 weeks)

### Pre-season (week before)
- Trailer for new season
- Battle pass preview
- Roadmap teaser (what comes during the season)
- Season-start countdown on social

### Season opening day
- In-game: full launch banner, login event, season-start cinematic if any
- Discord: launch celebration
- X / TikTok / YouTube: launch content blitz
- Email: paying-player launch email + free-player tease
- Press / influencer: previews lifted

### Mid-season (week 4–6 of an 8-week season)
- Mid-season event (mini story arc, limited-time content)
- "How are you doing?" community check-in
- First balance hotfix if needed (with `game-balancer`)

### Season end (week 7–8)
- Final-week countdown
- Last-call comms for pass completion
- Community celebration of top players (leaderboard winners, completionists)

### Inter-season (1–2 weeks)
- Roadmap update for next season
- Dev diary on next season's themes
- Refresh creative for ad networks

## Patch notes voice

- **Lead with the why** — "we're nerfing X because the meta has stagnated around it" beats "X: 15% damage reduction"
- **Acknowledge what you're breaking** — if nerfing a fan-favorite, say so
- **Plain language, not jargon** — players read; many don't speak the team's internal vocabulary
- **Commit to a tone** — formal vs casual vs witty; pick one and hold it
- **Don't dunk on players** — even when they're wrong about a bug, be respectful

## Balance change comms (per-change template)

```
**[CHANGE NAME]**

Why we're changing this:
[1–2 sentences explaining the design intent and what we observed]

What changed:
[Specific numbers and behaviors]

What this means for you:
[Practical implication for the player's experience]

What we're watching:
[KPIs / community signals we'll monitor; commitment to revisit if needed]
```

## Monetization change comms

When changing monetized content (rare; high-trust):

- **Announce in advance** (1–2+ weeks before change)
- **Compensate or grandfather** existing buyers
- **Be transparent about the why**
- **Coordinate with `iap-manager`** for catalog timing
- **Coordinate with `game-monetization-strategist`** for impact framing

## Re-engagement comms

For lapsed players (D14+):

- **Email:** "we miss you" + content tease + welcome-back bundle (with `iap-manager`)
- **Push notification (app-installed-but-inactive):** event-specific, not generic
- **Paid retargeting:** Meta / Google with custom audience of lapsed user IDs

## Web3-specific comms (if applicable)

- **Token launch announcements** — regulator-sensitive; legal review before publish
- **NFT mint event comms** — allowlist details, mint time, gas expectations, post-mint roadmap
- **Secondary market kickoff** — direct players to marketplaces with verified listings
- **Disclosure** — risk warnings where required by jurisdiction

## Anti-patterns to avoid in comms

- **Going silent during a controversy** — read as "team doesn't care"
- **Defensive responses to community critique** — escalates, doesn't deescalate
- **Inconsistent voice** across channels (formal on web, casual on Discord, sarcastic on X) — confuses identity
- **Auto-generated patch notes** — players want context, not a changelog
- **Ignoring small issues until they become big ones** — small acknowledgments prevent escalation

## Hand-off
- **`iap-manager`:** any catalog announcement timing
- **`game-balancer`:** balance change comms, updated patch notes
- **`game-monetization-strategist`:** monetization change comms (rare; coordinate)
- **`godot-engineer`:** hotfix availability, in-game banner / popup wiring
- **External:** community managers, social team, PR / press contacts
