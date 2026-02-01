# ==============================================================================
# ACCESSIBILITY MANAGER (AUTOLOAD/SINGLETON)
# ==============================================================================
# 
# FILE: scripts/core/accessibility_manager.gd
# PURPOSE: Manages accessibility settings and features for the game
#
# ==============================================================================

extends Node

# ==============================================================================
# SIGNALS
# ==============================================================================

signal colorblind_mode_changed(mode: ColorblindMode)
signal high_contrast_changed(enabled: bool)
signal text_size_changed(size: TextSize)
signal reduce_motion_changed(enabled: bool)
signal input_remapped(action: String)

# ==============================================================================
# ENUMS
# ==============================================================================

enum ColorblindMode {
	NONE,           # No colorblind filter
	DEUTERANOPIA,   # Red-green (most common - 6% of males)
	PROTANOPIA,     # Red-green (1% of males)
	TRITANOPIA      # Blue-yellow (rare - 0.001%)
}

enum TextSize {
	NORMAL,
	LARGE,
	EXTRA_LARGE
}

# ==============================================================================
# SETTINGS VARIABLES
# ==============================================================================

## Current colorblind mode
var colorblind_mode: ColorblindMode = ColorblindMode.NONE

## High contrast UI enabled
var high_contrast_enabled: bool = false

## Text size setting
var text_size: TextSize = TextSize.NORMAL

## Reduce motion enabled (disables animations)
var reduce_motion: bool = false

## Screen reader mode (adds accessible descriptions)
var screen_reader_mode: bool = false

## Custom key mappings (action name -> InputEvent)
var custom_input_map: Dictionary = {}

## Default input mappings (stored on first load)
var default_input_map: Dictionary = {}

# ==============================================================================
# SHADER CACHE
# ==============================================================================

var _colorblind_shader: Shader = null

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Load shader
	_colorblind_shader = preload("res://scripts/core/shaders/colorblind_filter.gdshader")
	
	# Store default input mappings before any changes
	_store_default_input_map()
	
	# Add colorblind overlay to scene tree
	var overlay_scene = preload("res://scenes/ui/colorblind_overlay.tscn")
	var overlay = overlay_scene.instantiate()
	add_child(overlay)
	
	# Load saved settings
	_load_settings()
	
	# Apply initial settings
	_apply_all_settings()
	
	print("[AccessibilityManager] Initialized")


# ==============================================================================
# COLORBLIND MODE
# ==============================================================================

func set_colorblind_mode(mode: ColorblindMode) -> void:
	if colorblind_mode == mode:
		return
	
	colorblind_mode = mode
	_apply_colorblind_filter()
	colorblind_mode_changed.emit(mode)
	_save_settings()
	print("[AccessibilityManager] Colorblind mode: ", _get_colorblind_mode_name(mode))


func get_colorblind_mode() -> ColorblindMode:
	return colorblind_mode


func _get_colorblind_mode_name(mode: ColorblindMode) -> String:
	match mode:
		ColorblindMode.NONE: return "None"
		ColorblindMode.DEUTERANOPIA: return "Deuteranopia"
		ColorblindMode.PROTANOPIA: return "Protanopia"
		ColorblindMode.TRITANOPIA: return "Tritanopia"
	return "Unknown"


func _apply_colorblind_filter() -> void:
	# Apply shader to viewport if colorblind mode is enabled
	var viewport = get_tree().root
	
	# Remove existing colorblind material
	if viewport.has_meta("colorblind_material"):
		var old_material = viewport.get_meta("colorblind_material")
		if old_material:
			viewport.set_meta("colorblind_material", null)
	
	# If mode is NONE, we're done
	if colorblind_mode == ColorblindMode.NONE:
		return
	
	# Create and apply new shader material
	# Note: In Godot 4, we use CanvasLayer with ColorRect and BackBufferCopy
	# This will be set up in the shader application


# ==============================================================================
# HIGH CONTRAST
# ==============================================================================

func set_high_contrast(enabled: bool) -> void:
	if high_contrast_enabled == enabled:
		return
	
	high_contrast_enabled = enabled
	_apply_high_contrast()
	high_contrast_changed.emit(enabled)
	_save_settings()
	print("[AccessibilityManager] High contrast: ", enabled)


func get_high_contrast() -> bool:
	return high_contrast_enabled


func _apply_high_contrast() -> void:
	# This will be implemented by UI elements listening to the signal
	# Each UI can adjust its theme/colors accordingly
	pass


# ==============================================================================
# TEXT SIZE
# ==============================================================================

func set_text_size(size: TextSize) -> void:
	if text_size == size:
		return
	
	text_size = size
	_apply_text_size()
	text_size_changed.emit(size)
	_save_settings()
	print("[AccessibilityManager] Text size: ", _get_text_size_name(size))


func get_text_size() -> TextSize:
	return text_size


func get_text_scale() -> float:
	match text_size:
		TextSize.NORMAL: return 1.0
		TextSize.LARGE: return 1.3
		TextSize.EXTRA_LARGE: return 1.6
	return 1.0


func _get_text_size_name(size: TextSize) -> String:
	match size:
		TextSize.NORMAL: return "Normal"
		TextSize.LARGE: return "Large"
		TextSize.EXTRA_LARGE: return "Extra Large"
	return "Unknown"


