class_name Weapon
extends RefCounted

## Firing controller for a ship. Owns cooldown state and spawns projectiles from
## its WeaponData. Decoupled from the scene tree: cooldown logic is pure and
## unit-testable; only try_fire() touches the tree (to spawn projectiles).
##
## `data` is held by reference (Module-Ready Architecture) so swapping the
## WeaponData (equipping a weapon module) changes behavior on the next shot.

var data: WeaponData

var _cooldown_remaining: float = 0.0


func _init(weapon_data: WeaponData = null) -> void:
	data = weapon_data if weapon_data != null else WeaponData.new()


## Advance the cooldown timer. Call every physics frame.
func advance(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)


## True when the weapon is off cooldown and ready to fire.
func is_ready() -> bool:
	return _cooldown_remaining <= 0.0


## Fire if ready. Spawns projectile(s) into `world`, configured from `data`.
## Returns the spawned projectiles (empty if it could not fire).
##   origin: world-space spawn point (muzzle)
##   direction: facing to fire along
##   source: the firing ship (so projectiles ignore it)
##   target_mask: collision mask for spawned projectiles (-1 keeps scene default)
func try_fire(world: Node, origin: Vector2, direction: Vector2, source: Node, target_mask: int = -1) -> Array:
	if world == null or data.bullet_scene == null or not is_ready():
		return []

	_cooldown_remaining = data.cooldown()

	var base_dir: Vector2 = direction.normalized()
	var count: int = maxi(1, data.projectiles_per_shot)
	var half_spread: float = deg_to_rad(data.spread_degrees) * 0.5
	var spawned: Array = []

	for i in count:
		var projectile: Node = data.bullet_scene.instantiate()
		world.add_child(projectile)
		projectile.global_position = origin
		var dir: Vector2 = base_dir
		if half_spread > 0.0:
			dir = base_dir.rotated(randf_range(-half_spread, half_spread))
		if projectile.has_method("setup"):
			projectile.setup(dir, data.bullet_speed, data.damage, data.bullet_lifetime, source, target_mask, data.motion, data.damage_type, data.bypass_barrier)
		spawned.append(projectile)

	return spawned
