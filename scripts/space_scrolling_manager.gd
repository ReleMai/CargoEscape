# ==============================================================================
# SPACE SCROLLING MANAGER - SIDE-SCROLLER WORLD CONTROLLER
# ==============================================================================
#
# FILE: scripts/space_scrolling_manager.gd
# PURPOSE: Manages the scrolling world, spawning, and progression during escape
#
# ARCHITECTURE:
# -------------
# This manager creates a side-scroller feel where:
# - The "world" scrolls toward the player (from right to left)
# - Obstacles spawn on the right and move left
# - Background parallax scrolls to enhance motion
# - Player stays roughly in place horizontally but can dodge vertically
# - Distance traveled determines progress toward the goal
#
# SPAWNING SYSTEM:
# ----------------
# Different obstacle types spawn based on distance/time:
# - DEBRIS: Small, fast, simple to dodge
# - CARGO: Medium, predictable patterns
# - ASTEROIDS: Large, slow, need careful positioning
# - ENERGY_FIELDS: Horizontal barriers, require timing
#
# ==============================================================================

extends Node2D
class_name SpaceScrollingManager


# ==============================================================================
# SIGNALS
# ==============================================================================

## Emitted when player reaches the destination
signal destination_reached(distance_traveled: float, score: int)

## Emitted when distance milestone is hit
signal distance_milestone(distance: float)

## Emitted when player takes damage from obstacle
signal player_hit(obstacle_type: String)

## Emitted for UI updates
signal progress_updated(current: float, total: float)


# ==============================================================================
# ENUMS
# ==============================================================================

## Types of obstacles that can spawn
enum ObstacleType {
	DEBRIS,        ## Small, fast moving debris
	CARGO,         ## Medium cargo containers
	ASTEROID,      ## Large asteroids
	ENERGY_FIELD   ## Horizontal barrier zones
}

## Difficulty stages
enum DifficultyStage {
	EASY,      ## First 20% - sparse, simple
	NORMAL,    ## 20-50% - moderate density
	HARD,      ## 50-80% - dense, mixed patterns
	INTENSE    ## 80-100% - everything at once
}


# ==============================================================================
# EXPORTS - SCROLLING
# ==============================================================================

@export_group("World Scrolling")

## Base scroll speed (pixels/second) - how fast obstacles come toward player
@export_range(100.0, 500.0, 25.0) var base_scroll_speed: float = 200.0

## Maximum scroll speed at highest difficulty
@export_range(200.0, 800.0, 25.0) var max_scroll_speed: float = 400.0

## Current scroll speed multiplier (for speed power-ups etc)
@export var scroll_speed_multiplier: float = 1.0


@export_group("Distance & Progress")

## Total distance to travel to reach station (pixels)
## At 200 px/s, 60000 pixels = 5 minutes
@export var destination_distance: float = 60000.0

## Distance between milestone notifications
@export var milestone_interval: float = 10000.0


@export_group("Spawning - Timing")

## Base time between spawns (seconds)
@export_range(0.5, 3.0, 0.1) var base_spawn_interval: float = 1.5

## Minimum spawn interval at maximum difficulty
@export_range(0.2, 1.0, 0.1) var min_spawn_interval: float = 0.4

## Spawn interval randomization (+/- this amount)
@export_range(0.0, 1.0, 0.1) var spawn_interval_variance: float = 0.3


@export_group("Spawning - Positions")

## Horizontal position where obstacles spawn (off screen right)
@export var spawn_x_offset: float = 100.0

## Vertical margin from screen edges for spawning
@export var spawn_margin: float = 50.0


@export_group("Obstacle Scenes")

## Scene for debris obstacles
@export var debris_scene: PackedScene

## Scene for cargo obstacles  
@export var cargo_scene: PackedScene

## Scene for asteroid obstacles
@export var asteroid_scene: PackedScene

## Scene for energy field obstacles
@export var energy_field_scene: PackedScene


# ==============================================================================
# STATE VARIABLES
# ==============================================================================

## Current scroll speed (base * multiplier * difficulty)
var current_scroll_speed: float = 0.0

## Total distance traveled
var distance_traveled: float = 0.0

## Last milestone hit
var last_milestone: float = 0.0

## Current difficulty stage
var current_difficulty: DifficultyStage = DifficultyStage.EASY

## Is the escape phase active?
var is_active: bool = false

## Screen dimensions
var screen_size: Vector2 = Vector2.ZERO

## Spawn timer
var spawn_timer: float = 0.0

## Current spawn interval
var current_spawn_interval: float = 1.5

