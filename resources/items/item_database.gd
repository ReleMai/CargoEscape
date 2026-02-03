# ==============================================================================
# COMPREHENSIVE ITEM DATABASE WITH FULL METADATA
# ==============================================================================
#
# FILE: resources/items/item_database.gd
# PURPOSE: Complete item definitions with all metadata properties
#
# This file extends the existing item_database.gd with enhanced metadata:
# - Tags for classification
# - Weight (kg) for inventory capacity
# - Base value and black market value
# - Faction affinity and restrictions
# - Spawn weights for loot tables
# - Stack sizes
# - Icon paths
#
# ==============================================================================

class_name ComprehensiveItemDatabase
extends RefCounted


# ==============================================================================
# RARITY ENUM
# ==============================================================================

enum Rarity {
	COMMON = 0,
	UNCOMMON = 1,
	RARE = 2,
	EPIC = 3,
	LEGENDARY = 4
}


# ==============================================================================
# COMPREHENSIVE ITEM DEFINITIONS
# ==============================================================================

## Get comprehensive item definition with all metadata
static func get_comprehensive_item_data(item_id: String) -> Dictionary:
	var items = get_all_comprehensive_items()
	return items.get(item_id, {})


## Get all comprehensive item definitions
static func get_all_comprehensive_items() -> Dictionary:
	var items = {}
	
	# Merge all categories
	items.merge(_get_scrap_items())
	items.merge(_get_component_items())
	items.merge(_get_valuable_items())
	items.merge(_get_epic_items())
	items.merge(_get_legendary_items())
	items.merge(_get_module_items())
	items.merge(_get_keycard_items())
	
	return items


# ==============================================================================
# SCRAP ITEMS (COMMON)
# ==============================================================================

static func _get_scrap_items() -> Dictionary:
	return {
		"scrap_metal": {
			"name": "Scrap Metal",
			"id": "scrap_metal",
			"description": "Salvaged hull plating and structural debris. Common but useful for repairs.",
			"tags": ["scrap", "metal", "recyclable"],
			"weight": 5.0,
			"base_value": 15,
			"black_market_value": 12,  # Less valuable on black market
			"rarity": Rarity.COMMON,
			"faction_affinity": -1,  # Universal
			"faction_restricted": [],
			"spawn_weight": 2.0,  # Very common
			"stack_size": 50,
			"icon_path": "res://assets/sprites/items/scrap_metal.svg",
			"width": 1,
			"height": 1,
			"category": 0  # SCRAP
		},
		
		"scrap_plastics": {
			"name": "Scrap Plastics",
			"id": "scrap_plastics",
			"description": "Assorted synthetic polymers. Lightweight and recyclable.",
			"tags": ["scrap", "plastic", "lightweight"],
			"weight": 1.5,
			"base_value": 10,
			"black_market_value": 8,
			"rarity": Rarity.COMMON,
			"faction_affinity": -1,
			"faction_restricted": [],
			"spawn_weight": 2.0,
			"stack_size": 99,
			"icon_path": "res://assets/sprites/items/scrap_plastics.svg",
			"width": 1,
			"height": 1,
			"category": 0
		},
		
		"scrap_electronics": {
			"name": "Scrap Electronics",
			"id": "scrap_electronics",
			"description": "Broken circuit boards and components. Contains trace precious metals.",
			"tags": ["scrap", "electronics", "recyclable", "tech"],
			"weight": 2.0,
			"base_value": 35,
			"black_market_value": 40,  # Slightly more on black market
			"rarity": Rarity.COMMON,
			"faction_affinity": 1,  # NEX (Nexus Corp)
			"faction_restricted": [],
			"spawn_weight": 1.5,
			"stack_size": 25,
			"icon_path": "res://assets/sprites/items/scrap_electronics.svg",
			"width": 1,
			"height": 2,
			"category": 0
		},
		
		"wire_bundle": {
			"name": "Wire Bundle",
			"id": "wire_bundle",
			"description": "Tangled assortment of cables and wiring. Every ship needs spares.",
			"tags": ["scrap", "wire", "electrical"],
			"weight": 2.0,
			"base_value": 18,
			"black_market_value": 15,
			"rarity": Rarity.COMMON,
			"faction_affinity": 0,  # CCG (Civilian)
			"faction_restricted": [],
			"spawn_weight": 1.8,
			"stack_size": 30,
			"icon_path": "res://assets/sprites/items/wire_bundle.svg",
			"width": 1,
			"height": 1,
			"category": 0
		}
	}


