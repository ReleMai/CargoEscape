# ==============================================================================
# DECORATION DATA - DATA DEFINITIONS FOR SHIP INTERIOR DECORATIONS
# ==============================================================================
#
# FILE: resources/decorations/decoration_data.gd
# PURPOSE: Defines decoration types, categories, and data structures
#
# DECORATION CATEGORIES:
# - Functional: Computer screens, control panels, pipes, vents, lights
# - Atmospheric: Posters, plants, personal items, cargo stacks, tool racks
# - Damage/Wear: Scorch marks, cracks, flickering lights, sparks, blood stains
#
# ==============================================================================

class_name DecorationData
extends RefCounted


# ==============================================================================
# ENUMS
# ==============================================================================

enum Category {
	FUNCTIONAL,
	ATMOSPHERIC,
	DAMAGE_WEAR
}

enum Type {
	# FUNCTIONAL DECORATIONS
	COMPUTER_SCREEN,
	COMPUTER_SCREEN_ANIMATED,
	CONTROL_PANEL,
	CONTROL_PANEL_LARGE,
	PIPE_HORIZONTAL,
	PIPE_VERTICAL,
	PIPE_CORNER,
	PIPE_JUNCTION,
	VENTILATION_SHAFT,
	VENTILATION_VENT,
	LIGHT_CEILING,
	LIGHT_WALL,
	LIGHT_FLOOR,
	LIGHT_GLOW,
	CONDUIT,
	WIRING,
	
	# ATMOSPHERIC DECORATIONS
	POSTER_GENERIC,
	POSTER_WARNING,
	POSTER_MOTIVATIONAL,
	POSTER_FACTION_CCG,
	POSTER_FACTION_NEX,
	POSTER_FACTION_GDF,
	POSTER_FACTION_SYN,
	POSTER_FACTION_IND,
	SIGN_EXIT,
	SIGN_CAUTION,
	SIGN_RESTRICTED,
	PLANT_SMALL,
	PLANT_LARGE,
	PLANT_DEAD,
	PERSONAL_PHOTOS,
	PERSONAL_MEMENTOS,
	PERSONAL_LOCKER,
	CARGO_CRATE_STACK,
	CARGO_BARREL_GROUP,
	TOOL_RACK,
	TOOL_BOX,
	FIRE_EXTINGUISHER,
	MEDKIT_WALL,
	
	# DAMAGE/WEAR DECORATIONS
	SCORCH_MARK_SMALL,
	SCORCH_MARK_LARGE,
	CRACK_WALL,
	CRACK_FLOOR,
	CRACK_CEILING,
	LIGHT_FLICKERING,
	SPARKING_ELECTRONICS,
	SPARKING_WIRE,
	BLOOD_STAIN_SMALL,
	BLOOD_STAIN_LARGE,
	BLOOD_SPLATTER,
	RUST_PATCH,
	DENT_WALL,
	BROKEN_PANEL,
	LEAKING_PIPE
}


# ==============================================================================
# DATA STRUCTURES
# ==============================================================================

class Decoration:
	var type: Type
	var category: Category
	var display_name: String
	var description: String
	var size: Vector2 = Vector2(20, 20)
	var color: Color = Color.WHITE
	var glow_color: Color = Color.TRANSPARENT
	var has_animation: bool = false
	var layer: int = 3  # Drawing layer (0=floor, 5=ceiling, 10=overlay)
	var rotation_allowed: bool = true
	var wall_mounted: bool = false
	var rare: bool = false  # Appears less frequently
	var faction_specific: bool = false
	var room_type_tags: Array[String] = []  # Room types where this should appear
	
	func _init(
		p_type: Type,
		p_category: Category,
		p_name: String,
		p_size: Vector2,
		p_desc: String = ""
	) -> void:
		type = p_type
		category = p_category
		display_name = p_name
		size = p_size
		description = p_desc


class DecorationPlacement:
	var decoration_type: Type
	var position: Vector2
	var rotation: float = 0.0
	var scale: Vector2 = Vector2.ONE
	var color_tint: Color = Color.WHITE
	var flicker_enabled: bool = false
	var animation_offset: float = 0.0  # For staggered animations


# ==============================================================================
# DECORATION POOL DEFINITIONS
# ==============================================================================

