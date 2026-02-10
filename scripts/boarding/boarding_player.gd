# ==============================================================================
# BOARDING PLAYER - PROFESSIONAL TOP-DOWN CHARACTER CONTROLLER
# ==============================================================================
#
# FILE: scripts/boarding/boarding_player.gd
# PURPOSE: Controls the player during the boarding/looting phase
#
# ARCHITECTURE:
# -------------
# This controller uses a STATE MACHINE pattern for clean, maintainable code.
# Each state (IDLE, MOVING, INTERACTING, etc.) has distinct behavior.
#
# PHYSICS MODEL:
# --------------
# Uses velocity-based movement with:
# - Acceleration: How quickly you reach max speed
# - Deceleration: How quickly you stop (friction)
# - Max Speed: Top movement speed
#
# The physics use delta-time for frame-rate independence:
#   velocity += acceleration * delta
#
# SIGNAL ARCHITECTURE:
# --------------------
# This class communicates through signals (loose coupling):
# - interaction_requested: When player wants to interact
# - reached_exit: When player enters exit zone
# - inventory_toggled: When player presses inventory key
# - state_changed: When movement state changes
#
# VISION SYSTEM:
# --------------
# Player vision is controlled by mouse position. The player always "looks"
# toward the mouse cursor, which reveals fog of war in a 90° cone.
#
# INTERACTION SYSTEM:
# -------------------
# Supports both legacy E-key interaction and new left-click interaction.
# Set use_click_interaction = true for mouse-based interaction.
#
# ==============================================================================

extends CharacterBody2D
class_name BoardingPlayer


# ==============================================================================
# ENUMS
# ==============================================================================

## Movement state machine states
enum State {
	IDLE,        ## Standing still, can move or interact
	MOVING,      ## Currently moving
	INTERACTING, ## In interaction (movement locked)
	DISABLED     ## Movement completely disabled (cutscenes, menus)
}


# ==============================================================================
# SIGNALS
# ==============================================================================

## Emitted when player requests interaction with a target
signal interaction_requested(target: Node2D)

## Emitted when player enters the exit zone
signal reached_exit(exit_point: Node2D)

## Emitted when inventory key is pressed
signal inventory_toggled

## Emitted when movement state changes (for animations, sounds)
signal state_changed(old_state: State, new_state: State)

## Emitted when player starts/stops moving (for footstep sounds)
signal movement_started
signal movement_stopped

## Emitted when look direction changes (for vision system)
signal look_direction_changed(direction: Vector2)

## Stealth signals
signal stealth_changed(is_stealthy: bool)
signal stealth_visibility_changed(visibility: float)
signal started_hiding(in_object: Node2D)
signal stopped_hiding


# ==============================================================================
# EXPORTS - MOVEMENT PHYSICS
# ==============================================================================

@export_group("Movement")

## Maximum movement speed in pixels per second
## Higher = faster movement, 200-300 feels good for top-down
@export_range(50.0, 500.0, 10.0) var max_speed: float = 280.0

## How quickly the player reaches max speed (pixels/second²)
## Higher = snappier, more responsive
## Lower = more floaty, momentum-based
@export_range(500.0, 5000.0, 100.0) var acceleration: float = 2200.0

## How quickly the player stops when not pressing movement (pixels/second²)
## Higher = stops quickly (tight controls)
## Lower = slides more (ice physics)
@export_range(500.0, 5000.0, 100.0) var deceleration: float = 2600.0

## Smoothing factor for direction changes (0-1)
## Higher = instant direction change
## Lower = more momentum when changing direction
@export_range(0.1, 1.0, 0.05) var direction_smoothing: float = 0.85


@export_group("Interaction")

## How close the player needs to be to interact (handled by Area2D)
@export var interaction_range: float = 60.0

## Use click-based interaction instead of E key
@export var use_click_interaction: bool = true


@export_group("Vision")

## Enable mouse-based look direction
@export var mouse_look_enabled: bool = true

## How much the camera should offset toward mouse (0-1)
## 0 = camera centered on player
## 1 = camera centered between player and mouse
@export_range(0.0, 1.0, 0.05) var camera_mouse_offset: float = 0.3

## Maximum camera offset distance from player
@export var max_camera_offset: float = 150.0


@export_group("Visual Feedback")

## Color tint for the player sprite
@export var sprite_tint: Color = Color(0.2, 0.8, 0.4)

## How much the sprite tilts when moving (radians)
@export_range(0.0, 0.5, 0.01) var move_tilt_amount: float = 0.1

## Speed of sprite tilt interpolation
@export_range(1.0, 20.0, 0.5) var tilt_speed: float = 8.0


@export_group("Animation")

## Enable head/body rotation following mouse
@export var head_tracking_enabled: bool = true

