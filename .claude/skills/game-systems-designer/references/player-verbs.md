# Player verbs

A verb is what the player *does*. Every system in the game exists to support a verb (or it should be cut). Every verb has the same anatomy. Designers who specify verbs imprecisely ship games where "the controls feel weird" — which is usually a verb-design problem misdiagnosed as a tuning problem.

## Verb anatomy

For each of the game's (max) three verbs:

1. **Input** — the literal player action (button, gesture, drag, decision under time pressure)
2. **Representation** — what the player sees / hears in response (animation, particles, audio, screen feedback)
3. **Feedback** — what tells the player *whether the action worked, and how well* (numbers, hit-stop, juice, audio pitch, visual escalation)
4. **Failure** — how the verb can fail and what failing feels like (whiff, miss, overcommit, cancelled)
5. **Depth axis** — how the verb *grows* across the play arc (timing → reading → mind games → optimization)

A verb that's missing any of these will feel mushy.

## The depth axis (often missed)

A verb without a depth axis is a verb the player gets bored of. Examples:

- **Punching** in a beat-em-up — Depth: combo timing → enemy-type-specific responses → resource management (super meter) → spacing and hitboxes
- **Building** in a city builder — Depth: placement → adjacency bonuses → supply chains → optimization for endgame goals
- **Negotiation** in an RPG — Depth: dialogue choices → reading characters → maintaining personae across factions → triggering long-term consequences

If you can't name 3–4 levels of depth for a verb, the verb is shallow and the player will exhaust it in the first hour. Either deepen it or drop it.

## Three verbs maximum

Why three:

- Each verb needs **input space** (buttons, screen real estate, control schemes). More than three and the controls fight themselves.
- Each verb needs **content** that exercises it. More than three and content production explodes.
- Each verb needs **mastery time**. Players have a finite attention budget for learning verbs in the first hours.

If the design has more than three "core" verbs, some are actually:
- **Sub-verbs** (variations on a primary verb — "dash" is a sub-verb of "move")
- **System interactions** (the player isn't doing them; they're picking what the system does)
- **Meta-verbs** (between sessions — "build a deck" is meta-verb to "play a card" core verb)

Refactor until you have three. If you can't, the concept has too many ideas in it (back to `game-concept-creator`).

## Verbs vs features

A common mistake: listing features as verbs.

| Feature (wrong) | Verb (right) |
|---|---|
| Skill tree | Specialize |
| Crafting | Combine |
| Multiplayer | Coordinate / compete / deceive |
| Achievements | Collect |
| Quests | Pursue |
| Dialogue | Persuade / interrogate |
| Inventory | Choose / discard |

The verb is what the player *does mentally*, not the menu they navigate. A "skill tree" with no real choice (you take everything in order) supports no verb.

## The verb-mechanic-aesthetic chain

Each verb traces back to one or more aesthetics:

- **Dodge** → Sensation, Challenge
- **Build** → Expression, Discovery
- **Trade** → Fellowship, Challenge
- **Decide** (under time pressure) → Challenge, sometimes Submission
- **Read** (other players, NPCs) → Fellowship, Discovery
- **Collect** → Discovery, Submission

Verbs that don't trace back to an aesthetic are *features dressed as verbs*. The chain must hold all the way from MDA aesthetic → dynamic → mechanic → verb.

## Verbs and accessibility

Specify accessibility for each verb:

- **Input alternatives** — keyboard, controller, touch, one-handed, accessibility hardware
- **Time pressure** — can the verb be performed without time pressure (toggle for difficulty)
- **Sensory channel** — does the verb require seeing color / hearing audio / fine motor control
- **Cognitive load** — does the verb require remembering hidden state, holding multiple things in mind

Accessibility decisions belong in the verb spec, not in a separate accessibility pass at the end. See `ux-design` for screen-level accessibility.

## Output for system specs

For each verb:

```
## Verb: <name>
- Input: <literal action — button / gesture / decision>
- Representation: <what the player sees and hears>
- Feedback: <what tells the player success/failure and how much>
- Failure: <how it can fail, and what failure feels like>
- Depth axis: <stage 1 → stage 2 → stage 3 → stage 4>
- Aesthetic supported: <which 1–2 from MDA>
- Accessibility: <input alternatives, time-pressure toggles, sensory alternatives>
```
