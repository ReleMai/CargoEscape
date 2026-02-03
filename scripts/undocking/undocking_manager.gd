# ==============================================================================
# UNDOCKING MANAGER - SEAMLESS CINEMATIC DEPARTURE
# ==============================================================================
#
# FILE: scripts/undocking/undocking_manager.gd
# PURPOSE: Creates a seamless, cinematic transition from boarding to escape
#
# SEQUENCE:
# 1. Fade in from black (coming from boarding)
# 2. Show ship in docking bay with space visible through exit
# 3. Status text: "INITIATING UNDOCK SEQUENCE"
# 4. Clamps release with warning lights
# 5. Ship separates and engines ignite
# 6. Ship accelerates through dock exit into space
# 7. Dock recedes as ship enters open space with stars
# 8. Speed lines and engine trail intensify
# 9. Seamless blend into escape gameplay
#
# ==============================================================================

extends Node2D
class_name UndockingManager


# ==============================================================================
# SIGNALS
# ==============================================================================

signal undocking_complete
signal undocking_progress(progress: float)
signal status_changed(text: String)


# ==============================================================================
# ENUMS
# ==============================================================================

enum Phase {
	FADE_IN,
	DOCKED,
	CLAMPS_RELEASE,
	SEPARATION,
	ACCELERATION,
	SPACE_FLIGHT,
	BLEND_OUT
}


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Timing")
@export var fade_in_time: float = 0.6
@export var docked_pause: float = 0.8
@export var clamp_time: float = 0.6
@export var separation_time: float = 0.8
@export var acceleration_time: float = 1.2
@export var space_flight_time: float = 1.5
@export var blend_out_time: float = 0.8


@export_group("Visuals")
@export var dock_wall_color: Color = Color(0.1, 0.12, 0.16, 1.0)
@export var dock_metal_color: Color = Color(0.18, 0.2, 0.24, 1.0)
@export var dock_accent: Color = Color(0.15, 0.4, 0.6, 0.8)
@export var warning_color: Color = Color(1.0, 0.35, 0.1, 1.0)
@export var space_color: Color = Color(0.008, 0.012, 0.025, 1.0)


# ==============================================================================
# STATE
# ==============================================================================

var current_phase: Phase = Phase.FADE_IN
var phase_timer: float = 0.0

# Ship
var ship_visual: ShipVisual
var ship_type: ShipVisual.ShipType = ShipVisual.ShipType.SHUTTLE
var station_data: Resource = null

# Animation state
var fade_alpha: float = 1.0
var clamp_progress: float = 0.0
var ship_pos: Vector2 = Vector2.ZERO
var ship_rot: float = 0.0
var dock_offset: float = 0.0
var engine_intensity: float = 0.0
var speed_line_intensity: float = 0.0

# Warning lights
var warning_on: bool = false
var warning_timer: float = 0.0

# Stars (generated once)
var stars: Array[Dictionary] = []
var distant_stars: Array[Dictionary] = []

# Screen
var screen_center: Vector2

# Dock dimensions
var dock_w: float = 450.0
var dock_h: float = 260.0


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	screen_center = get_viewport_rect().size / 2
	position = screen_center
	
	# Generate star field
	_generate_stars()
	
	# Play undocking music
	AudioManager.play_music("intro_cinematic")
	
	# Create ship visual
	ship_visual = ShipVisual.new()
	ship_visual.ship_type = ship_type
	ship_visual.engines_active = false
	add_child(ship_visual)


func _process(delta: float) -> void:
	# Apply speed multiplier from CutsceneManager
	var speed_mult = CutsceneManager.get_speed_multiplier()
	var modified_delta = delta * speed_mult
	
	phase_timer += modified_delta
	
	# Warning light blink
	warning_timer += modified_delta
	if warning_timer > 0.25:
		warning_timer = 0.0
		warning_on = not warning_on
	
	# Update based on phase
	match current_phase:
		Phase.FADE_IN:
			_process_fade_in(modified_delta)
		Phase.DOCKED:
			_process_docked(modified_delta)
		Phase.CLAMPS_RELEASE:
			_process_clamps(modified_delta)
		Phase.SEPARATION:
			_process_separation(modified_delta)
		Phase.ACCELERATION:
			_process_acceleration(modified_delta)
		Phase.SPACE_FLIGHT:
			_process_space_flight(modified_delta)
		Phase.BLEND_OUT:
			_process_blend_out(modified_delta)
	
	queue_redraw()


