# Project Void Break — Godot Implementation Guide

> **Engine**: Godot 4.7 (2D)  
> **Scope**: Solo developer  
> This document covers implementation difficulty, technical approaches, space movement design, and recommended development order.

---

## 1. Implementation Difficulty by System

### 1.1 Low Difficulty

**Top-Down Real-Time Combat (Core)**

The basic combat framework is well within Godot's strengths. Player ship movement, projectile spawning, collision detection, and destruction are standard 2D game patterns. The choice between `CharacterBody2D` and `RigidBody2D` for the player ship matters early — `RigidBody2D` gives natural momentum for the ramming build, while `CharacterBody2D` offers tighter control tuning. Prototype both before committing.

**FTL-Style Node Map**

The overworld map is a graph data structure (nodes and edges) rendered as a UI layer. Procedural generation can use a layered approach: place nodes in columns, randomly connect adjacent layers, and ensure at least one path to the final destination. Visually, this is just `Control` nodes with `Line2D` connections. The wormhole-to-node mapping is data, not geometry, so it's straightforward.

**Neon + Polygon Visual Style**

This aesthetic is efficient in Godot 2D. `Polygon2D` and `Line2D` handle ship shapes and outlines. `WorldEnvironment` with glow post-processing creates the neon bloom effect. `CanvasItem` shaders can add per-object glow on outlines and engine trails. No 3D modeling pipeline needed — the low-poly constraint is an art production advantage.

### 1.2 Medium Difficulty

**In-Node Map Procedural Generation**

The game's maps are open space with distributed points of interest, not tile-based dungeons. Poisson Disk Sampling works well for placing enemy fleets and wormholes with guaranteed minimum spacing. Wormholes should be placed near map edges, separated directionally. Obstacle fields (asteroids, debris) can use noise functions to create navigational variation.

The challenge is not the algorithm but the tuning — making generated layouts that consistently produce interesting routing decisions takes iteration.

**Fleet Management / Refit UI**

Technically moderate but design-intensive. The refit screen (ship list, module equipping, behavior assignment, container opening) runs every node transition, so it must be fast and frictionless. Godot's `Control` node system is flexible, but drag-and-drop interactions for module equipping require custom implementation. Prioritize keyboard shortcuts and minimal clicks.

### 1.3 High Difficulty

**Behavior Doctrine System (Fleet AI)**

This is the project's most challenging system. There is no built-in AI framework in Godot 4.

Recommended approach: **Hierarchical Finite State Machine (HFSM)** as the base, where doctrine modules modify state transition conditions and priorities.

- A "Guard" preset is a state machine: Follow Player → Intercept (when enemy approaches) → Evade (when HP low).
- A "Charge" preset uses the same states but with different transition thresholds.
- Doctrine modules acquired during a run alter thresholds, add new states, or change priority ordering.

Behavior Trees are an alternative — the **LimboAI** GDExtension provides a solid foundation. However, runtime modification of tree structures (which doctrine modules would need to do) adds architectural complexity.

Critical advice: **hardcode 3–4 presets first and verify that combat is fun before generalizing the system.** Knowing which behaviors are enjoyable is a prerequisite for designing a flexible doctrine architecture.

**Many-Entity Combat Performance**

Fleet builds with swarm sub-builds could put dozens of ships on screen, each running AI and firing projectiles simultaneously.

Mitigation strategies:

- Use `Area2D` with manual position updates for projectiles instead of physics bodies.
- Time-slice AI updates: divide ships into groups that update on alternating frames rather than every frame.
- Set a practical ceiling on simultaneous ships (20–30 per side) and design "swarm" builds as relatively many, not literally hundreds.
- Object pooling for projectiles and explosion effects.

**Engineer / Base-Building Build**

This build layer adds production queues, buildable structures with their own collision and behavior, and spawned units that also need AI. It is effectively a mini-RTS system on top of the existing combat layer. Implement this last, after the other two build archetypes are proven fun.

---

## 2. Space Movement Design

### 2.1 The Core Problem

Pure Newtonian physics in space is realistic but unpleasant for extended play. Constant acceleration without friction means overshooting targets, inability to stop precisely, and exhausting correction burns. The solution is to keep the parts of Newtonian motion that feel cool (momentum, drift, weight) while quietly removing the frustrating parts.

### 2.2 Fake Space Physics

**Dampening Is the Foundation**

Apply a deceleration force when there is no input, so ships gradually come to rest. This violates real physics but satisfies the player's intuition that releasing controls should stop the ship. In Godot, `RigidBody2D.linear_damp` handles this directly. With `CharacterBody2D`, multiply velocity by a decay factor each physics frame.

Target feel: the ship should coast to a stop roughly 1–1.5 seconds after releasing input. Not an instant halt (that feels like ground movement), but not an endless drift (that feels out of control).

**Rotation-Movement Coupling**

Thrust should only apply in the direction the ship is facing. Combined with dampening, this produces natural curved trajectories — turning while moving creates a smooth arc with a slight drift before the ship realigns to the new heading. This gives the "piloting a ship" sensation that twin-stick (move direction independent of facing) lacks.

Rotation speed must be generous. Slow rotation creates situations where the player dies because the ship wouldn't turn in time, which feels unfair rather than challenging.

**Soft Speed Cap**

Do not use a hard velocity clamp. When the ship hits max speed with a hard cap, the acceleration feeling cuts off abruptly. Instead, reduce thrust efficiency as speed increases — the ship keeps accelerating but with diminishing returns, converging on a maximum. This gives a natural "topping out" sensation.

