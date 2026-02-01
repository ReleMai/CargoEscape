# ==============================================================================
# ROOM TYPES - DEFINES ALL ROOM VARIATIONS FOR SHIP INTERIORS
# ==============================================================================
#
# FILE: scripts/data/room_types.gd
# PURPOSE: Data definitions for different room types in ship layouts
#
# ROOM CATEGORIES:
# - Essential: Entry Airlock, Exit Airlock, Corridor
# - Common: Cargo Bay, Storage, Crew Quarters, Supply Room
# - Special: Bridge, Engine Room, Armory, Vault, Med Bay, Lab, etc.
#
# ==============================================================================

class_name RoomTypes
extends RefCounted


# ==============================================================================
# ENUMS
# ==============================================================================

enum Type {
	# Essential
	ENTRY_AIRLOCK,
	EXIT_AIRLOCK,
	CORRIDOR,
	
	# Common
	CARGO_BAY,
	STORAGE,
	CREW_QUARTERS,
	SUPPLY_ROOM,
	
	# Special
	BRIDGE,
	ENGINE_ROOM,
	ARMORY,
	VAULT,
	MED_BAY,
	LAB,
	EXECUTIVE_SUITE,
	CONFERENCE,
	SERVER_ROOM,
	BARRACKS,
	CONTRABAND_HOLD
}

enum Category {
	ESSENTIAL,
	COMMON,
	SPECIAL
}


# ==============================================================================
# ROOM DATA STRUCTURE
# ==============================================================================

class RoomData:
	var type: Type
	var category: Category
	var display_name: String
	var description: String
	
	# Size constraints (in pixels)
	var min_size: Vector2 = Vector2(80, 80)
	var max_size: Vector2 = Vector2(200, 200)
	var preferred_size: Vector2 = Vector2(120, 120)
	
	# Placement preferences
	var preferred_position: String = "any"  # "front", "back", "side", "center", "any"
	var required_for_classes: Array[String] = []  # Ship classes that require this room
	
	# Container spawning
	var container_types: Array[int] = []  # ContainerTypes.Type values
	var min_containers: int = 0
	var max_containers: int = 3
	
	# Loot modifiers
	var rarity_modifiers: Dictionary = {
		0: 1.0,  # Common
		1: 1.0,  # Uncommon
		2: 1.0,  # Rare
		3: 1.0,  # Epic
		4: 1.0   # Legendary
	}
	
	# Visual properties
	var floor_pattern: String = "default"  # default, grid, carpet, grated, reinforced
	var wall_style: String = "standard"    # standard, reinforced, glass, bulkhead
	var has_special_lighting: bool = false
	var lighting_color: Color = Color.WHITE
	
	# Decoration hints
	var decoration_tags: Array[String] = []
	
	func _init(p_type: Type, p_category: Category, p_name: String, p_desc: String = "") -> void:
		type = p_type
		category = p_category
		display_name = p_name
		description = p_desc


# ==============================================================================
# ROOM DEFINITIONS
# ==============================================================================

static var _rooms: Dictionary = {}
static var _initialized: bool = false


static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_define_rooms()


