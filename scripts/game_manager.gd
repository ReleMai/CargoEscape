# ==============================================================================
# GAME MANAGER (AUTOLOAD/SINGLETON)
# ==============================================================================
# 
# FILE: scripts/game_manager.gd
# PURPOSE: Manages global game state that persists across scenes
#
# WHAT IS AN AUTOLOAD?
# --------------------
# An Autoload (also called Singleton) is a script that:
# - Loads automatically when the game starts
# - Stays loaded throughout the entire game
# - Can be accessed from ANY other script using its name
# - Perfect for: game state, settings, saving/loading
#
# HOW TO SET UP AUTOLOAD:
# 1. Go to Project > Project Settings > Autoload tab
# 2. Click the folder icon, select this script
# 3. Name it "GameManager" (this becomes the global access name)
# 4. Click "Add"
#
# USAGE FROM OTHER SCRIPTS:
# -------------------------
# # Access lives from anywhere:
# var current_lives = GameManager.lives
#
# # Call functions from anywhere:
# GameManager.lose_life()
# GameManager.reset_game()
#
# ==============================================================================

# "extends Node" means this script is attached to a basic Node
# We don't need Node2D features since this is just for data management
extends Node

# ==============================================================================
# PRELOADS
# ==============================================================================

const ComboSystem = preload("res://scripts/combo_system.gd")


# ==============================================================================
# SIGNALS
# ==============================================================================
# Signals are Godot's way of implementing the Observer pattern
# They allow loose coupling - objects can react to events without direct references
#
# Why use signals?
# - The HUD doesn't need to constantly check if lives changed
# - Instead, it "listens" for the signal and updates only when needed
# - This is more efficient and cleaner code

# Emitted when the player loses a life
# Other nodes can connect to this to react (e.g., HUD updates, sound plays)
signal health_changed(current_health: float, max_health: float)

# Emitted when all lives are gone
signal game_over

# Emitted when the game is reset/restarted
signal game_reset


# ==============================================================================
# GAME CONSTANTS
# ==============================================================================
# Constants are values that NEVER change during gameplay
# Use UPPER_CASE naming convention for constants
# 
# Why constants instead of magic numbers?
# - Easy to find and change in one place
# - Self-documenting code (MAX_LIVES is clearer than just "3")
# - Prevents accidental modification

## Base maximum health (can be upgraded)
const BASE_MAX_HEALTH: float = 100.0

## Points awarded for surviving (future feature)
const POINTS_PER_SECOND: int = 10

## Base laser damage (can be upgraded)
const BASE_LASER_DAMAGE: float = 25.0


# ==============================================================================
# COMBO SYSTEM
# ==============================================================================

## Combo system instance
var combo_system: ComboSystem = null


# ==============================================================================
# UPGRADE LEVELS (for future upgrade system)
# ==============================================================================

## Current health upgrade level (0 = base)
var health_upgrade_level: int = 0

## Current laser damage upgrade level (0 = base)
var laser_upgrade_level: int = 0

## Health bonus per upgrade level
const HEALTH_PER_UPGRADE: float = 25.0

## Laser damage bonus per upgrade level
const LASER_DAMAGE_PER_UPGRADE: float = 10.0


# ==============================================================================
# STATION & SHIP TYPE
# ==============================================================================

## Current station the player is at/escaping from
var current_station: Resource = null

## Station for the current escape sequence
var escape_station: Resource = null

## Player's ship type (0=Shuttle, 1=Cargo, 2=Fighter)
var ship_type: int = 0

## Signal when station changes
signal station_changed(new_station: Resource)

## Signal when ship type changes
signal ship_type_changed(new_type: int)


# ==============================================================================
# SHIP MODULES
# ==============================================================================

## Equipped modules by slot type (0=FLIGHT, 1=COMBAT, 2=UTILITY)
var equipped_modules: Dictionary = {
	0: null,  # FLIGHT
	1: null,  # COMBAT
	2: null   # UTILITY
}

## Signal when module is equipped or unequipped
signal module_changed(slot_type: int, module: Resource)