## Maximum head rotation angle (radians)
@export_range(0.0, 1.0, 0.05) var max_head_rotation: float = 0.5

## Speed of head tracking rotation
@export_range(1.0, 20.0, 0.5) var head_rotation_speed: float = 12.0

## Intensity of searching animation bobbing
@export_range(0.0, 10.0, 0.5) var search_bob_intensity: float = 4.0

## Speed of searching animation
@export_range(1.0, 5.0, 0.1) var search_animation_speed: float = 2.5


@export_group("Stealth")

## Speed multiplier when crouching/hiding
@export_range(0.2, 0.8, 0.05) var stealth_speed_mult: float = 0.5

## How visible the player is when in shadow (0 = invisible, 1 = normal)
@export_range(0.0, 1.0, 0.1) var shadow_visibility: float = 0.3

## Visibility when hiding in object (0 = invisible, 1 = normal)
@export_range(0.0, 0.5, 0.05) var hiding_visibility: float = 0.0


@export_group("Character Stats")

## Player stats resource (contains level, stats, progression)
@export var player_stats: PlayerStats

## If true, stat modifiers affect movement and abilities
@export var use_stats_for_movement: bool = true


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Label = $InteractionPrompt


# ==============================================================================
# STATE VARIABLES
# ==============================================================================

## Player equipment manager (weapons, armor, accessories)
var player_equipment: PlayerEquipment = null

## Current movement state
var current_state: State = State.IDLE

## Currently targeted interactable (if any)
var nearby_interactable: Node2D = null

## Tracks all nearby interactables for priority selection
var interactables_in_range: Array[Node2D] = []

## Input direction this frame (normalized)
var input_direction: Vector2 = Vector2.ZERO

## Smoothed movement direction (for momentum feel)
var smoothed_direction: Vector2 = Vector2.ZERO

## Target rotation for sprite tilt
var target_tilt: float = 0.0

## Footstep timing
var _footstep_timer: float = 0.0
var _footstep_interval: float = 0.35  # Time between footsteps

## Mouse look direction (normalized vector from player to mouse)
var look_direction: Vector2 = Vector2.RIGHT

## Camera reference for mouse offset
var _camera: Camera2D = null

## Vision system reference (VisionSystem class)
var vision_system = null

## Click interaction system reference (ClickInteraction class)
var click_interaction = null

## Animation state variables
var _head_rotation: float = 0.0
var _search_timer: float = 0.0
var _is_searching: bool = false
var _search_animation_active: bool = false
var _original_sprite_position: Vector2 = Vector2.ZERO
var _escape_running: bool = false
var _run_cycle_timer: float = 0.0

## Visual components (created at runtime)
var _head_indicator: Node2D = null
var _flashlight_beam: Node2D = null

## Stealth system variables
var is_crouching: bool = false
var is_hiding: bool = false
var hiding_object: Node2D = null
var is_in_shadow: bool = false
var current_visibility: float = 1.0
var interior_renderer = null  # Reference for shadow checking


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Add to player group for easy finding
	add_to_group("player")
	
	# Set z_index to be above containers and decorations
	z_index = 10
	
	# Initialize systems
	_setup_visuals()
	_setup_interaction_area()
	_setup_prompt()
	_setup_camera()
	_setup_stats_and_equipment()
	
	# Start in idle state
	_transition_to_state(State.IDLE)


func _physics_process(delta: float) -> void:
	# Block all movement when hiding
	if is_hiding:
		velocity = Vector2.ZERO
		return
	
	# Update look direction (mouse-based)
	if mouse_look_enabled:
		_update_look_direction()
	
	# Update camera offset toward mouse
	if mouse_look_enabled and _camera:
		_update_camera_offset()
	
	# Update shadow detection for stealth
	_update_shadow_detection()
	
	# Process based on current state
	match current_state:
		State.IDLE:
			_process_idle_state(delta)
		State.MOVING:
			_process_moving_state(delta)
		State.INTERACTING:
			_process_interacting_state(delta)
		State.DISABLED:
			_process_disabled_state(delta)
	
	# Update footstep sounds when moving
	if current_state == State.MOVING and velocity.length() > max_speed * 0.3:
		_footstep_timer += delta
		if _footstep_timer >= _footstep_interval:
			_play_footstep()
			_footstep_timer = 0.0
	else:
		_footstep_timer = 0.0
	
	# Always apply movement (even if velocity is zero)
	move_and_slide()
	
	# Update visuals
	_update_sprite_tilt(delta)
	_update_head_tracking(delta)
	_update_search_animation(delta)
	_update_escape_animation(delta)
	
	# Trigger redraw for custom drawing
	queue_redraw()


