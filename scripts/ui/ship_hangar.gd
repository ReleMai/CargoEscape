# ==============================================================================
# SHIP HANGAR UI - MODULE INSTALLATION AND UPGRADES
# ==============================================================================
#
# FILE: scripts/ui/ship_hangar.gd
# PURPOSE: Interface for managing ship modules and upgrades
#
# FEATURES:
# - Visual ship display with module slots
# - Drag and drop module installation
# - Module stats comparison
# - Upgrade system
# - Ship tier display
#
# ==============================================================================

extends Control
class_name ShipHangarUI


# ==============================================================================
# SIGNALS
# ==============================================================================

signal module_equipped(module, slot: String)
signal module_unequipped(slot: String)
signal module_upgraded(module)
signal hangar_closed


# ==============================================================================
# STATE
# ==============================================================================

var selected_module = null
var selected_slot: String = ""
var ship_tier: int = 1


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

var ship_display: Control = null
var slot_buttons: Dictionary = {}  # slot_name -> Button
var module_list: VBoxContainer = null
var module_preview: Control = null
var equip_button: Button = null
var unequip_button: Button = null
var upgrade_button: Button = null
var stats_panel: Control = null


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_build_ui()
	refresh_hangar()


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Background
	var bg = ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.07, 0.98)
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
	
	# Content
	var content = HBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 25)
	main_vbox.add_child(content)
	
	# Ship display (left/center)
	_build_ship_display(content)
	
	# Module storage (right)
	_build_module_section(content)


func _build_header(parent: Control) -> void:
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	parent.add_child(header)
	
	# Title
	var title = Label.new()
	title.text = "SHIP HANGAR"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	header.add_child(title)
	
	# Ship tier display
	var tier_container = HBoxContainer.new()
	tier_container.add_theme_constant_override("separation", 8)
	header.add_child(tier_container)
	
	var tier_label = Label.new()
	tier_label.text = "Ship Tier:"
	tier_label.add_theme_font_size_override("font_size", 14)
	tier_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	tier_container.add_child(tier_label)
	
	var tier_value = Label.new()
	tier_value.name = "TierValue"
	tier_value.text = "1"
	tier_value.add_theme_font_size_override("font_size", 18)
	tier_value.add_theme_color_override("font_color", Color(0.3, 0.8, 0.5))
	tier_container.add_child(tier_value)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)


func _build_ship_display(parent: Control) -> void:
	var section = VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.size_flags_stretch_ratio = 1.5
	section.add_theme_constant_override("separation", 15)
	parent.add_child(section)
	
	# Ship visualization panel
	var ship_panel = PanelContainer.new()
	ship_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_panel_style(ship_panel, Color(0.06, 0.08, 0.1))
	section.add_child(ship_panel)
	
	ship_display = Control.new()
	ship_display.anchor_right = 1.0
	ship_display.anchor_bottom = 1.0
	ship_display.draw.connect(_on_ship_draw)
	ship_panel.add_child(ship_display)
	
	# Module slots overlay
	_create_slot_buttons()
	
	# Ship stats panel
	stats_panel = PanelContainer.new()
	stats_panel.custom_minimum_size.y = 120
	_apply_panel_style(stats_panel, Color(0.08, 0.1, 0.12))
	section.add_child(stats_panel)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 8)
	stats_panel.add_child(stats_vbox)
	
	var stats_title = Label.new()
	stats_title.text = "SHIP STATS"
	stats_title.add_theme_font_size_override("font_size", 14)
	stats_title.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	stats_vbox.add_child(stats_title)
	
	var stats_grid = GridContainer.new()
	stats_grid.name = "StatsGrid"
	stats_grid.columns = 4
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 5)
	stats_vbox.add_child(stats_grid)
	
	_add_stat_item(stats_grid, "Combat:", "0", "CombatValue")
	_add_stat_item(stats_grid, "Speed:", "0", "SpeedValue")
	_add_stat_item(stats_grid, "Shield:", "0", "ShieldValue")
	_add_stat_item(stats_grid, "Cargo:", "+0", "CargoValue")


func _create_slot_buttons() -> void:
	# Create clickable slot buttons positioned on the ship
	var slots = {
		"flight": Vector2(0.5, 0.7),   # Back of ship (engines)
		"combat": Vector2(0.3, 0.4),   # Front-left (weapons)
		"utility": Vector2(0.7, 0.4)   # Front-right (utility)
	}
	
	for slot_name in slots:
		var btn = Button.new()
		btn.name = slot_name.capitalize() + "Slot"
		btn.text = slot_name.substr(0, 1).to_upper()
		btn.custom_minimum_size = Vector2(50, 50)
		btn.toggle_mode = true
		
		# Position will be set in _on_ship_draw based on ship_display size
		btn.set_meta("slot_name", slot_name)
		btn.set_meta("relative_pos", slots[slot_name])
		btn.pressed.connect(_on_slot_clicked.bind(slot_name))
		
		slot_buttons[slot_name] = btn
		ship_display.add_child(btn)


