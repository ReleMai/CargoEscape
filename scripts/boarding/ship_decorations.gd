# ==============================================================================
# SHIP DECORATIONS - PROCEDURAL INTERIOR PROPS AND DETAILS
# ==============================================================================
#
# FILE: scripts/boarding/ship_decorations.gd
# PURPOSE: Manages decoration spawning and rendering for ship interiors
#
# DECORATION TYPES:
# - Furniture (tables, chairs, beds, consoles)
# - Technical (pipes, vents, conduits, panels)
# - Cargo (crates, barrels, pallets)
# - Lighting (lamps, emergency lights, screens)
# - Warning (signs, floor markings, hazard stripes)
#
# NOTE: This class works with both legacy DecorationType system and
# the new DecorationData system for enhanced decorations.
#
# ==============================================================================

class_name ShipDecorations
extends Node2D


# ==============================================================================
# PRELOADS
# ==============================================================================

const DecorationDataClass = preload("res://resources/decorations/decoration_data.gd")


# ==============================================================================
# ENUMS
# ==============================================================================

enum DecorationType {
	# Furniture
	TABLE,
	CHAIR,
	BED,
	CONSOLE,
	DESK,
	COUCH,
	
	# Technical
	PIPE_HORIZONTAL,
	PIPE_VERTICAL,
	PIPE_CORNER,
	VENT,
	CONDUIT,
	CONTROL_PANEL,
	SCREEN,
	
	# Cargo
	CRATE_SMALL,
	CRATE_LARGE,
	BARREL,
	PALLET,
	
	# Lighting
	CEILING_LIGHT,
	EMERGENCY_LIGHT,
	FLOOR_LAMP,
	
	# Warning/Signs
	WARNING_STRIPE,
	FLOOR_ARROW,
	SIGN_EXIT,
	SIGN_DANGER,
	SIGN_AIRLOCK,
	
	# Room-specific
	MED_BED,
	LAB_TABLE,
	SERVER_RACK,
	WEAPON_RACK,
	LOCKER_ROW
}


# ==============================================================================
# DECORATION DATA
# ==============================================================================

class DecorationData:
	var type: DecorationType
	var position: Vector2
	var rotation: float = 0.0
	var scale: Vector2 = Vector2.ONE
	var color_tint: Color = Color.WHITE
	var layer: int = 0  # Drawing layer


# ==============================================================================
# STATE
# ==============================================================================

var _decorations: Array = []  # Array of DecorationData or legacy decorations
var _enhanced_decorations: Array = []  # Array of DecorationDataClass.DecorationPlacement
var _floor_color: Color = Color(0.15, 0.18, 0.2)
var _wall_color: Color = Color(0.25, 0.28, 0.32)
var _accent_color: Color = Color(0.6, 0.5, 0.3)
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _animation_time: float = 0.0


# ==============================================================================
# DECORATION DEFINITIONS
# ==============================================================================

const DECORATION_SIZES = {
	DecorationType.TABLE: Vector2(60, 40),
	DecorationType.CHAIR: Vector2(20, 20),
	DecorationType.BED: Vector2(80, 40),
	DecorationType.CONSOLE: Vector2(50, 25),
	DecorationType.DESK: Vector2(70, 35),
	DecorationType.COUCH: Vector2(80, 30),
	DecorationType.PIPE_HORIZONTAL: Vector2(100, 8),
	DecorationType.PIPE_VERTICAL: Vector2(8, 100),
	DecorationType.VENT: Vector2(30, 30),
	DecorationType.CONDUIT: Vector2(6, 80),
	DecorationType.CONTROL_PANEL: Vector2(40, 15),
	DecorationType.SCREEN: Vector2(35, 25),
	DecorationType.CRATE_SMALL: Vector2(25, 25),
	DecorationType.CRATE_LARGE: Vector2(40, 40),
	DecorationType.BARREL: Vector2(20, 20),
	DecorationType.PALLET: Vector2(50, 50),
	DecorationType.CEILING_LIGHT: Vector2(30, 10),
	DecorationType.EMERGENCY_LIGHT: Vector2(15, 8),
	DecorationType.FLOOR_LAMP: Vector2(12, 12),
	DecorationType.WARNING_STRIPE: Vector2(100, 10),
	DecorationType.FLOOR_ARROW: Vector2(40, 20),
	DecorationType.SIGN_EXIT: Vector2(50, 20),
	DecorationType.SIGN_DANGER: Vector2(40, 40),
	DecorationType.SIGN_AIRLOCK: Vector2(60, 25),
	DecorationType.MED_BED: Vector2(90, 45),
	DecorationType.LAB_TABLE: Vector2(80, 50),
	DecorationType.SERVER_RACK: Vector2(30, 60),
	DecorationType.WEAPON_RACK: Vector2(60, 20),
	DecorationType.LOCKER_ROW: Vector2(80, 25),
}


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_animation_time += delta
	# Only redraw if we have animated decorations
	if not _enhanced_decorations.is_empty():
		queue_redraw()


func _draw() -> void:
	# Draw legacy decorations first
	var sorted_decorations = _decorations.duplicate()
	sorted_decorations.sort_custom(func(a, b): return a.layer < b.layer)
	
	for deco in sorted_decorations:
		_draw_decoration(deco)
	
	# Draw enhanced decorations
	_draw_enhanced_decorations()


