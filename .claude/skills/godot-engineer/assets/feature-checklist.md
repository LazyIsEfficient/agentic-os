# Gameplay Feature Checklist

> Fillable checklist for shipping a new gameplay feature in a Godot 4 + C# project. Walk through this *before* declaring the feature done. Catches the things engineers routinely forget under deadline pressure.

## Header

- **Feature:** _____
- **Engineer:** _____
- **Date:** _____
- **Linked PRD / brief:** _____
- **Linked PR(s):** _____

---

## 1. Scope

- [ ] Feature requirements are documented (PRD, ticket, design doc).
- [ ] Acceptance criteria are clear and testable.
- [ ] Out-of-scope items are explicit.
- [ ] Engineering and design have signed off on the scope.

## 2. Scene Structure

- [ ] The feature is implemented as one or more scenes (`.tscn` files), not as a god-script.
- [ ] Scene composition uses focused child nodes (sprite, collision, animation, etc.) rather than inheritance.
- [ ] Scenes are reusable where applicable (a generic enemy scene rather than per-enemy code).
- [ ] No "god scene" — single `.tscn` file with everything inline.
- [ ] Scene-unique names (`%`) used for in-scene references.
- [ ] `[Export]` references used for cross-scene wiring.
- [ ] No path-based `GetNode("../../...")` reaching across the tree.

## 3. C# Code

