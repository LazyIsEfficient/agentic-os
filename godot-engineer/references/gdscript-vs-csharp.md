# GDScript vs C#

This skill defaults to **C#** as the primary language for Godot 4 work, but GDScript is still relevant in places. This file explains the trade-offs, when to reach for which, and how to interoperate when you have to.

The honest summary: **for a non-trivial project, C# is the better default in Godot 4.** It's faster, has better tooling, integrates with the broader .NET ecosystem, and handles complex codebases better. GDScript is still useful for tools, editor scripts, plugin development, and quick prototypes — but it's not the primary language for serious game work.

This is a *change* from Godot 3, where GDScript was the de facto standard and C# was a second-class citizen. Godot 4 with .NET 8 has made C# a real option, and for most production game work, it's the right one.

## The Two Languages At a Glance

| Aspect | GDScript | C# |
|---|---|---|
| **Type system** | Dynamic by default; optional static typing | Static, strict |
| **Performance** | Slower (interpreted); fine for most gameplay | Faster (JIT-compiled); better for hot paths |
| **Tooling** | Built into Godot editor; OK | VS Code or Rider; excellent |
| **Hot reload** | Yes, fast | Limited; usually requires restart |
| **Async/await** | No (uses signals/coroutines instead) | Yes |
| **Generics** | Limited | Full |
| **LINQ** | No | Yes |
| **Ecosystem** | Godot-only; small | All of NuGet; massive |
| **Build step** | None | Yes (.NET compile) |
| **Editor scripts / plugins** | Native support | Possible but harder |
| **Engine integration** | Tightest possible | Tight, with some overhead |
| **Iteration speed** | Very fast | Slower (compile step) |
| **Learning curve** | Low (Python-like) | Higher if new to C# |
| **Hiring** | Niche | Wide pool |

## When C# Wins

- **Non-trivial gameplay code.** Anything beyond a 10-scene prototype benefits from static typing and better refactoring.
- **Performance-critical paths.** Procedural generation, large-scale simulation, real-time pathfinding, anything that loops over thousands of objects per frame.
- **Code shared with non-game systems.** A backend, a tool, a server — if it's also .NET, you can share code.
- **Larger teams.** Multiple engineers benefit from C#'s static checks, refactoring tools, and consistent style.
- **Long-lived projects.** Years of iteration are easier in a typed language.
- **NuGet packages.** Need an HTTP client? JSON parser? Compression library? NuGet has it; GDScript would force you to write it.
- **You already know C# / .NET.** No reason to learn GDScript when C# works.

## When GDScript Wins

- **Quick prototypes.** A weekend game jam game; iteration speed matters more than scale.
- **Editor tools and plugins.** GDScript has tighter editor integration; many plugins are written in GDScript.
- **Simple shaders + light scripts.** A `Sprite2D` that needs a 5-line wiggle script.
- **Tutorials and learning.** Most Godot tutorials are in GDScript; following along is easier.
- **Quick scripts attached to specific nodes.** A button that does one thing; a particle that destroys itself after a second.
- **`@tool` scripts** (scripts that run in the editor for procedural authoring) — easier in GDScript.

## Mixing Both

You *can* use both GDScript and C# in the same project. They interoperate via Godot's `Variant` type, which is the universal value type the engine uses internally.

When to mix:

- A C#-primary project with a few GDScript editor tools or plugins.
- A GDScript-primary project that drops to C# for one performance-critical system.
- An imported asset / addon that's GDScript-based — just leave it.

When *not* to mix:

- Throughout the gameplay code. Pick one for the main codebase or you'll fight constant interop issues.
- For shared core data structures. Cross-language types get awkward.

The interop:

```csharp
// C# calling a GDScript node
var gdNode = GetNode("MyGDScriptNode");
gdNode.Call("DoSomething", 42);
var result = gdNode.Get("someProperty");
```

