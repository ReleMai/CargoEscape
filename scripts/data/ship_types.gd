# ==============================================================================
# SHIP TYPES - DEFINES ALL SHIP TIERS AND THEIR PROPERTIES
# ==============================================================================
#
# FILE: scripts/data/ship_types.gd
# PURPOSE: Data definitions for different ship tiers with loot and layout info
#
# SHIP TIERS:
# 1. Cargo Shuttle - Easy, common loot, 120s (smallest but still big)
# 2. Freight Hauler - Medium, uncommon focus, 150s
# 3. Corporate Transport - Medium-Hard, rare focus, 180s
# 4. Military Frigate - Hard, epic focus, 200s
# 5. Black Ops Vessel - Extreme, legendary focus, 240s
#
# SCALE NOTE:
# Ships are now MASSIVE to feel like real space vessels. Players need to
# explore and use the fog of war system to navigate. Time limits have been
# increased to compensate for the larger exploration area.
#
# ==============================================================================

class_name ShipTypes
extends RefCounted


# ==============================================================================
# ENUMS
# ==============================================================================

enum Tier {
	CARGO_SHUTTLE = 1,
	FREIGHT_HAULER = 2,
	CORPORATE_TRANSPORT = 3,
	MILITARY_FRIGATE = 4,
	BLACK_OPS_VESSEL = 5
}


# ==============================================================================
# SHIP DATA STRUCTURE
# ==============================================================================

class ShipData:
	var tier: Tier = Tier.CARGO_SHUTTLE
	var display_name: String
	var description: String
	
	# Time limit in seconds
	var time_limit: float = 90.0
	
	# Ship dimensions in pixels
	var size: Vector2 = Vector2(1200, 800)
	
	# Container spawning
	var min_containers: int = 3
	var max_containers: int = 5
	
	# Rarity weight modifiers (multiply base weights)
	var rarity_modifiers: Dictionary = {
		0: 1.0,  # Common
		1: 1.0,  # Uncommon
		2: 1.0,  # Rare
		3: 1.0,  # Epic
		4: 1.0   # Legendary
	}
	
	# Visual properties
	var hull_color: Color = Color(0.3, 0.3, 0.35)
	var accent_color: Color = Color(0.5, 0.5, 0.55)
	var interior_color: Color = Color(0.2, 0.2, 0.22)
	var lighting_tint: Color = Color.WHITE
	
	# Layout scene path (optional - for custom layouts)
	var layout_scene: String = ""
	
	# Danger level affects enemy spawns (future)
	var danger_level: int = 1
	
	func _init(p_tier: Tier, p_name: String, p_desc: String = "") -> void:
		tier = p_tier
		display_name = p_name
		description = p_desc


# ==============================================================================
# SHIP DEFINITIONS
# ==============================================================================

static var _ships: Dictionary = {}
static var _initialized: bool = false


static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_define_ships()


