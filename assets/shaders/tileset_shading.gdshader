shader_type canvas_item;
// Tileset shading/detail pass — TASK-016
// Matches character sprite fidelity (48px, Mo Hom palette) with subtle AO and color variation.
// Applied to WorldRender ground layers and environment props.

uniform float shading_strength : hint_range(0.0, 1.0) = 0.15;
uniform float detail_strength : hint_range(0.0, 1.0) = 0.08;
uniform vec4 tint_color : source_color = vec4(0.85, 0.72, 0.55, 1.0); // Wood Amber tint for shading

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	// Discard transparent
	if (base.a < 0.01) {
		COLOR = base;
		return;
	}
	// Subtle bottom shading (AO) — darker toward bottom of tile
	float v_shade = UV.y * shading_strength * 0.5;
	// Detail noise: cheap hash based on UV + FRAGCOORD
	float n = fract(sin(dot(UV * 48.0, vec2(12.9898, 78.233))) * 43758.5453);
	float detail = (n - 0.5) * detail_strength;
	// Apply tint and shading
	vec3 shaded = base.rgb * (1.0 - v_shade) + tint_color.rgb * v_shade * 0.3 + vec3(detail);
	COLOR = vec4(shaded, base.a);
}

void vertex() {
	// No vertex modification, keep for Y-sort compatibility
}