static func _define_rooms() -> void:
	# Import container types for reference
	const CT = preload("res://scripts/data/container_types.gd")
	
	# =========================================================================
	# ESSENTIAL ROOMS
	# =========================================================================
	
	# ENTRY AIRLOCK
	var entry = RoomData.new(
		Type.ENTRY_AIRLOCK,
		Category.ESSENTIAL,
		"Entry Airlock",
		"Player spawn point. Sealed door to the ship exterior."
	)
	entry.min_size = Vector2(80, 80)
	entry.max_size = Vector2(100, 100)
	entry.preferred_size = Vector2(90, 90)
	entry.preferred_position = "side"
	entry.min_containers = 0
	entry.max_containers = 0
	entry.floor_pattern = "grated"
	entry.wall_style = "bulkhead"
	entry.decoration_tags.assign(["airlock", "door_frame", "warning_lights"])
	_rooms[Type.ENTRY_AIRLOCK] = entry
	
	# EXIT AIRLOCK
	var exit = RoomData.new(
		Type.EXIT_AIRLOCK,
		Category.ESSENTIAL,
		"Exit Airlock",
		"Escape point. Must reach before timer expires."
	)
	exit.min_size = Vector2(80, 80)
	exit.max_size = Vector2(100, 100)
	exit.preferred_size = Vector2(90, 90)
	exit.preferred_position = "side"
	exit.min_containers = 0
	exit.max_containers = 0
	exit.floor_pattern = "grated"
	exit.wall_style = "bulkhead"
	exit.has_special_lighting = true
	exit.lighting_color = Color(0.3, 1.0, 0.3)  # Green glow
	exit.decoration_tags.assign(["airlock", "exit_sign", "green_lights"])
	_rooms[Type.EXIT_AIRLOCK] = exit
	
	# CORRIDOR
	var corridor = RoomData.new(
		Type.CORRIDOR,
		Category.ESSENTIAL,
		"Corridor",
		"Passageway connecting rooms."
	)
	corridor.min_size = Vector2(60, 60)
	corridor.max_size = Vector2(120, 400)  # Can be long
	corridor.preferred_size = Vector2(80, 150)
	corridor.preferred_position = "any"
	corridor.min_containers = 0
	corridor.max_containers = 1
	corridor.container_types.assign([CT.Type.SUPPLY_CABINET])
	corridor.floor_pattern = "default"
	corridor.decoration_tags.assign(["direction_arrows", "wall_panels", "lights"])
	_rooms[Type.CORRIDOR] = corridor
	
	# =========================================================================
	# COMMON ROOMS
	# =========================================================================
	
	# CARGO BAY
	var cargo = RoomData.new(
		Type.CARGO_BAY,
		Category.COMMON,
		"Cargo Bay",
		"Large storage area for freight and cargo."
	)
	cargo.min_size = Vector2(150, 150)
	cargo.max_size = Vector2(300, 250)
	cargo.preferred_size = Vector2(200, 180)
	cargo.preferred_position = "center"
	cargo.min_containers = 2
	cargo.max_containers = 5
	cargo.container_types.assign([CT.Type.CARGO_CRATE, CT.Type.SCRAP_PILE])
	cargo.floor_pattern = "grid"
	cargo.decoration_tags.assign([
		"crate_stacks", "cargo_lifts", "warning_stripes", "floor_markings"
	])
	_rooms[Type.CARGO_BAY] = cargo
	
	# STORAGE
	var storage = RoomData.new(
		Type.STORAGE,
		Category.COMMON,
		"Storage Room",
		"General purpose storage space."
	)
	storage.min_size = Vector2(100, 100)
	storage.max_size = Vector2(150, 150)
	storage.preferred_size = Vector2(120, 120)
	storage.preferred_position = "any"
	storage.min_containers = 1
	storage.max_containers = 3
	storage.container_types.assign([CT.Type.CARGO_CRATE, CT.Type.LOCKER])
	storage.floor_pattern = "default"
	storage.decoration_tags.assign(["shelves", "boxes"])
	_rooms[Type.STORAGE] = storage
	
	# CREW QUARTERS
	var quarters = RoomData.new(
		Type.CREW_QUARTERS,
		Category.COMMON,
		"Crew Quarters",
		"Living space for ship personnel."
	)
	quarters.min_size = Vector2(100, 80)
	quarters.max_size = Vector2(150, 120)
	quarters.preferred_size = Vector2(120, 100)
	quarters.preferred_position = "side"
	quarters.min_containers = 1
	quarters.max_containers = 2
	quarters.container_types.assign([CT.Type.LOCKER, CT.Type.SUPPLY_CABINET])
	quarters.rarity_modifiers = {0: 1.0, 1: 1.2, 2: 0.8, 3: 0.5, 4: 0.2}
	quarters.floor_pattern = "carpet"
	quarters.decoration_tags.assign(["bunks", "personal_items", "lockers"])
	_rooms[Type.CREW_QUARTERS] = quarters
	
	# SUPPLY ROOM
	var supply = RoomData.new(
		Type.SUPPLY_ROOM,
		Category.COMMON,
		"Supply Room",
		"Components and consumables storage."
	)
	supply.min_size = Vector2(80, 80)
	supply.max_size = Vector2(120, 120)
	supply.preferred_size = Vector2(100, 100)
	supply.preferred_position = "any"
	supply.min_containers = 1
	supply.max_containers = 3
	supply.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.CARGO_CRATE])
	supply.rarity_modifiers = {0: 1.2, 1: 1.3, 2: 0.8, 3: 0.4, 4: 0.1}
	supply.floor_pattern = "default"
	supply.decoration_tags.assign(["supply_shelves", "tool_racks"])
	_rooms[Type.SUPPLY_ROOM] = supply
	
	# =========================================================================
	# SPECIAL ROOMS
	# =========================================================================
	
	# BRIDGE
	var bridge = RoomData.new(
		Type.BRIDGE,
		Category.SPECIAL,
		"Bridge",
		"Ship command center with navigation and control systems."
	)
	bridge.min_size = Vector2(140, 120)
	bridge.max_size = Vector2(220, 180)
	bridge.preferred_size = Vector2(180, 150)
	bridge.preferred_position = "front"
	bridge.required_for_classes.assign([
		"patrol_frigate", "military_cruiser", "corporate_transport"
	])
	bridge.min_containers = 1
	bridge.max_containers = 2
	bridge.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.LOCKER])
	bridge.rarity_modifiers = {0: 0.7, 1: 1.0, 2: 1.3, 3: 1.2, 4: 0.8}
	bridge.floor_pattern = "reinforced"
	bridge.has_special_lighting = true
	bridge.lighting_color = Color(0.8, 0.9, 1.0)  # Blue-white
	bridge.decoration_tags.assign(["control_panels", "viewscreen", "captain_chair", "nav_console"])
	_rooms[Type.BRIDGE] = bridge
	
	# ENGINE ROOM
	var engine = RoomData.new(
		Type.ENGINE_ROOM,
		Category.SPECIAL,
		"Engine Room",
		"Ship propulsion and power systems."
	)
	engine.min_size = Vector2(140, 120)
	engine.max_size = Vector2(200, 180)
	engine.preferred_size = Vector2(170, 150)
	engine.preferred_position = "back"
	engine.required_for_classes.assign([
		"freight_hauler", "patrol_frigate", "military_cruiser"
	])
	engine.min_containers = 1
	engine.max_containers = 3
	engine.container_types.assign([CT.Type.SCRAP_PILE, CT.Type.SUPPLY_CABINET])
	engine.rarity_modifiers = {0: 1.5, 1: 1.3, 2: 0.7, 3: 0.3, 4: 0.1}
	engine.floor_pattern = "grated"
	engine.has_special_lighting = true
	engine.lighting_color = Color(1.0, 0.8, 0.6)  # Orange-warm
	engine.decoration_tags.assign(["pipes", "generators", "warning_lights", "conduits"])
	_rooms[Type.ENGINE_ROOM] = engine
	
	# ARMORY
	var armory = RoomData.new(
		Type.ARMORY,
		Category.SPECIAL,
		"Armory",
		"Weapons and combat equipment storage."
	)
	armory.min_size = Vector2(100, 100)
	armory.max_size = Vector2(160, 140)
	armory.preferred_size = Vector2(130, 120)
	armory.preferred_position = "side"
	armory.min_containers = 2
	armory.max_containers = 4
	armory.container_types.assign([CT.Type.ARMORY, CT.Type.LOCKER])
	armory.rarity_modifiers = {0: 0.5, 1: 0.8, 2: 1.2, 3: 1.5, 4: 1.0}
	armory.floor_pattern = "reinforced"
	armory.wall_style = "reinforced"
	armory.has_special_lighting = true
	armory.lighting_color = Color(1.0, 0.85, 0.85)  # Red-tinted
	armory.decoration_tags.assign(["weapon_racks", "ammo_crates", "security_door"])
	_rooms[Type.ARMORY] = armory
	
	# VAULT
	var vault = RoomData.new(
		Type.VAULT,
		Category.SPECIAL,
		"Vault",
		"Secured storage for valuable items."
	)
	vault.min_size = Vector2(80, 80)
	vault.max_size = Vector2(120, 120)
	vault.preferred_size = Vector2(100, 100)
	vault.preferred_position = "center"
	vault.min_containers = 1
	vault.max_containers = 2
	vault.container_types.assign([CT.Type.VAULT, CT.Type.SECURE_CACHE])
	vault.rarity_modifiers = {0: 0.3, 1: 0.6, 2: 1.2, 3: 1.8, 4: 2.0}
	vault.floor_pattern = "reinforced"
	vault.wall_style = "reinforced"
	vault.has_special_lighting = true
	vault.lighting_color = Color(1.0, 0.95, 0.8)  # Gold-white
	vault.decoration_tags.assign(["vault_door", "security_panels", "reinforced_walls"])
	_rooms[Type.VAULT] = vault
	
	# MED BAY
	var medbay = RoomData.new(
		Type.MED_BAY,
		Category.SPECIAL,
		"Medical Bay",
		"Medical treatment and supplies."
	)
	medbay.min_size = Vector2(100, 80)
	medbay.max_size = Vector2(150, 120)
	medbay.preferred_size = Vector2(120, 100)
	medbay.preferred_position = "any"
	medbay.min_containers = 1
	medbay.max_containers = 3
	medbay.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.LOCKER])
	medbay.rarity_modifiers = {0: 0.8, 1: 1.5, 2: 1.2, 3: 0.5, 4: 0.2}
	medbay.floor_pattern = "default"
	medbay.has_special_lighting = true
	medbay.lighting_color = Color(0.9, 1.0, 0.95)  # Clean white-green
	medbay.decoration_tags.assign(["med_beds", "medical_equipment", "cabinets"])
	_rooms[Type.MED_BAY] = medbay
	
	# LAB
	var lab = RoomData.new(
		Type.LAB,
		Category.SPECIAL,
		"Laboratory",
		"Research and development facility."
	)
	lab.min_size = Vector2(100, 100)
	lab.max_size = Vector2(160, 140)
	lab.preferred_size = Vector2(130, 120)
	lab.preferred_position = "any"
	lab.min_containers = 1
	lab.max_containers = 3
	lab.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.SECURE_CACHE])
	lab.rarity_modifiers = {0: 0.5, 1: 0.8, 2: 1.5, 3: 1.3, 4: 1.0}
	lab.floor_pattern = "default"
	lab.has_special_lighting = true
	lab.lighting_color = Color(0.85, 0.9, 1.0)  # Blue-white
	lab.decoration_tags.assign(["lab_equipment", "consoles", "specimens"])
	_rooms[Type.LAB] = lab
	
	# EXECUTIVE SUITE
	var executive = RoomData.new(
		Type.EXECUTIVE_SUITE,
		Category.SPECIAL,
		"Executive Suite",
		"Luxury quarters for VIPs."
	)
	executive.min_size = Vector2(120, 100)
	executive.max_size = Vector2(180, 150)
	executive.preferred_size = Vector2(150, 130)
	executive.preferred_position = "front"
	executive.min_containers = 1
	executive.max_containers = 2
	executive.container_types.assign([CT.Type.LOCKER, CT.Type.SUPPLY_CABINET])
	executive.rarity_modifiers = {0: 0.5, 1: 0.8, 2: 1.3, 3: 1.5, 4: 1.2}
	executive.floor_pattern = "carpet"
	executive.decoration_tags.assign(["luxury_furniture", "artwork", "personal_items"])
	_rooms[Type.EXECUTIVE_SUITE] = executive
	
	# CONFERENCE
	var conference = RoomData.new(
		Type.CONFERENCE,
		Category.SPECIAL,
		"Conference Room",
		"Meeting and briefing space."
	)
	conference.min_size = Vector2(100, 80)
	conference.max_size = Vector2(160, 120)
	conference.preferred_size = Vector2(130, 100)
	conference.preferred_position = "any"
	conference.min_containers = 0
	conference.max_containers = 1
	conference.container_types.assign([CT.Type.SUPPLY_CABINET])
	conference.rarity_modifiers = {0: 0.8, 1: 1.0, 2: 1.2, 3: 0.8, 4: 0.3}
	conference.floor_pattern = "carpet"
	conference.decoration_tags.assign(["conference_table", "screens", "chairs"])
	_rooms[Type.CONFERENCE] = conference
	
	# SERVER ROOM
	var server = RoomData.new(
		Type.SERVER_ROOM,
		Category.SPECIAL,
		"Server Room",
		"Data storage and processing systems."
	)
	server.min_size = Vector2(80, 80)
	server.max_size = Vector2(140, 120)
	server.preferred_size = Vector2(110, 100)
	server.preferred_position = "any"
	server.min_containers = 1
	server.max_containers = 2
	server.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.SECURE_CACHE])
	server.rarity_modifiers = {0: 0.6, 1: 1.0, 2: 1.4, 3: 1.2, 4: 0.8}
	server.floor_pattern = "grated"
	server.has_special_lighting = true
	server.lighting_color = Color(0.7, 0.85, 1.0)  # Blue
	server.decoration_tags.assign(["server_racks", "cables", "cooling_units"])
	_rooms[Type.SERVER_ROOM] = server
	
	# BARRACKS
	var barracks = RoomData.new(
		Type.BARRACKS,
		Category.SPECIAL,
		"Barracks",
		"Military personnel quarters."
	)
	barracks.min_size = Vector2(140, 100)
	barracks.max_size = Vector2(200, 160)
	barracks.preferred_size = Vector2(170, 130)
	barracks.preferred_position = "side"
	barracks.min_containers = 2
	barracks.max_containers = 4
	barracks.container_types.assign([CT.Type.LOCKER, CT.Type.CARGO_CRATE])
	barracks.rarity_modifiers = {0: 1.2, 1: 1.0, 2: 0.8, 3: 0.6, 4: 0.3}
	barracks.floor_pattern = "default"
	barracks.decoration_tags.assign(["bunks", "lockers", "military_gear"])
	_rooms[Type.BARRACKS] = barracks
	
	# CONTRABAND HOLD
	var contraband = RoomData.new(
		Type.CONTRABAND_HOLD,
		Category.SPECIAL,
		"Hidden Compartment",
		"Secret storage for illegal goods."
	)
	contraband.min_size = Vector2(60, 60)
	contraband.max_size = Vector2(100, 100)
	contraband.preferred_size = Vector2(80, 80)
	contraband.preferred_position = "any"
	contraband.min_containers = 1
	contraband.max_containers = 2
	contraband.container_types.assign([CT.Type.SECURE_CACHE])
	contraband.rarity_modifiers = {0: 0.2, 1: 0.5, 2: 1.0, 3: 1.8, 4: 2.5}
	contraband.floor_pattern = "grated"
	contraband.wall_style = "bulkhead"
	contraband.decoration_tags.assign(["hidden_panels", "concealed_door"])
	_rooms[Type.CONTRABAND_HOLD] = contraband


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Get room data by type
static func get_room(type: Type) -> RoomData:
	_ensure_initialized()
	return _rooms.get(type)


