# ==============================================================================
# LOOT ITEM - DRAGGABLE INVENTORY ITEM WITH VISUAL FEEDBACK
# ==============================================================================
#
# FILE: scripts/loot/loot_item.gd
# PURPOSE: Represents a draggable loot item with procedural visuals
#
# ARCHITECTURE:
# -------------
# This item uses a signal-based architecture for drag operations:
# - drag_started: Emitted when user begins dragging
# - drag_ended: Emitted when user releases (with drop position)
# - destroy_requested: Emitted when user right-clicks to destroy
#
# The parent (LootMenu/Inventory) handles what happens when dropped.
# This separation keeps the item logic simple and reusable.
#
# VISUAL STATES:
# --------------
# HIDDEN      - Shows silhouette with "?" (not yet revealed)
# REVEALED    - Shows full item with glow and value
# IN_INVENTORY - Shows item without glow (already collected)
#
# DRAG SYSTEM:
# ------------
# 1. On mouse down, save position and start drag
# 2. During drag, follow mouse with offset
# 3. Reparent to top-level control to avoid clipping
# 4. On release, emit signal with drop position
# 5. Parent decides if placement is valid
# 6. If invalid, animate back to original position
#
# ==============================================================================

extends Control
class_name LootItem


# ==============================================================================
# PRELOADS
# ==============================================================================

const ItemVisualsClass = preload("res://scripts/loot/item_visuals.gd")


# ==============================================================================
# ENUMS
# ==============================================================================

## Visual/interaction state
enum ItemState {
	HIDDEN,       ## Silhouette only
	REVEALED,     ## Full visual with glow
	IN_INVENTORY  ## In inventory (no glow)
}


# ==============================================================================
# SIGNALS
# ==============================================================================

## Emitted when drag begins
signal drag_started(item: LootItem)

## Emitted when drag ends (with drop position for placement check)
signal drag_ended(item: LootItem, drop_position: Vector2)

## Emitted when user requests item destruction (via context menu)
signal destroy_requested(item: LootItem)

## Emitted when user requests item rotation (via context menu)
signal rotate_requested(item: LootItem)

## Emitted when user requests to examine item (via context menu)
signal examine_requested(item: LootItem)

## Emitted when item search is completed (for containers)
signal search_completed(item: LootItem)

## Emitted when item search is started (for containers)
signal search_started(item: LootItem)


# ==============================================================================
# EXPORTS
# ==============================================================================

## The data this item represents
@export var item_data: ItemData

## Size of each grid cell in pixels
@export var cell_size: int = 64


# ==============================================================================
# VISUAL SETTINGS
# ==============================================================================

## Color for the silhouette background
const SILHOUETTE_COLOR := Color(0.08, 0.08, 0.12, 0.95)

## Color for the question mark on silhouette
const QUESTION_MARK_COLOR := Color(0.3, 0.3, 0.4)

## Alpha for rarity glow when revealed
const GLOW_ALPHA := 0.3

## Z-index when dragging (ensures on top)
const DRAG_Z_INDEX := 100


# ==============================================================================
# DRAG SETTINGS
# ==============================================================================

## Duration of return animation when drop fails (seconds)
const RETURN_DURATION := 0.2

## Scale while dragging (slight enlarge for feedback)
const DRAG_SCALE := 1.05


# ==============================================================================
# STATE
# ==============================================================================

## Current visual state
var current_state: ItemState = ItemState.REVEALED

## Is the item being dragged?
var is_dragging: bool = false

## Offset from mouse to item origin (for smooth drag)
var drag_offset: Vector2 = Vector2.ZERO

## Position before drag started (for return animation)
var original_position: Vector2 = Vector2.ZERO

## Parent before drag started (for reparenting)
var original_parent: Node = null

## Original scale (before drag scaling)
var original_scale: Vector2 = Vector2.ONE

## Search state
var search_time: float = 0.0
var search_duration: float = 1.5  # Default search time
var is_being_searched: bool = false
var pulse_time: float = 0.0

## Grid snap state (set by inventory when dragging over it)
var should_snap: bool = false
var snap_position: Vector2 = Vector2.ZERO
var snap_scale: Vector2 = Vector2.ONE


# ==============================================================================
# NODE REFERENCES (created dynamically)
# ==============================================================================

var visual_container: Control = null
var silhouette: ColorRect = null
var rarity_glow: ColorRect = null
var value_label: Label = null
var question_mark: Label = null
var search_progress_overlay: ColorRect = null
var context_menu: PopupMenu = null


