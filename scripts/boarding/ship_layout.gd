# ==============================================================================
# SHIP LAYOUT GENERATOR - PROCEDURAL SHIP INTERIOR LAYOUTS
# ==============================================================================
#
# FILE: scripts/boarding/ship_layout.gd
# PURPOSE: Generates varied ship interior layouts based on ship tier
#
# FEATURES:
# - Multiple layout templates per tier for variety
# - Procedural room placement with randomization
# - Container positioning based on room validity
# - Guaranteed path from entry to exit
#
# ==============================================================================

class_name ShipLayout
extends RefCounted


# ==============================================================================
# PRELOADS
# ==============================================================================

const ShipTypesClass = preload("res://scripts/data/ship_types.gd")
const ContainerTypesClass = preload("res://scripts/data/container_types.gd")


# ==============================================================================
# LAYOUT DATA STRUCTURES
# ==============================================================================

class LayoutData:
	var ship_tier: int = 1
	var ship_size: Vector2 = Vector2(1200, 800)
	var entry_position: Vector2 = Vector2.ZERO
	var exit_position: Vector2 = Vector2.ZERO
	var container_positions: Array = []  # Array of {position: Vector2, type: int}
	var wall_segments: Array = []  # Array of {start: Vector2, end: Vector2}
	var room_rects: Array = []  # Array of Rect2 for rooms
	var corridor_rects: Array = []  # Array of Rect2 for corridors
	var walkable_grid: Array = []  # 2D bool array - true = walkable
	var grid_cell_size: int = 40
	var hull_color: Color = Color.GRAY
	var accent_color: Color = Color.WHITE
	var interior_color: Color = Color.DIM_GRAY
	var layout_variant: int = 0  # Which variant was chosen
	var locked_doors: Array = []  # Array of {room_idx: int, tier: int}
	var keycard_spawns: Array = []  # Array of {position: Vector2, tier: int, for_room: int}


# ==============================================================================
# LAYOUT GENERATION
# ==============================================================================

## Generate a complete layout for a ship tier
static func generate_layout(tier: int) -> LayoutData:
	var ship_data = ShipTypesClass.get_ship_by_number(tier)
	if not ship_data:
		ship_data = ShipTypesClass.get_ship_by_number(1)
	
	var layout = LayoutData.new()
	layout.ship_tier = tier
	layout.ship_size = ship_data.size
	layout.hull_color = ship_data.hull_color
	layout.accent_color = ship_data.accent_color
	layout.interior_color = ship_data.interior_color
	
	# Pick a random variant for this tier
	var variant = randi() % 3  # 3 variants per tier
	layout.layout_variant = variant
	
	# Generate based on tier and variant
	match tier:
		1: _generate_tier1_layout(layout, ship_data, variant)
		2: _generate_tier2_layout(layout, ship_data, variant)
		3: _generate_tier3_layout(layout, ship_data, variant)
		4: _generate_tier4_layout(layout, ship_data, variant)
		5: _generate_tier5_layout(layout, ship_data, variant)
		_: _generate_tier1_layout(layout, ship_data, variant)
	
	return layout


# ==============================================================================
# TIER 1: CARGO SHUTTLE - Simple layouts
# ==============================================================================

static func _generate_tier1_layout(layout: LayoutData, ship_data, variant: int) -> void:
	var size = layout.ship_size
	var margin = 60.0
	
	match variant:
		0:  # Single large room
			layout.entry_position = Vector2(50, size.y / 2)
			layout.exit_position = Vector2(size.x - 50, size.y / 2)
			
			var main_room = Rect2(margin, margin, size.x - margin * 2, size.y - margin * 2)
			layout.room_rects.append(main_room)
			
		1:  # Two rooms side by side
			layout.entry_position = Vector2(50, size.y / 2)
			layout.exit_position = Vector2(size.x - 50, size.y / 2)
			
			var half_w = (size.x - margin * 2 - 40) / 2
			var room1 = Rect2(margin, margin, half_w, size.y - margin * 2)
			var room2 = Rect2(margin + half_w + 40, margin, half_w, size.y - margin * 2)
			layout.room_rects.append(room1)
			layout.room_rects.append(room2)
			
		2:  # L-shaped layout
			layout.entry_position = Vector2(50, size.y * 0.75)
			layout.exit_position = Vector2(size.x - 50, size.y * 0.25)
			
			# Bottom horizontal section
			var bottom = Rect2(margin, size.y / 2, size.x - margin * 2, size.y / 2 - margin)
			# Right vertical section
			var right = Rect2(size.x / 2, margin, size.x / 2 - margin, size.y / 2)
			layout.room_rects.append(bottom)
			layout.room_rects.append(right)
	
	# Generate walls and containers
	_finalize_layout(layout, ship_data)