## Get all room types
static func get_all_types() -> Array[Type]:
	_ensure_initialized()
	var types: Array[Type] = []
	for t in _rooms.keys():
		types.append(t)
	return types


## Get rooms by category
static func get_rooms_by_category(category: Category) -> Array[RoomData]:
	_ensure_initialized()
	var result: Array[RoomData] = []
	for room in _rooms.values():
		if room.category == category:
			result.append(room)
	return result


## Get common room types (for general spawning)
static func get_common_rooms() -> Array[RoomData]:
	return get_rooms_by_category(Category.COMMON)


## Get special room types
static func get_special_rooms() -> Array[RoomData]:
	return get_rooms_by_category(Category.SPECIAL)


## Get room names for a tier (for UI display)
static func get_room_names_for_tier(tier: int) -> Array[String]:
	_ensure_initialized()
	
	var names: Array[String] = []
	
	match tier:
		1:
			names = ["CARGO HOLD", "STORAGE", "CORRIDOR"]
		2:
			names = [
				"CARGO BAY A", "CARGO BAY B", "STORAGE",
				"CORRIDOR", "SUPPLY ROOM", "CREW QUARTERS"
			]
		3:
			names = ["EXECUTIVE SUITE", "CONFERENCE", "OFFICE", "VIP LOUNGE", "CORRIDOR", "ATRIUM"]
		4:
			names = [
				"BRIDGE", "ARMORY", "ENGINE ROOM", "BARRACKS",
				"MED BAY", "CORRIDOR", "WEAPONS BAY"
			]
		5:
			names = [
				"COMMAND", "VAULT", "LAB", "SERVER ROOM",
				"STEALTH SYS", "ARCHIVES", "CORRIDOR"
			]
	
	return names


