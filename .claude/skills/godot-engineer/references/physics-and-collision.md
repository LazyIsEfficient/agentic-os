# Physics and Collision

Godot's physics system is one of the most-used parts of the engine and one of the most-misused. Get the body type wrong, the layer setup wrong, or the process function wrong, and you get jitter, missed collisions, falling through floors, or bodies that ignore each other for no apparent reason.

This file is about Godot 4's physics, in C#, for both 2D and 3D — the body types, the collision system, the right process function, and the patterns that avoid the common pitfalls.

## The Three Physics Body Types

Godot has three main physics body types, in both 2D and 3D variants:

| Type | When to use | Movement |
|---|---|---|
| **`StaticBody2D` / `StaticBody3D`** | Things that don't move and other things collide with: walls, floors, static obstacles | None |
| **`RigidBody2D` / `RigidBody3D`** | Physics-driven objects: barrels, debris, ragdolls, anything that obeys physics laws naturally | Forces, impulses, gravity (engine controls) |
| **`CharacterBody2D` / `CharacterBody3D`** | Things you control programmatically with collision: players, most enemies, projectiles when you want precise control | Manual `MoveAndSlide()` (you control) |

There's also `Area2D` / `Area3D` for detecting overlaps without solid collision (triggers, hit detection zones, pickup areas).

The single most common physics confusion: which body type to use for the player. The answer is almost always **`CharacterBody2D` / `CharacterBody3D`** — you want precise, programmatic control over the player's movement, not a physics engine deciding when to slide and when to bounce.

## `CharacterBody2D` (and 3D)

The bread and butter of Godot character movement. You set `Velocity`, call `MoveAndSlide()`, and the engine handles the collision response — sliding along walls, stopping at obstacles, etc.

A complete 2D player example:

```csharp
using Godot;

public partial class Player : CharacterBody2D
{
    [Export] public float Speed { get; set; } = 200.0f;
    [Export] public float JumpVelocity { get; set; } = -400.0f;
    [Export] public float Gravity { get; set; } = 980.0f;

    public override void _PhysicsProcess(double delta)
    {
        var velocity = Velocity;

        // Gravity
        if (!IsOnFloor())
            velocity.Y += Gravity * (float)delta;

        // Jump
        if (Input.IsActionJustPressed("jump") && IsOnFloor())
            velocity.Y = JumpVelocity;

        // Horizontal movement
        var direction = Input.GetAxis("move_left", "move_right");
        if (direction != 0)
            velocity.X = direction * Speed;
        else
            velocity.X = Mathf.MoveToward(velocity.X, 0, Speed);

        Velocity = velocity;
        MoveAndSlide();
    }
}
```

A 3D version is structurally identical but uses `Vector3`:

```csharp
public partial class Player3D : CharacterBody3D
{
    [Export] public float Speed { get; set; } = 5.0f;
    [Export] public float JumpVelocity { get; set; } = 4.5f;

    public override void _PhysicsProcess(double delta)
    {
        var velocity = Velocity;

        if (!IsOnFloor())
            velocity.Y -= 9.8f * (float)delta;

        if (Input.IsActionJustPressed("jump") && IsOnFloor())
            velocity.Y = JumpVelocity;

        var inputDir = Input.GetVector("move_left", "move_right", "move_forward", "move_back");
        var direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();

        if (direction != Vector3.Zero)
        {
            velocity.X = direction.X * Speed;
            velocity.Z = direction.Z * Speed;
        }
        else
        {
            velocity.X = Mathf.MoveToward(velocity.X, 0, Speed);
            velocity.Z = Mathf.MoveToward(velocity.Z, 0, Speed);
        }

        Velocity = velocity;
        MoveAndSlide();
    }
}
```

A few critical things to notice:

- **Everything is in `_PhysicsProcess`**, not `_Process`. Wrong choice causes jitter.
- **`Velocity` is a property of the body**; `MoveAndSlide()` uses it.
- **`MoveAndSlide()` uses `delta` internally** — you set `Velocity` in units per second, and the engine multiplies by the physics delta. You don't multiply velocity by delta yourself.
- **Acceleration toward zero with `MoveToward`** gives smooth deceleration when input stops.
- **`IsOnFloor()`** is the correct way to check if the body is grounded — not by manually checking velocity.

## `_PhysicsProcess` vs `_Process`

The most consequential and most-misunderstood distinction in Godot.

| Method | Frequency | Purpose | Examples |
|---|---|---|---|
| **`_PhysicsProcess(delta)`** | Fixed (60Hz default) | Anything that interacts with physics or needs deterministic stepping | `MoveAndSlide`, `MoveAndCollide`, applying forces, raycasting against the physics world, AI decisions that affect movement |
| **`_Process(delta)`** | Variable (frame rate) | Anything visual or input-related that doesn't touch physics | UI updates, visual interpolation, polling input that doesn't affect physics, particle spawning, sound effects |

