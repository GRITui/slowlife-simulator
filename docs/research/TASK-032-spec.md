# TASK-032 — Mobile shader polish: seasonal water + foliage sway (canvas_item)

**Status:** `proposed` | **Priority:** medium | **Owner:** tech-art-lead
**Renderer:** `gl_compatibility` (Godot 4.7, iOS, A14+) — `canvas_item` only.
**Constraint:** no per-pixel `for` loops · subtle ambient · no combat VFX.

## Shaders
`res://assets/shaders/water_seasonal.gdshader` → `WaterOverlay` `ShaderMaterial`. `res://assets/shaders/foliage_sway.gdshader` → `BambooRing` (post-TASK-031 bake) + mango/banana tall props; `vertex()` weighted by `pow(1.0-UV.y, 2.0)`. Per-sprite phase via uniform (no `INSTANCE_CUSTOM` on `gl_compatibility` 2D).
**Palette** (ART_STYLE_GUIDE): `#5FB6C9` Canal Teal · `#3D5F80` Monsoon Blue · `#274259` Deep Navy. Blend 0=monsoon, 0.5=hot, 1=cool.

```glsl
// water_seasonal.gdshader — canvas_item
shader_type canvas_item; render_mode unshaded, blend_mix;
uniform float ripple_speed : hint_range(0.0, 2.0) = 0.35;
uniform float ripple_amp   : hint_range(0.0, 0.05) = 0.010;
uniform vec4  monsoon_tint : source_color = vec4(0.239,0.373,0.502,1.0);
uniform vec4  hot_tint     : source_color = vec4(0.373,0.714,0.788,1.0);
uniform vec4  cool_tint    : source_color = vec4(0.153,0.259,0.349,1.0);
uniform float season_blend : hint_range(0.0, 1.0) = 0.0;
uniform float spec_amp     : hint_range(0.0, 0.20) = 0.06;
void fragment() {
    vec2 uv = UV + vec2(sin(TIME*ripple_speed + UV.y*6.2831),
                        cos(TIME*ripple_speed*0.7 + UV.x*6.2831)) * ripple_amp;
    vec4 b = texture(TEXTURE, uv);
    vec3 t = mix(mix(monsoon_tint.rgb, hot_tint.rgb, clamp(season_blend*2.0,0.0,1.0)),
                 cool_tint.rgb, clamp((season_blend-0.5)*2.0,0.0,1.0));
    b.rgb = mix(b.rgb*t, b.rgb + sin(UV.x*12.0+TIME*0.6)*cos(UV.y*9.0-TIME*0.4)*spec_amp*vec3(1.0), 0.5);
    COLOR = b;
}
```

```gdscript
# scripts/autoload/SeasonShaderDriver.gd — bus-only, no TimeManager ref
extends Node; class_name SeasonShaderDriver
@export var water_material: ShaderMaterial
@export var sway_targets: Array[Sprite2D] = []
const SEASON_BLEND := {"monsoon": 0.0, "hot": 0.5, "cool": 1.0}
func _ready() -> void: SignalBus.season_changed.connect(_on_season)
func _on_season(season: String) -> void:
    var blend: float = SEASON_BLEND.get(season, 0.0)
    if water_material: water_material.set_shader_parameter("season_blend", blend)
    for i: int in sway_targets.size():
        sway_targets[i].material.set_shader_parameter("sway_phase", i * 0.7)
```

Foliage sway body (uniforms declared like above): `VERTEX.x += sin(TIME*sway_speed + sway_phase) * sway_amp * pow(1.0-UV.y, 2.0);`

## Plan
1. Author both `.gdshader` + matching `.tres` `ShaderMaterial`. 2. Attach water material in `WorldRender._build_water_overlay()`; add `_attach_sway(sprite, phase)` for ring + tall props. 3. Register `SeasonShaderDriver` autoload; wire `water_material` + `sway_targets` in `Main.tscn` — zero `TimeManager` refs. 4. Update `docs/art/style_guide.md` with assets + uniform tables.

## Perf caps + Gate test strategy
Water fragment ≤ 8 ALU + 1 sample, no branches. Sway vertex-only. Skip on caps (`kind == "cap"`). Sway amp ≤ 6 px.
- **Unit** `tests/shaders/test_water_seasonal.gd`: compile, `Image.get_pixel()` at 3 seasons, hue ±8/255 of anchors.
- **Perf** (extends TASK-031 probe): `RENDERING_INFO_SHADER_MEMORY_USED` delta ≤ 256 KB, frame P95 ≤ 12 ms iPhone-12 preset.
- **Visual** `tests/visual/test_seasonal_water.py`: headless hash-diff monsoon↔cool < 2% px, sway-off drift < 0.5%.
- **Manual**: iPhone 12 + iPhone SE (A13 floor); `OS.get_frames_per_second() >= 58` over 30 s with monsoon rain + sway.

## Acceptance
Shaders authored + attached, all gates green. `SignalBus.season_changed` listeners ≥ 1 for `SeasonShaderDriver`; `grep -r TimeManager scripts/autoload/SeasonShaderDriver.gd` empty. TASK-007 / TASK-031 gates stay green. **Risk:** low — additive; `sprite.material = null` for instant rollback.
