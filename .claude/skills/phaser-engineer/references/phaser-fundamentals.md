# Phaser Fundamentals

This file is the mental model. Before any of the other reference files make sense, you need to internalize how Phaser 3 thinks — what its core abstractions are, how the main loop runs, what a "scene" actually is, and how the engine relates to the browser hosting it. Skip this and the rest of the skill is harder to apply.

The thing most engineers new to Phaser get wrong, especially those coming from Unity or Godot: **they treat scenes as "the level" and `Phaser.Game` as a passive container, then write a single 3,000-line scene because everything has to live somewhere.** That is not the model. A scene is a unit of state with a lifecycle and its own systems; the `Game` is the runtime that owns a *list* of scenes and arbitrates which ones are running, paused, or sleeping. Once you internalize that, the rest of Phaser makes sense.

## The Engine Model in Five Sentences

1. **`Phaser.Game`** is the engine instance — it owns the canvas, the renderer, the scene manager, and the main loop, and it lives until the page unloads.
2. A **`Phaser.Scene`** is a contained unit of state and behavior with a lifecycle (`init` → `preload` → `create` → `update`); the game can run multiple scenes at the same time.
3. The **main loop** is a single-threaded `requestAnimationFrame`-driven tick that calls `update(time, delta)` on every active scene every frame.
4. **GameObjects** (sprites, text, containers, graphics, particles) live on a per-scene **display list** and are rendered each frame in depth order; cameras are the views into that display list.
5. Scenes communicate with each other through **events** (`scene.events`, `game.events`) and shared state (`registry`) — *not* by reaching into each other's internals.

If you understand those five things, you understand the engine. The rest is detail.

## What Phaser Is (and What It Isn't)

Phaser 3 is an **HTML5 game framework** that runs in the browser. Concretely:

- It draws to a single `<canvas>` element via either **WebGL** (default, hardware-accelerated) or **Canvas 2D** (fallback). The renderer is chosen at startup; you don't switch at runtime.
- It is **single-page, single-threaded JavaScript**. There is one event loop, one main thread, and one `requestAnimationFrame` driving everything.
- It is **browser-hosted**. Your game shares the page's CPU, memory, audio context, input system, and tab-visibility state. When the tab is backgrounded, `requestAnimationFrame` slows or stops.
- It is **statically served**. A Phaser game is HTML + JS + assets, deployable to any static host (Vercel, Netlify, itch.io, S3+CloudFront). There is no Phaser server.

Phaser is **not**:

- A 3D engine. Phaser 3 is 2D. (There is a `Phaser3D` plugin and Phaser 4 is a different conversation, but neither is in scope here.)
- A game *editor*. There is no Phaser equivalent of the Godot or Unity editor. You write code, place things by code or by importing data from external tools (Tiled, Texture Packer, Aseprite). This is a real ergonomic difference; budget for it.
- A managed runtime. There is no garbage collector tuning, no scene serialization format, no built-in save system, no built-in networking. You assemble these from JS/browser primitives.
- A native engine. It runs in the browser. You can wrap it in Electron / Capacitor / Cordova for "native" deployment, but the runtime is still a webview.

Knowing what Phaser *isn't* prevents the most common waste: trying to make it behave like Unity, fighting it because it doesn't have an editor, or assuming features that don't exist.

## The `Game` Instance

A Phaser app starts with one call:

```ts
import Phaser from 'phaser';

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  width: 1280,
  height: 720,
  parent: 'game-root',
  backgroundColor: '#0a0a0a',
  scene: [BootScene, PreloadScene, MenuScene, GameScene, HUDScene],
  physics: {
    default: 'arcade',
    arcade: { gravity: { y: 800 }, debug: false },
  },
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  fps: {
    target: 60,
    forceSetTimeOut: false,
  },
  audio: {
    disableWebAudio: false,
  },
};

new Phaser.Game(config);
```

A few things every Phaser engineer should know about this object up-front:

