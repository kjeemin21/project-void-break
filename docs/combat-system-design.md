# Project Void Break — Combat System Design

> How the weapon and defense variety (missiles, lasers, plasma, cannons, ram;
> barriers, point-defense, flares) is structured. The guiding idea: **combat is
> not a list of weapon types — it is a few independent axes, and each weapon or
> defense is a combination of choices on those axes.** This keeps content
> additive (a new `.tres` + maybe a small strategy script) instead of a growing
> tree of special-case classes.

---

## 1. The Four Axes

| Axis | Question | Examples |
|---|---|---|
| **Delivery** | How does the hit reach the target? | Projectile (Area2D), Hitscan ray (laser), Beam (sustained ray), Contact (ram) |
| **Motion** (projectile-only) | How does the projectile travel? | Straight, Accelerating, Homing/guided |
| **Damage interaction** | How do defenses respond? | `damage_type` + flags (`bypass_barrier`, resistance tables) |
| **Defense** | What intercepts the hit? | Hull HP, Barrier (area HP pool), Point-defense / APS, Flare (decoy) |

Every weapon/defense in the design decomposes into these:

| Weapon | Delivery | Motion | Damage interaction |
|---|---|---|---|
| Heavy cannon | Projectile | Straight | KINETIC, high damage, slow fire |
| Plasma | Projectile | Straight / Accelerating | PLASMA |
| Missile | Projectile | Homing / Accelerating | EXPLOSIVE, `bypass_barrier = true` |
| Laser | Hitscan | — | ENERGY, weak vs barrier, accuracy roll |
| Ram | Contact | — | KINETIC, scales with impact velocity (collision system, not a fired weapon) |

| Defense | Mechanism |
|---|---|
| Barrier | Area2D with its own HP; absorbs incoming damage unless `bypass_barrier`; type-resistances; regen after delay |
| Point-defense (APS) | Detects projectiles on the enemy-projectile layer; on cooldown, intercepts the nearest (hit chance) |
| Flare | Deployable node in group `"decoys"`; Homing motion weighs it as a lure |

---

## 2. The Seams

### 2.1 Damage packet — `scripts/combat/damage.gd`

Damage is passed as a typed object, never a bare float, so defenses can branch on
type and flags:

```gdscript
class_name Damage
extends RefCounted

enum Type { KINETIC, ENERGY, EXPLOSIVE, PLASMA }

var amount: float
var type: int = Type.KINETIC
var source: Node = null
var bypass_barrier: bool = false   # missiles set this
var hit_position: Vector2 = Vector2.ZERO
```

**Contract:** anything damageable exposes `take_damage(dmg: Damage)`.

### 2.2 Delivery as a strategy resource

`WeaponData` holds shared stats; a `WeaponDelivery` resource decides *how* the
shot is delivered. `Weapon.try_fire()` calls `data.delivery.fire(ctx)` — no
growing `match`, and a new delivery is a new script + `.tres`.

```gdscript
class_name WeaponDelivery
extends Resource
func fire(ctx) -> void: pass            # overridden

# ProjectileDelivery -> spawns a Projectile (today's Weapon logic)
# HitscanDelivery    -> intersect_ray, apply Damage instantly, flash a Line2D, roll accuracy
# BeamDelivery       -> sustained ray each frame while firing (DPS)
```

> Status: not yet implemented. The current `Weapon` only does projectile
> delivery. When laser/beam land, extract this strategy; the `Weapon` controller
> and `Damage` contract do not change.

### 2.3 Projectile motion as a stateless strategy — `scripts/resources/projectile_motion.gd`

One `projectile.tscn` serves cannon shells *and* missiles; the difference is the
assigned motion resource. Motion is stateless logic that mutates the projectile's
velocity each frame:

```gdscript
class_name ProjectileMotion
extends Resource
func update(projectile, delta: float) -> void: pass  # base = straight (no-op)

# AcceleratingMotion -> velocity += velocity.normalized() * accel * delta (clamped to max)
# HomingMotion       -> steer velocity toward projectile.target by turn_rate;
#                       re-acquire target, preferring nodes in group "decoys" (flares)
```

`Projectile` has `motion` (null or base = straight) and a `target`. The base
class behaves as straight line, so existing shots are unchanged.

> Status: base (straight) implemented now as the seam. Accelerating / Homing
> are added when missiles are built.

---

## 3. Defenses — components routed through one damage pipeline

Defenses are components on the ship (composition, per CLAUDE.md). Order is
centralized in a single pipeline so it stays predictable:

```
projectile / ray  -->  ship.take_damage(dmg)
                          |
                          v
                 Barrier absorbs?  (skipped if dmg.bypass_barrier)
                          |  remainder
                          v
                 Hull HealthComponent  (ShipStats resistances by Damage.Type)
```

- **Barrier** — `Area2D` on a `barrier` collision layer with its own HP +
  per-type resistance + regen-after-delay. *Missiles ignore it elegantly:* a
  projectile with `bypass_barrier` simply **excludes the barrier layer from its
  `collision_mask`**, so it physically passes through. Lasers (rays) include the
  barrier layer, hit it first, and apply reduced energy damage (barrier has high
  ENERGY resistance).
- **Point-defense / APS** — a detection `Area2D` on the enemy-projectile layer;
  on cooldown picks the nearest incoming projectile, rolls hit chance, frees it
  (or spawns a tiny interceptor). It is a `Weapon` whose targets are projectiles.
- **Flare** — deployable node added to group `"decoys"` with a lifetime and lure
  weight; `HomingMotion` weighs decoys when choosing a target.

---

## 4. Collision layer convention (2D physics)

Reused by all combat systems (also recorded in `EDITOR_TODO.md`):

| Bit | Layer |
|---|---|
| 1 | player |
| 2 | enemies |
| 3 | player_projectiles |
| 4 | enemy_projectiles |
| 5 | environment |
| 6 | barrier |

A player projectile's mask = enemies + environment (+ barrier, unless
`bypass_barrier`). APS masks the opposing projectile layer.

---

## 5. Build order (validate fun before generalizing)

The implementation guide is explicit (§1.3, Phase 1): prove the moment-to-moment
combat is fun before building a content factory. So:

1. **Now (Steps 2–3):** `Damage` packet + `DamageType` enum, and the
   `ProjectileMotion` hook (straight only). Cheap, and they prevent a painful
   `take_damage(float)` refactor across many files later. ✅ implemented.
2. **After core combat feels good (post Phase 1–2):** `HitscanDelivery` (laser)
   and `HomingMotion` (missile) — two very different weapons proving the axes
   compose, with no new framework.
3. **Phase 7 (Build Diversity):** Barrier, APS, Flare, plasma/cannon variety,
   and the full **module-slot** framework (ship holds `Array[ModuleData]` and
   instantiates controllers) that ties weapons + defenses into the refit/fleet
   layer.

Logic is code-only; the scenes for barriers, APS, flares, and the beam visual
are `EDITOR_TODO` items (Area2D + shapes + neon visuals).