func _input(event: InputEvent) -> void:
	# Don't process input when disabled
	if current_state == State.DISABLED:
		return
	
	# Stealth toggle (C key)
	if event is InputEventKey:
		if event.keycode == KEY_C and event.pressed and not event.echo:
			toggle_crouch()
			get_viewport().set_input_as_handled()
			return
	
	# Click-based interaction (new system)
	if use_click_interaction:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_try_click_interact()
				get_viewport().set_input_as_handled()
	else:
		# Legacy E-key interaction
		if _is_interact_pressed(event):
			_try_interact()
			get_viewport().set_input_as_handled()
	
	# Inventory toggle
	if _is_inventory_pressed(event):
		inventory_toggled.emit()
		get_viewport().set_input_as_handled()


# ==============================================================================
# STATE MACHINE
# ==============================================================================

## Transition to a new state
func _transition_to_state(new_state: State) -> void:
	if new_state == current_state:
		return
	
	var old_state := current_state
	
	# Exit current state
	_exit_state(old_state)
	
	# Enter new state
	current_state = new_state
	_enter_state(new_state)
	
	# Emit signal
	state_changed.emit(old_state, new_state)


## Called when entering a state
func _enter_state(state: State) -> void:
	match state:
		State.IDLE:
			pass
		State.MOVING:
			movement_started.emit()
		State.INTERACTING:
			velocity = Vector2.ZERO
		State.DISABLED:
			velocity = Vector2.ZERO
			input_direction = Vector2.ZERO


## Called when exiting a state
func _exit_state(state: State) -> void:
	match state:
		State.MOVING:
			movement_stopped.emit()
		_:
			pass


## Process IDLE state - waiting for input
func _process_idle_state(delta: float) -> void:
	# Read movement input
	input_direction = _get_movement_input()
	
	# Transition to moving if there's input
	if input_direction != Vector2.ZERO:
		_transition_to_state(State.MOVING)
		return
	
	# Apply deceleration to stop smoothly
	_apply_deceleration(delta)


## Process MOVING state - actively moving
func _process_moving_state(delta: float) -> void:
	# Read movement input
	input_direction = _get_movement_input()
	
	# Transition back to idle if no input
	if input_direction == Vector2.ZERO:
		_transition_to_state(State.IDLE)
		return
	
	# Notify tutorial on first movement (one-shot)
	if not get_meta("tutorial_moved", false):
		set_meta("tutorial_moved", true)
		_notify_tutorial_movement()
	
	# Apply movement physics
	_apply_movement(delta)


## Process INTERACTING state - in interaction animation/lock
func _process_interacting_state(_delta: float) -> void:
	# Interaction state is usually brief
	# External code calls set_movement_enabled(true) when done
	pass


## Process DISABLED state - no movement allowed
func _process_disabled_state(delta: float) -> void:
	# Apply strong deceleration to stop quickly
	velocity = velocity.move_toward(Vector2.ZERO, deceleration * 2.0 * delta)


# ==============================================================================
# MOVEMENT PHYSICS
# ==============================================================================

## Get movement input as a normalized vector
func _get_movement_input() -> Vector2:
	var direction := Vector2.ZERO
	
	# Use Input.get_axis for proper analog stick support
	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")
	
	# Fallback to direct key checks if input map not set up
	if direction == Vector2.ZERO:
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			direction.x -= 1.0
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			direction.x += 1.0
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			direction.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			direction.y += 1.0
	
	# Normalize to prevent faster diagonal movement
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	
	return direction


## Apply movement acceleration toward input direction
func _apply_movement(delta: float) -> void:
	# Smooth the direction for momentum feel
	smoothed_direction = smoothed_direction.lerp(input_direction, direction_smoothing)
	
	# Calculate target velocity (use effective speed for stealth)
	var target_velocity := smoothed_direction * get_effective_max_speed()
	
	# Accelerate toward target
	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	
	# Update facing direction
	_update_facing(smoothed_direction)


## Apply deceleration (friction) when not moving
func _apply_deceleration(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, deceleration * delta)
	
	# Also decay smoothed direction
	smoothed_direction = smoothed_direction.lerp(Vector2.ZERO, 0.1)


## Update sprite facing based on movement direction
func _update_facing(direction: Vector2) -> void:
	if sprite and absf(direction.x) > 0.1:
		sprite.flip_h = direction.x < 0


# ==============================================================================
# VISUAL FEEDBACK
# ==============================================================================

## Set up visual appearance
const PLAYER_SPRITE_PATH = "res://assets/sprites/boarding/player_salvager.svg"

func _setup_visuals() -> void:
	if sprite:
		sprite.modulate = sprite_tint
		_original_sprite_position = sprite.position
		
		# Load the custom player sprite
		_load_player_sprite()
	
	# Create head/flashlight indicator
	_setup_head_indicator()


