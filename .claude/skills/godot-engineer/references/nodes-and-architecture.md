# Nodes and Architecture

In Godot, the scene tree *is* the architecture of the game. There's no separate "framework layer" to design — the way you arrange nodes determines how the code communicates, how state flows, what's reusable, and what's coupled. Get this wrong and the codebase fights you forever; get it right and Godot's strengths carry you a long way.

This file is about thinking architecturally in Godot's idiom — composition with nodes, not inheritance with classes.

## The Core Principle: Composition With Nodes

Coming from a typical OO background, the instinct is to model game entities with class hierarchies. A `Player` class inherits from `Character` which inherits from `Entity` which inherits from `GameObject`. Then `Player` has a `Sprite`, an `AnimationController`, an `InputHandler`, etc., as fields.

In Godot, you do this differently. You compose a player out of *nodes*:

```
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── StateMachine (Node, custom script)
├── HitBox (Area2D)
│   └── CollisionShape2D
├── HurtBox (Area2D)
│   └── CollisionShape2D
└── Camera2D
```

The Player class is just `CharacterBody2D` with a script. The script handles physics, but the visual, audio, animation, hit detection, and camera are all separate child nodes that handle their own concerns. Each child can be configured in the inspector or replaced with a different implementation.

This is *composition*, and it's the right Godot idiom. You don't model the player as a god-class with everything inlined; you model it as a tree of focused, reusable nodes.

## Inheritance Has a Place — A Small Place

Inheritance in Godot is fine for *narrow* cases:

- **Specialized nodes**: a custom `EnemyBase` that derives from `CharacterBody2D` and adds health/damage methods, and `Goblin`, `Bat`, `Skeleton` derive from `EnemyBase`. The hierarchy is one or two levels deep; the shared behavior is real.
- **Custom resources**: a `WeaponData` resource type, with `MeleeWeaponData` and `RangedWeaponData` subclasses if needed.
- **Editor plugins**: tooling code where shared base behavior makes sense.

Inheritance is *wrong* when:

- The hierarchy is more than 2 levels deep.
- You're inheriting to "share code" rather than to express an "is-a" relationship.
- You'd be tempted to use inheritance just because that's how you'd do it in a class-based language.
- The shared behavior could be a child node instead.

A useful test: if "share code" is the only reason you're considering inheritance, prefer a child node. The child node is more flexible, can be swapped at runtime, and doesn't lock the parent into a hierarchy.

## What Goes in a Node Script

Each node script should have **one job**. The whole point of composing nodes is to keep each node focused.

### Good: focused nodes

```csharp
// Player.cs - movement and physics only
public partial class Player : CharacterBody2D
{
    [Export] public float Speed { get; set; } = 200.0f;
    [Export] public float JumpVelocity { get; set; } = -400.0f;

    private const float Gravity = 980.0f;

    public override void _PhysicsProcess(double delta)
    {
        var velocity = Velocity;

        if (!IsOnFloor())
            velocity.Y += Gravity * (float)delta;

        if (Input.IsActionJustPressed("jump") && IsOnFloor())
            velocity.Y = JumpVelocity;

        var direction = Input.GetAxis("move_left", "move_right");
        velocity.X = direction * Speed;

        Velocity = velocity;
        MoveAndSlide();
    }
}
```

```csharp
// Health.cs - health state only
public partial class Health : Node
{
    [Export] public int MaxHealth { get; set; } = 100;
    public int Current { get; private set; }

    [Signal] public delegate void HealthChangedEventHandler(int current, int max);
    [Signal] public delegate void DiedEventHandler();

    public override void _Ready()
    {
        Current = MaxHealth;
    }

    public void TakeDamage(int amount)
    {
        Current = Math.Max(0, Current - amount);
        EmitSignal(SignalName.HealthChanged, Current, MaxHealth);
        if (Current == 0) EmitSignal(SignalName.Died);
    }

    public void Heal(int amount)
    {
        Current = Math.Min(MaxHealth, Current + amount);
        EmitSignal(SignalName.HealthChanged, Current, MaxHealth);
    }
}
```

These two scripts each have one responsibility. They don't know about each other. They're reusable.

### Bad: god script

