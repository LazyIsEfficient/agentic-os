# Exporting and Platforms

Building a Godot game and getting it to players is most of the work that happens *after* the game is "done." Each platform has its own requirements, gotchas, and asset pipeline. This file is the practical guide to exporting Godot 4 projects to each common target.

The single most important rule: **test on the target platform early and often**. Desktop is forgiving; mobile, web, and console will surface problems that don't exist on dev machines. A game that's tested only on desktop will discover its mobile-specific bugs the day before launch.

## Export Presets

Export configuration lives in **Project → Export...** as one or more presets. Each preset targets a specific platform with specific settings.

A typical project has:

- **Windows Desktop** — `.exe` for Windows users.
- **Linux** — `.x86_64` binary for Linux users.
- **macOS** — `.app` bundle (signed and notarized for the App Store).
- **Android** — APK or AAB for Google Play.
- **iOS** — Xcode project for App Store.
- **Web** — HTML/JS/WASM for browsers.

Plus, sometimes:

- **Dedicated server** — headless build for hosting multiplayer servers.
- **Console** (Switch, PlayStation, Xbox) — requires platform SDKs and licensing; out of scope for this skill.

## Export Templates

Before exporting, you need the **export templates** — Godot's pre-built engine binaries for each target platform. Download them via **Editor → Manage Export Templates...** or directly from the Godot website.

Templates are versioned to match the editor. If you upgrade Godot, you also need to upgrade templates.

For C# projects, you need the **.NET version** of the export templates, not the standard ones. The .NET templates include the .NET runtime in the export.

## Common Export Settings

Each preset has dozens of settings. The most important ones:

### Resources

- **Export Mode**: `PCK Encrypted` for production builds (encrypts the data file). `PCK` for unencrypted (smaller, faster, but inspectable). `ZIP` for some hosting scenarios.
- **Filters to export non-resource files**: explicitly include or exclude files. Useful for modding support or excluding dev-only files.

### Features

- **Custom features**: a list of feature tags this export should include. Use `OS.HasFeature("...")` to check at runtime. Useful for "demo build" vs "full build" or "server" vs "client" builds.

### Renderer

Per-platform renderer choice. Generally:

- **Desktop**: Forward+ (the default; full features)
- **Mobile**: Mobile (lighter; fewer features)
- **Web**: Compatibility (most compatible)
- **Lower-end desktop**: Mobile or Compatibility

You can override per-export-preset.

### Encryption

If you're worried about reverse engineering or want to obfuscate game data, enable PCK encryption. Set an encryption key in the project settings; the engine uses it to encrypt the resource file. **The key is in the binary** so this is mild obfuscation, not real security — but it stops casual extraction.

## Per-Platform Export

### Windows Desktop

- **Output**: `.exe` plus a `.pck` (the data file). The PCK can be embedded into the EXE for a single-file build.
- **Code signing**: signing the EXE prevents Windows SmartScreen warnings. Use `signtool.exe` with a code-signing certificate.
- **Icon**: set in the export preset; auto-applied to the EXE.
- **Console window**: by default, the game shows a console window in debug builds. For release, disable it.

### Linux

- **Output**: an `.x86_64` binary plus a `.pck`.
- **Distribution formats**: tar.gz, AppImage, Flatpak, Snap. Each has different requirements.
- **AppImage** is the easiest cross-distribution format — bundles everything into a single executable file.
- **Steam** packages Linux builds via the depot system; just put the binary and PCK in the depot.

### macOS

- **Output**: an `.app` bundle.
- **Code signing**: required for distribution. Without it, users get a "developer cannot be verified" warning.
- **Notarization**: for distribution outside the App Store, Apple requires notarization (an automated security scan). Use `xcrun notarytool` after signing.
- **Universal binary**: macOS now requires Apple Silicon support. Godot 4's export supports both Intel and Apple Silicon (universal builds).
- **App Store**: requires meeting App Store guidelines, providing screenshots, etc. Significant overhead.

The signing/notarization workflow can be automated:

```bash
# After Godot exports to MyGame.app:
codesign --deep --force --options runtime --sign "Developer ID Application: Your Name" MyGame.app
ditto -c -k --sequesterRsrc --keepParent MyGame.app MyGame.zip
xcrun notarytool submit MyGame.zip --apple-id you@example.com --password APP_PASSWORD --team-id TEAMID --wait
xcrun stapler staple MyGame.app
```

### Android

- **Output**: an APK (Android Package) or AAB (Android App Bundle, required for Google Play).
- **Requirements**: Android SDK + Java JDK + Gradle. Configure paths in **Editor Settings → Export → Android**.
- **Signing**: Android requires a keystore. Generate one with `keytool` and configure in the export preset.
- **Permissions**: declare needed permissions in the export preset (Internet, Storage, etc.).
- **Min/target SDK version**: set in the preset. Google Play requires updating target SDK periodically.
- **Architectures**: ARMv7, ARMv8, x86, x86_64. ARMv8 is the modern default. Including more architectures bloats the APK.

A few mobile-specific things:

