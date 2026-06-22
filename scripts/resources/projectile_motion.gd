class_name ProjectileMotion
extends Resource

## Stateless motion strategy for a Projectile. Each frame it may mutate the
## projectile's velocity (and rotation) to produce straight / accelerating /
## homing trajectories. The base class is a no-op == straight-line flight, so a
## null or base motion behaves exactly like a plain bullet.
##
## Strategies are stateless and shareable: all per-instance state (velocity,
## position, target) lives on the Projectile that is passed in. See
## docs/combat-system-design.md §2.3.
##
## Future subclasses (added with missiles, not now):
##   AcceleratingMotion — velocity += velocity.normalized() * accel * delta (clamped)
##   HomingMotion       — steer velocity toward projectile.target by a turn rate,
##                        preferring nodes in group "decoys" (flares)

## Advance the projectile's heading for this frame. Base = straight (no change).
func update(_projectile: Node, _delta: float) -> void:
	pass
