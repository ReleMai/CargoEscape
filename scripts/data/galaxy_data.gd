# ==============================================================================
# GALAXY DATA - POI AND REGION DEFINITIONS
# ==============================================================================
#
# FILE: scripts/data/galaxy_data.gd
# PURPOSE: Defines galaxy regions, POIs, and travel mechanics
#
# REGIONS:
# - CCG_SPACE: Civilian Commerce Guild territory
# - NEX_SPACE: Nexus Corporation territory  
# - GDF_SPACE: Galactic Defense Force territory
# - SYN_SPACE: Shadow Syndicate territory
# - IND_SPACE: Independent Traders territory
# - NEUTRAL: Unclaimed space between factions
# - FRONTIER: Dangerous border zones
#
# ==============================================================================

class_name GalaxyData
extends RefCounted


# ==============================================================================
# ENUMS
# ==============================================================================

enum Region {
	CCG_SPACE,
	NEX_SPACE,
	GDF_SPACE,
	SYN_SPACE,
	IND_SPACE,
	NEUTRAL,
	FRONTIER
}

enum POIType {
	CARGO_SHIP,
	FREIGHTER,
	STATION,
	DERELICT,
	CONVOY,
	MILITARY_VESSEL,
	RESEARCH_FACILITY,
	SMUGGLER_DEN,
	MINING_OUTPOST,
	LUXURY_YACHT
}

enum Difficulty {
	EASY,      # Tier 1-2 ships, few enemies
	MEDIUM,    # Tier 2-3 ships, moderate enemies
	HARD,      # Tier 3-4 ships, many enemies
	EXTREME,   # Tier 4-5 ships, heavy resistance
	NIGHTMARE  # Tier 5, elite enemies, special hazards
}


# ==============================================================================
# POI DATA CLASS
# ==============================================================================

class POI:
	var id: String = ""
	var name: String = ""
	var description: String = ""
	var poi_type: POIType = POIType.CARGO_SHIP
	var region: Region = Region.NEUTRAL
	var faction: String = "IND"  # Faction code
	var difficulty: Difficulty = Difficulty.EASY
	var position: Vector2 = Vector2.ZERO  # Galaxy map position
	
	# Requirements
	var min_ship_tier: int = 1  # Minimum ship tier to attempt
	var required_modules: Array[String] = []  # Module IDs needed
	
	# Rewards
	var base_credits: int = 500
	var loot_tier_min: int = 1
	var loot_tier_max: int = 3
	var guaranteed_items: Array[String] = []  # Item IDs always dropped
	var special_loot_chance: float = 0.1
	
	# State
	var discovered: bool = false
	var completed: bool = false
	var available: bool = true
	var refresh_after_runs: int = 3  # Re-appears after X completed runs
	
	func _init(p_id: String = "", p_name: String = "") -> void:
		id = p_id
		name = p_name
	
	func get_enemy_count() -> int:
		match difficulty:
			Difficulty.EASY: return randi_range(0, 2)
			Difficulty.MEDIUM: return randi_range(2, 4)
			Difficulty.HARD: return randi_range(4, 6)
			Difficulty.EXTREME: return randi_range(6, 10)
			Difficulty.NIGHTMARE: return randi_range(8, 15)
		return 1
	
	func get_time_limit() -> float:
		match difficulty:
			Difficulty.EASY: return 120.0
			Difficulty.MEDIUM: return 100.0
			Difficulty.HARD: return 80.0
			Difficulty.EXTREME: return 60.0
			Difficulty.NIGHTMARE: return 45.0
		return 90.0
	
	func to_dict() -> Dictionary:
		return {
			"id": id,
			"name": name,
			"description": description,
			"poi_type": poi_type,
			"region": region,
			"faction": faction,
			"difficulty": difficulty,
			"position": {"x": position.x, "y": position.y},
			"min_ship_tier": min_ship_tier,
			"required_modules": required_modules,
			"base_credits": base_credits,
			"loot_tier_min": loot_tier_min,
			"loot_tier_max": loot_tier_max,
			"discovered": discovered,
			"completed": completed,
			"available": available
		}
	
	static func from_dict(data: Dictionary) -> POI:
		var poi = POI.new()
		poi.id = data.get("id", "")
		poi.name = data.get("name", "")
		poi.description = data.get("description", "")
		poi.poi_type = data.get("poi_type", POIType.CARGO_SHIP)
		poi.region = data.get("region", Region.NEUTRAL)
		poi.faction = data.get("faction", "IND")
		poi.difficulty = data.get("difficulty", Difficulty.EASY)
		var pos = data.get("position", {"x": 0, "y": 0})
		poi.position = Vector2(pos.get("x", 0), pos.get("y", 0))
		poi.min_ship_tier = data.get("min_ship_tier", 1)
		poi.required_modules = data.get("required_modules", [])
		poi.base_credits = data.get("base_credits", 500)
		poi.loot_tier_min = data.get("loot_tier_min", 1)
		poi.loot_tier_max = data.get("loot_tier_max", 3)
		poi.discovered = data.get("discovered", false)
		poi.completed = data.get("completed", false)
		poi.available = data.get("available", true)
		return poi