- **`type`** — `Phaser.AUTO` (try WebGL, fall back to Canvas), `Phaser.WEBGL`, or `Phaser.CANVAS`. Default to `AUTO`. WebGL is always faster on devices that can run it; Canvas is the safety net for low-end mobile and old Safari.
- **`width` / `height`** — the *internal* resolution, not the display size. Display size is governed by `scale`. Pick a logical resolution (often 1280×720 or 1920×1080 for desktop-first, 750×1334 or similar portrait for mobile-first) and treat it as the design canvas.
- **`parent`** — the DOM element ID (or element) the canvas is attached to. If omitted, Phaser appends to `<body>`. In a real app, you almost always want a specific div so you can size it and place it in a layout.
- **`scene`** — an array of scene *classes* (not instances). The first one is started automatically unless you mark it `active: false`. The rest are registered but inactive until you `start` / `launch` them. See [scenes-and-flow.md](scenes-and-flow.md) for what those mean.
- **`physics`** — declares which physics system is the default and configures it. You can have both Arcade and Matter loaded, but each scene picks one. See [physics-arcade.md](physics-arcade.md).
- **`scale`** — how the internal canvas is fit to the actual viewport. `FIT` (letterbox), `RESIZE` (fill, recompute layout), `ENVELOP` (fill, may crop), `NONE`. This decision is in the same family as "how does my game handle different screen sizes?" — answer it on day one.
- **`fps`** — `target` is the *physics/update* rate. The render rate follows `requestAnimationFrame` (almost always the display refresh: 60Hz, 120Hz, 144Hz). `forceSetTimeOut: true` falls back to `setTimeout`-driven loops when `requestAnimationFrame` is unavailable (rare).
- **`audio`** — `disableWebAudio: true` forces HTML5 audio (lower-quality but more compatible). Default is Web Audio. For mobile, expect to call `sound.unlock()` on first user gesture regardless.

Once `new Phaser.Game(config)` runs, the engine takes over: it creates the canvas, registers the scenes, starts the main loop, and starts the first active scene. **You do not call `update()` yourself.** The loop does.

The `Game` instance is reachable from any scene as `this.game`. Most things you'd want from the game (renderer, scale manager, sound manager, registry, scene manager) are on it, but you almost always go through scene-level shortcuts (`this.scale`, `this.sound`, `this.registry`, `this.scene`) instead.

## The `Scene` Lifecycle (High Level)

A scene is a TypeScript class that extends `Phaser.Scene`:

```ts
import Phaser from 'phaser';

export class GameScene extends Phaser.Scene {
  constructor() {
    super({ key: 'GameScene' });
  }

  init(data: { level: number }): void {
    // Pre-preload setup. Read data passed from scene.start().
  }

  preload(): void {
    // Queue asset loads. Loader runs after preload returns.
    this.load.image('player', 'assets/player.png');
  }

  create(): void {
    // World setup. Assets are now in cache.
    this.add.image(640, 360, 'player');
  }

  update(time: number, delta: number): void {
    // Per-frame logic. Hot path.
  }
}
```

The engine calls these in order:

1. **`init(data)`** — runs first, gets the data passed to `scene.start('GameScene', data)`. Use it to interpret arguments and set up scene-level fields. Don't load assets here.
2. **`preload()`** — runs once. Queue assets via `this.load.image(...)` etc. The Loader runs after `preload` returns; `create` waits for it.
3. **`create()`** — runs once, after the Loader finishes. The world is built here: instantiate game objects, set up colliders, wire input, kick off camera follow, register events.
4. **`update(time, delta)`** — runs every frame thereafter. `time` is the accumulated game time in ms; `delta` is ms since the previous frame. This is the hot path.

The full mechanics — scene-to-scene transitions, `start` vs `launch` vs `pause` vs `resume` vs `stop`, multi-scene patterns (HUD over GameScene), data passing, `init`/`preload`/`create` ordering across scenes, scene plugins — live in [scenes-and-flow.md](scenes-and-flow.md). This file just establishes the cycle.

