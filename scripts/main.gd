# ==============================================================================
# MAIN GAME SCENE SCRIPT - SIDE-SCROLLER SPACE ESCAPE
# ==============================================================================
# 
# FILE: scripts/main.gd
# PURPOSE: Controls the main game loop, spawning, and scene management
#
# ARCHITECTURE:
# -------------
# This is a side-scroller where:
# - The world scrolls toward the player (right to left)
# - Obstacles spawn on the right and move left
# - Player dodges obstacles while traveling toward a station
# - Parallax background creates depth and motion feel
#
# ==============================================================================

extends Node2D


# ==============================================================================
# PRELOADS
# ==============================================================================

const StationDataClass = preload("res://scripts/data/station_data.gd")
const AsteroidClass = preload("res://scripts/enemies/asteroid.gd")
const AsteroidScene = preload("res://scenes/enemies/asteroid.tscn")
const ScreenShake = preload("res://scripts/core/screen_shake.gd")


# ==============================================================================
# EXPORTED VARIABLES
# ==============================================================================

@export_group("Enemy Spawning")
## Path to the enemy scene to spawn
@export var enemy_scene: PackedScene

## Time between enemy spawns (in seconds)
@export var spawn_interval: float = 1.5

## Minimum spawn interval (for difficulty scaling)
@export var min_spawn_interval: float = 0.4

## How much to decrease spawn interval per second survived
@export var difficulty_increase_rate: float = 0.01

@export_group("Spawn Patterns")
## How long before advanced enemy patterns start appearing
@export var time_until_advanced_patterns: float = 15.0

## How long before homing enemies start appearing
@export var time_until_homing: float = 45.0

## Chance to spawn a wave of enemies instead of just one (0-1)
@export var wave_spawn_chance: float = 0.15

## Number of enemies in a wave
@export var wave_size_min: int = 3
@export var wave_size_max: int = 6

@export_group("Spawn Positions")
## Margin from top/bottom of screen for spawning
@export var spawn_margin: float = 60.0


@export_group("Scrolling World")
## Base world scroll speed (obstacles move this fast)
@export var base_scroll_speed: float = 350.0

## Maximum scroll speed at highest difficulty  
@export var max_scroll_speed: float = 500.0

## Distance to travel to reach the hideout (pixels)
## At base speed of 350, this takes ~2 seconds
@export var destination_distance: float = 800.0


# ==============================================================================
# ONREADY VARIABLES
# ==============================================================================

@onready var player: CharacterBody2D = $Player
@onready var enemy_container: Node2D = $EnemyContainer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var hud: CanvasLayer = $HUD
@onready var game_over_screen: CanvasLayer = $GameOverScreen
@onready var background: Node2D = $Background
@onready var space_station: Control = $SpaceStation


# ==============================================================================
# STATE VARIABLES
# ==============================================================================

var screen_size: Vector2
var game_manager: Node

## Track time for pattern unlocking
var survival_time: float = 0.0

## Current scroll speed
var current_scroll_speed: float = 0.0

## Distance traveled toward destination
var distance_traveled: float = 0.0

## Has reached destination?
var reached_destination: bool = false

## Screen shake system
var screen_shake: ScreenShake = null
var camera_base_position: Vector2 = Vector2.ZERO

## Legacy intensity conversion factor (matches max_offset)
const LEGACY_SHAKE_MAX: float = 15.0


# ==============================================================================
# BUILT-IN FUNCTIONS
# ==============================================================================

func _ready() -> void:
	print("=== MAIN SCENE READY ===")
	
	# Get screen dimensions
	screen_size = get_viewport_rect().size
	
	# Initialize screen shake system
	screen_shake = ScreenShake.new()
	screen_shake.default_intensity = 0.6
	screen_shake.default_duration = 0.4
	screen_shake.max_offset = LEGACY_SHAKE_MAX
	screen_shake.shake_frequency = 35.0
	screen_shake.decay_mode = ScreenShake.DecayMode.EXPONENTIAL
	screen_shake.shake_mode = ScreenShake.ShakeMode.TRAUMA
	screen_shake.cooldown_time = 0.15
	add_child(screen_shake)
	
	# Add player to group so enemies can find it
	player.add_to_group("player")
	
	# Get reference to GameManager autoload
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		setup_game_manager_connections()
	else:
		push_warning("GameManager autoload not found!")
	
	# Initialize object pools
	_initialize_pools()
	
	# Connect player signals
	setup_player_connections()
	
	# Setup spawn timer
	setup_spawn_timer()
	
	# Hide game over screen
	game_over_screen.visible = false
	
	# Start the game!
	start_game()