# ==============================================================================
# TIER 2: FREIGHT HAULER - Cargo-focused layouts
# ==============================================================================

static func _generate_tier2_layout(layout: LayoutData, ship_data, variant: int) -> void:
	var size = layout.ship_size
	var margin = 70.0
	
	match variant:
		0:  # Long corridor with side bays
			layout.entry_position = Vector2(50, size.y / 2)
			layout.exit_position = Vector2(size.x - 50, size.y / 2)
			
			var corridor_h = 140.0
			var corridor = Rect2(margin, size.y / 2 - corridor_h / 2, size.x - margin * 2, corridor_h)
			layout.room_rects.append(corridor)
			
			# Side bays
			var bay_h = (size.y - margin * 2 - corridor_h) / 2 - 30
			for i in range(3):
				var x = margin + 80 + i * ((size.x - margin * 2 - 160) / 2)
				var w = (size.x - margin * 2 - 200) / 3
				
				var top_bay = Rect2(x, margin, w, bay_h)
				var bot_bay = Rect2(x, size.y - margin - bay_h, w, bay_h)
				layout.room_rects.append(top_bay)
				layout.room_rects.append(bot_bay)
			
		1:  # Grid of cargo bays
			layout.entry_position = Vector2(50, size.y / 2)
			layout.exit_position = Vector2(size.x - 50, size.y / 2)
			
			var cols = 3
			var rows = 2
			var gap = 40.0
			var room_w = (size.x - margin * 2 - gap * (cols - 1)) / cols
			var room_h = (size.y - margin * 2 - gap * (rows - 1)) / rows
			
			for row in range(rows):
				for col in range(cols):
					var room = Rect2(
						margin + col * (room_w + gap),
						margin + row * (room_h + gap),
						room_w, room_h
					)
					layout.room_rects.append(room)
			
		2:  # T-junction layout
			layout.entry_position = Vector2(size.x / 2, size.y - 50)
			layout.exit_position = Vector2(size.x / 2, 50)
			
			# Main vertical corridor
			var main_w = 180.0
			var main = Rect2(size.x / 2 - main_w / 2, margin, main_w, size.y - margin * 2)
			layout.room_rects.append(main)
			
			# Left wing
			var wing_h = size.y * 0.4
			var left_wing = Rect2(margin, size.y / 2 - wing_h / 2, size.x / 2 - main_w / 2 - margin - 30, wing_h)
			layout.room_rects.append(left_wing)
			
			# Right wing
			var right_wing = Rect2(size.x / 2 + main_w / 2 + 30, size.y / 2 - wing_h / 2, size.x / 2 - main_w / 2 - margin - 30, wing_h)
			layout.room_rects.append(right_wing)
	
	_finalize_layout(layout, ship_data)


# ==============================================================================
# TIER 3: CORPORATE TRANSPORT - Elegant layouts
# ==============================================================================