## Signal when inventory changes
signal ship_inventory_changed
signal stash_inventory_changed


# ==============================================================================
# SHIP INVENTORY (persists during runs, lost on death)
# ==============================================================================

## Items currently on the ship (the player's active inventory)
var ship_inventory: Array = []

## Maximum ship inventory slots (upgradeable)
var ship_inventory_max: int = 10

## Ship inventory upgrade level
var ship_inventory_upgrade: int = 0

## Slots per upgrade
const SHIP_INVENTORY_PER_UPGRADE: int = 5


# ==============================================================================
# STASH INVENTORY (persists forever at hideout)
# ==============================================================================

## Items stored in the hideout stash (never lost)
var stash_inventory: Array = []

## Maximum stash slots (upgradeable)
var stash_inventory_max: int = 20

## Stash upgrade level
var stash_inventory_upgrade: int = 0

## Stash slots per upgrade
const STASH_PER_UPGRADE: int = 10


# ==============================================================================
# CREDITS (currency)
# ==============================================================================

## Current credits the player has
var credits: int = 0

## Signal when credits change
signal credits_changed(new_amount: int)


# ==============================================================================
# LOOT TIER (affects loot quality)
# ==============================================================================

## Current loot tier (0=Near, 1=Middle, 2=Far, 3=Deepest)
var loot_tier: int = 0


# ==============================================================================
# GAME STATE VARIABLES
# ==============================================================================
# These variables track the current state of the game
# They're not @export because we don't want to edit them in the Inspector

## Maximum health (base + upgrades)
var max_health: float = BASE_MAX_HEALTH

## Current health (0-100+ depending on upgrades)
var current_health: float = BASE_MAX_HEALTH

## Current score (survival time * points)
var score: int = 0

## Is the game currently running? (not paused, not game over)
var is_game_active: bool = false

## How long the player has survived (in seconds)
var survival_time: float = 0.0


# ==============================================================================
# BUILT-IN GODOT FUNCTIONS
# ==============================================================================
# These functions are called automatically by Godot at specific times
# They start with underscore (_) to indicate they're "virtual" functions

# ------------------------------------------------------------------------------
# _ready() - Called once when the node enters the scene tree
# ------------------------------------------------------------------------------
# This is like a constructor - use it for initialization
# The scene tree is Godot's hierarchy of all active nodes
func _ready() -> void:
	# Initialize combo system
	combo_system = ComboSystem.new()
	add_child(combo_system)
	
	# Calculate initial max health with upgrades
	_calculate_max_health()
	current_health = max_health
	
	# Print to console for debugging
	print("GameManager initialized!")
	print("Starting health: ", max_health)


# ------------------------------------------------------------------------------
# _process(delta) - Called every frame
# ------------------------------------------------------------------------------
# delta = time elapsed since last frame (in seconds)
# Typical values: 0.016 (at 60 FPS) or 0.033 (at 30 FPS)
#
# IMPORTANT: Use delta to make things frame-rate independent!
# Without delta: fast computer = fast game, slow computer = slow game
# With delta: game runs at same speed regardless of frame rate
func _process(delta: float) -> void:
	# Only count time if game is active
	if is_game_active:
		survival_time += delta
		# Update score based on survival time
		# int() converts float to integer (removes decimals)
		score = int(survival_time * POINTS_PER_SECOND)


# ==============================================================================
# CUSTOM FUNCTIONS - HEALTH MANAGEMENT
# ==============================================================================

# ------------------------------------------------------------------------------
# take_damage(amount) - Called when player takes damage
# ------------------------------------------------------------------------------
# Returns: bool - true if player is still alive, false if game over
func take_damage(amount: float) -> bool:
	current_health -= amount
	current_health = maxf(current_health, 0.0)
	
	# Break combo when taking damage
	if combo_system:
		combo_system.break_combo()
	
	# Debugging output
	print("Damage taken: ", amount, " | Health: ", current_health, "/", max_health)
	
	# Emit health changed signal
	health_changed.emit(current_health, max_health)
	
	# Check if player is dead
	if current_health <= 0:
		_handle_game_over()
		return false
	
	return true


