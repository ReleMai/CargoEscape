# ==============================================================================
# MODERN MINIMAP - CLEAN PROFESSIONAL MINIMAP SYSTEM
# ==============================================================================
#
# FILE: scripts/ui/modern_minimap.gd
# PURPOSE: Professional minimap with clean icons and visibility
#
# FEATURES:
# - Clean vector-style rendering
# - Distinct icons for different object types
# - Smooth player tracking
# - Fog of war with gradient edges
# - Enemy tracking when visible
# - Objective markers
#
# ==============================================================================

extends Control
class_name ModernMinimap


# ==============================================================================
# SIGNALS
# ==============================================================================

signal marker_clicked(marker_type: String, position: Vector2)


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Size & Scale")
@export var minimap_size: Vector2 = Vector2(180, 180)
@export var map_scale: float = 0.1
@export var zoom_level: float = 1.0

@export_group("Colors")
@export var background_color: Color = Color(0.08, 0.1, 0.12, 0.95)
@export var border_color: Color = Color(0.3, 0.35, 0.4, 1.0)
@export var room_color: Color = Color(0.18, 0.22, 0.28, 1.0)
@export var room_explored_color: Color = Color(0.25, 0.3, 0.38, 1.0)
@export var wall_color: Color = Color(0.4, 0.45, 0.5, 1.0)
@export var fog_color: Color = Color(0.05, 0.06, 0.08, 0.98)

@export_group("Player")
@export var player_color: Color = Color(0.2, 0.9, 0.4, 1.0)
@export var player_size: float = 6.0
@export var vision_cone_color: Color = Color(0.2, 0.9, 0.4, 0.15)

@export_group("Markers")
@export var exit_color: Color = Color(0.3, 0.8, 1.0, 1.0)
@export var container_color: Color = Color(0.9, 0.7, 0.2, 1.0)
@export var container_searched_color: Color = Color(0.4, 0.4, 0.4, 0.5)
@export var enemy_color: Color = Color(1.0, 0.3, 0.3, 1.0)
@export var objective_color: Color = Color(1.0, 0.85, 0.0, 1.0)


# ==============================================================================
# STATE
# ==============================================================================

var layout_data = null  # ShipLayout.LayoutData
var player_pos: Vector2 = Vector2.ZERO
var player_direction: Vector2 = Vector2.RIGHT
var exit_pos: Vector2 = Vector2.ZERO

var containers: Array = []  # {pos: Vector2, searched: bool, type: String}
var enemies: Array = []  # {pos: Vector2, alert: bool}
var objectives: Array = []  # {pos: Vector2, type: String}

var explored_cells: Dictionary = {}  # Vector2i -> bool
var exploration_resolution: float = 50.0


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	custom_minimum_size = minimap_size
	clip_contents = true


func _draw() -> void:
	# Background with rounded corners
	_draw_background()
	
	# Clip to circular/rounded area
	_draw_map_contents()
	
	# Border
	_draw_border()
	
	# Compass/direction indicator
	_draw_compass()


## Throttle updates to reduce draw calls
var _update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.05  # 20 FPS for minimap is plenty

func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= UPDATE_INTERVAL:
		_update_timer = 0.0
		queue_redraw()


# ==============================================================================
# DRAWING
# ==============================================================================

func _draw_background() -> void:
	var rect = Rect2(Vector2.ZERO, minimap_size)
	
	# Draw rounded rectangle background
	var radius = 8.0
	draw_rect(rect, background_color)
	
	# Subtle gradient overlay
	var center = minimap_size / 2.0
	for i in range(3):
		var r = minimap_size.x / 2.0 - i * 20
		var alpha = 0.02 * (3 - i)
		draw_circle(center, r, Color(1, 1, 1, alpha))


func _draw_map_contents() -> void:
	if not layout_data:
		_draw_no_data_message()
		return
	
	var center = minimap_size / 2.0
	var effective_scale = map_scale * zoom_level
	
	# Calculate offset to center on player
	var offset = center - player_pos * effective_scale
	
	# Draw fog of war first
	_draw_fog_of_war(offset, effective_scale)
	
	# Draw rooms
	_draw_rooms(offset, effective_scale)
	
	# Draw containers
	_draw_containers(offset, effective_scale)
	
	# Draw enemies
	_draw_enemies(offset, effective_scale)
	
	# Draw objectives
	_draw_objectives(offset, effective_scale)
	
	# Draw exit
	_draw_exit(offset, effective_scale)
	
	# Draw player (always on top)
	_draw_player(center)


func _draw_no_data_message() -> void:
	var center = minimap_size / 2.0
	draw_circle(center, 4, Color(0.5, 0.5, 0.5, 0.5))


func _draw_fog_of_war(offset: Vector2, scale: float) -> void:
	# Draw unexplored areas as fog
	if not layout_data or not layout_data.rooms:
		return
	
	for room in layout_data.rooms:
		var room_rect = Rect2(room.position, room.size)
		var screen_rect = Rect2(
			room_rect.position * scale + offset,
			room_rect.size * scale
		)
		
		# Check if room is explored
		var room_center = room.position + room.size / 2.0
		var cell = Vector2i(room_center / exploration_resolution)
		
		if not explored_cells.get(cell, false):
			draw_rect(screen_rect, fog_color)