```csharp
// Player.cs (god version) - DON'T DO THIS
public partial class Player : CharacterBody2D
{
    public int Health = 100;
    public int Mana = 50;
    public int Score = 0;
    public int Level = 1;

    private AnimationPlayer _anim;
    private Sprite2D _sprite;
    private AudioStreamPlayer _hitSound;
    private AudioStreamPlayer _deathSound;
    private Label _healthLabel;
    private Label _scoreLabel;

    public override void _PhysicsProcess(double delta)
    {
        // Movement
        // Animation
        // Sound effects
        // Health regen
        // UI updates
        // Score tracking
        // ... 200 lines of mixed concerns
    }
}
```

A god script is the same anti-pattern as a god class. Every change requires editing this one file; nothing is reusable; testing is impossible; merge conflicts are constant.

The fix: extract each concern to a child node with its own script.

## Patterns for Common Architectures

### State Machines

Game entities often have *states* that change behavior: idle, walking, jumping, attacking, dying. The naive way is a giant `if/else` in `_PhysicsProcess` that checks the current state and acts accordingly. This works for two states; it falls apart at five.

The Godot idiom: a **state machine as a child node**. Each state is its own script. The state machine node holds the current state and forwards `_Process` / `_PhysicsProcess` calls to it.

```
Player (CharacterBody2D)
├── Sprite2D
├── AnimationPlayer
└── StateMachine (Node)
    ├── IdleState (Node)
    ├── WalkState (Node)
    ├── JumpState (Node)
    └── AttackState (Node)
```

```csharp
// StateMachine.cs
public partial class StateMachine : Node
{
    [Export] public State InitialState { get; set; }
    public State CurrentState { get; private set; }

    public override void _Ready()
    {
        // Initialize after the parent is ready
        CallDeferred(MethodName.InitState);
    }

    private void InitState()
    {
        CurrentState = InitialState;
        CurrentState?.Enter();
    }

    public override void _Process(double delta)
    {
        CurrentState?.Update(delta);
    }

    public override void _PhysicsProcess(double delta)
    {
        CurrentState?.PhysicsUpdate(delta);
    }

    public void TransitionTo(State newState)
    {
        if (newState == CurrentState) return;
        CurrentState?.Exit();
        CurrentState = newState;
        CurrentState?.Enter();
    }
}

// State.cs - base class
public partial class State : Node
{
    [Export] public StateMachine StateMachine { get; set; }

    public virtual void Enter() { }
    public virtual void Exit() { }
    public virtual void Update(double delta) { }
    public virtual void PhysicsUpdate(double delta) { }
}

// IdleState.cs
public partial class IdleState : State
{
    public override void Enter()
    {
        // Play idle animation
        var player = GetParent<StateMachine>().GetParent<Player>();
        player.GetNode<AnimationPlayer>("AnimationPlayer").Play("idle");
    }

    public override void PhysicsUpdate(double delta)
    {
        var player = GetParent<StateMachine>().GetParent<Player>();
        var input = Input.GetAxis("move_left", "move_right");
        if (input != 0)
        {
            StateMachine.TransitionTo(GetNode<WalkState>("../WalkState"));
        }
        else if (Input.IsActionJustPressed("jump"))
        {
            StateMachine.TransitionTo(GetNode<JumpState>("../JumpState"));
        }
    }
}
```

This is one valid pattern. There are many state-machine patterns; the key is that each state is *contained*, *testable*, and *replaceable*.

For more elaborate animation state machines, Godot has `AnimationTree` with a built-in state machine — see [animation-and-tweens.md](animation-and-tweens.md).

### Manager Nodes

When several systems need coordination, a "manager" node is often the right answer. Examples:

- `GameManager` — tracks game state, score, progression
- `AudioManager` — plays sounds, manages bus volumes
- `UIManager` — handles transitions between menus
- `SaveManager` — handles save/load

These can live as children of the main scene, or as autoloads if they need to persist across scene changes.

A manager is *not* a god-class. It coordinates but delegates the actual work to other nodes. A `GameManager` doesn't *play* sounds — it tells the `AudioManager` to play one. The separation is the point.

### Service Nodes

Sometimes you want a node that provides a service that multiple other nodes use, but the service doesn't need to live in the scene tree of the consumers. Example: a `DamageNumberSpawner` that spawns floating text whenever any enemy is hit.

