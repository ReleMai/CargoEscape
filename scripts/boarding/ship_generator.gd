# ==============================================================================
# SHIP GENERATOR - PROCEDURAL SHIP INTERIOR GENERATION
# ==============================================================================
#
# FILE: scripts/boarding/ship_generator.gd
# PURPOSE: Generates unique ship layouts using grid-based room placement
#
# ALGORITHM:
# 1. Initialize grid based on ship size
# 2. Place essential rooms (entry, exit)
# 3. Place required rooms for ship class
# 4. Fill with appropriate common/special rooms
# 5. Generate corridors connecting all rooms
# 6. Place containers within rooms
# 7. Validate paths from entry to exit
#
# ==============================================================================

class_name ShipGenerator
extends RefCounted


# ==============================================================================
# CONSTANTS
# ==============================================================================

const CELL_SIZE: int = 40  # Grid cell size in pixels
const MIN_ROOM_GAP: int = 1  # Minimum cells between rooms
const MIN_CORRIDOR_WIDTH: int = 2  # Minimum corridor width in cells

# Cell states
enum CellState {
	EMPTY,
	WALL,
	ROOM,
	CORRIDOR,
	DOOR,
	RESERVED
}


# ==============================================================================
# PRELOADS
# ==============================================================================

const FactionsClass = preload("res://scripts/data/factions.gd")
const RoomTypesClass = preload("res://scripts/data/room_types.gd")
const ShipTypesClass = preload("res://scripts/data/ship_types.gd")
const ContainerTypesClass = preload("res://scripts/data/container_types.gd")
const ShipDecoratorClass = preload("res://scripts/boarding/ship_decorator.gd")
const DecorationDataClass = preload("res://resources/decorations/decoration_data.gd")


# ==============================================================================
# DATA STRUCTURES
# ==============================================================================

class RoomInstance:
	var type: RoomTypesClass.Type
	var rect: Rect2
	var display_name: String
	var container_placements: Array = []  # [{position: Vector2, type: int}]
	var decoration_placements: Array = []  # Array of DecorationPlacement
	var connected_to: Array = []  # Other room indices
	var center: Vector2:
		get: return rect.position + rect.size / 2.0

class CorridorInstance:
	var start_room_idx: int
	var end_room_idx: int
	var path_cells: Array = []  # Array of Vector2i grid positions
	var width: int = 2

class GeneratedLayout:
	var ship_tier: int = 1
	var faction_type: FactionsClass.Type = FactionsClass.Type.CCG
	var ship_size: Vector2 = Vector2(900, 600)
	var rooms: Array = []  # Array of RoomInstance
	var corridors: Array = []  # Array of CorridorInstance
	var corridor_rects: Array = []  # Array of Rect2 for corridor cells
	var walkable_grid: Array = []  # 2D bool grid - true = walkable
	var grid_cell_size: int = 40
	var entry_position: Vector2 = Vector2.ZERO
	var exit_position: Vector2 = Vector2.ZERO
	var container_positions: Array = []  # Combined from all rooms
	var decoration_placements: Dictionary = {}  # Room index -> Array of DecorationPlacement
	var time_limit: float = 90.0
	var generation_seed: int = 0
	
	# Visual data from faction
	var hull_color: Color = Color.GRAY
	var accent_color: Color = Color.WHITE
	var interior_floor: Color = Color.DIM_GRAY
	var interior_wall: Color = Color.DARK_GRAY
	var lighting_tint: Color = Color.WHITE


# ==============================================================================
# GENERATION STATE
# ==============================================================================

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _grid: Array = []  # 2D array of CellState
var _grid_width: int = 0
var _grid_height: int = 0
var _ship_size: Vector2 = Vector2.ZERO
var _current_tier: int = 1
var _current_faction: FactionsClass.FactionData = null
var _placed_rooms: Array = []  # Array of RoomInstance


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Generate a complete ship layout
static func generate(
	tier: int,
	faction_type = null,  # FactionsClass.Type or null for random
	seed_value: int = -1
) -> GeneratedLayout:
	var generator = ShipGenerator.new()
	return generator.generate_layout(tier, faction_type, seed_value)


