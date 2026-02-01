# ==============================================================================
# BACKGROUND PARALLAX SCROLLING SCRIPT - ENHANCED FOR SIDE-SCROLLER
# ==============================================================================
# 
# FILE: scripts/background.gd
# PURPOSE: Creates a scrolling space background with parallax effect
#
# WHAT IS PARALLAX?
# -----------------
# Parallax is an effect where distant objects appear to move slower than
# close objects. This creates an illusion of depth and makes 2D games
# feel more dynamic.
#
# Example:
# - Far stars (back layer): Move slowly
# - Medium stars: Move at medium speed
# - Close stars/nebulae (front layer): Move fast
#
# LAYER SYSTEM:
# -------------
# Layer 1 (Back)  - Distant stars, barely moving  (0.3x speed)
# Layer 2 (Mid)   - Medium stars, moderate speed  (0.6x speed)
# Layer 3 (Front) - Close particles, fast         (1.0x speed)
# Layer 4 (Near)  - Floating debris, very fast    (1.5x speed)
#
# PROCEDURAL GENERATION:
# ----------------------
# Stars are generated procedurally as colored dots/particles.
# This means we don't need texture files - everything is code!
#
# ==============================================================================

extends Node2D


# ==============================================================================
# EXPORTED VARIABLES
# ==============================================================================

@export_group("Scroll Speed")

## Base scroll speed (pixels per second)
@export var base_scroll_speed: float = 100.0

## Speed multipliers for each layer (back to front)
@export var layer_speed_multipliers: Array[float] = [0.3, 0.6, 1.0, 1.5]

## Should the background scroll automatically?
@export var auto_scroll: bool = true


@export_group("Star Generation")

## Number of stars per layer
@export var stars_per_layer: Array[int] = [50, 80, 40, 20]

## Star sizes for each layer (min, max)
@export var star_size_ranges: Array[Vector2] = [
	Vector2(1, 2),   # Back - tiny dots
	Vector2(1, 3),   # Mid - small dots
	Vector2(2, 4),   # Front - medium dots
	Vector2(3, 6)    # Near - larger particles
]

## Base colors for stars (can add variety)
@export var star_colors: Array[Color] = [
	Color(0.8, 0.8, 1.0, 0.5),   # Back - dim blue-white
	Color(0.9, 0.9, 1.0, 0.7),   # Mid - brighter
	Color(1.0, 1.0, 1.0, 0.9),   # Front - bright white
	Color(0.7, 0.7, 0.8, 0.8)    # Near - debris gray
]


@export_group("Special Effects")

## Enable occasional shooting stars
@export var enable_shooting_stars: bool = true

## Average time between shooting stars (seconds)
@export var shooting_star_interval: float = 8.0

## Enable nebula clouds (colored regions)
@export var enable_nebula: bool = true


# ==============================================================================
# INTERNAL STATE
# ==============================================================================

## Screen dimensions
var screen_size: Vector2

## Star data for each layer: Array[Array[Dictionary]]
## Each star: {position: Vector2, size: float, color: Color, alpha: float}
var star_layers: Array[Array[Dictionary]] = []

## External scroll speed (set by game manager)
var external_scroll_speed: float = 0.0

## Use external speed instead of auto_scroll
var use_external_speed: bool = false

## Shooting star data
var shooting_star: Dictionary = {}
var shooting_star_timer: float = 0.0


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
	# Generate stars for all layers
	_generate_all_stars()
	
	# Setup first shooting star timer
	if enable_shooting_stars:
		shooting_star_timer = randf_range(2.0, shooting_star_interval)
	
	# Queue redraw
	queue_redraw()


func _process(delta: float) -> void:
	var active_speed: float
	
	if use_external_speed:
		active_speed = external_scroll_speed
	elif auto_scroll:
		active_speed = base_scroll_speed
	else:
		return
	
	# Scroll each layer at different speeds
	_scroll_layers(delta, active_speed)
	
	# Update shooting stars
	if enable_shooting_stars:
		_update_shooting_stars(delta)
	
	# Redraw
	queue_redraw()


func _draw() -> void:
	# Draw base color (dark space)
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.02, 0.02, 0.06, 1.0))
	
	# Draw nebula if enabled
	if enable_nebula:
		_draw_nebula()
	
	# Draw all star layers (back to front)
	for layer_index in range(star_layers.size()):
		_draw_star_layer(layer_index)
	
	# Draw shooting star
	if shooting_star.has("active") and shooting_star.active:
		_draw_shooting_star()


# ==============================================================================
# STAR GENERATION
# ==============================================================================

func _generate_all_stars() -> void:
	star_layers.clear()
	
	for layer_index in range(stars_per_layer.size()):
		var layer_stars: Array[Dictionary] = []
		var count := stars_per_layer[layer_index]
		var default_size := Vector2(1, 3)
		var size_range: Vector2
		if layer_index < star_size_ranges.size():
			size_range = star_size_ranges[layer_index]
		else:
			size_range = default_size
		
		var base_color: Color
		if layer_index < star_colors.size():
			base_color = star_colors[layer_index]
		else:
			base_color = Color.WHITE
		
		for star_index in range(count):
			var _unused := star_index  # Silence unused warning
			var star := {
				"position": Vector2(
					randf_range(0, screen_size.x * 2),  # Double width for seamless wrap
					randf_range(0, screen_size.y)
				),
				"size": randf_range(size_range.x, size_range.y),
				"color": _vary_color(base_color),
				"twinkle_offset": randf() * TAU  # For twinkling effect
			}
			layer_stars.append(star)
		
		star_layers.append(layer_stars)


