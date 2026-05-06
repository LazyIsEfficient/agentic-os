# Core loops and progression

A game is a stack of loops. The shortest loop runs in seconds; the longest can run across months of live ops. Designing a game is mostly **picking the right loops at the right tempos and making sure they connect**.

## Anatomy of a loop

Every loop has the same five parts:

1. **Decision** — the player makes a choice (with meaningful trade-offs).
2. **Action** — the player executes the choice.
3. **Feedback** — the system responds (visual, audio, state change).
4. **Reward / consequence** — the loop produces something the player keeps.
5. **Context for the next decision** — the world is now slightly different; the next decision is informed by the last one.

If any of the five is missing, the loop is broken:
- No real decision → it's a chore, not a game.
- No clear feedback → the player feels disconnected.
- No reward → no reason to repeat.
- No new context → the next decision is identical to the last; the game is repetitive in the bad way.

## The core loop

The **core loop** is the activity the player does *most often* and that the rest of the game is wrapped around. In a roguelike: kill enemies → pick power → enter next room. In a card game: play turn → draw → respond. In a city builder: place buildings → wait for ticks → upgrade.

Rules for the core loop:

- **One core loop, not two.** If you have two "core" loops, one is meta (longer cadence) or you're looking at two minigames glued together.
- **Loop length: seconds to a few minutes.** Anything longer is a meta loop.
- **The player should run this loop hundreds of times per session.** If they don't, it's not core.
- **It should be fun on its own**, with no progression. Power, narrative, and progression all amplify a fun loop. They cannot make a boring loop fun.

## Meta loops

Meta loops carry between sessions. They're the *reason to come back*. Common kinds:

- **Vertical progression** — the player gets stronger (XP, levels, gear, mastery)
- **Horizontal progression** — the player gets more options (unlocks, characters, builds)
- **Collection** — the player completes a set (cards, achievements, NPCs befriended)
- **Narrative** — story beats unlock as the player proceeds
- **Social** — clans, leaderboards, friend lists, shared seasons
- **Seasonal / live ops** — limited-time content drops on a schedule

Rules for meta loops:

- **Each meta loop must connect back to the core loop.** Progression should change *how the player runs the core loop*, not just *that they run it more*.
- **One to three meta loops, not five.** Too many meta loops fragments the player's attention; they progress in nothing.
- **Cadence matters.** Vertical progression every few minutes (early), then every few hours (mid), then every few sessions (late). Live-ops on a fixed weekly/seasonal beat. The cadence is what schedules the player's life around the game.

## The loop-of-loops

For long-life games (live ops, MMOs, GaaS), there's a **loop-of-loops** layer above the meta:

- **Daily** — log in, claim, run a few core loops, hit a daily target
- **Weekly** — finish a weekly quest, climb a tier, raid night
- **Seasonal** — battle pass, season story, ladder reset
- **Annual / arc** — major content drops, expansion-level changes

Each layer needs to *reward returning at that cadence*. A game with no weekly hook will lose the player by week three.

## When to add a third loop

Most concepts need exactly two loops: core + one meta. Adding a third (often a collection or social loop) is appropriate when:

- The dominant aesthetic is **Fellowship** or **Expression** (third loop carries social/identity weight).
- The game is **service-shaped** and needs daily/weekly/seasonal cadences.
- The team has the **content production capacity** to feed the third loop.

Adding a third loop is *not* a fix for a weak core loop. If players bounce off the core, more meta makes it worse, not better.

## Progression curves (design intent only — numbers from `game-balancer`)

Capture the *shape* of the curve in the design, not the values:

- **Linear** — each level / tier costs the same (rare; usually only for short games)
- **Exponential** — each level costs N× the last (XP grinds, RPG levels)
- **Stepped** — long flats interrupted by sudden spikes (gear tiers, prestige systems)
- **Capped** — progression has a hard ceiling (skill mastery, season-long ladders)
- **Resetting** — progression resets each run / season (roguelikes, ladder seasons)

The shape choice constrains what kind of player journey is possible. Match the curve to the aesthetics you want.

## Anti-patterns

- **The progression treadmill** — players grind for upgrades that only let them grind faster for the next upgrade. The dynamic is *Submission*, not *Challenge* or *Discovery*. Fine for cozy games; lethal for action games pitched as challenge.
- **The choice that isn't** — the "decision" in the loop has one obviously correct answer. Cut the alternative and shorten the loop.
- **The loop without a hook back** — the meta loop unlocks something, but the unlock doesn't change *how* the player runs the core loop. Player progresses; play stays the same; player leaves.
- **Two cores in a trench coat** — the game has two loops at the same cadence (e.g. combat + base-building both at session-length). Players can't context-switch fast enough; one of the loops withers.

## Output for the design doc

For every loop the game has:

- **Name** and **layer** (core / meta / loop-of-loops daily / weekly / seasonal)
- **Length** (seconds / minutes / hours / days)
- **The five parts** (decision / action / feedback / reward / context for next)
- **Connection** — how this loop changes the player's behavior in *other* loops
- **Curve shape** (if it carries progression) — without numbers
