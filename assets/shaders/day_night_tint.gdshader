shader_type canvas_item;
render_mode unshaded, blend_mix;
// TASK-034 day/night screen grade — full-screen ColorRect overlay.
// Day fraction drives a 4-anchor palette (ART_STYLE_GUIDE.md):
// dawn Jasmine Gold #E0A23A -> noon neutral -> dusk Hot Orange #C9622F -> night Deep Navy #274259.
// Pure mix/step math, no branches, no per-pixel loops.
uniform float day_fraction : hint_range(0.0, 1.0) = 0.25; // 0=midnight 0.5=noon
uniform float grade_strength : hint_range(0.0, 1.0) = 0.22;
uniform vec3 dawn_color : source_color = vec3(0.878, 0.635, 0.227);
uniform vec3 dusk_color : source_color = vec3(0.788, 0.384, 0.184);
uniform vec3 night_color : source_color = vec3(0.153, 0.259, 0.349);

void fragment() {
	// Sunrise 05:00-07:00 (0.208-0.292), sunset 18:00-19:30 (0.75-0.8125).
	float dawn_w = 1.0 - step(0.05, abs(day_fraction - 0.25) * 24.0) ;
	dawn_w = clamp(1.0 - abs(day_fraction - 0.25) * 18.0, 0.0, 1.0);
	float dusk_w = clamp(1.0 - abs(day_fraction - 0.78) * 18.0, 0.0, 1.0);
	float night_w = step(0.8125, day_fraction) + (1.0 - step(0.208, day_fraction));
	night_w = clamp(night_w, 0.0, 1.0);
	float day_w = clamp(1.0 - dawn_w - dusk_w - night_w, 0.0, 1.0);
	vec3 warm = dawn_color * dawn_w + dusk_color * dusk_w;
	vec3 tint = warm * 1.0 + night_color * night_w;
	float strength = grade_strength * (dawn_w + dusk_w + night_w);
	vec3 graded = mix(vec3(1.0), tint, strength);
	COLOR = vec4(graded, 1.0 - day_w * 0.0);
}