# ==============================================================================
# REGION DATA CLASS
# ==============================================================================

class RegionData:
	var type: Region
	var name: String
	var description: String
	var color: Color
	var center: Vector2
	var radius: float
	var controlling_faction: String
	var danger_level: int  # 1-5
	
	func _init(
		p_type: Region,
		p_name: String,
		p_center: Vector2,
		p_radius: float,
		p_faction: String,
		p_color: Color,
		p_danger: int = 1
	) -> void:
		type = p_type
		name = p_name
		center = p_center
		radius = p_radius
		controlling_faction = p_faction
		color = p_color
		danger_level = p_danger


# ==============================================================================
# STATIC DATA
# ==============================================================================

static var _regions: Dictionary = {}
static var _poi_templates: Array[POI] = []
static var _initialized: bool = false


static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_define_regions()
	_define_poi_templates()


# ==============================================================================
# REGION DEFINITIONS
# ==============================================================================

static func _define_regions() -> void:
	# Galaxy is 1000x800 units
	
	# CCG Space - Center-left, large commercial zone
	_regions[Region.CCG_SPACE] = RegionData.new(
		Region.CCG_SPACE,
		"Commerce Guild Space",
		Vector2(200, 400),
		180.0,
		"CCG",
		Color(0.6, 0.5, 0.3, 0.3),
		1
	)
	
	# NEX Space - Upper right, corporate sector
	_regions[Region.NEX_SPACE] = RegionData.new(
		Region.NEX_SPACE,
		"Nexus Corporate Zone",
		Vector2(750, 200),
		150.0,
		"NEX",
		Color(0.9, 0.85, 0.6, 0.3),
		2
	)
	
	# GDF Space - Lower right, military zone
	_regions[Region.GDF_SPACE] = RegionData.new(
		Region.GDF_SPACE,
		"Defense Force Territory",
		Vector2(800, 600),
		140.0,
		"GDF",
		Color(0.5, 0.2, 0.2, 0.3),
		4
	)
	
	# SYN Space - Upper left, shadowy region
	_regions[Region.SYN_SPACE] = RegionData.new(
		Region.SYN_SPACE,
		"Syndicate Shadow Zone",
		Vector2(150, 150),
		120.0,
		"SYN",
		Color(0.3, 0.1, 0.4, 0.3),
		3
	)
	
	# IND Space - Center, mixed zone
	_regions[Region.IND_SPACE] = RegionData.new(
		Region.IND_SPACE,
		"Free Trader Lanes",
		Vector2(500, 450),
		160.0,
		"IND",
		Color(0.3, 0.5, 0.3, 0.3),
		2
	)
	
	# Neutral - Lower left
	_regions[Region.NEUTRAL] = RegionData.new(
		Region.NEUTRAL,
		"Unclaimed Space",
		Vector2(300, 650),
		130.0,
		"",
		Color(0.4, 0.4, 0.4, 0.2),
		2
	)
	
	# Frontier - Far right edge, dangerous
	_regions[Region.FRONTIER] = RegionData.new(
		Region.FRONTIER,
		"The Frontier",
		Vector2(950, 400),
		100.0,
		"",
		Color(0.6, 0.1, 0.1, 0.4),
		5
	)


