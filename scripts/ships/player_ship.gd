class_name PlayerShip
extends ShipBase

## The directly-controlled "body" ship. Death = run over.
##
## Extends ShipBase for the weapon mount + fire(). Movement math lives in
## ShipMovement (pure, testable); tuning lives in a MovementData resource
## (Module-Ready Architecture, CLAUDE.md). This node only:
##   - reads input,
##   - drives ShipMovement and triggers firing,
##   - pushes the result onto the CharacterBody2D and calls move_and_slide().
##
## Assign a MovementData .tres to `movement_data` and a WeaponData .tres to
## `weapon_data` (from ShipBase) in the editor to tune handling / weapons or swap
## modules. If movement_data is unassigned, a default is created at runtime so the
## ship is playable immediately (firing needs a weapon_data with a bullet_scene).
##
## Input: uses named InputMap actions when they exist, otherwise falls back to
## physical keys so the ship is playable before the editor input map is set up.
## See EDITOR_TODO.md for the proper action names to configure.

## Swappable movement tuning. Leave null to use defaults (a MovementData is
## instanced in _ready). Replace at runtime via set_movement_data() for modules.
@export var movement_data: MovementData

# Named input actions (configure these in the editor; see EDITOR_TODO.md).
const ACTION_THRUST := "thrust_forward"
const ACTION_TURN_LEFT := "turn_left"
const ACTION_TURN_RIGHT := "turn_right"
const ACTION_BOOST := "boost"
const ACTION_COMBAT_TOGGLE := "combat_mode"
const ACTION_FIRE := "fire"

var _movement: ShipMovement
var _combat_mode: bool = false


func _ready() -> void:
	super._ready()  # ShipBase: init weapon
	if movement_data == null:
		movement_data = MovementData.new()
	_movement = ShipMovement.new(movement_data)
	_movement.rotation = rotation


## Swap the movement tuning at runtime (e.g. equipping an engine module).
## Velocity and heading are preserved across the swap.
func set_movement_data(new_data: MovementData) -> void:
	if new_data == null:
		return
	movement_data = new_data
	_movement.data = new_data


func _unhandled_input(event: InputEvent) -> void:
	# Combat mode is a manual toggle (guide §2.3: lets the player express intent).
	if _action_just_pressed(ACTION_COMBAT_TOGGLE, event):
		_combat_mode = not _combat_mode


func _physics_process(delta: float) -> void:
	super._physics_process(delta)  # ShipBase: advance weapon cooldown

	var thrust_input: float = _thrust_strength()
	var rotation_input: float = _turn_axis()
	var boost: bool = _is_pressed(ACTION_BOOST, KEY_SHIFT)

	_movement.update(thrust_input, rotation_input, boost, _combat_mode, delta)

	rotation = _movement.rotation
	velocity = _movement.velocity
	move_and_slide()
	# move_and_slide() may have altered velocity on collision; feed it back so
	# momentum (and ram impacts) stay consistent next frame.
	_movement.velocity = velocity

	# Hold-to-fire; the weapon's cooldown gates the actual rate.
	if _is_pressed(ACTION_FIRE, KEY_SPACE):
		fire()


# --- Input helpers: prefer InputMap actions, fall back to physical keys ---

func _thrust_strength() -> float:
	if InputMap.has_action(ACTION_THRUST):
		return Input.get_action_strength(ACTION_THRUST)
	return 1.0 if Input.is_physical_key_pressed(KEY_W) else 0.0


func _turn_axis() -> float:
	if InputMap.has_action(ACTION_TURN_LEFT) and InputMap.has_action(ACTION_TURN_RIGHT):
		return Input.get_axis(ACTION_TURN_LEFT, ACTION_TURN_RIGHT)
	var left: float = 1.0 if Input.is_physical_key_pressed(KEY_A) else 0.0
	var right: float = 1.0 if Input.is_physical_key_pressed(KEY_D) else 0.0
	return right - left


func _is_pressed(action: String, fallback_key: Key) -> bool:
	if InputMap.has_action(action):
		return Input.is_action_pressed(action)
	return Input.is_physical_key_pressed(fallback_key)


func _action_just_pressed(action: String, event: InputEvent) -> bool:
	if InputMap.has_action(action):
		return event.is_action_pressed(action)
	# Fallback: physical 'C' for combat-mode toggle.
	var key_event := event as InputEventKey
	return key_event != null and key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_C
