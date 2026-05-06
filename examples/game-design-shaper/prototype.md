# game-design-shaper — prototype

Example of `/game-shape` producing a `prototype-template.md` brief — vertical slice testing one hypothesis.

---

## User's initial request

> 4-week prototype to test if combining roguelike combat with a between-runs farming meta loop feels good. Solo, Godot, PC build for playtesters.

## Shaper's batched questions

Vertical slice, named timebox, single hypothesis under test — routes to `prototype-template.md`. Payment-rails question still applies even for a prototype (placeholder for the full game).

1. **Sharpen the hypothesis** — "feels good" isn't measurable. What specific behavior would prove it ("≥60% of testers play 3+ runs in a session", "≥half ask to play again")?
2. **Core fantasy in 30 seconds of play** — what's the player buying into in the *first* run?
3. **Top 2 verbs** — combat verb (dodge, block, parry, shoot, build) and farming verb (plant, harvest, decorate, craft)?
4. **Vertical slice scope** — how many enemy types, how many crops, how many run types? List what's stubbed (no story, no UI polish, no save).
5. **Payment-rails placeholder** — even though monetization is out of scope for the prototype, what's the assumed model for the full game (premium, F2P)? Affects what "feels good" needs to mean.
6. **Success bar — what proves continue, what proves kill?** Quantitative + qualitative + hard-kill.

## User's answers

1. Quantitative: ≥60% of testers complete 3+ runs in a 30-min session, AND ≥50% spend time in the farming meta between runs (not just skip back to combat). Qualitative: testers describe both loops in their own words.
2. Be a witch raising her garden between dangerous expeditions into the woods.
3. Combat verb: *dodge*. Farming verb: *plant-and-harvest*.
4. 1 biome, 3 enemy types, 6 crops, 1 boss. Stubbed: no narrative, placeholder art, no save (each session is a fresh start), no audio polish.
5. Likely premium ($15–20) on Steam. No F2P, no web3.
6. Continue: hits both quant criteria above. Kill: <40% finish 3 runs, OR farming time is <10% of session for the median tester (means the meta loop isn't pulling its weight).

## Output brief

```markdown
## Working title
Witch's Garden (placeholder)

## Hypothesis under test
Combining roguelike combat (dodge-based, short runs) with a between-runs farming meta loop (plant-and-harvest, decorate the garden) creates a session shape where players choose to spend meaningful time in *both* loops — not just skipping the meta to get back to combat.

Specifically:
- ≥60% of testers complete 3+ runs in a 30-minute session.
- ≥50% of testers spend ≥10% of session time in the farming meta between runs.
- Testers describe both loops in their own words and ask to play again.

## Core fantasy
Be a witch raising her garden between dangerous expeditions into the woods. Cozy at home, tense in the woods.

## Player verbs (top 2)
- Dodge — combat verb. Short, readable telegraphs; the moment-to-moment skill expression.
- Plant-and-harvest — farming verb. Slow, deliberate. Spend the rewards from runs to grow the garden.

## Vertical slice scope
- Levels / scenes: 1 biome (the woods) + 1 home garden scene.
- Enemy / content variety: 3 enemy types + 1 boss.
- Systems included: dodge-based combat, run rewards (seeds + scrap), planting/harvesting, plot expansion, run start/end.
- Systems explicitly stubbed: no narrative, no audio polish, no save (each session is fresh), no UI polish, placeholder art, no progression unlocks beyond the 6 crops, no second biome, no in-run shops.

## Platform target for the prototype
- Primary: PC build (Windows + macOS) distributed to ~15 playtesters via direct download.
- Build cadence: weekly to playtesters; daily internal builds.

## Business model assumption (placeholder for full game)
- Likely model: premium ($15–20 on Steam).
- Payment rails to validate (if any): none. Monetization is out of scope.
- Monetization is *out of scope* for prototype: yes.

## Success bar (kill-or-continue criteria)
- Quantitative:
  - ≥60% of testers complete 3+ runs in a 30-minute session.
  - ≥50% of testers spend ≥10% of session time in the farming meta.
- Qualitative:
  - Testers describe both loops in their own words.
  - Testers ask to play again or want to know when more is coming.
- Hard kill:
  - <40% of testers complete 3 runs in 30 minutes (combat too punishing or too thin), OR
  - Farming time is <10% of session for the median tester (meta loop isn't pulling its weight).

## Timebox
- Total: 4 weeks.
- Mid-checkpoint: end of week 2 — full combat loop playable end-to-end with placeholder art and stubbed farming UI.
- Demo-day: end of week 4 — playtest sessions with ~15 testers, telemetry pulled within 48 hours.

## Team
- Designer: solo (also doing the engineering).
- Engineer(s): same person.
- Art / audio: placeholder Kenney + free SFX. No final art in prototype.

## Tooling
- Engine: Godot 4 + C#.
- Existing tech to reuse: prior dodge-combat prototype from a game jam (~3 months ago) — pull the dodge controller and trim.
- Telemetry to instrument: 5 events — `run_start`, `run_end` (with cause: death/win/quit), `seed_planted`, `crop_harvested`, `plot_expanded`. Stamp session ID and elapsed time.

## Constraints
- Hard dates: demo-day 4 weeks from kickoff. Cannot slip — there's a publisher pitch on the calendar.
- Budget: $0 cash (solo, existing tools).
- Things this prototype must *not* do:
  - No second biome.
  - No meta-progression beyond plot-expansion.
  - No multiplayer.
  - No save system (each session fresh).
  - No story / dialogue / cutscenes.

## Open questions
- Run length — fixed 5 minutes, or "until the boss"? Affects whether 30-min sessions yield 3+ runs reliably.
- Crop set: 6 crops with varied grow times to give the meta loop texture, or 3 with depth? 6 chosen here on instinct — to validate.
- Playtester recruitment — friends-and-family, Discord community, or paid via UserInterviews? Composition affects how representative the data is.
```

---

**Next step:** paste this into a fresh session with `godot-engineer` available, or say `go` and the brief is handed to the engineer for the week-1 vertical slice. Concept is locked enough — straight to systems and build, not to game-concept-creator.
