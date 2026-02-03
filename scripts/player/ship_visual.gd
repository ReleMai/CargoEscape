# ==============================================================================
# SHIP VISUAL - PROCEDURAL SHIP RENDERING WITH MODULES
# ==============================================================================
#
# FILE: scripts/player/ship_visual.gd
# PURPOSE: Draws the player ship procedurally with equipped modules visible
#
# SHIP TYPES:
# - Shuttle: Small, fast, minimal cargo
# - Cargo: Large, slow, maximum cargo
# - Fighter: Balanced, combat-focused
#
# MODULE SLOTS:
# Each ship has 3 slots visualized on the hull
# - Flight module: Engine area (back of ship)
# - Combat module: Weapon mount (top/front)
# - Utility module: Side pod (bottom)
#
# ==============================================================================

extends Node2D
class_name ShipVisual


# ==============================================================================
# ENUMS
# ==============================================================================

enum ShipType {
	SHUTTLE,   # Small, nimble, light cargo
	CARGO,     # Big, slow, lots of storage
	FIGHTER    # Medium, combat-focused
}


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Ship Configuration")

## Type of ship to draw
@export var ship_type: ShipType = ShipType.SHUTTLE

## Overall scale of the ship visual
@export_range(0.5, 2.0, 0.1) var ship_scale: float = 1.0


@export_group("Colors")

## Main hull color
@export var hull_color: Color = Color(0.25, 0.35, 0.45, 1.0)

## Hull accent/trim color
@export var accent_color: Color = Color(0.15, 0.6, 0.8, 1.0)

## Window/cockpit color
@export var window_color: Color = Color(0.3, 0.7, 0.9, 0.8)

## Engine glow color
@export var engine_color: Color = Color(0.2, 0.6, 1.0, 1.0)


# ==============================================================================
# STATE
# ==============================================================================

## Currently equipped modules (slot_type -> ShipModule)
var equipped_modules: Dictionary = {}

## Engine flame intensity (0-1, for animation)
var engine_intensity: float = 0.5

## Whether engines are firing
var engines_active: bool = true


# ==============================================================================
# CACHED MEASUREMENTS
# ==============================================================================

var hull_length: float = 60.0
var hull_width: float = 40.0


# ==============================================================================
# LIFECYCLE
# ==============================================================================

var _redraw_timer: float = 0.0
const REDRAW_INTERVAL: float = 0.033  # ~30 FPS for ship animation

func _ready() -> void:
	_configure_ship_dimensions()


func _process(delta: float) -> void:
	# Animate engine glow
	if engines_active:
		engine_intensity = 0.6 + sin(Time.get_ticks_msec() * 0.01) * 0.3
		# Throttle redraws when engines are active
		_redraw_timer += delta
		if _redraw_timer >= REDRAW_INTERVAL:
			_redraw_timer = 0.0
			queue_redraw()
	# Don't redraw when engines are off - ship is static


func _draw() -> void:
	match ship_type:
		ShipType.SHUTTLE:
			_draw_shuttle()
		ShipType.CARGO:
			_draw_cargo()
		ShipType.FIGHTER:
			_draw_fighter()
	
	# Draw equipped modules on top
	_draw_equipped_modules()
	
	# Draw engine effects last
	if engines_active:
		_draw_engine_flames()


# ==============================================================================
# CONFIGURATION
# ==============================================================================

func _configure_ship_dimensions() -> void:
	match ship_type:
		ShipType.SHUTTLE:
			hull_length = 50.0 * ship_scale
			hull_width = 30.0 * ship_scale
		ShipType.CARGO:
			hull_length = 70.0 * ship_scale
			hull_width = 50.0 * ship_scale
		ShipType.FIGHTER:
			hull_length = 55.0 * ship_scale
			hull_width = 35.0 * ship_scale


# ==============================================================================
# SHUTTLE DRAWING
# ==============================================================================

