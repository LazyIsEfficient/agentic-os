# Signals and Events

Signals are Godot's event system, and they're the single most important architectural tool the engine gives you. Used well, they let nodes communicate without knowing about each other; the result is a project where scenes are reusable, refactoring is safe, and adding features doesn't require touching unrelated code.

Used badly — or not at all — Godot projects collapse into spaghetti where every node holds direct references to every other node. The codebase becomes impossible to refactor and impossible to test.

This file is about signal patterns in C# Godot 4: when to use them, how to structure them, and when to reach for an autoload event bus instead.

## What a Signal Is

A signal is an event a node can *emit*. Other nodes can *connect* to that event and receive a callback when it fires. The emitter doesn't know who's listening; the listener has a typed connection to the emitter.

In C# Godot 4, signals are declared as delegate types with the `[Signal]` attribute, ending in `EventHandler` (this naming is required by the source generator):

```csharp
public partial class Health : Node
{
    [Signal] public delegate void DamagedEventHandler(int amount, int currentHealth);
    [Signal] public delegate void HealedEventHandler(int amount, int currentHealth);
    [Signal] public delegate void DiedEventHandler();

    [Export] public int MaxHealth { get; set; } = 100;
    public int Current { get; private set; }

    public override void _Ready()
    {
        Current = MaxHealth;
    }

    public void TakeDamage(int amount)
    {
        var newHealth = Math.Max(0, Current - amount);
        var actualDamage = Current - newHealth;
        Current = newHealth;

        EmitSignal(SignalName.Damaged, actualDamage, Current);

        if (Current == 0)
            EmitSignal(SignalName.Died);
    }

    public void Heal(int amount)
    {
        var newHealth = Math.Min(MaxHealth, Current + amount);
        var actualHeal = newHealth - Current;
        Current = newHealth;
        EmitSignal(SignalName.Healed, actualHeal, Current);
    }
}
```

A few patterns:

- **`SignalName.Damaged`** is a generated constant for the signal name. Preferable to the raw string `"Damaged"` because typos are caught at compile time.
- **Multiple parameters** are passed in `EmitSignal` after the signal name.
- **The same emitter can emit different signals** for different events.

## Connecting Signals

Two ways: in the editor, or in code.

### In the editor

Select the emitter node, look at the **Node** panel (next to Inspector), find the signal in the list, double-click. Pick the receiver node and the method name.

This is convenient for quick connections and for connections that should be visible to designers. The downside: the connection lives in the `.tscn` file rather than in code, so it's not greppable and a refactor of the receiver method name doesn't update the connection.

### In code (the C# 4 idiom)

Use `+=` and `-=` like normal C# events:

```csharp
public partial class HUD : CanvasLayer
{
    [Export] public Health PlayerHealth { get; set; }

    public override void _Ready()
    {
        PlayerHealth.Damaged += OnPlayerDamaged;
        PlayerHealth.Died += OnPlayerDied;
    }

    public override void _ExitTree()
    {
        if (IsInstanceValid(PlayerHealth))
        {
            PlayerHealth.Damaged -= OnPlayerDamaged;
            PlayerHealth.Died -= OnPlayerDied;
        }
    }

    private void OnPlayerDamaged(int amount, int currentHealth)
    {
        // Update health bar
        var healthBar = GetNode<ProgressBar>("%HealthBar");
        healthBar.Value = currentHealth;

        // Flash red, screen shake, etc.
    }

    private void OnPlayerDied()
    {
        var gameOver = GetNode<Control>("%GameOverScreen");
        gameOver.Visible = true;
    }
}
```

This is the right pattern for new code. It's:

- **Type-safe** — the compiler checks the parameter types match.
- **Refactor-friendly** — renaming the method updates the reference.
- **Greppable** — finding all connections to a signal is easy.
- **Idiomatic C#** — uses `+=` like every other event in the .NET world.

