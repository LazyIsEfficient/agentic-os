# Scenes and Flow

In Phaser, the `Scene` is the unit of state, the unit of flow, and the unit of cleanup. Almost every architectural mistake in a Phaser project starts as a scene mistake — a god scene that owns everything, a scene that reaches into another scene's fields, a listener attached in `create` that's never removed in `shutdown`, a restart that quietly loses references because nobody re-bound them.

This file is the playbook for getting scenes right: lifecycle, transitions, parallel scenes, cross-scene communication, and the cleanup discipline that keeps the whole thing from leaking.

## What a Scene Actually Is

A `Phaser.Scene` is three things at once:

1. **A render target.** Its own display list, cameras, input handlers. Parallel scenes render together (start order, then `bringToTop`).
2. **A lifecycle host.** `init` → `preload` → `create` → `update` (per frame) → `shutdown` (on stop) → `destroy` (on game destroy).
3. **A namespaced container.** `this.add`, `this.tweens`, `this.input`, `this.events`, `this.cameras`, `this.physics`, `this.sound`, `this.scene`, `this.registry` — each scene's factories and emitters are its own, so a tween in `GameScene` is owned by `GameScene` and dies when it shuts down.

That third property is why `shutdown` matters. Most of what a scene creates is auto-cleaned. The few things that aren't are what leak (see [The Lifecycle Gotchas](#the-lifecycle-gotchas)).

## A Scene Is a TypeScript Class

Write each scene as a class extending `Phaser.Scene`. Always set the key explicitly via the constructor:

```ts
// scenes/GameScene.ts
import Phaser from 'phaser';

export class GameScene extends Phaser.Scene {
  constructor() {
    super({ key: 'GameScene' });
  }
}
```

Why explicit keys: you'll use the string everywhere (`scene.start`, `scene.get`, event labels), it survives bundler mangling of class names, and registering two scenes with the same key fails loudly at startup. In larger projects, export the keys as a constant object (`SceneKeys.Game`) so `scene.start` is type-checked against typos.

## The Lifecycle

Each scene goes through a deterministic sequence. You override the methods you need; you leave the rest alone.

```ts
export class GameScene extends Phaser.Scene {
  constructor() { super({ key: 'GameScene' }); }

  init(data: GameSceneData): void {
    // 1. Runs first, *before* preload. Gets the scene-launch payload.
    // Use for: setting up scene-level config, deciding which assets to preload,
    // initializing properties that preload/create will read.
  }

  preload(): void {
    // 2. Asset loading. The Loader queues here; nothing actually loads until
    // the queue runs. `create` does not start until preload's queue is empty.
  }

  create(data: GameSceneData): void {
    // 3. Runs after preload completes. This is where the scene comes alive —
    // create GameObjects, wire input, start tweens, attach event listeners.
    // The same `data` payload as init, in case create needs it.
  }

  update(time: number, delta: number): void {
    // 4. Runs every frame after create. The hot path. Treat allocations
    // as expensive. `delta` is in ms; multiply by your speeds.
  }

  shutdown(): void {
    // 5. Runs when the scene is stopped (via scene.stop or scene.start to a
    // different key). The scene's own GameObjects, tweens, and timers are
    // auto-cleaned. *External* listeners attached in create are NOT —
    // remove them here.
  }

  // destroy() exists too, but you rarely need to override it. It runs when
  // the entire Game is being torn down (page unload, full app teardown).
  // For the per-scene-lifecycle cleanup, use shutdown.
}
```

A few subtleties that bite people:

- **`init` runs before `preload`.** To preload based on the launch payload, stash it in `init` (`this.levelId = data.levelId`) and read it in `preload`.
- **`init` and `create` both receive `data`.** `init` is for "configure before assets load"; `create` is for "build the world now that they're here." A scene with no preload step can skip `init` entirely.
- **`update` does not receive `data`** — only `(time, delta)`. Stash per-launch values on `this`.
- **`shutdown` is also an event.** Phaser emits `Phaser.Scenes.Events.SHUTDOWN` on `this.events`. Override the method or listen to the event — both work; pick one and be consistent.

## Typed Scene Data

The `data` payload is a free-form `object` by default. Type it.

