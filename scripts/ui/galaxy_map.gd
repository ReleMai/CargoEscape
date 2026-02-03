# ==============================================================================
# GALAXY MAP UI - INTERACTIVE MAP FOR POI SELECTION
# ==============================================================================
#
# FILE: scripts/ui/galaxy_map.gd
# PURPOSE: Interactive galaxy map for selecting missions/POIs
#
# FEATURES:
# - Faction regions with distinct colors
# - POI markers with difficulty indicators
# - Zoom and pan controls
# - POI information panel
# - Requirements display
#
# ==============================================================================

extends Control
class_name GalaxyMapUI


# ==============================================================================
# SIGNALS
# ==============================================================================

signal poi_selected(poi_id: String)
signal poi_confirmed(poi_id: String)
signal map_closed


# ==============================================================================
# CONSTANTS
# ==============================================================================

const MAP_SIZE := Vector2(1000, 800)
const MIN_ZOOM := 0.5
const MAX_ZOOM := 2.0


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Colors")
@export var background_color: Color = Color(0.02, 0.03, 0.05, 1.0)
@export var grid_color: Color = Color(0.1, 0.12, 0.15, 0.3)
@export var border_color: Color = Color(0.2, 0.25, 0.3, 1.0)
@export var selected_color: Color = Color(1.0, 0.85, 0.0, 1.0)
@export var hideout_color: Color = Color(0.3, 0.9, 0.4, 1.0)


# ==============================================================================
# STATE
# ==============================================================================

var zoom: float = 1.0
var pan_offset: Vector2 = Vector2.ZERO
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO

var pois: Array = []
var selected_poi = null
var hovered_poi = null
var hideout_position: Vector2 = Vector2(500, 400)

# UI References
var map_container: Control = null
var info_panel: PanelContainer = null
var close_button: Button = null
var launch_button: Button = null


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_build_ui()
	_load_pois()


func _build_ui() -> void:
	# Main container
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Background
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = background_color
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	add_child(bg)
	
	# Map viewport container
	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 300)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	
	map_container = Control.new()
	map_container.name = "MapContainer"
	map_container.clip_contents = true
	margin.add_child(map_container)
	
	# Map drawing area
	var map_area = Control.new()
	map_area.name = "MapArea"
	map_area.anchor_right = 1.0
	map_area.anchor_bottom = 1.0
	map_area.mouse_filter = Control.MOUSE_FILTER_STOP
	map_area.gui_input.connect(_on_map_input)
	map_area.draw.connect(_on_map_draw.bind(map_area))
	map_container.add_child(map_area)
	
	# Title
	var title = Label.new()
	title.name = "Title"
	title.text = "GALAXY MAP"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
	title.position = Vector2(20, 15)
	add_child(title)
	
	# Info panel on right side
	_build_info_panel()
	
	# Close button
	close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(40, 40)
	close_button.anchor_left = 1.0
	close_button.anchor_right = 1.0
	close_button.offset_left = -60
	close_button.offset_right = -20
	close_button.offset_top = 15
	close_button.offset_bottom = 55
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)


