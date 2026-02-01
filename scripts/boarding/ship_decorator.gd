# ==============================================================================
# SHIP DECORATOR - DECORATION PLACEMENT SYSTEM
# ==============================================================================
#
# FILE: scripts/boarding/ship_decorator.gd
# PURPOSE: Manages decoration placement for procedurally generated ships
#
# FEATURES:
# - Room-type appropriate decoration placement
# - Faction-themed decoration pools
# - Density settings per room type
# - Automatic wall/floor/ceiling decoration placement
# - Damage/wear decoration based on ship condition
#
# ==============================================================================

class_name ShipDecorator
extends RefCounted


# ==============================================================================
# PRELOADS
# ==============================================================================

const DecorationDataClass = preload("res://resources/decorations/decoration_data.gd")
const FactionsClass = preload("res://scripts/data/factions.gd")


# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Density settings per room type (0.0 to 1.0)
const ROOM_DENSITY_SETTINGS = {
	"bridge": 0.8,
	"engine_room": 0.9,
	"cargo_bay": 0.6,
	"storage": 0.7,
	"crew_quarters": 0.7,
	"med_bay": 0.5,
	"armory": 0.6,
	"lab": 0.7,
	"server_room": 0.8,
	"corridor": 0.4,
	"entry_airlock": 0.5,
	"exit_airlock": 0.5,
	"vault": 0.4,
	"executive_suite": 0.8,
	"conference": 0.6,
	"barracks": 0.7,
	"supply_room": 0.6,
	"contraband_hold": 0.5,
	"default": 0.5
}

# Category mix ratios per room type
const ROOM_CATEGORY_MIX = {
	"bridge": {"functional": 0.7, "atmospheric": 0.25, "damage": 0.05},
	"engine_room": {"functional": 0.8, "atmospheric": 0.1, "damage": 0.1},
	"cargo_bay": {"functional": 0.3, "atmospheric": 0.6, "damage": 0.1},
	"storage": {"functional": 0.4, "atmospheric": 0.5, "damage": 0.1},
	"crew_quarters": {"functional": 0.3, "atmospheric": 0.65, "damage": 0.05},
	"med_bay": {"functional": 0.6, "atmospheric": 0.35, "damage": 0.05},
	"armory": {"functional": 0.5, "atmospheric": 0.4, "damage": 0.1},
	"lab": {"functional": 0.7, "atmospheric": 0.25, "damage": 0.05},
	"server_room": {"functional": 0.85, "atmospheric": 0.1, "damage": 0.05},
	"corridor": {"functional": 0.5, "atmospheric": 0.45, "damage": 0.05},
	"default": {"functional": 0.5, "atmospheric": 0.4, "damage": 0.1}
}


# ==============================================================================
# STATE
# ==============================================================================

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _faction_type: int = FactionsClass.Type.CCG
var _ship_tier: int = 1
var _wear_level: float = 0.3  # 0.0 = pristine, 1.0 = heavily damaged


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Generate decorations for a room
func generate_room_decorations(
	room_rect: Rect2,
	room_type_name: String,
	faction_type: int,
	ship_tier: int,
	seed_value: int = -1
) -> Array[DecorationDataClass.DecorationPlacement]:
	
	if seed_value >= 0:
		_rng.seed = seed_value
	else:
		_rng.randomize()
	
	_faction_type = faction_type
	_ship_tier = ship_tier
	_wear_level = _calculate_wear_level(ship_tier)
	
	var decorations: Array[DecorationDataClass.DecorationPlacement] = []
	var room_tag = _normalize_room_name(room_type_name)
	
	# Get density for this room type
	var density = ROOM_DENSITY_SETTINGS.get(room_tag, ROOM_DENSITY_SETTINGS["default"])
	
	# Get category mix
	var category_mix = ROOM_CATEGORY_MIX.get(room_tag, ROOM_CATEGORY_MIX["default"])
	
	# Calculate number of decorations based on room size and density
	var room_area = room_rect.size.x * room_rect.size.y
	var base_count = int(room_area / 5000.0 * density)
	var decoration_count = _rng.randi_range(
		maxi(1, base_count - 2),
		base_count + 3
	)
	
	# Place decorations by category
	var functional_count = int(decoration_count * category_mix["functional"])
	var atmospheric_count = int(decoration_count * category_mix["atmospheric"])
	var damage_count = int(decoration_count * category_mix["damage"] * _wear_level)
	
	# Generate functional decorations
	decorations.append_array(
		_place_decorations_of_category(
			DecorationDataClass.Category.FUNCTIONAL,
			functional_count,
			room_rect,
			room_tag
		)
	)
	
	# Generate atmospheric decorations
	decorations.append_array(
		_place_decorations_of_category(
			DecorationDataClass.Category.ATMOSPHERIC,
			atmospheric_count,
			room_rect,
			room_tag
		)
	)
	
	# Generate damage/wear decorations
	decorations.append_array(
		_place_decorations_of_category(
			DecorationDataClass.Category.DAMAGE_WEAR,
			damage_count,
			room_rect,
			room_tag
		)
	)
	
	return decorations


