shader_type canvas_item;
// TASK-032 foliage sway — vertex-only, amp <= 6px, crown-weighted.
uniform float sway_amp : hint_range(0.0, 6.0) = 4.0;
uniform float sway_speed : hint_range(0.0, 4.0) = 1.2;
uniform float phase = 0.0;

void vertex() {
	VERTEX.x += sin(TIME * sway_speed + phase) * sway_amp * (1.0 - UV.y);
}