func _draw_rooms(offset: Vector2, scale: float) -> void:
	if not layout_data or not layout_data.rooms:
		return
	
	for room in layout_data.rooms:
		var room_rect = Rect2(room.position, room.size)
		var screen_rect = Rect2(
			room_rect.position * scale + offset,
			room_rect.size * scale
		)
		
		# Skip if outside minimap bounds
		if not _rect_visible(screen_rect):
			continue
		
		# Check exploration state
		var room_center = room.position + room.size / 2.0
		var cell = Vector2i(room_center / exploration_resolution)
		var explored = explored_cells.get(cell, false)
		
		# Draw room fill
		var fill_color = room_explored_color if explored else room_color
		draw_rect(screen_rect, fill_color)
		
		# Draw room border
		draw_rect(screen_rect, wall_color, false, 1.5)


func _draw_containers(offset: Vector2, scale: float) -> void:
	for container in containers:
		var screen_pos = container.pos * scale + offset
		
		if not _point_visible(screen_pos):
			continue
		
		# Check if in explored area
		var cell = Vector2i(container.pos / exploration_resolution)
		if not explored_cells.get(cell, false):
			continue
		
		var color = container_searched_color if container.searched else container_color
		var size = 4.0 if container.searched else 5.0
		
		# Draw container as small square
		var rect = Rect2(screen_pos - Vector2(size/2, size/2), Vector2(size, size))
		draw_rect(rect, color)
		
		# Glow effect for unsearched
		if not container.searched:
			draw_rect(rect.grow(1), Color(color.r, color.g, color.b, 0.3), false, 1)


func _draw_enemies(offset: Vector2, scale: float) -> void:
	for enemy in enemies:
		var screen_pos = enemy.pos * scale + offset
		
		if not _point_visible(screen_pos):
			continue
		
		# Only show enemies in explored areas or if alerted
		var cell = Vector2i(enemy.pos / exploration_resolution)
		if not explored_cells.get(cell, false) and not enemy.get("alert", false):
			continue
		
		var size = 5.0
		var color = enemy_color
		
		# Pulsing effect for alerted enemies
		if enemy.get("alert", false):
			var pulse = (sin(Time.get_ticks_msec() * 0.01) + 1) * 0.5
			color = color.lerp(Color.WHITE, pulse * 0.3)
			size += pulse * 2
		
		# Draw enemy as triangle pointing in facing direction
		var dir = enemy.get("direction", Vector2.DOWN)
		_draw_enemy_marker(screen_pos, size, dir, color)


func _draw_enemy_marker(pos: Vector2, size: float, dir: Vector2, color: Color) -> void:
	var angle = dir.angle()
	var points = PackedVector2Array()
	
	# Triangle pointing in direction
	points.append(pos + Vector2(size, 0).rotated(angle))
	points.append(pos + Vector2(-size * 0.6, size * 0.5).rotated(angle))
	points.append(pos + Vector2(-size * 0.6, -size * 0.5).rotated(angle))
	
	draw_colored_polygon(points, color)
	draw_polyline(points, color.lightened(0.2), 1.0, true)


func _draw_objectives(offset: Vector2, scale: float) -> void:
	for objective in objectives:
		var screen_pos = objective.pos * scale + offset
		
		if not _point_visible(screen_pos):
			# Draw edge indicator if objective is off-screen
			_draw_offscreen_indicator(screen_pos, objective_color)
			continue
		
		# Draw diamond shape
		var size = 6.0
		var points = PackedVector2Array([
			screen_pos + Vector2(0, -size),
			screen_pos + Vector2(size, 0),
			screen_pos + Vector2(0, size),
			screen_pos + Vector2(-size, 0)
		])
		
		draw_colored_polygon(points, objective_color)
		
		# Pulsing glow
		var pulse = (sin(Time.get_ticks_msec() * 0.005) + 1) * 0.5
		var glow_size = size + 2 + pulse * 2
		var glow_points = PackedVector2Array([
			screen_pos + Vector2(0, -glow_size),
			screen_pos + Vector2(glow_size, 0),
			screen_pos + Vector2(0, glow_size),
			screen_pos + Vector2(-glow_size, 0)
		])
		draw_polyline(glow_points, Color(objective_color.r, objective_color.g, objective_color.b, 0.5 * pulse), 2.0, true)


func _draw_exit(offset: Vector2, scale: float) -> void:
	var screen_pos = exit_pos * scale + offset
	
	if not _point_visible(screen_pos):
		_draw_offscreen_indicator(screen_pos, exit_color)
		return
	
	var size = 7.0
	var pulse = (sin(Time.get_ticks_msec() * 0.004) + 1) * 0.5
	
	# Draw exit as circle with arrow
	draw_circle(screen_pos, size, exit_color)
	draw_circle(screen_pos, size + 2 + pulse * 2, Color(exit_color.r, exit_color.g, exit_color.b, 0.3 * pulse))
	
	# Inner detail
	draw_circle(screen_pos, size * 0.5, Color(1, 1, 1, 0.8))


