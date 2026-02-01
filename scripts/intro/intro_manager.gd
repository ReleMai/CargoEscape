# ==============================================================================
# INTRO MANAGER - HIDEOUT DEPARTURE + MAIN MENU
# ==============================================================================
#
# FILE: scripts/intro/intro_manager.gd
# PURPOSE: Shows player ship leaving hideout, cruising through space, with menu
#
# FLOW:
# 1. Background: Ship cruising through space (looping)
# 2. Menu overlay visible
# 3. On "New Game": Fade to docking sequence, then to boarding
#
# ==============================================================================

extends Control
class_name IntroManager


# ==============================================================================
# PRELOADS
# ==============================================================================

const ItemDB = preload("res://scripts/loot/item_database.gd")


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var title_label: Label = $UI/TitleLabel
@onready var subtitle_label: Label = $UI/SubtitleLabel
@onready var skip_hint: Label = $UI/SkipHint
@onready var flash_overlay: ColorRect = $FlashOverlay
@onready var menu_container: Control = $UI/MenuContainer
@onready var start_button: Button = $UI/MenuContainer/StartButton
@onready var quit_button: Button = $UI/MenuContainer/QuitButton
@onready var footer_label: Label = $UI/Footer
@onready var dev_menu: Control = $UI/DevMenu
@onready var dev_hideout_button: Button = $UI/DevMenu/HideoutButton
@onready var dev_escape_button: Button = $UI/DevMenu/EscapeButton
@onready var dev_boarding_button: Button = $UI/DevMenu/BoardingButton


# ==============================================================================
# STATE
# ==============================================================================

var screen_w: float = 1280.0
var screen_h: float = 720.0

# Stars (parallax layers)
var stars_far: Array = []
var stars_mid: Array = []
var stars_near: Array = []

# Ship state (cruising through space)
var ship_bob_time: float = 0.0
var engine_flicker: float = 0.0

# Transition state
var is_transitioning: bool = false
var transition_phase: int = 0  # 0=none, 1=fadeout, 2=docking, 3=fadein_boarding
var transition_timer: float = 0.0

# Docking animation (during transition)
var dock_ship_x: float = 0.0
var dock_ship_scale: float = 0.5
var target_ship_x: float = 0.0
var target_ship_scale: float = 0.3
var dock_clamps: float = 0.0

# Transition effects
var camera_shake: float = 0.0
var camera_offset: Vector2 = Vector2.ZERO
var speed_lines: Array = []
var flash_alpha: float = 0.0
var zoom_factor: float = 1.0


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	var vp = get_viewport_rect().size
	screen_w = vp.x
	screen_h = vp.y
	
	_generate_stars()
	_setup_ui()
	_connect_signals()


func _process(delta: float) -> void:
	ship_bob_time += delta
	engine_flicker += delta * 15.0
	
	# Scroll stars continuously
	_scroll_stars(delta)
	
	# Handle transition
	if is_transitioning:
		_process_transition(delta)
		_update_camera_shake(delta)
		_update_speed_lines(delta)
	
	# Decay flash
	if flash_alpha > 0:
		flash_alpha = maxf(0, flash_alpha - delta * 3.0)
	
	queue_redraw()


func _draw() -> void:
	# Apply camera offset from shake
	draw_set_transform(camera_offset, 0, Vector2(zoom_factor, zoom_factor))
	
	# Space background
	draw_rect(Rect2(-50, -50, screen_w + 100, screen_h + 100), Color(0.01, 0.015, 0.03))
	
	# Draw star layers (parallax)
	_draw_stars()
	
	# Draw speed lines during high-speed transition
	if speed_lines.size() > 0:
		_draw_speed_lines()
	
	if is_transitioning and transition_phase >= 2:
		# Draw docking scene
		_draw_docking_scene()
	else:
		# Draw cruising ship
		_draw_cruising_ship()
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	
	# Transition fade (not affected by camera)
	if is_transitioning:
		_draw_transition_overlay()
	
	# Flash effect (for impacts/transitions)
	if flash_alpha > 0:
		draw_rect(Rect2(0, 0, screen_w, screen_h), Color(1, 1, 1, flash_alpha))


# ==============================================================================
# STAR SYSTEM
# ==============================================================================