# ------------------------------------------------------------------------------
# heal(amount) - Restore health
# ------------------------------------------------------------------------------
func heal(amount: float) -> void:
	current_health += amount
	current_health = minf(current_health, max_health)
	health_changed.emit(current_health, max_health)
	print("Healed: ", amount, " | Health: ", current_health, "/", max_health)


# ------------------------------------------------------------------------------
# get_health_percent() - Get health as percentage (0-100)
# ------------------------------------------------------------------------------
func get_health_percent() -> float:
	return (current_health / max_health) * 100.0


# ------------------------------------------------------------------------------
# _calculate_max_health() - Calculate max health with upgrades
# ------------------------------------------------------------------------------
func _calculate_max_health() -> void:
	max_health = BASE_MAX_HEALTH + (health_upgrade_level * HEALTH_PER_UPGRADE)


# ------------------------------------------------------------------------------
# get_laser_damage() - Get current laser damage with upgrades
# ------------------------------------------------------------------------------
func get_laser_damage() -> float:
	var base_damage = BASE_LASER_DAMAGE + (laser_upgrade_level * LASER_DAMAGE_PER_UPGRADE)
	
	# Apply combat module damage multiplier
	var combat_mod = equipped_modules.get(1)  # COMBAT = 1
	if combat_mod and combat_mod.has_method("get_module_type_name"):
		base_damage *= combat_mod.damage_multiplier
	
	return base_damage


# ==============================================================================
# MODULE MANAGEMENT
# ==============================================================================

## Get all equipped modules
func get_equipped_modules() -> Dictionary:
	return equipped_modules


## Set a module in a slot
func set_equipped_module(slot_type: int, module: Resource) -> void:
	equipped_modules[slot_type] = module
	_recalculate_stats()
	module_changed.emit(slot_type, module)


## Get module in a specific slot
func get_equipped_module(slot_type: int) -> Resource:
	return equipped_modules.get(slot_type)


## Get total speed multiplier from modules
func get_speed_multiplier() -> float:
	var flight_mod = equipped_modules.get(0)  # FLIGHT = 0
	if flight_mod and flight_mod.has_method("get_module_type_name"):
		return flight_mod.speed_multiplier
	return 1.0


## Get total thrust bonus from modules
func get_thrust_bonus() -> float:
	var flight_mod = equipped_modules.get(0)
	if flight_mod and flight_mod.has_method("get_module_type_name"):
		return flight_mod.thrust_bonus
	return 0.0


## Get fire rate multiplier from modules
func get_fire_rate_multiplier() -> float:
	var combat_mod = equipped_modules.get(1)
	if combat_mod and combat_mod.has_method("get_module_type_name"):
		return combat_mod.fire_rate_multiplier
	return 1.0


## Get damage reduction from modules
func get_damage_reduction() -> float:
	var utility_mod = equipped_modules.get(2)  # UTILITY = 2
	if utility_mod and utility_mod.has_method("get_module_type_name"):
		return utility_mod.damage_reduction
	return 0.0


## Get loot multiplier from modules
func get_loot_multiplier() -> float:
	var utility_mod = equipped_modules.get(2)
	if utility_mod and utility_mod.has_method("get_module_type_name"):
		return utility_mod.loot_multiplier
	return 1.0


## Recalculate stats after module change
func _recalculate_stats() -> void:
	# Recalculate max health with utility module bonus
	var base_max = BASE_MAX_HEALTH + (health_upgrade_level * HEALTH_PER_UPGRADE)
	var utility_mod = equipped_modules.get(2)
	if utility_mod and utility_mod.has_method("get_module_type_name"):
		base_max += utility_mod.health_bonus
	max_health = base_max
	
	# Ensure current health doesn't exceed new max
	current_health = minf(current_health, max_health)
	health_changed.emit(current_health, max_health)


# ------------------------------------------------------------------------------
# _handle_game_over() - Internal function for game over logic
# ------------------------------------------------------------------------------
func _handle_game_over() -> void:
	print("GAME OVER!")
	print("Final Score: ", score)
	print("Survival Time: ", survival_time, " seconds")
	
	is_game_active = false
	emit_signal("game_over")


