# Gameplay Feature Checklist

> Pre-shipping checklist for a new gameplay feature in a Phaser 3 + TypeScript project. Walk through this *before* declaring the feature done. Catches the things engineers routinely forget under deadline pressure — listener leaks, audio unlock, save migrations, mobile quirks, GC spikes in `update()`.

See [SKILL](../SKILL.md) for the parent skill and the universal rules behind these items.

## Header

- **Feature:** _____
- **Engineer:** _____
- **Date:** _____
- **Linked PRD / brief:** _____
- **Linked PR(s):** _____

---

## Code structure

- [ ] Scene under ~600 lines; otherwise systems extracted to `src/systems/` — keeps god scenes from forming.
- [ ] No `this.scene.get('OtherScene').thing` reach-ins for state mutation — use `events`/`registry`/EventBus instead.
- [ ] All `this.events.on(...)` listeners removed in `shutdown()` — leak guard on scene restart.
- [ ] All `this.input.keyboard.on(...)` / `this.input.on(...)` handlers removed in `shutdown()` — input doubles up otherwise on `scene.restart()`.
- [ ] All `tweens` and `timeline` references killed or completed before scene shutdown — orphan tweens fire callbacks against freed objects.
- [ ] Each gameplay system is a plain TS class the scene composes — not a `Phaser.Scene` subclass tree.
- [ ] Player / enemies / pickups composed as `Container` + components, not deep `Sprite` subclasses — composition wins once a second character type appears.
- [ ] Public API of new system is typed (`interface`/`type`), not `any` — TS catches drift cheaper than runtime.
- [ ] No globals smuggled through `this.registry` for things that should be instance state — registry is for cross-scene shared values, not "I didn't want to wire it."
- [ ] Scene keys, asset keys, event names live in `src/data/*.ts` constants — no string-literal sprawl.

## Scene lifecycle

- [ ] `init(data)` payload typed (`interface SceneData`) — untyped data is a footgun.
- [ ] Heavy work happens in `preload`/`create`, not `update` — `update` is the hot path.
- [ ] `shutdown()` (or `events.once('shutdown', ...)`) tears down: listeners, tweens, timers, intervals, custom systems.
- [ ] `wake`/`sleep` handlers exist if scene is launched in parallel and paused — pause without sleep keeps `update` running.
- [ ] Parallel HUD scenes use `scene.launch`, not nested `Container`s in the gameplay scene — separates input/render concerns.
- [ ] Scene-to-scene data flows through `start(key, data)` payloads or `events`, not module-level singletons.
- [ ] `scene.restart()` tested at least once — most leak bugs surface here.

## Hot path (`update`)

- [ ] No `new` allocations in `update()` — pre-allocate or pool.
- [ ] No string concatenation in HUD updates — `BitmapText` or pre-formatted slots updated in place.
- [ ] No `.forEach` over freshly allocated arrays in `update()` — iterate persistent `Group`s with `runChildUpdate`.
- [ ] No `JSON.parse`/`JSON.stringify` in `update()` — serialize on save, not per frame.
- [ ] No `getChildren()` repeatedly per frame — cache the array reference if the group is stable.
- [ ] Math.hypot / Math.sqrt avoided where squared distance suffices.
- [ ] `delta` is used (not assumed 16.6 ms) for any time-scaled motion done outside the physics body.
- [ ] `console.log` removed from hot paths — devtools logging tanks frame rate.
- [ ] Spawned objects come from a pool (`group.getFirstDead(true)`), not `new Sprite` per spawn.

## Physics (Arcade)