func _initialize_pools() -> void:
	# Create pool for asteroids
	ObjectPool.create_pool(AsteroidScene, 30)
	
	# Create pool for enemies if available
	if enemy_scene:
		ObjectPool.create_pool(enemy_scene, 20)
	
	print("[Main] Object pools initialized")


func _process(delta: float) -> void:
	# Track survival time locally
	if game_manager and game_manager.is_game_active:
		survival_time = game_manager.survival_time
	
	# Update camera shake
	_update_camera_shake(delta)
	
	# Skip processing if game is not active
	if not game_manager or not game_manager.is_game_active:
		return
	
	# DEV CHEAT: Press F1 to skip to hideout
	if Input.is_key_pressed(KEY_F1):
		print("[DEV] Skipping to hideout...")
		_on_destination_reached()
		return
	
	# Update scroll speed based on difficulty
	_update_scroll_speed()
	
	# Update distance traveled
	distance_traveled += current_scroll_speed * delta
	
	# Sync background scroll speed
	if background and background.has_method("set_scroll_speed"):
		background.set_scroll_speed(current_scroll_speed)
	
	# Move all enemies/obstacles with the world scroll
	_scroll_enemies(delta)
	
	# Check if reached destination
	if distance_traveled >= destination_distance and not reached_destination:
		_on_destination_reached()
	
	# Update difficulty (spawn rate) over time
	update_difficulty(delta)
	
	# Update HUD
	if game_manager:
		update_hud()


## Update camera shake effect
func _update_camera_shake(delta: float) -> void:
	if screen_shake and screen_shake.is_shaking():
		# Get shake offset from the screen shake system
		var shake_offset = screen_shake.get_shake_offset()
		
		# Apply shake to all visual nodes
		if background:
			background.position = camera_base_position + shake_offset
		if enemy_container:
			enemy_container.position = shake_offset
	else:
		# Reset positions
		if background:
			background.position = camera_base_position
		if enemy_container:
			enemy_container.position = Vector2.ZERO


## Trigger camera shake using the configurable screen shake system
## 
## The screen shake system provides:
## - Configurable intensity (0.0-1.0) scaled to pixels
## - Configurable duration with smooth decay curves
## - Multiple shake modes (Random, Perlin, Trauma)
## - Cooldown system to prevent shake spam
## 
## @param intensity: Legacy pixel-based intensity (converted to 0-1 range)
## @param bypass_cooldown: Set true for critical events like damage
func shake_camera(intensity: float = 0.5, bypass_cooldown: bool = false) -> void:
	if screen_shake:
		# Convert legacy intensity (pixel-based) to normalized 0-1 range
		var normalized_intensity = clampf(intensity / LEGACY_SHAKE_MAX, 0.0, 1.0)
		screen_shake.shake(normalized_intensity, -1.0, bypass_cooldown)


# ==============================================================================
# SETUP FUNCTIONS
# ==============================================================================

func setup_game_manager_connections() -> void:
	game_manager.game_over.connect(_on_game_over)
	game_manager.game_reset.connect(_on_game_reset)
	print("Connected to GameManager signals")


func setup_player_connections() -> void:
	player.hit.connect(_on_player_hit)
	
	# Connect new collision signal if player has it
	if player.has_signal("collision_occurred"):
		player.collision_occurred.connect(_on_player_collision)
	
	# Connect weapon fired signal for screen shake
	if player.has_signal("weapon_fired"):
		player.weapon_fired.connect(_on_player_weapon_fired)
	
	print("Connected to Player signals")


func setup_spawn_timer() -> void:
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	print("Spawn timer configured: ", spawn_interval, " seconds")


# ==============================================================================
# GAME FLOW
# ==============================================================================

func start_game() -> void:
	print("Starting game...")
	
	if game_manager:
		game_manager.reset_game()
		game_manager.start_game()
	
	# Load station-specific enemy configuration
	_load_station_data()
	
	# Reset local tracking
	survival_time = 0.0
	distance_traveled = 0.0
	reached_destination = false
	current_scroll_speed = base_scroll_speed
	
	# Start spawning enemies
	spawn_timer.start()
	
	# Reset player position
	player.visible = true
	player.position = Vector2(150, screen_size.y / 2)
	
	# Smooth fade in from undocking scene
	_fade_in_from_undocking()


