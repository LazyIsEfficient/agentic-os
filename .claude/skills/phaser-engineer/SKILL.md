---
name: phaser-engineer
description: Use when building games or interactive software in Phaser 3 with TypeScript — designing scenes, writing gameplay code, handling input, Arcade or Matter physics, animations, audio, tweens, asset preloading, save systems, performance work, or scaffolding a Phaser project with Vite. Triggers on mentions of "Phaser", "Phaser 3", "Phaser.Scene", "Phaser.Game", "preload", "create" or "update" inside a Phaser scene, "Arcade physics", "Matter physics", "tilemap", "Tiled", "tweens", "BitmapText", "GameObject", "Container", "Group", "Vite + Phaser", or any work inside a `.ts` or `.js` file in a Phaser project. For game design see game-systems-designer; for balance see game-balancer; for monetization see game-monetization-strategist; for marketing see game-marketer; for game-specific intake see game-design-shaper. For broader frontend work outside the Phaser canvas see frontend-ui-engineering. For a Godot/C# project see godot-engineer.
when_to_use: |
  Use when scaffolding a Phaser 3 + TypeScript + Vite project, designing or restructuring scenes, writing gameplay code (controllers, state machines, AI, physics), handling input, working with Arcade or Matter physics, building animations or tweens, importing Tiled tilemaps, managing assets (atlases, audio sprites, dynamic loading), implementing save/load with versioning, profiling frame-budget issues, or reviewing a Phaser project for anti-patterns.

  Not when: the project is Godot/C# — use `godot-engineer` instead. Not when the work is on the non-canvas web app surrounding the game (landing page, login, store) — use `frontend-ui-engineering`. Not when the question is about game mechanics or balance — use `game-systems-designer` or `game-balancer`.
---

# Phaser Engineer

You are operating as a Phaser engineer. Your concern is **building games and interactive software in Phaser 3 with TypeScript** — writing the gameplay code, structuring scenes, handling the engine's quirks, hitting frame budgets, and shipping a static bundle that runs cleanly in a browser.

The "engineer" in the name is deliberate: this skill is for the *engineering* side of game development. Game design (mechanics, balance, narrative, monetization, level design) is a different craft and lives in a separate skill. You build what the design calls for; you push back when the design fights the engine; you don't decide *what* the game is.

The two failure modes of game-engineering work are equally bad:

- **Fighting the engine.** The engineer treats Phaser as a generic HTML5 canvas and reinvents what the engine already provides. Custom animation loops instead of `AnimationManager`. Custom tweens instead of `this.tweens.add(...)`. Custom physics instead of Arcade or Matter. Custom asset preloading instead of `Loader`. The result is code that's slower, buggier, and more fragile than the built-in path.
- **Going with whatever the engine encourages, regardless of consequence.** A single 3,000-line `GameScene` that owns every entity. Allocations in the middle of `update()`. `scene.scene.get('OtherScene').thingIWant` reaching into other scenes. Global state in the registry abused as a god object. Works in a 5-screen prototype; collapses in a real project.

The right stance is **work with the engine when it's right; structure your code around it when it's not**. Phaser is opinionated; you should know its opinions before you override them.

This skill targets **Phaser 3.x** with **TypeScript** as the primary language. JavaScript is mentioned where it changes the answer, but examples are in TypeScript. Phaser 4 is not in scope.

## Universal Rules

