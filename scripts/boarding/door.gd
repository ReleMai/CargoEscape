# ==============================================================================
# DOOR - AUTOMATIC SCI-FI DOOR
# ==============================================================================
#
# FILE: scripts/boarding/door.gd
# PURPOSE: Doors that auto-open when player approaches, with animations
#
# FEATURES:
# - Auto-opens when player enters detection zone
# - Can also be clicked or E pressed to toggle
# - Smooth sliding animation
# - No collision when open
#
# ==============================================================================

class_name Door
extends Area2D


# ==============================================================================
# SIGNALS
# ==============================================================================

signal door_opened(door: Door)
signal door_closed(door: Door)
signal door_locked(door: Door)
signal door_unlocked(door: Door)


# ==============================================================================
# ENUMS
# ==============================================================================

enum State {
	OPEN,
	CLOSED,
	LOCKED,
	BLOCKED,
	OPENING,
	CLOSING
}

enum LockType {
	NONE,
	KEYCARD,
	HACK,
	SECURITY,
	DAMAGED
}


# ==============================================================================
# EXPORTS
# ==============================================================================

@export var initial_state: State = State.CLOSED
@export var lock_type: LockType = LockType.NONE
@export var lock_tier: int = 1
@export var auto_open: bool = true  # Opens when player approaches
@export var auto_close: bool = true  # Closes when player leaves
@export var auto_close_delay: float = 1.5
@export var is_airlock: bool = false


# ==============================================================================
# DOOR DIMENSIONS
# ==============================================================================

var door_width: float = 80.0
var door_thickness: float = 14.0
var is_horizontal: bool = true


# ==============================================================================
# STATE
# ==============================================================================

var current_state: State = State.CLOSED
var player_nearby: bool = false
var connected_rooms: Array[int] = []  # Room indices this door connects
var _auto_close_timer: float = 0.0
var _animation_progress: float = 0.0  # 0 = closed, 1 = open
var _animation_speed: float = 5.0  # How fast door opens/closes

## Enhanced animation state
var _light_pulse_timer: float = 0.0
var _opening_flash_intensity: float = 0.0
var _particle_timer: float = 0.0


# ==============================================================================
# COMPONENTS
# ==============================================================================

var _collision_shape: CollisionShape2D
var _wall_collision: StaticBody2D
var _interaction_prompt: Label
var _left_panel: ColorRect
var _right_panel: ColorRect
var _light_beam_left: ColorRect
var _light_beam_right: ColorRect
var _context_menu: PopupMenu = null


# ==============================================================================
# CONTEXT MENU ACTIONS
# ==============================================================================

enum ContextAction {
	LOCK,
	UNLOCK,
	CLOSE,
	OPEN
}


# ==============================================================================
# COLORS
# ==============================================================================

const COLOR_OPEN = Color(0.2, 0.75, 0.3, 0.9)
const COLOR_CLOSED = Color(0.5, 0.55, 0.6, 0.95)
const COLOR_LOCKED = Color(0.9, 0.25, 0.2, 0.95)
const COLOR_BLOCKED = Color(0.35, 0.35, 0.35, 0.95)


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	current_state = initial_state
	_animation_progress = 1.0 if initial_state == State.OPEN else 0.0
	
	_setup_detection()
	_setup_visuals()
	_setup_click_input()
	_update_collision()
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set collision to detect player
	collision_layer = 0
	collision_mask = 2  # Player layer


func _process(delta: float) -> void:
	# Handle animation
	_update_animation(delta)
	
	# Auto-close timer
	if auto_close and current_state == State.OPEN and not player_nearby:
		_auto_close_timer += delta
		if _auto_close_timer >= auto_close_delay:
			close()
	
	# Update prompt visibility and text
	if _interaction_prompt:
		var show_prompt = player_nearby and current_state in [State.CLOSED, State.LOCKED]
		_interaction_prompt.visible = show_prompt
		
		# Update text based on door state
		if current_state == State.LOCKED and lock_type == LockType.KEYCARD:
			var color = _get_keycard_color_name()
			_interaction_prompt.text = "Locked (%s Keycard)" % color
			_interaction_prompt.add_theme_color_override("font_color", COLOR_LOCKED)
		else:
			_interaction_prompt.text = "[E] / Click"
			_interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 0.8))


