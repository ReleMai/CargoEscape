# ==============================================================================
# GRID INVENTORY - REFACTORED
# ==============================================================================
#
# FILE: scripts/loot/inventory.gd
# PURPOSE: Grid-based inventory for placing items of various sizes
#
# FEATURES:
# - Grid-based placement with collision detection
# - Weight-based capacity system (default 50kg)
# - Keyboard shortcuts for inventory management
# - Visual feedback with color-coded cells
#
# ARCHITECTURE:
# -------------
# The inventory doesn't handle drag events directly. Instead, the LootManager
# calls try_place_item() when an item is dropped. This keeps the inventory
# focused on grid logic only.
#
# ==============================================================================

extends Control
class_name GridInventory

# ==============================================================================
# SIGNALS
# ==============================================================================

signal item_placed(item: LootItem, grid_pos: Vector2i)
signal item_removed(item: LootItem)
signal item_destroyed(item: LootItem)
signal inventory_full
signal item_drag_started(item: LootItem)
signal item_drag_ended(item: LootItem)
signal item_used(item: LootItem)
signal selected_slot_changed(slot_index: int)

# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Grid")
@export var grid_width: int = 8
@export var grid_height: int = 6
@export var cell_size: int = 64
@export var cell_gap: int = 2

@export_group("Capacity")
## Maximum weight capacity in kilograms
@export var max_capacity: float = 50.0

@export_group("Colors")
@export var empty_color: Color = Color(0.12, 0.12, 0.18, 0.9)
@export var occupied_color: Color = Color(0.2, 0.2, 0.28, 0.9)
@export var hover_valid_color: Color = Color(0.2, 0.7, 0.3, 0.6)
@export var hover_invalid_color: Color = Color(0.7, 0.2, 0.2, 0.6)
@export var selected_color: Color = Color(0.3, 0.5, 0.7, 0.8)

# ==============================================================================
# STATE
# ==============================================================================

# Grid data: grid[x][y] = true means occupied
var grid: Array = []

# Track which item is at each cell
var cell_items: Dictionary = {}  # "x,y" -> LootItem

# Currently showing hover preview
var hover_item: LootItem = null
var hover_pos: Vector2i = Vector2i(-1, -1)
var hover_valid: bool = false

# Dragging from inventory
var dragging_from_inventory: LootItem = null
var drag_original_pos: Vector2i = Vector2i(-1, -1)

# Total value
var total_value: int = 0

# Total weight
var current_weight: float = 0.0

# Cached style for weight bar (to avoid recreating every update)
var _weight_bar_style: StyleBoxFlat = null
var _last_weight_color: Color = Color.BLACK

# Keyboard shortcut support
var selected_slot: int = -1  # -1 means no selection, 0-8 for slots 1-9
var slot_items: Array[LootItem] = []  # Quick access slots (max 9 items)

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

var grid_container: Control
var items_layer: Control
var hover_preview: ColorRect
var value_label: Label
var weight_label: Label
var weight_bar: ProgressBar

# Cell visuals (2D array of ColorRects)
var cells: Array = []

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	grid_container = get_node_or_null("GridContainer")
	items_layer = get_node_or_null("ItemsLayer")
	hover_preview = get_node_or_null("HoverPreview")
	value_label = get_node_or_null("TotalValueLabel")
	weight_label = get_node_or_null("WeightLabel")
	weight_bar = get_node_or_null("WeightBar")
	
	_init_grid()
	_create_cell_visuals()
	_update_value_display()
	_update_weight_display()
	
	if hover_preview:
		hover_preview.visible = false


func _process(_delta: float) -> void:
	if hover_item:
		_update_hover_preview()


func _unhandled_input(_event: InputEvent) -> void:
	"""Handle keyboard shortcuts for inventory management"""
	# Note: event parameter required by Godot's virtual function signature
	# We use Input.is_action_just_pressed() instead of checking event directly
	
	# Handle number keys 1-9 for slot selection
	for i in range(9):
		var action_name = "inventory_slot_%d" % (i + 1)
		if Input.is_action_just_pressed(action_name):
			_select_slot(i)
			get_viewport().set_input_as_handled()
			return
	
	# Handle drop item (Q)
	if Input.is_action_just_pressed("drop_item"):
		_drop_selected_item()
		get_viewport().set_input_as_handled()
		return
	
	# Handle use/equip item (E)
	if Input.is_action_just_pressed("use_item"):
		_use_selected_item()
		get_viewport().set_input_as_handled()
		return


# ==============================================================================
# GRID INITIALIZATION
# ==============================================================================

