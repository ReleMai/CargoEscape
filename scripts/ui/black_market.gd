# ==============================================================================
# BLACK MARKET UI - SHOP WITH DYNAMIC PRICING
# ==============================================================================
#
# FILE: scripts/ui/black_market.gd
# PURPOSE: Shop interface for buying and selling items
#
# FEATURES:
# - Dynamic pricing with variance
# - Category tabs (Weapons, Gear, Modules, Misc)
# - Buy/sell functionality
# - Price comparison tooltips
# - Stock refresh timer
#
# ==============================================================================

extends Control
class_name BlackMarketUI


# ==============================================================================
# SIGNALS
# ==============================================================================

signal item_purchased(item_id: String, price: int)
signal item_sold(item, price: int)
signal market_closed


# ==============================================================================
# CONSTANTS
# ==============================================================================

const CATEGORY_ALL := "All"
const CATEGORY_WEAPONS := "Weapons"
const CATEGORY_GEAR := "Gear"
const CATEGORY_MODULES := "Modules"
const CATEGORY_MISC := "Misc"


# ==============================================================================
# STATE
# ==============================================================================

var current_category: String = CATEGORY_ALL
var selected_shop_item = null
var selected_inventory_item = null
var player_credits: int = 0


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

var credits_label: Label = null
var category_tabs: TabBar = null
var shop_list: VBoxContainer = null
var inventory_list: VBoxContainer = null
var item_preview: Control = null
var buy_button: Button = null
var sell_button: Button = null


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_build_ui()
	_connect_signals()
	refresh_market()


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
	
	# Content area
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 20)
	main_vbox.add_child(content_hbox)
	
	# Shop section (left)
	_build_shop_section(content_hbox)
	
	# Preview section (center)
	_build_preview_section(content_hbox)
	
	# Inventory section (right)
	_build_inventory_section(content_hbox)


func _build_header(parent: Control) -> void:
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	parent.add_child(header)
	
	# Title
	var title = Label.new()
	title.text = "BLACK MARKET"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	header.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	# Credits display
	var credits_container = HBoxContainer.new()
	credits_container.add_theme_constant_override("separation", 8)
	header.add_child(credits_container)
	
	var credits_icon = Label.new()
	credits_icon.text = "💰"
	credits_icon.add_theme_font_size_override("font_size", 20)
	credits_container.add_child(credits_icon)
	
	credits_label = Label.new()
	credits_label.name = "CreditsLabel"
	credits_label.text = "0"
	credits_label.add_theme_font_size_override("font_size", 22)
	credits_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	credits_container.add_child(credits_label)
	
	# Close button
	var close_btn = Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)


func _build_shop_section(parent: Control) -> void:
	var section = VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.size_flags_stretch_ratio = 1.2
	section.add_theme_constant_override("separation", 10)
	parent.add_child(section)
	
	# Section title
	var title = Label.new()
	title.text = "FOR SALE"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	section.add_child(title)
	
	# Category tabs
	category_tabs = TabBar.new()
	category_tabs.add_tab(CATEGORY_ALL)
	category_tabs.add_tab(CATEGORY_WEAPONS)
	category_tabs.add_tab(CATEGORY_GEAR)
	category_tabs.add_tab(CATEGORY_MODULES)
	category_tabs.add_tab(CATEGORY_MISC)
	category_tabs.tab_changed.connect(_on_category_changed)
	section.add_child(category_tabs)
	
	# Shop list panel
	var panel = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_list_style(panel)
	section.add_child(panel)
	
	var scroll = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	panel.add_child(scroll)
	
	shop_list = VBoxContainer.new()
	shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_list.add_theme_constant_override("separation", 4)
	scroll.add_child(shop_list)


