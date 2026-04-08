# Input and Controls

Input handling in Godot is built around the **Input Map** — an indirection layer that lets you define abstract "actions" (jump, attack, move_left) and bind them to physical inputs (keys, mouse buttons, controller buttons, touch). Always go through actions, never key codes directly. This is what makes rebinding, controller support, and touch control possible.

This file is the practical guide to input in Godot 4 with C#: setting up the input map, polling vs event-driven input, controllers, touch, custom rebinding, and the gotchas.

## The Input Map

Define your actions in **Project Settings → Input Map**.

For each action, give it a name (`move_left`, `jump`, `attack`, `pause`) and add the inputs that trigger it. You can add multiple inputs per action: keyboard *and* gamepad button *and* mouse button. The action fires when *any* of them is triggered.

Naming conventions:

- **`snake_case`** for action names. Godot's Input class is GDScript-flavored; this is the convention even in C# code.
- **Verbs for one-shot actions**: `jump`, `attack`, `interact`, `pause`.
- **Direction names for axes**: `move_left`, `move_right`, `move_up`, `move_down`. Use four directions even for 2D side-scrollers; you'll thank yourself when you add menu navigation.
- **`ui_*` prefix for menu actions**: Godot has built-in UI actions (`ui_accept`, `ui_cancel`, `ui_left`, `ui_right`, `ui_up`, `ui_down`, `ui_focus_next`, `ui_focus_prev`). Use these for menu and UI navigation; the `Control` system handles them automatically.

## Polling vs Event-Driven Input

Godot supports both styles, and you should know when to use each.

### Polling (in `_PhysicsProcess` or `_Process`)

```csharp
public override void _PhysicsProcess(double delta)
{
    // Held key check
    var direction = Input.GetAxis("move_left", "move_right");

    // Just-pressed (one-shot) check
    if (Input.IsActionJustPressed("jump") && IsOnFloor())
    {
        Velocity = new Vector2(Velocity.X, JumpVelocity);
    }

    // Released this frame check
    if (Input.IsActionJustReleased("jump") && Velocity.Y < 0)
    {
        Velocity = new Vector2(Velocity.X, Velocity.Y * 0.5f); // Variable jump height
    }

    // Currently held check
    if (Input.IsActionPressed("crouch"))
    {
        // Crouching
    }
}
```

The four common methods:

- **`Input.IsActionPressed("name")`** — `true` if the action is currently held.
- **`Input.IsActionJustPressed("name")`** — `true` for one frame when the action transitions from released to pressed.
- **`Input.IsActionJustReleased("name")`** — `true` for one frame when released.
- **`Input.GetAxis("negative", "positive")`** — returns `-1`, `0`, or `1` (or somewhere between for analog input) based on which actions are pressed.

There's also **`Input.GetVector("left", "right", "up", "down")`** which returns a `Vector2` and is useful for movement input — it handles both keyboard and analog stick automatically.

### Event-driven (in `_Input` or `_UnhandledInput`)

```csharp
public override void _UnhandledInput(InputEvent @event)
{
    if (@event.IsActionPressed("jump"))
    {
        // Handle jump
    }
    else if (@event.IsActionPressed("interact"))
    {
        // Handle interact
    }
}
```

The two methods:

- **`_Input(event)`** — receives every input event, before UI processes it.
- **`_UnhandledInput(event)`** — receives input events that haven't been handled by UI nodes.