# ==============================================================================
# PUBLIC API
# ==============================================================================

func set_colors(floor_col: Color, wall_col: Color, accent_col: Color) -> void:
	_floor_color = floor_col
	_wall_color = wall_col
	_accent_color = accent_col


func clear_decorations() -> void:
	_decorations.clear()
	_enhanced_decorations.clear()
	queue_redraw()


func add_enhanced_decorations(placements: Array) -> void:
	"""Add decorations from new DecorationPlacement system"""
	_enhanced_decorations.append_array(placements)
	queue_redraw()


func set_enhanced_decorations(placements: Array) -> void:
	"""Replace all enhanced decorations"""
	_enhanced_decorations = placements.duplicate()
	queue_redraw()


func add_decoration(
	type: DecorationType, 
	pos: Vector2, 
	rot: float = 0.0,
	tint: Color = Color.WHITE
) -> void:
	var deco = DecorationData.new()
	deco.type = type
	deco.position = pos
	deco.rotation = rot
	deco.color_tint = tint
	deco.layer = _get_layer_for_type(type)
	_decorations.append(deco)


func generate_for_room(
	room_rect: Rect2, 
	room_type: String,
	seed_value: int = -1
) -> void:
	if seed_value >= 0:
		_rng.seed = seed_value
	
	match room_type.to_lower():
		"cargo bay", "cargo_bay", "cargo":
			_generate_cargo_decorations(room_rect)
		"storage", "storage_room":
			_generate_storage_decorations(room_rect)
		"crew quarters", "crew_quarters", "quarters":
			_generate_quarters_decorations(room_rect)
		"bridge", "command":
			_generate_bridge_decorations(room_rect)
		"engine room", "engine_room", "engine":
			_generate_engine_decorations(room_rect)
		"med bay", "med_bay", "medbay", "medical":
			_generate_medbay_decorations(room_rect)
		"armory", "weapons":
			_generate_armory_decorations(room_rect)
		"lab", "laboratory":
			_generate_lab_decorations(room_rect)
		"server room", "server_room", "server":
			_generate_server_decorations(room_rect)
		"corridor", "hallway":
			_generate_corridor_decorations(room_rect)
		"airlock", "entry_airlock", "exit_airlock":
			_generate_airlock_decorations(room_rect)
		_:
			_generate_generic_decorations(room_rect)
	
	queue_redraw()


# ==============================================================================
# DECORATION GENERATION BY ROOM TYPE
# ==============================================================================

func _generate_cargo_decorations(rect: Rect2) -> void:
	var margin = 30.0
	
	# Floor warning stripes near edges
	_add_wall_stripes(rect)
	
	# Random crate clusters
	var cluster_count = _rng.randi_range(2, 4)
	for i in range(cluster_count):
		var cluster_pos = Vector2(
			_rng.randf_range(rect.position.x + margin * 2, rect.end.x - margin * 2),
			_rng.randf_range(rect.position.y + margin * 2, rect.end.y - margin * 2)
		)
		_generate_crate_cluster(cluster_pos, _rng.randi_range(2, 5))
	
	# Pallets
	if rect.size.x > 150:
		var pallet_count = _rng.randi_range(1, 2)
		for i in range(pallet_count):
			add_decoration(
				DecorationType.PALLET,
				Vector2(
					_rng.randf_range(rect.position.x + margin, rect.end.x - margin),
					_rng.randf_range(rect.position.y + margin, rect.end.y - margin)
				)
			)


func _generate_storage_decorations(rect: Rect2) -> void:
	var margin = 25.0
	
	# Shelving along walls (represented by small crates)
	_add_wall_items(rect, DecorationType.CRATE_SMALL, 3, margin)
	
	# Central barrel or crate
	if _rng.randf() > 0.5:
		add_decoration(DecorationType.BARREL, rect.get_center())


func _generate_quarters_decorations(rect: Rect2) -> void:
	var margin = 20.0
	
	# Beds along wall
	var bed_count = _rng.randi_range(1, 2)
	for i in range(bed_count):
		add_decoration(
			DecorationType.BED,
			Vector2(
				rect.position.x + margin + i * 100,
				rect.position.y + margin + 20
			)
		)
	
	# Small table
	if rect.size.x > 120:
		add_decoration(
			DecorationType.TABLE,
			Vector2(rect.end.x - margin - 30, rect.end.y - margin - 20)
		)


func _generate_bridge_decorations(rect: Rect2) -> void:
	var center = rect.get_center()
	
	# Central command console
	add_decoration(
		DecorationType.CONSOLE,
		Vector2(center.x, rect.position.y + 40)
	)
	
	# Side screens
	add_decoration(
		DecorationType.SCREEN,
		Vector2(rect.position.x + 30, center.y),
		PI / 2
	)
	add_decoration(
		DecorationType.SCREEN,
		Vector2(rect.end.x - 30, center.y),
		-PI / 2
	)
	
	# Control panels
	add_decoration(
		DecorationType.CONTROL_PANEL,
		Vector2(center.x - 50, rect.end.y - 25)
	)
	add_decoration(
		DecorationType.CONTROL_PANEL,
		Vector2(center.x + 50, rect.end.y - 25)
	)