func _draw() -> void:
	# Draw everything relative to center (0,0)
	
	# Layer 1: Deep space background (always visible through dock exit)
	_draw_space_background()
	
	# Layer 2: Docking bay (fades out as ship exits)
	if dock_offset < dock_w * 2:
		_draw_docking_bay()
	
	# Layer 3: Speed lines (during acceleration/flight)
	if speed_line_intensity > 0:
		_draw_speed_lines()
	
	# Layer 4: Engine trail (drawn by ship_visual, we add extra glow)
	if engine_intensity > 0.3:
		_draw_engine_glow()
	
	# Layer 5: Fade overlay
	if fade_alpha > 0.01:
		var fade_rect = Rect2(-screen_center, screen_center * 2)
		draw_rect(fade_rect, Color(0, 0, 0, fade_alpha))


# ==============================================================================
# PHASE PROCESSORS
# ==============================================================================

func _process_fade_in(_delta: float) -> void:
	var t = phase_timer / fade_in_time
	fade_alpha = 1.0 - ease(t, 0.3)
	
	if phase_timer >= fade_in_time:
		_transition_to(Phase.DOCKED)
		status_changed.emit("UNDOCK SEQUENCE INITIATED")


func _process_docked(_delta: float) -> void:
	# Just waiting, warning lights blinking
	if phase_timer >= docked_pause:
		_transition_to(Phase.CLAMPS_RELEASE)
		status_changed.emit("RELEASING DOCKING CLAMPS...")


func _process_clamps(_delta: float) -> void:
	var t = phase_timer / clamp_time
	clamp_progress = ease(t, 0.5)
	
	if phase_timer >= clamp_time:
		# Play clamp release sound
		AudioManager.play_sfx("airlock_open")
		_transition_to(Phase.SEPARATION)
		status_changed.emit("CLAMPS RELEASED - SEPARATING")


func _process_separation(_delta: float) -> void:
	var t = phase_timer / separation_time
	var eased = ease(t, 0.4)
	
	# Ship drifts forward slightly
	ship_pos.x = lerpf(0, dock_w * 0.15, eased)
	
	# Slight wobble
	ship_rot = sin(phase_timer * 8) * 0.03 * (1.0 - t)
	ship_visual.position = ship_pos
	ship_visual.rotation = ship_rot
	
	if phase_timer >= separation_time:
		# Play engine ignition sound
		AudioManager.play_sfx("engine_boost")
		_transition_to(Phase.ACCELERATION)
		status_changed.emit("ENGINES ONLINE - FULL THRUST")
		ship_visual.engines_active = true


func _process_acceleration(_delta: float) -> void:
	var t = phase_timer / acceleration_time
	var eased = ease(t, 2.0)  # Exponential acceleration feel
	
	# Engine ramps up
	engine_intensity = lerpf(0.0, 1.0, minf(t * 2, 1.0))
	
	# Ship accelerates through dock
	ship_pos.x = lerpf(dock_w * 0.15, dock_w * 0.8, eased)
	ship_visual.position = ship_pos
	
	# Dock starts to recede
	dock_offset = lerpf(0, dock_w * 0.3, eased)
	
	# Start speed lines
	speed_line_intensity = lerpf(0, 0.5, t)
	
	# Camera shake
	var shake = randf_range(-2, 2) * (1.0 - t * 0.5)
	ship_visual.position.y += shake
	
	# Straighten rotation
	ship_rot = lerpf(ship_rot, 0, t)
	ship_visual.rotation = ship_rot
	
	if phase_timer >= acceleration_time:
		_transition_to(Phase.SPACE_FLIGHT)
		status_changed.emit("CLEAR OF STATION - EN ROUTE TO HIDEOUT")


