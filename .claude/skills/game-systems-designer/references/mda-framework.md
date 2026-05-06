# MDA — Mechanics, Dynamics, Aesthetics

The MDA framework (Hunicke, LeBlanc, Zubek, 2004) is the discipline that keeps a game *feeling like its pitch*. Designers see Mechanics → Dynamics → Aesthetics; players experience the reverse. Designing in the player's direction (aesthetics first) is what stops a game from shipping with great mechanics that don't add up to anything.

## The three layers

- **Mechanics** — the rules of the game. Inputs, outputs, state transitions, win/lose conditions, numbers. The thing the engineer implements.
- **Dynamics** — the runtime behavior of the system as players interact with it. Patterns that emerge: arms races, racing-for-resources, deceptive bluffing, tension-and-release.
- **Aesthetics** — the player's emotional response. What the game *feels like* to play.

A game designer's job is to start at the *aesthetic*, work back through the *dynamics* that produce it, and only then write the *mechanics* that produce those dynamics.

## The eight aesthetics (LeBlanc)

A useful starter vocabulary. A game can promise more than one, but should have **one or two dominant** aesthetics — anything else and the pitch fragments.

1. **Sensation** — sensory pleasure (juice, feel, screen shake, audio impact)
2. **Fantasy** — make-believe (you *are* a wizard / spy / chef)
3. **Narrative** — drama unfolding (story beats, character arcs)
4. **Challenge** — obstacle course (mastery, skill ceiling)
5. **Fellowship** — social framework (community, belonging)
6. **Discovery** — uncharted territory (novelty, exploration, surprise)
7. **Expression** — self-discovery (creativity, identity, customization)
8. **Submission** — pastime (mindless flow, killing time)

## Designing backwards

The wrong order: "let's add a crafting system, a skill tree, and a faction reputation." That's mechanics-first. You'll ship a game with three systems and no idea what it feels like.

The right order:

1. **Pick the aesthetic.** "We want this game to feel like the *Discovery* of poking at an indifferent system + the *Expression* of building a personal identity inside it."
2. **Specify the dynamics.** "Players should encounter unexplained behavior that rewards experimentation. Players should make hundreds of small visible choices that compound into a recognizable personal style."
3. **Write the mechanics that produce those dynamics.** Now the crafting system, skill tree, and faction reputation either earn their place (because they produce the chosen dynamics) or get cut.

If a mechanic doesn't produce a dynamic that produces an aesthetic in the design doc, **cut the mechanic**. This is the single most useful test in systems design.

## Common mismatches

- **Pitched as "Fellowship"** (social, belonging) but mechanics are all single-player. The dynamics never produce the aesthetic.
- **Pitched as "Challenge"** (mastery) but every action succeeds with one button press. Dynamics produce *Submission*, not *Challenge*.
- **Pitched as "Discovery"** but the game has a quest log telling the player exactly where to go. Dynamics produce a checklist, not exploration.
- **Pitched as "Expression"** but customization is purely cosmetic and invisible to others. Expression needs an audience.

These are not bugs in the mechanics; they're MDA-misalignments. The fix is at the dynamics layer, not by adding more mechanics.

## When MDA is the wrong tool

MDA is weak at:

- **Narrative-led games** where authored story beats matter more than emergent dynamics. Use it to design the *systems-around-the-story*, not the story itself.
- **Pure social/cultural design** (matchmaking culture, community moderation, tournament structure) where the dynamics emerge from the *players*, not the system.
- **Live-ops cadence** where the meta-game is the operator's calendar, not the in-game systems.

For those, supplement with player-research methods (`ux-research`) and content-strategy thinking.

## Output

Every design doc should explicitly name:
- The 1–2 dominant aesthetics
- The 1–2 supporting aesthetics
- The aesthetics it is *not* targeting (this is as important as what it *is* targeting)
- For each aesthetic: the dynamics that should produce it, and the mechanics that should produce those dynamics

If a designer can't write that chain, the game is mechanics-first and will ship as mechanics-first.