func _generate_engine_decorations(rect: Rect2) -> void:
	@warning_ignore("unused_variable")
	var margin = 25.0
	
	# Pipes along walls
	add_decoration(
		DecorationType.PIPE_HORIZONTAL,
		Vector2(rect.get_center().x, rect.position.y + 15),
		0, _accent_color
	)
	add_decoration(
		DecorationType.PIPE_HORIZONTAL,
		Vector2(rect.get_center().x, rect.end.y - 15),
		0, _accent_color
	)
	
	# Vertical conduits
	add_decoration(
		DecorationType.CONDUIT,
		Vector2(rect.position.x + 20, rect.get_center().y),
		0, Color(0.4, 0.45, 0.5)
	)
	add_decoration(
		DecorationType.CONDUIT,
		Vector2(rect.end.x - 20, rect.get_center().y),
		0, Color(0.4, 0.45, 0.5)
	)
	
	# Vents
	add_decoration(
		DecorationType.VENT,
		Vector2(rect.get_center().x, rect.get_center().y)
	)
	
	# Warning stripes
	_add_wall_stripes(rect)


func _generate_medbay_decorations(rect: Rect2) -> void:
	var margin = 25.0
	
	# Medical beds
	var bed_count = _rng.randi_range(1, 2)
	for i in range(bed_count):
		add_decoration(
			DecorationType.MED_BED,
			Vector2(
				rect.position.x + margin + 50 + i * 110,
				rect.get_center().y
			),
			0, Color(0.9, 0.95, 1.0)
		)
	
	# Medical cabinet (represented as control panel)
	add_decoration(
		DecorationType.CONTROL_PANEL,
		Vector2(rect.end.x - margin - 20, rect.position.y + margin + 10),
		0, Color(0.8, 0.9, 1.0)
	)


func _generate_armory_decorations(rect: Rect2) -> void:
	var margin = 20.0
	
	# Weapon racks along walls
	add_decoration(
		DecorationType.WEAPON_RACK,
		Vector2(rect.get_center().x, rect.position.y + margin),
		0, Color(0.5, 0.5, 0.55)
	)
	
	# Locker row
	add_decoration(
		DecorationType.LOCKER_ROW,
		Vector2(rect.get_center().x, rect.end.y - margin),
		0, Color(0.45, 0.5, 0.5)
	)
	
	# Crates for ammo
	add_decoration(
		DecorationType.CRATE_SMALL,
		Vector2(rect.position.x + margin + 15, rect.get_center().y),
		0, Color(0.6, 0.5, 0.3)
	)


func _generate_lab_decorations(rect: Rect2) -> void:
	var center = rect.get_center()
	
	# Lab table
	add_decoration(
		DecorationType.LAB_TABLE,
		center,
		0, Color(0.85, 0.9, 0.95)
	)
	
	# Screens/monitors
	add_decoration(
		DecorationType.SCREEN,
		Vector2(rect.position.x + 25, center.y),
		PI / 2, Color(0.6, 0.8, 0.9)
	)


func _generate_server_decorations(rect: Rect2) -> void:
	var margin = 25.0
	
	# Server racks in rows
	var rack_count = mini(int(rect.size.x / 50), 4)
	for i in range(rack_count):
		add_decoration(
			DecorationType.SERVER_RACK,
			Vector2(
				rect.position.x + margin + 20 + i * 45,
				rect.get_center().y
			),
			0, Color(0.3, 0.35, 0.4)
		)
	
	# Floor vents for cooling
	add_decoration(
		DecorationType.VENT,
		Vector2(rect.get_center().x, rect.end.y - margin)
	)


func _generate_corridor_decorations(rect: Rect2) -> void:
	# Floor arrows pointing toward exits
	var is_horizontal = rect.size.x > rect.size.y
	
	if is_horizontal:
		add_decoration(
			DecorationType.FLOOR_ARROW,
			Vector2(rect.position.x + 30, rect.get_center().y),
			0, Color(0.4, 0.6, 0.4, 0.5)
		)
		add_decoration(
			DecorationType.FLOOR_ARROW,
			Vector2(rect.end.x - 30, rect.get_center().y),
			PI, Color(0.4, 0.6, 0.4, 0.5)
		)
	
	# Wall lights
	add_decoration(
		DecorationType.EMERGENCY_LIGHT,
		Vector2(rect.get_center().x, rect.position.y + 10),
		0, Color(0.8, 0.9, 0.5)
	)


func _generate_airlock_decorations(rect: Rect2) -> void:
	var center = rect.get_center()
	
	# Warning stripes
	_add_wall_stripes(rect)
	
	# Airlock sign
	add_decoration(
		DecorationType.SIGN_AIRLOCK,
		Vector2(center.x, rect.position.y + 20),
		0, Color(0.3, 0.8, 0.4)
	)
	
	# Emergency lights
	add_decoration(
		DecorationType.EMERGENCY_LIGHT,
		Vector2(rect.position.x + 15, center.y),
		0, Color(1.0, 0.3, 0.3)
	)
	add_decoration(
		DecorationType.EMERGENCY_LIGHT,
		Vector2(rect.end.x - 15, center.y),
		0, Color(1.0, 0.3, 0.3)
	)


