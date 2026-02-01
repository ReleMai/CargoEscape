# ==============================================================================
# SECTOR THEME DEMO
# ==============================================================================
#
# FILE: resources/backgrounds/sector_theme_demo.gd
# PURPOSE: Demo script to showcase all sector themes
#
# This script cycles through all 5 sector themes to demonstrate
# the visual differences between sectors.
#
# ==============================================================================

extends Node2D


@export var cycle_interval: float = 5.0  # Seconds between theme changes
@export var show_labels: bool = true


var background_node: Node2D
var current_theme_index: int = 0
var timer: float = 0.0
var faction_codes: Array[String] = ["CCG", "NEX", "GDF", "SYN", "IND"]
var theme_names: Dictionary = {
	"CCG": "Trading Hub (CCG)",
	"NEX": "Danger Zone (NEX)",
	"GDF": "Military Sector (GDF)",
	"SYN": "Tech Nexus (SYN)",
	"IND": "Frontier (IND)"
}


func _ready() -> void:
	# Create background using sector_background script
	background_node = Node2D.new()
	
	# Load and attach the sector background script
	var script = load("res://resources/backgrounds/sector_background.gd")
	if script:
		background_node.set_script(script)
		add_child(background_node)
		
		# Set initial theme
		if background_node.has_method("set_sector_theme"):
			background_node.set_sector_theme(faction_codes[0])
	
	print("=== Sector Theme Demo Started ===")
	print("Cycling through themes every %.1f seconds" % cycle_interval)
	_print_current_theme()


func _process(delta: float) -> void:
	timer += delta
	
	if timer >= cycle_interval:
		timer = 0.0
		_cycle_theme()


func _draw() -> void:
	if not show_labels:
		return
	
	# Draw theme name at top of screen
	var screen_size = get_viewport_rect().size
	var theme_name = theme_names.get(faction_codes[current_theme_index], "Unknown")
	
	# Draw background for text
	var text_bg_rect = Rect2(10, 10, 400, 40)
	draw_rect(text_bg_rect, Color(0, 0, 0, 0.7))
	
	# Draw theme name (note: using draw_string requires a font, so we skip it for now)
	# Instead, use print statements to console


func _cycle_theme() -> void:
	current_theme_index = (current_theme_index + 1) % faction_codes.size()
	
	if background_node and background_node.has_method("set_sector_theme"):
		background_node.set_sector_theme(faction_codes[current_theme_index])
	
	_print_current_theme()
	queue_redraw()


func _print_current_theme() -> void:
	var faction = faction_codes[current_theme_index]
	var name = theme_names.get(faction, "Unknown")
	var theme = SectorThemes.get_theme(faction)
	
	if theme:
		print("\n=== %s ===" % name)
		print("  Faction: %s" % faction)
		print("  Atmosphere: %s" % theme.atmosphere)
		print("  Mood: %s" % theme.mood)
		print("  Nebula Density: %.1f" % theme.nebula_density)
		print("  Ship Traffic: %.1f" % theme.ship_traffic)
		
		var features: Array[String] = []
		if theme.has_cargo: features.append("cargo")
		if theme.has_stations: features.append("stations")
		if theme.has_debris: features.append("debris")
		if theme.has_wrecks: features.append("wrecks")
		if theme.has_weapons_fire: features.append("weapons")
		if theme.has_patrols: features.append("patrols")
		if theme.has_beacons: features.append("beacons")
		if theme.has_satellites: features.append("satellites")
		if theme.has_asteroids: features.append("asteroids")
		
		if not features.is_empty():
			print("  Features: %s" % ", ".join(features))


func _input(event: InputEvent) -> void:
	# Press SPACE to manually cycle themes
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_cycle_theme()
	
	# Press 1-5 to jump to specific theme
	if event is InputEventKey and event.pressed:
		var key = event.keycode
		if key >= KEY_1 and key <= KEY_5:
			var index = key - KEY_1
			if index < faction_codes.size():
				current_theme_index = index
				if background_node and background_node.has_method("set_sector_theme"):
					background_node.set_sector_theme(faction_codes[current_theme_index])
				_print_current_theme()
				queue_redraw()
