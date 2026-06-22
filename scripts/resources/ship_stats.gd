class_name ShipStats
extends Resource

## Defensive stats for a ship, as a swappable Resource (Module-Ready Architecture,
## CLAUDE.md). A HealthComponent reads this by reference, so swapping the .tres
## (a hull/armor module) changes durability immediately.
##
## Damage pipeline (see HealthComponent / docs/combat-system-design.md §3):
##   incoming -> x resistance(type) -> shield absorbs -> hull armor (defense) -> HP
##
## Create .tres instances under resources/ships/.

@export var max_hp: float = 100.0   ## hull hit points
@export var shield: float = 0.0     ## personal shield pool, absorbed before the hull
@export var defense: float = 0.0    ## flat armor subtracted from post-shield hull damage

## Per-school damage multipliers. 1.0 = normal, 0.0 = immune, >1.0 = vulnerable.
## Indices mirror Damage.Type.
@export_group("Resistances")
@export var resist_kinetic: float = 1.0
@export var resist_energy: float = 1.0
@export var resist_explosive: float = 1.0
@export var resist_plasma: float = 1.0


## Damage multiplier for a Damage.Type school.
func resistance(type: int) -> float:
	match type:
		Damage.Type.ENERGY:
			return resist_energy
		Damage.Type.EXPLOSIVE:
			return resist_explosive
		Damage.Type.PLASMA:
			return resist_plasma
		_:
			return resist_kinetic