func _generate_generic_decorations(rect: Rect2) -> void:
	# Simple decorations for unspecified rooms
	if _rng.randf() > 0.5:
		add_decoration(
			DecorationType.CRATE_SMALL,
			Vector2(
				_rng.randf_range(rect.position.x + 30, rect.end.x - 30),
				_rng.randf_range(rect.position.y + 30, rect.end.y - 30)
			)
		)


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

func _generate_crate_cluster(center: Vector2, count: int) -> void:
	for i in range(count):
		var offset = Vector2(
			_rng.randf_range(-30, 30),
			_rng.randf_range(-30, 30)
		)
		var type = DecorationType.CRATE_LARGE if _rng.randf() > 0.6 else DecorationType.CRATE_SMALL
		add_decoration(type, center + offset)


func _add_wall_stripes(rect: Rect2) -> void:
	var stripe_color = Color(0.7, 0.6, 0.1, 0.4)
	
	# Bottom stripe
	add_decoration(
		DecorationType.WARNING_STRIPE,
		Vector2(rect.get_center().x, rect.end.y - 10),
		0, stripe_color
	)


func _add_wall_items(rect: Rect2, type: DecorationType, count: int, margin: float) -> void:
	for i in range(count):
		var edge = _rng.randi() % 4
		var pos: Vector2
		
		match edge:
			0:  # Top
				pos = Vector2(
					_rng.randf_range(rect.position.x + margin, rect.end.x - margin),
					rect.position.y + margin
				)
			1:  # Right
				pos = Vector2(
					rect.end.x - margin,
					_rng.randf_range(rect.position.y + margin, rect.end.y - margin)
				)
			2:  # Bottom
				pos = Vector2(
					_rng.randf_range(rect.position.x + margin, rect.end.x - margin),
					rect.end.y - margin
				)
			3:  # Left
				pos = Vector2(
					rect.position.x + margin,
					_rng.randf_range(rect.position.y + margin, rect.end.y - margin)
				)
		
		add_decoration(type, pos)


func _get_layer_for_type(type: DecorationType) -> int:
	match type:
		DecorationType.WARNING_STRIPE, DecorationType.FLOOR_ARROW:
			return 0  # Floor level
		DecorationType.PALLET:
			return 1
		DecorationType.CRATE_SMALL, DecorationType.CRATE_LARGE, DecorationType.BARREL:
			return 2
		DecorationType.TABLE, DecorationType.DESK, DecorationType.BED, DecorationType.COUCH:
			return 3
		DecorationType.CHAIR, DecorationType.CONSOLE, DecorationType.CONTROL_PANEL:
			return 4
		DecorationType.PIPE_HORIZONTAL, DecorationType.PIPE_VERTICAL, DecorationType.CONDUIT:
			return 5
		DecorationType.SCREEN, DecorationType.SIGN_EXIT, DecorationType.SIGN_DANGER:
			return 6
		_:
			return 3


# ==============================================================================
# DRAWING
# ==============================================================================

func _draw_enhanced_decorations() -> void:
	"""Draw decorations from the new system"""
	if _enhanced_decorations.is_empty():
		return
	
	# Sort by decoration layer
	var sorted = _enhanced_decorations.duplicate()
	sorted.sort_custom(func(a, b):
		var deco_a = DecorationDataClass.get_decoration(a.decoration_type)
		var deco_b = DecorationDataClass.get_decoration(b.decoration_type)
		if deco_a and deco_b:
			return deco_a.layer < deco_b.layer
		return false
	)
	
	for placement in sorted:
		_draw_enhanced_decoration(placement)


func _draw_enhanced_decoration(placement: DecorationDataClass.DecorationPlacement) -> void:
	var deco_data = DecorationDataClass.get_decoration(placement.decoration_type)
	if not deco_data:
		return
	
	var pos = placement.position
	var size = deco_data.size * placement.scale
	var color = placement.color_tint
	var rotation = placement.rotation
	
	# Apply flicker effect for animated decorations
	var alpha_mod = 1.0
	if placement.flicker_enabled and deco_data.has_animation:
		var flicker_speed = 3.0 + placement.animation_offset
		alpha_mod = 0.7 + 0.3 * sin(_animation_time * flicker_speed + placement.animation_offset)
	
	# Apply rotation transform if needed
	if rotation != 0:
		draw_set_transform(pos, rotation, Vector2.ONE)
		pos = Vector2.ZERO
	
	# Draw based on decoration type/category
	match deco_data.category:
		DecorationDataClass.Category.FUNCTIONAL:
			_draw_functional_decoration(deco_data, pos, size, color, alpha_mod)
		DecorationDataClass.Category.ATMOSPHERIC:
			_draw_atmospheric_decoration(deco_data, pos, size, color, alpha_mod)
		DecorationDataClass.Category.DAMAGE_WEAR:
			_draw_damage_decoration(deco_data, pos, size, color, alpha_mod)
	
	# Draw glow if present
	if deco_data.glow_color.a > 0:
		var glow_col = deco_data.glow_color
		glow_col.a *= alpha_mod
		draw_circle(pos, size.x * 0.8, glow_col)
	
	# Reset transform
	if rotation != 0:
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_functional_decoration(deco_data: DecorationDataClass.Decoration, pos: Vector2, size: Vector2, color: Color, alpha: float) -> void:
	var mod_color = Color(color.r, color.g, color.b, color.a * alpha)
	
	match deco_data.type:
		DecorationDataClass.Type.COMPUTER_SCREEN, DecorationDataClass.Type.COMPUTER_SCREEN_ANIMATED:
			_draw_screen(pos, size, mod_color)
		DecorationDataClass.Type.CONTROL_PANEL, DecorationDataClass.Type.CONTROL_PANEL_LARGE:
			_draw_console(pos, size, mod_color)
		DecorationDataClass.Type.PIPE_HORIZONTAL, DecorationDataClass.Type.PIPE_VERTICAL:
			_draw_pipe(pos, size, mod_color)
		DecorationDataClass.Type.VENTILATION_SHAFT, DecorationDataClass.Type.VENTILATION_VENT:
			_draw_vent(pos, size, mod_color)
		DecorationDataClass.Type.LIGHT_CEILING:
			_draw_ceiling_light(pos, size, mod_color)
		DecorationDataClass.Type.LIGHT_WALL:
			_draw_emergency_light(pos, size, mod_color)
		DecorationDataClass.Type.CONDUIT:
			_draw_conduit(pos, size, mod_color)
		_:
			# Generic functional decoration
			draw_rect(Rect2(pos - size / 2, size), Color(0.4, 0.4, 0.45) * alpha)


