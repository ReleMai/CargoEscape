# ==============================================================================
# ENEMY SPAWNER - STATION-BASED ENEMY SPAWNING SYSTEM
# ==============================================================================
#
# FILE: scripts/enemies/enemy_spawner.gd
# PURPOSE: Spawns enemies based on current station data configuration
#
# FEATURES:
# - Reads from StationData resource for enemy types
# - Handles asteroid fields with size distribution
# - Supports wave spawning patterns
# - Difficulty scaling over time
#
# ==============================================================================

extends Node
class_name EnemySpawner


# ==============================================================================
# SIGNALS
# ==============================================================================

signal enemy_spawned(enemy: Node2D)
signal wave_spawned(enemies: Array[Node2D])


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Station Configuration")
## Current station data (determines enemy types)
@export var station_data: StationData

@export_group("Spawn Settings")
## Container to spawn enemies into
@export var enemy_container: Node2D

## Screen size for spawn positioning
@export var screen_size: Vector2 = Vector2(1920, 1080)

## Margin from screen edges
@export var spawn_margin: float = 60.0


@export_group("Wave Spawning")
## Chance to spawn a wave instead of single enemy
@export_range(0.0, 0.5, 0.05) var wave_chance: float = 0.15

## Enemies per wave
@export var wave_size_min: int = 3
@export var wave_size_max: int = 6


# ==============================================================================
# STATE
# ==============================================================================

var spawn_timer: Timer
var current_interval: float
var time_elapsed: float = 0.0
var is_spawning: bool = false


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Create spawn timer
	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timeout)
	add_child(spawn_timer)


func _process(delta: float) -> void:
	if is_spawning:
		time_elapsed += delta
		_update_difficulty()


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Start spawning with given station configuration
func start_spawning(data: StationData) -> void:
	station_data = data
	time_elapsed = 0.0
	
	if station_data:
		current_interval = station_data.base_spawn_interval
		spawn_timer.wait_time = current_interval
		spawn_timer.start()
		is_spawning = true
		print("[Spawner] Started spawning for: ", station_data.station_name)
	else:
		push_warning("[Spawner] No station data provided!")


## Stop spawning enemies
func stop_spawning() -> void:
	spawn_timer.stop()
	is_spawning = false


## Clear all spawned enemies
func clear_enemies() -> void:
	if enemy_container:
		for child in enemy_container.get_children():
			child.queue_free()


## Configure spawn position boundaries
func set_screen_size(size: Vector2) -> void:
	screen_size = size


# ==============================================================================
# SPAWNING LOGIC
# ==============================================================================

func _on_spawn_timeout() -> void:
	if not station_data or not enemy_container:
		return
	
	# Decide: single spawn or wave?
	if randf() < wave_chance:
		_spawn_wave()
	else:
		_spawn_single()


func _spawn_single() -> void:
	var enemy := _create_enemy()
	if enemy:
		_position_enemy(enemy)
		enemy_container.add_child(enemy)
		enemy_spawned.emit(enemy)


func _spawn_wave() -> void:
	var wave_size := randi_range(wave_size_min, wave_size_max)
	var enemies: Array[Node2D] = []
	
	# Calculate vertical spacing for wave
	var available_height := screen_size.y - (spawn_margin * 2)
	var spacing := available_height / (wave_size + 1)
	
	for i in wave_size:
		var enemy := _create_enemy()
		if enemy:
			# Position in a line formation
			var y_pos := spawn_margin + spacing * (i + 1)
			enemy.position = Vector2(screen_size.x + 50 + (i * 30), y_pos)
			enemy_container.add_child(enemy)
			enemies.append(enemy)
	
	wave_spawned.emit(enemies)


func _create_enemy() -> Node2D:
	match station_data.station_type:
		StationData.StationType.ABANDONED:
			return _create_asteroid()
		_:
			# Default to primary enemy scene
			if station_data.primary_enemy_scene:
				return station_data.primary_enemy_scene.instantiate()
	
	return null


func _create_asteroid() -> Node2D:
	var asteroid_scene := preload("res://scenes/enemies/asteroid.tscn")
	var asteroid: Asteroid = asteroid_scene.instantiate()
	
	# Set random size based on weights
	var size_index := station_data.get_random_asteroid_size()
	asteroid.asteroid_size = size_index as Asteroid.AsteroidSize
	
	return asteroid


func _position_enemy(enemy: Node2D) -> void:
	# Spawn just off the right side of the screen
	var x_pos := screen_size.x + 100
	
	# Random Y position within margins
	var y_pos := randf_range(spawn_margin, screen_size.y - spawn_margin)
	
	enemy.position = Vector2(x_pos, y_pos)


# ==============================================================================
# DIFFICULTY
# ==============================================================================

func _update_difficulty() -> void:
	if not station_data:
		return
	
	# Gradually decrease spawn interval
	var new_interval := station_data.base_spawn_interval - (time_elapsed * station_data.difficulty_ramp_rate)
	new_interval = maxf(new_interval, station_data.min_spawn_interval)
	
	if absf(new_interval - current_interval) > 0.1:
		current_interval = new_interval
		spawn_timer.wait_time = current_interval


# ==============================================================================
# PATTERN SPAWNING (Advanced)
# ==============================================================================

## Spawn a cluster of asteroids
func spawn_asteroid_cluster(center: Vector2, count: int, spread: float) -> void:
	var asteroid_scene := preload("res://scenes/enemies/asteroid.tscn")
	
	for i in count:
		var asteroid: Asteroid = asteroid_scene.instantiate()
		asteroid.asteroid_size = Asteroid.AsteroidSize.SMALL
		
		var offset := Vector2(
			randf_range(-spread, spread),
			randf_range(-spread, spread)
		)
		asteroid.position = center + offset
		
		enemy_container.add_child(asteroid)


## Spawn enemies in a V formation
func spawn_v_formation(tip_position: Vector2, count: int, spacing: float) -> void:
	if not station_data or not station_data.primary_enemy_scene:
		return
	
	for i in count:
		var enemy := station_data.primary_enemy_scene.instantiate()
		var row := i / 2
		var side := 1 if i % 2 == 0 else -1
		
		var offset := Vector2(row * spacing, row * spacing * side * 0.5)
		enemy.position = tip_position + offset
		
		enemy_container.add_child(enemy)
