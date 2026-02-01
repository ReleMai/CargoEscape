# ==============================================================================
# SPACE BACKGROUND - PARALLAX STARFIELD FOR BOARDING PHASE
# ==============================================================================
#
# FILE: scripts/boarding/space_background.gd
# PURPOSE: Renders an animated space background visible through ship windows
#
# FEATURES:
# - Multiple parallax star layers
# - Nebula/dust clouds
# - Occasional ship silhouettes passing by
# - Subtle animation for atmosphere
#
# ==============================================================================

class_name SpaceBackground
extends Node2D


# ==============================================================================
# EXPORTS
# ==============================================================================

@export var star_count_near: int = 50
@export var star_count_mid: int = 100
@export var star_count_far: int = 200
@export var nebula_count: int = 3
@export var drift_speed: float = 5.0
@export var twinkle_speed: float = 2.0
@export var viewport_size: Vector2 = Vector2(1920, 1080)


# ==============================================================================
# STAR DATA
# ==============================================================================

class Star:
	var position: Vector2
	var size: float
	var color: Color
	var twinkle_offset: float
	var layer: int  # 0=far, 1=mid, 2=near
	var drift_factor: float

class Nebula:
	var position: Vector2
	var size: Vector2
	var color: Color
	var alpha: float
	var rotation: float


# ==============================================================================
# STATE
# ==============================================================================

var _stars: Array = []
var _nebulae: Array = []
var _time: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Colors for variety
const STAR_COLORS = [
	Color(1.0, 1.0, 1.0),      # White
	Color(1.0, 0.95, 0.8),     # Warm white
	Color(0.8, 0.9, 1.0),      # Cool white
	Color(1.0, 0.8, 0.6),      # Orange
	Color(0.7, 0.8, 1.0),      # Blue-white
	Color(1.0, 0.6, 0.6),      # Red giant
]

const NEBULA_COLORS = [
	Color(0.2, 0.1, 0.3, 0.15),   # Purple
	Color(0.1, 0.2, 0.3, 0.12),   # Blue
	Color(0.3, 0.15, 0.1, 0.1),   # Orange/brown
	Color(0.1, 0.25, 0.2, 0.12),  # Teal
	Color(0.25, 0.1, 0.15, 0.1),  # Magenta
]


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_rng.randomize()
	_generate_stars()
	_generate_nebulae()


func _process(delta: float) -> void:
	_time += delta
	
	# Drift stars slowly
	for star in _stars:
		star.position.x -= drift_speed * star.drift_factor * delta
		
		# Wrap around
		if star.position.x < -50:
			star.position.x = viewport_size.x + 50
			star.position.y = _rng.randf_range(0, viewport_size.y)
	
	queue_redraw()


func _draw() -> void:
	# Draw deep space background
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.02, 0.02, 0.04))
	
	# Draw nebulae (behind stars)
	for nebula in _nebulae:
		_draw_nebula(nebula)
	
	# Draw stars by layer (far to near)
	for layer in range(3):
		for star in _stars:
			if star.layer == layer:
				_draw_star(star)


# ==============================================================================
# GENERATION
# ==============================================================================

func _generate_stars() -> void:
	_stars.clear()
	
	# Far layer (smallest, slowest)
	for i in range(star_count_far):
		var star = Star.new()
		star.position = Vector2(
			_rng.randf_range(0, viewport_size.x),
			_rng.randf_range(0, viewport_size.y)
		)
		star.size = _rng.randf_range(0.5, 1.0)
		star.color = STAR_COLORS[_rng.randi() % STAR_COLORS.size()]
		star.color.a = _rng.randf_range(0.3, 0.6)
		star.twinkle_offset = _rng.randf_range(0, TAU)
		star.layer = 0
		star.drift_factor = 0.2
		_stars.append(star)
	
	# Mid layer
	for i in range(star_count_mid):
		var star = Star.new()
		star.position = Vector2(
			_rng.randf_range(0, viewport_size.x),
			_rng.randf_range(0, viewport_size.y)
		)
		star.size = _rng.randf_range(1.0, 2.0)
		star.color = STAR_COLORS[_rng.randi() % STAR_COLORS.size()]
		star.color.a = _rng.randf_range(0.5, 0.8)
		star.twinkle_offset = _rng.randf_range(0, TAU)
		star.layer = 1
		star.drift_factor = 0.5
		_stars.append(star)
	
	# Near layer (largest, fastest)
	for i in range(star_count_near):
		var star = Star.new()
		star.position = Vector2(
			_rng.randf_range(0, viewport_size.x),
			_rng.randf_range(0, viewport_size.y)
		)
		star.size = _rng.randf_range(2.0, 3.5)
		star.color = STAR_COLORS[_rng.randi() % STAR_COLORS.size()]
		star.color.a = _rng.randf_range(0.7, 1.0)
		star.twinkle_offset = _rng.randf_range(0, TAU)
		star.layer = 2
		star.drift_factor = 1.0
		_stars.append(star)


