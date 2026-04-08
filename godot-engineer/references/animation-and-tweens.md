# Animation and Tweens

Godot has three different ways to animate things, and the most common Godot mistake is picking the wrong one. Each tool has a specific job; using `AnimationPlayer` when a `Tween` would do is overengineering, and using a `Tween` when `AnimationTree` is the right call is underengineering.

This file is the practical guide to picking the right animation tool and using each one well.

## The Three Tools

| Tool | Best for | Key trait |
|---|---|---|
| **`Tween`** | Short, code-driven, one-off animations: button hover, screen shake, UI fade-in | Created in code; runs once; auto-frees |
| **`AnimationPlayer`** | Authored animations: sprite frames, complex movements, cutscenes, anything you'd want a designer to edit | Lives in the scene; visual editor; reusable |
| **`AnimationTree`** | State-machine-driven animation playback: character animation with states (idle, run, jump, attack) and blending | Wraps `AnimationPlayer`; handles transitions |

The decision tree:

1. **Is this a one-shot effect triggered by code (a button hover, a damage flash, a panel sliding in)?** → `Tween`.
2. **Is this an authored animation that should be edited in the editor (a cutscene, a complex sequence, a sprite animation)?** → `AnimationPlayer`.
3. **Is this a character with multiple animation states that need to blend (idle → walk → run, with crossfades)?** → `AnimationTree` driving an `AnimationPlayer`.

When in doubt: start with `Tween`. It's the simplest and you can always upgrade later.

## `Tween`

A `Tween` interpolates a property from its current value to a target value over time. It's the right tool for code-driven animation.

### Basic usage

```csharp
public override void _Ready()
{
    var tween = CreateTween();
    tween.TweenProperty(this, "position", new Vector2(500, 300), 1.0f);
}
```

This creates a tween that moves the node's position from its current value to (500, 300) over 1 second.

A few things to notice:

- **`CreateTween()`** is a method on `Node`. It returns a `Tween` parented to this node, which auto-frees when the node is freed.
- **`TweenProperty(target, property, value, duration)`** is the most common method. The property name is a string ("position", "modulate", "scale").
- **The tween runs immediately** — no `Play()` call needed.

### Easing and transitions

By default, the tween uses linear interpolation. For more natural animations, set the easing curve and transition type:

```csharp
var tween = CreateTween();
tween.TweenProperty(this, "position", target, 1.0f)
    .SetEase(Tween.EaseType.Out)
    .SetTrans(Tween.TransitionType.Cubic);
```

The available transition types: `Linear`, `Sine`, `Quint`, `Quart`, `Quad`, `Expo`, `Elastic`, `Cubic`, `Circ`, `Bounce`, `Back`, `Spring`. Each can be combined with an easing direction (`In`, `Out`, `InOut`).

A useful default for most game animations is `EaseType.Out` with `TransitionType.Cubic` — feels snappy but natural.

### Sequencing and parallel

Tweens can chain steps:

```csharp
var tween = CreateTween();
tween.TweenProperty(panel, "position:x", 100, 0.5f);  // Move right
tween.TweenInterval(0.2f);                             // Wait 0.2s
tween.TweenProperty(panel, "modulate:a", 0, 0.3f);     // Fade out
tween.TweenCallback(Callable.From(() => panel.QueueFree())); // Cleanup
```

By default, steps run sequentially. To run in parallel, mark the tween as parallel or use `Parallel()`:

```csharp
var tween = CreateTween();
tween.SetParallel(true);
tween.TweenProperty(node, "position:x", 100, 1.0f);
tween.TweenProperty(node, "modulate:a", 0.5f, 1.0f);
tween.TweenProperty(node, "rotation", Mathf.Pi, 1.0f);
// All three run simultaneously
```

Or, mix parallel and sequential:

```csharp
var tween = CreateTween();
tween.TweenProperty(node, "position:x", 100, 1.0f);  // Sequential
tween.Parallel().TweenProperty(node, "modulate", new Color(1, 0, 0), 1.0f); // Parallel with the previous
tween.TweenProperty(node, "scale", new Vector2(2, 2), 0.5f); // Sequential after both finish
```

### Sub-properties

You can tween a sub-property of a property using a colon:

```csharp
tween.TweenProperty(sprite, "modulate:a", 0.0f, 1.0f); // Fade alpha to 0
tween.TweenProperty(sprite, "position:x", 100, 0.5f);  // Move only X
tween.TweenProperty(sprite, "scale:y", 2.0f, 0.3f);    // Scale only Y
```

### Awaiting tweens

Tweens emit a `Finished` signal when they complete. With `await`, you can wait for them:

```csharp
public async void DoSequence()
{
    var tween = CreateTween();
    tween.TweenProperty(this, "position:x", 100, 1.0f);
    await ToSignal(tween, Tween.SignalName.Finished);

    // Continue after the tween finishes
    GD.Print("Tween done");
}
```

### Callbacks

`TweenCallback` lets you call a method as part of the sequence:

