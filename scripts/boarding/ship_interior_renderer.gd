# ==============================================================================
# SHIP INTERIOR RENDERER - PROCEDURAL ROOM DRAWING
# ==============================================================================
#
# FILE: scripts/boarding/ship_interior_renderer.gd
# PURPOSE: Draws ship interior based on generated layout data
#
# FEATURES:
# - Procedural room rendering from layout data
# - Visual variety per ship tier
# - Wall collision generation
# - Room labels and decorations
# - Space background with parallax stars
# - Enhanced procedural decorations per room type
#
# ==============================================================================

extends Node2D
class_name ShipInteriorRenderer


# ==============================================================================
# SIGNALS
# ==============================================================================

signal interior_ready


# ==============================================================================
# ROOM NAMES BY TIER
# ==============================================================================

const TIER1_ROOMS = ["CARGO HOLD", "STORAGE"]
const TIER2_ROOMS = [
	"CARGO BAY A", "CARGO BAY B", "STORAGE", "CORRIDOR", 
	"SUPPLY ROOM", "CREW QUARTERS"
]
const TIER3_ROOMS = [
	"EXECUTIVE SUITE", "CONFERENCE", "ATRIUM", 
	"VIP LOUNGE", "OFFICE", "CORRIDOR"
]
const TIER4_ROOMS = [
	"BRIDGE", "ARMORY", "ENGINE ROOM", "BARRACKS", 
	"WEAPONS BAY", "MED BAY", "CORRIDOR"
]
const TIER5_ROOMS = [
	"COMMAND", "VAULT", "LAB", "SERVER ROOM", 
	"STEALTH SYS", "ARCHIVES", "CORRIDOR", "AIRLOCK"
]

# Preloads for enhanced features
const DoorScript = preload("res://scripts/boarding/door.gd")
const DecoScript = preload("res://scripts/boarding/ship_decorations.gd")


# ==============================================================================
# EXPORTS
# ==============================================================================

@export var draw_room_labels: bool = true
@export var draw_decorations: bool = true
@export var enable_space_background: bool = true
@export var enable_enhanced_decorations: bool = true


# ==============================================================================
# STATE
# ==============================================================================

var current_layout: RefCounted = null  # ShipLayout.LayoutData
var ship_tier: int = 1
var wall_bodies: Array[StaticBody2D] = []

# Enhanced visual components
var space_background: Node2D = null
var decorations_node: Node2D = null
var doors: Array[Node2D] = []


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Render the interior based on layout data
func render_layout(layout: RefCounted, tier: int) -> void:
	current_layout = layout
	ship_tier = tier
	
	# Clear existing walls and visuals
	_clear_walls()
	_clear_enhanced_visuals()
	
	# Create space background first (behind everything)
	if enable_space_background:
		_create_space_background()
	
	# Create wall collisions
	_create_wall_collisions()
	
	# Create enhanced decorations
	if enable_enhanced_decorations:
		_create_enhanced_decorations()
	
	# Create doors between rooms
	_create_doors()
	
	# Redraw
	queue_redraw()
	
	emit_signal("interior_ready")


func _clear_enhanced_visuals() -> void:
	if space_background and is_instance_valid(space_background):
		space_background.queue_free()
		space_background = null
	
	if decorations_node and is_instance_valid(decorations_node):
		decorations_node.queue_free()
		decorations_node = null
	
	for door in doors:
		if is_instance_valid(door):
			door.queue_free()
	doors.clear()


## Get room rectangles for container spawning validation
func get_room_rects() -> Array[Rect2]:
	if current_layout:
		return current_layout.room_rects
	return []


## Check if a position is inside any room
func is_position_in_room(pos: Vector2) -> bool:
	if not current_layout:
		return false
	
	for room in current_layout.room_rects:
		if room.has_point(pos):
			return true
	return false


## Get a valid spawn position within rooms, avoiding other positions
func get_valid_spawn_position(
	existing_positions: Array,
	min_distance: float = 70.0,
	entry_pos: Vector2 = Vector2.ZERO,
	exit_pos: Vector2 = Vector2.ZERO
) -> Vector2:
	if not current_layout or current_layout.room_rects.is_empty():
		return Vector2.ZERO
	
	var attempts = 0
	var max_attempts = 100
	
	while attempts < max_attempts:
		attempts += 1
		
		# Pick a random room
		var room: Rect2 = current_layout.room_rects[randi() % current_layout.room_rects.size()]
		
		# Get random position within room with margin
		var margin = 50.0
		var pos = Vector2(
			randf_range(room.position.x + margin, room.end.x - margin),
			randf_range(room.position.y + margin, room.end.y - margin)
		)
		
		# Validate position
		var valid = true
		
		# Check against existing positions
		for existing in existing_positions:
			if pos.distance_to(existing) < min_distance:
				valid = false
				break
		
		# Check against entry/exit
		if valid and entry_pos != Vector2.ZERO:
			if pos.distance_to(entry_pos) < 100:
				valid = false
		
		if valid and exit_pos != Vector2.ZERO:
			if pos.distance_to(exit_pos) < 100:
				valid = false
		
		if valid:
			return pos
	
	# Fallback: return center of first room
	if current_layout.room_rects.size() > 0:
		return current_layout.room_rects[0].get_center()
	return Vector2(400, 400)


