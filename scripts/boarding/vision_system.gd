# ==============================================================================
# VISION SYSTEM - FOG OF WAR AND PLAYER VISION CONE
# ==============================================================================
#
# FILE: scripts/boarding/vision_system.gd
# PURPOSE: Manages player vision cone, fog of war reveal, and peripheral blur
#
# FEATURES:
# - 90° vision cone following mouse direction
# - Fog of war covering unexplored areas
# - Revealed areas stay visible but dimmed when not in active view
# - Smooth transitions between states with soft edges
# - Gradient fog edges for visual quality
#
# ==============================================================================

class_name VisionSystem
extends Node2D


# ==============================================================================
# SIGNALS
# ==============================================================================

signal area_revealed(world_pos: Vector2)
signal vision_updated


# ==============================================================================
# CONSTANTS
# ==============================================================================

## Vision cone half-angle in radians (90° cone = 45° half-angle)
const VISION_CONE_HALF_ANGLE: float = PI / 4.0  # 45 degrees

## Maximum vision distance in pixels
const MAX_VISION_DISTANCE: float = 600.0

## Resolution of the reveal texture (cells per pixel)
## Larger = better performance, smaller = smoother edges
const REVEAL_CELL_SIZE: int = 24  # Balance of performance and quality

## How fast fog transitions (per second)
const FOG_TRANSITION_SPEED: float = 6.0

## How fast revealed areas dim when out of view
const DIM_SPEED: float = 3.0

## Dim level for revealed but not visible areas (0 = invisible, 1 = fully visible)
const REVEALED_DIM_LEVEL: float = 0.35

## Edge softness multiplier (how gradual the fog edge is)
const EDGE_SOFTNESS: float = 2.0

## How often to update fog texture (frames between updates)
const FOG_UPDATE_INTERVAL: int = 2


# ==============================================================================
# EXPORTS
# ==============================================================================

@export var enabled: bool = true
@export var debug_draw: bool = false
@export var reveal_on_start: bool = false  # Start with fog or revealed
@export var always_visible_radius: float = 80.0  # Minimum always-visible area around player

@export_group("Visual Quality")
## Fog color (usually dark/black)
@export var fog_color: Color = Color(0.02, 0.03, 0.05, 1.0)
## Enable soft edges on vision cone
@export var soft_edges: bool = true
## Enable gradient visibility falloff
@export var gradient_falloff: bool = true


# ==============================================================================
# STATE
# ==============================================================================

## The player we're tracking
var player: Node2D = null

## Current look direction (normalized)
var look_direction: Vector2 = Vector2.RIGHT

## Current mouse world position
var mouse_world_pos: Vector2 = Vector2.ZERO

## Reveal grid - tracks which cells have been discovered
## Dictionary[Vector2i] -> float (0 = undiscovered, 1 = fully revealed)
var reveal_grid: Dictionary = {}

## Active vision grid - what's currently in the vision cone
## Dictionary[Vector2i] -> float (0 = not visible, 1 = fully visible)
var active_vision_grid: Dictionary = {}

## Current visibility grid - smooth interpolated values for rendering
## Dictionary[Vector2i] -> float (current rendered alpha)
var visibility_grid: Dictionary = {}

## Ship bounds for limiting the fog
var ship_bounds: Rect2 = Rect2()

## Grid dimensions
var grid_width: int = 0
var grid_height: int = 0

## Frame counter for performance optimization
var _update_frame: int = 0


# ==============================================================================
# COMPONENTS
# ==============================================================================

var fog_sprite: Sprite2D = null
var fog_texture: ImageTexture = null
var fog_image: Image = null


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Create fog overlay
	_setup_fog_overlay()


func _process(delta: float) -> void:
	if not enabled or not player:
		return
	
	# Update look direction based on mouse
	_update_look_direction()
	
	# Update which cells are in the vision cone
	_update_active_vision()
	
	# Update fog texture
	_update_fog_texture(delta)
	
	# Redraw debug visualization
	if debug_draw:
		queue_redraw()


# ==============================================================================
# SETUP
# ==============================================================================