## Create visual indicator showing look direction (flashlight beam / head direction)
func _setup_head_indicator() -> void:
	# Create the flashlight/vision beam indicator
	_flashlight_beam = Node2D.new()
	_flashlight_beam.name = "FlashlightBeam"
	_flashlight_beam.z_index = -1  # Behind player
	add_child(_flashlight_beam)
	
	# Create the head direction indicator
	_head_indicator = Node2D.new()
	_head_indicator.name = "HeadIndicator"
	_head_indicator.z_index = 11  # Above player
	add_child(_head_indicator)
	
	# The indicators will be drawn in _draw()
	queue_redraw()


## Override _draw for custom animations
func _draw() -> void:
	# Draw flashlight beam (soft cone of light)
	if _flashlight_beam and head_tracking_enabled:
		_draw_flashlight_beam()
	
	# Draw head direction indicator
	if _head_indicator and head_tracking_enabled:
		_draw_head_indicator()


## Draw the flashlight/vision cone
func _draw_flashlight_beam() -> void:
	var beam_length = 120.0
	var beam_width = 50.0
	var beam_color = Color(1.0, 0.95, 0.8, 0.08)  # Soft warm light
	
	# Calculate beam direction
	var beam_dir = look_direction
	var perp = beam_dir.orthogonal()
	
	# Create cone points
	var tip = beam_dir * beam_length
	var base_left = beam_dir * 20 + perp * 8
	var base_right = beam_dir * 20 - perp * 8
	var far_left = tip + perp * beam_width
	var far_right = tip - perp * beam_width
	
	# Draw cone as polygon
	var points = PackedVector2Array([base_left, far_left, far_right, base_right])
	var colors = PackedColorArray([
		beam_color, 
		Color(beam_color.r, beam_color.g, beam_color.b, 0.0),
		Color(beam_color.r, beam_color.g, beam_color.b, 0.0),
		beam_color
	])
	draw_polygon(points, colors)


## Draw the head direction indicator (small arrow/dot showing look direction)
func _draw_head_indicator() -> void:
	# Small indicator showing exact look direction
	var indicator_dist = 24.0
	var indicator_pos = look_direction * indicator_dist
	
	# Draw a small directional triangle
	var size = 4.0
	var forward = look_direction * size
	var perp = look_direction.orthogonal() * (size * 0.6)
	
	var p1 = indicator_pos + forward
	var p2 = indicator_pos - forward * 0.3 + perp
	var p3 = indicator_pos - forward * 0.3 - perp
	
	var indicator_color = Color(0.4, 0.9, 0.5, 0.7)
	draw_polygon(PackedVector2Array([p1, p2, p3]), PackedColorArray([
		indicator_color, indicator_color, indicator_color
	]))


## Load the SVG sprite for the player
func _load_player_sprite() -> void:
	if not sprite:
		return
	
	if ResourceLoader.exists(PLAYER_SPRITE_PATH):
		var texture = load(PLAYER_SPRITE_PATH)
		if texture:
			sprite.texture = texture
			sprite.scale = Vector2(1, 1)  # Adjust scale as needed
			
			# Hide the old ColorRect children if they exist
			for child in sprite.get_children():
				if child is ColorRect:
					child.visible = false
	else:
		print("Warning: Player sprite not found: ", PLAYER_SPRITE_PATH)


## Update sprite tilt based on movement
func _update_sprite_tilt(delta: float) -> void:
	if not sprite:
		return
	
	# Calculate target tilt based on horizontal velocity
	target_tilt = (velocity.x / max_speed) * move_tilt_amount
	target_tilt = clampf(target_tilt, -move_tilt_amount, move_tilt_amount)
	
	# Smoothly interpolate to target
	sprite.rotation = lerpf(sprite.rotation, target_tilt, tilt_speed * delta)


## Update head/body tracking toward mouse
func _update_head_tracking(delta: float) -> void:
	if not head_tracking_enabled:
		return
	
	# Calculate target rotation based on look direction
	var target_rotation = look_direction.angle()
	
	# Clamp to max rotation from forward
	var forward_angle = 0.0 if not sprite or not sprite.flip_h else PI
	var angle_diff = angle_difference(forward_angle, target_rotation)
	angle_diff = clampf(angle_diff, -max_head_rotation, max_head_rotation)
	
	# Smooth interpolation
	_head_rotation = lerpf(_head_rotation, angle_diff, head_rotation_speed * delta)


