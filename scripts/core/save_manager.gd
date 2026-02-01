# ==============================================================================
# SAVE MANAGER (AUTOLOAD/SINGLETON)
# ==============================================================================
#
# FILE: scripts/core/save_manager.gd
# PURPOSE: Manages game save data and persistent settings
#
# USAGE:
# - SaveManager.save_game()
# - SaveManager.load_game()
# - SaveManager.get_setting(key)
# - SaveManager.set_setting(key, value)
#
# ==============================================================================

extends Node

# ==============================================================================
# CONSTANTS
# ==============================================================================

const SAVE_FILE_PATH := "user://save_data.cfg"

# ==============================================================================
# SAVE DATA
# ==============================================================================

## Tutorial completion tracking
var tutorial_completed: bool = false

## Individual tutorial steps completed
var tutorial_steps_completed: Dictionary = {
	"movement": false,
	"container_interaction": false,
	"inventory": false,
	"timer": false,
	"exit": false,
	"selling": false
}

## First time playing
var first_time_player: bool = true

## Settings
var settings: Dictionary = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"show_tutorial": true
}

# ==============================================================================
# BUILT-IN FUNCTIONS
# ==============================================================================

func _ready() -> void:
	load_game()
	print("[SaveManager] Initialized")


# ==============================================================================
# SAVE/LOAD FUNCTIONS
# ==============================================================================

## Save game data to disk
func save_game() -> void:
	var config = ConfigFile.new()
	
	# Tutorial data
	config.set_value("tutorial", "completed", tutorial_completed)
	config.set_value("tutorial", "steps", tutorial_steps_completed)
	config.set_value("tutorial", "first_time", first_time_player)
	
	# Settings
	for key in settings:
		config.set_value("settings", key, settings[key])
	
	# Save to disk
	var err = config.save(SAVE_FILE_PATH)
	if err != OK:
		push_error("[SaveManager] Failed to save game: " + str(err))
	else:
		print("[SaveManager] Game saved successfully")


## Load game data from disk
func load_game() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_FILE_PATH)
	
	if err != OK:
		print("[SaveManager] No save file found, using defaults")
		return
	
	# Load tutorial data
	tutorial_completed = config.get_value("tutorial", "completed", false)
	tutorial_steps_completed = config.get_value("tutorial", "steps", tutorial_steps_completed)
	first_time_player = config.get_value("tutorial", "first_time", true)
	
	# Load settings
	for key in settings:
		settings[key] = config.get_value("settings", key, settings[key])
	
	print("[SaveManager] Game loaded successfully")


# ==============================================================================
# TUTORIAL FUNCTIONS
# ==============================================================================

## Check if tutorial should be shown
func should_show_tutorial() -> bool:
	return first_time_player or (settings.get("show_tutorial", true) and not tutorial_completed)


## Mark tutorial as completed
func complete_tutorial() -> void:
	tutorial_completed = true
	first_time_player = false
	save_game()
	print("[SaveManager] Tutorial marked as complete")


## Mark a specific tutorial step as completed
func complete_tutorial_step(step_id: String) -> void:
	if step_id in tutorial_steps_completed:
		tutorial_steps_completed[step_id] = true
		save_game()
		print("[SaveManager] Tutorial step completed: ", step_id)


## Check if a tutorial step is completed
func is_tutorial_step_completed(step_id: String) -> bool:
	return tutorial_steps_completed.get(step_id, false)


## Reset tutorial (for testing or replaying)
func reset_tutorial() -> void:
	tutorial_completed = false
	for key in tutorial_steps_completed:
		tutorial_steps_completed[key] = false
	save_game()
	print("[SaveManager] Tutorial reset")


# ==============================================================================
# SETTINGS FUNCTIONS
# ==============================================================================

## Get a setting value
func get_setting(key: String, default_value = null):
	return settings.get(key, default_value)


## Set a setting value
func set_setting(key: String, value) -> void:
	settings[key] = value
	save_game()
	print("[SaveManager] Setting updated: ", key, " = ", value)
