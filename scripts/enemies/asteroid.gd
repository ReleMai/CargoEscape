# ==============================================================================
# ASTEROID OBSTACLE - PROCEDURAL SPACE ROCK
# ==============================================================================
#
# FILE: scripts/enemies/asteroid.gd
# PURPOSE: Asteroid obstacle that spawns in abandoned station escape sequences
#
# FEATURES:
# - Procedurally drawn asteroid shape (no external assets needed)
# - Various sizes (small, medium, large)
# - Tumbling rotation animation
# - Different shades for visual variety
# - Breakable with health system
#
# ==============================================================================

extends Area2D
class_name Asteroid


# ==============================================================================
# ENUMS
# ==============================================================================

enum AsteroidSize {
	SMALL,    # Fast, low health
	MEDIUM,   # Balanced
	LARGE     # Slow, high health
}


# ==============================================================================
# SIGNALS
# ==============================================================================

signal destroyed


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Asteroid Properties")
## Size category of the asteroid
@export var asteroid_size: AsteroidSize = AsteroidSize.MEDIUM

## Base movement speed (modified by size)
@export var base_speed: float = 150.0

## Random speed variation
@export var speed_variation: float = 50.0

## Rotation speed (visual tumbling)
@export var rotation_speed: float = 0.5

## Base damage dealt to player on collision
@export var collision_damage: float = 10.0


@export_group("Health")
## Maximum health (adjusted by size)
@export var base_health: float = 30.0


@export_group("Visuals")
## Number of vertices for the asteroid shape
@export_range(6, 16, 1) var vertex_count: int = 10

## Irregularity factor (0 = circle, 1 = very jagged)
@export_range(0.0, 0.5, 0.05) var irregularity: float = 0.25


# ==============================================================================
# STATE VARIABLES
# ==============================================================================

var current_health: float
var actual_speed: float
var screen_size: Vector2

## Generated polygon points for drawing
var polygon_points: PackedVector2Array

## Asteroid base radius (depends on size)
var radius: float

## Color variations
var base_color: Color
var highlight_color: Color
var shadow_color: Color

## Random seed for consistent shape
var shape_seed: int

## Counter for generating unique seeds (incremented atomically)
## Note: This is currently single-threaded safe. If multi-threading is needed,
## wrap access with a mutex lock.
static var _seed_counter: int = 0


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
	# Set random seed for this asteroid
	shape_seed = randi()
	
	# Configure based on size
	_configure_by_size()
	
	# Generate the asteroid shape
	_generate_shape()
	
	# Set initial rotation randomly
	rotation = randf() * TAU
	
	# Randomize rotation direction
	if randf() > 0.5:
		rotation_speed *= -1
	
	# Calculate actual speed with variation
	actual_speed = base_speed + randf_range(-speed_variation, speed_variation)
	
	# Connect to body entered for collision detection
	body_entered.connect(_on_body_entered)
	
	# Request redraw
	queue_redraw()


func _process(delta: float) -> void:
	# Tumble rotation
	rotation += rotation_speed * delta
	
	# Movement is handled by main.gd scroll system
	# We just need to handle cleanup
	if position.x < -radius * 2:
		ObjectPool.release(self)


func _draw() -> void:
	# Draw shadow layer (slightly offset)
	var _shadow_offset := Vector2(3, 3)
	draw_polygon(polygon_points, [shadow_color])
	
	# Draw base asteroid
	draw_polygon(polygon_points, [base_color])
	
	# Draw crater details
	_draw_craters()
	
	# Draw highlight edge (top-left lighting)
	_draw_highlight_edge()


# ==============================================================================
# CONFIGURATION
# ==============================================================================

func _configure_by_size() -> void:
	match asteroid_size:
		AsteroidSize.SMALL:
			radius = randf_range(15, 25)
			current_health = base_health * 0.5
			base_speed *= 1.3
			collision_damage *= 0.5
			rotation_speed *= 1.5
		AsteroidSize.MEDIUM:
			radius = randf_range(30, 45)
			current_health = base_health
			# Default values
		AsteroidSize.LARGE:
			radius = randf_range(50, 70)
			current_health = base_health * 2.0
			base_speed *= 0.7
			collision_damage *= 1.5
			rotation_speed *= 0.6
	
	# Set up collision shape
	if collision_shape:
		var circle = CircleShape2D.new()
		circle.radius = radius * 0.85  # Slightly smaller for fair gameplay
		collision_shape.shape = circle
	
	# Generate color palette
	_generate_colors()


