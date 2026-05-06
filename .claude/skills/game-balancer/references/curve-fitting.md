# Curve fitting

How to solve for the constants once the curve shape is chosen.

## The core problem

You have:
- A chosen shape (linear / exponential / polynomial / log / stepped / capped / resetting)
- A design intent ("median player reaches L60 in 50 days")
- Player profile data (sessions/day, plays/session, earn rate per play)

You need:
- Concrete constants (e.g. `a = 100, r = 1.18` for `cost = a * r^(L-1)`)
- Validation that the constants produce the intent across multiple profiles

## Step-by-step

1. **Convert the intent into a quantity.** "L60 in 50 days" → "total_xp(L60) divided by xp_per_day = 50."
2. **Compute earn-per-day for each profile.** Median: 3 sessions × 1000 XP/session = 3000 XP/day.
3. **Pick a starting growth rate.** For exponential XP, start at `r = 1.18`.
4. **Solve for `a`** (the L1 → L2 cost) such that `cumulative(60) / earn_per_day = 50`.
5. **Validate against other profiles.** Hardcore (6 × 1500 = 9000 XP/day) should reach L60 in ~17 days. Casual (1.5 × 800 = 1200 XP/day) should reach in ~125 days. If those numbers don't match the intent for those profiles, *the curve shape is wrong* — don't keep tuning constants.
6. **Plot it.** Visual sanity check that the curve looks like the chosen shape.
7. **Document the math.** Future re-tunes need to know what was solved for.

## Common parameterizations

### Exponential

`cost(L) = a * r^(L-1)`

`cumulative(L) = a * (r^L - 1) / (r - 1)`

Picking `r`:
- Gentle growth: 1.10–1.15 (RPG XP, social games)
- Standard growth: 1.15–1.20 (most action games)
- Steep growth: 1.20–1.30 (challenge-aesthetic; players opt in)
- Avoid `r > 1.30` unless the design *intentionally* wants late-game grind

### Polynomial

`cost(L) = a * L^k`

`cumulative(L) ≈ (a / (k+1)) * L^(k+1)` (for `L` large)

Picking `k`:
- `k = 1.5`: gentle
- `k = 2`: quadratic — late game ~4× a level halfway through
- `k = 2.5–3`: cubic — much steeper

Polynomial is often a good "between linear and exponential" choice when exponential overshoots.

### Logarithmic (mastery / diminishing returns)

`progress(t) = a * log(b * t + 1)` or `mastery(plays) = a * sqrt(plays)` (a similar shape with simpler math)

Picking `a` and `b`:
- `a` controls the *ceiling* (asymptotic max)
- `b` controls the *steepness* (how quickly the player approaches the ceiling)

Logarithmic is for *skill or mastery*, where each additional play teaches less than the last. Bad for content unlocks.

### Stepped

Piecewise. Pick:
- **Tier intervals** (every 5 levels, every 10 levels, every quarter of the curve)
- **Tier costs** (often exponential between tiers, with a sudden jump at the boundary)
- **Tier rewards** (named, distinct, narratively meaningful)

Keep the tier count low — 5–10 tiers is typical. 20+ tiers feels arbitrary.

## When the constants don't fit

If you can't find constants that produce the intent across all profiles, the constraints conflict:

1. **The shape is wrong.** Try a different shape.
2. **The intent is unrealistic.** A 50-day median arc with a 17-day hardcore arc is a 3× spread. If the design wants a 2× spread, you need a less-steep curve. If the design wants a 5× spread, you need a steeper curve.
3. **The earn rates are wrong.** Recheck `xp_per_play` — it might need a different value.
4. **The design intent has hidden assumptions.** "Median reaches endgame in 50 days" might assume the player plays every day. A weekend player will take much longer.

When stuck, push back to `game-systems-designer` with the conflict surfaced explicitly.

## Solver tools

- **Spreadsheet goal-seek / solver** — fine for single-variable problems
- **Python `scipy.optimize`** — for multi-variable, multi-constraint
- **Custom one-off scripts** — often the fastest path; don't over-engineer
- **By inspection** — for simple problems with 1–2 levers, just iterate manually

The tool doesn't matter; the *math* matters. A well-modeled spreadsheet beats a poorly-modeled solver every time.

## Cross-validation

After fitting:

- **Plot** the curve and check it visually matches the intended shape
- **Run through the profiles table** — every profile should hit the design's intent for that profile
- **Check sensitivity** — ±20% on the key constants; how badly does the model break?
- **Compare to comp titles** — if the curve is 3× steeper than every comp title, either the design intent is unusual or the curve is wrong

## Output

For each fitted curve, capture:
- **Final constants** with units
- **Source equation** (so it can be re-derived)
- **Earn-rate assumption** per profile (so re-tune knows what to revisit)
- **Days-to-cap prediction** per profile (so live data has a target)
- **Sensitivity** on the top 2 constants