# ==============================================================================
# DRAWING
# ==============================================================================

func _draw() -> void:
	if not current_layout:
		return
	
	var size = current_layout.ship_size
	
	# Draw outer hull background
	draw_rect(Rect2(0, 0, size.x, size.y), Color(0.08, 0.08, 0.1))
	
	# Draw corridors first (under rooms)
	_draw_corridors()
	
	# Draw rooms
	for i in range(current_layout.room_rects.size()):
		var room = current_layout.room_rects[i]
		_draw_room(room, i)
	
	# Draw walls
	_draw_walls()
	
	# Draw room labels
	if draw_room_labels:
		_draw_room_labels()
	
	# Draw decorations
	if draw_decorations:
		_draw_decorations()


func _draw_corridors() -> void:
	if not current_layout.get("corridor_rects"):
		return
	
	var corridor_color = Color(
		current_layout.interior_color.r * 0.75,
		current_layout.interior_color.g * 0.75,
		current_layout.interior_color.b * 0.8
	)
	var corridor_dark = Color(corridor_color.r * 0.85, corridor_color.g * 0.85, corridor_color.b * 0.85)
	var corridor_light = Color(corridor_color.r * 1.1, corridor_color.g * 1.1, corridor_color.b * 1.1)
	
	# Draw corridor cells with panel pattern
	for cell_rect in current_layout.corridor_rects:
		# Base color
		draw_rect(cell_rect, corridor_color)
		
		# Panel effect
		var inner_margin = 2.0
		draw_rect(
			Rect2(
				cell_rect.position.x + inner_margin,
				cell_rect.position.y + inner_margin,
				cell_rect.size.x - inner_margin * 2,
				cell_rect.size.y - inner_margin * 2
			),
			corridor_dark
		)
		
		# Highlight edges
		draw_line(
			cell_rect.position,
			Vector2(cell_rect.end.x, cell_rect.position.y),
			corridor_light, 1
		)
		draw_line(
			cell_rect.position,
			Vector2(cell_rect.position.x, cell_rect.end.y),
			corridor_light, 1
		)
	
	# Draw center stripe along corridors (walkway guide)
	var stripe_color = Color(current_layout.accent_color.r, current_layout.accent_color.g, current_layout.accent_color.b, 0.2)
	for cell_rect in current_layout.corridor_rects:
		var center = cell_rect.get_center()
		var stripe_width = 8.0
		
		# Determine if part of horizontal or vertical corridor
		# Draw a small guide stripe
		draw_rect(
			Rect2(center.x - stripe_width / 2, center.y - stripe_width / 2, stripe_width, stripe_width),
			stripe_color
		)