class DecorationPool:
	var decorations: Array[Decoration] = []
	var faction_type: int = -1  # -1 = all factions
	var room_tags: Array[String] = []
	var category_filter: Category = Category.FUNCTIONAL
	var min_density: float = 0.0
	var max_density: float = 1.0


# ==============================================================================
# DECORATION REGISTRY
# ==============================================================================

static var _decorations: Dictionary = {}
static var _initialized: bool = false


static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_define_decorations()


static func _define_decorations() -> void:
	# -------------------------------------------------------------------------
	# FUNCTIONAL DECORATIONS
	# -------------------------------------------------------------------------
	
	# Computer Screens
	var screen = Decoration.new(
		Type.COMPUTER_SCREEN,
		Category.FUNCTIONAL,
		"Computer Screen",
		Vector2(35, 25),
		"Wall-mounted display screen"
	)
	screen.wall_mounted = true
	screen.glow_color = Color(0.2, 0.4, 0.6, 0.3)
	screen.room_type_tags = ["bridge", "lab", "server_room", "conference"]
	_decorations[Type.COMPUTER_SCREEN] = screen
	
	var screen_anim = Decoration.new(
		Type.COMPUTER_SCREEN_ANIMATED,
		Category.FUNCTIONAL,
		"Animated Screen",
		Vector2(40, 30),
		"Screen with animated display"
	)
	screen_anim.wall_mounted = true
	screen_anim.has_animation = true
	screen_anim.glow_color = Color(0.3, 0.6, 0.8, 0.4)
	screen_anim.room_type_tags = ["bridge", "server_room"]
	_decorations[Type.COMPUTER_SCREEN_ANIMATED] = screen_anim
	
	# Control Panels
	var panel = Decoration.new(
		Type.CONTROL_PANEL,
		Category.FUNCTIONAL,
		"Control Panel",
		Vector2(40, 15),
		"Small control interface"
	)
	panel.wall_mounted = true
	panel.room_type_tags = ["bridge", "engine_room", "armory"]
	_decorations[Type.CONTROL_PANEL] = panel
	
	var panel_large = Decoration.new(
		Type.CONTROL_PANEL_LARGE,
		Category.FUNCTIONAL,
		"Large Control Panel",
		Vector2(60, 25),
		"Primary control interface"
	)
	panel_large.wall_mounted = true
	panel_large.rare = true
	panel_large.room_type_tags = ["bridge", "engine_room"]
	_decorations[Type.CONTROL_PANEL_LARGE] = panel_large
	
	# Pipes and Conduits
	var pipe_h = Decoration.new(
		Type.PIPE_HORIZONTAL,
		Category.FUNCTIONAL,
		"Horizontal Pipe",
		Vector2(100, 8),
		"Ceiling-mounted pipe"
	)
	pipe_h.rotation_allowed = false
	pipe_h.layer = 5
	pipe_h.room_type_tags = ["engine_room", "storage", "cargo_bay"]
	_decorations[Type.PIPE_HORIZONTAL] = pipe_h
	
	var pipe_v = Decoration.new(
		Type.PIPE_VERTICAL,
		Category.FUNCTIONAL,
		"Vertical Pipe",
		Vector2(8, 100),
		"Wall-mounted pipe"
	)
	pipe_v.rotation_allowed = false
	pipe_v.wall_mounted = true
	pipe_v.room_type_tags = ["engine_room", "storage"]
	_decorations[Type.PIPE_VERTICAL] = pipe_v
	
	var pipe_corner = Decoration.new(
		Type.PIPE_CORNER,
		Category.FUNCTIONAL,
		"Pipe Corner",
		Vector2(15, 15),
		"Pipe corner connector"
	)
	pipe_corner.layer = 5
	pipe_corner.room_type_tags = ["engine_room"]
	_decorations[Type.PIPE_CORNER] = pipe_corner
	
	# Ventilation
	var vent_shaft = Decoration.new(
		Type.VENTILATION_SHAFT,
		Category.FUNCTIONAL,
		"Ventilation Shaft",
		Vector2(40, 40),
		"Large air vent"
	)
	vent_shaft.layer = 5
	vent_shaft.room_type_tags = ["corridor", "cargo_bay", "server_room"]
	_decorations[Type.VENTILATION_SHAFT] = vent_shaft
	
	var vent = Decoration.new(
		Type.VENTILATION_VENT,
		Category.FUNCTIONAL,
		"Vent",
		Vector2(25, 25),
		"Small air vent"
	)
	vent.wall_mounted = true
	vent.room_type_tags = ["crew_quarters", "storage"]
	_decorations[Type.VENTILATION_VENT] = vent
	
	# Lights
	var light_ceiling = Decoration.new(
		Type.LIGHT_CEILING,
		Category.FUNCTIONAL,
		"Ceiling Light",
		Vector2(30, 10),
		"Standard ceiling light"
	)
	light_ceiling.layer = 5
	light_ceiling.glow_color = Color(1.0, 0.95, 0.8, 0.3)
	_decorations[Type.LIGHT_CEILING] = light_ceiling
	
	var light_wall = Decoration.new(
		Type.LIGHT_WALL,
		Category.FUNCTIONAL,
		"Wall Light",
		Vector2(15, 8),
		"Wall-mounted light"
	)
	light_wall.wall_mounted = true
	light_wall.glow_color = Color(1.0, 0.9, 0.7, 0.25)
	light_wall.room_type_tags = ["corridor", "crew_quarters"]
	_decorations[Type.LIGHT_WALL] = light_wall
	
	var light_glow = Decoration.new(
		Type.LIGHT_GLOW,
		Category.FUNCTIONAL,
		"Glow Light",
		Vector2(20, 20),
		"Soft glow light source"
	)
	light_glow.has_animation = true
	light_glow.glow_color = Color(0.4, 0.7, 1.0, 0.4)
	light_glow.rare = true
	_decorations[Type.LIGHT_GLOW] = light_glow
	
	# Wiring and Conduits
	var conduit = Decoration.new(
		Type.CONDUIT,
		Category.FUNCTIONAL,
		"Conduit",
		Vector2(6, 80),
		"Cable conduit"
	)
	conduit.wall_mounted = true
	conduit.room_type_tags = ["engine_room", "server_room"]
	_decorations[Type.CONDUIT] = conduit
	
	var wiring = Decoration.new(
		Type.WIRING,
		Category.FUNCTIONAL,
		"Exposed Wiring",
		Vector2(50, 4),
		"Exposed electrical wiring"
	)
	wiring.wall_mounted = true
	wiring.room_type_tags = ["engine_room", "storage"]
	_decorations[Type.WIRING] = wiring
	
	# -------------------------------------------------------------------------
	# ATMOSPHERIC DECORATIONS
	# -------------------------------------------------------------------------
	
	# Posters and Signs
	var poster = Decoration.new(
		Type.POSTER_GENERIC,
		Category.ATMOSPHERIC,
		"Poster",
		Vector2(30, 40),
		"Generic wall poster"
	)
	poster.wall_mounted = true
	poster.room_type_tags = ["crew_quarters", "corridor"]
	_decorations[Type.POSTER_GENERIC] = poster
	
	var poster_warning = Decoration.new(
		Type.POSTER_WARNING,
		Category.ATMOSPHERIC,
		"Warning Poster",
		Vector2(35, 45),
		"Safety warning poster"
	)
	poster_warning.wall_mounted = true
	poster_warning.room_type_tags = ["engine_room", "armory"]
	_decorations[Type.POSTER_WARNING] = poster_warning
	
	var poster_motivational = Decoration.new(
		Type.POSTER_MOTIVATIONAL,
		Category.ATMOSPHERIC,
		"Motivational Poster",
		Vector2(30, 40),
		"Inspirational poster"
	)
	poster_motivational.wall_mounted = true
	poster_motivational.room_type_tags = ["crew_quarters", "conference"]
	_decorations[Type.POSTER_MOTIVATIONAL] = poster_motivational
	
	# Faction-specific posters
	for faction_idx in range(5):
		var faction_names = ["CCG", "NEX", "GDF", "SYN", "IND"]
		var faction_poster = Decoration.new(
			Type.POSTER_FACTION_CCG + faction_idx,
			Category.ATMOSPHERIC,
			faction_names[faction_idx] + " Poster",
			Vector2(35, 45),
			faction_names[faction_idx] + " faction poster"
		)
		faction_poster.wall_mounted = true
		faction_poster.faction_specific = true
		_decorations[Type.POSTER_FACTION_CCG + faction_idx] = faction_poster
	
	# Signs
	var sign_exit = Decoration.new(
		Type.SIGN_EXIT,
		Category.ATMOSPHERIC,
		"Exit Sign",
		Vector2(50, 20),
		"Emergency exit sign"
	)
	sign_exit.wall_mounted = true
	sign_exit.glow_color = Color(0.3, 0.8, 0.4, 0.3)
	sign_exit.room_type_tags = ["corridor", "entry_airlock", "exit_airlock"]
	_decorations[Type.SIGN_EXIT] = sign_exit
	
	var sign_caution = Decoration.new(
		Type.SIGN_CAUTION,
		Category.ATMOSPHERIC,
		"Caution Sign",
		Vector2(40, 40),
		"Caution warning sign"
	)
	sign_caution.wall_mounted = true
	sign_caution.room_type_tags = ["engine_room", "armory"]
	_decorations[Type.SIGN_CAUTION] = sign_caution
	
	var sign_restricted = Decoration.new(
		Type.SIGN_RESTRICTED,
		Category.ATMOSPHERIC,
		"Restricted Area Sign",
		Vector2(45, 25),
		"Access restricted sign"
	)
	sign_restricted.wall_mounted = true
	sign_restricted.room_type_tags = ["vault", "armory", "server_room"]
	_decorations[Type.SIGN_RESTRICTED] = sign_restricted
	
	# Plants
	var plant_small = Decoration.new(
		Type.PLANT_SMALL,
		Category.ATMOSPHERIC,
		"Small Plant",
		Vector2(15, 15),
		"Small potted plant"
	)
	plant_small.room_type_tags = ["crew_quarters", "executive_suite", "conference"]
	_decorations[Type.PLANT_SMALL] = plant_small
	
	var plant_large = Decoration.new(
		Type.PLANT_LARGE,
		Category.ATMOSPHERIC,
		"Large Plant",
		Vector2(25, 30),
		"Large decorative plant"
	)
	plant_large.room_type_tags = ["executive_suite", "conference"]
	plant_large.rare = true
	_decorations[Type.PLANT_LARGE] = plant_large
	
	var plant_dead = Decoration.new(
		Type.PLANT_DEAD,
		Category.ATMOSPHERIC,
		"Dead Plant",
		Vector2(15, 15),
		"Wilted plant"
	)
	plant_dead.room_type_tags = ["crew_quarters", "storage"]
	plant_dead.rare = true
	_decorations[Type.PLANT_DEAD] = plant_dead
	
	# Personal Items
	var photos = Decoration.new(
		Type.PERSONAL_PHOTOS,
		Category.ATMOSPHERIC,
		"Photos",
		Vector2(20, 15),
		"Personal photographs"
	)
	photos.wall_mounted = true
	photos.room_type_tags = ["crew_quarters", "executive_suite"]
	_decorations[Type.PERSONAL_PHOTOS] = photos
	
	var mementos = Decoration.new(
		Type.PERSONAL_MEMENTOS,
		Category.ATMOSPHERIC,
		"Mementos",
		Vector2(25, 20),
		"Personal belongings"
	)
	mementos.room_type_tags = ["crew_quarters"]
	_decorations[Type.PERSONAL_MEMENTOS] = mementos
	
	var locker = Decoration.new(
		Type.PERSONAL_LOCKER,
		Category.ATMOSPHERIC,
		"Locker",
		Vector2(30, 50),
		"Personal storage locker"
	)
	locker.wall_mounted = true
	locker.room_type_tags = ["crew_quarters", "barracks"]
	_decorations[Type.PERSONAL_LOCKER] = locker
	
	# Cargo and Tools
	var crate_stack = Decoration.new(
		Type.CARGO_CRATE_STACK,
		Category.ATMOSPHERIC,
		"Crate Stack",
		Vector2(40, 45),
		"Stacked cargo crates"
	)
	crate_stack.room_type_tags = ["cargo_bay", "storage"]
	_decorations[Type.CARGO_CRATE_STACK] = crate_stack
	
	var barrel_group = Decoration.new(
		Type.CARGO_BARREL_GROUP,
		Category.ATMOSPHERIC,
		"Barrel Group",
		Vector2(35, 35),
		"Group of barrels"
	)
	barrel_group.room_type_tags = ["cargo_bay", "storage", "supply_room"]
	_decorations[Type.CARGO_BARREL_GROUP] = barrel_group
	
	var tool_rack = Decoration.new(
		Type.TOOL_RACK,
		Category.ATMOSPHERIC,
		"Tool Rack",
		Vector2(50, 20),
		"Wall-mounted tool rack"
	)
	tool_rack.wall_mounted = true
	tool_rack.room_type_tags = ["engine_room", "storage", "supply_room"]
	_decorations[Type.TOOL_RACK] = tool_rack
	
	var toolbox = Decoration.new(
		Type.TOOL_BOX,
		Category.ATMOSPHERIC,
		"Toolbox",
		Vector2(25, 15),
		"Portable toolbox"
	)
	toolbox.room_type_tags = ["engine_room", "storage"]
	_decorations[Type.TOOL_BOX] = toolbox
	
	# Safety Equipment
	var fire_ext = Decoration.new(
		Type.FIRE_EXTINGUISHER,
		Category.ATMOSPHERIC,
		"Fire Extinguisher",
		Vector2(12, 25),
		"Wall-mounted fire extinguisher"
	)
	fire_ext.wall_mounted = true
	fire_ext.room_type_tags = ["corridor", "engine_room", "cargo_bay"]
	_decorations[Type.FIRE_EXTINGUISHER] = fire_ext
	
	var medkit = Decoration.new(
		Type.MEDKIT_WALL,
		Category.ATMOSPHERIC,
		"Medical Kit",
		Vector2(20, 20),
		"Wall-mounted medical kit"
	)
	medkit.wall_mounted = true
	medkit.room_type_tags = ["corridor", "crew_quarters", "med_bay"]
	_decorations[Type.MEDKIT_WALL] = medkit
	
	# -------------------------------------------------------------------------
	# DAMAGE/WEAR DECORATIONS
	# -------------------------------------------------------------------------
	
	# Scorch Marks
	var scorch_small = Decoration.new(
		Type.SCORCH_MARK_SMALL,
		Category.DAMAGE_WEAR,
		"Small Scorch Mark",
		Vector2(20, 20),
		"Burn damage"
	)
	scorch_small.layer = 1
	scorch_small.color = Color(0.1, 0.1, 0.1, 0.6)
	_decorations[Type.SCORCH_MARK_SMALL] = scorch_small
	
	var scorch_large = Decoration.new(
		Type.SCORCH_MARK_LARGE,
		Category.DAMAGE_WEAR,
		"Large Scorch Mark",
		Vector2(40, 40),
		"Heavy burn damage"
	)
	scorch_large.layer = 1
	scorch_large.color = Color(0.05, 0.05, 0.05, 0.7)
	scorch_large.rare = true
	_decorations[Type.SCORCH_MARK_LARGE] = scorch_large
	
	# Cracks
	var crack_wall = Decoration.new(
		Type.CRACK_WALL,
		Category.DAMAGE_WEAR,
		"Wall Crack",
		Vector2(30, 3),
		"Crack in wall"
	)
	crack_wall.wall_mounted = true
	crack_wall.layer = 8
	crack_wall.color = Color(0.2, 0.2, 0.2, 0.5)
	_decorations[Type.CRACK_WALL] = crack_wall
	
	var crack_floor = Decoration.new(
		Type.CRACK_FLOOR,
		Category.DAMAGE_WEAR,
		"Floor Crack",
		Vector2(40, 3),
		"Crack in floor"
	)
	crack_floor.layer = 0
	crack_floor.color = Color(0.15, 0.15, 0.15, 0.6)
	_decorations[Type.CRACK_FLOOR] = crack_floor
	
	var crack_ceiling = Decoration.new(
		Type.CRACK_CEILING,
		Category.DAMAGE_WEAR,
		"Ceiling Crack",
		Vector2(35, 3),
		"Crack in ceiling"
	)
	crack_ceiling.layer = 6
	crack_ceiling.color = Color(0.1, 0.1, 0.1, 0.4)
	_decorations[Type.CRACK_CEILING] = crack_ceiling
	
	# Electrical Damage
	var light_flicker = Decoration.new(
		Type.LIGHT_FLICKERING,
		Category.DAMAGE_WEAR,
		"Flickering Light",
		Vector2(30, 10),
		"Damaged light fixture"
	)
	light_flicker.has_animation = true
	light_flicker.layer = 5
	light_flicker.glow_color = Color(1.0, 0.8, 0.6, 0.2)
	_decorations[Type.LIGHT_FLICKERING] = light_flicker
	
	var spark_elec = Decoration.new(
		Type.SPARKING_ELECTRONICS,
		Category.DAMAGE_WEAR,
		"Sparking Electronics",
		Vector2(25, 25),
		"Damaged electronics"
	)
	spark_elec.has_animation = true
	spark_elec.glow_color = Color(0.8, 0.9, 1.0, 0.5)
	spark_elec.rare = true
	_decorations[Type.SPARKING_ELECTRONICS] = spark_elec
	
	var spark_wire = Decoration.new(
		Type.SPARKING_WIRE,
		Category.DAMAGE_WEAR,
		"Sparking Wire",
		Vector2(15, 15),
		"Exposed sparking wire"
	)
	spark_wire.has_animation = true
	spark_wire.glow_color = Color(0.9, 0.9, 1.0, 0.6)
	_decorations[Type.SPARKING_WIRE] = spark_wire
	
	# Blood Stains
	var blood_small = Decoration.new(
		Type.BLOOD_STAIN_SMALL,
		Category.DAMAGE_WEAR,
		"Small Blood Stain",
		Vector2(15, 15),
		"Blood stain"
	)
	blood_small.layer = 1
	blood_small.color = Color(0.3, 0.05, 0.05, 0.5)
	blood_small.rare = true
	_decorations[Type.BLOOD_STAIN_SMALL] = blood_small
	
	var blood_large = Decoration.new(
		Type.BLOOD_STAIN_LARGE,
		Category.DAMAGE_WEAR,
		"Large Blood Stain",
		Vector2(30, 30),
		"Large blood stain"
	)
	blood_large.layer = 1
	blood_large.color = Color(0.25, 0.03, 0.03, 0.6)
	blood_large.rare = true
	_decorations[Type.BLOOD_STAIN_LARGE] = blood_large
	
	var blood_splatter = Decoration.new(
		Type.BLOOD_SPLATTER,
		Category.DAMAGE_WEAR,
		"Blood Splatter",
		Vector2(25, 25),
		"Blood splatter"
	)
	blood_splatter.layer = 8
	blood_splatter.color = Color(0.28, 0.04, 0.04, 0.55)
	blood_splatter.rare = true
	_decorations[Type.BLOOD_SPLATTER] = blood_splatter
	
	# Other Damage
	var rust = Decoration.new(
		Type.RUST_PATCH,
		Category.DAMAGE_WEAR,
		"Rust Patch",
		Vector2(25, 25),
		"Rusty area"
	)
	rust.layer = 2
	rust.color = Color(0.5, 0.3, 0.2, 0.4)
	_decorations[Type.RUST_PATCH] = rust
	
	var dent = Decoration.new(
		Type.DENT_WALL,
		Category.DAMAGE_WEAR,
		"Wall Dent",
		Vector2(30, 30),
		"Dented wall panel"
	)
	dent.wall_mounted = true
	dent.layer = 7
	dent.color = Color(0.7, 0.7, 0.7, 0.3)
	_decorations[Type.DENT_WALL] = dent
	
	var broken_panel = Decoration.new(
		Type.BROKEN_PANEL,
		Category.DAMAGE_WEAR,
		"Broken Panel",
		Vector2(35, 35),
		"Damaged panel"
	)
	broken_panel.wall_mounted = true
	broken_panel.rare = true
	_decorations[Type.BROKEN_PANEL] = broken_panel
	
	var leaking_pipe = Decoration.new(
		Type.LEAKING_PIPE,
		Category.DAMAGE_WEAR,
		"Leaking Pipe",
		Vector2(12, 60),
		"Damaged leaking pipe"
	)
	leaking_pipe.has_animation = true
	leaking_pipe.rare = true
	_decorations[Type.LEAKING_PIPE] = leaking_pipe


## Get decoration definition by type
static func get_decoration(type: Type) -> Decoration:
	_ensure_initialized()
	return _decorations.get(type, null)


## Get all decorations of a specific category
static func get_decorations_by_category(category: Category) -> Array[Decoration]:
	_ensure_initialized()
	var result: Array[Decoration] = []
	for deco in _decorations.values():
		if deco.category == category:
			result.append(deco)
	return result


## Get decorations suitable for a room type
static func get_decorations_for_room(room_tag: String) -> Array[Decoration]:
	_ensure_initialized()
	var result: Array[Decoration] = []
	for deco in _decorations.values():
		if room_tag in deco.room_type_tags or deco.room_type_tags.is_empty():
			result.append(deco)
	return result


## Get all decoration types
static func get_all_types() -> Array:
	_ensure_initialized()
	return _decorations.keys()
