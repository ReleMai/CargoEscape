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
@onready var accessibility_button: Button = $MenuContainer/AccessibilityButton
@onready var quit_button: Button = $MenuContainer/QuitButton
@onready var title_label: Label = $TitleContainer/TitleLabel
@onready var subtitle_label: Label = $TitleContainer/SubtitleLabel

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
	if accessibility_button:
		accessibility_button.modulate.a = 0
	if quit_button:
		quit_button.modulate.a = 0


func _connect_signals() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if accessibility_button:
		accessibility_button.pressed.connect(_on_accessibility_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


func _play_entrance_animation() -> void:
	# Check if animations should be reduced
	var should_animate = true
	if has_node("/root/AccessibilityManager"):
		should_animate = AccessibilityManager.should_play_animation()
	
	if not should_animate:
		# Instantly show everything without animation
		if title_label:
			title_label.modulate.a = 1.0
		if subtitle_label:
			subtitle_label.modulate.a = 0.7
		if start_button:
			start_button.modulate.a = 1.0
		if accessibility_button:
			accessibility_button.modulate.a = 1.0
		if quit_button:
			quit_button.modulate.a = 1.0
		if start_button:
			start_button.grab_focus()
		return
	
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
	if accessibility_button:
		tween.tween_property(accessibility_button, "modulate:a", 1.0, 0.3)
	if quit_button:
		tween.tween_property(quit_button, "modulate:a", 1.0, 0.3)
	
	# Focus the start button for keyboard/controller navigation
	if start_button:
		tween.tween_callback(start_button.grab_focus)


# ==============================================================================
# BUTTON HANDLERS
# ==============================================================================

func _on_start_pressed() -> void:
	# Check if animations should be reduced
	var should_animate = true
	if has_node("/root/AccessibilityManager"):
		should_animate = AccessibilityManager.should_play_animation()
	
	if not should_animate:
		# Skip animation and go straight to game
		_start_game()
		return
	
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


func _on_accessibility_pressed() -> void:
	# Load and show accessibility menu
	var accessibility_scene = preload("res://scenes/ui/accessibility_menu.tscn")
	var accessibility_menu = accessibility_scene.instantiate()
	add_child(accessibility_menu)
	AccessibilityManager.announce_for_screen_reader("Opening accessibility settings")


# ==============================================================================
# INPUT
# ==============================================================================

func _input(event: InputEvent) -> void:
	# Allow pressing Enter/Space to start if no button is focused
	if event.is_action_pressed("ui_accept"):
		if not _is_any_button_focused():
			_on_start_pressed()


func _is_any_button_focused() -> bool:
	# Helper to check if any button has focus
	if start_button and start_button.has_focus():
		return true
	if accessibility_button and accessibility_button.has_focus():
		return true
	if quit_button and quit_button.has_focus():
		return true
	return false