## Generate with distance factor (auto-selects tier/faction)
static func generate_for_distance(distance_factor: float, seed_value: int = -1) -> GeneratedLayout:
	var tier = ShipTypesClass.roll_ship_tier(distance_factor)
	var faction = FactionsClass.roll_faction_for_tier(tier)
	
	var generator = ShipGenerator.new()
	return generator.generate_layout(tier, faction.type, seed_value)


# ==============================================================================
# GENERATION IMPLEMENTATION
# ==============================================================================

func generate_layout(
	tier: int,
	faction_type,
	seed_value: int
) -> GeneratedLayout:
	# Initialize RNG
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	
	# Get ship and faction data
	var ship_data = ShipTypesClass.get_ship_by_number(tier)
	if not ship_data:
		ship_data = ShipTypesClass.get_ship_by_number(1)
	
	if faction_type != null:
		_current_faction = FactionsClass.get_faction(faction_type)
	else:
		_current_faction = FactionsClass.roll_faction_for_tier(tier)
	
	_current_tier = tier
	_ship_size = ship_data.size
	
	# Initialize grid
	_init_grid()
	
	# Create layout result
	var layout = GeneratedLayout.new()
	layout.ship_tier = tier
	layout.faction_type = _current_faction.type
	layout.ship_size = _ship_size
	layout.time_limit = ship_data.time_limit
	layout.generation_seed = _rng.seed
	
	# Apply faction theme
	var theme = _current_faction.theme
	layout.hull_color = theme.hull_color
	layout.accent_color = theme.accent_color
	layout.interior_floor = theme.interior_floor
	layout.interior_wall = theme.interior_wall
	layout.lighting_tint = theme.lighting_tint
	layout.grid_cell_size = CELL_SIZE
	
	# Generate rooms
	_placed_rooms.clear()
	
	# 1. Place entry and exit airlocks
	_place_entry_exit(layout)
	
	# 2. Place required rooms for tier
	_place_required_rooms()
	
	# 3. Fill remaining space with appropriate rooms
	var target_room_count = _get_target_room_count()
	_fill_with_rooms(target_room_count)
	
	# 4. Generate corridors connecting all rooms
	_generate_corridors()
	
	# 5. Place containers within rooms
	_place_containers()
	
	# 6. Generate decorations for all rooms
	_place_decorations(layout)
	
	# 7. Copy rooms to layout
	layout.rooms = _placed_rooms.duplicate()
	
	# 8. Compile container positions
	for room in _placed_rooms:
		layout.container_positions.append_array(room.container_placements)
	
	# 9. Get corridor rects and walkable grid for rendering/collision
	layout.corridor_rects = get_corridor_rects()
	layout.walkable_grid = get_walkable_grid()
	
	# 10. Validate path exists
	if not _validate_path(layout):
		print("[ShipGenerator] Warning: Generated layout may have unreachable areas")
	
	return layout


func _init_grid() -> void:
	_grid_width = int(_ship_size.x / CELL_SIZE)
	_grid_height = int(_ship_size.y / CELL_SIZE)
	
	_grid.clear()
	for col_idx in range(_grid_width):
		var column: Array = []
		for row_idx in range(_grid_height):
			column.append(CellState.EMPTY)
		_grid.append(column)
	
	# Mark ship boundary as walls (outer edge)
	for x in range(_grid_width):
		_grid[x][0] = CellState.WALL
		_grid[x][_grid_height - 1] = CellState.WALL
	for y in range(_grid_height):
		_grid[0][y] = CellState.WALL
		_grid[_grid_width - 1][y] = CellState.WALL