## Update the searching animation when interacting with containers
func _update_search_animation(delta: float) -> void:
	if not _search_animation_active or not sprite:
		# Reset sprite position when not searching
		if sprite.position != _original_sprite_position:
			sprite.position = sprite.position.lerp(_original_sprite_position, 10.0 * delta)
		return
	
	# Increment search timer
	_search_timer += delta * search_animation_speed
	
	# Bobbing motion (up/down)
	var bob_offset = sin(_search_timer * 4.0) * search_bob_intensity
	
	# Slight side-to-side motion
	var sway_offset = sin(_search_timer * 2.5) * (search_bob_intensity * 0.5)
	
	# Apply to sprite position
	sprite.position = _original_sprite_position + Vector2(sway_offset, bob_offset)
	
	# Slight rotation wobble
	var wobble = sin(_search_timer * 3.0) * 0.05
	sprite.rotation = wobble


## Update escape running animation
func _update_escape_animation(delta: float) -> void:
	if not _escape_running or not sprite:
		return
	
	# Fast run cycle
	_run_cycle_timer += delta * 12.0
	
	# Exaggerated bobbing for running
	var bob = abs(sin(_run_cycle_timer)) * 3.0
	var tilt = sin(_run_cycle_timer * 2.0) * 0.15
	
	sprite.position = _original_sprite_position + Vector2(0, -bob)
	sprite.rotation = tilt


# ==============================================================================
# ANIMATION PUBLIC API
# ==============================================================================

## Start the searching animation (call when opening container)
func start_searching_animation() -> void:
	_search_animation_active = true
	_search_timer = 0.0
	_is_searching = true


## Stop the searching animation
func stop_searching_animation() -> void:
	_search_animation_active = false
	_is_searching = false


## Start escape running animation
func start_escape_animation() -> void:
	_escape_running = true
	_run_cycle_timer = 0.0
	# Speed boost during escape
	max_speed *= 1.3


## Stop escape running animation
func stop_escape_animation() -> void:
	_escape_running = false
	max_speed /= 1.3


## Check if currently in search animation
func is_searching() -> bool:
	return _is_searching


## Play footstep sound with variation
func _play_footstep() -> void:
	# Vary pitch and volume slightly for more natural sound
	var pitch_variation = randf_range(0.9, 1.1)
	var volume_db = randf_range(-8.0, -6.0)
	AudioManager.play_sfx("footstep", volume_db, pitch_variation)


## Set up the interaction prompt label
func _setup_prompt() -> void:
	if interaction_prompt:
		interaction_prompt.visible = false


## Set up camera reference for mouse offset
func _setup_camera() -> void:
	# Find camera in the scene
	_camera = get_viewport().get_camera_2d()
	if not _camera:
		# Try to find in parent tree
		var parent = get_parent()
		while parent:
			if parent.has_node("Camera2D"):
				_camera = parent.get_node("Camera2D")
				break
			parent = parent.get_parent()


## Set up player stats and equipment systems
func _setup_stats_and_equipment() -> void:
	# Create player stats if not assigned
	if not player_stats:
		player_stats = PlayerStats.new()
	
	# Create equipment manager
	player_equipment = PlayerEquipment.new()
	player_equipment.name = "PlayerEquipment"
	add_child(player_equipment)
	
	# Link equipment to stats
	player_equipment.set_player_stats(player_stats)
	
	# Give player a starting weapon (basic pistol)
	_give_starting_equipment()
	
	# Apply stat bonuses to movement
	if use_stats_for_movement and player_stats:
		_apply_stat_modifiers()


## Give the player their starting equipment
func _give_starting_equipment() -> void:
	if not player_equipment:
		return
	
	# Create a basic pistol from WeaponsDatabase
	var WeaponsDB = load("res://scripts/loot/weapons_database.gd")
	if WeaponsDB:
		var pistol = WeaponsDB.create_weapon_resource("pistol_basic")
		if pistol:
			player_equipment.equip(pistol, PlayerEquipment.SLOT_PRIMARY_WEAPON)
			print("[BoardingPlayer] Equipped starting weapon: %s" % pistol.name)
		else:
			push_warning("[BoardingPlayer] Failed to create starting pistol")


## Apply stat modifiers to movement parameters
func _apply_stat_modifiers() -> void:
	if not player_stats:
		return
	
	# Speed stat affects max_speed (each point = +1% speed)
	var speed_bonus = player_stats.get_speed() * 0.01
	max_speed = max_speed * (1.0 + speed_bonus)
	
	# Stealth stat affects visibility reduction
	var stealth_bonus = player_stats.get_stealth() * 0.01
	shadow_visibility = maxf(0.05, shadow_visibility - stealth_bonus * 0.2)


## Get the player stats resource
func get_stats() -> PlayerStats:
	return player_stats


## Get the equipment manager
func get_equipment() -> PlayerEquipment:
	return player_equipment


# ==============================================================================
# MOUSE LOOK SYSTEM
# ==============================================================================

