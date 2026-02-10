# ==============================================================================
# SPACE PLAYER - PHYSICS-BASED SPACECRAFT CONTROLLER
# ==============================================================================
#
# FILE: scripts/player.gd
# PURPOSE: Controls the player's spacecraft during the space escape phase
#
# PHYSICS MODEL:
# --------------
# This controller simulates Newtonian physics in space:
# - No air resistance (configurable drag for game feel)
# - Thrust adds acceleration in any direction
# - Momentum persists until counteracted
# - Braking thrusts opposite to velocity
#
# KEY PHYSICS CONCEPTS:
# ---------------------
# 1. VELOCITY: Current speed and direction (pixels/second)
# 2. ACCELERATION: Change in velocity (pixels/second²)
# 3. THRUST: Force that creates acceleration (F = ma)
# 4. DRAG: Optional friction for better game feel
#
# STATE MACHINE:
# --------------
# NORMAL     - Standard flight, can thrust and brake
# INVINCIBLE - Brief immunity after taking damage
# DISABLED   - No control (cutscenes, death)
#
# ==============================================================================

extends CharacterBody2D
class_name SpacePlayer


# ==============================================================================
# ENUMS
# ==============================================================================

## Player state machine
enum State {
	NORMAL,     ## Can thrust and take damage
	INVINCIBLE, ## Temporary immunity after hit
	DISABLED    ## No control
}


# ==============================================================================
# SIGNALS
# ==============================================================================

## Emitted when player takes damage
signal hit

## Emitted when player collides with something (for effects)
signal collision_occurred(impact_strength: float)

## Emitted when player fires weapon (for effects like screen shake)
signal weapon_fired

## Emitted when player state changes
signal state_changed(old_state: State, new_state: State)


# ==============================================================================
# EXPORTS - THRUST PHYSICS
# ==============================================================================

@export_group("Thrust Settings")

## How much acceleration when thrusting (pixels/second²)
## Higher = snappier, more responsive
## Lower = heavier, more realistic spacecraft feel
@export_range(100.0, 1000.0, 25.0) var thrust_power: float = 500.0

## Brake thrust power (pixels/second²)
## Used when actively braking to slow down
@export_range(100.0, 800.0, 25.0) var brake_power: float = 400.0

## Maximum speed in any direction (pixels/second)
## Prevents infinite acceleration
@export_range(200.0, 800.0, 25.0) var max_speed: float = 400.0


@export_group("Space Physics")

## Drag coefficient (0 = pure Newtonian, higher = more friction)
## 0.0-0.1 = realistic space feel
## 0.2-0.5 = easier to control
@export_range(0.0, 1.0, 0.05) var space_drag: float = 0.3

## Whether to apply drag at all
@export var use_drag: bool = true


@export_group("Collision")

## Knockback force when hitting enemies (pixels/second)
@export_range(100.0, 500.0, 25.0) var collision_knockback: float = 300.0

## Speed multiplier on collision (0.5 = lose half speed)
@export_range(0.0, 1.0, 0.1) var collision_speed_penalty: float = 0.6


@export_group("Boundaries")

## Margin from screen edges (pixels)
@export var screen_margin: float = 20.0

## Bounce factor at edges (0 = stop, 1 = full bounce)
@export_range(0.0, 1.0, 0.1) var edge_bounce: float = 0.3


@export_group("Invincibility")

## Duration of invincibility after hit (seconds)
@export_range(0.5, 3.0, 0.1) var invincibility_duration: float = 1.5

## Blink rate during invincibility (seconds per cycle)
@export var blink_rate: float = 0.1


@export_group("Weapon")

## Laser scene to instantiate
@export var laser_scene: PackedScene

## Time between shots (seconds)
@export var fire_rate: float = 0.2

## Damage dealt by laser (uses GameManager if not set)
@export var laser_damage: float = 0.0

## Damage taken when colliding with enemies (percentage of max health)
@export var collision_damage: float = 15.0