func _draw_room(room: Rect2, room_index: int) -> void:
	# Get room color based on tier and index
	var base_color = current_layout.interior_color
	var variation = (room_index % 4) * 0.02
	var room_color = Color(
		base_color.r + variation,
		base_color.g + variation * 0.8,
		base_color.b + variation * 0.5
	)
	
	# Draw floor with slight gradient effect
	draw_rect(room, room_color)
	
	# Draw floor panel grid pattern (better quality)
	var panel_size = 40.0
	var gap = 2.0
	var dark_color = Color(room_color.r * 0.85, room_color.g * 0.85, room_color.b * 0.85)
	var light_color = Color(room_color.r * 1.05, room_color.g * 1.05, room_color.b * 1.05)
	
	# Draw individual floor panels
	var x = room.position.x + gap
	while x < room.end.x - panel_size / 2:
		var y = room.position.y + gap
		while y < room.end.y - panel_size / 2:
			var panel_w = minf(panel_size - gap, room.end.x - x - gap)
			var panel_h = minf(panel_size - gap, room.end.y - y - gap)
			
			# Checkerboard pattern for visual interest
			var checker = (int(x / panel_size) + int(y / panel_size)) % 2
			var panel_col = dark_color if checker == 0 else room_color
			
			# Draw panel
			draw_rect(Rect2(x, y, panel_w, panel_h), panel_col)
			
			# Panel highlight edge
			draw_line(Vector2(x, y), Vector2(x + panel_w, y), light_color, 1)
			draw_line(Vector2(x, y), Vector2(x, y + panel_h), light_color, 1)
			
			y += panel_size
		x += panel_size
	
	# Room corner accents (improved)
	var accent = current_layout.accent_color
	var accent_size = 20.0
	var accent_thickness = 3.0
	
	# Top-left corner bracket
	draw_rect(Rect2(room.position.x, room.position.y, accent_size, accent_thickness), accent)
	draw_rect(Rect2(room.position.x, room.position.y, accent_thickness, accent_size), accent)
	
	# Top-right corner bracket
	draw_rect(Rect2(room.end.x - accent_size, room.position.y, accent_size, accent_thickness), accent)
	draw_rect(Rect2(room.end.x - accent_thickness, room.position.y, accent_thickness, accent_size), accent)
	
	# Bottom-left corner bracket
	draw_rect(Rect2(room.position.x, room.end.y - accent_thickness, accent_size, accent_thickness), accent)
	draw_rect(Rect2(room.position.x, room.end.y - accent_size, accent_thickness, accent_size), accent)
	
	# Bottom-right corner bracket
	draw_rect(Rect2(room.end.x - accent_size, room.end.y - accent_thickness, accent_size, accent_thickness), accent)
	draw_rect(Rect2(room.end.x - accent_thickness, room.end.y - accent_size, accent_thickness, accent_size), accent)
	
	# Edge glow/highlight
	var edge_glow = Color(accent.r, accent.g, accent.b, 0.15)
	draw_rect(Rect2(room.position.x, room.position.y, room.size.x, 4), edge_glow)
	draw_rect(Rect2(room.position.x, room.position.y, 4, room.size.y), edge_glow)


func _draw_walls() -> void:
	var wall_color = current_layout.hull_color
	var wall_highlight = Color(wall_color.r * 1.3, wall_color.g * 1.3, wall_color.b * 1.3)
	var wall_shadow = Color(wall_color.r * 0.6, wall_color.g * 0.6, wall_color.b * 0.6)
	var wall_thickness = 10.0
	
	for segment in current_layout.wall_segments:
		var start = segment.start
		var end_pos = segment.end
		
		# Determine if horizontal or vertical
		if absf(start.y - end_pos.y) < 1:
			# Horizontal wall
			var rect = Rect2(
				start.x, start.y - wall_thickness / 2,
				end_pos.x - start.x, wall_thickness
			)
			draw_rect(rect, wall_color)
			
			# Top highlight
			draw_line(
				Vector2(rect.position.x, rect.position.y),
				Vector2(rect.end.x, rect.position.y),
				wall_highlight, 2
			)
			# Bottom shadow
			draw_line(
				Vector2(rect.position.x, rect.end.y),
				Vector2(rect.end.x, rect.end.y),
				wall_shadow, 2
			)
		else:
			# Vertical wall
			var rect = Rect2(
				start.x - wall_thickness / 2, start.y,
				wall_thickness, end_pos.y - start.y
			)
			draw_rect(rect, wall_color)
			
			# Left highlight
			draw_line(
				Vector2(rect.position.x, rect.position.y),
				Vector2(rect.position.x, rect.end.y),
				wall_highlight, 2
			)
			# Right shadow
			draw_line(
				Vector2(rect.end.x, rect.position.y),
				Vector2(rect.end.x, rect.end.y),
				wall_shadow, 2
			)
	
	# Draw doorways (gaps in walls between adjacent rooms)
	_draw_doorways()


