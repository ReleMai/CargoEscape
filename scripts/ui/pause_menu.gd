# ==============================================================================
# PAUSE MENU
# ==============================================================================
#
# FILE: scripts/ui/pause_menu.gd
# PURPOSE: Pause menu that appears during gameplay
#
# ==============================================================================

extends Control
class_name PauseMenu

# ==============================================================================
# SIGNALS
# ==============================================================================

signal resume_requested
signal settings_requested
signal main_menu_requested
signal quit_requested

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var menu_container: VBoxContainer = $Panel/MarginContainer/MenuContainer
@onready var resume_button: Button = $Panel/MarginContainer/MenuContainer/ResumeButton
@onready var settings_button: Button = $Panel/MarginContainer/MenuContainer/SettingsButton
@onready var main_menu_button: Button = $Panel/MarginContainer/MenuContainer/MainMenuButton
@onready var quit_button: Button = $Panel/MarginContainer/MenuContainer/QuitButton
@onready var title_label: Label = $Panel/MarginContainer/MenuContainer/TitleLabel

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_connect_signals()
	hide()
	
	# Make sure the pause menu processes even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS


func _connect_signals() -> void:
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

func show_pause_menu() -> void:
	show()
	get_tree().paused = true
	if resume_button:
		resume_button.grab_focus()


func hide_pause_menu() -> void:
	hide()
	get_tree().paused = false


# ==============================================================================
# BUTTON HANDLERS
# ==============================================================================

func _on_resume_pressed() -> void:
	hide_pause_menu()
	resume_requested.emit()


func _on_settings_pressed() -> void:
	settings_requested.emit()


func _on_main_menu_pressed() -> void:
	main_menu_requested.emit()
	hide_pause_menu()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_quit_pressed() -> void:
	quit_requested.emit()
	hide_pause_menu()
	get_tree().quit()