```gdscript
# GDScript calling a C# node
var cs_node = get_node("MyCSharpNode")
cs_node.do_something(42)
var result = cs_node.some_property
```

Notice the conventions: GDScript uses `snake_case`, C# uses `PascalCase`. **Godot translates between them automatically** in interop calls. A C# method `DoSomething` is callable from GDScript as `do_something`.

This is convenient but it's also a foot-gun: typos in the string-based call don't error at compile time, only at runtime when the method isn't found.

## C# Code Conventions in Godot

C# in Godot follows *Godot* conventions, not standard .NET conventions, in places where the engine bridges them:

| Standard C# | Godot C# |
|---|---|
| `void OnReady()` | `public override void _Ready()` (note the underscore) |
| `void Update(float dt)` | `public override void _Process(double delta)` |
| `Vector2 position { get; set; }` | `Position` (PascalCase, no underscore) |
| `event Action OnDamaged` | `[Signal] delegate void DamagedEventHandler()` |

The reason: Godot generates source code for your scripts (the `partial` part of the class) and uses these conventions internally. Following them keeps interop clean.

A typical C# Godot script:

```csharp
using Godot;

public partial class Enemy : CharacterBody2D
{
    [Export] public float Speed { get; set; } = 100.0f;
    [Export] public int MaxHealth { get; set; } = 50;
    [Export] public PackedScene DeathParticles { get; set; }

    [Signal] public delegate void HealthChangedEventHandler(int newHealth);
    [Signal] public delegate void DiedEventHandler();

    private int _currentHealth;
    private AnimationPlayer _anim;

    public override void _Ready()
    {
        _currentHealth = MaxHealth;
        _anim = GetNode<AnimationPlayer>("AnimationPlayer");
    }

    public override void _PhysicsProcess(double delta)
    {
        // Movement and physics here.
    }

    public void TakeDamage(int amount)
    {
        _currentHealth = Mathf.Max(0, _currentHealth - amount);
        EmitSignal(SignalName.HealthChanged, _currentHealth);

        if (_currentHealth == 0)
        {
            EmitSignal(SignalName.Died);
            _anim.Play("die");
            // Spawn particles, queue free, etc.
        }
    }
}
```

A few patterns to notice:

- **`partial`** is required because Godot generates a companion class for the script.
- **`[Export]`** with `{ get; set; }` works for properties; with bare fields it also works but properties are more idiomatic in C#.
- **`PackedScene`** is the type for an instanced scene reference (e.g. for spawning).
- **`SignalName.HealthChanged`** is a generated constant for the signal name; preferable to the raw string `"HealthChanged"` because typos error at compile time.
- **`Mathf`** is Godot's math utility class (not `System.Math` — they have slightly different functions).

## Subscribing to Signals in C#

The C# 4 idiom uses `+=` and `-=` like normal events:

```csharp
public override void _Ready()
{
    var enemy = GetNode<Enemy>("Enemy");
    enemy.HealthChanged += OnEnemyHealthChanged;
    enemy.Died += OnEnemyDied;
}

private void OnEnemyHealthChanged(int newHealth)
{
    // Update HUD
}

private void OnEnemyDied()
{
    // Spawn loot, count score, etc.
}
```

The `EventHandler` suffix on the delegate name is required by Godot's source generator. The `+=` connection is type-checked by the compiler.

The older string-based approach (`Connect("HealthChanged", new Callable(this, nameof(OnEnemyHealthChanged)))`) still works but is fragile and you should avoid it in new code.

Always disconnect when the connection is no longer needed:

```csharp
public override void _ExitTree()
{
    if (IsInstanceValid(_enemy))
    {
        _enemy.HealthChanged -= OnEnemyHealthChanged;
        _enemy.Died -= OnEnemyDied;
    }
}
```

If the *emitter* is freed first, the connection auto-cleans. If the *listener* is freed first without disconnecting, you get a "memory leak" in the sense that Godot keeps the connection alive. The defensive habit: disconnect in `_ExitTree`.