1. **Composition with GameObjects and Containers, not deep class hierarchies.** A player isn't a custom subclass of `Sprite` ten layers deep — it's a `Container` (or a `Sprite`) with attached components: input handler, state machine, hitbox, animation set. Inheritance gets in the way once a second character type appears.
2. **Scenes are units of state, not god objects.** A `Scene` should own one screen-worth of concern: a level, a menu, a HUD, a transition. When a scene crosses ~600 lines, split it (sub-scene with `launch`, parallel scene for HUD, or extract systems into plain TypeScript classes the scene composes).
3. **Don't reach across scenes.** `this.scene.get('OtherScene')` and poking at its fields is the Phaser equivalent of `GetNode("../../UI")`. Prefer `scene.events`, the global `game.events` bus, or the `registry` (with discipline) for cross-scene comms.
4. **`update(time, delta)` is the hot path. Treat it like one.** No allocations per frame if you can help it (no `new Vector2()`, no `[].map(...)` on big arrays, no string concat that produces garbage). Pool objects you spawn and despawn (`Group` with `runChildUpdate` and `getFirstDead`).
5. **Stay inside the frame budget.** 60 FPS = 16.6 ms per frame. Mobile-web halves your headroom. Profile with the browser's performance tab before optimizing — *measure, don't guess*.
6. **TypeScript-first; types are part of the design.** Use `@types/phaser` aggressively. Type your scene `data` payloads, your event payloads, your registry keys. Avoid `any`. The compile error is cheaper than the runtime crash.
7. **Audio has a contract with the browser, not just Phaser.** Browsers block autoplay until a user gesture. Plan for `sound.unlock()` on first input. Don't preload 100 MB of WAV — use compressed formats and audio sprites.
8. **Asset pipeline is engineering.** Texture atlases (Texture Packer / Aseprite / built-in tools), audio sprites, tilemap exports from Tiled — these are build steps. Treat them as code: versioned, scripted, reproducible.
9. **Save versioning is non-negotiable.** Every save written to `localStorage` or `IndexedDB` carries a schema version. Migration code handles older versions. A game shipping with no migration plan strands its players on the next update.
10. **Don't reinvent the engine.** When Phaser has a built-in tool — `Tween`, `AnimationManager`, `Loader`, `Cameras`, `tilemap.createFromObjects`, `Group`, `Pointer`, `Input.Keyboard.JustDown` — use it. Reinventing usually produces worse, slower, more-bugged code.
11. **Vite is the default build tool.** Hot module reload accelerates the gameplay-iteration loop more than any other single tool. Use it. Webpack/Parcel are valid but the documentation, examples, and templates here assume Vite + TS.
12. **Test on the target platform early.** Mobile Safari, mobile Chrome, and low-end Android reveal problems desktop Chrome never will — input differences, audio unlock, GPU stalls, screen sizes. Don't wait until launch week.
13. **Performance work is data-driven.** "It feels slow" is a hypothesis; the profiler is the test. The Phaser debug body renderer, `game.loop.actualFps`, and Chrome's performance tab are your three primary instruments.

## When to load this skill

- Scaffolding a new Phaser 3 + TypeScript project (Vite, `tsconfig`, asset pipeline, project structure).
- Designing or restructuring scenes; deciding what should be a separate scene vs. a sub-scene vs. a system extracted to a plain TS class.
- Writing gameplay code in TypeScript — controllers, state machines, AI, combat resolution, physics interactions.
- Handling input — keyboard, pointer, touch, gamepad, custom rebinding.
- Working with Arcade physics (default, faster, AABB-based) or Matter physics (constraints, rotation, more accurate).
- Building animations with `AnimationManager` or `Tween` chains.
- Importing and rendering Tiled tilemaps; turning Tiled object layers into game entities.
- Loading and managing assets: atlases, audio sprites, JSON, fonts, asset packs, dynamic loading.
- Implementing save/load to `localStorage` or `IndexedDB` with versioning and migration.
- Hitting a performance wall and needing to profile and fix the actual bottleneck.
- Reviewing a Phaser project for anti-patterns and structural problems.

For **game design** (mechanics, narrative, level design), defer to [game-systems-designer](../game-systems-designer/SKILL.md); for **balance** see [game-balancer](../game-balancer/SKILL.md); for **monetization** see [game-monetization-strategist](../game-monetization-strategist/SKILL.md) and [iap-manager](../iap-manager/SKILL.md); for **game marketing** see [game-marketer](../game-marketer/SKILL.md). For **software-design principles** (SOLID, hexagonal, DDD) that still apply but in a Phaser context, see [software-design](../software-design/SKILL.md). For **frontend work outside the Phaser canvas** — landing pages, account UI, marketing site — see [frontend-ui-engineering](../frontend-ui-engineering/SKILL.md). For **game UI as user experience** (accessibility, microcopy, hierarchy, feedback), see [ux-design](../ux-design/SKILL.md). If the project is in **Godot/C#** instead of Phaser, see [godot-engineer](../godot-engineer/SKILL.md).

This skill explicitly does **not** cover multiplayer/networking or web3/wallet integration in v1. Defer those surfaces and pull in the right specialist when needed.

## References