func _init_grid() -> void:
	grid.clear()
	cell_items.clear()
	
	for x in range(grid_width):
		var col: Array = []
		for y in range(grid_height):
			col.append(false)
		grid.append(col)
	
	total_value = 0
	current_weight = 0.0


func _create_cell_visuals() -> void:
	if not grid_container:
		return
	
	# Clear old
	for child in grid_container.get_children():
		child.queue_free()
	cells.clear()
	
	# Size the container
	var total_w = grid_width * (cell_size + cell_gap) - cell_gap
	var total_h = grid_height * (cell_size + cell_gap) - cell_gap
	grid_container.custom_minimum_size = Vector2(total_w, total_h)
	
	# Create cells
	for y in range(grid_height):
		var row: Array = []
		for x in range(grid_width):
			var cell = ColorRect.new()
			cell.size = Vector2(cell_size, cell_size)
			cell.position = Vector2(x * (cell_size + cell_gap), y * (cell_size + cell_gap))
			cell.color = empty_color
			cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
			grid_container.add_child(cell)
			row.append(cell)
		cells.append(row)


func _update_cell_colors() -> void:
	# Get selected item for highlighting
	var selected_item = get_selected_item() if selected_slot >= 0 else null
	
	for y in range(grid_height):
		for x in range(grid_width):
			if y < cells.size() and x < cells[y].size():
				var key = "%d,%d" % [x, y]
				var cell_item = cell_items.get(key)
				
				# Check if this cell belongs to the selected item
				var is_selected = selected_item and cell_item == selected_item
				
				if is_selected:
					cells[y][x].color = selected_color
				elif grid[x][y]:
					cells[y][x].color = occupied_color
				else:
					cells[y][x].color = empty_color


# ==============================================================================
# ITEM PLACEMENT
# ==============================================================================

func can_place_at(item: LootItem, pos: Vector2i) -> bool:
	"""Check if item can be placed at grid position"""
	if not item or not item.item_data:
		return false
	
	var w = item.item_data.grid_width
	var h = item.item_data.grid_height
	
	# Bounds check
	if pos.x < 0 or pos.y < 0:
		return false
	if pos.x + w > grid_width or pos.y + h > grid_height:
		return false
	
	# Check all cells are free (ignore cells occupied by same item for moving)
	for dx in range(w):
		for dy in range(h):
			var key = "%d,%d" % [pos.x + dx, pos.y + dy]
			if grid[pos.x + dx][pos.y + dy]:
				# Allow if this cell is occupied by the same item being moved
				if cell_items.get(key) != item:
					return false
	
	return true


func place_item(item: LootItem, pos: Vector2i) -> bool:
	"""Place item at grid position. Returns true if successful."""
	if not can_place_at(item, pos):
		return false
	
	var w = item.item_data.grid_width
	var h = item.item_data.grid_height
	
	# Mark cells occupied
	for dx in range(w):
		for dy in range(h):
			var cx = pos.x + dx
			var cy = pos.y + dy
			grid[cx][cy] = true
			cell_items["%d,%d" % [cx, cy]] = item
	
	# Reset item drag state first (critical for mouse event handling)
	item.is_dragging = false
	item.z_index = 0
	item.scale = Vector2.ONE
	item.should_snap = false
	item.snap_position = Vector2.ZERO
	
	# Reparent item to inventory items layer
	if item.get_parent() != items_layer:
		item.reparent(items_layer)
	
	# Connect item signals if not already connected
	if not item.drag_started.is_connected(_on_inventory_item_drag_started):
		item.drag_started.connect(_on_inventory_item_drag_started)
	if not item.drag_ended.is_connected(_on_inventory_item_drag_ended):
		item.drag_ended.connect(_on_inventory_item_drag_ended)
	if not item.destroy_requested.is_connected(_on_inventory_item_destroy):
		item.destroy_requested.connect(_on_inventory_item_destroy)
	if not item.rotate_requested.is_connected(_on_inventory_item_rotate):
		item.rotate_requested.connect(_on_inventory_item_rotate)
	if not item.examine_requested.is_connected(_on_inventory_item_examine):
		item.examine_requested.connect(_on_inventory_item_examine)
	
	# Position item at grid cell (use local position since we're in items_layer)
	var target_pos = Vector2(pos.x * (cell_size + cell_gap), pos.y * (cell_size + cell_gap))
	item.position = target_pos
	
	# Force the item to stay at this position by updating original position
	# Use call_deferred to ensure position is applied after frame processing
	item.set_deferred("position", target_pos)
	
	# Update item's original position/parent for future drags
	# Set to the local position since that's what we want to preserve
	item.original_position = target_pos
	item.original_parent = items_layer
	
	item.set_in_inventory()
	
	# Update value and weight
	total_value += item.item_data.value
	current_weight += item.item_data.weight
	_update_value_display()
	_update_weight_display()
	_update_cell_colors()
	_update_slot_items()
	
	emit_signal("item_placed", item, pos)
	return true


