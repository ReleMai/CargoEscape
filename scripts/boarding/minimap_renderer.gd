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
## Exit point pulse animation frequency
@export var exit_pulse_frequency: float = 0.005
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
	queue_redraw()


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
	if not current_layout:
		return
	
	# Draw full fog first
	var ship_size = current_layout.ship_size
	var scaled_size = ship_size * minimap_scale
	draw_rect(Rect2(Vector2.ZERO, scaled_size), fog_color, true)


## Draw explored rooms
func _draw_rooms() -> void:
	if not current_layout or current_layout.room_rects.is_empty():
		return
	
	for room_rect in current_layout.room_rects:
		# Check if any explored position is near this room
		var is_explored = _is_room_explored(room_rect)
		
		if is_explored:
			# Scale room to minimap size
			var scaled_rect = Rect2(
				room_rect.position * minimap_scale,
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
		
		var scaled_pos = pos * minimap_scale
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
	
	var scaled_pos = exit_position * minimap_scale
	var size = 6.0
	
	# Draw as a pulsing diamond/square
	var pulse = 1.0 + sin(Time.get_ticks_msec() * exit_pulse_frequency) * exit_pulse_amplitude
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
	
	var scaled_pos = player_position * minimap_scale
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