func _build_info_panel() -> void:
	info_panel = PanelContainer.new()
	info_panel.name = "InfoPanel"
	info_panel.anchor_left = 1.0
	info_panel.anchor_right = 1.0
	info_panel.offset_left = -280
	info_panel.offset_right = -20
	info_panel.offset_top = 60
	info_panel.anchor_bottom = 1.0
	info_panel.offset_bottom = -20
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = border_color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	info_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	info_panel.add_child(vbox)
	
	# POI name
	var name_label = Label.new()
	name_label.name = "POIName"
	name_label.text = "Select a Target"
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)
	
	# Faction
	var faction_label = Label.new()
	faction_label.name = "Faction"
	faction_label.text = ""
	faction_label.add_theme_font_size_override("font_size", 12)
	faction_label.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	vbox.add_child(faction_label)
	
	# Separator
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)
	
	# Description
	var desc_label = Label.new()
	desc_label.name = "Description"
	desc_label.text = "Click on a POI marker to view details."
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.72, 0.75))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size.y = 60
	vbox.add_child(desc_label)
	
	# Separator
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	# Stats grid
	var stats_grid = GridContainer.new()
	stats_grid.name = "StatsGrid"
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 5)
	vbox.add_child(stats_grid)
	
	_add_stat_row(stats_grid, "Difficulty:", "---", "Difficulty")
	_add_stat_row(stats_grid, "Enemies:", "---", "Enemies")
	_add_stat_row(stats_grid, "Time Limit:", "---", "TimeLimit")
	_add_stat_row(stats_grid, "Base Reward:", "---", "Reward")
	_add_stat_row(stats_grid, "Ship Tier Required:", "---", "ShipTier")
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)
	
	# Requirements warning
	var req_label = Label.new()
	req_label.name = "Requirements"
	req_label.text = ""
	req_label.add_theme_font_size_override("font_size", 12)
	req_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	req_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(req_label)
	
	# Launch button
	launch_button = Button.new()
	launch_button.name = "LaunchButton"
	launch_button.text = "LAUNCH MISSION"
	launch_button.custom_minimum_size = Vector2(0, 45)
	launch_button.disabled = true
	launch_button.pressed.connect(_on_launch_pressed)
	vbox.add_child(launch_button)
	
	add_child(info_panel)


func _add_stat_row(grid: GridContainer, label_text: String, value_text: String, value_name: String) -> void:
	var label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	grid.add_child(label)
	
	var value = Label.new()
	value.name = value_name + "Value"
	value.text = value_text
	value.add_theme_font_size_override("font_size", 12)
	value.add_theme_color_override("font_color", Color(0.85, 0.87, 0.9))
	grid.add_child(value)


func _load_pois() -> void:
	# Get POIs from GameState if available
	if has_node("/root/GameState"):
		var game_state = get_node("/root/GameState")
		pois = game_state.get_active_pois()
	else:
		# Fallback to templates
		pois = GalaxyData.get_poi_templates()


# ==============================================================================
# INPUT
# ==============================================================================