func _draw_atmospheric_decoration(deco_data: DecorationDataClass.Decoration, pos: Vector2, size: Vector2, color: Color, alpha: float) -> void:
	var mod_color = Color(color.r, color.g, color.b, color.a * alpha)
	
	match deco_data.type:
		DecorationDataClass.Type.POSTER_GENERIC, \
		DecorationDataClass.Type.POSTER_WARNING, \
		DecorationDataClass.Type.POSTER_MOTIVATIONAL, \
		DecorationDataClass.Type.POSTER_FACTION_CCG, \
		DecorationDataClass.Type.POSTER_FACTION_NEX, \
		DecorationDataClass.Type.POSTER_FACTION_GDF, \
		DecorationDataClass.Type.POSTER_FACTION_SYN, \
		DecorationDataClass.Type.POSTER_FACTION_IND:
			_draw_poster(pos, size, mod_color)
		DecorationDataClass.Type.SIGN_EXIT:
			_draw_sign(pos, size, mod_color, "EXIT")
		DecorationDataClass.Type.SIGN_CAUTION:
			_draw_danger_sign(pos, size, mod_color)
		DecorationDataClass.Type.PLANT_SMALL, DecorationDataClass.Type.PLANT_LARGE:
			_draw_plant(pos, size, mod_color)
		DecorationDataClass.Type.PLANT_DEAD:
			_draw_plant(pos, size, Color(0.4, 0.35, 0.3) * alpha)
		DecorationDataClass.Type.CARGO_CRATE_STACK:
			_draw_crate(pos, size, mod_color)
		DecorationDataClass.Type.CARGO_BARREL_GROUP:
			_draw_barrel(pos, size, mod_color)
		DecorationDataClass.Type.TOOL_RACK:
			_draw_tool_rack(pos, size, mod_color)
		DecorationDataClass.Type.FIRE_EXTINGUISHER:
			_draw_fire_extinguisher(pos, size, mod_color)
		_:
			# Generic atmospheric decoration
			draw_rect(Rect2(pos - size / 2, size), Color(0.5, 0.5, 0.5) * alpha)


func _draw_damage_decoration(deco_data: DecorationDataClass.Decoration, pos: Vector2, size: Vector2, color: Color, alpha: float) -> void:
	var mod_color = Color(color.r, color.g, color.b, color.a * alpha)
	
	match deco_data.type:
		DecorationDataClass.Type.SCORCH_MARK_SMALL, DecorationDataClass.Type.SCORCH_MARK_LARGE:
			_draw_scorch_mark(pos, size, mod_color)
		DecorationDataClass.Type.CRACK_WALL, DecorationDataClass.Type.CRACK_FLOOR, DecorationDataClass.Type.CRACK_CEILING:
			_draw_crack(pos, size, mod_color)
		DecorationDataClass.Type.LIGHT_FLICKERING:
			_draw_ceiling_light(pos, size, mod_color)
		DecorationDataClass.Type.SPARKING_ELECTRONICS, DecorationDataClass.Type.SPARKING_WIRE:
			_draw_sparks(pos, size, alpha)
		DecorationDataClass.Type.BLOOD_STAIN_SMALL, DecorationDataClass.Type.BLOOD_STAIN_LARGE, DecorationDataClass.Type.BLOOD_SPLATTER:
			_draw_blood_stain(pos, size, mod_color)
		DecorationDataClass.Type.RUST_PATCH:
			_draw_rust(pos, size, mod_color)
		DecorationDataClass.Type.DENT_WALL:
			_draw_dent(pos, size, mod_color)
		_:
			# Generic damage decoration
			draw_circle(pos, size.x / 2, mod_color)


# New helper drawing methods for enhanced decorations
func _draw_poster(pos: Vector2, size: Vector2, color: Color) -> void:
	var frame = Color(0.2, 0.2, 0.22)
	draw_rect(Rect2(pos - size / 2, size), frame)
	draw_rect(Rect2(pos - size / 2 + Vector2(2, 2), size - Vector2(4, 4)), color)