## Container for spawned obstacles
var obstacle_container: Node2D = null


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
	# Create obstacle container if not exists
	obstacle_container = get_node_or_null("ObstacleContainer")
	if not obstacle_container:
		obstacle_container = Node2D.new()
		obstacle_container.name = "ObstacleContainer"
		add_child(obstacle_container)
	
	# Initialize spawn interval
	current_spawn_interval = base_spawn_interval


func _process(delta: float) -> void:
	if not is_active:
		return
	
	# Update scroll speed based on difficulty
	_update_scroll_speed()
	
	# Update distance traveled
	distance_traveled += current_scroll_speed * delta
	
	# Emit progress updates
	progress_updated.emit(distance_traveled, destination_distance)
	
	# Check for milestones
	_check_milestones()
	
	# Check for destination
	if distance_traveled >= destination_distance:
		_reach_destination()
		return
	
	# Update difficulty based on progress
	_update_difficulty()
	
	# Handle spawning
	_process_spawning(delta)
	
	# Move all obstacles
	_move_obstacles(delta)
	
	# Clean up off-screen obstacles
	_cleanup_obstacles()


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Start the escape phase
func start_escape() -> void:
	is_active = true
	distance_traveled = 0.0
	last_milestone = 0.0
	current_difficulty = DifficultyStage.EASY
	current_spawn_interval = base_spawn_interval
	spawn_timer = 0.0
	
	# Clear any existing obstacles
	clear_all_obstacles()
	
	print("[ScrollManager] Escape started! Destination: %.0f pixels" % destination_distance)


## Stop the escape phase
func stop_escape() -> void:
	is_active = false
	print("[ScrollManager] Escape stopped at distance: %.0f" % distance_traveled)


## Clear all obstacles
func clear_all_obstacles() -> void:
	if obstacle_container:
		for child in obstacle_container.get_children():
			child.queue_free()


## Get current progress percentage (0-1)
func get_progress() -> float:
	return clampf(distance_traveled / destination_distance, 0.0, 1.0)


## Get current scroll speed
func get_scroll_speed() -> float:
	return current_scroll_speed


# ==============================================================================
# SCROLL SPEED MANAGEMENT
# ==============================================================================

func _update_scroll_speed() -> void:
	# Calculate difficulty multiplier (increases over distance)
	var progress := get_progress()
	var difficulty_mult := lerpf(1.0, max_scroll_speed / base_scroll_speed, progress)
	
	# Apply all multipliers
	current_scroll_speed = base_scroll_speed * scroll_speed_multiplier * difficulty_mult
	current_scroll_speed = minf(current_scroll_speed, max_scroll_speed)


# ==============================================================================
# DISTANCE & MILESTONES
# ==============================================================================

func _check_milestones() -> void:
	var next_milestone := last_milestone + milestone_interval
	
	if distance_traveled >= next_milestone:
		last_milestone = next_milestone
		distance_milestone.emit(next_milestone)
		print("[ScrollManager] Milestone: %.0f / %.0f" % [next_milestone, destination_distance])


func _reach_destination() -> void:
	is_active = false
	
	var game_manager := _get_game_manager()
	var score := 0
	if game_manager and game_manager.has_method("get_score"):
		score = game_manager.get_score()
	
	destination_reached.emit(distance_traveled, score)
	print("[ScrollManager] DESTINATION REACHED!")


# ==============================================================================
# DIFFICULTY SCALING
# ==============================================================================

func _update_difficulty() -> void:
	var progress := get_progress()
	var new_difficulty: DifficultyStage
	
	if progress < 0.2:
		new_difficulty = DifficultyStage.EASY
	elif progress < 0.5:
		new_difficulty = DifficultyStage.NORMAL
	elif progress < 0.8:
		new_difficulty = DifficultyStage.HARD
	else:
		new_difficulty = DifficultyStage.INTENSE
	
	if new_difficulty != current_difficulty:
		current_difficulty = new_difficulty
		_on_difficulty_changed()


func _on_difficulty_changed() -> void:
	# Adjust spawn interval based on difficulty
	match current_difficulty:
		DifficultyStage.EASY:
			current_spawn_interval = base_spawn_interval
		DifficultyStage.NORMAL:
			current_spawn_interval = lerpf(base_spawn_interval, min_spawn_interval, 0.33)
		DifficultyStage.HARD:
			current_spawn_interval = lerpf(base_spawn_interval, min_spawn_interval, 0.66)
		DifficultyStage.INTENSE:
			current_spawn_interval = min_spawn_interval
	
	print("[ScrollManager] Difficulty: %s, Spawn Interval: %.2f" % [
		DifficultyStage.keys()[current_difficulty], 
		current_spawn_interval
	])