```csharp
tween.TweenProperty(door, "rotation", Mathf.Pi / 2, 1.0f);
tween.TweenCallback(Callable.From(() => GetNode<AudioStreamPlayer>("DoorOpen").Play()));
tween.TweenInterval(0.5f);
tween.TweenCallback(Callable.From(() => doorOpened = true));
```

### Killing tweens

If a node is freed mid-tween, the tween is auto-freed too (because `CreateTween` parents it to the calling node). For explicit cleanup, you can `tween.Kill()`.

A common pitfall: if you call `CreateTween()` repeatedly (e.g., on every button press) without killing previous tweens, you stack tweens and they all try to set the same property. The result is jittery or wrong animation.

The fix:

```csharp
private Tween _currentTween;

private void OnHover()
{
    _currentTween?.Kill();
    _currentTween = CreateTween();
    _currentTween.TweenProperty(this, "scale", new Vector2(1.1f, 1.1f), 0.1f);
}
```

### Common Tween patterns

**Screen shake:**

```csharp
public async void Shake(float intensity, float duration)
{
    var camera = GetNode<Camera2D>("Camera2D");
    var startPos = camera.Offset;
    var elapsed = 0.0f;

    while (elapsed < duration)
    {
        camera.Offset = startPos + new Vector2(
            GD.RandRange(-intensity, intensity),
            GD.RandRange(-intensity, intensity)
        );
        await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);
        elapsed += (float)GetProcessDeltaTime();
    }

    camera.Offset = startPos;
}
```

**Hit flash:**

```csharp
public void Flash()
{
    var tween = CreateTween();
    tween.TweenProperty(_sprite, "modulate", new Color(2, 2, 2), 0.05f);
    tween.TweenProperty(_sprite, "modulate", Colors.White, 0.1f);
}
```

**Slide-in panel:**

```csharp
public void Show()
{
    Visible = true;
    Position = new Vector2(-Size.X, Position.Y);
    var tween = CreateTween();
    tween.TweenProperty(this, "position:x", 0, 0.4f).SetTrans(Tween.TransitionType.Cubic).SetEase(Tween.EaseType.Out);
}
```

**Damage number popup:**

```csharp
public override void _Ready()
{
    var tween = CreateTween();
    tween.SetParallel(true);
    tween.TweenProperty(this, "position:y", Position.Y - 50, 0.6f).SetEase(Tween.EaseType.Out);
    tween.TweenProperty(this, "modulate:a", 0, 0.6f).SetDelay(0.2f);
    tween.Chain().TweenCallback(Callable.From(QueueFree));
}
```

## `AnimationPlayer`

`AnimationPlayer` plays *authored* animations — animations created in the editor's animation panel. The animations can target any property of any node, with keyframes, curves, and even method calls.

### When to use