func _place_entry_exit(layout: GeneratedLayout) -> void:
	var entry_data = RoomTypesClass.get_room(RoomTypesClass.Type.ENTRY_AIRLOCK)
	var exit_data = RoomTypesClass.get_room(RoomTypesClass.Type.EXIT_AIRLOCK)
	
	# Entry: left side of ship
	var entry_size = entry_data.preferred_size
	var entry_pos = Vector2(
		CELL_SIZE * 2,  # Near left edge
		(_ship_size.y - entry_size.y) / 2.0  # Vertical center
	)
	
	var entry_room = _create_room(RoomTypesClass.Type.ENTRY_AIRLOCK, entry_pos, entry_size)
	if entry_room:
		_placed_rooms.append(entry_room)
		layout.entry_position = entry_room.center
	
	# Exit: right side or opposite corner based on tier
	var exit_size = exit_data.preferred_size
	var exit_pos: Vector2
	
	if _current_tier >= 3:
		# Higher tiers: exit can be at a corner
		var corner_choice = _rng.randi() % 2
		if corner_choice == 0:
			exit_pos = Vector2(
				_ship_size.x - exit_size.x - CELL_SIZE * 2,
				CELL_SIZE * 2  # Top right
			)
		else:
			exit_pos = Vector2(
				_ship_size.x - exit_size.x - CELL_SIZE * 2,
				_ship_size.y - exit_size.y - CELL_SIZE * 2  # Bottom right
			)
	else:
		# Lower tiers: exit on right side, similar height to entry
		exit_pos = Vector2(
			_ship_size.x - exit_size.x - CELL_SIZE * 2,
			(_ship_size.y - exit_size.y) / 2.0
		)
	
	var exit_room = _create_room(RoomTypesClass.Type.EXIT_AIRLOCK, exit_pos, exit_size)
	if exit_room:
		_placed_rooms.append(exit_room)
		layout.exit_position = exit_room.center


func _place_required_rooms() -> void:
	# Place tier-specific required rooms
	match _current_tier:
		1:
			_try_place_room_type(RoomTypesClass.Type.CARGO_BAY, "center")
		2:
			_try_place_room_type(RoomTypesClass.Type.CARGO_BAY, "center")
			_try_place_room_type(RoomTypesClass.Type.STORAGE, "any")
		3:
			_try_place_room_type(RoomTypesClass.Type.BRIDGE, "front")
			_try_place_room_type(RoomTypesClass.Type.CARGO_BAY, "center")
		4:
			_try_place_room_type(RoomTypesClass.Type.BRIDGE, "front")
			_try_place_room_type(RoomTypesClass.Type.ENGINE_ROOM, "back")
			_try_place_room_type(RoomTypesClass.Type.ARMORY, "side")
		5:
			_try_place_room_type(RoomTypesClass.Type.BRIDGE, "front")
			_try_place_room_type(RoomTypesClass.Type.ENGINE_ROOM, "back")
			_try_place_room_type(RoomTypesClass.Type.VAULT, "center")
			_try_place_room_type(RoomTypesClass.Type.ARMORY, "side")


func _try_place_room_type(type: RoomTypesClass.Type, position_hint: String) -> bool:
	var room_data = RoomTypesClass.get_room(type)
	if not room_data:
		return false
	
	var size = _randomize_size(room_data.min_size, room_data.max_size, room_data.preferred_size)
	var pos = _find_position_for_hint(size, position_hint)
	
	if pos == Vector2(-1, -1):
		return false
	
	var room = _create_room(type, pos, size)
	if room:
		_placed_rooms.append(room)
		return true
	
	return false


func _fill_with_rooms(target_count: int) -> void:
	var attempts = 0
	var max_attempts = 100
	
	while _placed_rooms.size() < target_count and attempts < max_attempts:
		attempts += 1
		
		# Get room types already placed
		var placed_types: Array[RoomTypesClass.Type] = []
		for room in _placed_rooms:
			placed_types.append(room.type)
		
		# Roll for a room type
		var room_type = RoomTypesClass.roll_room_type(
			_current_faction.room_preferences,
			_current_tier,
			placed_types
		)
		
		var room_data = RoomTypesClass.get_room(room_type)
		if not room_data:
			continue
		
		var size = _randomize_size(room_data.min_size, room_data.max_size, room_data.preferred_size)
		var pos = _find_valid_position(size)
		
		if pos != Vector2(-1, -1):
			var room = _create_room(room_type, pos, size)
			if room:
				_placed_rooms.append(room)


func _get_target_room_count() -> int:
	# Base count by tier
	var base = 3 + _current_tier * 2
	# Add some randomness
	return base + _rng.randi_range(-1, 2)


func _randomize_size(min_size: Vector2, max_size: Vector2, preferred: Vector2) -> Vector2:
	# Bias towards preferred size with some variation
	var lerp_factor = _rng.randf_range(0.3, 0.7)
	var size = preferred.lerp(max_size, lerp_factor)
	
	# Snap to grid
	size.x = snapped(size.x, CELL_SIZE)
	size.y = snapped(size.y, CELL_SIZE)
	
	# Clamp
	size.x = clampf(size.x, min_size.x, max_size.x)
	size.y = clampf(size.y, min_size.y, max_size.y)
	
	return size