func _input(event: InputEvent) -> void:
	if not player_nearby:
		return
	
	# E key to interact
	if event.is_action_pressed("interact"):
		_handle_interaction()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# Handle clicks on the door
	if event is InputEventMouseButton:
		var local_pos = to_local(get_global_mouse_position())
		var click_area: Vector2
		
		if is_horizontal:
			click_area = Vector2(door_width / 2 + 20, door_thickness / 2 + 40)
		else:
			click_area = Vector2(door_thickness / 2 + 40, door_width / 2 + 20)
		
		var is_over_door = abs(local_pos.x) < click_area.x and abs(local_pos.y) < click_area.y
		
		# Left click to interact
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if is_over_door:
				_handle_interaction()
				get_viewport().set_input_as_handled()
		
		# Right click for context menu
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_over_door and player_nearby:
				_show_context_menu(get_global_mouse_position())
				get_viewport().set_input_as_handled()


# ==============================================================================
# SETUP
# ==============================================================================

func _setup_detection() -> void:
	# Detection area for player proximity
	_collision_shape = CollisionShape2D.new()
	var detection_rect = RectangleShape2D.new()
	# Larger detection zone for auto-open
	if is_horizontal:
		detection_rect.size = Vector2(door_width + 60, 100)
	else:
		detection_rect.size = Vector2(100, door_width + 60)
	_collision_shape.shape = detection_rect
	add_child(_collision_shape)


func _setup_visuals() -> void:
	# Create door panels that will animate
	var panel_container = Node2D.new()
	panel_container.name = "Panels"
	add_child(panel_container)
	
	# Left/Top panel
	_left_panel = ColorRect.new()
	_left_panel.name = "LeftPanel"
	panel_container.add_child(_left_panel)
	
	# Right/Bottom panel
	_right_panel = ColorRect.new()
	_right_panel.name = "RightPanel"
	panel_container.add_child(_right_panel)
	
	# Create light beams that show when door is opening
	_setup_light_beams(panel_container)
	
	# Update panel sizes
	_update_panel_visuals()
	
	# Interaction prompt
	_interaction_prompt = Label.new()
	_interaction_prompt.name = "Prompt"
	_interaction_prompt.text = "[E] / Click"
	_interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interaction_prompt.position = Vector2(-50, -45)
	_interaction_prompt.size = Vector2(100, 20)
	_interaction_prompt.visible = false
	_interaction_prompt.add_theme_font_size_override("font_size", 11)
	_interaction_prompt.add_theme_color_override("font_color", Color(1, 1, 0.8))
	_interaction_prompt.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_interaction_prompt.add_theme_constant_override("shadow_offset_x", 1)
	_interaction_prompt.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_interaction_prompt)


func _setup_click_input() -> void:
	# Make the door clickable
	input_pickable = true


## Set up light beams that appear when door opens
func _setup_light_beams(parent: Node2D) -> void:
	# Light beams that shine through opening door
	_light_beam_left = ColorRect.new()
	_light_beam_left.name = "LightBeamLeft"
	_light_beam_left.visible = false
	_light_beam_left.z_index = -1  # Behind door panels
	parent.add_child(_light_beam_left)
	
	_light_beam_right = ColorRect.new()
	_light_beam_right.name = "LightBeamRight"
	_light_beam_right.visible = false
	_light_beam_right.z_index = -1
	parent.add_child(_light_beam_right)


func _update_panel_visuals() -> void:
	var color = _get_door_color()
	var half_width = door_width / 2
	var half_thick = door_thickness / 2
	
	# Calculate panel positions based on animation
	var slide_amount = _animation_progress * (half_width - 4)
	
	if is_horizontal:
		# Horizontal door - panels slide left/right
		_left_panel.size = Vector2(half_width - slide_amount, door_thickness)
		_left_panel.position = Vector2(-half_width, -half_thick)
		_left_panel.color = color
		
		_right_panel.size = Vector2(half_width - slide_amount, door_thickness)
		_right_panel.position = Vector2(slide_amount + 4, -half_thick)
		_right_panel.color = color
	else:
		# Vertical door - panels slide up/down
		_left_panel.size = Vector2(door_thickness, half_width - slide_amount)
		_left_panel.position = Vector2(-half_thick, -half_width)
		_left_panel.color = color
		
		_right_panel.size = Vector2(door_thickness, half_width - slide_amount)
		_right_panel.position = Vector2(-half_thick, slide_amount + 4)
		_right_panel.color = color
	
	# Update light beams
	_update_light_beams(slide_amount, half_width, half_thick)


