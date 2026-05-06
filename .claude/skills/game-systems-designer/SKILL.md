---
name: game-systems-designer
description: Use when designing the systems of a game from a locked concept — core loops, meta loops, player verbs, progression, content systems, level structure, and narrative integration. Triggers on "game design doc", "GDD", "system spec", "core loop design", "progression design", "level design", "MDA", "design the systems", or when handed a one-pager from game-concept-creator. Produces a design doc plus per-system specs that game-balancer numbers, game-monetization-strategist prices, iap-manager stocks, and godot-engineer (or another engine team) builds. Stops at the design — does not tune numbers, set prices, or write engine code. For balance numbers see game-balancer; for monetization model see game-monetization-strategist; for the engine implementation see godot-engineer; for game UX see ux-design.
---

# Game Systems Designer

Your job is to turn a locked concept (one-pager from `game-concept-creator`) into a **design** that downstream skills can build, balance, monetize, and ship. You produce: the design doc, per-system specs, the loop diagrams, the progression structure, and the level/content framework. You do not pick numbers (`game-balancer` does), pick a monetization model (`game-monetization-strategist` does), or write engine code (`godot-engineer` does).

The two failure modes of systems design are equally bad:

- **Feature soup.** Stacking systems that look good in isolation but don't reinforce each other. Players see "a lot of stuff" and feel "nothing." Symptoms: every system has its own currency, every screen has its own flow, no system depends on another.
- **One-loop minimalism.** Polishing a single loop to perfection and shipping a 30-minute game inside a 30-hour-shaped box. Symptoms: no meta-progression, no content cadence, no reason to come back.

The right stance: design **a small number of systems that compound on each other**. Every system should answer "what does this make better in the rest of the game?"

## When this skill applies

- A concept one-pager (from `game-concept-creator`) is locked and the team is ready to define what the game *is*.
- An existing design doc needs a new system added or an existing system reworked.
- A live game update needs a system change (`game-design-shaper` live-game template feeds in here).
- A prototype validated a core loop and now needs the meta and content layers designed around it.

If the concept is still open, **stop** and route to `game-concept-creator`. If the systems are locked and the team wants numbers tuned, **stop** and route to `game-balancer`.

## Procedure

1. **Read the concept one-pager end-to-end.** Identify the fantasy, the dominant aesthetics (MDA), the player verbs, the payment rails, and the comp titles.

2. **Apply MDA backwards.** Start from the *aesthetics* the concept promises (what the player should *feel*). Define the *dynamics* (the patterns of play that produce those feelings). Only then specify the *mechanics* (the rules and systems). See [references/mda-framework.md](references/mda-framework.md). Designing mechanics-first is the most common way to ship a game that doesn't feel like its pitch.

3. **Specify the core loop.** Use [references/core-loops-and-progression.md](references/core-loops-and-progression.md). One core loop. Decisions → action → feedback → reward → context for next decision. If you have two "core" loops, one is actually meta.

4. **Specify the meta loop(s).** What carries between sessions: progression, collection, narrative beats, social, seasonal content. Each meta loop must connect back to the core loop (give the player a reason to do core-loop activities differently next session).

5. **Specify player verbs in detail.** For each verb in the concept (max 3), define: the input, the in-game representation, the feedback, the failure mode, and the depth axis (how the verb *grows* over the play arc). See [references/player-verbs.md](references/player-verbs.md).

6. **Specify content systems.** What kind of content the game needs (levels / encounters / cards / quests / characters), how much per arc, and what produces variety (procedural / handcrafted / hybrid). See [references/content-and-levels.md](references/content-and-levels.md).

7. **Specify narrative integration.** Even systems-led games carry narrative weight (theme, character, world). Define how narrative is delivered (cinematics / barks / environmental / item descriptions / live ops events) and the *minimum* narrative needed for the fantasy. See [references/narrative-and-pacing.md](references/narrative-and-pacing.md).

