extends SceneTree

## Headless tests for the Feedback bus — no autoload registration needed (the
## script is instanced directly). Run with:
##   godot --headless --script scripts/tests/test_feedback.gd

const FeedbackScript := preload("res://scripts/fx/feedback.gd")

var _failures: int = 0


func _init() -> void:
	_test_add_trauma_emits()
	_test_zero_trauma_does_not_emit()
	_test_hit_stop_sets_time_scale()
	_test_zero_duration_hit_stop_is_noop()

	Engine.time_scale = 1.0  # safety: never leave the runner slowed
	if _failures == 0:
		print("OK — all feedback tests passed")
		quit(0)
	else:
		printerr("FAILED — %d assertion(s)" % _failures)
		quit(1)


func _test_add_trauma_emits() -> void:
	var fb := FeedbackScript.new()
	var rec := _Recorder.new()
	fb.trauma_added.connect(rec.on_trauma)
	fb.add_trauma(0.5)
	_assert_approx(rec.last, 0.5, 1e-6, "add_trauma emits the amount")
	_assert_true(rec.count == 1, "add_trauma emits once")
	fb.free()


func _test_zero_trauma_does_not_emit() -> void:
	var fb := FeedbackScript.new()
	var rec := _Recorder.new()
	fb.trauma_added.connect(rec.on_trauma)
	fb.add_trauma(0.0)
	_assert_true(rec.count == 0, "zero trauma does not emit")
	fb.free()


func _test_hit_stop_sets_time_scale() -> void:
	var fb := FeedbackScript.new()
	Engine.time_scale = 1.0
	fb.hit_stop(0.1, 0.05)
	_assert_approx(Engine.time_scale, 0.05, 1e-6, "hit_stop lowers Engine.time_scale")
	Engine.time_scale = 1.0
	fb.free()


func _test_zero_duration_hit_stop_is_noop() -> void:
	var fb := FeedbackScript.new()
	Engine.time_scale = 1.0
	fb.hit_stop(0.0, 0.05)
	_assert_approx(Engine.time_scale, 1.0, 1e-6, "zero-duration hit_stop changes nothing")
	fb.free()


# --- Assertion helpers ---

func _assert_true(cond: bool, label: String) -> void:
	if cond:
		print("  pass: %s" % label)
	else:
		_failures += 1
		printerr("  FAIL: %s" % label)


func _assert_approx(actual: float, expected: float, tol: float, label: String) -> void:
	_assert_true(absf(actual - expected) <= tol, "%s (got %f, expected %f)" % [label, actual, expected])


# --- Test doubles ---

class _Recorder:
	var last: float = -1.0
	var count: int = 0
	func on_trauma(amount: float) -> void:
		last = amount
		count += 1