### 2.3 Speed Layers

A single movement speed creates problems: too slow for traversal, too fast for combat precision.

**Cruise Speed**: Default speed for navigating between points of interest. The map should be crossable in roughly 30–40 seconds. Fast enough that traversal isn't boring, slow enough that the player can read the battlefield while moving.

**Combat Speed**: Slower, more precise maneuvering during engagements. This can be automatic (detecting nearby enemies) or manual (a toggle). A manual toggle is preferable — it gives the player agency to express "I'm disengaging" by switching to cruise and boosting away.

**Emergency Boost**: Short-duration burst acceleration on a cooldown or fuel cost. Serves multiple purposes: escaping dangerous situations, closing distance for ramming, and adding a skill-expression layer to movement. During boost, reduce or remove dampening so that momentum carries through — this makes boosting feel powerful and gives the ramming build its weight.

### 2.4 Ramming Build Compatibility

The ramming build requires momentum to be a gameplay element, which seems to conflict with dampening. The resolution: dampening applies at normal speed, but boost partially or fully disables it. This means:

- Normal flight: controlled, responsive, easy to position.
- Boost: momentum takes over, the ship carries its inertia, and collisions hit hard.
- Collision damage scales with velocity at impact, so a properly accelerated ram deals far more damage than a slow bump.

This creates a skill curve for ramming — the player must judge distance, build speed, and commit to a trajectory, knowing that reduced dampening means less ability to correct course.

### 2.5 Implementation Notes

Whichever body type is chosen, expose all movement parameters as `@export` variables from day one:

- `thrust_force`: forward acceleration
- `linear_damp`: deceleration when no input
- `max_speed`: soft cap target (used to scale thrust reduction)
- `rotation_speed`: degrees per second
- `boost_multiplier`: thrust multiplier during boost
- `boost_damp_override`: dampening value during boost (lower = more drift)

With these exposed in the inspector, tuning can happen during play testing by adjusting sliders in real time, which is an order of magnitude faster than editing code and rebuilding.

For `RigidBody2D`: apply forces in `_physics_process`, let `linear_damp` handle deceleration, and scale applied force inversely with current speed for the soft cap.

For `CharacterBody2D`: manage a velocity vector directly, apply thrust as velocity delta, multiply velocity by a decay factor each frame, and call `move_and_slide()`.

---

## 3. Recommended Development Order

The ordering prioritizes validating fun at each stage before building the next layer. Each phase should be playable and testable on its own.

### Phase 1: Core Combat Feel

Player ship movement and shooting. One enemy ship with basic chase-and-fire behavior. Destruction, health, hit feedback. **Goal**: determine if the moment-to-moment action is satisfying. If this is not fun within 30 minutes of play, nothing built on top will save it.

### Phase 2: First Ally

Add a single AI-controlled ally ship with the simplest possible doctrine (follow player, attack nearest enemy). **Goal**: verify that "commanding a fleet" adds something — does the ally feel like a companion or a liability? This informs how much AI sophistication is needed.

### Phase 3: Single Node (Vertical Slice)

Procedurally generated node map with multiple enemy fleets, multiple wormholes, a time limit, and container drops. Local powerups. The extraction loop in miniature. **Goal**: validate the "enter, fight selectively, choose an exit" loop. This is the most important milestone — if this loop works, the game works.

### Phase 4: Node Transition and Refit

Connect two nodes via wormhole traversal. Build the refit screen: open containers, equip modules, build ships from blueprints, assign doctrines. **Goal**: confirm that the growth loop between nodes feels rewarding and that the refit flow is not tedious.

### Phase 5: Overworld Map

Full FTL-style node graph with multiple paths to the final destination. Map themes affecting enemy fleet pools. Route planning. **Goal**: validate that strategic path choice adds a meaningful layer.

### Phase 6: Boss Encounter

Design and implement the final node. If following the "ultimate extraction" approach: a map-dominating boss that must be survived while reaching the final wormhole. **Goal**: provide a climactic payoff that tests the player's full build.

### Phase 7: Build Diversity

Captain selection with starting loadouts. Expand the module and ship pool to support the three build archetypes (mothership-focused, fleet-focused, engineer/base-building). Behavior doctrine modules beyond basic presets. **Goal**: ensure multiple viable playstyles exist.

### Phase 8: Polish and Content

Visual effects (neon glow, polygon shattering, wormhole animations). Sound design. UI polish. Content expansion (more enemy types, more modules, more map themes). Balancing across builds and difficulty curves.

---

## 4. Technical Risk Summary

| Risk | Impact | Mitigation |
|---|---|---|
| Fleet AI not feeling intelligent | Players ignore fleet, game collapses to solo action | Validate with hardcoded presets early; prioritize readability of AI behavior over complexity |
| Performance with many entities | Frame drops in swarm builds break real-time combat | Time-sliced AI, object pooling, entity caps, Area2D over physics bodies for projectiles |
| Movement feel is wrong | Everything built on top feels bad | Expose all parameters as `@export`; tune during play; budget significant time for iteration |
| Procedural maps feel samey | Replayability drops despite roguelike structure | Invest in map theme differentiation; vary enemy placement density and obstacle geometry per theme |
| Refit screen is tedious | Players dread node transitions instead of anticipating them | Design for minimum clicks; playtest the refit loop specifically for friction |
| Engineer build is underpowered | One of three core archetypes becomes a trap | Implement last; design node types where base-building has a clear efficiency advantage |