- [ ] Bodies sized with `setSize`/`setOffset` AFTER `setScale` — body geometry order matters.
- [ ] Static geometry uses `physics.add.staticGroup()`, not dynamic group with `setImmovable(true)`.
- [ ] Tile collision uses `setCollisionByProperty({ collides: true })` reading from Tiled — single source of truth.
- [ ] Fast bodies have `setMaxVelocity` capped below thinnest wall × FPS — anti-tunneling.
- [ ] `colliders` and `overlaps` registered once in `create`, not re-registered per frame.
- [ ] Overlap callbacks short and allocation-free — they fire many times per frame.
- [ ] Movement uses `body.setVelocity(...)` with values in pixels/second, not manual `position += v * delta`.
- [ ] Disabled bodies use `body.enable = false` — destroyed-and-recreated bodies thrash the broadphase.
- [ ] World bounds set via `physics.world.setBounds(...)` to match the level, not left at the viewport.
- [ ] If using Matter instead, decision is documented — Arcade is the default; Matter is the deliberate choice.

## Input

- [ ] Pointer/touch input tested on a real mobile device, not just desktop emulation.
- [ ] Keyboard rebinds persist via `localStorage` and migrate cleanly across versions.
- [ ] Action-style input (`Phaser.Input.Keyboard.JustDown`, `JustUp`) used for one-shots, not raw `isDown`.
- [ ] Held-key input uses `cursors.left.isDown` polling in `update`, not `keydown` events — events fire on auto-repeat with OS-dependent delay.
- [ ] Pointer up/down handled, not just `pointermove` — touch fires differently than mouse.
- [ ] `input.topOnly = true` is the default unless overlapping interactives are intentional.
- [ ] Disabled UI elements don't capture input (`disableInteractive()` or `setInteractive(false)`).
- [ ] No `addEventListener` on `window` / `document` directly — use Phaser's input system so it cleans up on scene shutdown.
- [ ] Gamepad path (if supported) tested with at least Xbox + PlayStation pads — button maps differ.

## Audio

- [ ] First sound is gated behind a user gesture — autoplay won't work otherwise.
- [ ] `sound.unlock()` (or implicit unlock via `this.input.once('pointerdown', ...)` in the boot scene) is in place.
- [ ] Audio assets compressed (OGG + MP3 fallback) — file size budget respected, Safari needs MP3.
- [ ] Audio sprites used for many short SFX — fewer HTTP requests, faster load, fewer decoded buffers.
- [ ] Volume controls persist via `SaveSystem` and clamp to `[0, 1]`.
- [ ] Music duck/crossfade uses `tweens.add({ targets: music, volume: ... })` not raw setters — instant volume changes pop.
- [ ] No audio loaded inside `GameScene.preload` — load once in `PreloadScene`, key-reference everywhere.
- [ ] `sound.pauseAll()` on `visibilitychange` (tab hidden), `sound.resumeAll()` on visible — otherwise music keeps playing in a backgrounded tab.
- [ ] Music tracks use `loop: true` explicitly — Phaser does not loop by default.

## Animations and tweens

- [ ] Spritesheet/atlas animations registered once via `anims.create(...)` in a boot/preload scene, not per-instance.
- [ ] Animation keys read from a constants module — no string-literal `'player_run'` scattered.
- [ ] Tweens on the same target/property are killed before a new one is added — stacked tweens fight.
- [ ] Tweens use `onComplete` callbacks that null-check the target — target may be destroyed mid-tween.
- [ ] No `setInterval`/`setTimeout` for gameplay timing — use `time.addEvent` so it pauses with the scene.
- [ ] Hit-feedback (flash, shake, particles, hit-pause) present where the design called for it — game feel is shipping criteria.

## Assets

- [ ] All sprite sheets shipped as atlases (Texture Packer / Aseprite / Phaser Pack) — fewer draw calls, fewer texture binds.
- [ ] Tilemap JSON regenerated from Tiled — no stale exports in `public/assets/tilemaps/`.
- [ ] No assets loaded inside `GameScene.preload` — load once in `PreloadScene`, key-reference everywhere.
- [ ] Asset keys reference `src/data/assetKeys.ts` constants — typo'd string keys are a runtime crash.
- [ ] Bitmap fonts used for in-game HUD text — DOM text is heavy, web fonts are flaky on first paint.
- [ ] Source assets (Aseprite, .tmx, .wav masters) live outside `public/assets/` — exported assets are build artifacts, sources are inputs.
- [ ] Loader has an error path (`this.load.on('loaderror', ...)`) — silent missing assets are silent bug reports.
- [ ] Total `public/assets/` budget tracked in PR — drift catches itself early.

