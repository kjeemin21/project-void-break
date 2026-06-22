extends SceneTree

## Headless unit tests for ShipMovement — no scene or editor required.
## Run with:  godot --headless --script scripts/tests/test_ship_movement.gd
## Exits with code 0 on success, 1 on any failure.

const DT := 1.0 / 60.0

var _failures: int = 0


func _init() -> void:
	_test_rotation()
	_test_thrust_accelerates_along_facing()
	_test_soft_speed_cap()
	_test_coast_to_stop()
	_test_boost_exceeds_cruise_cap()
	_test_combat_mode_lowers_top_speed()
	_test_swapping_data_changes_handling()

	if _failures == 0:
		print("OK — all ShipMovement tests passed")
		quit(0)
	else:
		printerr("FAILED — %d assertion(s)" % _failures)
		quit(1)


# --- Helpers ---

## A ShipMovement backed by a fresh MovementData so tests can tune params freely.
func _make(overrides: Dictionary = {}) -> ShipMovement:
	var data := MovementData.new()
	for key in overrides:
		data.set(key, overrides[key])
	return ShipMovement.new(data)


# --- Tests ---

func _test_rotation() -> void:
	var m := _make({"rotation_speed": 180.0})  # deg/s
	m.update(0.0, 1.0, false, false, 1.0)
	_assert_approx(m.rotation, deg_to_rad(180.0), 1e-3, "rotation: 180 deg/s for 1s")


func _test_thrust_accelerates_along_facing() -> void:
	var m := _make()
	m.rotation = 0.0  # facing +X
	m.update(1.0, 0.0, false, false, DT)
	_assert_true(m.velocity.x > 0.0 and absf(m.velocity.y) < 1e-6, "thrust: moves along +X facing")


func _test_soft_speed_cap() -> void:
	var m := _make({"max_speed": 400.0})
	for i in range(600):  # 10s of full thrust
		m.update(1.0, 0.0, false, false, DT)
	# Soft cap: tops out near (slightly under) max_speed, never above.
	_assert_true(m.velocity.length() <= m.data.max_speed + 1.0, "soft cap: never exceeds max_speed")
	_assert_true(m.velocity.length() > m.data.max_speed * 0.8, "soft cap: reaches near max_speed")


func _test_coast_to_stop() -> void:
	var m := _make()
	m.velocity = Vector2(400, 0)
	for i in range(90):  # 1.5s coasting, no input
		m.update(0.0, 0.0, false, false, DT)
	_assert_true(m.velocity.length() < 400.0 * 0.25, "coast: ~stopped within 1.5s")


func _test_boost_exceeds_cruise_cap() -> void:
	var m := _make({"max_speed": 400.0})
	for i in range(600):
		m.update(1.0, 0.0, true, false, DT)
	_assert_true(m.velocity.length() > m.data.max_speed, "boost: exceeds cruise cap")


func _test_combat_mode_lowers_top_speed() -> void:
	var cruise := _make()
	var combat := _make()
	for i in range(600):
		cruise.update(1.0, 0.0, false, false, DT)
		combat.update(1.0, 0.0, false, true, DT)
	_assert_true(combat.velocity.length() < cruise.velocity.length(), "combat mode: lower top speed than cruise")


func _test_swapping_data_changes_handling() -> void:
	# Module-ready: swapping the MovementData reference changes handling live.
	var m := _make({"max_speed": 200.0})
	for i in range(600):
		m.update(1.0, 0.0, false, false, DT)
	var slow_top: float = m.velocity.length()
	m.data = MovementData.new()  # default max_speed 450 — like equipping a faster engine
	for i in range(600):
		m.update(1.0, 0.0, false, false, DT)
	_assert_true(m.velocity.length() > slow_top + 50.0, "swap data: faster engine raises top speed")


# --- Assertion helpers ---

func _assert_true(cond: bool, label: String) -> void:
	if cond:
		print("  pass: %s" % label)
	else:
		_failures += 1
		printerr("  FAIL: %s" % label)


func _assert_approx(actual: float, expected: float, tol: float, label: String) -> void:
	_assert_true(absf(actual - expected) <= tol, "%s (got %f, expected %f)" % [label, actual, expected])
