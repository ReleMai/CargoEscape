# ==============================================================================
# SAVE MANAGER (AUTOLOAD/SINGLETON)
# ==============================================================================
# 
# FILE: scripts/save_manager.gd
# PURPOSE: Handles saving and loading player progress using Godot's ConfigFile
#
# WHAT THIS DOES:
# ---------------
# - Saves player inventory (ship and stash)
# - Saves credits/score
# - Saves equipped modules
# - Saves upgrade levels
# - Saves settings preferences
# - Provides manual save/load functions
# - Auto-saves on scene transitions
#
# SAVE FILE LOCATION:
# -------------------
# user://save_data.cfg (platform-specific user directory)
# Windows: %APPDATA%\Godot\app_userdata\[ProjectName]
# Linux: ~/.local/share/godot/app_userdata/[ProjectName]
# macOS: ~/Library/Application Support/Godot/app_userdata/[ProjectName]
#
# ==============================================================================

extends Node

# ==============================================================================
# CONSTANTS
# ==============================================================================

## Path to save file (user:// is Godot's user data directory)
const SAVE_FILE_PATH: String = "user://save_data.cfg"

## Save file version (for compatibility checks)
const SAVE_VERSION: int = 1

# ==============================================================================
# SIGNALS
# ==============================================================================

signal save_completed
signal load_completed
signal save_failed(error_message: String)
signal load_failed(error_message: String)

# ==============================================================================
# STATE
# ==============================================================================

var auto_save_enabled: bool = true
var game_manager: Node = null

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Get GameManager reference
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	
	print("[SaveManager] Initialized")
	print("[SaveManager] Save file location: ", ProjectSettings.globalize_path(SAVE_FILE_PATH))
	
	# Auto-load save data if it exists
	if save_file_exists():
		print("[SaveManager] Save file found, loading...")
		load_game()
	else:
		print("[SaveManager] No save file found")


# ==============================================================================
# SAVE FUNCTIONS
# ==============================================================================

## Save all game data
func save_game() -> bool:
	if not game_manager:
		push_error("[SaveManager] Cannot save: GameManager not found!")
		save_failed.emit("GameManager not found")
		return false
	
	print("[SaveManager] Saving game...")
	
	var config = ConfigFile.new()
	
	# Save metadata
	config.set_value("meta", "version", SAVE_VERSION)
	config.set_value("meta", "save_time", Time.get_datetime_string_from_system())
	
	# Save player stats
	config.set_value("player", "credits", game_manager.credits)
	config.set_value("player", "health_upgrade_level", game_manager.health_upgrade_level)
	config.set_value("player", "laser_upgrade_level", game_manager.laser_upgrade_level)
	config.set_value("player", "ship_inventory_upgrade", game_manager.ship_inventory_upgrade)
	config.set_value("player", "stash_inventory_upgrade", game_manager.stash_inventory_upgrade)
	config.set_value("player", "ship_type", game_manager.ship_type)
	config.set_value("player", "loot_tier", game_manager.loot_tier)
	
	# Save equipped modules
	_save_equipped_modules(config)
	
	# Save ship inventory
	_save_inventory(config, "ship_inventory", game_manager.ship_inventory)
	
	# Save stash inventory
	_save_inventory(config, "stash_inventory", game_manager.stash_inventory)
	
	# Save current station (if any)
	if game_manager.current_station:
		config.set_value("game_state", "current_station_path", game_manager.current_station.resource_path)
	
	# Write to file
	var error = config.save(SAVE_FILE_PATH)
	if error != OK:
		push_error("[SaveManager] Failed to save file: ", error)
		save_failed.emit("Failed to write save file: " + str(error))
		return false
	
	print("[SaveManager] Game saved successfully!")
	save_completed.emit()
	return true


## Save equipped modules to config
func _save_equipped_modules(config: ConfigFile) -> void:
	for slot_type in game_manager.equipped_modules:
		var module = game_manager.equipped_modules[slot_type]
		if module:
			# Save the resource path so we can reload it
			var key = "module_slot_" + str(slot_type)
			config.set_value("modules", key, module.resource_path)


## Save inventory items to config
func _save_inventory(config: ConfigFile, section: String, inventory: Array) -> void:
	# Save item count
	config.set_value(section, "count", inventory.size())
	
	# Save each item's resource path
	for i in range(inventory.size()):
		var item = inventory[i]
		if item and item is Resource:
			config.set_value(section, "item_" + str(i), item.resource_path)


# ==============================================================================
# LOAD FUNCTIONS
# ==============================================================================