func _draw_plant(pos: Vector2, size: Vector2, color: Color) -> void:
	# Pot
	draw_rect(Rect2(pos.x - size.x / 3, pos.y, size.x * 0.66, size.y / 3), Color(0.3, 0.25, 0.2))
	# Leaves
	draw_circle(pos - Vector2(0, size.y / 3), size.x / 2, color)


func _draw_tool_rack(pos: Vector2, size: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos - size / 2, size), color)
	# Tools
	for i in range(3):
		var x = pos.x - size.x / 3 + i * size.x / 3
		draw_line(Vector2(x, pos.y - size.y / 4), Vector2(x, pos.y + size.y / 4), Color(0.5, 0.5, 0.55), 2)


func _draw_fire_extinguisher(pos: Vector2, size: Vector2, _color: Color) -> void:
	draw_rect(Rect2(pos - size / 2, size), Color(0.8, 0.1, 0.1))
	draw_circle(pos, 3, Color(0.2, 0.2, 0.2))


func _draw_scorch_mark(pos: Vector2, size: Vector2, color: Color) -> void:
	# Irregular scorch pattern
	draw_circle(pos, size.x / 2, color)
	draw_circle(pos + Vector2(size.x / 4, 0), size.x / 3, Color(color.r, color.g, color.b, color.a * 0.6))


func _draw_crack(pos: Vector2, size: Vector2, color: Color) -> void:
	# Jagged crack line
	var points = PackedVector2Array([
		pos - Vector2(size.x / 2, 0),
		pos - Vector2(size.x / 4, size.y / 6),
		pos,
		pos + Vector2(size.x / 4, -size.y / 6),
		pos + Vector2(size.x / 2, 0)
	])
	draw_polyline(points, color, 1.5)


func _draw_sparks(pos: Vector2, size: Vector2, alpha: float) -> void:
	# Animated sparks
	for i in range(3):
		var angle = _animation_time * 5 + i * TAU / 3
		var offset = Vector2(cos(angle), sin(angle)) * size.x / 2
		draw_circle(pos + offset, 2, Color(1.0, 0.9, 0.3, alpha))


func _draw_blood_stain(pos: Vector2, size: Vector2, color: Color) -> void:
	# Splatter effect
	draw_circle(pos, size.x / 2, color)
	for i in range(4):
		var angle = i * TAU / 4 + 0.3
		var offset = Vector2(cos(angle), sin(angle)) * size.x * 0.4
		draw_circle(pos + offset, size.x / 4, Color(color.r, color.g, color.b, color.a * 0.7))


func _draw_rust(pos: Vector2, size: Vector2, color: Color) -> void:
	# Irregular rust patch
	draw_circle(pos, size.x / 2, color)
	draw_circle(pos + Vector2(size.x / 3, size.y / 3), size.x / 3, Color(color.r * 0.8, color.g * 0.8, color.b * 0.8, color.a))


func _draw_dent(pos: Vector2, size: Vector2, color: Color) -> void:
	# Concave dent effect
	draw_circle(pos, size.x / 2, color)
	draw_circle(pos, size.x / 3, Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, color.a))


# ==============================================================================
# LEGACY DRAWING
# ==============================================================================

func _draw_decoration(deco: DecorationData) -> void:
	var size = DECORATION_SIZES.get(deco.type, Vector2(20, 20))
	var pos = deco.position
	var color = deco.color_tint
	
	# Apply rotation transform if needed
	if deco.rotation != 0:
		draw_set_transform(pos, deco.rotation, Vector2.ONE)
		pos = Vector2.ZERO
	
	match deco.type:
		# Tables and furniture
		DecorationType.TABLE, DecorationType.DESK:
			_draw_table(pos, size, color)
		DecorationType.CHAIR:
			_draw_chair(pos, size, color)
		DecorationType.BED, DecorationType.MED_BED:
			_draw_bed(pos, size, color)
		DecorationType.COUCH:
			_draw_couch(pos, size, color)
		DecorationType.CONSOLE, DecorationType.CONTROL_PANEL:
			_draw_console(pos, size, color)
		
		# Technical
		DecorationType.PIPE_HORIZONTAL, DecorationType.PIPE_VERTICAL:
			_draw_pipe(pos, size, color)
		DecorationType.VENT:
			_draw_vent(pos, size, color)
		DecorationType.CONDUIT:
			_draw_conduit(pos, size, color)
		DecorationType.SCREEN:
			_draw_screen(pos, size, color)
		DecorationType.SERVER_RACK:
			_draw_server_rack(pos, size, color)
		
		# Cargo
		DecorationType.CRATE_SMALL, DecorationType.CRATE_LARGE:
			_draw_crate(pos, size, color)
		DecorationType.BARREL:
			_draw_barrel(pos, size, color)
		DecorationType.PALLET:
			_draw_pallet(pos, size, color)
		
		# Signs and warnings
		DecorationType.WARNING_STRIPE:
			_draw_warning_stripe(pos, size, color)
		DecorationType.FLOOR_ARROW:
			_draw_floor_arrow(pos, size, color)
		DecorationType.SIGN_EXIT, DecorationType.SIGN_AIRLOCK:
			_draw_sign(pos, size, color, "EXIT" if deco.type == DecorationType.SIGN_EXIT else "AIRLOCK")
		DecorationType.SIGN_DANGER:
			_draw_danger_sign(pos, size, color)
		
		# Lighting
		DecorationType.CEILING_LIGHT:
			_draw_ceiling_light(pos, size, color)
		DecorationType.EMERGENCY_LIGHT:
			_draw_emergency_light(pos, size, color)
		
		# Room-specific
		DecorationType.LAB_TABLE:
			_draw_lab_table(pos, size, color)
		DecorationType.WEAPON_RACK:
			_draw_weapon_rack(pos, size, color)
		DecorationType.LOCKER_ROW:
			_draw_locker_row(pos, size, color)
	
	# Reset transform
	if deco.rotation != 0:
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# Individual drawing functions
func _draw_table(pos: Vector2, size: Vector2, color: Color) -> void:
	var dark = Color(color.r * 0.7, color.g * 0.7, color.b * 0.7)
	draw_rect(Rect2(pos - size / 2, size), dark)
	draw_rect(Rect2(pos - size / 2 + Vector2(3, 3), size - Vector2(6, 6)), color)