func _draw_doorways() -> void:
	# Find adjacent rooms and draw doorways
	var door_color = Color(0.12, 0.15, 0.18)
	var frame_color = current_layout.accent_color
	var track_color = Color(frame_color.r * 0.5, frame_color.g * 0.5, frame_color.b * 0.5)
	var door_size = 60.0
	
	for i in range(current_layout.room_rects.size()):
		for j in range(i + 1, current_layout.room_rects.size()):
			var room_a = current_layout.room_rects[i]
			var room_b = current_layout.room_rects[j]
			
			# Check if rooms share a wall
			var door_pos = _find_shared_wall_center(room_a, room_b)
			if door_pos != Vector2.ZERO:
				# Determine orientation
				var is_vertical = absf(room_a.end.x - room_b.position.x) < 50 or absf(room_a.position.x - room_b.end.x) < 50
				
				if is_vertical:
					# Vertical doorway (rooms side by side)
					# Door floor
					draw_rect(Rect2(
						door_pos.x - 8,
						door_pos.y - door_size / 2,
						16, door_size
					), door_color)
					
					# Door tracks
					draw_rect(Rect2(
						door_pos.x - 10,
						door_pos.y - door_size / 2,
						2, door_size
					), track_color)
					draw_rect(Rect2(
						door_pos.x + 8,
						door_pos.y - door_size / 2,
						2, door_size
					), track_color)
					
					# Door frame top/bottom
					draw_rect(Rect2(door_pos.x - 12, door_pos.y - door_size / 2 - 4, 24, 4), frame_color)
					draw_rect(Rect2(door_pos.x - 12, door_pos.y + door_size / 2, 24, 4), frame_color)
				else:
					# Horizontal doorway (rooms above/below)
					# Door floor
					draw_rect(Rect2(
						door_pos.x - door_size / 2,
						door_pos.y - 8,
						door_size, 16
					), door_color)
					
					# Door tracks
					draw_rect(Rect2(
						door_pos.x - door_size / 2,
						door_pos.y - 10,
						door_size, 2
					), track_color)
					draw_rect(Rect2(
						door_pos.x - door_size / 2,
						door_pos.y + 8,
						door_size, 2
					), track_color)
					
					# Door frame left/right
					draw_rect(Rect2(door_pos.x - door_size / 2 - 4, door_pos.y - 12, 4, 24), frame_color)
					draw_rect(Rect2(door_pos.x + door_size / 2, door_pos.y - 12, 4, 24), frame_color)


func _find_shared_wall_center(room_a: Rect2, room_b: Rect2) -> Vector2:
	var tolerance = 50.0  # How close rooms need to be
	
	# Check if room_a's right edge touches room_b's left edge
	if absf(room_a.end.x - room_b.position.x) < tolerance:
		var overlap_start = maxf(room_a.position.y, room_b.position.y)
		var overlap_end = minf(room_a.end.y, room_b.end.y)
		if overlap_end - overlap_start > 60:  # Minimum overlap for door
			return Vector2(room_a.end.x, (overlap_start + overlap_end) / 2)
	
	# Check if room_a's left edge touches room_b's right edge
	if absf(room_a.position.x - room_b.end.x) < tolerance:
		var overlap_start = maxf(room_a.position.y, room_b.position.y)
		var overlap_end = minf(room_a.end.y, room_b.end.y)
		if overlap_end - overlap_start > 60:
			return Vector2(room_a.position.x, (overlap_start + overlap_end) / 2)
	
	# Check if room_a's bottom edge touches room_b's top edge
	if absf(room_a.end.y - room_b.position.y) < tolerance:
		var overlap_start = maxf(room_a.position.x, room_b.position.x)
		var overlap_end = minf(room_a.end.x, room_b.end.x)
		if overlap_end - overlap_start > 60:
			return Vector2((overlap_start + overlap_end) / 2, room_a.end.y)
	
	# Check if room_a's top edge touches room_b's bottom edge
	if absf(room_a.position.y - room_b.end.y) < tolerance:
		var overlap_start = maxf(room_a.position.x, room_b.position.x)
		var overlap_end = minf(room_a.end.x, room_b.end.x)
		if overlap_end - overlap_start > 60:
			return Vector2((overlap_start + overlap_end) / 2, room_a.position.y)
	
	return Vector2.ZERO


func _draw_room_labels() -> void:
	# Get room names for this tier
	var room_names: Array
	match ship_tier:
		1: room_names = TIER1_ROOMS
		2: room_names = TIER2_ROOMS
		3: room_names = TIER3_ROOMS
		4: room_names = TIER4_ROOMS
		5: room_names = TIER5_ROOMS
		_: room_names = TIER1_ROOMS
	
	var accent_col = current_layout.accent_color
	@warning_ignore("unused_variable")
	var label_col = Color(accent_col.r, accent_col.g, accent_col.b, 0.4)
	
	for i in range(current_layout.room_rects.size()):
		var room = current_layout.room_rects[i]
		var name_idx = i % room_names.size()
		var room_name = room_names[name_idx]
		
		# Draw text (as simple colored rect for now, actual text via Label nodes)
		# Position at top of room
		var text_pos = room.position + Vector2(15, 20)
		
		# We'll use a placeholder visual since draw_string requires font
		# The actual labels will be created as Label nodes
		draw_rect(Rect2(text_pos.x, text_pos.y, room_name.length() * 8, 16), Color(0, 0, 0, 0.3))