func initialize(p_player: Node2D, p_bounds: Rect2) -> void:
	player = p_player
	ship_bounds = p_bounds
	
	# Calculate grid dimensions
	grid_width = ceili(ship_bounds.size.x / REVEAL_CELL_SIZE) + 2
	grid_height = ceili(ship_bounds.size.y / REVEAL_CELL_SIZE) + 2
	
	# Initialize grids
	reveal_grid.clear()
	active_vision_grid.clear()
	
	# Create fog texture
	_create_fog_texture()
	
	# Optionally reveal starting area
	if reveal_on_start:
		reveal_area(player.global_position, always_visible_radius * 2)


func _setup_fog_overlay() -> void:
	# Create sprite for fog
	fog_sprite = Sprite2D.new()
	fog_sprite.name = "FogOverlay"
	fog_sprite.z_index = 100  # Above most things
	fog_sprite.centered = false
	
	# Use texture filtering for smoother appearance
	fog_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	add_child(fog_sprite)


func _create_fog_texture() -> void:
	if grid_width <= 0 or grid_height <= 0:
		return
	
	# Create image for fog
	fog_image = Image.create(grid_width, grid_height, false, Image.FORMAT_RGBA8)
	fog_image.fill(fog_color)  # Start fully fogged with configured color
	
	# Create texture from image
	fog_texture = ImageTexture.create_from_image(fog_image)
	
	# Apply to sprite with scaling
	fog_sprite.texture = fog_texture
	fog_sprite.scale = Vector2(REVEAL_CELL_SIZE, REVEAL_CELL_SIZE)
	fog_sprite.position = ship_bounds.position - Vector2(REVEAL_CELL_SIZE, REVEAL_CELL_SIZE)


# ==============================================================================
# VISION UPDATES
# ==============================================================================

func _update_look_direction() -> void:
	if not player:
		return
	
	# Get mouse position in world coordinates
	mouse_world_pos = get_global_mouse_position()
	
	# Calculate direction from player to mouse
	var to_mouse = mouse_world_pos - player.global_position
	if to_mouse.length_squared() > 1.0:
		look_direction = to_mouse.normalized()


func _update_active_vision() -> void:
	if not player:
		return
	
	var player_pos = player.global_position
	var player_cell = _world_to_grid(player_pos)
	
	# Clear active vision (but not reveal grid)
	active_vision_grid.clear()
	
	# Calculate vision cone bounds
	var vision_radius_cells = ceili(MAX_VISION_DISTANCE / REVEAL_CELL_SIZE)
	
	# Scan all cells within vision radius
	for dx in range(-vision_radius_cells, vision_radius_cells + 1):
		for dy in range(-vision_radius_cells, vision_radius_cells + 1):
			var cell = Vector2i(player_cell.x + dx, player_cell.y + dy)
			
			# Skip if outside grid
			if cell.x < 0 or cell.y < 0 or cell.x >= grid_width or cell.y >= grid_height:
				continue
			
			var cell_world = _grid_to_world(cell)
			var to_cell = cell_world - player_pos
			var distance = to_cell.length()
			
			# Always visible in minimum radius with soft falloff
			if distance <= always_visible_radius:
				active_vision_grid[cell] = 1.0
				reveal_grid[cell] = 1.0
				continue
			
			# Smooth falloff around always-visible radius (no hard edge)
			var inner_edge = always_visible_radius * 0.6
			var outer_edge = always_visible_radius + REVEAL_CELL_SIZE * EDGE_SOFTNESS
			if distance <= outer_edge:
				var edge_factor: float
				if distance <= inner_edge:
					edge_factor = 1.0
				else:
					# Smooth quadratic falloff
					var t = (distance - inner_edge) / (outer_edge - inner_edge)
					edge_factor = 1.0 - (t * t)  # Quadratic falloff
				active_vision_grid[cell] = maxf(active_vision_grid.get(cell, 0.0), edge_factor)
				reveal_grid[cell] = 1.0
				continue
			
			# Check if within max distance
			if distance > MAX_VISION_DISTANCE:
				continue
			
			# Check if within vision cone with soft edges
			if to_cell.length_squared() > 1.0:
				var angle_to_cell = look_direction.angle_to(to_cell.normalized())
				var abs_angle = absf(angle_to_cell)
				
				if abs_angle <= VISION_CONE_HALF_ANGLE:
					# In the cone - calculate visibility
					var visibility = 1.0
					
					# Distance falloff
					if gradient_falloff:
						var dist_factor = 1.0 - pow(distance / MAX_VISION_DISTANCE, 1.5)
						visibility *= dist_factor
					
					# Soft edge at cone boundary
					if soft_edges:
						var edge_start = VISION_CONE_HALF_ANGLE * 0.7
						if abs_angle > edge_start:
							var edge_factor = 1.0 - (
								(abs_angle - edge_start) / 
								(VISION_CONE_HALF_ANGLE - edge_start)
							)
							visibility *= edge_factor
					
					active_vision_grid[cell] = visibility
					reveal_grid[cell] = 1.0  # Permanently revealed