The most common mistake here: **putting world setup in `preload`**. `preload` is for queuing loads. The cache isn't populated until *after* `preload` returns. Calling `this.add.image('player', ...)` inside `preload` will fail because the texture isn't loaded yet. World setup goes in `create`.

## The Render / Update Loop

Phaser's main loop is one `requestAnimationFrame` callback that ticks every active scene per frame. Per tick, in order:

1. **Input** is polled and dispatched (pointer events, keyboard, gamepad).
2. **Pre-update** runs on each scene's systems (physics integrate, etc.).
3. **`update(time, delta)`** is called on every active scene.
4. **Post-update** runs (camera follow, tween updates, sound updates).
5. **Render** — the renderer walks each active scene's display list and draws it through each camera.

Two timing values you will see constantly:

- **`time`** — `performance.now()`-style accumulated game time, in milliseconds. Useful for "is `time > nextSpawnAt`?" patterns.
- **`delta`** — milliseconds since the last frame. **Always multiply per-frame movement by `delta`** (or `delta / 1000` if you want seconds). Hard-coding `x += 5` per frame ties speed to framerate, which is wrong on a 144Hz monitor and wrong again on a slow phone.

```ts
update(time: number, delta: number): void {
  const dt = delta / 1000; // seconds
  this.player.x += this.playerVelocityX * dt;
}
```

Phaser also exposes the loop directly:

- **`this.game.loop.actualFps`** — the measured FPS, smoothed. Read this for in-game perf overlays.
- **`this.game.loop.targetFps`** — the configured target (default 60).
- **`this.game.loop.delta`** — same `delta` you get in `update`.

The loop is **single-threaded JavaScript**, sharing the main thread with everything else on the page (DOM events, fetch callbacks, postMessage from workers). Long-running synchronous JS will starve the loop and you'll see frame drops. The fix is not "make it async" — async still runs on the same thread. The fix is *don't do long-running work per frame.* Pool, cache, precompute, offload to a Web Worker if it's heavy enough to need its own thread.

The loop does **not** distinguish a "physics tick" from a "render tick" the way Godot or Unity do by default. Arcade physics steps inside the same `update` cycle. Matter has an internal fixed-step option. If you need hard determinism you build it on top — most Phaser games don't.

When the **tab is backgrounded**, browsers throttle `requestAnimationFrame` to ~1 Hz or stop it entirely. Phaser detects this via `Page Visibility API` and pauses scenes by default. On resume, `delta` for the first frame can be huge — your code needs to tolerate that, or you cap `delta` (`config.fps.smoothStep` or manual clamping).

## The Display List

Each scene has a **display list**: a flat-ish list of GameObjects that will be rendered this frame. A GameObject is anything Phaser can draw or manage as a positioned thing in the world: `Sprite`, `Image`, `Text`, `BitmapText`, `Graphics`, `TileSprite`, `Container`, `ParticleEmitter`, `RenderTexture`, `Video`, `Mesh`, etc.

The most-used base types:

| Type | Purpose |
|---|---|
| `Image` | Static sprite, no animation frames. |
| `Sprite` | Image that can play `Animation` clips from the `AnimationManager`. |
| `Text` | DOM-style text rendered to a texture (heavy on changes; cache it). |
| `BitmapText` / `DynamicBitmapText` | Bitmap-font text. Cheap. Use this for HUD numbers that change every frame. |
| `Graphics` | Procedural shapes — rects, lines, arcs, paths. Expensive to redraw every frame; consider `generateTexture()`. |
| `Container` | Composite GameObject. Children move/rotate/scale with the parent. The Phaser equivalent of "group these into a unit." |
| `Group` | Logical group (not a transform parent). Used for pooling, batched physics, batched logic. |
| `TileSprite` | Tiled/repeated texture. Good for parallax backgrounds. |
| `ParticleEmitter` | Particle system. Cheap because GPU-instanced under WebGL. |

A GameObject has:

- A **position** (`x`, `y`) and rotation/scale.
- A **depth** (`setDepth(n)`); higher renders on top.
- A **scrollFactor** (how much the camera scrolls past it; 0 = HUD, 1 = world).
- An **alpha**, **tint**, **blendMode**, **visible**.
- An **origin** (anchor point; 0,0 = top-left, 0.5,0.5 = center — the default).
- Optional **physics body** (added by `this.physics.add.existing(obj)` or by creating via `this.physics.add.sprite(...)`).
- Optional **input** (`obj.setInteractive()`).
- A **scene** reference (`obj.scene`).

**Render order** within a scene is by `depth`, then by insertion order for ties. Across scenes, the **scene order in `game.config.scene`** plus what's been started/launched determines which scene draws on top. A common pattern: `GameScene` runs the world; `HUDScene` is `launch`ed on top with `scene.bringToTop()` to ensure it renders above.

The **world coordinate system** is implicit: GameObjects have world `(x, y)` in pixels, with `+x` right and `+y` *down* (like the DOM, *unlike* most math conventions). The world is unbounded by default; the camera defines what the player sees.

A **Camera** is a view into the display list. Each scene has `this.cameras.main` by default, sized to the game's logical resolution. Cameras can be moved, rotated, zoomed, faded, shaken, made to follow a target, and constrained to bounds. You can have multiple cameras in one scene (split-screen, minimap). Cameras are *views*, not transforms applied to the world — moving the camera does not move the GameObjects.

```ts
this.cameras.main.startFollow(this.player, true, 0.1, 0.1);
this.cameras.main.setBounds(0, 0, levelWidth, levelHeight);
this.cameras.main.setZoom(2);
```

## The Loader and the Cache

Asset loading is centralized in `this.load`. Inside `preload()` (or any time you want to load more assets later), you queue requests:

```ts
preload(): void {
  this.load.image('player', 'assets/player.png');
  this.load.spritesheet('explosion', 'assets/explosion.png', { frameWidth: 64, frameHeight: 64 });
  this.load.atlas('characters', 'assets/characters.png', 'assets/characters.json');
  this.load.audio('music-main', ['assets/audio/main.ogg', 'assets/audio/main.mp3']);
  this.load.tilemapTiledJSON('level1', 'assets/levels/level1.json');
  this.load.json('config', 'assets/config.json');
  this.load.bitmapFont('hud-font', 'assets/fonts/hud.png', 'assets/fonts/hud.xml');
}
```

A few things every Phaser engineer should know about the Loader:

- **Asset keys are global per cache.** `'player'` lives in the texture cache forever (well, until `this.textures.remove('player')`). Loading `'player'` a second time silently no-ops if the key already exists. This is why scene restarts don't re-trigger loads — and why a typo in a key creates a hard-to-find bug.
- **Caches are per-asset-type.** Textures, audio, JSON, bitmap fonts, tilemaps each have their own cache (`this.textures`, `this.cache.audio`, `this.cache.json`, etc.). Querying `this.textures.exists('foo')` is the safe way to check before loading.
- **Multi-format audio fallback.** Pass an array of URLs; Phaser picks the first format the browser supports. Always provide at least `.ogg` + `.mp3` (or `.m4a`) for cross-browser coverage.
- **Asset packs** — `this.load.pack('config-pack', 'assets/pack.json')` loads a JSON file that itself describes a list of files to load. Useful for organizing per-scene asset manifests outside of code.
- **Async progress** — the Loader is event-driven. Listen on `this.load.on('progress', ...)` and `this.load.on('complete', ...)` to drive progress bars in a Boot/Preload scene. This is how you build a real loading screen instead of a frozen white canvas.
- **Dynamic loads after `create()`** — call `this.load.image(...)` later and then `this.load.start()`. Useful for streaming levels or DLC-style content.
- **CORS matters.** If you load assets from a different origin (CDN), the server must send the right CORS headers, especially for textures used by WebGL. Same-origin is the easy path; cross-origin requires server-side configuration.