func _draw_chair(pos: Vector2, size: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos - size / 2, size), Color(color.r * 0.6, color.g * 0.6, color.b * 0.6))


func _draw_bed(pos: Vector2, size: Vector2, color: Color) -> void:
	var frame_col = Color(0.4, 0.4, 0.45)
	var sheet_col = color
	draw_rect(Rect2(pos - size / 2, size), frame_col)
	draw_rect(Rect2(pos - size / 2 + Vector2(4, 4), size - Vector2(8, 8)), sheet_col)


func _draw_couch(pos: Vector2, size: Vector2, color: Color) -> void:
	var dark = Color(color.r * 0.6, color.g * 0.6, color.b * 0.6)
	draw_rect(Rect2(pos - size / 2, size), dark)
	draw_rect(Rect2(pos - size / 2 + Vector2(5, 5), size - Vector2(10, 15)), color)


func _draw_console(pos: Vector2, size: Vector2, _color: Color) -> void:
	var body_col = Color(0.3, 0.32, 0.35)
	var screen_col = Color(0.2, 0.4, 0.5)
	draw_rect(Rect2(pos - size / 2, size), body_col)
	draw_rect(Rect2(pos - size / 2 + Vector2(3, 2), size - Vector2(6, 6)), screen_col)
	# Indicator lights
	draw_circle(pos + Vector2(-size.x / 4, size.y / 3), 2, Color(0.2, 0.8, 0.3))
	draw_circle(pos + Vector2(size.x / 4, size.y / 3), 2, Color(0.8, 0.7, 0.2))


func _draw_pipe(pos: Vector2, size: Vector2, _color: Color) -> void:
	var pipe_col = Color(0.5, 0.55, 0.6)
	var highlight = Color(0.6, 0.65, 0.7)
	draw_rect(Rect2(pos - size / 2, size), pipe_col)
	# Highlight stripe
	if size.x > size.y:
		draw_rect(Rect2(pos.x - size.x / 2, pos.y - 1, size.x, 2), highlight)
	else:
		draw_rect(Rect2(pos.x - 1, pos.y - size.y / 2, 2, size.y), highlight)


func _draw_vent(pos: Vector2, size: Vector2, _color: Color) -> void:
	var frame_col = Color(0.4, 0.42, 0.45)
	var grate_col = Color(0.25, 0.28, 0.3)
	draw_rect(Rect2(pos - size / 2, size), frame_col)
	# Grate lines
	var step = 6
	for i in range(int(size.x / step)):
		var x = pos.x - size.x / 2 + i * step + 3
		draw_line(Vector2(x, pos.y - size.y / 2 + 2), Vector2(x, pos.y + size.y / 2 - 2), grate_col, 2)


func _draw_conduit(pos: Vector2, size: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos - size / 2, size), color)


func _draw_screen(pos: Vector2, size: Vector2, color: Color) -> void:
	var frame = Color(0.3, 0.3, 0.35)
	var screen = color if color != Color.WHITE else Color(0.15, 0.3, 0.4)
	draw_rect(Rect2(pos - size / 2, size), frame)
	draw_rect(Rect2(pos - size / 2 + Vector2(2, 2), size - Vector2(4, 4)), screen)


func _draw_server_rack(pos: Vector2, size: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos - size / 2, size), color)
	# Server units
	var unit_height = 10
	var units = int(size.y / unit_height) - 1
	for i in range(units):
		var y = pos.y - size.y / 2 + 5 + i * unit_height
		draw_rect(Rect2(pos.x - size.x / 2 + 2, y, size.x - 4, unit_height - 2), Color(0.2, 0.22, 0.25))
		# Status light
		draw_circle(Vector2(pos.x + size.x / 2 - 6, y + 4), 2, Color(0.2, 0.8, 0.3))