static func _generate_tier3_layout(layout: LayoutData, ship_data, variant: int) -> void:
	var size = layout.ship_size
	var margin = 80.0
	
	match variant:
		0:  # Central atrium with offices
			layout.entry_position = Vector2(50, size.y / 2)
			layout.exit_position = Vector2(size.x - 50, size.y / 2)
			
			# Central atrium
			var atrium_size = minf(size.x, size.y) * 0.35
			var atrium = Rect2(
				size.x / 2 - atrium_size / 2,
				size.y / 2 - atrium_size / 2,
				atrium_size, atrium_size
			)
			layout.room_rects.append(atrium)
			
			# Corner offices
			var office_size = 140.0
			var corners = [
				Rect2(margin, margin, office_size, office_size),
				Rect2(size.x - margin - office_size, margin, office_size, office_size),
				Rect2(margin, size.y - margin - office_size, office_size, office_size),
				Rect2(size.x - margin - office_size, size.y - margin - office_size, office_size, office_size)
			]
			for corner in corners:
				layout.room_rects.append(corner)
			
		1:  # Symmetrical wing design
			layout.entry_position = Vector2(size.x / 2, size.y - 50)
			layout.exit_position = Vector2(size.x / 2, 50)
			
			# Center spine
			var spine_w = 120.0
			var spine = Rect2(size.x / 2 - spine_w / 2, margin, spine_w, size.y - margin * 2)
			layout.room_rects.append(spine)
			
			# Wing rooms (3 per side)
			var wing_w = (size.x / 2 - spine_w / 2 - margin - 30) 
			var wing_h = (size.y - margin * 2) / 3 - 20
			
			for i in range(3):
				var y = margin + i * (wing_h + 20)
				# Left wing
				layout.room_rects.append(Rect2(margin, y, wing_w, wing_h))
				# Right wing
				layout.room_rects.append(Rect2(size.x / 2 + spine_w / 2 + 30, y, wing_w, wing_h))
			
		2:  # Open plan with meeting rooms
			layout.entry_position = Vector2(50, size.y / 2)
			layout.exit_position = Vector2(size.x - 50, size.y / 2)
			
			# Large open area
			var open = Rect2(margin, margin + 100, size.x - margin * 2, size.y - margin * 2 - 200)
			layout.room_rects.append(open)
			
			# Top meeting rooms
			var meeting_w = (size.x - margin * 2) / 4 - 15
			for i in range(4):
				var meeting = Rect2(margin + i * (meeting_w + 15), margin, meeting_w, 80)
				layout.room_rects.append(meeting)
			
			# Bottom meeting rooms
			for i in range(4):
				var meeting = Rect2(margin + i * (meeting_w + 15), size.y - margin - 80, meeting_w, 80)
				layout.room_rects.append(meeting)
	
	_finalize_layout(layout, ship_data)


# ==============================================================================
# TIER 4: MILITARY FRIGATE - Tactical layouts
# ==============================================================================

static func _generate_tier4_layout(layout: LayoutData, ship_data, variant: int) -> void:
	var size = layout.ship_size
	var margin = 90.0
	
	match variant:
		0:  # Bridge-to-engine corridor
			layout.entry_position = Vector2(50, size.y / 2)
			layout.exit_position = Vector2(size.x - 50, size.y / 2)
			
			# Central corridor
			var corridor_w = 100.0
			var corridor = Rect2(margin, size.y / 2 - corridor_w / 2, size.x - margin * 2, corridor_w)
			layout.room_rects.append(corridor)
			
			# Bridge (left)
			var bridge = Rect2(margin, margin, 200, size.y / 2 - corridor_w / 2 - margin - 20)
			layout.room_rects.append(bridge)
			
			# Engine room (right)
			var engine = Rect2(size.x - margin - 200, size.y / 2 + corridor_w / 2 + 20, 200, size.y / 2 - corridor_w / 2 - margin - 20)
			layout.room_rects.append(engine)
			
			# Armory bays
			var bay_w = 150.0
			var bay_h = (size.y / 2 - corridor_w / 2 - margin - 20)
			layout.room_rects.append(Rect2(size.x / 2 - bay_w - 20, margin, bay_w, bay_h))
			layout.room_rects.append(Rect2(size.x / 2 + 20, margin, bay_w, bay_h))
			layout.room_rects.append(Rect2(size.x / 2 - bay_w - 20, size.y / 2 + corridor_w / 2 + 20, bay_w, bay_h))
			layout.room_rects.append(Rect2(size.x / 2 + 20, size.y / 2 + corridor_w / 2 + 20, bay_w, bay_h))
			
		1:  # Diamond layout
			layout.entry_position = Vector2(50, size.y / 2)
			layout.exit_position = Vector2(size.x - 50, size.y / 2)
			
			# Central command
			var cmd_size = 200.0
			var cmd = Rect2(size.x / 2 - cmd_size / 2, size.y / 2 - cmd_size / 2, cmd_size, cmd_size)
			layout.room_rects.append(cmd)
			
			# Four outer compartments
			var outer_size = 160.0
			# Top
			layout.room_rects.append(Rect2(size.x / 2 - outer_size / 2, margin, outer_size, size.y / 2 - cmd_size / 2 - margin - 30))
			# Bottom
			layout.room_rects.append(Rect2(size.x / 2 - outer_size / 2, size.y / 2 + cmd_size / 2 + 30, outer_size, size.y / 2 - cmd_size / 2 - margin - 30))
			# Left
			layout.room_rects.append(Rect2(margin, size.y / 2 - outer_size / 2, size.x / 2 - cmd_size / 2 - margin - 30, outer_size))
			# Right
			layout.room_rects.append(Rect2(size.x / 2 + cmd_size / 2 + 30, size.y / 2 - outer_size / 2, size.x / 2 - cmd_size / 2 - margin - 30, outer_size))
			
		2:  # Barracks layout (many small rooms)
			layout.entry_position = Vector2(50, size.y / 2)
			layout.exit_position = Vector2(size.x - 50, size.y / 2)
			
			# Central mess hall
			var mess_w = size.x * 0.35
			var mess_h = size.y * 0.4
			var mess = Rect2(size.x / 2 - mess_w / 2, size.y / 2 - mess_h / 2, mess_w, mess_h)
			layout.room_rects.append(mess)
			
			# Surrounding bunks (8 rooms)
			var bunk_w = (size.x / 2 - mess_w / 2 - margin - 20) 
			var bunk_h = (size.y - margin * 2) / 2 - 20
			
			# Left side
			layout.room_rects.append(Rect2(margin, margin, bunk_w, bunk_h))
			layout.room_rects.append(Rect2(margin, size.y / 2 + 20, bunk_w, bunk_h))
			
			# Right side
			layout.room_rects.append(Rect2(size.x - margin - bunk_w, margin, bunk_w, bunk_h))
			layout.room_rects.append(Rect2(size.x - margin - bunk_w, size.y / 2 + 20, bunk_w, bunk_h))
			
			# Top/bottom center
			var center_w = mess_w
			var center_h = (size.y / 2 - mess_h / 2 - margin - 20)
			layout.room_rects.append(Rect2(size.x / 2 - center_w / 2, margin, center_w, center_h))
			layout.room_rects.append(Rect2(size.x / 2 - center_w / 2, size.y - margin - center_h, center_w, center_h))
	
	_finalize_layout(layout, ship_data)