func _vary_color(base: Color) -> Color:
	# Add slight random variation to color
	return Color(
		clampf(base.r + randf_range(-0.1, 0.1), 0, 1),
		clampf(base.g + randf_range(-0.1, 0.1), 0, 1),
		clampf(base.b + randf_range(-0.1, 0.1), 0, 1),
		base.a
	)


# ==============================================================================
# SCROLLING
# ==============================================================================

func _scroll_layers(delta: float, speed: float) -> void:
	for layer_index in range(star_layers.size()):
		var layer_speed := speed * _get_layer_speed_mult(layer_index)
		
		for star in star_layers[layer_index]:
			# Move star left
			star.position.x -= layer_speed * delta
			
			# Wrap around when off-screen left
			if star.position.x < -20:
				star.position.x = screen_size.x + randf_range(10, 100)
				star.position.y = randf_range(0, screen_size.y)


func _get_layer_speed_mult(layer_index: int) -> float:
	if layer_index < layer_speed_multipliers.size():
		return layer_speed_multipliers[layer_index]
	return 1.0


# ==============================================================================
# DRAWING
# ==============================================================================

func _draw_star_layer(layer_index: int) -> void:
	if layer_index >= star_layers.size():
		return
	
	var time := Time.get_ticks_msec() / 1000.0
	
	for star in star_layers[layer_index]:
		var pos: Vector2 = star.position
		
		# Skip if off-screen
		if pos.x < -20 or pos.x > screen_size.x + 20:
			continue
		
		# Calculate twinkle alpha
		var twinkle := (sin(time * 2.0 + star.twinkle_offset) + 1.0) * 0.5
		var alpha: float = star.color.a * lerpf(0.7, 1.0, twinkle)
		
		var color := Color(star.color.r, star.color.g, star.color.b, alpha)
		var size: float = star.size
		
		# Draw star as circle
		draw_circle(pos, size, color)
		
		# Add slight glow for larger stars
		if size > 3:
			var glow_color := Color(color.r, color.g, color.b, alpha * 0.3)
			draw_circle(pos, size * 1.5, glow_color)


func _draw_nebula() -> void:
	# Draw a subtle nebula effect using large transparent circles
	# This is very simple - you could enhance with gradient textures
	var nebula_color1 := Color(0.2, 0.1, 0.3, 0.1)
	var nebula_color2 := Color(0.1, 0.15, 0.25, 0.08)
	
	# Fixed nebula positions (these could scroll too)
	draw_circle(Vector2(screen_size.x * 0.2, screen_size.y * 0.3), 200, nebula_color1)
	draw_circle(Vector2(screen_size.x * 0.7, screen_size.y * 0.6), 250, nebula_color2)
	draw_circle(Vector2(screen_size.x * 0.5, screen_size.y * 0.8), 180, nebula_color1)


# ==============================================================================
# SHOOTING STARS
# ==============================================================================

func _update_shooting_stars(delta: float) -> void:
	shooting_star_timer -= delta
	
	if shooting_star_timer <= 0:
		_spawn_shooting_star()
		var min_interval := shooting_star_interval * 0.5
		var max_interval := shooting_star_interval * 1.5
		shooting_star_timer = randf_range(min_interval, max_interval)
	
	# Update active shooting star
	if shooting_star.has("active") and shooting_star.active:
		shooting_star.progress += delta * shooting_star.speed
		
		if shooting_star.progress >= 1.0:
			shooting_star.active = false


func _spawn_shooting_star() -> void:
	shooting_star = {
		"active": true,
		"start": Vector2(
			randf_range(screen_size.x * 0.3, screen_size.x),
			randf_range(0, screen_size.y * 0.5)
		),
		"angle": randf_range(PI * 0.6, PI * 0.8),  # Downward-left direction
		"length": randf_range(50, 150),
		"speed": randf_range(0.5, 1.5),
		"progress": 0.0,
		"color": Color(1, 1, 1, 0.8)
	}


func _draw_shooting_star() -> void:
	if not shooting_star.active:
		return
	
	var start: Vector2 = shooting_star.start
	var angle: float = shooting_star.angle
	var length: float = shooting_star.length
	var progress: float = shooting_star.progress
	
	# Calculate current position
	var total_distance := screen_size.x * 0.5
	var current_pos := start + Vector2.from_angle(angle) * total_distance * progress
	
	# Calculate tail
	var tail_pos := current_pos - Vector2.from_angle(angle) * length
	
	# Fade out near end
	var alpha := 1.0 - progress
	var color := Color(1, 1, 1, alpha * 0.8)
	var _tail_color := Color(1, 1, 1, 0)  # Reserved for future gradient
	
	# Draw line with gradient (simple version)
	draw_line(tail_pos, current_pos, color, 2.0)
	
	# Draw bright head
	draw_circle(current_pos, 3, Color(1, 1, 1, alpha))


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Set scroll speed from external source (like game manager)
func set_scroll_speed(speed: float) -> void:
	external_scroll_speed = speed
	use_external_speed = true


## Return to auto-scroll mode
func use_auto_scroll() -> void:
	use_external_speed = false


## Get current effective scroll speed
func get_current_speed() -> float:
	if use_external_speed:
		return external_scroll_speed
	return base_scroll_speed


## Apply sector theme colors (for sector-themed backgrounds)
func set_theme_colors(theme) -> void:
	if not theme:
		return
	
	# Update star colors if available
	if theme.has("star_colors") and not theme.star_colors.is_empty():
		star_colors = theme.star_colors.duplicate()
	
	# Regenerate stars with new colors
	_generate_all_stars()
	queue_redraw()