func _generate_colors() -> void:
	# Asteroid gray/brown variations
	var base_hue := randf_range(0.05, 0.12)  # Brown to gray range
	var base_sat := randf_range(0.1, 0.3)
	var base_val := randf_range(0.3, 0.5)
	
	base_color = Color.from_hsv(base_hue, base_sat, base_val)
	highlight_color = Color.from_hsv(base_hue, base_sat * 0.7, base_val * 1.4)
	shadow_color = Color.from_hsv(base_hue, base_sat * 1.2, base_val * 0.5)


func _generate_shape() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed
	
	polygon_points.clear()
	
	var angle_step := TAU / vertex_count
	
	for i in vertex_count:
		var angle := i * angle_step
		# Add irregularity to radius
		var r := radius * (1.0 + rng.randf_range(-irregularity, irregularity))
		var point := Vector2(cos(angle), sin(angle)) * r
		polygon_points.append(point)


func _draw_craters() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = shape_seed + 100  # Different seed for craters
	
	var crater_count := int(radius / 15) + 1
	var crater_color := shadow_color.darkened(0.2)
	
	for i in crater_count:
		# Random position within asteroid
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(0.2, 0.6) * radius
		var pos := Vector2(cos(angle), sin(angle)) * dist
		
		# Random crater size
		var crater_radius := rng.randf_range(radius * 0.1, radius * 0.25)
		
		# Draw crater as ellipse
		draw_circle(pos, crater_radius, crater_color)
		
		# Inner highlight (rim lighting)
		var _inner_pos := pos + Vector2(-crater_radius * 0.3, -crater_radius * 0.3)
		draw_arc(pos, crater_radius * 0.8, PI * 0.8, PI * 1.5, 8, highlight_color.darkened(0.3), 1.5)


func _draw_highlight_edge() -> void:
	# Draw a subtle highlight on the upper-left edge
	var highlight_points: PackedVector2Array = []
	
	for i in range(int(vertex_count / 4.0), int(vertex_count / 2.0)):
		highlight_points.append(polygon_points[i])
	
	if highlight_points.size() > 1:
		draw_polyline(highlight_points, highlight_color, 2.0, true)


# ==============================================================================
# DAMAGE SYSTEM
# ==============================================================================

func take_damage(damage: float) -> void:
	current_health -= damage
	
	# Visual feedback - flash white briefly
	modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.05)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.1)
	
	if current_health <= 0:
		_die()


func _die() -> void:
	destroyed.emit()
	
	# Spawn smaller asteroids if large enough
	if asteroid_size == AsteroidSize.LARGE:
		_spawn_debris(2, AsteroidSize.MEDIUM)
	elif asteroid_size == AsteroidSize.MEDIUM:
		_spawn_debris(2, AsteroidSize.SMALL)
	
	ObjectPool.release(self)


func _spawn_debris(count: int, size: AsteroidSize) -> void:
	var parent := get_parent()
	if not parent:
		return
	
	# Use asteroid scene for pooling
	var asteroid_scene := preload("res://scenes/enemies/asteroid.tscn")
	
	for i in count:
		var debris: Asteroid = ObjectPool.acquire(asteroid_scene)
		debris.asteroid_size = size
		debris.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		
		# Reparent to scene
		ObjectPool.reparent_pooled_object(debris, parent)


# ==============================================================================
# COLLISION
# ==============================================================================

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(collision_damage)


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func get_collision_damage() -> float:
	return collision_damage


## Set asteroid size and reconfigure
func set_size(size: AsteroidSize) -> void:
	asteroid_size = size
	if is_inside_tree():
		_configure_by_size()
		_generate_shape()
		queue_redraw()


## Reset the asteroid for object pooling
func reset() -> void:
	# Reset health based on current size
	_configure_by_size()
	
	# Generate unique shape seed for visual variety
	_seed_counter += 1
	shape_seed = Time.get_ticks_msec() + _seed_counter
	_generate_shape()
	
	# Reset visual
	rotation = randf() * TAU
	modulate = Color.WHITE
	
	# Randomize rotation direction
	if randf() > 0.5:
		rotation_speed = -abs(rotation_speed)
	else:
		rotation_speed = abs(rotation_speed)
	
	# Recalculate speed
	actual_speed = base_speed + randf_range(-speed_variation, speed_variation)
	
	# Ensure signal is connected
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Request redraw
	queue_redraw()