# ==============================================================================
# CONTEXT MENU IDS
# ==============================================================================

enum ContextMenuAction {
	ROTATE = 0,
	DESTROY = 1,
	EXAMINE = 2
}


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Capture mouse events
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Initialize visuals if data exists
	if item_data:
		_create_visuals()
		_setup_tooltip()
	
	# Only default to hidden state if not already set to IN_INVENTORY (loaded items)
	if current_state != ItemState.IN_INVENTORY:
		set_state(ItemState.HIDDEN)


func _process(delta: float) -> void:
	# Follow mouse while dragging (with optional grid snap)
	if is_dragging:
		if should_snap:
			# When snapping to grid, use exact position and scale to fit slot
			global_position = snap_position
			scale = snap_scale
		else:
			global_position = get_global_mouse_position() + drag_offset
			scale = Vector2.ONE * DRAG_SCALE
	
	# Update search progress
	if is_being_searched and current_state == ItemState.HIDDEN:
		search_time += delta
		pulse_time += delta
		_update_search_progress_visual()
		if search_time >= search_duration:
			_complete_search()
	else:
		pulse_time = 0.0


func _gui_input(event: InputEvent) -> void:
	# Only handle mouse button events
	if not event is InputEventMouseButton:
		return
	
	var mouse_event := event as InputEventMouseButton
	
	# Left click - drag handling for revealed items, search for hidden items
	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		if current_state == ItemState.HIDDEN:
			_handle_search_click(mouse_event)
		else:
			_handle_left_click(mouse_event)
	
	# Right click - destroy request (only in inventory)
	elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		_handle_right_click(mouse_event)


# ==============================================================================
# INITIALIZATION
# ==============================================================================

## Initialize with item data (call before adding to scene or after)
func initialize(data: ItemData) -> void:
	item_data = data
	
	if is_node_ready():
		_create_visuals()
		_setup_tooltip()


## Call this after adding to tree to show as revealed
func setup_revealed() -> void:
	if not is_node_ready():
		await ready
	
	_create_visuals()
	_setup_tooltip()
	set_state(ItemState.REVEALED)


## Setup hover detection for custom tooltip
func _setup_tooltip() -> void:
	# Connect mouse signals for custom tooltip
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)


# ==============================================================================
# VISUAL CREATION
# ==============================================================================

## Create all visual components
func _create_visuals() -> void:
	if not item_data:
		return
	
	# Calculate size from grid dimensions
	var w := item_data.grid_width * cell_size
	var h := item_data.grid_height * cell_size
	
	# Set control size
	custom_minimum_size = Vector2(w, h)
	size = Vector2(w, h)
	
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Create silhouette (shown when HIDDEN)
	_create_silhouette(w, h)
	
	# Create item visual (shown when REVEALED or IN_INVENTORY)
	_create_item_visual()
	
	# Create rarity glow (shown when REVEALED)
	_create_rarity_glow(w, h)
	
	# Create value label (shown when REVEALED)
	_create_value_label(w, h)


## Create the silhouette (hidden state visual)
func _create_silhouette(w: float, h: float) -> void:
	silhouette = ColorRect.new()
	silhouette.size = Vector2(w, h)
	silhouette.color = SILHOUETTE_COLOR
	silhouette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(silhouette)
	
	# Question mark
	question_mark = Label.new()
	question_mark.text = "?"
	question_mark.add_theme_font_size_override("font_size", 32)
	question_mark.add_theme_color_override("font_color", QUESTION_MARK_COLOR)
	question_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_mark.size = Vector2(w, h)
	question_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	silhouette.add_child(question_mark)
	
	# Create search progress overlay
	_create_search_progress_overlay(w, h)


## Create the item visual using ItemVisuals system
func _create_item_visual() -> void:
	visual_container = ItemVisualsClass.create_item_visual(item_data, cell_size)
	if visual_container:
		add_child(visual_container)
		visual_container.position = Vector2.ZERO
		visual_container.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Create the rarity glow overlay
func _create_rarity_glow(w: float, h: float) -> void:
	rarity_glow = ColorRect.new()
	rarity_glow.size = Vector2(w, h)
	rarity_glow.color = item_data.get_rarity_color()
	rarity_glow.color.a = 0.0
	rarity_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rarity_glow)


