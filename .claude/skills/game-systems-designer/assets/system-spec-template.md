# System spec — <system name>

> One per major system named in the design doc's systems list. The contract that `game-balancer` tunes against and `godot-engineer` (or other engine team) builds to.

## Role
<one sentence: what this system does for the game and how it serves the fantasy/aesthetic>

## Player verbs it supports
- <verb 1>
- <verb 2>

## Inputs (what feeds this system)
- From player: <inputs, choices, resources>
- From other systems: <which systems hand off into this one>
- From content: <levels, items, characters, events>

## Outputs (what this system feeds)
- To player: <feedback, rewards, state changes>
- To other systems: <which systems receive from this one>
- To save state: <what persists across sessions>

## Rules and state
- Entities: <the things this system tracks>
- State per entity: <what each entity holds>
- Transitions: <how state changes — events, conditions, triggers>
- Invariants: <what must always be true>

## Interactions with other systems (cohesion check)
- This system is *better* because of: <which other systems amplify it>
- This system makes *better*: <which other systems it amplifies>
- If this system were cut, the game would lose: <one sentence — if the answer is "nothing important", cut the system>

## Failure cases
- How the player can fail in this system: <>
- How the system can fail (edge cases the engineer must handle): <>

## Numbers (placeholders for `game-balancer`)
- <variable name>: <TBD by game-balancer — design intent: "should make the player choose X over Y about 60% of the time">
- <variable name>: <TBD — intent: "session length impact ≈ +20%">

> Do NOT guess at numbers. Capture the *design intent* (what behavior the number should produce) and let `game-balancer` pick the value.

## Pricing / monetization touchpoints
- Does this system touch monetization? <yes/no>
- If yes, what catalog SKUs it implies (for `iap-manager`): <e.g. "currency packs", "cosmetics for X", "skip-timer">
- Which monetization model fits this system best (for `game-monetization-strategist`): <>

## UI surfaces (for `ux-design`)
- Screens this system needs: <>
- Critical states the UI must convey: <>
- Microcopy load: <heavy / light>

## Engineering hand-off (for `godot-engineer` or other team)
- Suggested architectural fit (Godot example): <e.g. "autoload singleton + per-entity component", "scene-instanced controller">
- Save/load expectations: <which state persists, version migration concern>
- Multiplayer authority (if applicable): <client / server / hybrid>
- Performance hot path: <expected entity count, tick frequency>

## Open design questions
- <questions to resolve before this system is built>