func _build_preview_section(parent: Control) -> void:
	var section = VBoxContainer.new()
	section.custom_minimum_size.x = 280
	section.add_theme_constant_override("separation", 15)
	parent.add_child(section)
	
	# Preview panel
	item_preview = PanelContainer.new()
	item_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_preview_style(item_preview)
	section.add_child(item_preview)
	
	var preview_vbox = VBoxContainer.new()
	preview_vbox.add_theme_constant_override("separation", 12)
	item_preview.add_child(preview_vbox)
	
	# Item name
	var name_label = Label.new()
	name_label.name = "ItemName"
	name_label.text = "Select an Item"
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_vbox.add_child(name_label)
	
	# Item icon area
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(100, 100)
	preview_vbox.add_child(icon_container)
	
	var icon_bg = ColorRect.new()
	icon_bg.name = "IconBG"
	icon_bg.custom_minimum_size = Vector2(80, 80)
	icon_bg.color = Color(0.15, 0.18, 0.22)
	icon_container.add_child(icon_bg)
	
	# Rarity indicator
	var rarity_label = Label.new()
	rarity_label.name = "RarityLabel"
	rarity_label.text = ""
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_vbox.add_child(rarity_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = "Browse the market to find items."
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.65, 0.68, 0.72))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size.y = 60
	preview_vbox.add_child(desc_label)
	
	# Stats area
	var stats_label = Label.new()
	stats_label.name = "StatsLabel"
	stats_label.text = ""
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color(0.5, 0.75, 0.6))
	preview_vbox.add_child(stats_label)
	
	# Price display
	var price_container = HBoxContainer.new()
	price_container.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_vbox.add_child(price_container)
	
	var price_label = Label.new()
	price_label.name = "PriceLabel"
	price_label.text = ""
	price_label.add_theme_font_size_override("font_size", 20)
	price_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	price_container.add_child(price_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_vbox.add_child(spacer)
	
	# Action buttons
	var button_container = HBoxContainer.new()
	button_container.add_theme_constant_override("separation", 10)
	section.add_child(button_container)
	
	buy_button = Button.new()
	buy_button.name = "BuyButton"
	buy_button.text = "BUY"
	buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_button.custom_minimum_size.y = 45
	buy_button.disabled = true
	buy_button.pressed.connect(_on_buy_pressed)
	button_container.add_child(buy_button)
	
	sell_button = Button.new()
	sell_button.name = "SellButton"
	sell_button.text = "SELL"
	sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_button.custom_minimum_size.y = 45
	sell_button.disabled = true
	sell_button.pressed.connect(_on_sell_pressed)
	button_container.add_child(sell_button)


func _build_inventory_section(parent: Control) -> void:
	var section = VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 10)
	parent.add_child(section)
	
	# Section title
	var title = Label.new()
	title.text = "YOUR INVENTORY"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	section.add_child(title)
	
	# Inventory list panel
	var panel = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_list_style(panel)
	section.add_child(panel)
	
	var scroll = ScrollContainer.new()
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	panel.add_child(scroll)
	
	inventory_list = VBoxContainer.new()
	inventory_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_list.add_theme_constant_override("separation", 4)
	scroll.add_child(inventory_list)


func _apply_list_style(panel: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.2, 0.25, 0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)


func _apply_preview_style(panel: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.25, 0.3, 0.35)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 15
	style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", style)


func _connect_signals() -> void:
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		game_state.credits_changed.connect(_on_credits_changed)


# ==============================================================================
# DATA LOADING
# ==============================================================================

func refresh_market() -> void:
	_update_credits_display()
	_populate_shop_list()
	_populate_inventory_list()
	_clear_preview()


func _update_credits_display() -> void:
	if has_node("/root/GameState"):
		player_credits = get_node("/root/GameState").credits
	credits_label.text = str(player_credits)


func _populate_shop_list() -> void:
	# Clear existing
	for child in shop_list.get_children():
		child.queue_free()
	
	var stock = []
	if has_node("/root/GameState"):
		stock = get_node("/root/GameState").get_market_stock()
	
	for item_data in stock:
		if current_category != CATEGORY_ALL:
			if not _item_matches_category(item_data, current_category):
				continue
		
		var row = _create_shop_row(item_data)
		shop_list.add_child(row)


func _populate_inventory_list() -> void:
	# Clear existing
	for child in inventory_list.get_children():
		child.queue_free()
	
	var items = []
	if has_node("/root/GameState"):
		items = get_node("/root/GameState").get_stash_items()
	
	for item in items:
		var row = _create_inventory_row(item)
		inventory_list.add_child(row)


