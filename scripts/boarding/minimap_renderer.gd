# ==============================================================================
# MINIMAP RENDERER - SHIP INTERIOR MINIMAP
# ==============================================================================
#
# FILE: scripts/boarding/minimap_renderer.gd
# PURPOSE: Renders a minimap of the ship interior for navigation
#
# FEATURES:
# - Shows room layout
# - Player position indicator
# - Container locations (searched vs unsearched)
# - Exit point marker
# - Fog of war (reveal as explored)
#
# ==============================================================================

extends Node2D
class_name MinimapRenderer


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Appearance")
## Background color for unexplored areas
@export var fog_color: Color = Color(0.1, 0.1, 0.15, 0.9)
## Color for explored rooms
@export var room_color: Color = Color(0.25, 0.3, 0.35, 0.8)
## Color for room borders
@export var wall_color: Color = Color(0.4, 0.45, 0.5, 1.0)
## Player indicator color
@export var player_color: Color = Color(0.2, 0.8, 0.4, 1.0)
## Exit point color
@export var exit_color: Color = Color(0.3, 0.8, 0.9, 1.0)
## Unsearched container color
@export var container_unsearched_color: Color = Color(0.8, 0.6, 0.2, 1.0)
## Searched container color
@export var container_searched_color: Color = Color(0.4, 0.4, 0.4, 0.6)

@export_group("Settings")
## Scale factor for the minimap (smaller = more zoomed out)
@export_range(0.01, 0.2, 0.01) var minimap_scale: float = 0.08
## Fog of war exploration radius in game units
@export var exploration_radius: float = 200.0
## Wall thickness on minimap
@export var wall_thickness: float = 2.0

@export_group("Visual Details")
## Number of segments for drawing circles and arcs
@export_range(8, 64) var circle_segments: int = 16
## Border width for containers
@export var container_border_width: float = 1.0
## Exit point pulse animation speed (radians per millisecond)
@export var exit_pulse_speed: float = 0.005
## Exit point pulse animation amplitude
@export var exit_pulse_amplitude: float = 0.2


# ==============================================================================
# STATE
# ==============================================================================

var current_layout: RefCounted = null  # ShipLayout.LayoutData
var player_position: Vector2 = Vector2.ZERO
var exit_position: Vector2 = Vector2.ZERO
var containers: Array = []  # Array of {position: Vector2, searched: bool}
var explored_areas: Array[Vector2] = []  # Player positions that have been visited

## Calculated bounds from actual room data
var map_bounds: Rect2 = Rect2()
var map_offset: Vector2 = Vector2.ZERO

## Viewport panning to follow player
var viewport_offset: Vector2 = Vector2.ZERO
## Size of the minimap widget (set from parent)
var minimap_size: Vector2 = Vector2(200, 200)


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Enable custom drawing
	set_process(true)


func _draw() -> void:
	if not current_layout:
		return
	
	# Draw fog of war (unexplored areas)
	_draw_fog()
	
	# Draw explored rooms
	_draw_rooms()
	
	# Draw containers
	_draw_containers()
	
	# Draw exit point
	_draw_exit()
	
	# Draw player indicator (always on top)
	_draw_player()


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Initialize the minimap with layout data
func set_layout(layout: RefCounted) -> void:
	current_layout = layout
	explored_areas.clear()
	_calculate_map_bounds()
	queue_redraw()


