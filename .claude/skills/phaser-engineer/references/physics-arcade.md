# Arcade Physics

Phaser 3 ships two physics engines. Arcade is the default — fast, AABB-only (axis-aligned bounding boxes), and good enough for the overwhelming majority of 2D games. Matter is the heavyweight option — full rigid-body simulation with rotation, joints, constraints, and slopes — and you should reach for it only when you've identified a specific need Arcade can't meet.

This file is about Arcade. It covers bodies, body shapes, velocities, gravity, groups, collisions vs. overlaps, world bounds, tile collision, the body-vs-GameObject position trap, debug rendering, the variable timestep, and the gotchas that bite every Phaser project.

## Arcade vs Matter — the decision

Pick **Arcade** when:

- Collisions are between rectangles or circles — platformer player vs. tiles, top-down character vs. walls, bullet vs. enemy, classic arcade-style games.
- Rotation does not matter for collision response. (You can still spin a sprite visually; the body stays AABB.)
- You need many bodies cheaply — bullet hells, particle-like swarms, large groups of enemies.
- Determinism across machines is *not* a hard requirement.

Pick **Matter** when:

- Sprites need to rotate *as part of the collision* — boxes that tumble, ragdolls, vehicles that flip.
- You need joints, constraints, springs, motors, or pinned objects.
- You need slopes that work correctly without manual tile tricks.
- You want stacking dynamics (boxes that pile up and settle).

**Default to Arcade.** Switching from Arcade to Matter mid-project is a substantial rewrite — different API, different semantics, different debug tools. If the design ever needed Matter, you'd already know. Don't pre-emptively pick Matter "just in case." Arcade carries ~80% of Phaser games to ship; the rest is a deliberate choice.

The rest of this file assumes Arcade. The Matter deep dive is out of scope for v1.

## Enabling Arcade physics

In the game config:

```ts
import Phaser from 'phaser';

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  width: 800,
  height: 600,
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { x: 0, y: 600 },
      debug: false,
    },
  },
  scene: [GameScene],
};

new Phaser.Game(config);
```

A scene that runs in this game has access to `this.physics` — the `Phaser.Physics.Arcade.ArcadePhysics` plugin. Use it to spawn bodies, register colliders, set world bounds, and so on:

```ts
class GameScene extends Phaser.Scene {
  create() {
    const player = this.physics.add.sprite(100, 100, 'player');
    // this.physics.add.sprite() = Sprite + dynamic Arcade body
  }
}
```

If a scene shouldn't have physics (a pure menu, a HUD overlay), it doesn't get one — physics is enabled per-scene by setting `physics` in the scene's config or by using `this.physics`. The plugin only spins up if used.

## Bodies — dynamic vs static

Every Arcade body is one of two kinds:

| Kind | Moves? | Pushed by collisions? | Use for |
|---|---|---|---|
| **Dynamic** | Yes (velocity, gravity) | Yes | Player, enemies, projectiles, anything that moves |
| **Static** | No | No (immovable) | Walls, floors, platforms, anything fixed |

Three ways to create a body:

```ts
// 1. Sprite with a dynamic body — most common
const player = this.physics.add.sprite(100, 100, 'player');

// 2. Image with a dynamic body
const ball = this.physics.add.image(200, 200, 'ball');

// 3. Attach a body to an existing GameObject
const npc = this.add.sprite(300, 300, 'npc');
this.physics.add.existing(npc); // dynamic by default
this.physics.add.existing(npc, true); // true = static body
```

A dynamic body has `velocity`, `acceleration`, `drag`, `gravity`, `bounce`, `mass`, etc. A static body has none of that — it just sits there and other bodies collide with it.

Useful flags on a dynamic body:

```ts
const body = player.body as Phaser.Physics.Arcade.Body;

body.setImmovable(true);     // dynamic, but won't be pushed (e.g., moving platform)
body.setAllowGravity(false); // ignore the world's gravity (floating enemy, UI prop in physics world)
body.setAllowRotation(false);// don't rotate the visual when angularVelocity changes
body.setBounce(0.5, 0.8);    // x/y restitution on collision
body.setDrag(200, 0);        // velocity damping per second
```