For most gameplay code, use `_UnhandledInput` so the UI gets first dibs (a player pressing Escape in a menu shouldn't also pause the game).

### When to use which

| Use polling when... | Use events when... |
|---|---|
| You're checking input every frame anyway (player movement, held actions) | The action only matters when it happens (one-shot triggers, menu input) |
| The check is part of physics or processing logic | The action is rare or unpredictable |
| You want continuous response (running, charging) | You're handling text input or special device events |

For player movement, **polling in `_PhysicsProcess`** is the right choice. For one-off actions in menus, event-driven is cleaner.

## Why Always Use Actions

Don't poll keys directly:

```csharp
// Wrong
if (Input.IsKeyPressed(Key.Space)) { ... }

// Right
if (Input.IsActionPressed("jump")) { ... }
```

Reasons:

- **Rebinding is impossible** if your code references specific keys. Players will want to rebind.
- **Controllers don't work** with key-based code.
- **Touch input doesn't fit** into key-based code.
- **Different keyboards** have different layouts; AZERTY users will hit a different key for "Space".
- **The action layer is one line of indirection** that costs you nothing and gains you everything.

The only legitimate use of `IsKeyPressed` directly is in tools or debug code (e.g., a developer key combo to spawn debug entities). For shipped gameplay, always use actions.

## Movement Input Patterns

### 4-direction (top-down)

```csharp
public override void _PhysicsProcess(double delta)
{
    var input = Input.GetVector("move_left", "move_right", "move_up", "move_down");
    Velocity = input * Speed;
    MoveAndSlide();
}
```

### Side-scroller (with jump)

```csharp
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
```

### 3D first-person

```csharp
public override void _PhysicsProcess(double delta)
{
    var inputDir = Input.GetVector("move_left", "move_right", "move_forward", "move_back");
    var direction = (Transform.Basis * new Vector3(inputDir.X, 0, inputDir.Y)).Normalized();

    var velocity = Velocity;
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

    if (!IsOnFloor())
        velocity.Y -= Gravity * (float)delta;

    if (Input.IsActionJustPressed("jump") && IsOnFloor())
        velocity.Y = JumpVelocity;

    Velocity = velocity;
    MoveAndSlide();
}
```

### Mouse look (3D)

```csharp
public override void _Ready()
{
    Input.MouseMode = Input.MouseModeEnum.Captured;
}

public override void _UnhandledInput(InputEvent @event)
{
    if (@event is InputEventMouseMotion motion && Input.MouseMode == Input.MouseModeEnum.Captured)
    {
        var camera = GetNode<Camera3D>("Camera3D");
        RotateY(-motion.Relative.X * MouseSensitivity);
        camera.RotateX(-motion.Relative.Y * MouseSensitivity);

        // Clamp pitch
        var rot = camera.Rotation;
        rot.X = Mathf.Clamp(rot.X, -Mathf.Pi / 2, Mathf.Pi / 2);
        camera.Rotation = rot;
    }

    if (@event.IsActionPressed("ui_cancel"))
    {
        Input.MouseMode = Input.MouseModeEnum.Visible;
    }
}
```

`Input.MouseMode = Captured` locks the mouse to the window and lets you read relative motion from `InputEventMouseMotion.Relative`. `Visible` releases it.

## Controller Support

Godot has good gamepad support out of the box. Once you've defined your actions and added gamepad inputs to them, your code automatically works with controllers.

A few specifics:

### Detecting connected controllers

```csharp
public override void _Ready()
{
    Input.JoyConnectionChanged += OnJoyConnectionChanged;

    // Check existing
    for (int i = 0; i < 4; i++)
    {
        if (Input.IsJoyKnown(i))
        {
            GD.Print($"Controller {i} connected: {Input.GetJoyName(i)}");
        }
    }
}

private void OnJoyConnectionChanged(long device, bool connected)
{
    if (connected)
        GD.Print($"Controller {device} connected: {Input.GetJoyName((int)device)}");
    else
        GD.Print($"Controller {device} disconnected");
}
```

### Analog stick deadzone

When you add a joypad axis to an action in the input map, set the **Deadzone** to about 0.2-0.3. Otherwise, drift on analog sticks will trigger the action.

For more precise control, use `Input.GetVector` with a deadzone parameter:

```csharp
var input = Input.GetVector("move_left", "move_right", "move_up", "move_down", deadzone: 0.2f);
```

### Detecting input device for prompts

A common need: showing the right button prompt depending on whether the player is using keyboard or controller.

Track the last input device used:

```csharp
public partial class InputDeviceTracker : Node
{
    public enum DeviceType { KeyboardMouse, Gamepad }
    public DeviceType LastDevice { get; private set; } = DeviceType.KeyboardMouse;

    [Signal] public delegate void DeviceChangedEventHandler(DeviceType newDevice);

    public override void _Input(InputEvent @event)
    {
        DeviceType? newDevice = @event switch
        {
            InputEventKey or InputEventMouseButton => DeviceType.KeyboardMouse,
            InputEventJoypadButton or InputEventJoypadMotion => DeviceType.Gamepad,
            _ => null
        };

        if (newDevice.HasValue && newDevice.Value != LastDevice)
        {
            LastDevice = newDevice.Value;
            EmitSignal(SignalName.DeviceChanged, (int)LastDevice);
        }
    }
}
```

UI prompts then change based on the latest device. Most games show keyboard prompts by default and switch to controller prompts when a controller input is detected.

## Touch Input

For mobile, Godot supports touch via `InputEventScreenTouch` and `InputEventScreenDrag`. You can also enable **Project Settings → Input Devices → Pointing → Emulate Mouse from Touch** to map touches to mouse events automatically — useful for desktop UI ported to mobile.

Multi-touch is detected by `index` on the events:

```csharp
public override void _Input(InputEvent @event)
{
    if (@event is InputEventScreenTouch touch)
    {
        if (touch.Pressed)
            GD.Print($"Finger {touch.Index} touched at {touch.Position}");
        else
            GD.Print($"Finger {touch.Index} lifted at {touch.Position}");
    }
}
```

For most mobile games, the right pattern is virtual on-screen controls — touch joysticks, touch buttons — implemented as `Control` nodes with their own input handling. Or, with **Emulate Mouse from Touch** enabled, the regular UI controls work.

## Custom Rebinding

Letting players rebind controls is a non-trivial feature but it's important — accessibility, preference, and competitive players all need it. Godot's input map is designed to support it.

The basic pattern: when the player wants to rebind, capture the next input event and replace the action's bindings.

```csharp
public partial class RebindButton : Button
{
    [Export] public string ActionName { get; set; }
    private bool _waitingForInput = false;

    public override void _Ready()
    {
        UpdateLabel();
        Pressed += OnPressed;
    }

    private void OnPressed()
    {
        _waitingForInput = true;
        Text = "Press any key...";
    }

    public override void _UnhandledInput(InputEvent @event)
    {
        if (!_waitingForInput) return;

        if (@event is InputEventKey key && key.Pressed)
        {
            // Replace the action's bindings
            InputMap.ActionEraseEvents(ActionName);
            InputMap.ActionAddEvent(ActionName, key);

            _waitingForInput = false;
            UpdateLabel();
            GetViewport().SetInputAsHandled();
        }
        else if (@event is InputEventJoypadButton joy && joy.Pressed)
        {
            InputMap.ActionEraseEvents(ActionName);
            InputMap.ActionAddEvent(ActionName, joy);

            _waitingForInput = false;
            UpdateLabel();
            GetViewport().SetInputAsHandled();
        }
    }

    private void UpdateLabel()
    {
        var events = InputMap.ActionGetEvents(ActionName);
        if (events.Count > 0)
        {
            Text = events[0].AsText();
        }
    }
}
```

Then save and load the bindings as part of the player's settings file (see [save-load-and-persistence.md](save-load-and-persistence.md)).

A few real-world considerations:

- **Allow multiple bindings per action.** Players want to bind both WASD and arrow keys to movement.
- **Detect conflicts.** Two actions bound to the same key produces ambiguity; warn the player.
- **Allow restoring defaults.** Have a "reset to default" button.
- **Don't allow rebinding `ui_*` actions.** These are needed for menu navigation; if the player rebinds `ui_cancel` away, they can't get back to the menu.
- **Save bindings per device.** Rebinding the gamepad shouldn't affect the keyboard.

## Input in UI

`Control` nodes have their own input handling. The `_GuiInput` method is called when the input event is targeted at this UI node:

```csharp
public partial class CustomButton : Control
{
    public override void _GuiInput(InputEvent @event)
    {
        if (@event is InputEventMouseButton mouse && mouse.Pressed && mouse.ButtonIndex == MouseButton.Left)
        {
            GD.Print("Custom button clicked");
            AcceptEvent();
        }
    }
}
```

UI focus and `ui_*` actions handle most things automatically (Tab between controls, Enter to activate, arrow keys to navigate). Use `_GuiInput` only when you need custom handling.

## Common Gotchas

### `ui_cancel` is `Escape` by default

Pressing Escape closes mouse capture, shows the menu, etc. — because it triggers `ui_cancel`. Don't override it lightly.

### Held vs just-pressed

`IsActionPressed` returns `true` every frame the action is held, *including the frame it was just pressed*. `IsActionJustPressed` is `true` for *exactly one frame*. Mixing them up causes either missed inputs (just-pressed when you wanted continuous) or repeated inputs (just-pressed when you wanted one-shot).

### `_Process` vs `_PhysicsProcess` for input polling

Polling input in `_Process` is fine for most things; polling in `_PhysicsProcess` is fine for things that affect physics. The catch: if you check `IsActionJustPressed` in `_Process` *and* also do something with it in `_PhysicsProcess`, you might miss the just-pressed frame because they don't run at the same time.

The fix: poll input in *one* function, and use it from both contexts via a member variable, or just consistently use `_PhysicsProcess` for input that drives gameplay.

### Mouse position vs viewport coordinates

`InputEventMouseMotion.Position` is in window coordinates. If your game has a non-default viewport (e.g., for pixel art with integer scaling), the mouse position might not match world coordinates. Use `viewport.GetMousePosition()` or transform appropriately.

### Input handled by UI

If a `Control` node consumes an input event, `_UnhandledInput` won't see it. This is *correct* — pressing a button in a menu shouldn't also fire the player's attack. But it can confuse you if you're trying to debug why an action isn't reaching the player.

Use `_Input` (which sees everything) for debugging, and check whether the event is being consumed by a `Control`.

### Multiple input events per frame

A single physics frame can have multiple input events. If a player presses and releases a key within one frame (rare but possible), you'll see both events. Don't assume one event per frame.

## Anti-Patterns

- **Polling raw keys** (`Input.IsKeyPressed`) instead of actions. Breaks rebinding and controller support.
- **Hardcoding controller layouts.** Different controllers have different button positions; use action names.
- **No deadzone on analog sticks.** Drift triggers actions constantly.
- **Mixing `IsActionPressed` and `IsActionJustPressed`** confusingly. Pick the right one for each case.
- **Custom touch controls without considering desktop.** Or vice versa: desktop controls that don't work on touch.
- **Forgetting to call `AcceptEvent()`** when handling input in a `Control`. The event propagates and gets handled twice.
- **No way to rebind.** Ships with hardcoded controls; players can't customize.
- **Rebinding without persistence.** The player rebinds, restarts the game, has to do it again.
- **No conflict detection in rebinding.** Two actions bound to the same key.
- **Rebinding `ui_*` actions.** Player can't navigate menus.
- **Mouse capture without escape.** Player can't get the cursor back; has to alt-tab.
- **Not handling controller disconnect.** Player unplugs the controller mid-game; game crashes or freezes.
- **`_Input` for things that should be in `_UnhandledInput`.** Conflicts with UI.
- **`_UnhandledInput` for global hotkeys.** They should be in `_Input` so they can't be eaten by UI.
- **`Input.GetActionStrength` for digital input.** Returns 0 or 1; use `IsActionPressed`. Use `GetActionStrength` for analog.
- **Handling input in non-active scenes.** A paused scene whose `_PhysicsProcess` still runs (because `ProcessMode` is wrong) still polls input.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — `_Input`, `_UnhandledInput`, and the lifecycle
- [physics-and-collision.md](physics-and-collision.md) — physics-driven input handling
- [ui-and-controls.md](ui-and-controls.md) — `Control` input and `ui_*` actions
- [save-load-and-persistence.md](save-load-and-persistence.md) — saving keybinds
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
