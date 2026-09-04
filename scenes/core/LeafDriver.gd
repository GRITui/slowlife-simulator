extends CanvasLayer
## LeafDriver — TASK-366 ambient leaf-particle effect. Always-on outdoor
## decoration, deliberately NOT weather/season-gated: this is a pure
## atmosphere touch (unlike RainDriver/HeatHazeDriver, which react to real
## weather/season state), so there's no meaningful "off" condition to
## react to -- it just runs continuously once World.tscn loads. Simpler
## than inventing a fake gating condition for a purely decorative effect.

@onready var _leaves: GPUParticles2D = $LeafParticles if has_node("LeafParticles") else null

func _ready() -> void:
	if _leaves:
		_leaves.emitting = true
