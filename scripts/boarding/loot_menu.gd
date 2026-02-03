# ==============================================================================
# LOOT MENU - CONTAINER + INVENTORY SIDE BY SIDE WITH SEARCH REVEAL
# ==============================================================================
#
# FILE: scripts/boarding/loot_menu.gd
# PURPOSE: Full-screen loot interface with container items and inventory grid
#
# SEARCH REVEAL MECHANIC:
# - When container opens, items are hidden under a dark overlay
# - Overlay gradually fades to reveal items
# - Search progress shows how much is revealed
# - Once fully revealed, items can be dragged
#
# LAYOUT:
# ┌─────────────────────────────────────────────────────────────┐
# │                    LOOTING: Container Name                   │
# ├──────────────────────────┬──────────────────────────────────┤
# │     CONTAINER ITEMS      │         YOUR INVENTORY           │
# │   ████████████████████   │                                  │
# │   █ (searching...) █████ │   ┌──┬──┬──┬──┬──┬──┬──┬──┐     │
# │   ████████████████████   │   ├──┼──┼──┼──┼──┼──┼──┼──┤     │
# │                          │   └──┴──┴──┴──┴──┴──┴──┴──┘     │
# └──────────────────────────┴──────────────────────────────────┘
#
# ==============================================================================

extends Control
class_name LootMenu

# ==============================================================================
# PRELOADS
# ==============================================================================

const ItemTooltipClass = preload("res://scripts/loot/item_tooltip.gd")
const SearchSystemClass = preload("res://scripts/boarding/search_system.gd")

# ==============================================================================
# SIGNALS
# ==============================================================================

signal item_transferred(item_data: ItemData)
signal menu_closed
signal container_emptied
signal search_completed

# ==============================================================================
# EXPORTS
# ==============================================================================

@export var loot_item_scene: PackedScene
@export var cell_size: int = 64
@export var base_search_time: float = 3.0  # Base time to search a container

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var header_label: Label = $Panel/VBox/Header
@onready var container_panel: Control = $Panel/VBox/ContentArea/ContainerSide/ItemsPanel
@onready var container_items: Control = $Panel/VBox/ContentArea/ContainerSide/ItemsPanel/Items
@onready var inventory_grid: SlotInventory = $Panel/VBox/ContentArea/InventorySide/InventoryGrid
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var value_label: Label = $Panel/VBox/ContentArea/InventorySide/ValueLabel

# ==============================================================================
# STATE
# ==============================================================================

var current_container: Node = null
var loot_items: Array[LootItem] = []
var dragging_item: LootItem = null
var tooltip: PanelContainer = null
var tooltip_layer: CanvasLayer = null  # Canvas layer for tooltip

# Search reveal state
var is_searching: bool = false
var search_progress: float = 0.0
var search_duration: float = 3.0
var search_overlay: ColorRect = null
var search_label: Label = null
var search_progress_bar: ProgressBar = null

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	visible = false
	
	if not loot_item_scene:
		loot_item_scene = preload("res://scenes/loot/loot_item.tscn")
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	# Create tooltip for item hover
	_create_tooltip()
	
	# Create search overlay UI
	_create_search_overlay()


func _process(delta: float) -> void:
	if not visible:
		return
	
	# Hide the redundant value label - value is shown in inventory grid
	if value_label:
		value_label.visible = false
	
	# Update search progress
	if is_searching:
		_update_search(delta)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		close_menu()


func _create_tooltip() -> void:
	tooltip = ItemTooltipClass.new()
	# Add tooltip to a CanvasLayer so it's always visible (even when loot_menu is hidden)
	# This allows tooltips to work in the standalone TAB inventory panel
	tooltip_layer = CanvasLayer.new()
	tooltip_layer.name = "TooltipLayer"
	tooltip_layer.layer = 100  # High layer to stay on top
	get_tree().root.add_child(tooltip_layer)
	tooltip_layer.add_child(tooltip)


func _exit_tree() -> void:
	# Clean up the tooltip layer when this node is freed
	if tooltip_layer and is_instance_valid(tooltip_layer):
		tooltip_layer.queue_free()


## Create the dark overlay that hides items during search
func _create_search_overlay() -> void:
	# Create overlay ColorRect
	search_overlay = ColorRect.new()
	search_overlay.name = "SearchOverlay"
	search_overlay.color = Color(0.05, 0.05, 0.1, 1.0)  # Dark blue-black
	search_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Create searching label
	search_label = Label.new()
	search_label.name = "SearchLabel"
	search_label.text = "SEARCHING..."
	search_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	search_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	search_label.add_theme_font_size_override("font_size", 24)
	search_label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3))
	search_overlay.add_child(search_label)
	
	# Create progress bar
	search_progress_bar = ProgressBar.new()
	search_progress_bar.name = "SearchProgress"
	search_progress_bar.min_value = 0.0
	search_progress_bar.max_value = 1.0
	search_progress_bar.value = 0.0
	search_progress_bar.show_percentage = false
	search_overlay.add_child(search_progress_bar)


