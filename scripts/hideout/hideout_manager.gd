# ==============================================================================
# HIDEOUT MANAGER - DOCKING ANIMATION + HIDEOUT MENU
# ==============================================================================
#
# FILE: scripts/hideout/hideout_manager.gd
# PURPOSE: Plays the docking sequence, then shows hideout menu
#
# SEQUENCE:
# 1. Fade from escape scene to black
# 2. Show player ship approaching hideout station
# 3. Dock animation
# 4. Fade in hideout menu with multiple options
#
# ==============================================================================

extends Control
class_name HideoutManager


# ==============================================================================
# SIGNALS
# ==============================================================================

signal new_mission_requested
signal returned_to_menu


# ==============================================================================
# EXPORTS
# ==============================================================================

@export var skip_enabled: bool = true
@export var auto_start: bool = true


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var background: ColorRect = $Background
@onready var star_field: Control = $StarField
@onready var player_ship: Control = $ShipLayer/PlayerShip
@onready var station: Control = $ShipLayer/Station
@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var skip_hint: Label = $UI/SkipHint

# Menu nodes
@onready var menu_container: Control = $UI/MenuContainer
@onready var title_label: Label = $UI/MenuContainer/VBox/Title
@onready var stash_button: Button = $UI/MenuContainer/VBox/ButtonGrid/StashButton
@onready var market_button: Button = $UI/MenuContainer/VBox/ButtonGrid/MarketButton
@onready var upgrades_button: Button = $UI/MenuContainer/VBox/ButtonGrid/UpgradesButton
@onready var map_button: Button = $UI/MenuContainer/VBox/ButtonGrid/MapButton
@onready var credits_label: Label = $UI/MenuContainer/VBox/CreditsLabel
@onready var depart_button: Button = $UI/MenuContainer/VBox/DepartButton
@onready var return_button: Button = $UI/MenuContainer/VBox/ReturnButton

# Sub-panels
@onready var stash_panel: Control = $UI/StashPanel
@onready var market_panel: Control = $UI/MarketPanel
@onready var upgrades_panel: Control = $UI/UpgradesPanel
@onready var map_panel: Control = $UI/MapPanel

# Stash panel nodes
@onready var stash_ship_label: Label = $UI/StashPanel/VBox/Inventories/ShipColumn/ShipLabel
@onready var stash_ship_list: VBoxContainer = \
	$UI/StashPanel/VBox/Inventories/ShipColumn/ShipScroll/ShipList
@onready var stash_stash_label: Label = $UI/StashPanel/VBox/Inventories/StashColumn/StashLabel
@onready var stash_stash_list: VBoxContainer = \
	$UI/StashPanel/VBox/Inventories/StashColumn/StashScroll/StashList
@onready var transfer_to_stash_btn: Button = \
	$UI/StashPanel/VBox/Inventories/TransferColumn/ToStash
@onready var transfer_to_ship_btn: Button = \
	$UI/StashPanel/VBox/Inventories/TransferColumn/ToShip

# Market panel nodes
@onready var market_credits_label: Label = $UI/MarketPanel/VBox/CreditsDisplay
@onready var market_tabs: TabContainer = $UI/MarketPanel/VBox/Tabs
@onready var market_ship_info: Label = null
@onready var market_ship_list: VBoxContainer = null
@onready var market_stash_info: Label = null
@onready var market_stash_list: VBoxContainer = null
@onready var sell_all_button: Button = $UI/MarketPanel/VBox/SellAllButton

# Selected items for transfer
var selected_ship_item: Resource = null
var selected_stash_item: Resource = null


# ==============================================================================
# STATE
# ==============================================================================

var intro_playing: bool = false
var can_skip: bool = false
var menu_visible: bool = false

# Animation phases
const PHASE_FADE_IN = 0
const PHASE_APPROACH = 1
const PHASE_DOCK = 2
const PHASE_MENU = 3

var current_phase: int = 0

# Hideout names
var hideout_names: Array[String] = [
	"The Rusty Anchor",
	"Shadow's Den",
	"Smuggler's Rest",
	"Black Nebula Station",
	"The Pirate's Haven",
	"Void Walker's Refuge",
	"The Broken Compass"
]


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_setup_market_references()
	_setup_initial_state()
	_connect_signals()
	
	if auto_start:
		start_docking_sequence()