func _apply_text_size() -> void:
	# UI elements will listen to the signal and update their font sizes
	pass


# ==============================================================================
# REDUCE MOTION
# ==============================================================================

func set_reduce_motion(enabled: bool) -> void:
	if reduce_motion == enabled:
		return
	
	reduce_motion = enabled
	reduce_motion_changed.emit(enabled)
	_save_settings()
	print("[AccessibilityManager] Reduce motion: ", enabled)


func get_reduce_motion() -> bool:
	return reduce_motion


func should_play_animation() -> bool:
	return not reduce_motion


# ==============================================================================
# SCREEN READER
# ==============================================================================

func set_screen_reader_mode(enabled: bool) -> void:
	screen_reader_mode = enabled
	_save_settings()
	print("[AccessibilityManager] Screen reader mode: ", enabled)


func get_screen_reader_mode() -> bool:
	return screen_reader_mode


func announce_for_screen_reader(text: String) -> void:
	if screen_reader_mode:
		# In a full implementation, this would interface with OS screen readers
		# For now, we'll print to console
		print("[Screen Reader] ", text)


# ==============================================================================
# CUSTOM INPUT REMAPPING
# ==============================================================================

func remap_action(action: String, new_event: InputEvent) -> void:
	if not InputMap.has_action(action):
		print("[AccessibilityManager] ERROR: Action '", action, "' does not exist")
		return
	
	# Store custom mapping
	custom_input_map[action] = new_event
	
	# Clear existing events for this action
	InputMap.action_erase_events(action)
	
	# Add new event
	InputMap.action_add_event(action, new_event)
	
	input_remapped.emit(action)
	_save_settings()
	print("[AccessibilityManager] Remapped '", action, "' to ", new_event)


func get_action_events(action: String) -> Array:
	return InputMap.action_get_events(action)


func reset_action_to_default(action: String) -> void:
	# Restore action to default from stored defaults
	if custom_input_map.has(action):
		custom_input_map.erase(action)
	
	# Clear current events
	InputMap.action_erase_events(action)
	
	# Restore default events if we have them stored
	if default_input_map.has(action):
		var default_events = default_input_map[action]
		for event in default_events:
			InputMap.action_add_event(action, event)
	
	input_remapped.emit(action)
	_save_settings()


func reset_all_inputs() -> void:
	custom_input_map.clear()
	
	# Restore all defaults
	for action in default_input_map:
		InputMap.action_erase_events(action)
		var default_events = default_input_map[action]
		for event in default_events:
			InputMap.action_add_event(action, event)
		input_remapped.emit(action)


func _store_default_input_map() -> void:
	# Store the default input configuration from project.godot
	for action in InputMap.get_actions():
		# Skip built-in UI actions
		if action.begins_with("ui_"):
			continue
		
		var events = InputMap.action_get_events(action)
		default_input_map[action] = events.duplicate()


# ==============================================================================
# SETTINGS PERSISTENCE
# ==============================================================================

const SETTINGS_PATH = "user://accessibility_settings.cfg"

func _save_settings() -> void:
	var config = ConfigFile.new()
	
	config.set_value("accessibility", "colorblind_mode", colorblind_mode)
	config.set_value("accessibility", "high_contrast", high_contrast_enabled)
	config.set_value("accessibility", "text_size", text_size)
	config.set_value("accessibility", "reduce_motion", reduce_motion)
	config.set_value("accessibility", "screen_reader_mode", screen_reader_mode)
	
	# Save custom input mappings
	for action in custom_input_map:
		config.set_value("input_map", action, var_to_str(custom_input_map[action]))
	
	var err = config.save(SETTINGS_PATH)
	if err != OK:
		print("[AccessibilityManager] ERROR: Failed to save settings: ", err)


func _load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	
	if err != OK:
		print("[AccessibilityManager] No saved settings found, using defaults")
		return
	
	# Load accessibility settings
	colorblind_mode = config.get_value("accessibility", "colorblind_mode", ColorblindMode.NONE)
	high_contrast_enabled = config.get_value("accessibility", "high_contrast", false)
	text_size = config.get_value("accessibility", "text_size", TextSize.NORMAL)
	reduce_motion = config.get_value("accessibility", "reduce_motion", false)
	screen_reader_mode = config.get_value("accessibility", "screen_reader_mode", false)
	
	# Load custom input mappings
	if config.has_section("input_map"):
		for action in config.get_section_keys("input_map"):
			var event_str = config.get_value("input_map", action)
			var event = str_to_var(event_str)
			if event is InputEvent:
				remap_action(action, event)
	
	print("[AccessibilityManager] Settings loaded")


func _apply_all_settings() -> void:
	_apply_colorblind_filter()
	_apply_high_contrast()
	_apply_text_size()


# ==============================================================================
# UTILITY
# ==============================================================================

func get_all_actions() -> Array:
	return InputMap.get_actions()


func get_action_display_name(action: String) -> String:
	# Convert snake_case to Title Case
	var words = action.split("_")
	var result = ""
	for word in words:
		if word.length() > 0:
			result += word.capitalize() + " "
	return result.strip_edges()