func _build_module_section(parent: Control) -> void:
	var section = VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 15)
	parent.add_child(section)
	
	# Module preview
	_build_module_preview(section)
	
	# Action buttons
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	section.add_child(btn_row)
	
	equip_button = Button.new()
	equip_button.text = "EQUIP"
	equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equip_button.custom_minimum_size.y = 40
	equip_button.disabled = true
	equip_button.pressed.connect(_on_equip_pressed)
	btn_row.add_child(equip_button)
	
	unequip_button = Button.new()
	unequip_button.text = "UNEQUIP"
	unequip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unequip_button.custom_minimum_size.y = 40
	unequip_button.disabled = true
	unequip_button.pressed.connect(_on_unequip_pressed)
	btn_row.add_child(unequip_button)
	
	# Module storage title
	var storage_title = Label.new()
	storage_title.text = "STORED MODULES"
	storage_title.add_theme_font_size_override("font_size", 14)
	storage_title.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	section.add_child(storage_title)
	
	# Module list
	var list_panel = PanelContainer.new()
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_panel_style(list_panel, Color(0.08, 0.1, 0.12))
	section.add_child(list_panel)
	
	var scroll = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	list_panel.add_child(scroll)
	
	module_list = VBoxContainer.new()
	module_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	module_list.add_theme_constant_override("separation", 4)
	scroll.add_child(module_list)


func _build_module_preview(parent: Control) -> void:
	module_preview = PanelContainer.new()
	module_preview.custom_minimum_size.y = 180
	_apply_panel_style(module_preview, Color(0.1, 0.12, 0.15))
	parent.add_child(module_preview)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	module_preview.add_child(vbox)
	
	# Module name
	var name_label = Label.new()
	name_label.name = "ModuleName"
	name_label.text = "No Module Selected"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	vbox.add_child(name_label)
	
	# Module type
	var type_label = Label.new()
	type_label.name = "ModuleType"
	type_label.text = ""
	type_label.add_theme_font_size_override("font_size", 12)
	type_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	vbox.add_child(type_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.name = "ModuleDesc"
	desc_label.text = "Select a module or slot to view details."
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.6, 0.63, 0.67))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	
	# Stats
	var stats_label = Label.new()
	stats_label.name = "ModuleStats"
	stats_label.text = ""
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color(0.4, 0.7, 0.5))
	vbox.add_child(stats_label)


func _add_stat_item(grid: GridContainer, label_text: String, value_text: String, value_name: String) -> void:
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	grid.add_child(label)
	
	var value = Label.new()
	value.name = value_name
	value.text = value_text
	value.add_theme_font_size_override("font_size", 12)
	value.add_theme_color_override("font_color", Color(0.8, 0.83, 0.87))
	grid.add_child(value)


func _apply_panel_style(panel: PanelContainer, bg_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.25, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)


# ==============================================================================
# DRAWING
# ==============================================================================

func _on_ship_draw() -> void:
	var size = ship_display.size
	var center = size / 2.0
	
	# Draw ship outline (simplified top-down view)
	_draw_ship_body(center, size)
	
	# Update slot button positions
	_update_slot_positions(size)


func _draw_ship_body(center: Vector2, size: Vector2) -> void:
	var ship_length = minf(size.x, size.y) * 0.7
	var ship_width = ship_length * 0.4
	
	# Main body (elongated hexagon)
	var body_points = PackedVector2Array([
		center + Vector2(0, -ship_length * 0.45),           # Front tip
		center + Vector2(ship_width * 0.3, -ship_length * 0.3),
		center + Vector2(ship_width * 0.5, 0),              # Mid-side
		center + Vector2(ship_width * 0.4, ship_length * 0.35),
		center + Vector2(0, ship_length * 0.45),            # Back center
		center + Vector2(-ship_width * 0.4, ship_length * 0.35),
		center + Vector2(-ship_width * 0.5, 0),
		center + Vector2(-ship_width * 0.3, -ship_length * 0.3)
	])
	
	ship_display.draw_colored_polygon(body_points, Color(0.2, 0.25, 0.3))
	ship_display.draw_polyline(body_points, Color(0.4, 0.45, 0.5), 2.0, true)
	
	# Cockpit
	var cockpit_points = PackedVector2Array([
		center + Vector2(0, -ship_length * 0.35),
		center + Vector2(ship_width * 0.15, -ship_length * 0.2),
		center + Vector2(-ship_width * 0.15, -ship_length * 0.2)
	])
	ship_display.draw_colored_polygon(cockpit_points, Color(0.3, 0.5, 0.7, 0.8))
	
	# Engine glow
	var engine_pos = center + Vector2(0, ship_length * 0.4)
	ship_display.draw_circle(engine_pos, ship_width * 0.15, Color(0.3, 0.7, 1.0, 0.6))
	ship_display.draw_circle(engine_pos, ship_width * 0.1, Color(0.5, 0.8, 1.0, 0.8))