## Maximum angle from forward direction for aiming (degrees)
## 45 = 90 degree cone, 60 = 120 degree cone
@export_range(15.0, 90.0, 5.0) var aim_cone_half_angle: float = 45.0


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $HurtBox
@onready var muzzle: Marker2D = $Muzzle
@onready var ship_visual: Node2D = $ShipVisual


# ==============================================================================
# STATE VARIABLES
# ==============================================================================

## Current player state
var current_state: State = State.NORMAL

## Screen dimensions (set in _ready)
var screen_size: Vector2

## Current thrust input direction
var thrust_direction: Vector2 = Vector2.ZERO

## Is player currently thrusting?
var is_thrusting: bool = false

## Is player currently braking?
var is_braking: bool = false

## Invincibility timer
var invincibility_timer: float = 0.0

## Blink timer for invincibility visual
var blink_timer: float = 0.0

## Fire cooldown timer
var fire_cooldown: float = 0.0

## Edge bounce collision cooldown (prevents shake spam)
var edge_collision_cooldown: float = 0.0
const EDGE_COLLISION_COOLDOWN_TIME: float = 0.25

## Reference to GameManager
var game_manager: Node = null


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Add to player group
	add_to_group("player")
	
	# Get screen size
	screen_size = get_viewport_rect().size
	
	# Get GameManager reference
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		_setup_ship_visual()
	
	# Connect hurtbox
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	# Load laser scene if not set
	if laser_scene == null:
		laser_scene = preload("res://scenes/laser.tscn")
	
	# Initialize laser pool
	if laser_scene:
		ObjectPool.create_pool(laser_scene, 50)


func _setup_ship_visual() -> void:
	# Configure ship visual based on GameManager data
	if not ship_visual or not game_manager:
		return
	
	# Set ship type from GameManager
	if game_manager.has_method("get_ship_type"):
		var ship_type: int = game_manager.get_ship_type()
		if ship_visual.has_method("set_ship_type"):
			ship_visual.set_ship_type(ship_type)
	elif "ship_type" in game_manager:
		if ship_visual.has_method("set_ship_type"):
			ship_visual.set_ship_type(game_manager.ship_type)
	
	# Load equipped modules from GameManager
	if game_manager.has_method("get_equipped_modules"):
		var modules: Dictionary = game_manager.get_equipped_modules()
		for slot_type in modules:
			var module = modules[slot_type]
			if module and ship_visual.has_method("equip_module"):
				ship_visual.equip_module(module)
	elif "equipped_modules" in game_manager:
		for slot_type in game_manager.equipped_modules:
			var module = game_manager.equipped_modules[slot_type]
			if module and ship_visual.has_method("equip_module"):
				ship_visual.equip_module(module)
	
	print("[Player] Ship visual configured")
	
	# Start in normal state
	_transition_to_state(State.NORMAL)


func _physics_process(delta: float) -> void:
	# Update fire cooldown
	if fire_cooldown > 0:
		fire_cooldown -= delta
	
	# Update edge collision cooldown
	if edge_collision_cooldown > 0:
		edge_collision_cooldown -= delta
	
	# Process state-specific logic
	match current_state:
		State.NORMAL:
			_process_normal_state(delta)
		State.INVINCIBLE:
			_process_invincible_state(delta)
		State.DISABLED:
			_process_disabled_state(delta)
	
	# Always move
	move_and_slide()
	
	# Handle boundaries
	_handle_screen_boundaries()
	
	# Update visuals
	_update_ship_rotation()


# ==============================================================================
# STATE MACHINE
# ==============================================================================

## Transition to a new state
func _transition_to_state(new_state: State) -> void:
	if new_state == current_state:
		return
	
	var old_state := current_state
	
	# Exit old state
	_exit_state(old_state)
	
	# Enter new state
	current_state = new_state
	_enter_state(new_state)
	
	# Emit signal
	state_changed.emit(old_state, new_state)