func _draw_player(center: Vector2) -> void:
	# Player is always at center
	var size = player_size
	
	# Vision cone (subtle)
	var cone_length = 40.0
	var cone_angle = PI / 4  # 45 degrees
	var dir_angle = player_direction.angle()
	
	var cone_points = PackedVector2Array([center])
	for i in range(9):
		var angle = dir_angle - cone_angle / 2 + (cone_angle * i / 8.0)
		cone_points.append(center + Vector2(cone_length, 0).rotated(angle))
	
	draw_colored_polygon(cone_points, vision_cone_color)
	
	# Player marker (triangle pointing in facing direction)
	var player_points = PackedVector2Array()
	player_points.append(center + Vector2(size, 0).rotated(dir_angle))
	player_points.append(center + Vector2(-size * 0.6, size * 0.6).rotated(dir_angle))
	player_points.append(center + Vector2(-size * 0.6, -size * 0.6).rotated(dir_angle))
	
	draw_colored_polygon(player_points, player_color)
	
	# Outline
	draw_polyline(player_points, Color.WHITE, 1.5, true)


func _draw_offscreen_indicator(screen_pos: Vector2, color: Color) -> void:
	var center = minimap_size / 2.0
	var dir = (screen_pos - center).normalized()
	var edge_pos = center + dir * (minimap_size.x / 2.0 - 10)
	
	# Draw arrow pointing towards target
	var arrow_size = 6.0
	var points = PackedVector2Array([
		edge_pos + dir * arrow_size,
		edge_pos + dir.rotated(2.5) * arrow_size * 0.6,
		edge_pos + dir.rotated(-2.5) * arrow_size * 0.6
	])
	
	var pulse = (sin(Time.get_ticks_msec() * 0.006) + 1) * 0.5
	var alpha = 0.6 + pulse * 0.4
	
	draw_colored_polygon(points, Color(color.r, color.g, color.b, alpha))


func _draw_border() -> void:
	var rect = Rect2(Vector2.ZERO, minimap_size)
	
	# Main border
	draw_rect(rect, border_color, false, 2.0)
	
	# Inner highlight
	var inner = rect.grow(-2)
	draw_rect(inner, Color(1, 1, 1, 0.05), false, 1.0)


func _draw_compass() -> void:
	# North indicator at top
	var top_center = Vector2(minimap_size.x / 2.0, 8)
	
	# "N" label
	draw_string(
		ThemeDB.fallback_font,
		top_center + Vector2(-4, 4),
		"N",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		10,
		Color(0.6, 0.65, 0.7, 0.8)
	)


# ==============================================================================
# HELPERS
# ==============================================================================

func _rect_visible(rect: Rect2) -> bool:
	var bounds = Rect2(Vector2.ZERO, minimap_size)
	return bounds.intersects(rect)


func _point_visible(point: Vector2) -> bool:
	return point.x >= 0 and point.x <= minimap_size.x and \
		   point.y >= 0 and point.y <= minimap_size.y


# ==============================================================================
# PUBLIC API
# ==============================================================================

func set_layout(layout) -> void:
	layout_data = layout
	explored_cells.clear()
	queue_redraw()


func update_player(pos: Vector2, direction: Vector2) -> void:
	player_pos = pos
	player_direction = direction
	
	# Mark current area as explored
	var cell = Vector2i(pos / exploration_resolution)
	explored_cells[cell] = true
	
	# Also mark adjacent cells for smoother exploration
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var adj_cell = cell + Vector2i(dx, dy)
			var adj_pos = Vector2(adj_cell) * exploration_resolution
			if pos.distance_to(adj_pos) < exploration_resolution * 1.5:
				explored_cells[adj_cell] = true


func set_exit(pos: Vector2) -> void:
	exit_pos = pos


func set_containers(container_list: Array) -> void:
	containers = container_list


func update_container_searched(index: int) -> void:
	if index >= 0 and index < containers.size():
		containers[index].searched = true


func set_enemies(enemy_list: Array) -> void:
	enemies = enemy_list


func update_enemy(index: int, pos: Vector2, alert: bool, direction: Vector2 = Vector2.DOWN) -> void:
	if index >= 0 and index < enemies.size():
		enemies[index].pos = pos
		enemies[index].alert = alert
		enemies[index].direction = direction


func add_objective(pos: Vector2, type: String = "default") -> void:
	objectives.append({"pos": pos, "type": type})


func remove_objective(pos: Vector2) -> void:
	for i in range(objectives.size() - 1, -1, -1):
		if objectives[i].pos.distance_to(pos) < 10:
			objectives.remove_at(i)


func clear_objectives() -> void:
	objectives.clear()


func set_zoom(level: float) -> void:
	zoom_level = clampf(level, 0.5, 2.0)


func reveal_all() -> void:
	# Debug function to reveal entire map
	if layout_data and layout_data.rooms:
		for room in layout_data.rooms:
			var room_center = room.position + room.size / 2.0
			var cell = Vector2i(room_center / exploration_resolution)
			explored_cells[cell] = true
