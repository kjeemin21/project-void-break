# Project Void Break

Roguelike × extraction × fleet management game built in Godot 4.7 (2D).

## Architecture

- **Player ship**: single directly-controlled ship (the "body"). Death = run over.
- **Fleet**: AI-controlled ships with behavior doctrine modules.
- **Node map**: FTL-style graph with a fixed final destination. Each node is an extraction-style map with enemies, wormholes, and a time limit.
- **Visual style**: neon + low-polygon. Ships defined by vertex arrays, glow via shaders.

## Code-Only Development Rules

This project is developed WITHOUT the Godot editor on this machine. Follow these rules strictly:

### DO
- Write GDScript files (.gd) and shader files (.gdshader)
- Write resource definitions (.tres) as text — but ONLY new files, never edit existing ones
- Read .tscn and .tres files to understand structure
- Add TODO entries to `EDITOR_TODO.md` when work requires the Godot editor
- Write unit-testable logic decoupled from scene tree when possible

### DO NOT
- Create or edit .tscn scene files (permission denied by settings.json)
- Edit existing .tres resource files (permission denied by settings.json)
- Assume any scene tree structure — read the .tscn first if you need to know
- Generate code that depends on editor-configured properties without documenting it

### EDITOR_TODO.md Protocol
When your code requires ANY of the following, append an entry to `EDITOR_TODO.md`:
- Attaching a script to a scene node
- Creating a new scene
- Setting up collision shapes/layers
- Configuring input mappings
- Adjusting visual parameters (shader uniforms, particle settings)
- Wiring signals between nodes in the editor
- UI layout work

Format:
```
## [DATE] [Short Title]
- **File(s)**: which script(s) were created/modified
- **Action**: what needs to be done in the editor
- **Details**: specifics (node paths, property values, etc.)
- **Priority**: high / medium / low
```

## Directory Structure

```
void-break/
├── scripts/
│   ├── ships/          # Ship classes (player, allies, enemies)
│   ├── resources/      # Resource subclass DEFINITIONS (.gd): MovementData, WeaponData, ShipStats, DoctrineData
│   ├── fleet/          # Fleet AI, doctrine system
│   ├── combat/         # Damage calc, projectiles, collision
│   ├── generation/     # Procedural generation (maps, enemy placement)
│   ├── meta/           # Node map, run state, save/load
│   ├── loot/           # Containers, drop tables, blueprints
│   ├── fx/             # Game feel: screen shake, hit-stop, effect/sound helpers
│   └── ui/             # UI logic (refit screen, HUD, map view)
├── resources/          # Resource INSTANCES (.tres) — the actual tunable data assets
│   ├── ships/          # Ship stat / movement definitions (.tres)
│   ├── modules/        # Module definitions (.tres)
│   ├── doctrines/      # Behavior doctrine presets (.tres)
│   └── enemies/        # Enemy fleet composition data (.tres)
├── scenes/             # Scene files — DO NOT EDIT
├── shaders/            # .gdshader files
├── EDITOR_TODO.md      # Editor tasks queue
└── CLAUDE.md           # This file
```

## GDScript Conventions

- Use static typing everywhere: `var speed: float = 100.0`
- Use `@export` for tunable parameters
- Use `@onready` for node references
- Signal naming: past tense verb (`health_changed`, `ship_destroyed`)
- Class naming: PascalCase. File naming: snake_case matching class name
- Prefer composition (modular resources) over deep inheritance
- Factory pattern for runtime entity creation (ships, projectiles, structures)

## Key Design References