func _update_slot_positions(size: Vector2) -> void:
	for slot_name in slot_buttons:
		var btn = slot_buttons[slot_name]
		var rel_pos = btn.get_meta("relative_pos")
		btn.position = Vector2(
			size.x * rel_pos.x - btn.size.x / 2,
			size.y * rel_pos.y - btn.size.y / 2
		)


# ==============================================================================
# DATA
# ==============================================================================

func refresh_hangar() -> void:
	_load_ship_data()
	_populate_module_list()
	_update_ship_stats()
	_update_slot_displays()
	_clear_preview()


func _load_ship_data() -> void:
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		ship_tier = game_state.ship_tier


func _populate_module_list() -> void:
	# Clear existing
	for child in module_list.get_children():
		child.queue_free()
	
	var modules = []
	if has_node("/root/GameState"):
		modules = get_node("/root/GameState").get_owned_modules()
	
	if modules.is_empty():
		var empty_label = Label.new()
		empty_label.text = "No modules in storage"
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.45, 0.5))
		module_list.add_child(empty_label)
		return
	
	for module in modules:
		var row = _create_module_row(module)
		module_list.add_child(row)


func _create_module_row(module) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size.y = 45
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.toggle_mode = true
	
	var hbox = HBoxContainer.new()
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.add_theme_constant_override("separation", 10)
	btn.add_child(hbox)
	
	# Slot type icon
	var type_label = Label.new()
	type_label.text = _get_slot_icon(module.slot_type if module else 0)
	type_label.add_theme_font_size_override("font_size", 14)
	type_label.add_theme_color_override("font_color", _get_slot_color(module.slot_type if module else 0))
	hbox.add_child(type_label)
	
	# Module name
	var name_label = Label.new()
	name_label.text = module.module_name if module else "Unknown"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", _get_rarity_color(module))
	hbox.add_child(name_label)
	
	btn.set_meta("module", module)
	btn.pressed.connect(_on_module_selected.bind(btn))
	
	return btn


func _update_ship_stats() -> void:
	if not stats_panel:
		return
	
	var grid = stats_panel.get_node("StatsGrid")
	if not grid:
		return
	
	var combat = 0.0
	var speed = 0.0
	var shield = 0.0
	var cargo = 0
	
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		combat = game_state.get_ship_combat_bonus()
		speed = game_state.get_ship_speed_bonus()
		var utility = game_state.get_ship_utility_bonus()
		shield = utility.get("shield", 0)
		cargo = utility.get("cargo", 0)
	
	_set_stat_value(grid, "CombatValue", str(int(combat)))
	_set_stat_value(grid, "SpeedValue", str(int(speed)))
	_set_stat_value(grid, "ShieldValue", str(int(shield)))
	_set_stat_value(grid, "CargoValue", "+" + str(cargo))


func _set_stat_value(grid: GridContainer, name: String, value: String) -> void:
	var label = grid.get_node_or_null(name)
	if label:
		label.text = value


func _update_slot_displays() -> void:
	if not has_node("/root/GameState"):
		return
	
	var game_state = get_node("/root/GameState")
	
	for slot_name in slot_buttons:
		var btn = slot_buttons[slot_name]
		var module = game_state.get_equipped_module(slot_name)
		
		if module:
			btn.text = module.module_name.substr(0, 1).to_upper()
			btn.modulate = _get_rarity_color(module)
		else:
			btn.text = slot_name.substr(0, 1).to_upper()
			btn.modulate = Color(0.5, 0.55, 0.6)


func _get_slot_icon(slot_type: int) -> String:
	match slot_type:
		0: return "🚀"  # Flight
		1: return "⚔️"  # Combat
		2: return "🛡️"  # Utility
	return "?"


