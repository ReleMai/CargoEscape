# ==============================================================================
# ENEMY SCRIPT - VARIED MOVEMENT PATTERNS
# ==============================================================================
# 
# FILE: scripts/enemy.gd
# PURPOSE: Controls enemy movement with multiple path patterns
#
# ATTACHED TO: Enemy scene (Area2D)
#
# MOVEMENT PATTERNS AVAILABLE:
# ----------------------------
# 1. STRAIGHT: Classic left-moving enemy
# 2. SINE_WAVE: Moves in a wavy pattern (up and down while going left)
# 3. DIAGONAL_DOWN: Moves diagonally from top-right to bottom-left
# 4. DIAGONAL_UP: Moves diagonally from bottom-right to top-left
# 5. ZIGZAG: Sharp direction changes
# 6. HOMING: Slowly tracks toward the player (advanced)
# 7. CIRCULAR: Spiral/circular approach pattern
#
# HOW PATTERNS WORK:
# ------------------
# Each pattern modifies the enemy's velocity each frame differently.
# The pattern is set when the enemy spawns (randomly or by the spawner).
#
# ==============================================================================

extends Area2D


# ==============================================================================
# ENUMS
# ==============================================================================
# Enums are a way to define named constants
# Instead of remembering that 0=straight, 1=sine, etc.
# We can use MovementPattern.STRAIGHT, MovementPattern.SINE_WAVE

enum MovementPattern {
	STRAIGHT,      # 0 - Simple left movement
	SINE_WAVE,     # 1 - Wavy up/down motion
	DIAGONAL_DOWN, # 2 - Top-right to bottom-left
	DIAGONAL_UP,   # 3 - Bottom-right to top-left
	ZIGZAG,        # 4 - Sharp direction changes
	HOMING,        # 5 - Tracks toward player
	CIRCULAR       # 6 - Spiral pattern
}


# ==============================================================================
# SIGNALS
# ==============================================================================

signal destroyed


# ==============================================================================
# EXPORTED VARIABLES
# ==============================================================================

@export_group("Base Movement")
## Base horizontal speed (pixels per second)
@export var base_speed: float = 200.0

## Random speed variation (+/- this amount)
@export var speed_variation: float = 50.0

## Rotation speed (radians per second) - visual tumbling
@export var rotation_speed: float = 1.0

@export_group("Pattern Settings")
## Which movement pattern to use (can be set by spawner)
@export var movement_pattern: MovementPattern = MovementPattern.STRAIGHT

## Amplitude for wave patterns (how far up/down it moves)
@export var wave_amplitude: float = 100.0

## Frequency for wave patterns (how fast it oscillates)
@export var wave_frequency: float = 3.0

## How strongly homing enemies track the player (0-1)
@export var homing_strength: float = 0.02

## Zigzag interval (seconds between direction changes)
@export var zigzag_interval: float = 0.5

@export_group("Difficulty")
## Should speed increase over time?
@export var use_difficulty_scaling: bool = true


@export_group("Health")
## Maximum health of this enemy (percentage-based like player)
@export var max_health: float = 50.0

## Current health
var current_health: float = 50.0

## Health bar scene
var health_bar_scene: PackedScene = preload("res://scenes/ui/enemy_health_bar.tscn")

## Health bar instance
var health_bar: Control = null


# ==============================================================================
# STATE VARIABLES
# ==============================================================================

## Actual speed this enemy uses (base + variation)
var actual_speed: float

## Time since spawn (used for wave calculations)
var time_alive: float = 0.0

## Starting Y position (used for wave patterns)
var start_y: float

## Current velocity
var current_velocity: Vector2 = Vector2.ZERO

## For zigzag pattern: current vertical direction (1 or -1)
var zigzag_direction: float = 1.0

## Timer for zigzag direction changes
var zigzag_timer: float = 0.0

## Reference to player (for homing pattern)
var player_ref: Node2D = null

## Cleanup margin
var cleanup_margin: float = 100.0

## Screen bounds
var screen_height: float

## Whether to use world scroll (horizontal movement handled by main scene)
var use_world_scroll: bool = false


# ==============================================================================
# BUILT-IN FUNCTIONS
# ==============================================================================

