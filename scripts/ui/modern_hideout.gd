# ==============================================================================
# MODERN HIDEOUT - PROFESSIONAL HIDEOUT HUB INTERFACE
# ==============================================================================
#
# FILE: scripts/ui/modern_hideout.gd
# PURPOSE: Modern hub interface connecting all hideout systems
#
# FEATURES:
# - Clean professional UI design
# - Quick access to all sub-systems
# - Player stats overview
# - Run summary display
# - Smooth transitions
#
# ==============================================================================

extends Control
class_name ModernHideout


# ==============================================================================
# SIGNALS
# ==============================================================================

signal mission_launched(poi_id: String)
signal returned_to_menu


# ==============================================================================
# PRELOADS
# ==============================================================================

const GalaxyMapScene = preload("res://scripts/ui/galaxy_map.gd")
const BlackMarketScene = preload("res://scripts/ui/black_market.gd")
const StashScene = preload("res://scripts/ui/stash_ui.gd")
const ShipHangarScene = preload("res://scripts/ui/ship_hangar.gd")


# ==============================================================================
# STATE
# ==============================================================================

var current_panel: Control = null
var animation_playing: bool = false

# Sub-panels
var galaxy_map: Control = null
var black_market: Control = null
var stash_ui: Control = null
var ship_hangar: Control = null


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

var background: ColorRect = null
var sidebar: PanelContainer = null
var content_area: Control = null
var main_menu: VBoxContainer = null

# Sidebar elements
var credits_label: Label = null
var ship_tier_label: Label = null
var runs_label: Label = null

# Menu buttons
var map_button: Button = null
var market_button: Button = null
var stash_button: Button = null
var hangar_button: Button = null
var depart_button: Button = null
var quit_button: Button = null


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_build_ui()
	_connect_signals()
	_update_stats_display()
	_create_sub_panels()


func _build_ui() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Background with gradient
	background = ColorRect.new()
	background.color = Color(0.03, 0.04, 0.06)
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	add_child(background)
	
	# Stars background effect
	_create_star_background()
	
	# Main layout - sidebar + content
	var main_hbox = HBoxContainer.new()
	main_hbox.anchor_right = 1.0
	main_hbox.anchor_bottom = 1.0
	main_hbox.add_theme_constant_override("separation", 0)
	add_child(main_hbox)
	
	# Sidebar
	_build_sidebar(main_hbox)
	
	# Content area
	content_area = Control.new()
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(content_area)
	
	# Main menu (shown in content area when no panel is open)
	_build_main_menu()


func _create_star_background() -> void:
	var stars = Control.new()
	stars.anchor_right = 1.0
	stars.anchor_bottom = 1.0
	stars.draw.connect(_draw_stars.bind(stars))
	add_child(stars)


func _draw_stars(control: Control) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345  # Fixed seed for consistent stars
	
	for i in range(150):
		var pos = Vector2(
			rng.randf() * control.size.x,
			rng.randf() * control.size.y
		)
		var size = rng.randf_range(0.5, 2.0)
		var alpha = rng.randf_range(0.2, 0.6)
		control.draw_circle(pos, size, Color(1, 1, 1, alpha))


func _build_sidebar(parent: Control) -> void:
	sidebar = PanelContainer.new()
	sidebar.custom_minimum_size.x = 280
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.09, 0.98)
	style.border_width_right = 2
	style.border_color = Color(0.15, 0.18, 0.22)
	sidebar.add_theme_stylebox_override("panel", style)
	parent.add_child(sidebar)
	
	var sidebar_vbox = VBoxContainer.new()
	sidebar_vbox.add_theme_constant_override("separation", 0)
	sidebar.add_child(sidebar_vbox)
	
	# Header
	_build_sidebar_header(sidebar_vbox)
	
	# Stats section
	_build_stats_section(sidebar_vbox)
	
	# Navigation buttons
	_build_nav_buttons(sidebar_vbox)
	
	# Bottom section
	_build_bottom_section(sidebar_vbox)