## Async/Await with Signals

C# in Godot supports `await`-ing signals:

```csharp
public async void StartCutscene()
{
    GD.Print("Cutscene started");
    var anim = GetNode<AnimationPlayer>("AnimationPlayer");
    anim.Play("cutscene_intro");
    await ToSignal(anim, AnimationPlayer.SignalName.AnimationFinished);
    GD.Print("Intro done; starting next part");
    anim.Play("cutscene_part_2");
    await ToSignal(anim, AnimationPlayer.SignalName.AnimationFinished);
    GD.Print("Cutscene complete");
}
```

This is much cleaner than chaining signal callbacks for sequenced events. Use it for cutscenes, multi-step animations, dialogue systems, level transitions, anything that's "do this, then wait, then do the next thing."

A caveat: be careful with `async void` (the example above). It's necessary for event handlers but it can swallow exceptions. For non-event-handler cases, prefer `async Task` and `await` it from the caller.

## Performance Notes

- **C# is faster than GDScript** for tight loops, math, and procedural code. Often 2-10x.
- **The first-call overhead** of C# methods (JIT compile) can show up as a small startup hitch.
- **GC pauses are real but small**. The Godot 4 .NET integration uses CoreCLR; GC is well-behaved for typical game workloads but still exists. Pre-allocate hot collections, use `Span<T>` where it helps, and don't allocate in `_Process` if you can avoid it.
- **`Variant` boxing** crosses the C#-Godot boundary and has some overhead. Avoid passing C# `int`/`float`/`Vector2` through `Variant` in tight loops; use the typed APIs where possible.
- **`GetNode<T>(...)`** has a string lookup cost. Cache references in `_Ready` instead of calling it every frame.
- **For really hot paths**, you can drop into `unsafe` C# or even GDExtension (a C++ binding mechanism). Most projects never need this.

For the deeper performance discussion, see [performance-and-profiling.md](performance-and-profiling.md).

## Project Setup for C#

A C# Godot project uses the **.NET version of Godot** (separate download from the standard version, also available as the "Mono" build in older releases).

To start a C# project:

1. Use the **.NET / Mono** version of the Godot editor.
2. Create a new project.
3. **Project → Tools → C# → Create C# Solution**.
4. Set the .NET SDK in the project settings.

The `.csproj` is auto-generated and minimal:

```xml
<Project Sdk="Godot.NET.Sdk/4.2.0">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <EnableDynamicLoading>true</EnableDynamicLoading>
  </PropertyGroup>
</Project>
```

You can add NuGet packages like any other .NET project:

```bash
dotnet add package Newtonsoft.Json
dotnet add package System.IO.Hashing
```

NuGet works as expected in Godot 4 — this was a frequent pain point in earlier versions.

## C# Editor Workflow

Most C# Godot devs use one of:

- **VS Code with the C# Dev Kit** — lightweight, free, works well.
- **JetBrains Rider** — paid (free for non-commercial), the most polished experience for C# work.
- **Visual Studio** (Windows) — works but heavier than needed.

Workflow:

1. Edit the scene structure in the Godot editor.
2. Edit C# scripts in your IDE of choice.
3. The Godot editor watches for `.cs` changes and rebuilds when you save.
4. Run the project from the Godot editor (F5).

Hot reload is *limited* in Godot 4 with C# — you can change some things at runtime, but most code changes require restarting the game. This is the main downside vs. GDScript, which hot-reloads almost everything instantly.

## Common Gotchas

### `partial` is required

Forgetting `partial` produces confusing errors. Every script class needs it.

```csharp
// Wrong
public class Player : CharacterBody2D { ... }

// Right
public partial class Player : CharacterBody2D { ... }
```

### Constructors run before `_Ready`

