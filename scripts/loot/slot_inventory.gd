# ==============================================================================
# SLOT INVENTORY - MULTI-SLOT INVENTORY SYSTEM
# ==============================================================================
#
# FILE: scripts/loot/slot_inventory.gd
# PURPOSE: Grid inventory where items can span multiple slots based on size
#
# FEATURES:
# - Items occupy slots based on their grid_width x grid_height
# - Simple slot-based collision detection
# - Weight-based capacity system
# - Clean visual layout
#
# ==============================================================================

extends Control
class_name SlotInventory

# ==============================================================================
# SIGNALS
# ==============================================================================

signal item_placed(item: LootItem, slot_index: int)
signal item_removed(item: LootItem)
signal item_destroyed(item: LootItem)
signal inventory_full
signal item_drag_started(item: LootItem)
signal item_drag_ended(item: LootItem)

# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Layout")
## Number of columns in the grid
@export var columns: int = 8
## Number of rows in the grid
@export var rows: int = 6
## Size of each slot in pixels
@export var slot_size: int = 64
## Gap between slots
@export var slot_gap: int = 2

@export_group("Capacity")
## Maximum weight capacity in kilograms
@export var max_capacity: float = 50.0

@export_group("Colors")
@export var empty_slot_color: Color = Color(0.15, 0.15, 0.22, 0.9)
@export var occupied_slot_color: Color = Color(0.2, 0.2, 0.28, 0.9)
@export var hover_valid_color: Color = Color(0.2, 0.7, 0.3, 0.6)
@export var hover_invalid_color: Color = Color(0.7, 0.2, 0.2, 0.6)

# ==============================================================================
# STATE
# ==============================================================================

## Grid of slot occupancy: slot_index -> LootItem (null = empty)
var slot_grid: Array = []

## All placed items (for iteration)
var placed_items: Array[LootItem] = []

## Total number of slots
var total_slots: int = 0

## Currently hovered slot during drag
var hover_slot: int = -1
var hover_valid: bool = false

## Item being dragged
var dragging_item: LootItem = null
var drag_original_slot: int = -1

## Stats
var total_value: int = 0
var current_weight: float = 0.0

## Save optimization
var _save_pending: bool = false
var _save_timer: float = 0.0
const SAVE_DELAY: float = 0.1  # Batch saves within 100ms window

# ==============================================================================
# NODE REFERENCES (created dynamically)
# ==============================================================================

var slots_container: Control = null
var items_container: Control = null
var hover_preview: Control = null
var slot_visuals: Array[ColorRect] = []

# Keycard slot references
var keycard_container: Control = null
var keycard_slot_visual: ColorRect = null
var keycard_item: LootItem = null
var keycard_label: Label = null

# ==============================================================================
# CONSTANTS
# ==============================================================================

const KEYCARD_SLOT_SIZE: int = 64

# ==============================================================================
# LIFECYCLE
# ==============================================================================

var _initialized: bool = false
var _instance_id: int = 0
static var _next_instance_id: int = 0

func _ready() -> void:
	_instance_id = _next_instance_id
	_next_instance_id += 1
	
	# Only initialize once - don't reset if already set up
	if _initialized:
		return
	
	total_slots = columns * rows
	slot_grid.resize(total_slots)
	for i in range(total_slots):
		slot_grid[i] = null
	
	_create_ui()
	
	# Load saved inventory from GameManager
	_load_from_game_manager()
	
	_update_displays()
	_initialized = true
	
	# Connect visibility change to refresh items
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		# Check if any items are invalid (freed)
		var has_invalid = false
		for item in placed_items:
			if not is_instance_valid(item):
				has_invalid = true
				break
		
		# Only reload if items became invalid (were freed externally)
		# Don't reload just because GM has items - we already have them
		if has_invalid:
			# Items were freed - reload from GameManager
			print("[SlotInventory] Detected invalid items, reloading from GameManager")
			_clear_and_reload_from_game_manager()
		else:
			refresh_display()


## Clear invalid items and reload from GameManager
func _clear_and_reload_from_game_manager() -> void:
	# Clear any invalid items from tracking
	for i in range(total_slots):
		slot_grid[i] = null
	placed_items.clear()
	
	# Clear visual children
	if items_container:
		for child in items_container.get_children():
			child.queue_free()
	
	# Reload from GameManager
	_load_from_game_manager()
	_update_slot_colors()


