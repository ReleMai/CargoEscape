# ==============================================================================
# TUTORIAL MANAGER (AUTOLOAD/SINGLETON)
# ==============================================================================
#
# FILE: scripts/core/tutorial_manager.gd
# PURPOSE: Manages interactive tutorial system for new players
#
# TUTORIAL FLOW:
# 1. Checks if tutorial should be shown
# 2. Displays step-by-step guidance with highlights and tooltips
# 3. Waits for player actions before proceeding
# 4. Tracks completion in save data
#
# USAGE:
# - TutorialManager.start_tutorial()
# - TutorialManager.skip_tutorial()
# - TutorialManager.complete_current_step()
#
# ==============================================================================

extends Node

# ==============================================================================
# SIGNALS
# ==============================================================================

signal tutorial_started
signal tutorial_completed
signal tutorial_skipped
signal step_started(step_id: String)
signal step_completed(step_id: String)

# ==============================================================================
# TUTORIAL STEPS
# ==============================================================================

enum TutorialStep {
	NONE = -1,
	MOVEMENT = 0,
	CONTAINER_INTERACTION = 1,
	INVENTORY = 2,
	TIMER = 3,
	EXIT = 4,
	SELLING = 5
}

const STEP_DATA = {
	TutorialStep.MOVEMENT: {
		"id": "movement",
		"title": "Movement Controls",
		"description": "Use WASD or Arrow Keys to move around the ship.\nTry moving in all directions!",
		"highlight_target": null,
		"wait_for_action": "movement"
	},
	TutorialStep.CONTAINER_INTERACTION: {
		"id": "container_interaction",
		"title": "Interacting with Containers",
		"description": "Approach a container and press E to search it.\nContainers contain valuable loot!",
		"highlight_target": "container",
		"wait_for_action": "container_search"
	},
	TutorialStep.INVENTORY: {
		"id": "inventory",
		"title": "Managing Inventory",
		"description": "Press I or TAB to open your inventory.\nDrag items to manage your loot.",
		"highlight_target": "inventory",
		"wait_for_action": "inventory_open"
	},
	TutorialStep.TIMER: {
		"id": "timer",
		"title": "Understanding the Timer",
		"description": "You have limited time to loot!\nWatch the timer at the top of the screen.\nDon't let it run out!",
		"highlight_target": "timer",
		"wait_for_action": "none"
	},
	TutorialStep.EXIT: {
		"id": "exit",
		"title": "Finding the Exit",
		"description": "Find the exit marker and reach it before time runs out.\nThe exit is marked with a glowing indicator!",
		"highlight_target": "exit",
		"wait_for_action": "exit_reached"
	},
	TutorialStep.SELLING: {
		"id": "selling",
		"title": "Selling Loot at Station",
		"description": "At the station, you can sell your loot for credits.\nClick on items to sell them.",
		"highlight_target": "station_sell",
		"wait_for_action": "item_sold"
	}
}

# ==============================================================================
# STATE
# ==============================================================================

var is_active: bool = false
var current_step: TutorialStep = TutorialStep.NONE
var tutorial_overlay: Node = null
var can_skip: bool = true

# ==============================================================================
# BUILT-IN FUNCTIONS
# ==============================================================================

func _ready() -> void:
	print("[TutorialManager] Initialized")


# ==============================================================================
# TUTORIAL CONTROL
# ==============================================================================

## Start the tutorial system
func start_tutorial() -> void:
	# Check if we have save manager
	if not has_node("/root/SaveManager"):
		push_warning("[TutorialManager] SaveManager not found, tutorial disabled")
		return
	
	var save_manager = get_node("/root/SaveManager")
	
	# Check if tutorial should be shown
	if not save_manager.should_show_tutorial():
		print("[TutorialManager] Tutorial already completed or disabled")
		return
	
	is_active = true
	tutorial_started.emit()
	print("[TutorialManager] Tutorial started")
	
	# Load tutorial overlay UI
	_load_tutorial_overlay()
	
	# Start first step
	start_step(TutorialStep.MOVEMENT)


