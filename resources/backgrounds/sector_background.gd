# ==============================================================================
# SECTOR BACKGROUND - ENHANCED BACKGROUND WITH SECTOR THEMES
# ==============================================================================
#
# FILE: resources/backgrounds/sector_background.gd
# PURPOSE: Example implementation showing how to use SectorThemes with backgrounds
#
# USAGE:
# 1. Add this script to a Node2D or use the existing Background script
# 2. Set the faction_code to one of: CCG, NEX, GDF, SYN, IND
# 3. The background will automatically use sector-appropriate colors
#
# ==============================================================================

extends Node2D


# ==============================================================================
# EXPORTS
# ==============================================================================

## Which sector/faction theme to use
@export_enum("CCG:0", "NEX:1", "GDF:2", "SYN:3", "IND:4") var faction_code: String = "CCG"

## Base scroll speed
@export var base_scroll_speed: float = 100.0

## Enable auto-scroll
@export var auto_scroll: bool = true


# ==============================================================================
# SECTOR-SPECIFIC SETTINGS
# ==============================================================================

## Current active theme
var current_theme: SectorThemes.SectorTheme = null

## Screen dimensions
var screen_size: Vector2

## Star layers data
var star_layers: Array = []

## Time accumulator
var time: float = 0.0


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
	# Load sector theme
	current_theme = SectorThemes.get_theme(faction_code)
	if not current_theme:
		push_warning("Invalid faction code: %s, defaulting to CCG" % faction_code)
		current_theme = SectorThemes.get_theme("CCG")
	
	# Generate stars using theme colors
	_generate_stars_with_theme()
	
	queue_redraw()


func _process(delta: float) -> void:
	time += delta
	
	if auto_scroll:
		_scroll_stars(delta * base_scroll_speed)
	
	queue_redraw()


func _draw() -> void:
	if not current_theme:
		return
	
	# Draw ambient background
	draw_rect(Rect2(Vector2.ZERO, screen_size), current_theme.ambient_color)
	
	# Draw nebulae using sector colors
	_draw_sector_nebulae()
	
	# Draw stars
	_draw_stars()


# ==============================================================================
# STAR GENERATION
# ==============================================================================

func _generate_stars_with_theme() -> void:
	if not current_theme:
		return
	
	star_layers.clear()
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Create 3 layers with different counts
	var layer_counts = [200, 100, 50]  # Far, mid, near
	var layer_sizes = [
		Vector2(0.5, 1.5),
		Vector2(1.0, 2.5),
		Vector2(2.0, 4.0)
	]
	var layer_speeds = [0.3, 0.6, 1.0]
	
	for layer_idx in range(3):
		var layer_stars: Array = []
		
		for i in range(layer_counts[layer_idx]):
			var color = SectorThemes.get_random_star_color(faction_code, rng)
			color.a = rng.randf_range(0.5, 1.0)
			
			var star = {
				"position": Vector2(
					rng.randf_range(0, screen_size.x * 2),
					rng.randf_range(0, screen_size.y)
				),
				"size": rng.randf_range(layer_sizes[layer_idx].x, layer_sizes[layer_idx].y),
				"color": color,
				"speed_mult": layer_speeds[layer_idx],
				"twinkle_offset": rng.randf() * TAU
			}
			layer_stars.append(star)
		
		star_layers.append(layer_stars)


func _scroll_stars(speed: float) -> void:
	for layer in star_layers:
		for star in layer:
			star.position.x -= speed * star.speed_mult * get_process_delta_time()
			
			# Wrap around
			if star.position.x < -20:
				star.position.x = screen_size.x + 20


func _draw_stars() -> void:
	for layer in star_layers:
		for star in layer:
			if star.position.x < -20 or star.position.x > screen_size.x + 20:
				continue
			
			# Twinkle effect
			var twinkle = sin(time * 2.0 + star.twinkle_offset)
			var alpha = star.color.a * lerpf(0.7, 1.0, (twinkle + 1.0) * 0.5)
			var draw_color = Color(star.color.r, star.color.g, star.color.b, alpha)
			
			draw_circle(star.position, star.size, draw_color)
			
			# Glow for larger stars
			if star.size > 2.5:
				var glow = Color(draw_color.r, draw_color.g, draw_color.b, alpha * 0.3)
				draw_circle(star.position, star.size * 1.5, glow)


# ==============================================================================
# NEBULA DRAWING
# ==============================================================================

func _draw_sector_nebulae() -> void:
	if not current_theme or current_theme.nebula_density < 0.1:
		return
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(faction_code)  # Consistent seed for this sector
	
	# Number of nebula clouds based on density
	var nebula_count = int(current_theme.nebula_density * 5)
	
	for i in range(nebula_count):
		var nebula_color = SectorThemes.get_random_nebula_color(faction_code, rng)
		var pos = Vector2(
			screen_size.x * (float(i) / nebula_count + 0.1),
			rng.randf_range(screen_size.y * 0.2, screen_size.y * 0.8)
		)
		var radius = rng.randf_range(150, 350)
		
		# Draw multiple circles for soft effect
		for layer in range(3):
			var layer_radius = radius * (1.0 - layer * 0.2)
			var layer_alpha = nebula_color.a * (1.0 + layer * 0.3)
			var layer_color = Color(
				nebula_color.r,
				nebula_color.g,
				nebula_color.b,
				layer_alpha
			)
			draw_circle(pos, layer_radius, layer_color)


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Change sector theme at runtime
func set_sector_theme(new_faction_code: String) -> void:
	faction_code = new_faction_code
	current_theme = SectorThemes.get_theme(faction_code)
	if current_theme:
		_generate_stars_with_theme()
		queue_redraw()


## Get current theme information
func get_current_theme() -> SectorThemes.SectorTheme:
	return current_theme