# ==============================================================================
# OPEN/CLOSE
# ==============================================================================

func open_with_container(container: Node) -> void:
	current_container = container
	
	# Play container open sound
	AudioManager.play_sfx("container_open", -2.0)
	
	if header_label and container.has_method("get") and container.get("container_name"):
		header_label.text = "LOOTING: %s" % container.container_name
	elif header_label:
		header_label.text = "LOOTING CONTAINER"
	
	# Get items from container
	var items: Array[ItemData] = []
	if container.has_method("get") and container.get("item_data_list"):
		items = container.item_data_list
	
	# Log container opened
	if DebugLogger:
		var total_value = 0
		for item in items:
			total_value += item.value if item else 0
		var container_name = container.container_name if container.has_method("get") and container.get("container_name") else "Unknown"
		DebugLogger.log_container_opened(container_name, items.size(), total_value)
	
	# Calculate search time based on container type
	search_duration = _calculate_search_duration(container)
	
	_populate_container_items(items)
	_start_search()
	
	# Refresh inventory display to ensure items are visible
	if inventory_grid:
		inventory_grid.refresh_display()
	
	visible = true


## Calculate how long to search based on container type
func _calculate_search_duration(container: Node) -> float:
	if container.has_method("get_search_duration"):
		return container.get_search_duration()
	
	# Default calculation based on container_type
	if container.has_method("get") and container.get("container_type"):
		var ctype = container.container_type
		# Bigger containers take longer
		match ctype:
			0: return 1.5   # SCRAP_PILE
			1: return 2.5   # CARGO_CRATE
			2: return 2.0   # LOCKER
			3: return 2.5   # SUPPLY_CABINET
			4: return 5.0   # VAULT
			5: return 3.5   # ARMORY
			6: return 4.0   # SECURE_CACHE
	
	return base_search_time


func close_menu() -> void:
	visible = false
	is_searching = false
	_clear_container_items()
	current_container = null
	emit_signal("menu_closed")


func _check_container_empty() -> void:
	if loot_items.is_empty():
		emit_signal("container_emptied")
		# Auto-close after brief delay
		await get_tree().create_timer(0.3).timeout
		close_menu()


# ==============================================================================
# SEARCH REVEAL SYSTEM
# ==============================================================================

## Begin the search reveal animation
func _start_search() -> void:
	is_searching = true
	search_progress = 0.0
	
	# Play search sound (looping ambient)
	AudioManager.play_sfx("container_search", -5.0)
	
	# Make sure overlay is added to container panel
	if search_overlay and container_panel:
		if search_overlay.get_parent():
			search_overlay.get_parent().remove_child(search_overlay)
		container_panel.add_child(search_overlay)
		
		# Position overlay to cover container items area
		search_overlay.size = container_panel.size
		search_overlay.position = Vector2.ZERO
		search_overlay.visible = true
		search_overlay.modulate.a = 1.0
		
		# Position label and progress bar
		if search_label:
			search_label.size = search_overlay.size
			search_label.position = Vector2(0, -30)
		
		if search_progress_bar:
			search_progress_bar.size = Vector2(search_overlay.size.x - 40, 20)
			search_progress_bar.position = Vector2(20, search_overlay.size.y / 2 + 20)
			search_progress_bar.value = 0.0
	
	# Hide all items initially
	for item in loot_items:
		if is_instance_valid(item):
			item.modulate.a = 0.0


## Update search progress each frame
func _update_search(delta: float) -> void:
	search_progress += delta / search_duration
	search_progress = clamp(search_progress, 0.0, 1.0)
	
	# Update progress bar
	if search_progress_bar:
		search_progress_bar.value = search_progress
	
	# Fade overlay based on progress
	if search_overlay:
		search_overlay.modulate.a = 1.0 - search_progress
	
	# Gradually reveal items
	for item in loot_items:
		if is_instance_valid(item):
			item.modulate.a = search_progress
	
	# Update label text
	if search_label:
		var dots = ".".repeat(int(fmod(search_progress * 10, 4)))
		search_label.text = "SEARCHING" + dots
	
	# Complete search
	if search_progress >= 1.0:
		_complete_search()


## Search complete - fully reveal items
func _complete_search() -> void:
	is_searching = false
	
	# Play search complete sound based on best rarity found
	var best_rarity := 0
	for item in loot_items:
		if is_instance_valid(item) and item.item_data:
			best_rarity = maxi(best_rarity, item.item_data.rarity)
	AudioManager.play_loot_sound(best_rarity)
	
	# Hide overlay
	if search_overlay:
		search_overlay.visible = false
	
	# Fully reveal all items and make them draggable
	for item in loot_items:
		if is_instance_valid(item):
			item.modulate.a = 1.0
			item.setup_revealed()
	
	emit_signal("search_completed")


# ==============================================================================
# CONTAINER ITEMS
# ==============================================================================