func _update_fog_texture(delta: float) -> void:
	if not fog_image or not fog_texture:
		return
	
	_update_frame += 1
	
	# Skip frames for performance (update every N frames)
	if _update_frame % FOG_UPDATE_INTERVAL != 0:
		return
	
	# Adjust delta for skipped frames
	var adjusted_delta = delta * FOG_UPDATE_INTERVAL
	
	# Update visibility grid and write directly to image
	for x in range(grid_width):
		for y in range(grid_height):
			var cell = Vector2i(x, y)
			var revealed = reveal_grid.get(cell, 0.0)
			var active = active_vision_grid.get(cell, 0.0)
			var current_vis = visibility_grid.get(cell, 0.0)
			
			# Calculate target visibility
			var target_vis: float
			if active > 0.0:
				target_vis = active
			elif revealed > 0.0:
				target_vis = REVEALED_DIM_LEVEL
			else:
				target_vis = 0.0
			
			# Smooth interpolation
			var speed = FOG_TRANSITION_SPEED if target_vis > current_vis else DIM_SPEED
			var new_vis = lerpf(current_vis, target_vis, speed * adjusted_delta)
			visibility_grid[cell] = new_vis
			
			# Write directly to fog image (skip separate blur pass)
			var fog_alpha = 1.0 - new_vis
			fog_image.set_pixel(x, y, Color(fog_color.r, fog_color.g, fog_color.b, fog_alpha))
	
	# Update texture - texture filtering provides smoothing
	fog_texture.update(fog_image)


## Apply simple edge smoothing (legacy, not used by default)
func _apply_fog_blur() -> void:
	# First pass: write visibility to image
	for x in range(grid_width):
		for y in range(grid_height):
			var cell = Vector2i(x, y)
			var vis = visibility_grid.get(cell, 0.0)
			var fog_alpha = 1.0 - vis
			fog_image.set_pixel(x, y, Color(fog_color.r, fog_color.g, fog_color.b, fog_alpha))
	
	# Apply a simple 3x3 box blur for smoother edges
	if soft_edges:
		var blurred_image = fog_image.duplicate()
		for x in range(1, grid_width - 1):
			for y in range(1, grid_height - 1):
				var sum_alpha := 0.0
				var kernel_sum := 0.0
				# 3x3 Gaussian-ish kernel weights
				var weights = [
					[0.0625, 0.125, 0.0625],
					[0.125, 0.25, 0.125],
					[0.0625, 0.125, 0.0625]
				]
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var px = fog_image.get_pixel(x + dx, y + dy)
						var w = weights[dy + 1][dx + 1]
						sum_alpha += px.a * w
						kernel_sum += w
				
				var orig = fog_image.get_pixel(x, y)
				var blurred_alpha = sum_alpha / kernel_sum
				blurred_image.set_pixel(x, y, Color(orig.r, orig.g, orig.b, blurred_alpha))
		
		# Copy blurred back
		for x in range(1, grid_width - 1):
			for y in range(1, grid_height - 1):
				var px = blurred_image.get_pixel(x, y)
				fog_image.set_pixel(x, y, px)


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Reveal an area around a position
func reveal_area(world_pos: Vector2, radius: float) -> void:
	var center_cell = _world_to_grid(world_pos)
	var radius_cells = ceili(radius / REVEAL_CELL_SIZE)
	
	for dx in range(-radius_cells, radius_cells + 1):
		for dy in range(-radius_cells, radius_cells + 1):
			var cell = Vector2i(center_cell.x + dx, center_cell.y + dy)
			if cell.x >= 0 and cell.y >= 0 and cell.x < grid_width and cell.y < grid_height:
				var cell_world = _grid_to_world(cell)
				if cell_world.distance_to(world_pos) <= radius:
					reveal_grid[cell] = 1.0
					area_revealed.emit(cell_world)