# ==============================================================================
# COMPONENT ITEMS (UNCOMMON)
# ==============================================================================

static func _get_component_items() -> Dictionary:
	return {
		"copper_wire": {
			"name": "Copper Wire Bundle",
			"id": "copper_wire",
			"description": "High-quality copper wiring. Essential for electrical repairs.",
			"tags": ["component", "wire", "electrical", "valuable"],
			"weight": 3.0,
			"base_value": 60,
			"black_market_value": 55,
			"rarity": Rarity.UNCOMMON,
			"faction_affinity": -1,
			"faction_restricted": [],
			"spawn_weight": 1.2,
			"stack_size": 20,
			"icon_path": "res://assets/sprites/items/copper_wire.svg",
			"width": 1,
			"height": 1,
			"category": 1  # COMPONENT
		},
		
		"data_chip": {
			"name": "Data Chip",
			"id": "data_chip",
			"description": "Encrypted storage module. May contain valuable intel or corporate secrets.",
			"tags": ["component", "tech", "data", "valuable"],
			"weight": 0.2,
			"base_value": 85,
			"black_market_value": 120,  # High value on black market
			"rarity": Rarity.UNCOMMON,
			"faction_affinity": 1,  # NEX
			"faction_restricted": [],
			"spawn_weight": 1.0,
			"stack_size": 10,
			"icon_path": "res://assets/sprites/items/data_chip.svg",
			"width": 1,
			"height": 1,
			"category": 1
		},
		
		"fuel_cell": {
			"name": "Fuel Cell",
			"id": "fuel_cell",
			"description": "Compact energy storage unit. Powers small devices and emergency systems.",
			"tags": ["component", "power", "energy"],
			"weight": 4.0,
			"base_value": 120,
			"black_market_value": 110,
			"rarity": Rarity.UNCOMMON,
			"faction_affinity": -1,
			"faction_restricted": [],
			"spawn_weight": 1.0,
			"stack_size": 5,
			"icon_path": "res://assets/sprites/items/fuel_cell.svg",
			"width": 1,
			"height": 2,
			"category": 1
		},
		
		"plasma_coil": {
			"name": "Plasma Coil",
			"id": "plasma_coil",
			"description": "Magnetic containment unit for plasma engines. Dangerous if damaged.",
			"tags": ["component", "power", "dangerous", "tech"],
			"weight": 6.0,
			"base_value": 150,
			"black_market_value": 140,
			"rarity": Rarity.UNCOMMON,
			"faction_affinity": 2,  # GDF (Military)
			"faction_restricted": [],
			"spawn_weight": 0.8,
			"stack_size": 3,
			"icon_path": "res://assets/sprites/items/plasma_coil.svg",
			"width": 1,
			"height": 3,
			"category": 1
		}
	}


# ==============================================================================
# VALUABLE ITEMS (RARE)
# ==============================================================================

static func _get_valuable_items() -> Dictionary:
	return {
		"gold_bar": {
			"name": "Gold Bar",
			"id": "gold_bar",
			"description": "Pure gold ingot. Universal currency across all systems and factions.",
			"tags": ["valuable", "precious", "currency"],
			"weight": 12.0,
			"base_value": 500,
			"black_market_value": 480,  # Slightly less (harder to fence)
			"rarity": Rarity.RARE,
			"faction_affinity": 1,  # NEX
			"faction_restricted": [],
			"spawn_weight": 0.5,
			"stack_size": 10,
			"icon_path": "res://assets/sprites/items/gold_bar.svg",
			"width": 2,
			"height": 1,
			"category": 2  # VALUABLE
		},
		
		"weapon_core": {
			"name": "Weapon Core",
			"id": "weapon_core",
			"description": "Power source for military-grade armaments. Heavily regulated and illegal in civilian sectors.",
			"tags": ["valuable", "weapon", "military", "illegal", "dangerous"],
			"weight": 8.0,
			"base_value": 400,
			"black_market_value": 800,  # Double on black market (illegal)
			"rarity": Rarity.RARE,
			"faction_affinity": 2,  # GDF
			"faction_restricted": [0],  # Not on CCG ships
			"spawn_weight": 0.4,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/weapon_core.svg",
			"width": 2,
			"height": 2,
			"category": 2
		},
		
		"targeting_array": {
			"name": "Targeting Array",
			"id": "targeting_array",
			"description": "Military precision optics. Illegal in most sectors, highly sought after.",
			"tags": ["valuable", "weapon", "military", "illegal", "tech"],
			"weight": 3.0,
			"base_value": 320,
			"black_market_value": 650,  # Very high black market value
			"rarity": Rarity.RARE,
			"faction_affinity": 2,  # GDF
			"faction_restricted": [0],  # Not on CCG
			"spawn_weight": 0.3,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/targeting_array.svg",
			"width": 2,
			"height": 1,
			"category": 1  # COMPONENT
		},
		
		"encrypted_drive": {
			"name": "Encrypted Drive",
			"id": "encrypted_drive",
			"description": "Military-grade encrypted storage. Could contain corporate or government secrets.",
			"tags": ["valuable", "data", "tech", "illegal"],
			"weight": 0.3,
			"base_value": 300,
			"black_market_value": 550,
			"rarity": Rarity.RARE,
			"faction_affinity": 3,  # SYN (Shadow Syndicate)
			"faction_restricted": [],
			"spawn_weight": 0.4,
			"stack_size": 5,
			"icon_path": "res://assets/sprites/items/encrypted_drive.svg",
			"width": 1,
			"height": 1,
			"category": 2
		}
	}


