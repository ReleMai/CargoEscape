# ==============================================================================
# DYNAMIC BACKGROUND TEST CONTROLLER
# ==============================================================================
#
# PURPOSE: Test controller for the dynamic background system
# Allows interactive testing of features
#
# ==============================================================================

extends Node2D


var dynamic_background: DynamicBackground = null
var current_theme_index: int = 0
var themes: Array[String] = ["Blue", "Purple", "Orange", "Green", "Red"]


func _ready() -> void:
	# Find the dynamic background node
	dynamic_background = $DynamicBackground
	
	if not dynamic_background:
		push_error("DynamicBackground node not found!")
		return
	
	# Connect signals for debugging
	dynamic_background.theme_changed.connect(_on_theme_changed)
	dynamic_background.random_event_triggered.connect(_on_random_event)
	
	print("=== Dynamic Background Test Started ===")
	print("Controls:")
	print("  1-5: Change color theme")
	print("  SPACE: Toggle auto-scroll")
	print("  UP/DOWN: Adjust scroll speed")
	print("  T: Toggle day/night cycle")
	print("  E: Trigger random event")
	print("  R: Reset background")


func _process(_delta: float) -> void:
	_handle_input()
	_update_label()


func _handle_input() -> void:
	if not dynamic_background:
		return
	
	# Theme selection (1-5)
	if Input.is_physical_key_pressed(KEY_1):
		dynamic_background.change_theme("Blue")
	elif Input.is_physical_key_pressed(KEY_2):
		dynamic_background.change_theme("Purple")
	elif Input.is_physical_key_pressed(KEY_3):
		dynamic_background.change_theme("Orange")
	elif Input.is_physical_key_pressed(KEY_4):
		dynamic_background.change_theme("Green")
	elif Input.is_physical_key_pressed(KEY_5):
		dynamic_background.change_theme("Red")
	
	# Toggle auto-scroll
	if Input.is_action_just_pressed("ui_select"):
		dynamic_background.auto_scroll = !dynamic_background.auto_scroll
		print("Auto-scroll: ", dynamic_background.auto_scroll)
	
	# Adjust scroll speed
	if Input.is_action_pressed("ui_up"):
		dynamic_background.base_scroll_speed += 1.0
		print("Scroll speed: ", dynamic_background.base_scroll_speed)
	elif Input.is_action_pressed("ui_down"):
		dynamic_background.base_scroll_speed = max(0.0, dynamic_background.base_scroll_speed - 1.0)
		print("Scroll speed: ", dynamic_background.base_scroll_speed)
	
	# Toggle day/night cycle
	if Input.is_key_just_pressed(KEY_T):
		dynamic_background.enable_day_night_cycle = !dynamic_background.enable_day_night_cycle
		print("Day/Night cycle: ", dynamic_background.enable_day_night_cycle)
	
	# Trigger random event
	if Input.is_key_just_pressed(KEY_E):
		dynamic_background._trigger_random_event()
	
	# Reset
	if Input.is_key_just_pressed(KEY_R):
		dynamic_background.reset()
		print("Background reset")


func _update_label() -> void:
	var label = $TestLabel
	if label and dynamic_background:
		label.text = "Dynamic Background System Test\n"
		label.text += "Theme: %s\n" % dynamic_background.color_theme
		label.text += "Scroll Speed: %.1f\n" % dynamic_background.get_current_speed()
		label.text += "Auto-Scroll: %s\n" % str(dynamic_background.auto_scroll)
		label.text += "Day/Night: %s\n" % str(dynamic_background.enable_day_night_cycle)
		label.text += "\nControls: 1-5=Theme, SPACE=Scroll, T=Cycle, E=Event, R=Reset"


func _on_theme_changed(theme_name: String) -> void:
	print("[Test] Theme changed to: ", theme_name)


func _on_random_event(event_type: String) -> void:
	print("[Test] Random event: ", event_type)
