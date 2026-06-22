class_name ShipBase
extends CharacterBody2D

## Shared base for all ships (player, allies, enemies). Provides the weapon mount
## + firing and the health/damage pipeline; subclasses add movement/AI on top.
##
## Composition over inheritance for data: behavior lives in swappable resources
## (WeaponData, ShipStats), driven by controllers (Weapon, HealthComponent).
## Projectiles call take_damage(dmg) on the ship body that they overlap.

@export_group("Stats")
## Swappable hull/shield/resistance tuning. Leave null for a default ShipStats.
@export var stats: ShipStats

@export_group("Weapon")
## Swappable weapon tuning. Leave null to start unarmed (a default WeaponData
## with no bullet_scene fires nothing). Swap at runtime via set_weapon_data().
@export var weapon_data: WeaponData
## How far ahead of the ship's origin (along facing) projectiles spawn, so a
## ship never collides with its own shot. A Muzzle Marker2D can replace this later.
@export var muzzle_distance: float = 28.0
## Optional node to parent projectiles under. Defaults to the current scene so
## projectiles keep their own trajectory instead of moving with the ship.
@export var projectile_container_path: NodePath

@export_group("Impact Feedback")
## Hull visual (the Polygon2D) to flash on hit. Leave null to skip hit-flash.
@export var visual: CanvasItem
## Modulate applied on hit; HDR-bright reads as a neon pop. Returns to the
## visual's original modulate over hit_flash_time.
@export var hit_flash_color: Color = Color(4.0, 4.0, 4.0, 1.0)
@export var hit_flash_time: float = 0.06
## Screen shake (0..1) when THIS ship is hit. Player: set > 0. Trash mobs: 0,
## or the screen shakes on every stray hit.
@export var trauma_on_taking_hit: float = 0.0
## Screen shake (0..1) when THIS ship dies.
@export var trauma_on_death: float = 0.4
## Brief time-freeze on death for weighty kills (wall-clock seconds). 0 = off.
@export var hitstop_on_death_sec: float = 0.0
@export var hitstop_scale: float = 0.05

@export_subgroup("Optional Assets")
## Assign in the editor once you have art/audio; inert until then.
@export var hit_vfx: PackedScene
@export var death_vfx: PackedScene
@export var hit_sfx: AudioStream
@export var death_sfx: AudioStream

var _weapon: Weapon
var _health: HealthComponent
var _feedback = null  ## Feedback autoload (optional; untyped for dynamic dispatch)
var _visual_base_modulate: Color = Color.WHITE


func _ready() -> void:
	_weapon = Weapon.new(weapon_data)
	_health = HealthComponent.new(stats)
	_health.died.connect(_on_died)
	_feedback = get_node_or_null("/root/Feedback")
	if visual != null:
		_visual_base_modulate = visual.modulate


func _physics_process(delta: float) -> void:
	_weapon.advance(delta)


## Damage entry point — projectiles/rays call this on the ship body they hit.
func take_damage(dmg: Damage) -> void:
	# Future: an area Barrier component intercepts here before the hull, unless
	# dmg.bypass_barrier (see docs/combat-system-design.md §3).
	# Already dead (e.g. a second projectile lands the same frame before queue_free
	# resolves): swallow it so we don't shake/flash/tween on a freed node.
	if _health.is_dead():
		return
	_health.take_damage(dmg)  # may emit died -> _on_died (queues free) synchronously
	var killed: bool = _health.is_dead()
	_play_impact_feedback(killed)


## The health component, for HUD binding / queries.
func get_health() -> HealthComponent:
	return _health


## Called when health reaches zero. Override per ship type (player -> game over
## in Step 5; enemy -> drop loot in Step 7). Default: remove the ship.
func _on_died() -> void:
	queue_free()


## Screen shake + hit-stop + hit-flash + optional VFX/SFX for an incoming hit.
func _play_impact_feedback(killed: bool) -> void:
	if _feedback != null:
		if killed:
			_feedback.add_trauma(trauma_on_death)
			_feedback.hit_stop(hitstop_on_death_sec, hitstop_scale)
		else:
			_feedback.add_trauma(trauma_on_taking_hit)

	if visual != null and not killed:
		_flash_visual()

	var world: Node = get_tree().current_scene
	var vfx: PackedScene = death_vfx if killed else hit_vfx
	if vfx != null and world != null:
		var instance: Node = vfx.instantiate()
		world.add_child(instance)
		if instance is Node2D:
			(instance as Node2D).global_position = global_position

	var sfx: AudioStream = death_sfx if killed else hit_sfx
	SoundFX.play_2d(sfx, world, global_position)


func _flash_visual() -> void:
	visual.modulate = hit_flash_color
	var tween := create_tween()
	tween.tween_property(visual, "modulate", _visual_base_modulate, hit_flash_time)


## Swap the weapon module at runtime (preserves nothing — fresh cooldown).
func set_weapon_data(new_data: WeaponData) -> void:
	if new_data == null:
		return
	weapon_data = new_data
	_weapon = Weapon.new(new_data)


## Fire along the ship's current facing, if the weapon is ready.
func fire() -> void:
	var dir: Vector2 = Vector2.RIGHT.rotated(rotation)
	var origin: Vector2 = global_position + dir * muzzle_distance
	_weapon.try_fire(_projectile_container(), origin, dir, self, _projectile_mask())


## Collision mask for this ship's projectiles (who they may hit). Default -1
## keeps the mask configured on the projectile scene; subclasses override to
## target a specific faction layer.
func _projectile_mask() -> int:
	return -1


func _projectile_container() -> Node:
	if not projectile_container_path.is_empty():
		var node: Node = get_node_or_null(projectile_container_path)
		if node != null:
			return node
	return get_tree().current_scene