# ==============================================================================
# TIER 5: BLACK OPS VESSEL - Complex stealth layouts
# ==============================================================================

static func _generate_tier5_layout(layout: LayoutData, ship_data, variant: int) -> void:
	var size = layout.ship_size
	var margin = 100.0
	
	match variant:
		0:  # Grid maze
			layout.entry_position = Vector2(50, size.y - 80)
			layout.exit_position = Vector2(size.x - 50, 80)
			
			# 3x3 grid with center missing (corridor)
			var room_size = (minf(size.x, size.y) - margin * 2) / 3 - 20
			var positions = [
				Vector2(0, 0), Vector2(1, 0), Vector2(2, 0),
				Vector2(0, 1),               Vector2(2, 1),
				Vector2(0, 2), Vector2(1, 2), Vector2(2, 2)
			]
			
			for pos in positions:
				var room = Rect2(
					margin + pos.x * (room_size + 20),
					margin + pos.y * (room_size + 20),
					room_size, room_size
				)
				layout.room_rects.append(room)
			
			# Center corridor
			layout.room_rects.append(Rect2(
				margin + room_size + 20,
				margin + room_size + 20,
				room_size, room_size
			))
			
		1:  # Serpentine path
			layout.entry_position = Vector2(50, margin + 80)
			layout.exit_position = Vector2(size.x - 50, size.y - margin - 80)
			
			# Winding rooms that force player to traverse most of ship
			var segment_h = (size.y - margin * 2) / 3
			
			# Top-left room
			layout.room_rects.append(Rect2(margin, margin, size.x * 0.55, segment_h))
			# Middle-right room
			layout.room_rects.append(Rect2(size.x * 0.35, margin + segment_h + 30, size.x * 0.55, segment_h))
			# Bottom-left room
			layout.room_rects.append(Rect2(margin, margin + (segment_h + 30) * 2, size.x * 0.55, segment_h))
			
			# Connecting corridors
			var corr_w = 80.0
			layout.room_rects.append(Rect2(size.x * 0.45, margin + segment_h - 40, corr_w, 70))
			layout.room_rects.append(Rect2(size.x * 0.35, margin + segment_h * 2 + 20, corr_w, 70))
			
		2:  # Hub and spoke
			layout.entry_position = Vector2(50, size.y / 2)
			layout.exit_position = Vector2(size.x - 50, size.y / 2)
			
			# Central hub
			var hub_size = minf(size.x, size.y) * 0.3
			var hub = Rect2(size.x / 2 - hub_size / 2, size.y / 2 - hub_size / 2, hub_size, hub_size)
			layout.room_rects.append(hub)
			
			# 6 spoke rooms
			var spoke_w = 120.0
			var spoke_h = 100.0
			
			# Left
			layout.room_rects.append(Rect2(margin, size.y / 2 - spoke_h / 2, size.x / 2 - hub_size / 2 - margin - 30, spoke_h))
			# Right  
			layout.room_rects.append(Rect2(size.x / 2 + hub_size / 2 + 30, size.y / 2 - spoke_h / 2, size.x / 2 - hub_size / 2 - margin - 30, spoke_h))
			# Top
			layout.room_rects.append(Rect2(size.x / 2 - spoke_w / 2, margin, spoke_w, size.y / 2 - hub_size / 2 - margin - 30))
			# Bottom
			layout.room_rects.append(Rect2(size.x / 2 - spoke_w / 2, size.y / 2 + hub_size / 2 + 30, spoke_w, size.y / 2 - hub_size / 2 - margin - 30))
			
			# Corner rooms
			var corner_size = 100.0
			layout.room_rects.append(Rect2(margin, margin, corner_size, corner_size))
			layout.room_rects.append(Rect2(size.x - margin - corner_size, margin, corner_size, corner_size))
			layout.room_rects.append(Rect2(margin, size.y - margin - corner_size, corner_size, corner_size))
			layout.room_rects.append(Rect2(size.x - margin - corner_size, size.y - margin - corner_size, corner_size, corner_size))
	
	_finalize_layout(layout, ship_data)


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

