# ==============================================================================
# STATION DATA - RESOURCE DEFINING STATION PROPERTIES
# ==============================================================================
#
# FILE: scripts/data/station_data.gd
# PURPOSE: Resource that defines a station's properties including enemy types
#
# USAGE:
# Create .tres files with different station configurations
# E.g., abandoned_station.tres, pirate_outpost.tres, military_base.tres
#
# ==============================================================================

extends Resource
class_name StationData


# ==============================================================================
# ENUMS
# ==============================================================================

enum StationType {
	ABANDONED,     # No security, just asteroids and debris
	CIVILIAN,      # Light patrol drones
	PIRATE,        # Aggressive pirates
	CORPORATE,     # Security drones, turrets
	MILITARY       # Heavy military response
}


# ==============================================================================
# BASIC INFO
# ==============================================================================

@export_group("Station Info")

## Unique ID for this station
@export var station_id: String = "abandoned_01"

## Display name
@export var station_name: String = "Abandoned Cargo Hub"

## Station type determines enemy spawning
@export var station_type: StationType = StationType.ABANDONED

## Brief description shown to player
@export_multiline var description: String = "A derelict station drifting through an asteroid field. Long abandoned, but still holds valuable salvage."


# ==============================================================================
# ENEMY CONFIGURATION
# ==============================================================================

@export_group("Enemy Spawning")

## Primary enemy scene to spawn
@export var primary_enemy_scene: PackedScene

## Secondary enemy scene (mixed in occasionally)
@export var secondary_enemy_scene: PackedScene

## Chance to spawn secondary instead of primary (0-1)
@export_range(0.0, 1.0, 0.05) var secondary_spawn_chance: float = 0.2

## Base spawn interval (seconds between spawns)
@export var base_spawn_interval: float = 2.0

## Minimum spawn interval (difficulty cap)
@export var min_spawn_interval: float = 0.5

## How quickly difficulty ramps up
@export var difficulty_ramp_rate: float = 0.01


# ==============================================================================
# ASTEROID FIELD (for ABANDONED type)
# ==============================================================================

@export_group("Asteroid Field")

## Does this station have an asteroid field?
@export var has_asteroid_field: bool = true

## Density of asteroids (spawns per second at base)
@export var asteroid_density: float = 1.5

## Size distribution weights [small, medium, large]
@export var asteroid_size_weights: Vector3 = Vector3(0.5, 0.35, 0.15)


# ==============================================================================
# VISUAL THEME
# ==============================================================================

@export_group("Visual Theme")

## Background color tint
@export var background_tint: Color = Color(0.15, 0.12, 0.1, 1.0)

## Star field density
@export var star_density: float = 1.0

## Nebula color (if any)
@export var nebula_color: Color = Color(0.3, 0.2, 0.15, 0.3)


# ==============================================================================
# LOOT CONFIGURATION
# ==============================================================================

@export_group("Loot")

## Base loot tier at this station (0-3)
@export_range(0, 3, 1) var loot_tier: int = 0

## Loot quality multiplier
@export_range(0.5, 2.0, 0.1) var loot_multiplier: float = 1.0


# ==============================================================================
# UNDOCKING
# ==============================================================================

@export_group("Undocking")

## Time for undocking animation (seconds)
@export var undock_duration: float = 3.0

## Ship types allowed at this station
@export var allowed_ship_types: Array[String] = ["shuttle", "cargo", "fighter"]


# ==============================================================================
# HELPER METHODS
# ==============================================================================

## Get weighted random asteroid size
func get_random_asteroid_size() -> int:
	var total := asteroid_size_weights.x + asteroid_size_weights.y + asteroid_size_weights.z
	var roll := randf() * total
	
	if roll < asteroid_size_weights.x:
		return 0  # Small
	elif roll < asteroid_size_weights.x + asteroid_size_weights.y:
		return 1  # Medium
	else:
		return 2  # Large


## Check if secondary enemy should spawn
func should_spawn_secondary() -> bool:
	return randf() < secondary_spawn_chance and secondary_enemy_scene != null


## Get the appropriate enemy scene to spawn
func get_enemy_to_spawn() -> PackedScene:
	if should_spawn_secondary():
		return secondary_enemy_scene
	return primary_enemy_scene