- **Use the Mobile renderer**, not Forward+.
- **Texture compression**: ASTC for modern devices, ETC2 for compatibility.
- **Test on real low-end hardware**, not the latest flagship phone.
- **Battery and thermal throttling**: a long session will throttle the CPU/GPU. Plan for it.

### iOS

- **Output**: an Xcode project. You then build it in Xcode and submit via App Store Connect.
- **Requirements**: macOS, Xcode, Apple Developer account.
- **Provisioning profiles**: required for any iOS deployment. Set up in Apple's developer portal.
- **App Store guidelines**: review them before designing the game. Some monetization patterns are forbidden; some content is restricted; some features (parental controls, accessibility) are required.
- **Performance**: similar concerns to Android — test on real low-end iOS devices.

### Web

- **Output**: HTML, JS, WASM, and a PCK file.
- **Requirements**: a web server to serve the files. Local file:// URLs don't work.
- **Specific server requirements**: Godot's web export uses `SharedArrayBuffer`, which requires the server to send `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp` headers.
- **Initial load size**: the WASM file is several megabytes; the PCK is project-dependent. Web games should be under ~50MB total for reasonable load times.
- **Memory limit**: ~2GB hard limit; less in practice. Trim assets aggressively.
- **No threading** (mostly): web has limited threading. Some Godot features that depend on threads don't work.
- **Audio quirks**: web audio has known issues with Godot. Test thoroughly.
- **No file system access**: `user://` is browser local storage; no real file I/O.
- **Use the Compatibility renderer** for the broadest compatibility.

A typical web hosting setup:

```nginx
# nginx config snippet for hosting a Godot web export
server {
    listen 443 ssl http2;
    server_name game.example.com;

    location / {
        root /var/www/game;
        add_header Cross-Origin-Opener-Policy same-origin;
        add_header Cross-Origin-Embedder-Policy require-corp;
        try_files $uri $uri/ /index.html;
    }
}
```

The `Cross-Origin-*` headers are required; without them, the game won't load.

### Dedicated server

For online multiplayer games, you'll want a server build that:

- Has no rendering, audio, or input.
- Runs headless on Linux.
- Uses minimal resources.

Set up a dedicated-server export preset:

- **Platform**: Linux/X11
- **Custom features**: `dedicated_server` (or your own tag)
- **Templates**: use the `linux_server.x86_64` template if available, or the standard Linux template
- **Run as headless**: pass `--headless` on the command line

In your code, branch on the feature:

```csharp
public override void _Ready()
{
    if (OS.HasFeature("dedicated_server") || "--server" in OS.GetCmdlineArgs())
    {
        StartServer();
    }
    else
    {
        ShowMainMenu();
    }
}
```

Strip out client-only assets (textures, audio, models) from the server build via export filters to make the server binary smaller.

## Asset Import Settings

The biggest performance lever for many projects is **asset import settings**. These are configured per-asset in the import dock.

### Textures

- **Compress Mode**:
  - `Lossless` for pixel art and UI.
  - `Lossy` (WebP) for general 2D art (small files; some quality loss).
  - `VRAM Compressed` for 3D textures (S3TC/BC on desktop, ASTC/ETC on mobile).
- **Filter**:
  - `Nearest` for pixel art.
  - `Linear` for everything else.
- **Mipmaps**: generate for 3D textures and zoomed-out 2D; skip for fixed-size UI.
- **Detect 3D**: when on, Godot warns if you use a 2D-imported texture in 3D. Helpful default.

### Models

- **Materials**: keep external materials (separate `.tres` files) for tweaking. Use embedded materials for one-off models.
- **Mesh compression**: enable for smaller files.
- **Generate LODs**: Godot 4 can auto-generate Level-of-Detail meshes for distance-based simplification. Big win for 3D performance.
- **Generate tangents**: required for normal mapping.
- **Animation import**: select which animations to keep, set loop modes, etc.

### Audio

- **Loop**: for looping music or ambient.
- **Compression**: OGG Vorbis is the default and works well. WAV for short SFX where the file size doesn't matter.
- **Trim**: silent leading/trailing audio.

### Fonts

- **Antialiasing**: smoother text but blurrier pixel art.
- **Subpixel positioning**: better text quality.
- **Multichannel signed distance field**: for fonts that need to scale to many sizes; bigger texture, better quality.

## Build Pipeline

For any non-trivial project, set up an automated build pipeline. The basic flow:

1. **CI triggers** on push or release tag.
2. **Build the project** via `godot --headless --export "Preset Name" output_file`.
3. **Sign and package** for the target platform.
4. **Upload** to distribution (Steam, Itch.io, Google Play, App Store, etc.).

This deserves a real engineering setup; see [deployment-pipelines](../../deployment-pipelines/SKILL.md).

A simple GitHub Actions example for a Linux build:

```yaml
name: Build Linux
on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Godot
        uses: chickensoft-games/setup-godot@v2
        with:
          version: 4.2.2
          use-dotnet: true
      - name: Import resources
        run: godot --headless --import || true
      - name: Export
        run: |
          mkdir -p build/linux
          godot --headless --export-release "Linux" build/linux/MyGame.x86_64
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: linux-build
          path: build/linux
```

