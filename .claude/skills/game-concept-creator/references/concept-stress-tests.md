# Concept stress tests

Run every one-pager through these tests before handing it off to `game-systems-designer`. Each failed test goes in the one-pager's `Risks` section — do not silently fix.

## 1. The elevator test

A stranger reads the one-pager in 60 seconds and can describe the game back to you in their own words.

**Failure mode:** the logline is too abstract ("an experience about loss"), too generic ("an action game with progression"), or too dense (six concepts smuggled into one paragraph).

**Fix direction:** rewrite the logline using the `[Genre] where you [verb] to [goal] in [setting] with [twist]` template. Cut anything that doesn't survive.

## 2. The hook test

The one-pager describes a specific moment in the first 30 seconds of play that makes the player text a friend.

**Failure mode:** "the hook is gradually unlocking new mechanics" — that's not a hook, that's a curve. Hooks are *moments*, not *eventual properties*.

**Fix direction:** name the moment. *Vampire Survivors* hook = "the screen is suddenly full of enemies and you survive anyway." *Among Us* hook = "you watched the body get reported and you have no idea who did it." If you can't name the moment, the concept needs more shaping.

## 3. The comp-differentiation test

The one-pager lists 2–3 comp titles and one specific thing this game does *differently*.

**Failure mode:** "It's like X but better." Better-but-same loses to X every time, because X is already shipped, polished, and known.

**Fix direction:** name the wedge. The wedge can be a mechanic ("but with deck-building"), a setting ("but in feudal Japan"), an audience ("but for cozy players"), a session length ("but as a 5-minute commute game"), or a constraint ("but on a single screen"). Without a wedge, the concept is a clone.

## 4. The rails-fit test

The chosen payment rails do not fight the concept. See `payment-rails-decision.md`.

**Failure modes:**
- F2P with no daily-engagement loop
- Premium with mandatory live ops
- Subscription on a finite experience
- Web3 with no liquidity story
- Cosmetic IAP in a single-player game
- IAP-heavy in a category that's culturally premium (e.g. story-driven indie)

**Fix direction:** either change the rails, change the concept, or surface the conflict in `Risks` and let the team decide.

## 5. The scope-realism test

The scope estimate matches the concept's content needs.

**Failure modes:**
- "Two-person team, six months" attached to an open-world RPG
- "Solo developer" attached to a 32-player PvP shooter
- "Four-week prototype" attached to a 100-character roster
- "Live game" with no plan for ongoing content cadence

**Fix direction:** either cut scope (smaller world, fewer characters, fewer modes) or raise team/timeline. If neither, surface in `Risks`.

## 6. The risk inventory

The one-pager lists the **top 3 risks**, ranked.

Risk types to consider:

- **Mechanical risk** — "the core loop might not be fun" (almost always true for novel ideas; the prototype exists to disprove it)
- **Market risk** — "this audience may not exist at this price point"
- **Platform risk** — "App Store / Google Play / Steam may reject this category" (loot boxes, crypto, gambling-adjacent)
- **Technical risk** — "this needs custom netcode / server cost / engine work we don't have"
- **Regulatory risk** — "loot box rules / crypto rules / age rating in target markets"
- **Team risk** — "we don't have the discipline / craft / experience for this genre"
- **Content risk** — "this is a content-hungry genre and we can't produce content fast enough"
- **Monetization risk** — "the economy could be broken by whales, bots, or RMT"

A concept with no risks listed has not been thought through. A concept with all-mechanical risks has under-considered the commercial side. Push for breadth.

## 7. The "what would kill it" test

In one sentence: what specific event (signal, KPI, market change, platform action) would convince the team to **stop development** of this concept?

**Failure mode:** the team has no kill criterion, which usually means they have no success criterion either.

**Fix direction:** force the team to write the kill criterion. Without it, the concept will be defended past the point of evidence.

## What "passing" looks like

- All seven tests have an explicit answer or are flagged as a risk.
- The one-pager would be useful to a designer who has never spoken to the user.
- A skeptical reader can identify both the upside and the downside in under two minutes.

If the one-pager passes all tests, hand off to `game-systems-designer`. If it fails the elevator or hook test, do not hand off — the concept is not ready.
