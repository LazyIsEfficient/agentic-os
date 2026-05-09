# Phaser Project Structure Template

> A recommended folder layout for a Phaser 3 + TypeScript + Vite project. Use this unless you have a concrete reason not to. Reasons exist; "I prefer my own layout" is rarely one of them on a project bigger than a jam.

This file is the canonical structure that downstream Phaser work in this skill assumes. It builds directly on the scaffold described in [project-and-vite](../references/project-and-vite.md) — same `index.html`, same `vite.config.ts`, same `tsconfig.json`. The piece this file owns is *what goes in `src/` and `public/` once the scaffold is up*.

## Top-level tree

```
my-game/
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
├── public/
│   └── assets/
│       ├── atlases/
│       ├── audio/
│       ├── images/
│       ├── tilemaps/
│       └── fonts/
├── src/
│   ├── main.ts
│   ├── config.ts
│   ├── scenes/
│   │   ├── keys.ts
│   │   ├── BootScene.ts
│   │   ├── PreloadScene.ts
│   │   ├── MenuScene.ts
│   │   ├── GameScene.ts
│   │   └── HudScene.ts
│   ├── entities/
│   │   ├── Player.ts
│   │   └── Enemy.ts
│   ├── systems/
│   │   ├── ScoreSystem.ts
│   │   ├── SaveSystem.ts
│   │   └── InputSystem.ts
│   ├── ui/
│   │   ├── HealthBar.ts
│   │   └── Button.ts
│   ├── data/
│   │   ├── assetKeys.ts
│   │   ├── levels.ts
│   │   └── items.ts
│   ├── events/
│   │   └── EventBus.ts
│   ├── types/
│   │   ├── events.ts
│   │   └── save.ts
│   └── util/
│       ├── math.ts
│       └── format.ts
└── tools/
    └── (atlas/audio sprite scripts, optional)
```

The tree is deliberately shallow. Most directories sit one level under `src/`. Going deeper before you have evidence the project warrants it produces folders with one file in them and a lot of `../../..` imports.

## Per-directory commentary

### `public/assets/`

Static assets served verbatim by Vite. Phaser's `Loader` URLs reference these. Subdivide by asset type — `atlases/`, `audio/`, `images/`, `tilemaps/`, `fonts/` — not by feature.

Why `public/` over `src/assets/`: predictable URLs, no fingerprint hashes the loader has to reconcile. Atlases reference their PNG by filename; tilemaps reference tilesets by relative path. Fingerprinting breaks both. Files imported via `import url from './foo.png'` belong in `src/assets/`; files passed to `this.load.atlas('chars', 'assets/...')` belong here.

Don't subdivide by level or feature here ("assets/level1/", "assets/menu/"). Asset *type* is what survives a feature rename; asset *purpose* is not.

### `src/main.ts`

The `new Phaser.Game(config)` entry. Keep it short — config import + scene registration + game instantiation. No game logic. No DOM manipulation beyond what's needed to mount.

If you find yourself adding more than ~30 lines here, what you're adding probably belongs in `config.ts` or a dedicated `bootstrap.ts`.

### `src/config.ts`

The Phaser game config object exported separately so test harnesses, alternate entry points, or a debug overlay scene can reuse it. Export the `Phaser.Types.Core.GameConfig` as a named export; `main.ts` imports it.

This split feels excessive for a five-scene game and pays for itself the moment you write a second entry point — a debug build, a level-editor variant, a Storybook-style scene playground.

### `src/scenes/`

One file per scene, named `<Name>Scene.ts`. The scene's class name matches the file name. Scene keys live in `keys.ts` next to them.

Don't nest scenes by feature (`scenes/combat/CombatScene.ts`). The scene list is a flat surface — the `Phaser.Scene` registry is flat, the scene manager treats them flat, and your imports want them flat. Nest only when you have ten or more scenes and a clear taxonomy that already shows up in the design doc.

### `src/entities/`

TypeScript classes wrapping `GameObject`s — `Player`, `Enemy`, `Projectile`. Composed by scenes; not subclassed by them.

An entity is a thing that exists *in the game world*: it has a position, it draws itself, gameplay rules apply to it. Entities typically extend `Phaser.GameObjects.Sprite` or `Phaser.GameObjects.Container`. Keep the inheritance shallow — composition (state machines, components) over deep class chains. See the parent skill's universal rule on composition.

### `src/systems/`

Plain TS classes for cross-cutting game systems — `InventorySystem`, `ScoreSystem`, `SaveSystem`, `InputSystem`. No engine inheritance. Systems take a `Scene` reference if they need to spawn things, emit events, or read input.

The split between `entities/` and `systems/`: entities *exist* in the world; systems *act on* the world. A `Player` is an entity. A `SaveSystem` is a system. A `Bullet` is an entity; the `BulletPool` that recycles them is a system. When the line is fuzzy, ask whether the thing has a position on screen — if not, it's a system.

