# Project and Vite

This file is the practical "how do I start a Phaser 3 + TypeScript project today" reference. Scaffold, build tool, TypeScript config, the entry point, the first scene, where assets live, what `npm run dev` and `npm run build` actually do. If you're staring at an empty directory, start here. If you inherited a Phaser project that's on Webpack and Babel-compiled JS, skim this anyway — the conventions matter regardless of how you got there.

## Why Vite

Vite is the default build tool in this skill and there is exactly one reason: **the iteration loop is faster**. Native ESM in development means no bundling step on save — the browser fetches the modules you changed and nothing else. HMR on non-Phaser code (UI overlays, plain TypeScript modules) updates without a refresh. The production build is `esbuild` for transforms plus Rollup for bundling, and both are fast and well-maintained. Configuration is one short file. There is no `webpack.config.js` with eight loaders, no `babel.config.js`, no plugin-resolve-tree to debug at midnight.

Webpack and Parcel are valid choices. The Phaser docs ship templates for both. This skill picks Vite because the speed-of-edit-to-screen pays for itself in the first hour, and the production output is identical: a static `dist/` you can host on anything.

## Initial scaffold

The shortest path from nothing to a running Phaser project:

```bash
npm create vite@latest my-game -- --template vanilla-ts
cd my-game
npm install
npm install phaser
```

Vite's `vanilla-ts` template gives you the right TS config and dev-server setup without any framework noise (no React, no Vue, no Svelte). After `npm install phaser` you have everything you need to run a Phaser game.

The resulting project structure:

```
my-game/
├── node_modules/         ← gitignored
├── public/               ← static assets, served verbatim
├── src/
│   ├── main.ts           ← entry point
│   ├── style.css         ← (delete or repurpose)
│   ├── typescript.svg    ← (delete)
│   └── vite-env.d.ts     ← Vite's type augmentations
├── index.html            ← entry HTML
├── package.json
├── tsconfig.json
└── vite.config.ts        ← (you'll add this)
```

You'll delete the `src/style.css`, `src/counter.ts`, and SVG that the template ships with, and replace `src/main.ts` with the Phaser entry. The rest stays.

## `package.json`

A minimal but complete `package.json` after scaffolding:

```json
{
  "name": "my-game",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "phaser": "^3.80.0"
  },
  "devDependencies": {
    "typescript": "^5.4.0",
    "vite": "^5.2.0"
  }
}
```

Key points:

- **`phaser` is a runtime dependency**, not a devDependency. It ends up in your bundle.
- **Do not install `@types/phaser`.** Phaser 3 ships its own type definitions in `phaser/types/phaser`, and they are good. The `@types/phaser` package on DefinitelyTyped is stale and will fight the bundled types if both are present.
- **`type: "module"`** matters — it tells Node and Vite that `.js`/`.ts` files use ESM. The default Vite template sets this; don't remove it.
- **The build script runs `tsc -b` first** to typecheck (with project references / build mode), then `vite build` to bundle. If TS fails, the build fails. This is the right gate.
- **`preview`** serves the built `dist/` locally so you can sanity-check the production build before deploying.

## `vite.config.ts`

For a basic Phaser project, the config is short. Create `vite.config.ts` at the project root:

```ts
import { defineConfig } from 'vite'

export default defineConfig({
  base: './',
  publicDir: 'public',
  server: {
    port: 5173,
    open: true,
  },
  build: {
    outDir: 'dist',
    sourcemap: true,
    chunkSizeWarningLimit: 1500,
  },
})
```

What each setting buys you:

- **`base: './'`** — emits relative URLs in the built `index.html`. This is what makes the same `dist/` work on itch.io, on a subpath, on `file://` (with a local server), and on the root of a domain. If you know you're deploying to a fixed subpath (e.g. `https://example.com/games/my-game/`), set `base: '/games/my-game/'` instead — relative paths still work but absolute paths are slightly nicer for asset prefetching.
- **`publicDir: 'public'`** — files in `public/` are copied verbatim into `dist/` at build time, no fingerprinting. This is where Phaser-loaded assets live (see "Asset directory conventions" below).
- **`server.open: true`** — opens the browser when `npm run dev` starts. Convenience; remove if it annoys you.
- **`build.sourcemap: true`** — ships sourcemaps to the `dist/` so production stack traces are readable. For a public game where you don't want source visible, set this to `'hidden'` — sourcemaps are emitted but not referenced from the JS, so error reporting tools can use them but casual users can't.
- **`build.chunkSizeWarningLimit: 1500`** — Vite's default is 500 kB and Phaser alone is ~1 MB minified. The default warning is meaningless noise for a game; bump it so real warnings (an accidentally-included 5 MB lib) still fire.