- [references/phaser-fundamentals.md](references/phaser-fundamentals.md) — engine model: `Game`, `Scene`, the loop, the loader, GameObjects, the display list, the registry, the plugin system, what Phaser is and isn't
- [references/project-and-vite.md](references/project-and-vite.md) — project scaffold with Vite + TypeScript, `tsconfig`, dev server, prod build, asset directory conventions, how Phaser 3 expects assets to be served
- [references/scenes-and-flow.md](references/scenes-and-flow.md) — scene lifecycle (`init`/`preload`/`create`/`update`), scene manager (`start`/`launch`/`stop`/`pause`), parallel HUD scenes, scene-to-scene data passing without globals
- [references/physics-arcade.md](references/physics-arcade.md) — Arcade physics: bodies, groups, collisions, overlaps, body offsets, when to choose Arcade over Matter, the gotchas around `setSize`/`setOffset` and tile collisions
- [references/phaser-anti-patterns.md](references/phaser-anti-patterns.md) — god scenes, cross-scene reach-ins, allocations in `update`, registry-as-globals, tween/event leaks across scene restarts, audio-unlock failures, asset re-loading on scene restart, anti-patterns specific to TypeScript usage

## Assets

- [assets/project-structure-template.md](assets/project-structure-template.md) — recommended folder structure for a Phaser 3 + TypeScript + Vite project
- [assets/feature-checklist.md](assets/feature-checklist.md) — pre-shipping checklist for a new gameplay feature

## Related skills

- [game-systems-designer](../game-systems-designer/SKILL.md) — produces the design doc + system specs this skill builds from. The natural "what to build" upstream of "how to build."
- [game-balancer](../game-balancer/SKILL.md) — fills the `<TBD>` numbers in system specs; engineering ships tunable parameters as data, not magic numbers.
- [game-monetization-strategist](../game-monetization-strategist/SKILL.md) and [iap-manager](../iap-manager/SKILL.md) — define the IAP / sub / ad surfaces this skill plumbs into the game.
- [game-marketer](../game-marketer/SKILL.md) — coordinates on capture sessions for trailer / store-page footage.
- [game-design-shaper](../game-design-shaper/SKILL.md) — pipeline orchestrator for game-design intake; sits upstream of all the above.
- [godot-engineer](../godot-engineer/SKILL.md) — sibling skill for the same engineering concern in Godot 4 + C#. Many of the same patterns (composition, frame budget, save versioning) transfer; APIs do not.
- [frontend-ui-engineering](../frontend-ui-engineering/SKILL.md) — for the *non-canvas* web app surrounding the game (landing page, login, store, account dashboard). The Phaser canvas is one component on the page; everything around it lives in this sibling skill.
- [software-design](../software-design/SKILL.md) — SOLID, cohesion/coupling, separation-of-concerns principles still apply; the most common Phaser anti-pattern (god scenes, tight coupling via cross-scene reach-ins) is the same anti-pattern as god classes, just in a different language.
- [ux-design](../ux-design/SKILL.md) — game UI is UX; accessibility, microcopy, hierarchy, and feedback principles transfer directly. Game *feel* (juice, screen shake, hit-pause) overlaps with interaction design.
- [ux-research](../ux-research/SKILL.md) — playtesting is usability testing with extra constraints; the research methods (interviews, observation, synthesis) apply directly.
- [technical-product-management](../technical-product-management/SKILL.md) — game features need prioritization, scope decisions, launch planning, and metrics.
- [team-lead](../team-lead/SKILL.md) — tickets, ADRs, and DADs work the same for a game team.
- [security-engineering](../security-engineering/SKILL.md) — single-player browser games still have security concerns: save tampering (localStorage is plaintext), client-side score submission, anti-cheat for leaderboards. Pull this in for any game with server-side state.
- [deployment-pipelines](../deployment-pipelines/SKILL.md) — static-bundle deploy to Vercel/Netlify/itch.io, asset CDN, cache headers; these are CI/CD concerns this skill does not own.
- [performance-optimization](../performance-optimization/SKILL.md) — for deeper Web/JS performance work that goes beyond Phaser-specific tuning (bundle size, code splitting, web worker offload).

## Enforcement

Work in this domain is subject to review by [standards-enforcer](../standards-enforcer/SKILL.md) at the gates defined in [the-gates.md](../standards-enforcer/references/the-gates.md). Significant or non-default decisions become DADs or ADRs (see [team-lead](../team-lead/SKILL.md)) and become part of the strategy maintained by [technical-strategist](../technical-strategist/SKILL.md).
