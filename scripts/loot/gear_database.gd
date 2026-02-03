# ==============================================================================
# GEAR DATABASE
# ==============================================================================
#
# FILE: scripts/loot/gear_database.gd
# PURPOSE: Central database for armor, helmets, accessories, and relics
#
# GEAR CATEGORIES:
# - Armor (body protection with defense bonuses)
# - Helmets (head protection with utility bonuses)
# - Accessories (rings, necklaces with various bonuses)
# - Relics (unique passive items with special abilities)
#
# ==============================================================================

extends Node
class_name GearDatabase


# ==============================================================================
# ARMOR (10 items)
# ==============================================================================

const ARMOR_ITEMS = {
	# ============ LIGHT ARMOR ============
	"armor_flight_suit": {
		"name": "Flight Suit",
		"description": "Basic pilot's jumpsuit. Minimal protection.",
		"width": 2, "height": 3,
		"armor_value": 5,
		"damage_reduction": 0.05,
		"bonus_speed": 2,
		"rarity": 0,
		"value": 100,
		"icon": "res://assets/sprites/items/gear/armor_flight_suit.png"
	},
	"armor_stealth_suit": {
		"name": "Stealth Suit",
		"description": "Sound-dampening bodysuit. Built for infiltration.",
		"width": 2, "height": 3,
		"armor_value": 8,
		"damage_reduction": 0.08,
		"bonus_stealth": 8,
		"bonus_speed": 1,
		"rarity": 2,
		"value": 1200,
		"icon": "res://assets/sprites/items/gear/armor_stealth_suit.png"
	},
	"armor_scout": {
		"name": "Scout Armor",
		"description": "Lightweight tactical armor. Mobility over protection.",
		"width": 2, "height": 3,
		"armor_value": 12,
		"damage_reduction": 0.10,
		"bonus_speed": 3,
		"rarity": 1,
		"value": 450,
		"icon": "res://assets/sprites/items/gear/armor_scout.png"
	},
	
	# ============ MEDIUM ARMOR ============
	"armor_tactical": {
		"name": "Tactical Vest",
		"description": "Modular combat vest. Balanced protection.",
		"width": 2, "height": 3,
		"armor_value": 20,
		"damage_reduction": 0.15,
		"bonus_defense": 3,
		"rarity": 1,
		"value": 600,
		"icon": "res://assets/sprites/items/gear/armor_tactical.png"
	},
	"armor_combat": {
		"name": "Combat Armor",
		"description": "Standard military-grade protection.",
		"width": 2, "height": 3,
		"armor_value": 28,
		"damage_reduction": 0.20,
		"bonus_defense": 5,
		"bonus_health": 10,
		"rarity": 2,
		"value": 950,
		"icon": "res://assets/sprites/items/gear/armor_combat.png"
	},
	"armor_mercenary": {
		"name": "Mercenary Gear",
		"description": "Battle-worn but reliable protection.",
		"width": 2, "height": 3,
		"armor_value": 25,
		"damage_reduction": 0.18,
		"bonus_attack": 3,
		"bonus_defense": 3,
		"rarity": 2,
		"value": 1100,
		"icon": "res://assets/sprites/items/gear/armor_mercenary.png"
	},
	
	# ============ HEAVY ARMOR ============
	"armor_riot": {
		"name": "Riot Armor",
		"description": "Heavy anti-personnel protection. Slows movement.",
		"width": 2, "height": 4,
		"armor_value": 40,
		"damage_reduction": 0.30,
		"bonus_defense": 8,
		"bonus_health": 20,
		"bonus_speed": -3,
		"rarity": 2,
		"value": 1500,
		"icon": "res://assets/sprites/items/gear/armor_riot.png"
	},
	"armor_power": {
		"name": "Power Armor",
		"description": "Powered exosuit. Maximum protection.",
		"width": 3, "height": 4,
		"armor_value": 55,
		"damage_reduction": 0.40,
		"bonus_defense": 12,
		"bonus_health": 30,
		"bonus_attack": 5,
		"bonus_speed": -4,
		"bonus_stealth": -5,
		"rarity": 3,
		"value": 3500,
		"icon": "res://assets/sprites/items/gear/armor_power.png"
	},
	"armor_exo": {
		"name": "Exoskeleton Frame",
		"description": "Full body mechanical support. Enhanced everything.",
		"width": 3, "height": 4,
		"armor_value": 45,
		"damage_reduction": 0.35,
		"bonus_defense": 10,
		"bonus_health": 25,
		"bonus_attack": 8,
		"bonus_speed": 2,
		"rarity": 4,
		"value": 6000,
		"icon": "res://assets/sprites/items/gear/armor_exo.png"
	},
	"armor_nano": {
		"name": "Nanoweave Suit",
		"description": "Self-repairing nanomaterial. Legendary protection.",
		"width": 2, "height": 3,
		"armor_value": 50,
		"damage_reduction": 0.45,
		"bonus_defense": 15,
		"bonus_health": 40,
		"bonus_speed": 2,
		"bonus_stealth": 3,
		"rarity": 4,
		"value": 8000,
		"icon": "res://assets/sprites/items/gear/armor_nano.png"
	}
}


