class_name ShipBase
extends CharacterBody2D

## Shared base for all ships (player, allies, enemies). Provides the weapon mount
## and firing; subclasses add movement/AI on top. Health will be added here as a
## component in Step 3.
##
## Composition over inheritance for data: the actual weapon behavior lives in a
## swappable WeaponData resource, driven by a Weapon controller.

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

var _weapon: Weapon


func _ready() -> void:
	_weapon = Weapon.new(weapon_data)


func _physics_process(delta: float) -> void:
	_weapon.advance(delta)


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