func _process_space_flight(_delta: float) -> void:
	var t = phase_timer / space_flight_time
	var eased = ease(t, 0.6)
	
	# Ship continues forward, dock fully recedes
	ship_pos.x = lerpf(dock_w * 0.8, 0, eased)  # Move back to center for transition
	ship_visual.position = ship_pos
	
	# Dock disappears behind
	dock_offset = lerpf(dock_w * 0.3, dock_w * 3, eased)
	
	# Full speed lines
	speed_line_intensity = lerpf(0.5, 1.0, minf(t * 2, 1.0))
	
	# Slight camera settle
	var settle = (1.0 - t) * randf_range(-1, 1)
	ship_visual.position.y += settle
	
	if phase_timer >= space_flight_time:
		_transition_to(Phase.BLEND_OUT)
		status_changed.emit("")


func _process_blend_out(_delta: float) -> void:
	var t = phase_timer / blend_out_time
	
	# Fade speed lines
	speed_line_intensity = lerpf(1.0, 0.0, t)
	
	# Slight fade (not full black - blend into escape scene)
	fade_alpha = lerpf(0, 0.3, ease(t, 0.5))
	
	if phase_timer >= blend_out_time:
		undocking_complete.emit()


func _transition_to(phase: Phase) -> void:
	current_phase = phase
	phase_timer = 0.0
	undocking_progress.emit(float(phase) / float(Phase.BLEND_OUT))


# ==============================================================================
# DRAWING FUNCTIONS
# ==============================================================================

func _draw_space_background() -> void:
	# Deep space
	var space_rect = Rect2(-screen_center, screen_center * 2)
	draw_rect(space_rect, space_color)
	
	# Distant stars (small, don't move much)
	for star in distant_stars:
		var pos: Vector2 = star.pos
		var size: float = star.size
		var brightness: float = star.brightness
		
		# Subtle twinkle
		var twinkle = 0.8 + sin(Time.get_ticks_msec() * 0.003 + star.seed) * 0.2
		var col = Color(1, 1, 1, brightness * twinkle)
		draw_circle(pos, size, col)
	
	# Near stars (larger, parallax with dock movement)
	for star in stars:
		var base_pos: Vector2 = star.pos
		var pos = base_pos - Vector2(dock_offset * 0.1, 0)
		var size: float = star.size
		var col: Color = star.color
		
		# Speed line effect when moving fast
		if speed_line_intensity > 0.1:
			var streak_len = speed_line_intensity * 30 * size
			draw_line(pos, pos - Vector2(streak_len, 0), col, size)
		else:
			draw_circle(pos, size, col)