The Loader is one of Phaser's strongest systems. Don't roll your own; the things you'd reinvent (progress, retry, format fallback, cache dedup, parallel fetches with concurrency control) are already there.

## The Systems Exposed on a Scene

A `Phaser.Scene` is a façade over the engine's systems. Inside any scene method, `this.<system>` is your entry point:

| Property | What it is |
|---|---|
| `this.add` | The **GameObject factory**. `this.add.sprite(...)`, `this.add.text(...)`, `this.add.container(...)`. Creates and adds to the display list. |
| `this.physics` | The active **physics system** for this scene (Arcade by default). `this.physics.add.sprite`, `this.physics.add.collider`, `this.physics.world`. |
| `this.tweens` | The **TweenManager**. `this.tweens.add({ targets, x, duration, ease })`. Scene-scoped — tweens are killed when the scene shuts down. |
| `this.anims` | The **AnimationManager**. *Global*, not per-scene — animations defined here are visible to all scenes. Define once, reuse everywhere. |
| `this.input` | The **InputPlugin**. `this.input.keyboard`, `this.input.gamepad`, `this.input.on('pointerdown', ...)`. Input is per-scene; multiple scenes can each receive input. |
| `this.cameras` | The **CameraManager**. `this.cameras.main`, `this.cameras.add(...)`. |
| `this.sound` | The **SoundManager**. `this.sound.add('music')`, `this.sound.play(...)`. *Global* — `this.sound` proxies the game-wide sound manager. |
| `this.scene` | The **ScenePlugin**: scene-manager controls. `this.scene.start('Other')`, `this.scene.launch('HUD')`, `this.scene.pause()`, `this.scene.get('Other')`. |
| `this.events` | A **per-scene event emitter**. Use this for *intra-scene* communication. Cleared on shutdown. |
| `this.game.events` | A **game-wide event emitter** on the `Game` instance. Use sparingly for cross-scene events. |
| `this.registry` | A **game-wide key/value store** (`Phaser.Data.DataManager`). Persists across scene changes. Useful for a small amount of shared state (player name, score, settings). Easy to abuse — see [phaser-anti-patterns.md](phaser-anti-patterns.md). |
| `this.data` | A **per-scene** data manager. Less commonly used; mostly a convenience over scene fields. |
| `this.time` | The **Clock**. Schedule one-shot or repeating callbacks: `this.time.delayedCall(1000, fn)`, `this.time.addEvent({ delay, callback, loop })`. Pauses with the scene. |
| `this.lights` | The **LightsPlugin** (WebGL only). Normal-mapped 2D lighting. Niche; powerful when you need it. |
| `this.textures` | The **texture cache** (game-wide). Useful for `generateTexture` from a `Graphics` object, or runtime atlas manipulation. |
| `this.cache` | The **non-texture caches** (audio, JSON, bitmap fonts, tilemaps, XML). |

Two things on this table that bite people:

1. **`this.anims` and `this.sound` are game-global, not per-scene.** Define an animation in one scene and it's available in all scenes. Add a sound in one scene and it survives scene changes (which is usually what you want for music; usually *not* what you want for SFX — destroy SFX sounds on scene shutdown).
2. **`this.events` is per-scene; `this.game.events` is game-wide.** Mix these up and you'll either leak listeners across scene restarts (`game.events` listener registered in `create`, never removed in `shutdown`) or wonder why your "global" event isn't reaching a sibling scene (you used `this.events`).

Cleanup on scene shutdown is critical and is covered in [scenes-and-flow.md](scenes-and-flow.md) and [phaser-anti-patterns.md](phaser-anti-patterns.md). The short version: every listener you add on `this.game.events` or external sources (DOM, `window`) needs a matching removal in the scene's `shutdown` event.

## Plugins (Brief)

