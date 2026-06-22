extends SceneTree

## Headless unit tests for the weapon/projectile logic — no scene or editor needed.
## Run with:  godot --headless --script scripts/tests/test_weapon.gd
## Exits 0 on success, 1 on any failure.

const DT := 1.0 / 60.0

var _failures: int = 0


func _init() -> void:
	_test_cooldown_math()
	_test_weapon_starts_ready()
	_test_advance_clears_cooldown()
	_test_try_fire_without_scene_is_noop()
	_test_swapping_weapon_data()
	_test_projectile_travels_along_heading()
	_test_projectile_ignores_no_take_damage()
	_test_damage_packet_defaults()
	_test_projectile_delivers_typed_damage()
	_test_base_motion_is_straight()

	if _failures == 0:
		print("OK — all weapon/projectile tests passed")
		quit(0)
	else:
		printerr("FAILED — %d assertion(s)" % _failures)
		quit(1)


# --- WeaponData / Weapon ---

func _test_cooldown_math() -> void:
	var d := WeaponData.new()
	d.fire_rate = 4.0
	_assert_approx(d.cooldown(), 0.25, 1e-6, "cooldown = 1 / fire_rate")
	d.fire_rate = 0.0
	_assert_true(d.cooldown() == INF, "cooldown = INF when fire_rate <= 0")


func _test_weapon_starts_ready() -> void:
	var w := Weapon.new()
	_assert_true(w.is_ready(), "weapon starts ready")


func _test_advance_clears_cooldown() -> void:
	var w := Weapon.new()
	w._cooldown_remaining = 0.25
	_assert_true(not w.is_ready(), "not ready while cooling down")
	w.advance(0.1)
	_assert_true(not w.is_ready(), "still cooling at 0.15 remaining")
	w.advance(0.2)
	_assert_true(w.is_ready(), "ready after enough time elapses")


func _test_try_fire_without_scene_is_noop() -> void:
	# Default WeaponData has no bullet_scene; firing must spawn nothing and not
	# consume the cooldown.
	var w := Weapon.new()
	var spawned: Array = w.try_fire(root, Vector2.ZERO, Vector2.RIGHT, null)
	_assert_true(spawned.is_empty(), "no bullet_scene -> no projectiles")
	_assert_true(w.is_ready(), "failed fire does not start cooldown")


func _test_swapping_weapon_data() -> void:
	# Module-ready: replacing the WeaponData reference changes the reported stats.
	var slow := WeaponData.new()
	slow.fire_rate = 1.0
	var fast := WeaponData.new()
	fast.fire_rate = 10.0
	var w := Weapon.new(slow)
	_assert_approx(w.data.cooldown(), 1.0, 1e-6, "swap: starts with slow cooldown")
	w.data = fast
	_assert_approx(w.data.cooldown(), 0.1, 1e-6, "swap: faster module shortens cooldown")


# --- Projectile ---

func _test_projectile_travels_along_heading() -> void:
	var p := Projectile.new()
	p.setup(Vector2.RIGHT, 100.0, 5.0, 5.0, null)
	_assert_approx(p.rotation, 0.0, 1e-6, "projectile faces its heading")
	p._physics_process(0.1)
	_assert_approx(p.global_position.x, 10.0, 1e-3, "projectile moves speed*dt along heading")
	_assert_approx(p.global_position.y, 0.0, 1e-6, "projectile stays on-axis")
	p.free()


func _test_projectile_ignores_no_take_damage() -> void:
	# A target lacking take_damage() must not crash the hit handler.
	var p := Projectile.new()
	p.setup(Vector2.RIGHT, 100.0, 5.0, 5.0, null)
	var dummy := Node.new()
	p._on_hit(dummy)  # should be safe; projectile queues itself free
	_assert_true(p._consumed, "hit on non-damageable target is consumed safely")
	dummy.free()


# --- Damage packet / motion seams ---

func _test_damage_packet_defaults() -> void:
	var d := Damage.new(7.0, Damage.Type.ENERGY, null, true)
	_assert_approx(d.amount, 7.0, 1e-6, "Damage carries amount")
	_assert_true(d.type == Damage.Type.ENERGY, "Damage carries type")
	_assert_true(d.bypass_barrier, "Damage carries bypass_barrier flag")
	var def := Damage.new()
	_assert_true(def.type == Damage.Type.KINETIC and not def.bypass_barrier, "Damage defaults: kinetic, no bypass")


func _test_projectile_delivers_typed_damage() -> void:
	# The projectile builds a Damage packet from its configured fields.
	var sink := _DamageSink.new()
	var p := Projectile.new()
	p.setup(Vector2.RIGHT, 100.0, 12.0, 5.0, null, -1, null, Damage.Type.PLASMA, true)
	p._on_hit(sink)
	_assert_true(sink.received != null, "target received a Damage packet")
	if sink.received != null:
		_assert_approx(sink.received.amount, 12.0, 1e-6, "delivered amount matches weapon damage")
		_assert_true(sink.received.type == Damage.Type.PLASMA, "delivered type matches weapon")
		_assert_true(sink.received.bypass_barrier, "delivered bypass_barrier matches weapon")
	sink.free()


func _test_base_motion_is_straight() -> void:
	# A base ProjectileMotion must not alter velocity (== straight line).
	var p := Projectile.new()
	p.setup(Vector2.RIGHT, 200.0, 1.0, 5.0, null, -1, ProjectileMotion.new())
	var v_before: Vector2 = p.velocity
	p._physics_process(0.1)
	_assert_true(p.velocity.is_equal_approx(v_before), "base motion keeps constant velocity")
	_assert_approx(p.global_position.x, 20.0, 1e-3, "base motion travels straight")
	p.free()


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

## Captures the Damage packet it receives, to assert on the take_damage contract.
class _DamageSink:
	extends Node
	var received: Damage = null
	func take_damage(dmg: Damage) -> void:
		received = dmg
