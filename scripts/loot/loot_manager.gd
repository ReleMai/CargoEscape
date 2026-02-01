# ==============================================================================
# LOOT MANAGER - MAIN CONTROLLER (REFACTORED)
# ==============================================================================
#
# FILE: scripts/loot/loot_manager.gd
# PURPOSE: Orchestrates the cargo looting minigame
#
# ARCHITECTURE:
# -------------
# This is the CENTRAL COORDINATOR for drag-and-drop. It:
#   1. Listens to drag_started/drag_ended signals from LootItems
#   2. Tells the inventory to show/hide hover preview
#   3. Decides whether to place item in inventory or return it
#
# This solves the fragmented ownership problem by having ONE script that
# handles all drag coordination.
#
# ==============================================================================

extends Control
class_name LootManager

# Preload ItemDatabase for loot generation
const ItemDB = preload("res://scripts/loot/item_database.gd")

# ==============================================================================
# SIGNALS
# ==============================================================================

signal looting_started
signal looting_ended(total_value: int)
signal item_looted(item: LootItem)
signal time_warning(seconds_left: int)

# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Timer")
@export var loot_time: float = 60.0
@export var warning_time: float = 15.0

@export_group("Containers")
@export var container_count: int = 4
@export var min_items: int = 3
@export var max_items: int = 6

@export_group("Scenes")
@export var container_scene: PackedScene
@export var loot_item_scene: PackedScene

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var container: CargoContainer = %Container
@onready var inventory: GridInventory = %Inventory
@onready var score_label: Label = %ScoreLabel
@onready var continue_button: Button = %ContinueButton
@onready var drag_visual: Control = %DraggedItem

# ==============================================================================
# STATE
# ==============================================================================

var time_remaining: float = 0.0
var is_looting: bool = false
var item_database: Array[ItemData] = []

# Current drag state
var dragging_item: LootItem = null

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_load_item_database()
	
	# Connect continue button
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
	
	# Start the game
	_start_looting()


func _process(delta: float) -> void:
	if not is_looting:
		return
	
	# Update timer
	time_remaining -= delta
	time_remaining = max(0, time_remaining)
	_update_score_display()
	
	if time_remaining <= 0:
		_end_looting()


func _input(event: InputEvent) -> void:
	# Right-click or Escape cancels drag
	if dragging_item:
		if event is InputEventMouseButton:
			var mb = event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
				_cancel_drag()
		elif event is InputEventKey:
			var key = event as InputEventKey
			if key.keycode == KEY_ESCAPE and key.pressed:
				_cancel_drag()


# ==============================================================================
# LOOTING PHASE
# ==============================================================================

func _start_looting() -> void:
	is_looting = true
	time_remaining = loot_time
	
	_populate_container()
	_update_score_display()
	
	emit_signal("looting_started")


func _end_looting() -> void:
	if not is_looting:
		return
	
	is_looting = false
	
	# Cancel any active drag
	if dragging_item:
		_cancel_drag()
	
	var final_value = inventory.get_total_value() if inventory else 0
	emit_signal("looting_ended", final_value)
	
	# Transition to escape
	_transition_to_escape()


func _transition_to_escape() -> void:
	if GameManager:
		GameManager.add_score(inventory.get_total_value() if inventory else 0)
	
	LoadingScreen.start_transition("res://scenes/main.tscn")


# ==============================================================================
# CONTAINER POPULATION
# ==============================================================================

func _populate_container() -> void:
	if not container:
		push_error("LootManager: No container found!")
		return
	
	# Generate items
	var item_count = randi_range(min_items, max_items)
	var items = _generate_items(item_count)
	container.populate_items(items)
	
	# Connect to items for drag signals
	for item in container.contained_items:
		_connect_item_signals(item)


func _generate_items(count: int) -> Array[ItemData]:
	var items: Array[ItemData] = []
	
	for i in range(count):
		var item = _get_random_item()
		if item:
			items.append(item)
	
	return items


# ==============================================================================
# DRAG AND DROP COORDINATION
# ==============================================================================

func _connect_item_signals(item: LootItem) -> void:
	"""Connect drag signals from an item"""
	if not item.drag_started.is_connected(_on_item_drag_started):
		item.drag_started.connect(_on_item_drag_started)
	if not item.drag_ended.is_connected(_on_item_drag_ended):
		item.drag_ended.connect(_on_item_drag_ended)


func _on_item_drag_started(item: LootItem) -> void:
	"""Called when any item starts being dragged"""
	dragging_item = item
	
	# Tell inventory to show hover preview
	if inventory:
		inventory.start_hover(item)


func _on_item_drag_ended(item: LootItem, _drop_pos: Vector2) -> void:
	"""Called when item is released"""
	if item != dragging_item:
		return
	
	var placed = false
	
	# Try to place in inventory if cursor is over it
	if inventory and inventory.is_cursor_over_grid():
		placed = inventory.try_place_at_cursor(item)
		
		if placed:
			# Remove from container
			if container:
				container.remove_item(item)
			emit_signal("item_looted", item)
			_update_score_display()
	
	# If not placed, return to original position
	if not placed:
		item.return_to_original()
	
	# Clean up
	if inventory:
		inventory.stop_hover()
	dragging_item = null


func _cancel_drag() -> void:
	"""Cancel current drag operation"""
	if dragging_item:
		dragging_item.cancel_drag()
		dragging_item = null
	
	if inventory:
		inventory.stop_hover()


# ==============================================================================
# SCORE DISPLAY
# ==============================================================================

func _update_score_display() -> void:
	if not score_label:
		return
	
	var current_value = inventory.get_total_value() if inventory else 0
	score_label.text = "SCORE: $%d" % current_value


# ==============================================================================
# CALLBACKS
# ==============================================================================

func _on_continue_pressed() -> void:
	_end_looting()


# ==============================================================================
# ITEM DATABASE - Now using ItemDatabase class
# ==============================================================================

## Current loot tier based on game state
var current_loot_tier: int = 0

func _load_item_database() -> void:
	item_database.clear()
	
	# Determine loot tier from GameManager or default to 0
	if GameManager and "loot_tier" in GameManager:
		current_loot_tier = GameManager.loot_tier
	else:
		current_loot_tier = 0
	
	print("[LootManager] Using loot tier: ", current_loot_tier)


func _get_random_item() -> ItemData:
	# Use ItemDB (preloaded) to roll loot based on tier
	var item = ItemDB.roll_loot(current_loot_tier)
	if item:
		return item
	
	# Fallback to scrap metal
	return ItemDB.create_item("scrap_metal")
