# Performance and Profiling

Game performance is constrained by **the frame budget**: the time the engine has to do everything between two consecutive frames being shown to the player. At 60 FPS, that's 16.67ms. At 120 FPS, 8.33ms. At 30 FPS (often the floor for "playable"), 33ms.

Inside that budget, you have to do *everything*: input, physics, AI, animation, rendering, audio, scripting, garbage collection. Going over budget produces a dropped frame; doing it consistently produces visible stutter and unhappy players.

This file is about working within the budget — how to measure, where time goes, what to optimize, and what *not* to optimize.

## The Cardinal Rule

> **Don't optimize what you haven't measured.**

The instinct of every engineer is to "make it fast" by intuition. The instinct is wrong. Performance work without measurements is gambling: you spend time on the things that *feel* slow, while the actual bottleneck stays unmeasured and unfixed.

The discipline:

1. **Establish a measurement.** Before optimizing, know what frame time you have and what it should be.
2. **Profile to find the bottleneck.** Don't guess. The profiler tells you where time goes.
3. **Optimize the bottleneck.** Not the second-most expensive thing. The actual bottleneck.
4. **Re-measure.** Confirm the optimization actually helped, in real workload conditions.
5. **Stop when you're under budget.** Don't optimize past your target; that's wasted time.

Engineers who skip step 2 — guessing instead of profiling — almost always optimize the wrong thing.

## Frame Budget Math

Pick a target framerate. The budget per frame is `1000 / target_fps` milliseconds.

| Target | Budget per frame |
|---|---|
| 30 FPS | 33.3ms |
| 60 FPS | 16.7ms |
| 120 FPS | 8.3ms |
| 144 FPS | 6.9ms |

Inside that budget, your time goes to (rough breakdown for a typical 60 FPS game):

- **CPU game logic** (~5-8ms): scripts, AI, gameplay code
- **Physics step** (~1-3ms): collisions, body updates
- **Rendering setup** (~2-4ms): culling, draw call submission
- **GPU rendering** (~3-6ms): the actual GPU drawing the frame
- **Audio, input, OS overhead** (~1-2ms)

These are not strict; different games have very different distributions. A heavy 3D scene might spend 10ms on rendering and 2ms on logic; a heavy procedural generator might be the opposite.

The point: any single thing eating 5ms is consuming a third of your frame budget. Get familiar with the orders of magnitude.

## The Godot Profiler

Godot's built-in profiler is your primary tool. Open it in **Debugger → Profiler** while the game is running.

### What it shows

- **Frame time** — total time per frame, broken down into segments
- **Function time** — how long each script function took
- **Process time** vs **Physics process time** — split by process function
- **Static memory** — memory used by Godot's static allocations
- **Dynamic memory** — memory allocated per frame

### How to use it

1. **Run the game**. Let it reach the situation you want to profile (a complex scene, a specific gameplay moment).
2. **Open the profiler**. Click "Start" to begin profiling.
3. **Capture some frames**. Let it run for ~10 seconds in the situation of interest.
4. **Click "Stop"**. Now you can scroll through the captured frames.
5. **Sort by time**. Find the worst frames; click into them.
6. **Drill down**. The profiler shows a tree of function calls and their costs. Find the expensive ones.

Things to look for:

- **Functions that take a lot of time per call.** A 5ms function called once a frame is the bottleneck.
- **Functions called many times per frame.** A 0.1ms function called 100 times is also the bottleneck.
- **Variability between frames.** A function that's usually fast but sometimes slow indicates GC, allocations, or hitches.
- **Physics vs process split.** If physics is dominant, optimize physics. If process is, optimize gameplay code.

## The Visual Profiler

For rendering performance, the **Debugger → Visual Profiler** shows:

- **Render frame time**
- **Vertex count, draw calls, primitives drawn**
- **Sky / fog / SSAO / SSR cost**
- **Shadow rendering cost**

If your game is GPU-bound (rendering is the bottleneck), the visual profiler tells you where the GPU is spending its time. The fixes are different from CPU optimizations: reduce draw calls, simplify shaders, reduce overdraw, bake lighting.

## Common CPU Bottlenecks

### Too much in `_Process` / `_PhysicsProcess`

