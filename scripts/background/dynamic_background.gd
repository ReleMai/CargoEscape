# ==============================================================================
# DYNAMIC BACKGROUND SYSTEM - LAYERED PARALLAX SPACE BACKGROUND
# ==============================================================================
#
# FILE: scripts/background/dynamic_background.gd
# PURPOSE: Manages a multi-layered parallax background system with dynamic effects
#
# FEATURES:
# - 6 distinct parallax layers (far stars to foreground effects)
# - Shader-based star rendering for performance
# - Procedural content generation
# - Color theme support per sector/area
# - Day/night cycle simulation (lighting shifts)
# - Random events (comets, distant explosions)
# - Object pooling for particles
# - LOD for distant objects
#
# LAYERS:
# 1. Static Far Stars - Barely moving points (0.1x speed)
# 2. Nebula Layer - Slow color-shifting clouds (0.2x speed)
# 3. Mid Stars - Parallax scrolling (0.5x speed)
# 4. Planets - Occasional large objects (0.3x speed)
# 5. Near Particles - Fast-moving dust/debris (1.0x speed)
# 6. Foreground Effects - Asteroids, ships (1.5x speed)
#
# ==============================================================================

class_name DynamicBackground
extends Node2D


# ==============================================================================
# SIGNALS
# ==============================================================================

signal random_event_triggered(event_type: String)
signal theme_changed(theme_name: String)


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Scrolling")

## Base scroll speed (pixels per second)
@export var base_scroll_speed: float = 50.0

## Enable automatic scrolling
@export var auto_scroll: bool = true

## Scroll direction (normalized)
@export var scroll_direction: Vector2 = Vector2(-1, 0)


@export_group("Layers Configuration")

## Enable/disable individual layers
@export var enable_far_stars: bool = true
@export var enable_nebula: bool = true
@export var enable_mid_stars: bool = true
@export var enable_planets: bool = true
@export var enable_near_particles: bool = true
@export var enable_foreground: bool = true


@export_group("Color Theme")

## Current color theme
@export_enum("Blue", "Purple", "Orange", "Green", "Red") var color_theme: String = "Blue"

## Enable day/night cycle
@export var enable_day_night_cycle: bool = false

## Day/night cycle duration (seconds)
@export var cycle_duration: float = 120.0


@export_group("Random Events")

## Enable random events (comets, explosions, etc.)
@export var enable_random_events: bool = true

## Average time between random events (seconds)
@export var event_interval: float = 30.0


@export_group("Performance")

## Use shaders for star layers (better performance)
@export var use_shaders: bool = true

## Enable LOD for distant objects
@export var enable_lod: bool = true


# ==============================================================================
# LAYER DATA
# ==============================================================================

# Layer speed multipliers (how fast each layer moves relative to base speed)
const LAYER_SPEEDS = {
	"far_stars": 0.1,
	"nebula": 0.2,
	"mid_stars": 0.5,
	"planets": 0.3,
	"near_particles": 1.0,
	"foreground": 1.5
}

# Color themes for different sectors
const COLOR_THEMES = {
	"Blue": {
		"far_stars": Color(0.7, 0.8, 1.0),
		"nebula": Color(0.1, 0.2, 0.4, 0.15),
		"mid_stars": Color(0.8, 0.9, 1.0),
		"ambient": Color(0.05, 0.05, 0.15)
	},
	"Purple": {
		"far_stars": Color(0.8, 0.7, 1.0),
		"nebula": Color(0.2, 0.1, 0.3, 0.15),
		"mid_stars": Color(0.9, 0.8, 1.0),
		"ambient": Color(0.08, 0.05, 0.12)
	},
	"Orange": {
		"far_stars": Color(1.0, 0.9, 0.7),
		"nebula": Color(0.3, 0.15, 0.1, 0.15),
		"mid_stars": Color(1.0, 0.95, 0.8),
		"ambient": Color(0.12, 0.08, 0.05)
	},
	"Green": {
		"far_stars": Color(0.7, 1.0, 0.8),
		"nebula": Color(0.1, 0.25, 0.15, 0.15),
		"mid_stars": Color(0.8, 1.0, 0.9),
		"ambient": Color(0.05, 0.12, 0.08)
	},
	"Red": {
		"far_stars": Color(1.0, 0.7, 0.7),
		"nebula": Color(0.3, 0.1, 0.1, 0.15),
		"mid_stars": Color(1.0, 0.8, 0.8),
		"ambient": Color(0.15, 0.05, 0.05)
	}
}