static func _define_ships() -> void:
	# -------------------------------------------------------------------------
	# TIER 1: CARGO SHUTTLE
	# Smallest ship but still feels substantial - like a real cargo vessel
	# -------------------------------------------------------------------------
	var shuttle = ShipData.new(
		Tier.CARGO_SHUTTLE,
		"Cargo Shuttle",
		"Small civilian cargo vessel. Easy pickings but slim rewards."
	)
	shuttle.time_limit = 120.0  # Increased for larger ship
	shuttle.size = Vector2(3200, 2400)  # ~2.5x larger than before
	shuttle.min_containers = 6
	shuttle.max_containers = 8
	shuttle.rarity_modifiers = {
		0: 1.5,   # Common boosted
		1: 0.8,   # Uncommon reduced
		2: 0.3,   # Rare rare
		3: 0.1,   # Epic very rare
		4: 0.0    # Legendary impossible
	}
	shuttle.hull_color = Color(0.55, 0.42, 0.32)  # Rust orange
	shuttle.accent_color = Color(0.75, 0.65, 0.25)  # Yellow
	shuttle.interior_color = Color(0.25, 0.22, 0.2)
	shuttle.lighting_tint = Color(1.0, 0.95, 0.85)  # Warm
	shuttle.danger_level = 1
	_ships[Tier.CARGO_SHUTTLE] = shuttle
	
	# -------------------------------------------------------------------------
	# TIER 2: FREIGHT HAULER
	# Medium-sized cargo ship with multiple cargo bays
	# -------------------------------------------------------------------------
	var hauler = ShipData.new(
		Tier.FREIGHT_HAULER,
		"Freight Hauler",
		"Commercial freight vessel. More cargo, more risk."
	)
	hauler.time_limit = 150.0  # Increased for larger ship
	hauler.size = Vector2(4200, 3000)  # ~2.5x larger
	hauler.min_containers = 10
	hauler.max_containers = 14
	hauler.rarity_modifiers = {
		0: 1.2,   # Common still common
		1: 1.2,   # Uncommon boosted
		2: 0.6,   # Rare moderate
		3: 0.2,   # Epic rare
		4: 0.05   # Legendary very rare
	}
	hauler.hull_color = Color(0.35, 0.4, 0.5)  # Blue-gray
	hauler.accent_color = Color(0.5, 0.7, 0.9)  # Light blue
	hauler.interior_color = Color(0.22, 0.24, 0.28)
	hauler.lighting_tint = Color(0.95, 0.95, 1.0)  # Neutral
	hauler.danger_level = 2
	_ships[Tier.FREIGHT_HAULER] = hauler
	
	# -------------------------------------------------------------------------
	# TIER 3: CORPORATE TRANSPORT
	# Large luxury transport with multiple decks
	# -------------------------------------------------------------------------
	var corporate = ShipData.new(
		Tier.CORPORATE_TRANSPORT,
		"Corporate Transport",
		"Luxury corporate vessel. High value cargo, tighter security."
	)
	corporate.time_limit = 180.0  # Increased for massive ship
	corporate.size = Vector2(5400, 3600)  # ~3x larger
	corporate.min_containers = 14
	corporate.max_containers = 18
	corporate.rarity_modifiers = {
		0: 0.8,   # Common reduced
		1: 1.0,   # Uncommon normal
		2: 1.2,   # Rare boosted
		3: 0.6,   # Epic moderate
		4: 0.2    # Legendary possible
	}
	corporate.hull_color = Color(0.9, 0.9, 0.92)  # White
	corporate.accent_color = Color(0.85, 0.7, 0.3)  # Gold
	corporate.interior_color = Color(0.28, 0.28, 0.3)
	corporate.lighting_tint = Color(1.0, 1.0, 1.0)  # Bright
	corporate.danger_level = 3
	_ships[Tier.CORPORATE_TRANSPORT] = corporate
	
	# -------------------------------------------------------------------------
	# TIER 4: MILITARY FRIGATE
	# Massive warship with armories and secure compartments
	# -------------------------------------------------------------------------
	var frigate = ShipData.new(
		Tier.MILITARY_FRIGATE,
		"Military Frigate",
		"Armed military vessel. Heavy firepower, high-grade equipment."
	)
	frigate.time_limit = 200.0  # Long time for huge ship
	frigate.size = Vector2(6800, 4200)  # ~3.5x larger
	frigate.min_containers = 18
	frigate.max_containers = 24
	frigate.rarity_modifiers = {
		0: 0.5,   # Common rare
		1: 0.8,   # Uncommon reduced
		2: 1.0,   # Rare normal
		3: 1.2,   # Epic boosted
		4: 0.6    # Legendary moderate
	}
	frigate.hull_color = Color(0.25, 0.27, 0.3)  # Dark gray
	frigate.accent_color = Color(0.8, 0.2, 0.15)  # Red
	frigate.interior_color = Color(0.18, 0.18, 0.2)
	frigate.lighting_tint = Color(1.0, 0.85, 0.85)  # Red tint
	frigate.danger_level = 4
	_ships[Tier.MILITARY_FRIGATE] = frigate
	
	# -------------------------------------------------------------------------
	# TIER 5: BLACK OPS VESSEL
	# Enormous classified ship - a true capital ship experience
	# -------------------------------------------------------------------------
	var blackops = ShipData.new(
		Tier.BLACK_OPS_VESSEL,
		"Black Ops Vessel",
		"Classified stealth ship. Extreme danger, legendary rewards."
	)
	blackops.time_limit = 240.0  # Extended for massive exploration
	blackops.size = Vector2(8000, 5000)  # ~4x larger - truly massive
	blackops.min_containers = 24
	blackops.max_containers = 30
	blackops.rarity_modifiers = {
		0: 0.2,   # Common very rare
		1: 0.5,   # Uncommon rare
		2: 0.8,   # Rare moderate
		3: 1.2,   # Epic boosted
		4: 1.5    # Legendary very boosted
	}
	blackops.hull_color = Color(0.08, 0.08, 0.1)  # Black
	blackops.accent_color = Color(0.0, 0.85, 0.9)  # Cyan
	blackops.interior_color = Color(0.1, 0.1, 0.12)
	blackops.lighting_tint = Color(0.8, 0.9, 1.0)  # Blue tint
	blackops.danger_level = 5
	_ships[Tier.BLACK_OPS_VESSEL] = blackops


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Get ship data by tier
static func get_ship(tier: Tier) -> ShipData:
	_ensure_initialized()
	return _ships.get(tier)