- **Movement**: fake Newtonian physics with dampening. `linear_damp` ~1-1.5s coast. Soft speed cap. Boost disables dampening for ramming.
- **Fleet AI**: HFSM base. Doctrine modules change state transitions. Start with hardcoded presets (guard, charge, ranged, standby).
- **Rewards**: containers drop from defeated enemies. Contents applied at node transition (refit phase). Local powerups are node-scoped.
- **Fleet regen**: ships return next node with condition penalty. Repair costs resources.
- **Combat systems**: weapon/defense variety is built from independent axes (delivery, projectile motion, damage interaction, defense), not per-type subclasses. Damageable entities expose `take_damage(dmg: Damage)` with a typed `Damage` packet (school + `bypass_barrier`). Full design in `docs/combat-system-design.md`.
- **Game feel**: a `Feedback` autoload (`scripts/fx/`) is the global juice bus — `add_trauma()` (screen shake via `ShakeCamera`), `hit_stop()` (wall-clock-timed `Engine.time_scale` dips). `ShipBase` drives shake/hit-stop/hit-flash from `take_damage`, tuned per-ship via `@export`. VFX/SFX are optional `PackedScene`/`AudioStream` slots, inert until assigned.

## Module-Ready Architecture

All gameplay parameters must be defined in `Resource` subclasses, not hardcoded in scripts. This enables future module/upgrade swapping without refactoring.

Rules:
- Movement params → `MovementData` resource (thrust, linear_damp, max_speed, rotation_speed, boost_multiplier, boost_damp_override)
- Weapon params → `WeaponData` resource (damage, fire_rate, bullet_speed, bullet_scene)
- Ship stats → `ShipStats` resource (max_hp, defense, shield)
- Doctrine params → `DoctrineData` resource (chase_range, engage_range, retreat_hp_threshold)
- Scripts reference these resources via `@export var`. Never write raw numbers in gameplay logic.
- When creating any new system, always ask: "what if this gets swapped out mid-run?" If the answer is "it might," extract parameters into a `Resource`.
- **File layout**: the resource *definition* (`class_name Foo extends Resource`) lives in `scripts/resources/<foo>.gd`; the resource *instances* (`.tres`) live under the root `resources/` tree. Gameplay logic holds the resource **by reference** so swapping the `.tres` (or editing it in the inspector) takes effect immediately.

## Implementation Roadmap

- [x] **Step 1: Movement** — `CharacterBody2D` or `RigidBody2D` with dampening-based fake Newtonian physics. All params via `MovementData` resource. `@export` for inspector tuning. (Editor: create player scene, attach script, add Camera2D) — _code complete; editor scene tracked in EDITOR_TODO.md_
- [x] **Step 2: Projectile system** — `projectile_base.gd` with `WeaponData` resource. Shooting function on `ship_base`. Cooldown handling. (Editor: projectile scene with `Area2D`, input mapping for fire) — _code complete; editor scene tracked in EDITOR_TODO.md_
- [ ] ← CURRENT **Step 3: Passive enemy** — `health_component.gd` for HP/damage/death signal. `enemy_basic.gd` as a stationary rotating dummy. (Editor: enemy scene, collision layers between player projectiles and enemies)
- [ ] **Step 4: Enemy AI** — Extend enemy with detection, chase, and attack. Simple FSM: Idle → Chase → Attack. Enemy shooting. (Editor: detection `Area2D` on enemy, enemy projectile scene, collision layers for enemy projectiles vs player)
- [ ] **Step 5: Player HP + death** — `health_component` on player. HUD health bar. Game over screen with restart. (Editor: HUD `CanvasLayer`, game over UI)
- [ ] **Step 6: First ally** — `ally_ship.gd` with basic follow + attack AI. `doctrine_guard.gd` hardcoded as first behavior doctrine. (Editor: ally scene with distinct neon color)
- [ ] **Step 7: Single node vertical slice** — Map boundary. Enemy group placement (Poisson disk or random). 2-3 wormholes at map edges (touching = extraction success). Timer with escalating threat. Container drops from defeated enemies. Local powerups (node-scoped). (Editor: wormhole visuals, container visuals, minimap or directional indicators)
- [ ] **Step 8+: Expansion** — Node transition + refit screen → full node map → module/blueprint system → captain selection → build diversity → boss encounter → content expansion.

## Editor TODO

All editor-dependent tasks are tracked in `EDITOR_TODO.md`. Claude Code must append an entry there whenever code requires scene setup, collision configuration, input mapping, or visual tuning. See the **EDITOR_TODO.md Protocol** section above for the entry format.