## Skip the tutorial
func skip_tutorial() -> void:
	if not is_active:
		return
	
	is_active = false
	current_step = TutorialStep.NONE
	
	# Mark tutorial as completed in save
	if has_node("/root/SaveManager"):
		var save_manager = get_node("/root/SaveManager")
		save_manager.complete_tutorial()
	
	# Hide overlay
	if tutorial_overlay and is_instance_valid(tutorial_overlay):
		tutorial_overlay.queue_free()
		tutorial_overlay = null
	
	tutorial_skipped.emit()
	print("[TutorialManager] Tutorial skipped")


## Complete the current tutorial step
func complete_current_step() -> void:
	if current_step == TutorialStep.NONE:
		return
	
	var step_data = STEP_DATA.get(current_step)
	if not step_data:
		return
	
	# Mark step as completed
	if has_node("/root/SaveManager"):
		var save_manager = get_node("/root/SaveManager")
		save_manager.complete_tutorial_step(step_data.id)
	
	step_completed.emit(step_data.id)
	print("[TutorialManager] Step completed: ", step_data.id)
	
	# Move to next step or complete tutorial
	var next_step = current_step + 1
	if next_step > TutorialStep.SELLING:
		_complete_tutorial()
	else:
		# Don't auto-advance to selling step (that's in a different scene)
		if next_step == TutorialStep.SELLING:
			current_step = TutorialStep.NONE
		else:
			start_step(next_step)


## Start a specific tutorial step
func start_step(step: TutorialStep) -> void:
	current_step = step
	var step_data = STEP_DATA.get(step)
	
	if not step_data:
		push_error("[TutorialManager] Invalid step: ", step)
		return
	
	step_started.emit(step_data.id)
	print("[TutorialManager] Step started: ", step_data.id)
	
	# Update overlay UI
	if tutorial_overlay and tutorial_overlay.has_method("show_step"):
		tutorial_overlay.show_step(step_data)


## Notify tutorial of a player action
func on_player_action(action: String) -> void:
	if not is_active or current_step == TutorialStep.NONE:
		return
	
	var step_data = STEP_DATA.get(current_step)
	if not step_data:
		return
	
	# Check if this action completes the current step
	if step_data.wait_for_action == action:
		complete_current_step()
	elif step_data.wait_for_action == "none":
		# Auto-complete after showing message
		await get_tree().create_timer(4.0).timeout
		# Check if still on same step (compare enum values)
		if STEP_DATA.get(current_step) == step_data:
			complete_current_step()


## Check if tutorial is active
func is_tutorial_active() -> bool:
	return is_active


## Get current step
func get_current_step() -> TutorialStep:
	return current_step


# ==============================================================================
# PRIVATE FUNCTIONS
# ==============================================================================

func _load_tutorial_overlay() -> void:
	# Load tutorial overlay scene
	var overlay_scene = load("res://scenes/ui/tutorial_overlay.tscn")
	if not overlay_scene:
		push_error("[TutorialManager] Failed to load tutorial overlay scene")
		return
	
	tutorial_overlay = overlay_scene.instantiate()
	
	# Add to scene tree (as top-level UI)
	var root = get_tree().root
	root.add_child(tutorial_overlay)
	
	# Connect skip button if available
	if tutorial_overlay.has_signal("skip_requested"):
		tutorial_overlay.skip_requested.connect(skip_tutorial)
	
	print("[TutorialManager] Tutorial overlay loaded")


func _complete_tutorial() -> void:
	is_active = false
	current_step = TutorialStep.NONE
	
	# Mark tutorial as completed
	if has_node("/root/SaveManager"):
		var save_manager = get_node("/root/SaveManager")
		save_manager.complete_tutorial()
	
	# Hide overlay
	if tutorial_overlay and is_instance_valid(tutorial_overlay):
		tutorial_overlay.queue_free()
		tutorial_overlay = null
	
	tutorial_completed.emit()
	print("[TutorialManager] Tutorial completed!")
