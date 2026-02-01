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


# ==============================================================================
# EXPORTS - MOVEMENT PHYSICS
# ==============================================================================

@export_group("Movement")

## Maximum movement speed in pixels per second
## Higher = faster movement, 200-300 feels good for top-down
@export_range(50.0, 500.0, 10.0) var max_speed: float = 220.0

## How quickly the player reaches max speed (pixels/second²)
## Higher = snappier, more responsive
## Lower = more floaty, momentum-based
@export_range(500.0, 5000.0, 100.0) var acceleration: float = 1800.0

## How quickly the player stops when not pressing movement (pixels/second²)
## Higher = stops quickly (tight controls)
## Lower = slides more (ice physics)
@export_range(500.0, 5000.0, 100.0) var deceleration: float = 2200.0

## Smoothing factor for direction changes (0-1)
## Higher = instant direction change
## Lower = more momentum when changing direction
@export_range(0.1, 1.0, 0.05) var direction_smoothing: float = 0.85


@export_group("Interaction")

## How close the player needs to be to interact (handled by Area2D)
@export var interaction_range: float = 60.0


@export_group("Visual Feedback")

## Color tint for the player sprite
@export var sprite_tint: Color = Color(0.2, 0.8, 0.4)

## How much the sprite tilts when moving (radians)
@export_range(0.0, 0.5, 0.01) var move_tilt_amount: float = 0.1

## Speed of sprite tilt interpolation
@export_range(1.0, 20.0, 0.5) var tilt_speed: float = 8.0


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


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Add to player group for easy finding
	add_to_group("player")
	
	# Initialize systems
	_setup_visuals()
	_setup_interaction_area()
	_setup_prompt()
	
	# Start in idle state
	_transition_to_state(State.IDLE)


func _physics_process(delta: float) -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	# Don't process input when disabled
	if current_state == State.DISABLED:
		return
	
	# Interaction input
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
	
	# Calculate target velocity
	var target_velocity := smoothed_direction * max_speed
	
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
		
		# Load the custom player sprite
		_load_player_sprite()


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
	
	# Find closest interactable
	var closest: Node2D = null
	var closest_dist := INF
	
	for interactable in interactables_in_range:
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
		interaction_requested.emit(nearby_interactable)


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


# ==============================================================================
# TUTORIAL INTEGRATION
# ==============================================================================

## Signal for tutorial system
signal tutorial_movement_detected

func _notify_tutorial_movement() -> void:
	tutorial_movement_detected.emit()

