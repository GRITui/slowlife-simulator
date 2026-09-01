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
export preset's **Exclude** filter (Patterns):

```text
scripts/_dormant/*
```

Currently dormant (audit 2026-08-31, `docs/research/QA-AUDIT-2026-08-31.md`):
- `scripts/autoload/GameStateManager.gd`, `scripts/autoload/AudioManager.gd`
  — unregistered autoloads (not in `project.godot`)
- `scripts/core/ProfilerOverlay.gd`, `scripts/resource_types/RecipeData.gd`
  — no production consumer

Re-register or delete these when their wiring tasks land; do not ship them.

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