func _setup_market_references() -> void:
	# Get market panel nodes with spaces in names
	if market_panel:
		var tabs = market_panel.get_node_or_null("VBox/Tabs")
		if tabs:
			market_tabs = tabs
			var ship_cargo = tabs.get_node_or_null("Ship Cargo")
			if ship_cargo:
				market_ship_info = ship_cargo.get_node_or_null("ShipInfo")
				var scroll = ship_cargo.get_node_or_null("ShipScroll")
				if scroll:
					market_ship_list = scroll.get_node_or_null("ShipMarketList")
			var stash_items = tabs.get_node_or_null("Stash Items")
			if stash_items:
				market_stash_info = stash_items.get_node_or_null("StashInfo")
				var scroll = stash_items.get_node_or_null("StashScroll")
				if scroll:
					market_stash_list = scroll.get_node_or_null("StashMarketList")


func _input(event: InputEvent) -> void:
	# Skip docking animation on key/click (only during animation, not menu)
	if intro_playing and can_skip and not menu_visible and skip_enabled:
		if event is InputEventKey and event.pressed:
			skip_to_menu()
		elif event is InputEventMouseButton and event.pressed:
			skip_to_menu()


func _setup_initial_state() -> void:
	# Start with black screen
	if fade_overlay:
		fade_overlay.color = Color.BLACK
		fade_overlay.modulate.a = 1.0
	
	# Hide UI elements
	if skip_hint:
		skip_hint.modulate.a = 0
	
	# Hide menu initially
	if menu_container:
		menu_container.modulate.a = 0
		menu_container.visible = false
	
	# Hide sub-panels
	_hide_all_panels()
	
	# Position ships
	if player_ship:
		player_ship.position = Vector2(1400, 360)  # Start off right
	if station:
		station.position = Vector2(200, 180)  # Station on left


func _connect_signals() -> void:
	if stash_button:
		stash_button.pressed.connect(_on_stash_pressed)
	if market_button:
		market_button.pressed.connect(_on_market_pressed)
	if upgrades_button:
		upgrades_button.pressed.connect(_on_upgrades_pressed)
	if map_button:
		map_button.pressed.connect(_on_map_pressed)
	if depart_button:
		depart_button.pressed.connect(_on_depart_pressed)
	if return_button:
		return_button.pressed.connect(_on_return_pressed)
	
	# Connect close buttons on panels
	_connect_panel_close_buttons()
	
	# Connect stash transfer buttons
	if transfer_to_stash_btn:
		transfer_to_stash_btn.pressed.connect(_on_transfer_to_stash)
	if transfer_to_ship_btn:
		transfer_to_ship_btn.pressed.connect(_on_transfer_to_ship)
	
	# Connect sell all button
	if sell_all_button:
		sell_all_button.pressed.connect(_on_sell_all)


# ==============================================================================
# DOCKING SEQUENCE
# ==============================================================================

func start_docking_sequence() -> void:
	intro_playing = true
	current_phase = PHASE_FADE_IN
	
	# Fade from black to reveal space
	if fade_overlay:
		var tween = create_tween()
		tween.tween_property(fade_overlay, "modulate:a", 0.0, 1.2)
		tween.tween_callback(_start_approach)
	else:
		_start_approach()
	
	# Enable skip after a moment
	await get_tree().create_timer(0.5).timeout
	can_skip = true
	_fade_in_skip_hint()


func _start_approach() -> void:
	if not intro_playing:
		return
	
	current_phase = PHASE_APPROACH
	
	# Animate player ship approaching station from right
	if player_ship:
		var tween = create_tween()
		tween.tween_property(player_ship, "position", Vector2(600, 340), 2.0)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_callback(_start_dock)


func _start_dock() -> void:
	if not intro_playing:
		return
	
	current_phase = PHASE_DOCK
	
	# Player ship docks with station - add slight rotation for realism
	if player_ship:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(player_ship, "position", Vector2(380, 300), 1.2)
		tween.tween_property(player_ship, "rotation", deg_to_rad(5), 0.6).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(player_ship, "rotation", 0.0, 0.6).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(_dock_complete)


func _dock_complete() -> void:
	# Brief camera shake as docking completes
	_shake_ui(4.0)
	
	# Brief delay then show menu
	await get_tree().create_timer(0.3).timeout
	_show_menu()


