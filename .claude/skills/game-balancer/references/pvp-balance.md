# PvP balance

PvP balance is qualitatively different from PvE balance. The opponents are *adapting* to your tuning. The "right" balance is the one that produces a *healthy meta*, which is rarely the one where every option has a 50% win rate.

## Symmetric vs asymmetric

- **Symmetric** — both sides start with identical resources / abilities (StarCraft 1v1 mirror, fighting game mirror). Internal balance is "do the actions / units / characters all have equal viability?" Easier to reason about; usually less interesting at the top level.
- **Asymmetric** — sides differ (different races / characters / classes / starting hands). Balance is "do the *match-ups* across the roster produce a healthy meta?" Harder; usually more interesting; requires more telemetry.

The choice of symmetric vs asymmetric is a *design* call, not a balance one. Balance the game you have, not the one you'd rather balance.

## What "balanced" actually means

For PvP, the goals are usually:

1. **No dominant strategy.** No single approach wins regardless of what the opponent does.
2. **Multiple viable archetypes.** Several distinct ways to play that are competitive at the top level.
3. **Skill expression.** The better player wins more often, but not 100% of the time.
4. **Comeback potential.** Losing positions can recover (sometimes), but not arbitrarily.
5. **Meta health.** The set of *commonly chosen* options stays interesting — not stale, not chaotic.

A 50% win rate on every character does *not* mean balanced — it can mean "everyone is mediocre" or "everyone is interchangeable." A spread of 45–55% across the roster with distinct archetypes is usually healthier.

## Win rate, pick rate, and ban rate

Three metrics that interact:

- **Win rate** — % of matches won when this option is picked
- **Pick rate** — % of matches where this option is picked
- **Ban rate** — % of matches where this option is banned (if a ban system exists)

Useful patterns:
- **High WR + high PR** — overpowered; nerf candidate
- **High WR + low PR** — sleeper / niche; investigate why pick rate is low
- **Low WR + high PR** — popular but weak; players love this option even when it loses
- **Low WR + low PR** — dead; buff candidate or rework

Don't tune on win rate alone. A character with a 53% win rate but 5% pick rate is fine; a character with a 51% win rate and 40% pick rate is dominating the meta even though the win rate looks "balanced."

## Skill bracket disaggregation

Win rates and pick rates differ wildly by skill bracket:
- A character that's 45% at low skill and 60% at high skill is a *high-skill-ceiling* character. Buff at low skill, leave alone at high.
- A character that's 60% at low and 45% at high is *low-skill-floor*. Nerf at low (often by removing braindead options), leave alone at high.

A balance pass that uses *aggregate* numbers across all brackets will fix high-skill perceptions and break low-skill experience, or vice versa.

## Matchmaking interactions

PvP balance is entangled with matchmaking. Balance changes that look right in isolation can produce match-quality issues:

- **Skill-based matchmaking + DDA.** A balance change that makes one character easier nudges the matchmaker; players using that character get matched with weaker opponents; the win rate goes up; the change looks worse than it is.
- **New player onboarding.** New players don't know what's strong; a balance pass tuned for veterans can make new players bounce off characters the veterans understand are great.
- **Smurfs / bots.** Both inflate the apparent win rate of "new" accounts. A balance read on the lowest brackets is contaminated.

Coordinate with the matchmaking team (or the relevant code in `godot-engineer`'s domain) before drawing conclusions.

## Patch cadence

PvP balance is a *cadence* discipline:

- **Too rare** (yearly patches) — the meta calcifies, players burn out
- **Too frequent** (weekly nerfs) — players can't develop skill, top players never feel mastered
- **Just right** — usually a major patch every 4–8 weeks, with hotfixes for emergencies

Each patch should:
- Address the most distorted match-ups
- Avoid simultaneous large changes to multiple options (you can't tell which change caused the meta shift)
- Be communicated transparently — patch notes are part of the social contract

## Buff over nerf, when possible

When two options are out of balance, the choice is buff-the-weaker or nerf-the-stronger.

- **Buffing** is usually better received by players. Adds power; players feel rewarded.
- **Nerfing** is more reliable for meta health. The strongest option will always be the meta until it isn't strongest.

Use both, but lean toward buffs for first attempts and nerfs only when buffs would create power creep across the roster.

## Counter-pick design

Healthy asymmetric PvP includes intentional counter-picks: option A loses to option B, which loses to option C, which loses to A. Players learn the matchup chart and pick adaptively.

- **Hard counters** are interesting once or twice per roster. More than that, the game becomes "pick the counter and you win."
- **Soft counters** are how most matchups should work. A small advantage / disadvantage based on archetype, not an instant win.

If your matchup matrix has many 70-30 cells, the meta will degenerate to "pick the right counter." Aim for most cells in 45-55, with a few intentional 60-40s for archetypal flavor.

## Output

For PvP balance:
- **Matchup matrix** with target win rates per cell
- **Per-option WR / PR / BR table** with skill-bracket disaggregation
- **Patch plan** — which options to touch, by how much, with what predicted impact
- **Telemetry contract** — match outcomes, picks, bans, per-bracket
- **Comms plan** with `game-marketer` — patch notes are content
