extends SceneTree

## Headless unit tests for HealthComponent + ShipStats — no scene or editor needed.
## Run with:  godot --headless --script scripts/tests/test_health.gd
## Exits 0 on success, 1 on any failure.

var _failures: int = 0


func _init() -> void:
	_test_takes_raw_damage()
	_test_resistance_scales_damage()
	_test_defense_flat_reduction()
	_test_shield_absorbs_first()
	_test_death_emitted_once()
	_test_dead_ignores_further_damage()
	_test_heal_clamps_to_max()
	_test_health_changed_signal()

	if _failures == 0:
		print("OK — all health tests passed")
		quit(0)
	else:
		printerr("FAILED — %d assertion(s)" % _failures)
		quit(1)


# --- Helpers ---

func _stats(overrides: Dictionary = {}) -> ShipStats:
	var s := ShipStats.new()
	for key in overrides:
		s.set(key, overrides[key])
	return s


# --- Tests ---

func _test_takes_raw_damage() -> void:
	var h := HealthComponent.new(_stats({"max_hp": 50.0}))
	h.take_damage(Damage.new(20.0))
	_assert_approx(h.current_hp, 30.0, 1e-6, "raw damage subtracts from hull")


func _test_resistance_scales_damage() -> void:
	var h := HealthComponent.new(_stats({"max_hp": 100.0, "resist_energy": 0.5}))
	h.take_damage(Damage.new(40.0, Damage.Type.ENERGY))
	_assert_approx(h.current_hp, 80.0, 1e-6, "resistance halves energy damage (40 -> 20)")


func _test_defense_flat_reduction() -> void:
	var h := HealthComponent.new(_stats({"max_hp": 100.0, "defense": 3.0}))
	h.take_damage(Damage.new(10.0))  # kinetic
	_assert_approx(h.current_hp, 93.0, 1e-6, "defense subtracts flat armor (10 - 3 = 7)")


func _test_shield_absorbs_first() -> void:
	var h := HealthComponent.new(_stats({"max_hp": 100.0, "shield": 5.0}))
	h.take_damage(Damage.new(8.0))  # 5 to shield, 3 to hull
	_assert_approx(h.current_shield, 0.0, 1e-6, "shield drained first")
	_assert_approx(h.current_hp, 97.0, 1e-6, "overflow past shield hits hull (3)")


func _test_death_emitted_once() -> void:
	var h := HealthComponent.new(_stats({"max_hp": 10.0}))
	var rec := _Recorder.new()
	h.died.connect(rec.on_died)
	h.take_damage(Damage.new(100.0))
	_assert_true(h.is_dead(), "dies when hull reaches 0")
	_assert_approx(h.current_hp, 0.0, 1e-6, "hp clamps at 0 (no negative)")
	_assert_true(rec.died_count == 1, "died emitted exactly once")


func _test_dead_ignores_further_damage() -> void:
	var h := HealthComponent.new(_stats({"max_hp": 10.0}))
	var rec := _Recorder.new()
	h.died.connect(rec.on_died)
	h.take_damage(Damage.new(100.0))
	h.take_damage(Damage.new(100.0))  # already dead — must be a no-op
	_assert_true(rec.died_count == 1, "no second died signal after death")


func _test_heal_clamps_to_max() -> void:
	var h := HealthComponent.new(_stats({"max_hp": 10.0}))
	h.take_damage(Damage.new(7.0))  # hp = 3
	h.heal(2.0)
	_assert_approx(h.current_hp, 5.0, 1e-6, "heal restores hull")
	h.heal(100.0)
	_assert_approx(h.current_hp, 10.0, 1e-6, "heal clamps to max_hp")


func _test_health_changed_signal() -> void:
	var h := HealthComponent.new(_stats({"max_hp": 40.0}))
	var rec := _Recorder.new()
	h.health_changed.connect(rec.on_health)
	h.take_damage(Damage.new(15.0))
	_assert_approx(rec.last_hp, 25.0, 1e-6, "health_changed reports current hp")
	_assert_approx(rec.last_max, 40.0, 1e-6, "health_changed reports max hp")


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

## Records signal emissions for assertions.
class _Recorder:
	var died_count: int = 0
	var last_hp: float = -1.0
	var last_max: float = -1.0
	func on_died() -> void:
		died_count += 1
	func on_health(current_hp: float, max_hp: float) -> void:
		last_hp = current_hp
		last_max = max_hp
