# Phaser Anti-Patterns

A catalog of common Phaser 3 + TypeScript mistakes. The point of naming them is recognition: when your code starts to look like one of these, you should be able to spot it, name it, and route around it.

This is the cross-cutting catalog. Subsystem-specific gotchas live in their own reference files; pointers at the bottom. Each entry has the same shape: **what it looks like**, **why it's bad**, **what to do instead**. Code is TypeScript and assumes Phaser 3.x.

## Architecture

### 1. The God Scene

**Looks like:**

```ts
export class GameScene extends Phaser.Scene {
  // 60+ fields: player, enemies, bullets, hud, pause menu,
  // inventory, dialogue, achievements, audio, save system...

  create() {
    this.setupPlayer();
    this.setupEnemies();
    this.setupHUD();
    this.setupInventory();
    this.setupDialogue();
    // ...500 more lines of wiring
  }

  update(time: number, delta: number) {
    // 800-line update method. Scrolling required.
  }
}
```

**Why it's bad:** every change touches the same file. Two engineers can't work on it without merge conflicts. Every system has implicit dependencies on every other system because they all read the same `this.*` fields. Removing or replacing any one piece is impossible.

**Do instead:** the scene is the orchestrator, not the implementation. Each system is a plain TypeScript class the scene composes. Independent surfaces (HUD, pause menu) become parallel scenes.

```ts
export class GameScene extends Phaser.Scene {
  private combat!: CombatSystem;
  private spawner!: EnemySpawner;
  private input!: PlayerInputController;

  create() {
    this.combat = new CombatSystem(this);
    this.spawner = new EnemySpawner(this);
    this.input = new PlayerInputController(this);
    this.scene.launch('HudScene'); // parallel scene
  }

  update(time: number, delta: number) {
    this.input.update(delta);
    this.combat.update(delta);
    this.spawner.update(time);
  }
}
```

A scene over ~600 lines is a smell. Over 1,000 is a refactor.

### 2. Cross-scene reach-in

**Looks like:**

```ts
// HudScene.update():
const game = this.scene.get('GameScene') as GameScene;
this.scoreLabel.setText(`Score: ${game.player.score}`);

// PauseScene:
this.scene.get('GameScene').player.health = 0;
```

**Why it's bad:** every reach-in couples the two scenes. Renaming a field in `GameScene` silently breaks `HudScene`. Ownership of the data becomes ambiguous. Worst case, the consumer mutates state on a scene mid-shutdown and you get a confusing crash.

**Do instead:** push events through `this.events`, `this.game.events`, or `this.registry`. The HUD listens; gameplay broadcasts.

```ts
// GameScene:
this.registry.set('score', newScore);

// HudScene:
this.registry.events.on('changedata-score', (_p: unknown, value: number) => {
  this.scoreLabel.setText(`Score: ${value}`);
});
```

The one acceptable read-only pattern is a HUD reading the registry for display. The HUD never *writes* gameplay state.

### 3. Registry as a god object

**Looks like:**

```ts
// scattered across 30 files:
this.registry.set('player_x', this.player.x);
this.registry.set('player_anim', 'walk_left');
this.registry.set('enemy_count', this.enemies.getLength());
this.registry.set('inventory_slot_3', 'health_potion');
// ... 50 more keys, used inconsistently
```

**Why it's bad:** the registry was meant for a small set of cross-scene values (score, settings, current level). As a dumping ground, no one knows what lives there or who owns it. `registry.get('player_x')` returns `unknown`. Two systems writing the same key collide silently.

**Do instead:** define the small list of keys that are genuinely cross-scene state. Type them. Keep system-internal state inside the system.

```ts
export const RegistryKey = {
  Score: 'score',
  Lives: 'lives',
  HighScore: 'highScore',
  Settings: 'settings',
} as const;

this.registry.set(RegistryKey.Score, 0);
const score = this.registry.get(RegistryKey.Score) as number;
```

"Current player position" lives on the player. Not in the registry.

### 4. `any` for scene `data` payloads

**Looks like:**

```ts
export class LevelScene extends Phaser.Scene {
  init(data: any) {
    this.level = data.level;
    this.difficulty = data.diff; // typo? no one will know.
  }
}

this.scene.start('LevelScene', { level: 3, difficutly: 'hard' });
//                                          ^ typo, silently undefined
```

**Why it's bad:** `init`/`create` data flow through `any`, so typos go unnoticed and field renames don't propagate. The two ends of the contract drift. Half the bugs in scene transitions are silent typos in payload keys.

**Do instead:** type both ends.