## Called when entering a state
func _enter_state(state: State) -> void:
	match state:
		State.NORMAL:
			_set_sprite_visible(true)
		State.INVINCIBLE:
			invincibility_timer = invincibility_duration
			blink_timer = 0.0
		State.DISABLED:
			thrust_direction = Vector2.ZERO
			is_thrusting = false
			is_braking = false


## Called when exiting a state
func _exit_state(state: State) -> void:
	match state:
		State.INVINCIBLE:
			_set_sprite_visible(true)
		_:
			pass


## Process NORMAL state - standard flight
func _process_normal_state(delta: float) -> void:
	_handle_thrust_input()
	_handle_shooting()
	_apply_physics(delta)
	_limit_speed()


## Process INVINCIBLE state - immune to damage
func _process_invincible_state(delta: float) -> void:
	# Still allow movement and shooting
	_handle_thrust_input()
	_handle_shooting()
	_apply_physics(delta)
	_limit_speed()
	
	# Update invincibility timer
	invincibility_timer -= delta
	
	# Blink effect
	blink_timer += delta
	if blink_timer >= blink_rate:
		blink_timer = 0.0
		_toggle_sprite_visibility()
	
	# End invincibility
	if invincibility_timer <= 0.0:
		_transition_to_state(State.NORMAL)


## Process DISABLED state - no control
func _process_disabled_state(delta: float) -> void:
	# Apply drag to slow down
	if use_drag:
		var drag_factor := 1.0 - (space_drag * delta)
		velocity *= clampf(drag_factor, 0.0, 1.0)


# ==============================================================================
# INPUT HANDLING
# ==============================================================================

## Read thrust input from player
func _handle_thrust_input() -> void:
	# Reset state
	thrust_direction = Vector2.ZERO
	is_thrusting = false
	is_braking = false
	
	# Check for brake first
	if Input.is_action_pressed("brake"):
		is_braking = true
		return
	
	# Vertical thrust
	if Input.is_action_pressed("move_up"):
		thrust_direction.y -= 1.0
		is_thrusting = true
	if Input.is_action_pressed("move_down"):
		thrust_direction.y += 1.0
		is_thrusting = true
	
	# Horizontal thrust
	if Input.is_action_pressed("move_left"):
		thrust_direction.x -= 1.0
		is_thrusting = true
	if Input.is_action_pressed("move_right"):
		thrust_direction.x += 1.0
		is_thrusting = true
	
	# Fallback key checks
	if thrust_direction == Vector2.ZERO:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			thrust_direction.y -= 1.0
			is_thrusting = true
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			thrust_direction.y += 1.0
			is_thrusting = true
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			thrust_direction.x -= 1.0
			is_thrusting = true
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			thrust_direction.x += 1.0
			is_thrusting = true
	
	# Check brake with fallback (Shift key only now, space is for shooting)
	if not is_braking:
		if Input.is_key_pressed(KEY_SHIFT):
			is_braking = true
			is_thrusting = false
	
	# Normalize diagonal thrust
	if thrust_direction.length_squared() > 1.0:
		thrust_direction = thrust_direction.normalized()


## Handle shooting input
func _handle_shooting() -> void:
	# Check for fire input (space, J, or left mouse button)
	var wants_to_fire = Input.is_action_pressed("fire")
	
	# Fallback key check
	if not wants_to_fire:
		wants_to_fire = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_J) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	if wants_to_fire and fire_cooldown <= 0:
		_fire_laser()
		
		# Apply fire rate with module bonus
		var fire_mult = 1.0
		if game_manager and game_manager.has_method("get_fire_rate_multiplier"):
			fire_mult = game_manager.get_fire_rate_multiplier()
		
		fire_cooldown = fire_rate / fire_mult