func remove_item(item: LootItem) -> bool:
	"""Remove item from inventory"""
	var keys_to_remove: Array = []
	
	for key in cell_items.keys():
		if cell_items[key] == item:
			keys_to_remove.append(key)
	
	if keys_to_remove.is_empty():
		return false
	
	for key in keys_to_remove:
		var parts = key.split(",")
		var x = int(parts[0])
		var y = int(parts[1])
		grid[x][y] = false
		cell_items.erase(key)
	
	if item.item_data:
		total_value -= item.item_data.value
		current_weight -= item.item_data.weight
	
	_update_value_display()
	_update_weight_display()
	_update_cell_colors()
	_update_slot_items()
	
	emit_signal("item_removed", item)
	return true


func find_free_position(item: LootItem) -> Vector2i:
	"""Find first free position for item. Returns (-1,-1) if none."""
	if not item or not item.item_data:
		return Vector2i(-1, -1)
	
	for y in range(grid_height):
		for x in range(grid_width):
			if can_place_at(item, Vector2i(x, y)):
				return Vector2i(x, y)
	
	return Vector2i(-1, -1)


func auto_place(item: LootItem) -> bool:
	"""Automatically place item in first free spot"""
	var pos = find_free_position(item)
	if pos.x >= 0:
		return place_item(item, pos)
	
	emit_signal("inventory_full")
	return false


# ==============================================================================
# HOVER PREVIEW (for drag feedback)
# ==============================================================================

func start_hover(item: LootItem) -> void:
	"""Start showing hover preview for item"""
	hover_item = item
	
	if hover_preview and item and item.item_data:
		# Size the preview based on item dimensions
		hover_preview.size = Vector2(
			item.item_data.grid_width * cell_size,
			item.item_data.grid_height * cell_size
		)
		# Visibility will be managed by _update_hover_preview based on cursor position


func stop_hover() -> void:
	"""Stop showing hover preview"""
	# Reset snap state on the item
	if hover_item:
		hover_item.should_snap = false
	
	hover_item = null
	hover_pos = Vector2i(-1, -1)
	
	if hover_preview:
		hover_preview.visible = false


func _update_hover_preview() -> void:
	if not hover_item or not hover_preview or not grid_container:
		return
	
	# Check if cursor is over the grid
	var over_grid = is_cursor_over_grid()
	
	if not over_grid:
		# Cursor not over grid - hide preview and disable snap
		hover_preview.visible = false
		if hover_item:
			hover_item.should_snap = false
		return
	
	# Show preview when over grid
	hover_preview.visible = true
	
	# Get mouse position in grid space
	var local_pos = grid_container.get_local_mouse_position()
	var gx = int(local_pos.x / (cell_size + cell_gap))
	var gy = int(local_pos.y / (cell_size + cell_gap))
	
	hover_pos = Vector2i(gx, gy)
	hover_valid = can_place_at(hover_item, hover_pos)
	
	# Calculate grid cell position (relative to grid_container)
	var cell_pos = Vector2(gx * (cell_size + cell_gap), gy * (cell_size + cell_gap))
	
	# Position hover preview - add grid_container's position since preview is a sibling
	hover_preview.position = grid_container.position + cell_pos
	hover_preview.color = hover_valid_color if hover_valid else hover_invalid_color
	
	# Update the item's snap position so it aligns with the grid
	if hover_item and hover_item.is_dragging:
		hover_item.snap_position = grid_container.global_position + cell_pos
		hover_item.should_snap = true


func try_place_at_cursor(item: LootItem) -> bool:
	"""Try to place item at current cursor position. Returns true if placed."""
	if hover_valid and hover_pos.x >= 0:
		return place_item(item, hover_pos)
	return false


func is_cursor_over_grid() -> bool:
	"""Check if cursor is over the inventory grid"""
	if not grid_container:
		return false
	
	var local_pos = grid_container.get_local_mouse_position()
	var grid_size = Vector2(
		grid_width * (cell_size + cell_gap) - cell_gap,
		grid_height * (cell_size + cell_gap) - cell_gap
	)
	
	return local_pos.x >= 0 and local_pos.y >= 0 and local_pos.x < grid_size.x and local_pos.y < grid_size.y


