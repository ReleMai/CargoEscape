# ==============================================================================
# INTRO SEQUENCE - LOGO, TEXT CRAWL, TITLE CARD
# ==============================================================================
#
# FILE: scripts/intro/intro_sequence.gd
# PURPOSE: Engaging intro sequence with logo, scene setting, and title reveal
#
# FLOW:
# 1. Logo Phase (2s): Game logo fades in with glow/particles
# 2. Scene Setting (5s): Pan across space with text crawl
# 3. Title Card (2s): "CARGO ESCAPE" with tagline
# 4. Menu Transition: Ship flies in, camera follows to main menu
#
# FEATURES:
# - Skippable after first view
# - Settings to disable on startup
# - Music sync with visuals (future)
#
# ==============================================================================

extends Control
class_name IntroSequence


# ==============================================================================
# CONSTANTS
# ==============================================================================

## Duration of each phase in seconds
const LOGO_DURATION: float = 2.0
const SCENE_SETTING_DURATION: float = 5.0
const TITLE_CARD_DURATION: float = 2.0
const TRANSITION_DURATION: float = 3.0

## Particle system constants
const PARTICLE_SPAWN_PROBABILITY: float = 0.3
const MIN_GLOW_FOR_PARTICLES: float = 0.3

## Text crawl content
const CRAWL_TEXT: Array[String] = [
	"In the lawless sectors of space...",
	"Fortune favors the bold...",
	"And the quick."
]


# ==============================================================================
# SEQUENCE PHASES
# ==============================================================================

enum Phase {
	LOGO,           # Game logo fades in with glow
	SCENE_SETTING,  # Pan across space with text crawl
	TITLE_CARD,     # Main title reveal
	TRANSITION,     # Ship animation to menu
	COMPLETE        # Sequence finished
}


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var logo_container: Control = $LogoContainer
@onready var logo_label: Label = $LogoContainer/LogoLabel
@onready var logo_glow: ColorRect = $LogoContainer/GlowEffect

@onready var scene_container: Control = $SceneContainer
@onready var crawl_label: Label = $SceneContainer/CrawlLabel

@onready var title_container: Control = $TitleContainer
@onready var title_label: Label = $TitleContainer/TitleLabel
@onready var tagline_label: Label = $TitleContainer/TaglineLabel

@onready var skip_hint: Label = $SkipHint

# Particle system
var logo_particles: Array = []


# ==============================================================================
# STATE
# ==============================================================================

var current_phase: Phase = Phase.LOGO
var phase_timer: float = 0.0
var total_time: float = 0.0

# Background animation
var stars: Array = []
var screen_w: float = 1280.0
var screen_h: float = 720.0
var pan_offset: float = 0.0

# Logo animation
var logo_alpha: float = 0.0
var glow_intensity: float = 0.0
var glow_pulse_time: float = 0.0

# Text crawl
var crawl_text_index: int = 0
var crawl_alpha: float = 0.0
var crawl_position: float = 0.0

# Title card
var title_alpha: float = 0.0
var title_scale: float = 0.8

# Transition animation (ship flies in)
var ship_x: float = 0.0
var ship_y: float = 0.0
var ship_scale: float = 0.3
var camera_follow: Vector2 = Vector2.ZERO

# Skip functionality
var has_been_viewed: bool = false
var can_skip: bool = false


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	var vp = get_viewport_rect().size
	screen_w = vp.x
	screen_h = vp.y
	
	_generate_stars()
	_setup_ui()
	
	# Check if intro has been viewed before
	if ProjectSettings.has_setting("intro/has_been_viewed"):
		has_been_viewed = ProjectSettings.get_setting("intro/has_been_viewed")
		can_skip = has_been_viewed
	
	# Check if intro is disabled in settings
	if ProjectSettings.has_setting("intro/disable_on_startup") and \
	   ProjectSettings.get_setting("intro/disable_on_startup"):
		_skip_to_menu()
		return
	
	_start_phase(Phase.LOGO)