# ==============================================================================
# CUSTOM FUNCTIONS - GAME FLOW
# ==============================================================================

# ------------------------------------------------------------------------------
# start_game() - Initialize a new game
# ------------------------------------------------------------------------------
func start_game() -> void:
	print("Starting new game...")
	is_game_active = true
	# Note: We don't reset lives/score here - that's done in reset_game()
	# This allows for "continue" functionality later


# ------------------------------------------------------------------------------
# reset_game() - Reset all values to starting state
# ------------------------------------------------------------------------------
# Call this when returning to main menu or restarting
func reset_game() -> void:
	print("Resetting game...")
	
	# Note: We keep modules equipped across runs (persistent upgrades)
	
	# Recalculate max health (in case upgrades changed)
	_calculate_max_health()
	_recalculate_stats()
	
	# Reset all game state
	current_health = max_health
	score = 0
	survival_time = 0.0
	is_game_active = false
	
	# Reset combo system
	if combo_system:
		combo_system.reset_combo()
	
	# Notify other nodes that game was reset
	emit_signal("game_reset")
	health_changed.emit(current_health, max_health)


# ------------------------------------------------------------------------------
# pause_game() - Pause/unpause the game
# ------------------------------------------------------------------------------
# In Godot, you can pause the entire game tree
# Nodes with process_mode = PROCESS_MODE_ALWAYS will ignore pause
func pause_game(paused: bool) -> void:
	# get_tree() returns the SceneTree (manages all nodes)
	# Setting paused = true stops _process and _physics_process for most nodes
	get_tree().paused = paused
	is_game_active = not paused
	print("Game paused: ", paused)


# ==============================================================================
# SHIP INVENTORY MANAGEMENT
# ==============================================================================

func get_ship_inventory_capacity() -> int:
	return ship_inventory_max + (ship_inventory_upgrade * SHIP_INVENTORY_PER_UPGRADE)


func add_to_ship_inventory(item: Resource) -> bool:
	if ship_inventory.size() >= get_ship_inventory_capacity():
		print("[GameManager] Ship inventory full!")
		return false
	ship_inventory.append(item)
	ship_inventory_changed.emit()
	print("[GameManager] Added to ship: ", item.name if item else "null")
	return true


func remove_from_ship_inventory(item: Resource) -> bool:
	var idx = ship_inventory.find(item)
	if idx >= 0:
		ship_inventory.remove_at(idx)
		ship_inventory_changed.emit()
		return true
	return false


func clear_ship_inventory() -> void:
	ship_inventory.clear()
	ship_inventory_changed.emit()


# ==============================================================================
# STASH INVENTORY MANAGEMENT
# ==============================================================================

func get_stash_capacity() -> int:
	return stash_inventory_max + (stash_inventory_upgrade * STASH_PER_UPGRADE)


func add_to_stash(item: Resource) -> bool:
	if stash_inventory.size() >= get_stash_capacity():
		print("[GameManager] Stash full!")
		return false
	stash_inventory.append(item)
	stash_inventory_changed.emit()
	print("[GameManager] Added to stash: ", item.name if item else "null")
	return true


func remove_from_stash(item: Resource) -> bool:
	var idx = stash_inventory.find(item)
	if idx >= 0:
		stash_inventory.remove_at(idx)
		stash_inventory_changed.emit()
		return true
	return false


func transfer_to_stash(item: Resource) -> bool:
	# Move an item from ship to stash
	if stash_inventory.size() >= get_stash_capacity():
		return false
	if remove_from_ship_inventory(item):
		return add_to_stash(item)
	return false


func transfer_to_ship(item: Resource) -> bool:
	# Move an item from stash to ship
	if ship_inventory.size() >= get_ship_inventory_capacity():
		return false
	if remove_from_stash(item):
		return add_to_ship_inventory(item)
	return false


# ==============================================================================
# CREDITS MANAGEMENT
# ==============================================================================

