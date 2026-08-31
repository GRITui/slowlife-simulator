shader_type canvas_item;
// TASK-032 seasonal water tint — gl_compatibility safe (<=8 ALU, 1 sample, no branches).
uniform vec4 hot_color : source_color = vec4(0.85, 0.65, 0.2, 0.5);
uniform vec4 monsoon_color : source_color = vec4(0.13, 0.59, 0.95, 0.5);
uniform vec4 cool_color : source_color = vec4(0.0, 0.59, 0.53, 0.5);
uniform float season_index : hint_range(0.0, 2.0) = 2.0; // 0=hot 1=monsoon 2=cool
uniform float mix_amount : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 tint = season_index < 0.5 ? hot_color.rgb : (season_index < 1.5 ? monsoon_color.rgb : cool_color.rgb);
	COLOR = vec4(mix(base.rgb, tint, mix_amount), base.a);
}