### `src/ui/`

UI-specific GameObjects, often `Container` subclasses — `HealthBar`, `Button`, `DialogBox`, `Tooltip`. Distinct from `entities/` because they're inert from a gameplay-rules perspective: damage doesn't apply to them, physics doesn't move them, save data doesn't track them.

A HUD scene composes UI components; a game scene composes entities and systems. The UI components themselves don't know which scene they live in.

### `src/data/`

Static data — level definitions, item tables, dialog scripts, asset-key constants. Often `as const` typed records. Tunable numbers live here, not in scene code.

This is the boundary between the game-balancer's spreadsheet and the engineer's code. The balancer hands you numbers; you transcribe them into typed `as const` records under `src/data/`. When the balancer changes a value, exactly one file changes. See the parent skill's universal rule on tunable parameters as data, not magic numbers.

### `src/events/EventBus.ts`

The singleton `Phaser.Events.EventEmitter` used for cross-scene comms. See [scenes-and-flow](../references/scenes-and-flow.md) for how it's used. Other event-related modules — typed payload helpers, debug listeners — can live alongside it.

One file, one bus. Don't multiply buses (`UIEventBus`, `GameEventBus`, `SaveEventBus`) until you have a concrete reason. Typed event names and payloads achieve isolation without a second bus.

### `src/types/`

Shared TypeScript types and interfaces — event payloads, scene `init` data, save schemas, registry-key shapes. Files are named by domain: `events.ts`, `save.ts`, `scenes.ts`.

Types that live with one class (a `PlayerState` enum used only by `Player`) stay in that class's file. `src/types/` is for types that cross module boundaries — things three or more files import.

### `src/util/`

Small pure helpers — math, formatting, type guards. No engine references if avoidable; util functions should be testable in isolation without a `Phaser.Game` instance.

If you're tempted to put something Phaser-specific in `util/` ("a helper that wraps `this.tweens.add`"), it probably belongs in `systems/` or as a method on the scene base class — not in util.

### `tools/`

Optional folder for asset-pipeline scripts — atlas regeneration via TexturePacker CLI, audio sprite generation via `audiosprite`, custom tilemap post-processors. Run via `npm` scripts (`"pack:atlas": "node tools/pack-atlas.mjs"`). Outputs land in `public/assets/`.

These scripts are code; treat them as code. Versioned, scripted, reproducible. The asset pipeline is part of the project's build, even if it doesn't run on every commit.

## Naming conventions

### Scenes

