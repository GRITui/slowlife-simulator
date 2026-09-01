// heat_haze.gdshader — TASK-040. Hot-season top-band shimmer overlay.
// canvas_item, full-screen ColorRect overlay (same proven pattern as
// day_night_tint.gdshader) — flat COLOR output, no TEXTURE/SCREEN_TEXTURE
// sampling (avoids gl_compatibility screen-texture reliability concerns).
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float shimmer_speed : hint_range(0.0, 3.0) = 1.4;
uniform float band_height : hint_range(0.0, 1.0) = 0.22;
uniform float strength : hint_range(0.0, 0.3) = 0.08;
uniform vec3 haze_color : source_color = vec3(0.788, 0.384, 0.184); // Hot Orange

void fragment() {
	float band = clamp(1.0 - UV.y / max(band_height, 0.001), 0.0, 1.0);
	float shimmer = 0.5 + 0.5 * sin(TIME * shimmer_speed + UV.x * 14.0);
	float alpha = band * strength * shimmer;
	COLOR = vec4(haze_color, alpha);
}