# ==============================================================================
# HELMETS (8 items)
# ==============================================================================

const HELMET_ITEMS = {
	"helmet_cap": {
		"name": "Pilot Cap",
		"description": "Simple head covering. Better than nothing.",
		"width": 2, "height": 2,
		"armor_value": 2,
		"damage_reduction": 0.02,
		"rarity": 0,
		"value": 50,
		"icon": "res://assets/sprites/items/gear/helmet_cap.png"
	},
	"helmet_goggles": {
		"name": "Tactical Goggles",
		"description": "Enhanced visibility. Low-light capable.",
		"width": 2, "height": 1,
		"armor_value": 3,
		"damage_reduction": 0.03,
		"bonus_luck": 3,
		"rarity": 1,
		"value": 280,
		"icon": "res://assets/sprites/items/gear/helmet_goggles.png"
	},
	"helmet_mask": {
		"name": "Infiltrator Mask",
		"description": "Face-covering for covert ops. Hides identity.",
		"width": 2, "height": 2,
		"armor_value": 5,
		"damage_reduction": 0.05,
		"bonus_stealth": 5,
		"rarity": 1,
		"value": 400,
		"icon": "res://assets/sprites/items/gear/helmet_mask.png"
	},
	"helmet_combat": {
		"name": "Combat Helmet",
		"description": "Standard ballistic helmet. Reliable protection.",
		"width": 2, "height": 2,
		"armor_value": 12,
		"damage_reduction": 0.10,
		"bonus_defense": 3,
		"rarity": 1,
		"value": 350,
		"icon": "res://assets/sprites/items/gear/helmet_combat.png"
	},
	"helmet_tactical": {
		"name": "Tactical Helmet",
		"description": "Full-coverage tactical headgear with HUD.",
		"width": 2, "height": 2,
		"armor_value": 18,
		"damage_reduction": 0.12,
		"bonus_defense": 4,
		"bonus_luck": 2,
		"rarity": 2,
		"value": 800,
		"icon": "res://assets/sprites/items/gear/helmet_tactical.png"
	},
	"helmet_riot": {
		"name": "Riot Helmet",
		"description": "Heavy-duty face shield. Maximum head protection.",
		"width": 2, "height": 2,
		"armor_value": 25,
		"damage_reduction": 0.18,
		"bonus_defense": 6,
		"bonus_health": 10,
		"rarity": 2,
		"value": 900,
		"icon": "res://assets/sprites/items/gear/helmet_riot.png"
	},
	"helmet_power": {
		"name": "Power Helm",
		"description": "Powered helmet with integrated systems.",
		"width": 2, "height": 2,
		"armor_value": 30,
		"damage_reduction": 0.22,
		"bonus_defense": 8,
		"bonus_health": 15,
		"bonus_attack": 3,
		"rarity": 3,
		"value": 2200,
		"icon": "res://assets/sprites/items/gear/helmet_power.png"
	},
	"helmet_neural": {
		"name": "Neural Interface Helm",
		"description": "Direct neural link. Enhanced reflexes and awareness.",
		"width": 2, "height": 2,
		"armor_value": 22,
		"damage_reduction": 0.15,
		"bonus_defense": 5,
		"bonus_speed": 4,
		"bonus_luck": 5,
		"bonus_attack": 4,
		"rarity": 4,
		"value": 5000,
		"icon": "res://assets/sprites/items/gear/helmet_neural.png"
	}
}


