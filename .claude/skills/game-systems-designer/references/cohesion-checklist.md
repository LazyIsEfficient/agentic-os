# Cohesion checklist

Run every system in the design doc through these tests. A system that fails is either *cut* or *reworked* — silently keeping a failing system is how feature soup ships.

## The compounding test

For each system, name:

- **What other systems is this system *better* because of?** (which systems amplify it)
- **What other systems does this system make *better*?** (which systems it amplifies)

If the answer to *both* is "none," the system is isolated — cut it or merge it into a related system.

If the answer to one is "many" and the other is "none," the system is parasitic (it consumes other systems' value without giving back) or feeder (it produces value nothing consumes). Both need rework.

The healthiest systems are *both consumers and producers* of value from at least 2–3 other systems.

## The fantasy test

For each system:
- **Which aesthetic from the design doc does this system serve?**
- **Which player verb does this system support?**

If a system serves no aesthetic and supports no verb, it's a feature without a fantasy. Cut.

## The cut test

For each system, ask the team: *if we cut this system, what does the game lose?*

- "Nothing important" → cut it.
- "A whole pillar of the experience" → keep it; it's load-bearing.
- "The game would feel less rich" → suspicious; "richness" is often a euphemism for clutter. Probe further.

## The seam test

For each interaction between two systems, ask:
- **Is the seam visible to the player?** (Do they understand that A and B are connected?)
- **Is the seam *enjoyable*?** (Does the player like that A and B interact, or do they find it confusing/unfair?)

Hidden, unenjoyable seams are where players say "the game is buggy" when really the systems are fighting each other.

## The currency test

Count the currencies in the game (any tracked resource that gates content):

- **1–2 currencies** — usually right
- **3 currencies** — workable if each has a *clearly different role* (e.g. soft / hard / time)
- **4+ currencies** — almost always broken; consolidate

Each currency should have:
- A **source** (how the player earns it) that connects to a verb
- A **sink** (what the player spends it on) that produces meaningful choice
- A **velocity** (how fast it accumulates and depletes) tuned to a session cadence

Currencies with no source / no sink / no velocity discipline are spreadsheet rows, not systems.

## The new-player test

Walk a hypothetical new player through the first hour. For each system:

- **Has the player seen this system yet?**
- **Is it relevant to what they're doing right now?**
- **If the system is gated until later, what's the unlock pacing?**

A design with 12 systems all visible from minute one is overwhelming. A design with 12 systems gated behind 30 hours of play is content-starved early. Most healthy designs reveal 2–4 systems in the first hour and the rest over the next 5–10 hours.

## The team-capacity test

For each system:
- **How much engineering work is this?** (Rough order of magnitude — days, weeks, months)
- **How much content does this system need to feel rich?** (Number of items / levels / variations)
- **Who maintains it after launch?** (Live-ops cadence, balance updates, bug fixes)

A design with 8 systems where each needs months of engineering and ongoing maintenance is a 50-person studio's project. A 3-person team with the same design will ship 2 of the 8 systems, broken.

## The rails-fit test

For each system, check against the chosen payment rails (from `game-concept-creator`):

- **F2P / IAP-heavy:** does this system create a *fair, optional* spending opportunity, or does it create paywalls?
- **Premium:** does this system require live-ops to feel complete? If yes, the model is wrong, not the system.
- **Web3 tokens:** does this system create token sinks or only token sources? (Token-source-only systems collapse the economy.)
- **Web3 NFTs:** does this system require *rebalancing* characters/items? (NFT'd content is hard to nerf.)
- **Subscription:** does this system give subscribers *ongoing reasons* to stay subscribed?

Systems that fight the rails are landmines for `game-monetization-strategist` and `iap-manager` later. Surface the conflict in the design doc, don't bury it.

## The five-system limit (heuristic)

For most teams and most games, the design should ship with **3–5 major systems** in the launch version. New systems can be added in updates.

If the design has 8+ major systems, two things are likely true:
- The team will ship a quarter of them well and the rest poorly.
- The player will never internalize all of them.

The fix is *not* to add a tutorial for the extra systems. The fix is to cut them or convert them to *expansions / live-ops content* that ships after launch.

## What to do with a failing system

When a system fails the checklist:

1. **Cut it.** Default. Most "interesting ideas" should die at the design stage.
2. **Merge it.** Combine with a related system that's load-bearing.
3. **Defer it.** Move to a planned post-launch update.
4. **Rework it.** Only if the system is load-bearing and the failure is fixable.

"Keep it as is, we'll figure it out later" is the path that produces feature soup. Don't take it.

## Output

After running the checklist, the design doc's systems list should be:

- 3–5 systems that all pass the compounding test
- Each labeled with the aesthetic and verb it serves
- Each with a clear connection to at least 2 other systems
- Each with a defensible team-capacity story

If the list still has 8 systems and you can't cut, route back to `game-design-shaper` for scope clarification.