func _build_sidebar_header(parent: Control) -> void:
	var header = PanelContainer.new()
	header.custom_minimum_size.y = 80
	
	var header_style = StyleBoxFlat.new()
	header_style.bg_color = Color(0.08, 0.1, 0.13)
	header_style.border_width_bottom = 1
	header_style.border_color = Color(0.2, 0.25, 0.3)
	header_style.content_margin_left = 20
	header_style.content_margin_right = 20
	header_style.content_margin_top = 15
	header_style.content_margin_bottom = 15
	header.add_theme_stylebox_override("panel", header_style)
	parent.add_child(header)
	
	var header_vbox = VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 5)
	header.add_child(header_vbox)
	
	var title = Label.new()
	title.text = "SHADOW'S DEN"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	header_vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.text = "Smuggler's Hideout"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	header_vbox.add_child(subtitle)


func _build_stats_section(parent: Control) -> void:
	var stats = PanelContainer.new()
	
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0.05, 0.06, 0.08)
	stats_style.content_margin_left = 20
	stats_style.content_margin_right = 20
	stats_style.content_margin_top = 15
	stats_style.content_margin_bottom = 15
	stats.add_theme_stylebox_override("panel", stats_style)
	parent.add_child(stats)
	
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 12)
	stats.add_child(stats_vbox)
	
	# Credits
	var credits_row = _create_stat_row("💰 Credits", "0")
	credits_label = credits_row.get_child(1)
	credits_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	stats_vbox.add_child(credits_row)
	
	# Ship Tier
	var tier_row = _create_stat_row("🚀 Ship Tier", "1")
	ship_tier_label = tier_row.get_child(1)
	ship_tier_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.5))
	stats_vbox.add_child(tier_row)
	
	# Runs
	var runs_row = _create_stat_row("📊 Runs", "0")
	runs_label = runs_row.get_child(1)
	stats_vbox.add_child(runs_row)


func _create_stat_row(label_text: String, value_text: String) -> HBoxContainer:
	var row = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	row.add_child(label)
	
	var value = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
	row.add_child(value)
	
	return row


func _build_nav_buttons(parent: Control) -> void:
	var nav = VBoxContainer.new()
	nav.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nav.add_theme_constant_override("separation", 4)
	
	var nav_margin = MarginContainer.new()
	nav_margin.add_theme_constant_override("margin_left", 15)
	nav_margin.add_theme_constant_override("margin_right", 15)
	nav_margin.add_theme_constant_override("margin_top", 20)
	nav_margin.add_child(nav)
	parent.add_child(nav_margin)
	
	# Section title
	var nav_title = Label.new()
	nav_title.text = "NAVIGATION"
	nav_title.add_theme_font_size_override("font_size", 11)
	nav_title.add_theme_color_override("font_color", Color(0.4, 0.45, 0.5))
	nav.add_child(nav_title)
	
	var spacer1 = Control.new()
	spacer1.custom_minimum_size.y = 10
	nav.add_child(spacer1)
	
	# Galaxy Map
	map_button = _create_nav_button("🌌  GALAXY MAP", "Select your next target")
	map_button.pressed.connect(_on_map_pressed)
	nav.add_child(map_button)
	
	# Black Market
	market_button = _create_nav_button("💀  BLACK MARKET", "Buy and sell goods")
	market_button.pressed.connect(_on_market_pressed)
	nav.add_child(market_button)
	
	# Stash
	stash_button = _create_nav_button("📦  STASH", "Manage your storage")
	stash_button.pressed.connect(_on_stash_pressed)
	nav.add_child(stash_button)
	
	# Ship Hangar
	hangar_button = _create_nav_button("🔧  SHIP HANGAR", "Upgrade your ship")
	hangar_button.pressed.connect(_on_hangar_pressed)
	nav.add_child(hangar_button)


