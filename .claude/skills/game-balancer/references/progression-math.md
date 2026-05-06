# Progression math

Choose the **shape** of the curve before you solve for the **constants**. The shape decision says what the player journey *feels* like; the constants set how long it takes.

## Common curve shapes

### Linear

`cost(level) = a + b*(level)`

- **Player feel:** every level costs the same. Predictable. No acceleration.
- **Use for:** short games (≤10 levels), narrative-led games, tutorials.
- **Avoid for:** long games — the late game has no weight.

### Exponential

`cost(level) = a * r^(level-1)` where `r > 1` (commonly 1.10–1.25)

- **Player feel:** late levels take meaningfully longer than early ones. Powerful sense of progression in early game, sense of mountain to climb late.
- **Use for:** RPGs, MMOs, GaaS leveling.
- **Avoid for:** competitive PvP where late-level players have permanent stat advantage and early/late can't match-make.
- **Common `r` values:** 1.10 (gentle), 1.18 (standard), 1.25 (steep). >1.30 starts to feel grindy.

### Polynomial / power

`cost(level) = a * level^k` where `k > 1` (commonly 1.5–2.5)

- **Player feel:** grows faster than linear, slower than exponential. Mid-late game stretches without becoming punishing.
- **Use for:** XP curves where exponential feels too steep but linear feels too flat.

### Logarithmic

`progress(time) = a * log(b * time + 1)`

- **Player feel:** lots of progress early, slowing down. The honeymoon shape.
- **Use for:** mastery curves, skill ratings, idle-game prestige.
- **Avoid for:** content unlocks (player feels stuck mid-game).

### Stepped

`cost(level) = piecewise(level)` — long flats interrupted by sudden jumps

- **Player feel:** "tier-ups" — most of the time the player progresses smoothly, but periodically they hit a wall, work to break through, and feel a big jump.
- **Use for:** gear tiers, prestige systems, ranked ladders, season tiers (battle pass).
- **Avoid for:** core XP that drives moment-to-moment play (the wall feels arbitrary).

### Capped

`cost(level) = formula until level <= cap; afterwards = ∞ (or alt path)`

- **Player feel:** "I finished the season." Closure. Then the next season opens.
- **Use for:** seasonal content, time-bound progression, anti-burnout in PvP.
- **Always pair with** an alternative aspirational goal at the cap (mastery, prestige, cosmetic, status badge).

### Resetting

Cap with periodic reset to baseline.

- **Player feel:** "fresh start." Re-engagement opportunity.
- **Use for:** roguelike runs, ladder seasons, prestige loops, battle pass cycles.
- **Risk:** if reset costs too much (e.g. all gear lost), players feel cheated. If reset costs too little (no real loss), the reset has no narrative weight.

## Picking the shape

| If the design wants ... | Pick |
|---|---|
| Simple, short-arc progression | Linear |
| RPG-style "the climb gets steeper" | Exponential |
| Mid-game stretching without grind | Polynomial |
| Mastery / diminishing returns | Logarithmic |
| Tier-ups with breakthroughs | Stepped |
| Bounded seasonal content | Capped |
| Repeatable fresh starts | Resetting |

Combine shapes: e.g. exponential XP curve up to L60, then capped + alt-mastery curve afterwards. Most live games are *layers* of curves, not a single curve.

## Solving for constants

Given a chosen shape and a design intent ("median player reaches L60 in 50 days at 3 sessions/day, 1000 XP/session"):

1. Compute total XP needed: `cumulative_xp(60)` for chosen shape and growth rate
2. Compute XP earned per day for median profile: `sessions/day × XP/session = 3000 XP/day`
3. Compute days to L60: `total_xp / 3000 = days`
4. Adjust growth rate or starting cost until days matches intent (here, 50)

For exponential `r`:

- `r = 1.10` produces a gentle late-game; total XP for 60 levels at `a = 100` is ~30,400 → ~10 days at 3000 XP/day. Too fast.
- `r = 1.18` produces a moderate climb; total XP ~187,000 → ~62 days. About right.
- `r = 1.22` produces a steep climb; total XP ~530,000 → ~177 days. Too slow.

This is solving by inspection. For complex multi-curve systems, use a spreadsheet solver or write a 10-line script.

## Reward map placement

Rewards must land at *significant* tiers, not arbitrary ones:

- **First reward** — within the first 10–20 minutes of play (onboarding completion)
- **First "wow" reward** — within the first 2–3 sessions (validates the meta loop)
- **Mid-arc unlock** — at the midpoint of the curve (rotates the play experience)
- **Capstone reward** — at the cap (the "I made it" moment)

A reward at every tier dilutes their meaning. A reward at no tier feels grindy. Place rewards where *the curve naturally creates emotion* (after a steep climb, at a tier-up, on the first day of a season).

## Pity systems and pseudo-random distribution

For random-drop progression (loot, gacha, gambling-adjacent):

- **True random** — each attempt is independent. Players hate true random for rare items because variance is large.
- **PRD (pseudo-random distribution)** — the probability of a hit increases with each miss; on a hit, the counter resets. Used in *Dota 2*, etc.
- **Hard pity** — guaranteed drop after N consecutive misses. Caps frustration.
- **Soft pity** — drop rate ramps up starting at N misses, before the hard pity at M.
- **Cross-pull pity** — pity counter persists across sessions / banners. Players treat this as ownership of their progress.

Document the algorithm. Disclose drop rates if your jurisdiction requires it. *Don't* hide the algorithm and then rely on player ignorance — it leaks, and trust is harder to recover than to build.

## Power creep

Each new content drop is at least as strong as the last. Over many drops:
- Old content feels useless
- Players who took breaks fall behind
- The skill ceiling becomes a power-floor

Defenses:
- **Sideways content** — new drops add *options*, not raw power
- **Rotating buffs / nerfs** — meta cycles keep older content viable
- **Power resets** — seasonal resets, prestige systems
- **Gating new content behind older content** — old gear has long-tail purpose

## Output

For each curve in the design:
- Filled `progression-curve-skeleton.md`
- The chosen shape and the intent it serves
- The constants and the math that produced them
- Plot of the curve (visual sanity check)
- Reward map per tier
- Sensitivity to growth-rate and earn-rate variation
