# ==============================================================================
# SHIP MODULE DATA - BASE RESOURCE FOR SHIP UPGRADES
# ==============================================================================
#
# FILE: scripts/data/ship_module.gd
# PURPOSE: Base resource defining ship modules that can be equipped
#
# MODULE SLOTS:
# - FLIGHT: Engines, thrusters, navigation
# - COMBAT: Weapons, targeting systems
# - UTILITY: Shields, scanners, cargo expansions
#
# ==============================================================================

extends Resource
class_name ShipModule


# ==============================================================================
# ENUMS
# ==============================================================================

enum ModuleSlot {
	FLIGHT,   # 0 - Engine/thrust modules
	COMBAT,   # 1 - Weapon modules
	UTILITY   # 2 - Shield/utility modules
}

enum ModuleRarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}


# ==============================================================================
# BASE PROPERTIES
# ==============================================================================

@export_group("Basic Info")

## Unique identifier for this module
@export var module_id: String = "basic_laser"

## Display name
@export var module_name: String = "Basic Laser"

## Description shown in UI
@export_multiline var description: String = "A standard mining laser repurposed for combat."

## Which slot this module fits in
@export var slot_type: ModuleSlot = ModuleSlot.COMBAT

## Rarity affects stats and visuals
@export var rarity: ModuleRarity = ModuleRarity.COMMON

## Base credit value
@export var base_value: int = 100


# ==============================================================================
# VISUAL PROPERTIES
# ==============================================================================

@export_group("Visuals")

## Primary color of the module
@export var primary_color: Color = Color(0.8, 0.2, 0.2, 1.0)

## Secondary/accent color
@export var secondary_color: Color = Color(1.0, 0.5, 0.2, 1.0)

## Glow color when active
@export var glow_color: Color = Color(1.0, 0.3, 0.1, 0.8)

## Size multiplier for visual (1.0 = standard)
@export_range(0.5, 2.0, 0.1) var visual_scale: float = 1.0


# ==============================================================================
# COMBAT STATS (for COMBAT modules)
# ==============================================================================

@export_group("Combat Stats")

## Damage per shot
@export var damage: float = 25.0

## Shots per second
@export var fire_rate: float = 5.0

## Projectile speed
@export var projectile_speed: float = 800.0

## Energy cost per shot
@export var energy_cost: float = 5.0


# ==============================================================================
# FLIGHT STATS (for FLIGHT modules)
# ==============================================================================

@export_group("Flight Stats")

## Thrust power bonus
@export var thrust_bonus: float = 0.0

## Max speed bonus
@export var speed_bonus: float = 0.0

## Drag reduction
@export var drag_reduction: float = 0.0


# ==============================================================================
# UTILITY STATS (for UTILITY modules)
# ==============================================================================

@export_group("Utility Stats")

## Shield capacity bonus
@export var shield_bonus: float = 0.0

## Scanner range bonus
@export var scanner_bonus: float = 0.0

## Cargo space bonus
@export var cargo_bonus: int = 0


# ==============================================================================
# HELPER METHODS
# ==============================================================================

func get_rarity_color() -> Color:
	match rarity:
		ModuleRarity.COMMON:
			return Color(0.7, 0.7, 0.7)
		ModuleRarity.UNCOMMON:
			return Color(0.2, 0.8, 0.2)
		ModuleRarity.RARE:
			return Color(0.2, 0.4, 1.0)
		ModuleRarity.EPIC:
			return Color(0.6, 0.2, 0.8)
		ModuleRarity.LEGENDARY:
			return Color(1.0, 0.6, 0.1)
	return Color.WHITE


func get_slot_name() -> String:
	match slot_type:
		ModuleSlot.FLIGHT:
			return "Flight"
		ModuleSlot.COMBAT:
			return "Combat"
		ModuleSlot.UTILITY:
			return "Utility"
	return "Unknown"
