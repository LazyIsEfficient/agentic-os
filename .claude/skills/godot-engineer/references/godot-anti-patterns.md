# Godot Anti-Patterns

A catalogue of the most common ways Godot projects go wrong. Each anti-pattern is real, observable, and recoverable. The point of naming them is not to shame anyone — every Godot engineer has done some of these — but to recognize them in your own work and in your team's so they can be addressed.

The other reference files in this skill all have anti-pattern sections specific to their topic. This file collects the *cross-cutting* patterns — the ones that span multiple subsystems or describe how the project as a whole goes wrong.

## Architectural Anti-Patterns

### The God Scene

**The pattern:** a single `.tscn` file contains everything. The "level" scene has the player inline, the enemies inline, the HUD inline, the pause menu inline, the AI inline, the save logic inline. Every change opens this one massive file.

**Why it happens:**

- Starting from a tutorial that built a small game in one scene.
- Inertia — the project grew without anyone factoring it.
- Engineers afraid of refactoring because the editor doesn't track scene relationships well.

**Symptoms:**

- The `.tscn` file is hundreds of lines long.
- Multiple people can't work on it without merge conflicts.
- Things that should be reusable across levels are duplicated by hand.
- Adding a new feature means adding new top-level nodes to the god scene.
- The scene takes seconds to open in the editor.

**The fix:** extract reusable parts into their own scenes. The level scene becomes a thin orchestrator that *instances* other scenes (player, enemies, HUD, pickups). See [scenes-and-instancing.md](scenes-and-instancing.md).

### The God Script

**The pattern:** one `Player.cs` (or whatever) file with 1,500 lines that handles movement, animation, sound, UI updates, save state, score tracking, AI behavior, and inventory. Every change requires editing this one file.

**Why it happens:**

- Starting with a simple player and adding features without restructuring.
- Coming from an OO background where putting everything in one class is the default.
- Not knowing about node composition.

**Symptoms:**

- The script imports everything.
- Multiple unrelated tests would have to be written for the same class.
- Merge conflicts on the script are constant.
- Refactoring is impossible because every method depends on every field.

**The fix:** decompose into focused child nodes. A player has a Health node, a Movement node, an Inventory node, a StateMachine node — each with one job. See [nodes-and-architecture.md](nodes-and-architecture.md).

### Tight Coupling via `GetNode` Paths

**The pattern:** scripts reach into other parts of the tree with explicit paths.

```csharp
GetNode<Label>("../../../UI/HUD/Score").Text = $"Score: {_score}";
```

**Why it's wrong:**

- Renames break it.
- Reorganization breaks it.
- The script is now coupled to a specific tree structure.
- Refactoring is dangerous.
- Reusing the scene in a different parent is impossible.

**The fix:** use signals to send events outward; let the listener subscribe. Or use `[Export]` references for direct assignments via the inspector. Or use scene-unique names (`%`) for in-scene lookups. See [signals-and-events.md](signals-and-events.md).

### Autoload Abuse

**The pattern:** every shared concern goes through autoloads. Game state, audio, save manager, scene switcher, level data, settings, achievements, inventory, dialogue, UI manager — all autoloads. The autoloads import each other; they accumulate methods over time; soon every node depends on the autoloads for everything.

**Why it happens:**

- Autoloads are easy to access from anywhere.
- They feel like a global namespace, which is convenient.
- The cost of fragmentation isn't visible until the project is large.

**Symptoms:**

- The autoload list in project settings has 10+ entries.
- Most scripts start with `var gameState = GetNode<GameState>("/root/GameState");`.
- Removing or changing an autoload breaks everything.
- Tests are impossible because every test requires the entire autoload graph.
- New team members can't understand the project without learning the autoload conventions.

**The fix:** use autoloads sparingly, for *truly global* concerns (game-wide state, scene transitions, audio bus management). Local communication should use signals and direct references. When an autoload grows too large, decompose it; not every "manager" needs to be a singleton.

### Autoload-as-Service-Locator

**The pattern:** an autoload exposes a registry of "services" that nodes look up by name. Looks decoupled; isn't.

**Why it's wrong:**

- It's still a singleton with a slightly fancier API.
- The runtime lookup hides the dependency.
- Tests can't substitute services without monkey-patching.
- Refactoring is harder, not easier, because the dependencies are invisible.

**The fix:** explicit dependencies via `[Export]` references or constructor parameters. Pass services in, don't fetch them.

## Process Anti-Patterns

### Movement in `_Process`

**The pattern:** physics body movement code in `_Process` instead of `_PhysicsProcess`. Often copied from a tutorial that didn't understand the difference.

**Symptoms:**

- The character moves jittery, especially at non-default framerates.
- Collisions sometimes don't work as expected.
- The game runs differently on faster vs slower machines.