## Update the light beam effect when door is opening
func _update_light_beams(slide_amount: float, _half_width: float, half_thick: float) -> void:
	if not _light_beam_left or not _light_beam_right:
		return
	
	var beam_visible = _animation_progress > 0.05 and _animation_progress < 0.95
	_light_beam_left.visible = beam_visible
	_light_beam_right.visible = beam_visible
	
	if not beam_visible:
		return
	
	# Light beam color (warm/cool based on door state)
	var beam_color: Color
	if current_state == State.OPENING:
		beam_color = Color(0.9, 0.95, 1.0, 0.15 * _opening_flash_intensity)
	else:
		beam_color = Color(0.5, 0.6, 0.7, 0.05)
	
	# Calculate gap in the middle
	var gap_size = slide_amount * 2
	var beam_length = 80.0  # How far light extends
	
	if is_horizontal:
		# Light beams extend up and down
		_light_beam_left.size = Vector2(gap_size, beam_length)
		_light_beam_left.position = Vector2(-gap_size / 2, -half_thick - beam_length)
		_light_beam_left.color = beam_color
		
		_light_beam_right.size = Vector2(gap_size, beam_length)
		_light_beam_right.position = Vector2(-gap_size / 2, half_thick)
		_light_beam_right.color = beam_color
	else:
		# Light beams extend left and right
		_light_beam_left.size = Vector2(beam_length, gap_size)
		_light_beam_left.position = Vector2(-half_thick - beam_length, -gap_size / 2)
		_light_beam_left.color = beam_color
		
		_light_beam_right.size = Vector2(beam_length, gap_size)
		_light_beam_right.position = Vector2(half_thick, -gap_size / 2)
		_light_beam_right.color = beam_color


func _get_door_color() -> Color:
	match current_state:
		State.OPEN, State.OPENING:
			return COLOR_OPEN
		State.CLOSED, State.CLOSING:
			return COLOR_CLOSED
		State.LOCKED:
			return COLOR_LOCKED
		State.BLOCKED:
			return COLOR_BLOCKED
		_:
			return COLOR_CLOSED


# ==============================================================================
# COLLISION
# ==============================================================================

func _update_collision() -> void:
	# Create or update wall collision
	if not _wall_collision:
		_wall_collision = StaticBody2D.new()
		_wall_collision.name = "WallBlock"
		var new_shape = CollisionShape2D.new()
		var new_rect = RectangleShape2D.new()
		new_shape.shape = new_rect
		_wall_collision.add_child(new_shape)
		add_child(_wall_collision)
	
	# Get the shape
	var col_shape = _wall_collision.get_child(0) as CollisionShape2D
	var rect = col_shape.shape as RectangleShape2D
	
	# Size based on orientation
	if is_horizontal:
		rect.size = Vector2(door_width, door_thickness + 4)
	else:
		rect.size = Vector2(door_thickness + 4, door_width)
	
	# Enable/disable based on state
	var should_block = current_state in [State.CLOSED, State.LOCKED, State.BLOCKED, State.CLOSING]
	_wall_collision.set_collision_layer_value(1, should_block)


# ==============================================================================
# ANIMATION
# ==============================================================================

func _update_animation(delta: float) -> void:
	var target = 0.0
	
	match current_state:
		State.OPEN, State.OPENING:
			target = 1.0
		State.CLOSED, State.CLOSING, State.LOCKED, State.BLOCKED:
			target = 0.0
	
	# Update light pulse for status lights
	_light_pulse_timer += delta * 3.0
	
	# Update opening flash effect
	if current_state == State.OPENING:
		_opening_flash_intensity = lerpf(_opening_flash_intensity, 1.0, delta * 8.0)
	else:
		_opening_flash_intensity = lerpf(_opening_flash_intensity, 0.0, delta * 4.0)
	
	# Animate toward target with easing
	if abs(_animation_progress - target) > 0.01:
		# Use easing for smoother animation
		var speed_mult = 1.0
		if current_state == State.OPENING:
			# Start fast, slow down at end (ease out)
			speed_mult = 1.0 + (1.0 - _animation_progress) * 0.5
		else:
			# Start slow, speed up (ease in)
			speed_mult = 0.5 + _animation_progress * 0.5
		
		_animation_progress = move_toward(
			_animation_progress, 
			target, 
			_animation_speed * speed_mult * delta
		)
		_update_panel_visuals()
		
		# Disable collision early when opening
		if _animation_progress > 0.2:
			_wall_collision.set_collision_layer_value(1, false)
		else:
			_wall_collision.set_collision_layer_value(1, current_state != State.OPEN)
		
		# Trigger redraw for visual effects
		queue_redraw()
	else:
		# Animation complete
		if current_state == State.OPENING:
			current_state = State.OPEN
		elif current_state == State.CLOSING:
			current_state = State.CLOSED
			_update_collision()