`setImmovable(true)` is the difference between "this dynamic body responds to collisions normally" and "this dynamic body acts like a wall to other bodies but you can still move it programmatically." Moving platforms are the canonical use case: dynamic (so you can `setVelocity` it on a path) but immovable (so the player doesn't shove it sideways when they land on it).

## Body shape — `setSize` and `setOffset`

By default, the physics body is the size of the sprite's texture frame. That is almost never what you want for a character — your texture is usually larger than the visible character (idle frames have headroom, attack frames bulge, etc.).

`body.setSize(width, height)` changes the body dimensions. `body.setOffset(x, y)` shifts the body relative to the texture's top-left:

```ts
// Texture frame is 64x64. The visible character is 24x40, sitting roughly
// centered horizontally with feet near the bottom of the frame.
const player = this.physics.add.sprite(100, 100, 'player');
player.body.setSize(24, 40);
player.body.setOffset(20, 24);
```

Two important rules:

1. **Call `setSize` and `setOffset` AFTER `setScale`.** Scaling re-derives the body dimensions from the texture, blowing away your offset. Order: spawn, scale, then size/offset.
2. **Test with debug rendering on.** Set `physics.arcade.debug: true` in the game config (or toggle `this.physics.world.drawDebug = true` at runtime) and you'll see the body outline overlaid on the sprite. The body is what collides; the texture is decoration.

Sprites with multiple animation frames of different sizes are still a single, fixed body — Arcade does not animate the body. Pick a body that fits the *gameplay* silhouette (usually slightly smaller than the most generous frame) and let the texture be visually generous.

## Velocity, acceleration, drag, max velocity

The four levers that produce "feels right" character movement:

```ts
const body = player.body as Phaser.Physics.Arcade.Body;
const cursors = this.input.keyboard!.createCursorKeys();
const ACCEL = 600;
const MAX_VX = 200;
const DRAG = 800;

body.setMaxVelocity(MAX_VX, 600);
body.setDragX(DRAG);

// in update():
if (cursors.left.isDown) {
  body.setAccelerationX(-ACCEL);
} else if (cursors.right.isDown) {
  body.setAccelerationX(ACCEL);
} else {
  body.setAccelerationX(0); // drag will pull velocity toward 0
}
```

The pattern: **input adds acceleration, drag decelerates when input stops, max velocity caps the top end.** This produces movement that feels weighty and predictable — the player doesn't snap from 0 to full speed, and they coast slightly when they release the key.

The naive alternative — `body.setVelocity(direction * SPEED)` directly — works fine for arcade-feel games (Asteroids-style instant turning), but most modern games expect some easing. Pick the pattern that matches the design.

A subtler note: **Arcade integrates velocity into position using the engine's delta — you do not multiply velocity by delta yourself**. `setVelocity(200, 0)` means "200 pixels per second." The engine handles the per-frame math.

## Gravity

Three places gravity comes from, in increasing specificity:

1. **World gravity** — set in the game config (`physics.arcade.gravity`). Applies to every dynamic body that hasn't opted out.
2. **Per-body gravity** — `body.setGravity(x, y)` adds *to* the world gravity. A body with world gravity `(0, 600)` and `setGravity(0, 200)` falls at 800.
3. **Disable per body** — `body.setAllowGravity(false)` opts the body out of all gravity. Floating UI sprites, hovering enemies, particles you want to control manually.

A common pattern: world gravity for the platformer player, disabled gravity for projectiles and enemies that fly:

```ts
// in game config:
arcade: { gravity: { x: 0, y: 800 } }

// player: gets world gravity automatically
const player = this.physics.add.sprite(100, 100, 'player');

// flying enemy: opts out
const bat = this.physics.add.sprite(400, 200, 'bat');
bat.body.setAllowGravity(false);

// homing missile: gravity off, control velocity directly
const missile = this.physics.add.sprite(0, 0, 'missile');
missile.body.setAllowGravity(false);
```

## Groups — bulk operations and pooling

A `Group` is a container for GameObjects with shared behavior. The physics version, `this.physics.add.group(...)`, attaches Arcade bodies to every member.

```ts
const enemies = this.physics.add.group({
  classType: Phaser.Physics.Arcade.Sprite,
  defaultKey: 'enemy',
  maxSize: 50,
  runChildUpdate: true,
});

enemies.create(200, 100);
enemies.create(400, 100);
enemies.setVelocityX(-100); // sets velocity on all members
```

The win is bulk operations and the **object pool pattern**, which is the standard way to handle high-frequency spawn/despawn in Phaser:

```ts
class Bullets extends Phaser.Physics.Arcade.Group {
  constructor(scene: Phaser.Scene) {
    super(scene.physics.world, scene, {
      classType: Phaser.Physics.Arcade.Image,
      defaultKey: 'bullet',
      maxSize: 30,
    });
  }

  fire(x: number, y: number, vx: number, vy: number) {
    const bullet = this.getFirstDead(true, x, y, 'bullet') as
      Phaser.Physics.Arcade.Image | null;
    if (!bullet) return; // pool exhausted
    bullet.setActive(true).setVisible(true);
    bullet.body.reset(x, y);
    (bullet.body as Phaser.Physics.Arcade.Body).setVelocity(vx, vy);
  }

  recycle(bullet: Phaser.Physics.Arcade.Image) {
    bullet.setActive(false).setVisible(false);
    (bullet.body as Phaser.Physics.Arcade.Body).stop();
  }
}
```

Why pool: spawning a `new Sprite()` per bullet allocates, allocations cause GC, GC causes frame hitches. A 30-bullet pool created once at scene start and recycled forever has zero allocation in `update()`. This is the difference between a smooth bullet hell and a stuttering one.

`getFirstDead(createIfNull, x, y, ...)` returns an inactive member or creates a new one if the pool isn't at `maxSize`. `getFirstAlive()` is the mirror — useful for "is any enemy still alive?" checks.

## Static groups for level geometry

Walls, floors, platforms — anything that doesn't move — go in a static group:

```ts
const platforms = this.physics.add.staticGroup();
platforms.create(400, 568, 'ground').setScale(2, 1).refreshBody();
platforms.create(600, 400, 'platform');
platforms.create(50, 250, 'platform');
```

The `refreshBody()` call after `setScale` is the critical bit — static bodies don't auto-update from transforms, so you need to tell the physics engine to recompute the body dimensions. Forgetting this is the #1 source of "my scaled-up platform has the wrong collision size."

For tile-based levels, use a tilemap layer with collision instead of a static group of sprites. Static groups are for hand-placed geometry; tilemaps are for grid-aligned levels.

## Collisions vs overlaps

The two ways to register an interaction between bodies:

```ts
// Collider: physically separates the bodies AND fires the callback
this.physics.add.collider(player, platforms);

// Overlap: fires the callback but does NOT separate the bodies
this.physics.add.overlap(player, coins, (p, coin) => {
  (coin as Phaser.GameObjects.GameObject).destroy();
  this.score += 1;
});
```

The rule: **collider for solid things that should bounce off each other; overlap for triggers that should just notify.** A player vs. wall is a collider. A player vs. coin is an overlap. A player vs. lava could be either depending on whether you want the player to stand on lava or walk through it.

Both functions take the same shape:

```ts
this.physics.add.collider(
  objectA,        // sprite, group, or array
  objectB,        // sprite, group, or array
  collideCallback, // fired after separation
  processCallback, // fired before separation; return false to skip
  callbackContext
);
```

`processCallback` is a less-known but powerful tool. It runs *before* separation and lets you return `false` to skip the collision entirely. Use it for one-way platforms, faction filtering ("friendly bullets pass through allies"), or conditional immunity:

```ts
this.physics.add.collider(player, platform, undefined, (p, plat) => {
  // Only collide if player is moving downward (one-way platform)
  return (p.body as Phaser.Physics.Arcade.Body).velocity.y > 0;
});
```

For group-vs-group, the callback receives the two specific colliding members, not the groups:

```ts
this.physics.add.overlap(bullets, enemies, (bullet, enemy) => {
  bulletPool.recycle(bullet as Phaser.Physics.Arcade.Image);
  (enemy as Enemy).takeDamage(1);
});
```

Type the callback parameters explicitly when you can; the `@types/phaser` defaults are loose.

## World bounds

The world is the rectangle bodies live in. By default it matches the game size. To explicitly set it:

```ts
this.physics.world.setBounds(0, 0, 1600, 600); // a wide level
```

To make a body collide with the world edges:

```ts
player.body.setCollideWorldBounds(true);
```

To get an event when it does:

```ts
const body = player.body as Phaser.Physics.Arcade.Body;
body.setCollideWorldBounds(true);
body.onWorldBounds = true; // opt this body in to the event

this.physics.world.on('worldbounds', (
  hitBody: Phaser.Physics.Arcade.Body,
  up: boolean, down: boolean, left: boolean, right: boolean
) => {
  if (hitBody.gameObject === player && down) {
    // player hit the bottom of the world
  }
});
```

The event fires once per body per frame the body is in contact with a bound. It does *not* fire every frame the body sits against the wall.

## Tile collision

The Arcade-tilemap pairing is a workhorse for platformers and top-down games. The Tiled-side workflow is:

1. In Tiled, give your collidable tiles a custom property — typically a boolean `collides: true`.
2. Export the map as JSON.
3. Load it in the scene.
4. Tell the layer which tiles collide.
5. Add a collider between the player and the layer.

```ts
preload() {
  this.load.image('tiles', 'assets/tiles.png');
  this.load.tilemapTiledJSON('map', 'assets/map.json');
}

create() {
  const map = this.make.tilemap({ key: 'map' });
  const tileset = map.addTilesetImage('tileset', 'tiles')!;
  const ground = map.createLayer('Ground', tileset, 0, 0)!;

  // Three ways to mark which tiles collide; pick one:
  ground.setCollisionByProperty({ collides: true });
  // ground.setCollisionByExclusion([-1]); // every non-empty tile
  // ground.setCollision([1, 5, 7]);       // by tile index

  this.physics.add.collider(player, ground);
}
```

`setCollisionByProperty` is the workflow you want for any non-trivial map. Marking specific tiles in Tiled is a designer-friendly task; touching tile indices in code is brittle.

Two gotchas worth knowing:

- **One-tile-thick walls can jitter** when a fast body squeezes against them. Phaser exposes `tileBias` on the world (`this.physics.world.TILE_BIAS = 32`) — increase it from the default 16 if you see this. The bias is the extra distance Arcade looks ahead when separating from a tile.
- **Arcade can't do slopes natively.** Tiles are AABB. If you want a 45° ramp, you have two options: stairstep it as several tiles (cheap and ugly), or use Matter physics (correct but a different engine). For most platformers, stairstepping plus a generous body offset is fine.

## Body position vs GameObject position

`sprite.x` and `sprite.body.x` are not the same number when there's an offset.

- `sprite.x` and `sprite.y` are the GameObject's position (the texture origin, by default the texture's top-left or center, depending on `setOrigin`).
- `body.x` and `body.y` are the body's top-left corner in world space, which is `sprite.x - origin*width + offsetX`.