## Fire a laser projectile
func _fire_laser() -> void:
	if laser_scene == null:
		return
	
	# Play laser fire sound
	AudioManager.play_sfx("laser_fire", -3.0)
	
	# Acquire laser from pool
	var laser = ObjectPool.acquire(laser_scene)
	
	# Position at muzzle or front of ship
	if muzzle:
		laser.global_position = muzzle.global_position
	else:
		laser.global_position = global_position + Vector2(40, 0)
	
	# Calculate direction towards mouse, clamped to cone
	var aim_direction = _get_aim_direction()
	laser.set_direction(aim_direction)
	
	# Rotate laser sprite to match direction
	laser.rotation = aim_direction.angle()
	
	# Set damage from GameManager or export
	var damage = laser_damage
	if damage <= 0 and game_manager and game_manager.has_method("get_laser_damage"):
		damage = game_manager.get_laser_damage()
	if damage > 0:
		laser.set_damage(damage)

	# Reparent to scene tree (using pool)
	ObjectPool.reparent_pooled_object(laser, get_tree().current_scene)
	
	# Emit weapon fired signal for effects
	weapon_fired.emit()


## Get aim direction toward mouse, clamped within forward cone
func _get_aim_direction() -> Vector2:
	# Get mouse position in world coordinates
	var mouse_pos = get_global_mouse_position()
	
	# Direction from muzzle/player to mouse
	var spawn_pos = muzzle.global_position if muzzle else global_position + Vector2(40, 0)
	var to_mouse = (mouse_pos - spawn_pos).normalized()
	
	# Forward direction (always right for this game)
	var forward = Vector2.RIGHT
	
	# Calculate angle between forward and mouse direction
	var angle_to_mouse = forward.angle_to(to_mouse)
	
	# Convert cone angle to radians
	var max_angle = deg_to_rad(aim_cone_half_angle)
	
	# Clamp angle within cone
	var clamped_angle = clampf(angle_to_mouse, -max_angle, max_angle)
	
	# Return the clamped direction
	return forward.rotated(clamped_angle)


# ==============================================================================
# PHYSICS
# ==============================================================================

## Apply physics forces
func _apply_physics(delta: float) -> void:
	# Get module bonuses
	var speed_mult = 1.0
	var thrust_bonus_val = 0.0
	if game_manager:
		if game_manager.has_method("get_speed_multiplier"):
			speed_mult = game_manager.get_speed_multiplier()
		if game_manager.has_method("get_thrust_bonus"):
			thrust_bonus_val = game_manager.get_thrust_bonus()
	
	# --- BRAKING ---
	# Brake thrusts opposite to velocity
	if is_braking and velocity.length() > 10.0:
		var brake_dir := -velocity.normalized()
		velocity += brake_dir * brake_power * delta
		
		# Stop completely if very slow
		if velocity.length() < 20.0:
			velocity = Vector2.ZERO
		return
	
	# --- THRUSTING ---
	if is_thrusting:
		var effective_thrust = (thrust_power + thrust_bonus_val) * speed_mult
		velocity += thrust_direction * effective_thrust * delta
	
	# --- DRAG ---
	if use_drag and space_drag > 0.0:
		var drag_factor := 1.0 - (space_drag * delta)
		velocity *= clampf(drag_factor, 0.0, 1.0)


## Limit velocity to max_speed (modified by modules)
func _limit_speed() -> void:
	var speed_mult = 1.0
	if game_manager and game_manager.has_method("get_speed_multiplier"):
		speed_mult = game_manager.get_speed_multiplier()
	
	var effective_max = max_speed * speed_mult
	if velocity.length() > effective_max:
		velocity = velocity.normalized() * effective_max