**Movement of any physics body goes in `_PhysicsProcess`. Always.** Doing it in `_Process` causes the visual position to update at the rendering rate (which can be different from the physics rate), producing jitter and inconsistent collision response.

The most common bug: a tutorial says "in `_process`, move the player." The tutorial is wrong (or it's about a non-physics node). For physics bodies, it's `_PhysicsProcess`.

A subtle but important point: **`delta` in `_PhysicsProcess` is fixed**. At the default 60Hz, it's always `1.0/60.0 = 0.01667` seconds. This means physics simulations are deterministic across machines (assuming the same code and inputs), which is critical for replay systems, networking, and reproducibility.

**`delta` in `_Process` varies** with the frame rate. A game running at 144 FPS has a smaller `_Process` delta than one running at 30 FPS. Use `delta` correctly when scaling things to time:

```csharp
// _Process: scale by delta for time-based smoothing
public override void _Process(double delta)
{
    var camera = GetNode<Camera2D>("Camera2D");
    var target = GetNode<Player>("Player").GlobalPosition;
    camera.GlobalPosition = camera.GlobalPosition.Lerp(target, 5.0f * (float)delta);
}
```

## `RigidBody2D` (and 3D)

For things that should obey physics naturally — barrels rolling, boxes stacking, debris flying. The engine controls the body's position; you control its forces and impulses.

```csharp
public partial class ExplodingBarrel : RigidBody2D
{
    public void Explode()
    {
        ApplyImpulse(new Vector2(0, -500), Vector2.Zero);
        // Spawn particles, play sound, etc.
    }
}
```

Things to know:

- **Don't set `GlobalPosition` directly** on a `RigidBody`. The physics engine owns its position. To teleport a rigid body, use `SetDeferred` or set `GlobalTransform` (carefully).
- **Apply forces and impulses** to make it move. `ApplyImpulse` for one-shot pushes; `ApplyForce` for continuous forces.
- **Mass matters**. Heavier bodies move less per impulse. Set in the inspector.
- **Use `_IntegrateForces` for fine control** — this is called by the physics engine before the body's state is computed, and lets you read/write the body's `LinearVelocity`/`AngularVelocity` directly.

```csharp
public override void _IntegrateForces(PhysicsDirectBodyState2D state)
{
    // Custom physics tweaks here
    if (state.LinearVelocity.Length() > MaxSpeed)
    {
        state.LinearVelocity = state.LinearVelocity.Normalized() * MaxSpeed;
    }
}
```

For most game purposes, you don't need `_IntegrateForces`. Apply impulses and let the engine handle the rest.

## `Area2D` (and 3D)

`Area`s detect overlaps without producing physical collision. Use them for:

- **Hit detection** — a sword's hit area, an enemy's hurt area
- **Triggers** — a region that activates when the player enters
- **Pickups** — area around an item that detects the player
- **Damage zones** — fire, poison gas, etc.

```csharp
public partial class HealthPickup : Area2D
{
    [Export] public int HealAmount { get; set; } = 25;

    public override void _Ready()
    {
        BodyEntered += OnBodyEntered;
    }

    private void OnBodyEntered(Node2D body)
    {
        if (body is Player player)
        {
            player.Heal(HealAmount);
            QueueFree();
        }
    }
}
```

The `BodyEntered` signal fires when a `PhysicsBody` enters the area; `AreaEntered` fires when another `Area` enters. Pick the one matching what you're detecting.

A common pattern is **hitbox vs hurtbox**:

- **Hitbox**: an `Area` attached to the attacking entity. It represents the area where the attack hits.
- **Hurtbox**: an `Area` attached to the defending entity. It represents the area where the entity can be hit.

When a hitbox overlaps a hurtbox, damage is dealt:

```csharp
// Hitbox.cs (on the attacker)
public partial class Hitbox : Area2D
{
    [Export] public int Damage { get; set; }

    public override void _Ready()
    {
        AreaEntered += OnAreaEntered;
    }

    private void OnAreaEntered(Area2D area)
    {
        if (area is Hurtbox hurtbox)
        {
            hurtbox.TakeDamage(Damage);
        }
    }
}

// Hurtbox.cs (on the defender)
public partial class Hurtbox : Area2D
{
    [Signal] public delegate void DamagedEventHandler(int amount);

    public void TakeDamage(int amount)
    {
        EmitSignal(SignalName.Damaged, amount);
    }
}
```

This pattern decouples the attacker from the defender. The hitbox doesn't know the type of thing it's hitting; the hurtbox doesn't know the type of thing that hit it. Each handles its own concern.

## Collision Layers and Masks

The most common cause of "my collision isn't working": layers and masks set incorrectly.

Every physics body and area has:

- **`CollisionLayer`** — what *I am*. A bitmask of layers I exist in.
- **`CollisionMask`** — what *I detect/collide with*. A bitmask of layers I look for.

Two bodies interact if and only if **A's mask includes B's layer**. Note: it's a one-way relationship — A might detect B without B detecting A.

Example: in a 2D platformer, you might define layers as:

| Bit | Layer name |
|---|---|
| 1 | Player |
| 2 | Enemies |
| 3 | Player Bullets |
| 4 | Enemy Bullets |
| 5 | Environment (walls, floors) |
| 6 | Pickups |

Then:

- **Player**: layer 1 (Player), mask 5 + 6 (collides with environment, detects pickups) — but you also want it to be hit by enemies and enemy bullets, so mask 2 + 4 + 5 + 6.
- **Enemy**: layer 2 (Enemies), mask 5 (collides with environment).
- **Player Bullet**: layer 3, mask 2 + 5 (hits enemies and walls).
- **Enemy Bullet**: layer 4, mask 1 + 5 (hits player and walls).
- **Environment**: layer 5, mask 0 (doesn't actively detect anything; other things detect it).
- **Pickup**: layer 6, mask 0 (the player detects it).

Set these in the inspector, in the **Collision** section of any physics node.

**Name your layers** in **Project Settings → Layer Names → 2D Physics** (or 3D Physics). Bare bit numbers are unreadable; named layers ("Player", "Enemy", "Environment") are self-documenting.

## Collision Shapes

Every physics body and area needs a `CollisionShape2D` or `CollisionShape3D` child node with a shape resource. Common shapes:

| 2D | 3D |
|---|---|
| `RectangleShape2D` | `BoxShape3D` |
| `CircleShape2D` | `SphereShape3D` |
| `CapsuleShape2D` | `CapsuleShape3D` |
| `ConvexPolygonShape2D` | `ConvexPolygonShape3D` |
| `ConcavePolygonShape2D` | `ConcavePolygonShape3D` (use sparingly — slower) |

Tips:

- **Prefer simple shapes.** A circle or capsule is much faster than a complex polygon. For characters, a capsule is usually right in 3D; a rectangle or circle in 2D.
- **One shape per body is the default.** You can have multiple, but each adds collision cost.
- **Concave shapes only for static geometry.** `ConcavePolygonShape3D` is for static environment meshes; using it on moving bodies is slow and prone to bugs.
- **`StaticBody`s with `CollisionShape`s** can be assembled from multiple shapes for complex environments. For tile-based 2D, use `TileMap` instead, which handles this automatically.

## Raycasting

For line-of-sight checks, hit-scan weapons, and queries against the physics world, use raycasting.

The cleanest API is `PhysicsDirectSpaceState2D` / `3D` via the world's `DirectSpaceState`:

```csharp
public bool CanSeeTarget(Node2D target)
{
    var spaceState = GetWorld2D().DirectSpaceState;
    var query = PhysicsRayQueryParameters2D.Create(GlobalPosition, target.GlobalPosition);
    query.Exclude = new Godot.Collections.Array<Rid> { GetRid() }; // Don't hit self
    query.CollisionMask = 1 << 4; // Only check layer 5 (Environment)

    var result = spaceState.IntersectRay(query);
    return result.Count == 0; // No collision means clear line of sight
}
```

The `result` is a dictionary that's empty if no collision was found, or contains `position`, `normal`, `collider`, `rid`, etc. if there was a hit.

For frequent raycasts (e.g., a player's vision cone), prefer `RayCast2D` / `RayCast3D` *nodes*, which run the cast every physics frame and cache the result:

```
Player (CharacterBody2D)
└── GroundCheck (RayCast2D)
    Target Position: (0, 30)
    Enabled: true
```

```csharp
public override void _PhysicsProcess(double delta)
{
    var groundCheck = GetNode<RayCast2D>("GroundCheck");
    var isGrounded = groundCheck.IsColliding();
    // ...
}
```

This is faster for queries that happen every frame because the engine batches them with the physics step.

## `MoveAndCollide` vs `MoveAndSlide`

`CharacterBody` has two methods for movement:

- **`MoveAndSlide()`** — Move along the velocity vector, sliding along walls when collisions occur. The standard way to move a player.
- **`MoveAndCollide(motion)`** — Move by a specific motion vector, stopping on collision and returning a `KinematicCollision`. Used for finer control or for projectiles.

```csharp
// Sliding along walls (player)
Velocity = new Vector2(speed * direction, Velocity.Y + gravity * delta);
MoveAndSlide();

// Stop-on-collision (projectile)
var motion = direction * speed * (float)delta;
var collision = MoveAndCollide(motion);
if (collision != null)
{
    var hitNode = collision.GetCollider();
    if (hitNode is Enemy enemy)
    {
        enemy.TakeDamage(damage);
    }
    QueueFree();
}
```

`MoveAndSlide` is what you want 95% of the time for player-like characters. `MoveAndCollide` is for one-shot collision queries where you want full control over the response.

## Common Physics Patterns

### Coyote Time (Forgiving Jumps)

A small grace period after walking off a ledge during which the player can still jump. Makes platformers feel responsive.

```csharp
private float _coyoteTimer = 0;
private const float CoyoteTime = 0.1f;

public override void _PhysicsProcess(double delta)
{
    if (IsOnFloor())
        _coyoteTimer = CoyoteTime;
    else
        _coyoteTimer -= (float)delta;

    if (Input.IsActionJustPressed("jump") && _coyoteTimer > 0)
    {
        Velocity = new Vector2(Velocity.X, JumpVelocity);
        _coyoteTimer = 0;
    }
    // ... rest of physics
}
```

### Jump Buffering

If the player presses jump slightly before landing, register the jump on landing.

```csharp
private float _jumpBufferTimer = 0;
private const float JumpBufferTime = 0.1f;

public override void _PhysicsProcess(double delta)
{
    if (Input.IsActionJustPressed("jump"))
        _jumpBufferTimer = JumpBufferTime;
    else
        _jumpBufferTimer -= (float)delta;

    if (IsOnFloor() && _jumpBufferTimer > 0)
    {
        Velocity = new Vector2(Velocity.X, JumpVelocity);
        _jumpBufferTimer = 0;
    }
    // ... rest of physics
}
```

### One-Way Platforms

Platforms you can jump *up* through but stand *on*. Use `OneWayCollisionDirection` on the collision shape, or use a tile map's one-way property.

### Moving Platforms

A `CharacterBody2D` will automatically inherit motion from a moving platform if the platform is properly set up. In 2D: set the platform's `Sync To Physics` to true and use a `CharacterBody2D` for the platform itself. The player will be carried along.

## Determinism

If you need deterministic physics (replays, lockstep multiplayer, reproducible saves), be aware:

- **Physics is deterministic *if and only if*** all inputs and the initial state are the same. The engine itself is deterministic.
- **Floating-point math** is mostly deterministic on the same hardware/OS combo, but cross-platform determinism is hard.
- **Use `_PhysicsProcess` for everything that affects state**, never `_Process`.
- **Don't use `Time.GetTicksMsec()`** for game logic; use frame counts.
- **Avoid randomness without a seeded RNG.** `GD.Randf()` is non-deterministic by default; use `RandomNumberGenerator` with an explicit seed.

For most single-player games, you don't need strict determinism. For lockstep multiplayer or replays, design for it from the start.

## Anti-Patterns

- **Movement in `_Process` instead of `_PhysicsProcess`.** Jitter; bad collision response.
- **Setting `Velocity *= delta`** before calling `MoveAndSlide`. The engine handles delta; you set velocity in units per second.
- **Setting `GlobalPosition` on a `RigidBody`.** Fights the physics engine; produces unpredictable behavior.
- **Using `RigidBody` for the player.** You want precise control; physics-driven players are floaty and unpredictable.
- **Using `StaticBody` for things that move.** They're "static" — moving them is wrong.
- **Forgetting collision layers/masks.** Things don't collide; you can't figure out why.
- **Layers without names.** Project settings has a "Layer Names" section. Use it.
- **Concave polygon shapes on dynamic bodies.** Slow; bug-prone. Use convex pieces or simpler shapes.
- **Too many collision shapes per body.** Each shape adds cost. Prefer fewer, simpler shapes.
- **Raycasting in tight loops in `_Process`.** Raycasts are not free; cache results when possible.
- **Manually checking ground state instead of `IsOnFloor()`.** Often wrong about edge cases like slopes.
- **Skipping `IsOnFloor()` after `MoveAndSlide()`.** Some games check ground state *before* moving; you usually want it after.
- **Forgetting `IsInstanceValid` checks** when storing references to physics bodies that might be freed.
- **Treating `Area` as a body and vice versa.** Areas detect; they don't collide. Bodies collide. They're different.
- **Mixing `_IntegrateForces` with `MoveAndSlide`.** They serve different paradigms; pick one.
- **Hardcoding gravity on each body** instead of using the project-wide setting (or a shared gravity manager).
- **Ignoring `delta`.** `Velocity *= 0.95` per frame produces frame-rate-dependent behavior; use `Velocity = Velocity.Lerp(target, 0.95f * delta)` or similar.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — `_Process` vs `_PhysicsProcess` foundationally
- [input-and-controls.md](input-and-controls.md) — input handling that drives physics
- [animation-and-tweens.md](animation-and-tweens.md) — animating physics bodies
- [performance-and-profiling.md](performance-and-profiling.md) — physics performance work
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