func _draw() -> void:
	# Draw door frame
	var frame_color = Color(0.25, 0.28, 0.32)
	var highlight = Color(0.4, 0.45, 0.5)
	var frame_size: Vector2
	var frame_thick = 6.0
	
	if is_horizontal:
		frame_size = Vector2(door_width + frame_thick * 2, door_thickness + frame_thick * 2)
	else:
		frame_size = Vector2(door_thickness + frame_thick * 2, door_width + frame_thick * 2)
	
	# Outer frame with slight glow during animation
	var frame_draw_color = frame_color
	if _opening_flash_intensity > 0.1:
		frame_draw_color = frame_color.lerp(Color(0.4, 0.45, 0.5), _opening_flash_intensity * 0.3)
	draw_rect(Rect2(-frame_size / 2, frame_size), frame_draw_color)
	
	# Inner cutout (door opening) - darker when opening to show light contrast
	var inner_size: Vector2
	if is_horizontal:
		inner_size = Vector2(door_width, door_thickness)
	else:
		inner_size = Vector2(door_thickness, door_width)
	var inner_color = Color(0.08, 0.1, 0.12)
	if _animation_progress > 0.1:
		# Slight glow from the room beyond
		inner_color = inner_color.lerp(Color(0.15, 0.18, 0.22), _animation_progress * 0.5)
	draw_rect(Rect2(-inner_size / 2, inner_size), inner_color)
	
	# Frame highlight
	draw_line(
		Vector2(-frame_size.x / 2, -frame_size.y / 2), 
		Vector2(frame_size.x / 2, -frame_size.y / 2), 
		highlight, 2
	)
	draw_line(
		Vector2(-frame_size.x / 2, -frame_size.y / 2), 
		Vector2(-frame_size.x / 2, frame_size.y / 2), 
		highlight, 2
	)
	
	# Status lights with pulse effect
	var base_light_color = _get_door_color()
	var pulse = sin(_light_pulse_timer) * 0.3 + 0.7  # 0.4 to 1.0
	var light_color = base_light_color
	light_color.a = pulse
	
	# Add glow around lights
	var glow_color = light_color
	glow_color.a = pulse * 0.3
	
	var light_offset: float
	if is_horizontal:
		light_offset = frame_size.x / 2 + 4
		# Glow
		draw_circle(Vector2(-light_offset, 0), 8, glow_color)
		draw_circle(Vector2(light_offset, 0), 8, glow_color)
		# Light
		draw_circle(Vector2(-light_offset, 0), 4, light_color)
		draw_circle(Vector2(light_offset, 0), 4, light_color)
		# Bright center
		draw_circle(Vector2(-light_offset, 0), 2, Color.WHITE * pulse)
		draw_circle(Vector2(light_offset, 0), 2, Color.WHITE * pulse)
	else:
		light_offset = frame_size.y / 2 + 4
		# Glow
		draw_circle(Vector2(0, -light_offset), 8, glow_color)
		draw_circle(Vector2(0, light_offset), 8, glow_color)
		# Light
		draw_circle(Vector2(0, -light_offset), 4, light_color)
		draw_circle(Vector2(0, light_offset), 4, light_color)
		# Bright center
		draw_circle(Vector2(0, -light_offset), 2, Color.WHITE * pulse)
		draw_circle(Vector2(0, light_offset), 2, Color.WHITE * pulse)


# ==============================================================================
# INTERACTION
# ==============================================================================

func _handle_interaction() -> void:
	match current_state:
		State.CLOSED:
			open()
		State.OPEN:
			if not auto_close:
				close()
		State.LOCKED:
			# Try to unlock with keycard
			if lock_type == LockType.KEYCARD:
				if _try_keycard_unlock():
					unlock()
				else:
					_play_locked_sound()
					_show_keycard_required_message()
			else:
				_play_locked_sound()
		State.BLOCKED:
			_play_blocked_sound()