## Create the value label
func _create_value_label(_w: float, h: float) -> void:
	value_label = Label.new()
	value_label.text = "$%d" % item_data.value
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.add_theme_color_override("font_color", Color.WHITE)
	value_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	value_label.add_theme_constant_override("shadow_offset_x", 1)
	value_label.add_theme_constant_override("shadow_offset_y", 1)
	value_label.position = Vector2(4, h - 18)
	value_label.visible = false
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(value_label)


## Create the search progress overlay (simpler approach using ColorRect)
func _create_search_progress_overlay(_w: float, h: float) -> void:
	search_progress_overlay = ColorRect.new()
	search_progress_overlay.name = "SearchProgressOverlay"
	search_progress_overlay.position = Vector2(0, h - 4)
	search_progress_overlay.size = Vector2(0, 4)
	search_progress_overlay.color = Color(0.4, 0.8, 1.0, 0.9)
	search_progress_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	search_progress_overlay.visible = false
	silhouette.add_child(search_progress_overlay)


## Update search progress visual
func _update_search_progress_visual() -> void:
	if search_progress_overlay:
		search_progress_overlay.visible = is_being_searched
		if is_being_searched:
			var progress = get_search_progress()
			var max_width = silhouette.size.x if silhouette else size.x
			search_progress_overlay.size.x = progress * max_width
			
			# Add pulsing effect to the overlay
			var pulse = (sin(pulse_time * 5.0) + 1.0) / 2.0
			search_progress_overlay.color.a = 0.7 + pulse * 0.2


# ==============================================================================
# STATE MANAGEMENT
# ==============================================================================

## Change visual state
func set_state(new_state: ItemState) -> void:
	current_state = new_state
	_update_visuals_for_state()


## Mark as placed in inventory
func set_in_inventory() -> void:
	# Ensure visuals exist before setting state (needed when loading from GameManager)
	if is_node_ready() and not visual_container and item_data:
		_create_visuals()
		_setup_tooltip()
	set_state(ItemState.IN_INVENTORY)


## Update visual elements based on current state
func _update_visuals_for_state() -> void:
	var show_silhouette := current_state == ItemState.HIDDEN
	var show_visual := current_state in [ItemState.REVEALED, ItemState.IN_INVENTORY]
	var show_glow := current_state == ItemState.REVEALED
	var show_value := current_state == ItemState.REVEALED
	
	if silhouette:
		silhouette.visible = show_silhouette
	
	if visual_container:
		visual_container.visible = show_visual
	
	if rarity_glow:
		rarity_glow.color.a = GLOW_ALPHA if show_glow else 0.0
	
	if value_label:
		value_label.visible = show_value


# ==============================================================================
# MOUSE INPUT HANDLING
# ==============================================================================

## Handle left mouse button
func _handle_left_click(event: InputEventMouseButton) -> void:
	if event.pressed:
		# Only start drag if not already dragging
		if not is_dragging and current_state in [ItemState.REVEALED, ItemState.IN_INVENTORY]:
			_start_drag()
	else:
		# End drag on release
		if is_dragging:
			_end_drag()


## Handle search click (for hidden items)
func _handle_search_click(event: InputEventMouseButton) -> void:
	if event.pressed:
		# Start searching
		start_search()
	else:
		# Cancel search on release
		cancel_search()


## Handle right mouse button - show context menu
func _handle_right_click(event: InputEventMouseButton) -> void:
	if event.pressed and current_state == ItemState.IN_INVENTORY:
		_show_context_menu(event.global_position)


## Create context menu if needed
func _create_context_menu() -> void:
	if context_menu:
		return
	
	context_menu = PopupMenu.new()
	context_menu.add_item("Rotate", ContextMenuAction.ROTATE)
	context_menu.add_separator()
	context_menu.add_item("Destroy", ContextMenuAction.DESTROY)
	context_menu.add_separator()
	context_menu.add_item("Examine", ContextMenuAction.EXAMINE)
	
	# Note: Godot 4.x doesn't have direct item coloring for menu items
	
	context_menu.id_pressed.connect(_on_context_menu_selected)
	add_child(context_menu)


## Show context menu at position
func _show_context_menu(at_position: Vector2) -> void:
	_create_context_menu()
	context_menu.position = at_position
	context_menu.popup()


## Handle context menu selection
func _on_context_menu_selected(id: int) -> void:
	match id:
		ContextMenuAction.ROTATE:
			rotate_requested.emit(self)
		ContextMenuAction.DESTROY:
			destroy_requested.emit(self)
		ContextMenuAction.EXAMINE:
			examine_requested.emit(self)