func _item_matches_category(item_data: Dictionary, category: String) -> bool:
	var item_type = item_data.get("type", "")
	match category:
		CATEGORY_WEAPONS: return item_type == "weapon"
		CATEGORY_GEAR: return item_type == "gear"
		CATEGORY_MODULES: return item_type == "module"
		CATEGORY_MISC: return item_type == "item"
	return true


# ==============================================================================
# UI CREATION
# ==============================================================================

func _create_shop_row(item_data: Dictionary) -> Control:
	var row = Button.new()
	row.custom_minimum_size.y = 50
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var hbox = HBoxContainer.new()
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)
	
	# Item name
	var name_label = Label.new()
	name_label.text = _get_item_display_name(item_data)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", _get_rarity_color(item_data))
	hbox.add_child(name_label)
	
	# Price
	var price = 0
	if has_node("/root/GameState"):
		price = get_node("/root/GameState").get_market_price(item_data.id)
	
	var price_label = Label.new()
	price_label.text = str(price) + "c"
	price_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	hbox.add_child(price_label)
	
	# Store data
	row.set_meta("item_data", item_data)
	row.set_meta("price", price)
	row.pressed.connect(_on_shop_item_selected.bind(row))
	
	return row


func _create_inventory_row(item) -> Control:
	var row = Button.new()
	row.custom_minimum_size.y = 45
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var hbox = HBoxContainer.new()
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.add_theme_constant_override("separation", 10)
	row.add_child(hbox)
	
	# Item name
	var name_label = Label.new()
	name_label.text = item.name if item.has_method("get") else str(item)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_label)
	
	# Sell value
	var sell_price = 0
	if has_node("/root/GameState"):
		sell_price = get_node("/root/GameState").get_sell_price(item)
	
	var price_label = Label.new()
	price_label.text = str(sell_price) + "c"
	price_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	hbox.add_child(price_label)
	
	# Store data
	row.set_meta("item", item)
	row.set_meta("sell_price", sell_price)
	row.pressed.connect(_on_inventory_item_selected.bind(row))
	
	return row


func _get_item_display_name(item_data: Dictionary) -> String:
	var item_id = item_data.get("id", "unknown")
	
	# Try to get actual name from database
	if item_data.type == "weapon":
		var weapon_data = WeaponsDatabase.get_weapon_data(item_id)
		if not weapon_data.is_empty():
			return weapon_data.get("name", item_id)
	
	# Fallback to formatted ID
	return item_id.replace("_", " ").capitalize()


func _get_rarity_color(item_data: Dictionary) -> Color:
	var item_id = item_data.get("id", "")
	var rarity = 0
	
	if item_data.type == "weapon":
		var weapon_data = WeaponsDatabase.get_weapon_data(item_id)
		rarity = weapon_data.get("rarity", 0)
	
	match rarity:
		0: return Color(0.7, 0.72, 0.75)  # Common
		1: return Color(0.3, 0.8, 0.4)    # Uncommon
		2: return Color(0.3, 0.6, 1.0)    # Rare
		3: return Color(0.7, 0.3, 0.9)    # Epic
		4: return Color(1.0, 0.8, 0.2)    # Legendary
	return Color.WHITE


# ==============================================================================
# PREVIEW
# ==============================================================================