func _draw_docking_bay() -> void:
	var w = dock_w
	var h = dock_h
	var offset_x = -dock_offset
	
	# Only draw if visible
	if offset_x < -w * 1.5:
		return
	
	var alpha = clampf(1.0 - dock_offset / (dock_w * 1.5), 0, 1)
	var wall_col = Color(dock_wall_color, dock_wall_color.a * alpha)
	var metal_col = Color(dock_metal_color, dock_metal_color.a * alpha)
	var accent_col = Color(dock_accent, dock_accent.a * alpha)
	
	# Back wall
	var back = Rect2(Vector2(-w * 0.55 + offset_x, -h * 0.5), Vector2(w * 0.12, h))
	draw_rect(back, wall_col)
	
	# Floor (3D perspective)
	var floor_pts = PackedVector2Array([
		Vector2(-w * 0.55 + offset_x, h * 0.38),
		Vector2(w * 0.7, h * 0.52),
		Vector2(w * 0.7, h * 0.58),
		Vector2(-w * 0.55 + offset_x, h * 0.48)
	])
	draw_polygon(floor_pts, [metal_col])
	
	# Ceiling
	var ceil_pts = PackedVector2Array([
		Vector2(-w * 0.55 + offset_x, -h * 0.38),
		Vector2(w * 0.7, -h * 0.52),
		Vector2(w * 0.7, -h * 0.58),
		Vector2(-w * 0.55 + offset_x, -h * 0.48)
	])
	draw_polygon(ceil_pts, [metal_col])
	
	# Side walls
	var side_top = PackedVector2Array([
		Vector2(-w * 0.43 + offset_x, -h * 0.5),
		Vector2(w * 0.7, -h * 0.58),
		Vector2(w * 0.7, -h * 0.48),
		Vector2(-w * 0.43 + offset_x, -h * 0.35)
	])
	var side_bot = PackedVector2Array([
		Vector2(-w * 0.43 + offset_x, h * 0.5),
		Vector2(w * 0.7, h * 0.58),
		Vector2(w * 0.7, h * 0.48),
		Vector2(-w * 0.43 + offset_x, h * 0.35)
	])
	draw_polygon(side_top, [wall_col.lightened(0.05)])
	draw_polygon(side_bot, [wall_col.lightened(0.05)])
	
	# Floor guide lines
	for i in 6:
		var lx = -w * 0.35 + offset_x + i * w * 0.15
		if lx > -w and lx < w:
			var line_col = Color(accent_col.r, accent_col.g, accent_col.b, accent_col.a * 0.4)
			draw_line(Vector2(lx, h * 0.38), Vector2(lx + w * 0.08, h * 0.5), line_col, 1.5)
	
	# Docking clamps
	_draw_clamps(offset_x, alpha)
	
	# Warning lights (only when docked/releasing)
	if dock_offset < dock_w * 0.5:
		_draw_warning_lights(offset_x, alpha)
	
	# Exit frame (the opening to space)
	var frame_col = Color(0.25, 0.28, 0.32, alpha)
	# Top frame
	draw_rect(Rect2(Vector2(w * 0.35, -h * 0.55), Vector2(w * 0.4, h * 0.08)), frame_col)
	# Bottom frame
	draw_rect(Rect2(Vector2(w * 0.35, h * 0.47), Vector2(w * 0.4, h * 0.08)), frame_col)


func _draw_clamps(offset_x: float, alpha: float) -> void:
	var w = dock_w
	var h = dock_h
	var open = clamp_progress
	
	var clamp_col = Color(0.35, 0.32, 0.28, alpha)
	var clamp_hi = Color(0.45, 0.42, 0.38, alpha)
	
	# Upper clamp arm
	var u_base_y = -h * 0.12
	var u_open_offset = -open * h * 0.25
	var u_pts = PackedVector2Array([
		Vector2(-w * 0.12 + offset_x, u_base_y + u_open_offset),
		Vector2(w * 0.08 + offset_x, u_base_y + u_open_offset - 8),
		Vector2(w * 0.08 + offset_x, u_base_y + u_open_offset - 20),
		Vector2(-w * 0.12 + offset_x, u_base_y + u_open_offset - 25)
	])
	draw_polygon(u_pts, [clamp_col])
	draw_line(u_pts[0], u_pts[1], clamp_hi, 2.0)
	
	# Lower clamp arm
	var l_base_y = h * 0.12
	var l_open_offset = open * h * 0.25
	var l_pts = PackedVector2Array([
		Vector2(-w * 0.12 + offset_x, l_base_y + l_open_offset),
		Vector2(w * 0.08 + offset_x, l_base_y + l_open_offset + 8),
		Vector2(w * 0.08 + offset_x, l_base_y + l_open_offset + 20),
		Vector2(-w * 0.12 + offset_x, l_base_y + l_open_offset + 25)
	])
	draw_polygon(l_pts, [clamp_col])
	draw_line(l_pts[0], l_pts[1], clamp_hi, 2.0)


func _draw_warning_lights(offset_x: float, alpha: float) -> void:
	var w = dock_w
	var h = dock_h
	
	var light_col: Color
	if warning_on:
		light_col = Color(warning_color.r, warning_color.g, warning_color.b, alpha)
	else:
		var dim = 0.3
		light_col = Color(
			warning_color.r * dim, warning_color.g * dim, 
			warning_color.b * dim, alpha * 0.6
		)
	
	# Multiple warning lights around the dock
	var positions = [
		Vector2(-w * 0.32 + offset_x, -h * 0.4),
		Vector2(-w * 0.32 + offset_x, h * 0.4),
		Vector2(w * 0.15, -h * 0.5),
		Vector2(w * 0.15, h * 0.5),
	]
	
	for pos in positions:
		draw_circle(pos, 6, light_col)
		if warning_on:
			# Glow effect
			draw_circle(pos, 12, Color(light_col.r, light_col.g, light_col.b, light_col.a * 0.3))