func _draw_shuttle() -> void:
	var l := hull_length
	var w := hull_width
	
	# Main hull - sleek wedge shape
	var hull_points := PackedVector2Array([
		Vector2(l * 0.5, 0),           # Nose
		Vector2(l * 0.2, -w * 0.3),    # Upper front
		Vector2(-l * 0.4, -w * 0.4),   # Upper back
		Vector2(-l * 0.5, -w * 0.25),  # Back top
		Vector2(-l * 0.5, w * 0.25),   # Back bottom
		Vector2(-l * 0.4, w * 0.4),    # Lower back
		Vector2(l * 0.2, w * 0.3),     # Lower front
	])
	draw_polygon(hull_points, [hull_color])
	
	# Hull outline
	draw_polyline(hull_points, accent_color.darkened(0.2), 2.0, true)
	
	# Cockpit window
	var cockpit_points := PackedVector2Array([
		Vector2(l * 0.35, 0),
		Vector2(l * 0.15, -w * 0.15),
		Vector2(-l * 0.05, -w * 0.12),
		Vector2(-l * 0.05, w * 0.12),
		Vector2(l * 0.15, w * 0.15),
	])
	draw_polygon(cockpit_points, [window_color])
	
	# Accent stripes
	var stripe_color := accent_color
	draw_line(Vector2(-l * 0.3, -w * 0.35), Vector2(l * 0.1, -w * 0.22), stripe_color, 3.0)
	draw_line(Vector2(-l * 0.3, w * 0.35), Vector2(l * 0.1, w * 0.22), stripe_color, 3.0)
	
	# Engine housing
	var engine_rect := Rect2(Vector2(-l * 0.55, -w * 0.2), Vector2(l * 0.15, w * 0.4))
	draw_rect(engine_rect, hull_color.darkened(0.2))
	
	# Module slot indicators (empty slots glow subtly)
	_draw_module_slot(Vector2(-l * 0.4, 0), 0)        # Flight slot (back)
	_draw_module_slot(Vector2(l * 0.1, -w * 0.35), 1) # Combat slot (top)
	_draw_module_slot(Vector2(-l * 0.1, w * 0.35), 2) # Utility slot (bottom)


# ==============================================================================
# CARGO SHIP DRAWING
# ==============================================================================

func _draw_cargo() -> void:
	var l := hull_length
	var w := hull_width
	
	# Main hull - boxy cargo shape
	var hull_points := PackedVector2Array([
		Vector2(l * 0.4, -w * 0.15),   # Nose top
		Vector2(l * 0.45, 0),           # Nose tip
		Vector2(l * 0.4, w * 0.15),    # Nose bottom
		Vector2(l * 0.2, w * 0.4),     # Front bottom
		Vector2(-l * 0.4, w * 0.45),   # Back bottom
		Vector2(-l * 0.5, w * 0.3),    # Engine bottom
		Vector2(-l * 0.5, -w * 0.3),   # Engine top
		Vector2(-l * 0.4, -w * 0.45),  # Back top
		Vector2(l * 0.2, -w * 0.4),    # Front top
	])
	draw_polygon(hull_points, [hull_color])
	draw_polyline(hull_points, accent_color.darkened(0.3), 2.0, true)
	
	# Cargo bay panels
	var panel_color := hull_color.lightened(0.1)
	for i in 3:
		var x := -l * 0.2 + i * l * 0.2
		var panel := Rect2(Vector2(x - l * 0.08, -w * 0.35), Vector2(l * 0.14, w * 0.7))
		draw_rect(panel, panel_color)
		draw_rect(panel, accent_color.darkened(0.4), false, 1.0)
	
	# Cockpit (smaller, utilitarian)
	var cockpit := PackedVector2Array([
		Vector2(l * 0.38, 0),
		Vector2(l * 0.28, -w * 0.1),
		Vector2(l * 0.15, -w * 0.08),
		Vector2(l * 0.15, w * 0.08),
		Vector2(l * 0.28, w * 0.1),
	])
	draw_polygon(cockpit, [window_color])
	
	# Dual engines
	var engine_top := Rect2(Vector2(-l * 0.55, -w * 0.35), Vector2(l * 0.12, w * 0.2))
	var engine_bot := Rect2(Vector2(-l * 0.55, w * 0.15), Vector2(l * 0.12, w * 0.2))
	draw_rect(engine_top, hull_color.darkened(0.3))
	draw_rect(engine_bot, hull_color.darkened(0.3))
	
	# Module slots
	_draw_module_slot(Vector2(-l * 0.45, 0), 0)        # Flight (center back)
	_draw_module_slot(Vector2(l * 0.25, -w * 0.45), 1) # Combat (top turret)
	_draw_module_slot(Vector2(-l * 0.25, w * 0.45), 2) # Utility (bottom pod)


# ==============================================================================
# FIGHTER DRAWING
# ==============================================================================

