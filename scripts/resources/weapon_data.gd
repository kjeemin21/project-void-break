class_name WeaponData
extends Resource

## Tunable weapon parameters as a swappable Resource (Module-Ready Architecture,
## CLAUDE.md). A Weapon holds this by reference, so swapping the .tres on a ship
## at runtime (equipping a weapon module) changes its fire behavior immediately.
##
## Create .tres instances under resources/modules/ for each weapon module.
## Defaults describe a basic rapid-fire blaster.

@export_group("Damage")
@export var damage: float = 10.0              ## damage dealt per projectile hit
@export var fire_rate: float = 4.0            ## shots per second (cooldown = 1 / fire_rate)
## Damage school. Indices match Damage.Type (0 Kinetic, 1 Energy, 2 Explosive, 3 Plasma).
@export_enum("Kinetic", "Energy", "Explosive", "Plasma") var damage_type: int = 0
## Skip area barriers (missiles). Implemented by excluding the barrier layer from
## the spawned projectile's collision_mask — see docs/combat-system-design.md §3.
@export var bypass_barrier: bool = false

@export_group("Projectile")
@export var bullet_scene: PackedScene         ## the Projectile scene to spawn (set in editor)
@export var bullet_speed: float = 700.0       ## projectile travel speed (px/s)
@export var bullet_lifetime: float = 1.5      ## seconds before despawn; effective range = speed * lifetime
## Motion strategy applied to spawned projectiles. null = straight line. Assign an
## AcceleratingMotion / HomingMotion resource for missiles, etc.
@export var motion: ProjectileMotion

@export_group("Pattern")
@export var projectiles_per_shot: int = 1     ## >1 for shotgun/burst modules
@export var spread_degrees: float = 0.0       ## total cone width; 0 = perfectly straight


## Seconds between shots. INF when fire_rate is non-positive (effectively disabled).
func cooldown() -> float:
	return 1.0 / fire_rate if fire_rate > 0.0 else INF
