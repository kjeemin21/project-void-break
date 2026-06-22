# Project Void Break

Roguelike × extraction × fleet management game built in Godot 4 (2D).

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
│   ├── fleet/          # Fleet AI, doctrine system
│   ├── combat/         # Damage calc, projectiles, collision
│   ├── generation/     # Procedural generation (maps, enemy placement)
│   ├── meta/           # Node map, run state, save/load
│   ├── loot/           # Containers, drop tables, blueprints
│   └── ui/             # UI logic (refit screen, HUD, map view)
├── resources/
│   ├── ships/          # Ship stat definitions (.tres)
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