func _draw_speed_lines() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = int(Time.get_ticks_msec() / 50)  # Change every 50ms
	
	var line_count = int(20 * speed_line_intensity)
	var line_col = Color(0.7, 0.8, 1.0, speed_line_intensity * 0.4)
	
	for i in line_count:
		var y = rng.randf_range(-screen_center.y, screen_center.y)
		var length = rng.randf_range(50, 200) * speed_line_intensity
		var x_start = rng.randf_range(-screen_center.x * 0.5, screen_center.x)
		
		draw_line(
			Vector2(x_start, y),
			Vector2(x_start - length, y),
			line_col,
			rng.randf_range(1, 2.5)
		)


func _draw_engine_glow() -> void:
	# Extra glow behind ship during acceleration
	var glow_pos = ship_pos - Vector2(40, 0)
	var glow_size = 30 * engine_intensity
	var glow_col = Color(0.3, 0.6, 1.0, engine_intensity * 0.4)
	
	draw_circle(glow_pos, glow_size, glow_col)
	draw_circle(glow_pos, glow_size * 0.6, Color(0.5, 0.8, 1.0, engine_intensity * 0.3))


# ==============================================================================
# STAR GENERATION
# ==============================================================================

func _generate_stars() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	# Distant small stars
	for i in 80:
		distant_stars.append({
			"pos": Vector2(
				rng.randf_range(-screen_center.x * 1.2, screen_center.x * 1.2),
				rng.randf_range(-screen_center.y * 1.2, screen_center.y * 1.2)
			),
			"size": rng.randf_range(0.5, 1.5),
			"brightness": rng.randf_range(0.3, 0.7),
			"seed": rng.randf() * 1000
		})
	
	# Nearer stars with color
	for i in 40:
		var col_idx = rng.randi() % 3
		var base_col = Color(1, 1, 1)
		match col_idx:
			0: base_col = Color(1.0, 1.0, 1.0)      # White
			1: base_col = Color(0.9, 0.95, 1.0)    # Blue-white
			2: base_col = Color(1.0, 0.95, 0.85)   # Warm
		
		stars.append({
			"pos": Vector2(
				rng.randf_range(-screen_center.x * 1.5, screen_center.x * 1.5),
				rng.randf_range(-screen_center.y * 1.2, screen_center.y * 1.2)
			),
			"size": rng.randf_range(1.5, 3.0),
			"color": Color(base_col, rng.randf_range(0.5, 1.0))
		})


# ==============================================================================
# PUBLIC API
# ==============================================================================

func start_undocking(type: ShipVisual.ShipType, data: Resource = null) -> void:
	ship_type = type
	station_data = data
	
	# Configure ship
	ship_visual.set_ship_type(type)
	ship_visual.engines_active = false
	ship_visual.position = Vector2.ZERO
	ship_visual.rotation = 0
	ship_pos = Vector2.ZERO
	
	# Dock size based on ship
	match type:
		ShipVisual.ShipType.CARGO:
			dock_w = 550.0
			dock_h = 300.0
		ShipVisual.ShipType.FIGHTER:
			dock_w = 400.0
			dock_h = 220.0
		_:
			dock_w = 450.0
			dock_h = 260.0
	
	# Reset state
	fade_alpha = 1.0
	clamp_progress = 0.0
	dock_offset = 0.0
	engine_intensity = 0.0
	speed_line_intensity = 0.0
	
	# Start sequence
	_transition_to(Phase.FADE_IN)


func skip_animation() -> void:
	# Jump to end
	fade_alpha = 0.3
	speed_line_intensity = 0.0
	undocking_complete.emit()


func get_total_duration() -> float:
	return (fade_in_time + docked_pause + clamp_time + 
			separation_time + acceleration_time + 
			space_flight_time + blend_out_time)
