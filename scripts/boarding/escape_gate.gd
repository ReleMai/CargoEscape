# ==============================================================================
# ESCAPE GATE - KILL REQUIREMENT SYSTEM
# ==============================================================================
#
# FILE: scripts/boarding/escape_gate.gd
# PURPOSE: Manages escape requirements - kill X enemies to unlock exit
#
# DESIGN:
# - Each ship tier requires a certain number of kills
# - Gate is locked until requirement met
# - Visual/audio feedback when gate unlocks
# - UI shows progress toward requirement
#
# ==============================================================================

extends Node
class_name EscapeGate


# ==============================================================================
# SIGNALS
# ==============================================================================

signal gate_unlocked
signal progress_updated(current: int, required: int)
signal enemy_killed_tracked


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Requirements by Tier")
## Kill requirements per ship tier (index 0 = tier 1)
@export var kills_by_tier: Array[int] = [2, 3, 4, 5, 7]

@export_group("Overrides")
## Force a specific requirement (0 = use tier-based)
@export var forced_requirement: int = 0

@export_group("Feedback")
## Play unlock sound when gate opens
@export var play_unlock_sound: bool = true
## Flash exit point when unlocked
@export var flash_exit_on_unlock: bool = true


# ==============================================================================
# STATE
# ==============================================================================

var kills_required: int = 0
var kills_current: int = 0
var is_unlocked: bool = false
var ship_tier: int = 1

# Reference to exit point (set by boarding manager)
var exit_point: Node2D = null


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Connect to all soldiers in scene
	_connect_to_soldiers()


## Initialize the gate with a ship tier
func initialize(tier: int, exit: Node2D = null) -> void:
	ship_tier = tier
	exit_point = exit
	
	# Set requirement
	if forced_requirement > 0:
		kills_required = forced_requirement
	else:
		var tier_index = clampi(tier - 1, 0, kills_by_tier.size() - 1)
		kills_required = kills_by_tier[tier_index]
	
	kills_current = 0
	is_unlocked = false
	
	# Lock exit initially
	if exit_point and exit_point.has_method("set_locked"):
		exit_point.set_locked(true, "Eliminate %d crew members" % kills_required)
	
	print("[EscapeGate] Initialized - Tier %d requires %d kills" % [tier, kills_required])
	progress_updated.emit(kills_current, kills_required)


## Connect to all existing soldiers and any that spawn later
func _connect_to_soldiers() -> void:
	# Connect to existing soldiers
	for soldier in get_tree().get_nodes_in_group("soldiers"):
		_connect_soldier(soldier)
	
	# Watch for new soldiers being added
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node.is_in_group("soldiers"):
		_connect_soldier(node)


func _connect_soldier(soldier: Node) -> void:
	if soldier.has_signal("soldier_died"):
		if not soldier.soldier_died.is_connected(_on_soldier_died):
			soldier.soldier_died.connect(_on_soldier_died)


# ==============================================================================
# KILL TRACKING
# ==============================================================================

func _on_soldier_died() -> void:
	if is_unlocked:
		return
	
	kills_current += 1
	enemy_killed_tracked.emit()
	progress_updated.emit(kills_current, kills_required)
	
	print("[EscapeGate] Kill tracked: %d/%d" % [kills_current, kills_required])
	
	# Check if requirement met
	if kills_current >= kills_required:
		_unlock_gate()


func _unlock_gate() -> void:
	if is_unlocked:
		return
	
	is_unlocked = true
	
	print("[EscapeGate] GATE UNLOCKED!")
	
	# Unlock exit point
	if exit_point and exit_point.has_method("set_locked"):
		exit_point.set_locked(false)
	
	# Play unlock sound
	if play_unlock_sound:
		AudioManager.play_sfx("unlock_gate")
		# Also play a positive chime
		AudioManager.play_sfx("objective_complete")
	
	# Flash the exit point
	if flash_exit_on_unlock and exit_point:
		_flash_exit()
	
	# Emit signal
	gate_unlocked.emit()


func _flash_exit() -> void:
	if not exit_point:
		return
	
	# Create a flash effect
	var original_modulate = exit_point.modulate
	var tween = create_tween()
	
	# Flash sequence
	tween.tween_property(exit_point, "modulate", Color(2.0, 2.0, 1.0, 1.0), 0.1)
	tween.tween_property(exit_point, "modulate", original_modulate, 0.2)
	tween.tween_property(exit_point, "modulate", Color(1.5, 2.0, 1.5, 1.0), 0.1)
	tween.tween_property(exit_point, "modulate", original_modulate, 0.3)


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Get current progress
func get_progress() -> Dictionary:
	return {
		"current": kills_current,
		"required": kills_required,
		"unlocked": is_unlocked,
		"remaining": maxi(0, kills_required - kills_current)
	}


## Check if gate is unlocked
func can_escape() -> bool:
	return is_unlocked


## Force unlock (for debugging or special circumstances)
func force_unlock() -> void:
	kills_current = kills_required
	_unlock_gate()


## Add kills manually (for non-soldier enemies)
func add_kill(count: int = 1) -> void:
	for i in range(count):
		_on_soldier_died()
