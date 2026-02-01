# ==============================================================================
# DOOR - INTERACTIVE DOOR BETWEEN ROOMS
# ==============================================================================
#
# FILE: scripts/boarding/door.gd
# PURPOSE: Handles door functionality between rooms
#
# STATES:
# - OPEN: Player can pass through freely
# - CLOSED: Requires interaction to open
# - LOCKED: Requires keycard/hack to unlock (future)
# - BLOCKED: Cannot be opened (NPC controlled, damaged, etc.)
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
signal interaction_attempted(door: Door, success: bool)


# ==============================================================================
# ENUMS
# ==============================================================================

enum State {
	OPEN,
	CLOSED,
	LOCKED,
	BLOCKED
}

enum LockType {
	NONE,
	KEYCARD,       # Requires specific keycard
	HACK,          # Can be hacked with tool
	SECURITY,      # High security - multiple requirements
	DAMAGED        # Physically blocked
}


# ==============================================================================
# EXPORTS
# ==============================================================================

@export var initial_state: State = State.OPEN
@export var lock_type: LockType = LockType.NONE
@export var lock_tier: int = 1  # Difficulty of lock (1-5)
@export var auto_close: bool = false
@export var auto_close_delay: float = 3.0
@export var is_airlock: bool = false  # Special handling for airlocks


# ==============================================================================
# STATE
# ==============================================================================

var current_state: State = State.OPEN
var connected_rooms: Array[int] = []  # Room indices this door connects
var player_nearby: bool = false
var _auto_close_timer: float = 0.0

# Visual components
var _door_sprite: Sprite2D
var _collision_shape: CollisionShape2D
var _wall_collision: StaticBody2D
var _indicator_light: Node2D
var _interaction_prompt: Label


# ==============================================================================
# COLORS
# ==============================================================================

const COLOR_OPEN = Color(0.2, 0.8, 0.3, 0.8)      # Green
const COLOR_CLOSED = Color(0.8, 0.6, 0.2, 0.9)   # Yellow/Orange
const COLOR_LOCKED = Color(0.9, 0.2, 0.2, 0.9)   # Red
const COLOR_BLOCKED = Color(0.4, 0.4, 0.4, 0.9)  # Gray


# ==============================================================================
# DOOR DIMENSIONS
# ==============================================================================

var door_width: float = 60.0
var door_thickness: float = 12.0
var is_horizontal: bool = true  # Horizontal or vertical orientation


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	current_state = initial_state
	_setup_visuals()
	_setup_collision()
	_update_appearance()
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(delta: float) -> void:
	# Handle auto-close
	if auto_close and current_state == State.OPEN and not player_nearby:
		_auto_close_timer += delta
		if _auto_close_timer >= auto_close_delay:
			close()
	
	# Update interaction prompt
	if _interaction_prompt:
		_interaction_prompt.visible = player_nearby and current_state != State.OPEN


func _input(event: InputEvent) -> void:
	if not player_nearby:
		return
	
	if event.is_action_pressed("interact"):
		attempt_interaction()


# ==============================================================================
# VISUAL SETUP
# ==============================================================================

func _setup_visuals() -> void:
	# Create door sprite (procedural for now)
	_door_sprite = Sprite2D.new()
	_door_sprite.name = "DoorSprite"
	add_child(_door_sprite)
	
	# Create indicator light
	_indicator_light = Node2D.new()
	_indicator_light.name = "IndicatorLight"
	add_child(_indicator_light)
	
	# Create interaction prompt
	_interaction_prompt = Label.new()
	_interaction_prompt.name = "InteractionPrompt"
	_interaction_prompt.text = "[E] Open"
	_interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_prompt.position = Vector2(-40, -50)
	_interaction_prompt.visible = false
	_interaction_prompt.add_theme_font_size_override("font_size", 12)
	_interaction_prompt.add_theme_color_override("font_color", Color.WHITE)
	add_child(_interaction_prompt)