## Calculate the actual bounds from room and corridor data
func _calculate_map_bounds() -> void:
	if not current_layout:
		map_bounds = Rect2()
		map_offset = Vector2.ZERO
		return
	
	var min_pos = Vector2(INF, INF)
	var max_pos = Vector2(-INF, -INF)
	
	# Include all rooms
	if current_layout.get("room_rects"):
		for room_rect in current_layout.room_rects:
			min_pos.x = minf(min_pos.x, room_rect.position.x)
			min_pos.y = minf(min_pos.y, room_rect.position.y)
			max_pos.x = maxf(max_pos.x, room_rect.end.x)
			max_pos.y = maxf(max_pos.y, room_rect.end.y)
	
	# Include all corridors
	if current_layout.get("corridor_rects"):
		for corridor_rect in current_layout.corridor_rects:
			min_pos.x = minf(min_pos.x, corridor_rect.position.x)
			min_pos.y = minf(min_pos.y, corridor_rect.position.y)
			max_pos.x = maxf(max_pos.x, corridor_rect.end.x)
			max_pos.y = maxf(max_pos.y, corridor_rect.end.y)
	
	# Handle edge case of no rooms
	if min_pos.x == INF:
		min_pos = Vector2.ZERO
		max_pos = current_layout.ship_size if current_layout else Vector2(800, 600)
	
	# Add padding
	var padding = 20.0
	min_pos -= Vector2(padding, padding)
	max_pos += Vector2(padding, padding)
	
	map_offset = min_pos
	map_bounds = Rect2(Vector2.ZERO, max_pos - min_pos)


## Update player position (call every frame from manager)
func update_player_position(pos: Vector2) -> void:
	player_position = pos
	
	# Add to explored areas (with deduplication to prevent infinite growth)
	# Only add if significantly different from last position
	if explored_areas.is_empty() or explored_areas[-1].distance_to(pos) > 20.0:
		explored_areas.append(pos)
		
		# Limit array size to prevent memory issues
		if explored_areas.size() > 1000:
			explored_areas.remove_at(0)
	
	# Update viewport offset to center on player
	_update_viewport_offset()
	
	queue_redraw()


## Update viewport offset to keep player centered
func _update_viewport_offset() -> void:
	# Calculate where the player would be on the minimap without offset
	var player_minimap_pos = (player_position - map_offset) * minimap_scale
	
	# Center point of the visible minimap area
	var center = minimap_size * 0.5
	
	# Calculate offset needed to center player
	viewport_offset = player_minimap_pos - center
	
	# Clamp offset to prevent showing empty space beyond map edges
	var scaled_bounds = map_bounds.size * minimap_scale
	var max_offset = scaled_bounds - minimap_size
	
	# Only clamp if map is larger than viewport
	if max_offset.x > 0:
		viewport_offset.x = clampf(viewport_offset.x, 0, max_offset.x)
	else:
		viewport_offset.x = max_offset.x * 0.5  # Center if map is smaller
	
	if max_offset.y > 0:
		viewport_offset.y = clampf(viewport_offset.y, 0, max_offset.y)
	else:
		viewport_offset.y = max_offset.y * 0.5  # Center if map is smaller


## Set the minimap widget size (call from parent)
func set_minimap_size(size: Vector2) -> void:
	minimap_size = size
	_update_viewport_offset()
	queue_redraw()


## Update exit position
func set_exit_position(pos: Vector2) -> void:
	exit_position = pos
	queue_redraw()


## Update containers array
func set_containers(container_list: Array) -> void:
	containers = container_list
	queue_redraw()


## Update a specific container's searched state
func mark_container_searched(container_position: Vector2) -> void:
	for container in containers:
		if container.position.distance_to(container_position) < 10:
			container.searched = true
			queue_redraw()
			break


# ==============================================================================
# DRAWING FUNCTIONS
# ==============================================================================

## Draw fog of war over unexplored areas
func _draw_fog() -> void:
	if not current_layout or map_bounds.size == Vector2.ZERO:
		return
	
	# Draw fog based on calculated bounds, adjusted for viewport offset
	var scaled_size = map_bounds.size * minimap_scale
	var fog_pos = -viewport_offset
	draw_rect(Rect2(fog_pos, scaled_size), fog_color, true)


## Convert world position to minimap position (with viewport panning)
func _world_to_minimap(world_pos: Vector2) -> Vector2:
	return (world_pos - map_offset) * minimap_scale - viewport_offset