func _process(_delta: float) -> void:
	if dragging_item:
		_update_hover_state()
	
	# Handle deferred save
	if _save_pending:
		_save_timer -= _delta
		if _save_timer <= 0:
			_save_pending = false
			_do_save_to_game_manager()


## Handle keyboard input for item rotation while dragging
func _unhandled_input(event: InputEvent) -> void:
	# R key to rotate while dragging
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if dragging_item:
			_rotate_dragging_item()
			get_viewport().set_input_as_handled()


## Call this to refresh all items' visual state
func refresh_display() -> void:
	_recalculate_stats()
	_update_slot_colors()
	
	# Ensure all items are properly visible
	for item in placed_items:
		_ensure_item_visible(item)


# ==============================================================================
# UI CREATION
# ==============================================================================

func _create_ui() -> void:
	# Don't create if already exists
	if slots_container != null:
		return
	
	slots_container = Control.new()
	slots_container.name = "SlotsContainer"
	add_child(slots_container)
	
	hover_preview = Control.new()
	hover_preview.name = "HoverPreview"
	hover_preview.visible = false
	hover_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hover_preview)
	
	items_container = Control.new()
	items_container.name = "ItemsContainer"
	items_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(items_container)
	
	var total_width = columns * (slot_size + slot_gap) - slot_gap
	var total_height = rows * (slot_size + slot_gap) - slot_gap
	custom_minimum_size = Vector2(total_width, total_height + 80)  # Extra space for keycard slot
	
	slot_visuals.clear()
	for i in range(total_slots):
		var slot_rect = ColorRect.new()
		slot_rect.size = Vector2(slot_size, slot_size)
		slot_rect.position = _get_slot_pixel_pos(i)
		slot_rect.color = empty_slot_color
		slot_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slots_container.add_child(slot_rect)
		slot_visuals.append(slot_rect)
	
	# Create keycard slot below the main grid
	_create_keycard_slot(total_width, total_height)


## Create the dedicated keycard slot UI
func _create_keycard_slot(grid_width: float, grid_height: float) -> void:
	keycard_container = Control.new()
	keycard_container.name = "KeycardContainer"
	keycard_container.position = Vector2(0, grid_height + 10)
	add_child(keycard_container)
	
	# Create background panel
	var bg = ColorRect.new()
	bg.size = Vector2(grid_width, 70)
	bg.color = Color(0.12, 0.12, 0.18, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	keycard_container.add_child(bg)
	
	# Create label
	keycard_label = Label.new()
	keycard_label.text = "KEYCARD"
	keycard_label.position = Vector2(10, 8)
	keycard_label.add_theme_font_size_override("font_size", 12)
	keycard_label.add_theme_color_override("font_color", Color(0.5, 0.7, 0.9, 1.0))
	keycard_container.add_child(keycard_label)
	
	# Create keycard slot visual
	keycard_slot_visual = ColorRect.new()
	keycard_slot_visual.size = Vector2(KEYCARD_SLOT_SIZE, KEYCARD_SLOT_SIZE)
	keycard_slot_visual.position = Vector2(10, 28)
	keycard_slot_visual.color = Color(0.18, 0.25, 0.35, 0.9)  # Blue-tinted slot
	keycard_slot_visual.mouse_filter = Control.MOUSE_FILTER_STOP
	keycard_container.add_child(keycard_slot_visual)
	
	# Create hint text
	var hint = Label.new()
	hint.text = "(Keycards don't count toward weight)"
	hint.position = Vector2(KEYCARD_SLOT_SIZE + 20, 45)
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6, 1.0))
	keycard_container.add_child(hint)


func _get_slot_pixel_pos(slot_index: int) -> Vector2:
	var col = slot_index % columns
	var row = int(slot_index / columns)
	return Vector2(col * (slot_size + slot_gap), row * (slot_size + slot_gap))


func _get_slot_at_pixel(local_pos: Vector2) -> int:
	if local_pos.x < 0 or local_pos.y < 0:
		return -1
	var col = int(local_pos.x / (slot_size + slot_gap))
	var row = int(local_pos.y / (slot_size + slot_gap))
	if col >= columns or row >= rows:
		return -1
	var slot_pos = _get_slot_pixel_pos(row * columns + col)
	if local_pos.x > slot_pos.x + slot_size or local_pos.y > slot_pos.y + slot_size:
		return -1
	return row * columns + col


func _slot_to_col(slot: int) -> int:
	return slot % columns


func _slot_to_row(slot: int) -> int:
	return int(slot / columns)