Phaser's plugin system lets you add behavior to a scene or the whole game. There are **scene plugins** (mounted on `this.<key>` in every scene) and **global plugins** (mounted on `this.game.<key>`). Most projects don't write custom plugins; you consume third-party ones (e.g. `phaser3-rex-plugins` for UI components, `phaser-matter-collision-plugin` for nicer Matter collision events). Add via the `plugins` config in `GameConfig`. If you find yourself reaching for a plugin, prefer one that's actively maintained and has TS types — the alternative is reinventing it yourself, which is sometimes the right call. Plugin design isn't covered further here.

## TypeScript Integration (Brief)

Phaser ships with first-class TypeScript types bundled in the `phaser` package itself (`phaser/types/phaser`) — do not install `@types/phaser`, which is stale and conflicts with the bundled types. The basics:

```ts
import Phaser from 'phaser';

interface GameSceneData {
  level: number;
  difficulty: 'easy' | 'normal' | 'hard';
}

export class GameScene extends Phaser.Scene {
  private player!: Phaser.Physics.Arcade.Sprite;
  private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;

  constructor() {
    super({ key: 'GameScene' });
  }

  init(data: GameSceneData): void {
    // data is now typed — typos caught at compile time.
  }

  create(): void {
    this.player = this.physics.add.sprite(100, 100, 'player');
    this.cursors = this.input.keyboard!.createCursorKeys();
  }
}
```

The `any`-leak hot spots — `this.add.sprite(...).body`, `Container` children, scene `data`, registry values, event payloads — and the TS-friendly patterns for typing each are catalogued in [phaser-anti-patterns.md](phaser-anti-patterns.md). For now: lean into types, treat compile errors as the cheap signal they are, and avoid `as any` anywhere it's tempting.

## Common Mistakes Coming In

A few things that trip up new Phaser engineers, especially those coming from Unity, Godot, or "just plain JS":

- **One giant `GameScene`.** Everything in one class, 3,000 lines, every entity. Split early, use `launch` for HUD/UI scenes, extract systems into plain TS classes the scene composes.
- **Calling `add.image` in `preload`.** Assets aren't loaded yet. World setup is `create`'s job.
- **Hard-coded movement (`x += 5` per frame).** Tied to framerate. Multiply by `delta`.
- **Allocations in `update`.** `new Phaser.Math.Vector2(...)`, `[].map(...)` over thousands of entities, string concatenation that produces garbage. The hot path needs to be allocation-free or pooled.
- **Not handling audio unlock.** First load works on desktop, fails silently on mobile until first tap. Handle `sound.unlock()` (or `sound.context.resume()` for Web Audio) on first user gesture.
- **Reaching across scenes.** `this.scene.get('Other').someField` couples scenes hard. Use events, the registry, or a passed-in reference.
- **Listeners that outlive the scene.** Adding to `this.game.events` or `window` in `create`, never removing in `shutdown`. Comes back as ghost callbacks on the next scene restart.
- **Custom animation/tween/loader.** Phaser has `AnimationManager`, `Tween`, and `Loader` for a reason. Use them. The custom version will be slower, buggier, and harder to maintain.
- **Treating the registry as a global object.** A few well-typed keys: fine. Dozens of arbitrary fields: god-singleton, just like an autoload abuse in Godot.
- **Ignoring scale and DPI.** Game looks fine on a 1080p monitor, blurry on a 4K display, broken on a phone. Decide your `scale` mode and design canvas on day one.

The rest of this skill's references go deep on each of these. Start with this file as the mental model, then read the references that match what you're doing today.

## Related

- [scenes-and-flow.md](scenes-and-flow.md) — scene lifecycle in depth, scene manager, multi-scene patterns
- [project-and-vite.md](project-and-vite.md) — Vite + TypeScript scaffold, asset pipeline, dev server, prod build
- [physics-arcade.md](physics-arcade.md) — Arcade physics in depth: bodies, groups, collisions, gotchas
- [phaser-anti-patterns.md](phaser-anti-patterns.md) — what not to do, with the TS-specific traps called out
- [SKILL](../SKILL.md) — the parent skill and its universal rules