func _create_nav_button(text: String, tooltip: String) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.tooltip_text = tooltip
	btn.custom_minimum_size.y = 50
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12)
	style.border_width_left = 3
	style.border_color = Color(0.15, 0.18, 0.22)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 15
	btn.add_theme_stylebox_override("normal", style)
	
	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.12, 0.14, 0.18)
	hover_style.border_color = Color(0.4, 0.5, 0.6)
	btn.add_theme_stylebox_override("hover", hover_style)
	
	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(0.15, 0.18, 0.22)
	pressed_style.border_color = Color(0.9, 0.75, 0.3)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.8, 0.83, 0.87))
	
	return btn


func _build_bottom_section(parent: Control) -> void:
	var bottom = VBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	
	var bottom_margin = MarginContainer.new()
	bottom_margin.add_theme_constant_override("margin_left", 15)
	bottom_margin.add_theme_constant_override("margin_right", 15)
	bottom_margin.add_theme_constant_override("margin_bottom", 20)
	bottom_margin.add_child(bottom)
	parent.add_child(bottom_margin)
	
	# Separator
	var sep = HSeparator.new()
	bottom.add_child(sep)
	
	# Depart button
	depart_button = Button.new()
	depart_button.text = "🚀 LAUNCH MISSION"
	depart_button.custom_minimum_size.y = 55
	depart_button.disabled = true
	depart_button.pressed.connect(_on_depart_pressed)
	
	var depart_style = StyleBoxFlat.new()
	depart_style.bg_color = Color(0.2, 0.5, 0.3)
	depart_style.corner_radius_top_left = 6
	depart_style.corner_radius_top_right = 6
	depart_style.corner_radius_bottom_left = 6
	depart_style.corner_radius_bottom_right = 6
	depart_button.add_theme_stylebox_override("normal", depart_style)
	
	var depart_hover = depart_style.duplicate()
	depart_hover.bg_color = Color(0.25, 0.6, 0.35)
	depart_button.add_theme_stylebox_override("hover", depart_hover)
	
	var depart_disabled = depart_style.duplicate()
	depart_disabled.bg_color = Color(0.15, 0.18, 0.2)
	depart_button.add_theme_stylebox_override("disabled", depart_disabled)
	
	depart_button.add_theme_font_size_override("font_size", 16)
	bottom.add_child(depart_button)
	
	# Quit button
	quit_button = Button.new()
	quit_button.text = "Return to Menu"
	quit_button.custom_minimum_size.y = 35
	quit_button.pressed.connect(_on_quit_pressed)
	quit_button.add_theme_font_size_override("font_size", 12)
	quit_button.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	bottom.add_child(quit_button)


func _build_main_menu() -> void:
	main_menu = VBoxContainer.new()
	main_menu.anchor_left = 0.5
	main_menu.anchor_right = 0.5
	main_menu.anchor_top = 0.5
	main_menu.anchor_bottom = 0.5
	main_menu.offset_left = -200
	main_menu.offset_right = 200
	main_menu.offset_top = -150
	main_menu.offset_bottom = 150
	main_menu.add_theme_constant_override("separation", 20)
	content_area.add_child(main_menu)
	
	# Welcome message
	var welcome = Label.new()
	welcome.text = "Welcome back, Captain"
	welcome.add_theme_font_size_override("font_size", 28)
	welcome.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_menu.add_child(welcome)
	
	# Instruction
	var instruction = Label.new()
	instruction.text = "Use the navigation menu to prepare for your next run.\nSelect a target from the Galaxy Map when ready."
	instruction.add_theme_font_size_override("font_size", 14)
	instruction.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_menu.add_child(instruction)
	
	# Quick tips
	var tips_panel = PanelContainer.new()
	var tips_style = StyleBoxFlat.new()
	tips_style.bg_color = Color(0.08, 0.1, 0.12, 0.8)
	tips_style.border_width_left = 2
	tips_style.border_color = Color(0.3, 0.35, 0.4)
	tips_style.corner_radius_top_left = 4
	tips_style.corner_radius_top_right = 4
	tips_style.corner_radius_bottom_left = 4
	tips_style.corner_radius_bottom_right = 4
	tips_style.content_margin_left = 20
	tips_style.content_margin_right = 20
	tips_style.content_margin_top = 15
	tips_style.content_margin_bottom = 15
	tips_panel.add_theme_stylebox_override("panel", tips_style)
	main_menu.add_child(tips_panel)
	
	var tips_vbox = VBoxContainer.new()
	tips_vbox.add_theme_constant_override("separation", 8)
	tips_panel.add_child(tips_vbox)
	
	var tips_title = Label.new()
	tips_title.text = "QUICK TIPS"
	tips_title.add_theme_font_size_override("font_size", 12)
	tips_title.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	tips_vbox.add_child(tips_title)
	
	var tips = [
		"• Check the Galaxy Map for available targets",
		"• Upgrade your ship to access harder missions",
		"• Store valuable items in your Stash",
		"• Visit the Black Market for supplies"
	]
	
	for tip in tips:
		var tip_label = Label.new()
		tip_label.text = tip
		tip_label.add_theme_font_size_override("font_size", 13)
		tip_label.add_theme_color_override("font_color", Color(0.55, 0.6, 0.65))
		tips_vbox.add_child(tip_label)