The pattern: a service node lives in a known location (often a manager autoload or a known child of the main scene). Other nodes signal it when they need the service.

```csharp
// DamageNumberSpawner.cs
public partial class DamageNumberSpawner : Node2D
{
    [Export] public PackedScene DamageNumberScene { get; set; }

    public void Spawn(int amount, Vector2 position)
    {
        var number = DamageNumberScene.Instantiate<DamageNumber>();
        AddChild(number);
        number.GlobalPosition = position;
        number.SetAmount(amount);
    }
}
```

Then enemies use it via a signal connection or via the autoload pattern. The enemy doesn't know how to spawn a damage number; the spawner doesn't know about specific enemies; the connection happens at the scene level (or via a signal bus).

### Spawner / Pool Patterns

When you spawn many short-lived things (bullets, particles, damage numbers), use object pooling instead of `Instantiate`/`QueueFree` cycles to reduce GC pressure.

```csharp
public partial class BulletPool : Node
{
    [Export] public PackedScene BulletScene { get; set; }
    [Export] public int InitialSize = 50;

    private Queue<Bullet> _available = new Queue<Bullet>();

    public override void _Ready()
    {
        for (int i = 0; i < InitialSize; i++)
        {
            var bullet = BulletScene.Instantiate<Bullet>();
            AddChild(bullet);
            bullet.SetPhysicsProcess(false);
            bullet.Visible = false;
            bullet.OnReturned += () => Return(bullet);
            _available.Enqueue(bullet);
        }
    }

    public Bullet Spawn(Vector2 position, Vector2 direction)
    {
        Bullet bullet;
        if (_available.Count > 0)
        {
            bullet = _available.Dequeue();
        }
        else
        {
            // Pool exhausted; create a new one (or fail, depending on policy)
            bullet = BulletScene.Instantiate<Bullet>();
            AddChild(bullet);
            bullet.OnReturned += () => Return(bullet);
        }

        bullet.GlobalPosition = position;
        bullet.Direction = direction;
        bullet.SetPhysicsProcess(true);
        bullet.Visible = true;
        return bullet;
    }

    private void Return(Bullet bullet)
    {
        bullet.SetPhysicsProcess(false);
        bullet.Visible = false;
        _available.Enqueue(bullet);
    }
}
```

This is more code than `QueueFree`/`Instantiate`, but for things spawned dozens of times per second, it makes a real performance difference. See [performance-and-profiling.md](performance-and-profiling.md) for when pooling is worth it.

## Holding References to Children

The most common architectural friction in Godot: holding references to child nodes from a parent script. There are several patterns; some are brittle, some are robust.

### Path-based (brittle)

```csharp
public override void _Ready()
{
    _sprite = GetNode<Sprite2D>("Sprite2D");
    _anim = GetNode<AnimationPlayer>("AnimationPlayer");
    _statusLabel = GetNode<Label>("UI/Container/InfoPanel/StatusLabel");
}
```

The first two are fine because they're shallow. The third is brittle because moving any of those parent nodes breaks the path.

### Scene-unique names (good)

Mark the node with `%` in the editor (right-click → "Access as Scene Unique Name") and reference it by short name:

```csharp
public override void _Ready()
{
    _statusLabel = GetNode<Label>("%StatusLabel");
}
```

The lookup is by name within the scene, regardless of where in the tree the node lives. Robust to moving the node around.

### `[Export]` references (best for cross-scene)

For references that span scene boundaries, drag the target node onto an `[Export]` field:

```csharp
[Export] public Player Target { get; set; }
[Export] public Label HealthLabel { get; set; }
```

In the editor, drag the target nodes onto the fields. The references are typed and resolved when the scene loads. Renaming the target doesn't break anything.

The downside: you have to remember to wire them up in the editor, and if you forget, you get null reference errors at runtime. Set the field in `_Ready` with a null check if you want to fail loudly:

```csharp
public override void _Ready()
{
    if (Target == null)
    {
        GD.PrintErr($"{Name} has no Target assigned!");
    }
}
```

### `[Export(PropertyHint.NodePath)]` (between)

For node references within the same scene, you can use `NodePath`:

```csharp
[Export] public NodePath TargetPath { get; set; }
private Player _target;

public override void _Ready()
{
    _target = GetNode<Player>(TargetPath);
}
```