## Creates a smooth fade-in from the undocking scene for seamless transition
func _fade_in_from_undocking() -> void:
	# Check if we came from undocking (escape_station is set)
	var from_undocking = false
	if game_manager:
		if game_manager.has_method("get_escape_station"):
			from_undocking = game_manager.get_escape_station() != null
		elif "escape_station" in game_manager:
			from_undocking = game_manager.escape_station != null
	
	# Create fade-in overlay
	var fade_layer = CanvasLayer.new()
	fade_layer.name = "FadeLayer"
	fade_layer.layer = 100
	add_child(fade_layer)
	
	var fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade_rect)
	
	# Fade in with speed lines effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade_rect, "color:a", 0.0, 0.6).set_ease(Tween.EASE_OUT)
	
	# Small camera shake at start (engine rumble)
	shake_camera(3.0)
	
	tween.tween_callback(func(): 
		fade_layer.queue_free()
	).set_delay(0.6)


func _update_scroll_speed() -> void:
	# Calculate progress (0 to 1)
	var progress := clampf(distance_traveled / destination_distance, 0.0, 1.0)
	
	# Interpolate scroll speed based on progress
	current_scroll_speed = lerpf(base_scroll_speed, max_scroll_speed, progress)


## Returns progress toward hideout as a value from 0.0 to 1.0
func get_distance_progress() -> float:
	return clampf(distance_traveled / destination_distance, 0.0, 1.0)


func _scroll_enemies(delta: float) -> void:
	# Move all enemies with the world scroll
	for enemy in enemy_container.get_children():
		# Enemies move at scroll speed plus their own movement
		# The enemy script handles its own patterns, we just add the base scroll
		enemy.position.x -= current_scroll_speed * delta
		
		# Clean up enemies that are too far off-screen left
		if enemy.position.x < -200:
			enemy.queue_free()


func _on_destination_reached() -> void:
	reached_destination = true
	print("=== HIDEOUT REACHED! ===")
	
	# Stop spawning
	spawn_timer.stop()
	
	# Clear remaining enemies
	clear_all_enemies()
	
	# Celebratory effects
	_play_arrival_effects()
	
	# Fade to black and transition to hideout scene
	await get_tree().create_timer(0.5).timeout
	_transition_to_hideout()


func _play_arrival_effects() -> void:
	# Brief flash of relief
	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 90
	add_child(flash_layer)
	
	var flash = ColorRect.new()
	flash.color = Color(0.2, 0.8, 0.4, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5)
	tween.tween_callback(flash_layer.queue_free)


func _transition_to_hideout() -> void:
	# Create a fade overlay
	var fade_layer = CanvasLayer.new()
	fade_layer.layer = 100
	add_child(fade_layer)
	
	var fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(fade)
	
	# Fade to black with slight zoom effect feel
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_callback(_go_to_hideout)


func _go_to_hideout() -> void:
	# Auto-save progress before transitioning to hideout
	if has_node("/root/SaveManager"):
		var save_manager = get_node("/root/SaveManager")
		save_manager.auto_save()
	
	get_tree().change_scene_to_file("res://scenes/hideout/hideout_scene.tscn")
	LoadingScreen.start_transition("res://scenes/hideout/hideout_scene.tscn")


func _on_new_mission() -> void:
	# Start a new boarding phase
	print("Starting new mission...")
	restart_game()


func update_difficulty(delta: float) -> void:
	# Gradually decrease spawn interval
	if spawn_timer.wait_time > min_spawn_interval:
		spawn_timer.wait_time -= difficulty_increase_rate * delta
		spawn_timer.wait_time = max(spawn_timer.wait_time, min_spawn_interval)


func update_hud() -> void:
	# HUD updates itself by reading from GameManager
	pass


# ==============================================================================
# ENEMY SPAWNING
# ==============================================================================

## Current station data for enemy spawning
var current_station_data: Resource  # StationData resource

## Load station-specific enemy configuration
func _load_station_data() -> void:
	# Try to get station from GameManager
	if game_manager and game_manager.has_method("get_escape_station"):
		current_station_data = game_manager.get_escape_station()
	elif game_manager and "escape_station" in game_manager:
		current_station_data = game_manager.escape_station
	
	# Fallback to abandoned station (first station)
	if current_station_data == null:
		current_station_data = preload("res://resources/stations/abandoned_station.tres")
	
	if current_station_data:
		print("[Main] Loaded station: ", current_station_data.station_name)
	else:
		print("[Main] No station data loaded")
	
	# Apply station configuration
	if current_station_data:
		spawn_interval = current_station_data.base_spawn_interval
		min_spawn_interval = current_station_data.min_spawn_interval
		difficulty_increase_rate = current_station_data.difficulty_ramp_rate


