# ==============================================================================
# FACTIONS - SHIP FACTIONS WITH VISUAL THEMES AND LOOT MODIFIERS
# ==============================================================================
#
# FILE: scripts/data/factions.gd
# PURPOSE: Defines factions that own ships, affecting visuals and loot
#
# FACTIONS:
# - CCG: Civilian Commerce Guild - Industrial, basic loot
# - NEX: Nexus Corporation - Corporate, high-value items
# - GDF: Galactic Defense Force - Military, weapons/modules
# - SYN: Shadow Syndicate - Covert, rare/legendary items
# - IND: Independent Traders - Mixed, variable loot
#
# ==============================================================================

class_name Factions
extends RefCounted


# ==============================================================================
# ENUMS
# ==============================================================================

enum Type {
	CCG,  # Civilian Commerce Guild
	NEX,  # Nexus Corporation
	GDF,  # Galactic Defense Force
	SYN,  # Shadow Syndicate
	IND   # Independent Traders
}


# ==============================================================================
# FACTION THEME DATA
# ==============================================================================

class FactionTheme:
	var hull_color: Color = Color.GRAY
	var accent_color: Color = Color.WHITE
	var interior_floor: Color = Color.DIM_GRAY
	var interior_wall: Color = Color.DARK_GRAY
	var lighting_tint: Color = Color.WHITE
	var glow_color: Color = Color.TRANSPARENT
	var decoration_style: String = "industrial"  # industrial, corporate, military, stealth
	
	func _init(
		p_hull: Color,
		p_accent: Color,
		p_floor: Color,
		p_wall: Color,
		p_lighting: Color,
		p_glow: Color,
		p_style: String
	) -> void:
		hull_color = p_hull
		accent_color = p_accent
		interior_floor = p_floor
		interior_wall = p_wall
		lighting_tint = p_lighting
		glow_color = p_glow
		decoration_style = p_style


# ==============================================================================
# FACTION DATA
# ==============================================================================

class FactionData:
	var type: Type
	var code: String  # Short code (CCG, NEX, etc.)
	var display_name: String
	var description: String
	var theme: FactionTheme
	
	# Preferred ship tiers (weighted chances)
	var tier_weights: Dictionary = {1: 1.0, 2: 1.0, 3: 1.0, 4: 1.0, 5: 1.0}
	
	# Rarity modifiers for loot
	var rarity_modifiers: Dictionary = {
		0: 1.0,  # Common
		1: 1.0,  # Uncommon
		2: 1.0,  # Rare
		3: 1.0,  # Epic
		4: 1.0   # Legendary
	}
	
	# Item category preferences (higher = more likely)
	var category_weights: Dictionary = {
		"scrap": 1.0,
		"component": 1.0,
		"valuable": 1.0,
		"module": 1.0,
		"artifact": 1.0
	}
	
	# Room type preferences (which rooms appear more often)
	var room_preferences: Array[String] = []
	
	# Danger level modifier (affects future enemy spawning)
	var danger_modifier: float = 1.0
	
	func _init(p_type: Type, p_code: String, p_name: String, p_desc: String = "") -> void:
		type = p_type
		code = p_code
		display_name = p_name
		description = p_desc


# ==============================================================================
# FACTION DEFINITIONS
# ==============================================================================

static var _factions: Dictionary = {}
static var _initialized: bool = false


static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_define_factions()