You don't need a `vite-plugin-phaser`. Phaser is a normal npm package; Vite handles it as-is.

## `tsconfig.json`

The `vanilla-ts` template's `tsconfig.json` is mostly correct but worth tightening:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],

    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "exactOptionalPropertyTypes": false,

    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "isolatedModules": true,
    "resolveJsonModule": true,

    "noEmit": true,
    "useDefineForClassFields": true,

    "baseUrl": "./src",
    "paths": {
      "@/*": ["*"]
    }
  },
  "include": ["src"]
}
```

Notes on the choices:

- **`target: "ES2020"`** — Phaser 3 supports modern browsers; you don't need to ship to IE11. ES2020 buys you optional chaining, nullish coalescing, BigInt, dynamic imports, all native. ES2022 is fine too if your minimum browser is recent.
- **`module: "ESNext"` + `moduleResolution: "bundler"`** — the right combo for a Vite/esbuild/Rollup project. `bundler` mode lets you import without extensions and matches how Vite actually resolves modules.
- **`lib: ["ES2020", "DOM", "DOM.Iterable"]`** — Phaser runs in the browser; you want DOM types. `DOM.Iterable` covers `for...of` on `NodeList` and friends, which you'll hit the moment you touch the DOM around the canvas.
- **`strict: true` is non-negotiable.** Turning off strict in a Phaser project is a self-inflicted wound. Phaser's API surface is huge and many methods accept multiple shapes — strict mode forces you to be explicit, which catches real bugs early. If a specific call is too painful with strict, narrow the type at the call site, don't disable strict project-wide.
- **`noUncheckedIndexedAccess: true`** — `arr[0]` becomes `T | undefined` instead of `T`. Saves you from "why is `tile.index` undefined here" three weeks in. Mildly painful when you adopt it; correct.
- **`noImplicitOverride: true`** — when you override Phaser's `preload`, `create`, `update`, you must use the `override` keyword. Catches typos like `creat()` that would otherwise silently fail to override.
- **`baseUrl` + `paths`** — lets you import `import { Player } from '@/entities/Player'` instead of `'../../entities/Player'`. Vite picks this up via `vite-tsconfig-paths` (optional plugin) or you can mirror the same paths in `vite.config.ts` under `resolve.alias`. For small projects, skip it; for anything with more than two folders deep, it's a quality-of-life win.
- **No `types: ["phaser"]` entry.** Phaser's types come from `import Phaser from 'phaser'` — they're attached to the import, not the global. If you use the global `Phaser` namespace in places where you didn't import (e.g. an HTML inline script), you'd add `"types": ["phaser"]`, but the modern pattern is to import everywhere.

## `index.html`

The entry HTML is small but every line earns its keep:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <meta name="theme-color" content="#000000" />
    <title>My Game</title>
    <style>
      html, body {
        margin: 0;
        padding: 0;
        background: #000;
        overflow: hidden;
        height: 100%;
        width: 100%;
      }
      #game {
        width: 100vw;
        height: 100vh;
        touch-action: none;
        user-select: none;
        -webkit-user-select: none;
      }
    </style>
  </head>
  <body>
    <div id="game"></div>
    <script type="module" src="/src/main.ts"></script>
  </body>
</html>
```

What's load-bearing:

- **The viewport meta with `maximum-scale=1.0, user-scalable=no`** — stops mobile browsers from pinch-zooming the canvas, which is almost never what a game wants.
- **`overflow: hidden` on `html, body`** — prevents the page from scrolling when a touch drag goes off the canvas. Critical on mobile.
- **`#game` div as the parent** — Phaser mounts its canvas inside this div. The div needs to exist *before* `new Phaser.Game(...)` runs, which is why `<script type="module">` goes after the body.
- **`touch-action: none`** — prevents the browser from interpreting touches as scroll/zoom gestures and stealing them from Phaser's input system. Most-forgotten setting; symptoms are touches that "miss" the game and pinch-zoom the page.
- **`user-select: none`** — stops accidental text selection during fast tapping. Also a tiny performance win.

The `<script type="module" src="/src/main.ts">` reference is what Vite hooks into. In dev, Vite serves `/src/main.ts` directly (transformed on the fly); in build, Vite rewrites this to the fingerprinted bundle path.

## `src/main.ts`

The canonical entry. Its only job is to instantiate `Phaser.Game` with the right config and register the scenes:

```ts
import Phaser from 'phaser'
import { BootScene } from './scenes/BootScene'
import { PreloadScene } from './scenes/PreloadScene'
import { GameScene } from './scenes/GameScene'
import { HUDScene } from './scenes/HUDScene'

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  parent: 'game',
  backgroundColor: '#000000',
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: 1280,
    height: 720,
  },
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { x: 0, y: 0 },
      debug: false,
    },
  },
  render: {
    pixelArt: false,
    antialias: true,
  },
  scene: [BootScene, PreloadScene, GameScene, HUDScene],
}

new Phaser.Game(config)
```

A few things worth calling out:

- **`type: Phaser.AUTO`** — uses WebGL when available, falls back to Canvas. Use `Phaser.WEBGL` if you depend on shaders or WebGL-only features and want a hard error rather than silent fallback.
- **`parent: 'game'`** — the id of the div in `index.html`. If you mount before the div exists in the DOM, Phaser falls back to appending to `<body>`, which usually does the wrong thing on mobile.
- **`scale.mode: FIT`** with a base resolution — your game logic uses 1280×720, the engine handles letterboxing to whatever the actual viewport is. `RESIZE` is the alternative if your game adapts to the viewport at runtime; it's harder to design for. Pick `FIT` unless you have a reason.
- **`scene` is an array of classes**, not instances. Phaser instantiates them on demand. Order matters: the first scene starts automatically unless you opt into manual control.
- **`pixelArt: true`** — disables texture filtering. Use for pixel-art games. Setting it to `true` and then loading non-pixel-art textures produces ugly aliasing.

For larger projects, split this file: keep `main.ts` to the `new Phaser.Game(config)` call and put the config in `src/config/gameConfig.ts`. For a starter, inline is fine.

## A first scene

`src/scenes/BootScene.ts` — the minimum viable scene:

```ts
import Phaser from 'phaser'

export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: 'BootScene' })
  }

  override preload(): void {
    // Load just enough to render a loading screen.
    this.load.image('logo', 'assets/branding/logo.png')
  }

  override create(): void {
    const { width, height } = this.scale
    this.add.image(width / 2, height / 2, 'logo')

    // After 500ms, transition to the real preloader.
    this.time.delayedCall(500, () => {
      this.scene.start('PreloadScene')
    })
  }
}
```

Things to notice:

- **`super({ key: 'BootScene' })`** — the `key` is how `scene.start('BootScene')` finds this scene. Match it to the class name. Skipping the key works (Phaser will use the class name) but it's brittle.
- **`override` keywords** — required because of `noImplicitOverride: true` in `tsconfig`. Without it, `preolad` (typo) would silently not run.
- **`this.scale.width` / `this.scale.height`** — the *base* resolution from the config (1280×720 in our case), not the actual viewport size. If you want device pixels, use `this.scale.gameSize.width`. Almost always you want the base size.
- **`this.time.delayedCall(...)`** — Phaser's scheduler. Survives scene pause/resume correctly. Don't use `setTimeout` inside scenes; it doesn't interact with Phaser's clock and won't pause when the scene pauses.

The real shape of scenes — `init`, `preload`, `create`, `update`, lifecycle ordering, scene-to-scene communication — is in [scenes-and-flow.md](scenes-and-flow.md). This file just shows you a working minimum.

## Asset directory conventions

This is the part new Phaser engineers get wrong most often. There are two places assets can live, and they behave differently:

### `public/assets/` — recommended for game assets

Files in `public/` are copied verbatim into `dist/` at build time. No fingerprinting, no transformation, predictable URLs.

```
public/
└── assets/
    ├── atlases/
    │   ├── characters.png
    │   └── characters.json
    ├── audio/
    │   ├── music/
    │   └── sfx/
    ├── fonts/
    ├── tilemaps/
    │   └── level1.json
    └── ui/
```

Phaser loads these via the path you'd expect: `this.load.atlas('chars', 'assets/atlases/characters.png', 'assets/atlases/characters.json')`. The path is relative to the served root, which matches `vite.config.ts`'s `base`.

Use this for:

- **Texture atlases** — atlas JSON references the PNG by filename; if Vite fingerprinted the PNG, the JSON's reference would break.
- **Audio files** — usually large, no benefit to fingerprinting per build.
- **Tilemap JSON** (Tiled exports) — they reference tileset images by relative path; same breakage risk as atlases.
- **Anything Phaser's `Loader` fetches** — the loader uses string URLs at runtime; you can't run them through the bundler.

The downside: no fingerprinting means you handle cache busting yourself (typically via cache headers on the CDN, or by versioning the asset path on a release).

### `src/assets/` — for assets you import directly

