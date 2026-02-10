# ==============================================================================
# CONTAINER TYPES - DEFINES ALL CONTAINER VARIATIONS AND THEIR PROPERTIES
# ==============================================================================
#
# FILE: scripts/data/container_types.gd
# PURPOSE: Data definitions for different container types with loot modifiers
#
# CONTAINER TYPES:
# - Scrap Pile: Fast search, mostly common junk
# - Cargo Crate: Standard container, mixed loot
# - Locker: Personal storage, better valuables
# - Supply Cabinet: Wall mount, components/supplies
# - Vault: Secured, rare/epic items
# - Armory: Weapons/modules focus
# - Secure Cache: Hidden, epic/legendary
#
# ==============================================================================

class_name ContainerTypes
extends RefCounted


# ==============================================================================
# ENUMS
# ==============================================================================

enum Type {
	SCRAP_PILE,
	CARGO_CRATE,
	LOCKER,
	SUPPLY_CABINET,
	VAULT,
	ARMORY,
	SECURE_CACHE,
	GEAR_LOCKER,
	WEAPONS_CACHE
}

enum ItemCategory {
	SCRAP,
	COMPONENT,
	VALUABLE,
	MODULE,
	ARTIFACT
}


# ==============================================================================
# CONTAINER DATA STRUCTURE
# ==============================================================================

class ContainerData:
	var type: Type
	var display_name: String
	var description: String
	
	# Search timing
	var search_time_modifier: float = 1.0  # Multiplier on item search times
	
	# Item slots
	var min_slots: int = 2
	var max_slots: int = 4
	
	# Rarity weight modifiers (multiply base weights)
	var rarity_modifiers: Dictionary = {
		0: 1.0,  # Common
		1: 1.0,  # Uncommon
		2: 1.0,  # Rare
		3: 1.0,  # Epic
		4: 1.0   # Legendary
	}
	
	# Category affinity weights (higher = more likely)
	var category_weights: Dictionary = {
		ItemCategory.SCRAP: 1.0,
		ItemCategory.COMPONENT: 1.0,
		ItemCategory.VALUABLE: 1.0,
		ItemCategory.MODULE: 1.0,
		ItemCategory.ARTIFACT: 1.0
	}
	
	# Visual properties
	var sprite_path: String = ""
	var sprite_open_path: String = ""
	var glow_color: Color = Color.TRANSPARENT
	var base_color: Color = Color(0.4, 0.4, 0.4)
	
	# Size in pixels
	var sprite_size: Vector2 = Vector2(48, 48)
	
	func _init(
		p_type: Type,
		p_name: String,
		p_desc: String = ""
	) -> void:
		type = p_type
		display_name = p_name
		description = p_desc


# ==============================================================================
# CONTAINER DEFINITIONS
# ==============================================================================

static var _containers: Dictionary = {}
static var _initialized: bool = false


static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_define_containers()