func _process(delta: float) -> void:
	total_time += delta
	phase_timer += delta
	
	# Update background
	_update_stars(delta)
	
	# Update current phase
	match current_phase:
		Phase.LOGO:
			_update_logo_phase(delta)
		Phase.SCENE_SETTING:
			_update_scene_setting_phase(delta)
		Phase.TITLE_CARD:
			_update_title_card_phase(delta)
		Phase.TRANSITION:
			_update_transition_phase(delta)
	
	queue_redraw()


func _input(event: InputEvent) -> void:
	# Allow skipping with Space key if allowed
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("fire"):
		if can_skip:
			_skip_to_menu()


func _draw() -> void:
	# Apply camera follow offset during transition
	if current_phase == Phase.TRANSITION:
		draw_set_transform(camera_follow, 0, Vector2.ONE)
	
	# Draw space background
	draw_rect(Rect2(0, 0, screen_w, screen_h), Color(0.01, 0.015, 0.03))
	
	# Draw stars with pan offset for scene setting phase
	_draw_stars()
	
	# Draw logo particles
	if current_phase == Phase.LOGO:
		_draw_logo_particles()
	
	# Draw ship during transition
	if current_phase == Phase.TRANSITION:
		_draw_transition_ship()
	
	# Reset transform
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


# ==============================================================================
# PHASE MANAGEMENT
# ==============================================================================

func _start_phase(phase: Phase) -> void:
	current_phase = phase
	phase_timer = 0.0
	
	match phase:
		Phase.LOGO:
			logo_container.visible = true
			logo_alpha = 0.0
			glow_intensity = 0.0
			scene_container.visible = false
			title_container.visible = false
		
		Phase.SCENE_SETTING:
			logo_container.visible = false
			scene_container.visible = true
			title_container.visible = false
			crawl_text_index = 0
			crawl_alpha = 0.0
			pan_offset = 0.0
		
		Phase.TITLE_CARD:
			logo_container.visible = false
			scene_container.visible = false
			title_container.visible = true
			title_alpha = 0.0
			title_scale = 0.8
		
		Phase.TRANSITION:
			# Fade out title card
			var tween = create_tween()
			tween.tween_property(title_container, "modulate:a", 0.0, 0.5)
			
			# Initialize ship position
			ship_x = -200
			ship_y = screen_h * 0.3
			ship_scale = 0.3
			camera_follow = Vector2.ZERO
		
		Phase.COMPLETE:
			_complete_sequence()


# ==============================================================================
# LOGO PHASE
# ==============================================================================

func _update_logo_phase(delta: float) -> void:
	glow_pulse_time += delta * 3.0
	
	# Fade in logo over first half
	if phase_timer < LOGO_DURATION * 0.5:
		logo_alpha = phase_timer / (LOGO_DURATION * 0.5)
	else:
		logo_alpha = 1.0
	
	# Glow builds up
	glow_intensity = minf(phase_timer / LOGO_DURATION, 1.0)
	
	# Apply to logo
	if logo_label:
		logo_label.modulate.a = logo_alpha
	
	# Animate glow
	if logo_glow:
		var pulse = 0.5 + sin(glow_pulse_time) * 0.3
		logo_glow.modulate.a = glow_intensity * pulse * 0.6
		var glow_scale = 1.0 + sin(glow_pulse_time * 0.5) * 0.1
		logo_glow.scale = Vector2(glow_scale, glow_scale)
	
	# Spawn particles around logo
	if randf() < PARTICLE_SPAWN_PROBABILITY and glow_intensity > MIN_GLOW_FOR_PARTICLES:
		_spawn_logo_particle()
	
	# Update particles
	_update_logo_particles(delta)
	
	# Transition to next phase
	if phase_timer >= LOGO_DURATION:
		_start_phase(Phase.SCENE_SETTING)


# ==============================================================================
# SCENE SETTING PHASE (TEXT CRAWL)
# ==============================================================================