## Load all game data
func load_game() -> bool:
	if not game_manager:
		push_error("[SaveManager] Cannot load: GameManager not found!")
		load_failed.emit("GameManager not found")
		return false
	
	if not save_file_exists():
		print("[SaveManager] No save file to load")
		load_failed.emit("No save file found")
		return false
	
	print("[SaveManager] Loading game...")
	
	var config = ConfigFile.new()
	var error = config.load(SAVE_FILE_PATH)
	
	if error != OK:
		push_error("[SaveManager] Failed to load save file: ", error)
		load_failed.emit("Failed to read save file: " + str(error))
		return false
	
	# Check version compatibility
	var version = config.get_value("meta", "version", 0)
	if version != SAVE_VERSION:
		push_warning("[SaveManager] Save file version mismatch. Expected: ", SAVE_VERSION, ", Got: ", version)
	
	# Load player stats
	game_manager.credits = config.get_value("player", "credits", 0)
	game_manager.health_upgrade_level = config.get_value("player", "health_upgrade_level", 0)
	game_manager.laser_upgrade_level = config.get_value("player", "laser_upgrade_level", 0)
	game_manager.ship_inventory_upgrade = config.get_value("player", "ship_inventory_upgrade", 0)
	game_manager.stash_inventory_upgrade = config.get_value("player", "stash_inventory_upgrade", 0)
	game_manager.ship_type = config.get_value("player", "ship_type", 0)
	game_manager.loot_tier = config.get_value("player", "loot_tier", 0)
	
	# Load equipped modules
	_load_equipped_modules(config)
	
	# Load ship inventory
	game_manager.ship_inventory = _load_inventory(config, "ship_inventory")
	
	# Load stash inventory
	game_manager.stash_inventory = _load_inventory(config, "stash_inventory")
	
	# Load current station
	var station_path = config.get_value("game_state", "current_station_path", "")
	if station_path != "":
		var station = load(station_path)
		if station:
			game_manager.set_current_station(station)
	
	# Recalculate stats after loading
	if game_manager.has_method("_recalculate_stats"):
		game_manager._recalculate_stats()
	
	# Emit signals to update UI
	game_manager.credits_changed.emit(game_manager.credits)
	game_manager.ship_inventory_changed.emit()
	game_manager.stash_inventory_changed.emit()
	
	print("[SaveManager] Game loaded successfully!")
	print("[SaveManager] Credits: ", game_manager.credits)
	print("[SaveManager] Ship inventory items: ", game_manager.ship_inventory.size())
	print("[SaveManager] Stash inventory items: ", game_manager.stash_inventory.size())
	
	load_completed.emit()
	return true


## Load equipped modules from config
func _load_equipped_modules(config: ConfigFile) -> void:
	for slot_type in [0, 1, 2]:  # FLIGHT, COMBAT, UTILITY
		var key = "module_slot_" + str(slot_type)
		var module_path = config.get_value("modules", key, "")
		
		if module_path != "":
			var module = load(module_path)
			if module:
				game_manager.set_equipped_module(slot_type, module)
			else:
				push_warning("[SaveManager] Failed to load module: ", module_path)


## Load inventory from config
func _load_inventory(config: ConfigFile, section: String) -> Array:
	var inventory: Array = []
	var count = config.get_value(section, "count", 0)
	
	for i in range(count):
		var item_path = config.get_value(section, "item_" + str(i), "")
		if item_path != "":
			var item = load(item_path)
			if item:
				inventory.append(item)
			else:
				push_warning("[SaveManager] Failed to load item: ", item_path)
	
	return inventory


# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

## Check if save file exists
func save_file_exists() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)


## Delete save file
func delete_save() -> bool:
	if save_file_exists():
		var dir = DirAccess.open("user://")
		if dir:
			var error = dir.remove(SAVE_FILE_PATH.get_file())
			if error == OK:
				print("[SaveManager] Save file deleted")
				return true
			else:
				push_error("[SaveManager] Failed to delete save file: ", error)
				return false
	return false


## Get save file info for UI display
func get_save_info() -> Dictionary:
	if not save_file_exists():
		return {}
	
	var config = ConfigFile.new()
	var error = config.load(SAVE_FILE_PATH)
	
	if error != OK:
		return {}
	
	return {
		"version": config.get_value("meta", "version", 0),
		"save_time": config.get_value("meta", "save_time", "Unknown"),
		"credits": config.get_value("player", "credits", 0),
		"ship_inventory_size": config.get_value("ship_inventory", "count", 0),
		"stash_inventory_size": config.get_value("stash_inventory", "count", 0)
	}


## Enable/disable auto-save
func set_auto_save_enabled(enabled: bool) -> void:
	auto_save_enabled = enabled
	print("[SaveManager] Auto-save ", "enabled" if enabled else "disabled")


## Auto-save wrapper (only saves if enabled)
func auto_save() -> bool:
	if auto_save_enabled:
		print("[SaveManager] Auto-saving...")
		return save_game()
	else:
		print("[SaveManager] Auto-save skipped (disabled)")
		return false


# ==============================================================================
# DEBUG FUNCTIONS
# ==============================================================================

## Print save file contents for debugging
func print_save_file() -> void:
	if not save_file_exists():
		print("[SaveManager] No save file to print")
		return
	
	var config = ConfigFile.new()
	var error = config.load(SAVE_FILE_PATH)
	
	if error != OK:
		print("[SaveManager] Failed to load save file for printing")
		return
	
	print("=== SAVE FILE CONTENTS ===")
	for section in config.get_sections():
		print("[", section, "]")
		for key in config.get_section_keys(section):
			print("  ", key, " = ", config.get_value(section, key))
	print("=========================")