func _generate_stars() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 54321
	
	# Far stars (slowest, smallest)
	for i in range(120):
		stars_far.append({
			"x": rng.randf_range(0, screen_w),
			"y": rng.randf_range(0, screen_h),
			"size": rng.randf_range(0.5, 1.2),
			"brightness": rng.randf_range(0.2, 0.5)
		})
	
	# Mid stars
	for i in range(60):
		stars_mid.append({
			"x": rng.randf_range(0, screen_w),
			"y": rng.randf_range(0, screen_h),
			"size": rng.randf_range(1.0, 2.0),
			"brightness": rng.randf_range(0.4, 0.7)
		})
	
	# Near stars (fastest, biggest)
	for i in range(30):
		stars_near.append({
			"x": rng.randf_range(0, screen_w),
			"y": rng.randf_range(0, screen_h),
			"size": rng.randf_range(1.5, 3.0),
			"brightness": rng.randf_range(0.5, 0.9)
		})


func _scroll_stars(delta: float) -> void:
	var far_speed = 15.0
	var mid_speed = 40.0
	var near_speed = 80.0
	
	for star in stars_far:
		star.x -= far_speed * delta
		if star.x < -5:
			star.x = screen_w + 5
			star.y = randf_range(0, screen_h)
	
	for star in stars_mid:
		star.x -= mid_speed * delta
		if star.x < -5:
			star.x = screen_w + 5
			star.y = randf_range(0, screen_h)
	
	for star in stars_near:
		star.x -= near_speed * delta
		if star.x < -5:
			star.x = screen_w + 5
			star.y = randf_range(0, screen_h)


func _draw_stars() -> void:
	# Far layer
	for star in stars_far:
		var col = Color(0.7, 0.8, 1.0, star.brightness)
		draw_circle(Vector2(star.x, star.y), star.size, col)
	
	# Mid layer
	for star in stars_mid:
		var col = Color(0.9, 0.9, 1.0, star.brightness)
		draw_circle(Vector2(star.x, star.y), star.size, col)
	
	# Near layer
	for star in stars_near:
		var col = Color(1.0, 1.0, 1.0, star.brightness)
		draw_circle(Vector2(star.x, star.y), star.size, col)


# ==============================================================================
# CRUISING SHIP (Main Menu Background)
# ==============================================================================

func _draw_cruising_ship() -> void:
	# Ship bobs gently while cruising
	var bob_y = sin(ship_bob_time * 0.8) * 8
	var bob_rot = sin(ship_bob_time * 0.5) * 0.02
	
	var center = Vector2(screen_w * 0.35, screen_h * 0.55 + bob_y)
	var ship_scale = 0.8
	
	_draw_player_ship(center, ship_scale, bob_rot, true)


func _draw_player_ship(center: Vector2, s: float, rot: float, engines_on: bool) -> void:
	draw_set_transform(center, rot, Vector2(s, s))
	
	# Engine glow (behind ship)
	if engines_on:
		var flicker = 0.8 + sin(engine_flicker) * 0.15
		var glow_col = Color(1.0, 0.5, 0.2, 0.5 * flicker)
		draw_circle(Vector2(-70, 0), 20, glow_col)
		draw_circle(Vector2(-65, -12), 12, glow_col)
		draw_circle(Vector2(-65, 12), 12, glow_col)
		
		# Flame trails
		var flame_col = Color(1.0, 0.3, 0.1, 0.3 * flicker)
		var trail_len = 30 + sin(engine_flicker * 1.3) * 15
		draw_line(Vector2(-70, 0), Vector2(-70 - trail_len, 0), flame_col, 6)
		draw_line(Vector2(-65, -12), Vector2(-65 - trail_len * 0.7, -12), flame_col, 4)
		draw_line(Vector2(-65, 12), Vector2(-65 - trail_len * 0.7, 12), flame_col, 4)
	
	# Main hull
	var hull_col = Color(0.25, 0.55, 0.35)
	var hull = PackedVector2Array([
		Vector2(70, 0),
		Vector2(35, -22),
		Vector2(-55, -25),
		Vector2(-65, -18),
		Vector2(-65, 18),
		Vector2(-55, 25),
		Vector2(35, 22),
	])
	draw_colored_polygon(hull, hull_col)
	
	# Hull detail
	var detail_col = Color(0.2, 0.45, 0.3)
	draw_line(Vector2(-50, -20), Vector2(25, -18), detail_col, 2)
	draw_line(Vector2(-50, 20), Vector2(25, 18), detail_col, 2)
	
	# Cockpit
	var cockpit_col = Color(0.3, 0.7, 0.9, 0.9)
	var cockpit = PackedVector2Array([
		Vector2(65, 0),
		Vector2(45, -10),
		Vector2(28, -8),
		Vector2(28, 8),
		Vector2(45, 10),
	])
	draw_colored_polygon(cockpit, cockpit_col)
	
	# Wings
	var wing_col = Color(0.2, 0.45, 0.3)
	var top_wing = PackedVector2Array([
		Vector2(15, -22),
		Vector2(30, -40),
		Vector2(-15, -48),
		Vector2(-35, -25),
	])
	draw_colored_polygon(top_wing, wing_col)
	
	var bot_wing = PackedVector2Array([
		Vector2(15, 22),
		Vector2(30, 40),
		Vector2(-15, 48),
		Vector2(-35, 25),
	])
	draw_colored_polygon(bot_wing, wing_col)
	
	# Engine housings
	var engine_col = Color(0.3, 0.3, 0.35)
	draw_rect(Rect2(-68, -20, 20, 12), engine_col)
	draw_rect(Rect2(-68, 8, 20, 12), engine_col)
	
	# Running lights
	var light_time = Time.get_ticks_msec() * 0.003
	var light_a = 0.6 + sin(light_time) * 0.4
	draw_circle(Vector2(60, 0), 3, Color(0, 1, 0, light_a))
	draw_circle(Vector2(-25, -30), 2, Color(1, 0, 0, light_a))
	draw_circle(Vector2(-25, 30), 2, Color(1, 0, 0, light_a))
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# ==============================================================================
# DOCKING SCENE (Transition Animation)
# ==============================================================================