```ts
export interface LevelInitData {
  level: number;
  difficulty: 'easy' | 'normal' | 'hard';
}

export class LevelScene extends Phaser.Scene {
  init(data: LevelInitData) {
    this.level = data.level;
    this.difficulty = data.difficulty;
  }
}

// compile error on typo:
this.scene.start('LevelScene', { level: 3, difficulty: 'hard' } satisfies LevelInitData);
```

### 5. Scene `key` typos

**Looks like:**

```ts
this.scene.start('GameSene'); // typo. silent failure.
this.scene.launch('HUD');     // capitalization mismatch with registered 'Hud'.
```

**Why it's bad:** scene keys are strings sprinkled across the codebase. Phaser doesn't error on `start('GameSene')` — it just doesn't start anything. You find out from playtesters.

**Do instead:** a single source of truth. Use it everywhere.

```ts
export const SceneKey = {
  Boot: 'BootScene',
  Preload: 'PreloadScene',
  Game: 'GameScene',
  Hud: 'HudScene',
} as const;

export class GameScene extends Phaser.Scene {
  constructor() { super(SceneKey.Game); }
}

this.scene.start(SceneKey.Game); // typo is now a TS error
```

## The Hot Path: `update()` and the Frame Budget

### 6. Allocations in `update()`

**Looks like:**

```ts
update(time: number, delta: number) {
  const target = new Phaser.Math.Vector2(this.player.x, this.player.y);
  this.scoreLabel.setText('Score: ' + this.score + ' | Combo: ' + this.combo);
  this.enemies.forEach(e => {
    const v = new Phaser.Math.Vector2(e.x - target.x, e.y - target.y);
    e.setVelocity(v.x, v.y);
  });
}
```

**Why it's bad:** every `new`, every `.forEach` closure, every string concat allocates. At 60 FPS that's 60 allocations per line per second per object. GC runs mid-gameplay; you get a 30 ms hitch. On mobile, worse.

**Do instead:** pre-allocate, mutate, reuse. Pool short-lived game objects. Use `BitmapText` for frequently-updated HUD text.

```ts
private readonly _tmpVec = new Phaser.Math.Vector2();

update(time: number, delta: number) {
  this._tmpVec.set(this.player.x, this.player.y);

  // typed loop, no closure allocation
  const list = this.enemies.getChildren();
  for (let i = 0; i < list.length; i++) {
    const e = list[i] as EnemySprite;
    e.setVelocity(e.x - this._tmpVec.x, e.y - this._tmpVec.y);
  }
}
```

Treat `update()` like a tight inner loop. Because it is one.

### 7. Per-frame text mutation with `Text` instead of `BitmapText`

**Looks like:**

```ts
this.fps = this.add.text(8, 8, '', { fontSize: '16px' });

update() {
  this.fps.setText(`FPS: ${Math.round(this.game.loop.actualFps)}`);
}
```

**Why it's bad:** `Phaser.GameObjects.Text` re-renders to an internal canvas every time the string changes. That's a draw call's worth of work plus garbage every frame for a tiny FPS readout. Multiply across score, combo, timer, ammo, and you've burned the frame budget on text.

**Do instead:** `BitmapText` reads from a pre-rendered glyph atlas; mutation is essentially free.

```ts
// PreloadScene:
this.load.bitmapFont('hud', 'fonts/hud.png', 'fonts/hud.xml');

// HudScene:
this.fps = this.add.bitmapText(8, 8, 'hud', '', 16);
update() {
  this.fps.setText(`FPS: ${Math.round(this.game.loop.actualFps)}`);
}
```

`Text` is fine for static UI (titles, menu items, dialogue that changes once per beat). For per-frame, use `BitmapText`.

## Lifecycle: Listeners, Tweens, and Timers

### 8. Listener leaks across scene restart

**Looks like:**

```ts
create() {
  this.events.on('player-died', this.onPlayerDied, this);
  this.game.events.on('focus', this.onFocus, this);
}

onRestart() {
  this.scene.restart();
}
```

**Why it's bad:** `scene.restart()` runs `create()` again, registering the same listeners again. After 5 deaths, `onPlayerDied` fires 5 times. `onFocus` is *permanently* leaked — the global game event bus survives the scene and nothing cleans it up.

**Do instead:** clean up in `shutdown`. For one-shot listeners, use `once`.

```ts
create() {
  this.events.on('player-died', this.onPlayerDied, this);
  // Game-bus outlives the scene; remove explicitly.
  this.game.events.on('focus', this.onFocus, this);

  this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
    this.game.events.off('focus', this.onFocus, this);
  });
}
```

