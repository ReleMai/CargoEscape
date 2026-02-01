# ==============================================================================
# MODULE DATA - SHIP UPGRADE MODULES
# ==============================================================================
#
# FILE: scripts/loot/module_data.gd
# PURPOSE: Defines ship modules that provide stat bonuses
#
# MODULE TYPES:
# - FLIGHT: Speed, maneuverability, drag
# - COMBAT: Damage, fire rate, projectile speed
# - UTILITY: Health, shields, special abilities
#
# ==============================================================================

extends ItemData
class_name ModuleData


# ==============================================================================
# ENUMS
# ==============================================================================

enum ModuleType {
	FLIGHT,   # Speed, thrust, handling
	COMBAT,   # Damage, fire rate
	UTILITY   # Health, shields, special
}


# ==============================================================================
# MODULE PROPERTIES
# ==============================================================================

## What type of module this is
@export var module_type: ModuleType = ModuleType.FLIGHT

## Module tier (determines slot it goes in and power level)
@export_range(1, 4) var module_tier: int = 1


# ==============================================================================
# STAT BONUSES - FLIGHT
# ==============================================================================

@export_group("Flight Bonuses")

## Speed multiplier bonus (1.0 = no change, 1.2 = 20% faster)
@export var speed_multiplier: float = 1.0

## Thrust power bonus (added to base thrust)
@export var thrust_bonus: float = 0.0

## Drag reduction (lower = less drag)
@export var drag_multiplier: float = 1.0


# ==============================================================================
# STAT BONUSES - COMBAT
# ==============================================================================

@export_group("Combat Bonuses")

## Damage multiplier (1.0 = no change, 1.5 = 50% more damage)
@export var damage_multiplier: float = 1.0

## Fire rate multiplier (1.0 = no change, 1.2 = 20% faster)
@export var fire_rate_multiplier: float = 1.0

## Projectile speed bonus
@export var projectile_speed_bonus: float = 0.0


# ==============================================================================
# STAT BONUSES - UTILITY
# ==============================================================================

@export_group("Utility Bonuses")

## Max health bonus (added to base health)
@export var health_bonus: float = 0.0

## Damage reduction (0.0 = no reduction, 0.2 = 20% less damage taken)
@export var damage_reduction: float = 0.0

## Loot value multiplier (1.0 = no change, 1.2 = 20% more value)
@export var loot_multiplier: float = 1.0


# ==============================================================================
# HELPERS
# ==============================================================================

## Get module type as string
func get_module_type_name() -> String:
	match module_type:
		ModuleType.FLIGHT: return "Flight"
		ModuleType.COMBAT: return "Combat"
		ModuleType.UTILITY: return "Utility"
		_: return "Unknown"


## Get a description of the module's effects
func get_effects_description() -> String:
	var effects: Array[String] = []
	
	match module_type:
		ModuleType.FLIGHT:
			if speed_multiplier != 1.0:
				effects.append("+%d%% Speed" % [int((speed_multiplier - 1.0) * 100)])
			if thrust_bonus > 0:
				effects.append("+%d Thrust" % [int(thrust_bonus)])
			if drag_multiplier != 1.0:
				effects.append("-%d%% Drag" % [int((1.0 - drag_multiplier) * 100)])
		
		ModuleType.COMBAT:
			if damage_multiplier != 1.0:
				effects.append("+%d%% Damage" % [int((damage_multiplier - 1.0) * 100)])
			if fire_rate_multiplier != 1.0:
				effects.append("+%d%% Fire Rate" % [int((fire_rate_multiplier - 1.0) * 100)])
			if projectile_speed_bonus > 0:
				effects.append("+%d Proj Speed" % [int(projectile_speed_bonus)])
		
		ModuleType.UTILITY:
			if health_bonus > 0:
				effects.append("+%d Max Health" % [int(health_bonus)])
			if damage_reduction > 0:
				effects.append("-%d%% Damage Taken" % [int(damage_reduction * 100)])
			if loot_multiplier != 1.0:
				effects.append("+%d%% Loot Value" % [int((loot_multiplier - 1.0) * 100)])
	
	if effects.is_empty():
		return "No bonuses"
	
	return ", ".join(effects)


## Get module color by type
func get_module_type_color() -> Color:
	match module_type:
		ModuleType.FLIGHT: return Color(0.3, 0.7, 1.0)   # Blue
		ModuleType.COMBAT: return Color(1.0, 0.4, 0.3)   # Red
		ModuleType.UTILITY: return Color(0.4, 0.9, 0.4)  # Green
		_: return Color.WHITE


# ==============================================================================
# STATIC HELPER - Create module programmatically
# ==============================================================================

## Create a flight module
static func create_flight_module(
	mod_name: String,
	tier: int,
	speed_mult: float = 1.0,
	thrust: float = 0.0,
	drag_mult: float = 1.0
) -> ModuleData:
	var module = ModuleData.new()
	module.id = mod_name.to_lower().replace(" ", "_")
	module.name = mod_name
	module.module_type = ModuleType.FLIGHT
	module.module_tier = tier
	module.grid_width = 2
	module.grid_height = 2
	module.speed_multiplier = speed_mult
	module.thrust_bonus = thrust
	module.drag_multiplier = drag_mult
	module.rarity = clampi(tier - 1, 0, 4)
	module.value = tier * 200
	module.description = "Flight Module: " + module.get_effects_description()
	return module


## Create a combat module
static func create_combat_module(
	mod_name: String,
	tier: int,
	dmg_mult: float = 1.0,
	fire_mult: float = 1.0,
	proj_speed: float = 0.0
) -> ModuleData:
	var module = ModuleData.new()
	module.id = mod_name.to_lower().replace(" ", "_")
	module.name = mod_name
	module.module_type = ModuleType.COMBAT
	module.module_tier = tier
	module.grid_width = 2
	module.grid_height = 2
	module.damage_multiplier = dmg_mult
	module.fire_rate_multiplier = fire_mult
	module.projectile_speed_bonus = proj_speed
	module.rarity = clampi(tier - 1, 0, 4)
	module.value = tier * 200
	module.description = "Combat Module: " + module.get_effects_description()
	return module


## Create a utility module
static func create_utility_module(
	mod_name: String,
	tier: int,
	health: float = 0.0,
	dmg_red: float = 0.0,
	loot_mult: float = 1.0
) -> ModuleData:
	var module = ModuleData.new()
	module.id = mod_name.to_lower().replace(" ", "_")
	module.name = mod_name
	module.module_type = ModuleType.UTILITY
	module.module_tier = tier
	module.grid_width = 2
	module.grid_height = 2
	module.health_bonus = health
	module.damage_reduction = dmg_red
	module.loot_multiplier = loot_mult
	module.rarity = clampi(tier - 1, 0, 4)
	module.value = tier * 200
	module.description = "Utility Module: " + module.get_effects_description()
	return module