- **Sprite frame animations** (though `AnimatedSprite2D` is often easier)
- **Complex movement sequences** (a chest opening, a flag waving, a NPC's idle gestures)
- **Cutscenes** with multiple things happening
- **Anything you want a non-coder to edit**

### Setting up

Add an `AnimationPlayer` node as a child of whatever you want to animate. Open the animation panel (the bottom of the editor; click the `AnimationPlayer` node first to enable it). Click "Animation → New" to create an animation.

Then, while recording is enabled (the red dot button on the animation panel), tweak properties of nodes in the scene. Each tweak creates a keyframe.

### Playing animations from code

```csharp
public partial class Player : CharacterBody2D
{
    private AnimationPlayer _anim;

    public override void _Ready()
    {
        _anim = GetNode<AnimationPlayer>("AnimationPlayer");
    }

    public override void _PhysicsProcess(double delta)
    {
        // ... movement code ...

        if (Velocity.X != 0)
            _anim.Play("walk");
        else
            _anim.Play("idle");
    }
}
```

`Play("name")` is idempotent — calling it repeatedly with the same name doesn't restart the animation. To force a restart, use `Stop()` then `Play()`, or `Seek(0); Play()`.

### Method tracks

`AnimationPlayer` can call methods on nodes as part of an animation. This is how you trigger sound effects, particle spawns, or anything else at a specific moment in an animation.

In the animation panel, right-click → "Add Track" → "Method Call Track" → pick the node and method.

This is useful for things like "play hit sound at frame 5 of the attack animation" — the timing is authored in the animation, not hardcoded in script.

### Awaiting animations

```csharp
_anim.Play("attack");
await ToSignal(_anim, AnimationPlayer.SignalName.AnimationFinished);
GD.Print("Attack animation finished");
```

This is great for cutscene-style sequencing.

### Animation libraries

For projects with many animations across many characters, `AnimationLibrary` lets you organize animations into reusable libraries that can be assigned to multiple `AnimationPlayer`s. Useful for a project with 20 enemy types that share an animation set.

## `AnimationTree`

`AnimationTree` is the state-machine-driven layer on top of `AnimationPlayer`. It handles transitions between animations with blending, parameters, and a visual state machine editor.

### When to use

- **Character animation with multiple states**: idle, walk, run, jump, attack, hurt, die — with smooth blending between them.
- **Animations parameterized by inputs**: blend between walk-forward, walk-left, walk-right based on input direction.
- **Complex animation logic** that would be a mess of `if/else` calls to `AnimationPlayer.Play()`.

### Setting up

1. Add an `AnimationPlayer` with all your individual animations (idle, walk, etc.).
2. Add an `AnimationTree` node as a sibling.
3. Set the `AnimationTree`'s `Anim Player` to point at the `AnimationPlayer`.
4. Set the `Tree Root` to a new `AnimationNodeStateMachine`.
5. Click `Active → True`.
6. Open the `AnimationTree` in the editor (the tree icon at the bottom). You see a visual state machine editor.

In the state machine editor, add states (each state plays an animation), connect them with transitions, set transition conditions and parameters.

### Playing states from code

```csharp
public partial class Enemy : CharacterBody2D
{
    private AnimationTree _animTree;
    private AnimationNodeStateMachinePlayback _stateMachine;

    public override void _Ready()
    {
        _animTree = GetNode<AnimationTree>("AnimationTree");
        _stateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/playback");
    }

    public void StartAttack()
    {
        _stateMachine.Travel("attack");
    }

    public void StartIdle()
    {
        _stateMachine.Travel("idle");
    }
}
```

`Travel("state_name")` tells the state machine to transition to the named state, going through any intermediate states required by the transition graph. `Start("state_name")` immediately starts the state without transitions.

### Blend trees

Within a state, you can use blend trees to mix animations based on parameters. The most common: a `BlendSpace2D` for directional blending.

Example: a 2D blend space with `idle` at the center, `walk_up`, `walk_down`, `walk_left`, `walk_right` at the edges. Set the blend position based on input:

```csharp
public override void _PhysicsProcess(double delta)
{
    var input = Input.GetVector("move_left", "move_right", "move_up", "move_down");
    _animTree.Set("parameters/movement/blend_position", input);
    Velocity = input * Speed;
    MoveAndSlide();
}
```

The animation smoothly blends between the directional animations as the input changes.

### `AnimationTree` vs hand-rolled state machine

If you have a hand-rolled state machine (see [nodes-and-architecture.md](nodes-and-architecture.md)) that drives an `AnimationPlayer`, you might wonder whether to switch to `AnimationTree`.

| Use `AnimationTree` when... | Use hand-rolled when... |
|---|---|
| Animation transitions are the core of the state machine | The state machine governs more than just animations (gameplay logic, AI decisions) |
| You want a visual editor for transitions | You want full control in code |
| Blending between animations matters | Discrete animation playback is fine |
| The state machine is complex enough to benefit from a graph | The state machine is simple |

Many games use both: a hand-rolled state machine for gameplay state, an `AnimationTree` for animation state, with the gameplay state machine telling the `AnimationTree` what to do.

## Other Animation Patterns

### `AnimatedSprite2D`

For simple sprite-frame animations (a 4-frame walk cycle, a 6-frame idle), `AnimatedSprite2D` with `SpriteFrames` is the easiest path. No `AnimationPlayer` needed.

```csharp
var sprite = GetNode<AnimatedSprite2D>("AnimatedSprite2D");
sprite.Play("walk");
```

The frames are configured in the inspector with the `SpriteFrames` editor.

### `Particles2D` and `Particles3D`

For particle effects, use the particle nodes. They're not animations exactly but they handle large numbers of moving sprites efficiently.

### Manual interpolation

For trivial cases, you can interpolate manually:

```csharp
public override void _Process(double delta)
{
    Position = Position.Lerp(_target, (float)delta * 5.0f);
}
```

This is fine for simple smoothing (camera follow, UI smoothing). For anything more complex, prefer `Tween`.

## Animation Anti-Patterns

- **Using `Tween` for sprite frame animation.** Use `AnimatedSprite2D` or `AnimationPlayer`.
- **Using `AnimationPlayer` for hit flashes and screen shake.** Overkill — `Tween` is right.
- **Hand-coding state transitions** when `AnimationTree` would handle them with a visual editor.
- **Calling `Play("idle")` every frame.** It's idempotent for the same animation, but if you flip rapidly between two animations, the playback state is unpredictable.
- **Stacking tweens on the same property** without killing the previous one. Jittery results.
- **Tweens not parented to a node.** If you do `var tween = new Tween()` instead of `CreateTween()`, you have to add it to the tree manually and free it manually.
- **Interpolating in `_PhysicsProcess` for visual effects.** Use `_Process` for visuals.
- **Animation method tracks calling methods that don't exist.** Silent failure; the animation looks broken.
- **`AnimationPlayer` for cutscenes that never re-play.** Sometimes a `Tween` sequence in code is fine.
- **Forgetting to set `AnimationTree.Active = true`.** Nothing plays.
- **Mixing `Tween` and `AnimationPlayer` on the same property.** They fight; the result is unpredictable.
- **Not awaiting animations** when sequencing matters. Async/await with `ToSignal` is much cleaner than callback chains.
- **Hardcoding animation timing in code** when it should be in the animation file. Designers can't tweak it without bothering an engineer.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — `Node` lifecycle
- [nodes-and-architecture.md](nodes-and-architecture.md) — state machines
- [signals-and-events.md](signals-and-events.md) — awaiting tween/animation completion
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