func _draw_docking_scene() -> void:
	# Target ship (the one we're boarding)
	_draw_target_ship()
	
	# Player ship approaching
	var center = Vector2(dock_ship_x, screen_h * 0.5)
	_draw_player_ship(center, dock_ship_scale, 0.0, dock_ship_x < screen_w * 0.55)
	
	# Docking clamps
	if dock_clamps > 0:
		_draw_dock_clamps()


func _draw_target_ship() -> void:
	var center = Vector2(target_ship_x, screen_h * 0.5)
	var s = target_ship_scale
	
	draw_set_transform(center, 0, Vector2(s, s))
	
	# Large cargo ship hull
	var hull_col = Color(0.35, 0.32, 0.3)
	draw_rect(Rect2(-200, -80, 400, 160), hull_col)
	
	# Bridge section
	var bridge_col = Color(0.4, 0.38, 0.35)
	draw_rect(Rect2(150, -60, 80, 120), bridge_col)
	
	# Cockpit windows
	var window_col = Color(0.2, 0.4, 0.5, 0.8)
	draw_rect(Rect2(200, -40, 25, 30), window_col)
	draw_rect(Rect2(200, 10, 25, 30), window_col)
	
	# Cargo containers on deck
	var cargo_colors = [
		Color(0.5, 0.3, 0.2),
		Color(0.3, 0.4, 0.3),
		Color(0.4, 0.35, 0.25),
	]
	for i in range(4):
		var cx = -150 + i * 70
		var col = cargo_colors[i % cargo_colors.size()]
		draw_rect(Rect2(cx, -50, 50, 40), col)
		draw_rect(Rect2(cx, 10, 50, 40), col)
	
	# Engine section
	var engine_col = Color(0.3, 0.28, 0.25)
	draw_rect(Rect2(-250, -60, 60, 120), engine_col)
	
	# Docking port (left side, facing player)
	var port_col = Color(0.25, 0.35, 0.4)
	draw_rect(Rect2(-260, -30, 20, 60), port_col)
	
	# Docking lights
	var light_time = Time.get_ticks_msec() * 0.005
	var light_a = 0.5 + sin(light_time) * 0.5
	draw_circle(Vector2(-255, -35), 5, Color(0.2, 1.0, 0.3, light_a))
	draw_circle(Vector2(-255, 35), 5, Color(0.2, 1.0, 0.3, light_a))
	
	# Hull details
	var line_col = Color(0.3, 0.28, 0.26)
	draw_line(Vector2(-200, -40), Vector2(150, -40), line_col, 2)
	draw_line(Vector2(-200, 40), Vector2(150, 40), line_col, 2)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _draw_dock_clamps() -> void:
	var port_x = target_ship_x - 260 * target_ship_scale
	var port_y = screen_h * 0.5
	
	var extend = dock_clamps * 25 * target_ship_scale
	var clamp_col = Color(0.4, 0.4, 0.45)
	
	# Top clamp
	draw_rect(Rect2(
		port_x - 15 * target_ship_scale,
		port_y - 40 * target_ship_scale - extend,
		8 * target_ship_scale,
		extend + 5
	), clamp_col)
	
	# Bottom clamp
	draw_rect(Rect2(
		port_x - 15 * target_ship_scale,
		port_y + 35 * target_ship_scale,
		8 * target_ship_scale,
		extend + 5
	), clamp_col)