func _shake_ui(intensity: float) -> void:
	if menu_container:
		var original_pos = menu_container.position
		var tween = create_tween()
		for i in range(5):
			var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			tween.tween_property(menu_container, "position", original_pos + offset, 0.03)
		tween.tween_property(menu_container, "position", original_pos, 0.05)


func _show_menu() -> void:
	intro_playing = false
	menu_visible = true
	current_phase = PHASE_MENU
	
	# Fade out skip hint
	if skip_hint:
		var tween = create_tween()
		tween.tween_property(skip_hint, "modulate:a", 0.0, 0.2)
	
	# Set random hideout name
	if title_label:
		title_label.text = hideout_names[randi() % hideout_names.size()]
	
	# Update credits display
	_update_credits_display()
	
	# Show menu with scale and fade
	if menu_container:
		menu_container.visible = true
		menu_container.scale = Vector2(0.9, 0.9)
		menu_container.pivot_offset = menu_container.size / 2
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(menu_container, "modulate:a", 1.0, 0.4)
		tween.tween_property(menu_container, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func skip_to_menu() -> void:
	intro_playing = false
	
	# Instantly position ships
	if player_ship:
		player_ship.position = Vector2(380, 300)
	if station:
		station.position = Vector2(200, 180)
	
	# Clear fade overlay
	if fade_overlay:
		fade_overlay.modulate.a = 0.0
	
	_show_menu()


# ==============================================================================
# MENU HANDLERS
# ==============================================================================

func _on_stash_pressed() -> void:
	_hide_all_panels()
	if stash_panel:
		stash_panel.visible = true
		_animate_panel_in(stash_panel)
		_populate_stash_panel()


func _on_market_pressed() -> void:
	_hide_all_panels()
	if market_panel:
		market_panel.visible = true
		_animate_panel_in(market_panel)
		_populate_market_panel()


func _on_upgrades_pressed() -> void:
	_hide_all_panels()
	if upgrades_panel:
		upgrades_panel.visible = true
		_animate_panel_in(upgrades_panel)


func _on_map_pressed() -> void:
	_hide_all_panels()
	if map_panel:
		map_panel.visible = true
		_animate_panel_in(map_panel)


func _on_depart_pressed() -> void:
	# Flash effect before fade
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.3, 0.5, 0.7, 0.3)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "color:a", 0.0, 0.3)
	flash_tween.tween_callback(flash.queue_free)
	
	# Fade menu out quickly
	if menu_container:
		var menu_tween = create_tween()
		menu_tween.tween_property(menu_container, "modulate:a", 0.0, 0.3)
	
	# Fade to black and start new mission
	if fade_overlay:
		fade_overlay.color = Color.BLACK
		var tween = create_tween()
		tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.6)
		tween.tween_callback(_go_to_boarding)
	else:
		_go_to_boarding()


func _go_to_boarding() -> void:
	new_mission_requested.emit()
	get_tree().change_scene_to_file("res://scenes/boarding/boarding_scene.tscn")


# ==============================================================================
# PANEL MANAGEMENT
# ==============================================================================

func _hide_all_panels() -> void:
	if stash_panel:
		stash_panel.visible = false
	if market_panel:
		market_panel.visible = false
	if upgrades_panel:
		upgrades_panel.visible = false
	if map_panel:
		map_panel.visible = false


func _animate_panel_in(panel: Control) -> void:
	panel.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)


func _connect_panel_close_buttons() -> void:
	# Connect all close buttons in sub-panels
	# Stash panel close button is in header
	if stash_panel:
		var stash_close = stash_panel.get_node_or_null("VBox/Header/CloseButton")
		if stash_close:
			stash_close.pressed.connect(_hide_all_panels)
	
	# Market panel close button is in header
	if market_panel:
		var market_close = market_panel.get_node_or_null("VBox/Header/CloseButton")
		if market_close:
			market_close.pressed.connect(_hide_all_panels)
	
	# Other panels still have VBox/CloseButton
	for panel in [upgrades_panel, map_panel]:
		if panel:
			var close_btn = panel.get_node_or_null("VBox/CloseButton")
			if close_btn:
				close_btn.pressed.connect(_hide_all_panels)