func _ready() -> void:
	# Initialize health
	current_health = max_health
	
	# Create health bar
	_setup_health_bar()
	
	# Calculate actual speed with random variation
	actual_speed = base_speed + randf_range(-speed_variation, speed_variation)
	
	# Apply difficulty scaling
	if use_difficulty_scaling:
		apply_difficulty_scaling()
	
	# Add to enemies group for collision detection
	add_to_group("enemies")
	
	# Store starting position for wave calculations
	start_y = position.y
	
	# Get screen height for boundary checks
	screen_height = get_viewport_rect().size.y
	
	# Randomize starting rotation
	rotation = randf() * TAU
	
	# Randomize rotation direction
	if randf() > 0.5:
		rotation_speed = -rotation_speed
	
	# Initialize zigzag direction randomly
	zigzag_direction = 1.0 if randf() > 0.5 else -1.0
	zigzag_timer = randf() * zigzag_interval  # Random start offset
	
	# Try to find player for homing pattern
	# We use call_deferred to ensure the scene tree is ready
	call_deferred("_find_player")
	
	# Initialize velocity based on pattern
	initialize_pattern()


func _find_player() -> void:
	# Find the player node for homing behavior
	# get_tree().get_first_node_in_group() finds the first node in a group
	player_ref = get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	# Track time alive (for wave calculations)
	time_alive += delta
	
	# Update velocity based on movement pattern
	update_pattern_movement(delta)
	
	# Apply the velocity
	# If using world scroll, only apply vertical movement (horizontal handled by main)
	if use_world_scroll:
		position.y += current_velocity.y * delta
	else:
		position += current_velocity * delta
	
	# Rotate for visual effect
	rotation += rotation_speed * delta
	
	# Check for cleanup (only if not using world scroll - main handles cleanup)
	if not use_world_scroll:
		check_cleanup()


# ==============================================================================
# MOVEMENT PATTERN SYSTEM
# ==============================================================================

func initialize_pattern() -> void:
	# -------------------------------------------------------------------------
	# PATTERN INITIALIZATION:
	# -------------------------------------------------------------------------
	# Set up initial velocity based on the chosen pattern
	# This runs once when the enemy spawns
	
	match movement_pattern:
		MovementPattern.STRAIGHT:
			# Simple: just move left
			current_velocity = Vector2(-actual_speed, 0)
		
		MovementPattern.SINE_WAVE:
			# Start moving left, vertical component added in update
			current_velocity = Vector2(-actual_speed, 0)
		
		MovementPattern.DIAGONAL_DOWN:
			# Move left AND down
			# normalized() keeps total speed consistent
			current_velocity = Vector2(-1, 0.5).normalized() * actual_speed
		
		MovementPattern.DIAGONAL_UP:
			# Move left AND up
			current_velocity = Vector2(-1, -0.5).normalized() * actual_speed
		
		MovementPattern.ZIGZAG:
			# Start moving left with vertical component
			current_velocity = Vector2(-actual_speed, actual_speed * 0.5 * zigzag_direction)
		
		MovementPattern.HOMING:
			# Start moving left, will adjust toward player
			current_velocity = Vector2(-actual_speed * 0.7, 0)
		
		MovementPattern.CIRCULAR:
			# Start with leftward velocity
			current_velocity = Vector2(-actual_speed * 0.8, 0)


func update_pattern_movement(delta: float) -> void:
	# -------------------------------------------------------------------------
	# PATTERN UPDATE:
	# -------------------------------------------------------------------------
	# Called every frame to update velocity based on pattern
	# This is where the "personality" of each pattern comes from
	
	match movement_pattern:
		MovementPattern.STRAIGHT:
			# Straight pattern: no changes needed, velocity stays constant
			pass
		
		MovementPattern.SINE_WAVE:
			update_sine_wave_pattern()
		
		MovementPattern.DIAGONAL_DOWN, MovementPattern.DIAGONAL_UP:
			# Diagonal patterns: check boundaries and bounce
			update_diagonal_pattern()
		
		MovementPattern.ZIGZAG:
			update_zigzag_pattern(delta)
		
		MovementPattern.HOMING:
			update_homing_pattern(delta)
		
		MovementPattern.CIRCULAR:
			update_circular_pattern(delta)