# ==============================================================================
# UTILITY
# ==============================================================================

func _update_value_display() -> void:
	if value_label:
		value_label.text = "Total: $%d" % total_value


func _update_weight_display() -> void:
	"""Update weight label and bar with color coding"""
	# Update label
	if weight_label:
		weight_label.text = "Weight: %.1f / %.1f kg" % [current_weight, max_capacity]
	
	# Update progress bar
	if weight_bar:
		weight_bar.max_value = max_capacity
		weight_bar.value = current_weight
		
		# Color coding based on capacity percentage
		var weight_ratio = current_weight / max_capacity if max_capacity > 0 else 0.0
		var bar_color: Color
		
		if weight_ratio < 0.75:
			bar_color = Color(0.2, 0.8, 0.2)  # Green
		elif weight_ratio < 1.0:
			bar_color = Color(0.9, 0.8, 0.2)  # Yellow
		else:
			bar_color = Color(0.9, 0.2, 0.2)  # Red
		
		# Only update style if color changed (optimization)
		if bar_color != _last_weight_color:
			_last_weight_color = bar_color
			if not _weight_bar_style:
				_weight_bar_style = StyleBoxFlat.new()
			_weight_bar_style.bg_color = bar_color
			weight_bar.add_theme_stylebox_override("fill", _weight_bar_style)


func get_total_value() -> int:
	return total_value


func get_current_weight() -> float:
	"""Get current inventory weight"""
	return current_weight


func get_max_capacity() -> float:
	"""Get maximum weight capacity"""
	return max_capacity


func get_weight_ratio() -> float:
	"""Get current weight as ratio of max capacity (0.0 to 1.0+)"""
	return current_weight / max_capacity if max_capacity > 0 else 0.0


func is_over_encumbered() -> bool:
	"""Check if inventory is over weight capacity"""
	return current_weight > max_capacity


func can_carry_weight(additional_weight: float) -> bool:
	"""Check if additional weight can be carried"""
	return (current_weight + additional_weight) <= max_capacity


func get_item_count() -> int:
	var unique: Array = []
	for item in cell_items.values():
		if item not in unique:
			unique.append(item)
	return unique.size()


func get_all_items() -> Array[LootItem]:
	var items: Array[LootItem] = []
	for item in cell_items.values():
		if item not in items:
			items.append(item)
	return items


func clear_all() -> void:
	var items = get_all_items()
	for item in items:
		remove_item(item)
		if is_instance_valid(item):
			item.queue_free()
	

func get_item_at_position(pos: Vector2i) -> LootItem:
	"""Get item at grid position, or null if empty"""
	var key = "%d,%d" % [pos.x, pos.y]
	return cell_items.get(key, null)


func get_item_grid_position(item: LootItem) -> Vector2i:
	"""Get grid position of item's top-left corner"""
	for key in cell_items.keys():
		if cell_items[key] == item:
			var parts = key.split(",")
			var x = int(parts[0])
			var y = int(parts[1])
			# Find top-left corner
			if x == 0 or cell_items.get("%d,%d" % [x-1, y]) != item:
				if y == 0 or cell_items.get("%d,%d" % [x, y-1]) != item:
					return Vector2i(x, y)
	return Vector2i(-1, -1)


# ==============================================================================
# INVENTORY ITEM DRAGGING
# ==============================================================================

func start_drag_from_inventory(item: LootItem) -> void:
	"""Start dragging an item that's already in the inventory"""
	if not item or item not in cell_items.values():
		return
	
	dragging_from_inventory = item
	drag_original_pos = get_item_grid_position(item)
	
	# Temporarily remove from grid but keep the item
	remove_item(item)
	
	# Start hover preview for placement
	start_hover(item)
	
	emit_signal("item_drag_started", item)


func end_drag_from_inventory(drop_in_inventory: bool) -> bool:
	"""End dragging item from inventory. Returns true if successfully placed."""
	if not dragging_from_inventory:
		return false
	
	var item = dragging_from_inventory
	var placed = false
	
	if drop_in_inventory and hover_valid and hover_pos.x >= 0:
		# Place at new position
		placed = place_item(item, hover_pos)
	
	if not placed and drag_original_pos.x >= 0:
		# Return to original position
		placed = place_item(item, drag_original_pos)
	
	stop_hover()
	emit_signal("item_drag_ended", item)
	
	dragging_from_inventory = null
	drag_original_pos = Vector2i(-1, -1)
	
	return placed