func _update_preview_shop(item_data: Dictionary, price: int) -> void:
	var preview_vbox = item_preview.get_child(0)
	var name_label = preview_vbox.get_node("ItemName")
	var rarity_label = preview_vbox.get_node("RarityLabel")
	var desc_label = preview_vbox.get_node("DescLabel")
	var stats_label = preview_vbox.get_node("StatsLabel")
	var price_label = preview_vbox.get_node("PriceLabel")
	
	name_label.text = _get_item_display_name(item_data)
	name_label.add_theme_color_override("font_color", _get_rarity_color(item_data))
	
	# Get detailed info
	var desc = "No description available."
	var stats_text = ""
	
	if item_data.type == "weapon":
		var weapon_data = WeaponsDatabase.get_weapon_data(item_data.id)
		if not weapon_data.is_empty():
			desc = weapon_data.get("description", desc)
			stats_text = "Damage: %d\nFire Rate: %.1f\nRange: %d" % [
				weapon_data.get("base_damage", 0),
				weapon_data.get("fire_rate", 1.0),
				weapon_data.get("range", 100)
			]
			rarity_label.text = _get_rarity_name(weapon_data.get("rarity", 0))
			rarity_label.add_theme_color_override("font_color", _get_rarity_color(item_data))
	
	desc_label.text = desc
	stats_label.text = stats_text
	price_label.text = str(price) + " credits"
	
	# Update button states
	buy_button.disabled = player_credits < price
	sell_button.disabled = true


func _update_preview_inventory(item, sell_price: int) -> void:
	var preview_vbox = item_preview.get_child(0)
	var name_label = preview_vbox.get_node("ItemName")
	var rarity_label = preview_vbox.get_node("RarityLabel")
	var desc_label = preview_vbox.get_node("DescLabel")
	var stats_label = preview_vbox.get_node("StatsLabel")
	var price_label = preview_vbox.get_node("PriceLabel")
	
	name_label.text = item.name if "name" in item else "Item"
	desc_label.text = item.description if "description" in item else ""
	rarity_label.text = _get_rarity_name(item.rarity if "rarity" in item else 0)
	stats_label.text = ""
	price_label.text = "Sell for: " + str(sell_price) + " credits"
	
	buy_button.disabled = true
	sell_button.disabled = false


func _clear_preview() -> void:
	var preview_vbox = item_preview.get_child(0)
	preview_vbox.get_node("ItemName").text = "Select an Item"
	preview_vbox.get_node("RarityLabel").text = ""
	preview_vbox.get_node("DescLabel").text = "Browse the market to find items."
	preview_vbox.get_node("StatsLabel").text = ""
	preview_vbox.get_node("PriceLabel").text = ""
	
	buy_button.disabled = true
	sell_button.disabled = true
	
	selected_shop_item = null
	selected_inventory_item = null


func _get_rarity_name(rarity: int) -> String:
	match rarity:
		0: return "Common"
		1: return "Uncommon"
		2: return "Rare"
		3: return "Epic"
		4: return "Legendary"
	return ""


# ==============================================================================
# EVENT HANDLERS
# ==============================================================================

func _on_category_changed(tab_index: int) -> void:
	match tab_index:
		0: current_category = CATEGORY_ALL
		1: current_category = CATEGORY_WEAPONS
		2: current_category = CATEGORY_GEAR
		3: current_category = CATEGORY_MODULES
		4: current_category = CATEGORY_MISC
	
	_populate_shop_list()


func _on_shop_item_selected(row: Control) -> void:
	selected_shop_item = row
	selected_inventory_item = null
	
	var item_data = row.get_meta("item_data")
	var price = row.get_meta("price")
	_update_preview_shop(item_data, price)


func _on_inventory_item_selected(row: Control) -> void:
	selected_inventory_item = row
	selected_shop_item = null
	
	var item = row.get_meta("item")
	var sell_price = row.get_meta("sell_price")
	_update_preview_inventory(item, sell_price)


func _on_buy_pressed() -> void:
	if not selected_shop_item:
		return
	
	var item_data = selected_shop_item.get_meta("item_data")
	var price = selected_shop_item.get_meta("price")
	
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		if game_state.buy_from_market(item_data.id):
			item_purchased.emit(item_data.id, price)
			refresh_market()


func _on_sell_pressed() -> void:
	if not selected_inventory_item:
		return
	
	var item = selected_inventory_item.get_meta("item")
	
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		var price = game_state.sell_to_market(item)
		game_state.remove_from_stash(item)
		item_sold.emit(item, price)
		refresh_market()


func _on_credits_changed(new_amount: int) -> void:
	player_credits = new_amount
	credits_label.text = str(new_amount)


func _on_close_pressed() -> void:
	market_closed.emit()
	hide()