`BootScene`, `PreloadScene`, `MenuScene`, `GameScene`, `HudScene` — class name and file name match. The `Scene` suffix is non-negotiable; it disambiguates `Game` (Phaser's root class) from `GameScene` (your gameplay scene), and `Menu` (the data structure) from `MenuScene` (the screen).

### Scene keys

A `const` map or `enum` in `src/scenes/keys.ts`:

```ts
export const SceneKeys = {
  Boot: 'BootScene',
  Preload: 'PreloadScene',
  Menu: 'MenuScene',
  Game: 'GameScene',
  Hud: 'HudScene',
} as const

export type SceneKey = typeof SceneKeys[keyof typeof SceneKeys]
```

Avoid string literals scattered through the codebase. `this.scene.start('GameSceen')` (typo) silently does nothing; `this.scene.start(SceneKeys.Game)` fails to compile.

### Entities

`Player`, `Enemy`, `Projectile` — singular nouns, classes. If you have multiple enemy types, name them concretely (`Goblin`, `Slime`, `Boss`) and keep `Enemy` as the base class or interface they implement. Don't end entity names with `Entity` — the suffix doesn't add information.

### Systems

`<Concern>System` — `ScoreSystem`, `SaveSystem`, `InputSystem`, `InventorySystem`. The `System` suffix earns its keep here because the alternative names (`Score`, `Save`, `Input`) collide with concepts that already exist in the codebase or in Phaser.

Manager and Controller are also acceptable when they read more naturally (`AudioManager`, `CameraController`). Pick one and stay consistent within a project.

### Asset keys

Namespaced strings — `"atlas:player"`, `"audio:sfx:jump"`, `"image:logo"` — or, even better, exported `const` strings from `src/data/assetKeys.ts`:

```ts
export const AssetKeys = {
  atlas: {
    player: 'atlas:player',
    enemies: 'atlas:enemies',
  },
  audio: {
    sfxJump: 'audio:sfx:jump',
    musicTitle: 'audio:music:title',
  },
} as const
```

The string-key form is fine for a jam. The `const` map is what survives a project rename, a refactor, or a typo. `noUncheckedIndexedAccess` plus the const map plus your editor's autocomplete makes asset keys impossible to misspell silently.

### Files

- `PascalCase.ts` for files that export a primary class — `Player.ts`, `HealthBar.ts`, `GameScene.ts`.
- `camelCase.ts` for utility modules and data files — `assetKeys.ts`, `math.ts`, `levels.ts`.

The split is "is the headline export of this file a class?" If yes, PascalCase. If it's a function, a const, or a type, camelCase.

## Where state lives

A short cheat sheet — when you're deciding where to put a piece of state, walk this list:

- **Per-scene transient state** — scene class fields (`this.player`, `this.score`). Dies on `shutdown`. Default for anything that only matters while one scene is active.
- **Cross-scene persistent state (in-memory)** — `this.registry` (the `Phaser.Data.DataManager` on the game) or a singleton TS class. For things multiple scenes need to read or write within one play session: current run's score, selected character, audio volume.
- **Persistent state (across sessions)** — `localStorage` / `IndexedDB` via a `SaveSystem`. Schema-versioned from day one. Anything the player would lose if they closed the tab and you didn't save it.
- **Tunable numbers** — `src/data/` as `as const` records. Damage values, drop rates, level configs, costs. Never magic numbers in scene code; never read from `localStorage` (those are *save* data, not *tuning* data).

The mistake at every scale is putting state one level too low — making a piece of run-state into a `localStorage` save, or putting a tunable number in a scene class field. Walk the list, pick the highest level that fits.

## What this layout deliberately does NOT do

### No Redux / Zustand / MobX

Phaser scenes own their state. The registry handles cross-scene state. The EventBus handles comms. State libraries add ceremony for a problem this layout doesn't have — and they add it on the hot path, where allocations matter.

If your game has a non-trivial *web app* surrounding the canvas (account, store, leaderboard, social), use a state library *there* — but on the React/Vue/Svelte side, in a separate package or a separate `src/web/` directory. Don't reach across the canvas boundary with one.

### No `index.ts` barrel exports per directory by default

Barrels (`src/entities/index.ts` re-exporting everything) are a pleasant convenience that becomes a circular-import factory in larger games. `Player` imports from `entities/index.ts` which re-exports `Enemy` which imports from `entities/index.ts` — and now your bundle has a load-order cycle.

Add barrels only when a directory has a *stable* surface — `src/util/`, `src/types/`, `src/data/` are reasonable candidates once they stop changing weekly. `src/scenes/`, `src/entities/`, `src/systems/` should not have barrels.

### No mixing of canvas-game code and surrounding-web-app code

If a marketing site, a login flow, or a store wraps the game, that's a separate package or a separate `src/web/` directory with its own entry point and its own bundle. Phaser code doesn't import React. React doesn't import Phaser.

The boundary is a `<canvas>` element in the page, plus a small typed event interface for "game says player died, web app shows leaderboard modal". Crossing this boundary in either direction collapses two cleanly-separated concerns into one tangled one — and produces bundles where the marketing landing page ships 1 MB of game engine.

## Variations

### Smaller projects

For a jam or prototype, a flat layout is fine:

```
my-game/
├── public/assets/
├── src/
│   ├── main.ts
│   ├── BootScene.ts
│   ├── GameScene.ts
│   └── Player.ts
├── index.html
├── package.json
├── tsconfig.json
└── vite.config.ts
```

Don't over-organize until the project warrants it. The structure above is what a five-day jam looks like; the full structure earlier is what a six-month project looks like. Migrate when the flat version starts to hurt — usually around 20 source files.

### Larger projects

For a project with many systems, you might add:

- `src/scenes/levels/` — when you have ten or more level scenes that share a base class
- `src/ai/` — behavior trees, state machines, pathfinding, separate from `systems/` because the volume justifies a dedicated folder
- `src/network/` — multiplayer client code, if and when networking is in scope (out of scope for this skill in v1)
- `src/web3/` — wallet integration, if and when relevant (also out of scope for this skill in v1)
- `tests/unit/`, `tests/integration/` — if you're running a test framework

Add these *as you need them*, not preemptively.

## Related

- [SKILL](../SKILL.md) — the parent skill and its universal rules
- [project-and-vite](../references/project-and-vite.md) — the scaffold this layout sits on top of
- [phaser-fundamentals](../references/phaser-fundamentals.md) — engine model: `Game`, `Scene`, the loop, the loader, GameObjects
- [scenes-and-flow](../references/scenes-and-flow.md) — scene lifecycle, scene manager, EventBus pattern referenced above
- [physics-arcade](../references/physics-arcade.md) — Arcade physics setup, where bodies and groups fit in this structure
- [phaser-anti-patterns](../references/phaser-anti-patterns.md) — god scenes, cross-scene reach-ins, registry-as-globals — the failure modes this structure is designed to prevent
- [feature-checklist](feature-checklist.md) — pre-shipping checklist for a new gameplay feature built within this structure