```ts
// scenes/GameScene.ts
export interface GameSceneData {
  levelId: string;
  difficulty: 'easy' | 'normal' | 'hard';
  carryOverScore?: number;
}

export class GameScene extends Phaser.Scene {
  private levelId!: string;
  private difficulty!: GameSceneData['difficulty'];
  private startingScore = 0;

  constructor() { super({ key: 'GameScene' }); }

  init(data: GameSceneData): void {
    this.levelId = data.levelId;
    this.difficulty = data.difficulty;
    this.startingScore = data.carryOverScore ?? 0;
  }

  preload(): void {
    this.load.json('level-data', `assets/levels/${this.levelId}.json`);
  }

  create(_data: GameSceneData): void {
    // ...build the level, using this.levelId / this.difficulty / this.startingScore
  }
}
```

The `!` on field declarations is the "definitely-assigned-in-init" assertion. Phaser does call `init` before anything else reaches these fields, so it's honest.

To launch this scene with a typed payload from elsewhere:

```ts
this.scene.start('GameScene', {
  levelId: 'forest-1',
  difficulty: 'normal',
  carryOverScore: 1500,
} satisfies GameSceneData);
```

Use `satisfies`, not `as` — `satisfies` checks against the type without widening; `as` defeats the check.

## The Scene Manager

`this.scene` (inside a scene) and `game.scene` (outside) is the `SceneManager`. It owns every method that changes which scenes are running. The methods you'll use 95% of the time:

### `start(key, data?)` — replace the current scene

The default for "go to next screen." Stops the current scene (which fires `shutdown`), starts the target scene (which fires `init` → `preload` → `create`).

```ts
this.scene.start('GameScene', { levelId: 'forest-1', difficulty: 'normal' });
```

After `start`, the calling scene is gone. Its event listeners are the ones you should have removed in `shutdown`.

### `launch(key, data?)` — run another scene *in parallel*

Both the calling scene and the target scene run. Their `update` methods both fire each frame; their display lists both render. Use for HUDs over gameplay, modal overlays, parallel gameplay layers.

```ts
// In GameScene.create:
this.scene.launch('HudScene', { initialScore: this.startingScore });
```