func _setup_collision() -> void:
	# Detection area for player proximity
	_collision_shape = CollisionShape2D.new()
	var detection_rect = RectangleShape2D.new()
	detection_rect.size = Vector2(door_width + 40, door_width + 40)
	_collision_shape.shape = detection_rect
	add_child(_collision_shape)
	
	# Physical wall collision (blocks player when closed)
	_wall_collision = StaticBody2D.new()
	_wall_collision.name = "WallCollision"
	var wall_shape = CollisionShape2D.new()
	var wall_rect = RectangleShape2D.new()
	if is_horizontal:
		wall_rect.size = Vector2(door_width, door_thickness)
	else:
		wall_rect.size = Vector2(door_thickness, door_width)
	wall_shape.shape = wall_rect
	_wall_collision.add_child(wall_shape)
	add_child(_wall_collision)


func _update_appearance() -> void:
	# Update door color based on state
	var door_color: Color
	var prompt_text: String
	
	match current_state:
		State.OPEN:
			door_color = COLOR_OPEN
			prompt_text = ""
			_wall_collision.set_collision_layer_value(1, false)
		State.CLOSED:
			door_color = COLOR_CLOSED
			prompt_text = "[E] Open"
			_wall_collision.set_collision_layer_value(1, true)
		State.LOCKED:
			door_color = COLOR_LOCKED
			prompt_text = _get_lock_prompt()
			_wall_collision.set_collision_layer_value(1, true)
		State.BLOCKED:
			door_color = COLOR_BLOCKED
			prompt_text = "Blocked"
			_wall_collision.set_collision_layer_value(1, true)
	
	if _interaction_prompt:
		_interaction_prompt.text = prompt_text
	
	# Redraw
	queue_redraw()


func _get_lock_prompt() -> String:
	match lock_type:
		LockType.KEYCARD:
			return "[E] Locked - Keycard Required"
		LockType.HACK:
			return "[E] Locked - Hack to Unlock"
		LockType.SECURITY:
			return "[E] High Security"
		LockType.DAMAGED:
			return "Damaged - Cannot Open"
		_:
			return "[E] Locked"


func _draw() -> void:
	# Draw door frame
	var frame_color = Color(0.3, 0.35, 0.4)
	var frame_size: Vector2
	if is_horizontal:
		frame_size = Vector2(door_width + 8, door_thickness + 8)
	else:
		frame_size = Vector2(door_thickness + 8, door_width + 8)
	draw_rect(Rect2(-frame_size / 2, frame_size), frame_color)
	
	# Draw door panels based on state
	var panel_color: Color
	match current_state:
		State.OPEN:
			panel_color = COLOR_OPEN
		State.CLOSED:
			panel_color = COLOR_CLOSED
		State.LOCKED:
			panel_color = COLOR_LOCKED
		State.BLOCKED:
			panel_color = COLOR_BLOCKED
	
	if current_state == State.OPEN:
		# Draw open door (panels retracted to sides)
		var panel_width = door_width / 2 - 4
		if is_horizontal:
			# Left panel
			draw_rect(Rect2(
				-door_width / 2, -door_thickness / 2,
				8, door_thickness
			), panel_color)
			# Right panel
			draw_rect(Rect2(
				door_width / 2 - 8, -door_thickness / 2,
				8, door_thickness
			), panel_color)
		else:
			# Top panel
			draw_rect(Rect2(
				-door_thickness / 2, -door_width / 2,
				door_thickness, 8
			), panel_color)
			# Bottom panel
			draw_rect(Rect2(
				-door_thickness / 2, door_width / 2 - 8,
				door_thickness, 8
			), panel_color)
	else:
		# Draw closed door
		var door_size: Vector2
		if is_horizontal:
			door_size = Vector2(door_width, door_thickness)
		else:
			door_size = Vector2(door_thickness, door_width)
		draw_rect(Rect2(-door_size / 2, door_size), panel_color)
		
		# Draw center seam
		var seam_color = Color(panel_color.r * 0.7, panel_color.g * 0.7, panel_color.b * 0.7)
		if is_horizontal:
			draw_line(Vector2(0, -door_thickness / 2), Vector2(0, door_thickness / 2), seam_color, 2)
		else:
			draw_line(Vector2(-door_thickness / 2, 0), Vector2(door_thickness / 2, 0), seam_color, 2)
	
	# Draw indicator lights
	var light_color = panel_color
	var light_pos: Vector2
	if is_horizontal:
		light_pos = Vector2(-door_width / 2 - 6, 0)
	else:
		light_pos = Vector2(0, -door_width / 2 - 6)
	draw_circle(light_pos, 4, light_color)
	draw_circle(-light_pos, 4, light_color)


