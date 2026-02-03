# ==============================================================================
# STASH UI - PERSISTENT STORAGE MANAGEMENT
# ==============================================================================
#
# FILE: scripts/ui/stash_ui.gd
# PURPOSE: Interface for managing persistent item storage
#
# FEATURES:
# - Grid-based stash display
# - Drag and drop between ship and stash
# - Item sorting and filtering
# - Capacity display
#
# ==============================================================================

extends Control
class_name StashUI


# ==============================================================================
# SIGNALS
# ==============================================================================

signal item_transferred(item, from_stash: bool)
signal stash_closed


# ==============================================================================
# CONSTANTS
# ==============================================================================

const STASH_COLUMNS: int = 10
const STASH_ROWS: int = 10
const SLOT_SIZE: Vector2 = Vector2(48, 48)


# ==============================================================================
# STATE
# ==============================================================================

var selected_item = null
var selected_from_stash: bool = false
var dragging: bool = false


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

var stash_grid: GridContainer = null
var ship_grid: GridContainer = null
var capacity_label: Label = null
var transfer_button: Button = null
var sort_button: Button = null


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_build_ui()
	refresh_stash()


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.08, 0.98)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	
	# Main margin
	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(main_vbox)
	
	# Header
	_build_header(main_vbox)
	
	# Content area - two grids side by side
	var content = HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 30)
	main_vbox.add_child(content)
	
	# Ship inventory (left)
	_build_ship_section(content)
	
	# Transfer buttons (center)
	_build_transfer_section(content)
	
	# Stash inventory (right)
	_build_stash_section(content)


func _build_header(parent: Control) -> void:
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	parent.add_child(header)
	
	# Title
	var title = Label.new()
	title.text = "STASH"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	header.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	# Capacity display
	capacity_label = Label.new()
	capacity_label.text = "0 / 100"
	capacity_label.add_theme_font_size_override("font_size", 16)
	capacity_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	header.add_child(capacity_label)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)


func _build_ship_section(parent: Control) -> void:
	var section = VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 10)
	parent.add_child(section)
	
	# Title
	var title_row = HBoxContainer.new()
	section.add_child(title_row)
	
	var title = Label.new()
	title.text = "SHIP CARGO"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	title_row.add_child(title)
	
	# Grid panel
	var panel = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_grid_style(panel)
	section.add_child(panel)
	
	var scroll = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	panel.add_child(scroll)
	
	ship_grid = GridContainer.new()
	ship_grid.columns = 6
	ship_grid.add_theme_constant_override("h_separation", 4)
	ship_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(ship_grid)


func _build_transfer_section(parent: Control) -> void:
	var section = VBoxContainer.new()
	section.custom_minimum_size.x = 100
	section.alignment = BoxContainer.ALIGNMENT_CENTER
	section.add_theme_constant_override("separation", 15)
	parent.add_child(section)
	
	# Transfer to stash button
	var to_stash_btn = Button.new()
	to_stash_btn.text = "→ STASH"
	to_stash_btn.custom_minimum_size = Vector2(90, 40)
	to_stash_btn.pressed.connect(_on_transfer_to_stash)
	section.add_child(to_stash_btn)
	
	# Transfer to ship button
	var to_ship_btn = Button.new()
	to_ship_btn.text = "← SHIP"
	to_ship_btn.custom_minimum_size = Vector2(90, 40)
	to_ship_btn.pressed.connect(_on_transfer_to_ship)
	section.add_child(to_ship_btn)
	
	# Sort button
	sort_button = Button.new()
	sort_button.text = "SORT"
	sort_button.custom_minimum_size = Vector2(90, 35)
	sort_button.pressed.connect(_on_sort_pressed)
	section.add_child(sort_button)


func _build_stash_section(parent: Control) -> void:
	var section = VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 10)
	parent.add_child(section)
	
	# Title
	var title = Label.new()
	title.text = "STASH STORAGE"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	section.add_child(title)
	
	# Grid panel
	var panel = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_grid_style(panel)
	section.add_child(panel)
	
	var scroll = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	panel.add_child(scroll)
	
	stash_grid = GridContainer.new()
	stash_grid.columns = STASH_COLUMNS
	stash_grid.add_theme_constant_override("h_separation", 4)
	stash_grid.add_theme_constant_override("v_separation", 4)
	scroll.add_child(stash_grid)


func _apply_grid_style(panel: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.25, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)


# ==============================================================================
# DATA
# ==============================================================================

func refresh_stash() -> void:
	_populate_ship_grid()
	_populate_stash_grid()
	_update_capacity()


