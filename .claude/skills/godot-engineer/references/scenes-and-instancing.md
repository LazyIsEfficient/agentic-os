# Scenes and Instancing

Scenes are the most powerful and most misused feature in Godot. They're how you compose a game out of reusable, self-contained pieces. They're also where most projects collapse into chaos when they're not used well — too many scenes and the project is fragmented, too few and you've built a god-scene.

This file is the playbook for getting scene composition right.

## What a Scene Actually Is

A scene is a tree of nodes saved as a `.tscn` file. The root node is the "type" of the scene; the children are its parts. The whole tree is the *template* — when you instance the scene, you get a copy of the entire tree, with overrides applied at the root.

A scene has three properties that matter:

1. **It's a template.** Instancing it gives you a fresh copy.
2. **It's editable in the inspector** at the instance level. Override values; change properties; add child nodes.
3. **Changes to the source `.tscn` propagate to all instances.** Update the player scene; every level using the player scene gets the update.

The third property is what makes scenes powerful and what makes them dangerous. A change to a heavily-used scene affects every place it's used; sometimes that's exactly what you want, and sometimes it breaks four levels you forgot about.

## When to Make Something a Scene

A useful test: would you ever want to use this exact tree of nodes more than once, or have a designer reuse it without engineering's help?

If yes → it's a scene.

If no → it's just a child node of the parent, no separate scene needed.

Concrete examples:

| Thing | Scene? | Why |
|---|---|---|
| Player character | Yes | Reused across levels; complex; deserves its own file |
| Enemy type (e.g., goblin) | Yes | Many instances; reused across levels |
| Bullet | Yes | Spawned dynamically, many instances |
| Pickup item | Yes | Many instances |
| HUD root | Yes | Reused across levels (or at least loaded as one unit) |
| A specific button in the HUD | No | One instance, only meaningful inside the HUD scene |
| A particular level | Yes (it *is* a scene) | Loaded by name |
| A unique boss with one instance | Maybe | Yes if you want it editable separately; no if it lives only in one level |
| A door | Yes | Many instances likely |
| A specific door in a specific level | No | Just a door instance with overrides |
| A reusable AI behavior | Yes | If multiple enemies share it |
| A one-off cutscene trigger | No | Inline child of the level |

The bias should be **toward more scenes**. A few too many is fine; a few too few becomes a god-scene problem fast.

## The God Scene Anti-Pattern

The most common scene-design failure: a single scene that contains everything. The "level" scene has the player inline, the enemies inline, the HUD inline, the pause menu inline, and 50 other things. Every change requires opening this one massive scene; merge conflicts on the `.tscn` are constant.

Symptoms of a god scene:

- The `.tscn` file is hundreds of lines long.
- Multiple people can't work on it without merge conflicts.
- Things that should be reusable across levels are duplicated by hand.
- Adding a new feature means adding new top-level nodes to the god scene.
- The scene takes a long time to open in the editor.

The fix: extract reusable parts into their own scenes. The level scene becomes a thin orchestrator that *instances* other scenes (player, enemies, HUD, pickups). Each piece is owned by its own file.

A healthy level scene might look like:

```
Level1 (Node2D)
├── TileMap (level-specific geometry; can stay inline)
├── Player (instance of player.tscn)
├── Enemies (Node2D)
│   ├── Goblin (instance of goblin.tscn)
│   ├── Goblin (instance of goblin.tscn)
│   └── BossEntrance (Area2D — level-specific)
├── Pickups (Node2D)
│   ├── HealthPotion (instance of health_potion.tscn)
│   └── Coin (instance of coin.tscn)
├── HUD (CanvasLayer; instance of hud.tscn)
└── PauseMenu (CanvasLayer; instance of pause_menu.tscn)
```

The level scene is small. It says "this level has these things, in these positions, with these values." It doesn't define what a player, an enemy, or the HUD *is*.

## Instancing in Code

You instance a scene in two ways:

### In the editor

Right-click a node → "Instance Child Scene" → pick the `.tscn` file. The instance appears with a chain icon, indicating it came from another scene.

### In code

Load the scene as a `PackedScene` resource and call `Instantiate()`:

```csharp
public partial class EnemySpawner : Node2D
{
    [Export] public PackedScene EnemyScene { get; set; }
    [Export] public int SpawnCount = 5;

    public override void _Ready()
    {
        for (int i = 0; i < SpawnCount; i++)
        {
            var enemy = EnemyScene.Instantiate<Enemy>();
            AddChild(enemy);
            enemy.GlobalPosition = GlobalPosition + new Vector2(i * 50, 0);
        }
    }
}
```

A few things to notice:

- **`PackedScene` is a resource type.** Assign it via `[Export]` in the inspector — much cleaner than `GD.Load<PackedScene>("res://path/to/scene.tscn")` scattered through the code.
- **`Instantiate<T>()`** returns the root node typed as `T`. If the scene's root is the right type, this is type-safe; if not, it returns `null` or throws.
- **`AddChild(enemy)`** adds the new instance to the tree. Until you do this, the instance exists in memory but isn't part of the running game.
- **Setting position after `AddChild`** is correct — many nodes initialize properties on entering the tree; setting position before is sometimes overridden.

