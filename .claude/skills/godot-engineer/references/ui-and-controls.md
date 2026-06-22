# UI and Controls

Godot's UI system is one of its strengths and one of its most-misunderstood subsystems. The `Control` node, with its anchors and containers, is powerful enough to build complex interfaces — and confusing enough that many engineers spend hours fighting it before learning the patterns.

This file is the practical guide to building UI in Godot 4 with C#. The most important thing to internalize: **don't fight the engine**. Godot's container system is good, the anchor system is good, and reinventing them is almost always wrong.

## The Control System

A `Control` is the base class for all UI elements: buttons, labels, text inputs, panels, sliders, etc. It has properties most other nodes don't:

- **Position** and **size** in screen space (or relative to parent)
- **Anchors** (how it's positioned relative to its parent)
- **Margins** / **offsets** (the actual position computed from anchors and absolute offsets)
- **Min size** (minimum size the layout system will give it)
- **Layout direction** (LTR/RTL for internationalization)
- **Theme** (visual styling)
- **Focus** (for keyboard/gamepad navigation)
- **Mouse filter** (whether it intercepts mouse events)

The system is built around the idea that you can lay out UI by:

1. Setting **anchors** that describe where in the parent the control sticks to
2. Setting **margins** that describe the offset from those anchors
3. Or, using **containers** (described below) that lay out their children automatically

The first approach is for free-floating UI elements; the second is for grids, lists, and structured layouts. Both have their place.

## Anchors and Margins

The anchor system is best understood with a picture, but here's the verbal version: every `Control` has four anchor values (left, top, right, bottom), each between 0 and 1. They describe what *fraction* of the parent the control's edges are anchored to.

| Anchors | What it does |
|---|---|
| `left=0, top=0, right=0, bottom=0` | Top-left corner; size is fixed |
| `left=1, top=1, right=1, bottom=1` | Bottom-right corner; size is fixed |
| `left=0, top=0, right=1, bottom=1` | Stretches to fill the parent |
| `left=0.5, top=0.5, right=0.5, bottom=0.5` | Centered point; size is fixed |
| `left=0, top=0, right=1, bottom=0` | Stretches horizontally at the top |

The **Layout** menu in the inspector (the icon at the top of the Control inspector) has presets: "Center", "Top Left", "Full Rect", "Center Top", etc. These set the anchors for you. **Use the presets** unless you have a specific reason not to.

The **margins** (now called **offsets** in Godot 4) are the absolute pixel offsets from the anchor point. Anchors `(0, 0, 0, 0)` with offsets `(50, 50, 100, 80)` produces a control 50 pixels from the top-left, 50 pixels wide, 30 pixels tall.

In code:

```csharp
var control = GetNode<Control>("MyControl");
control.SetAnchorsPreset(Control.LayoutPreset.Center);
control.Position = new Vector2(0, 0);
control.Size = new Vector2(200, 100);
```

`SetAnchorsPreset` is the equivalent of clicking the layout preset in the editor.

## Containers

A `Container` is a `Control` that lays out its children automatically. The container types:

| Container | Layout |
|---|---|
| **`HBoxContainer`** | Children in a horizontal row |
| **`VBoxContainer`** | Children in a vertical column |
| **`GridContainer`** | Children in a grid (configurable column count) |
| **`PanelContainer`** | Single child with a styled background |
| **`MarginContainer`** | Single child with configurable margins |
| **`CenterContainer`** | Centers a single child |
| **`AspectRatioContainer`** | Maintains an aspect ratio |
| **`HSplitContainer` / `VSplitContainer`** | Two children with a draggable split |
| **`ScrollContainer`** | Children that can scroll |
| **`TabContainer`** | Tabbed interface |
| **`HFlowContainer` / `VFlowContainer`** | Children that wrap |

When you put a `Control` inside a container, the container takes over its layout. You don't set anchors or position — you set `Custom Minimum Size`, and the container does the rest.

A typical menu:

```
PauseMenu (CanvasLayer)
└── Center (CenterContainer; full rect)
    └── Background (PanelContainer)
        └── VBox (VBoxContainer)
            ├── Title (Label)
            ├── ResumeButton (Button)
            ├── SettingsButton (Button)
            ├── HSeparator (HSeparator)
            └── QuitButton (Button)
```

This produces a centered panel with a column of buttons, regardless of screen size. No manual positioning. The `VBoxContainer` lays out the buttons; the `PanelContainer` gives them a background; the `CenterContainer` centers the whole thing.

The single most useful UI insight: **stop manually positioning things; use containers**.

## Size Flags

When a child is in a container, it has **Size Flags** that control how the container treats it:

- **Fill** — fill the available space
- **Expand** — claim a share of leftover space
- **Shrink Center / Begin / End** — alignment within the cell

For example, in an `HBoxContainer` with a label and a button, by default they take their minimum size and sit on the left. If you want the label to grow and the button to stay tight, set the label's `Horizontal Size Flags` to `Fill | Expand` and leave the button at default.

Size flags are confusing at first; experiment with them in the editor to see the effect.

## The Theme System

The `Theme` system is Godot's CSS equivalent — a way to style controls consistently across the project.

### Setting up a theme

1. Create a new `Theme` resource (`Resource → New Theme`).
2. In the theme editor, add a control type (e.g., `Button`).
3. Set styles for each state (Normal, Hovered, Pressed, Disabled, Focus).
4. Save the theme to disk.
5. Apply it to the project in **Project Settings → GUI → Theme → Custom**, or to specific scenes by setting the `Theme` property of a root `Control`.

### Theme overrides

Individual controls can override the theme for specific properties:

```csharp
var button = GetNode<Button>("MyButton");
button.AddThemeColorOverride("font_color", Colors.Red);
```

Use overrides sparingly. They're per-instance and don't update when the theme changes.

### What goes in a theme

- **Colors** — text colors, accent colors, background colors
- **Fonts** — fonts for different control types
- **Font sizes** — base size, header size, etc.
- **Constants** — spacing, margins, separator widths
- **Styleboxes** — backgrounds, borders, hover effects
- **Icons** — control-specific icons

A well-organized theme is what separates a Godot game that looks polished from one that looks like raw default UI.

## StyleBox

A `StyleBox` is a styled rectangle used as a background for controls. The two main types:

- **`StyleBoxFlat`** — flat color with optional border and corner radius. Most common.
- **`StyleBoxTexture`** — textured background using a 9-slice. Good for stylized UI.

In the theme editor, you assign a `StyleBox` to each state of each control type. A button's "Normal" state might have a dark gray `StyleBoxFlat`; the "Hovered" state, a slightly lighter one; the "Pressed" state, darker again.

```csharp
// Creating a StyleBoxFlat in code (rarely needed; usually done in the editor)
var stylebox = new StyleBoxFlat
{
    BgColor = new Color(0.2f, 0.2f, 0.2f),
    BorderWidthLeft = 2,
    BorderWidthRight = 2,
    BorderWidthTop = 2,
    BorderWidthBottom = 2,
    BorderColor = new Color(0.5f, 0.5f, 0.5f),
    CornerRadiusTopLeft = 4,
    CornerRadiusTopRight = 4,
    CornerRadiusBottomLeft = 4,
    CornerRadiusBottomRight = 4,
};
```

## Common UI Components

### Buttons

```csharp
var button = GetNode<Button>("MyButton");
button.Pressed += OnButtonPressed;

private void OnButtonPressed()
{
    GD.Print("Clicked");
}
```

`Button` has variants: `TextureButton` (uses textures for each state), `CheckBox`, `CheckButton`, `OptionButton` (dropdown), `MenuButton` (dropdown menu).

### Labels

```csharp
var label = GetNode<Label>("ScoreLabel");
label.Text = "Score: 100";
```

For rich text (colors, font sizes, links within the text), use `RichTextLabel` with BBCode:

```csharp
var label = GetNode<RichTextLabel>("RichLabel");
label.Text = "[color=red]Critical hit![/color] [b]100[/b] damage";
label.BbcodeEnabled = true; // (Default in Godot 4)
```

### Inputs

`LineEdit` for single-line text input, `TextEdit` for multi-line.

```csharp
var input = GetNode<LineEdit>("NameInput");
input.TextSubmitted += OnNameSubmitted;
input.TextChanged += OnNameChanged;

private void OnNameSubmitted(string newText) { ... }
private void OnNameChanged(string newText) { ... }
```

### Sliders

```csharp
var volumeSlider = GetNode<HSlider>("VolumeSlider");
volumeSlider.MinValue = 0;
volumeSlider.MaxValue = 1;
volumeSlider.Step = 0.01;
volumeSlider.Value = 0.5;
volumeSlider.ValueChanged += OnVolumeChanged;

private void OnVolumeChanged(double newValue)
{
    AudioServer.SetBusVolumeDb(0, Mathf.LinearToDb((float)newValue));
}
```

### Progress bars

```csharp
var healthBar = GetNode<ProgressBar>("HealthBar");
healthBar.MinValue = 0;
healthBar.MaxValue = 100;
healthBar.Value = currentHealth;
```

For a custom-styled health bar (gradient, animated, etc.), often a `TextureProgressBar` is the right choice.

## Focus and Keyboard Navigation

Godot's `Control` system has built-in focus management. With keyboard or controller, the player can `Tab` between focusable controls, press `Enter` to activate, etc. This works automatically — but it requires your UI to be set up correctly.

The `ui_*` actions handle navigation by default:

- `ui_focus_next` (Tab) — focus the next control
- `ui_focus_prev` (Shift+Tab) — focus the previous control
- `ui_accept` (Enter, Space) — activate the focused control
- `ui_cancel` (Escape) — back / dismiss
- `ui_left`, `ui_right`, `ui_up`, `ui_down` — directional navigation

Each control has **Focus** properties:

- **Focus Mode** — None, Click, All. "All" means it can be focused via Tab.
- **Focus Neighbor** properties (Top, Left, Bottom, Right) — explicitly set the next focusable control in each direction.

For controller-friendly menus, set focus neighbors so directional input always lands somewhere sensible.

```csharp
public override void _Ready()
{
    GetNode<Button>("ResumeButton").GrabFocus();
}
```

`GrabFocus()` puts focus on a control programmatically. Common use: when a menu opens, focus the first item.

## Connecting Game Logic to UI

A common pattern: the game state changes; the UI should update. The naive approach is for the game state to know about the UI and update it directly. The better approach is signals.

```csharp
// PlayerHealth.cs
public partial class PlayerHealth : Node
{
    [Signal] public delegate void HealthChangedEventHandler(int current, int max);

    [Export] public int Max { get; set; } = 100;
    public int Current { get; private set; }

    public override void _Ready()
    {
        Current = Max;
        EmitSignal(SignalName.HealthChanged, Current, Max);
    }

    public void TakeDamage(int amount)
    {
        Current = Math.Max(0, Current - amount);
        EmitSignal(SignalName.HealthChanged, Current, Max);
    }
}

// HUD.cs
public partial class HUD : CanvasLayer
{
    [Export] public PlayerHealth Health { get; set; }

    public override void _Ready()
    {
        Health.HealthChanged += OnHealthChanged;
        OnHealthChanged(Health.Current, Health.Max); // Initial update
    }

    private void OnHealthChanged(int current, int max)
    {
        var bar = GetNode<ProgressBar>("%HealthBar");
        bar.MaxValue = max;
        bar.Value = current;
    }
}
```

The `PlayerHealth` doesn't know the HUD exists. The HUD subscribes to changes. Either can be replaced or removed without touching the other.

## Custom Drawing

Sometimes you need a `Control` that draws something custom — a radar display, a custom progress visualization, a non-standard widget. For this, override `_Draw`:

```csharp
public partial class CustomBar : Control
{
    [Export] public float Value { get; set; } = 0.5f;

    public override void _Draw()
    {
        var size = Size;
        var fillRect = new Rect2(Vector2.Zero, new Vector2(size.X * Value, size.Y));
        DrawRect(new Rect2(Vector2.Zero, size), Colors.DarkGray);
        DrawRect(fillRect, Colors.Green);
    }

    public void SetValue(float value)
    {
        Value = Math.Clamp(value, 0, 1);
        QueueRedraw(); // Triggers _Draw to be called next frame
    }
}
```

`_Draw` is only called when `QueueRedraw()` is called, so it's not running every frame for nothing. The available draw methods include `DrawRect`, `DrawCircle`, `DrawLine`, `DrawTexture`, `DrawString`, `DrawPolygon`, etc.

## Resolution and Scaling

A game needs to look right on multiple screen sizes. Godot supports this via project-level stretch settings.

In **Project Settings → Display → Window**:

- **Viewport Width / Height** — your "base" resolution. Pick something appropriate for your art.
- **Stretch Mode**:
  - `disabled` — no scaling; UI scales with the window
  - `canvas_items` — UI scales smoothly to fit the window (vector-friendly)
  - `viewport` — render at base resolution and scale (pixel-art-friendly, integer scaling possible)
- **Stretch Aspect**:
  - `ignore` — stretch to fit; can distort
  - `keep` — letterbox or pillarbox to maintain aspect ratio
  - `keep_width` / `keep_height` — extend in the other dimension
  - `expand` — extend in both dimensions; UI must handle variable size

For a typical 2D game with a designed resolution (say, 1920x1080) and want it to scale to other resolutions: **stretch_mode = `canvas_items`, aspect = `keep`**.

For a pixel art game at 320x180: **stretch_mode = `viewport`, aspect = `keep`**.

## Internationalization (i18n)

Godot has built-in i18n support via `tr()` (in GDScript) or `Tr()` (in C#):

```csharp
label.Text = Tr("MAIN_MENU_PLAY");
```

The translation key `"MAIN_MENU_PLAY"` is looked up in the project's translation files (CSV or PO format). You set the active locale via `TranslationServer.SetLocale("fr")`.

For UI that supports multiple languages:

- **Use translation keys, not literal strings.** Even if you only ship in English now.
- **Allow space for translation expansion.** German is 30% longer than English; some languages double the length. Don't design buttons that fit "OK" exactly.
- **Right-to-left layout support.** `Control` has a `Layout Direction` property. Some languages need this set.
- **Test with a "long string" locale** during development to catch overflow issues.

## Common UI Patterns

### Dialog box

```
Dialog (CanvasLayer)
└── Background (ColorRect, full rect, dark transparent)
    └── Center (CenterContainer)
        └── Box (PanelContainer)
            └── Margin (MarginContainer)
                └── VBox (VBoxContainer)
                    ├── Title (Label)
                    ├── Message (Label)
                    └── Buttons (HBoxContainer)
                        ├── OK (Button)
                        └── Cancel (Button)
```

### HUD

```
HUD (CanvasLayer)
├── TopLeft (Control, layout: Top Left)
│   └── HealthBar (ProgressBar)
├── TopRight (Control, layout: Top Right)
│   └── ScoreLabel (Label)
└── BottomCenter (Control, layout: Center Bottom)
    └── ObjectiveLabel (Label)
```

### Settings menu

```
Settings (PanelContainer)
└── VBox (VBoxContainer)
    ├── Title (Label)
    ├── TabContainer
    │   ├── Audio (VBoxContainer)
    │   │   ├── MasterVolume (HSlider)
    │   │   └── MusicVolume (HSlider)
    │   ├── Video (VBoxContainer)
    │   │   ├── Fullscreen (CheckBox)
    │   │   └── Resolution (OptionButton)
    │   └── Controls (VBoxContainer)
    │       └── (rebind buttons)
    └── HBox (HBoxContainer)
        ├── Cancel (Button)
        └── Apply (Button)
```

## Anti-Patterns

- **Manually positioning everything.** Containers exist for a reason.
- **Hardcoding screen sizes.** Use anchors, containers, and the stretch settings.
- **Reinventing the theme system.** Use Godot's; it covers most cases.
- **Reinventing controls** (custom buttons, custom labels) when the built-ins would do.
- **Per-instance theme overrides everywhere** instead of theme types. The theme becomes irrelevant.
- **Plain text strings** instead of translation keys. Ships in one language only.
- **Mixing units.** Some controls in pixels, others in percentages. Confusing layout.
- **No focus mode for controller-friendly menus.** Player can't navigate with a gamepad.
- **`MouseFilter` set to `Pass` on big invisible panels.** They block clicks to the controls beneath.
- **`MouseFilter` set to `Stop` on labels that should be clickable through.** They eat clicks meant for buttons.
- **UI in the world space, not in a `CanvasLayer`.** UI scrolls with the camera.
- **Multiple `CanvasLayer`s with the same layer index.** Order is unpredictable.
- **`get_node` paths in UI scripts.** Use `[Export]` references or `%UniqueName`.
- **Animating UI in `_PhysicsProcess`.** Use `_Process` or `Tween`.
- **Updating UI from `_Process`** when an event would do. Polling wastes work.
- **Tightly coupling game logic to UI.** Use signals; game state shouldn't know about the HUD.
- **Custom drawing every frame** without `QueueRedraw`. `_Draw` is only called when needed.
- **Long strings** that overflow buttons in other languages. Test with longer text.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — `Control`, `CanvasLayer`, focus
- [signals-and-events.md](signals-and-events.md) — connecting game state to UI via signals
- [animation-and-tweens.md](animation-and-tweens.md) — animating UI elements
- [input-and-controls.md](input-and-controls.md) — input handling in UI
- ux-design — broader UX principles that apply to game UI
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
