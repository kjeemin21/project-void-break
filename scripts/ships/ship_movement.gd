class_name ShipMovement
extends RefCounted

## Pure "fake space physics" movement logic, decoupled from the scene tree so it
## can be unit-tested without a SceneTree. See docs/godot-implementation-guide.md §2.
##
## Model:
##   - Thrust applies only along the ship's facing (rotation-movement coupling).
##   - A soft speed cap reduces thrust efficiency as speed approaches max_speed,
##     so the ship tops out smoothly instead of hitting a hard clamp.
##   - Dampening acts mainly when there is NO thrust input, so releasing controls
##     coasts the ship to rest in ~1-1.5s. While thrusting, damp drops to a small
##     fraction so the soft cap (not friction) defines top speed.
##   - Boost multiplies thrust and overrides damp to a low value, letting momentum
##     carry through for the ramming build.
##
## Tunables live in a MovementData resource (Module-Ready Architecture, CLAUDE.md).
## `data` is held by reference, so swapping it mid-run (engine module) or editing
## it in the inspector changes handling on the next frame — no re-sync needed.

var data: MovementData
var velocity: Vector2 = Vector2.ZERO
var rotation: float = 0.0  ## radians; 0 faces +X (Godot convention)


func _init(movement_data: MovementData = null) -> void:
	data = movement_data if movement_data != null else MovementData.new()


## Advance one physics step.
##   thrust_input : 0..1 forward throttle
##   rotation_input : -1 (left) .. +1 (right)
##   boost / combat_mode : mode flags
func update(thrust_input: float, rotation_input: float, boost: bool, combat_mode: bool, delta: float) -> void:
	thrust_input = clampf(thrust_input, 0.0, 1.0)
	rotation_input = clampf(rotation_input, -1.0, 1.0)

	# --- Rotation ---
	rotation += deg_to_rad(data.rotation_speed) * rotation_input * delta
	rotation = wrapf(rotation, -PI, PI)

	# --- Resolve mode-adjusted force, cap, and damp ---
	var force: float = data.thrust_force
	var cap: float = data.max_speed
	var damp: float = lerpf(data.linear_damp, data.linear_damp * data.thrust_damp_fraction, thrust_input)

	if combat_mode:
		force *= data.combat_speed_multiplier
		cap *= data.combat_speed_multiplier
	if boost:
		force = data.thrust_force * data.boost_multiplier
		cap = data.max_speed * data.boost_multiplier
		damp = data.boost_damp_override

	# --- Thrust along facing, with soft speed cap (diminishing returns near cap) ---
	if thrust_input > 0.0 and cap > 0.0:
		var facing: Vector2 = Vector2.RIGHT.rotated(rotation)
		var speed_ratio: float = clampf(velocity.length() / cap, 0.0, 1.0)
		var efficiency: float = 1.0 - speed_ratio
		velocity += facing * force * thrust_input * efficiency * delta

	# --- Dampening (asymptotic coast; mirrors RigidBody2D.linear_damp semantics) ---
	velocity /= (1.0 + damp * delta)