func _populate_ship_grid() -> void:
	# Clear existing
	for child in ship_grid.get_children():
		child.queue_free()
	
	# Get items from current run or player inventory
	# For now, show empty slots
	for i in range(36):  # 6x6 grid
		var slot = _create_slot(null, false, i)
		ship_grid.add_child(slot)


func _populate_stash_grid() -> void:
	# Clear existing
	for child in stash_grid.get_children():
		child.queue_free()
	
	var stash_items = []
	if has_node("/root/GameState"):
		stash_items = get_node("/root/GameState").get_stash_items()
	
	# Create slots for each stash position
	var total_slots = STASH_COLUMNS * STASH_ROWS
	for i in range(total_slots):
		var item = stash_items[i] if i < stash_items.size() else null
		var slot = _create_slot(item, true, i)
		stash_grid.add_child(slot)


func _create_slot(item, is_stash: bool, index: int) -> Control:
	var slot = Button.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.toggle_mode = true
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18) if item else Color(0.08, 0.1, 0.12)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.3, 0.35)
	slot.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.border_color = Color(0.4, 0.5, 0.6)
	slot.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = style.duplicate()
	pressed_style.border_color = Color(0.9, 0.8, 0.3)
	pressed_style.border_width_left = 2
	pressed_style.border_width_right = 2
	pressed_style.border_width_top = 2
	pressed_style.border_width_bottom = 2
	slot.add_theme_stylebox_override("pressed", pressed_style)
	
	if item:
		# Item icon/label
		var label = Label.new()
		label.text = item.name[0] if "name" in item and item.name else "?"
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", _get_rarity_color(item))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchor_right = 1.0
		label.anchor_bottom = 1.0
		slot.add_child(label)
	
	slot.set_meta("item", item)
	slot.set_meta("is_stash", is_stash)
	slot.set_meta("index", index)
	slot.pressed.connect(_on_slot_pressed.bind(slot))
	
	return slot


func _get_rarity_color(item) -> Color:
	var rarity = item.rarity if "rarity" in item else 0
	match rarity:
		0: return Color(0.7, 0.72, 0.75)
		1: return Color(0.3, 0.8, 0.4)
		2: return Color(0.3, 0.6, 1.0)
		3: return Color(0.7, 0.3, 0.9)
		4: return Color(1.0, 0.8, 0.2)
	return Color.WHITE


func _update_capacity() -> void:
	var count = 0
	var max_count = 100
	
	if has_node("/root/GameState"):
		count = get_node("/root/GameState").get_stash_count()
	
	capacity_label.text = "%d / %d" % [count, max_count]
	
	if count >= max_count:
		capacity_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	elif count >= max_count * 0.8:
		capacity_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	else:
		capacity_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))


# ==============================================================================
# EVENT HANDLERS
# ==============================================================================

func _on_slot_pressed(slot: Control) -> void:
	var item = slot.get_meta("item")
	var is_stash = slot.get_meta("is_stash")
	
	# Deselect previous
	_deselect_all()
	
	if item:
		selected_item = item
		selected_from_stash = is_stash
		slot.button_pressed = true


func _deselect_all() -> void:
	for slot in ship_grid.get_children():
		slot.button_pressed = false
	for slot in stash_grid.get_children():
		slot.button_pressed = false
	selected_item = null


func _on_transfer_to_stash() -> void:
	if selected_item and not selected_from_stash:
		if has_node("/root/GameState"):
			var game_state = get_node("/root/GameState")
			if game_state.add_to_stash(selected_item):
				item_transferred.emit(selected_item, false)
				refresh_stash()


func _on_transfer_to_ship() -> void:
	if selected_item and selected_from_stash:
		if has_node("/root/GameState"):
			var game_state = get_node("/root/GameState")
			if game_state.remove_from_stash(selected_item):
				item_transferred.emit(selected_item, true)
				refresh_stash()


func _on_sort_pressed() -> void:
	# Sort stash items by rarity, then name
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		game_state.stash_items.sort_custom(_sort_by_rarity)
		refresh_stash()


func _sort_by_rarity(a, b) -> bool:
	var rarity_a = a.rarity if "rarity" in a else 0
	var rarity_b = b.rarity if "rarity" in b else 0
	if rarity_a != rarity_b:
		return rarity_a > rarity_b  # Higher rarity first
	var name_a = a.name if "name" in a else ""
	var name_b = b.name if "name" in b else ""
	return name_a < name_b


func _on_close_pressed() -> void:
	stash_closed.emit()
	hide()
