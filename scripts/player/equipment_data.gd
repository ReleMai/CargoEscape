# ==============================================================================
# EQUIPMENT DATA RESOURCE
# ==============================================================================
#
# FILE: scripts/player/equipment_data.gd
# PURPOSE: Defines equippable items (weapons, armor, accessories, relics)
#
# EQUIPMENT TYPES:
# - Weapons (ranged and melee)
# - Armor (body protection)
# - Helmet (head protection)
# - Accessories (rings, necklaces, etc.)
# - Relics (special passive items)
# - Ammo (consumable weapon ammunition)
#
# ==============================================================================

extends Resource
class_name EquipmentData


# ==============================================================================
# ENUMS
# ==============================================================================

enum EquipmentType {
	NONE = 0,
	WEAPON_RANGED = 1,
	WEAPON_MELEE = 2,
	ARMOR = 3,
	HELMET = 4,
	ACCESSORY = 5,
	RELIC = 6,
	AMMO = 7
}

enum WeaponDamageType {
	PHYSICAL = 0,
	ENERGY = 1,
	PLASMA = 2,
	EXPLOSIVE = 3
}

enum AmmoType {
	NONE = 0,
	BULLET = 1,
	SHELL = 2,
	ENERGY_CELL = 3,
	PLASMA_CELL = 4,
	ROCKET = 5,
	ARROW = 6
}


# ==============================================================================
# BASIC INFO
# ==============================================================================

@export_group("Basic Info")
## Unique identifier
@export var id: String = "equipment_unknown"

## Display name
@export var name: String = "Unknown Equipment"

## Description
@export_multiline var description: String = "A mysterious piece of equipment."

## Equipment type (determines slot)
@export var equipment_type: EquipmentType = EquipmentType.NONE

## Rarity (0-4: Common, Uncommon, Rare, Epic, Legendary)
@export_range(0, 4) var rarity: int = 0

## Lore/flavor text
@export_multiline var lore_text: String = ""

## Components obtained when salvaging
@export var crafting_components: Dictionary = {}

## Recipe to craft this item
@export var craft_recipe: Dictionary = {}


# ==============================================================================
# GRID SIZE (For inventory)
# ==============================================================================

@export_group("Grid Size")
## Width in inventory grid cells
@export_range(1, 6) var grid_width: int = 1

## Height in inventory grid cells
@export_range(1, 6) var grid_height: int = 2


# ==============================================================================
# STAT BONUSES
# ==============================================================================

@export_group("Stat Bonuses")
## Health bonus when equipped
@export var bonus_health: int = 0

## Attack bonus when equipped
@export var bonus_attack: int = 0

## Defense bonus when equipped
@export var bonus_defense: int = 0

## Speed bonus when equipped
@export var bonus_speed: int = 0

## Luck bonus when equipped
@export var bonus_luck: int = 0

## Stealth bonus when equipped
@export var bonus_stealth: int = 0


# ==============================================================================
# WEAPON STATS (Only for weapons)
# ==============================================================================

@export_group("Weapon Stats")
## Base damage dealt by this weapon
@export var base_damage: int = 10

## Damage type
@export var damage_type: WeaponDamageType = WeaponDamageType.PHYSICAL

## Fire rate (attacks per second, for ranged)
@export var fire_rate: float = 1.0

## Range in pixels (for ranged weapons)
@export var range_pixels: float = 500.0

## Ammo type required (NONE for melee)
@export var ammo_type: AmmoType = AmmoType.NONE

## Magazine size (0 for unlimited/melee)
@export var magazine_size: int = 0

## Reload time in seconds
@export var reload_time: float = 1.5

## Critical hit chance (0.0 to 1.0)
@export var crit_chance: float = 0.05

## Critical damage multiplier
@export var crit_multiplier: float = 2.0

## Accuracy (1.0 = perfect, 0.5 = very inaccurate)
@export var accuracy: float = 0.9

## Attack speed multiplier for melee
@export var attack_speed: float = 1.0


# ==============================================================================
# ARMOR STATS (Only for armor/helmet)
# ==============================================================================

@export_group("Armor Stats")
## Flat damage reduction
@export var armor_value: int = 0

## Damage reduction percentage (0.0 to 1.0)
@export var damage_reduction: float = 0.0

## Special resistances (damage type -> reduction %)
@export var resistances: Dictionary = {}


# ==============================================================================
# AMMO STATS (Only for ammo)
# ==============================================================================

@export_group("Ammo Stats")
## Current stack amount
@export var ammo_amount: int = 1

## Maximum stack size
@export var max_ammo_stack: int = 100


# ==============================================================================
# SPECIAL ABILITIES
# ==============================================================================

@export_group("Special Abilities")
## Unique ability ID (empty for none)
@export var special_ability_id: String = ""

## Ability description
@export_multiline var ability_description: String = ""

## Ability cooldown in seconds
@export var ability_cooldown: float = 0.0


# ==============================================================================
# VISUALS
# ==============================================================================

@export_group("Visuals")
## Icon texture for inventory
@export var icon: Texture2D

## Sprite when equipped (for visible equipment)
@export var equipped_sprite: Texture2D

## Muzzle flash sprite (for ranged weapons)
@export var muzzle_flash: Texture2D

## Projectile sprite (for ranged weapons)
@export var projectile_sprite: Texture2D


# ==============================================================================
# VALUE
# ==============================================================================

@export_group("Value")
## Base credit value
@export var base_value: int = 100

## EXP granted when picking up
@export var exp_value: int = 0


# ==============================================================================
# HELPER METHODS
# ==============================================================================

## Check if this is a weapon
func is_weapon() -> bool:
	return equipment_type == EquipmentType.WEAPON_RANGED or equipment_type == EquipmentType.WEAPON_MELEE


## Check if this is armor (body or helmet)
func is_armor() -> bool:
	return equipment_type == EquipmentType.ARMOR or equipment_type == EquipmentType.HELMET


## Check if this requires ammo
func requires_ammo() -> bool:
	return equipment_type == EquipmentType.WEAPON_RANGED and ammo_type != AmmoType.NONE


## Get total stat bonuses as dictionary
func get_stat_bonuses() -> Dictionary:
	return {
		"health": bonus_health,
		"attack": bonus_attack,
		"defense": bonus_defense,
		"speed": bonus_speed,
		"luck": bonus_luck,
		"stealth": bonus_stealth
	}


## Calculate EXP value based on rarity and size
func calculate_exp_value() -> int:
	var rarity_multipliers = [1, 2, 4, 8, 16]  # Common to Legendary
	var size_factor = grid_width * grid_height
	var base_exp = 5
	
	return base_exp * rarity_multipliers[rarity] * size_factor


## Get rarity name
func get_rarity_name() -> String:
	match rarity:
		0: return "Common"
		1: return "Uncommon"
		2: return "Rare"
		3: return "Epic"
		4: return "Legendary"
		_: return "Unknown"


## Get equipment type name
func get_type_name() -> String:
	match equipment_type:
		EquipmentType.WEAPON_RANGED: return "Ranged Weapon"
		EquipmentType.WEAPON_MELEE: return "Melee Weapon"
		EquipmentType.ARMOR: return "Armor"
		EquipmentType.HELMET: return "Helmet"
		EquipmentType.ACCESSORY: return "Accessory"
		EquipmentType.RELIC: return "Relic"
		EquipmentType.AMMO: return "Ammunition"
		_: return "Unknown"
