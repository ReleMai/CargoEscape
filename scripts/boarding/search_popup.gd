# ==============================================================================
# SEARCH POPUP - CONTAINER SEARCH UI
# ==============================================================================
#
# FILE: scripts/boarding/search_popup.gd
# PURPOSE: UI popup for searching containers - integrates with loot system
#
# ==============================================================================

extends Control
class_name SearchPopup

# ==============================================================================
# SIGNALS
# ==============================================================================

signal item_taken(item_data: ItemData)
signal search_closed

# ==============================================================================
# EXPORTS
# ==============================================================================

@export var loot_item_scene: PackedScene

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var header_label: Label = $Panel/VBox/Header
@onready var items_container: Control = $Panel/VBox/ItemsArea/ItemsContainer
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var take_all_button: Button = $Panel/VBox/TakeAllButton

# ==============================================================================
# STATE
# ==============================================================================

var current_container: ShipContainer = null
var loot_items: Array = []  # LootItem nodes

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	visible = false
	
	if not loot_item_scene:
		loot_item_scene = preload("res://scenes/loot/loot_item.tscn")
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	if take_all_button:
		take_all_button.pressed.connect(_on_take_all_pressed)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		close_popup()


# ==============================================================================
# OPEN/CLOSE
# ==============================================================================

func open_with_container(container: ShipContainer) -> void:
	current_container = container
	
	if header_label:
		header_label.text = "Searching: %s" % container.container_name
	
	_populate_items(container.item_data_list)
	visible = true


func close_popup() -> void:
	visible = false
	current_container = null
	_clear_items()
	emit_signal("search_closed")


# ==============================================================================
# ITEM MANAGEMENT
# ==============================================================================

func _populate_items(item_data_list: Array[ItemData]) -> void:
	_clear_items()
	
	if not items_container:
		return
	
	var x_pos = 10
	var y_pos = 10
	var row_height = 0
	var max_width = 400
	
	for data in item_data_list:
		var loot_item = loot_item_scene.instantiate() as LootItem
		loot_item.initialize(data)
		
		# Connect signals
		loot_item.search_completed.connect(_on_item_revealed.bind(loot_item))
		loot_item.drag_started.connect(_on_item_drag_started.bind(loot_item))
		
		items_container.add_child(loot_item)
		loot_items.append(loot_item)
		
		# Position
		var item_size = Vector2(data.grid_width * 64, data.grid_height * 64)
		
		if x_pos + item_size.x > max_width:
			x_pos = 10
			y_pos += row_height + 10
			row_height = 0
		
		loot_item.position = Vector2(x_pos, y_pos)
		x_pos += item_size.x + 10
		row_height = max(row_height, item_size.y)


func _clear_items() -> void:
	for item in loot_items:
		if is_instance_valid(item):
			item.queue_free()
	loot_items.clear()


# ==============================================================================
# CALLBACKS
# ==============================================================================

func _on_item_revealed(_item: LootItem) -> void:
	# Item has been searched and revealed
	pass


func _on_item_drag_started(_dragged_item: LootItem, loot_item: LootItem) -> void:
	# Player is dragging an item - they want to take it
	# _dragged_item is the item from the signal, loot_item is from .bind()
	if loot_item.current_state == LootItem.ItemState.REVEALED:
		_take_item(loot_item)


func _take_item(loot_item: LootItem) -> void:
	if not current_container or not loot_item.item_data:
		return
	
	var item_data = loot_item.item_data
	
	# Remove from container
	current_container.remove_item(item_data)
	
	# Remove from our display
	loot_items.erase(loot_item)
	loot_item.queue_free()
	
	# Emit signal
	emit_signal("item_taken", item_data)
	
	# Close if container is empty
	if current_container.item_data_list.is_empty():
		close_popup()


func _on_take_all_pressed() -> void:
	if not current_container:
		return
	
	# Take all revealed items
	var items_to_take: Array = []
	for loot_item in loot_items:
		if loot_item.current_state == LootItem.ItemState.REVEALED:
			items_to_take.append(loot_item)
	
	for loot_item in items_to_take:
		_take_item(loot_item)


func _on_close_pressed() -> void:
	close_popup()