## Check if a position is currently visible (in vision cone)
func is_position_visible(world_pos: Vector2) -> bool:
	var cell = _world_to_grid(world_pos)
	return active_vision_grid.get(cell, 0.0) > 0.0


## Check if a position has been revealed (discovered)
func is_position_revealed(world_pos: Vector2) -> bool:
	var cell = _world_to_grid(world_pos)
	return reveal_grid.get(cell, 0.0) > 0.0


## Get the current look direction
func get_look_direction() -> Vector2:
	return look_direction


## Get vision cone angle (for external use)
func get_vision_cone_angle() -> float:
	return VISION_CONE_HALF_ANGLE * 2.0


## Set the player reference (for late binding)
func set_player(p_player: Node2D) -> void:
	player = p_player


## Set the look direction manually
func set_look_direction(direction: Vector2) -> void:
	if direction.length_squared() > 0.01:
		look_direction = direction.normalized()
		queue_redraw()


# ==============================================================================
# COORDINATE CONVERSION
# ==============================================================================

func _world_to_grid(world_pos: Vector2) -> Vector2i:
	var local = world_pos - ship_bounds.position + Vector2(REVEAL_CELL_SIZE, REVEAL_CELL_SIZE)
	return Vector2i(
		int(local.x / REVEAL_CELL_SIZE),
		int(local.y / REVEAL_CELL_SIZE)
	)


func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		ship_bounds.position.x + grid_pos.x * REVEAL_CELL_SIZE - REVEAL_CELL_SIZE,
		ship_bounds.position.y + grid_pos.y * REVEAL_CELL_SIZE - REVEAL_CELL_SIZE
	) + Vector2(REVEAL_CELL_SIZE / 2.0, REVEAL_CELL_SIZE / 2.0)


# ==============================================================================
# DEBUG DRAWING
# ==============================================================================

func _draw() -> void:
	if not debug_draw or not player:
		return
	
	var player_pos = player.global_position - global_position
	
	# Draw vision cone
	var left_dir = look_direction.rotated(-VISION_CONE_HALF_ANGLE)
	var right_dir = look_direction.rotated(VISION_CONE_HALF_ANGLE)
	
	# Draw cone edges
	draw_line(player_pos, player_pos + left_dir * MAX_VISION_DISTANCE, Color.GREEN, 2)
	draw_line(player_pos, player_pos + right_dir * MAX_VISION_DISTANCE, Color.GREEN, 2)
	
	# Draw min radius circle
	draw_arc(player_pos, always_visible_radius, 0, TAU, 32, Color.YELLOW, 1)
	
	# Draw max radius arc in cone
	var arc_points: PackedVector2Array = []
	var arc_segments = 16
	for i in range(arc_segments + 1):
		var t = float(i) / arc_segments
		var angle = look_direction.angle() - VISION_CONE_HALF_ANGLE
		angle += t * VISION_CONE_HALF_ANGLE * 2.0
		arc_points.append(player_pos + Vector2.from_angle(angle) * MAX_VISION_DISTANCE)
	
	for i in range(arc_points.size() - 1):
		draw_line(arc_points[i], arc_points[i + 1], Color.GREEN, 1)
	
	# Draw look direction
	draw_line(player_pos, player_pos + look_direction * 100, Color.CYAN, 3)
