class_name EnemyBasic
extends ShipBase

## A passive target dummy (Step 3): stationary, slowly rotating, damageable.
##
## Reuses ShipBase for the health/damage pipeline (take_damage) and the weapon
## mount (unused here — Step 4 turns this into an active enemy with detection,
## chase, and shooting). On death it frees itself via ShipBase._on_died; loot
## drops arrive in Step 7.
##
## Editor: place on the "enemies" collision layer so player projectiles (which
## mask that layer) register hits. See EDITOR_TODO.md.

@export var spin_speed: float = 30.0  ## idle rotation (deg/s); purely visual feedback


func _physics_process(delta: float) -> void:
	super._physics_process(delta)  # ShipBase: advance weapon cooldown (harmless while unarmed)
	rotation += deg_to_rad(spin_speed) * delta