The flow each physics step is **GameObject → body**: the body reads the GameObject's position at the start of the step, integrates velocity, resolves collisions, and writes the new position back to the GameObject. The reverse — setting `body.x` directly — is almost never what you want; the GameObject and body desynchronize.

To teleport a body, set the GameObject position and call `body.reset(x, y)`:

```ts
player.setPosition(100, 100);
(player.body as Phaser.Physics.Arcade.Body).reset(100, 100);
```

`reset` zeros velocity and re-syncs the body to the GameObject's position. Use it for respawns, scene transitions, level resets — anywhere you'd otherwise be tempted to write `body.x = ...`.

## Debug rendering

The Arcade debug renderer draws the body outline (green for non-colliding, red/blue for sides currently in contact) on top of every sprite. You'll catch wrong body sizes, missing offsets, and unexpected collisions just by looking.

Enable in the game config:

```ts
physics: {
  default: 'arcade',
  arcade: { debug: true }
}
```

Toggle at runtime — useful for binding to a hotkey:

```ts
this.input.keyboard!.on('keydown-F1', () => {
  this.physics.world.drawDebug = !this.physics.world.drawDebug;
  if (!this.physics.world.drawDebug) {
    this.physics.world.debugGraphic.clear();
  }
});
```

Leave debug *off* in production. The renderer is cheap but not free.