## Inspector Overrides

When you instance a scene, the instance starts with all the values from the source. You can then *override* any of them in the parent scene:

- Position the enemy differently than the default
- Set a different sprite
- Change the maximum health
- Connect a signal to a different handler
- Add new child nodes

Overrides are stored in the parent `.tscn` file as deltas — only the changed values are saved, so the instance stays small. When the source scene changes, unchanged properties update; changed (overridden) properties keep their override.

This is what makes scenes a real composition system. The base behavior comes from the scene; the per-use customization comes from the parent.

## Scene Inheritance

Godot supports scene *inheritance* — a scene that inherits from another scene and overrides parts of it. This is different from scene instancing.

When to use scene inheritance:

- You have a "base enemy" scene with shared behavior, and "specific enemy" scenes that inherit and override the visuals and stats.
- You have a "menu page" scene with shared layout, and specific pages that inherit and add page-specific content.

When *not* to use scene inheritance:

- For most cases. Composition (instancing reusable child scenes) is simpler and more flexible.
- When the inheritance hierarchy gets deep. Two levels is usually fine; three is suspect; four is a smell.

The classic guideline applies: **prefer composition over inheritance**. Inheritance has its uses but composition scales better and breaks less.

To create an inherited scene: in the editor, **Scene → New Inherited Scene** → pick the parent. The new scene has the parent's tree visible but locked; you can override properties and add children, but you can't modify the parent's structure.

## Unique Names and the `%` Syntax

A common pain point in scenes: holding references to deeply-nested nodes. The brittle way:

```csharp
var label = GetNode<Label>("UI/Container/InfoPanel/StatusLabel");
```

Move "InfoPanel" out of "Container" and the path breaks. Move "StatusLabel" anywhere and the path breaks.

The fix: **scene-unique names**. Right-click a node in the editor → "Access as Scene Unique Name". The node now has a `%` prefix in the scene panel and is accessible by short name from anywhere in the same scene:

```csharp
var label = GetNode<Label>("%StatusLabel");
```

This works regardless of where `StatusLabel` is in the tree, as long as it's in the same scene. Move it; the reference still works.

The trade-offs:

- **Pros:** robust to refactoring; clean code; works across deeply nested trees.
- **Cons:** the names must be unique within the scene; you don't see the path in the code so it's slightly harder to find.

For most cases, scene-unique names are the right call. Use them for any node referenced from script.

## Saving and Loading Scenes

The full machinery for runtime scene loading:

```csharp
// Load a scene from disk into a PackedScene
var scene = GD.Load<PackedScene>("res://scenes/levels/level_2.tscn");

// Instantiate it
var levelInstance = scene.Instantiate<Level>();

// Add it to the tree
GetTree().Root.AddChild(levelInstance);
```

Or, the more idiomatic pattern: change the current scene entirely:

```csharp
GetTree().ChangeSceneToFile("res://scenes/levels/level_2.tscn");
```

`ChangeSceneToFile` unloads the current scene at the end of the frame and replaces it with the new one. This is the standard way to transition between levels, menus, and the main game.

```csharp
// Or, with a pre-loaded PackedScene:
var nextScene = GD.Load<PackedScene>("res://scenes/levels/level_2.tscn");
GetTree().ChangeSceneToPacked(nextScene);
```

A common pattern: an autoload that handles scene changes with transitions:

```csharp
// SceneSwitcher.cs (autoload)
public partial class SceneSwitcher : Node
{
    public async void SwitchScene(string path)
    {
        // Fade to black, await tween
        var tween = CreateTween();
        tween.TweenProperty(GetNode<ColorRect>("Fade"), "color:a", 1.0f, 0.5f);
        await ToSignal(tween, Tween.SignalName.Finished);

        // Change the scene
        GetTree().ChangeSceneToFile(path);

        // Fade back in
        tween = CreateTween();
        tween.TweenProperty(GetNode<ColorRect>("Fade"), "color:a", 0.0f, 0.5f);
    }
}
```

For more transition patterns, see [animation-and-tweens.md](animation-and-tweens.md).

## Communicating Between Scenes

A frequent question: a scene needs to react to something happening in *another* scene. How?

Several patterns, in order of preference:

### 1. Signal up, command down

The most idiomatic Godot pattern. A child scene emits a signal; the parent connects to it and decides what to do (often passing the information to other children).

```
Level
├── Player (emits Damaged signal)
└── HUD (receives information from Level, displays it)
```

The Level scene's script:

```csharp
public override void _Ready()
{
    var player = GetNode<Player>("Player");
    var hud = GetNode<HUD>("HUD");
    player.HealthChanged += hud.OnPlayerHealthChanged;
}
```

The Player doesn't know about the HUD. The HUD doesn't know about the Player. The Level wires them together.

This pattern scales well because each scene only knows about its own children.

### 2. Event bus (autoload)