func _col_row_to_slot(col: int, row: int) -> int:
	if col < 0 or col >= columns or row < 0 or row >= rows:
		return -1
	return row * columns + col


# ==============================================================================
# HOVER MANAGEMENT
# ==============================================================================

func start_hover(item: LootItem) -> void:
	dragging_item = item
	_create_hover_preview(item)


func stop_hover() -> void:
	if dragging_item:
		dragging_item.should_snap = false
	dragging_item = null
	hover_slot = -1
	hover_valid = false
	hover_preview.visible = false
	_clear_hover_preview()
	_update_slot_colors()


func _create_hover_preview(item: LootItem) -> void:
	_clear_hover_preview()
	var item_w = 1
	var item_h = 1
	if item.item_data:
		item_w = item.item_data.grid_width
		item_h = item.item_data.grid_height
	
	for dy in range(item_h):
		for dx in range(item_w):
			var rect = ColorRect.new()
			rect.size = Vector2(slot_size, slot_size)
			rect.position = Vector2(dx * (slot_size + slot_gap), dy * (slot_size + slot_gap))
			rect.color = hover_valid_color
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hover_preview.add_child(rect)


func _clear_hover_preview() -> void:
	for child in hover_preview.get_children():
		child.queue_free()


func _update_hover_state() -> void:
	if not dragging_item:
		hover_preview.visible = false
		return
	
	var local_pos = get_local_mouse_position()
	var slot = _get_slot_at_pixel(local_pos)
	
	if slot < 0:
		hover_slot = -1
		hover_valid = false
		hover_preview.visible = false
		dragging_item.should_snap = false
		return
	
	hover_slot = slot
	hover_valid = can_place_item_at(dragging_item, slot)
	
	hover_preview.position = _get_slot_pixel_pos(slot)
	hover_preview.visible = true
	
	var color = hover_valid_color if hover_valid else hover_invalid_color
	for child in hover_preview.get_children():
		if child is ColorRect:
			child.color = color
	
	var snap_pos = global_position + hover_preview.position
	dragging_item.snap_position = snap_pos
	dragging_item.snap_scale = Vector2.ONE
	dragging_item.should_snap = true


func is_cursor_over_inventory() -> bool:
	var local_pos = get_local_mouse_position()
	var total_w = columns * (slot_size + slot_gap) - slot_gap
	var total_h = rows * (slot_size + slot_gap) - slot_gap
	return local_pos.x >= 0 and local_pos.y >= 0 and \
		   local_pos.x < total_w and local_pos.y < total_h


# ==============================================================================
# PLACEMENT LOGIC
# ==============================================================================

func can_place_item_at(item: LootItem, top_left_slot: int) -> bool:
	if top_left_slot < 0 or not item or not item.item_data:
		return false
	
	var item_w = item.item_data.grid_width
	var item_h = item.item_data.grid_height
	var start_col = _slot_to_col(top_left_slot)
	var start_row = _slot_to_row(top_left_slot)
	
	if start_col + item_w > columns or start_row + item_h > rows:
		print("[INV] Cannot place %s: out of bounds" % item.item_data.name)
		return false
	
	for dy in range(item_h):
		for dx in range(item_w):
			var check_slot = _col_row_to_slot(start_col + dx, start_row + dy)
			if check_slot < 0:
				return false
			var occupant = slot_grid[check_slot]
			if occupant != null and occupant != item:
				print("[INV] Cannot place %s: slot %d occupied" % [item.item_data.name, check_slot])
				return false
	
	var item_weight = item.item_data.weight
	var future_weight = current_weight + item_weight
	if item in placed_items:
		future_weight -= item_weight
	
	if future_weight > max_capacity:
		print("[INV] Cannot place %s: weight %.1f + %.1f > %.1f capacity" % [
			item.item_data.name, current_weight, item_weight, max_capacity])
		return false
	
	return true