The editor lets you pick the node from the scene tree. This is useful when the target is in the same scene but you don't want to use scene-unique names.

## "Wire It Up From the Top"

A useful general principle: **wiring happens at the level above where the wired things live**.

If two siblings need to communicate, their parent wires them up:

```csharp
// Player and HUD are siblings; Level wires them
public partial class Level : Node2D
{
    public override void _Ready()
    {
        var player = GetNode<Player>("Player");
        var hud = GetNode<HUD>("HUD");
        player.HealthChanged += hud.UpdateHealthBar;
        player.Died += hud.ShowGameOver;
    }
}
```

This keeps Player and HUD ignorant of each other. Either can be removed; either can be reused in a different scene that wires them differently.

The opposite (the player reaching out to find the HUD) couples them and makes both less reusable.

## Nodes vs Resources for Data

A common confusion: when should something be a node vs. a custom resource?

**Nodes** are runtime entities. They have a lifecycle, they're in the tree, they participate in `_Process`/`_PhysicsProcess`, they emit signals.

**Resources** are data. They're inert. They live on disk and in memory; they don't process, don't have transforms, don't respond to physics.

| Thing | Node or Resource? |
|---|---|
| The player character | Node (has lifecycle, processing, transform) |
| The player's stats (max HP, attack power) | Could be either; usually a resource if shared between instances |
| A specific weapon definition | Resource (data shared between weapon instances) |
| A weapon equipped by the player | Node (or a property of the player that holds a reference to a weapon resource) |
| A level | Scene (which is a special tree of nodes) |
| A level's ambient music | Resource (`AudioStream`) |
| A particle effect template | Resource (`ParticleProcessMaterial`) or scene |
| A spawned particle effect | Node |
| A sprite frame | Resource (`Texture2D`, `AtlasTexture`, or `SpriteFrames`) |
| A sprite displaying a frame | Node (`Sprite2D`) |

When in doubt: ask "does it have a position in the world or a lifecycle?" If yes, it's a node. If it's pure data, it's a resource.

## Signals as Architecture

In a well-architected Godot project, signals are how *most* communication happens. Direct method calls are for parent-to-child commands; signals are for child-to-parent (and broader) events.

Signal patterns:

- **Child emits, parent listens.** The most common pattern. The child doesn't know who's listening.
- **Sibling-to-sibling via parent.** The parent connects sibling A's signal to sibling B's method. Neither sibling knows about the other.
- **Global event bus (autoload).** For events that don't fit a parent-child structure; reserved for truly global concerns.

Direct call patterns:

- **Parent commands child.** `enemy.TakeDamage(10)`. The parent knows which child to command.
- **Method call up the tree.** Generally avoided; use signals.

For more on signals, see [signals-and-events.md](signals-and-events.md).

## Anti-Patterns

- **God script.** All player logic in one 800-line file.
- **God scene.** A single `.tscn` containing everything.
- **Deep inheritance.** Custom node classes 4 levels deep. Refactor to composition.
- **Mixed concerns.** A "Player" script that also handles UI, audio, score tracking, save state, and pathfinding.
- **Tight coupling via paths.** `GetNode("../../UI/HUD/Score")`. Brittle on every refactor.
- **Manager-as-god.** A `GameManager` that does *everything*. Split by responsibility.
- **Direct cross-scene access.** A node in one scene reaching into another scene's children. Use signals or events instead.
- **Inheritance for code reuse.** "I'll make a `BaseEnemy` so I don't repeat code." Often, a child node would do.
- **State-as-flags.** Booleans for `isJumping`, `isAttacking`, `isDying`. The state machine pattern is cleaner.
- **Mutable shared state in resources.** Resources are loaded once and shared; mutating them affects every instance silently. If you need per-instance state, put it on the node, not the resource.
- **`new ClassName()` for nodes that should come from scenes.** Misses children, signals, and exports. Use `PackedScene.Instantiate<T>()`.
- **Manager autoloads instead of properly-rooted scenes.** Sometimes a manager belongs in the active scene's tree, not as an autoload.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — the engine model
- [scenes-and-instancing.md](scenes-and-instancing.md) — scene composition
- [signals-and-events.md](signals-and-events.md) — signal patterns
- software-design — broader principles (SOLID, cohesion/coupling) that apply
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