For truly global events that don't fit a parent-child structure: a singleton autoload that holds signals.

```csharp
// EventBus.cs (autoload)
public partial class EventBus : Node
{
    [Signal] public delegate void PlayerDiedEventHandler();
    [Signal] public delegate void LevelCompletedEventHandler(int levelNumber);
    [Signal] public delegate void ScoreChangedEventHandler(int newScore);
}
```

Any node can emit:

```csharp
GetNode<EventBus>("/root/EventBus").EmitSignal(EventBus.SignalName.PlayerDied);
```

Any node can subscribe:

```csharp
public override void _Ready()
{
    var bus = GetNode<EventBus>("/root/EventBus");
    bus.PlayerDied += OnPlayerDied;
}
```

Use this *sparingly*. The event bus is convenient but it can become a god-singleton if everything goes through it. Reserve it for events that are genuinely global or cross-cut multiple unrelated systems.

### 3. Groups

Godot has a built-in concept of "groups" — string tags you can attach to nodes. You can then send a method call or fetch a list of all nodes in a group.

```csharp
// In an enemy:
public override void _Ready()
{
    AddToGroup("enemies");
}

// Elsewhere:
foreach (var enemy in GetTree().GetNodesInGroup("enemies"))
{
    if (enemy is Enemy e)
    {
        e.OnPlayerSpotted();
    }
}

// Or, broadcast a method call:
GetTree().CallGroup("enemies", "OnPlayerSpotted");
```

Groups are useful for "all of these things at once" patterns. Avoid them for one-to-one communication where signals work better.

### 4. Direct references via `[Export]`

When a parent needs a long-lived reference to a child of another sibling scene, the parent can hold a reference exported in the inspector:

```csharp
public partial class HUD : CanvasLayer
{
    [Export] public Player Player { get; set; }

    public override void _Ready()
    {
        Player.HealthChanged += UpdateHealthBar;
    }
}
```

In the editor, drag the Player node onto the HUD's `Player` field. Now the HUD has a typed reference, no path lookup needed.

This is brittle if the Player node is renamed or moved, but the editor catches it: the field becomes empty and you have to re-assign. Better than a string path.

## Refactoring a Scene Into Reusable Parts

A common task: a scene has grown too big. Here's the workflow to extract a sub-scene:

1. **Identify the subtree** that should be its own scene. It's a logical unit; it has clear boundaries.
2. **Right-click the root of the subtree** → "Save Branch as Scene" → name it.
3. The original scene now contains an *instance* of the new scene where the subtree used to be.
4. Open the new scene independently and verify it still works.
5. Update any references in code to use scene-unique names or `[Export]` references.

Godot handles most of the bookkeeping. The script attached to the subtree's root moves with the subtree into the new scene.

**Caveat**: any signal connections from outside the extracted subtree into the inside will break. You'll need to re-wire them at the new boundary (often by emitting a new signal at the root of the extracted scene, and connecting it from the parent).

## Resource References vs Scene References

Don't confuse them:

- A **`PackedScene`** is a reference to a scene `.tscn` file. You instantiate it to get a tree of nodes.
- A **`Resource`** is a reference to any other resource (texture, audio, custom data).

Both can be assigned via `[Export]`. Both can be loaded with `GD.Load<T>(...)`. They're different types and not interchangeable.

```csharp
[Export] public PackedScene BulletScene { get; set; } // For spawning
[Export] public Texture2D IconTexture { get; set; }    // For displaying
[Export] public AudioStream HitSound { get; set; }     // For playing
```

## Anti-Patterns

- **God scene.** Everything in one `.tscn`. Merge conflicts; long load times; impossible to reuse.
- **Scenes per node.** The opposite extreme: every individual node is its own scene. Excessive fragmentation; the project is hard to navigate.
- **Path-based `GetNode` everywhere.** Brittle; breaks on every refactor. Use `[Export]` references or `%UniqueName`.
- **Reaching across the tree** (e.g., `GetNode("../../UI/HUD/Score")`). Couples the child to the parent's structure. Use signals or pass references.
- **Modifying scene state via global state.** A scene that depends on autoload values for its initial state can't be tested or reused independently.
- **Inheritance instead of composition.** A 3-level deep scene inheritance hierarchy. Hard to reason about; refactor into composed scenes.
- **Hand-duplicating instead of instancing.** Two enemies that should be the same scene type, but were copy-pasted. The next change touches both files.
- **Loading scenes with `GD.Load` in `_Process`.** Slow; allocates; the scene should be a `[Export] PackedScene` cached at `_Ready`.
- **`Free()` instead of `QueueFree()` when removing instances.** Crashes if anyone is iterating.
- **Forgetting to disconnect signals** between scenes that span lifetimes. Memory leaks.
- **Editing `.tscn` files by hand.** They're text format and you *can*, but the editor is the right tool. Hand-edits often produce subtly broken scenes.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — what scenes are, foundationally
- [nodes-and-architecture.md](nodes-and-architecture.md) — node hierarchy as architecture
- [signals-and-events.md](signals-and-events.md) — communication between scenes
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