func _find_position_for_hint(size: Vector2, hint: String) -> Vector2:
	var margin = CELL_SIZE * 3
	var candidates: Array = []
	
	match hint:
		"front":
			# Right side of ship (front in top-down view)
			for i in range(5):
				candidates.append(Vector2(
					_ship_size.x - size.x - margin - _rng.randf_range(0, 100),
					margin + _rng.randf_range(0, _ship_size.y - size.y - margin * 2)
				))
		"back":
			# Left side of ship (back in top-down view)
			for i in range(5):
				candidates.append(Vector2(
					margin + _rng.randf_range(0, 100),
					margin + _rng.randf_range(0, _ship_size.y - size.y - margin * 2)
				))
		"center":
			# Center of ship
			for i in range(5):
				candidates.append(Vector2(
					(_ship_size.x - size.x) / 2.0 + _rng.randf_range(-50, 50),
					(_ship_size.y - size.y) / 2.0 + _rng.randf_range(-50, 50)
				))
		"side":
			# Top or bottom
			for i in range(5):
				var top = _rng.randf() > 0.5
				var y_pos: float
				if top:
					y_pos = float(margin)
				else:
					y_pos = _ship_size.y - size.y - margin
				candidates.append(Vector2(
					margin + _rng.randf_range(0, _ship_size.x - size.x - margin * 2),
					y_pos
				))
		_:  # "any"
			candidates.append(_find_valid_position(size))
	
	# Try each candidate
	for pos in candidates:
		pos = _snap_to_grid(pos)
		if _can_place_room(pos, size):
			return pos
	
	# Fallback to any valid position
	return _find_valid_position(size)


func _find_valid_position(size: Vector2) -> Vector2:
	var margin = CELL_SIZE * 2
	var max_attempts = 50
	
	for attempt in range(max_attempts):
		var pos = Vector2(
			_rng.randf_range(margin, _ship_size.x - size.x - margin),
			_rng.randf_range(margin, _ship_size.y - size.y - margin)
		)
		pos = _snap_to_grid(pos)
		
		if _can_place_room(pos, size):
			return pos
	
	return Vector2(-1, -1)  # Failed to find position


func _snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		snapped(pos.x, CELL_SIZE),
		snapped(pos.y, CELL_SIZE)
	)


func _can_place_room(pos: Vector2, size: Vector2) -> bool:
	var rect = Rect2(pos, size)
	var ship_rect = Rect2(Vector2.ZERO, _ship_size).grow(-CELL_SIZE)
	
	# Check bounds
	if not ship_rect.encloses(rect):
		return false
	
	# Check overlap with existing rooms (with gap)
	var expanded_rect = rect.grow(CELL_SIZE * MIN_ROOM_GAP)
	for room in _placed_rooms:
		if expanded_rect.intersects(room.rect):
			return false
	
	return true


func _create_room(type: RoomTypesClass.Type, pos: Vector2, size: Vector2) -> RoomInstance:
	var room_data = RoomTypesClass.get_room(type)
	if not room_data:
		return null
	
	var room = RoomInstance.new()
	room.type = type
	room.rect = Rect2(pos, size)
	room.display_name = room_data.display_name
	
	# Mark grid cells as occupied
	_mark_room_on_grid(room)
	
	return room


func _mark_room_on_grid(room: RoomInstance) -> void:
	var start_x = int(room.rect.position.x / CELL_SIZE)
	var start_y = int(room.rect.position.y / CELL_SIZE)
	var end_x = int(room.rect.end.x / CELL_SIZE)
	var end_y = int(room.rect.end.y / CELL_SIZE)
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			if x >= 0 and x < _grid_width and y >= 0 and y < _grid_height:
				_grid[x][y] = CellState.ROOM


# ==============================================================================
# CORRIDOR GENERATION (Minimum Spanning Tree)
# ==============================================================================