func _draw_decorations() -> void:
	# Skip if using enhanced decorations (handled separately)
	if enable_enhanced_decorations:
		return
	
	# Fallback simple decorations for rooms
	var rng = RandomNumberGenerator.new()
	rng.seed = ship_tier * 1000 + current_layout.room_rects.size()
	
	for room in current_layout.room_rects:
		# Skip very small rooms
		if room.size.x < 100 or room.size.y < 100:
			continue
		
		# Random decorations based on room size
		var num_decorations = rng.randi_range(2, 4)
		
		for deco_idx in range(num_decorations):
			var deco_type = rng.randi_range(0, 5)
			var deco_pos = Vector2(
				rng.randf_range(room.position.x + 35, room.end.x - 35),
				rng.randf_range(room.position.y + 35, room.end.y - 35)
			)
			
			match deco_type:
				0:  # Floor panel/grating
					var panel_col = Color(0.1, 0.12, 0.14)
					var panel_size = Vector2(rng.randf_range(25, 40), rng.randf_range(25, 40))
					draw_rect(Rect2(deco_pos - panel_size / 2, panel_size), panel_col)
					# Grate lines
					var line_col = Color(0.15, 0.17, 0.2)
					for i in range(int(panel_size.x / 8)):
						var lx = deco_pos.x - panel_size.x / 2 + i * 8 + 2
						draw_line(Vector2(lx, deco_pos.y - panel_size.y / 2 + 2), Vector2(lx, deco_pos.y + panel_size.y / 2 - 2), line_col, 1)
				
				1:  # Pipe/vent
					var pipe_col = Color(0.22, 0.24, 0.28)
					draw_circle(deco_pos, 12, pipe_col)
					draw_circle(deco_pos, 8, Color(0.08, 0.09, 0.1))
					# Inner detail
					draw_circle(deco_pos, 3, Color(0.15, 0.17, 0.2))
				
				2:  # Light strip
					var light_col = Color(0.5, 0.6, 0.4, 0.6)
					var length = rng.randf_range(30, 50)
					draw_rect(Rect2(deco_pos.x - length / 2, deco_pos.y - 2, length, 4), light_col)
					# Glow effect
					draw_rect(Rect2(deco_pos.x - length / 2 - 2, deco_pos.y - 4, length + 4, 8), Color(light_col.r, light_col.g, light_col.b, 0.2))
				
				3:  # Caution stripe
					var stripe_col = Color(0.6, 0.5, 0.15, 0.4)
					var stripe_length = rng.randf_range(40, 60)
					# Diagonal stripes
					for s in range(int(stripe_length / 10)):
						var sx = deco_pos.x - stripe_length / 2 + s * 10
						draw_rect(Rect2(sx, deco_pos.y - 3, 5, 6), stripe_col if s % 2 == 0 else Color(0, 0, 0, 0))
				
				4:  # Control box
					var box_col = Color(0.18, 0.2, 0.22)
					draw_rect(Rect2(deco_pos.x - 12, deco_pos.y - 8, 24, 16), box_col)
					# Indicator light
					var indicator_col = Color(0.2, 0.8, 0.3, 0.8) if rng.randf() > 0.3 else Color(0.8, 0.3, 0.2, 0.8)
					draw_circle(deco_pos + Vector2(6, 0), 3, indicator_col)
				
				5:  # Floor marking
					var mark_col = Color(current_layout.accent_color.r, current_layout.accent_color.g, current_layout.accent_color.b, 0.25)
					var is_circle = rng.randf() > 0.5
					if is_circle:
						draw_arc(deco_pos, 15, 0, TAU, 32, mark_col, 2, true)
					else:
						# Small arrow
						var arrow_points = PackedVector2Array([
							deco_pos + Vector2(-10, 5),
							deco_pos + Vector2(0, -8),
							deco_pos + Vector2(10, 5)
						])
						draw_polyline(arrow_points, mark_col, 2)


# ==============================================================================
# WALL COLLISION GENERATION
# ==============================================================================

func _clear_walls() -> void:
	for wall in wall_bodies:
		if is_instance_valid(wall):
			wall.queue_free()
	wall_bodies.clear()


func _create_wall_collisions() -> void:
	if not current_layout:
		return
	
	# Check if we have a walkable grid (new system)
	if current_layout.get("walkable_grid") and not current_layout.walkable_grid.is_empty():
		_create_grid_based_collisions()
	else:
		_create_boundary_collisions()


