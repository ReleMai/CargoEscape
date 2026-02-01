# ==============================================================================
# INPUT ACTIONS - CENTRALIZED INPUT DEFINITIONS
# ==============================================================================
#
# FILE: scripts/core/input_actions.gd
# PURPOSE: Single source of truth for all input action names and key bindings
#
# USAGE:
# ------
# Access action names: InputActions.MOVE_UP
# Check input: Input.is_action_pressed(InputActions.MOVE_UP)
# Register actions: InputActions.register_all_actions()
#
# WHY THIS FILE EXISTS:
# ---------------------
# 1. Prevents typos in action strings ("move_up" vs "moveup")
# 2. Easy to see all controls in one place
# 3. Can programmatically register actions without project.godot
# 4. Enables runtime rebinding
#
# ==============================================================================

class_name InputActions
extends RefCounted


# ==============================================================================
# MOVEMENT ACTIONS
# ==============================================================================
# Standard movement in 4/8 directions

const MOVE_UP: StringName = &"move_up"
const MOVE_DOWN: StringName = &"move_down"
const MOVE_LEFT: StringName = &"move_left"
const MOVE_RIGHT: StringName = &"move_right"

# Space ship specific
const THRUST: StringName = &"thrust"
const BRAKE: StringName = &"brake"


# ==============================================================================
# GAMEPLAY ACTIONS
# ==============================================================================

const INTERACT: StringName = &"interact"
const INVENTORY: StringName = &"inventory"
const PAUSE: StringName = &"pause"

# ==============================================================================
# INVENTORY MANAGEMENT ACTIONS
# ==============================================================================

# Quick slot selection (1-9)
const INVENTORY_SLOT_1: StringName = &"inventory_slot_1"
const INVENTORY_SLOT_2: StringName = &"inventory_slot_2"
const INVENTORY_SLOT_3: StringName = &"inventory_slot_3"
const INVENTORY_SLOT_4: StringName = &"inventory_slot_4"
const INVENTORY_SLOT_5: StringName = &"inventory_slot_5"
const INVENTORY_SLOT_6: StringName = &"inventory_slot_6"
const INVENTORY_SLOT_7: StringName = &"inventory_slot_7"
const INVENTORY_SLOT_8: StringName = &"inventory_slot_8"
const INVENTORY_SLOT_9: StringName = &"inventory_slot_9"

# Item actions
const DROP_ITEM: StringName = &"drop_item"
const USE_ITEM: StringName = &"use_item"

# Menu controls
const TOGGLE_INVENTORY: StringName = &"toggle_inventory"
const CLOSE_MENU: StringName = &"close_menu"


# ==============================================================================
# UI ACTIONS
# ==============================================================================

const UI_ACCEPT: StringName = &"ui_accept"
const UI_CANCEL: StringName = &"ui_cancel"
const UI_UP: StringName = &"ui_up"
const UI_DOWN: StringName = &"ui_down"
const UI_LEFT: StringName = &"ui_left"
const UI_RIGHT: StringName = &"ui_right"


# ==============================================================================
# DEFAULT KEY BINDINGS
# ==============================================================================
# Dictionary mapping action names to their default input events

const DEFAULT_BINDINGS: Dictionary = {
	# Movement - WASD
	MOVE_UP: [KEY_W, KEY_UP],
	MOVE_DOWN: [KEY_S, KEY_DOWN],
	MOVE_LEFT: [KEY_A, KEY_LEFT],
	MOVE_RIGHT: [KEY_D, KEY_RIGHT],
	
	# Space controls
	THRUST: [KEY_W, KEY_UP, KEY_SPACE],
	BRAKE: [KEY_SHIFT, KEY_CTRL],
	
	# Gameplay
	INTERACT: [KEY_E, KEY_SPACE],
	INVENTORY: [KEY_TAB, KEY_I],
	PAUSE: [KEY_ESCAPE, KEY_P],
	
	# Inventory slots (1-9 for quick access)
	INVENTORY_SLOT_1: [KEY_1],
	INVENTORY_SLOT_2: [KEY_2],
	INVENTORY_SLOT_3: [KEY_3],
	INVENTORY_SLOT_4: [KEY_4],
	INVENTORY_SLOT_5: [KEY_5],
	INVENTORY_SLOT_6: [KEY_6],
	INVENTORY_SLOT_7: [KEY_7],
	INVENTORY_SLOT_8: [KEY_8],
	INVENTORY_SLOT_9: [KEY_9],
	
	# Item actions
	DROP_ITEM: [KEY_Q],
	# Note: USE_ITEM shares E key with INTERACT but is context-specific
	# It's handled via _unhandled_input in inventory, preventing conflicts
	USE_ITEM: [KEY_E],
}


# ==============================================================================
# REGISTRATION
# ==============================================================================

## Register all input actions programmatically
## Call this from an autoload or main scene to ensure inputs work
static func register_all_actions() -> void:
	for action_name in DEFAULT_BINDINGS.keys():
		_register_action(action_name, DEFAULT_BINDINGS[action_name])


## Register a single action with its key bindings
static func _register_action(action_name: StringName, keys: Array) -> void:
	# Skip if action already exists
	if InputMap.has_action(action_name):
		return
	
	# Add the action
	InputMap.add_action(action_name)
	
	# Add each key as an event
	for key in keys:
		var event := InputEventKey.new()
		event.keycode = key
		InputMap.action_add_event(action_name, event)


## Check if an action was just pressed this frame with optional buffer
static func is_action_just_pressed_buffered(
	action: StringName, 
	_buffer_time: float = 0.1
) -> bool:
	# For now, just use the standard check
	# A full implementation would track timing
	return Input.is_action_just_pressed(action)


# ==============================================================================
# INPUT HELPERS
# ==============================================================================

## Get movement input as a normalized Vector2
## Returns Vector2.ZERO if no input
static func get_movement_vector() -> Vector2:
	var direction := Vector2.ZERO
	
	direction.x = Input.get_axis(MOVE_LEFT, MOVE_RIGHT)
	direction.y = Input.get_axis(MOVE_UP, MOVE_DOWN)
	
	# Normalize to prevent faster diagonal movement
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	
	return direction


## Get raw movement input (not normalized, for analog sticks)
static func get_movement_vector_raw() -> Vector2:
	return Vector2(
		Input.get_axis(MOVE_LEFT, MOVE_RIGHT),
		Input.get_axis(MOVE_UP, MOVE_DOWN)
	)


## Check if any movement input is being pressed
static func is_movement_pressed() -> bool:
	return (
		Input.is_action_pressed(MOVE_UP) or
		Input.is_action_pressed(MOVE_DOWN) or
		Input.is_action_pressed(MOVE_LEFT) or
		Input.is_action_pressed(MOVE_RIGHT)
	)