func place_item(item: LootItem, top_left_slot: int) -> bool:
	if not can_place_item_at(item, top_left_slot):
		return false
	
	if item in placed_items:
		_clear_item_slots(item)
		placed_items.erase(item)
	
	var item_w = item.item_data.grid_width
	var item_h = item.item_data.grid_height
	var start_col = _slot_to_col(top_left_slot)
	var start_row = _slot_to_row(top_left_slot)
	
	for dy in range(item_h):
		for dx in range(item_w):
			var slot_idx = _col_row_to_slot(start_col + dx, start_row + dy)
			slot_grid[slot_idx] = item
	
	placed_items.append(item)
	
	item.is_dragging = false
	item.z_index = 0
	item.scale = Vector2.ONE
	item.should_snap = false
	
	if item.get_parent() != items_container:
		item.reparent(items_container)
	
	var slot_pos = _get_slot_pixel_pos(top_left_slot)
	item.position = slot_pos
	
	item.original_position = slot_pos
	item.original_parent = items_container
	
	_connect_item_signals(item)
	item.set_in_inventory()
	_recalculate_stats()
	_update_slot_colors()
	
	# Log inventory change
	if DebugLogger and item.item_data:
		DebugLogger.log_inventory_change("ADDED", item.item_data.name, {
			"slot": top_left_slot,
			"value": item.item_data.value,
			"rarity": item.item_data.rarity
		})
	
	# Persist to GameManager
	_save_to_game_manager()
	
	emit_signal("item_placed", item, top_left_slot)
	return true


func _clear_item_slots(item: LootItem) -> void:
	for i in range(total_slots):
		if slot_grid[i] == item:
			slot_grid[i] = null


func _find_item_top_left_slot(item: LootItem) -> int:
	for i in range(total_slots):
		if slot_grid[i] == item:
			return i
	return -1


func try_place_at_cursor(item: LootItem) -> bool:
	if hover_valid and hover_slot >= 0:
		return place_item(item, hover_slot)
	return false


## Find next available slot for an item of given dimensions, starting from a given slot
func _find_next_available_slot(start_slot: int, item_w: int, item_h: int) -> int:
	var start_row = _slot_to_row(maxi(0, start_slot))
	var start_col = _slot_to_col(maxi(0, start_slot))
	
	for row in range(start_row, rows - item_h + 1):
		var col_start = start_col if row == start_row else 0
		for col in range(col_start, columns - item_w + 1):
			var slot = _col_row_to_slot(col, row)
			if _is_slot_range_empty(slot, item_w, item_h):
				return slot
	
	# Also check from the beginning if we started mid-grid
	if start_slot > 0:
		for row in range(0, start_row + 1):
			var col_end = start_col if row == start_row else columns - item_w + 1
			for col in range(0, col_end):
				var slot = _col_row_to_slot(col, row)
				if _is_slot_range_empty(slot, item_w, item_h):
					return slot
	
	return -1


## Check if a range of slots is empty for a given item size
func _is_slot_range_empty(top_left_slot: int, item_w: int, item_h: int) -> bool:
	var start_col = _slot_to_col(top_left_slot)
	var start_row = _slot_to_row(top_left_slot)
	
	# Check bounds
	if start_col + item_w > columns or start_row + item_h > rows:
		return false
	
	# Check all slots
	for dy in range(item_h):
		for dx in range(item_w):
			var slot_idx = _col_row_to_slot(start_col + dx, start_row + dy)
			if slot_idx < 0 or slot_idx >= total_slots or slot_grid[slot_idx] != null:
				return false
	
	return true


## Check if a slot can fit an item of given dimensions (used during load)
func _can_place_at_slot(slot: int, item_w: int, item_h: int) -> bool:
	if slot < 0 or slot >= total_slots:
		return false
	return _is_slot_range_empty(slot, item_w, item_h)


func auto_place(item: LootItem) -> bool:
	if not item or not item.item_data:
		return false
	
	# Check if this is a keycard - auto-place in keycard slot
	if _is_keycard_item(item):
		return place_keycard(item)
	
	var item_w = item.item_data.grid_width
	var item_h = item.item_data.grid_height
	
	for row in range(rows - item_h + 1):
		for col in range(columns - item_w + 1):
			var slot = _col_row_to_slot(col, row)
			if can_place_item_at(item, slot):
				return place_item(item, slot)
	
	emit_signal("inventory_full")
	return false


# ==============================================================================
# KEYCARD SLOT MANAGEMENT
# ==============================================================================

## Check if an item is a keycard
func _is_keycard_item(item: LootItem) -> bool:
	if not item or not item.item_data:
		return false
	# Check tags for keycard
	if item.item_data.tags.has("keycard"):
		return true
	# Also check ID prefix
	if item.item_data.id.begins_with("keycard"):
		return true
	return false