static func _define_containers() -> void:
	# -------------------------------------------------------------------------
	# SCRAP PILE - Fast search, mostly junk
	# -------------------------------------------------------------------------
	var scrap = ContainerData.new(
		Type.SCRAP_PILE,
		"Scrap Pile",
		"A pile of debris and discarded parts. Quick to search but rarely valuable."
	)
	scrap.search_time_modifier = 0.7
	scrap.min_slots = 2
	scrap.max_slots = 4
	scrap.rarity_modifiers = {
		0: 2.0,   # Common x2
		1: 1.0,   # Uncommon normal
		2: 0.3,   # Rare reduced
		3: 0.1,   # Epic very rare
		4: 0.0    # Legendary impossible
	}
	scrap.category_weights = {
		ItemCategory.SCRAP: 5.0,
		ItemCategory.COMPONENT: 2.0,
		ItemCategory.VALUABLE: 0.1,
		ItemCategory.MODULE: 0.0,
		ItemCategory.ARTIFACT: 0.0
	}
	scrap.sprite_path = "res://assets/sprites/containers/scrap_pile.svg"
	scrap.base_color = Color(0.45, 0.35, 0.25)
	scrap.sprite_size = Vector2(48, 48)
	_containers[Type.SCRAP_PILE] = scrap
	
	# -------------------------------------------------------------------------
	# CARGO CRATE - Standard container
	# -------------------------------------------------------------------------
	var crate = ContainerData.new(
		Type.CARGO_CRATE,
		"Cargo Crate",
		"Standard shipping container. Could contain anything."
	)
	crate.search_time_modifier = 1.0
	crate.min_slots = 3
	crate.max_slots = 5
	crate.rarity_modifiers = {
		0: 1.2,   # Common slightly up
		1: 1.2,   # Uncommon slightly up
		2: 0.8,   # Rare reduced
		3: 0.4,   # Epic rare
		4: 0.1    # Legendary very rare
	}
	crate.category_weights = {
		ItemCategory.SCRAP: 3.0,
		ItemCategory.COMPONENT: 4.0,
		ItemCategory.VALUABLE: 2.0,
		ItemCategory.MODULE: 1.0,
		ItemCategory.ARTIFACT: 0.1
	}
	crate.sprite_path = "res://assets/sprites/containers/cargo_crate.svg"
	crate.base_color = Color(0.35, 0.38, 0.42)
	crate.sprite_size = Vector2(48, 48)
	_containers[Type.CARGO_CRATE] = crate
	
	# -------------------------------------------------------------------------
	# LOCKER - Personal storage, better valuables
	# -------------------------------------------------------------------------
	var locker = ContainerData.new(
		Type.LOCKER,
		"Locker",
		"Personal storage locker. Often contains valuable personal items."
	)
	locker.search_time_modifier = 1.2
	locker.min_slots = 2
	locker.max_slots = 4
	locker.rarity_modifiers = {
		0: 0.8,   # Common reduced
		1: 1.5,   # Uncommon boosted
		2: 1.2,   # Rare boosted
		3: 0.6,   # Epic moderate
		4: 0.2    # Legendary possible
	}
	locker.category_weights = {
		ItemCategory.SCRAP: 1.0,
		ItemCategory.COMPONENT: 2.0,
		ItemCategory.VALUABLE: 4.0,
		ItemCategory.MODULE: 3.0,
		ItemCategory.ARTIFACT: 1.0
	}
	locker.sprite_path = "res://assets/sprites/containers/locker.svg"
	locker.glow_color = Color(0.3, 0.5, 0.8, 0.3)
	locker.base_color = Color(0.3, 0.35, 0.45)
	locker.sprite_size = Vector2(32, 48)
	_containers[Type.LOCKER] = locker
	
	# -------------------------------------------------------------------------
	# SUPPLY CABINET - Components and supplies
	# -------------------------------------------------------------------------
	var cabinet = ContainerData.new(
		Type.SUPPLY_CABINET,
		"Supply Cabinet",
		"Wall-mounted supply cabinet. Usually stocked with useful components."
	)
	cabinet.search_time_modifier = 1.0
	cabinet.min_slots = 2
	cabinet.max_slots = 3
	cabinet.rarity_modifiers = {
		0: 1.0,   # Common normal
		1: 1.5,   # Uncommon boosted
		2: 1.0,   # Rare normal
		3: 0.3,   # Epic rare
		4: 0.1    # Legendary very rare
	}
	cabinet.category_weights = {
		ItemCategory.SCRAP: 2.0,
		ItemCategory.COMPONENT: 5.0,
		ItemCategory.VALUABLE: 1.0,
		ItemCategory.MODULE: 2.0,
		ItemCategory.ARTIFACT: 0.1
	}
	cabinet.sprite_path = "res://assets/sprites/containers/supply_cabinet.svg"
	cabinet.base_color = Color(0.85, 0.85, 0.9)
	cabinet.sprite_size = Vector2(32, 32)
	_containers[Type.SUPPLY_CABINET] = cabinet
	
	# -------------------------------------------------------------------------
	# VAULT - Secured, rare/epic items
	# -------------------------------------------------------------------------
	var vault = ContainerData.new(
		Type.VAULT,
		"Vault",
		"Reinforced secure container. Takes longer to crack but worth it."
	)
	vault.search_time_modifier = 1.8
	vault.min_slots = 3
	vault.max_slots = 6
	vault.rarity_modifiers = {
		0: 0.3,   # Common rare
		1: 0.6,   # Uncommon reduced
		2: 1.5,   # Rare boosted
		3: 1.5,   # Epic boosted
		4: 0.8    # Legendary good chance
	}
	vault.category_weights = {
		ItemCategory.SCRAP: 0.1,
		ItemCategory.COMPONENT: 2.0,
		ItemCategory.VALUABLE: 5.0,
		ItemCategory.MODULE: 3.0,
		ItemCategory.ARTIFACT: 4.0
	}
	vault.sprite_path = "res://assets/sprites/containers/vault.svg"
	vault.glow_color = Color(0.9, 0.75, 0.3, 0.4)
	vault.base_color = Color(0.6, 0.6, 0.65)
	vault.sprite_size = Vector2(48, 48)
	_containers[Type.VAULT] = vault
	
	# -------------------------------------------------------------------------
	# ARMORY - Weapons and modules
	# -------------------------------------------------------------------------
	var armory = ContainerData.new(
		Type.ARMORY,
		"Armory",
		"Weapons and equipment storage. High chance for military-grade modules."
	)
	armory.search_time_modifier = 1.5
	armory.min_slots = 2
	armory.max_slots = 4
	armory.rarity_modifiers = {
		0: 0.5,   # Common reduced
		1: 0.8,   # Uncommon reduced
		2: 1.2,   # Rare boosted
		3: 1.5,   # Epic boosted
		4: 0.5    # Legendary moderate
	}
	armory.category_weights = {
		ItemCategory.SCRAP: 0.1,
		ItemCategory.COMPONENT: 3.0,
		ItemCategory.VALUABLE: 1.0,
		ItemCategory.MODULE: 5.0,
		ItemCategory.ARTIFACT: 2.0
	}
	armory.sprite_path = "res://assets/sprites/containers/armory.svg"
	armory.glow_color = Color(0.8, 0.2, 0.2, 0.4)
	armory.base_color = Color(0.35, 0.25, 0.25)
	armory.sprite_size = Vector2(48, 48)
	_containers[Type.ARMORY] = armory
	
	# -------------------------------------------------------------------------
	# SECURE CACHE - Hidden, epic/legendary
	# -------------------------------------------------------------------------
	var cache = ContainerData.new(
		Type.SECURE_CACHE,
		"Secure Cache",
		"Hidden high-security container. Encrypted and well-protected."
	)
	cache.search_time_modifier = 2.5
	cache.min_slots = 1
	cache.max_slots = 3
	cache.rarity_modifiers = {
		0: 0.1,   # Common almost none
		1: 0.3,   # Uncommon rare
		2: 0.8,   # Rare moderate
		3: 1.8,   # Epic very boosted
		4: 1.5    # Legendary boosted
	}
	cache.category_weights = {
		ItemCategory.SCRAP: 0.0,
		ItemCategory.COMPONENT: 1.0,
		ItemCategory.VALUABLE: 4.0,
		ItemCategory.MODULE: 4.0,
		ItemCategory.ARTIFACT: 5.0
	}
	cache.sprite_path = "res://assets/sprites/containers/secure_cache.svg"
	cache.glow_color = Color(0.0, 0.9, 0.9, 0.5)
	cache.base_color = Color(0.1, 0.12, 0.15)
	cache.sprite_size = Vector2(32, 32)
	_containers[Type.SECURE_CACHE] = cache
	
	# -------------------------------------------------------------------------
	# GEAR LOCKER - Armor, helmets, accessories
	# -------------------------------------------------------------------------
	var gear_locker = ContainerData.new(
		Type.GEAR_LOCKER,
		"Gear Locker",
		"Equipment storage for armor and accessories. May contain protective gear."
	)
	gear_locker.search_time_modifier = 1.3
	gear_locker.min_slots = 2
	gear_locker.max_slots = 4
	gear_locker.rarity_modifiers = {
		0: 0.6,   # Common reduced
		1: 1.2,   # Uncommon boosted
		2: 1.5,   # Rare boosted
		3: 1.0,   # Epic moderate
		4: 0.4    # Legendary rare
	}
	gear_locker.category_weights = {
		ItemCategory.SCRAP: 0.5,
		ItemCategory.COMPONENT: 1.0,
		ItemCategory.VALUABLE: 2.0,
		ItemCategory.MODULE: 4.0,   # Armor counts as module
		ItemCategory.ARTIFACT: 2.0  # Relics
	}
	gear_locker.sprite_path = "res://assets/sprites/containers/gear_locker.svg"
	gear_locker.glow_color = Color(0.3, 0.7, 0.9, 0.4)
	gear_locker.base_color = Color(0.25, 0.35, 0.45)
	gear_locker.sprite_size = Vector2(48, 64)
	_containers[Type.GEAR_LOCKER] = gear_locker
	
	# -------------------------------------------------------------------------
	# WEAPONS CACHE - Weapons and ammo
	# -------------------------------------------------------------------------
	var weapons = ContainerData.new(
		Type.WEAPONS_CACHE,
		"Weapons Cache",
		"Hidden weapons stash. Contains firearms, melee weapons, and ammunition."
	)
	weapons.search_time_modifier = 1.4
	weapons.min_slots = 2
	weapons.max_slots = 5
	weapons.rarity_modifiers = {
		0: 0.8,   # Common reduced
		1: 1.0,   # Uncommon normal
		2: 1.3,   # Rare boosted
		3: 1.2,   # Epic boosted
		4: 0.6    # Legendary moderate
	}
	weapons.category_weights = {
		ItemCategory.SCRAP: 0.2,
		ItemCategory.COMPONENT: 2.0,   # Ammo
		ItemCategory.VALUABLE: 0.5,
		ItemCategory.MODULE: 5.0,      # Weapons
		ItemCategory.ARTIFACT: 1.0
	}
	weapons.sprite_path = "res://assets/sprites/containers/weapons_cache.svg"
	weapons.glow_color = Color(0.9, 0.3, 0.2, 0.4)
	weapons.base_color = Color(0.35, 0.2, 0.2)
	weapons.sprite_size = Vector2(48, 48)
	_containers[Type.WEAPONS_CACHE] = weapons


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Get container data by type
static func get_container(type: Type) -> ContainerData:
	_ensure_initialized()
	return _containers.get(type)