static func _define_factions() -> void:
	# -------------------------------------------------------------------------
	# CCG: CIVILIAN COMMERCE GUILD
	# -------------------------------------------------------------------------
	var ccg = FactionData.new(
		Type.CCG,
		"CCG",
		"Civilian Commerce Guild",
		"Standard commercial shipping. Common cargo but easy targets."
	)
	ccg.theme = FactionTheme.new(
		Color("8C6B4F"),  # Rust brown hull
		Color("BF9B30"),  # Gold-yellow accent
		Color("3D3630"),  # Dark brown floor
		Color("524840"),  # Brown wall
		Color("FFF2DB"),  # Warm lighting
		Color("FFD700"),  # Gold glow
		"industrial"
	)
	ccg.tier_weights = {1: 2.0, 2: 1.5, 3: 0.5, 4: 0.1, 5: 0.0}
	ccg.rarity_modifiers = {0: 1.5, 1: 1.0, 2: 0.5, 3: 0.2, 4: 0.05}
	ccg.category_weights = {
		"scrap": 1.5,
		"component": 1.2,
		"valuable": 0.8,
		"module": 0.5,
		"artifact": 0.1
	}
	ccg.room_preferences.assign(["cargo_bay", "storage", "crew_quarters", "corridor"])
	ccg.danger_modifier = 0.8
	_factions[Type.CCG] = ccg
	
	# -------------------------------------------------------------------------
	# NEX: NEXUS CORPORATION
	# -------------------------------------------------------------------------
	var nex = FactionData.new(
		Type.NEX,
		"NEX",
		"Nexus Corporation",
		"Interstellar corp. High-value assets and rare technology."
	)
	nex.theme = FactionTheme.new(
		Color("E8E8EC"),  # Off-white hull
		Color("D4AF37"),  # Metallic gold accent
		Color("3C3C44"),  # Charcoal floor
		Color("505058"),  # Gray wall
		Color("FFFFFF"),  # Bright white lighting
		Color("FFD700"),  # Gold glow
		"corporate"
	)
	nex.tier_weights = {1: 0.2, 2: 0.8, 3: 1.5, 4: 1.0, 5: 0.3}
	nex.rarity_modifiers = {0: 0.8, 1: 1.0, 2: 1.3, 3: 1.0, 4: 0.5}
	nex.category_weights = {
		"scrap": 0.5,
		"component": 1.3,
		"valuable": 1.8,
		"module": 1.2,
		"artifact": 0.5
	}
	nex.room_preferences.assign(["executive_suite", "conference", "vault", "office", "server_room"])
	nex.danger_modifier = 1.0
	_factions[Type.NEX] = nex
	
	# -------------------------------------------------------------------------
	# GDF: GALACTIC DEFENSE FORCE
	# -------------------------------------------------------------------------
	var gdf = FactionData.new(
		Type.GDF,
		"GDF",
		"Galactic Defense Force",
		"Military org. Weapons, tactical gear, and mil-spec modules."
	)
	gdf.theme = FactionTheme.new(
		Color("40444C"),  # Dark steel hull
		Color("CC3333"),  # Warning red accent
		Color("282830"),  # Dark gray floor
		Color("383840"),  # Steel wall
		Color("FFF0F0"),  # Slightly red-tinted lighting
		Color("FF4444"),  # Red glow
		"military"
	)
	gdf.tier_weights = {1: 0.1, 2: 0.5, 3: 1.0, 4: 1.5, 5: 1.0}
	gdf.rarity_modifiers = {0: 0.7, 1: 1.0, 2: 1.0, 3: 1.2, 4: 0.8}
	gdf.category_weights = {
		"scrap": 0.8,
		"component": 1.0,
		"valuable": 0.7,
		"module": 2.0,
		"artifact": 0.3
	}
	gdf.room_preferences.assign(["bridge", "armory", "barracks", "med_bay", "engine_room"])
	gdf.danger_modifier = 1.5
	_factions[Type.GDF] = gdf
	
	# -------------------------------------------------------------------------
	# SYN: SHADOW SYNDICATE
	# -------------------------------------------------------------------------
	var syn = FactionData.new(
		Type.SYN,
		"SYN",
		"Shadow Syndicate",
		"Covert criminal vessels. Extremely dangerous, legendary loot."
	)
	syn.theme = FactionTheme.new(
		Color("141418"),  # Near-black hull
		Color("00D9E0"),  # Neon cyan accent
		Color("18181C"),  # Very dark floor
		Color("242428"),  # Dark wall
		Color("D0F0FF"),  # Cyan-tinted lighting
		Color("00FFFF"),  # Cyan glow
		"stealth"
	)
	syn.tier_weights = {1: 0.0, 2: 0.1, 3: 0.5, 4: 1.2, 5: 2.0}
	syn.rarity_modifiers = {0: 0.4, 1: 0.7, 2: 1.0, 3: 1.5, 4: 2.0}
	syn.category_weights = {
		"scrap": 0.3,
		"component": 0.8,
		"valuable": 1.2,
		"module": 1.5,
		"artifact": 2.5
	}
	syn.room_preferences.assign(["vault", "lab", "server_room", "contraband_hold", "hidden_cache"])
	syn.danger_modifier = 2.0
	_factions[Type.SYN] = syn
	
	# -------------------------------------------------------------------------
	# IND: INDEPENDENT TRADERS
	# -------------------------------------------------------------------------
	var ind = FactionData.new(
		Type.IND,
		"IND",
		"Independent Traders",
		"Freelance merchants with eclectic vessels. You never know what you might find aboard."
	)
	ind.theme = FactionTheme.new(
		Color("6B7080"),  # Mixed gray hull
		Color("88CC88"),  # Green accent
		Color("343840"),  # Gray floor
		Color("484C54"),  # Gray wall
		Color("F8F8F0"),  # Neutral lighting
		Color("44FF44"),  # Green glow
		"industrial"
	)
	ind.tier_weights = {1: 1.0, 2: 1.0, 3: 1.0, 4: 0.5, 5: 0.2}
	ind.rarity_modifiers = {0: 1.0, 1: 1.0, 2: 1.0, 3: 1.0, 4: 1.0}  # Neutral
	ind.category_weights = {
		"scrap": 1.0,
		"component": 1.0,
		"valuable": 1.0,
		"module": 1.0,
		"artifact": 1.0
	}
	ind.room_preferences.assign(["cargo_bay", "storage", "crew_quarters"])
	ind.danger_modifier = 1.0
	_factions[Type.IND] = ind


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Get faction data by type
static func get_faction(type: Type) -> FactionData:
	_ensure_initialized()
	return _factions.get(type)


