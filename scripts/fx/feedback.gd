extends Node

## Global "game feel" bus. Register as an autoload named "Feedback"
## (Project Settings -> Autoload). Gameplay code requests impact effects; a
## ShakeCamera (or anything) listens. Every call is safe even with no listener.
##
## Screen shake uses a trauma model: callers add trauma, the camera renders
## shake = trauma^2 and decays it, so impacts accumulate and fall off smoothly.
## Hit-stop briefly drops Engine.time_scale to give hits/kills weight; it is
## timed on the wall clock (Time.get_ticks_msec) so it is immune to the very
## scale it sets, and stacking hits extend rather than fight each other.

signal trauma_added(amount: float)

var _frozen: bool = false
var _restore_scale: float = 1.0
var _unfreeze_at_ms: int = 0


## Request screen shake. amount is 0..1 trauma (it accumulates, capped at the camera).
func add_trauma(amount: float) -> void:
	if amount > 0.0:
		trauma_added.emit(amount)


## Briefly slow or freeze time. duration is wall-clock seconds; scale is the
## Engine.time_scale to hold (~0.05 = a punchy hit-stop, ~0.3 = slow-mo).
func hit_stop(duration_sec: float, scale: float = 0.05) -> void:
	if duration_sec <= 0.0:
		return
	if not _frozen:
		_restore_scale = Engine.time_scale
		_frozen = true
	Engine.time_scale = scale
	var end_ms: int = Time.get_ticks_msec() + int(duration_sec * 1000.0)
	_unfreeze_at_ms = maxi(_unfreeze_at_ms, end_ms)


## Convenience: shake and (optionally) freeze in one call.
func impact(trauma: float, freeze_sec: float = 0.0, freeze_scale: float = 0.05) -> void:
	add_trauma(trauma)
	hit_stop(freeze_sec, freeze_scale)


func _process(_delta: float) -> void:
	if _frozen and Time.get_ticks_msec() >= _unfreeze_at_ms:
		Engine.time_scale = _restore_scale
		_frozen = false