# ==============================================================================
# EPIC ITEMS (EPIC)
# ==============================================================================

static func _get_epic_items() -> Dictionary:
	return {
		"alien_artifact": {
			"name": "Alien Artifact",
			"id": "alien_artifact",
			"description": "Unknown origin. Emits faint energy readings. Forbidden by galactic law.",
			"tags": ["artifact", "alien", "illegal", "mysterious", "dangerous"],
			"weight": 3.0,
			"base_value": 850,
			"black_market_value": 2500,  # Extremely valuable on black market
			"rarity": Rarity.EPIC,
			"faction_affinity": 3,  # SYN
			"faction_restricted": [0, 2],  # Not on CCG or GDF ships
			"spawn_weight": 0.15,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/alien_artifact.svg",
			"width": 2,
			"height": 2,
			"category": 4  # ARTIFACT
		},
		
		"quantum_cpu": {
			"name": "Quantum CPU",
			"id": "quantum_cpu",
			"description": "Next-gen processor using quantum superposition. Corporate prototype worth a fortune.",
			"tags": ["tech", "quantum", "prototype", "illegal"],
			"weight": 0.5,
			"base_value": 650,
			"black_market_value": 1400,
			"rarity": Rarity.EPIC,
			"faction_affinity": 1,  # NEX
			"faction_restricted": [0],  # Not on CCG
			"spawn_weight": 0.2,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/quantum_cpu.svg",
			"width": 1,
			"height": 1,
			"category": 1
		},
		
		"stealth_plating": {
			"name": "Stealth Plating",
			"id": "stealth_plating",
			"description": "Radar-absorbing hull material. Military prototype, extremely illegal.",
			"tags": ["military", "prototype", "illegal", "tech"],
			"weight": 15.0,
			"base_value": 950,
			"black_market_value": 2000,
			"rarity": Rarity.EPIC,
			"faction_affinity": 3,  # SYN
			"faction_restricted": [0, 4],  # Not on CCG or IND
			"spawn_weight": 0.1,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/stealth_plating.svg",
			"width": 3,
			"height": 2,
			"category": 2
		},
		
		"void_shard": {
			"name": "Void Shard",
			"id": "void_shard",
			"description": "Fragment of collapsed star matter. Impossibly dense, otherworldly properties.",
			"tags": ["artifact", "exotic", "dangerous", "mysterious"],
			"weight": 50.0,  # Extremely heavy
			"base_value": 700,
			"black_market_value": 1600,
			"rarity": Rarity.EPIC,
			"faction_affinity": -1,
			"faction_restricted": [0],  # Too dangerous for civilian ships
			"spawn_weight": 0.12,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/void_shard.svg",
			"width": 1,
			"height": 1,
			"category": 4
		}
	}


# ==============================================================================
# LEGENDARY ITEMS (LEGENDARY)
# ==============================================================================