## Save / persistence

- [ ] Save schema version field present and bumped if format changed — every change ships with migration.
- [ ] Migration tested by hand-editing an old save in `localStorage` — proves the path works.
- [ ] No untrusted data deserialized blindly — defensive parsing, version check first, schema validation if leaderboards are involved.
- [ ] Save writes are debounced (e.g. 500 ms) — every-frame writes hammer `localStorage` and stutter on iOS Safari.
- [ ] Save data contains only IDs and primitives — no `Sprite` / `Container` references.
- [ ] Quota errors from `localStorage` caught and surfaced as a UX state — not an unhandled exception.
- [ ] Cleared-save / new-game path tested — first-run is a real code path.
- [ ] If save touches a server, see [security-engineering](../../security-engineering/SKILL.md) — client is untrusted.

## Performance

- [ ] `game.loop.actualFps` ≥ target on a low-end test device (mobile-web is the hard case).
- [ ] No GC spikes in Chrome performance trace during a 30-second representative play.
- [ ] Draw call count reasonable (single-digit hundreds for a 2D game) — atlases reduce this.
- [ ] Memory growth flat across a 5-minute play — no entity leaks, no event-listener leaks.
- [ ] Object pools used for bullets, particles, FX, popup numbers — anything that spawns more than a few per second.
- [ ] Off-screen entities culled or `setActive(false)` — invisible bodies still cost broadphase work.
- [ ] Camera `setRoundPixels(true)` if pixel-art — sub-pixel rendering blurs and costs fillrate.
- [ ] Heavy preload happens once in `PreloadScene`, not on every level start — `scene.restart()` should not re-decode textures.
- [ ] Particle emitters use `frequency` / `quantity` / `lifespan` budgets that are bounded — runaway emitters are silent killers.

## Cross-platform

- [ ] Tested on mobile Safari (iOS) — quirks: audio unlock, `requestAnimationFrame` throttling on background tabs, `localStorage` quota.
- [ ] Tested on mobile Chrome (Android low-end) — quirks: GPU stalls on first composite, smaller texture limits.
- [ ] Tested on desktop Chrome and Firefox.
- [ ] `meta viewport` and CSS `touch-action: none` set on the game container — prevents default browser pinch / scroll gestures eating input.
- [ ] Canvas scales/responds correctly across portrait and landscape (`Scale.FIT` / `Scale.RESIZE` chosen deliberately).
- [ ] `dpr` (device pixel ratio) handled — high-DPI mobile devices either upscale crisp or take the perf hit deliberately.
- [ ] No reliance on right-click — touch has no equivalent.
- [ ] Game still works at 360×640 (low-end phone portrait) and 1920×1080 (desktop) — both ends of the supported range.

## Build / deploy

- [ ] `npm run build` succeeds; `dist/` size sanity-checked (game total < 5 MB compressed for web).
- [ ] `vite.config.ts` `base` matches the deployment subpath if not at root — broken asset URLs otherwise.
- [ ] Asset cache headers configured at host or CDN level — see [deployment-pipelines](../../deployment-pipelines/SKILL.md).
- [ ] `tsconfig.json` `strict: true`; build fails on type errors — type errors leaking into prod is a smell.
- [ ] Source maps either served (debugging in prod) or stripped (size win) — choose deliberately.
- [ ] No `console.log` / `debugger` left in shipped code — strip in build or via lint rule.
- [ ] Service-worker / cache version bumped if asset hashes changed — stale caches strand updated builds.

## Game UX

