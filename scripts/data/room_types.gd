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
	CONTRABAND_HOLD,
	
	# Tier 1 - Cargo Shuttle additions
	MAINTENANCE_BAY,
	PILOT_CABIN,
	FUEL_STORAGE,
	
	# Tier 2 - Freight Hauler additions
	GALLEY,
	HYDROPONIC_BAY,
	COMMUNICATIONS,
	RECREATION_ROOM,
	
	# Tier 3 - Corporate Transport additions
	BOARDROOM,
	EXECUTIVE_BEDROOM,
	PRIVATE_BAR,
	ART_GALLERY,
	SPA,
	
	# Tier 4 - Military Frigate additions
	TACTICAL_OPERATIONS,
	BRIG,
	TRAINING_ROOM,
	DRONE_BAY,
	MESS_HALL,
	
	# Tier 5 - Black Ops Vessel additions
	INTERROGATION,
	SPECIMEN_LAB,
	SECURE_COMMS,
	EXPERIMENTAL_WEAPONS,
	ESCAPE_PODS
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
	
	# =========================================================================
	# TIER 1 - CARGO SHUTTLE ADDITIONS
	# =========================================================================
	
	# MAINTENANCE BAY
	var maintenance_bay = RoomData.new(
		Type.MAINTENANCE_BAY,
		Category.COMMON,
		"Maintenance Bay",
		"Small repair area for basic ship maintenance."
	)
	maintenance_bay.min_size = Vector2(100, 80)
	maintenance_bay.max_size = Vector2(140, 120)
	maintenance_bay.preferred_size = Vector2(120, 100)
	maintenance_bay.preferred_position = "any"
	maintenance_bay.min_containers = 1
	maintenance_bay.max_containers = 3
	maintenance_bay.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.CARGO_CRATE])
	maintenance_bay.rarity_modifiers = {0: 1.3, 1: 1.1, 2: 0.7, 3: 0.4, 4: 0.1}
	maintenance_bay.floor_pattern = "grated"
	maintenance_bay.decoration_tags.assign(["tool_benches", "repair_equipment", "spare_parts"])
	_rooms[Type.MAINTENANCE_BAY] = maintenance_bay
	
	# PILOT CABIN
	var pilot_cabin = RoomData.new(
		Type.PILOT_CABIN,
		Category.COMMON,
		"Pilot Cabin",
		"Basic cockpit area for ship navigation."
	)
	pilot_cabin.min_size = Vector2(80, 80)
	pilot_cabin.max_size = Vector2(120, 100)
	pilot_cabin.preferred_size = Vector2(100, 90)
	pilot_cabin.preferred_position = "front"
	pilot_cabin.min_containers = 0
	pilot_cabin.max_containers = 1
	pilot_cabin.container_types.assign([CT.Type.LOCKER])
	pilot_cabin.rarity_modifiers = {0: 1.0, 1: 1.0, 2: 0.5, 3: 0.3, 4: 0.1}
	pilot_cabin.floor_pattern = "default"
	pilot_cabin.decoration_tags.assign(["pilot_seat", "control_panels", "viewport"])
	_rooms[Type.PILOT_CABIN] = pilot_cabin
	
	# FUEL STORAGE
	var fuel_storage = RoomData.new(
		Type.FUEL_STORAGE,
		Category.COMMON,
		"Fuel Storage",
		"Dangerous area containing fuel tanks."
	)
	fuel_storage.min_size = Vector2(90, 90)
	fuel_storage.max_size = Vector2(130, 110)
	fuel_storage.preferred_size = Vector2(110, 100)
	fuel_storage.preferred_position = "back"
	fuel_storage.min_containers = 1
	fuel_storage.max_containers = 2
	fuel_storage.container_types.assign([CT.Type.CARGO_CRATE, CT.Type.SCRAP_PILE])
	fuel_storage.rarity_modifiers = {0: 1.2, 1: 0.9, 2: 0.6, 3: 0.3, 4: 0.1}
	fuel_storage.floor_pattern = "grated"
	fuel_storage.wall_style = "reinforced"
	fuel_storage.has_special_lighting = true
	fuel_storage.lighting_color = Color(1.0, 0.8, 0.3)  # Orange warning
	fuel_storage.decoration_tags.assign(["fuel_tanks", "warning_signs", "hazard_stripes"])
	_rooms[Type.FUEL_STORAGE] = fuel_storage
	
	# =========================================================================
	# TIER 2 - FREIGHT HAULER ADDITIONS
	# =========================================================================
	
	# GALLEY
	var galley = RoomData.new(
		Type.GALLEY,
		Category.COMMON,
		"Galley",
		"Kitchen and mess area for crew meals."
	)
	galley.min_size = Vector2(110, 90)
	galley.max_size = Vector2(150, 120)
	galley.preferred_size = Vector2(130, 105)
	galley.preferred_position = "any"
	galley.min_containers = 1
	galley.max_containers = 2
	galley.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.LOCKER])
	galley.rarity_modifiers = {0: 1.2, 1: 1.0, 2: 0.6, 3: 0.3, 4: 0.1}
	galley.floor_pattern = "default"
	galley.decoration_tags.assign(["food_prep", "tables", "storage_units"])
	_rooms[Type.GALLEY] = galley
	
	# HYDROPONIC BAY
	var hydroponic = RoomData.new(
		Type.HYDROPONIC_BAY,
		Category.COMMON,
		"Hydroponic Bay",
		"Food production and plant cultivation."
	)
	hydroponic.min_size = Vector2(120, 100)
	hydroponic.max_size = Vector2(160, 140)
	hydroponic.preferred_size = Vector2(140, 120)
	hydroponic.preferred_position = "any"
	hydroponic.min_containers = 1
	hydroponic.max_containers = 2
	hydroponic.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.CARGO_CRATE])
	hydroponic.rarity_modifiers = {0: 1.0, 1: 1.2, 2: 0.8, 3: 0.4, 4: 0.2}
	hydroponic.floor_pattern = "grid"
	hydroponic.has_special_lighting = true
	hydroponic.lighting_color = Color(0.7, 1.0, 0.7)  # Green grow lights
	hydroponic.decoration_tags.assign(["grow_beds", "irrigation", "plants"])
	_rooms[Type.HYDROPONIC_BAY] = hydroponic
	
	# COMMUNICATIONS
	var communications = RoomData.new(
		Type.COMMUNICATIONS,
		Category.COMMON,
		"Communications",
		"Radio and communications equipment."
	)
	communications.min_size = Vector2(90, 80)
	communications.max_size = Vector2(120, 100)
	communications.preferred_size = Vector2(105, 90)
	communications.preferred_position = "any"
	communications.min_containers = 0
	communications.max_containers = 2
	communications.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.SECURE_CACHE])
	communications.rarity_modifiers = {0: 0.8, 1: 1.2, 2: 1.0, 3: 0.6, 4: 0.3}
	communications.floor_pattern = "default"
	communications.has_special_lighting = true
	communications.lighting_color = Color(0.8, 0.9, 1.0)  # Blue
	communications.decoration_tags.assign(["comm_stations", "antenna_controls", "monitors"])
	_rooms[Type.COMMUNICATIONS] = communications
	
	# RECREATION ROOM
	var recreation = RoomData.new(
		Type.RECREATION_ROOM,
		Category.COMMON,
		"Recreation Room",
		"Crew morale and entertainment area."
	)
	recreation.min_size = Vector2(120, 100)
	recreation.max_size = Vector2(160, 140)
	recreation.preferred_size = Vector2(140, 120)
	recreation.preferred_position = "any"
	recreation.min_containers = 1
	recreation.max_containers = 2
	recreation.container_types.assign([CT.Type.LOCKER, CT.Type.SUPPLY_CABINET])
	recreation.rarity_modifiers = {0: 1.0, 1: 1.1, 2: 0.7, 3: 0.4, 4: 0.2}
	recreation.floor_pattern = "carpet"
	recreation.decoration_tags.assign(["gaming_tables", "entertainment", "seating"])
	_rooms[Type.RECREATION_ROOM] = recreation
	
	# =========================================================================
	# TIER 3 - CORPORATE TRANSPORT ADDITIONS
	# =========================================================================
	
	# BOARDROOM
	var boardroom = RoomData.new(
		Type.BOARDROOM,
		Category.SPECIAL,
		"Boardroom",
		"High-value meeting room for executives."
	)
	boardroom.min_size = Vector2(140, 120)
	boardroom.max_size = Vector2(200, 160)
	boardroom.preferred_size = Vector2(170, 140)
	boardroom.preferred_position = "center"
	boardroom.min_containers = 1
	boardroom.max_containers = 3
	boardroom.container_types.assign([CT.Type.SECURE_CACHE, CT.Type.LOCKER])
	boardroom.rarity_modifiers = {0: 0.6, 1: 0.9, 2: 1.3, 3: 1.0, 4: 0.5}
	boardroom.floor_pattern = "carpet"
	boardroom.wall_style = "glass"
	boardroom.decoration_tags.assign(["conference_table", "luxury_chairs", "displays"])
	_rooms[Type.BOARDROOM] = boardroom
	
	# EXECUTIVE BEDROOM
	var exec_bedroom = RoomData.new(
		Type.EXECUTIVE_BEDROOM,
		Category.SPECIAL,
		"Executive Bedroom",
		"Personal luxury quarters for VIP passengers."
	)
	exec_bedroom.min_size = Vector2(120, 100)
	exec_bedroom.max_size = Vector2(160, 140)
	exec_bedroom.preferred_size = Vector2(140, 120)
	exec_bedroom.preferred_position = "side"
	exec_bedroom.min_containers = 1
	exec_bedroom.max_containers = 2
	exec_bedroom.container_types.assign([CT.Type.LOCKER, CT.Type.SECURE_CACHE])
	exec_bedroom.rarity_modifiers = {0: 0.5, 1: 0.8, 2: 1.2, 3: 1.0, 4: 0.6}
	exec_bedroom.floor_pattern = "carpet"
	exec_bedroom.decoration_tags.assign(["luxury_bed", "personal_safe", "amenities"])
	_rooms[Type.EXECUTIVE_BEDROOM] = exec_bedroom
	
	# PRIVATE BAR
	var private_bar = RoomData.new(
		Type.PRIVATE_BAR,
		Category.SPECIAL,
		"Private Bar",
		"Luxury amenity for corporate entertainment."
	)
	private_bar.min_size = Vector2(100, 90)
	private_bar.max_size = Vector2(140, 120)
	private_bar.preferred_size = Vector2(120, 105)
	private_bar.preferred_position = "any"
	private_bar.min_containers = 1
	private_bar.max_containers = 2
	private_bar.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.LOCKER])
	private_bar.rarity_modifiers = {0: 0.7, 1: 1.0, 2: 1.1, 3: 0.7, 4: 0.3}
	private_bar.floor_pattern = "carpet"
	private_bar.decoration_tags.assign(["bar_counter", "seating", "bottles"])
	_rooms[Type.PRIVATE_BAR] = private_bar
	
	# ART GALLERY
	var art_gallery = RoomData.new(
		Type.ART_GALLERY,
		Category.SPECIAL,
		"Art Gallery",
		"Valuable art collection display."
	)
	art_gallery.min_size = Vector2(130, 110)
	art_gallery.max_size = Vector2(180, 150)
	art_gallery.preferred_size = Vector2(155, 130)
	art_gallery.preferred_position = "any"
	art_gallery.min_containers = 1
	art_gallery.max_containers = 3
	art_gallery.container_types.assign([CT.Type.SECURE_CACHE, CT.Type.VAULT])
	art_gallery.rarity_modifiers = {0: 0.3, 1: 0.6, 2: 1.2, 3: 1.5, 4: 1.0}
	art_gallery.floor_pattern = "carpet"
	art_gallery.wall_style = "glass"
	art_gallery.has_special_lighting = true
	art_gallery.lighting_color = Color(1.0, 1.0, 0.95)  # Warm white
	art_gallery.decoration_tags.assign(["art_pieces", "display_cases", "pedestals"])
	_rooms[Type.ART_GALLERY] = art_gallery
	
	# SPA
	var spa = RoomData.new(
		Type.SPA,
		Category.SPECIAL,
		"Spa",
		"Corporate luxury relaxation facility."
	)
	spa.min_size = Vector2(120, 100)
	spa.max_size = Vector2(160, 140)
	spa.preferred_size = Vector2(140, 120)
	spa.preferred_position = "any"
	spa.min_containers = 1
	spa.max_containers = 2
	spa.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.LOCKER])
	spa.rarity_modifiers = {0: 0.8, 1: 1.0, 2: 1.0, 3: 0.5, 4: 0.3}
	spa.floor_pattern = "carpet"
	spa.has_special_lighting = true
	spa.lighting_color = Color(0.9, 0.95, 1.0)  # Soft blue
	spa.decoration_tags.assign(["massage_tables", "relaxation_pods", "plants"])
	_rooms[Type.SPA] = spa
	
	# =========================================================================
	# TIER 4 - MILITARY FRIGATE ADDITIONS
	# =========================================================================
	
	# TACTICAL OPERATIONS
	var tactical = RoomData.new(
		Type.TACTICAL_OPERATIONS,
		Category.SPECIAL,
		"Tactical Operations",
		"Mission planning and coordination center."
	)
	tactical.min_size = Vector2(140, 120)
	tactical.max_size = Vector2(190, 160)
	tactical.preferred_size = Vector2(165, 140)
	tactical.preferred_position = "front"
	tactical.min_containers = 1
	tactical.max_containers = 3
	tactical.container_types.assign([CT.Type.SECURE_CACHE, CT.Type.SUPPLY_CABINET])
	tactical.rarity_modifiers = {0: 0.5, 1: 0.8, 2: 1.0, 3: 1.3, 4: 0.8}
	tactical.floor_pattern = "grid"
	tactical.has_special_lighting = true
	tactical.lighting_color = Color(1.0, 0.85, 0.85)  # Red tint
	tactical.decoration_tags.assign(["holo_table", "tactical_displays", "command_stations"])
	_rooms[Type.TACTICAL_OPERATIONS] = tactical
	
	# BRIG
	var brig = RoomData.new(
		Type.BRIG,
		Category.SPECIAL,
		"Brig",
		"Prisoner holding and detention."
	)
	brig.min_size = Vector2(100, 90)
	brig.max_size = Vector2(140, 120)
	brig.preferred_size = Vector2(120, 105)
	brig.preferred_position = "any"
	brig.min_containers = 0
	brig.max_containers = 2
	brig.container_types.assign([CT.Type.LOCKER, CT.Type.SUPPLY_CABINET])
	brig.rarity_modifiers = {0: 1.0, 1: 0.9, 2: 0.7, 3: 0.8, 4: 0.4}
	brig.floor_pattern = "reinforced"
	brig.wall_style = "reinforced"
	brig.decoration_tags.assign(["holding_cells", "security_panels", "restraints"])
	_rooms[Type.BRIG] = brig
	
	# TRAINING ROOM
	var training = RoomData.new(
		Type.TRAINING_ROOM,
		Category.SPECIAL,
		"Training Room",
		"Combat simulation and practice facility."
	)
	training.min_size = Vector2(130, 110)
	training.max_size = Vector2(180, 150)
	training.preferred_size = Vector2(155, 130)
	training.preferred_position = "any"
	training.min_containers = 1
	training.max_containers = 2
	training.container_types.assign([CT.Type.ARMORY, CT.Type.SUPPLY_CABINET])
	training.rarity_modifiers = {0: 0.7, 1: 1.0, 2: 0.9, 3: 1.2, 4: 0.6}
	training.floor_pattern = "reinforced"
	training.decoration_tags.assign(["training_dummies", "equipment", "weapon_racks"])
	_rooms[Type.TRAINING_ROOM] = training
	
	# DRONE BAY
	var drone_bay = RoomData.new(
		Type.DRONE_BAY,
		Category.SPECIAL,
		"Drone Bay",
		"Unmanned vehicle launch and maintenance."
	)
	drone_bay.min_size = Vector2(140, 120)
	drone_bay.max_size = Vector2(190, 160)
	drone_bay.preferred_size = Vector2(165, 140)
	drone_bay.preferred_position = "side"
	drone_bay.min_containers = 2
	drone_bay.max_containers = 4
	drone_bay.container_types.assign([CT.Type.CARGO_CRATE, CT.Type.SUPPLY_CABINET])
	drone_bay.rarity_modifiers = {0: 0.6, 1: 1.0, 2: 1.1, 3: 1.3, 4: 0.7}
	drone_bay.floor_pattern = "grated"
	drone_bay.wall_style = "bulkhead"
	drone_bay.decoration_tags.assign(["drone_docks", "launch_rails", "control_stations"])
	_rooms[Type.DRONE_BAY] = drone_bay
	
	# MESS HALL
	var mess_hall = RoomData.new(
		Type.MESS_HALL,
		Category.COMMON,
		"Mess Hall",
		"Large dining area for military personnel."
	)
	mess_hall.min_size = Vector2(150, 120)
	mess_hall.max_size = Vector2(200, 160)
	mess_hall.preferred_size = Vector2(175, 140)
	mess_hall.preferred_position = "any"
	mess_hall.min_containers = 1
	mess_hall.max_containers = 3
	mess_hall.container_types.assign([CT.Type.SUPPLY_CABINET, CT.Type.LOCKER])
	mess_hall.rarity_modifiers = {0: 1.1, 1: 1.0, 2: 0.7, 3: 0.5, 4: 0.2}
	mess_hall.floor_pattern = "default"
	mess_hall.decoration_tags.assign(["dining_tables", "food_service", "seating_rows"])
	_rooms[Type.MESS_HALL] = mess_hall
	
	# =========================================================================
	# TIER 5 - BLACK OPS VESSEL ADDITIONS
	# =========================================================================
	
	# INTERROGATION
	var interrogation = RoomData.new(
		Type.INTERROGATION,
		Category.SPECIAL,
		"Interrogation Room",
		"Dark secrets and classified information extraction."
	)
	interrogation.min_size = Vector2(90, 80)
	interrogation.max_size = Vector2(130, 110)
	interrogation.preferred_size = Vector2(110, 95)
	interrogation.preferred_position = "any"
	interrogation.min_containers = 0
	interrogation.max_containers = 2
	interrogation.container_types.assign([CT.Type.SECURE_CACHE, CT.Type.SUPPLY_CABINET])
	interrogation.rarity_modifiers = {0: 0.4, 1: 0.7, 2: 1.0, 3: 1.4, 4: 1.2}
	interrogation.floor_pattern = "reinforced"
	interrogation.wall_style = "reinforced"
	interrogation.has_special_lighting = true
	interrogation.lighting_color = Color(1.0, 0.7, 0.7)  # Harsh red
	interrogation.decoration_tags.assign(["restraint_chair", "monitoring", "soundproofing"])
	_rooms[Type.INTERROGATION] = interrogation
	
	# SPECIMEN LAB
	var specimen_lab = RoomData.new(
		Type.SPECIMEN_LAB,
		Category.SPECIAL,
		"Specimen Lab",
		"Alien research and biological containment."
	)
	specimen_lab.min_size = Vector2(130, 110)
	specimen_lab.max_size = Vector2(180, 150)
	specimen_lab.preferred_size = Vector2(155, 130)
	specimen_lab.preferred_position = "any"
	specimen_lab.min_containers = 2
	specimen_lab.max_containers = 4
	specimen_lab.container_types.assign([CT.Type.SECURE_CACHE, CT.Type.VAULT])
	specimen_lab.rarity_modifiers = {0: 0.3, 1: 0.6, 2: 1.0, 3: 1.5, 4: 2.0}
	specimen_lab.floor_pattern = "grated"
	specimen_lab.wall_style = "reinforced"
	specimen_lab.has_special_lighting = true
	specimen_lab.lighting_color = Color(0.7, 1.0, 0.8)  # Eerie green
	specimen_lab.decoration_tags.assign(["containment_pods", "research_stations", "biohazard"])
	_rooms[Type.SPECIMEN_LAB] = specimen_lab
	
	# SECURE COMMS
	var secure_comms = RoomData.new(
		Type.SECURE_COMMS,
		Category.SPECIAL,
		"Secure Communications",
		"Encrypted transmission and intelligence gathering."
	)
	secure_comms.min_size = Vector2(100, 90)
	secure_comms.max_size = Vector2(140, 120)
	secure_comms.preferred_size = Vector2(120, 105)
	secure_comms.preferred_position = "any"
	secure_comms.min_containers = 1
	secure_comms.max_containers = 3
	secure_comms.container_types.assign([CT.Type.SECURE_CACHE, CT.Type.SUPPLY_CABINET])
	secure_comms.rarity_modifiers = {0: 0.4, 1: 0.7, 2: 1.2, 3: 1.4, 4: 1.0}
	secure_comms.floor_pattern = "default"
	secure_comms.has_special_lighting = true
	secure_comms.lighting_color = Color(0.7, 0.85, 1.0)  # Blue
	secure_comms.decoration_tags.assign(["encryption_stations", "signal_arrays", "monitors"])
	_rooms[Type.SECURE_COMMS] = secure_comms
	
	# EXPERIMENTAL WEAPONS
	var exp_weapons = RoomData.new(
		Type.EXPERIMENTAL_WEAPONS,
		Category.SPECIAL,
		"Experimental Weapons",
		"Prototype weapon storage and testing."
	)
	exp_weapons.min_size = Vector2(140, 120)
	exp_weapons.max_size = Vector2(190, 160)
	exp_weapons.preferred_size = Vector2(165, 140)
	exp_weapons.preferred_position = "any"
	exp_weapons.min_containers = 2
	exp_weapons.max_containers = 5
	exp_weapons.container_types.assign([CT.Type.VAULT, CT.Type.ARMORY, CT.Type.SECURE_CACHE])
	exp_weapons.rarity_modifiers = {0: 0.2, 1: 0.4, 2: 0.8, 3: 1.5, 4: 2.5}
	exp_weapons.floor_pattern = "reinforced"
	exp_weapons.wall_style = "reinforced"
	exp_weapons.has_special_lighting = true
	exp_weapons.lighting_color = Color(1.0, 0.9, 0.7)  # Amber warning
	exp_weapons.decoration_tags.assign(["weapon_racks", "test_equipment", "containment"])
	_rooms[Type.EXPERIMENTAL_WEAPONS] = exp_weapons
	
	# ESCAPE PODS
	var escape_pods = RoomData.new(
		Type.ESCAPE_PODS,
		Category.ESSENTIAL,
		"Escape Pods",
		"Emergency evacuation system."
	)
	escape_pods.min_size = Vector2(100, 90)
	escape_pods.max_size = Vector2(140, 120)
	escape_pods.preferred_size = Vector2(120, 105)
	escape_pods.preferred_position = "side"
	escape_pods.min_containers = 0
	escape_pods.max_containers = 1
	escape_pods.container_types.assign([CT.Type.SUPPLY_CABINET])
	escape_pods.rarity_modifiers = {0: 0.9, 1: 1.0, 2: 0.6, 3: 0.4, 4: 0.2}
	escape_pods.floor_pattern = "grated"
	escape_pods.wall_style = "bulkhead"
	escape_pods.has_special_lighting = true
	escape_pods.lighting_color = Color(1.0, 0.5, 0.2)  # Emergency orange
	escape_pods.decoration_tags.assign(["pod_bays", "emergency_equipment", "launch_controls"])
	_rooms[Type.ESCAPE_PODS] = escape_pods


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