## Place a keycard in the dedicated keycard slot
func place_keycard(item: LootItem) -> bool:
	if not item or not item.item_data:
		return false
	
	# If slot is already occupied, swap or reject
	if keycard_item != null:
		print("[SlotInventory] Keycard slot already occupied")
		return false
	
	# Remove from regular inventory if present
	if item in placed_items:
		_clear_item_slots(item)
		placed_items.erase(item)
	
	keycard_item = item
	
	item.is_dragging = false
	item.z_index = 0
	item.scale = Vector2.ONE
	item.should_snap = false
	
	# Reparent to keycard container
	if keycard_container:
		if item.get_parent() != keycard_container:
			item.reparent(keycard_container)
		item.position = Vector2(10, 28)  # Position within keycard slot
	
	item.original_position = item.position
	item.original_parent = keycard_container
	
	_connect_item_signals(item)
	item.set_in_inventory()
	
	# Update keycard slot visual
	if keycard_slot_visual:
		keycard_slot_visual.color = Color(0.25, 0.4, 0.5, 0.9)  # Highlight when occupied
	
	# Log keycard pickup
	if DebugLogger and item.item_data:
		DebugLogger.log_inventory_change("KEYCARD_ADDED", item.item_data.name, {
			"tier": item.item_data.id
		})
	
	# Include in value but NOT weight
	total_value += item.item_data.value
	_update_displays()
	_save_to_game_manager()
	
	emit_signal("item_placed", item, -1)  # -1 indicates keycard slot
	return true


## Remove keycard from the dedicated slot
func remove_keycard() -> LootItem:
	if keycard_item == null:
		return null
	
	var item = keycard_item
	keycard_item = null
	
	# Update visual
	if keycard_slot_visual:
		keycard_slot_visual.color = Color(0.18, 0.25, 0.35, 0.9)  # Empty color
	
	# Update value
	if item.item_data:
		total_value -= item.item_data.value
	_update_displays()
	_save_to_game_manager()
	
	emit_signal("item_removed", item)
	return item


## Check if player has a keycard of a specific tier
func has_keycard_tier(tier: int) -> bool:
	if keycard_item == null or keycard_item.item_data == null:
		return false
	# Check if keycard matches or exceeds required tier
	var keycard_id = keycard_item.item_data.id
	if keycard_id == "keycard_tier%d" % tier:
		return true
	# Higher tier keycards work for lower tier locks
	for t in range(tier, 4):  # Up to tier 3
		if keycard_id == "keycard_tier%d" % t:
			return true
	return false


## Get the current keycard item (or null)
func get_keycard() -> LootItem:
	return keycard_item


func remove_item(item: LootItem) -> bool:
	if item not in placed_items:
		return false
	
	# Log before removing
	if DebugLogger and item.item_data:
		DebugLogger.log_inventory_change("REMOVED", item.item_data.name, {
			"value": item.item_data.value
		})
	
	_clear_item_slots(item)
	placed_items.erase(item)
	_recalculate_stats()
	_update_slot_colors()
	
	# Persist to GameManager
	_save_to_game_manager()
	
	emit_signal("item_removed", item)
	return true


func destroy_item(item: LootItem) -> void:
	# Log destruction
	if DebugLogger and item.item_data:
		DebugLogger.log_inventory_change("DESTROYED", item.item_data.name, {
			"value": item.item_data.value
		})
	
	remove_item(item)  # This calls _save_to_game_manager()
	emit_signal("item_destroyed", item)
	item.queue_free()


func _connect_item_signals(item: LootItem) -> void:
	if not item.drag_started.is_connected(_on_item_drag_started):
		item.drag_started.connect(_on_item_drag_started)
	if not item.drag_ended.is_connected(_on_item_drag_ended):
		item.drag_ended.connect(_on_item_drag_ended)
	if not item.destroy_requested.is_connected(_on_item_destroy_requested):
		item.destroy_requested.connect(_on_item_destroy_requested)
	if not item.rotate_requested.is_connected(_on_item_rotate_requested):
		item.rotate_requested.connect(_on_item_rotate_requested)
	if not item.examine_requested.is_connected(_on_item_examine_requested):
		item.examine_requested.connect(_on_item_examine_requested)


# ==============================================================================
# DRAG FROM INVENTORY
# ==============================================================================

func start_drag_from_inventory(item: LootItem) -> void:
	var slot = _find_item_top_left_slot(item)
	if slot < 0:
		return
	
	drag_original_slot = slot
	dragging_item = item
	
	_clear_item_slots(item)
	_update_slot_colors()
	
	start_hover(item)
	emit_signal("item_drag_started", item)


