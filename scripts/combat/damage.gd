class_name Damage
extends RefCounted

## A typed damage packet. Passed to take_damage(dmg: Damage) so defenses can
## branch on the damage school and on flags like bypass_barrier, instead of
## reacting to a bare float. See docs/combat-system-design.md §2.1.

## Damage schools. Defenses (hull resistances, barrier) key their multipliers
## off these. Keep indices stable — WeaponData mirrors them in an @export_enum.
enum Type { KINETIC, ENERGY, EXPLOSIVE, PLASMA }

var amount: float = 0.0
var type: int = Type.KINETIC
var source: Node = null              ## the entity that dealt this (never self-damaged)
var bypass_barrier: bool = false     ## true for missiles etc.: skips area barriers
var hit_position: Vector2 = Vector2.ZERO


func _init(p_amount: float = 0.0, p_type: int = Type.KINETIC, p_source: Node = null, p_bypass_barrier: bool = false, p_hit_position: Vector2 = Vector2.ZERO) -> void:
	amount = p_amount
	type = p_type
	source = p_source
	bypass_barrier = p_bypass_barrier
	hit_position = p_hit_position