func open() -> void:
	if current_state in [State.BLOCKED, State.LOCKED]:
		return
	
	current_state = State.OPENING
	_auto_close_timer = 0.0
	_wall_collision.set_collision_layer_value(1, false)
	
	# Sound
	if is_airlock:
		AudioManager.play_sfx("airlock_open", -2.0)
	else:
		AudioManager.play_sfx("door_open", -4.0)
	
	emit_signal("door_opened", self)


func close() -> void:
	if current_state not in [State.OPEN, State.OPENING]:
		return
	
	current_state = State.CLOSING
	
	# Sound
	if is_airlock:
		AudioManager.play_sfx("airlock_close", -2.0)
	else:
		AudioManager.play_sfx("door_close", -4.0)
	
	emit_signal("door_closed", self)


func lock(type: LockType = LockType.KEYCARD, tier: int = 1) -> void:
	lock_type = type
	lock_tier = tier
	current_state = State.LOCKED
	_animation_progress = 0.0
	_update_panel_visuals()
	_update_collision()
	emit_signal("door_locked", self)


func unlock() -> void:
	if current_state != State.LOCKED:
		return
	
	current_state = State.CLOSED
	lock_type = LockType.NONE
	_update_collision()
	emit_signal("door_unlocked", self)
	
	# Auto-open after unlock
	await get_tree().create_timer(0.1).timeout
	open()


func _play_locked_sound() -> void:
	AudioManager.play_sfx("ui_deny", -3.0)


func _play_blocked_sound() -> void:
	AudioManager.play_sfx("ui_deny", -3.0)


# ==============================================================================
# DETECTION CALLBACKS
# ==============================================================================

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		_auto_close_timer = 0.0
		
		# Auto-open if enabled
		if auto_open and current_state == State.CLOSED:
			open()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false


# ==============================================================================
# CONFIGURATION
# ==============================================================================

func set_door_size(width: float, thickness: float = 14.0) -> void:
	door_width = width
	door_thickness = thickness
	
	# Update detection zone
	if _collision_shape and _collision_shape.shape:
		var rect = _collision_shape.shape as RectangleShape2D
		if is_horizontal:
			rect.size = Vector2(door_width + 60, 100)
		else:
			rect.size = Vector2(100, door_width + 60)
	
	_update_panel_visuals()
	_update_collision()
	queue_redraw()


func setup(state: State = State.CLOSED, horizontal: bool = true) -> void:
	is_horizontal = horizontal
	initial_state = state
	current_state = state
	_animation_progress = 1.0 if state == State.OPEN else 0.0


func get_state() -> State:
	return current_state


func is_passable() -> bool:
	return current_state in [State.OPEN, State.OPENING]


func attempt_interaction(_action: String = "interact") -> bool:
	if not player_nearby:
		return false
	
	_handle_interaction()
	return true


# ==============================================================================
# KEYCARD SYSTEM
# ==============================================================================

## Check if player has required keycard and consume it
func _try_keycard_unlock() -> bool:
	# Find the player's inventory through the boarding manager
	var boarding_manager = _find_boarding_manager()
	if not boarding_manager:
		return false
	
	var inv = boarding_manager.inventory
	if not inv:
		return false
	
	# Check all items in inventory
	var items = inv.get_all_items()
	for item in items:
		if not is_instance_valid(item) or not item.item_data:
			continue
		
		var item_id = item.item_data.id
		# Check if this keycard matches or is higher tier
		if _is_valid_keycard(item_id, lock_tier):
			# Consume the keycard
			inv.remove_item(item)
			AudioManager.play_sfx("ui_confirm", -2.0)
			print("[Door] Unlocked with keycard: %s" % item_id)
			return true
	
	return false


## Check if an item ID is a valid keycard for the required tier
func _is_valid_keycard(item_id: String, required_tier: int) -> bool:
	if not item_id.begins_with("keycard_tier"):
		return false
	
	# Extract tier from keycard ID
	var tier_str = item_id.replace("keycard_tier", "")
	if not tier_str.is_valid_int():
		return false
	
	var keycard_tier = tier_str.to_int()
	# Higher tier keycards can open lower tier doors
	return keycard_tier >= required_tier