# ==============================================================================
# OBSTACLE SPAWNING
# ==============================================================================

func _process_spawning(delta: float) -> void:
	spawn_timer += delta
	
	# Add variance to spawn timing
	var actual_interval := current_spawn_interval + randf_range(
		-spawn_interval_variance, 
		spawn_interval_variance
	)
	
	if spawn_timer >= actual_interval:
		spawn_timer = 0.0
		_spawn_obstacle()


func _spawn_obstacle() -> void:
	# Choose obstacle type based on difficulty
	var obstacle_type := _choose_obstacle_type()
	var obstacle := _create_obstacle(obstacle_type)
	
	if not obstacle:
		return
	
	# Position off-screen right
	var spawn_x := screen_size.x + spawn_x_offset
	var spawn_y := randf_range(spawn_margin, screen_size.y - spawn_margin)
	
	obstacle.position = Vector2(spawn_x, spawn_y)
	
	# Add custom data
	if obstacle.has_method("set_scroll_speed"):
		obstacle.set_scroll_speed(current_scroll_speed)
	
	# Store obstacle type for hit detection
	obstacle.set_meta("obstacle_type", ObstacleType.keys()[obstacle_type])
	
	obstacle_container.add_child(obstacle)


func _choose_obstacle_type() -> ObstacleType:
	# Weight-based selection depending on difficulty
	var weights: Dictionary = {}
	
	match current_difficulty:
		DifficultyStage.EASY:
			weights = {
				ObstacleType.DEBRIS: 60,
				ObstacleType.CARGO: 30,
				ObstacleType.ASTEROID: 10,
				ObstacleType.ENERGY_FIELD: 0
			}
		DifficultyStage.NORMAL:
			weights = {
				ObstacleType.DEBRIS: 40,
				ObstacleType.CARGO: 35,
				ObstacleType.ASTEROID: 20,
				ObstacleType.ENERGY_FIELD: 5
			}
		DifficultyStage.HARD:
			weights = {
				ObstacleType.DEBRIS: 30,
				ObstacleType.CARGO: 30,
				ObstacleType.ASTEROID: 25,
				ObstacleType.ENERGY_FIELD: 15
			}
		DifficultyStage.INTENSE:
			weights = {
				ObstacleType.DEBRIS: 25,
				ObstacleType.CARGO: 25,
				ObstacleType.ASTEROID: 25,
				ObstacleType.ENERGY_FIELD: 25
			}
	
	# Weighted random selection
	var total := 0
	for w in weights.values():
		total += w
	
	var roll := randi() % total
	var cumulative := 0
	
	for obstacle_type in weights:
		cumulative += weights[obstacle_type]
		if roll < cumulative:
			return obstacle_type
	
	return ObstacleType.DEBRIS


func _create_obstacle(type: ObstacleType) -> Node2D:
	var scene: PackedScene = null
	
	match type:
		ObstacleType.DEBRIS:
			scene = debris_scene
		ObstacleType.CARGO:
			scene = cargo_scene
		ObstacleType.ASTEROID:
			scene = asteroid_scene
		ObstacleType.ENERGY_FIELD:
			scene = energy_field_scene
	
	# Fallback to cargo_scene (which is likely the enemy_scene)
	if not scene:
		scene = cargo_scene
	
	if not scene:
		push_warning("[ScrollManager] No obstacle scene available for type: %s" % type)
		return null
	
	return scene.instantiate()


# ==============================================================================
# OBSTACLE MOVEMENT
# ==============================================================================

func _move_obstacles(delta: float) -> void:
	if not obstacle_container:
		return
	
	for obstacle in obstacle_container.get_children():
		# Move obstacle left at scroll speed
		# Individual obstacles can have their own speed modifiers
		var speed := current_scroll_speed
		
		if obstacle.has_method("get_speed_modifier"):
			speed *= obstacle.get_speed_modifier()
		
		obstacle.position.x -= speed * delta
		
		# Let obstacle handle its own vertical movement if it wants
		if obstacle.has_method("update_movement"):
			obstacle.update_movement(delta)


func _cleanup_obstacles() -> void:
	if not obstacle_container:
		return
	
	var cleanup_x := -200.0  # Remove when this far off left side
	
	for obstacle in obstacle_container.get_children():
		if obstacle.position.x < cleanup_x:
			obstacle.queue_free()


# ==============================================================================
# UTILITY
# ==============================================================================

func _get_game_manager() -> Node:
	if has_node("/root/GameManager"):
		return get_node("/root/GameManager")
	return null
