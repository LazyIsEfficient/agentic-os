# Live-ops comms

The cadence that makes a live game *feel alive*. Gaps in comms read as "team is gone." Patch notes are content. Events are stories. Balance changes need explanation.

## Patch notes voice

The single most-read marketing surface for a live game. Players read patch notes more carefully than the team's design docs. Voice rules:

- **Lead with the why.** "We're nerfing X because the meta has stagnated around it" beats "X: 15% damage reduction." Players forgive nerfs they understand; they resent nerfs they don't.
- **Acknowledge what you're breaking.** If nerfing a fan-favorite, say so explicitly.
- **Plain language, not jargon.** Players don't speak the team's internal vocabulary.
- **Commit to a tone.** Formal vs casual vs witty; pick one and hold across the patch-notes lifespan.
- **Don't dunk on players.** Even when the player misunderstands, be respectful in print.
- **Don't oversell.** Patch notes that breathlessly hype small changes train the audience to discount the team's communication.

## Per-change template

```
**[CHANGE NAME]**

Why we're changing this:
[1–2 sentences explaining design intent and what we observed]

What changed:
[Specific numbers / behaviors]

What this means for you:
[Practical implication for the player's experience]

What we're watching:
[KPIs / community signals; commitment to revisit if needed]
```

## Patch frequency

- **Hotfixes** — within hours / days of launch issues; scope: bug fixes, server stability, no balance changes
- **Bi-weekly patches** — small balance changes, content drips, QoL improvements
- **Monthly patches** — larger content, balance passes, feature additions
- **Seasonal patches** — major content drops, season transitions, ladder resets

Match the cadence to the team's capacity. A weekly patch cadence the team can't sustain produces droughts that hurt more than slower-but-steady would have.

## Event comms

Events are *stories*, not just bonuses. A weekend "double XP event" with no theme converts worse than a "Lunar New Year Festival" with the same in-game effect.

### Event story structure
- **Theme** — connects to the game world or seasonal context
- **Stakes** — what's at risk; what's gained
- **Limited time** — real time-bound, not fake
- **Reward identity** — themed cosmetics that *only* exist for this event
- **Recap** — post-event content celebrating community participation

### Event cadence
- **Weekly** — small theme bundles, weekend events
- **Monthly** — major events tied to content drops
- **Seasonal** — biggest events, season-defining narrative beats
- **Annual** — anniversaries, world events that define the game's calendar (Halloween, Lunar New Year, anniversaries)

## Balance change comms

Higher stakes than other comms. Players form lasting opinions from how nerfs / buffs are delivered.

### Rules
- **Bundle with explanation.** Never ship a balance change with only the numbers.
- **Acknowledge the meta context.** "X has dominated the meta for 3 weeks; here's why we're acting."
- **Predicted impact.** "We expect this to bring X back to viability without making it dominant."
- **Commitment to revisit.** "We'll watch X for 2 weeks and re-tune if needed."

Coordinate with `game-balancer` for the actual changes; this skill writes the comms.

## Monetization change comms

Highest stakes. Coordinate with `iap-manager` and `game-monetization-strategist`.

### Rules
- **Announce in advance.** 1–2+ weeks before change.
- **Compensate or grandfather** existing buyers where possible.
- **Be transparent about the why.** Players forgive necessary changes they understand.
- **Don't bury the lede.** The change goes in the headline, not paragraph 4.

A monetization change without comms is a trust break. Treat with care.

## Roadmap comms

Players want to know what's coming. Roadmaps build anticipation but also create commitments the team must meet.

### Best practices
- **Quarterly roadmap** — high-level "what we're working on"
- **Pre-season roadmap** — specifics for the next season
- **Don't over-promise.** Be conservative about what makes the public roadmap.
- **Announce delays clearly.** "X is moving from Q2 to Q3 because Y" — players appreciate honesty far more than missed dates.
- **Roadmap reveals are content.** Trailer + dev diary + Discord event around the reveal.

## Live-ops content calendar

Map the full year ahead:

- **Annual:** anniversary, year-in-review, biggest content drops
- **Quarterly:** seasonal content + roadmap updates
- **Monthly:** event + patch + community spotlight
- **Weekly:** in-game banner + Discord event + patch notes (if any)
- **Daily:** social posts, community management

See `assets/comms-cadence-template.md` for the structure.

## Voice across channels

The voice should be *consistent* across channels but *adapted* to the platform:

- **Discord:** community-y, casual, devs answering directly
- **X:** punchier, in-the-news, can engage with memes
- **YouTube:** longer-form, dev diary feel
- **Reddit:** longer text, community-discussion style, devs respond to top concerns
- **In-game:** terse, contextual, action-oriented
- **Patch notes:** structured, transparent, why-led

The studio's *identity* should be recognizable across all of them. A Soulslike game's voice is different from a cozy farming sim's voice — and that should hold across every channel.

## Anti-patterns

- **Auto-generated patch notes** — players want context, not a changelog dump
- **Inconsistent voice** — formal on web, sarcastic on Discord, defensive on Reddit; reads as institutional
- **Going silent** during a controversy or content drought
- **Over-promising on roadmap** — slipped dates erode trust faster than slow-but-steady delivery
- **Forgetting localized markets** — JP / KR / BR / TR community managers need their own voice + content cadence
- **Treating comms as marketing leftover** — comms is half the live-ops job; staff accordingly
