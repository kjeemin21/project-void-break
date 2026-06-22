class_name Projectile
extends Area2D

## A single projectile. Per docs/godot-implementation-guide.md §1.3, projectiles
## use Area2D with manual position updates (not a physics body) so swarms stay
## cheap; pooling can replace queue_free() later without touching callers.
##
## Configured at spawn via setup(); travels according to its `motion` strategy
## (null = straight line), despawns after `lifetime`, and deals a typed Damage
## packet to the first thing it overlaps that exposes take_damage().
## See docs/combat-system-design.md §2.

var velocity: Vector2 = Vector2.ZERO
var damage: float = 0.0
var damage_type: int = Damage.Type.KINETIC
var bypass_barrier: bool = false
var lifetime: float = 1.5
var source: Node = null              ## the ship that fired this; never damaged by it
var target: Node = null              ## optional, for homing motion strategies

## Motion strategy (assignable in the projectile scene; overridden per-shot by
## the weapon). null behaves as straight-line flight.
@export var motion: ProjectileMotion

var _age: float = 0.0
var _consumed: bool = false          ## guards against double-hits in one frame


func _ready() -> void:
	# Connect our own detection signals in code (code-only dev; no editor wiring).
	body_entered.connect(_on_hit)
	area_entered.connect(_on_hit)


## Initialise a freshly-instanced projectile. Call after adding to the tree and
## setting global_position.
##   target_mask: collision mask to apply (who this can hit). -1 keeps the
##     mask configured on the projectile scene in the editor.
##   p_motion: motion strategy override; null keeps the scene's own `motion`.
func setup(direction: Vector2, speed: float, dmg: float, life: float, shooter: Node, target_mask: int = -1, p_motion: ProjectileMotion = null, p_damage_type: int = Damage.Type.KINETIC, p_bypass_barrier: bool = false) -> void:
	var dir: Vector2 = direction.normalized()
	velocity = dir * speed
	damage = dmg
	damage_type = p_damage_type
	bypass_barrier = p_bypass_barrier
	lifetime = life
	source = shooter
	rotation = dir.angle()
	if p_motion != null:
		motion = p_motion
	if target_mask >= 0:
		collision_mask = target_mask


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	if motion != null:
		motion.update(self, delta)
	global_position += velocity * delta


func _on_hit(other: Node) -> void:
	if _consumed or other == source:
		return
	_consumed = true
	if other.has_method("take_damage"):
		var dmg := Damage.new(damage, damage_type, source, bypass_barrier, global_position)
		other.take_damage(dmg)
	queue_free()  # later: return to pool instead
