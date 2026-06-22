class_name HealthComponent
extends RefCounted

## Hull + shield HP for a ship, decoupled from the scene tree so the damage
## pipeline is unit-testable (like ShipMovement / Weapon). Consumes the typed
## Damage packet and applies stats from a ShipStats resource.
##
## Pipeline (see docs/combat-system-design.md §3):
##   amount x stats.resistance(type) -> shield absorbs -> hull armor -> current_hp
##
## bypass_barrier on the packet concerns area barriers (a future component), not
## the personal shield — it is intentionally ignored here.

signal health_changed(current_hp: float, max_hp: float)
signal shield_changed(current_shield: float)
signal died

var stats: ShipStats
var current_hp: float = 0.0
var current_shield: float = 0.0

var _dead: bool = false


func _init(ship_stats: ShipStats = null) -> void:
	stats = ship_stats if ship_stats != null else ShipStats.new()
	current_hp = stats.max_hp
	current_shield = stats.shield


func is_dead() -> bool:
	return _dead


## Apply a damage packet. No-op once dead.
func take_damage(dmg: Damage) -> void:
	if _dead:
		return

	var amount: float = maxf(0.0, dmg.amount) * stats.resistance(dmg.type)

	# Shield absorbs first (takes the post-resistance amount directly).
	if current_shield > 0.0 and amount > 0.0:
		var absorbed: float = minf(current_shield, amount)
		current_shield -= absorbed
		amount -= absorbed
		shield_changed.emit(current_shield)

	# Hull armor mitigates what reaches the hull.
	var hull_damage: float = maxf(0.0, amount - stats.defense)
	if hull_damage > 0.0:
		current_hp = maxf(0.0, current_hp - hull_damage)
		health_changed.emit(current_hp, stats.max_hp)

	if current_hp <= 0.0 and not _dead:
		_dead = true
		died.emit()


## Restore hull HP (clamped to max). No-op once dead.
func heal(amount: float) -> void:
	if _dead:
		return
	current_hp = minf(stats.max_hp, current_hp + maxf(0.0, amount))
	health_changed.emit(current_hp, stats.max_hp)