func end_drag_from_inventory(drop_in_inventory: bool) -> bool:
	if not dragging_item:
		return false
	
	var item = dragging_item
	var placed = false
	
	if drop_in_inventory and hover_valid and hover_slot >= 0:
		placed = place_item(item, hover_slot)
	
	if not placed and drag_original_slot >= 0:
		placed = place_item(item, drag_original_slot)
	
	stop_hover()
	emit_signal("item_drag_ended", item)
	drag_original_slot = -1
	return placed


# ==============================================================================
# ITEM SIGNAL HANDLERS
# ==============================================================================

func _on_item_drag_started(item: LootItem) -> void:
	start_drag_from_inventory(item)


func _on_item_drag_ended(item: LootItem, _drop_pos: Vector2) -> void:
	if dragging_item != item:
		return
	var over_inventory = is_cursor_over_inventory()
	end_drag_from_inventory(over_inventory)


func _on_item_destroy_requested(item: LootItem) -> void:
	if dragging_item == item:
		return
	destroy_item(item)


func _on_item_rotate_requested(item: LootItem) -> void:
	if dragging_item == item:
		return
	rotate_item(item)


func _on_item_examine_requested(item: LootItem) -> void:
	# Show tooltip for the item
	var tooltip := ItemTooltip.get_instance()
	if tooltip and item.item_data:
		var item_rect = item.get_global_rect()
		tooltip.show_tooltip(item.item_data, item_rect.position + item_rect.size / 2)


## Rotate an item being dragged (R key while holding)
func _rotate_dragging_item() -> void:
	if not dragging_item or not dragging_item.item_data:
		return
	
	var item = dragging_item
	
	# Store old dimensions
	var old_width = item.item_data.grid_width
	var old_height = item.item_data.grid_height
	
	# Swap width and height in item_data
	item.item_data.grid_width = old_height
	item.item_data.grid_height = old_width
	
	# Update visual size (container size = new dimensions)
	var new_w = item.item_data.grid_width * slot_size
	var new_h = item.item_data.grid_height * slot_size
	item.custom_minimum_size = Vector2(new_w, new_h)
	item.size = Vector2(new_w, new_h)
	
	# Rotate the visual content and adjust position to compensate
	if item.visual_container:
		# Add 90 degrees to rotation
		item.visual_container.rotation_degrees += 90
		
		# The visual_container was created for old dimensions (old_w x old_h)
		var old_visual_w = old_width * slot_size
		var old_visual_h = old_height * slot_size
		
		# Set pivot at center of the OLD visual size
		item.visual_container.pivot_offset = Vector2(old_visual_w, old_visual_h) / 2
		
		# After rotation, we need to reposition so the rotated content fits in new bounds
		# When rotating 90 CW: old (w,h) becomes visual of (h,w)
		# The pivot is at center, so we need to translate so rotated content is centered in new container
		var center_new = Vector2(new_w, new_h) / 2
		var center_old = Vector2(old_visual_w, old_visual_h) / 2
		
		# Position adjustment: move pivot to be at center of new container
		item.visual_container.position = center_new - center_old
	
	# Recreate hover preview for new dimensions
	_create_hover_preview(item)
	_update_hover_state()
	
	# Play rotation sound
	AudioManager.play_sfx("ui_click", -5.0)


## Update hover preview size after rotation (recreates preview cells)
func _update_hover_preview_size() -> void:
	if not hover_preview or not dragging_item:
		return
	
	# Recreate the preview to match new item dimensions
	_create_hover_preview(dragging_item)


