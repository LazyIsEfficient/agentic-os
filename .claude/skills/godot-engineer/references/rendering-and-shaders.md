# Rendering and Shaders

Godot 4 introduced a new renderer (Vulkan with three profiles: Forward+, Mobile, Compatibility) that's a substantial improvement over Godot 3's GLES backend. This file covers how Godot renders things, the major concepts you need to engineer with, and the basics of shader work.

This is *not* a graphics programming course. It's the practical level a Godot engineer needs: how to use the renderer well, how to write basic shaders when you need them, and how to avoid the common performance and visual pitfalls.

## The Three Renderers

Godot 4 ships with three rendering backends:

| Renderer | Best for | Limitations |
|---|---|---|
| **Forward+** (default) | Desktop, mid-to-high-end hardware, complex 3D scenes | Heavy on lower-end hardware; not great for mobile |
| **Mobile** | Mobile, lower-end hardware, simpler 3D scenes | Fewer rendering features (no global illumination, fewer lights, etc.) |
| **Compatibility** (formerly GLES2/3) | Web, very old hardware, when Vulkan isn't available | Most limited; older shading model |

You pick the renderer in **Project Settings → Rendering → Renderer**. You can also set per-platform overrides — Forward+ on desktop, Mobile on mobile, Compatibility on web.

For a 2D game, the renderer choice mostly doesn't matter — 2D works similarly across all three. For 3D, the choice has real consequences. Pick based on your target platforms.

## 2D Rendering

The 2D renderer is conceptually simple: every visible 2D node is drawn in a sorted order based on `z_index` and tree position. There's no real "depth buffer" — sorting is based on layer and order.

Key concepts for 2D:

### `CanvasItem` and the draw order

Everything visible in 2D inherits from `CanvasItem` (`Sprite2D`, `Label`, `Polygon2D`, `Line2D`, etc.). They're drawn in tree order — earlier siblings under later siblings — with `z_index` as an override.

A common pitfall: a UI element drawn under a sprite because the sprite is later in the tree. Use `z_index` to control layering, or restructure the scene.

### `CanvasLayer`

A `CanvasLayer` creates a *separate* drawing layer that ignores the camera. Use it for:

- HUD and UI (so they don't move with the camera)
- Pause menus and overlays
- Transition effects
- Anything that should be in screen space, not world space

```
Level (Node2D)
├── World (Node2D, contains the game world)
│   ├── Player
│   ├── Enemies
│   └── TileMap
└── HUD (CanvasLayer)
    └── Container (Control)
        ├── HealthBar
        └── ScoreLabel
```

### Sprites and atlases

For pixel art and 2D games with many sprites, **texture atlases** dramatically improve performance by reducing draw calls. Godot's importer can pack textures into atlases automatically, or you can use sprite sheets manually with `AtlasTexture`.

```csharp
[Export] public Texture2D Atlas { get; set; }

public override void _Ready()
{
    var atlasTexture = new AtlasTexture
    {
        Atlas = Atlas,
        Region = new Rect2(0, 0, 32, 32) // First 32x32 frame
    };
    var sprite = GetNode<Sprite2D>("Sprite2D");
    sprite.Texture = atlasTexture;
}
```

For animated sprites, `AnimatedSprite2D` with `SpriteFrames` (which can use an atlas) is the standard.

### Pixel art settings

For pixel art games:

- **Project Settings → Rendering → Textures → Default Texture Filter → Nearest** (or set per-texture in the import settings)
- **Project Settings → Display → Window → Stretch → Mode → `viewport`** for integer scaling
- **Stretch → Aspect → `keep`** to preserve aspect ratio
- Set the project's base resolution to your target pixel art resolution (e.g., 320x180)

The `viewport` stretch mode renders the game at the base resolution and scales the result to the window, giving crisp pixels. This is the right setup for any pixel art game.

### Lighting in 2D

Godot 4 has a 2D lighting system: `PointLight2D`, `DirectionalLight2D`, and `LightOccluder2D` for shadows. To use it:

1. Set sprites' textures to have a "normal map" if you want directional lighting effects.
2. Add `PointLight2D` nodes for light sources.
3. Add `LightOccluder2D` nodes (with `OccluderPolygon2D` shape) where shadows should be cast.
4. Sprites and `CanvasItem`s have a `Light Mask` property that determines which lights affect them.

For a simpler "darkness" effect, a black `ColorRect` with a `BackBufferCopy` and a circular mask shader is often faster than full 2D lighting.

## 3D Rendering

3D in Godot is built around `Node3D` (formerly `Spatial`), with familiar concepts:

- **`MeshInstance3D`** — displays a 3D mesh.
- **`Material`** — how the mesh's surface looks (color, texture, roughness, etc.).
- **`Light3D`** — light sources (`DirectionalLight3D`, `OmniLight3D`, `SpotLight3D`).
- **`Camera3D`** — what the player sees.
- **`Environment`** — global rendering settings (sky, ambient, fog, post-processing).

A minimal 3D scene:

```
Main (Node3D)
├── Camera3D
├── DirectionalLight3D
├── WorldEnvironment (Node)
│   └── Environment (Sky, ambient, fog)
└── Floor (MeshInstance3D)
    └── BoxMesh
```

### Materials

Godot's `StandardMaterial3D` is a PBR material with all the usual settings: albedo, metallic, roughness, normal, emission, etc. You can assign textures to each property and tweak parameters in the inspector.

For more control, use `ShaderMaterial` with a custom shader (more on shaders below).

### Lighting models and global illumination

Godot 4's Forward+ renderer supports:

- **Real-time lights** with shadows (directional, omni, spot).
- **Voxel GI** (`VoxelGI` node) — global illumination via voxelization. Good quality, moderate cost.
- **SDFGI** (Signed Distance Field GI) — large-scale dynamic GI; good for outdoor scenes.
- **LightmapGI** — pre-baked lightmaps. Best quality, no runtime cost, but only for static geometry.
- **Reflection probes** for local reflections.

For most projects, baked lightmaps are the right choice — best visual quality, lowest runtime cost. Use real-time lights only for dynamic things.

### Environment

A `WorldEnvironment` node holds an `Environment` resource that controls:

- **Sky** — procedural sky, panorama, or solid color
- **Ambient light** — global ambient term
- **Fog** — distance-based fog
- **Tonemap** — color grading
- **Glow** (bloom) — emissive bloom
- **SSAO** — screen-space ambient occlusion
- **SSR** — screen-space reflections

You usually have one `WorldEnvironment` per level. Tweak the `Environment` resource for the level's mood.

### Camera basics

```csharp
public partial class FollowCamera : Camera3D
{
    [Export] public Node3D Target { get; set; }
    [Export] public Vector3 Offset = new(0, 5, 10);
    [Export] public float Smoothness = 5.0f;

    public override void _Process(double delta)
    {
        if (Target == null) return;
        var desired = Target.GlobalPosition + Offset;
        GlobalPosition = GlobalPosition.Lerp(desired, (float)delta * Smoothness);
        LookAt(Target.GlobalPosition);
    }
}
```

A common camera bug: putting camera updates in `_PhysicsProcess`, which produces a stutter when the framerate doesn't match the physics rate. Camera updates belong in `_Process` for smooth visuals.

## Viewports

A `Viewport` (or `SubViewport` in Godot 4) is a separate rendering target. Use cases:

- **Render-to-texture** — render the world to a texture for use in materials or UI.
- **Split screen** — multiple viewports for multiplayer.
- **Mini-maps** — render the level from above to a `SubViewport` and display in the HUD.
- **Cameras for cutscenes** — switch between cameras in different viewports.
- **Post-processing chains** — render to a viewport, apply a shader, render again.

Basic setup:

```
SubViewportContainer (Control, sizes the viewport)
└── SubViewport (Viewport)
    ├── Camera2D (or Camera3D)
    └── (the things to render)
```

The `SubViewportContainer` displays the rendered viewport as a UI element.

## Shaders — The Basics

Godot's shading language (`gdshader`) is similar to GLSL but with engine-specific extensions. Shaders are written in `.gdshader` files (or inline in `ShaderMaterial.code`).

### When to write a shader

Most of the time, you don't need to. Standard materials handle most cases. Reach for a shader when:

- You need a *visual effect* the standard material can't do (water ripples, dissolve, outline, etc.)
- You need a *performance optimization* via custom rendering
- You need *procedural content* (procedural sky, procedural texture)
- You need a *post-processing effect*

### Shader types

| Type | Used by | Purpose |
|---|---|---|
| **`spatial`** | `MeshInstance3D` materials | 3D rendering |
| **`canvas_item`** | `CanvasItem` materials (2D) | 2D rendering |
| **`particles`** | Particle systems | Per-particle logic |
| **`sky`** | `Sky` material | Procedural sky |
| **`fog`** | Volumetric fog | Volumetric fog |

### A simple 2D shader

A shader that tints a sprite based on time:

```glsl
shader_type canvas_item;

uniform vec4 tint_color : source_color = vec4(1.0);
uniform float speed : hint_range(0.0, 10.0) = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float pulse = sin(TIME * speed) * 0.5 + 0.5;
    COLOR = tex_color * mix(vec4(1.0), tint_color, pulse);
}
```

Save as `pulse.gdshader`. Apply in the editor: select a `Sprite2D` → Material → New ShaderMaterial → assign the shader.

A few language notes:

- **`shader_type canvas_item`** declares the shader type. Required.
- **`uniform`** declares parameters that can be set from the inspector or code.
- **`hint_range(min, max)`** is a hint for the editor (gives you a slider).
- **`source_color`** hint marks a uniform as a color (gets a color picker).
- **`TIME`** is a built-in that's the time since the shader started.
- **`TEXTURE`** is the sprite's texture (built-in for `canvas_item`).
- **`UV`** is the texture coordinate (built-in).
- **`COLOR`** is the output color (built-in).

### A simple 3D shader

A custom material with a Fresnel rim light:

```glsl
shader_type spatial;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 rim_color : source_color = vec4(1.0);
uniform float rim_power : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    ALBEDO = albedo.rgb;

    vec3 view_dir = normalize(VIEW);
    float fresnel = pow(1.0 - dot(NORMAL, view_dir), rim_power);
    EMISSION = rim_color.rgb * fresnel;
}
```

This shader gives a 3D mesh a rim light effect, where the edges glow more strongly than the surfaces facing the camera.

### Setting shader parameters from code

```csharp
public partial class ShimmerEffect : Sprite2D
{
    public override void _Ready()
    {
        var material = (ShaderMaterial)Material;
        material.SetShaderParameter("tint_color", new Color(1, 0.5f, 0));
        material.SetShaderParameter("speed", 3.0f);
    }

    public override void _Process(double delta)
    {
        var material = (ShaderMaterial)Material;
        material.SetShaderParameter("speed", Mathf.Sin((float)Time.GetTicksMsec() / 1000.0f) + 1.5f);
    }
}
```

### Common 2D shader effects

A few shaders worth keeping around:

**Outline:**

```glsl
shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 2.0;

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * outline_width;
    float alpha = texture(TEXTURE, UV).a;
    if (alpha == 0.0) {
        float a = 0.0;
        a += texture(TEXTURE, UV + vec2(size.x, 0)).a;
        a += texture(TEXTURE, UV + vec2(-size.x, 0)).a;
        a += texture(TEXTURE, UV + vec2(0, size.y)).a;
        a += texture(TEXTURE, UV + vec2(0, -size.y)).a;
        if (a > 0.0) {
            COLOR = outline_color;
            return;
        }
    }
    COLOR = texture(TEXTURE, UV);
}
```

**Hit flash:**

```glsl
shader_type canvas_item;

uniform float flash_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = mix(tex, flash_color, flash_strength * tex.a);
}
```

Animate `flash_strength` with a `Tween` for hit feedback.

**Dissolve:**

```glsl
shader_type canvas_item;

uniform sampler2D noise_texture;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float edge_width : hint_range(0.0, 0.1) = 0.05;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float n = texture(noise_texture, UV).r;

    if (n < dissolve) {
        discard;
    } else if (n < dissolve + edge_width) {
        COLOR = edge_color;
    } else {
        COLOR = tex;
    }
}
```

For a dissolving-into-particles effect, animate `dissolve` from 0 to 1.

## Performance Considerations

### 2D performance

- **Use atlases.** Dramatically reduces draw calls.
- **Use `MultiMeshInstance2D`** for many copies of the same mesh (e.g., grass, debris).
- **Limit `Light2D` count.** Each adds cost; for darkness, a shader is often cheaper.
- **`Polygon2D` and `Line2D` are slower than sprites.** Use sprites where possible.
- **`TileMap` is highly optimized.** Use it for tile-based 2D, not individual sprite nodes.

### 3D performance

- **Bake lighting** for static scenes. Real-time lights are expensive; baked lighting is free at runtime.
- **Use LODs** (`Level of Detail`). `MeshInstance3D` supports automatic LOD generation in Godot 4.
- **Use `MultiMeshInstance3D`** for many copies of the same mesh (e.g., trees, rocks, bullets).
- **Frustum culling is automatic** but only works if your meshes have correct bounds. Set `Visibility AABB` if needed.
- **Avoid transparent surfaces** where possible. Transparency requires sorting and disables some optimizations.
- **Watch the draw call count.** Use the **Visual Profiler** to see how many draw calls per frame; aim to keep it low.

### Shader performance

- **`fragment` runs per pixel.** Keep it cheap.
- **`vertex` runs per vertex.** Cheaper if you can move work there.
- **Texture lookups are expensive.** Each `texture(...)` call costs.
- **`if` statements in shaders are slow.** Prefer `mix`, `step`, `clamp` for branchless code.
- **`discard` disables some optimizations.** Use sparingly.

For the deeper performance discussion, see [performance-and-profiling.md](performance-and-profiling.md).

## Anti-Patterns

- **Default texture filter for pixel art.** Defaults to linear; pixel art needs nearest. Set per-import or in project settings.
- **Camera in `_PhysicsProcess`.** Stutters when framerate ≠ physics rate. Use `_Process`.
- **No `CanvasLayer` for HUD.** HUD scrolls with the camera; looks broken.
- **Sprites without atlases** in a project with hundreds of sprites. Massive draw call count.
- **Real-time lights everywhere in 3D.** Bake static ones.
- **Custom shaders when standard material would do.** Standard materials are often more performant and cover most cases.
- **Heavy logic in `fragment` shader.** Move to vertex shader or to CPU where possible.
- **Texture loads in shader uniforms changed every frame.** Sets a new texture sampler; expensive. Pre-load and reuse.
- **`Polygon2D` for things that should be sprites.** Slower; use sprites.
- **No frustum culling on large meshes.** Set `Visibility AABB` correctly.
- **Transparent objects with the wrong sort order.** Half-transparent things look broken.
- **Rendering the world to a `SubViewport` every frame** when it doesn't change. Cache the result.
- **Multiple `WorldEnvironment` nodes.** Only one is active; the others are wasted.
- **Forgetting to set the rendering backend per platform.** Forward+ on mobile is too heavy; Mobile on desktop is unnecessarily limited.
- **Hand-writing shaders for things Godot's `StandardMaterial3D` already does.** Reinventing.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — `CanvasItem`, `Node3D`, viewports
- [animation-and-tweens.md](animation-and-tweens.md) — animating shader parameters
- [ui-and-controls.md](ui-and-controls.md) — UI rendering with `Control`
- [performance-and-profiling.md](performance-and-profiling.md) — rendering performance
- [exporting-and-platforms.md](exporting-and-platforms.md) — per-platform renderer choice
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