func _generate_nebulae() -> void:
	_nebulae.clear()
	
	for i in range(nebula_count):
		var nebula = Nebula.new()
		nebula.position = Vector2(
			_rng.randf_range(0, viewport_size.x),
			_rng.randf_range(0, viewport_size.y)
		)
		nebula.size = Vector2(
			_rng.randf_range(200, 500),
			_rng.randf_range(150, 400)
		)
		nebula.color = NEBULA_COLORS[_rng.randi() % NEBULA_COLORS.size()]
		nebula.alpha = _rng.randf_range(0.05, 0.15)
		nebula.rotation = _rng.randf_range(0, TAU)
		_nebulae.append(nebula)


# ==============================================================================
# DRAWING
# ==============================================================================

func _draw_star(star: Star) -> void:
	# Calculate twinkle
	var twinkle = sin(_time * twinkle_speed + star.twinkle_offset)
	var alpha_mod = 0.7 + twinkle * 0.3
	
	var draw_color = Color(
		star.color.r,
		star.color.g,
		star.color.b,
		star.color.a * alpha_mod
	)
	
	# Draw star with glow
	if star.size > 2.0:
		# Larger stars get a glow effect
		var glow_color = Color(draw_color.r, draw_color.g, draw_color.b, draw_color.a * 0.3)
		draw_circle(star.position, star.size * 2, glow_color)
	
	draw_circle(star.position, star.size, draw_color)
	
	# Brightest stars get a cross/spike effect
	if star.size > 2.5 and star.color.a > 0.8:
		var spike_color = Color(draw_color.r, draw_color.g, draw_color.b, draw_color.a * 0.5)
		var spike_len = star.size * 3
		draw_line(
			star.position - Vector2(spike_len, 0),
			star.position + Vector2(spike_len, 0),
			spike_color, 1.0
		)
		draw_line(
			star.position - Vector2(0, spike_len),
			star.position + Vector2(0, spike_len),
			spike_color, 1.0
		)


func _draw_nebula(nebula: Nebula) -> void:
	# Draw nebula as multiple overlapping ellipses for soft effect
	var base_color = nebula.color
	
	# Draw several layers with decreasing size and increasing alpha
	for layer_idx in range(5):
		var scale = 1.0 - layer_idx * 0.15
		var alpha = nebula.alpha * (1.0 + layer_idx * 0.3)
		
		var layer_color = Color(base_color.r, base_color.g, base_color.b, alpha)
		var layer_size = nebula.size * scale
		
		# Approximate ellipse with polygon
		var points: PackedVector2Array = PackedVector2Array()
		var segments = 32
		for seg_idx in range(segments):
			var angle = (float(seg_idx) / segments) * TAU + nebula.rotation
			var point = nebula.position + Vector2(
				cos(angle) * layer_size.x / 2,
				sin(angle) * layer_size.y / 2
			)
			points.append(point)
		
		if points.size() >= 3:
			draw_colored_polygon(points, layer_color)


# ==============================================================================
# PUBLIC API
# ==============================================================================

func set_viewport(size: Vector2) -> void:
	viewport_size = size
	_generate_stars()
	_generate_nebulae()


func regenerate(new_seed: int = -1) -> void:
	if new_seed >= 0:
		_rng.seed = new_seed
	else:
		_rng.randomize()
	
	_generate_stars()
	_generate_nebulae()