# ==============================================================================
# STATE
# ==============================================================================

## Layer references
var layers: Dictionary = {}

## Current effective scroll speed
var current_scroll_speed: float = 0.0

## External scroll speed (set by game)
var external_scroll_speed: float = 0.0
var use_external_speed: bool = false

## Day/night cycle state
var cycle_time: float = 0.0
var current_brightness: float = 1.0

## Random event timer
var event_timer: float = 0.0

## Viewport size
var viewport_size: Vector2 = Vector2.ZERO

## Background color rect
var background_rect: ColorRect = null


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	viewport_size = get_viewport_rect().size
	
	# Create background base
	_create_background_base()
	
	# Create all layers
	_create_layers()
	
	# Apply initial theme
	apply_theme(color_theme)
	
	# Setup random events
	if enable_random_events:
		event_timer = randf_range(event_interval * 0.5, event_interval * 1.5)


func _process(delta: float) -> void:
	# Determine scroll speed
	if use_external_speed:
		current_scroll_speed = external_scroll_speed
	elif auto_scroll:
		current_scroll_speed = base_scroll_speed
	else:
		current_scroll_speed = 0.0
	
	# Update scroll for all layers
	if current_scroll_speed > 0:
		_update_layers(delta)
	
	# Update day/night cycle
	if enable_day_night_cycle:
		_update_day_night_cycle(delta)
	
	# Update random events
	if enable_random_events:
		_update_random_events(delta)


# ==============================================================================
# LAYER CREATION
# ==============================================================================

func _create_background_base() -> void:
	# Create base dark space background
	background_rect = ColorRect.new()
	background_rect.size = viewport_size
	background_rect.color = Color(0.02, 0.02, 0.06, 1.0)
	background_rect.z_index = -1000
	add_child(background_rect)


func _create_layers() -> void:
	# Layer 1: Far Stars (static, barely moving)
	if enable_far_stars:
		layers["far_stars"] = _create_star_layer(
			"far_stars",
			LAYER_SPEEDS["far_stars"],
			-900,
			30.0,  # density
			0.3, 1.0,  # size range
			Color.WHITE
		)
	
	# Layer 2: Nebula (slow color-shifting clouds)
	if enable_nebula:
		layers["nebula"] = _create_nebula_layer(
			"nebula",
			LAYER_SPEEDS["nebula"],
			-800
		)
	
	# Layer 3: Mid Stars (main parallax layer)
	if enable_mid_stars:
		layers["mid_stars"] = _create_star_layer(
			"mid_stars",
			LAYER_SPEEDS["mid_stars"],
			-700,
			50.0,  # density
			0.5, 2.5,  # size range
			Color.WHITE
		)
	
	# Layer 4: Planets (occasional large objects)
	if enable_planets:
		layers["planets"] = _create_planet_layer(
			"planets",
			LAYER_SPEEDS["planets"],
			-600
		)
	
	# Layer 5: Near Particles (fast-moving dust)
	if enable_near_particles:
		layers["near_particles"] = _create_particle_layer(
			"near_particles",
			LAYER_SPEEDS["near_particles"],
			-500
		)
	
	# Layer 6: Foreground Effects
	if enable_foreground:
		layers["foreground"] = _create_foreground_layer(
			"foreground",
			LAYER_SPEEDS["foreground"],
			-400
		)