func add_credits(amount: int) -> void:
	credits += amount
	credits_changed.emit(credits)
	print("[GameManager] Credits: +", amount, " (Total: ", credits, ")")


func spend_credits(amount: int) -> bool:
	if credits >= amount:
		credits -= amount
		credits_changed.emit(credits)
		return true
	return false


func sell_item(item: Resource, from_stash: bool = false) -> bool:
	# Sell an item for credits
	if not item:
		return false
	
	var price = item.value if "value" in item else 10
	
	var removed = false
	if from_stash:
		removed = remove_from_stash(item)
	else:
		removed = remove_from_ship_inventory(item)
	
	if removed:
		add_credits(price)
		print("[GameManager] Sold ", item.name, " for ", price, " credits")
		return true
	return false


# ==============================================================================
# DEATH / RUN END
# ==============================================================================

func on_player_death() -> void:
	# Called when player dies - lose ship inventory but keep stash
	print("[GameManager] Player died! Losing ship inventory...")
	clear_ship_inventory()
	# Reset modules (they were on the ship)
	equipped_modules = {0: null, 1: null, 2: null}
	_recalculate_stats()


func on_successful_escape() -> void:
	# Called when player escapes - keep everything
	print("[GameManager] Escaped successfully! Inventory preserved.")
	# Ship inventory stays intact until manually stashed


# ==============================================================================
# STATION MANAGEMENT
# ==============================================================================

## Set the current station
func set_current_station(station: Resource) -> void:
	current_station = station
	station_changed.emit(station)
	print("[GameManager] Current station: ", station.station_name if station else "None")


## Get the current station
func get_current_station() -> Resource:
	return current_station


## Set the escape station (station we're fleeing from)
func set_escape_station(station: Resource) -> void:
	escape_station = station
	print("[GameManager] Escape station set: ", station.station_name if station else "None")


## Get the escape station
func get_escape_station() -> Resource:
	return escape_station


# ==============================================================================
# SHIP TYPE MANAGEMENT
# ==============================================================================

## Set the player's ship type
func set_ship_type(type: int) -> void:
	ship_type = type
	ship_type_changed.emit(type)
	print("[GameManager] Ship type: ", get_ship_type_name())


## Get the player's ship type
func get_ship_type() -> int:
	return ship_type


## Get ship type as string name
func get_ship_type_name() -> String:
	match ship_type:
		0: return "Shuttle"
		1: return "Cargo"
		2: return "Fighter"
	return "Unknown"


## Initialize starting equipment (called at game start)
func initialize_starting_equipment() -> void:
	# Give player a basic laser in the combat slot
	var basic_laser := preload("res://resources/modules/basic_laser.tres")
	set_equipped_module(1, basic_laser)  # 1 = COMBAT slot
	print("[GameManager] Starting equipment: ", basic_laser.module_name)


# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

# ------------------------------------------------------------------------------
# get_health_display() - Format health for display
# ------------------------------------------------------------------------------
func get_health_display() -> String:
	return "%d/%d" % [int(current_health), int(max_health)]


# ------------------------------------------------------------------------------
# get_formatted_score() - Format score with leading zeros
# ------------------------------------------------------------------------------
# Returns "000123" instead of "123" for consistent display width
func get_formatted_score() -> String:
	# String formatting: %06d means pad with zeros to 6 digits
	return "%06d" % score


# ------------------------------------------------------------------------------
# add_score() - Add points to the current score
# ------------------------------------------------------------------------------
# Called when player loots items, destroys enemies, etc.
func add_score(points: int) -> void:
	score += points
	print("Score increased by ", points, " - Total: ", score)


# ==============================================================================
# TEMPLATE: Adding New Game State
# ==============================================================================
# To add new tracked values (like power-ups, high score, etc.):
#
# 1. Add the variable:
#    var power_level: int = 0
#
# 2. Add a signal if other nodes need to know about changes:
#    signal power_changed(new_power: int)
#
# 3. Create getter/setter functions:
#    func add_power(amount: int) -> void:
#        power_level += amount
#        emit_signal("power_changed", power_level)
#
# 4. Add to reset_game():
#    power_level = 0
# ==============================================================================
