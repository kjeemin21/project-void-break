class_name OneShotEffect
extends Node2D

## Convenience script for effect scene roots (hit sparks, explosions): removes
## itself after `lifetime` seconds so spawned VFX never leak. Set `lifetime` to
## at least the particle system's lifetime. (Particle scenes can instead self-
## free via their own setup — this is just an easy default.)

@export var lifetime: float = 1.0


func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