## Update look direction based on mouse position
func _update_look_direction() -> void:
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	if direction.length_squared() > 0.01:
		var old_direction = look_direction
		look_direction = direction
		
		# Emit signal if direction changed significantly
		if old_direction.dot(look_direction) < 0.99:
			look_direction_changed.emit(look_direction)
			
			# Update vision system if attached
			if vision_system:
				vision_system.set_look_direction(look_direction)


## Update camera offset toward mouse position
func _update_camera_offset() -> void:
	if not _camera:
		return
	
	var mouse_pos = get_global_mouse_position()
	var offset_direction = (mouse_pos - global_position)
	
	# Limit offset distance
	if offset_direction.length() > max_camera_offset:
		offset_direction = offset_direction.normalized() * max_camera_offset
	
	# Apply offset factor
	var target_offset = offset_direction * camera_mouse_offset
	
	# Smoothly interpolate camera offset
	_camera.offset = _camera.offset.lerp(target_offset, 0.1)


## Get the current look direction (normalized)
func get_look_direction() -> Vector2:
	return look_direction


## Get look angle in radians
func get_look_angle() -> float:
	return look_direction.angle()


# ==============================================================================
# INTERACTION SYSTEM
# ==============================================================================

## Set up the interaction area signals
func _setup_interaction_area() -> void:
	if not interaction_area:
		push_warning("BoardingPlayer: No InteractionArea found!")
		return
	
	interaction_area.body_entered.connect(_on_body_entered_interaction)
	interaction_area.body_exited.connect(_on_body_exited_interaction)
	interaction_area.area_entered.connect(_on_area_entered_interaction)
	interaction_area.area_exited.connect(_on_area_exited_interaction)


## Called when a body enters interaction range
func _on_body_entered_interaction(body: Node2D) -> void:
	_try_add_interactable(body)


## Called when a body exits interaction range
func _on_body_exited_interaction(body: Node2D) -> void:
	_remove_interactable(body)


## Called when an area enters interaction range
func _on_area_entered_interaction(area: Area2D) -> void:
	# Check for exit point
	if area.is_in_group("exit_point"):
		reached_exit.emit(area)
	
	_try_add_interactable(area)


## Called when an area exits interaction range
func _on_area_exited_interaction(area: Area2D) -> void:
	_remove_interactable(area)


## Try to add a node to interactables list
func _try_add_interactable(node: Node2D) -> void:
	if not _is_interactable(node):
		return
	
	if node not in interactables_in_range:
		interactables_in_range.append(node)
	
	_update_nearest_interactable()


## Remove a node from interactables list
func _remove_interactable(node: Node2D) -> void:
	interactables_in_range.erase(node)
	_update_nearest_interactable()


## Check if a node can be interacted with
func _is_interactable(node: Node2D) -> bool:
	return node.has_method("can_interact") and node.can_interact()


## Check if there's a clear line of sight to the target (no walls in the way)
func _has_line_of_sight(target: Node2D) -> bool:
	if not is_inside_tree():
		return false
	
	var space_state = get_world_2d().direct_space_state
	if not space_state:
		return true  # Default to allowing interaction if no physics available
	
	# Create raycast query from player to target
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		target.global_position,
		1  # Collision mask for walls (layer 1)
	)
	# Exclude the player and the target from the raycast
	query.exclude = [self]
	if target is CollisionObject2D:
		query.exclude.append(target.get_rid())
	
	var result = space_state.intersect_ray(query)
	
	# If no hit, we have line of sight
	# If hit something, check if it's a wall (not another interactable)
	if result.is_empty():
		return true
	
	# Check if we hit a StaticBody2D (wall) or a locked door blocking line of sight
	var collider = result.get("collider")
	if collider is StaticBody2D:
		# Check if it's a door's wall block
		if collider.get_parent() is Door:
			var door: Door = collider.get_parent()
			# Can't see through locked/closed doors
			if door.current_state in [Door.State.LOCKED, Door.State.CLOSED]:
				return false
		else:
			# It's a regular wall - no line of sight
			return false
	
	return true


## Find and set the nearest interactable
func _update_nearest_interactable() -> void:
	# Remove any invalid entries
	interactables_in_range = interactables_in_range.filter(
		func(n): return is_instance_valid(n) and _is_interactable(n)
	)
	
	if interactables_in_range.is_empty():
		nearby_interactable = null
		_update_prompt()
		return
	
	# Find closest interactable WITH line of sight
	var closest: Node2D = null
	var closest_dist := INF
	
	for interactable in interactables_in_range:
		# Skip if wall is blocking line of sight
		if not _has_line_of_sight(interactable):
			continue
		
		var dist: float = global_position.distance_squared_to(
			interactable.global_position
		)
		if dist < closest_dist:
			closest_dist = dist
			closest = interactable
	
	nearby_interactable = closest
	_update_prompt()