Files imported via TypeScript (`import logoUrl from './assets/logo.png'`) get fingerprinted and bundled. The import returns the final URL.

```ts
import logoUrl from './assets/logo.png'
// logoUrl === '/assets/logo-a3f29c1b.png' at runtime

this.load.image('logo', logoUrl)
```

Use this for:

- **One-off assets that don't reference other files** — a single icon, a splash logo.
- **Assets you want fingerprinted** for aggressive caching.

Mixing: it's fine to do both. Game-loaded assets in `public/assets/`, build-time imports in `src/assets/`. Don't put atlases or tilemaps under `src/` — the cross-file references will break.

## Asset pipeline notes

Phaser doesn't author your assets — your tooling does. The pipeline matters because the file shape on disk has to match what `Loader` expects.

### Texture atlases

Use **TexturePacker** (commercial; the standard) or **free-tex-packer** (open source) to combine many sprites into one texture + JSON. Phaser supports the JSON-Hash and JSON-Array formats; both packers export both.

Output:
- `characters.png` — the atlas image
- `characters.json` — frame coordinates

Load:
```ts
this.load.atlas('characters', 'assets/atlases/characters.png', 'assets/atlases/characters.json')
// Then:
this.add.sprite(x, y, 'characters', 'hero_idle_01')
```

For pixel-art workflows, **Aseprite** can export directly to a Phaser-compatible JSON (`File → Export Sprite Sheet → Output: JSON Array`). The result is the same shape as TexturePacker's output.

### Tilemaps

**Tiled** (`mapeditor.org`) is the de facto standard. Export as JSON (not TMX) — Phaser's `tilemapTiledJSON` loader expects JSON.

Load:
```ts
this.load.image('tiles', 'assets/tilemaps/tileset.png')
this.load.tilemapTiledJSON('level1', 'assets/tilemaps/level1.json')
// Then in create():
const map = this.make.tilemap({ key: 'level1' })
const tileset = map.addTilesetImage('tileset_name_in_tiled', 'tiles')
```

Tiled object layers can be turned into Phaser game objects via `map.createFromObjects(...)`. The mapping is in [scenes-and-flow.md](scenes-and-flow.md) and physics docs.

### Audio sprites

A single audio file with multiple labeled clips and a JSON of timings. Generate with **audiosprite** (`npm install -g audiosprite`).

```bash
audiosprite -e ogg,mp3 -f howler -o sfx sfx-input/*.wav
```

Output:
- `sfx.ogg`, `sfx.mp3` — the combined audio
- `sfx.json` — clip timings

Load:
```ts
this.load.audioSprite('sfx', 'assets/audio/sfx.json', ['assets/audio/sfx.ogg', 'assets/audio/sfx.mp3'])
// Then:
this.sound.playAudioSprite('sfx', 'jump')
```

Audio sprites are the right call for short SFX (gunshots, jumps, UI clicks) because they avoid the per-file HTTP latency and the per-file decode cost. For longer music tracks, use individual files.

## Dev workflow

```bash
npm run dev
```

Vite starts a dev server (default port 5173), opens the browser, and serves `/src/main.ts` with on-the-fly TypeScript transformation. Save a `.ts` file and Vite pushes the change to the browser.

What HMR does and doesn't do for a Phaser project:

- **Plain TypeScript modules (utilities, data, configs) hot-replace.** If you edit a constants file imported by a scene, Vite swaps the module and the scene picks up the new value next time it reads the import.
- **Phaser scenes already running do NOT auto-rebind.** When you edit `GameScene.ts`, Vite swaps the module, but the *running instance* of `GameScene` is still the old one. Its prototype is now stale; method changes won't take effect on the live instance.

The pragmatic workaround: **just full-reload the page** when you change a scene file. Most engineers configure Vite to do a hard reload on scene changes by adding to `vite.config.ts`:

```ts
export default defineConfig({
  // ...
  server: {
    // ...
    hmr: {
      overlay: true,
    },
  },
})
```

And accept that scenes refresh via `Cmd-R`. The 200ms reload is faster than tracking down phantom-old-instance bugs.

If you want to engineer around it: scenes can listen for `import.meta.hot` events and call `scene.restart()`, but the ergonomics are not worth it for most projects. Reload.

## Prod build

```bash
npm run build
```

This runs `tsc -b` (typecheck) then `vite build` (bundle). The output:

```
dist/
├── index.html                    ← rewritten to point at fingerprinted JS
├── assets/
│   ├── index-a3f29c1b.js         ← bundled and minified
│   └── index-7b2e1d4f.js.map     ← sourcemap
└── assets/                       ← (your public/assets/, copied verbatim)
    ├── atlases/
    ├── audio/
    └── ...
```