func _create_boundary_collisions() -> void:
	# Fallback: Create outer boundary walls only
	var size = current_layout.ship_size
	var wall_thickness = 40.0
	
	# Top wall
	_create_wall_body(Vector2(size.x / 2, -wall_thickness / 2), Vector2(size.x + 100, wall_thickness))
	# Bottom wall
	_create_wall_body(Vector2(size.x / 2, size.y + wall_thickness / 2), Vector2(size.x + 100, wall_thickness))
	# Left wall
	_create_wall_body(Vector2(-wall_thickness / 2, size.y / 2), Vector2(wall_thickness, size.y + 100))
	# Right wall
	_create_wall_body(Vector2(size.x + wall_thickness / 2, size.y / 2), Vector2(wall_thickness, size.y + 100))


func _create_grid_based_collisions() -> void:
	# Create collision bodies for non-walkable cells
	var grid = current_layout.walkable_grid
	var cell_size: int = current_layout.grid_cell_size if current_layout.get("grid_cell_size") else 40
	
	var grid_width = grid.size()
	if grid_width == 0:
		_create_boundary_collisions()
		return
	
	var grid_height = grid[0].size()
	
	# Merge adjacent non-walkable cells into larger rectangles for efficiency
	var processed: Dictionary = {}
	
	for x in range(grid_width):
		for y in range(grid_height):
			var key = Vector2i(x, y)
			if key in processed:
				continue
			
			if not grid[x][y]:  # Non-walkable cell
				# Try to expand into a rectangle
				var rect = _expand_wall_rect(grid, x, y, grid_width, grid_height, processed)
				
				# Create collision body for this rect
				var center = Vector2(
					(rect.position.x + rect.size.x / 2.0) * cell_size,
					(rect.position.y + rect.size.y / 2.0) * cell_size
				)
				var body_size = Vector2(rect.size.x * cell_size, rect.size.y * cell_size)
				_create_wall_body(center, body_size)


func _expand_wall_rect(
	grid: Array, start_x: int, start_y: int,
	grid_width: int, grid_height: int, processed: Dictionary
) -> Rect2:
	# Expand horizontally first, then vertically
	var end_x = start_x
	var end_y = start_y
	
	# Expand right
	while end_x + 1 < grid_width:
		if grid[end_x + 1][start_y]:  # Walkable, stop
			break
		var key = Vector2i(end_x + 1, start_y)
		if key in processed:
			break
		end_x += 1
	
	# Expand down
	var can_expand_y = true
	while can_expand_y and end_y + 1 < grid_height:
		# Check if entire row can be added
		for check_x in range(start_x, end_x + 1):
			if grid[check_x][end_y + 1]:  # Walkable, can't expand
				can_expand_y = false
				break
			var key = Vector2i(check_x, end_y + 1)
			if key in processed:
				can_expand_y = false
				break
		
		if can_expand_y:
			end_y += 1
	
	# Mark all cells in this rect as processed
	for px in range(start_x, end_x + 1):
		for py in range(start_y, end_y + 1):
			processed[Vector2i(px, py)] = true
	
	return Rect2(start_x, start_y, end_x - start_x + 1, end_y - start_y + 1)