The two scenes do not share state automatically. They communicate via events, the registry, or a shared event bus — see [Cross-Scene Communication](#cross-scene-communication).

### `pause(key?)` / `resume(key?)` — freeze without unloading

`pause` stops the scene's `update` and physics but leaves its display list rendered. `resume` un-pauses. Scene state is preserved. Classic use — a pause menu over gameplay:

```ts
// In GameScene, on ESC:
this.scene.launch('PauseMenuScene');
this.scene.pause();   // pauses the calling scene

// In PauseMenuScene, when resuming:
this.scene.stop();
this.scene.resume('GameScene');
```

With no key, these methods act on the calling scene; with a key, on the named scene. Be deliberate.

### `stop(key?)` — actually shut a scene down

Triggers `shutdown`. GameObjects, tweens, timers, and scene-level listeners are released. After `stop`, `scene.start` runs `init` → `preload` → `create` from scratch. `scene.start(key)` implicitly stops the calling scene; explicit `scene.stop` is for cleaning up a *launched* parallel scene (HUD, pause menu) you're done with.

### `restart(data?)` — full reset of the calling scene

The "retry level" hammer. Phaser stops the scene and starts it again with new `data`. All scene state is lost; `init` and `create` run fresh.

```ts
this.scene.restart({ levelId: this.levelId, difficulty: this.difficulty, carryOverScore: 0 });
```

What restart resets: GameObjects, tweens, timers, physics, animations, `this.events`, all `this.<field>` state.

What restart does **not** reset: the `registry`, the global `game.events` emitter, a shared `EventBus` singleton, any other parallel scene that wasn't stopped.

If a `game.events.on(...)` listener was attached without a matching `off` in shutdown, restart silently double-binds it. Three retries in, the same handler runs four times per event. See [The Lifecycle Gotchas](#the-lifecycle-gotchas).

### `sleep(key?)` / `wake(key?)` — pause + hide

`sleep` pauses *and* removes the scene from the display list; `wake` puts it back. Less common than pause/resume; useful for "tabbed" sub-scenes you flip between without rebuilding.

### `bringToTop(key)` — reorder parallel scenes

Scenes draw in start order. `bringToTop` (and siblings `sendToBack`, `moveAbove`, `moveBelow`) force a different render order — typically the HUD on top of gameplay on top of a background.

### `swap(from, to)` — clean transition shorthand

`scene.swap('A', 'B')` starts B if not running, brings B to top, stops A. Use it when you specifically need that dance.

## The Parallel HUD Pattern

The canonical "two scenes running together" use case is a HUD over gameplay. Concretely:

```ts
// scenes/GameScene.ts
export class GameScene extends Phaser.Scene {
  constructor() { super({ key: 'GameScene' }); }

  create(): void {
    // Launch the HUD in parallel — does NOT stop GameScene.
    this.scene.launch('HudScene');
    this.scene.bringToTop('HudScene');

    // Game-side events that the HUD will observe.
    // Use this.events (scene-scoped) — when GameScene shuts down,
    // these listeners die with it automatically.
    this.events.on('score-changed', (newScore: number) => {
      // ...local effects in GameScene if needed
    });
  }

  private addScore(amount: number): void {
    const newScore = (this.registry.get('score') as number) + amount;
    this.registry.set('score', newScore);
    this.events.emit('score-changed', newScore);
  }
}
```

```ts
// scenes/HudScene.ts
export class HudScene extends Phaser.Scene {
  private scoreText!: Phaser.GameObjects.Text;
  constructor() { super({ key: 'HudScene' }); }

  create(): void {
    this.scoreText = this.add.text(16, 16, 'Score: 0', { fontSize: '24px' });

    // The one acceptable cross-scene reach: HUD subscribes to game's events.
    const game = this.scene.get('GameScene');
    const onScoreChanged = (s: number) => this.scoreText.setText(`Score: ${s}`);
    game.events.on('score-changed', onScoreChanged);

    // CRITICAL: remove on shutdown, or restarting GameScene leaks this binding.
    this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      game.events.off('score-changed', onScoreChanged);
    });
  }
}
```

Two things to call out:

- The HUD *observes* the game. It never writes back. Score logic stays in `GameScene`.
- The HUD's listener on `GameScene.events` is a **cross-scene listener** — `this.events` cleanup is the HUD's own emitter, not the game's. The explicit `SHUTDOWN` handler is mandatory.

For anything more than HUD-listens-to-game telemetry, prefer a shared `EventBus` (next section). Reaching into another scene's emitter scales poorly — six scenes all listening to each other becomes a graph nobody can untangle.

## Cross-Scene Communication

Three approaches, ranked from best to worst.

### Best: a shared `EventBus`

A module-level singleton `Phaser.Events.EventEmitter`. Any scene can import it; any scene can emit or subscribe.

```ts
// events/EventBus.ts
import Phaser from 'phaser';

export const EventBus = new Phaser.Events.EventEmitter();

// Type the event surface.
export type GameEvents = {
  'player-died': { cause: string };
  'level-completed': { levelId: string; timeMs: number };
  'score-changed': { newScore: number; delta: number };
};

// Helper for type-safe emit (optional but worth it).
export function emit<K extends keyof GameEvents>(key: K, payload: GameEvents[K]): void {
  EventBus.emit(key, payload);
}
```

Anywhere in the game:

```ts
import { EventBus, emit } from '../events/EventBus';

// In GameScene:
emit('player-died', { cause: 'fall' });

// In any other scene:
const onDeath = (p: GameEvents['player-died']) => { /* ... */ };
EventBus.on('player-died', onDeath);
this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
  EventBus.off('player-died', onDeath);
});
```

The `EventBus` survives scene restarts. **That's its strength and its trap.** Always pair the `on` with an `off` in `SHUTDOWN`. Skip the cleanup and you've built a leak that grows with every restart.

### OK: `this.registry`

The registry is a game-wide key/value store, accessible as `this.registry` from any scene. It emits `changedata-<key>` events when values change.

```ts
// In GameScene:
this.registry.set('score', 0);

// Increment from anywhere:
this.registry.set('score', (this.registry.get('score') as number) + 100);

// In HudScene:
this.registry.events.on('changedata-score', (_parent: unknown, value: number) => {
  this.scoreText.setText(`Score: ${value}`);
});
this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
  this.registry.events.off('changedata-score');
});
```

Good for: persistent state that survives scene transitions — score, lives, currency, current level, audio volume, settings.

Bad for: rich event payloads (use `EventBus`); anything you'd be embarrassed to call "global state." The registry is convenient enough to abuse; see [phaser-anti-patterns.md](phaser-anti-patterns.md).

### Last resort: `this.scene.get('OtherScene').events`

Fine for HUD-listens-to-game telemetry, where the dependency is one-way and obvious. Beyond that it's a smell — the subscriber knows the publisher's scene key, the subscriber must remember to clean up on `SHUTDOWN`, and N scenes listening to each other becomes a quadratic graph. Past the HUD case, reach for the `EventBus` or the registry.

### Anti-pattern: `this.scene.get('OtherScene').someField`

Reading another scene's fields directly. Brittle; couples reader to writer's internals; breaks at the next refactor. See [phaser-anti-patterns.md](phaser-anti-patterns.md).

## Scene-Level vs Game-Level Events

Three emitters live in any scene. They look similar; they have very different lifetimes.

| Emitter | Scope | Survives scene shutdown? | Use for |
|---|---|---|---|
| `this.events` | Per-scene | No — fresh every `create` | Within-scene events; `SHUTDOWN`, `PAUSE`, `RESUME`, `CREATE` lifecycle hooks; emitting events the HUD scene listens to |
| `this.game.events` | Game-wide | Yes — survives every scene transition | Truly global signals — focus/blur, full game pause, save events. Cleanup is mandatory. |
| `this.registry.events` | Game-wide | Yes — registry is game-wide | Reacting to state changes in the registry (`changedata-<key>`). Cleanup is mandatory. |
| `EventBus` (your singleton) | Game-wide | Yes — module-level | Cross-scene event-driven communication. Cleanup is mandatory. |

The pattern: anything that survives the scene's own lifetime is a leak risk. `this.events` cleans itself up; everything else needs a `SHUTDOWN` handler.

## The Lifecycle Gotchas

These are the cleanup rules that keep scenes from leaking on restart. Memorize them.

1. **Scene-internal listeners on `this.events` are auto-cleaned.** Dies on shutdown.
2. **Scene-internal tweens and timers are auto-cleaned.** `this.tweens.add(...)`, `this.time.addEvent(...)` — released on shutdown.
3. **GameObjects in the scene's display list are auto-destroyed on shutdown.** Their listeners go with them.
4. **`this.input` listeners are auto-cleaned** — `this.input` and `this.input.keyboard` are per-scene.
5. **External listeners are NOT auto-cleaned.** Anything attached to `this.game.events`, `this.registry.events`, the `EventBus`, or another scene's `events` survives the scene. Remove in `shutdown` or in a `SHUTDOWN` event handler.
6. **Tweens on non-scene objects.** `this.tweens.add({ targets: external, ... })` is still owned by the scene's tween manager and gets cleaned up. But a *custom* tween loop holding a scene-local target from outside the scene inverts ownership — clean up by hand.
7. **DOM and third-party listeners are yours.** `window.addEventListener`, observers, `setInterval`, plugin globals — Phaser doesn't know about them. You own the cleanup.

The clean shutdown pattern: a single `SHUTDOWN` handler at the end of `create` that mirrors every external `on` with an `off`.

```ts
create(): void {
  const onResize = () => { /* ... */ };
  const onGlobalPause = () => { /* ... */ };
  const onScoreChanged = (..._args: unknown[]) => { /* ... */ };

  window.addEventListener('resize', onResize);
  this.game.events.on('hidden', onGlobalPause);
  EventBus.on('score-changed', onScoreChanged);

  this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
    window.removeEventListener('resize', onResize);
    this.game.events.off('hidden', onGlobalPause);
    EventBus.off('score-changed', onScoreChanged);
  });
}
```

Local to the bindings, easy to grep, survives refactors.

## Splitting a Scene That's Grown Too Big

Symptoms of a scene-too-big problem: `create` is 300+ lines; `update` mixes player logic, enemy AI, projectile updates, UI tweaks, and audio cues; the file is fighting merge conflicts. Three escape hatches, in order of preference.

### 1. Extract a system into a plain TS class

Best for game systems that don't render anything new and don't need a separate display list. The scene composes the system, holds a reference, calls into it.

```ts
// systems/SpawnSystem.ts
export class SpawnSystem {
  constructor(private scene: Phaser.Scene, private enemies: Phaser.GameObjects.Group) {}
  update(time: number, delta: number): void { /* ... */ }
  spawnWave(count: number): void { /* ... */ }
}

// scenes/GameScene.ts — uses the system
private spawns!: SpawnSystem;
create(): void { this.spawns = new SpawnSystem(this, this.add.group()); }
update(t: number, dt: number): void { this.spawns.update(t, dt); }
```

A class, not a scene. Uses the scene's factories but has no lifecycle of its own. Test it in isolation; reuse across game scenes.

### 2. Launch a sub-scene for a self-contained sub-experience

Best when the sub-experience has its own input, its own UI, or its own pause/resume semantics. Examples: a minigame inside a level, a modal dialog flow, an inventory screen, a cutscene.

```ts
// In GameScene, when entering a fishing minigame:
this.scene.launch('FishingMinigameScene', { lakeId: 'pond-1' });
this.scene.pause();  // freeze the world while the minigame plays
```

The sub-scene has its own `create`, `update`, `shutdown`. When it's done, it stops itself and resumes the parent.

### 3. Promote it to a parallel HUD/overlay scene

Best when the concern is purely UI rendering on top of gameplay. Score, health bar, mini-map, ability cooldowns, debug overlays — all of these are HUD scenes.

The scene runs in parallel with `GameScene`, observes `EventBus` or `registry` events, renders its own display list. Detailed in [The Parallel HUD Pattern](#the-parallel-hud-pattern) above.

The wrong move: making everything a scene because "scenes are how Phaser organizes things." A scene has overhead — its own cameras, its own input plugins, its own display list, its own update loop. A small system that doesn't need any of that should be a plain class.

## Scene Transitions and Visual Continuity

A hard cut feels jarring. The cross-fade pattern via `Cameras.main` covers 90% of cases:

```ts
// Leaving scene:
private leaveTo(nextKey: string, data?: object): void {
  this.cameras.main.fadeOut(400, 0, 0, 0);
  this.cameras.main.once(Phaser.Cameras.Scene2D.Events.FADE_OUT_COMPLETE, () => {
    this.scene.start(nextKey, data);
  });
}

// Destination scene's create:
create(): void {
  this.cameras.main.fadeIn(400, 0, 0, 0);
}
```

For elaborate transitions (wipes, circle reveals), launch a dedicated `TransitionScene` in parallel that renders the effect on top and triggers `start`. You almost never need that — fade is enough.

For physics-heavy scenes, call `this.physics.pause()` on the way out so a body doesn't tick off-screen during the fade.

## The Boot + Preload Pattern

The canonical loading pattern in any non-trivial Phaser project: **two scenes before the game starts**, not one.

- **`BootScene`** — minimal. Loads only the assets needed to render the loading screen itself: the logo, the loading-bar texture, a font. Nothing else. Then transitions to `PreloadScene`.
- **`PreloadScene`** — loads the bulk of game assets while showing a progress bar. Subscribes to the loader's `progress` event to update the bar. When loading completes, transitions to the menu (or directly into the game on speed-runs and dev builds).

Why two scenes: if you put both jobs in one scene, you have a chicken-and-egg problem — the loading bar's texture isn't loaded yet when the loader starts. `BootScene` solves this by being pre-pre-load.

Skeleton:

```ts
// scenes/BootScene.ts
export class BootScene extends Phaser.Scene {
  constructor() { super({ key: 'BootScene' }); }

  preload(): void {
    // Just the loading-screen assets. Keep this tiny.
    this.load.image('logo', 'assets/ui/logo.png');
    this.load.image('loading-bar', 'assets/ui/loading-bar.png');
    this.load.image('loading-bar-bg', 'assets/ui/loading-bar-bg.png');
  }

  create(): void {
    this.scene.start('PreloadScene');
  }
}
```

```ts
// scenes/PreloadScene.ts
export class PreloadScene extends Phaser.Scene {
  constructor() { super({ key: 'PreloadScene' }); }

  preload(): void {
    const { width, height } = this.cameras.main;
    this.add.image(width / 2, height / 2 - 60, 'logo');
    this.add.image(width / 2, height / 2 + 40, 'loading-bar-bg');
    const bar = this.add.image(width / 2, height / 2 + 40, 'loading-bar');
    const full = bar.width;
    bar.setCrop(0, 0, 0, bar.height);

    this.load.on(Phaser.Loader.Events.PROGRESS, (v: number) => {
      bar.setCrop(0, 0, full * v, bar.height);
    });

    // The bulk of the game's assets.
    this.load.atlas('characters', 'assets/characters.png', 'assets/characters.json');
    this.load.audioSprite('sfx', 'assets/sfx.json', ['assets/sfx.ogg', 'assets/sfx.mp3']);
    this.load.tilemapTiledJSON('forest-1', 'assets/levels/forest-1.json');
    this.load.image('tiles', 'assets/tiles.png');
  }

  create(): void {
    this.scene.start('MenuScene');
  }
}
```

```ts
// main.ts — registering the scenes in order
import { BootScene } from './scenes/BootScene';
import { PreloadScene } from './scenes/PreloadScene';
import { MenuScene } from './scenes/MenuScene';
import { GameScene } from './scenes/GameScene';
import { HudScene } from './scenes/HudScene';

new Phaser.Game({
  type: Phaser.AUTO,
  width: 1280,
  height: 720,
  scene: [BootScene, PreloadScene, MenuScene, GameScene, HudScene],
  // ...rest of config
});
```

Phaser starts the **first** scene in the array by default. Put `BootScene` first.

Extensions that come up:

- **Per-level preloading.** Global `PreloadScene` loads only the always-used assets. Per-level assets go in `GameScene.preload`, gated on `levelId` from the launch payload.
- **Asset packs.** `this.load.pack('assets', 'assets/pack.json')` declares everything in one JSON file — cleaner than dozens of `load.image` lines.
- **Restart is cheap.** The loader caches by key, so re-calling `this.load.image('foo', ...)` is a no-op. But dynamic keys (`level-${id}`) cache forever — call `this.textures.remove(key)` for ones you won't reuse.

## Anti-Patterns

- **God scene.** One `GameScene` owning the player, every enemy, inventory UI, pause menu, score logic, audio, save state. ~3000 lines of mixed concerns. Split via one of the escape hatches above.
- **Cross-scene reach-ins.** `this.scene.get('Other').player.health = 0`. Couples caller to internals; breaks at next refactor. Use `EventBus` or registry.
- **Forgetting to remove external listeners on shutdown.** The leak that compounds on every restart. Pair every external `on` with a `SHUTDOWN`-time `off`.
- **Module-level globals for scene state.** "I'll just stick `currentLevel` in a module variable." Restart can't reset it; tests can't isolate it. Use the registry, scene fields, or the launch payload.
- **Implicit Z-order from start order.** Past two parallel scenes, document intended render order with explicit `bringToTop` calls and comments — don't hope launch order matches.
- **Heavy work in `init`.** `init` is for cheap config. No asset loading (use `preload`); no GameObjects (use `create` — `init` runs before the scene is fully wired).
- **`scene.start` from `update` without a guard.** `start` defers to end-of-frame, but a chain of events calling `start` repeatedly produces duplicate restarts. Add `if (this.transitioning) return;`.
- **Mutating the launch-data payload.** The object is shared with the caller. Treat it as read-only; copy to scene fields if you need to mutate.
- **`scene.restart` to "reset state."** Correct for death/retry — but if the only reason is "I don't want to write a reset function," write the function. Restart tears down and rebuilds everything; selective reset is faster and clearer.

For the broader catalog (registry-as-globals, update-loop allocations, asset re-loading), see [phaser-anti-patterns.md](phaser-anti-patterns.md).

## Related

- [phaser-fundamentals.md](phaser-fundamentals.md) — the engine model: `Game`, `Scene`, the loop, the loader, GameObjects, the display list
- [project-and-vite.md](project-and-vite.md) — project scaffold; where scene files live; how the build serves them
- [physics-arcade.md](physics-arcade.md) — physics bodies and groups within a scene's lifecycle
- [phaser-anti-patterns.md](phaser-anti-patterns.md) — broader patterns to avoid
- [SKILL](../SKILL.md) — the parent Phaser engineer skill