func _on_spawn_timer_timeout() -> void:
	# Use station-based spawning if we have station data
	if current_station_data:
		_spawn_station_enemy()
	else:
		# Fallback to original spawning
		if randf() < wave_spawn_chance and survival_time > 10.0:
			spawn_enemy_wave()
		else:
			spawn_enemy()


func _spawn_station_enemy() -> void:
	# Check station type enum value
	if current_station_data.station_type == StationDataClass.StationType.ABANDONED:
		_spawn_asteroid()
	else:
		# Default enemy spawning for other station types
		spawn_enemy()


func _spawn_asteroid() -> void:
	var asteroid = ObjectPool.acquire(AsteroidScene)
	
	# Set size based on station weights
	var size_index: int = current_station_data.get_random_asteroid_size()
	asteroid.asteroid_size = size_index
	
	# Position on right side of screen
	var spawn_x := screen_size.x + 100
	var spawn_y := randf_range(spawn_margin, screen_size.y - spawn_margin)
	asteroid.position = Vector2(spawn_x, spawn_y)
	
	# Connect destroyed signal with asteroid size for shake intensity
	if asteroid.has_signal("destroyed"):
		if not asteroid.destroyed.is_connected(_on_enemy_destroyed):
			asteroid.destroyed.connect(_on_enemy_destroyed)
	
	# Reparent to container
	ObjectPool.reparent_pooled_object(asteroid, enemy_container)


func spawn_enemy() -> void:
	if enemy_scene == null:
		push_error("Enemy scene not set!")
		return
	
	# Acquire enemy from pool
	var enemy = ObjectPool.acquire(enemy_scene)
	
	# Position on right side of screen, random height
	var spawn_x = screen_size.x + 50
	var spawn_y = randf_range(spawn_margin, screen_size.y - spawn_margin)
	enemy.position = Vector2(spawn_x, spawn_y)
	
	# Tell enemy to use world scroll (not its own horizontal movement)
	if enemy.has_method("set_use_world_scroll"):
		enemy.set_use_world_scroll(true)
	
	# Assign movement pattern based on difficulty/time (for vertical movement only)
	assign_enemy_pattern(enemy)
	
	# Connect destroyed signal (only if not already connected)
	if enemy.has_signal("destroyed") and not enemy.destroyed.is_connected(_on_enemy_destroyed):
		enemy.destroyed.connect(_on_enemy_destroyed)
	
	# Reparent to container
	ObjectPool.reparent_pooled_object(enemy, enemy_container)


func spawn_enemy_wave() -> void:
	# -------------------------------------------------------------------------
	# WAVE SPAWNING:
	# -------------------------------------------------------------------------
	# Spawns a group of enemies in a formation
	# This creates more interesting gameplay moments
	
	var wave_size = randi_range(wave_size_min, wave_size_max)
	var spawn_x = screen_size.x + 50
	
	# Choose a pattern for the whole wave
	var wave_pattern = get_random_pattern_for_difficulty()
	
	# Choose formation type
	var formation = randi() % 3  # 0=vertical line, 1=horizontal line, 2=diagonal
	
	print("Spawning wave of ", wave_size, " enemies in formation ", formation)
	
	for i in range(wave_size):
		if enemy_scene == null:
			return
		
		var enemy = ObjectPool.acquire(enemy_scene)
		
		# Position based on formation
		match formation:
			0:  # Vertical line
				var spacing = (screen_size.y - spawn_margin * 2) / (wave_size + 1)
				enemy.position = Vector2(spawn_x + i * 30, spawn_margin + spacing * (i + 1))
			
			1:  # Horizontal line (staggered entry)
				var center_y = screen_size.y / 2 + randf_range(-100, 100)
				enemy.position = Vector2(spawn_x + i * 80, center_y)
			
			2:  # Diagonal line
				var start_y = randf_range(spawn_margin, screen_size.y / 2)
				enemy.position = Vector2(spawn_x + i * 60, start_y + i * 50)
		
		# Set pattern
		if enemy.has_method("set_pattern"):
			enemy.set_pattern(wave_pattern)
		
		# Connect destroyed signal (only if not already connected)
		if enemy.has_signal("destroyed") and not enemy.destroyed.is_connected(_on_enemy_destroyed):
			enemy.destroyed.connect(_on_enemy_destroyed)
		
		# Reparent to container
		ObjectPool.reparent_pooled_object(enemy, enemy_container)


func assign_enemy_pattern(enemy: Node) -> void:
	# -------------------------------------------------------------------------
	# PATTERN ASSIGNMENT:
	# -------------------------------------------------------------------------
	# Assigns movement patterns based on how long the player has survived
	# Early game: simple patterns
	# Late game: complex patterns including homing
	
	if not enemy.has_method("set_pattern"):
		return
	
	var pattern = get_random_pattern_for_difficulty()
	enemy.set_pattern(pattern)