## The physics step — variable timestep, not fixed

Arcade physics runs once per render frame. The `delta` it integrates with is whatever the browser hands the loop — it varies with the frame rate. At 60 FPS it's ~16.6 ms; at 144 FPS it's ~6.9 ms; on a struggling mobile device it might spike to 50+ ms.

Two practical implications:

- **Arcade is not deterministic across machines.** Same inputs on two computers produce different exact outcomes because the deltas differ. For lockstep multiplayer, replays, or reproducible test runs, you need a fixed step — which Arcade doesn't natively offer. That's a Matter physics + custom-loop conversation, out of scope for this file.
- **Spike-induced tunneling.** A 50 ms delta means a 600-pixel/sec body moves 30 pixels in one step. If your floor is 32 pixels thick, that's the floor. Cap fall speed (`body.setMaxVelocity(0, 600)`) so a single-frame spike can't punch through thin geometry.

Arcade does internally clamp the per-step delta to prevent the worst tunneling cases, but the clamp is generous. Don't rely on it.

## `update` vs collider callbacks — where gameplay reactions live

A common sloppy pattern is reading collision state inside `update()`:

```ts
// don't do this — bad
update() {
  if (player.body.touching.down) {
    this.canJump = true;
  }
}
```

The clean version uses callbacks for collision-driven reactions and `update` for input-driven state changes:

```ts
update(time: number, delta: number) {
  // input + movement intent
  if (cursors.left.isDown) body.setAccelerationX(-ACCEL);
  // ...
  if (jumpPressed && this.canJump) {
    body.setVelocityY(-400);
    this.canJump = false;
  }
}

// collision-driven reactions in callbacks
create() {
  this.physics.add.collider(player, ground, () => {
    this.canJump = true; // landed
  });

  this.physics.add.overlap(player, coins, (_, coin) => {
    (coin as Phaser.GameObjects.GameObject).destroy();
    this.score += 1;
  });
}
```

The `body.touching` flags (`touching.up`, `touching.down`, `touching.left`, `touching.right`, and `body.blocked.*` for world-bounds contact) are still useful — for things like wall-slide checks or coyote-time grounded detection — but reach for callbacks first when the question is "what happened on this collision."

## Common Arcade gotchas

- **Setting `velocity` to 0 inside a collide callback** — almost never what you want. The collider already separated the bodies; zeroing velocity makes the player feel sticky against walls. Let the engine handle it.
- **Rotation does not rotate the body.** `sprite.angle = 45` rotates the sprite visually but the AABB stays axis-aligned. If you genuinely need rotated collision, you need Matter.
- **Body offset breaks after `setScale`.** Scaling re-derives the body from the texture, wiping your `setSize` and `setOffset` calls. Always: spawn → setScale → setSize/setOffset.
- **"My sprite falls through the floor"** — cap fall speed with `setMaxVelocity(0, 600)` so it can't move further than the floor's thickness in one step. Also check that the floor is actually a static body and that you registered the collider.
- **`this.physics.add.group()` makes dynamic bodies; use `staticGroup` for static** — easy to forget when you're prototyping. Symptom: a "wall" group that drifts under gravity.
- **Forgetting `refreshBody()` after `setScale` on a static group member** — the visual scales but the body doesn't, so collision happens in the wrong place.
- **Calling `setSize` before `setScale`** — same root cause, opposite symptom: your tuned body gets blown away.
- **Using overlap when you wanted collide** (or vice versa) — overlaps don't separate; if you want the player to stop at a wall, that's a collider, not an overlap.
- **Reading `body.x` to "where is my sprite"** — use `sprite.x`. The body has its own coordinate that includes the offset; you almost never want that.
- **Setting `body.x` directly** — desynchronizes the body from the GameObject. Use `body.reset(x, y)` for teleports.
- **Adding colliders inside `update()`** — colliders are persistent registrations, not per-frame calls. Add them in `create()` and let them fire forever.

## Related

- [phaser-fundamentals.md](phaser-fundamentals.md) — `Game`, `Scene`, the loop, the loader, and how the engine is structured around `update(time, delta)`.
- [scenes-and-flow.md](scenes-and-flow.md) — scene lifecycle and where physics lives across `init` / `preload` / `create` / `update`.
- [phaser-anti-patterns.md](phaser-anti-patterns.md) — broader Phaser anti-patterns, including registry-as-globals, allocations in `update`, and event leaks across scene restarts.
- [project-and-vite.md](project-and-vite.md) — project scaffold; physics plugin config lives in the same `GameConfig` covered there.