func _on_return_pressed() -> void:
	# Fade to black and return to main menu
	if fade_overlay:
		fade_overlay.color = Color.BLACK
		var tween = create_tween()
		tween.tween_property(fade_overlay, "modulate:a", 1.0, 0.5)
		tween.tween_callback(_go_to_menu)
	else:
		_go_to_menu()


func _go_to_menu() -> void:
	returned_to_menu.emit()
	get_tree().change_scene_to_file("res://scenes/intro/intro_scene.tscn")


# ==============================================================================
# UI HELPERS
# ==============================================================================

func _update_credits_display() -> void:
	if credits_label and GameManager:
		credits_label.text = "Credits: $%d" % GameManager.credits


func _fade_in_skip_hint() -> void:
	if skip_hint:
		var tween = create_tween()
		tween.tween_property(skip_hint, "modulate:a", 0.5, 0.5)


# ==============================================================================
# STASH PANEL LOGIC
# ==============================================================================

func _populate_stash_panel() -> void:
	selected_ship_item = null
	selected_stash_item = null
	
	# Update ship inventory
	_update_stash_ship_list()
	
	# Update stash
	_update_stash_stash_list()


func _update_stash_ship_list() -> void:
	if not stash_ship_list or not GameManager:
		return
	
	# Clear existing
	for child in stash_ship_list.get_children():
		child.queue_free()
	
	# Update label
	if stash_ship_label:
		stash_ship_label.text = "SHIP INVENTORY (%d/%d)" % [
			GameManager.ship_inventory.size(),
			GameManager.get_ship_inventory_capacity()
		]
	
	# Add items
	for item in GameManager.ship_inventory:
		var btn = _create_item_button(item, true)
		stash_ship_list.add_child(btn)
	
	# Empty message
	if GameManager.ship_inventory.is_empty():
		var label = Label.new()
		label.text = "(Empty)"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stash_ship_list.add_child(label)


func _update_stash_stash_list() -> void:
	if not stash_stash_list or not GameManager:
		return
	
	# Clear existing
	for child in stash_stash_list.get_children():
		child.queue_free()
	
	# Update label
	if stash_stash_label:
		stash_stash_label.text = "STASH (%d/%d)" % [
			GameManager.stash_inventory.size(),
			GameManager.get_stash_capacity()
		]
	
	# Add items
	for item in GameManager.stash_inventory:
		var btn = _create_item_button(item, false)
		stash_stash_list.add_child(btn)
	
	# Empty message
	if GameManager.stash_inventory.is_empty():
		var label = Label.new()
		label.text = "(Empty)"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stash_stash_list.add_child(label)


func _create_item_button(item: Resource, is_ship: bool) -> Button:
	var btn = Button.new()
	var item_name = item.name if item and "name" in item else "Unknown"
	var item_value = item.value if item and "value" in item else 0
	var item_rarity = item.rarity if item and "rarity" in item else 0
	
	# Format with rarity indicator
	var rarity_prefix = _get_rarity_prefix(item_rarity)
	btn.text = "%s%s - $%d" % [rarity_prefix, item_name, item_value]
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Color by rarity
	var rarity_color = _get_rarity_color(item_rarity)
	btn.add_theme_color_override("font_color", rarity_color)
	
	# Store reference to item
	btn.set_meta("item", item)
	btn.set_meta("is_ship", is_ship)
	
	# Connect to selection
	btn.pressed.connect(_on_stash_item_selected.bind(item, is_ship, btn))
	
	return btn


func _get_rarity_prefix(rarity: int) -> String:
	match rarity:
		0: return ""           # Common - no prefix
		1: return "◆ "         # Uncommon
		2: return "◆◆ "        # Rare
		3: return "★ "         # Epic
		4: return "★★ "        # Legendary
		_: return ""


func _get_rarity_color(rarity: int) -> Color:
	match rarity:
		0: return Color(0.7, 0.7, 0.7)      # Gray - Common
		1: return Color(0.3, 0.8, 0.3)      # Green - Uncommon
		2: return Color(0.4, 0.6, 1.0)      # Blue - Rare
		3: return Color(0.7, 0.3, 0.9)      # Purple - Epic
		4: return Color(1.0, 0.8, 0.2)      # Gold - Legendary
		_: return Color.WHITE