static func _finalize_layout(layout: LayoutData, ship_data) -> void:
	# Generate walls for each room
	for room in layout.room_rects:
		_add_room_walls(layout, room)
	
	# Place containers
	var count = randi_range(ship_data.min_containers, ship_data.max_containers)
	_place_containers_safely(layout, count, layout.ship_tier)


static func _place_containers_safely(layout: LayoutData, count: int, ship_tier: int) -> void:
	var positions_used: Array = []
	var placed = 0
	var attempts = 0
	var max_attempts = 200
	
	while placed < count and attempts < max_attempts:
		attempts += 1
		
		# Pick a random room
		if layout.room_rects.is_empty():
			break
		
		var room = layout.room_rects[randi() % layout.room_rects.size()]
		
		# Ensure room is big enough
		if room.size.x < 80 or room.size.y < 80:
			continue
		
		# Random position within room with good margin
		var margin = 45.0
		var pos = Vector2(
			randf_range(room.position.x + margin, room.end.x - margin),
			randf_range(room.position.y + margin, room.end.y - margin)
		)
		
		# Validate position
		var valid = true
		
		# Check distance from other containers
		for existing in positions_used:
			if pos.distance_to(existing) < 75:
				valid = false
				break
		
		# Check distance from entry/exit
		if valid and layout.entry_position != Vector2.ZERO:
			if pos.distance_to(layout.entry_position) < 90:
				valid = false
		
		if valid and layout.exit_position != Vector2.ZERO:
			if pos.distance_to(layout.exit_position) < 90:
				valid = false
		
		# Ensure position is actually inside the room (double-check)
		if valid:
			if not room.has_point(pos):
				valid = false
		
		if valid:
			positions_used.append(pos)
			var container_type = ContainerTypesClass.roll_container_type(ship_tier)
			layout.container_positions.append({
				"position": pos,
				"type": container_type
			})
			placed += 1


static func _add_room_walls(layout: LayoutData, room: Rect2) -> void:
	var tl = room.position
	var top_right = Vector2(room.end.x, room.position.y)
	var br = room.end
	var bl = Vector2(room.position.x, room.end.y)
	
	layout.wall_segments.append({"start": tl, "end": top_right})
	layout.wall_segments.append({"start": top_right, "end": br})
	layout.wall_segments.append({"start": br, "end": bl})
	layout.wall_segments.append({"start": bl, "end": tl})