**The fix:** put physics body movement in `_PhysicsProcess`. Always. See [physics-and-collision.md](physics-and-collision.md).

### `_PhysicsProcess` for Visuals

**The opposite pattern:** putting visual smoothing or camera follow in `_PhysicsProcess`. Visual code locked to the physics tick rate (often 60Hz) doesn't take advantage of higher frame rates and looks stuttery on 144Hz monitors.

**The fix:** visual smoothing goes in `_Process`. Physics goes in `_PhysicsProcess`.

### Polling in `_Process` Instead of Signals

**The pattern:** updating UI from `_Process` by reading game state every frame.

```csharp
public override void _Process(double delta)
{
    var label = GetNode<Label>("HealthLabel");
    label.Text = $"HP: {Player.Health}";
}
```

**Why it's wrong:**

- The UI updates 60 times per second even when nothing changed.
- String allocations every frame trigger GC.
- The script is coupled to the player's state.

**The fix:** use a signal. The player emits `HealthChanged`; the UI listens; the label updates only when the value changes.

### Doing Everything in `_Ready`

**The pattern:** every node's `_Ready` does heavy work — loading resources, instantiating children, building meshes, computing pathfinding grids. The level takes seconds to load.

**The fix:**

- **Defer heavy work.** Use `CallDeferred` or background loading.
- **Show a loading screen.** If the work has to happen, give the player visual feedback.
- **Lazy-initialize** when possible. Don't compute the dialog tree until the dialog opens.
- **Profile the load.** Find which `_Ready` is slow.

### `GetNode` in Tight Loops

**The pattern:** calling `GetNode<T>("path")` inside `_Process` or `_PhysicsProcess` every frame.

**Why it's wrong:** string lookups against the scene tree are not free. Doing them every frame for every node compounds.

**The fix:** cache references in `_Ready`. Or use scene-unique names (`%`) which have a faster lookup path.

## Code Anti-Patterns

### `new ClassName()` Instead of Instantiating Scenes

**The pattern:** creating nodes with the C# constructor instead of `PackedScene.Instantiate<T>()`.

```csharp
// Wrong: misses children, signals, exports
var enemy = new Enemy();
AddChild(enemy);

// Right: creates the full scene with all its parts
var enemy = EnemyScene.Instantiate<Enemy>();
AddChild(enemy);
```

**Why it's wrong:** the `new` constructor only creates the C# class instance. The scene's children, exports, and editor configuration are missed.

**The fix:** always instantiate scenes from `PackedScene` references.

### `Free()` Instead of `QueueFree()`

**The pattern:** calling `node.Free()` to immediately destroy a node.

**Why it's wrong:** if any code is still iterating over the node's children or holding references, you get a "freed object" error or a crash.

**The fix:** `QueueFree()` schedules the free for the end of the frame, after iteration is safe. Use it 99% of the time.

### Mutating `Vector2`/`Vector3` Properties

**The pattern:** trying to mutate a struct property in place.

```csharp
// Wrong: doesn't compile, but the spirit is wrong
GetNode<Sprite2D>("Sprite").Position.X += 10;

// What people actually write:
var sprite = GetNode<Sprite2D>("Sprite");
sprite.Position.X = 10; // This compiles in C# but doesn't update the sprite
```

**Why it's wrong:** Godot's vector types are *value types* (structs). Reading `Position` returns a copy; modifying the copy doesn't propagate.

**The fix:**

```csharp
// Read, modify, write
var pos = sprite.Position;
pos.X += 10;
sprite.Position = pos;

// Or in one line:
sprite.Position += new Vector2(10, 0);
```

### Forgetting `partial`

**The pattern:** writing a Godot script class without `partial`.

```csharp
public class Player : CharacterBody2D { ... }  // Wrong
public partial class Player : CharacterBody2D { ... }  // Right
```

**Why it's wrong:** Godot generates source code for the class (signal name constants, etc.). Without `partial`, the generated code can't merge with yours.

**The fix:** every script class is `partial`. Period.

### String-Based Signal Connections

**The pattern:** using the old string-based API for signal connections.

```csharp
// Old/wrong
health.Connect("Damaged", new Callable(this, nameof(OnDamaged)));

// New/right
health.Damaged += OnDamaged;
```

**Why it's wrong:** the string-based version isn't compile-checked, doesn't update on rename, and is less readable.

**The fix:** use the typed `+=` syntax for all new code.

### Holding References to Freed Nodes

**The pattern:** keeping a C# reference to a Godot node that was freed elsewhere. Calling methods on the reference produces "the object was freed" errors.

**The fix:** check `IsInstanceValid(node)` before using a held reference. Or use weak references. Or don't hold references that can outlive the node.

### Constructor Logic for Nodes

**The pattern:** doing setup in the C# constructor.