Every node with a `_Process` or `_PhysicsProcess` method costs time per frame. With hundreds or thousands of nodes, this adds up.

The fix: **don't process when you don't need to**. Use `SetProcess(false)` and `SetPhysicsProcess(false)` on nodes that are inactive.

```csharp
public override void _Ready()
{
    SetProcess(false); // Off by default; turn on when needed
}

public void Activate()
{
    SetProcess(true);
}
```

For example, an enemy that's far from the player doesn't need to process AI every frame. Disable processing when out of range; re-enable when near.

### Allocation in hot paths

C# allocations on the heap trigger garbage collection. GC pauses are short (~1-5ms typically) but visible. Allocations in `_Process` are particularly bad because they accumulate.

```csharp
// Bad: allocates a new array every frame
public override void _Process(double delta)
{
    var nearby = new List<Enemy>();
    foreach (var enemy in _allEnemies)
    {
        if (Position.DistanceTo(enemy.Position) < Range)
            nearby.Add(enemy);
    }
    UseNearby(nearby);
}

// Good: reuse a member array
private List<Enemy> _nearbyBuffer = new();

public override void _Process(double delta)
{
    _nearbyBuffer.Clear();
    foreach (var enemy in _allEnemies)
    {
        if (Position.DistanceTo(enemy.Position) < Range)
            _nearbyBuffer.Add(enemy);
    }
    UseNearby(_nearbyBuffer);
}
```

Other allocation sources to watch:

- **Lambda captures** that allocate
- **String concatenation** in loops (use `StringBuilder` or `string.Format`)
- **Boxing** (passing a value type to a method that takes `object`)
- **`new Vector2(...)`** in hot paths is fine (it's a struct), but `new SomeReferenceClass(...)` is not

### `GetNode<T>` in hot paths

`GetNode<T>("path")` does a string lookup against the scene tree. Doing it once in `_Ready` is fine; doing it every frame in `_Process` is wasteful.

```csharp
// Bad
public override void _Process(double delta)
{
    var label = GetNode<Label>("UI/Container/Label");
    label.Text = $"Score: {_score}";
}

// Good
private Label _label;

public override void _Ready()
{
    _label = GetNode<Label>("UI/Container/Label");
}

public override void _Process(double delta)
{
    _label.Text = $"Score: {_score}";
}
```

### String operations

String allocation in `_Process` is a common GC source. Update labels only when the value changes:

```csharp
// Bad: allocates every frame
public override void _Process(double delta)
{
    _scoreLabel.Text = $"Score: {_score}";
}

// Good: only update when score changes
private int _lastScore = -1;

public override void _Process(double delta)
{
    if (_score != _lastScore)
    {
        _scoreLabel.Text = $"Score: {_score}";
        _lastScore = _score;
    }
}
```

Or, even better: don't poll. Use a signal so the label only updates when something actually changes.

### Inefficient algorithms

Sometimes the bottleneck is just an O(n²) algorithm that should be O(n) or O(n log n). Examples:

- **Pairwise checks**: every entity checking every other entity for proximity, every frame.
- **Path search per frame**: re-running A* every frame instead of caching the path.
- **Frequent sorting**: sorting a large list every frame instead of maintaining sorted order.

The fix is algorithm-level: spatial partitioning, caching, or different data structures. Profile first to confirm this is actually the bottleneck before rewriting.

### Spatial partitioning

For "find nearby things" queries, a spatial data structure (quadtree, grid, octree) is dramatically faster than checking every entity:

```csharp
// O(n²) — checking every pair
foreach (var a in entities)
foreach (var b in entities)
    if (a.Position.DistanceTo(b.Position) < range)
        ...

// O(n) with a grid — only check nearby cells
foreach (var a in entities)
{
    var cell = (int)(a.Position.X / CellSize);
    foreach (var b in grid.GetNeighborsOf(a))
        if (a.Position.DistanceTo(b.Position) < range)
            ...
}
```

Godot has built-in spatial structures: `AStarGrid2D` for grid-based pathfinding, the navigation server for pathfinding through navmesh. For custom proximity queries, Godot's `Area2D`/`Area3D` with collision masks is often the right tool.

## Common GPU Bottlenecks

### Too many draw calls

Each visible thing typically generates one or more draw calls. Hundreds of draw calls per frame is fine; thousands starts to hurt.

Reductions:

- **Texture atlases** for 2D — one draw call per atlas instead of per sprite.
- **`MultiMeshInstance2D`/`3D`** for many copies of the same mesh.
- **Static mesh batching** — Godot does some of this automatically; check the visual profiler.
- **Instancing** for repeated geometry (trees, grass, debris).
- **TileMaps** for tile-based 2D — highly optimized.

### Overdraw

Overdraw is when the same pixel is drawn multiple times in a frame (a transparent thing on top of an opaque thing). High overdraw on mobile is a major performance hit.

Reductions:

- **Avoid stacked transparencies.** Each transparent layer is overdraw.
- **Use opaque rendering where possible.** Discard transparent pixels with `discard;` rather than blending.
- **Mind your particles.** Particle systems with many overlapping transparent quads are overdraw nightmares.

### Expensive shaders

Shader complexity matters, especially in fragment shaders that run per pixel.

- **Texture lookups are expensive.** Each `texture(...)` call costs.
- **Branching is slow.** Use `mix`, `step`, `clamp` instead of `if`.
- **Loops are slow.** Bounded loops are OK; data-dependent loops are bad.
- **Trigonometry is expensive.** Pre-compute, use lookup tables, or use cheaper approximations.

For complex effects, profile the shader specifically — sometimes a single expensive shader on a full-screen quad is the entire bottleneck.

### Shadow rendering

Shadows are expensive. Each shadow-casting light costs ~as much as another full pass of the scene.

- **Limit shadow-casting lights** to a few key ones.
- **Use baked shadows for static scenes.**
- **Use shadow LOD** (lower-resolution shadows for distant objects).
- **Disable shadows** on small or unimportant objects.

### Post-processing

Each post-processing effect (SSAO, SSR, glow, FXAA) adds full-screen passes. They're cheap individually but accumulate.

- **Disable on lower-quality settings.**
- **Use them deliberately, not as defaults.**
- **Profile each one** to know its cost on your target hardware.

## Object Pooling

For things spawned and destroyed frequently (bullets, particles, damage numbers), object pooling avoids the cost of `Instantiate`/`QueueFree` cycles and the GC pressure they create.

```csharp
public partial class BulletPool : Node
{
    [Export] public PackedScene BulletScene { get; set; }
    [Export] public int InitialSize { get; set; } = 100;

    private Queue<Bullet> _available = new();

    public override void _Ready()
    {
        for (int i = 0; i < InitialSize; i++)
        {
            CreatePooled();
        }
    }

    private Bullet CreatePooled()
    {
        var bullet = BulletScene.Instantiate<Bullet>();
        AddChild(bullet);
        DeactivateBullet(bullet);
        bullet.LifetimeEnded += () => Return(bullet);
        return bullet;
    }

    public Bullet Spawn(Vector2 position, Vector2 direction)
    {
        Bullet bullet;
        if (_available.Count > 0)
            bullet = _available.Dequeue();
        else
            bullet = CreatePooled(); // Pool exhausted; grow

        ActivateBullet(bullet, position, direction);
        return bullet;
    }

    private void ActivateBullet(Bullet bullet, Vector2 position, Vector2 direction)
    {
        bullet.GlobalPosition = position;
        bullet.Direction = direction;
        bullet.SetProcess(true);
        bullet.SetPhysicsProcess(true);
        bullet.Visible = true;
    }

    private void DeactivateBullet(Bullet bullet)
    {
        bullet.SetProcess(false);
        bullet.SetPhysicsProcess(false);
        bullet.Visible = false;
    }

    private void Return(Bullet bullet)
    {
        DeactivateBullet(bullet);
        _available.Enqueue(bullet);
    }
}
```

When pooling pays off:

- **Many short-lived instances**: bullets, particles, debris, damage numbers.
- **High spawn rate**: dozens per second.
- **Measured GC pressure**: profile shows GC pauses correlated with spawning.

When pooling doesn't pay off:

- **Long-lived instances**: enemies that live for minutes.
- **Low spawn rate**: a few per second.
- **Different configurations**: each instance has wildly different setup; pooling adds complexity without much win.

## When to Drop to Native Code

For really hot paths where C# isn't fast enough, you have options:

- **`unsafe` C#** — pointer arithmetic and manual memory layout, faster but harder.
- **`Span<T>` and `Memory<T>`** — zero-allocation slicing of arrays.
- **GDExtension (C++)** — write a native module that exposes types to Godot. The fastest option but the highest complexity.

These are rarely needed. If you're considering them, profile first to confirm the C# code really is the bottleneck. Often, an algorithmic improvement gives you more speedup than dropping to C++.

## Mobile Performance

Mobile is much more constrained than desktop. Things to know:

- **Frame budget is the same** (16.7ms at 60 FPS) but the hardware is slower, so you have less to work with.
- **Thermal throttling**: mobile devices throttle when hot. Performance drops over a long session.
- **Battery considerations**: minimize CPU/GPU work; consider 30 FPS instead of 60 to save power.
- **Renderer choice**: use the Mobile renderer, not Forward+.
- **Texture compression**: use ASTC or ETC2 for mobile textures (not the desktop's BC7).
- **Draw call budget is smaller**: aim for hundreds, not thousands.
- **Overdraw is more painful**: mobile GPUs are tile-based and overdraw kills them.
- **Memory is constrained**: aim for under 1GB peak RAM.

Always test on a real low-end device, not just on your dev phone. The cheap Android device is the actual target for many players.

## Web Performance

Godot's web export is real but constrained:

- **No threading** (mostly): the web target has limited multithreading support.
- **Memory is capped**: ~2GB is a hard limit; less in practice.
- **Initial load time is real**: the WASM and assets all download. Keep the project small.
- **Audio glitches**: web audio is a known weak spot.
- **Fewer rendering features**: use the Compatibility renderer.

For web, optimize aggressively for size and load time. A 200MB web game is too large; aim for under 50MB if possible.

## Profiling Workflow

A productive performance workflow:

1. **Define your target framerate** and the platform(s) it must hit.
2. **Build a representative test scene** — a level with realistic counts of enemies, particles, etc.
3. **Run on the target hardware**. Not your dev machine; the real target.
4. **Establish a baseline**. What's the current frame time? Where does it go?
5. **Identify the bottleneck**. CPU vs GPU? Which function or pass?
6. **Make one change**. Targeted at the bottleneck.
7. **Re-measure**. Did it help? By how much?
8. **Repeat** until under budget.

The most common failure: making many changes at once and not knowing which helped. Always change one thing, measure, then change the next.

## Anti-Patterns

- **Optimizing without measuring.** Wastes time on the wrong things.
- **"Optimize as you go".** You don't know what's slow yet. Build it, profile it, then optimize.
- **Premature optimization.** Spending hours on micro-optimizations of code that runs once a minute.
- **`GetNode` in hot paths.** Cache references in `_Ready`.
- **Allocating in `_Process`.** GC pressure; visible hitches.
- **String operations in `_Process` without caching.** Allocates per frame.
- **Updating UI every frame** when an event would do.
- **Processing inactive nodes.** Use `SetProcess(false)` to disable.
- **Real-time lights everywhere in 3D.** Bake static ones.
- **No texture atlases for 2D.** Massive draw call counts.
- **Shadows on every light.** Each shadow caster doubles render cost.
- **Custom shaders that re-implement what `StandardMaterial3D` does.** Reinventing for no reason.
- **Object pooling things that don't need it.** Adds complexity without measurable benefit.
- **Optimizing the GPU when the CPU is the bottleneck (or vice versa).** Profile to find out which.
- **Targeting 60 FPS on a 144 Hz monitor.** Vsync at 144 means a smaller budget; either target 144 or accept the tearing.
- **Ignoring mobile/web performance until ship.** Discover problems too late to fix.
- **Different optimization on every commit.** Many small wins, no clear story; impossible to bisect regressions.
- **Optimizing past your budget.** Wasted time; the player doesn't notice.
- **Performance budgets nobody enforces.** Set a number; check it; reject changes that blow it.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — `_Process` vs `_PhysicsProcess` budgets
- [physics-and-collision.md](physics-and-collision.md) — physics performance
- [rendering-and-shaders.md](rendering-and-shaders.md) — rendering performance
- [exporting-and-platforms.md](exporting-and-platforms.md) — per-platform performance
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
