# ==============================================================================
# MAIN MENU
# ==============================================================================
#
# FILE: scripts/ui/main_menu.gd
# PURPOSE: Main menu screen with title, buttons for starting game, etc.
#
# ==============================================================================

extends Control
class_name MainMenu

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var start_button: Button = $MenuContainer/StartButton
@onready var achievements_button: Button = $MenuContainer/AchievementsButton
@onready var quit_button: Button = $MenuContainer/QuitButton
@onready var title_label: Label = $TitleContainer/TitleLabel
@onready var subtitle_label: Label = $TitleContainer/SubtitleLabel


# ==============================================================================
# PRELOADS
# ==============================================================================

const AchievementGalleryScene = preload("res://scenes/ui/achievement_gallery.tscn")

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_play_entrance_animation()


func _setup_ui() -> void:
	# Initial state for animation
	if title_label:
		title_label.modulate.a = 0
	if subtitle_label:
		subtitle_label.modulate.a = 0
	if start_button:
		start_button.modulate.a = 0
	if achievements_button:
		achievements_button.modulate.a = 0
	if quit_button:
		quit_button.modulate.a = 0


func _connect_signals() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if achievements_button:
		achievements_button.pressed.connect(_on_achievements_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


func _play_entrance_animation() -> void:
	var tween = create_tween()
	
	# Fade in title
	if title_label:
		tween.tween_property(title_label, "modulate:a", 1.0, 0.8)
	
	# Fade in subtitle
	if subtitle_label:
		tween.tween_property(subtitle_label, "modulate:a", 0.7, 0.5)
	
	# Fade in buttons with slight delay
	if start_button:
		tween.tween_property(start_button, "modulate:a", 1.0, 0.3)
	if achievements_button:
		tween.tween_property(achievements_button, "modulate:a", 1.0, 0.3)
	if quit_button:
		tween.tween_property(quit_button, "modulate:a", 1.0, 0.3)
	
	# Focus the start button for keyboard/controller navigation
	if start_button:
		tween.tween_callback(start_button.grab_focus)


# ==============================================================================
# BUTTON HANDLERS
# ==============================================================================

func _on_start_pressed() -> void:
	# Play a quick fade out then transition to intro
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(_start_game)


func _start_game() -> void:
	# Reset game state before starting
	if GameManager:
		GameManager.reset_game()
	
	# Go to intro scene
	get_tree().change_scene_to_file("res://scenes/intro/intro_scene.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_achievements_pressed() -> void:
	# Open achievement gallery as overlay
	var gallery = AchievementGalleryScene.instantiate()
	add_child(gallery)


# ==============================================================================
# INPUT
# ==============================================================================

func _input(event: InputEvent) -> void:
	# Allow pressing Enter/Space to start if no button is focused
	if event.is_action_pressed("ui_accept"):
		if not (start_button and start_button.has_focus()) and not (quit_button and quit_button.has_focus()):
			_on_start_pressed()