Rule: any listener attached to a target that *outlives* the scene (`game.events`, `registry.events`) must be removed on `SHUTDOWN`. Per-scene listeners (`this.events`, `this.input`) are cleaned for you.

### 9. Tween and timer leaks

**Looks like:**

```ts
// Plain JS object as the tween target — survives the scene
const flashState = { alpha: 0 };
this.tweens.add({ targets: flashState, alpha: 1, duration: 500, repeat: -1 });
```

**Why it's bad:** if the tween's target isn't a scene-managed `GameObject`, the tween manager has nothing to clean up against and the tween runs forever. Worst case, a tween on a destroyed object throws on the next tick.

**Do instead:** prefer scene-managed targets. If you need to tween a plain object, track and stop it in `shutdown`.

```ts
private flashTween?: Phaser.Tweens.Tween;
private flashState = { alpha: 0 };

create() {
  this.flashTween = this.tweens.add({
    targets: this.flashState, alpha: 1, duration: 500, repeat: -1,
  });
  this.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
    this.flashTween?.stop();
  });
}
```

If a tween or timer might survive the scene, it will. Stop it explicitly.

## Loader and Audio

### 10. Audio without unlock

**Looks like:**

```ts
// MenuScene.create():
this.sound.play('title-music', { loop: true });
// nothing plays. engineer suspects asset is broken.
```

**Why it's bad:** every modern browser blocks audio until the page receives a user gesture. Phaser's `WebAudioSound` honors that. Calling `play` before any input does nothing — no error, just silence.

**Do instead:** start audio after the first input.

```ts
create() {
  this.input.once('pointerdown', () => {
    this.sound.play('title-music', { loop: true });
  });

  // or listen for the unlock event:
  this.sound.once(Phaser.Sound.Events.UNLOCKED, () => {
    this.sound.play('title-music', { loop: true });
  });
}
```

Plan for this from day one. What plays on your laptop after a reload click will not play on a freshly opened phone.

### 11. Re-loading assets on scene restart

**Looks like:**

```ts
export class GameScene extends Phaser.Scene {
  preload() {
    this.load.image('player', 'assets/player.png');
    this.load.audio('hit', 'assets/hit.wav');
    // ...20 more loads
  }

  onPlayerDeath() { this.scene.restart(); } // re-runs preload
}
```

**Why it's bad:** the Loader is smart enough to skip already-cached assets, so this isn't catastrophic on its own. But it's a habit that scales badly. Once you set a `setBaseURL`, switch to asset packs, or load assets conditionally, the duplicated load code becomes a source of subtle bugs (wrong base URL, race with the cache, double-decoded audio).

**Do instead:** load once in a dedicated `PreloadScene` at boot. Gameplay scenes assume their assets exist.

```ts
export class PreloadScene extends Phaser.Scene {
  constructor() { super(SceneKey.Preload); }
  preload() { this.load.pack('main-pack', 'assets/asset-pack.json'); }
  create() { this.scene.start(SceneKey.Menu); }
}

export class GameScene extends Phaser.Scene {
  // no preload(); assets guaranteed loaded.
  create() { this.add.image(0, 0, 'player'); }
}
```

Restart re-runs `create`, not `preload`, when there's nothing to preload. Faster, safer, asset-pack-ready.

## Physics

### 12. `setScale` then `setSize`/`setOffset` in the wrong order

**Looks like:**

```ts
const player = this.physics.add.sprite(100, 100, 'player');
player.body.setSize(20, 28);
player.body.setOffset(6, 4);
player.setScale(2); // body geometry now invalidated
```

**Why it's bad:** Arcade body dimensions are computed from the texture's pixel size. `setScale` changes the body's computed extents, but `setSize`/`setOffset` were applied against the unscaled texture. The body ends up visibly offset from the sprite; collisions feel wrong.

**Do instead:** scale first, then size the body.

```ts
const player = this.physics.add.sprite(100, 100, 'player');
player.setScale(2);
player.body.setSize(20, 28);   // values in unscaled texture pixels;
player.body.setOffset(6, 4);   // Arcade applies the scale internally
```

See [physics-arcade.md](physics-arcade.md) for the full body-geometry rules.

### 13. Direct write to `body.x`

**Looks like:**

```ts
this.player.body.x = 500;
this.player.body.y = 300;
```

**Why it's bad:** the Arcade body is *driven by* the GameObject in the physics step, not the other way around. Writing `body.x` puts them out of sync until the next step — visual lag, mid-frame collisions against stale positions, tunneling.

**Do instead:** move the GameObject. The body follows on the next step.

```ts
this.player.setPosition(500, 300);
```

To teleport without dragging old velocity:

```ts
this.player.setPosition(500, 300);
this.player.body.reset(500, 300); // clears velocity and resyncs
```