func _update_scene_setting_phase(delta: float) -> void:
	# Pan across space background
	pan_offset += delta * 50.0
	
	# Calculate which text line to show
	var time_per_line = SCENE_SETTING_DURATION / CRAWL_TEXT.size()
	var current_line = int(phase_timer / time_per_line)
	
	if current_line != crawl_text_index and current_line < CRAWL_TEXT.size():
		crawl_text_index = current_line
		crawl_alpha = 0.0
		if crawl_label:
			crawl_label.text = CRAWL_TEXT[crawl_text_index]
	
	# Fade in/out text
	var line_time = fmod(phase_timer, time_per_line)
	var fade_duration = 0.5
	
	if line_time < fade_duration:
		crawl_alpha = line_time / fade_duration
	elif line_time > time_per_line - fade_duration:
		crawl_alpha = (time_per_line - line_time) / fade_duration
	else:
		crawl_alpha = 1.0
	
	if crawl_label:
		crawl_label.modulate.a = crawl_alpha
		# Slight upward drift
		crawl_position = -line_time * 10.0
		crawl_label.position.y = screen_h * 0.5 + crawl_position
	
	# Transition to next phase
	if phase_timer >= SCENE_SETTING_DURATION:
		_start_phase(Phase.TITLE_CARD)


# ==============================================================================
# TITLE CARD PHASE
# ==============================================================================

func _update_title_card_phase(delta: float) -> void:
	# Fade in and scale up
	var t = minf(phase_timer / (TITLE_CARD_DURATION * 0.5), 1.0)
	title_alpha = ease(t, 0.5)
	title_scale = 0.8 + ease(t, 0.3) * 0.2
	
	if title_label:
		title_label.modulate.a = title_alpha
		title_label.scale = Vector2(title_scale, title_scale)
	
	if tagline_label:
		# Tagline appears slightly delayed
		var tagline_t = maxf(0, (phase_timer - 0.3) / (TITLE_CARD_DURATION * 0.5))
		tagline_label.modulate.a = minf(tagline_t, 1.0)
	
	# Transition to next phase
	if phase_timer >= TITLE_CARD_DURATION:
		_start_phase(Phase.TRANSITION)


# ==============================================================================
# TRANSITION PHASE
# ==============================================================================

func _update_transition_phase(delta: float) -> void:
	# Ship flies in from left
	var t = minf(phase_timer / TRANSITION_DURATION, 1.0)
	var eased = ease(t, 0.4)
	
	# Ship movement
	ship_x = lerpf(-200, screen_w * 0.5, eased)
	ship_y = lerpf(screen_h * 0.3, screen_h * 0.5, eased * 0.5)
	ship_scale = lerpf(0.3, 0.6, eased)
	
	# Camera follows ship slightly
	camera_follow = Vector2(
		(ship_x - screen_w * 0.5) * 0.1,
		(ship_y - screen_h * 0.5) * 0.1
	)
	
	# Simple fade to black then to menu
	if phase_timer >= TRANSITION_DURATION:
		_start_phase(Phase.COMPLETE)


# ==============================================================================
# STAR SYSTEM
# ==============================================================================

func _generate_stars() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	for i in range(150):
		stars.append({
			"x": rng.randf_range(0, screen_w),
			"y": rng.randf_range(0, screen_h),
			"size": rng.randf_range(0.5, 2.5),
			"brightness": rng.randf_range(0.3, 0.9),
			"layer": rng.randi_range(0, 2)  # 0=far, 1=mid, 2=near
		})


func _update_stars(delta: float) -> void:
	for star in stars:
		# Different scroll speeds based on layer
		var speed_multiplier = 1.0 + star.layer * 0.5
		var scroll_speed = 30.0 * speed_multiplier
		
		# Add pan effect during scene setting
		if current_phase == Phase.SCENE_SETTING:
			scroll_speed += 20.0 * speed_multiplier
		
		star.x -= scroll_speed * delta
		
		# Wrap around
		if star.x < -5:
			star.x = screen_w + 5
			star.y = randf_range(0, screen_h)