## Generate decorations for multiple rooms
func generate_ship_decorations(
	rooms: Array,  # Array of {rect: Rect2, type: String}
	faction_type: int,
	ship_tier: int,
	seed_value: int = -1
) -> Dictionary:
	
	if seed_value >= 0:
		_rng.seed = seed_value
	
	var result = {}
	
	for i in range(rooms.size()):
		var room = rooms[i]
		var room_seed = (_rng.seed + i * 12345) if seed_value >= 0 else -1
		
		var decorations = generate_room_decorations(
			room.rect,
			room.type,
			faction_type,
			ship_tier,
			room_seed
		)
		
		result[i] = decorations
	
	return result


## Set wear level manually (0.0 = pristine, 1.0 = heavily damaged)
func set_wear_level(level: float) -> void:
	_wear_level = clampf(level, 0.0, 1.0)


# ==============================================================================
# PRIVATE METHODS - DECORATION PLACEMENT
# ==============================================================================

func _place_decorations_of_category(
	category: DecorationDataClass.Category,
	count: int,
	room_rect: Rect2,
	room_tag: String
) -> Array[DecorationDataClass.DecorationPlacement]:
	
	var placements: Array[DecorationDataClass.DecorationPlacement] = []
	var placed_positions: Array[Vector2] = []
	
	# Get available decorations for this category and room type
	var available_decorations = _get_available_decorations(category, room_tag)
	if available_decorations.is_empty():
		return placements
	
	var attempts = 0
	var max_attempts = count * 10
	
	while placements.size() < count and attempts < max_attempts:
		attempts += 1
		
		# Pick a random decoration from available pool
		var decoration = _pick_decoration(available_decorations)
		if not decoration:
			continue
		
		# Determine placement position
		var position: Vector2
		var rotation: float = 0.0
		
		if decoration.wall_mounted:
			position = _find_wall_position(room_rect, decoration, placed_positions)
			if position == Vector2(-1, -1):
				continue
			rotation = _rng.randf_range(0, TAU) if decoration.rotation_allowed else 0.0
		else:
			position = _find_floor_position(room_rect, decoration, placed_positions)
			if position == Vector2(-1, -1):
				continue
			rotation = _rng.randf_range(0, TAU) if decoration.rotation_allowed else 0.0
		
		# Create placement
		var placement = DecorationDataClass.DecorationPlacement.new()
		placement.decoration_type = decoration.type
		placement.position = position
		placement.rotation = rotation
		placement.color_tint = _get_decoration_tint(decoration)
		placement.flicker_enabled = decoration.has_animation and _rng.randf() > 0.5
		placement.animation_offset = _rng.randf_range(0.0, TAU)
		
		placements.append(placement)
		placed_positions.append(position)
	
	return placements


func _get_available_decorations(
	category: DecorationDataClass.Category,
	room_tag: String
) -> Array[DecorationDataClass.Decoration]:
	
	var all_decorations = DecorationDataClass.get_decorations_by_category(category)
	var available: Array[DecorationDataClass.Decoration] = []
	
	for deco in all_decorations:
		# Check if suitable for room
		if not deco.room_type_tags.is_empty():
			var match_found = false
			for tag in deco.room_type_tags:
				if tag in room_tag or room_tag in tag:
					match_found = true
					break
			if not match_found:
				continue
		
		# Check faction-specific decorations
		if deco.faction_specific:
			# Map faction type to poster type
			var faction_poster_offset = _faction_type
			var expected_type = DecorationDataClass.Type.POSTER_FACTION_CCG + faction_poster_offset
			if deco.type != expected_type:
				continue
		
		available.append(deco)
	
	return available