```csharp
public Player()
{
    _sprite = GetNode<Sprite2D>("Sprite2D");  // Crashes; not in tree yet
}
```

**Why it's wrong:** the constructor runs *before* the node is added to the tree. `GetNode` and other tree-dependent operations don't work.

**The fix:** put setup in `_Ready`, which runs after the node is in the tree.

### Synchronous `GD.Load` in Hot Paths

**The pattern:** loading resources by string path in `_Process` or in code that runs frequently.

```csharp
public override void _Process(double delta)
{
    var bullet = GD.Load<PackedScene>("res://bullet.tscn"); // Loads every frame
    // ...
}
```

**Why it's wrong:** `GD.Load` is cached but still has overhead, especially the first time.

**The fix:** use `[Export] PackedScene` and assign in the inspector. Cache in `_Ready` if you need to load programmatically.

## Resource Anti-Patterns

### Mutating Shared Resources

**The pattern:** modifying a `Resource` at runtime, expecting the change to be local — but the resource is shared between instances and the change affects everyone.

```csharp
var weapon = GetNode<Weapon>("Weapon");
weapon.Data.Damage = 100; // Mutates the shared WeaponData resource!
```

**Why it's wrong:** resources are reference-counted and shared by default. Two weapons that use the same `WeaponData` *literally share* it.

**The fix:** if you need per-instance state, put it on the *node*, not on the resource. Or use `Resource.Duplicate()` to create a copy.

### Not Using Resources for Data

**The opposite pattern:** hardcoding game data in scripts instead of using resources.

```csharp
public partial class WeaponDatabase : Node
{
    public static readonly Dictionary<string, int> WeaponDamages = new()
    {
        { "sword", 10 },
        { "axe", 15 },
        { "bow", 8 },
        // ... grows forever
    };
}
```

**Why it's wrong:** every change requires a code edit and recompile. Designers can't tweak values. The data and code are mixed.

**The fix:** use custom `Resource` types with `[Export]` fields. Each weapon is a `.tres` file. Designers can add and tweak weapons in the editor without touching code.

### `.tres` Files Without `[GlobalClass]`

**The pattern:** custom `Resource` types that aren't decorated with `[GlobalClass]`. The editor doesn't know how to create them.

**The fix:** add `[GlobalClass]` to make custom resource types visible in the editor's "Create New Resource" dialog.

## Workflow Anti-Patterns

### Editor as Optional

**The pattern:** doing everything in code; treating the editor as a debugger and runner only.

**Why it's wrong:** Godot's editor is good. Many things (signal connections, instance overrides, animation editing, theme creation) are faster in the editor. Trying to do them in code is slower and harder.

**The fix:** use the editor for what it's good at. Use code for what code is good at. Don't be religious about either.

### Hand-Editing `.tscn` Files

**The pattern:** opening `.tscn` or `.tres` files in a text editor and editing them directly.

**Why it's wrong:** these files have a specific format Godot expects. Hand edits often produce subtly broken files that work in some cases and crash in others.

**The fix:** use the editor. The only legitimate reason to touch `.tscn` directly is bulk find-and-replace operations or merge conflict resolution — and even then, open the file in Godot afterward to verify.

### Mixing GDScript and C# in the Same Codebase

**The pattern:** half the project is in C#, half is in GDScript, the two interop constantly.

**Why it's wrong:** every interop call has overhead, isn't type-checked, and is awkward. Refactoring is harder. Onboarding is harder.

**The fix:** pick one for the main codebase. Mix only when there's a specific reason — a GDScript editor plugin you're using, a quick `@tool` script, etc.

### Not Source-Controlling `.import` Files

**The pattern:** committing `.tscn`, `.cs`, and assets but not the `.import` files.

**Why it's wrong:** `.import` files contain the import settings for each asset. Without them, every developer who opens the project re-imports with default settings, potentially breaking things.

**The fix:** commit `.import` files. They're source.

### Committing the `.godot/` Folder

**The opposite pattern:** committing the auto-generated `.godot/` folder, which contains caches and generated files.

**The fix:** add `.godot/` to `.gitignore`. It's per-machine cache.

### No Branching for Risky Changes

**The pattern:** working directly on `main`. A risky scene refactor breaks the project; rolling back is hard because of how Godot handles `.tscn` files.

**The fix:** branch for risky work. Test the branch. Merge when it's stable. Standard software practice; especially important in Godot because `.tscn` files are awkward to merge.

### No Backups of Save Files During Development

**The pattern:** the dev game writes to `user://` and overwrites valuable test saves.

**The fix:** during development, write to a versioned subfolder. Or back up the user folder regularly.

## Performance Anti-Patterns

### Optimizing Without Profiling

**The pattern:** rewriting code to be "faster" based on intuition. Often makes things slower or more complex without benefit.