- [ ] All script classes are `partial`.
- [ ] `_Ready` is used for setup (not the C# constructor).
- [ ] `_Process` vs `_PhysicsProcess` is used correctly (physics in `_PhysicsProcess`, visuals in `_Process`).
- [ ] No `GetNode<T>` in tight loops or `_Process` (cached in `_Ready` instead).
- [ ] No allocations in `_Process` for hot paths.
- [ ] Strings are not concatenated in tight loops.
- [ ] Vector mutations use the read-modify-write pattern, not direct property mutation.
- [ ] `[Signal]` delegates end in `EventHandler`.
- [ ] Signal connections use `+=` syntax (not string-based `Connect`).
- [ ] Signal connections are disconnected in `_ExitTree` if the listener can outlive the emitter.
- [ ] `IsInstanceValid` is used for held references that might be freed.
- [ ] `QueueFree` is used (not `Free`) when removing nodes.

## 4. Physics (if applicable)

- [ ] Movement code is in `_PhysicsProcess`, not `_Process`.
- [ ] The right body type is used (`CharacterBody` for player-controlled, `RigidBody` for physics-driven, `StaticBody` for static).
- [ ] `MoveAndSlide` is used for character bodies (or `MoveAndCollide` for projectiles).
- [ ] `Velocity` is in units per second (no manual `* delta`).
- [ ] Collision layers and masks are set correctly.
- [ ] Layer names are documented in project settings.
- [ ] No setting `GlobalPosition` directly on `RigidBody`.
- [ ] `IsOnFloor()` is used to check ground state, not manual velocity checks.
- [ ] Collision shapes are appropriately simple (no concave shapes on dynamic bodies).

## 5. Input

- [ ] Input is via actions (in the input map), not raw key codes.
- [ ] Polling vs event-driven input is appropriate (`_PhysicsProcess` polling for movement, `_UnhandledInput` for one-shot menus).
- [ ] Action names follow `snake_case` convention.
- [ ] Controller and keyboard work for any control scheme.
- [ ] Touch input considered (if applicable).
- [ ] No hardcoded keys.

## 6. Animation

- [ ] The right animation tool is used (`Tween` for code-driven, `AnimationPlayer` for authored, `AnimationTree` for state machines).
- [ ] Animations are smooth (no frame stalls, no jitter).
- [ ] State transitions are well-defined.
- [ ] Animation timing matches gameplay timing (not arbitrary).
- [ ] Hit feedback (flash, screen shake, particles) is in place.
- [ ] No `Tween` stacking on the same property without killing previous.

## 7. UI (if the feature has UI)

- [ ] UI is in a `CanvasLayer`, not in world space.
- [ ] `Control` containers are used (no manual positioning).
- [ ] Anchors and stretch settings are appropriate for multiple resolutions.
- [ ] Theme is used for styling, not per-instance overrides.
- [ ] Translation keys (`Tr(...)`) used for any user-facing text.
- [ ] Focus and keyboard/controller navigation work.
- [ ] UI updates via signals, not polling.
- [ ] Game state and UI are decoupled.

## 8. Save / Persistence (if state needs to persist)

- [ ] Save format has a version field.
- [ ] Migration code exists for previous versions (if there were any).
- [ ] Save uses `user://`, not `res://`.
- [ ] Errors during save/load are handled gracefully.
- [ ] Autosave triggers at safe points if applicable.
- [ ] Save data doesn't include `Node` references; only IDs.

## 9. Performance

- [ ] Profiled in a representative scene; frame budget is met.
- [ ] No allocations in hot paths.
- [ ] Object pooling used for frequently spawned things (bullets, particles, etc.) if measured to matter.
- [ ] Inactive nodes have `SetProcess(false)` / `SetPhysicsProcess(false)` to disable.
- [ ] Texture import settings are appropriate (compression, filter).
- [ ] Tested on the target hardware (mobile, web, low-end desktop).

## 10. States

For every visual element / scene that has multiple states, all states are designed and tested:

- [ ] Default / idle state
- [ ] Active state
- [ ] Disabled state (if applicable)
- [ ] Hover / focus state (for UI)
- [ ] Loading state (if applicable)
- [ ] Error state (if applicable)
- [ ] Empty state (if applicable)
- [ ] Maximum-data state (long names, full inventory, etc.)
- [ ] Minimum-data state (zero items, empty list)

## 11. Edge Cases

- [ ] What happens if the player presses a button at an unexpected moment? (Pause during attack, alt-tab during cutscene)
- [ ] What happens if the player has zero of something? Maximum?
- [ ] What happens at the boundaries of the level (edges, corners)?
- [ ] What happens with very long names, very large numbers, very small/empty values?
- [ ] What happens if the player triggers two interactions simultaneously?
- [ ] What happens if a connected node is freed mid-interaction?
- [ ] What happens during a scene transition mid-feature?
- [ ] What happens when the game is paused?

## 12. Multiplayer (if applicable)

- [ ] Server-side validation for any state changes.
- [ ] Authority is set correctly on networked nodes.
- [ ] RPCs use the correct `RpcMode` (Authority vs AnyPeer).
- [ ] State synchronization rate is appropriate (not every frame for every property).
- [ ] Client-side interpolation/extrapolation if needed.
- [ ] Disconnection and reconnection handled.
- [ ] No client-trusted hit confirmation.
- [ ] Tested with simulated network latency.

## 13. Accessibility

- [ ] Color is not the only signal (icons + text accompany color).
- [ ] Text contrast meets WCAG AA where readable text is important.
- [ ] Important information has an audio cue (where relevant).
- [ ] Keyboard navigation works for menus and core gameplay (where applicable).
- [ ] Subtitles for any voice or important audio.
- [ ] Animation respects reduced-motion preferences if implemented.

## 14. Audio

- [ ] Sound effects play at the right moments.
- [ ] Music transitions smoothly.
- [ ] Audio buses are routed correctly (master, music, sfx).
- [ ] Audio doesn't pop, click, or cut off.
- [ ] Volume settings affect this feature appropriately.

## 15. Testing

- [ ] Manually playtested by the engineer.
- [ ] Manually playtested by someone else (designer, QA, teammate).
- [ ] Tested on the target framerate (60 FPS, 30 FPS, etc.).
- [ ] Tested on the target platform(s).
- [ ] Edge cases from section 11 explicitly verified.
- [ ] No console errors or warnings.

## 16. Anti-Pattern Audit

A quick scan for the most common Godot anti-patterns. None of these should be present:

- [ ] No god scenes
- [ ] No god scripts
- [ ] No tight coupling via `GetNode("../../path")`
- [ ] No autoload abuse (every shared concern as a singleton)
- [ ] No movement in `_Process`
- [ ] No `GetNode` in hot paths
- [ ] No string-based signal connections in new code
- [ ] No `Free()` instead of `QueueFree()`
- [ ] No `new ClassName()` instead of `Instantiate<T>()`
- [ ] No mutating shared `Resource` data expecting per-instance behavior
- [ ] No hardcoded resource paths in `_Process`

## 17. Documentation

- [ ] Code comments explain any non-obvious choices.
- [ ] Public API of the feature is documented (if other team members will use it).
- [ ] Any new conventions or patterns are documented in the project's docs.
- [ ] If this is a notable architectural choice, an ADR is filed (see team-lead).

## 18. Cleanup

- [ ] Debug code removed or wrapped in `#if DEBUG`.
- [ ] `GD.Print` debug logging removed from hot paths.
- [ ] Unused exports / fields removed.
- [ ] Unused scenes / scripts removed.
- [ ] Resource files no longer referenced are deleted.

## 19. Version Control

- [ ] All changes committed.
- [ ] PR description explains the change and links to the PRD.
- [ ] Reviewer assigned.
- [ ] CI passing.

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