func _draw_crate(pos: Vector2, size: Vector2, color: Color) -> void:
	var main_col = Color(0.5, 0.4, 0.3) if color == Color.WHITE else color
	var dark = Color(main_col.r * 0.7, main_col.g * 0.7, main_col.b * 0.7)
	draw_rect(Rect2(pos - size / 2, size), dark)
	draw_rect(Rect2(pos - size / 2 + Vector2(2, 2), size - Vector2(4, 4)), main_col)
	# Cross straps
	draw_line(pos - size / 2, pos + size / 2, dark, 2)
	draw_line(Vector2(pos.x + size.x / 2, pos.y - size.y / 2), Vector2(pos.x - size.x / 2, pos.y + size.y / 2), dark, 2)


func _draw_barrel(pos: Vector2, size: Vector2, _color: Color) -> void:
	var barrel_col = Color(0.45, 0.4, 0.35)
	draw_circle(pos, size.x / 2, barrel_col)
	draw_circle(pos, size.x / 2 - 3, Color(barrel_col.r * 1.1, barrel_col.g * 1.1, barrel_col.b * 1.1))


func _draw_pallet(pos: Vector2, size: Vector2, _color: Color) -> void:
	var wood_col = Color(0.5, 0.4, 0.3)
	# Slats
	var slat_count = 4
	var slat_width = size.x / slat_count - 2
	for i in range(slat_count):
		var x = pos.x - size.x / 2 + i * (size.x / slat_count) + 2
		draw_rect(Rect2(x, pos.y - size.y / 2, slat_width, size.y), wood_col)


func _draw_warning_stripe(pos: Vector2, size: Vector2, color: Color) -> void:
	var stripe_width = 15
	var stripes = int(size.x / stripe_width)
	for i in range(stripes):
		if i % 2 == 0:
			var x = pos.x - size.x / 2 + i * stripe_width
			draw_rect(Rect2(x, pos.y - size.y / 2, stripe_width, size.y), color)


func _draw_floor_arrow(pos: Vector2, size: Vector2, color: Color) -> void:
	var points = PackedVector2Array([
		pos + Vector2(-size.x / 2, 0),
		pos + Vector2(0, -size.y / 2),
		pos + Vector2(0, -size.y / 4),
		pos + Vector2(size.x / 2, -size.y / 4),
		pos + Vector2(size.x / 2, size.y / 4),
		pos + Vector2(0, size.y / 4),
		pos + Vector2(0, size.y / 2),
	])
	draw_colored_polygon(points, color)


func _draw_sign(pos: Vector2, size: Vector2, color: Color, _text: String) -> void:
	var bg = Color(0.15, 0.15, 0.18)
	draw_rect(Rect2(pos - size / 2, size), bg)
	draw_rect(Rect2(pos - size / 2 + Vector2(2, 2), size - Vector2(4, 4)), color)


func _draw_danger_sign(pos: Vector2, size: Vector2, color: Color) -> void:
	var bg = Color(0.8, 0.2, 0.1) if color == Color.WHITE else color
	# Triangle
	var points = PackedVector2Array([
		pos + Vector2(0, -size.y / 2),
		pos + Vector2(-size.x / 2, size.y / 2),
		pos + Vector2(size.x / 2, size.y / 2),
	])
	draw_colored_polygon(points, bg)
	# Exclamation
	draw_rect(Rect2(pos.x - 2, pos.y - size.y / 4, 4, size.y / 3), Color.WHITE)
	draw_circle(Vector2(pos.x, pos.y + size.y / 4), 3, Color.WHITE)


func _draw_ceiling_light(pos: Vector2, size: Vector2, color: Color) -> void:
	var fixture = Color(0.5, 0.5, 0.55)
	draw_rect(Rect2(pos - size / 2, size), fixture)
	# Light glow
	draw_rect(Rect2(pos.x - size.x / 2 + 3, pos.y - 2, size.x - 6, 4), color)


func _draw_emergency_light(pos: Vector2, size: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos - size / 2, size), Color(0.3, 0.3, 0.32))
	draw_circle(pos, 3, color)


func _draw_lab_table(pos: Vector2, size: Vector2, color: Color) -> void:
	_draw_table(pos, size, color)
	# Equipment on table
	draw_circle(pos + Vector2(-size.x / 4, 0), 5, Color(0.4, 0.6, 0.7))
	draw_rect(Rect2(pos.x + size.x / 6, pos.y - 5, 15, 10), Color(0.5, 0.55, 0.6))


func _draw_weapon_rack(pos: Vector2, size: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos - size / 2, size), color)
	# Weapon slots
	var slots = 4
	for i in range(slots):
		var x = pos.x - size.x / 2 + 10 + i * (size.x - 20) / slots
		draw_rect(Rect2(x, pos.y - 3, 8, 6), Color(0.3, 0.3, 0.32))


func _draw_locker_row(pos: Vector2, size: Vector2, color: Color) -> void:
	var locker_width = 18
	var lockers = int(size.x / locker_width)
	for i in range(lockers):
		var x = pos.x - size.x / 2 + i * locker_width + 1
		var locker_col = color if i % 2 == 0 else Color(color.r * 0.9, color.g * 0.9, color.b * 0.9)
		draw_rect(Rect2(x, pos.y - size.y / 2, locker_width - 2, size.y), locker_col)
		# Handle
		draw_circle(Vector2(x + locker_width - 5, pos.y), 2, Color(0.6, 0.6, 0.65))