func _create_wall_body(center: Vector2, body_size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = center
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = body_size
	shape.shape = rect
	body.add_child(shape)
	
	add_child(body)
	wall_bodies.append(body)


# ==============================================================================
# LABEL GENERATION (called after _ready)
# ==============================================================================

func create_room_labels() -> void:
	if not current_layout:
		return
	
	# Get room names for this tier
	var room_names: Array
	match ship_tier:
		1: room_names = TIER1_ROOMS
		2: room_names = TIER2_ROOMS
		3: room_names = TIER3_ROOMS
		4: room_names = TIER4_ROOMS
		5: room_names = TIER5_ROOMS
		_: room_names = TIER1_ROOMS
	
	for i in range(current_layout.room_rects.size()):
		var room = current_layout.room_rects[i]
		var name_idx = i % room_names.size()
		var room_name = room_names[name_idx]
		
		var label = Label.new()
		label.text = room_name
		label.position = room.position + Vector2(15, 15)
		label.add_theme_color_override("font_color", Color(current_layout.accent_color.r, current_layout.accent_color.g, current_layout.accent_color.b, 0.4))
		label.add_theme_font_size_override("font_size", 14)
		add_child(label)


# ==============================================================================
# SPACE BACKGROUND
# ==============================================================================

func _create_space_background() -> void:
	if not current_layout:
		return
	
	space_background = Node2D.new()
	space_background.name = "SpaceBackground"
	space_background.z_index = -100  # Behind everything
	add_child(space_background)
	move_child(space_background, 0)
	
	# Create background renderer
	var bg = _SpaceBackgroundRenderer.new()
	bg.ship_size = current_layout.ship_size
	bg.seed_value = ship_tier * 12345
	space_background.add_child(bg)


## Inner class for space background rendering
class _SpaceBackgroundRenderer extends Node2D:
	var ship_size: Vector2 = Vector2(800, 600)
	var seed_value: int = 0
	
	# Star data
	var far_stars: Array = []
	var mid_stars: Array = []
	var near_stars: Array = []
	var nebulae: Array = []
	
	# Animation
	var time: float = 0.0
	var twinkle_speed: float = 2.0
	
	func _ready() -> void:
		_generate_stars()
	
	func _process(delta: float) -> void:
		time += delta
		queue_redraw()
	
	func _generate_stars() -> void:
		var rng = RandomNumberGenerator.new()
		rng.seed = seed_value
		
		# Background extends beyond ship for visual effect
		var margin = 200.0
		var bg_rect = Rect2(-margin, -margin, ship_size.x + margin * 2, ship_size.y + margin * 2)
		
		# Generate far stars (small, dim, many)
		for i in range(150):
			far_stars.append({
				"pos": Vector2(
					rng.randf_range(bg_rect.position.x, bg_rect.end.x),
					rng.randf_range(bg_rect.position.y, bg_rect.end.y)
				),
				"size": rng.randf_range(0.5, 1.2),
				"brightness": rng.randf_range(0.3, 0.6),
				"twinkle_phase": rng.randf() * TAU
			})
		
		# Generate mid stars (medium)
		for i in range(60):
			mid_stars.append({
				"pos": Vector2(
					rng.randf_range(bg_rect.position.x, bg_rect.end.x),
					rng.randf_range(bg_rect.position.y, bg_rect.end.y)
				),
				"size": rng.randf_range(1.0, 2.0),
				"brightness": rng.randf_range(0.5, 0.8),
				"twinkle_phase": rng.randf() * TAU,
				"color_tint": _random_star_color(rng)
			})
		
		# Generate near stars (large, bright, few)
		for i in range(20):
			near_stars.append({
				"pos": Vector2(
					rng.randf_range(bg_rect.position.x, bg_rect.end.x),
					rng.randf_range(bg_rect.position.y, bg_rect.end.y)
				),
				"size": rng.randf_range(2.0, 3.5),
				"brightness": rng.randf_range(0.7, 1.0),
				"twinkle_phase": rng.randf() * TAU,
				"color_tint": _random_star_color(rng),
				"has_glow": rng.randf() > 0.5
			})
		
		# Generate nebulae (soft colored clouds)
		for i in range(rng.randi_range(2, 4)):
			nebulae.append({
				"pos": Vector2(
					rng.randf_range(bg_rect.position.x, bg_rect.end.x),
					rng.randf_range(bg_rect.position.y, bg_rect.end.y)
				),
				"radius": rng.randf_range(100, 250),
				"color": _random_nebula_color(rng),
				"intensity": rng.randf_range(0.05, 0.15)
			})
	
	func _random_star_color(rng: RandomNumberGenerator) -> Color:
		var colors = [
			Color(1.0, 1.0, 1.0),      # White
			Color(1.0, 0.95, 0.85),    # Warm white
			Color(0.85, 0.9, 1.0),     # Cool blue-white
			Color(1.0, 0.85, 0.7),     # Orange tint
			Color(0.9, 0.85, 1.0),     # Slight purple
		]
		return colors[rng.randi() % colors.size()]
	
	func _random_nebula_color(rng: RandomNumberGenerator) -> Color:
		var colors = [
			Color(0.2, 0.1, 0.4),      # Purple
			Color(0.1, 0.2, 0.35),     # Blue
			Color(0.25, 0.15, 0.1),    # Orange/brown
			Color(0.1, 0.25, 0.2),     # Teal
			Color(0.3, 0.1, 0.15),     # Red/pink
		]
		return colors[rng.randi() % colors.size()]
	
	func _draw() -> void:
		# Deep space background
		var margin = 200.0
		draw_rect(
			Rect2(-margin, -margin, ship_size.x + margin * 2, ship_size.y + margin * 2),
			Color(0.02, 0.02, 0.05)
		)
		
		# Draw nebulae (soft glow)
		for nebula in nebulae:
			_draw_nebula(nebula)
		
		# Draw far stars
		for star in far_stars:
			var twinkle = 0.8 + 0.2 * sin(time * twinkle_speed * 0.5 + star.twinkle_phase)
			var col = Color(1, 1, 1, star.brightness * twinkle)
			draw_circle(star.pos, star.size, col)
		
		# Draw mid stars with color
		for star in mid_stars:
			var twinkle = 0.7 + 0.3 * sin(time * twinkle_speed + star.twinkle_phase)
			var col = star.color_tint
			col.a = star.brightness * twinkle
			draw_circle(star.pos, star.size, col)
		
		# Draw near stars with glow
		for star in near_stars:
			var twinkle = 0.6 + 0.4 * sin(time * twinkle_speed * 1.5 + star.twinkle_phase)
			var col = star.color_tint
			col.a = star.brightness * twinkle
			
			# Glow effect
			if star.has_glow:
				var glow_col = Color(col.r, col.g, col.b, col.a * 0.3)
				draw_circle(star.pos, star.size * 3, glow_col)
				draw_circle(star.pos, star.size * 2, Color(col.r, col.g, col.b, col.a * 0.5))
			
			draw_circle(star.pos, star.size, col)
	
	func _draw_nebula(nebula: Dictionary) -> void:
		# Soft nebula cloud effect with multiple layers
		var pos = nebula.pos
		var radius = nebula.radius
		var color = nebula.color
		var intensity = nebula.intensity
		
		# Draw several overlapping soft circles
		for i in range(5):
			var offset = Vector2(
				sin(time * 0.1 + i * 1.2) * 10,
				cos(time * 0.08 + i * 0.9) * 10
			)
			var r = radius * (1.0 - i * 0.15)
			var c = Color(color.r, color.g, color.b, intensity * (1.0 - i * 0.18))
			draw_circle(pos + offset, r, c)


# ==============================================================================
# ENHANCED DECORATIONS
# ==============================================================================

func _create_enhanced_decorations() -> void:
	if not current_layout:
		return
	
	# Check if ShipDecorations class exists
	if not DecoScript:
		return
	
	decorations_node = DecoScript.new()
	decorations_node.name = "EnhancedDecorations"
	decorations_node.z_index = 5  # Above floor, below player
	add_child(decorations_node)
	
	# Set colors from layout
	decorations_node.set_colors(
		current_layout.interior_color,
		current_layout.hull_color,
		current_layout.accent_color
	)
	
	# Generate decorations for each room
	var room_names = _get_room_names_for_tier()
	for i in range(current_layout.room_rects.size()):
		var room = current_layout.room_rects[i]
		var room_name = room_names[i % room_names.size()]
		decorations_node.generate_for_room(room, room_name, ship_tier * 1000 + i)


func _get_room_names_for_tier() -> Array:
	match ship_tier:
		1: return TIER1_ROOMS
		2: return TIER2_ROOMS
		3: return TIER3_ROOMS
		4: return TIER4_ROOMS
		5: return TIER5_ROOMS
		_: return TIER1_ROOMS


# ==============================================================================
# DOOR SYSTEM
# ==============================================================================

func _create_doors() -> void:
	if not current_layout:
		return
	
	# Check if Door class exists
	if not DoorScript:
		return
	
	# Find door positions between rooms
	for i in range(current_layout.room_rects.size()):
		for j in range(i + 1, current_layout.room_rects.size()):
			var room_a = current_layout.room_rects[i]
			var room_b = current_layout.room_rects[j]
			
			var door_pos = _find_shared_wall_center(room_a, room_b)
			if door_pos != Vector2.ZERO:
				_spawn_door(door_pos, room_a, room_b)


func _spawn_door(pos: Vector2, room_a: Rect2, room_b: Rect2) -> void:
	if not DoorScript:
		return
	
	var door = DoorScript.new()
	door.position = pos
	door.z_index = 10
	
	# Determine orientation based on room positions
	# is_horizontal means the door spans horizontally (rooms are above/below)
	var rooms_side_by_side = absf(room_a.end.x - room_b.position.x) < 50 
	rooms_side_by_side = rooms_side_by_side or absf(room_a.position.x - room_b.end.x) < 50
	door.is_horizontal = not rooms_side_by_side
	
	# Set door dimensions
	door.door_width = 60.0
	door.door_thickness = 10.0
	
	# Random chance for locked doors on higher tiers
	if ship_tier >= 3:
		var lock_chance = (ship_tier - 2) * 0.15
		if randf() < lock_chance:
			# State.LOCKED = 2 in the Door enum
			door.initial_state = 2
			door.lock_type = (randi() % 4) + 1
	
	add_child(door)
	doors.append(door)


## Get all doors for interaction checking
func get_doors() -> Array:
	return doors