Important: there are *two* `assets/` directories that end up at the same path in `dist/`. Vite's bundled JS goes into `dist/assets/index-*.js`, and your `public/assets/` is copied to `dist/assets/...`. They merge cleanly because the filenames don't collide — but if you put a file at `public/assets/index.js`, you'd get a conflict. Don't.

```bash
npm run preview
```

Serves `dist/` on port 4173. Use this to verify the build before deploying — it's the most common place to catch broken asset paths from a misconfigured `base`.

## Deploy notes (light)

Full CI/CD belongs to [deployment-pipelines](../../deployment-pipelines/SKILL.md). A few Phaser-specific things:

- **itch.io** — zip the `dist/` directory (not the parent folder). The zip's root must contain `index.html`. With `base: './'` in `vite.config.ts`, this Just Works. Itch's HTML5 game host serves the zip from a subpath; relative paths are required.
- **Subpath hosting** — if deploying to `https://example.com/games/my-game/`, set `base: '/games/my-game/'` in `vite.config.ts`. Relative paths still work from `index.html`, but absolute references (rare in Phaser projects) need the prefix.
- **CDN cache headers** — fingerprinted JS bundles can be `Cache-Control: public, max-age=31536000, immutable`. Asset files in `public/assets/` are *not* fingerprinted; cache them shorter (e.g. 1 day) or version the directory in your release process. This belongs in CI/CD config, not the project.

## Common gotchas

A short list of the things that will bite you in your first Phaser project:

### Bundle size

Phaser is ~1 MB minified+gzipped. That's not negotiable for the default build — Phaser is mostly not tree-shakeable because the renderer registry pulls in all GameObject types by reference. Treat 1 MB as a floor, not a ceiling.

If you genuinely need a smaller bundle:
- **`phaser/dist/phaser-core.js`** — a slimmer build that excludes physics, input, and several other systems. You opt back in by importing what you need. Real but advanced; only consider if you've shipped and the bundle is the actual problem.
- **Code-split your scenes** — dynamic `import()` per scene means later scenes don't load until the player progresses. Phaser supports this via the scene manager's `add()` method, which accepts a class or a key + class.

For most projects, just accept the 1 MB and ship.

### CORS on `file://`

Don't open `dist/index.html` directly in the browser — `file://` URLs trigger CORS errors on every asset Phaser tries to load. Always serve via `npm run preview`, a real web server, or any local-server tool (`python -m http.server`, `npx serve dist`, etc.).

### Audio autoplay blocking

Browsers block audio playback until the user has interacted with the page (a click, tap, or key press). If `BootScene` tries to play music in `create()`, it silently fails. Phaser's audio system handles this for you when you let it — but it does mean your title music starts on the first input, not on scene start.

The detail belongs in [phaser-anti-patterns.md](phaser-anti-patterns.md), but the short version: don't fight it. Design around the user gesture.

### `parent` element must exist before `new Phaser.Game(...)`

If your `<script type="module">` tag is in `<head>` instead of after the body, the `#game` div doesn't exist yet when `main.ts` runs. Phaser falls back to appending to `<body>`, which usually works visually but breaks the CSS sizing you set on `#game`. Keep the script tag at the end of `<body>`, or wrap the `new Phaser.Game(config)` call in `window.addEventListener('DOMContentLoaded', ...)`.

### Importing Phaser

Always:
```ts
import Phaser from 'phaser'
```

Not:
```ts
import * as Phaser from 'phaser'   // works but loses the default export
import { Scene } from 'phaser'      // works but messes with the namespace
```

The first form is what every Phaser example, every type definition, and every Stack Overflow answer assumes. Stick to it.

## Related

- [phaser-fundamentals.md](phaser-fundamentals.md) — the engine model: `Game`, `Scene`, the loop, the loader, GameObjects, the display list
- [scenes-and-flow.md](scenes-and-flow.md) — scene lifecycle, scene manager, parallel HUD scenes
- [physics-arcade.md](physics-arcade.md) — Arcade physics setup once the project is running
- [phaser-anti-patterns.md](phaser-anti-patterns.md) — what to avoid, including audio unlock and asset re-loading
- [SKILL](../SKILL.md) — the parent skill and its universal rules
- [project-structure-template](../assets/project-structure-template.md) — recommended folder structure that builds on this scaffold
- [deployment-pipelines](../../deployment-pipelines/SKILL.md) — CI/CD for the static `dist/` output
- performance-optimization — bundle size, code splitting, web worker offload beyond Phaser-specific tuning