func _draw_stars() -> void:
	for star in stars:
		var pos = Vector2(star.x, star.y)
		
		# Add parallax offset during scene setting
		if current_phase == Phase.SCENE_SETTING:
			pos.x -= pan_offset * (1.0 + star.layer * 0.3)
		
		var col = Color(0.8, 0.9, 1.0, star.brightness)
		draw_circle(pos, star.size, col)


# ==============================================================================
# UI SETUP
# ==============================================================================

func _setup_ui() -> void:
	# Setup logo
	if logo_label:
		logo_label.text = "CARGO ESCAPE"
		logo_label.modulate.a = 0.0
	
	if logo_glow:
		logo_glow.modulate.a = 0.0
	
	# Setup text crawl
	if crawl_label:
		crawl_label.text = ""
		crawl_label.modulate.a = 0.0
	
	# Setup title card
	if title_label:
		title_label.text = "CARGO ESCAPE"
		title_label.modulate.a = 0.0
	
	if tagline_label:
		tagline_label.text = "Loot. Escape. Survive."
		tagline_label.modulate.a = 0.0
	
	# Setup skip hint
	if skip_hint:
		skip_hint.visible = can_skip
		skip_hint.text = "Press SPACE to skip"


# ==============================================================================
# COMPLETION
# ==============================================================================

func _complete_sequence() -> void:
	# Mark as viewed
	if not has_been_viewed:
		ProjectSettings.set_setting("intro/has_been_viewed", true)
		var err = ProjectSettings.save()
		if err != OK:
			push_warning("Failed to save intro viewed state: " + str(err))
	
	# Transition to main menu (intro_scene.tscn with menu)
	get_tree().change_scene_to_file("res://scenes/intro/intro_scene.tscn")


func _skip_to_menu() -> void:
	# Mark as viewed and go to menu
	if not has_been_viewed:
		ProjectSettings.set_setting("intro/has_been_viewed", true)
		var err = ProjectSettings.save()
		if err != OK:
			push_warning("Failed to save intro viewed state: " + str(err))
	
	get_tree().change_scene_to_file("res://scenes/intro/intro_scene.tscn")


# ==============================================================================
# PARTICLE SYSTEM (for logo phase)
# ==============================================================================

func _spawn_logo_particle() -> void:
	var center = Vector2(screen_w * 0.5, screen_h * 0.5)
	var angle = randf() * TAU
	var distance = randf_range(200, 400)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	
	logo_particles.append({
		"pos": center + offset,
		"vel": Vector2(cos(angle), sin(angle)) * randf_range(-20, -50),
		"life": randf_range(0.8, 1.5),
		"max_life": randf_range(0.8, 1.5),
		"size": randf_range(2, 5),
		"color": Color(1.0, randf_range(0.7, 0.95), randf_range(0.3, 0.6))
	})


func _update_logo_particles(delta: float) -> void:
	for i in range(logo_particles.size() - 1, -1, -1):
		var p = logo_particles[i]
		p.pos += p.vel * delta
		p.life -= delta
		
		# Add slight drift
		p.vel.y += delta * 10
		
		if p.life <= 0:
			logo_particles.remove_at(i)


func _draw_logo_particles() -> void:
	for p in logo_particles:
		var alpha = p.life / p.max_life
		var col = p.color
		col.a = alpha * 0.7
		draw_circle(p.pos, p.size, col)


func _draw_transition_ship() -> void:
	var center = Vector2(ship_x, ship_y)
	var s = ship_scale
	
	draw_set_transform(center, 0, Vector2(s, s))
	
	# Engine glow
	var engine_flicker = 0.8 + sin(total_time * 15.0) * 0.15
	var glow_col = Color(1.0, 0.5, 0.2, 0.5 * engine_flicker)
	draw_circle(Vector2(-70, 0), 20, glow_col)
	draw_circle(Vector2(-65, -12), 12, glow_col)
	draw_circle(Vector2(-65, 12), 12, glow_col)
	
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
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
