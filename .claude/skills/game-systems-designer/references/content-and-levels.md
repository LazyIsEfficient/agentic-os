# Content and levels

Content is the recurring fuel the player consumes. Levels, encounters, cards, quests, characters, items, narrative beats — all of it. Content design fails in two predictable ways: **producing too little** (game runs out fast) and **producing too much sameness** (content is there, but it doesn't feel like content).

## What's the content unit?

Pick *the* unit the game's content production is measured in:

- **Levels** — handcrafted spaces (platformer, puzzle, narrative game)
- **Encounters** — combat or social setups (RPG, tactics, roguelike)
- **Cards** — reusable atoms combined by the player (deckbuilder, autobattler)
- **Quests / missions** — authored objectives (open world, MMO)
- **Characters** — playable or NPCs (gacha, fighting game, roster shooter)
- **Items / loot** — gear, cosmetics, consumables (ARPG, looter shooter)
- **Story beats** — narrative chunks (visual novel, adventure game)
- **Events** — live-ops time-boxed content (GaaS, F2P)

Most games have *one* primary content unit and 1–2 secondary ones. Identifying the primary unit tells you what production capacity is the bottleneck and what the content cadence pipeline must produce.

## Production model

Pick how the content is produced:

- **Handcrafted** — designers author each unit one by one. High craft, low quantity, expensive to produce. Good for: narrative games, premium indies, set-piece moments.
- **Procedural** — content generated from rules and parameters. Low craft per unit, high quantity, cheap to produce *but expensive to make feel good*. Good for: roguelikes, survival, replayable session games.
- **Hybrid** — handcrafted set pieces glued together with procedural connective tissue. Most successful long-form games use this. Examples: handcrafted dungeons + procedural between-dungeon space; handcrafted boss encounters + procedural waves.
- **UGC (user-generated)** — players make content; the team makes tools. Low marginal cost per unit, high marginal cost in tools and moderation. Good for: long-tail games, community-led titles.

The production model **must match team capacity**. A 2-person team that picks "handcrafted, 100 levels" will ship 12 levels and exhaustion. A 50-person team that picks "procedural, infinite" will ship a samey-feeling game.

## Variety drivers

Procedural and hybrid content needs explicit variety drivers, or it feels samey within hours. The drivers are:

- **Mechanical variety** — different enemy behaviors, different room rules, different deck archetypes
- **Combinatorial variety** — small atoms × many combinations (like *Slay the Spire*'s relics × cards)
- **Aesthetic variety** — visual / audio / tone shifts that *feel* different even when underlying mechanics repeat
- **Narrative variety** — a layer of authored context per content unit
- **Player-driven variety** — players make different choices that interact differently with the same content

The right driver depends on the aesthetic the game targets. Discovery-aesthetic games need more *novelty* per unit. Challenge-aesthetic games need more *combinatorial* depth. Fellowship-aesthetic games need more *player-driven* variety.

## Content cadence

For live-ops games, content is a *schedule*, not a quantity:

- **Daily** — login rewards, one-day events, daily quests
- **Weekly** — weekly events, weekly bosses, weekly leaderboards
- **Bi-weekly / monthly** — patch cadence, balance updates
- **Seasonal** — battle pass, season story, ladder reset (typically 4–12 weeks)
- **Annual** — major content drops, expansion-level changes

A live-ops game without a sustainable cadence will lose players within one season. Pick a cadence the team can hold *for a year*, not a sprint.

## Level / encounter design pillars

For handcrafted units:

1. **Beat structure** — every level has an open / build / twist / climax / resolve shape (see `level-spec-template.md`). Levels without a twist feel like the previous level.
2. **Verb practice** — each level exercises 1–2 verbs from the design. New verbs are introduced gradually; old verbs are *re-used differently* in new contexts.
3. **Pacing density** — events per minute. Too few = boring. Too many = exhausting. The right density is aesthetic-dependent (action high, exploration low, cozy lowest).
4. **Failure case** — every level can be lost; the loss is fair (player can attribute it); the player keeps something on retry.
5. **Replay incentive** — for replayable games, the level should be different on subsequent plays (different goal, different score, different route).

## Content density and the hour-to-content ratio

Rough sanity check on whether the content production matches the play target:

- **Premium narrative game** — ~1 hour of designer time per ~5 minutes of play (high craft)
- **Premium replayable game** — ~1 hour of designer time per ~30 minutes of play (replays + content)
- **F2P / live ops** — content per hour drops over time; the meta and social loops carry play hours
- **Roguelike / procedural** — content density is *lower per unit* but *higher per play hour* (variety drivers do the work)

If the design demands 100 hours of play and the team has capacity for 10 hours of handcrafted content, the math doesn't work. Either drop the play target, change the production model, or shrink the scope.

## Output for the design doc

In §8 of the design doc:

- **Content unit** (one primary)
- **Production model** (handcrafted / procedural / hybrid / UGC)
- **Content per arc** (e.g. "20 hand-built levels in chapter 1, +60 procedural in endless mode")
- **Variety drivers** (which kinds and which carry the most weight)
- **Content cadence** for live ops (or "no live ops" if not applicable)

For each handcrafted level / encounter, fill `assets/level-spec-template.md`.