## Get all container types
static func get_all_types() -> Array[Type]:
	_ensure_initialized()
	var types: Array[Type] = []
	for key in _containers.keys():
		types.append(key as Type)
	return types


## Get container display name
static func get_name(type: Type) -> String:
	var data = get_container(type)
	return data.display_name if data else "Unknown"


## Get search time modifier for container
static func get_search_modifier(type: Type) -> float:
	var data = get_container(type)
	return data.search_time_modifier if data else 1.0


## Get slot range for container
static func get_slot_range(type: Type) -> Vector2i:
	var data = get_container(type)
	if data:
		return Vector2i(data.min_slots, data.max_slots)
	return Vector2i(2, 4)


## Get rarity modifier for container
static func get_rarity_modifier(type: Type, rarity: int) -> float:
	var data = get_container(type)
	if data:
		return data.rarity_modifiers.get(rarity, 1.0)
	return 1.0


## Get category weight for container
static func get_category_weight(type: Type, category: ItemCategory) -> float:
	var data = get_container(type)
	if data:
		return data.category_weights.get(category, 1.0)
	return 1.0


## Roll a random container type based on rarity weights
## Higher tier containers are rarer
static func roll_container_type(ship_tier: int = 1) -> Type:
	_ensure_initialized()
	
	# Weights for each container type by ship tier
	# Higher tiers have better containers
	var weights: Dictionary = {}
	
	match ship_tier:
		1:  # Cargo Shuttle - mostly scrap and crates
			weights = {
				Type.SCRAP_PILE: 40,
				Type.CARGO_CRATE: 40,
				Type.LOCKER: 10,
				Type.SUPPLY_CABINET: 5,
				Type.VAULT: 0,
				Type.ARMORY: 0,
				Type.SECURE_CACHE: 0,
				Type.GEAR_LOCKER: 3,
				Type.WEAPONS_CACHE: 2
			}
		2:  # Freight Hauler - introduces lockers
			weights = {
				Type.SCRAP_PILE: 22,
				Type.CARGO_CRATE: 35,
				Type.LOCKER: 18,
				Type.SUPPLY_CABINET: 10,
				Type.VAULT: 4,
				Type.ARMORY: 1,
				Type.SECURE_CACHE: 0,
				Type.GEAR_LOCKER: 6,
				Type.WEAPONS_CACHE: 4
			}
		3:  # Corporate Transport - introduces vaults
			weights = {
				Type.SCRAP_PILE: 8,
				Type.CARGO_CRATE: 25,
				Type.LOCKER: 20,
				Type.SUPPLY_CABINET: 12,
				Type.VAULT: 12,
				Type.ARMORY: 6,
				Type.SECURE_CACHE: 2,
				Type.GEAR_LOCKER: 8,
				Type.WEAPONS_CACHE: 7
			}
		4:  # Military Frigate - armory and weapons focus
			weights = {
				Type.SCRAP_PILE: 4,
				Type.CARGO_CRATE: 15,
				Type.LOCKER: 15,
				Type.SUPPLY_CABINET: 12,
				Type.VAULT: 12,
				Type.ARMORY: 15,
				Type.SECURE_CACHE: 7,
				Type.GEAR_LOCKER: 10,
				Type.WEAPONS_CACHE: 10
			}
		5, _:  # Black Ops - secure cache and weapons focus
			weights = {
				Type.SCRAP_PILE: 2,
				Type.CARGO_CRATE: 8,
				Type.LOCKER: 10,
				Type.SUPPLY_CABINET: 8,
				Type.VAULT: 15,
				Type.ARMORY: 15,
				Type.SECURE_CACHE: 17,
				Type.GEAR_LOCKER: 12,
				Type.WEAPONS_CACHE: 13
			}
	
	# Calculate total weight
	var total: float = 0.0
	for w in weights.values():
		total += w
	
	# Roll
	var roll = randf() * total
	var cumulative: float = 0.0
	
	for type in weights.keys():
		cumulative += weights[type]
		if roll <= cumulative:
			return type
	
	return Type.CARGO_CRATE  # Fallback