# ==============================================================================
# SEARCH SYSTEM
# ==============================================================================

## Start searching this item (for hidden items)
func start_search() -> void:
	if current_state != ItemState.HIDDEN or is_being_searched:
		return
	
	is_being_searched = true
	search_time = 0.0
	search_started.emit(self)


## Cancel searching this item
func cancel_search() -> void:
	if not is_being_searched:
		return
	
	is_being_searched = false
	search_time = 0.0


## Complete the search and reveal the item
func _complete_search() -> void:
	is_being_searched = false
	set_state(ItemState.REVEALED)
	search_completed.emit(self)


## Check if item is currently being searched
func is_searching() -> bool:
	return is_being_searched


## Get search progress (0.0 to 1.0)
func get_search_progress() -> float:
	if search_duration <= 0:
		return 0.0
	return clampf(search_time / search_duration, 0.0, 1.0)


## Check if item is revealed
func is_revealed() -> bool:
	return current_state in [ItemState.REVEALED, ItemState.IN_INVENTORY]


# ==============================================================================
# DRAG SYSTEM
# ==============================================================================

## Begin dragging the item
func _start_drag() -> void:
	is_dragging = true
	
	# Hide tooltip when dragging starts
	var tooltip := ItemTooltip.get_instance()
	if tooltip:
		tooltip.hide_tooltip()
	
	# Store original state (use local position for return)
	original_position = position
	original_parent = get_parent()
	original_scale = scale
	
	# Center item on cursor for precise grid placement
	# Use the visual size of the item for proper centering
	if item_data:
		var item_visual_size = custom_minimum_size if custom_minimum_size != Vector2.ZERO else size
		drag_offset = -item_visual_size / 2.0
	else:
		drag_offset = -size / 2.0
	
	# Reparent to top-level for visibility during drag
	var top_parent := _find_top_level_control()
	if top_parent and top_parent != get_parent():
		var saved_pos := global_position
		reparent(top_parent)
		global_position = saved_pos
	
	# Visual feedback
	z_index = DRAG_Z_INDEX
	# Scale is now handled in _process based on snap state
	
	# Notify listeners
	drag_started.emit(self)


## End dragging the item
func _end_drag() -> void:
	is_dragging = false
	
	# Reset visual feedback
	z_index = 0
	scale = original_scale
	
	# Get drop position for parent to handle
	var drop_pos := get_global_mouse_position()
	
	# Notify listeners
	drag_ended.emit(self, drop_pos)


## Find the highest-level Control for reparenting
func _find_top_level_control() -> Control:
	var node := get_parent()
	var last_control: Control = null
	
	while node:
		if node is Control:
			last_control = node
		
		# Stop at CanvasLayer or scene root
		if node is CanvasLayer or node.get_parent() == null:
			break
		
		node = node.get_parent()
	
	return last_control


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Cancel drag and return to original position (no signal)
func cancel_drag() -> void:
	if not is_dragging:
		return
	
	is_dragging = false
	z_index = 0
	scale = original_scale
	
	# Reparent back
	if original_parent and get_parent() != original_parent:
		reparent(original_parent)
	
	position = original_position


## Animate return to original position
## Called by parent when drop is invalid
func return_to_original() -> void:
	# Reparent first
	if original_parent and get_parent() != original_parent:
		reparent(original_parent)
	
	# Animate back to original local position
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", original_position, RETURN_DURATION)


## Get the grid size of this item
func get_grid_size() -> Vector2i:
	if item_data:
		return Vector2i(item_data.grid_width, item_data.grid_height)
	return Vector2i(1, 1)


## Get the value of this item
func get_value() -> int:
	if item_data:
		return item_data.value
	return 0


## Check if item is currently being dragged
func is_being_dragged() -> bool:
	return is_dragging


# ==============================================================================
# TOOLTIP HANDLING
# ==============================================================================

## Show tooltip on mouse enter
func _on_mouse_entered() -> void:
	if is_dragging:
		return
	
	# Only show tooltip for revealed items
	if current_state == ItemState.HIDDEN:
		return
	
	var tooltip := ItemTooltip.get_instance()
	if tooltip and item_data:
		tooltip.show_for_item(item_data)


## Hide tooltip on mouse exit
func _on_mouse_exited() -> void:
	var tooltip := ItemTooltip.get_instance()
	if tooltip:
		tooltip.hide_tooltip()