static func _get_legendary_items() -> Dictionary:
	return {
		"quantum_core": {
			"name": "Quantum Core",
			"id": "quantum_core",
			"description": "Unstable quantum processor. Powers interdimensional drives. One of three known to exist.",
			"tags": ["artifact", "quantum", "prototype", "illegal", "dangerous", "unique"],
			"weight": 5.0,
			"base_value": 1800,
			"black_market_value": 5000,
			"rarity": Rarity.LEGENDARY,
			"faction_affinity": 3,  # SYN
			"faction_restricted": [0, 4],  # Only on high-end ships
			"spawn_weight": 0.05,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/quantum_core.svg",
			"width": 2,
			"height": 2,
			"category": 4
		},
		
		"dark_matter_vial": {
			"name": "Dark Matter Vial",
			"id": "dark_matter_vial",
			"description": "Contained dark matter sample. Worth a fortune to scientists and collectors. Extremely unstable.",
			"tags": ["artifact", "exotic", "illegal", "dangerous", "unique"],
			"weight": 0.1,
			"base_value": 2200,
			"black_market_value": 6000,
			"rarity": Rarity.LEGENDARY,
			"faction_affinity": -1,
			"faction_restricted": [0, 4],
			"spawn_weight": 0.03,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/dark_matter_vial.svg",
			"width": 1,
			"height": 2,
			"category": 4
		},
		
		"ancient_relic": {
			"name": "Ancient Relic",
			"id": "ancient_relic",
			"description": "Precursor civilization artifact. Thousands of years old. Illegal to possess.",
			"tags": ["artifact", "alien", "ancient", "illegal", "unique", "mysterious"],
			"weight": 25.0,
			"base_value": 3500,
			"black_market_value": 10000,
			"rarity": Rarity.LEGENDARY,
			"faction_affinity": 3,  # SYN
			"faction_restricted": [0, 2],
			"spawn_weight": 0.02,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/ancient_relic.svg",
			"width": 3,
			"height": 3,
			"category": 4
		},
		
		"singularity_gem": {
			"name": "Singularity Gem",
			"id": "singularity_gem",
			"description": "Crystallized black hole energy. Radiates impossible light. Defies known physics.",
			"tags": ["artifact", "exotic", "illegal", "dangerous", "unique", "mysterious"],
			"weight": 1.0,
			"base_value": 5000,
			"black_market_value": 15000,
			"rarity": Rarity.LEGENDARY,
			"faction_affinity": -1,
			"faction_restricted": [0, 4],
			"spawn_weight": 0.01,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/singularity_gem.svg",
			"width": 2,
			"height": 2,
			"category": 4
		}
	}


# ==============================================================================
# MODULE ITEMS
# ==============================================================================

static func _get_module_items() -> Dictionary:
	return {
		"module_scanner": {
			"name": "Cargo Scanner",
			"id": "module_scanner",
			"description": "Advanced sensors that increase loot value by 15%. Utility module.",
			"tags": ["module", "utility", "tech"],
			"weight": 10.0,
			"base_value": 600,
			"black_market_value": 580,
			"rarity": Rarity.UNCOMMON,
			"faction_affinity": 1,  # NEX
			"faction_restricted": [],
			"spawn_weight": 0.6,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/module_scanner.svg",
			"width": 2,
			"height": 2,
			"category": 3  # MODULE
		},
		
		"module_shield": {
			"name": "Shield Generator",
			"id": "module_shield",
			"description": "Adds 50 max health and 10% damage reduction. Military-grade utility module.",
			"tags": ["module", "utility", "military", "defense"],
			"weight": 20.0,
			"base_value": 1000,
			"black_market_value": 1200,
			"rarity": Rarity.EPIC,
			"faction_affinity": 2,  # GDF
			"faction_restricted": [],
			"spawn_weight": 0.3,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/module_shield.svg",
			"width": 2,
			"height": 2,
			"category": 3
		}
	}


# ==============================================================================
# KEYCARD ITEMS
# ==============================================================================