# ==============================================================================
# ACCESSORIES (10 items)
# ==============================================================================

const ACCESSORY_ITEMS = {
	"acc_ring_luck": {
		"name": "Lucky Ring",
		"description": "A ring said to bring fortune to its wearer.",
		"width": 1, "height": 1,
		"bonus_luck": 5,
		"rarity": 1,
		"value": 300,
		"icon": "res://assets/sprites/items/gear/acc_ring_luck.png"
	},
	"acc_ring_speed": {
		"name": "Ring of Swiftness",
		"description": "Lightweight band that enhances agility.",
		"width": 1, "height": 1,
		"bonus_speed": 4,
		"rarity": 1,
		"value": 350,
		"icon": "res://assets/sprites/items/gear/acc_ring_speed.png"
	},
	"acc_ring_strength": {
		"name": "Ring of Power",
		"description": "Heavy iron ring. Grants unnatural strength.",
		"width": 1, "height": 1,
		"bonus_attack": 5,
		"rarity": 2,
		"value": 600,
		"icon": "res://assets/sprites/items/gear/acc_ring_strength.png"
	},
	"acc_amulet_health": {
		"name": "Vitality Pendant",
		"description": "Ancient amulet that bolsters life force.",
		"width": 1, "height": 2,
		"bonus_health": 20,
		"rarity": 2,
		"value": 700,
		"icon": "res://assets/sprites/items/gear/acc_amulet_health.png"
	},
	"acc_amulet_defense": {
		"name": "Guardian Medallion",
		"description": "Protective charm worn by bodyguards.",
		"width": 1, "height": 2,
		"bonus_defense": 6,
		"bonus_health": 10,
		"rarity": 2,
		"value": 750,
		"icon": "res://assets/sprites/items/gear/acc_amulet_defense.png"
	},
	"acc_belt_utility": {
		"name": "Utility Belt",
		"description": "Multi-tool storage belt. Always prepared.",
		"width": 2, "height": 1,
		"bonus_luck": 3,
		"bonus_speed": 2,
		"rarity": 1,
		"value": 400,
		"icon": "res://assets/sprites/items/gear/acc_belt_utility.png"
	},
	"acc_stealth_cloak": {
		"name": "Shadow Cloak",
		"description": "Darkness-weaving fabric. Blend into shadows.",
		"width": 2, "height": 2,
		"bonus_stealth": 10,
		"bonus_speed": 2,
		"rarity": 3,
		"value": 1800,
		"icon": "res://assets/sprites/items/gear/acc_stealth_cloak.png"
	},
	"acc_combat_gloves": {
		"name": "Combat Gloves",
		"description": "Reinforced tactical gloves. Better grip.",
		"width": 2, "height": 1,
		"bonus_attack": 4,
		"bonus_defense": 2,
		"rarity": 1,
		"value": 320,
		"icon": "res://assets/sprites/items/gear/acc_combat_gloves.png"
	},
	"acc_neural_link": {
		"name": "Neural Enhancer",
		"description": "Implant that boosts cognitive function.",
		"width": 1, "height": 1,
		"bonus_attack": 3,
		"bonus_speed": 3,
		"bonus_luck": 3,
		"rarity": 3,
		"value": 2000,
		"icon": "res://assets/sprites/items/gear/acc_neural_link.png"
	},
	"acc_master_band": {
		"name": "Master's Armband",
		"description": "Worn by elite operatives. Enhances all abilities.",
		"width": 1, "height": 2,
		"bonus_health": 15,
		"bonus_attack": 5,
		"bonus_defense": 5,
		"bonus_speed": 3,
		"bonus_luck": 5,
		"bonus_stealth": 5,
		"rarity": 4,
		"value": 6500,
		"icon": "res://assets/sprites/items/gear/acc_master_band.png"
	}
}