func _create_sub_panels() -> void:
	# Galaxy Map
	galaxy_map = GalaxyMapScene.new()
	galaxy_map.visible = false
	galaxy_map.poi_confirmed.connect(_on_poi_confirmed)
	galaxy_map.map_closed.connect(_on_panel_closed)
	content_area.add_child(galaxy_map)
	
	# Black Market
	black_market = BlackMarketScene.new()
	black_market.visible = false
	black_market.market_closed.connect(_on_panel_closed)
	content_area.add_child(black_market)
	
	# Stash
	stash_ui = StashScene.new()
	stash_ui.visible = false
	stash_ui.stash_closed.connect(_on_panel_closed)
	content_area.add_child(stash_ui)
	
	# Ship Hangar
	ship_hangar = ShipHangarScene.new()
	ship_hangar.visible = false
	ship_hangar.hangar_closed.connect(_on_panel_closed)
	content_area.add_child(ship_hangar)


func _connect_signals() -> void:
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		game_state.credits_changed.connect(_on_credits_changed)


# ==============================================================================
# DATA
# ==============================================================================

func _update_stats_display() -> void:
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		credits_label.text = str(game_state.credits)
		ship_tier_label.text = str(game_state.ship_tier)
		runs_label.text = str(game_state.total_runs)


# ==============================================================================
# PANEL NAVIGATION
# ==============================================================================

func _show_panel(panel: Control) -> void:
	if current_panel == panel:
		return
	
	# Hide current
	if current_panel:
		current_panel.hide()
	
	# Hide main menu
	main_menu.hide()
	
	# Show new panel
	current_panel = panel
	if panel:
		panel.show()
		
		# Refresh panel data
		if panel == galaxy_map:
			galaxy_map.refresh_pois()
		elif panel == black_market:
			black_market.refresh_market()
		elif panel == stash_ui:
			stash_ui.refresh_stash()
		elif panel == ship_hangar:
			ship_hangar.refresh_hangar()


func _on_panel_closed() -> void:
	current_panel = null
	main_menu.show()
	_update_stats_display()


# ==============================================================================
# BUTTON HANDLERS
# ==============================================================================

func _on_map_pressed() -> void:
	_show_panel(galaxy_map)


func _on_market_pressed() -> void:
	_show_panel(black_market)


func _on_stash_pressed() -> void:
	_show_panel(stash_ui)


func _on_hangar_pressed() -> void:
	_show_panel(ship_hangar)


func _on_depart_pressed() -> void:
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		if not game_state.current_poi.is_empty():
			mission_launched.emit(game_state.current_poi)


func _on_quit_pressed() -> void:
	returned_to_menu.emit()


func _on_poi_confirmed(poi_id: String) -> void:
	if has_node("/root/GameState"):
		get_node("/root/GameState").select_poi(poi_id)
		depart_button.disabled = false
		depart_button.text = "🚀 LAUNCH MISSION"


func _on_credits_changed(new_amount: int) -> void:
	if credits_label:
		credits_label.text = str(new_amount)