# ==============================================================================
# POI TEMPLATE DEFINITIONS - 24 UNIQUE LOCATIONS
# ==============================================================================

static func _define_poi_templates() -> void:
	_poi_templates.clear()
	
	# --- CCG SPACE POIs (4) ---
	
	var poi1 = POI.new("ccg_cargo_hauler", "CCG Cargo Hauler")
	poi1.description = "Standard commerce guild freighter. Easy pickings."
	poi1.poi_type = POIType.CARGO_SHIP
	poi1.region = Region.CCG_SPACE
	poi1.faction = "CCG"
	poi1.difficulty = Difficulty.EASY
	poi1.min_ship_tier = 1
	poi1.base_credits = 400
	poi1.loot_tier_min = 1
	poi1.loot_tier_max = 2
	_poi_templates.append(poi1)
	
	var poi2 = POI.new("ccg_supply_depot", "Orbital Supply Depot")
	poi2.description = "Commerce guild resupply station. Moderate security."
	poi2.poi_type = POIType.STATION
	poi2.region = Region.CCG_SPACE
	poi2.faction = "CCG"
	poi2.difficulty = Difficulty.MEDIUM
	poi2.min_ship_tier = 2
	poi2.base_credits = 800
	poi2.loot_tier_min = 2
	poi2.loot_tier_max = 3
	_poi_templates.append(poi2)
	
	var poi3 = POI.new("ccg_trade_convoy", "Trade Convoy")
	poi3.description = "Three ships traveling together. Higher reward."
	poi3.poi_type = POIType.CONVOY
	poi3.region = Region.CCG_SPACE
	poi3.faction = "CCG"
	poi3.difficulty = Difficulty.MEDIUM
	poi3.min_ship_tier = 2
	poi3.base_credits = 1200
	poi3.loot_tier_min = 2
	poi3.loot_tier_max = 4
	_poi_templates.append(poi3)
	
	var poi4 = POI.new("ccg_mining_barge", "Mining Barge 'Dusty Pick'")
	poi4.description = "Slow-moving ore hauler. Valuable raw materials."
	poi4.poi_type = POIType.MINING_OUTPOST
	poi4.region = Region.CCG_SPACE
	poi4.faction = "CCG"
	poi4.difficulty = Difficulty.EASY
	poi4.min_ship_tier = 1
	poi4.base_credits = 600
	poi4.loot_tier_min = 1
	poi4.loot_tier_max = 3
	_poi_templates.append(poi4)
	
	# --- NEX SPACE POIs (4) ---
	
	var poi5 = POI.new("nex_executive_yacht", "Executive Yacht 'Prosperity'")
	poi5.description = "Nexus exec's personal vessel. Luxury goods."
	poi5.poi_type = POIType.LUXURY_YACHT
	poi5.region = Region.NEX_SPACE
	poi5.faction = "NEX"
	poi5.difficulty = Difficulty.MEDIUM
	poi5.min_ship_tier = 2
	poi5.base_credits = 1500
	poi5.loot_tier_min = 3
	poi5.loot_tier_max = 4
	poi5.special_loot_chance = 0.25
	_poi_templates.append(poi5)
	
	var poi6 = POI.new("nex_research_station", "Research Station Theta-7")
	poi6.description = "Classified Nexus research. Prototype tech inside."
	poi6.poi_type = POIType.RESEARCH_FACILITY
	poi6.region = Region.NEX_SPACE
	poi6.faction = "NEX"
	poi6.difficulty = Difficulty.HARD
	poi6.min_ship_tier = 3
	poi6.base_credits = 2000
	poi6.loot_tier_min = 3
	poi6.loot_tier_max = 5
	poi6.special_loot_chance = 0.4
	_poi_templates.append(poi6)
	
	var poi7 = POI.new("nex_data_courier", "Data Courier 'Silent Runner'")
	poi7.description = "Fast ship carrying encrypted corporate data."
	poi7.poi_type = POIType.CARGO_SHIP
	poi7.region = Region.NEX_SPACE
	poi7.faction = "NEX"
	poi7.difficulty = Difficulty.MEDIUM
	poi7.min_ship_tier = 2
	poi7.base_credits = 900
	poi7.loot_tier_min = 2
	poi7.loot_tier_max = 4
	_poi_templates.append(poi7)
	
	var poi8 = POI.new("nex_factory_ship", "Factory Ship 'Forge Eternal'")
	poi8.description = "Mobile manufacturing. Modules and components."
	poi8.poi_type = POIType.FREIGHTER
	poi8.region = Region.NEX_SPACE
	poi8.faction = "NEX"
	poi8.difficulty = Difficulty.HARD
	poi8.min_ship_tier = 3
	poi8.base_credits = 1800
	poi8.loot_tier_min = 3
	poi8.loot_tier_max = 5
	_poi_templates.append(poi8)
	
	# --- GDF SPACE POIs (4) ---
	
	var poi9 = POI.new("gdf_patrol_vessel", "GDF Patrol Vessel")
	poi9.description = "Armed military patrol. Weapons and gear."
	poi9.poi_type = POIType.MILITARY_VESSEL
	poi9.region = Region.GDF_SPACE
	poi9.faction = "GDF"
	poi9.difficulty = Difficulty.HARD
	poi9.min_ship_tier = 3
	poi9.base_credits = 1600
	poi9.loot_tier_min = 3
	poi9.loot_tier_max = 4
	_poi_templates.append(poi9)
	
	var poi10 = POI.new("gdf_supply_frigate", "Supply Frigate 'Iron Resolve'")
	poi10.description = "Military supply ship. Ammo and rations."
	poi10.poi_type = POIType.FREIGHTER
	poi10.region = Region.GDF_SPACE
	poi10.faction = "GDF"
	poi10.difficulty = Difficulty.MEDIUM
	poi10.min_ship_tier = 2
	poi10.base_credits = 1100
	poi10.loot_tier_min = 2
	poi10.loot_tier_max = 4
	_poi_templates.append(poi10)
	
	var poi11 = POI.new("gdf_weapons_depot", "Weapons Depot Sigma")
	poi11.description = "Military armory station. Elite weapons."
	poi11.poi_type = POIType.STATION
	poi11.region = Region.GDF_SPACE
	poi11.faction = "GDF"
	poi11.difficulty = Difficulty.EXTREME
	poi11.min_ship_tier = 4
	poi11.base_credits = 3000
	poi11.loot_tier_min = 4
	poi11.loot_tier_max = 5
	poi11.special_loot_chance = 0.5
	_poi_templates.append(poi11)
	
	var poi12 = POI.new("gdf_prison_transport", "Prison Transport 'Chains'")
	poi12.description = "Dangerous prisoners aboard. Contraband likely."
	poi12.poi_type = POIType.MILITARY_VESSEL
	poi12.region = Region.GDF_SPACE
	poi12.faction = "GDF"
	poi12.difficulty = Difficulty.HARD
	poi12.min_ship_tier = 3
	poi12.base_credits = 1400
	poi12.loot_tier_min = 2
	poi12.loot_tier_max = 5
	_poi_templates.append(poi12)
	
	# --- SYN SPACE POIs (4) ---
	
	var poi13 = POI.new("syn_smuggler_ship", "Smuggler Vessel 'Ghost'")
	poi13.description = "Syndicate smuggler. Rare and illegal goods."
	poi13.poi_type = POIType.SMUGGLER_DEN
	poi13.region = Region.SYN_SPACE
	poi13.faction = "SYN"
	poi13.difficulty = Difficulty.HARD
	poi13.min_ship_tier = 3
	poi13.base_credits = 2200
	poi13.loot_tier_min = 3
	poi13.loot_tier_max = 5
	poi13.special_loot_chance = 0.35
	_poi_templates.append(poi13)
	
	var poi14 = POI.new("syn_black_market", "Black Market Station")
	poi14.description = "Illegal trading post. Everything has a price."
	poi14.poi_type = POIType.STATION
	poi14.region = Region.SYN_SPACE
	poi14.faction = "SYN"
	poi14.difficulty = Difficulty.EXTREME
	poi14.min_ship_tier = 4
	poi14.base_credits = 4000
	poi14.loot_tier_min = 4
	poi14.loot_tier_max = 5
	poi14.special_loot_chance = 0.6
	_poi_templates.append(poi14)
	
	var poi15 = POI.new("syn_hitman_yacht", "Assassin's Yacht 'Silent Death'")
	poi15.description = "Professional killer's ship. Deadly gear."
	poi15.poi_type = POIType.LUXURY_YACHT
	poi15.region = Region.SYN_SPACE
	poi15.faction = "SYN"
	poi15.difficulty = Difficulty.HARD
	poi15.min_ship_tier = 3
	poi15.base_credits = 1800
	poi15.loot_tier_min = 3
	poi15.loot_tier_max = 5
	_poi_templates.append(poi15)
	
	var poi16 = POI.new("syn_info_broker", "Info Broker Station 'The Eye'")
	poi16.description = "Intelligence hub. Data chips and secrets."
	poi16.poi_type = POIType.STATION
	poi16.region = Region.SYN_SPACE
	poi16.faction = "SYN"
	poi16.difficulty = Difficulty.MEDIUM
	poi16.min_ship_tier = 2
	poi16.base_credits = 1300
	poi16.loot_tier_min = 2
	poi16.loot_tier_max = 4
	_poi_templates.append(poi16)
	
	# --- IND SPACE POIs (4) ---
	
	var poi17 = POI.new("ind_freelancer", "Freelance Trader 'Lucky Star'")
	poi17.description = "Independent trader. Mixed cargo."
	poi17.poi_type = POIType.CARGO_SHIP
	poi17.region = Region.IND_SPACE
	poi17.faction = "IND"
	poi17.difficulty = Difficulty.EASY
	poi17.min_ship_tier = 1
	poi17.base_credits = 500
	poi17.loot_tier_min = 1
	poi17.loot_tier_max = 3
	_poi_templates.append(poi17)
	
	var poi18 = POI.new("ind_salvage_yard", "Salvage Yard 'Junkheap'")
	poi18.description = "Scrap and parts dealer. Modules galore."
	poi18.poi_type = POIType.STATION
	poi18.region = Region.IND_SPACE
	poi18.faction = "IND"
	poi18.difficulty = Difficulty.MEDIUM
	poi18.min_ship_tier = 2
	poi18.base_credits = 900
	poi18.loot_tier_min = 2
	poi18.loot_tier_max = 4
	_poi_templates.append(poi18)
	
	var poi19 = POI.new("ind_merc_convoy", "Mercenary Convoy")
	poi19.description = "Hired guns on the move. Combat gear."
	poi19.poi_type = POIType.CONVOY
	poi19.region = Region.IND_SPACE
	poi19.faction = "IND"
	poi19.difficulty = Difficulty.HARD
	poi19.min_ship_tier = 3
	poi19.base_credits = 1500
	poi19.loot_tier_min = 3
	poi19.loot_tier_max = 4
	_poi_templates.append(poi19)
	
	var poi20 = POI.new("ind_casino_ship", "Casino Ship 'Fortune's Favor'")
	poi20.description = "Gambling den. Credits and valuables."
	poi20.poi_type = POIType.LUXURY_YACHT
	poi20.region = Region.IND_SPACE
	poi20.faction = "IND"
	poi20.difficulty = Difficulty.MEDIUM
	poi20.min_ship_tier = 2
	poi20.base_credits = 2000
	poi20.loot_tier_min = 2
	poi20.loot_tier_max = 5
	poi20.special_loot_chance = 0.3
	_poi_templates.append(poi20)
	
	# --- NEUTRAL SPACE POIs (2) ---
	
	var poi21 = POI.new("neutral_derelict", "Abandoned Freighter")
	poi21.description = "Ghost ship. What happened to the crew?"
	poi21.poi_type = POIType.DERELICT
	poi21.region = Region.NEUTRAL
	poi21.faction = ""
	poi21.difficulty = Difficulty.EASY
	poi21.min_ship_tier = 1
	poi21.base_credits = 300
	poi21.loot_tier_min = 1
	poi21.loot_tier_max = 4
	poi21.special_loot_chance = 0.2
	_poi_templates.append(poi21)
	
	var poi22 = POI.new("neutral_refugee_ship", "Refugee Transport")
	poi22.description = "Desperate people fleeing conflict. Humanitarian aid."
	poi22.poi_type = POIType.CARGO_SHIP
	poi22.region = Region.NEUTRAL
	poi22.faction = ""
	poi22.difficulty = Difficulty.EASY
	poi22.min_ship_tier = 1
	poi22.base_credits = 200
	poi22.loot_tier_min = 1
	poi22.loot_tier_max = 2
	_poi_templates.append(poi22)
	
	# --- FRONTIER POIs (2) ---
	
	var poi23 = POI.new("frontier_pirate_base", "Pirate Stronghold")
	poi23.description = "Heavily fortified pirate base. Ultimate challenge."
	poi23.poi_type = POIType.STATION
	poi23.region = Region.FRONTIER
	poi23.faction = "SYN"
	poi23.difficulty = Difficulty.NIGHTMARE
	poi23.min_ship_tier = 5
	poi23.base_credits = 6000
	poi23.loot_tier_min = 4
	poi23.loot_tier_max = 5
	poi23.special_loot_chance = 0.7
	_poi_templates.append(poi23)
	
	var poi24 = POI.new("frontier_alien_derelict", "Unknown Vessel")
	poi24.description = "Alien technology? No one knows what's inside."
	poi24.poi_type = POIType.DERELICT
	poi24.region = Region.FRONTIER
	poi24.faction = ""
	poi24.difficulty = Difficulty.NIGHTMARE
	poi24.min_ship_tier = 5
	poi24.base_credits = 8000
	poi24.loot_tier_min = 5
	poi24.loot_tier_max = 5
	poi24.special_loot_chance = 1.0
	_poi_templates.append(poi24)