## Roll a random room type appropriate for faction and ship tier
static func roll_room_type(
	faction_preferences: Array[String],
	tier: int,
	placed_rooms: Array[Type]
) -> Type:
	_ensure_initialized()
	
	var weights: PackedFloat32Array = PackedFloat32Array()
	var room_list: Array = []
	
	# Consider common and special rooms
	var common_rooms = get_rooms_by_category(Category.COMMON)
	var special_rooms = get_rooms_by_category(Category.SPECIAL)
	var candidates = common_rooms + special_rooms
	
	for room in candidates:
		var weight: float = 1.0
		
		# Boost weight if faction prefers this room
		var room_key = _type_to_key(room.type)
		if room_key in faction_preferences:
			weight *= 2.0
		
		# Reduce weight if we already have this room type
		var existing_count = placed_rooms.count(room.type)
		if existing_count > 0:
			weight *= pow(0.5, existing_count)
		
		# Some rooms are more common at certain tiers
		if tier <= 2 and room.category == Category.SPECIAL:
			weight *= 0.5
		elif tier >= 4 and room.type in [Type.ARMORY, Type.VAULT, Type.LAB]:
			weight *= 1.5
		
		weights.append(weight)
		room_list.append(room.type)
	
	if room_list.is_empty():
		return Type.STORAGE  # Fallback
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var index = rng.rand_weighted(weights)
	
	if index >= 0 and index < room_list.size():
		return room_list[index]
	
	return Type.STORAGE


## Convert type enum to string key
static func _type_to_key(type: Type) -> String:
	match type:
		Type.ENTRY_AIRLOCK: return "entry_airlock"
		Type.EXIT_AIRLOCK: return "exit_airlock"
		Type.CORRIDOR: return "corridor"
		Type.CARGO_BAY: return "cargo_bay"
		Type.STORAGE: return "storage"
		Type.CREW_QUARTERS: return "crew_quarters"
		Type.SUPPLY_ROOM: return "supply_room"
		Type.BRIDGE: return "bridge"
		Type.ENGINE_ROOM: return "engine_room"
		Type.ARMORY: return "armory"
		Type.VAULT: return "vault"
		Type.MED_BAY: return "med_bay"
		Type.LAB: return "lab"
		Type.EXECUTIVE_SUITE: return "executive_suite"
		Type.CONFERENCE: return "conference"
		Type.SERVER_ROOM: return "server_room"
		Type.BARRACKS: return "barracks"
		Type.CONTRABAND_HOLD: return "contraband_hold"
	return "unknown"