For multi-platform builds, you'll likely want a matrix strategy or separate jobs per platform. Some platforms (macOS, iOS) require macOS runners; Android requires the Android SDK; web requires the right server config for testing.

## Distribution Channels

A few common channels and their requirements:

### Steam (Steamworks)

- **Steam Direct fee**: one-time $100 per game.
- **Steamworks SDK**: integrate via the Steamworks API. Several Godot bindings exist (e.g., GodotSteam).
- **Depots**: organize files into depots; upload via SteamPipe.
- **Achievements, leaderboards, cloud saves**: integrate via the Steamworks API.
- **Reviews and approval**: Steam doesn't curate heavily, but they do basic review.

### Itch.io

- **Free to upload**.
- **Itch app integration**: use butler to upload builds.
- **No store curation**: anyone can publish.
- **Lower exposure than Steam**, but no fees for small games.

### Epic Games Store

- **Less open** than Steam; Epic curates which games get featured.
- **EOS SDK** for Epic-specific features (achievements, friends).

### Google Play

- **$25 one-time fee** to register.
- **AAB format required** (not APK).
- **Content rating** required.
- **Play Console** for managing releases.

### App Store

- **$99/year** Apple Developer fee.
- **App Review** is a real process; expect multiple rounds.
- **Strict content guidelines** — some monetization, gambling, and content are forbidden.
- **iOS-specific features** (iCloud, GameCenter) require integration.

### Console (Switch, PlayStation, Xbox)

- **Closed platforms**: requires applying for a developer license.
- **NDAs**: most details are under NDA.
- **SDK requirements**: each platform has its own SDK and requires platform-specific code.
- **Out of scope** for this skill; engage a porting partner if you need console releases.

## Versioning Builds

Every released build should be uniquely identified. The pattern:

- **Semantic version** in the project settings (`config/version` or your own).
- **Build number** that increments per build.
- **Git commit hash** baked into the binary.

```csharp
public partial class VersionInfo : Node
{
    public const string Version = "1.2.3";
    public const string GitCommit = "abc1234"; // Set by CI
    public const string BuildDate = "2026-04-07"; // Set by CI

    public override void _Ready()
    {
        GD.Print($"MyGame v{Version} ({GitCommit}) built {BuildDate}");
    }
}
```

CI substitutes the placeholders before building. Display the version somewhere in the UI (settings menu, splash screen) for bug reports.

## Telemetry and Crash Reporting

Once a game is in players' hands, you need to know what's happening. Options:

- **Crash reporting**: Sentry, Bugsnag, Backtrace, etc. There are Godot integrations or you can wire it up via HTTP.
- **Analytics**: PostHog, GameAnalytics, Unity Analytics (yes, even for Godot games), or your own backend.
- **Player feedback**: in-game feedback button that submits to a backend or email.

Whatever you use, **be transparent and let players opt out**. Some jurisdictions require consent.

## Anti-Patterns

- **Testing only on dev machine.** Mobile, web, and low-end hardware will surface problems.
- **No automated build pipeline.** Manual builds are slow, error-prone, and hard to reproduce.
- **One mega-export-preset for all platforms.** Different platforms need different settings.
- **Same renderer for all platforms.** Forward+ on mobile is too heavy.
- **Same texture compression for all platforms.** Use BCn on desktop, ASTC/ETC on mobile.
- **No version info in builds.** Bug reports come in for an unknown version.
- **No code signing.** Windows SmartScreen blocks; macOS shows scary warnings.
- **No automated update system.** Players have to manually download new versions.
- **Web builds without the right CORS headers.** Game doesn't load.
- **iOS/Android without testing on a low-end device.** Performance disasters at launch.
- **No telemetry or crash reporting.** Can't tell what's broken in the wild.
- **Mixing client and server in the same build** without a feature flag. Server has rendering and audio it doesn't need.
- **Forgetting to update target SDK** for Android. Google Play eventually rejects old SDKs.
- **Forgetting to renew Apple Developer account.** Builds expire.
- **Forgetting to renew code-signing certificates.** Builds stop signing.
- **Including dev-only files in release builds.** `*.tmp`, `*.bak`, debug logs.
- **PCK encryption with the key checked into version control.** Defeats the purpose.
- **Hardcoded test URLs.** Production server URL still points to dev.
- **No way to debug release builds.** No log file, no remote logging, no in-game console.
- **Releasing without a beta phase.** Bugs that beta would have caught hit everyone.

## Related

- [godot-fundamentals.md](godot-fundamentals.md) — `OS.HasFeature`, `OS.GetCmdlineArgs`
- [save-load-and-persistence.md](save-load-and-persistence.md) — `user://` paths and platform differences
- [performance-and-profiling.md](performance-and-profiling.md) — per-platform performance
- [multiplayer-and-websockets.md](multiplayer-and-websockets.md) — server builds
- [deployment-pipelines](../../deployment-pipelines/SKILL.md) — CI for Godot builds
- the `devops-engineer` agent — hosting servers and web builds
- [security-engineering](../../security-engineering/SKILL.md) — code signing, anti-tampering
- [godot-anti-patterns.md](godot-anti-patterns.md) — broader patterns to avoid
