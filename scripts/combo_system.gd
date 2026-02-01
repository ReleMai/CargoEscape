# ==============================================================================
# COMBO SYSTEM - SCORING MULTIPLIER MECHANIC
# ==============================================================================
#
# FILE: scripts/combo_system.gd
# PURPOSE: Manages combo scoring for consecutive successful looting actions
#
# MECHANICS:
# - Combo increases when items are revealed from containers
# - Combo timer decreases over time
# - Combo breaks when taking damage or timer expires
# - Higher combos provide score multipliers
# - Visual feedback through signals
#
# ==============================================================================

extends Node
class_name ComboSystem

# ==============================================================================
# SIGNALS
# ==============================================================================

## Emitted when combo counter changes
signal combo_changed(combo_count: int, multiplier: float)

## Emitted when combo timer updates (for progress bar)
signal combo_timer_updated(time_remaining: float, max_time: float)

## Emitted when combo is broken
signal combo_broken

## Emitted when combo reaches a new threshold
signal combo_threshold_reached(threshold: int, multiplier: float)

# ==============================================================================
# CONSTANTS
# ==============================================================================

## Time window to maintain combo (seconds)
const COMBO_TIME_WINDOW: float = 5.0

## Combo thresholds and their multipliers
const COMBO_THRESHOLDS: Dictionary = {
	2: 1.2,   # 2 items = 1.2x multiplier
	5: 1.5,   # 5 items = 1.5x multiplier
	10: 2.0,  # 10 items = 2.0x multiplier
	15: 2.5,  # 15 items = 2.5x multiplier
	20: 3.0   # 20 items = 3.0x multiplier
}

## Bonus credits at specific combo milestones
const COMBO_BONUS_CREDITS: Dictionary = {
	5: 50,
	10: 150,
	15: 300,
	20: 500
}

# ==============================================================================
# STATE
# ==============================================================================

## Current combo count (number of consecutive items revealed)
var combo_count: int = 0

## Current score multiplier based on combo
var combo_multiplier: float = 1.0

## Time remaining in current combo window
var combo_timer: float = 0.0

## Whether combo is currently active
var is_combo_active: bool = false

## Last combo threshold reached (to avoid duplicate threshold events)
var last_threshold: int = 0

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	reset_combo()


func _process(delta: float) -> void:
	if is_combo_active:
		_update_combo_timer(delta)

# ==============================================================================
# COMBO MANAGEMENT
# ==============================================================================

## Called when player successfully reveals an item from a container
func increase_combo() -> void:
	combo_count += 1
	
	# Reset timer to max window
	combo_timer = COMBO_TIME_WINDOW
	is_combo_active = true
	
	# Update multiplier based on current combo
	_update_multiplier()
	
	# Emit combo changed signal
	combo_changed.emit(combo_count, combo_multiplier)
	combo_timer_updated.emit(combo_timer, COMBO_TIME_WINDOW)
	
	# Check for threshold reached
	_check_threshold()
	
	print("[ComboSystem] Combo: %d (%.1fx multiplier)" % [combo_count, combo_multiplier])


## Update the combo timer
func _update_combo_timer(delta: float) -> void:
	combo_timer -= delta
	
	# Emit timer update
	combo_timer_updated.emit(combo_timer, COMBO_TIME_WINDOW)
	
	# Check if combo expired
	if combo_timer <= 0.0:
		break_combo()


## Break the current combo (called on damage or timer expiration)
func break_combo() -> void:
	if combo_count == 0:
		return
	
	print("[ComboSystem] Combo broken! Was at: %d" % combo_count)
	
	# Reset combo state
	combo_count = 0
	combo_multiplier = 1.0
	combo_timer = 0.0
	is_combo_active = false
	last_threshold = 0
	
	# Emit signals
	combo_broken.emit()
	combo_changed.emit(combo_count, combo_multiplier)


## Reset combo to initial state (called on game reset)
func reset_combo() -> void:
	combo_count = 0
	combo_multiplier = 1.0
	combo_timer = 0.0
	is_combo_active = false
	last_threshold = 0


## Update multiplier based on current combo count
func _update_multiplier() -> void:
	# Find highest threshold met
	var highest_multiplier: float = 1.0
	
	for threshold in COMBO_THRESHOLDS.keys():
		if combo_count >= threshold:
			highest_multiplier = COMBO_THRESHOLDS[threshold]
	
	combo_multiplier = highest_multiplier


## Check if a new threshold was reached and award bonuses
func _check_threshold() -> void:
	for threshold in COMBO_THRESHOLDS.keys():
		if combo_count == threshold and threshold > last_threshold:
			last_threshold = threshold
			
			# Emit threshold reached signal
			combo_threshold_reached.emit(threshold, COMBO_THRESHOLDS[threshold])
			
			# Award bonus credits if applicable
			if threshold in COMBO_BONUS_CREDITS:
				var bonus = COMBO_BONUS_CREDITS[threshold]
				if GameManager:
					GameManager.add_credits(bonus)
				print("[ComboSystem] Threshold bonus! +%d credits" % bonus)

# ==============================================================================
# GETTERS
# ==============================================================================

## Get current combo count
func get_combo_count() -> int:
	return combo_count


## Get current multiplier
func get_multiplier() -> float:
	return combo_multiplier


## Get time remaining in combo window
func get_time_remaining() -> float:
	return combo_timer


## Get max combo time
func get_max_time() -> float:
	return COMBO_TIME_WINDOW


## Check if combo is active
func is_active() -> bool:
	return is_combo_active


## Apply combo multiplier to a score value
func apply_multiplier(base_score: int) -> int:
	return int(base_score * combo_multiplier)