func update_sine_wave_pattern() -> void:
	# -------------------------------------------------------------------------
	# SINE WAVE PATTERN:
	# -------------------------------------------------------------------------
	# Uses sin() function to create smooth wave motion
	# 
	# sin() returns values between -1 and 1, oscillating smoothly
	# time_alive * frequency = how fast we go through the wave
	# * amplitude = how far up/down we go
	
	# Keep horizontal velocity constant
	current_velocity.x = -actual_speed
	
	# Calculate wave offset using sine
	# sin(time * frequency) gives us a value from -1 to 1
	# Multiply by amplitude to get actual pixel offset
	var wave_offset = sin(time_alive * wave_frequency) * wave_amplitude
	
	# Set vertical velocity to move toward the wave position
	# This creates smooth following of the wave
	var target_y = start_y + wave_offset
	current_velocity.y = (target_y - position.y) * 5.0  # 5.0 = smoothing factor


func update_diagonal_pattern() -> void:
	# -------------------------------------------------------------------------
	# DIAGONAL PATTERN:
	# -------------------------------------------------------------------------
	# Bounces off top and bottom screen edges
	
	# Check bottom boundary
	if position.y > screen_height - 50:
		# Reverse vertical direction (go up)
		current_velocity.y = -abs(current_velocity.y)
	
	# Check top boundary
	if position.y < 50:
		# Reverse vertical direction (go down)
		current_velocity.y = abs(current_velocity.y)


func update_zigzag_pattern(delta: float) -> void:
	# -------------------------------------------------------------------------
	# ZIGZAG PATTERN:
	# -------------------------------------------------------------------------
	# Sharp direction changes at regular intervals
	
	# Update zigzag timer
	zigzag_timer += delta
	
	# Time to change direction?
	if zigzag_timer >= zigzag_interval:
		zigzag_timer = 0.0
		zigzag_direction *= -1.0  # Flip direction
		
		# Update vertical velocity
		current_velocity.y = actual_speed * 0.6 * zigzag_direction
	
	# Keep horizontal velocity constant
	current_velocity.x = -actual_speed
	
	# Bounce off screen edges
	if position.y > screen_height - 50 or position.y < 50:
		zigzag_direction *= -1.0
		current_velocity.y = actual_speed * 0.6 * zigzag_direction


func update_homing_pattern(_delta: float) -> void:
	# -------------------------------------------------------------------------
	# HOMING PATTERN:
	# -------------------------------------------------------------------------
	# Slowly adjusts direction toward the player
	# Not too aggressive - player can still dodge!
	
	if player_ref == null or not is_instance_valid(player_ref):
		# No player found, just move straight
		current_velocity.x = -actual_speed * 0.7
		return
	
	# Calculate direction to player
	var direction_to_player = (player_ref.global_position - global_position).normalized()
	
	# Create target velocity pointing at player
	var target_velocity = direction_to_player * actual_speed * 0.8
	
	# Smoothly interpolate toward target (lerp)
	# homing_strength controls how aggressively it tracks
	# Low value (0.02) = gentle tracking, gives player time to react
	current_velocity = current_velocity.lerp(target_velocity, homing_strength)
	
	# Ensure minimum leftward movement (so it doesn't just hover)
	if current_velocity.x > -actual_speed * 0.3:
		current_velocity.x = -actual_speed * 0.3


func update_circular_pattern(delta: float) -> void:
	# -------------------------------------------------------------------------
	# CIRCULAR PATTERN:
	# -------------------------------------------------------------------------
	# Rotates the velocity vector over time creating spiral motion
	
	# Rotate the velocity by a small angle each frame
	var rotation_rate = 2.0  # Radians per second
	var angle = rotation_rate * delta
	
	# Rotate velocity vector
	current_velocity = current_velocity.rotated(angle)
	
	# Add constant leftward drift so it eventually exits screen
	current_velocity.x -= 20.0 * delta
	
	# Keep total speed consistent
	if current_velocity.length() > actual_speed:
		current_velocity = current_velocity.normalized() * actual_speed


# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

