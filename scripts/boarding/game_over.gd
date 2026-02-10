# ==============================================================================
# GAME OVER SCREEN
# ==============================================================================
#
# FILE: scripts/boarding/game_over.gd
# PURPOSE: Displays when player fails to escape in time
#
# FEATURES:
# - Dramatic red flash and shake effect
# - Animated text appearance
# - Slow motion effect
# - Fade transitions
#
# ==============================================================================

extends CanvasLayer
class_name GameOverScreen

# ==============================================================================
# SIGNALS
# ==============================================================================

signal retry_pressed
signal menu_pressed

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var loot_label: Label = %LootLabel
@onready var retry_button: Button = %RetryButton
@onready var menu_button: Button = %MenuButton
@onready var title_label: Label = %TitleLabel
@onready var background: ColorRect = %Background
@onready var content_container: Control = %ContentContainer

# ==============================================================================
# STATE
# ==============================================================================

var lost_loot_value: int = 0
var animation_timer: float = 0.0

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	if retry_button:
		retry_button.pressed.connect(_on_retry_pressed)
	
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
	
	# Pause game while showing
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Play game over music
	AudioManager.play_music("defeat")
	
	# Start dramatic entrance animation
	_play_entrance_animation()


func _exit_tree() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0


# ==============================================================================
# PUBLIC
# ==============================================================================

func set_lost_loot(value: int) -> void:
	lost_loot_value = value
	if loot_label:
		loot_label.text = "Loot Lost: $%d" % value


# ==============================================================================
# ANIMATION
# ==============================================================================

func _play_entrance_animation() -> void:
	# Initial state - everything hidden
	if background:
		background.modulate.a = 0.0
	if content_container:
		content_container.modulate.a = 0.0
		content_container.scale = Vector2(0.8, 0.8)
	if title_label:
		title_label.modulate.a = 0.0
	if loot_label:
		loot_label.modulate.a = 0.0
	if retry_button:
		retry_button.modulate.a = 0.0
	if menu_button:
		menu_button.modulate.a = 0.0
	
	# Create tween sequence
	var tween = create_tween()
	tween.set_parallel(false)
	
	# Flash red briefly
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(1, 0.2, 0.1, 0.8)
	add_child(flash)
	
	# Quick red flash
	tween.tween_property(flash, "color:a", 0.0, 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)
	
	# Slow motion effect (ramp down then up)
	Engine.time_scale = 0.3
	tween.tween_property(Engine, "time_scale", 1.0, 1.0).set_ease(Tween.EASE_OUT)
	
	# Fade in background
	if background:
		tween.parallel().tween_property(background, "modulate:a", 1.0, 0.5)
	
	# Title slides in and scales
	if title_label:
		title_label.scale = Vector2(1.5, 1.5)
		tween.tween_property(title_label, "modulate:a", 1.0, 0.3)
		tween.parallel().tween_property(title_label, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Content fades in
	if content_container:
		tween.tween_property(content_container, "modulate:a", 1.0, 0.3)
		tween.parallel().tween_property(content_container, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT)
	
	# Loot label
	if loot_label:
		tween.tween_property(loot_label, "modulate:a", 1.0, 0.2)
	
	# Buttons appear
	if retry_button:
		tween.tween_property(retry_button, "modulate:a", 1.0, 0.2)
	if menu_button:
		tween.tween_property(menu_button, "modulate:a", 1.0, 0.2)
	
	# Focus retry button
	if retry_button:
		tween.tween_callback(retry_button.grab_focus)


# ==============================================================================
# CALLBACKS
# ==============================================================================

func _on_retry_pressed() -> void:
	_transition_out("res://scenes/boarding/boarding_scene.tscn")


func _on_menu_pressed() -> void:
	_transition_out("res://scenes/intro/intro_scene.tscn")


func _transition_out(scene_path: String) -> void:
	# Create fade out
	var fade = ColorRect.new()
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 0)
	add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.4)
	tween.tween_callback(func():
		get_tree().paused = false
		Engine.time_scale = 1.0
		LoadingScreen.start_transition(scene_path)
	)
