class_name ShakeCamera
extends Camera2D

## Trauma-based screen shake (Squirrel Eiserloh model). Attach to the player's
## Camera2D. It auto-connects to the Feedback autoload, so any gameplay code can
## shake the screen via Feedback.add_trauma() without referencing the camera.
##
## shake = trauma^2, so small hits barely nudge while big ones kick hard, and the
## shake decays smoothly back to rest. Offset-only (no roll): keep the camera's
## `ignore_rotation` = true so the view never spins with the ship.

@export var max_offset: Vector2 = Vector2(18.0, 12.0)  ## peak positional shake (px)
@export var recovery: float = 1.4                      ## trauma lost per second

var _trauma: float = 0.0
var _base_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	_base_offset = offset
	# Untyped: the Feedback autoload has no class_name, and it may not be
	# registered yet (shake just no-ops until it is).
	var feedback = get_node_or_null("/root/Feedback")
	if feedback != null:
		feedback.trauma_added.connect(add_trauma)


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if _trauma <= 0.0:
		offset = _base_offset
		return
	_trauma = maxf(0.0, _trauma - recovery * delta)
	var shake: float = _trauma * _trauma
	offset = _base_offset + Vector2(
		max_offset.x * shake * randf_range(-1.0, 1.0),
		max_offset.y * shake * randf_range(-1.0, 1.0))
