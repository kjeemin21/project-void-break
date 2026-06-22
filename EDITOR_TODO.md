# Editor TODO

> Tasks that require the Godot editor. Work through these when you have editor access.
> Mark completed items with ~~strikethrough~~ or delete them.

---

<!-- New entries go below this line, newest first -->

## [2026-06-22] Enemy Dummy Scene + Stats Resource + Hit Layers (Step 3)
- **File(s)**: `scripts/ships/enemy_basic.gd`, `scripts/combat/health_component.gd`, `scripts/resources/ship_stats.gd`, `scripts/ships/ship_base.gd`
- **Action**:
  1. Create `scenes/ships/enemy_basic.tscn`: root `CharacterBody2D` with `scripts/ships/enemy_basic.gd` attached. Children: a `CollisionShape2D` (hull-sized) and a neon `Polygon2D` in a distinct enemy color (e.g. red/orange) so it reads as hostile vs the player.
  2. Collision layers (using the convention from the Step 2 entry / docs §4): set the enemy's `collision_layer` = enemies (2). This is what makes player projectiles connect — the projectile Area2D masks layer 2, and `body_entered` fires on bodies whose layer is in that mask. Set the enemy's `collision_mask` = environment (5) [+ player (1) later for ramming]; a stationary dummy barely needs a mask.
  3. Create a `ShipStats` resource: in `resources/ships/`, New Resource → `ShipStats`, save as `resources/ships/enemy_dummy_stats.tres`. Set `max_hp` (e.g. 30), leave `defense`/`shield` at 0 and resistances at 1.0 for a plain target. Assign it to the enemy's `stats` export. (If unassigned, ShipBase makes a default 100-HP ShipStats.)
  4. Place one or more enemy instances in `scenes/test_movement.tscn` within firing range so you can shoot them. Confirm: projectiles reduce HP, the dummy frees itself at 0 HP, and it idle-spins (`spin_speed`).
  5. (Optional, helps debugging before the HUD exists) temporarily connect to the enemy's health via code or a Label to watch HP go down — full HUD is Step 5.
- **Details**: `EnemyBasic extends ShipBase`, inheriting `take_damage(dmg: Damage)` and the death pipeline. The damage packet is typed (school + resistances), so once you add armored/resistant enemy stats later, weapon schools start to matter. Player ship death is intentionally NOT wired yet (ShipBase default frees the node) — `PlayerShip` overrides `_on_died` in Step 5.
- **Priority**: high

## [2026-06-22] Projectile Scene + Weapon Resource + Fire Input (Step 2)
- **File(s)**: `scripts/combat/projectile_base.gd`, `scripts/combat/weapon.gd`, `scripts/resources/weapon_data.gd`, `scripts/ships/ship_base.gd`, `scripts/ships/player_ship.gd`
- **Action**:
  1. Create `scenes/combat/projectile_basic.tscn`: root `Area2D` with `scripts/combat/projectile_base.gd` attached. Children: a `CollisionShape2D` (small `CircleShape2D`, radius ~4-6) and a neon visual (`Polygon2D` or short `Line2D` oriented along +X — the projectile's heading). Leave `monitoring`/`monitorable` on (default). Do NOT connect `body_entered`/`area_entered` in the editor — the script connects them in code.
  2. Define collision layers (Project Settings → Layer Names → 2D Physics). Convention (reused by all later combat; see docs/combat-system-design.md §4):
     - 1 = player, 2 = enemies, 3 = player_projectiles, 4 = enemy_projectiles, 5 = environment, 6 = barrier
     Set the projectile scene's `collision_layer` = player_projectiles (3) and `collision_mask` = enemies (2) + environment (5) [+ barrier (6) for non-bypass weapons]. (Step 4 will add an enemy projectile variant masking player.)
  3. Create a `WeaponData` resource: in `resources/modules/`, New Resource → `WeaponData`, save as `resources/modules/blaster_basic.tres`. Set `bullet_scene` to `projectile_basic.tscn`; tune `damage` / `fire_rate` / `bullet_speed` / `bullet_lifetime`. Leave `damage_type` Kinetic, `bypass_barrier` off, and `motion` empty (= straight) for the basic blaster. Assign it to the player ship's `weapon_data` export (from ShipBase). Until a WeaponData with a bullet_scene is assigned, firing is a no-op.
  4. Add Input Map action `fire` → Space and/or left mouse button (the script falls back to physical Space if unset).
  5. Optional: add a `Projectiles` `Node2D` to the test scene and set the player's `projectile_container_path` to it, to keep spawned shots grouped. If unset, projectiles parent to the current scene root (fine).
  6. Optional polish: a `Muzzle` `Marker2D` child on the ship can later replace the `muzzle_distance` offset for off-center barrels.
- **Details**: `PlayerShip` now `extends ShipBase`; the scene root script stays `player_ship.gd` (no scene change needed beyond the existing player ship task). Projectiles fire along ship facing from `muzzle_distance` ahead of the origin. No enemies exist yet (Step 3), so verify shots spawn, travel straight, and despawn after `bullet_lifetime`.
- **Priority**: high

## [2026-06-22] Player Ship Scene + Input Map (Basic Movement)
- **File(s)**: `scripts/ships/player_ship.gd`, `scripts/ships/ship_movement.gd`, `scripts/resources/movement_data.gd`
- **Action**:
  1. Create `scenes/ships/player_ship.tscn` with root node `CharacterBody2D` and attach `scripts/ships/player_ship.gd`.
  2. Add child nodes for the ship body: a `Polygon2D` (low-poly hull, vertex array) and a `CollisionShape2D` (convex/capsule fitting the hull). Neon glow comes later via shader + WorldEnvironment.
  3. Create a `MovementData` resource for the player: in the FileSystem dock, right-click `resources/ships/` → New Resource → `MovementData`, save as `resources/ships/player_movement.tres`. Defaults are fine to start (they match the tuned values); adjust live while play-testing. Then assign it to the player ship's `movement_data` export. (If left unassigned, the script instances a default at runtime, so movement still works — but a .tres is needed for tuning and for swapping engine modules later.)
  4. Configure Input Map actions (Project Settings → Input Map). The script falls back to physical W / A / D / Shift / C if these are missing, but set them properly:
     - `thrust_forward` → W (and gamepad right trigger if desired)
     - `turn_left` → A
     - `turn_right` → D
     - `boost` → Shift
     - `combat_mode` → C (toggle)
  5. Set up collision layers/masks: player ship on a "player" layer, masking "enemies" / "environment" (define the layer naming convention now — combat and projectiles will reuse it).
  6. Make a quick test scene `scenes/test_movement.tscn` with the player ship instanced + a Camera2D, set as the run/main scene, to feel-test movement.
- **Details**: Movement params now live in the `MovementData` resource (Module-Ready Architecture), grouped Thrust / Dampening / Speed Layers in the inspector — tune the .tres live while playing. Default facing is +X (rotation 0); orient the polygon to point along +X so the sprite matches the heading.
- **Priority**: high