func _draw_fighter() -> void:
	var l := hull_length
	var w := hull_width
	
	# Main hull - aggressive angular shape
	var hull_points := PackedVector2Array([
		Vector2(l * 0.55, 0),           # Sharp nose
		Vector2(l * 0.25, -w * 0.2),    # Upper nose
		Vector2(-l * 0.1, -w * 0.35),   # Wing root top
		Vector2(-l * 0.45, -w * 0.3),   # Back top
		Vector2(-l * 0.5, 0),           # Back center
		Vector2(-l * 0.45, w * 0.3),    # Back bottom
		Vector2(-l * 0.1, w * 0.35),    # Wing root bottom
		Vector2(l * 0.25, w * 0.2),     # Lower nose
	])
	draw_polygon(hull_points, [hull_color])
	draw_polyline(hull_points, accent_color.darkened(0.2), 2.0, true)
	
	# Wings
	var wing_top := PackedVector2Array([
		Vector2(-l * 0.1, -w * 0.35),
		Vector2(l * 0.05, -w * 0.6),
		Vector2(-l * 0.35, -w * 0.55),
		Vector2(-l * 0.4, -w * 0.35),
	])
	var wing_bot := PackedVector2Array([
		Vector2(-l * 0.1, w * 0.35),
		Vector2(l * 0.05, w * 0.6),
		Vector2(-l * 0.35, w * 0.55),
		Vector2(-l * 0.4, w * 0.35),
	])
	draw_polygon(wing_top, [hull_color.darkened(0.1)])
	draw_polygon(wing_bot, [hull_color.darkened(0.1)])
	
	# Wing stripes
	draw_line(Vector2(-l * 0.05, -w * 0.45), Vector2(-l * 0.3, -w * 0.45), accent_color, 2.0)
	draw_line(Vector2(-l * 0.05, w * 0.45), Vector2(-l * 0.3, w * 0.45), accent_color, 2.0)
	
	# Cockpit
	var cockpit := PackedVector2Array([
		Vector2(l * 0.4, 0),
		Vector2(l * 0.2, -w * 0.12),
		Vector2(-l * 0.05, -w * 0.1),
		Vector2(-l * 0.05, w * 0.1),
		Vector2(l * 0.2, w * 0.12),
	])
	draw_polygon(cockpit, [window_color])
	
	# Central engine
	var engine := Rect2(Vector2(-l * 0.55, -w * 0.15), Vector2(l * 0.12, w * 0.3))
	draw_rect(engine, hull_color.darkened(0.3))
	
	# Module slots
	_draw_module_slot(Vector2(-l * 0.45, 0), 0)        # Flight (back)
	_draw_module_slot(Vector2(l * 0.15, -w * 0.25), 1) # Combat (weapon hardpoint)
	_draw_module_slot(Vector2(-l * 0.2, w * 0.4), 2)   # Utility (wing pod)


# ==============================================================================
# MODULE RENDERING
# ==============================================================================

func _draw_module_slot(pos: Vector2, slot_type: int) -> void:
	# Only draw empty slot indicator if no module equipped
	if equipped_modules.has(slot_type):
		return
	
	# Empty slot - subtle glow circle
	var slot_color := Color(0.3, 0.3, 0.3, 0.4)
	draw_circle(pos, 6.0 * ship_scale, slot_color)
	draw_arc(pos, 6.0 * ship_scale, 0, TAU, 16, slot_color.lightened(0.3), 1.0)


func _draw_equipped_modules() -> void:
	for slot_type in equipped_modules:
		var module: ShipModule = equipped_modules[slot_type]
		if module:
			var pos := _get_module_position(slot_type)
			_draw_module_at(module, pos)


func _get_module_position(slot_type: int) -> Vector2:
	var l := hull_length
	var w := hull_width
	
	match ship_type:
		ShipType.SHUTTLE:
			match slot_type:
				0: return Vector2(-l * 0.4, 0)        # Flight
				1: return Vector2(l * 0.1, -w * 0.35) # Combat
				2: return Vector2(-l * 0.1, w * 0.35) # Utility
		ShipType.CARGO:
			match slot_type:
				0: return Vector2(-l * 0.45, 0)
				1: return Vector2(l * 0.25, -w * 0.45)
				2: return Vector2(-l * 0.25, w * 0.45)
		ShipType.FIGHTER:
			match slot_type:
				0: return Vector2(-l * 0.45, 0)
				1: return Vector2(l * 0.15, -w * 0.25)
				2: return Vector2(-l * 0.2, w * 0.4)
	
	return Vector2.ZERO


func _draw_module_at(module: ShipModule, pos: Vector2) -> void:
	var scale := module.visual_scale * ship_scale * 8.0
	
	match module.slot_type:
		ShipModule.ModuleSlot.FLIGHT:
			_draw_engine_module(module, pos, scale)
		ShipModule.ModuleSlot.COMBAT:
			_draw_weapon_module(module, pos, scale)
		ShipModule.ModuleSlot.UTILITY:
			_draw_utility_module(module, pos, scale)