func _generate_corridors() -> void:
	if _placed_rooms.size() < 2:
		return
	
	# Build MST using Prim's algorithm
	var connected: Array = [0]  # Start with first room (entry)
	var unconnected: Array = range(1, _placed_rooms.size())
	
	while not unconnected.is_empty():
		var best_distance = INF
		var best_connected_idx = -1
		var best_unconnected_idx = -1
		
		for c_idx in connected:
			for u_idx in unconnected:
				var dist = _placed_rooms[c_idx].center.distance_to(_placed_rooms[u_idx].center)
				if dist < best_distance:
					best_distance = dist
					best_connected_idx = c_idx
					best_unconnected_idx = u_idx
		
		if best_unconnected_idx >= 0:
			# Create corridor between these rooms
			_create_corridor(best_connected_idx, best_unconnected_idx)
			
			# Mark rooms as connected
			_placed_rooms[best_connected_idx].connected_to.append(best_unconnected_idx)
			_placed_rooms[best_unconnected_idx].connected_to.append(best_connected_idx)
			
			# Move to connected
			connected.append(best_unconnected_idx)
			unconnected.erase(best_unconnected_idx)
	
	# Optionally add extra connections for loops (makes navigation more interesting)
	if _current_tier >= 3 and _placed_rooms.size() >= 4:
		_add_extra_connections()


func _create_corridor(room_a_idx: int, room_b_idx: int) -> void:
	var room_a = _placed_rooms[room_a_idx]
	var room_b = _placed_rooms[room_b_idx]
	
	# Find closest edges between rooms
	var start = _get_room_edge_point(room_a, room_b.center)
	var end = _get_room_edge_point(room_b, room_a.center)
	
	# Create L-shaped or straight corridor
	var corridor = CorridorInstance.new()
	corridor.start_room_idx = room_a_idx
	corridor.end_room_idx = room_b_idx
	corridor.width = MIN_CORRIDOR_WIDTH
	
	# Decide corridor path (horizontal then vertical, or vice versa)
	var mid_point: Vector2
	if _rng.randf() > 0.5:
		mid_point = Vector2(end.x, start.y)  # Horizontal first
	else:
		mid_point = Vector2(start.x, end.y)  # Vertical first
	
	# Mark corridor cells on grid
	_mark_corridor_segment(start, mid_point, corridor.width)
	_mark_corridor_segment(mid_point, end, corridor.width)


func _get_room_edge_point(room: RoomInstance, target: Vector2) -> Vector2:
	var center = room.center
	var rect = room.rect
	
	# Determine which edge is closest to target
	var dir = (target - center).normalized()
	
	if abs(dir.x) > abs(dir.y):
		# Horizontal edge
		if dir.x > 0:
			return Vector2(rect.end.x, center.y)  # Right edge
		return Vector2(rect.position.x, center.y)  # Left edge
	
	# Vertical edge
	if dir.y > 0:
		return Vector2(center.x, rect.end.y)  # Bottom edge
	return Vector2(center.x, rect.position.y)  # Top edge


func _mark_corridor_segment(start: Vector2, end: Vector2, width: int) -> void:
	var start_cell = Vector2i(int(start.x / CELL_SIZE), int(start.y / CELL_SIZE))
	var end_cell = Vector2i(int(end.x / CELL_SIZE), int(end.y / CELL_SIZE))
	
	# Bresenham-like line with width
	var x_step = sign(end_cell.x - start_cell.x) if end_cell.x != start_cell.x else 0
	var y_step = sign(end_cell.y - start_cell.y) if end_cell.y != start_cell.y else 0
	
	var current = start_cell
	@warning_ignore("integer_division")
	var half_width: int = width / 2
	while true:
		# Mark cells around current position for width
		for wx in range(-half_width, half_width + 1):
			for wy in range(-half_width, half_width + 1):
				var cx = current.x + wx
				var cy = current.y + wy
				if cx >= 0 and cx < _grid_width and cy >= 0 and cy < _grid_height:
					if _grid[cx][cy] == CellState.EMPTY:
						_grid[cx][cy] = CellState.CORRIDOR
		
		if current == end_cell:
			break
		
		# Move towards end
		if x_step != 0 and current.x != end_cell.x:
			current.x += x_step
		elif y_step != 0 and current.y != end_cell.y:
			current.y += y_step
		else:
			break


