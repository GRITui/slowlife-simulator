# iOS Export Template — TASK-028

`export_presets.cfg` is gitignored (`.gitignore:4`), so the iOS preset is
documented here for reproducible setup on the build machine.

## [HOLD] Team ID / Bundle ID / Apple Developer enrollment (2026-09-01)

Owner call: deferred until the app is actually ready to launch. Not a
development blocker — free "Personal Team" signing + a placeholder bundle ID
work fine for local builds and on-device testing (7-day-expiring
provisioning) with zero cost. These three only need to be real before the
first TestFlight/App Store Connect registration, since the bundle ID locks
permanently at that point:

- **Apple Developer Program enrollment** ($99/yr) — hold
- **Bundle identifier** sign-off (`com.gritui.slowlife-simulator` proposed
  below, not yet confirmed) — hold
- **Team ID** (`application/signature`) — hold, depends on enrollment above

## Godot 4.7 iOS preset (export_presets.cfg → iOS section)

| Setting | Value | Why |
|---|---|---|
| `application/config/name` | Thai Rural Countryside Sim | App Store name |
| `application/bundle_identifier` | `com.gritui.slowlife-simulator` (proposed — **[HOLD]**, use a placeholder for dev builds) | reverse-DNS |
| `application/signature` (team id) | *(local secret — do not commit)* — **[HOLD]**, use free Personal Team for dev | signing |
| `display/window/size/viewport_width` | 1600 | matches project.godot |
| `display/window/size/viewport_height` | 900 | matches project.godot |
| `display/window/stretch/mode` | `canvas_items` | keep 48px canon crisp |
| `display/window/stretch/aspect` | `expand` | fill notched screens |
| `renderer/rendering_method` | `gl_compatibility` | already set (GLES3/Metal path) |
| `textures/vram_compression/import_etc2_astc` | `true` | ASTC for A-series+ |
| `application/icon_iphone_180` / `icon_ipad_167` | 180px / 167px PNG | App Store requirement |
| `capabilities/arkit` | off | unused, smaller binary |

## Safe-area compliance (implemented in code, TASK-028)

- `scenes/ui/HUD.gd` → `apply_safe_area()`: reads
  `DisplayServer.get_display_safe_area()` on mobile and insets the HUD
  `MarginContainer` so nothing renders under the notch / Dynamic Island /
  home indicator. Desktop/headless no-ops (empty safe rect).
- CLAUDE.md touch rule: interactive targets keep ≥ 44x44pt — slider/check
  rows in `Settings.tscn` and the joystick zone honor the 48px canon grid.

## Startup parse budget (TASK-033)

Every `res://` script is parsed at iOS launch. Prune dead weight via the
export preset's **Exclude** filter (Patterns) — there is no `scripts/_dormant/`
directory today, so a real exclude pattern has to name actual dead files
directly rather than a folder convention that was never adopted:

```text
scripts/autoload/GameStateManager.gd
```

Re-audited 2026-09-01 (issue #175) — most of the 2026-08-31 dormant list has
since gained real consumers and is no longer safe to exclude:
- `scripts/autoload/AudioManager.gd` — now a registered autoload
  (`project.godot [autoload]`)
- `scripts/core/ProfilerOverlay.gd` — now wired via `Main._ensure_profiler_overlay()`
  (TASK-041)
- `scripts/resource_types/RecipeData.gd` — now consumed by
  `scripts/interactables/CookingStation.gd`

Only `scripts/autoload/GameStateManager.gd` is still genuinely dead (zero
consumers anywhere, unregistered autoload). Re-register or delete it when its
wiring task lands; do not ship it. Re-verify this list before relying on it —
dormant status changes as tasks land.

## Build steps (local)

1. `godot --headless --import --path .`
2. Editor → Project → Export → iOS preset (values above, placeholder bundle
   ID + free Personal Team signing for dev builds while Team ID is
   **[HOLD]**) → Export Project.
3. Xcode: open exported project, set Team (Personal Team for dev / real Team
   once enrollment lands), archive → App Store Connect (release only, after
   [HOLD] items are resolved).
4. CI note: no signing secrets live in this repo; xcodebuild smoke runs are
   manual-dispatch only by design.