A C# constructor runs when the object is created, *before* it's added to the tree. You can't call `GetNode<T>(...)` in a constructor because the node isn't in the tree yet.

```csharp
// Wrong
public Player()
{
    _sprite = GetNode<Sprite2D>("Sprite2D"); // Crashes
}

// Right
public override void _Ready()
{
    _sprite = GetNode<Sprite2D>("Sprite2D");
}
```

### `[Export]` on private fields needs an underscore prefix

By Godot convention, private fields start with `_`, but `[Export]` works on them anyway:

```csharp
[Export] private int _maxHealth = 100;
```

This is the most idiomatic for C# fields. For properties, use PascalCase:

```csharp
[Export] public int MaxHealth { get; set; } = 100;
```

### Don't `new` a node directly

Nodes should be created via `new ClassName()` only if you immediately add them to the tree. The preferred way to create scenes is:

```csharp
[Export] public PackedScene EnemyScene { get; set; }

private void SpawnEnemy()
{
    var enemy = EnemyScene.Instantiate<Enemy>();
    AddChild(enemy);
    enemy.GlobalPosition = new Vector2(100, 100);
}
```

Using `PackedScene.Instantiate<T>()` gives you the entire tree (root + all children, with all properties), not just an empty class instance.

### `QueueFree` vs `Free`

- `QueueFree()` schedules the node to be freed at the end of the current frame. This is what you almost always want.
- `Free()` immediately frees the node. Dangerous if any code is still iterating over the children or holding references.

```csharp
// Right (in 99% of cases)
deadEnemy.QueueFree();
```

### `IsInstanceValid` for orphan checks

If you're holding a reference to a node that might have been freed, check before using:

```csharp
if (IsInstanceValid(_target))
{
    _target.TakeDamage(10);
}
```

Otherwise you can hit "object was freed" errors when the held reference points to a freed Godot object.

### `Vector2` is a struct

Godot's `Vector2`, `Vector3`, `Color`, `Rect2`, etc. are *value types*. Mutating a property doesn't propagate:

```csharp
// Wrong
GetNode<Sprite2D>("Sprite2D").GlobalPosition.X += 10; // Doesn't compile, but the equivalent doesn't work either

// Right
var sprite = GetNode<Sprite2D>("Sprite2D");
var pos = sprite.GlobalPosition;
pos.X += 10;
sprite.GlobalPosition = pos;
```

Or, more concisely:

```csharp
sprite.GlobalPosition += new Vector2(10, 0);
```

## Anti-Patterns

- **Mixing GDScript and C# in the same gameplay code.** Pick one for the main codebase; mixing for non-trivial logic produces interop pain.
- **Using string-based signal connections** (`Connect("name", ...)`) when typed `+=` is available.
- **Creating nodes with `new ClassName()` instead of instantiating a `PackedScene`.** Misses children and exports.
- **Doing setup in C# constructors instead of `_Ready`.** Crashes from `GetNode` calls.
- **Forgetting `partial`.** Constant compilation errors.
- **Calling `GetNode<T>` every frame.** Cache references in `_Ready`.
- **`Free()` instead of `QueueFree()`.** Mid-frame crashes.
- **Mutating `Vector2` properties as if they're references.** Compiles but doesn't do what you think.
- **Ignoring `IsInstanceValid` for held references.** "Object was freed" errors at random times.
- **Treating C# Godot like normal C#.** Following standard .NET naming conventions where Godot uses different ones; missing the `_Process` underscore; etc.
- **Avoiding GDScript entirely** when an editor tool or plugin would clearly be faster. Use the right tool.
- **Using GDScript for performance-critical code.** Drop to C# (or C++/GDExtension) for hot paths.
- **Picking one language because of the tutorial you're following.** Pick based on your project's needs.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — the engine model that both languages target
- [signals-and-events.md](signals-and-events.md) — signal patterns in C#
- [performance-and-profiling.md](performance-and-profiling.md) — when C# performance matters
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