# ==============================================================================
# RELICS (8 items - unique with special abilities)
# ==============================================================================

const RELIC_ITEMS = {
	"relic_shield_gen": {
		"name": "Personal Shield Generator",
		"description": "Projects an energy barrier. Absorbs first hit.",
		"width": 2, "height": 2,
		"bonus_defense": 5,
		"bonus_health": 10,
		"special_ability": "shield_absorb",
		"ability_desc": "Blocks the first hit taken, then recharges over 30 seconds.",
		"rarity": 3,
		"value": 2500,
		"icon": "res://assets/sprites/items/gear/relic_shield_gen.png"
	},
	"relic_scanner": {
		"name": "Loot Scanner",
		"description": "Detects valuable items through walls.",
		"width": 1, "height": 2,
		"bonus_luck": 8,
		"special_ability": "reveal_loot",
		"ability_desc": "Highlights containers with rare items on minimap.",
		"rarity": 2,
		"value": 1200,
		"icon": "res://assets/sprites/items/gear/relic_scanner.png"
	},
	"relic_cloaking": {
		"name": "Cloaking Device",
		"description": "Bends light around the user. Brief invisibility.",
		"width": 2, "height": 2,
		"bonus_stealth": 12,
		"special_ability": "cloak",
		"ability_desc": "Become invisible for 5 seconds. 45 second cooldown.",
		"rarity": 4,
		"value": 5500,
		"icon": "res://assets/sprites/items/gear/relic_cloaking.png"
	},
	"relic_medkit": {
		"name": "Auto-Med Injector",
		"description": "Emergency medical system. Heals when critical.",
		"width": 1, "height": 2,
		"bonus_health": 25,
		"special_ability": "auto_heal",
		"ability_desc": "Automatically heals 30% HP when below 20% health. 60s cooldown.",
		"rarity": 3,
		"value": 2800,
		"icon": "res://assets/sprites/items/gear/relic_medkit.png"
	},
	"relic_luck_charm": {
		"name": "Four-Leaf Quantum Clover",
		"description": "Probability manipulation device. Impossible luck.",
		"width": 1, "height": 1,
		"bonus_luck": 15,
		"special_ability": "double_loot",
		"ability_desc": "10% chance to double loot from containers.",
		"rarity": 4,
		"value": 4000,
		"icon": "res://assets/sprites/items/gear/relic_luck_charm.png"
	},
	"relic_ammo_gen": {
		"name": "Ammo Fabricator",
		"description": "Nanomachine ammo generator. Never run out.",
		"width": 2, "height": 2,
		"bonus_attack": 3,
		"special_ability": "ammo_regen",
		"ability_desc": "Regenerates 1 ammo every 10 seconds for equipped weapon.",
		"rarity": 3,
		"value": 2200,
		"icon": "res://assets/sprites/items/gear/relic_ammo_gen.png"
	},
	"relic_speed_boost": {
		"name": "Adrenaline Pump",
		"description": "Cybernetic enhancement for bursts of speed.",
		"width": 1, "height": 2,
		"bonus_speed": 5,
		"bonus_attack": 3,
		"special_ability": "sprint_burst",
		"ability_desc": "Triple movement speed for 3 seconds. 30s cooldown.",
		"rarity": 2,
		"value": 1500,
		"icon": "res://assets/sprites/items/gear/relic_speed_boost.png"
	},
	"relic_ancient": {
		"name": "Precursor Artifact",
		"description": "Ancient alien relic. Its power is overwhelming.",
		"width": 2, "height": 2,
		"bonus_health": 30,
		"bonus_attack": 8,
		"bonus_defense": 8,
		"bonus_speed": 4,
		"bonus_luck": 8,
		"bonus_stealth": 5,
		"special_ability": "precursor_power",
		"ability_desc": "All stats enhanced. Enemies fear your presence.",
		"rarity": 4,
		"value": 10000,
		"icon": "res://assets/sprites/items/gear/relic_ancient.png"
	}
}