func destroy_item(item: LootItem) -> void:
	"""Permanently destroy an item"""
	if not item:
		return
	
	# Remove from inventory if present
	if item in cell_items.values():
		remove_item(item)
	
	emit_signal("item_destroyed", item)
	item.queue_free()
	
	_update_cell_colors()


# ==============================================================================
# INVENTORY ITEM SIGNAL HANDLERS
# ==============================================================================

func _on_inventory_item_drag_started(item: LootItem) -> void:
	"""Handle drag start from item in inventory"""
	# Don't start a new drag if we're already dragging something
	if dragging_from_inventory and dragging_from_inventory != item:
		return
	start_drag_from_inventory(item)


func _on_inventory_item_drag_ended(item: LootItem, _drop_pos: Vector2) -> void:
	"""Handle drag end from item in inventory"""
	# Only handle if this is the item we were dragging
	if dragging_from_inventory != item:
		return
	
	var over_grid = is_cursor_over_grid()
	end_drag_from_inventory(over_grid)


func _on_inventory_item_destroy(item: LootItem) -> void:
	"""Handle destroy request from item in inventory"""
	# Can't destroy while dragging
	if dragging_from_inventory == item:
		return
	destroy_item(item)


func _on_inventory_item_rotate(item: LootItem) -> void:
	"""Handle rotate request from item in inventory"""
	# Can't rotate while dragging
	if dragging_from_inventory == item:
		return
	# Note: Basic inventory doesn't support rotation - it uses free placement
	# Just show a message or do nothing
	pass


func _on_inventory_item_examine(item: LootItem) -> void:
	"""Handle examine request from item in inventory"""
	# Show tooltip for the item
	var tooltip := ItemTooltip.get_instance()
	if tooltip and item.item_data:
		var item_rect = item.get_global_rect()
		tooltip.show_tooltip(item.item_data, item_rect.position + item_rect.size / 2)


# ==============================================================================
# KEYBOARD SHORTCUT HELPERS
# ==============================================================================

func _select_slot(slot_index: int) -> void:
	"""Select an inventory slot by index (0-8 for slots 1-9)"""
	if slot_index < 0 or slot_index >= 9:
		return
	
	# Update slot items list based on current inventory
	_update_slot_items()
	
	# Check if this slot has an item
	if slot_index >= slot_items.size():
		# No item in this slot - clear selection
		# This prevents confusion about which item is selected
		selected_slot = -1
		emit_signal("selected_slot_changed", -1)
		_update_cell_colors()
		return
	
	selected_slot = slot_index
	emit_signal("selected_slot_changed", slot_index)
	_update_cell_colors()


func _drop_selected_item() -> void:
	"""Drop the currently selected item"""
	if selected_slot < 0 or selected_slot >= slot_items.size():
		return
	
	var item = slot_items[selected_slot]
	if not item or not is_instance_valid(item):
		return
	
	# Emit signal so parent can handle dropping
	emit_signal("item_destroyed", item)
	destroy_item(item)
	
	# Clear selection after dropping
	selected_slot = -1
	_update_slot_items()


func _use_selected_item() -> void:
	"""Use/equip the currently selected item"""
	if selected_slot < 0 or selected_slot >= slot_items.size():
		return
	
	var item = slot_items[selected_slot]
	if not item or not is_instance_valid(item):
		return
	
	# Emit signal so parent can handle usage
	emit_signal("item_used", item)


func _update_slot_items() -> void:
	"""Update the quick access slot items array"""
	slot_items.clear()
	
	# Get all unique items sorted by grid position
	var items = get_all_items()
	
	# Cache grid positions to avoid redundant lookups during sorting
	var item_positions: Dictionary = {}
	for item in items:
		var pos = get_item_grid_position(item)
		# Only include items with valid positions
		if pos.x >= 0 and pos.y >= 0:
			item_positions[item] = pos
	
	# Filter out items without valid positions
	var valid_items: Array[LootItem] = []
	for item in items:
		if item in item_positions:
			valid_items.append(item)
	
	# Sort items by their grid position (top-left to bottom-right)
	valid_items.sort_custom(func(a: LootItem, b: LootItem) -> bool:
		var pos_a = item_positions[a]
		var pos_b = item_positions[b]
		if pos_a.y != pos_b.y:
			return pos_a.y < pos_b.y
		return pos_a.x < pos_b.x
	)
	
	# Take first 9 items
	for i in range(min(9, valid_items.size())):
		slot_items.append(valid_items[i])


func get_selected_item() -> LootItem:
	"""Get the currently selected item, or null if none"""
	if selected_slot < 0 or selected_slot >= slot_items.size():
		return null
	return slot_items[selected_slot]
