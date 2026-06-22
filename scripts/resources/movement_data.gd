class_name MovementData
extends Resource

## Tunable movement parameters for a ship, as a swappable Resource.
##
## Per the Module-Ready Architecture rule (CLAUDE.md): movement values live here,
## never hardcoded in gameplay scripts. Swapping this resource on a ship at
## runtime (e.g. an engine module mid-run) changes its handling immediately —
## ShipMovement holds a live reference, so edits here take effect next frame.
##
## Defaults mirror the values validated in docs/godot-implementation-guide.md §2.
## Create .tres instances under resources/ships/ for per-ship / per-module tuning.

@export_group("Thrust")
@export var thrust_force: float = 900.0           ## forward acceleration (px/s^2)
@export var max_speed: float = 450.0              ## soft cap target for cruise (px/s)
@export var rotation_speed: float = 220.0         ## turn rate (deg/s)

@export_group("Dampening")
@export var linear_damp: float = 1.2              ## coast deceleration when no input (higher = stops sooner)
@export var thrust_damp_fraction: float = 0.1     ## fraction of linear_damp applied while thrusting (lateral bleed)

@export_group("Speed Layers")
@export var boost_multiplier: float = 2.5         ## thrust + cap multiplier during boost
@export var boost_damp_override: float = 0.15     ## damp while boosting (low = more drift)
@export var combat_speed_multiplier: float = 0.5  ## scales thrust + cap in combat mode for precision