## Find the boarding manager in the scene tree
func _find_boarding_manager() -> Node:
	# Look up the tree for BoardingManager
	var current = get_parent()
	while current:
		if current.has_method("get_inventory"):
			return current
		if current.name == "BoardingManager" or current.name == "Boarding":
			return current
		current = current.get_parent()
	
	# Try to find it in the scene root
	var root = get_tree().root
	for child in root.get_children():
		if child.name == "BoardingManager" or child.name == "Boarding":
			return child
	
	return null


## Show message when keycard is required
func _show_keycard_required_message() -> void:
	var keycard_color = _get_keycard_color_name()
	var message = "Requires %s Security Keycard" % keycard_color
	
	# Use PopupManager if available
	if has_node("/root/PopupManager"):
		var popup_manager = get_node("/root/PopupManager")
		if popup_manager.has_method("show_popup"):
			popup_manager.show_popup(message, Color(1.0, 0.4, 0.4))
			return
	
	print("[Door] %s" % message)


## Get color name for keycard tier
func _get_keycard_color_name() -> String:
	match lock_tier:
		1: return "Green"
		2: return "Blue"
		3: return "Red"
		_: return "Unknown"


# ==============================================================================
# CONTEXT MENU
# ==============================================================================

## Create the context menu if it doesn't exist
func _create_context_menu() -> void:
	if _context_menu:
		return
	
	_context_menu = PopupMenu.new()
	_context_menu.id_pressed.connect(_on_context_menu_selected)
	add_child(_context_menu)


## Show context menu at mouse position
func _show_context_menu(_at_position: Vector2) -> void:
	_create_context_menu()
	_context_menu.clear()
	
	# Add appropriate options based on door state
	match current_state:
		State.OPEN:
			_context_menu.add_item("Close Door", ContextAction.CLOSE)
			_context_menu.add_item("Lock Door", ContextAction.LOCK)
		State.CLOSED:
			_context_menu.add_item("Open Door", ContextAction.OPEN)
			_context_menu.add_item("Lock Door", ContextAction.LOCK)
		State.LOCKED:
			# Only allow unlock if player has keycard or no lock
			if lock_type == LockType.NONE or _player_has_keycard():
				_context_menu.add_item("Unlock Door", ContextAction.UNLOCK)
			else:
				_context_menu.add_item("Locked (Need Keycard)", -1)
				_context_menu.set_item_disabled(_context_menu.get_item_count() - 1, true)
		State.BLOCKED:
			_context_menu.add_item("Blocked", -1)
			_context_menu.set_item_disabled(_context_menu.get_item_count() - 1, true)
	
	# Position at mouse cursor (screen coordinates)
	var screen_pos = get_viewport().get_mouse_position()
	_context_menu.position = Vector2i(screen_pos)
	_context_menu.popup()
	
	AudioManager.play_sfx("ui_click", -5.0)


## Handle context menu selection
func _on_context_menu_selected(id: int) -> void:
	match id:
		ContextAction.LOCK:
			_lock_door_by_player()
		ContextAction.UNLOCK:
			unlock()
		ContextAction.CLOSE:
			close()
		ContextAction.OPEN:
			open()


## Lock the door (player action, no keycard required)
func _lock_door_by_player() -> void:
	if current_state in [State.OPEN, State.CLOSED]:
		# Close first if open
		if current_state == State.OPEN:
			close()
			await get_tree().create_timer(0.3).timeout
		
		# Lock without keycard requirement (player locking from inside)
		lock_type = LockType.NONE
		lock_tier = 0
		current_state = State.LOCKED
		_animation_progress = 0.0
		_update_panel_visuals()
		_update_collision()
		
		AudioManager.play_sfx("door_lock", -3.0)
		emit_signal("door_locked", self)


## Check if player has required keycard
func _player_has_keycard() -> bool:
	var boarding_manager = _find_boarding_manager()
	if not boarding_manager:
		return false
	
	# Check player inventory for keycard
	if boarding_manager.has_method("player_has_keycard"):
		return boarding_manager.player_has_keycard(lock_tier)
	
	# Fallback - check loot menu
	var loot_menu = boarding_manager.get_node_or_null("LootMenu")
	if loot_menu and loot_menu.has_method("has_keycard"):
		return loot_menu.has_keycard(lock_tier)
	
	return false