func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_click(event.position)
			dragging = false
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				dragging = true
				drag_start = event.position
			else:
				dragging = false
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at(event.position, 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at(event.position, 0.9)
	
	elif event is InputEventMouseMotion:
		if dragging:
			pan_offset += event.relative
			map_container.get_child(0).queue_redraw()
		else:
			_update_hover(event.position)


func _zoom_at(pos: Vector2, factor: float) -> void:
	var old_zoom = zoom
	zoom = clampf(zoom * factor, MIN_ZOOM, MAX_ZOOM)
	
	# Adjust pan to zoom towards mouse position
	if zoom != old_zoom:
		var zoom_change = zoom / old_zoom
		pan_offset = pos - (pos - pan_offset) * zoom_change
		map_container.get_child(0).queue_redraw()


func _handle_click(pos: Vector2) -> void:
	var map_pos = _screen_to_map(pos)
	
	# Check POI clicks
	for poi in pois:
		if poi.position.distance_to(map_pos) < 20 / zoom:
			_select_poi(poi)
			return
	
	# Click on empty space deselects
	_select_poi(null)


func _update_hover(pos: Vector2) -> void:
	var map_pos = _screen_to_map(pos)
	var new_hover = null
	
	for poi in pois:
		if poi.position.distance_to(map_pos) < 20 / zoom:
			new_hover = poi
			break
	
	if new_hover != hovered_poi:
		hovered_poi = new_hover
		map_container.get_child(0).queue_redraw()


func _screen_to_map(screen_pos: Vector2) -> Vector2:
	var container_size = map_container.size
	var center = container_size / 2.0
	return (screen_pos - center - pan_offset) / zoom + MAP_SIZE / 2.0


func _map_to_screen(map_pos: Vector2) -> Vector2:
	var container_size = map_container.size
	var center = container_size / 2.0
	return (map_pos - MAP_SIZE / 2.0) * zoom + center + pan_offset


# ==============================================================================
# DRAWING
# ==============================================================================

func _on_map_draw(control: Control) -> void:
	var size = control.size
	var center = size / 2.0
	
	# Draw grid
	_draw_grid(control, center)
	
	# Draw regions
	_draw_regions(control, center)
	
	# Draw connections (optional)
	_draw_connections(control, center)
	
	# Draw hideout
	_draw_hideout(control, center)
	
	# Draw POIs
	_draw_pois(control, center)
	
	# Draw legend
	_draw_legend(control)


func _draw_grid(control: Control, center: Vector2) -> void:
	var grid_spacing = 100.0 * zoom
	var start_x = fmod(center.x + pan_offset.x, grid_spacing)
	var start_y = fmod(center.y + pan_offset.y, grid_spacing)
	
	# Vertical lines
	var x = start_x
	while x < control.size.x:
		control.draw_line(Vector2(x, 0), Vector2(x, control.size.y), grid_color, 1.0)
		x += grid_spacing
	
	# Horizontal lines
	var y = start_y
	while y < control.size.y:
		control.draw_line(Vector2(0, y), Vector2(control.size.x, y), grid_color, 1.0)
		y += grid_spacing


func _draw_regions(control: Control, _center: Vector2) -> void:
	for region in GalaxyData.get_all_regions():
		var screen_pos = _map_to_screen(region.center)
		var radius = region.radius * zoom
		
		# Draw region fill
		control.draw_circle(screen_pos, radius, region.color)
		
		# Draw region border
		var border_col = Color(region.color.r, region.color.g, region.color.b, 0.6)
		_draw_circle_outline(control, screen_pos, radius, border_col, 2.0)
		
		# Draw region name
		if zoom > 0.6:
			var font = ThemeDB.fallback_font
			var text_pos = screen_pos + Vector2(-50, -radius - 15)
			control.draw_string(font, text_pos, region.name, HORIZONTAL_ALIGNMENT_CENTER, 100, 11, Color(0.7, 0.75, 0.8, 0.8))


func _draw_circle_outline(control: Control, pos: Vector2, radius: float, color: Color, width: float) -> void:
	var points = PackedVector2Array()
	var segments = 32
	for i in range(segments + 1):
		var angle = TAU * i / segments
		points.append(pos + Vector2(cos(angle), sin(angle)) * radius)
	control.draw_polyline(points, color, width, true)


func _draw_connections(control: Control, _center: Vector2) -> void:
	# Draw travel lanes between regions (optional visual)
	var regions = GalaxyData.get_all_regions()
	for i in range(regions.size()):
		for j in range(i + 1, regions.size()):
			var r1 = regions[i]
			var r2 = regions[j]
			var dist = r1.center.distance_to(r2.center)
			if dist < 400:
				var p1 = _map_to_screen(r1.center)
				var p2 = _map_to_screen(r2.center)
				control.draw_line(p1, p2, Color(0.15, 0.18, 0.22, 0.3), 1.0)


func _draw_hideout(control: Control, _center: Vector2) -> void:
	var screen_pos = _map_to_screen(hideout_position)
	
	# Draw hideout marker
	var size = 12.0 * zoom
	
	# Glow
	control.draw_circle(screen_pos, size + 4, Color(hideout_color.r, hideout_color.g, hideout_color.b, 0.2))
	
	# Main marker
	control.draw_circle(screen_pos, size, hideout_color)
	control.draw_circle(screen_pos, size * 0.6, Color(1, 1, 1, 0.9))
	
	# Label
	if zoom > 0.7:
		var font = ThemeDB.fallback_font
		control.draw_string(font, screen_pos + Vector2(-25, size + 15), "HIDEOUT", HORIZONTAL_ALIGNMENT_CENTER, 50, 10, hideout_color)


func _draw_pois(control: Control, _center: Vector2) -> void:
	for poi in pois:
		var screen_pos = _map_to_screen(poi.position)
		var size = 8.0 * zoom
		
		# Get difficulty color
		var diff_color = GalaxyData.get_difficulty_color(poi.difficulty)
		
		# Check if this POI is available
		var available = poi.available if "available" in poi else true
		if not available:
			diff_color = diff_color.darkened(0.5)
		
		# Hover effect
		if poi == hovered_poi:
			control.draw_circle(screen_pos, size + 6, Color(1, 1, 1, 0.2))
		
		# Selection effect
		if poi == selected_poi:
			var pulse = (sin(Time.get_ticks_msec() * 0.005) + 1) * 0.5
			control.draw_circle(screen_pos, size + 4 + pulse * 3, selected_color)
		
		# Completed marker
		if poi.completed:
			control.draw_circle(screen_pos, size + 2, Color(0.3, 0.3, 0.3, 0.8))
		
		# Main marker
		control.draw_circle(screen_pos, size, diff_color)
		
		# Inner detail based on type
		_draw_poi_icon(control, screen_pos, size * 0.5, poi.poi_type)
		
		# Name label
		if zoom > 0.8 and (poi == hovered_poi or poi == selected_poi):
			var font = ThemeDB.fallback_font
			control.draw_string(font, screen_pos + Vector2(-40, -size - 8), poi.name, HORIZONTAL_ALIGNMENT_CENTER, 80, 10, Color(0.9, 0.92, 0.95))


func _draw_poi_icon(control: Control, pos: Vector2, size: float, poi_type: int) -> void:
	var icon_color = Color(0.1, 0.1, 0.1, 0.8)
	
	match poi_type:
		GalaxyData.POIType.CARGO_SHIP, GalaxyData.POIType.FREIGHTER:
			# Rectangle for ships
			control.draw_rect(Rect2(pos - Vector2(size, size/2), Vector2(size*2, size)), icon_color)
		GalaxyData.POIType.STATION, GalaxyData.POIType.RESEARCH_FACILITY:
			# Diamond for stations
			var points = PackedVector2Array([
				pos + Vector2(0, -size),
				pos + Vector2(size, 0),
				pos + Vector2(0, size),
				pos + Vector2(-size, 0)
			])
			control.draw_colored_polygon(points, icon_color)
		GalaxyData.POIType.DERELICT:
			# X for derelicts
			control.draw_line(pos - Vector2(size, size), pos + Vector2(size, size), icon_color, 2)
			control.draw_line(pos - Vector2(-size, size), pos + Vector2(-size, size), icon_color, 2)
		GalaxyData.POIType.MILITARY_VESSEL:
			# Triangle for military
			var points = PackedVector2Array([
				pos + Vector2(0, -size),
				pos + Vector2(size, size),
				pos + Vector2(-size, size)
			])
			control.draw_colored_polygon(points, icon_color)
		_:
			# Circle for others
			control.draw_circle(pos, size * 0.6, icon_color)


func _draw_legend(control: Control) -> void:
	var pos = Vector2(15, control.size.y - 100)
	var font = ThemeDB.fallback_font
	
	# Background
	control.draw_rect(Rect2(pos - Vector2(5, 5), Vector2(120, 95)), Color(0, 0, 0, 0.5))
	
	# Title
	control.draw_string(font, pos, "DIFFICULTY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.75, 0.8))
	
	# Legend items
	var items = [
		["Easy", GalaxyData.Difficulty.EASY],
		["Medium", GalaxyData.Difficulty.MEDIUM],
		["Hard", GalaxyData.Difficulty.HARD],
		["Extreme", GalaxyData.Difficulty.EXTREME],
		["Nightmare", GalaxyData.Difficulty.NIGHTMARE]
	]
	
	for i in range(items.size()):
		var item_pos = pos + Vector2(0, 15 + i * 15)
		var color = GalaxyData.get_difficulty_color(items[i][1])
		control.draw_circle(item_pos + Vector2(5, -3), 4, color)
		control.draw_string(font, item_pos + Vector2(15, 0), items[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.65, 0.7))


# ==============================================================================
# POI SELECTION
# ==============================================================================

func _select_poi(poi) -> void:
	selected_poi = poi
	_update_info_panel()
	map_container.get_child(0).queue_redraw()
	
	if poi:
		poi_selected.emit(poi.id)


func _update_info_panel() -> void:
	if not info_panel:
		return
	
	var vbox = info_panel.get_child(0)
	var name_label = vbox.get_node("POIName")
	var faction_label = vbox.get_node("Faction")
	var desc_label = vbox.get_node("Description")
	var stats_grid = vbox.get_node("StatsGrid")
	var req_label = vbox.get_node("Requirements")
	
	if not selected_poi:
		name_label.text = "Select a Target"
		faction_label.text = ""
		desc_label.text = "Click on a POI marker to view details."
		_clear_stats(stats_grid)
		req_label.text = ""
		launch_button.disabled = true
		return
	
	name_label.text = selected_poi.name
	faction_label.text = _get_faction_name(selected_poi.faction)
	desc_label.text = selected_poi.description
	
	# Update stats
	_update_stat(stats_grid, "DifficultyValue", GalaxyData.get_difficulty_name(selected_poi.difficulty), GalaxyData.get_difficulty_color(selected_poi.difficulty))
	_update_stat(stats_grid, "EnemiesValue", str(selected_poi.get_enemy_count()) + " approx.")
	_update_stat(stats_grid, "TimeLimitValue", str(int(selected_poi.get_time_limit())) + "s")
	_update_stat(stats_grid, "RewardValue", str(selected_poi.base_credits) + " credits")
	_update_stat(stats_grid, "ShipTierValue", "Tier " + str(selected_poi.min_ship_tier))
	
	# Check requirements
	var available = selected_poi.available if "available" in selected_poi else true
	if available:
		req_label.text = ""
		launch_button.disabled = selected_poi.completed
		launch_button.text = "COMPLETED" if selected_poi.completed else "LAUNCH MISSION"
	else:
		req_label.text = "⚠ Requirements not met\nUpgrade your ship to Tier " + str(selected_poi.min_ship_tier)
		launch_button.disabled = true
		launch_button.text = "UNAVAILABLE"


func _clear_stats(grid: GridContainer) -> void:
	for child in grid.get_children():
		if "Value" in child.name:
			child.text = "---"
			child.add_theme_color_override("font_color", Color(0.85, 0.87, 0.9))


func _update_stat(grid: GridContainer, value_name: String, text: String, color: Color = Color(0.85, 0.87, 0.9)) -> void:
	var label = grid.get_node_or_null(value_name)
	if label:
		label.text = text
		label.add_theme_color_override("font_color", color)


func _get_faction_name(faction_code: String) -> String:
	match faction_code:
		"CCG": return "Civilian Commerce Guild"
		"NEX": return "Nexus Corporation"
		"GDF": return "Galactic Defense Force"
		"SYN": return "Shadow Syndicate"
		"IND": return "Independent Traders"
		"": return "Unclaimed"
	return faction_code


# ==============================================================================
# BUTTON HANDLERS
# ==============================================================================

func _on_close_pressed() -> void:
	map_closed.emit()
	hide()


func _on_launch_pressed() -> void:
	if selected_poi and not selected_poi.completed:
		poi_confirmed.emit(selected_poi.id)


# ==============================================================================
# PUBLIC API
# ==============================================================================

func refresh_pois() -> void:
	_load_pois()
	_select_poi(null)
	map_container.get_child(0).queue_redraw()


func center_on_hideout() -> void:
	pan_offset = Vector2.ZERO
	zoom = 1.0
	map_container.get_child(0).queue_redraw()