## Rotate an item 90 degrees and try to refit in inventory
func rotate_item(item: LootItem) -> void:
	if not item or not item.item_data:
		return
	
	# Find current slot
	var current_slot = _find_item_top_left_slot(item)
	if current_slot < 0:
		return
	
	# Remove item from current position
	_clear_item_slots(item)
	
	# Store old dimensions
	var old_width = item.item_data.grid_width
	var old_height = item.item_data.grid_height
	
	# Swap width and height in item_data
	item.item_data.grid_width = old_height
	item.item_data.grid_height = old_width
	
	# Update visual size
	var new_w = item.item_data.grid_width * slot_size
	var new_h = item.item_data.grid_height * slot_size
	item.custom_minimum_size = Vector2(new_w, new_h)
	item.size = Vector2(new_w, new_h)
	
	# Rotate the visual content and adjust position
	if item.visual_container:
		# Add 90 degrees to rotation
		item.visual_container.rotation_degrees += 90
		
		# The visual_container was created for old dimensions
		var old_visual_w = old_width * slot_size
		var old_visual_h = old_height * slot_size
		
		# Set pivot at center of the OLD visual size
		item.visual_container.pivot_offset = Vector2(old_visual_w, old_visual_h) / 2
		
		# Reposition so rotated content is centered in new container
		var center_new = Vector2(new_w, new_h) / 2
		var center_old = Vector2(old_visual_w, old_visual_h) / 2
		item.visual_container.position = center_new - center_old
	
	# Try to place at same position
	if can_place_item_at(item, current_slot):
		place_item(item, current_slot)
	else:
		# Try to find any valid position using auto_place logic
		var placed := false
		for row in range(rows - item.item_data.grid_height + 1):
			for col in range(columns - item.item_data.grid_width + 1):
				var slot = _col_row_to_slot(col, row)
				if can_place_item_at(item, slot):
					place_item(item, slot)
					placed = true
					break
			if placed:
				break
		
		if not placed:
			# Revert rotation if can't fit
			item.item_data.grid_width = old_width
			item.item_data.grid_height = old_height
			var w = old_width * slot_size
			var h = old_height * slot_size
			item.custom_minimum_size = Vector2(w, h)
			item.size = Vector2(w, h)
			if item.visual_container:
				item.visual_container.rotation_degrees -= 90
			place_item(item, current_slot)
	
	_update_slot_colors()


# ==============================================================================
# STATS & DISPLAY
# ==============================================================================

func _recalculate_stats() -> void:
	total_value = 0
	current_weight = 0.0
	
	# Clean up any invalid items first
	var valid_items: Array[LootItem] = []
	for item in placed_items:
		var valid = is_instance_valid(item)
		var has_data = item.item_data if valid else null
		if valid and has_data:
			total_value += item.item_data.value
			current_weight += item.item_data.weight
			valid_items.append(item)
			_ensure_item_visible(item)
	placed_items = valid_items
	
	_update_displays()


func _ensure_item_visible(item: LootItem) -> void:
	## Ensure an item is properly displayed in the inventory.
	if not is_instance_valid(item):
		return
	
	# Ensure items_container exists
	if items_container == null:
		_create_ui()
	
	# Reparent if needed
	if item.get_parent() != items_container:
		if item.get_parent():
			item.get_parent().remove_child(item)
		items_container.add_child(item)
	
	# Ensure visible
	item.visible = true
	item.modulate.a = 1.0
	item.scale = Vector2.ONE
	
	# Find and restore position based on slot_grid
	var found_slot = -1
	for i in range(total_slots):
		if slot_grid[i] == item:
			found_slot = i
			break
	
	if found_slot >= 0:
		item.position = _get_slot_pixel_pos(found_slot)


func _update_displays() -> void:
	# Labels are children of this node, not siblings
	var value_label = get_node_or_null("TotalValueLabel")
	if value_label:
		value_label.text = "Total: $%d" % total_value
	
	var weight_label = get_node_or_null("WeightLabel")
	if weight_label:
		weight_label.text = "Weight: %.1f / %.1f kg" % [current_weight, max_capacity]


func _update_slot_colors() -> void:
	for i in range(total_slots):
		if i >= slot_visuals.size():
			break
		var slot_rect = slot_visuals[i]
		if slot_grid[i] != null:
			slot_rect.color = occupied_slot_color
		else:
			slot_rect.color = empty_slot_color


# ==============================================================================
# PUBLIC GETTERS
# ==============================================================================

func get_total_value() -> int:
	return total_value


func get_current_weight() -> float:
	return current_weight


func get_item_count() -> int:
	return placed_items.size()


func get_all_items() -> Array[LootItem]:
	return placed_items.duplicate()


## Clear all items from the inventory without destroying them
func clear_all() -> void:
	# Clear slot tracking
	for i in range(total_slots):
		slot_grid[i] = null
	
	# Remove items from container (but don't destroy them)
	for item in placed_items:
		if is_instance_valid(item) and item.get_parent() == items_container:
			items_container.remove_child(item)
	
	placed_items.clear()
	_recalculate_stats()
	_update_slot_colors()


func is_empty() -> bool:
	return placed_items.is_empty()


func is_full() -> bool:
	for i in range(total_slots):
		if slot_grid[i] == null:
			return false
	return true


# ==============================================================================
# PERSISTENCE - Save/Load from GameManager
# ==============================================================================

## Request a save to GameManager (deferred to batch multiple changes)
func _save_to_game_manager() -> void:
	_save_pending = true
	_save_timer = SAVE_DELAY


## Force immediate save (use when leaving inventory screen)
func save_immediate() -> void:
	if _save_pending:
		_save_pending = false
		_do_save_to_game_manager()