## Update the interaction prompt display
func _update_prompt() -> void:
	if not interaction_prompt:
		return
	
	# Hide prompt when using click interaction (cursor indicates interactable)
	if use_click_interaction:
		interaction_prompt.visible = false
		return
	
	if nearby_interactable:
		interaction_prompt.visible = true
		if nearby_interactable.has_method("get_interact_prompt"):
			interaction_prompt.text = nearby_interactable.get_interact_prompt()
		else:
			interaction_prompt.text = "[E] Interact"
	else:
		interaction_prompt.visible = false


## Check if interact was pressed this event
func _is_interact_pressed(event: InputEvent) -> bool:
	return (
		event.is_action_pressed("interact") or
		event.is_action_pressed("ui_accept")
	)


## Check if inventory was pressed this event
func _is_inventory_pressed(event: InputEvent) -> bool:
	return event.is_action_pressed("inventory")


## Attempt to interact with nearby interactable
func _try_interact() -> void:
	if current_state == State.INTERACTING:
		return
	
	if nearby_interactable:
		# Log the interaction
		if DebugLogger:
			var target_name: String = nearby_interactable.name
			DebugLogger.log_interaction(target_name, "interact")
		interaction_requested.emit(nearby_interactable)


## Attempt click-based interaction with object under mouse
func _try_click_interact() -> void:
	if current_state == State.INTERACTING:
		return
	
	var mouse_pos = get_global_mouse_position()
	var closest_interactable: Node2D = null
	var closest_dist: float = INF
	
	# Check all interactables in range
	for interactable in interactables_in_range:
		if not is_instance_valid(interactable):
			continue
		
		if not _is_interactable(interactable):
			continue
		
		# Check distance from mouse to interactable
		var dist_to_mouse = mouse_pos.distance_to(interactable.global_position)
		var hit_radius = _get_interactable_hit_radius(interactable)
		
		if dist_to_mouse <= hit_radius and dist_to_mouse < closest_dist:
			# Verify line of sight
			if _has_line_of_sight(interactable):
				closest_dist = dist_to_mouse
				closest_interactable = interactable
	
	if closest_interactable:
		if DebugLogger:
			var target_name: String = closest_interactable.name
			DebugLogger.log_interaction(target_name, "click_interact")
		interaction_requested.emit(closest_interactable)


## Get hit radius for click detection
func _get_interactable_hit_radius(node: Node2D) -> float:
	# Try to get size from collision shape
	if node.has_node("CollisionShape2D"):
		var col = node.get_node("CollisionShape2D")
		if col.shape is RectangleShape2D:
			var rect_shape = col.shape as RectangleShape2D
			return maxf(rect_shape.size.x, rect_shape.size.y) * 0.6
		if col.shape is CircleShape2D:
			var circle_shape = col.shape as CircleShape2D
			return circle_shape.radius * 1.2
	
	# Default hit radius
	return 48.0


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Enable or disable player movement
## Use this when opening menus, during interactions, etc.
func set_movement_enabled(enabled: bool) -> void:
	if enabled:
		if current_state in [State.DISABLED, State.INTERACTING]:
			_transition_to_state(State.IDLE)
	else:
		_transition_to_state(State.DISABLED)


## Lock player in interacting state
func set_interacting(interacting: bool) -> void:
	if interacting:
		_transition_to_state(State.INTERACTING)
	else:
		_transition_to_state(State.IDLE)


## Get current movement speed (for UI/animations)
func get_current_speed() -> float:
	return velocity.length()


## Get normalized movement direction (for animations)
func get_movement_direction() -> Vector2:
	if velocity.length() > 0.1:
		return velocity.normalized()
	return Vector2.ZERO


## Check if player is currently moving
func is_moving() -> bool:
	return current_state == State.MOVING


## Check if player can currently move
func can_move() -> bool:
	return current_state in [State.IDLE, State.MOVING]