# ==============================================================================
# AMMO TYPES (6 types)
# ==============================================================================

const AMMO_ITEMS = {
	"ammo_bullet": {
		"name": "Bullet Pack",
		"description": "Standard ammunition for ballistic weapons.",
		"width": 1, "height": 1,
		"ammo_type": 1,  # BULLET
		"amount": 30,
		"max_stack": 300,
		"rarity": 0,
		"value": 20,
		"icon": "res://assets/sprites/items/ammo/ammo_bullet.png"
	},
	"ammo_shell": {
		"name": "Shotgun Shells",
		"description": "12-gauge buckshot rounds.",
		"width": 1, "height": 1,
		"ammo_type": 2,  # SHELL
		"amount": 12,
		"max_stack": 100,
		"rarity": 0,
		"value": 35,
		"icon": "res://assets/sprites/items/ammo/ammo_shell.png"
	},
	"ammo_energy": {
		"name": "Energy Cells",
		"description": "Power cells for energy weapons.",
		"width": 1, "height": 1,
		"ammo_type": 3,  # ENERGY_CELL
		"amount": 25,
		"max_stack": 200,
		"rarity": 1,
		"value": 50,
		"icon": "res://assets/sprites/items/ammo/ammo_energy.png"
	},
	"ammo_plasma": {
		"name": "Plasma Cells",
		"description": "Superheated plasma canisters.",
		"width": 1, "height": 2,
		"ammo_type": 4,  # PLASMA_CELL
		"amount": 15,
		"max_stack": 100,
		"rarity": 2,
		"value": 80,
		"icon": "res://assets/sprites/items/ammo/ammo_plasma.png"
	},
	"ammo_rocket": {
		"name": "Rockets",
		"description": "Explosive projectiles for launchers.",
		"width": 1, "height": 2,
		"ammo_type": 5,  # ROCKET
		"amount": 3,
		"max_stack": 20,
		"rarity": 2,
		"value": 150,
		"icon": "res://assets/sprites/items/ammo/ammo_rocket.png"
	},
	"ammo_arrow": {
		"name": "Arrows",
		"description": "Aerodynamic projectiles. Silent but deadly.",
		"width": 1, "height": 2,
		"ammo_type": 6,  # ARROW
		"amount": 10,
		"max_stack": 50,
		"rarity": 1,
		"value": 40,
		"icon": "res://assets/sprites/items/ammo/ammo_arrow.png"
	}
}


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

## Get all armor IDs
static func get_armor_ids() -> Array:
	return ARMOR_ITEMS.keys()


## Get all helmet IDs
static func get_helmet_ids() -> Array:
	return HELMET_ITEMS.keys()


## Get all accessory IDs
static func get_accessory_ids() -> Array:
	return ACCESSORY_ITEMS.keys()


## Get all relic IDs
static func get_relic_ids() -> Array:
	return RELIC_ITEMS.keys()


## Get all ammo IDs
static func get_ammo_ids() -> Array:
	return AMMO_ITEMS.keys()


## Get gear data by ID
static func get_gear_data(gear_id: String) -> Dictionary:
	if ARMOR_ITEMS.has(gear_id):
		return ARMOR_ITEMS[gear_id]
	if HELMET_ITEMS.has(gear_id):
		return HELMET_ITEMS[gear_id]
	if ACCESSORY_ITEMS.has(gear_id):
		return ACCESSORY_ITEMS[gear_id]
	if RELIC_ITEMS.has(gear_id):
		return RELIC_ITEMS[gear_id]
	if AMMO_ITEMS.has(gear_id):
		return AMMO_ITEMS[gear_id]
	return {}