func _draw_weapon_module(module: ShipModule, pos: Vector2, scale: float) -> void:
	# Weapon turret/barrel
	var barrel_length := scale * 1.5
	var barrel_width := scale * 0.4
	
	# Base mount
	draw_circle(pos, scale * 0.6, module.secondary_color.darkened(0.2))
	
	# Barrel
	var barrel_rect := Rect2(
		pos + Vector2(0, -barrel_width * 0.5),
		Vector2(barrel_length, barrel_width)
	)
	draw_rect(barrel_rect, module.primary_color)
	
	# Barrel tip glow
	var tip_pos := pos + Vector2(barrel_length, 0)
	draw_circle(tip_pos, scale * 0.25, module.glow_color)
	
	# Rarity glow
	var rarity_color := module.get_rarity_color()
	draw_arc(pos, scale * 0.7, 0, TAU, 12, rarity_color, 1.5)


func _draw_engine_module(module: ShipModule, pos: Vector2, scale: float) -> void:
	# Engine housing
	var housing_size := Vector2(scale * 0.8, scale * 1.2)
	var housing_rect := Rect2(pos - housing_size * 0.5, housing_size)
	draw_rect(housing_rect, module.secondary_color.darkened(0.2))
	
	# Engine cone
	var cone_points := PackedVector2Array([
		pos + Vector2(-scale * 0.5, -scale * 0.4),
		pos + Vector2(-scale * 0.5, scale * 0.4),
		pos + Vector2(scale * 0.3, scale * 0.2),
		pos + Vector2(scale * 0.3, -scale * 0.2),
	])
	draw_polygon(cone_points, [module.primary_color])


func _draw_utility_module(module: ShipModule, pos: Vector2, scale: float) -> void:
	# Pod shape
	var pod_points := PackedVector2Array([
		pos + Vector2(scale * 0.5, 0),
		pos + Vector2(scale * 0.2, -scale * 0.4),
		pos + Vector2(-scale * 0.4, -scale * 0.3),
		pos + Vector2(-scale * 0.4, scale * 0.3),
		pos + Vector2(scale * 0.2, scale * 0.4),
	])
	draw_polygon(pod_points, [module.primary_color])
	draw_polyline(pod_points, module.secondary_color, 1.5, true)
	
	# Center detail
	draw_circle(pos, scale * 0.2, module.glow_color)


# ==============================================================================
# ENGINE EFFECTS
# ==============================================================================

func _draw_engine_flames() -> void:
	var l := hull_length
	var w := hull_width
	var intensity := engine_intensity
	
	var flame_color := engine_color
	flame_color.a = intensity * 0.8
	var flame_core := Color(0.8, 0.9, 1.0, intensity)
	
	match ship_type:
		ShipType.SHUTTLE:
			_draw_flame(Vector2(-l * 0.55, 0), l * 0.4 * intensity, w * 0.25, flame_color, flame_core)
		ShipType.CARGO:
			_draw_flame(Vector2(-l * 0.55, -w * 0.25), l * 0.35 * intensity, w * 0.12, flame_color, flame_core)
			_draw_flame(Vector2(-l * 0.55, w * 0.25), l * 0.35 * intensity, w * 0.12, flame_color, flame_core)
		ShipType.FIGHTER:
			_draw_flame(Vector2(-l * 0.55, 0), l * 0.5 * intensity, w * 0.18, flame_color, flame_core)


func _draw_flame(pos: Vector2, length: float, width: float, color: Color, core_color: Color) -> void:
	# Outer flame
	var flame_points := PackedVector2Array([
		pos + Vector2(0, -width),
		pos + Vector2(-length * 0.5, -width * 0.6),
		pos + Vector2(-length, 0),
		pos + Vector2(-length * 0.5, width * 0.6),
		pos + Vector2(0, width),
	])
	draw_polygon(flame_points, [color])
	
	# Inner core
	var core_points := PackedVector2Array([
		pos + Vector2(0, -width * 0.5),
		pos + Vector2(-length * 0.6, 0),
		pos + Vector2(0, width * 0.5),
	])
	draw_polygon(core_points, [core_color])


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Equip a module to the ship
func equip_module(module: ShipModule) -> void:
	equipped_modules[module.slot_type] = module
	queue_redraw()


## Remove a module from a slot
func unequip_module(slot_type: int) -> void:
	equipped_modules.erase(slot_type)
	queue_redraw()


## Get equipped module in a slot
func get_module(slot_type: int) -> ShipModule:
	return equipped_modules.get(slot_type)


## Set engine active state
func set_engines_active(active: bool) -> void:
	engines_active = active
	queue_redraw()


## Change ship type and reconfigure
func set_ship_type(type: ShipType) -> void:
	ship_type = type
	_configure_ship_dimensions()
	queue_redraw()


## Set all colors at once
func set_colors(hull: Color, accent: Color, window: Color, engine: Color) -> void:
	hull_color = hull
	accent_color = accent
	window_color = window
	engine_color = engine
	queue_redraw()