# ==============================================================================
# TRANSITION SYSTEM
# ==============================================================================

func _update_camera_shake(delta: float) -> void:
	if camera_shake > 0:
		camera_shake = maxf(0, camera_shake - delta * 8.0)
		camera_offset = Vector2(
			randf_range(-camera_shake, camera_shake),
			randf_range(-camera_shake, camera_shake)
		)
	else:
		camera_offset = Vector2.ZERO


func _update_speed_lines(delta: float) -> void:
	# Move existing speed lines
	for i in range(speed_lines.size() - 1, -1, -1):
		var line = speed_lines[i]
		line.x -= line.speed * delta
		line.life -= delta
		if line.life <= 0 or line.x < -100:
			speed_lines.remove_at(i)


func _spawn_speed_lines(count: int, intensity: float = 1.0) -> void:
	for i in range(count):
		speed_lines.append({
			"x": screen_w + randf_range(0, 200),
			"y": randf_range(0, screen_h),
			"length": randf_range(80, 200) * intensity,
			"speed": randf_range(800, 1500) * intensity,
			"alpha": randf_range(0.3, 0.7),
			"life": randf_range(0.3, 0.8)
		})


func _draw_speed_lines() -> void:
	for line in speed_lines:
		var alpha = line.alpha * (line.life / 0.8)
		var col = Color(0.8, 0.9, 1.0, alpha)
		draw_line(
			Vector2(line.x, line.y),
			Vector2(line.x + line.length, line.y),
			col, 2
		)


func _process_transition(delta: float) -> void:
	transition_timer += delta
	
	match transition_phase:
		1:  # Fade out menu + start warp effect
			# Spawn speed lines to simulate acceleration
			if randf() < 0.3:
				_spawn_speed_lines(3, transition_timer * 0.5)
			
			# Gradual zoom
			zoom_factor = lerpf(1.0, 1.05, transition_timer / 1.2)
			
			if transition_timer >= 1.2:
				# Flash and shake when "jumping"
				flash_alpha = 0.8
				camera_shake = 15.0
				transition_phase = 2
				transition_timer = 0.0
				# Initialize docking positions (ships appear mid-warp)
				dock_ship_x = screen_w * 0.2
				dock_ship_scale = 0.4
				target_ship_x = screen_w * 0.85
				target_ship_scale = 0.5
		
		2:  # Docking animation
			var t = minf(transition_timer / 3.5, 1.0)
			var eased = ease(t, 0.3)
			
			# Player ship approaches from current position
			dock_ship_x = lerpf(screen_w * 0.2, screen_w * 0.38, eased)
			dock_ship_scale = lerpf(0.4, 0.6, eased)
			
			# Target ship slows down to meet
			target_ship_x = lerpf(screen_w * 0.85, screen_w * 0.7, eased)
			target_ship_scale = lerpf(0.5, 0.7, eased)
			
			# Zoom settles back
			zoom_factor = lerpf(1.05, 1.0, minf(t * 2, 1.0))
			
			# Clamps engage in final phase
			if t > 0.75:
				dock_clamps = (t - 0.75) / 0.25
				# Small shake when clamps engage
				if dock_clamps < 0.1:
					camera_shake = 5.0
			
			# Docking complete - flash and transition
			if transition_timer >= 3.8:
				flash_alpha = 1.0
				camera_shake = 20.0
				transition_phase = 3
				transition_timer = 0.0
		
		3:  # Fade to boarding (fast, hidden by flash)
			zoom_factor = lerpf(1.0, 1.15, transition_timer / 0.5)
			if transition_timer >= 0.5:
				_go_to_boarding()


func _draw_transition_overlay() -> void:
	var alpha = 0.0
	
	match transition_phase:
		1:  # Fade out with vignette
			var t = transition_timer / 1.2
			alpha = ease(t, 0.5) * 0.2
			# Draw vignette effect
			_draw_vignette(0.3 + t * 0.3)
		2:  # Docking - slight vignette
			_draw_vignette(0.2)
		3:  # Fast fade to black (hidden by flash)
			alpha = ease(transition_timer / 0.5, 2.0)
	
	if alpha > 0:
		draw_rect(Rect2(0, 0, screen_w, screen_h), Color(0, 0, 0, alpha))