## Get faction data by code (CCG, NEX, etc.)
static func get_faction_by_code(code: String) -> FactionData:
	_ensure_initialized()
	for faction in _factions.values():
		if faction.code == code:
			return faction
	return null


## Get all faction types
static func get_all_types() -> Array[Type]:
	_ensure_initialized()
	return [Type.CCG, Type.NEX, Type.GDF, Type.SYN, Type.IND]


## Roll a random faction weighted by ship tier
static func roll_faction_for_tier(tier: int) -> FactionData:
	_ensure_initialized()
	
	var weights: PackedFloat32Array = PackedFloat32Array()
	var factions_list: Array = []
	
	for type in _factions.keys():
		var faction = _factions[type]
		var weight = faction.tier_weights.get(tier, 0.5)
		if weight > 0:
			weights.append(weight)
			factions_list.append(faction)
	
	if factions_list.is_empty():
		return _factions[Type.CCG]  # Fallback
	
	# Create RNG and use weighted random
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var index = rng.rand_weighted(weights)
	
	if index >= 0 and index < factions_list.size():
		return factions_list[index]
	
	return factions_list[0]


## Roll a random faction with distance factor consideration
static func roll_faction_for_distance(distance_factor: float) -> FactionData:
	_ensure_initialized()
	
	# Clamp distance factor
	distance_factor = clampf(distance_factor, 0.0, 1.0)
	
	var weights: PackedFloat32Array = PackedFloat32Array()
	var factions_list: Array = []
	
	for type in _factions.keys():
		var faction = _factions[type]
		
		# Calculate weight based on danger modifier and distance
		var base_weight = 1.0
		
		# Higher danger factions more likely at greater distances
		if distance_factor > 0.7:
			base_weight *= faction.danger_modifier
		elif distance_factor < 0.3:
			base_weight *= (2.0 - faction.danger_modifier)
		
		weights.append(base_weight)
		factions_list.append(faction)
	
	if factions_list.is_empty():
		return _factions[Type.CCG]
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var index = rng.rand_weighted(weights)
	
	if index >= 0 and index < factions_list.size():
		return factions_list[index]
	
	return factions_list[0]


## Get rarity modifier for a faction
static func get_rarity_modifier(type: Type, rarity: int) -> float:
	var faction = get_faction(type)
	if faction:
		return faction.rarity_modifiers.get(rarity, 1.0)
	return 1.0


## Get category weight for a faction
static func get_category_weight(type: Type, category: String) -> float:
	var faction = get_faction(type)
	if faction:
		return faction.category_weights.get(category, 1.0)
	return 1.0