func _get_slot_color(slot_type: int) -> Color:
	match slot_type:
		0: return Color(0.3, 0.7, 1.0)   # Flight - blue
		1: return Color(1.0, 0.4, 0.3)   # Combat - red
		2: return Color(0.4, 0.8, 0.5)   # Utility - green
	return Color.WHITE


func _get_rarity_color(module) -> Color:
	if not module or not "rarity" in module:
		return Color(0.7, 0.72, 0.75)
	
	match module.rarity:
		0: return Color(0.7, 0.72, 0.75)
		1: return Color(0.3, 0.8, 0.4)
		2: return Color(0.3, 0.6, 1.0)
		3: return Color(0.7, 0.3, 0.9)
		4: return Color(1.0, 0.8, 0.2)
	return Color.WHITE


# ==============================================================================
# PREVIEW
# ==============================================================================

func _update_preview(module) -> void:
	var vbox = module_preview.get_child(0)
	var name_label = vbox.get_node("ModuleName")
	var type_label = vbox.get_node("ModuleType")
	var desc_label = vbox.get_node("ModuleDesc")
	var stats_label = vbox.get_node("ModuleStats")
	
	if not module:
		_clear_preview()
		return
	
	name_label.text = module.module_name if "module_name" in module else "Unknown"
	name_label.add_theme_color_override("font_color", _get_rarity_color(module))
	
	var slot_name = ""
	if "slot_type" in module:
		match module.slot_type:
			0: slot_name = "Flight Module"
			1: slot_name = "Combat Module"
			2: slot_name = "Utility Module"
	type_label.text = slot_name
	
	desc_label.text = module.description if "description" in module else ""
	
	# Build stats string
	var stats_parts = []
	if "damage" in module and module.damage > 0:
		stats_parts.append("Damage: " + str(int(module.damage)))
	if "fire_rate" in module and module.fire_rate > 0:
		stats_parts.append("Fire Rate: " + str(module.fire_rate))
	if "thrust_power" in module and module.thrust_power > 0:
		stats_parts.append("Thrust: " + str(int(module.thrust_power)))
	if "shield_capacity" in module and module.shield_capacity > 0:
		stats_parts.append("Shield: " + str(int(module.shield_capacity)))
	
	stats_label.text = " | ".join(stats_parts)


func _clear_preview() -> void:
	var vbox = module_preview.get_child(0)
	vbox.get_node("ModuleName").text = "No Module Selected"
	vbox.get_node("ModuleType").text = ""
	vbox.get_node("ModuleDesc").text = "Select a module or slot to view details."
	vbox.get_node("ModuleStats").text = ""
	
	equip_button.disabled = true
	unequip_button.disabled = true
	selected_module = null
	selected_slot = ""


# ==============================================================================
# EVENT HANDLERS
# ==============================================================================

func _on_slot_clicked(slot_name: String) -> void:
	# Deselect modules
	for child in module_list.get_children():
		if child is Button:
			child.button_pressed = false
	
	selected_slot = slot_name
	selected_module = null
	
	# Deselect other slots
	for sn in slot_buttons:
		slot_buttons[sn].button_pressed = (sn == slot_name)
	
	# Show equipped module info
	if has_node("/root/GameState"):
		var module = get_node("/root/GameState").get_equipped_module(slot_name)
		_update_preview(module)
		
		equip_button.disabled = true
		unequip_button.disabled = (module == null)


func _on_module_selected(btn: Control) -> void:
	# Deselect slots
	for slot_name in slot_buttons:
		slot_buttons[slot_name].button_pressed = false
	
	# Deselect other modules
	for child in module_list.get_children():
		if child is Button and child != btn:
			child.button_pressed = false
	
	selected_module = btn.get_meta("module")
	selected_slot = ""
	
	_update_preview(selected_module)
	
	equip_button.disabled = false
	unequip_button.disabled = true


func _on_equip_pressed() -> void:
	if not selected_module:
		return
	
	# Determine slot from module type
	var slot_name = ""
	if "slot_type" in selected_module:
		match selected_module.slot_type:
			0: slot_name = "flight"
			1: slot_name = "combat"
			2: slot_name = "utility"
	
	if slot_name.is_empty():
		return
	
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		if game_state.equip_module(selected_module, slot_name):
			module_equipped.emit(selected_module, slot_name)
			refresh_hangar()


func _on_unequip_pressed() -> void:
	if selected_slot.is_empty():
		return
	
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		if game_state.unequip_module(selected_slot):
			module_unequipped.emit(selected_slot)
			refresh_hangar()


func _on_close_pressed() -> void:
	hangar_closed.emit()
	hide()