static func _get_keycard_items() -> Dictionary:
	return {
		"keycard_tier1": {
			"name": "Security Keycard (Green)",
			"id": "keycard_tier1",
			"description": "Standard security keycard. Opens basic locked doors.",
			"tags": ["keycard", "tool", "key", "security", "tier1"],
			"weight": 0.05,
			"base_value": 25,
			"black_market_value": 40,
			"rarity": Rarity.COMMON,
			"faction_affinity": -1,  # Universal
			"faction_restricted": [],
			"spawn_weight": 1.5,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/keycard_green.svg",
			"width": 1,
			"height": 1,
			"category": 1  # COMPONENT
		},
		
		"keycard_tier2": {
			"name": "Security Keycard (Blue)",
			"id": "keycard_tier2",
			"description": "Enhanced security keycard. Opens mid-level secure doors.",
			"tags": ["keycard", "tool", "key", "security", "tier2"],
			"weight": 0.05,
			"base_value": 75,
			"black_market_value": 100,
			"rarity": Rarity.UNCOMMON,
			"faction_affinity": -1,  # Universal
			"faction_restricted": [],
			"spawn_weight": 1.0,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/keycard_blue.svg",
			"width": 1,
			"height": 1,
			"category": 1
		},
		
		"keycard_tier3": {
			"name": "Security Keycard (Red)",
			"id": "keycard_tier3",
			"description": "High-security keycard. Opens restricted areas and captain's quarters.",
			"tags": ["keycard", "tool", "key", "security", "tier3"],
			"weight": 0.05,
			"base_value": 150,
			"black_market_value": 200,
			"rarity": Rarity.RARE,
			"faction_affinity": -1,  # Universal
			"faction_restricted": [],
			"spawn_weight": 0.5,
			"stack_size": 1,
			"icon_path": "res://assets/sprites/items/keycard_red.svg",
			"width": 1,
			"height": 1,
			"category": 1
		}
	}


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

## Create ItemData resource from comprehensive definition
static func create_item_from_comprehensive_data(item_id: String) -> Resource:
	var def = get_comprehensive_item_data(item_id)
	if def.is_empty():
		push_error("Unknown comprehensive item ID: " + item_id)
		return null
	
	var ItemDataClass = load("res://scripts/loot/item_data.gd")
	var item = ItemDataClass.new()
	
	# Basic properties
	item.id = def.get("id", item_id)
	item.name = def.get("name", "Unknown")
	item.description = def.get("description", "")
	item.grid_width = def.get("width", 1)
	item.grid_height = def.get("height", 1)
	item.rarity = def.get("rarity", 0)
	item.category = def.get("category", 0)
	
	# New comprehensive properties
	item.tags = def.get("tags", [])
	item.weight = def.get("weight", 1.0)
	item.base_value = def.get("base_value", 50)
	item.black_market_value = def.get("black_market_value", item.base_value)
	item.faction_affinity = def.get("faction_affinity", -1)
	item.faction_restricted = def.get("faction_restricted", [])
	item.spawn_weight = def.get("spawn_weight", 1.0)
	item.stack_size = def.get("stack_size", 1)
	item.icon_path = def.get("icon_path", "")
	
	# Backward compatibility
	item.value = item.base_value
	
	# Calculate search time
	var size = item.grid_width * item.grid_height
	item.base_search_time = 1.0 + size * 0.3 + item.rarity * 0.5
	
	# Load sprite if available
	var icon_path = item.icon_path
	if icon_path != "" and ResourceLoader.exists(icon_path):
		item.sprite = load(icon_path)
	
	return item


## Get all item IDs from comprehensive database
static func get_all_item_ids() -> Array[String]:
	var ids: Array[String] = []
	var items = get_all_comprehensive_items()
	for item_id in items.keys():
		ids.append(item_id)
	return ids


## Get items by tag
static func get_items_by_tag(tag: String) -> Array[String]:
	var result: Array[String] = []
	var items = get_all_comprehensive_items()
	for item_id in items:
		var item_def = items[item_id]
		if tag in item_def.get("tags", []):
			result.append(item_id)
	return result


## Get items by rarity
static func get_items_by_rarity(rarity: int) -> Array[String]:
	var result: Array[String] = []
	var items = get_all_comprehensive_items()
	for item_id in items:
		var item_def = items[item_id]
		if item_def.get("rarity", 0) == rarity:
			result.append(item_id)
	return result


## Get items by faction affinity
static func get_items_by_faction(faction_type: int) -> Array[String]:
	var result: Array[String] = []
	var items = get_all_comprehensive_items()
	for item_id in items:
		var item_def = items[item_id]
		var affinity = item_def.get("faction_affinity", -1)
		if affinity == faction_type or affinity == -1:
			# Include if matches affinity or is universal
			var restricted = item_def.get("faction_restricted", [])
			if not (faction_type in restricted):
				result.append(item_id)
	return result