# ==============================================================================
# PUBLIC API
# ==============================================================================

static func get_region(region_type: Region) -> RegionData:
	_ensure_initialized()
	return _regions.get(region_type)


static func get_all_regions() -> Array:
	_ensure_initialized()
	return _regions.values()


static func get_poi_templates() -> Array[POI]:
	_ensure_initialized()
	return _poi_templates


static func get_pois_for_region(region_type: Region) -> Array[POI]:
	_ensure_initialized()
	var result: Array[POI] = []
	for poi in _poi_templates:
		if poi.region == region_type:
			result.append(poi)
	return result


static func get_poi_by_id(poi_id: String) -> POI:
	_ensure_initialized()
	for poi in _poi_templates:
		if poi.id == poi_id:
			return poi
	return null


static func get_region_at_position(pos: Vector2) -> RegionData:
	_ensure_initialized()
	var closest: RegionData = null
	var closest_dist: float = INF
	
	for region in _regions.values():
		var dist = pos.distance_to(region.center)
		if dist < region.radius and dist < closest_dist:
			closest = region
			closest_dist = dist
	
	return closest


static func get_difficulty_name(diff: Difficulty) -> String:
	match diff:
		Difficulty.EASY: return "Easy"
		Difficulty.MEDIUM: return "Medium"
		Difficulty.HARD: return "Hard"
		Difficulty.EXTREME: return "Extreme"
		Difficulty.NIGHTMARE: return "Nightmare"
	return "Unknown"


static func get_difficulty_color(diff: Difficulty) -> Color:
	match diff:
		Difficulty.EASY: return Color(0.4, 0.8, 0.4)
		Difficulty.MEDIUM: return Color(0.8, 0.8, 0.3)
		Difficulty.HARD: return Color(0.9, 0.5, 0.2)
		Difficulty.EXTREME: return Color(0.9, 0.2, 0.2)
		Difficulty.NIGHTMARE: return Color(0.6, 0.1, 0.6)
	return Color.WHITE


static func get_poi_type_name(poi_type: POIType) -> String:
	match poi_type:
		POIType.CARGO_SHIP: return "Cargo Ship"
		POIType.FREIGHTER: return "Freighter"
		POIType.STATION: return "Station"
		POIType.DERELICT: return "Derelict"
		POIType.CONVOY: return "Convoy"
		POIType.MILITARY_VESSEL: return "Military Vessel"
		POIType.RESEARCH_FACILITY: return "Research Facility"
		POIType.SMUGGLER_DEN: return "Smuggler Den"
		POIType.MINING_OUTPOST: return "Mining Outpost"
		POIType.LUXURY_YACHT: return "Luxury Yacht"
	return "Unknown"