**The fix:** profile first. Optimize the bottleneck. Re-measure. See [performance-and-profiling.md](performance-and-profiling.md).

### Allocating in Hot Paths

**The pattern:** creating new objects, lists, strings, or collections every frame.

**Why it's wrong:** GC pressure produces visible hitches.

**The fix:** reuse buffers. Cache strings. Avoid `new` in `_Process` for reference types.

### Real-Time Lights for Static Scenes

**The pattern:** lighting an outdoor 3D scene with 20 real-time directional and point lights.

**The fix:** bake static lighting. Use real-time lights only for dynamic things.

### Custom Shaders That Reinvent Standard Material

**The pattern:** a shader that does what `StandardMaterial3D` already does, just because.

**The fix:** use `StandardMaterial3D` unless you genuinely need something it doesn't provide.

## Multiplayer Anti-Patterns

(Covered in detail in [multiplayer-and-websockets.md](multiplayer-and-websockets.md). Highlights:)

- **Trusting the client.** Validate everything server-side.
- **Authority on the client** in competitive games. Cheating.
- **No reconnection logic.** Network blip = game over.
- **Sending state every frame.** Bandwidth nightmare; use rate limiting and interpolation.
- **No TLS in production.** Plaintext WebSockets.

## UI Anti-Patterns

(Covered in detail in [ui-and-controls.md](ui-and-controls.md). Highlights:)

- **Manually positioning everything.** Containers exist.
- **Hardcoded screen sizes.** Use anchors and stretch settings.
- **Reinventing the theme system.** Use Godot's.
- **UI in world space, not in `CanvasLayer`.** UI scrolls with the camera.

## Save Anti-Patterns

(Covered in detail in [save-load-and-persistence.md](save-load-and-persistence.md). Highlights:)

- **No version field.** Updates break existing saves.
- **No migration code.** Saves crash on load after upgrade.
- **`res://` instead of `user://`.** Doesn't work; read-only.
- **No autosave.** Players lose progress on crash.
- **Direct write to the real file.** Mid-write crash corrupts the save.

## General Anti-Patterns

### Tutorials as Architecture

**The pattern:** structuring the project the way a tutorial showed you, even when it doesn't fit your project's needs. Tutorials are designed to be simple and self-contained, not to scale.

**The fix:** learn from tutorials, then *think about your specific project's needs*.

### "I'll Refactor Later"

**The pattern:** accumulating technical debt while telling yourself you'll fix it after the next milestone. The refactor never comes.

**The fix:** allocate time for refactoring as you go. The cost compounds; doing it later is always more expensive than doing it now.

### Testing Only the Happy Path

**The pattern:** the game works when the player does what you expect. It crashes or does weird things when they do anything else.

**The fix:** test the unhappy paths. What happens when the player tries to interact with two things at once? When they pause mid-attack? When they alt-tab during a cutscene?

### Not Testing on the Target Platform

**The pattern:** developing on a high-end PC, exporting to mobile/web/console at the end.

**The fix:** test on target platforms continuously. Problems found late are more expensive than problems found early.

### No Crash Reporting in Production

**The pattern:** ship the game; players have crashes; you have no idea.

**The fix:** integrate a crash reporter. Sentry, Bugsnag, or a simple in-game error logger that submits via HTTP.

### Working on `main` Without Branches

**The pattern:** all changes go directly to `main`. Risky refactors break the build for everyone.

**The fix:** branches for non-trivial work. Standard practice.

### Treating Godot Like Unity (or Vice Versa)

**The pattern:** importing Unity (or Unreal, or GameMaker) idioms into Godot. The result is a Godot project that fights the engine.

**Specific manifestations:**

- "MonoBehaviour"-style components attached to one node, instead of node composition.
- "Prefabs" mental model for scenes (close but not the same).
- Singleton "managers" everywhere because that was the Unity pattern.
- Building a custom UI system because "Unity UI is better."

**The fix:** learn Godot's idioms. They're different from Unity/Unreal/GameMaker, and they're often *better* for the things Godot is built for.

## Related

Every other reference file in this skill has its own anti-patterns section. This one is the cross-cutting overview.

- [godot-fundamentals.md](godot-fundamentals.md) — the engine model
- [scenes-and-instancing.md](scenes-and-instancing.md) — god scenes, scene composition
- [nodes-and-architecture.md](nodes-and-architecture.md) — god scripts, composition
- [signals-and-events.md](signals-and-events.md) — signal patterns
- [physics-and-collision.md](physics-and-collision.md) — `_PhysicsProcess` mistakes
- [performance-and-profiling.md](performance-and-profiling.md) — performance anti-patterns
- [save-load-and-persistence.md](save-load-and-persistence.md) — save anti-patterns
- [multiplayer-and-websockets.md](multiplayer-and-websockets.md) — networking anti-patterns
- software-design — broader software design principles