func _pick_decoration(decorations: Array[DecorationDataClass.Decoration]) -> DecorationDataClass.Decoration:
	if decorations.is_empty():
		return null
	
	# Build weighted list (rare items have lower weight)
	var weights: Array[float] = []
	var total_weight = 0.0
	
	for deco in decorations:
		var weight = 1.0 if not deco.rare else 0.3
		weights.append(weight)
		total_weight += weight
	
	# Pick weighted random
	var roll = _rng.randf_range(0, total_weight)
	var accumulated = 0.0
	
	for i in range(decorations.size()):
		accumulated += weights[i]
		if roll <= accumulated:
			return decorations[i]
	
	return decorations[0]


func _find_wall_position(
	room_rect: Rect2,
	decoration: DecorationDataClass.Decoration,
	existing_positions: Array[Vector2]
) -> Vector2:
	
	var margin = 15.0
	var min_spacing = 25.0
	var attempts = 0
	var max_attempts = 20
	
	while attempts < max_attempts:
		attempts += 1
		
		# Pick a random wall (0=top, 1=right, 2=bottom, 3=left)
		var wall = _rng.randi_range(0, 3)
		var position: Vector2
		
		match wall:
			0:  # Top wall
				position = Vector2(
					_rng.randf_range(room_rect.position.x + margin, room_rect.end.x - margin),
					room_rect.position.y + decoration.size.y / 2 + 5
				)
			1:  # Right wall
				position = Vector2(
					room_rect.end.x - decoration.size.x / 2 - 5,
					_rng.randf_range(room_rect.position.y + margin, room_rect.end.y - margin)
				)
			2:  # Bottom wall
				position = Vector2(
					_rng.randf_range(room_rect.position.x + margin, room_rect.end.x - margin),
					room_rect.end.y - decoration.size.y / 2 - 5
				)
			3:  # Left wall
				position = Vector2(
					room_rect.position.x + decoration.size.x / 2 + 5,
					_rng.randf_range(room_rect.position.y + margin, room_rect.end.y - margin)
				)
		
		# Check spacing from existing decorations
		var valid = true
		for existing in existing_positions:
			if position.distance_to(existing) < min_spacing:
				valid = false
				break
		
		if valid:
			return position
	
	return Vector2(-1, -1)


func _find_floor_position(
	room_rect: Rect2,
	decoration: DecorationDataClass.Decoration,
	existing_positions: Array[Vector2]
) -> Vector2:
	
	var margin = 25.0
	var min_spacing = 30.0
	var attempts = 0
	var max_attempts = 20
	
	while attempts < max_attempts:
		attempts += 1
		
		var position = Vector2(
			_rng.randf_range(room_rect.position.x + margin, room_rect.end.x - margin),
			_rng.randf_range(room_rect.position.y + margin, room_rect.end.y - margin)
		)
		
		# Check spacing from existing decorations
		var valid = true
		for existing in existing_positions:
			if position.distance_to(existing) < min_spacing:
				valid = false
				break
		
		if valid:
			return position
	
	return Vector2(-1, -1)


func _get_decoration_tint(decoration: DecorationDataClass.Decoration) -> Color:
	# Apply faction-themed tints to certain decorations
	var base_tint = decoration.color
	
	# Functional decorations get faction accent color influence
	if decoration.category == DecorationDataClass.Category.FUNCTIONAL:
		var faction_data = FactionsClass.get_faction(_faction_type)
		if faction_data and faction_data.theme:
			var accent = faction_data.theme.accent_color
			base_tint = base_tint.lerp(accent, 0.2)
	
	return base_tint


# ==============================================================================
# PRIVATE METHODS - HELPERS
# ==============================================================================

func _normalize_room_name(name: String) -> String:
	return name.to_lower().replace(" ", "_")


func _calculate_wear_level(tier: int) -> float:
	# Higher tier ships tend to be better maintained
	match tier:
		1: return _rng.randf_range(0.3, 0.6)  # Civilian ships, moderate wear
		2: return _rng.randf_range(0.2, 0.5)  # Freight, some wear
		3: return _rng.randf_range(0.1, 0.3)  # Corporate, well-maintained
		4: return _rng.randf_range(0.15, 0.4) # Military, combat damage
		5: return _rng.randf_range(0.2, 0.5)  # Black ops, battle-worn
		_: return 0.3