The older string-based approach (`Connect("Damaged", new Callable(this, nameof(OnPlayerDamaged)))`) still works but you should avoid it in new code.

## Disconnecting Signals

Always disconnect signals when the connection is no longer needed. The standard place is `_ExitTree`.

```csharp
public override void _ExitTree()
{
    if (IsInstanceValid(_emitter))
    {
        _emitter.SomeSignal -= OnSomeSignal;
    }
}
```

The `IsInstanceValid` check is defensive: if the emitter has been freed first, the connection auto-cleans, and trying to disconnect from a freed object errors.

If both the emitter and the listener are freed at the same time (because they're in the same scene that gets unloaded), no manual disconnect is needed. But if their lifetimes can differ (e.g., one is in an autoload and the other is in a temporary scene), disconnect explicitly.

A useful rule of thumb: **always disconnect what you connect**, in the symmetric lifecycle method:

| Connect in | Disconnect in |
|---|---|
| `_Ready` | `_ExitTree` |
| Constructor | Destructor / `Dispose` (rarely needed; nodes don't usually use this) |
| A specific method | Either explicitly when done, or in `_ExitTree` defensively |

## Signal Patterns

### Pattern 1: Child Emits, Parent Listens

The most common pattern. A child node emits a signal when something happens. The parent script connects to it and decides what to do (often passing the information to other children).

```
Player (Node2D)
├── Health (emits HealthChanged)
├── HealthBar (Control, listens)
└── HitFlash (AnimationPlayer, listens)
```

```csharp
public partial class Player : Node2D
{
    public override void _Ready()
    {
        var health = GetNode<Health>("Health");
        var bar = GetNode<HealthBar>("HealthBar");
        var flash = GetNode<HitFlash>("HitFlash");

        health.Damaged += (amount, current) =>
        {
            bar.UpdateValue(current);
            flash.Play();
        };

        health.Died += () =>
        {
            // Game over, etc.
        };
    }
}
```

The Health node has no idea anyone is listening. The HealthBar has no idea where its updates come from. The Player wires them together. Each child can be removed or replaced without touching the others.

### Pattern 2: Sibling-to-Sibling via Parent

Same as above, but the wiring is between specific siblings rather than parent-and-child. The parent is the matchmaker.

```csharp
public override void _Ready()
{
    var enemy = GetNode<Enemy>("Enemy");
    var loot = GetNode<LootDropper>("LootDropper");

    enemy.Died += (position) => loot.DropAt(position);
}
```

The enemy doesn't know about loot dropping. The loot dropper doesn't know about enemies. The level wires them together — and could just as easily wire a *different* loot dropper to a *different* enemy.

### Pattern 3: Lambda Connections for Simple Cases

For one-off connections that don't need disconnecting, lambdas are concise:

```csharp
GetNode<Button>("StartButton").Pressed += () => GetTree().ChangeSceneToFile("res://levels/level_1.tscn");
GetNode<Button>("QuitButton").Pressed += () => GetTree().Quit();
```

The downside: lambdas can't be disconnected by reference (you'd need to store the lambda first). For long-lived connections that need explicit disconnect, use named methods.

### Pattern 4: Signal Bus (Autoload Event Bus)

When events are *truly global* and don't fit a parent-child structure, an autoload event bus is the right tool. Examples: "the player died" (everything in the game might want to know), "the level was completed", "an achievement was unlocked".

```csharp
// EventBus.cs (set as autoload "EventBus")
public partial class EventBus : Node
{
    [Signal] public delegate void PlayerDiedEventHandler();
    [Signal] public delegate void PlayerLeveledUpEventHandler(int newLevel);
    [Signal] public delegate void LevelCompletedEventHandler(int levelNumber);
    [Signal] public delegate void AchievementUnlockedEventHandler(string achievementId);
    [Signal] public delegate void ItemPickedUpEventHandler(string itemId, int quantity);
}
```

Anywhere in the game, emit:

```csharp
GetNode<EventBus>("/root/EventBus").EmitSignal(EventBus.SignalName.PlayerDied);
```

Or, more typed:

```csharp
public partial class Player : CharacterBody2D
{
    private EventBus _bus;

    public override void _Ready()
    {
        _bus = GetNode<EventBus>("/root/EventBus");
    }

    private void OnDied()
    {
        _bus.EmitSignal(EventBus.SignalName.PlayerDied);
    }
}
```

Anywhere else in the game, listen:

```csharp
public override void _Ready()
{
    var bus = GetNode<EventBus>("/root/EventBus");
    bus.PlayerDied += OnPlayerDied;
}
```

The event bus is a powerful pattern. It's also the most-abused. The temptation is to put *every* signal through it because it's easy. The result is a god-singleton — a single file that lists hundreds of signals, every node depending on it for everything.

**Use the bus only for events that are genuinely global** (cross-cut multiple unrelated systems, no clear parent-child relationship, or need to be received by code in completely different scenes). Local communication should use direct signal connections.

A useful test: if the signal logically belongs to one specific node (the player's health, an enemy's death, a button press), it should be on that node. If the signal is a *fact about the world* that many systems might react to (the player died, the level changed), it might belong on the bus.

### Pattern 5: Signal With Awaiter

C# in Godot supports `await`-ing signals via `ToSignal`. This is great for sequenced logic.

```csharp
public async void StartTutorial()
{
    var dialog = GetNode<DialogBox>("DialogBox");
    var anim = GetNode<AnimationPlayer>("AnimationPlayer");

    dialog.Show("Welcome to the game!");
    await ToSignal(dialog, DialogBox.SignalName.Dismissed);

    anim.Play("highlight_player");
    await ToSignal(anim, AnimationPlayer.SignalName.AnimationFinished);

    dialog.Show("Use arrow keys to move.");
    await ToSignal(dialog, DialogBox.SignalName.Dismissed);

    // Wait for the player to actually move
    var player = GetNode<Player>("Player");
    await ToSignal(player, Player.SignalName.Moved);

    dialog.Show("Great! Now try jumping.");
    // ...
}
```

This pattern is much cleaner than chains of nested signal callbacks for sequenced events. Use it for tutorials, cutscenes, dialogue trees, multi-step animations, anything that's "do this, then wait, then do the next thing."

## Direct Method Calls vs Signals

A frequent question: when should I use a signal vs. just calling a method directly?

| Use a method call when... | Use a signal when... |
|---|---|
| The caller naturally has a reference to the callee | The caller doesn't and shouldn't need a reference |
| The caller is *commanding* the callee to do something | The caller is *announcing* something happened |
| The relationship is parent-to-child or owner-to-owned | The relationship is observer/subscriber |
| There's exactly one receiver | There might be zero, one, or many receivers |
| The flow is "I want this to happen" | The flow is "this happened; whoever cares can react" |

Examples:

```csharp
// Method call: parent commands child
enemy.TakeDamage(10);
spawner.Spawn();
audio.PlaySound(SoundType.Hit);

// Signal: child announces; observers react
playerHealth.Damaged += UpdateHud;        // Player doesn't know about HUD
playerHealth.Damaged += FlashScreen;      // Player doesn't know about screen flash
playerHealth.Damaged += LogToTelemetry;   // Player doesn't know about telemetry
```

The discipline: methods for *commands*, signals for *events*. When you want to tell a specific node "do this thing," call its method. When you want to announce "this thing happened," emit a signal.

## Custom Resource as Event Carrier

For complex events with many parameters, consider a custom resource as the event payload:

```csharp
[GlobalClass]
public partial class DamageEvent : Resource
{
    [Export] public int Amount { get; set; }
    [Export] public DamageType Type { get; set; }
    [Export] public Node2D Source { get; set; }
    [Export] public Vector2 HitPoint { get; set; }
    [Export] public bool IsCritical { get; set; }
}

[Signal] public delegate void DamageDealtEventHandler(DamageEvent ev);
```

This is more verbose than passing individual parameters but it's:

- **Extensible**: adding a new field doesn't break existing handlers.
- **Self-documenting**: the type is the schema.
- **Reusable**: the same event type can be used by multiple signals.

Use it when the event has more than ~3 parameters or when the parameters might grow.

## Signal Chains and Order

If multiple handlers are connected to the same signal, they're called in the order they were connected. Don't depend on this order — it's fragile. If you need ordering, use intermediate signals or explicit sequencing.

```csharp
// Fragile: depends on connection order
health.Damaged += OnDamageHandler1;
health.Damaged += OnDamageHandler2;  // Runs after OnDamageHandler1

// Robust: handler1 emits a signal that handler2 listens to
health.Damaged += OnDamageHandler1;
// In OnDamageHandler1, after doing the work:
EmitSignal("DamageHandled");
// And:
this.DamageHandled += OnDamageHandler2;
```

For most cases, just don't depend on order. Each handler should be self-contained.

## Signal Propagation

Godot signals don't propagate up the tree automatically. If a child emits a signal, only nodes that have explicitly *connected* to that signal receive it. This is different from DOM events in web programming.

If you want a "bubble up" pattern, you have to wire it manually: the parent listens to the child's signal, then re-emits its own signal that grandparents can listen to.

```csharp
// Child:
[Signal] public delegate void ButtonClickedEventHandler();

// Parent:
public override void _Ready()
{
    var button = GetNode<MyButton>("Button");
    button.ButtonClicked += () => EmitSignal(SignalName.ChildButtonClicked);
}

[Signal] public delegate void ChildButtonClickedEventHandler();
```

This is verbose. For most cases, a direct connection from the grandparent to the child (using `[Export]` references or scene-unique names) is cleaner. Only re-emit when the grandparent really shouldn't know about the child.

## Anti-Patterns

- **String-based connection** (`Connect("name", ...)`) when typed `+=` is available. Loses compile-time checking.
- **Forgetting to disconnect** when the listener might outlive the emitter. Memory leaks.
- **Disconnecting in the wrong place.** `_Ready` connects, `_ExitTree` disconnects. Don't connect twice without disconnecting.
- **God event bus.** Every signal goes through one autoload. Hides which node owns which event; coupling pretends to be decoupling.
- **Signals as a substitute for direct calls.** When a parent commands a child, use a method call. Signals are for *events*, not for indirection for its own sake.
- **Direct method calls when a signal would do.** When a child needs to tell a parent something, emit a signal — don't call up the tree.
- **`GetParent<T>()` to call a method up the tree.** Couples the child to the parent's type.
- **Lambda connections to long-lived nodes** without storing the lambda. Can't disconnect later.
- **Connecting to a node in `_EnterTree` instead of `_Ready`.** The node's children might not be ready yet.
- **Multiple connections to the same handler.** Easy to do accidentally; produces duplicate calls. Disconnect first if reconnecting.
- **Signal with too many parameters.** If you're passing 6 things, make a resource event payload.
- **Depending on connection order.** Fragile.
- **Propagating signals manually up many levels.** If you need it, restructure: the listener probably wants direct access via `[Export]` or scene-unique name.
- **Using signals where a method call is fine, just because "decoupling is good".** Signals have a small overhead; for hot paths, direct method calls are faster and clearer.
- **Forgetting the `EventHandler` suffix on the delegate.** Won't compile.
- **Forgetting `[Signal]`.** It's just a delegate type, not a signal.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — what signals are, foundationally
- [scenes-and-instancing.md](scenes-and-instancing.md) — wiring scenes together
- [nodes-and-architecture.md](nodes-and-architecture.md) — broader architectural patterns
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