## Draw explored rooms and corridors
func _draw_rooms() -> void:
	if not current_layout:
		return
	
	# Draw corridors first (underneath rooms)
	if current_layout.get("corridor_rects"):
		for corridor_rect in current_layout.corridor_rects:
			var is_explored = _is_room_explored(corridor_rect)
			if is_explored:
				var scaled_rect = Rect2(
					_world_to_minimap(corridor_rect.position),
					corridor_rect.size * minimap_scale
				)
				# Corridor color slightly darker than rooms
				var corridor_color = room_color.darkened(0.15)
				draw_rect(scaled_rect, corridor_color, true)
				draw_rect(scaled_rect, wall_color, false, wall_thickness * 0.5)
	
	# Draw rooms on top
	if current_layout.get("room_rects") and not current_layout.room_rects.is_empty():
		for room_rect in current_layout.room_rects:
			# Check if any explored position is near this room
			var is_explored = _is_room_explored(room_rect)
			
			if is_explored:
				# Scale room to minimap size
				var scaled_rect = Rect2(
					_world_to_minimap(room_rect.position),
					room_rect.size * minimap_scale
				)
				
				# Draw room floor
				draw_rect(scaled_rect, room_color, true)
				
				# Draw room border
				draw_rect(scaled_rect, wall_color, false, wall_thickness)


## Draw containers on the minimap
func _draw_containers() -> void:
	if containers.is_empty():
		return
	
	var container_size = 4.0  # Size of container indicator on minimap
	
	for container in containers:
		var pos = container.position
		
		# Check if container area is explored
		if not _is_position_explored(pos):
			continue
		
		var scaled_pos = _world_to_minimap(pos)
		var color = container_searched_color if container.get("searched", false) else container_unsearched_color
		
		# Draw as a small circle
		draw_circle(scaled_pos, container_size, color)
		
		# Draw border for better visibility
		draw_arc(scaled_pos, container_size, 0, TAU, circle_segments, Color.BLACK, container_border_width)


## Draw exit point marker
func _draw_exit() -> void:
	if exit_position == Vector2.ZERO:
		return
	
	# Check if exit is explored
	if not _is_position_explored(exit_position):
		return
	
	var scaled_pos = _world_to_minimap(exit_position)
	var size = 6.0
	
	# Draw as a pulsing diamond/square
	# Convert to seconds for consistent animation regardless of frame rate
	var time_seconds = Time.get_ticks_msec() * 0.001
	var pulse = 1.0 + sin(time_seconds * exit_pulse_speed * 1000.0) * exit_pulse_amplitude
	var current_size = size * pulse
	
	# Draw diamond shape
	var points = PackedVector2Array([
		scaled_pos + Vector2(0, -current_size),
		scaled_pos + Vector2(current_size, 0),
		scaled_pos + Vector2(0, current_size),
		scaled_pos + Vector2(-current_size, 0)
	])
	
	draw_colored_polygon(points, exit_color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.BLACK, 1.0)


## Draw player position indicator
func _draw_player() -> void:
	if player_position == Vector2.ZERO:
		return
	
	var scaled_pos = _world_to_minimap(player_position)
	var size = 5.0
	
	# Draw as a triangle pointing up (player's view direction doesn't matter much in top-down)
	var points = PackedVector2Array([
		scaled_pos + Vector2(0, -size),
		scaled_pos + Vector2(size * 0.7, size * 0.5),
		scaled_pos + Vector2(-size * 0.7, size * 0.5)
	])
	
	draw_colored_polygon(points, player_color)
	draw_polyline(points + PackedVector2Array([points[0]]), Color.BLACK, 1.5)


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

## Check if a room has been explored
func _is_room_explored(room_rect: Rect2) -> bool:
	# Check if any explored position is within or near the room
	for explored_pos in explored_areas:
		# Expand room rect by exploration radius
		var expanded_rect = room_rect.grow(exploration_radius)
		if expanded_rect.has_point(explored_pos):
			return true
	
	return false


## Check if a specific position has been explored
func _is_position_explored(pos: Vector2) -> bool:
	for explored_pos in explored_areas:
		if explored_pos.distance_to(pos) < exploration_radius:
			return true
	
	return false