## Get ship data by tier number (1-5)
static func get_ship_by_number(tier_num: int) -> ShipData:
	_ensure_initialized()
	tier_num = clampi(tier_num, 1, 5)
	return _ships.get(tier_num as Tier)


## Get all ship tiers
static func get_all_tiers() -> Array[Tier]:
	_ensure_initialized()
	return [
		Tier.CARGO_SHUTTLE,
		Tier.FREIGHT_HAULER,
		Tier.CORPORATE_TRANSPORT,
		Tier.MILITARY_FRIGATE,
		Tier.BLACK_OPS_VESSEL
	]


## Get ship display name
static func get_name(tier: Tier) -> String:
	var data = get_ship(tier)
	return data.display_name if data else "Unknown Ship"


## Get time limit for ship tier
static func get_time_limit(tier: Tier) -> float:
	var data = get_ship(tier)
	return data.time_limit if data else 90.0


## Get rarity modifier for ship tier
static func get_rarity_modifier(tier: Tier, rarity: int) -> float:
	var data = get_ship(tier)
	if data:
		return data.rarity_modifiers.get(rarity, 1.0)
	return 1.0


## Get container count range for ship tier
static func get_container_range(tier: Tier) -> Vector2i:
	var data = get_ship(tier)
	if data:
		return Vector2i(data.min_containers, data.max_containers)
	return Vector2i(3, 5)


## Calculate effective rarity weight
## Combines base weight, ship modifier, and container modifier
static func calculate_rarity_weight(
	base_weight: float,
	rarity: int,
	ship_tier: Tier,
	container_type: int  # ContainerTypes.Type
) -> float:
	var ship_mod = get_rarity_modifier(ship_tier, rarity)
	
	# Get container modifier (using the ContainerTypes class)
	var container_mod = 1.0
	var ContainerTypesClass = load("res://scripts/data/container_types.gd")
	if ContainerTypesClass:
		container_mod = ContainerTypesClass.get_rarity_modifier(container_type, rarity)
	
	return base_weight * ship_mod * container_mod


## Roll a ship tier based on distance from hideout
## Further = higher tier = better loot but harder
## distance_factor: 0.0 = near hideout, 1.0 = far from hideout (default 0.5 = medium)
static func roll_ship_tier(distance_factor: float = 0.5) -> Tier:
	_ensure_initialized()
	
	# distance_factor: 0.0 = near hideout, 1.0 = far from hideout
	distance_factor = clampf(distance_factor, 0.0, 1.0)
	
	# Base weights (lower tier = higher base weight)
	var weights = {
		Tier.CARGO_SHUTTLE: 100,
		Tier.FREIGHT_HAULER: 60,
		Tier.CORPORATE_TRANSPORT: 30,
		Tier.MILITARY_FRIGATE: 15,
		Tier.BLACK_OPS_VESSEL: 5
	}
	
	# Distance modifies weights
	# Near hideout: boost lower tiers
	# Far from hideout: boost higher tiers
	var near_mod = 1.0 - distance_factor  # 1.0 when near, 0.0 when far
	var far_mod = distance_factor          # 0.0 when near, 1.0 when far
	
	weights[Tier.CARGO_SHUTTLE] *= (1.0 + near_mod * 0.5)
	weights[Tier.FREIGHT_HAULER] *= (1.0 + near_mod * 0.3)
	weights[Tier.CORPORATE_TRANSPORT] *= 1.0  # Middle ground
	weights[Tier.MILITARY_FRIGATE] *= (1.0 + far_mod * 0.5)
	weights[Tier.BLACK_OPS_VESSEL] *= (1.0 + far_mod * 1.0)
	
	# Calculate total
	var total: float = 0.0
	for w in weights.values():
		total += w
	
	# Roll
	var roll = randf() * total
	var cumulative: float = 0.0
	
	for tier in weights.keys():
		cumulative += weights[tier]
		if roll <= cumulative:
			return tier
	
	return Tier.CARGO_SHUTTLE  # Fallback