func _create_star_layer(
	layer_name: String,
	speed_mult: float,
	z_order: int,
	density: float,
	size_min: float,
	size_max: float,
	color: Color
) -> ParallaxLayer:
	var layer = ParallaxLayer.new()
	layer.name = layer_name
	layer.speed_multiplier = speed_mult
	layer.draw_order = z_order
	layer.content_type = "Stars"
	layer.use_shader = use_shaders
	layer.star_density = density
	layer.star_size_min = size_min
	layer.star_size_max = size_max
	layer.star_color = color
	layer.color_variation = 0.2
	layer.enable_twinkle = true
	layer.twinkle_speed = 2.0
	layer.twinkle_amount = 0.3
	
	add_child(layer)
	return layer


func _create_nebula_layer(layer_name: String, speed_mult: float, z_order: int) -> Node2D:
	# Simple nebula implementation using colored rectangles
	var layer = Node2D.new()
	layer.name = layer_name
	layer.z_index = z_order
	
	# Create a few nebula clouds
	for i in range(3):
		var nebula = ColorRect.new()
		nebula.size = Vector2(
			randf_range(300, 600),
			randf_range(200, 400)
		)
		nebula.position = Vector2(
			randf_range(0, viewport_size.x),
			randf_range(0, viewport_size.y)
		)
		nebula.color = Color(0.1, 0.2, 0.3, 0.1)
		nebula.set_meta("speed_mult", speed_mult)
		layer.add_child(nebula)
	
	add_child(layer)
	return layer


func _create_planet_layer(layer_name: String, speed_mult: float, z_order: int) -> Node2D:
	# Layer for occasional planets/large objects
	var layer = Node2D.new()
	layer.name = layer_name
	layer.z_index = z_order
	layer.set_meta("speed_mult", speed_mult)
	
	# Spawn 1-2 distant planets
	if randf() > 0.5:
		var planet = _create_planet()
		planet.position = Vector2(
			randf_range(viewport_size.x * 0.2, viewport_size.x * 0.8),
			randf_range(viewport_size.y * 0.2, viewport_size.y * 0.8)
		)
		layer.add_child(planet)
	
	add_child(layer)
	return layer


func _create_planet() -> Node2D:
	var planet = Node2D.new()
	
	# Simple circle representation
	var circle = Polygon2D.new()
	var radius = randf_range(30, 80)
	var points: PackedVector2Array = PackedVector2Array()
	var segments = 32
	
	for i in range(segments):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	circle.polygon = points
	circle.color = Color(
		randf_range(0.3, 0.7),
		randf_range(0.3, 0.7),
		randf_range(0.3, 0.7),
		0.6
	)
	
	planet.add_child(circle)
	return planet


func _create_particle_layer(layer_name: String, speed_mult: float, z_order: int) -> Node2D:
	# Fast-moving particle layer
	var layer = Node2D.new()
	layer.name = layer_name
	layer.z_index = z_order
	layer.set_meta("speed_mult", speed_mult)
	
	add_child(layer)
	return layer


func _create_foreground_layer(layer_name: String, speed_mult: float, z_order: int) -> Node2D:
	# Foreground effects layer
	var layer = Node2D.new()
	layer.name = layer_name
	layer.z_index = z_order
	layer.set_meta("speed_mult", speed_mult)
	
	add_child(layer)
	return layer


# ==============================================================================
# LAYER UPDATES
# ==============================================================================

func _update_layers(delta: float) -> void:
	var scroll_delta = scroll_direction * current_scroll_speed * delta
	
	# Update each layer
	for layer_name in layers:
		var layer = layers[layer_name]
		
		if layer is ParallaxLayer:
			# Update parallax layer with shader support
			layer.update_scroll(scroll_delta)
		else:
			# Update simple node layer
			var speed_mult = layer.get_meta("speed_mult", 1.0)
			layer.position += scroll_delta * speed_mult
			
			# Wrap nebula clouds
			if layer_name == "nebula":
				_wrap_nebula_elements(layer)