func _draw_vignette(intensity: float) -> void:
	# Simple corner darkening
	var corner_size = 300.0
	var corner_alpha = 0.4 * intensity
	
	# Top-left
	for i in range(5):
		var a = corner_alpha * (1.0 - i / 5.0)
		var s = corner_size * (1.0 - i / 5.0)
		draw_rect(Rect2(0, 0, s, s * 0.3), Color(0, 0, 0, a * 0.3))
	
	# Top-right
	for i in range(5):
		var a = corner_alpha * (1.0 - i / 5.0)
		var s = corner_size * (1.0 - i / 5.0)
		draw_rect(Rect2(screen_w - s, 0, s, s * 0.3), Color(0, 0, 0, a * 0.3))
	
	# Bottom corners
	for i in range(5):
		var a = corner_alpha * (1.0 - i / 5.0)
		var s = corner_size * (1.0 - i / 5.0)
		draw_rect(Rect2(0, screen_h - s * 0.3, s, s * 0.3), Color(0, 0, 0, a * 0.3))
		draw_rect(Rect2(screen_w - s, screen_h - s * 0.3, s, s * 0.3), Color(0, 0, 0, a * 0.3))


func _start_transition() -> void:
	is_transitioning = true
	transition_phase = 1
	transition_timer = 0.0
	zoom_factor = 1.0
	speed_lines.clear()
	
	# Fade out UI
	var tween = create_tween()
	tween.set_parallel(true)
	if title_label:
		tween.tween_property(title_label, "modulate:a", 0.0, 0.4)
	if subtitle_label:
		tween.tween_property(subtitle_label, "modulate:a", 0.0, 0.4)
	if menu_container:
		tween.tween_property(menu_container, "modulate:a", 0.0, 0.3)
	if footer_label:
		tween.tween_property(footer_label, "modulate:a", 0.0, 0.2)
	if dev_menu:
		tween.tween_property(dev_menu, "modulate:a", 0.0, 0.2)


# ==============================================================================
# UI SETUP
# ==============================================================================

func _setup_ui() -> void:
	# Show menu immediately (no intro animation needed)
	if title_label:
		title_label.text = "CARGO ESCAPE"
		title_label.modulate.a = 1.0
	
	if subtitle_label:
		subtitle_label.text = "Intercept. Board. Loot. Escape."
		subtitle_label.modulate.a = 0.7
	
	if menu_container:
		menu_container.visible = true
		menu_container.modulate.a = 1.0
	
	if footer_label:
		footer_label.modulate.a = 0.5
	
	if skip_hint:
		skip_hint.visible = false
	
	if flash_overlay:
		flash_overlay.modulate.a = 0.0
	
	# Focus start button
	if start_button:
		start_button.call_deferred("grab_focus")


func _connect_signals() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	if dev_hideout_button:
		dev_hideout_button.pressed.connect(_on_dev_hideout)
	if dev_escape_button:
		dev_escape_button.pressed.connect(_on_dev_escape)
	if dev_boarding_button:
		dev_boarding_button.pressed.connect(_on_dev_boarding)


# ==============================================================================
# BUTTON HANDLERS
# ==============================================================================

func _on_start_pressed() -> void:
	if is_transitioning:
		return
	
	# Setup game state
	if GameManager:
		GameManager.reset_game()
		GameManager.initialize_starting_equipment()
		var station_data = preload("res://resources/stations/abandoned_station.tres")
		GameManager.set_current_station(station_data)
	
	# Start seamless transition
	_start_transition()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _go_to_boarding() -> void:
	get_tree().change_scene_to_file("res://scenes/boarding/boarding_scene.tscn")


# ==============================================================================
# DEV MENU
# ==============================================================================

func _on_dev_hideout() -> void:
	if GameManager:
		_add_test_items()
	get_tree().change_scene_to_file("res://scenes/hideout/hideout_scene.tscn")


func _on_dev_escape() -> void:
	if GameManager:
		GameManager.reset_game()
		_add_test_items()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_dev_boarding() -> void:
	if GameManager:
		GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/boarding/boarding_scene.tscn")


func _add_test_items() -> void:
	if not GameManager:
		return
	
	var test_items = [
		"scrap_metal", "wire_bundle", "copper_wire", "plasma_coil",
		"med_kit", "gold_bar", "weapon_core", "alien_artifact"
	]
	
	for item_id in test_items:
		var item = ItemDB.create_item(item_id)
		if item:
			GameManager.add_to_ship_inventory(item)
