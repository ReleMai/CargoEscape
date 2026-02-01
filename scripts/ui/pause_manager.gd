# ==============================================================================
# PAUSE MANAGER
# ==============================================================================
#
# FILE: scripts/ui/pause_manager.gd
# PURPOSE: Manages pause menu and settings menu transitions
#
# ==============================================================================

extends CanvasLayer
class_name PauseManager

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var pause_menu: Control = $PauseMenu
@onready var settings_menu: Control = $SettingsMenu

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_connect_signals()
	
	# Make sure this processes even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Hide both menus initially
	if pause_menu:
		pause_menu.hide()
	if settings_menu:
		settings_menu.hide()


func _input(event: InputEvent) -> void:
	# Handle pause toggle
	if event.is_action_pressed("pause"):
		# If settings menu is visible, go back to pause menu
		if settings_menu and settings_menu.visible:
			_on_settings_back()
		# If pause menu is visible, resume game
		elif pause_menu and pause_menu.visible:
			pause_menu.hide_pause_menu()
		# Otherwise, show pause menu
		else:
			if pause_menu:
				pause_menu.show_pause_menu()
		get_viewport().set_input_as_handled()


func _connect_signals() -> void:
	if pause_menu:
		pause_menu.settings_requested.connect(_on_settings_requested)
	
	if settings_menu:
		settings_menu.back_requested.connect(_on_settings_back)


# ==============================================================================
# SIGNAL HANDLERS
# ==============================================================================

func _on_settings_requested() -> void:
	if pause_menu:
		pause_menu.hide()
	if settings_menu:
		settings_menu.show_settings()


func _on_settings_back() -> void:
	if settings_menu:
		settings_menu.hide()
	if pause_menu:
		pause_menu.show()
		if pause_menu.has_node("Panel/MarginContainer/MenuContainer/ResumeButton"):
			pause_menu.get_node("Panel/MarginContainer/MenuContainer/ResumeButton").grab_focus()
