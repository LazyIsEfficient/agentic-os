# Save / Load and Persistence

Every non-trivial game needs to save and load state — the player's progress, settings, achievements, the current level. This is one of the most-failed parts of indie game development, because the saves must:

- **Survive game updates** without bricking the player's progress
- **Be tamper-resistant** (some level of) for competitive features
- **Handle errors gracefully** (corrupted file, partial write, missing file)
- **Be fast enough** to autosave without hitching
- **Be portable** across platforms (cloud saves, syncing, etc.)

Most early-stage indie games skip the migration plan and ship a save format that breaks on the next update. Players lose hours of progress; reviews tank; the team scrambles. This file is about not doing that.

## What to Persist

A typical game persists several different kinds of data:

| Data | Storage | Lifetime |
|---|---|---|
| **Player progress** (current level, XP, inventory) | Save file | Per save slot |
| **Settings** (audio volumes, keybindings, graphics) | Settings file | Per device |
| **Statistics** (total playtime, kills, distance) | Stats file or save | Per profile |
| **Achievements** | Achievements file or platform | Per profile |
| **Custom levels / mods** | User content folder | Per device |
| **Cache / preloaded data** | Cache | Best effort |

These often live in separate files because they have different lifetimes and different update strategies. Don't put settings inside the save file (the player would lose their settings on a new game); don't put per-save progress in the settings file (it'd persist across saves).

## Where to Save

Godot's `user://` path is the cross-platform location for save data. It maps to:

- **Windows**: `%APPDATA%\Godot\app_userdata\<project_name>\`
- **macOS**: `~/Library/Application Support/Godot/app_userdata/<project_name>/`
- **Linux**: `~/.local/share/godot/app_userdata/<project_name>/`
- **Mobile / web**: platform-specific persistent storage

Use `user://` for everything that should survive a game update. Don't write to `res://` (that's the project's resources, read-only at runtime).

```csharp
// Right
var path = "user://saves/save_1.dat";

// Wrong
var path = "res://saves/save_1.dat";  // Read-only at runtime; doesn't work
var path = "C:/Users/.../saves";       // Platform-specific; doesn't work
```

For multi-slot saves, use a folder structure:

```
user://
├── settings.cfg
├── stats.cfg
└── saves/
    ├── slot_1.dat
    ├── slot_2.dat
    └── slot_3.dat
```

Create the saves directory if it doesn't exist:

```csharp
if (!DirAccess.DirExistsAbsolute("user://saves"))
{
    DirAccess.MakeDirAbsolute("user://saves");
}
```

## Save Format Options

Godot offers several built-in mechanisms for saving data. Pick based on the use case.

### `ConfigFile` — for settings and small structured data

`ConfigFile` is the easiest path. It's an INI-like format with sections and key-value pairs. Built into Godot, no external libraries needed, human-readable.

```csharp
public partial class Settings : Node
{
    private const string SettingsPath = "user://settings.cfg";

    public void Save()
    {
        var config = new ConfigFile();

        config.SetValue("audio", "master_volume", AudioServer.GetBusVolumeDb(0));
        config.SetValue("audio", "music_volume", AudioServer.GetBusVolumeDb(1));
        config.SetValue("audio", "sfx_volume", AudioServer.GetBusVolumeDb(2));

        config.SetValue("video", "fullscreen", DisplayServer.WindowGetMode() == DisplayServer.WindowMode.Fullscreen);
        config.SetValue("video", "vsync", DisplayServer.WindowGetVsyncMode() != DisplayServer.VSyncMode.Disabled);

        config.SetValue("input", "keybindings", SerializeKeybindings());

        config.Save(SettingsPath);
    }

    public void Load()
    {
        var config = new ConfigFile();
        var error = config.Load(SettingsPath);

        if (error != Error.Ok)
        {
            // First run, or file missing/corrupt — use defaults
            return;
        }

        AudioServer.SetBusVolumeDb(0, (float)config.GetValue("audio", "master_volume", 0.0));
        AudioServer.SetBusVolumeDb(1, (float)config.GetValue("audio", "music_volume", 0.0));
        AudioServer.SetBusVolumeDb(2, (float)config.GetValue("audio", "sfx_volume", 0.0));

        var fullscreen = (bool)config.GetValue("video", "fullscreen", false);
        DisplayServer.WindowSetMode(fullscreen ? DisplayServer.WindowMode.Fullscreen : DisplayServer.WindowMode.Windowed);

        // ... etc
    }
}
```

`ConfigFile` is good for:

- Settings (audio, video, controls)
- Small flat data
- Things you want to be human-readable for debugging or modding

It's not good for:

- Large binary data
- Complex nested structures (technically possible but awkward)
- Save files that need tamper resistance

### JSON — for structured save data

For save data with nested structure, JSON is the natural fit. C# in Godot has access to all of .NET, so you can use `System.Text.Json` (built-in) or `Newtonsoft.Json` (NuGet).

`System.Text.Json` is built into .NET 8 and works well for most cases:

```csharp
using System.Text.Json;
using System.Text.Json.Serialization;

public class SaveData
{
    public int Version { get; set; } = 1;
    public string PlayerName { get; set; }
    public int Level { get; set; }
    public int Experience { get; set; }
    public Vector2Save Position { get; set; }
    public List<string> Inventory { get; set; } = new();
    public Dictionary<string, int> Stats { get; set; } = new();
    public DateTime SavedAt { get; set; }
}

public class Vector2Save
{
    public float X { get; set; }
    public float Y { get; set; }

    public static Vector2Save From(Vector2 v) => new() { X = v.X, Y = v.Y };
    public Vector2 ToVector2() => new(X, Y);
}

public partial class SaveSystem : Node
{
    public void SaveGame(int slot, SaveData data)
    {
        var path = $"user://saves/slot_{slot}.json";
        DirAccess.MakeDirRecursiveAbsolute("user://saves");

        var json = JsonSerializer.Serialize(data, new JsonSerializerOptions
        {
            WriteIndented = true
        });

        using var file = FileAccess.Open(path, FileAccess.ModeFlags.Write);
        if (file == null)
        {
            GD.PrintErr($"Failed to open save file: {FileAccess.GetOpenError()}");
            return;
        }
        file.StoreString(json);
    }

    public SaveData LoadGame(int slot)
    {
        var path = $"user://saves/slot_{slot}.json";
        if (!FileAccess.FileExists(path))
        {
            return null;
        }

        using var file = FileAccess.Open(path, FileAccess.ModeFlags.Read);
        if (file == null)
        {
            GD.PrintErr($"Failed to open save file: {FileAccess.GetOpenError()}");
            return null;
        }

        var json = file.GetAsText();

        try
        {
            return JsonSerializer.Deserialize<SaveData>(json);
        }
        catch (JsonException e)
        {
            GD.PrintErr($"Failed to parse save file: {e.Message}");
            return null;
        }
    }
}
```

JSON is good for:

- Most save data
- Files you might want to inspect manually
- Cross-language interop (e.g., a backend that reads saves)

It's not good for:

- Binary data (textures, audio); you'd encode them as base64 which is bloated
- Tamper resistance (it's plain text and easy to edit)
- Very large saves where binary format would be smaller

Note on `Vector2`: Godot's `Vector2` is a struct that doesn't serialize cleanly to JSON by default. Either implement a converter or use a wrapper class like `Vector2Save` above.

### Binary `FileAccess` — for compact or tamper-resistant saves

For binary save formats, use `FileAccess` directly:

```csharp
public void SaveBinary(int slot, SaveData data)
{
    var path = $"user://saves/slot_{slot}.dat";
    using var file = FileAccess.Open(path, FileAccess.ModeFlags.Write);

    file.Store32((uint)data.Version);
    file.StorePascalString(data.PlayerName);
    file.Store32((uint)data.Level);
    file.Store32((uint)data.Experience);
    file.StoreFloat(data.Position.X);
    file.StoreFloat(data.Position.Y);
    file.Store32((uint)data.Inventory.Count);
    foreach (var item in data.Inventory)
    {
        file.StorePascalString(item);
    }
    // ... etc
}

public SaveData LoadBinary(int slot)
{
    var path = $"user://saves/slot_{slot}.dat";
    if (!FileAccess.FileExists(path)) return null;

    using var file = FileAccess.Open(path, FileAccess.ModeFlags.Read);

    var version = (int)file.Get32();
    var data = new SaveData
    {
        Version = version,
        PlayerName = file.GetPascalString(),
        Level = (int)file.Get32(),
        Experience = (int)file.Get32(),
        Position = new Vector2Save { X = file.GetFloat(), Y = file.GetFloat() }
    };

    var inventoryCount = file.Get32();
    for (int i = 0; i < inventoryCount; i++)
    {
        data.Inventory.Add(file.GetPascalString());
    }

    return data;
}
```

Binary is good for:

- Compact storage (smaller files than JSON)
- Some tamper resistance (not real security but raises the bar)
- Speed (faster to read/write than JSON for large data)

It's not good for:

- Debugging (can't read it manually)
- Save format evolution (need to manage byte layout carefully)
- Cross-language sharing

For most indie projects, **JSON is the right default**. Reach for binary only when JSON's downsides bite.

### `Resource.Save` — for Godot-native resources

Godot's `ResourceSaver` and `ResourceLoader` can save and load any `Resource`, including custom ones:

```csharp
[GlobalClass]
public partial class SaveData : Resource
{
    [Export] public int Version { get; set; } = 1;
    [Export] public string PlayerName { get; set; }
    [Export] public int Level { get; set; }
    [Export] public Vector2 Position { get; set; }
    [Export] public Godot.Collections.Array<string> Inventory { get; set; } = new();
}

public void SaveGame(int slot)
{
    var data = new SaveData
    {
        PlayerName = "Glenn",
        Level = 5,
        Position = new Vector2(100, 200),
        Inventory = new Godot.Collections.Array<string> { "sword", "potion" }
    };

    var path = $"user://saves/slot_{slot}.tres";
    ResourceSaver.Save(data, path);
}

public SaveData LoadGame(int slot)
{
    var path = $"user://saves/slot_{slot}.tres";
    if (!ResourceLoader.Exists(path)) return null;
    return ResourceLoader.Load<SaveData>(path);
}
```

`Resource`-based saves are convenient because:

- Native Godot serialization (handles `Vector2`, `Color`, etc.)
- The save data is just a `Resource` you can edit in the inspector
- Type-safe in C#
- No JSON converters needed for Godot types

The downsides:

- Files are in Godot's `.tres` text format (or binary `.res`); harder to inspect than JSON
- Less portable to other systems
- Loading bypasses the `Resource` cache, which can cause issues with reused references

For most save data, JSON is more flexible. Use `Resource.Save` when the save data is genuinely just Godot objects.

## Save Versioning (Critical)

**Every save format must have a version number.** Without one, you cannot evolve the save format without breaking existing saves. This is non-negotiable.

```csharp
public class SaveData
{
    public int Version { get; set; } = CurrentVersion;
    public const int CurrentVersion = 3;

    // ... other fields
}

public SaveData LoadGame(int slot)
{
    var data = LoadRaw(slot);
    if (data == null) return null;

    if (data.Version < CurrentVersion)
    {
        data = MigrateSave(data);
    }

    return data;
}

private SaveData MigrateSave(SaveData data)
{
    if (data.Version == 1)
    {
        // Migrate v1 → v2
        // (Add new fields, transform existing ones)
        data.Version = 2;
    }

    if (data.Version == 2)
    {
        // Migrate v2 → v3
        data.Version = 3;
    }

    return data;
}
```

Two important rules:

1. **Migrations are step-by-step.** v1 → v2 → v3, not v1 → v3 directly. If you skip steps, you can't add a v4 cleanly later.
2. **Migrations only go forward.** Don't try to make new saves work with old versions of the game.

What needs migration:

- New fields with defaults (the migration sets the default)
- Renamed fields (the migration copies the old value to the new name)
- Changed structure (the migration restructures the data)
- Removed fields (the migration ignores them)

### When to bump the version

Any change to the save format that's not purely additive with sensible defaults. If the game can read v1 saves correctly without any code changes, the version doesn't need to bump. If it can't, bump it and write a migration.

Conservative rule: **bump on every meaningful change, even if you think it's compatible.** Easier to have many small migrations than one big "what changed" investigation.

### Version mismatch — too new

If a save file has a version *higher* than the current game (the player downgraded?), don't try to load it. Show a clear message: "This save was made with a newer version of the game. Please update."

```csharp
if (data.Version > CurrentVersion)
{
    GD.PrintErr("Save is from a newer version; cannot load");
    ShowError("This save is from a newer version of the game.");
    return null;
}
```

## Autosave

Most modern games autosave. The pattern:

```csharp
public partial class AutoSaveManager : Node
{
    [Export] public float AutoSaveInterval { get; set; } = 60.0f; // 1 minute

    private float _timeSinceLastSave = 0;

    public override void _Process(double delta)
    {
        _timeSinceLastSave += (float)delta;
        if (_timeSinceLastSave >= AutoSaveInterval)
        {
            AutoSave();
            _timeSinceLastSave = 0;
        }
    }

    public void AutoSave()
    {
        var saveData = GameState.GetCurrentSaveData();
        SaveSystem.Save("autosave", saveData);
        ShowAutosaveIndicator();
    }
}
```

A few rules:

- **Don't autosave during action.** Save at safe points: between rooms, during pauses, when the player is idle.
- **Show a brief indicator** when autosave happens, so the player knows.
- **Don't block the main thread for long saves.** If the save is heavy, do it in a background thread.
- **Have multiple autosave slots.** If autosave 1 corrupts, you can fall back to autosave 2.
- **Combine with manual save slots.** Autosave is for safety; manual saves are for player control.

## Save Errors

Saves fail. The disk is full; the file is locked; the game crashes mid-write. Handle errors gracefully:

```csharp
public bool TrySave(int slot, SaveData data)
{
    try
    {
        var path = $"user://saves/slot_{slot}.json";
        var tempPath = path + ".tmp";

        // Write to a temp file first
        using (var file = FileAccess.Open(tempPath, FileAccess.ModeFlags.Write))
        {
            if (file == null)
            {
                GD.PrintErr($"Failed to open temp save file: {FileAccess.GetOpenError()}");
                return false;
            }
            file.StoreString(JsonSerializer.Serialize(data));
        }

        // Replace the real file with the temp file
        if (FileAccess.FileExists(path))
        {
            DirAccess.RemoveAbsolute(path);
        }
        DirAccess.RenameAbsolute(tempPath, path);
        return true;
    }
    catch (Exception e)
    {
        GD.PrintErr($"Save error: {e.Message}");
        return false;
    }
}
```

The "write to temp, then rename" pattern prevents partial writes from corrupting the existing save. If the write fails or the game crashes, the existing save is untouched.

For really paranoid handling: **keep N backups**. Every save, rotate the previous file to `.bak.1`, `.bak.2`, etc. If the current save is corrupt, fall back.

## Tamper Resistance

For purely single-player games, full save security isn't needed — players can edit their own saves if they want. But if your game has competitive features (leaderboards, achievements, multiplayer), some tamper resistance is worth having.

Levels of protection:

1. **None** — JSON in plain text. Anyone can edit it.
2. **Obfuscation** — base64 encoding, simple XOR. Stops casual modification, doesn't stop motivated players.
3. **Hashing** — include a hash of the data; reject saves where the hash doesn't match. Stops most edits but can be reverse-engineered.
4. **Encryption** — encrypt with a key shipped in the binary. Stops most players but the key can be extracted.
5. **Server-side validation** — the authoritative save lives on a server; the client never has the unencrypted data. The only real protection.

For a single-player game with leaderboards, hashing is usually enough:

```csharp
private string ComputeHash(string data)
{
    var bytes = System.Text.Encoding.UTF8.GetBytes(data + "secret_salt");
    var hash = System.Security.Cryptography.SHA256.HashData(bytes);
    return Convert.ToHexString(hash);
}

public void SaveWithHash(SaveData data)
{
    var json = JsonSerializer.Serialize(data);
    var hash = ComputeHash(json);

    var wrapped = new { Data = json, Hash = hash };
    var wrappedJson = JsonSerializer.Serialize(wrapped);

    // Save wrappedJson
}

public SaveData LoadWithHash(string wrappedJson)
{
    var wrapper = JsonSerializer.Deserialize<JsonElement>(wrappedJson);
    var json = wrapper.GetProperty("Data").GetString();
    var savedHash = wrapper.GetProperty("Hash").GetString();

    var computedHash = ComputeHash(json);
    if (savedHash != computedHash)
    {
        GD.PrintErr("Save file tampered with");
        return null;
    }

    return JsonSerializer.Deserialize<SaveData>(json);
}
```

This isn't real security — the salt is in the binary and can be extracted — but it stops casual tampering.

## Cloud Saves

For Steam, Epic, GOG, mobile stores, etc., the platform usually provides cloud save sync. Configure it in:

- **Steam**: Steamworks settings; configure Steam Cloud quota and file paths. Save files in `user://` are typically picked up.
- **Epic / GOG**: similar mechanisms.
- **iOS / Android**: platform-specific APIs (Game Center, Google Play Games).

For most desktop stores, cloud sync is automatic if you save to `user://`. Verify on each platform.

## Common Save Patterns

### Profile system

A profile is the player's identity (name, settings, achievements). Save slots are individual game runs by that profile.

```
user://
├── profiles/
│   ├── default/
│   │   ├── settings.cfg
│   │   ├── achievements.cfg
│   │   └── saves/
│   │       ├── slot_1.json
│   │       └── slot_2.json
│   └── second_player/
│       └── ...
```

### Save metadata

Each save has metadata visible in the load menu — playtime, level, screenshot, save date. Store this in a way that can be loaded *without* loading the entire save:

```csharp
public class SaveMetadata
{
    public int Version { get; set; }
    public string PlayerName { get; set; }
    public int Level { get; set; }
    public TimeSpan Playtime { get; set; }
    public DateTime SavedAt { get; set; }
    public string ScreenshotPath { get; set; }
}
```

The metadata file is small and quick to load. The full save data is loaded only when the player picks a slot.

### Atomic level saves

If the game has discrete "levels" or "rooms", save the state of each one separately. When the player leaves a room, save its state to its own file. When they return, load it. This makes saves smaller and avoids re-saving the entire world every time.

## Anti-Patterns

- **No version field.** First time you change the save format, every existing save breaks.
- **No migration code.** Bumped the version but didn't write a migration. Old saves crash on load.
- **Saving during gameplay** without considering the cost. Frame hitches when the disk write is slow.
- **Direct write to the real file.** If the game crashes mid-write, the save is corrupted. Use temp + rename.
- **Saving everything in one giant file.** Slow to read/write; corruption risk; can't load partial state.
- **Plain-text saves with leaderboard scores.** Players will edit them and submit fake scores.
- **Saving raw `Vector2` to JSON without a converter.** Doesn't serialize correctly with `System.Text.Json`.
- **Loading without error handling.** Corrupted file → unhandled exception → game crash.
- **`res://` instead of `user://`.** Doesn't work; `res://` is read-only at runtime.
- **No autosave at all.** Player loses progress on crash.
- **Autosave so frequent it hitches the game.** Save at safe points, not every frame.
- **No backups.** One corrupt file = lost progress. Keep at least one previous save.
- **Saving editor-only state.** Some properties are editor-only and don't make sense at runtime.
- **Cross-platform incompatible serialization.** `BinaryFormatter` is .NET-specific; .NET 8 even refuses to use it.
- **Saving `Node` references directly.** They don't serialize; you need to save IDs and reconstruct.
- **Migration code that's not idempotent.** Running it twice produces different results.
- **No way to tell which version a save is.** Hidden in the binary; debugging is impossible.
- **Cloud sync conflicts not handled.** Two devices write different saves; no resolution strategy.
- **Save format coupled to scene structure.** Refactoring the scene breaks every existing save.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — `Resource`, `FileAccess`
- [exporting-and-platforms.md](exporting-and-platforms.md) — platform-specific save locations and cloud sync
- [security-engineering](../../security-engineering/SKILL.md) — for tamper-resistant saves
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