func _on_stash_item_selected(item: Resource, is_ship: bool, btn: Button) -> void:
	if is_ship:
		selected_ship_item = item
		# Highlight selected
		_highlight_selected_in_list(stash_ship_list, btn)
	else:
		selected_stash_item = item
		_highlight_selected_in_list(stash_stash_list, btn)


func _highlight_selected_in_list(list: VBoxContainer, selected_btn: Button) -> void:
	for child in list.get_children():
		if child is Button:
			if child == selected_btn:
				child.add_theme_color_override("font_color", Color(0.2, 1, 0.4))
			else:
				child.remove_theme_color_override("font_color")


func _on_transfer_to_stash() -> void:
	if not selected_ship_item or not GameManager:
		return
	
	if GameManager.transfer_to_stash(selected_ship_item):
		selected_ship_item = null
		_populate_stash_panel()
		_update_credits_display()


func _on_transfer_to_ship() -> void:
	if not selected_stash_item or not GameManager:
		return
	
	if GameManager.transfer_to_ship(selected_stash_item):
		selected_stash_item = null
		_populate_stash_panel()
		_update_credits_display()


# ==============================================================================
# MARKET PANEL LOGIC
# ==============================================================================

func _populate_market_panel() -> void:
	if not GameManager:
		return
	
	# Update credits
	if market_credits_label:
		market_credits_label.text = "Your Credits: $%d" % GameManager.credits
	
	# Update ship tab
	_update_market_ship_list()
	
	# Update stash tab
	_update_market_stash_list()


func _update_market_ship_list() -> void:
	if not market_ship_list or not GameManager:
		return
	
	# Clear existing
	for child in market_ship_list.get_children():
		child.queue_free()
	
	# Update info label
	if market_ship_info:
		var count = GameManager.ship_inventory.size()
		market_ship_info.text = "Sell items from your ship (%d items)" % count
	
	# Add items with sell buttons
	for item in GameManager.ship_inventory:
		var row = _create_market_row(item, false)
		market_ship_list.add_child(row)
	
	if GameManager.ship_inventory.is_empty():
		var label = Label.new()
		label.text = "No items to sell"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		market_ship_list.add_child(label)


func _update_market_stash_list() -> void:
	if not market_stash_list or not GameManager:
		return
	
	# Clear existing
	for child in market_stash_list.get_children():
		child.queue_free()
	
	# Update info label
	if market_stash_info:
		var count = GameManager.stash_inventory.size()
		market_stash_info.text = "Sell items from your stash (%d items)" % count
	
	# Add items with sell buttons
	for item in GameManager.stash_inventory:
		var row = _create_market_row(item, true)
		market_stash_list.add_child(row)
	
	if GameManager.stash_inventory.is_empty():
		var label = Label.new()
		label.text = "No items in stash"
		label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		market_stash_list.add_child(label)


func _create_market_row(item: Resource, from_stash: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var item_name = item.name if item and "name" in item else "Unknown"
	var item_value = item.value if item and "value" in item else 10
	var item_rarity = item.rarity if item and "rarity" in item else 0
	
	var name_label = Label.new()
	var rarity_prefix = _get_rarity_prefix(item_rarity)
	name_label.text = rarity_prefix + item_name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", _get_rarity_color(item_rarity))
	row.add_child(name_label)
	
	var sell_btn = Button.new()
	sell_btn.text = "SELL $%d" % item_value
	sell_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	sell_btn.pressed.connect(_on_sell_item.bind(item, from_stash))
	row.add_child(sell_btn)
	
	return row


func _on_sell_item(item: Resource, from_stash: bool) -> void:
	if not GameManager:
		return
	
	if GameManager.sell_item(item, from_stash):
		_populate_market_panel()
		_update_credits_display()


func _on_sell_all() -> void:
	if not GameManager:
		return
	
	# Determine which tab is active
	var current_tab = market_tabs.current_tab if market_tabs else 0
	
	if current_tab == 0:
		# Sell all ship items
		var items_to_sell = GameManager.ship_inventory.duplicate()
		for item in items_to_sell:
			GameManager.sell_item(item, false)
	else:
		# Sell all stash items
		var items_to_sell = GameManager.stash_inventory.duplicate()
		for item in items_to_sell:
			GameManager.sell_item(item, true)
	
	_populate_market_panel()
	_update_credits_display()