func apply_difficulty_scaling() -> void:
	# Increase speed based on survival time
	if not has_node("/root/GameManager"):
		return
	
	var game_manager = get_node("/root/GameManager")
	var time_multiplier = 1.0 + (game_manager.survival_time / 30.0) * 0.1
	time_multiplier = min(time_multiplier, 2.0)
	
	actual_speed *= time_multiplier


func check_cleanup() -> void:
	# Remove enemy if it goes off the left side of the screen
	if position.x < -cleanup_margin:
		destroy()
	
	# Also remove if it somehow goes way off the top/bottom
	if position.y < -cleanup_margin * 2 or position.y > screen_height + cleanup_margin * 2:
		destroy()


func destroy() -> void:
	emit_signal("destroyed")
	ObjectPool.release(self)


## Take damage from projectiles or other sources
func take_damage(amount: float) -> void:
	current_health -= amount
	
	# Visual feedback - flash white briefly
	_flash_damage()
	
	# Update health bar
	if health_bar and health_bar.has_method("update_health"):
		health_bar.update_health(current_health)
	
	if current_health <= 0:
		destroy()


## Flash white when hit
func _flash_damage() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		var placeholder = sprite.get_node_or_null("Placeholder")
		if placeholder and placeholder is ColorRect:
			var original_color = placeholder.color
			placeholder.color = Color.WHITE
			
			# Reset color after brief delay
			var tween = create_tween()
			tween.tween_property(placeholder, "color", original_color, 0.1)


## Setup the health bar above the enemy
func _setup_health_bar() -> void:
	if health_bar_scene:
		health_bar = health_bar_scene.instantiate()
		add_child(health_bar)
		
		# Position above the enemy
		health_bar.position = Vector2(-20, -40)
		
		# Initialize health bar
		if health_bar.has_method("setup"):
			health_bar.setup(max_health)


# ==============================================================================
# PUBLIC FUNCTIONS (Called by spawner)
# ==============================================================================

## Set the movement pattern (called by spawner before adding to scene)
func set_pattern(pattern: MovementPattern) -> void:
	movement_pattern = pattern


## Set a random pattern
func randomize_pattern() -> void:
	# Get random pattern from the enum
	# MovementPattern.size() returns the number of patterns
	movement_pattern = randi() % MovementPattern.size() as MovementPattern


## Set pattern with weights (some patterns more common than others)
func set_weighted_random_pattern() -> void:
	# Weighted random selection
	# Higher weight = more likely to be chosen
	var weights = {
		MovementPattern.STRAIGHT: 30,      # Common
		MovementPattern.SINE_WAVE: 25,     # Common
		MovementPattern.DIAGONAL_DOWN: 15, # Moderate
		MovementPattern.DIAGONAL_UP: 15,   # Moderate
		MovementPattern.ZIGZAG: 10,        # Rare
		MovementPattern.HOMING: 3,         # Very rare
		MovementPattern.CIRCULAR: 2        # Very rare
	}
	
	# Calculate total weight
	var total = 0
	for w in weights.values():
		total += w
	
	# Pick random number
	var roll = randi() % total
	
	# Find which pattern was selected
	var cumulative = 0
	for pattern in weights:
		cumulative += weights[pattern]
		if roll < cumulative:
			movement_pattern = pattern
			return


## Set whether to use world scroll (horizontal movement handled externally)
func set_use_world_scroll(enabled: bool) -> void:
	use_world_scroll = enabled


## Reset the enemy for object pooling
func reset() -> void:
	# Reset health
	current_health = max_health
	
	# Reset state
	time_alive = 0.0
	zigzag_timer = randf() * zigzag_interval
	zigzag_direction = 1.0 if randf() > 0.5 else -1.0
	
	# Reset velocity
	current_velocity = Vector2.ZERO
	
	# Reset visual
	modulate = Color.WHITE
	rotation = randf() * TAU
	
	# Randomize rotation direction
	if randf() > 0.5:
		rotation_speed = -abs(rotation_speed)
	else:
		rotation_speed = abs(rotation_speed)
	
	# Update health bar
	if health_bar and health_bar.has_method("update_health"):
		health_bar.update_health(current_health)
	
	# Re-initialize pattern
	initialize_pattern()
