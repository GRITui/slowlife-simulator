// pond_glow.gdshader — TASK-103. Soft radial warm glow overlay for the lotus
// pond during an active festival. Flat-color technique (no TEXTURE sampling),
// same proven safe pattern as day_night_tint.gdshader / heat_haze.gdshader.
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform float pulse_speed : hint_range(0.0, 3.0) = 0.8;
uniform float strength : hint_range(0.0, 0.5) = 0.16;
uniform vec3 glow_color : source_color = vec3(0.878, 0.635, 0.227); // Jasmine Gold

void fragment() {
	vec2 centered = UV - vec2(0.5);
	float dist = length(centered) * 2.0;
	float falloff = clamp(1.0 - dist, 0.0, 1.0);
	float pulse = 0.7 + 0.3 * sin(TIME * pulse_speed);
	float alpha = falloff * falloff * strength * pulse;
	COLOR = vec4(glow_color, alpha);
}