func _add_extra_connections() -> void:
	# Add 1-2 extra corridors for variety
	var extra_count = _rng.randi_range(0, 1)
	
	for extra_idx in range(extra_count):
		if _placed_rooms.size() < 3:
			break
		
		# Find two rooms not already connected
		var attempts = 0
		while attempts < 20:
			attempts += 1
			var idx_a = _rng.randi() % _placed_rooms.size()
			var idx_b = _rng.randi() % _placed_rooms.size()
			
			if idx_a == idx_b:
				continue
			if idx_b in _placed_rooms[idx_a].connected_to:
				continue
			
			_create_corridor(idx_a, idx_b)
			_placed_rooms[idx_a].connected_to.append(idx_b)
			_placed_rooms[idx_b].connected_to.append(idx_a)
			break


# ==============================================================================
# CONTAINER PLACEMENT
# ==============================================================================

func _place_containers() -> void:
	for room in _placed_rooms:
		var room_data = RoomTypesClass.get_room(room.type)
		if not room_data or room_data.max_containers == 0:
			continue
		
		var count = _rng.randi_range(room_data.min_containers, room_data.max_containers)
		if count == 0:
			continue
		
		var placed_positions: Array = []
		var margin = 40.0
		
		for container_idx in range(count):
			var attempts = 0
			while attempts < 20:
				attempts += 1
				
				# Random position within room
				var pos = Vector2(
					_rng.randf_range(room.rect.position.x + margin, room.rect.end.x - margin),
					_rng.randf_range(room.rect.position.y + margin, room.rect.end.y - margin)
				)
				
				# Check distance from other containers
				var valid = true
				for existing_pos in placed_positions:
					if pos.distance_to(existing_pos) < 60:
						valid = false
						break
				
				if valid:
					placed_positions.append(pos)
					
					# Roll container type
					var container_type: int
					if room_data.container_types.is_empty():
						container_type = ContainerTypesClass.roll_container_type(_current_tier)
					else:
						var type_idx = _rng.randi() % room_data.container_types.size()
						container_type = room_data.container_types[type_idx]
					
					room.container_placements.append({
						"position": pos,
						"type": container_type
					})
					break


# ==============================================================================
# DECORATION PLACEMENT
# ==============================================================================

func _place_decorations(layout: GeneratedLayout) -> void:
	var decorator = ShipDecoratorClass.new()
	
	for i in range(_placed_rooms.size()):
		var room = _placed_rooms[i]
		var room_data = RoomTypesClass.get_room(room.type)
		if not room_data:
			continue
		
		# Generate decoration seed based on ship seed and room index
		var room_seed = layout.generation_seed + i * 7919
		
		# Generate decorations for this room
		var decorations = decorator.generate_room_decorations(
			room.rect,
			room.display_name,
			_current_faction.type,
			_current_tier,
			room_seed
		)
		
		# Store in room and layout
		room.decoration_placements = decorations
		layout.decoration_placements[i] = decorations


# ==============================================================================
# VALIDATION
# ==============================================================================

func _validate_path(_layout: GeneratedLayout) -> bool:
	# Simple connectivity check - BFS from entry room
	if _placed_rooms.is_empty():
		return false
	
	var visited: Array = []
	var queue: Array = [0]  # Start from entry (room 0)
	
	while not queue.is_empty():
		var current = queue.pop_front()
		if current in visited:
			continue
		visited.append(current)
		
		for connected_idx in _placed_rooms[current].connected_to:
			if connected_idx not in visited:
				queue.append(connected_idx)
	
	# Check if exit room (index 1) is reachable
	return 1 in visited


## Get all corridor cells as rectangles for rendering
func get_corridor_rects() -> Array:
	var rects: Array = []
	var corridor_size = float(CELL_SIZE)
	
	for x in range(_grid_width):
		for y in range(_grid_height):
			if _grid[x][y] == CellState.CORRIDOR:
				var cell_rect = Rect2(
					x * corridor_size,
					y * corridor_size,
					corridor_size,
					corridor_size
				)
				rects.append(cell_rect)
	
	return rects


## Get all walkable cells (rooms + corridors) as a grid for collision
func get_walkable_grid() -> Array:
	var walkable: Array = []
	
	for x in range(_grid_width):
		var column: Array = []
		for y in range(_grid_height):
			var cell = _grid[x][y]
			column.append(cell == CellState.ROOM or cell == CellState.CORRIDOR)
		walkable.append(column)
	
	return walkable