func get_random_pattern_for_difficulty() -> int:
	# -------------------------------------------------------------------------
	# DIFFICULTY-BASED PATTERN SELECTION:
	# -------------------------------------------------------------------------
	# Uses weighted random to select patterns
	# Weights change based on survival time
	
	# Import the enum from enemy script
	# We'll use integers matching the enum values
	const STRAIGHT = 0
	const SINE_WAVE = 1
	const DIAGONAL_DOWN = 2
	const DIAGONAL_UP = 3
	const ZIGZAG = 4
	const HOMING = 5
	const CIRCULAR = 6
	
	# Base weights (early game)
	var weights = {
		STRAIGHT: 40,
		SINE_WAVE: 30,
		DIAGONAL_DOWN: 15,
		DIAGONAL_UP: 15,
		ZIGZAG: 0,
		HOMING: 0,
		CIRCULAR: 0
	}
	
	# Unlock advanced patterns over time
	if survival_time > time_until_advanced_patterns:
		weights[STRAIGHT] = 25
		weights[SINE_WAVE] = 25
		weights[DIAGONAL_DOWN] = 15
		weights[DIAGONAL_UP] = 15
		weights[ZIGZAG] = 15
		weights[CIRCULAR] = 5
	
	# Unlock homing enemies later
	if survival_time > time_until_homing:
		weights[HOMING] = 5
		weights[ZIGZAG] = 12
		weights[CIRCULAR] = 8
	
	# Calculate total weight
	var total = 0
	for w in weights.values():
		total += w
	
	# Pick random number and find pattern
	var roll = randi() % total
	var cumulative = 0
	
	for pattern in weights:
		cumulative += weights[pattern]
		if roll < cumulative:
			return pattern
	
	return STRAIGHT  # Fallback


func clear_all_enemies() -> void:
	for enemy in enemy_container.get_children():
		enemy.queue_free()
	print("Cleared all enemies")


# ==============================================================================
# SIGNAL CALLBACKS
# ==============================================================================

func _on_player_hit() -> void:
	print("Player was hit!")
	# Camera shake on hit - bypass cooldown for damage hits
	shake_camera(12.0, true)
	
	# Flash effect
	_flash_damage()


func _on_player_collision(impact_strength: float = 0.0) -> void:
	# Camera shake based on impact strength (capped to prevent extreme shaking)
	# Intensity is in legacy pixel scale (0-15 range)
	var shake_intensity = minf(6.0 + impact_strength * 2.0, 10.0)
	shake_camera(shake_intensity)


func _on_player_weapon_fired() -> void:
	# Small screen shake for weapon recoil effect
	shake_camera(2.0)


func _flash_damage() -> void:
	# Create a brief red flash overlay
	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 90
	add_child(flash_layer)
	
	var flash = ColorRect.new()
	flash.color = Color(1, 0.2, 0.1, 0.4)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.25)
	tween.tween_callback(flash_layer.queue_free)


func _on_enemy_destroyed() -> void:
	# Could add score for enemies that pass by
	pass


func _on_asteroid_destroyed(asteroid: Asteroid) -> void:
	# Trigger screen shake based on asteroid size (explosion effect)
	# Using legacy pixel-based intensity values for consistency
	var shake_intensity: float
	
	# Adjust intensity based on asteroid size
	match asteroid.asteroid_size:
		AsteroidClass.AsteroidSize.SMALL:
			shake_intensity = 3.0   # Small explosion
		AsteroidClass.AsteroidSize.MEDIUM:
			shake_intensity = 6.0   # Medium explosion
		AsteroidClass.AsteroidSize.LARGE:
			shake_intensity = 10.5  # Large explosion
		_:
			# Unknown size - default to medium intensity
			shake_intensity = 6.0
	
	# Trigger shake for explosion
	shake_camera(shake_intensity)


func _on_game_over() -> void:
	print("=== GAME OVER ===")
	spawn_timer.stop()
	game_over_screen.visible = true


func _on_game_reset() -> void:
	print("Game reset")
	clear_all_enemies()
	game_over_screen.visible = false
	spawn_timer.wait_time = spawn_interval
	survival_time = 0.0


# ==============================================================================
# PUBLIC FUNCTIONS
# ==============================================================================

func restart_game() -> void:
	print("Restarting game...")
	get_tree().paused = false
	
	if game_manager:
		game_manager.reset_game()
	
	start_game()


func quit_to_menu() -> void:
	get_tree().reload_current_scene()