## Get equipment type for a gear ID
static func get_gear_type(gear_id: String) -> EquipmentData.EquipmentType:
	if ARMOR_ITEMS.has(gear_id):
		return EquipmentData.EquipmentType.ARMOR
	if HELMET_ITEMS.has(gear_id):
		return EquipmentData.EquipmentType.HELMET
	if ACCESSORY_ITEMS.has(gear_id):
		return EquipmentData.EquipmentType.ACCESSORY
	if RELIC_ITEMS.has(gear_id):
		return EquipmentData.EquipmentType.RELIC
	if AMMO_ITEMS.has(gear_id):
		return EquipmentData.EquipmentType.AMMO
	return EquipmentData.EquipmentType.NONE


## Create EquipmentData resource from gear ID
static func create_gear_resource(gear_id: String) -> EquipmentData:
	var data = get_gear_data(gear_id)
	if data.is_empty():
		return null
	
	var gear = EquipmentData.new()
	gear.id = gear_id
	gear.name = data.get("name", "Unknown Gear")
	gear.description = data.get("description", "")
	gear.grid_width = data.get("width", 2)
	gear.grid_height = data.get("height", 2)
	gear.rarity = data.get("rarity", 0)
	gear.base_value = data.get("value", 100)
	gear.equipment_type = get_gear_type(gear_id)
	
	# Armor stats
	gear.armor_value = data.get("armor_value", 0)
	gear.damage_reduction = data.get("damage_reduction", 0.0)
	
	# Stat bonuses
	gear.bonus_health = data.get("bonus_health", 0)
	gear.bonus_attack = data.get("bonus_attack", 0)
	gear.bonus_defense = data.get("bonus_defense", 0)
	gear.bonus_speed = data.get("bonus_speed", 0)
	gear.bonus_luck = data.get("bonus_luck", 0)
	gear.bonus_stealth = data.get("bonus_stealth", 0)
	
	# Special ability (for relics)
	gear.special_ability_id = data.get("special_ability", "")
	gear.ability_description = data.get("ability_desc", "")
	
	# Ammo specific
	if gear.equipment_type == EquipmentData.EquipmentType.AMMO:
		gear.ammo_type = data.get("ammo_type", EquipmentData.AmmoType.NONE)
		gear.ammo_amount = data.get("amount", 1)
		gear.max_ammo_stack = data.get("max_stack", 100)
	
	# Calculate EXP value
	gear.exp_value = gear.calculate_exp_value()
	
	# Try to load icon
	if data.has("icon") and ResourceLoader.exists(data.icon):
		gear.icon = load(data.icon)
	
	return gear


## Get random gear by type and rarity range
static func get_random_gear(
	gear_type: EquipmentData.EquipmentType,
	min_rarity: int = 0,
	max_rarity: int = 4
) -> String:
	var pool = []
	var source: Dictionary
	
	match gear_type:
		EquipmentData.EquipmentType.ARMOR:
			source = ARMOR_ITEMS
		EquipmentData.EquipmentType.HELMET:
			source = HELMET_ITEMS
		EquipmentData.EquipmentType.ACCESSORY:
			source = ACCESSORY_ITEMS
		EquipmentData.EquipmentType.RELIC:
			source = RELIC_ITEMS
		EquipmentData.EquipmentType.AMMO:
			source = AMMO_ITEMS
		_:
			return ""
	
	for id in source:
		var r = source[id].get("rarity", 0)
		if r >= min_rarity and r <= max_rarity:
			pool.append(id)
	
	if pool.is_empty():
		return ""
	
	return pool[randi() % pool.size()]


## Get all gear by rarity
static func get_gear_by_rarity(rarity: int) -> Array:
	var result = []
	
	for collection in [ARMOR_ITEMS, HELMET_ITEMS, ACCESSORY_ITEMS, RELIC_ITEMS]:
		for id in collection:
			if collection[id].get("rarity", 0) == rarity:
				result.append(id)
	
	return result
