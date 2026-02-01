# ==============================================================================
# SEARCH PROGRESS UI - CIRCULAR PROGRESS INDICATOR FOR SEARCHING
# ==============================================================================
#
# FILE: scripts/boarding/search_progress.gd
# PURPOSE: Visual progress ring that shows search progress on items/containers
#
# FEATURES:
# - Circular progress ring
# - Color changes based on progress
# - Pulsing animation when complete
# - Can be attached to any node
#
# ==============================================================================

extends Control
class_name SearchProgress


# ==============================================================================
# SIGNALS
# ==============================================================================

signal search_completed
signal search_cancelled


# ==============================================================================
# CONSTANTS
# ==============================================================================

const RING_RADIUS := 28.0
const RING_THICKNESS := 4.0
const BG_COLOR := Color(0.1, 0.1, 0.15, 0.8)
const PROGRESS_COLOR_START := Color(0.3, 0.6, 1.0)
const PROGRESS_COLOR_END := Color(0.3, 1.0, 0.5)
const COMPLETE_COLOR := Color(0.4, 1.0, 0.5)


# ==============================================================================
# STATE
# ==============================================================================

var progress: float = 0.0  # 0.0 to 1.0
var total_time: float = 1.0
var elapsed_time: float = 0.0
var is_searching: bool = false
var is_complete: bool = false

# Animation
var pulse_time: float = 0.0


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(RING_RADIUS * 2 + 8, RING_RADIUS * 2 + 8)
	size = custom_minimum_size


func _process(delta: float) -> void:
	if is_searching and not is_complete:
		elapsed_time += delta
		progress = clampf(elapsed_time / total_time, 0.0, 1.0)
		
		if progress >= 1.0:
			_complete_search()
		
		queue_redraw()
	
	if is_complete:
		pulse_time += delta
		queue_redraw()


func _draw() -> void:
	var center = size / 2
	
	# Draw background ring
	_draw_arc_ring(center, RING_RADIUS, 0.0, TAU, BG_COLOR)
	
	# Draw progress arc
	if progress > 0:
		var progress_color = PROGRESS_COLOR_START.lerp(PROGRESS_COLOR_END, progress)
		if is_complete:
			progress_color = COMPLETE_COLOR
			# Pulse effect
			var pulse = (sin(pulse_time * 6.0) + 1.0) / 2.0
			progress_color.a = 0.7 + pulse * 0.3
		
		var end_angle = -PI / 2 + progress * TAU
		_draw_arc_ring(center, RING_RADIUS, -PI / 2, end_angle, progress_color)
	
	# Draw percentage text
	if is_searching or is_complete:
		var text = "%d%%" % int(progress * 100)
		var font = ThemeDB.fallback_font
		var font_size = 12
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = center - text_size / 2
		text_pos.y += font_size / 3
		draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)


func _draw_arc_ring(
	center: Vector2,
	radius: float,
	start_angle: float,
	end_angle: float,
	color: Color
) -> void:
	var points_outer: PackedVector2Array = []
	var points_inner: PackedVector2Array = []
	var colors: PackedColorArray = []
	
	var segments = 32
	var angle_step = (end_angle - start_angle) / segments
	
	for i in range(segments + 1):
		var angle = start_angle + i * angle_step
		var dir = Vector2(cos(angle), sin(angle))
		points_outer.append(center + dir * radius)
		points_inner.append(center + dir * (radius - RING_THICKNESS))
	
	# Draw as polygon strips
	for i in range(segments):
		var quad: PackedVector2Array = [
			points_outer[i],
			points_outer[i + 1],
			points_inner[i + 1],
			points_inner[i]
		]
		var quad_colors: PackedColorArray = [color, color, color, color]
		draw_polygon(quad, quad_colors)


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Start a new search
func start_search(duration: float) -> void:
	total_time = maxf(duration, 0.1)
	elapsed_time = 0.0
	progress = 0.0
	is_searching = true
	is_complete = false
	pulse_time = 0.0
	visible = true
	queue_redraw()


## Cancel current search
func cancel_search() -> void:
	if is_searching and not is_complete:
		is_searching = false
		search_cancelled.emit()
	visible = false


## Reset to initial state
func reset() -> void:
	progress = 0.0
	elapsed_time = 0.0
	is_searching = false
	is_complete = false
	visible = false
	queue_redraw()


## Check if currently searching
func is_active() -> bool:
	return is_searching and not is_complete


## Get current progress (0-1)
func get_progress() -> float:
	return progress


# ==============================================================================
# INTERNAL
# ==============================================================================

func _complete_search() -> void:
	is_complete = true
	is_searching = false
	search_completed.emit()
	
	# Auto-hide after delay
	await get_tree().create_timer(0.5).timeout
	if is_complete:
		visible = false