### 14. Polling `body.touching.down` for "is grounded?"

**Looks like:**

```ts
update() {
  if (this.jumpKey.isDown && this.player.body.touching.down) {
    this.player.setVelocityY(-400);
  }
}
```

**Why it's bad:** `body.touching.down` is true *only on the frame the body is touching the ground*. If input runs before the physics step on a given frame, you miss the touching state and the jump doesn't fire. It also misses coyote-time jumps (the grace window after walking off a ledge) every platformer expects.

**Do instead:** track grounded via collider callback, then add coyote-time.

```ts
private coyoteMs = 0;
private static readonly COYOTE_WINDOW = 100;

create() {
  this.physics.add.collider(this.player, this.platforms, () => {
    if (this.player.body!.blocked.down) {
      this.coyoteMs = LevelScene.COYOTE_WINDOW;
    }
  });
}

update(_time: number, delta: number) {
  this.coyoteMs = Math.max(0, this.coyoteMs - delta);
  if (Phaser.Input.Keyboard.JustDown(this.jumpKey) && this.coyoteMs > 0) {
    this.player.setVelocityY(-400);
    this.coyoteMs = 0;
  }
}
```

Same pattern for "just landed" — fire on the callback transition, not by polling.

### 15. Tunneling through one-tile-thick walls

**Looks like:**

```ts
const wallsLayer = map.createLayer('Walls', tileset);
wallsLayer.setCollisionByProperty({ collides: true });
this.physics.add.collider(this.bullet, wallsLayer);
// fast bullet sometimes passes through a 1-tile wall
```

**Why it's bad:** Arcade physics is discrete. A body moving more than one tile per step against a one-tile-thick wall can teleport through without ever overlapping the tile.

**Do instead:** combine (a) thicker walls, (b) capped velocity, (c) higher physics step rate, (d) higher tile bias. (a) and (b) are usually enough.

```ts
this.bullet.body.setMaxVelocity(800, 800);
this.physics.world.TILE_BIAS = 32; // default 16; raise for fast bodies
```

For hitscan-fast bodies (lasers), Arcade is the wrong tool — raycast or use Matter. See [physics-arcade.md](physics-arcade.md).

## Build and Configuration

### 16. Missing `parent` in Game config

**Looks like:**

```ts
new Phaser.Game({
  type: Phaser.AUTO,
  width: 1280,
  height: 720,
  scene: [BootScene, GameScene],
});
// canvas gets appended to <body>, breaking page layout
```

**Why it's bad:** without `parent`, Phaser appends the canvas to `document.body`. The canvas lands on top of or below your headers and sidebars. On a Vite + React app, the canvas appears outside the React tree, and React reconciliation occasionally collides with it.

**Do instead:** explicit `parent` matching an element in `index.html`.

```html
<div id="game-container"></div>
```

```ts
new Phaser.Game({
  type: Phaser.AUTO,
  parent: 'game-container',
  width: 1280,
  height: 720,
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
  scene: [BootScene, GameScene],
});
```

If `'game-container'` doesn't exist at boot, you get a clear error instead of a silent layout bug.

### 17. Phaser bundle bloat

**Looks like:**

```ts
import Phaser from 'phaser';
// 1.4 MB (compressed) of Phaser shipped to a 5-screen mobile-web game
```

**Why it's bad:** Phaser is one large bundle and does not tree-shake well. The full library brings in Arcade *and* Matter, the entire loader, every GameObject type, every plugin.

**Do instead:** for most projects, accept it — Phaser's footprint is the cost of using Phaser, and splitting won't recover much. When bundle size genuinely matters (ad units, embedded widgets), use `phaser-core` and explicitly include the plugins you need.

```ts
// vite.config.ts
export default defineConfig({
  resolve: { alias: { phaser: 'phaser/dist/phaser-core.js' } },
});
```

Verify with a bundle analyzer. If the savings aren't material (>30%), revert and stop optimizing.

## Related

Each subsystem reference has its own anti-patterns section with deeper, topic-specific gotchas. This file is the cross-cutting catalog.

- [phaser-fundamentals.md](phaser-fundamentals.md) — engine model, the loop, the loader, registry semantics
- [project-and-vite.md](project-and-vite.md) — Game config, `parent`, scale modes, build setup
- [scenes-and-flow.md](scenes-and-flow.md) — scene lifecycle, parallel scenes, init/data typing, shutdown rules
- [physics-arcade.md](physics-arcade.md) — body offsets, tile bias, fast-body tunneling, collider callbacks
- software-design — the cross-cutting design principles these patterns instantiate