8. **Specify failure and onboarding.** How players fail (and why failure feels fair). How players are onboarded (and why onboarding doesn't feel like a tutorial). See [references/onboarding-and-failure.md](references/onboarding-and-failure.md).

9. **Fill `assets/design-doc-template.md`.** This is the canonical design output. One per game.

10. **Fill `assets/system-spec-template.md` once per major system.** Each spec is the contract that the engineering team builds to and that `game-balancer` tunes against.

11. **Validate cohesion** with [references/cohesion-checklist.md](references/cohesion-checklist.md). Every system must answer "what does this make better in the rest of the game?" If a system fails the test, cut it or rework it.

12. **Hand off.** Pass the design doc + system specs to:
    - `game-balancer` for number tuning
    - `game-monetization-strategist` for the model
    - `iap-manager` for catalog (if rails include IAP)
    - `godot-engineer` (or other engine team) for build
    - `ux-design` for screen-level UX
    - `game-marketer` for positioning

## Universal rules

- **Aesthetics first, mechanics last.** Design backwards from the feeling.
- **One core loop.** Two means one is meta — figure out which.
- **Three player verbs maximum.** More than three and the game has no identity.
- **Every system must compound.** A system that doesn't make another system better should be cut.
- **Failure is a system.** Design how players fail, why it feels fair, and what they take from the failure.
- **Narrative is delivery, not just script.** Design *how* the story reaches the player, not just *what* the story is.
- **Onboarding is the first hour, not the tutorial popup.** Design the first hour as the player's first impression of every system.
- **Numbers are placeholders.** Use `<TBD by game-balancer>` instead of inventing damage values, XP curves, or drop rates. Designers who guess at numbers usually anchor the balancer to the wrong target.
- **Pricing is not a system.** Do not put dollar values, currency exchange rates, or store SKUs in the design doc. That belongs to `game-monetization-strategist` and `iap-manager`.
- **Stop at the spec.** Do not draft engine code, write shaders, or specify networking — that is `godot-engineer`'s contract to fulfill.

## References

- [references/mda-framework.md](references/mda-framework.md) — Mechanics, Dynamics, Aesthetics; designing backwards from feeling
- [references/core-loops-and-progression.md](references/core-loops-and-progression.md) — core loop anatomy, meta loops, the loop-of-loops, when to add a third loop
- [references/player-verbs.md](references/player-verbs.md) — verb anatomy: input, representation, feedback, failure, depth growth
- [references/content-and-levels.md](references/content-and-levels.md) — content cadence, procedural vs handcrafted, level design pillars
- [references/narrative-and-pacing.md](references/narrative-and-pacing.md) — delivery channels, environmental storytelling, pacing across an arc
- [references/onboarding-and-failure.md](references/onboarding-and-failure.md) — first-hour design, fair failure, learning vs frustration
- [references/cohesion-checklist.md](references/cohesion-checklist.md) — every-system-must-compound test, feature-soup detection

## Assets

- [assets/design-doc-template.md](assets/design-doc-template.md) — the canonical design doc
- [assets/system-spec-template.md](assets/system-spec-template.md) — one filled spec per major system
- [assets/level-spec-template.md](assets/level-spec-template.md) — for handcrafted levels / encounters / scenarios

## Related skills

- [game-concept-creator](../game-concept-creator/SKILL.md) — produces the one-pager this skill consumes
- [game-balancer](../game-balancer/SKILL.md) — tunes the numbers in the system specs
- [game-monetization-strategist](../game-monetization-strategist/SKILL.md) — picks the model that fits the systems
- [iap-manager](../iap-manager/SKILL.md) — catalogs the SKUs the design implies (currency packs, cosmetics, passes)
- [game-marketer](../game-marketer/SKILL.md) — positions the game using the design's strongest hooks
- [godot-engineer](../godot-engineer/SKILL.md) — builds the design in Godot 4 + C#
- [ux-design](../ux-design/SKILL.md) — designs the screens, flows, and microcopy on top of the systems
- [ux-research](../ux-research/SKILL.md) — playtesting and synthesis to validate the design holds up under real players
- [software-design](../software-design/SKILL.md) — the design's *implementation* should still respect cohesion/coupling principles
- [content-ops](../content-ops/SKILL.md) — expert-panel scoring of the design doc before committing to build