# ==============================================================================
# INTERACTION
# ==============================================================================

func attempt_interaction() -> bool:
	match current_state:
		State.OPEN:
			if auto_close:
				# Manual close
				close()
				return true
			return false
		
		State.CLOSED:
			open()
			emit_signal("interaction_attempted", self, true)
			return true
		
		State.LOCKED:
			# Check if player has means to unlock
			var can_unlock = _check_unlock_requirements()
			if can_unlock:
				unlock()
				emit_signal("interaction_attempted", self, true)
				return true
			else:
				emit_signal("interaction_attempted", self, false)
				# Play locked sound/feedback
				return false
		
		State.BLOCKED:
			emit_signal("interaction_attempted", self, false)
			return false
	
	return false


func _check_unlock_requirements() -> bool:
	# TODO: Check player inventory for keycards, hacking tools, etc.
	# For now, always return false for locked doors
	match lock_type:
		LockType.KEYCARD:
			return false  # Check for keycard
		LockType.HACK:
			return false  # Check for hacking tool
		LockType.SECURITY:
			return false  # Multiple requirements
		LockType.DAMAGED:
			return false  # Cannot unlock
		_:
			return true


# ==============================================================================
# STATE CHANGES
# ==============================================================================

func open() -> void:
	if current_state == State.BLOCKED:
		return
	
	current_state = State.OPEN
	_auto_close_timer = 0.0
	_update_appearance()
	
	# Play door open sound
	if is_airlock:
		AudioManager.play_sfx("airlock_open", -2.0)
	else:
		AudioManager.play_sfx("door_open", -4.0)
	
	emit_signal("door_opened", self)


func close() -> void:
	if current_state != State.OPEN:
		return
	
	current_state = State.CLOSED
	_update_appearance()
	
	# Play door close sound
	if is_airlock:
		AudioManager.play_sfx("airlock_close", -2.0)
	else:
		AudioManager.play_sfx("door_close", -4.0)
	
	emit_signal("door_closed", self)


func lock(type: LockType = LockType.KEYCARD, tier: int = 1) -> void:
	lock_type = type
	lock_tier = tier
	current_state = State.LOCKED
	_update_appearance()
	emit_signal("door_locked", self)


func unlock() -> void:
	if current_state != State.LOCKED:
		return
	
	current_state = State.CLOSED
	lock_type = LockType.NONE
	_update_appearance()
	emit_signal("door_unlocked", self)
	
	# Auto-open after unlock
	open()


func block() -> void:
	current_state = State.BLOCKED
	_update_appearance()


func unblock() -> void:
	current_state = State.CLOSED
	_update_appearance()


# ==============================================================================
# CONFIGURATION
# ==============================================================================

func setup(
	pos: Vector2, 
	horizontal: bool, 
	width: float = 60.0,
	state: State = State.OPEN,
	rooms: Array = []
) -> void:
	position = pos
	is_horizontal = horizontal
	door_width = width
	initial_state = state
	current_state = state
	connected_rooms = rooms
	
	# Rebuild collision
	if _collision_shape and _collision_shape.shape:
		(_collision_shape.shape as RectangleShape2D).size = Vector2(width + 40, width + 40)
	
	if _wall_collision:
		var wall_shape = _wall_collision.get_child(0) as CollisionShape2D
		if wall_shape and wall_shape.shape:
			if horizontal:
				(wall_shape.shape as RectangleShape2D).size = Vector2(width, door_thickness)
			else:
				(wall_shape.shape as RectangleShape2D).size = Vector2(door_thickness, width)
	
	_update_appearance()


# ==============================================================================
# DETECTION
# ==============================================================================

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		_auto_close_timer = 0.0


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