## Teleport player to position (for spawning, etc.)
func teleport_to(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	smoothed_direction = Vector2.ZERO


## Connect a vision system to this player
func set_vision_system(system) -> void:
	vision_system = system
	if vision_system:
		vision_system.set_player(self)
		# Update initial look direction
		vision_system.set_look_direction(look_direction)


## Connect a click interaction system to this player
func set_click_interaction_system(system) -> void:
	click_interaction = system
	if click_interaction:
		click_interaction.initialize(self, vision_system)
		click_interaction.interaction_requested.connect(_on_click_interaction_requested)


func _on_click_interaction_requested(target: Node2D) -> void:
	if current_state == State.INTERACTING:
		return
	
	if DebugLogger:
		var target_name: String = target.name
		DebugLogger.log_interaction(target_name, "click_interact")
	interaction_requested.emit(target)


# ==============================================================================
# TUTORIAL INTEGRATION
# ==============================================================================

## Signal for tutorial system
signal tutorial_movement_detected

func _notify_tutorial_movement() -> void:
	tutorial_movement_detected.emit()


# ==============================================================================
# STEALTH SYSTEM
# ==============================================================================

## Toggle crouch/stealth mode
func toggle_crouch() -> void:
	if is_hiding:
		exit_hiding()
		return
	
	is_crouching = not is_crouching
	_update_stealth_visuals()
	stealth_changed.emit(is_crouching)
	
	if is_crouching:
		AudioManager.play_sfx_varied("player_crouch", 0.1, -5.0)


## Enter hiding in an object
func enter_hiding(obj: Node2D) -> void:
	if is_hiding:
		return
	
	is_hiding = true
	hiding_object = obj
	is_crouching = false
	
	# Disable collision while hiding
	collision_shape.disabled = true
	
	_update_stealth_visuals()
	started_hiding.emit(obj)
	AudioManager.play_sfx_varied("player_hide", 0.1, -3.0)


## Exit hiding
func exit_hiding() -> void:
	if not is_hiding:
		return
	
	is_hiding = false
	hiding_object = null
	
	# Re-enable collision
	collision_shape.disabled = false
	
	_update_stealth_visuals()
	stopped_hiding.emit()
	AudioManager.play_sfx_varied("player_unhide", 0.1, -3.0)


## Update visibility based on stealth state
func _update_stealth_visuals() -> void:
	var target_alpha := 1.0
	var target_scale := Vector2.ONE
	
	if is_hiding:
		target_alpha = hiding_visibility
		target_scale = Vector2(0.8, 0.8)  # Shrink slightly while hiding
	elif is_crouching:
		target_alpha = shadow_visibility if is_in_shadow else 0.7
		target_scale = Vector2(0.9, 0.9)  # Slightly smaller when crouching
	
	current_visibility = target_alpha
	stealth_visibility_changed.emit(current_visibility)
	
	# Animate sprite
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", target_alpha, 0.2)
	tween.tween_property(sprite, "scale", target_scale, 0.2)


## Update shadow detection (call from _physics_process)
func _update_shadow_detection() -> void:
	if not interior_renderer:
		return
	
	var was_in_shadow = is_in_shadow
	is_in_shadow = interior_renderer.is_position_in_shadow(global_position)
	
	# Update visibility if crouching and shadow state changed
	if is_crouching and was_in_shadow != is_in_shadow:
		_update_stealth_visuals()


## Set reference to interior renderer for shadow checking
func set_interior_renderer(renderer) -> void:
	interior_renderer = renderer


## Get current visibility level (0-1)
func get_visibility() -> float:
	return current_visibility


## Check if player is currently stealthy (crouching or hiding)
func is_stealthy() -> bool:
	return is_crouching or is_hiding


## Get stealth level (0-1) for detection calculations
func get_stealth_level() -> float:
	var base_stealth := 0.0
	
	if is_hiding:
		base_stealth = 0.9  # Very hidden
	elif is_crouching:
		base_stealth = 0.4  # Moderately stealthy
	
	# Add bonus from stats
	if player_stats:
		base_stealth += player_stats.get_stealth() * 0.01
	
	return clampf(base_stealth, 0.0, 1.0)


## Get effective movement speed (reduced when crouching)
func get_effective_max_speed() -> float:
	if is_crouching:
		return max_speed * stealth_speed_mult
	return max_speed


# ==============================================================================
# DAMAGE SYSTEM
# ==============================================================================

## Take damage from enemy attacks
func take_damage(amount: int) -> void:
	if is_hiding:
		# Reduced damage while hiding
		amount = int(amount * 0.5)
	
	if player_stats:
		# Apply defense reduction
		var defense = player_stats.get_defense()
		var damage_reduction = defense * 0.01  # 1% reduction per defense point
		amount = int(amount * (1.0 - damage_reduction))
		amount = maxi(1, amount)  # Always take at least 1 damage
		
		# Deal damage to health
		var current_health = player_stats.get_health()
		player_stats.set_health(current_health - amount)
		
		# Check for death
		if player_stats.get_health() <= 0:
			_on_player_death()
	
	# Visual feedback
	_flash_damage()
	
	# Sound
	if AudioManager:
		AudioManager.play_sfx("player_hurt")


## Flash red when taking damage
func _flash_damage() -> void:
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)


## Handle player death
func _on_player_death() -> void:
	current_state = State.DISABLED
	velocity = Vector2.ZERO
	
	# Death animation
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.3)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	
	# Trigger game over after animation
	tween.tween_callback(_trigger_game_over)


## Trigger game over screen
func _trigger_game_over() -> void:
	var game_over = load("res://scenes/boarding/game_over.tscn")
	if game_over:
		var instance = game_over.instantiate()
		get_tree().current_scene.add_child(instance)