func _populate_container_items(items: Array[ItemData]) -> void:
	_clear_container_items()
	
	if not container_items:
		return
	
	var x_pos: float = 10
	var y_pos: float = 10
	var row_height: float = 0
	var max_width: float = 380.0
	
	for data in items:
		var loot_item = loot_item_scene.instantiate() as LootItem
		loot_item.initialize(data)
		
		# Connect drag signals
		loot_item.drag_started.connect(_on_item_drag_started)
		loot_item.drag_ended.connect(_on_item_drag_ended)
		loot_item.destroy_requested.connect(_on_item_destroy_requested)
		loot_item.rotate_requested.connect(_on_item_rotate_requested)
		loot_item.examine_requested.connect(_on_item_examine_requested)
		
		container_items.add_child(loot_item)
		loot_items.append(loot_item)
		
		# Don't reveal yet - search system will reveal gradually
		# Items start hidden (modulate.a = 0)
		loot_item.modulate.a = 0.0
		
		# Position items in a flow layout
		var item_size = Vector2(data.grid_width * cell_size, data.grid_height * cell_size)
		
		if x_pos + item_size.x > max_width:
			x_pos = 10
			y_pos += row_height + 10
			row_height = 0
		
		loot_item.position = Vector2(x_pos, y_pos)
		x_pos += item_size.x + 10
		row_height = max(row_height, item_size.y)


func _clear_container_items() -> void:
	for item in loot_items:
		if is_instance_valid(item):
			item.queue_free()
	loot_items.clear()
	dragging_item = null


# ==============================================================================
# DRAG AND DROP
# ==============================================================================

func _on_item_drag_started(item: LootItem) -> void:
	# Prevent dragging while still searching
	if is_searching:
		return
	
	dragging_item = item
	
	# Check if this item is from inventory (for rearranging)
	if inventory_grid and item.current_state == LootItem.ItemState.IN_INVENTORY:
		inventory_grid.start_drag_from_inventory(item)
	else:
		# Tell inventory to show hover preview
		if inventory_grid:
			inventory_grid.start_hover(item)


func _on_item_drag_ended(item: LootItem, _drop_pos: Vector2) -> void:
	if item != dragging_item:
		print("[LootMenu] _on_item_drag_ended: item != dragging_item, skipping")
		return
	
	var placed = false
	var item_name = item.item_data.name if item and item.item_data else "null"
	print("[LootMenu] _on_item_drag_ended: %s (state=%d)" % [item_name, item.current_state])
	
	# Check if this item is from inventory (for rearranging) - use state, not dragging_item
	# because start_hover also sets dragging_item for container items
	var is_from_inventory = item.current_state == LootItem.ItemState.IN_INVENTORY
	
	if inventory_grid and is_from_inventory:
		# End inventory drag (will place or return to original)
		print("[LootMenu] Item was from inventory, ending inventory drag")
		var over_grid = inventory_grid.is_cursor_over_inventory()
		placed = inventory_grid.end_drag_from_inventory(over_grid)
	else:
		# Try to place in inventory from container
		print("[LootMenu] Item from container, checking placement...")
		if inventory_grid and inventory_grid.is_cursor_over_inventory():
			print("[LootMenu] Cursor over inventory, trying to place")
			placed = inventory_grid.try_place_at_cursor(item)
			print("[LootMenu] try_place_at_cursor returned: %s" % placed)
			
			if placed:
				# Remove from container tracking
				loot_items.erase(item)
				
				if current_container and current_container.has_method("remove_item"):
					current_container.remove_item(item.item_data)
				
				# Play loot pickup sound
				AudioManager.play_sfx_varied("loot_pickup", 0.2, -2.0)
				
				# Emit signal for boarding manager to track loot value
				print("[LootMenu] Emitting item_transferred for: %s ($%d)" % [
					item.item_data.name if item.item_data else "null",
					item.item_data.value if item.item_data else 0])
				emit_signal("item_transferred", item.item_data)
				
				# Check if container is now empty
				_check_container_empty()
		else:
			print("[LootMenu] Cursor NOT over inventory")
		
		# If not placed, return to original position
		if not placed:
			item.return_to_original()
		
		# Clean up hover
		if inventory_grid:
			inventory_grid.stop_hover()
	
	dragging_item = null


# ==============================================================================
# CALLBACKS
# ==============================================================================

func _on_close_pressed() -> void:
	close_menu()


## Handle request to destroy an item (via context menu in inventory)
func _on_item_destroy_requested(item: LootItem) -> void:
	if inventory_grid:
		inventory_grid.destroy_item(item)


## Handle request to rotate an item (via context menu in inventory)
func _on_item_rotate_requested(item: LootItem) -> void:
	if inventory_grid:
		inventory_grid.rotate_item(item)


## Handle request to examine an item (via context menu in inventory)
func _on_item_examine_requested(item: LootItem) -> void:
	# Show tooltip for the item
	var item_tooltip := ItemTooltip.get_instance()
	if item_tooltip and item.item_data:
		item_tooltip.show_for_item(item.item_data)


# ==============================================================================
# INVENTORY ACCESS
# ==============================================================================

func get_inventory() -> SlotInventory:
	return inventory_grid