- [ ] First-frame loading state is non-blank — at least a logo + progress, not a black canvas.
- [ ] Pause behavior verified — game pauses fully (no tween/timer drift) when tab loses focus or `scene.pause()` is called.
- [ ] Failure states (death, level fail) reset cleanly via `scene.restart()` with no leaked listeners or zombie tweens.
- [ ] Audio resumes correctly after tab regains focus — `sound.resumeAll()` on `visibilitychange`.
- [ ] Loading bar reflects real progress (`load.on('progress', ...)`) — not a fake animation that finishes before the load does.
- [ ] First-time-player path tested with cleared `localStorage` — onboarding is a code path.
- [ ] Settings (volume, controls, language) persist and apply on next launch.
- [ ] Empty / max-data states handled — zero items, full inventory, very long names, big numbers.
- [ ] Game UX reviewed against ux-design principles — feedback, hierarchy, accessibility.

## Anti-pattern audit

A quick scan for the most common Phaser anti-patterns. None of these should be present:

- [ ] No god scenes (single 2,000-line `GameScene`).
- [ ] No cross-scene reach-ins (`this.scene.get('Other').foo = bar`).
- [ ] No allocations in `update()`.
- [ ] No `this.events.on(...)` without a matching cleanup in `shutdown()`.
- [ ] No `tweens.add` without thinking about what happens if the target is destroyed.
- [ ] No `setInterval` / `setTimeout` for gameplay timing — use `time.addEvent`.
- [ ] No `addEventListener('keydown', ...)` directly on `window` for game input.
- [ ] No re-loading the same asset on every scene start.
- [ ] No `JSON.parse(localStorage.getItem('save'))` without version check and try/catch.
- [ ] No magic-string asset keys outside the constants module.
- [ ] No physics body created with `setSize` *before* `setScale` (geometry will be wrong).

## Cleanup

- [ ] Debug code removed or wrapped behind a `DEBUG` env flag.
- [ ] Phaser debug rendering (`physics.world.createDebugGraphic()` / `debug: true`) disabled in prod.
- [ ] Unused imports / dead branches removed.
- [ ] Unused assets purged from `public/assets/` — they ship to users otherwise.
- [ ] Commented-out code deleted — git remembers.

## Documentation

- [ ] Public API of the new system documented (TSDoc on exports).
- [ ] Any non-obvious choice has a comment explaining *why*, not *what*.
- [ ] If this is a notable architectural choice, an ADR is filed (see team-lead).
- [ ] README updated if the project structure or run commands changed.

## Hand-off to other skills

- [ ] If new save/leaderboard surface: security review for tamper resistance — pull in [security-engineering](../../security-engineering/SKILL.md).
- [ ] If new IAP touchpoint: catalog updated by [iap-manager](../../iap-manager/SKILL.md).
- [ ] If new gameplay system: design doc owned by [game-systems-designer](../../game-systems-designer/SKILL.md), balance pass by [game-balancer](../../game-balancer/SKILL.md).
- [ ] If non-canvas web UI added (account page, store, landing): frontend-ui-engineering owns it, not this skill.
- [ ] If deeper bundle/perf work needed: performance-optimization.
- [ ] If CI/CD pipeline touched: [deployment-pipelines](../../deployment-pipelines/SKILL.md).
- [ ] If feature warrants a launch plan: the `marketer` agent for store-page / trailer / wishlist comms.

## Version control

- [ ] All changes committed.
- [ ] PR description explains the change and links to the PRD / design doc.
- [ ] Reviewer assigned.
- [ ] CI passing (typecheck, lint, build).

---

## Sign-off

- [ ] Engineer (self): _____ (date)
- [ ] Reviewer: _____ (date)
- [ ] Designer (if relevant): _____ (date)
- [ ] QA (if applicable): _____ (date)

---

## Notes

> Anything specific about this feature that doesn't fit the checklist.

> _____

---

> **Reminder**: this is a checklist, not a religion. If a section doesn't apply, skip it. If you find yourself skipping most sections, that's a smell — either the checklist is wrong for your project, or the feature isn't actually as small as you think.