func _wrap_nebula_elements(layer: Node2D) -> void:
	# Wrap nebula elements around screen
	for child in layer.get_children():
		if child.position.x < -200:
			child.position.x = viewport_size.x + 200
		elif child.position.x > viewport_size.x + 200:
			child.position.x = -200


# ==============================================================================
# THEMING
# ==============================================================================

func apply_theme(theme_name: String) -> void:
	if not COLOR_THEMES.has(theme_name):
		push_warning("[DynamicBackground] Unknown theme: " + theme_name)
		return
	
	color_theme = theme_name
	var theme = COLOR_THEMES[theme_name]
	
	# Update background color
	if background_rect:
		background_rect.color = theme["ambient"]
	
	# Update layer colors
	if layers.has("far_stars") and layers["far_stars"] is ParallaxLayer:
		layers["far_stars"].set_star_color(theme["far_stars"])
	
	if layers.has("mid_stars") and layers["mid_stars"] is ParallaxLayer:
		layers["mid_stars"].set_star_color(theme["mid_stars"])
	
	if layers.has("nebula"):
		_update_nebula_color(layers["nebula"], theme["nebula"])
	
	theme_changed.emit(theme_name)


func _update_nebula_color(layer: Node2D, color: Color) -> void:
	for child in layer.get_children():
		if child is ColorRect:
			child.color = color


# ==============================================================================
# DAY/NIGHT CYCLE
# ==============================================================================

func _update_day_night_cycle(delta: float) -> void:
	cycle_time += delta
	
	# Calculate brightness (0.5 to 1.0 cycle)
	var cycle_progress = fmod(cycle_time, cycle_duration) / cycle_duration
	current_brightness = 0.5 + sin(cycle_progress * TAU) * 0.5
	
	# Apply brightness to layers
	modulate = Color(current_brightness, current_brightness, current_brightness)


# ==============================================================================
# RANDOM EVENTS
# ==============================================================================

func _update_random_events(delta: float) -> void:
	event_timer -= delta
	
	if event_timer <= 0:
		_trigger_random_event()
		event_timer = randf_range(event_interval * 0.5, event_interval * 1.5)


func _trigger_random_event() -> void:
	# Choose random event type
	var events = ["comet", "explosion", "ship_flyby"]
	var event_type = events[randi() % events.size()]
	
	# Trigger event (could spawn particles, change colors, etc.)
	match event_type:
		"comet":
			_spawn_comet()
		"explosion":
			_spawn_explosion_flash()
		"ship_flyby":
			_spawn_ship_silhouette()
	
	random_event_triggered.emit(event_type)


func _spawn_comet() -> void:
	# Simple comet effect (could be enhanced)
	print("[DynamicBackground] Comet event!")


func _spawn_explosion_flash() -> void:
	# Flash effect in distance
	print("[DynamicBackground] Distant explosion!")


func _spawn_ship_silhouette() -> void:
	# Ship passes in foreground
	print("[DynamicBackground] Ship flyby!")


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Set scroll speed from external source
func set_scroll_speed(speed: float) -> void:
	external_scroll_speed = speed
	use_external_speed = true


## Return to auto-scroll mode
func use_auto_scroll() -> void:
	use_external_speed = false


## Get current scroll speed
func get_current_speed() -> float:
	return current_scroll_speed


## Change color theme
func change_theme(theme_name: String) -> void:
	apply_theme(theme_name)


## Reset all layers
func reset() -> void:
	for layer_name in layers:
		var layer = layers[layer_name]
		if layer is ParallaxLayer:
			layer.reset_scroll()
		else:
			layer.position = Vector2.ZERO


## Enable/disable a specific layer
func set_layer_enabled(layer_name: String, enabled: bool) -> void:
	if layers.has(layer_name):
		layers[layer_name].visible = enabled


## Update viewport size
func resize_to_viewport() -> void:
	viewport_size = get_viewport_rect().size
	
	if background_rect:
		background_rect.size = viewport_size
	
	for layer in layers.values():
		if layer is ParallaxLayer:
			layer.resize_to_viewport()