## Handle screen edge collisions
func _handle_screen_boundaries() -> void:
	var bounced := false
	
	# Left edge
	if position.x < screen_margin:
		position.x = screen_margin
		velocity.x = absf(velocity.x) * edge_bounce
		bounced = true
	
	# Right edge
	if position.x > screen_size.x - screen_margin:
		position.x = screen_size.x - screen_margin
		velocity.x = -absf(velocity.x) * edge_bounce
		bounced = true
	
	# Top edge
	if position.y < screen_margin:
		position.y = screen_margin
		velocity.y = absf(velocity.y) * edge_bounce
		bounced = true
	
	# Bottom edge
	if position.y > screen_size.y - screen_margin:
		position.y = screen_size.y - screen_margin
		velocity.y = -absf(velocity.y) * edge_bounce
		bounced = true
	
	# Only emit collision signal if not on cooldown (prevents shake spam)
	if bounced and edge_collision_cooldown <= 0:
		edge_collision_cooldown = EDGE_COLLISION_COOLDOWN_TIME
		# Emit with a smaller impact value for edge bounces
		collision_occurred.emit(minf(velocity.length() * 0.05, 3.0))


# ==============================================================================
# COLLISION
# ==============================================================================

## Called when hurtbox overlaps an area
func _on_hurtbox_area_entered(area: Area2D) -> void:
	# Ignore if invincible
	if current_state == State.INVINCIBLE:
		return
	
	# Check for enemy
	if area.is_in_group("enemies"):
		_handle_enemy_collision(area)


## Handle collision with enemy
func _handle_enemy_collision(enemy: Area2D) -> void:
	# Calculate knockback direction (away from enemy)
	var knockback_dir := (global_position - enemy.global_position).normalized()
	if knockback_dir == Vector2.ZERO:
		knockback_dir = Vector2(-1, -1).normalized()
	
	# Apply collision physics
	velocity *= collision_speed_penalty
	velocity += knockback_dir * collision_knockback
	
	# Emit signals
	collision_occurred.emit(collision_knockback)
	
	# Take damage
	_take_damage(collision_damage)


## Process taking damage
func _take_damage(damage: float = 15.0) -> void:
	# Apply damage reduction from utility modules
	var dmg_reduction = 0.0
	if game_manager and game_manager.has_method("get_damage_reduction"):
		dmg_reduction = game_manager.get_damage_reduction()
	
	var final_damage = damage * (1.0 - dmg_reduction)
	
	# Play damage sound
	AudioManager.play_sfx("ship_damage", 0.0)
	
	# Apply damage to GameManager
	if game_manager and game_manager.has_method("take_damage"):
		game_manager.take_damage(final_damage)
	
	hit.emit()
	_transition_to_state(State.INVINCIBLE)


# ==============================================================================
# VISUALS
# ==============================================================================

## Update ship rotation based on velocity
func _update_ship_rotation() -> void:
	if not sprite:
		return
	
	# Tilt based on horizontal velocity
	var target_rotation := velocity.x * 0.001
	target_rotation = clampf(target_rotation, -0.3, 0.3)
	
	# Smooth interpolation
	sprite.rotation = lerpf(sprite.rotation, target_rotation, 0.1)


## Set sprite visibility
func _set_sprite_visible(show_sprite: bool) -> void:
	if sprite:
		sprite.modulate.a = 1.0 if show_sprite else 0.3


## Toggle sprite visibility (for blink effect)
func _toggle_sprite_visibility() -> void:
	if sprite:
		sprite.modulate.a = 0.3 if sprite.modulate.a > 0.5 else 1.0


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Apply an external force (explosions, powerups, etc.)
func apply_force(force: Vector2) -> void:
	velocity += force


## Get current speed for UI display
func get_current_speed() -> float:
	return velocity.length()


## Check if player is currently falling (moving down fast)
func is_falling() -> bool:
	return velocity.y > 50.0 and not is_thrusting


## Check if player can take damage
func can_take_damage() -> bool:
	return current_state == State.NORMAL


## Enable/disable player control
func set_control_enabled(enabled: bool) -> void:
	if enabled:
		if current_state == State.DISABLED:
			_transition_to_state(State.NORMAL)
	else:
		_transition_to_state(State.DISABLED)


## Teleport player to position
func teleport_to(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
