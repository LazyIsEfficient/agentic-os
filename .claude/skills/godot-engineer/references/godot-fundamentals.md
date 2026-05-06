# Godot Fundamentals

This file is the mental model. Before any of the other reference files make sense, you need to internalize how Godot 4 thinks — what its core abstractions are, how the main loop runs, what a "scene" actually is, and how the editor relates to your code. Skip this and the rest of the skill is harder to apply.

The thing most new Godot engineers (especially those coming from Unity or web development) get wrong: **they treat Godot's nodes and scenes as classes and objects in their language of choice**. They aren't quite that. Nodes are runtime entities in a tree; scenes are *templates* for sub-trees that can be instanced. Once you internalize this, the rest of Godot makes sense.

## The Engine Model in Five Sentences

1. A **Node** is the basic building block of everything in Godot — every visible thing, every behavior, every UI element is a node.
2. A **Scene** is a tree of nodes saved to disk as a `.tscn` file, designed to be *instanced* (used multiple times, anywhere in the project).
3. The running game is **one big tree of nodes**, built by adding scenes to other scenes; this tree is called the SceneTree.
4. The **main loop** ticks the tree every frame, calling `_Process` (variable timestep) and `_PhysicsProcess` (fixed timestep) on every node that defines them.
5. Nodes communicate by **signals** (events), by direct method calls, and via **autoloads** (singletons available everywhere).

If you understand those five things, you understand the engine. The rest is detail.

## Nodes

A node is the smallest unit of *anything* in Godot. There are hundreds of built-in node types, all inheriting from `Node`. The most important ones to know:

| Node | Purpose |
|---|---|
| `Node` | Generic, no transform; for non-spatial logic |
| `Node2D` | 2D spatial node with position/rotation/scale |
| `Node3D` | 3D spatial node (was `Spatial` in Godot 3) |
| `Control` | UI element with anchor/margin layout |
| `CanvasLayer` | Holds 2D things (UI, HUD) above the world |
| `Sprite2D` / `Sprite3D` | Display images |
| `MeshInstance3D` | Display 3D meshes |
| `CharacterBody2D` / `CharacterBody3D` | Player/enemy physics body that moves with code |
| `RigidBody2D` / `RigidBody3D` | Physics-driven body |
| `StaticBody2D` / `StaticBody3D` | Non-moving collision |
| `Area2D` / `Area3D` | Detect overlap without collision |
| `CollisionShape2D` / `CollisionShape3D` | Defines collision geometry (child of a body) |
| `AnimationPlayer` | Plays keyframe animations on properties |
| `AnimationTree` | State-machine-driven animation playback |
| `AudioStreamPlayer` / `AudioStreamPlayer2D` / `AudioStreamPlayer3D` | Audio playback |
| `Timer` | Schedules callbacks |
| `Camera2D` / `Camera3D` | View into the world |
| `Label`, `Button`, `LineEdit`, `OptionButton`, etc. | UI controls |
| `Container` (and subclasses: `VBoxContainer`, `HBoxContainer`, `GridContainer`, etc.) | UI layout |

A node has:

- A **type** (its class)
- A **name** (string, unique among siblings)
- A **parent** (or none, if it's the root)
- **Children** (zero or more)
- A **script** (optional — your code attached to this specific node)
- **Properties** (exported in the inspector)
- **Signals** (events it emits)
- A **process mode** (always, paused, etc.)

In C#, a node is a class that inherits from `Node` (or one of its subclasses). When you attach a script to a node in the editor, the script's class *becomes* that node at runtime.

```csharp
using Godot;

public partial class Player : CharacterBody2D
{
    [Export] public float Speed = 200.0f;
    [Export] public float JumpVelocity = -400.0f;

    public override void _Ready()
    {
        // Called when the node is added to the tree.
    }

    public override void _PhysicsProcess(double delta)
    {
        // Called every physics frame.
    }
}
```

A few things to note:

- `partial` is required because Godot generates source code for the class.
- `[Export]` makes the field visible in the inspector and tweakable per-instance.
- `_Ready` and `_PhysicsProcess` are *override* methods Godot calls automatically.
- The class name should match the file name (Godot convention).

## Scenes

A scene is a tree of nodes, saved as a `.tscn` file. The simplest scene has one node (the root); a complex scene might have hundreds. The key insight: **a scene is a template that can be instanced multiple times**.

A typical player scene might look like:

```
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── Camera2D (only on the local player)
└── HitDetection (Area2D)
    └── CollisionShape2D
```

The root node is a `CharacterBody2D` named "Player". It has child nodes for visuals (sprite, animation), physics (collision shape), camera (so the camera follows the player), and a hit-detection area. All saved as one `.tscn` file. You can drag this scene into a level scene and you've added a player.

Scenes can contain other scenes. This is called **instancing**. A level scene might have:

```
Level (Node2D)
├── TileMap
├── Player (instance of player.tscn)
├── Enemies (Node2D)
│   ├── Goblin (instance of goblin.tscn)
│   ├── Goblin (instance of goblin.tscn, same scene reused)
│   └── Bat (instance of bat.tscn)
├── Pickups (Node2D)
└── HUD (CanvasLayer; instance of hud.tscn)
```

Each instance starts identical but can have its position, properties, and overrides set per-instance in the parent scene. If you change `goblin.tscn`, all instances of it update.

This is the most powerful feature in Godot. It's also where most engineers go wrong — by *not* using it. The signal that you should split something into its own scene: it appears more than once, or it's complex enough that you'd want to reuse it later, or it's owned by a different person/team.

## The SceneTree and the Main Loop

When the game runs, Godot loads the *main scene* (set in project settings) and starts its main loop. The main loop:

1. Polls input.
2. Calls `_Process(delta)` on every node that defines it. Variable timestep — `delta` is the time since the last frame, in seconds.
3. Steps the physics. Calls `_PhysicsProcess(delta)` on every node that defines it. **Fixed timestep** — defaults to 60Hz, so `delta` is always `1.0/60.0` (regardless of how fast the game is running).
4. Draws the frame.
5. Repeats.

The variable-vs-fixed distinction is critical:

- `_Process` runs as fast as the framerate allows. At 120 FPS, it runs twice per "physics frame." At 30 FPS, it runs less often than physics. Use it for visual interpolation, UI updates, polling, anything that's tied to "what the user sees this instant."
- `_PhysicsProcess` runs at a consistent rate (60Hz by default). Physics happens here. Movement that interacts with collisions happens here. Determinism is easier here because the timestep is predictable.

The most common Godot bug from misusing these: putting movement in `_Process`. The character moves jittery because the physics step doesn't match the rendering step. **Movement of physics bodies goes in `_PhysicsProcess`. Always.**

## Lifecycle Methods

Every node can override these:

| Method | When called |
|---|---|
| `_Ready()` | Once, when the node enters the tree and all its children are also ready. |
| `_EnterTree()` | When the node enters the tree (before children). |
| `_ExitTree()` | When the node leaves the tree. |
| `_Process(double delta)` | Every frame (variable timestep). |
| `_PhysicsProcess(double delta)` | Every physics frame (fixed timestep). |
| `_Input(InputEvent ev)` | When an unhandled input event occurs. |
| `_UnhandledInput(InputEvent ev)` | When an input event hasn't been handled by UI. |
| `_Notification(int what)` | For low-level system events. |

`_Ready` is the most-used. It's the equivalent of a constructor for a node, except it runs *after* the node is in the tree, so you can call `GetNode<T>(...)` on children. Putting initialization in C# constructors is wrong because the node isn't in the tree yet.

```csharp
public partial class Player : CharacterBody2D
{
    private AnimationPlayer _animPlayer;
    private Sprite2D _sprite;

    public override void _Ready()
    {
        _animPlayer = GetNode<AnimationPlayer>("AnimationPlayer");
        _sprite = GetNode<Sprite2D>("Sprite2D");
    }
}
```

The pattern of grabbing references to children in `_Ready` is *common but brittle*. Better patterns are covered in [nodes-and-architecture.md](nodes-and-architecture.md) — using `[Export]` to assign references in the inspector, or using groups/signals to avoid the path-based lookup entirely.

## Signals

Signals are Godot's event system. A node *emits* a signal when something happens; other nodes *connect* to that signal to react.

In C#, signals are declared with the `[Signal]` attribute on a delegate type:

```csharp
public partial class Health : Node
{
    [Signal] public delegate void DamagedEventHandler(int amount, int newHealth);
    [Signal] public delegate void DiedEventHandler();

    [Export] public int MaxHealth = 100;
    private int _currentHealth;

    public override void _Ready()
    {
        _currentHealth = MaxHealth;
    }

    public void TakeDamage(int amount)
    {
        _currentHealth = Math.Max(0, _currentHealth - amount);
        EmitSignal(SignalName.Damaged, amount, _currentHealth);
        if (_currentHealth == 0)
        {
            EmitSignal(SignalName.Died);
        }
    }
}
```

Then somewhere else (often the parent scene's script) connects to the signal:

```csharp
public override void _Ready()
{
    var health = GetNode<Health>("Health");
    health.Damaged += OnPlayerDamaged;
    health.Died += OnPlayerDied;
}

private void OnPlayerDamaged(int amount, int newHealth)
{
    // Update HUD, play hit animation, screen shake, etc.
}

private void OnPlayerDied()
{
    // Game over flow.
}
```

Note: in C# Godot 4, signals are *strongly typed* via the generated `SignalName` class and the `EventHandler` delegate naming convention. You connect with `+=` and disconnect with `-=`, just like normal C# events. This is much better than the string-based approach used in GDScript and earlier C# versions.

The reason signals matter: they let nodes communicate **without knowing about each other**. The Health node doesn't know about the HUD; the HUD subscribes from the outside. This is the foundation of decoupled scene design.

For deeper signal patterns, see [signals-and-events.md](signals-and-events.md).

## Autoloads (Singletons)

An autoload is a node (or a script) that Godot loads automatically at startup and keeps available globally. Set in **Project Settings → Autoload**.

Common uses:

- **Global game state** — current level, score, settings.
- **Audio bus controllers** — global SFX/music systems.
- **Scene switchers** — handling transitions between scenes.
- **Save manager** — load and save the game from anywhere.
- **Event bus** — a central hub for global events.

Example:

```csharp
// GameState.cs (autoloaded as "GameState")
public partial class GameState : Node
{
    public int Score { get; private set; }
    public int Level { get; private set; } = 1;

    [Signal] public delegate void ScoreChangedEventHandler(int newScore);

    public void AddScore(int amount)
    {
        Score += amount;
        EmitSignal(SignalName.ScoreChanged, Score);
    }
}
```

Anywhere in your code:

```csharp
var gameState = GetNode<GameState>("/root/GameState");
gameState.AddScore(10);
```

Autoloads are powerful and *easily abused*. The temptation is to put everything in autoloads because they're easy to access. The result: a god-singleton that knows everything, and a project where every node depends on the autoload for everything. This is the same anti-pattern as a god class in OO design.

The discipline: use autoloads for *truly global* concerns (game state, audio, scene transitions, saves). Local communication between nodes should use signals and direct references, not autoloads.

For deeper patterns, see [signals-and-events.md](signals-and-events.md).

## The Editor

Godot's editor is part of the workflow, not just a tool to launch scenes. You design scenes in the editor visually:

- **Scene panel** — the node tree of the current scene.
- **Inspector** — the properties of the selected node.
- **Filesystem panel** — files in the project.
- **Output / Debugger** — logs and debugging.
- **2D / 3D viewport** — visual editing of the scene.
- **Script editor** — code editor (or use VS Code / Rider for C#).

Many things are configured in the inspector rather than in code:

- Initial property values
- Signal connections
- Resource references
- Group memberships
- Process modes

This is *good* for things that vary per-instance (a particular enemy's health) and *good* for designer-tweakable values. It's *bad* for anything that needs source-control diffability or that should be the same everywhere — those go in code.

For **C# specifically**, the editor experience is a little weaker than for GDScript: scripts must be compiled, the editor needs to find the .NET assembly, hot-reload doesn't always work. Most C# Godot developers use **VS Code** or **JetBrains Rider** for the actual code editing, with the Godot editor for scene design.

## Resources

A **Resource** is a piece of data saved to disk that can be shared between nodes. Examples: textures, audio streams, fonts, materials, scripts, scenes themselves.

Resources are reference-counted and shared. Two `Sprite2D` nodes that use the same texture share the underlying `Texture2D` resource — no duplication.

You can also create **custom resources** by inheriting from `Resource`:

```csharp
[GlobalClass]
public partial class WeaponData : Resource
{
    [Export] public string WeaponName { get; set; }
    [Export] public int Damage { get; set; }
    [Export] public float AttackSpeed { get; set; }
    [Export] public Texture2D Icon { get; set; }
    [Export] public AudioStream HitSound { get; set; }
}
```

`[GlobalClass]` makes the type available in the editor's "Create New Resource" dialog. You can now create `.tres` files for each weapon, edit them in the inspector, and assign them to nodes via `[Export]`. This is the Godot equivalent of "data files" in other engines and is *the* idiomatic way to handle game data (item stats, ability definitions, level configs, etc.).

```csharp
public partial class Weapon : Node
{
    [Export] public WeaponData Data { get; set; }
}
```

In the editor, you'd assign the `.tres` resource to the `Data` field. At runtime, the weapon has its data without any code knowing the specific weapon names. This pattern scales to thousands of items without any code changes.

## Project Structure

A new Godot project starts with just a `project.godot` file. You add folders as you go. Common conventions (more in [assets/project-structure-template.md](../assets/project-structure-template.md)):

```
project.godot
.godot/                  ← Generated; gitignore this
addons/                  ← Third-party plugins
scenes/                  ← .tscn files
  ├── player/
  ├── enemies/
  ├── levels/
  └── ui/
scripts/                 ← .cs files (or .gd)
  ├── player/
  ├── enemies/
  ├── managers/
  └── utils/
resources/               ← Custom .tres data files
  ├── weapons/
  ├── enemies/
  └── items/
assets/                  ← Raw assets (textures, audio, models)
  ├── sprites/
  ├── audio/
  ├── fonts/
  └── models/
shaders/                 ← .gdshader files
exports/                 ← Generated; gitignore this
```

The structure is flexible — Godot doesn't enforce it. Pick something that scales with the project and stick to it.

## C# Specifics

A few things every C# Godot engineer should know up-front:

- **`Godot.NET.Sdk`** is the project SDK. Your `.csproj` is auto-generated by Godot.
- **`partial` is required** on every class with Godot generated code (which is most node classes).
- **`[Export]` attribute** exposes a field/property to the editor's inspector.
- **`[Signal]` attribute** declares a signal; the convention is `EventHandler` suffix on the delegate.
- **Naming conventions differ from C# norms**: Godot uses `PascalCase` for methods and properties (`_Process`, not `_process`; `GlobalPosition`, not `globalPosition`). Follow Godot's conventions in Godot code.
- **`GD.Print(...)`** is the equivalent of `Console.WriteLine`. `GD.PrintErr(...)` for errors.
- **`Tween` and `SignalAwaiter`** can be `await`ed, integrating with async/await.
- **`ToSignal(node, "name")`** lets you await a signal.

The most important thing about C# in Godot 4: **it's a first-class citizen now**. Earlier versions had a clunky C# story; Godot 4 with .NET 8 is much better. Performance, tooling, and ergonomics are all reasonable. Most of what you'd want from C# (LINQ, async/await, generics, modern syntax) just works.

## Common Mistakes Coming In

A few things that trip up new Godot engineers, especially those coming from Unity:

- **Treating the editor as optional.** Trying to do everything in code. Godot's editor is good and using it is faster.
- **Confusing nodes with components.** A `Sprite2D` is a node, not a component on a "player" object. The player *is* a tree of nodes; the sprite is a child of the player. There's no MonoBehaviour-style component model.
- **Putting movement in `_Process`.** Jitter follows.
- **Not using signals.** Direct method calls everywhere; tightly coupled mess.
- **Autoload abuse.** Everything in singletons; god-bus pattern.
- **Thinking GDScript and C# are interchangeable.** They are *not*. They have different semantics, different performance characteristics, different ecosystem support. Pick one for your project.
- **Path-based `GetNode` everywhere.** Brittle. Use `[Export]` references or `%UniqueName` syntax.
- **Custom UI systems.** Godot's `Control` system is powerful; learning it takes a day; reinventing it takes weeks and produces worse results.
- **Treating `_Ready` like a constructor for the C# class.** Actual C# constructors run *before* the node is in the tree; most setup belongs in `_Ready`.

The rest of this skill's references go deep on each of these topics. Start with this file as the mental model, then read the references that match what you're doing today.

## Related

- [scenes-and-instancing.md](scenes-and-instancing.md) — how scenes compose and instance
- [nodes-and-architecture.md](nodes-and-architecture.md) — node hierarchy as architecture
- [signals-and-events.md](signals-and-events.md) — signal patterns
- [gdscript-vs-csharp.md](gdscript-vs-csharp.md) — language choice and interop
- [godot-anti-patterns.md](godot-anti-patterns.md) — what not to do