## Actually perform the save
func _do_save_to_game_manager() -> void:
	if not GameManager:
		print("[SlotInventory] ERROR: No GameManager!")
		return
	
	var save_data: Array = []
	var total_val = 0
	for item in placed_items:
		if is_instance_valid(item) and item.item_data:
			# Find the top-left slot for this item
			var item_slot = _find_item_top_left_slot(item)
			save_data.append({
				"item_data": item.item_data,
				"slot": item_slot
			})
			total_val += item.item_data.value
	
	# Save keycard separately
	var keycard_data: Dictionary = {}
	if keycard_item and is_instance_valid(keycard_item) and keycard_item.item_data:
		keycard_data = {
			"item_data": keycard_item.item_data
		}
		total_val += keycard_item.item_data.value
	
	var msg = "[SlotInventory] Saved %d items + keycard ($%d)"
	print(msg % [save_data.size(), total_val])
	GameManager.set_ship_inventory(save_data)
	GameManager.set_keycard_data(keycard_data)


## Load inventory state from GameManager
## Items are placed at their saved slot positions
func _load_from_game_manager() -> void:
	if not GameManager:
		return
	
	var saved_items = GameManager.get_ship_inventory()
	var loot_item_scene = preload("res://scenes/loot/loot_item.tscn")
	
	# Load keycard first
	var keycard_data = GameManager.get_keycard_data()
	if keycard_data and keycard_data.has("item_data"):
		var item_data = keycard_data.item_data
		if item_data is ItemData:
			var keycard = loot_item_scene.instantiate() as LootItem
			keycard.initialize(item_data)
			place_keycard(keycard)
			print("[SlotInventory] Loaded keycard: %s" % item_data.name)
	
	if saved_items.is_empty():
		return
	
	print("[SlotInventory] Loading %d items from GameManager" % saved_items.size())
	
	for entry in saved_items:
		# Handle both old format (just ItemData) and new format ({item_data, slot})
		var item_data: ItemData
		var target_slot: int = -1
		
		if entry is ItemData:
			# Old format - just ItemData
			item_data = entry
		elif entry is Dictionary and entry.has("item_data"):
			# New format with slot position
			item_data = entry.item_data
			target_slot = entry.get("slot", -1)
		else:
			continue
		
		if not item_data is ItemData:
			continue
		
		var loot_item = loot_item_scene.instantiate() as LootItem
		loot_item.initialize(item_data)
		
		# Try to place at saved slot, or find first available
		var slot = target_slot
		if slot < 0 or not _can_place_at_slot(slot, item_data.grid_width, item_data.grid_height):
			slot = _find_next_available_slot(0, item_data.grid_width, item_data.grid_height)
		
		if slot >= 0:
			_place_item_internal(loot_item, slot)
		else:
			loot_item.queue_free()
			print("[SlotInventory] WARN: Could not place %s - no space" % item_data.name)
	
	_recalculate_stats()
	_update_slot_colors()
	print("[SlotInventory] Loaded %d items from GameManager" % placed_items.size())


## Internal placement that doesn't trigger a save (used during load)
func _place_item_internal(item: LootItem, top_left_slot: int) -> bool:
	if top_left_slot < 0 or not item or not item.item_data:
		return false
	
	var item_w = item.item_data.grid_width
	var item_h = item.item_data.grid_height
	var start_col = _slot_to_col(top_left_slot)
	var start_row = _slot_to_row(top_left_slot)
	
	# Check bounds
	if start_col + item_w > columns or start_row + item_h > rows:
		return false
	
	# Mark slots as occupied
	for dy in range(item_h):
		for dx in range(item_w):
			var slot_idx = _col_row_to_slot(start_col + dx, start_row + dy)
			if slot_idx >= 0:
				slot_grid[slot_idx] = item
	
	placed_items.append(item)
	
	item.is_dragging = false
	item.z_index = 0
	item.scale = Vector2.ONE
	item.should_snap = false
	
	# Ensure items_container exists
	if items_container == null:
		_create_ui()
	
	if item.get_parent() != items_container:
		if item.get_parent():
			item.get_parent().remove_child(item)
		items_container.add_child(item)
	
	var slot_pos = _get_slot_pixel_pos(top_left_slot)
	item.position = slot_pos
	
	item.original_position = slot_pos
	item.original_parent = items_container
	
	_connect_item_signals(item)
	item.set_in_inventory()
	
	return true
