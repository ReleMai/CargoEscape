# ==============================================================================
# SECTOR BACKGROUND THEMES
# ==============================================================================
#
# FILE: resources/backgrounds/sector_themes.gd
# PURPOSE: Defines visual themes for different game sectors (CCG, NEX, GDF, SYN, IND)
#
# FEATURES:
# - Sector-specific nebula colors and effects
# - Custom star colors per sector
# - Environmental elements (debris, ships, stations)
# - Faction-aligned visual themes
#
# ==============================================================================

class_name SectorThemes
extends RefCounted


# ==============================================================================
# SECTOR THEME DATA
# ==============================================================================

class SectorTheme:
	var sector_name: String = ""
	var faction_code: String = ""
	
	# Colors
	var nebula_colors: Array[Color] = []
	var star_colors: Array[Color] = []
	var ambient_color: Color = Color(0.02, 0.02, 0.06)
	var glow_color: Color = Color.TRANSPARENT
	
	# Environmental effects
	var has_debris: bool = false
	var has_ships: bool = false
	var has_stations: bool = false
	var has_cargo: bool = false
	var has_wrecks: bool = false
	var has_weapons_fire: bool = false
	var has_patrols: bool = false
	var has_beacons: bool = false
	var has_satellites: bool = false
	var has_energy_streams: bool = false
	var has_asteroids: bool = false
	
	# Visual density
	var debris_density: float = 0.0  # 0.0 to 1.0
	var ship_traffic: float = 0.0    # 0.0 to 1.0
	var nebula_density: float = 0.5  # 0.0 to 1.0
	
	# Atmosphere
	var atmosphere: String = "calm"  # calm, busy, dangerous, structured, chaotic
	var mood: String = "neutral"     # neutral, warm, hostile, clinical, mysterious, lonely
	
	func _init(name: String, faction: String) -> void:
		sector_name = name
		faction_code = faction


# ==============================================================================
# THEME DEFINITIONS
# ==============================================================================

static var _themes: Dictionary = {}
static var _initialized: bool = false


static func _ensure_initialized() -> void:
	if _initialized:
		return
	_initialized = true
	_define_themes()


static func _define_themes() -> void:
	# -------------------------------------------------------------------------
	# TRADING HUB (CCG TERRITORY)
	# -------------------------------------------------------------------------
	var ccg_theme = SectorTheme.new("Trading Hub", "CCG")
	
	# Warm orange/yellow nebula
	ccg_theme.nebula_colors = [
		Color(0.4, 0.25, 0.1, 0.15),   # Dark orange-brown
		Color(0.5, 0.35, 0.15, 0.18),  # Orange
		Color(0.6, 0.45, 0.2, 0.12),   # Light orange
		Color(0.55, 0.5, 0.25, 0.1),   # Yellow-orange
	]
	
	# Warm-tinted stars
	ccg_theme.star_colors = [
		Color(1.0, 0.95, 0.8),   # Warm white
		Color(1.0, 0.9, 0.7),    # Yellow-white
		Color(1.0, 0.85, 0.6),   # Orange-white
		Color(0.95, 0.8, 0.5),   # Golden
	]
	
	ccg_theme.ambient_color = Color(0.06, 0.04, 0.02)  # Warm dark
	ccg_theme.glow_color = Color(1.0, 0.84, 0.0, 0.3)  # Gold glow
	
	# Busy with ship traffic
	ccg_theme.has_ships = true
	ccg_theme.has_stations = true
	ccg_theme.has_cargo = true
	ccg_theme.ship_traffic = 0.8
	ccg_theme.nebula_density = 0.6
	
	ccg_theme.atmosphere = "busy"
	ccg_theme.mood = "warm"
	
	_themes["CCG"] = ccg_theme
	
	# -------------------------------------------------------------------------
	# DANGER ZONE (NEX TERRITORY)
	# -------------------------------------------------------------------------
	var nex_theme = SectorTheme.new("Danger Zone", "NEX")
	
	# Red/crimson nebula
	nex_theme.nebula_colors = [
		Color(0.4, 0.05, 0.05, 0.2),   # Dark red
		Color(0.6, 0.1, 0.1, 0.18),    # Crimson
		Color(0.7, 0.15, 0.1, 0.15),   # Red-orange
		Color(0.5, 0.08, 0.15, 0.12),  # Dark crimson
	]
	
	# Red-tinted stars
	nex_theme.star_colors = [
		Color(1.0, 0.9, 0.9),    # Slightly red white
		Color(1.0, 0.8, 0.8),    # Pink-white
		Color(1.0, 0.7, 0.6),    # Red-orange
		Color(0.9, 0.6, 0.6),    # Red
	]
	
	nex_theme.ambient_color = Color(0.08, 0.02, 0.02)  # Red-tinted dark
	nex_theme.glow_color = Color(0.8, 0.2, 0.2, 0.4)  # Red glow
	
	# Debris fields and destroyed ships
	nex_theme.has_debris = true
	nex_theme.has_wrecks = true
	nex_theme.has_weapons_fire = true
	nex_theme.debris_density = 0.7
	nex_theme.nebula_density = 0.7
	
	nex_theme.atmosphere = "dangerous"
	nex_theme.mood = "hostile"
	
	_themes["NEX"] = nex_theme
	
	# -------------------------------------------------------------------------
	# MILITARY SECTOR (GDF TERRITORY)
	# -------------------------------------------------------------------------
	var gdf_theme = SectorTheme.new("Military Sector", "GDF")
	
	# Blue/white clean space - less nebula, more clear
	gdf_theme.nebula_colors = [
		Color(0.1, 0.15, 0.3, 0.08),   # Dark blue
		Color(0.15, 0.2, 0.35, 0.1),   # Blue
		Color(0.2, 0.25, 0.4, 0.06),   # Light blue
		Color(0.12, 0.18, 0.32, 0.05), # Navy blue
	]
	
	# Cool blue-white stars
	gdf_theme.star_colors = [
		Color(0.9, 0.95, 1.0),   # Cool white
		Color(0.85, 0.9, 1.0),   # Blue-white
		Color(0.8, 0.85, 0.95),  # Light blue
		Color(0.95, 0.98, 1.0),  # Bright white
	]
	
	gdf_theme.ambient_color = Color(0.02, 0.03, 0.06)  # Blue-tinted dark
	gdf_theme.glow_color = Color(0.3, 0.5, 1.0, 0.25)  # Blue glow
	
	# Patrol ships and structured formations
	gdf_theme.has_ships = true
	gdf_theme.has_patrols = true
	gdf_theme.has_beacons = true
	gdf_theme.ship_traffic = 0.5
	gdf_theme.nebula_density = 0.3  # Cleaner space
	
	gdf_theme.atmosphere = "structured"
	gdf_theme.mood = "clinical"
	
	_themes["GDF"] = gdf_theme
	
	# -------------------------------------------------------------------------
	# TECH NEXUS (SYN TERRITORY)
	# -------------------------------------------------------------------------
	var syn_theme = SectorTheme.new("Tech Nexus", "SYN")
	
	# Cyan/teal glow
	syn_theme.nebula_colors = [
		Color(0.05, 0.2, 0.25, 0.15),  # Dark teal
		Color(0.1, 0.3, 0.35, 0.18),   # Teal
		Color(0.15, 0.35, 0.4, 0.12),  # Cyan
		Color(0.08, 0.25, 0.3, 0.1),   # Deep cyan
	]
	
	# Cyan-tinted stars with digital feel
	syn_theme.star_colors = [
		Color(0.7, 0.9, 1.0),    # Cyan-white
		Color(0.5, 0.85, 0.95),  # Bright cyan
		Color(0.6, 1.0, 1.0),    # Electric cyan
		Color(0.4, 0.8, 0.9),    # Deep cyan
	]
	
	syn_theme.ambient_color = Color(0.01, 0.03, 0.04)  # Cyan-tinted dark
	syn_theme.glow_color = Color(0.0, 0.85, 0.88, 0.35)  # Cyan glow
	
	# Digital artifacts and satellite arrays
	syn_theme.has_satellites = true
	syn_theme.has_energy_streams = true
	syn_theme.ship_traffic = 0.3
	syn_theme.nebula_density = 0.5
	
	syn_theme.atmosphere = "structured"
	syn_theme.mood = "mysterious"
	
	_themes["SYN"] = syn_theme
	
	# -------------------------------------------------------------------------
	# FRONTIER (IND TERRITORY)
	# -------------------------------------------------------------------------
	var ind_theme = SectorTheme.new("Frontier", "IND")
	
	# Mixed colors, chaotic
	ind_theme.nebula_colors = [
		Color(0.25, 0.2, 0.15, 0.12),  # Brown-gray
		Color(0.2, 0.25, 0.2, 0.1),    # Green-gray
		Color(0.3, 0.25, 0.3, 0.08),   # Purple-gray
		Color(0.25, 0.3, 0.25, 0.1),   # Mixed gray-green
		Color(0.35, 0.3, 0.2, 0.12),   # Dusty brown
	]
	
	# Mixed star colors
	ind_theme.star_colors = [
		Color(0.9, 0.9, 0.85),   # Dusty white
		Color(0.85, 0.9, 0.8),   # Green-white
		Color(0.9, 0.85, 0.8),   # Warm white
		Color(0.8, 0.85, 0.85),  # Gray-white
		Color(0.95, 0.9, 0.85),  # Off-white
	]
	
	ind_theme.ambient_color = Color(0.04, 0.04, 0.03)  # Neutral dark
	ind_theme.glow_color = Color(0.5, 0.8, 0.5, 0.2)  # Green glow
	
	# Asteroid belts and old equipment
	ind_theme.has_debris = true
	ind_theme.has_asteroids = true
	ind_theme.has_cargo = true
	ind_theme.debris_density = 0.6
	ind_theme.ship_traffic = 0.2
	ind_theme.nebula_density = 0.5
	
	ind_theme.atmosphere = "chaotic"
	ind_theme.mood = "lonely"
	
	_themes["IND"] = ind_theme


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Get theme by faction code (CCG, NEX, GDF, SYN, IND)
static func get_theme(faction_code: String) -> SectorTheme:
	_ensure_initialized()
	return _themes.get(faction_code)


## Get all available themes
static func get_all_themes() -> Dictionary:
	_ensure_initialized()
	return _themes.duplicate()


## Get theme names
static func get_theme_names() -> Array[String]:
	_ensure_initialized()
	var names: Array[String] = []
	for theme in _themes.values():
		names.append(theme.sector_name)
	return names


## Apply theme to a background node (works with Background or SpaceBackground)
static func apply_theme_to_background(background: Node, faction_code: String) -> void:
	var theme = get_theme(faction_code)
	if not theme:
		push_warning("SectorThemes: Unknown faction code '%s'" % faction_code)
		return
	
	# Try to apply to Background script
	if background.has_method("set_theme_colors"):
		background.set_theme_colors(theme)
		return
	
	# Apply to standard properties if they exist
	if background.has("star_colors") and not theme.star_colors.is_empty():
		background.star_colors = theme.star_colors.duplicate()
	
	if background.has("enable_nebula"):
		background.enable_nebula = theme.nebula_density > 0.1
	
	# Regenerate if possible
	if background.has_method("_generate_all_stars"):
		background._generate_all_stars()
	elif background.has_method("regenerate"):
		background.regenerate()
	
	if background.has_method("queue_redraw"):
		background.queue_redraw()


## Get a random star color from theme
static func get_random_star_color(faction_code: String, rng: RandomNumberGenerator = null) -> Color:
	var theme = get_theme(faction_code)
	if not theme or theme.star_colors.is_empty():
		return Color.WHITE
	
	if not rng:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	
	var index = rng.randi() % theme.star_colors.size()
	return theme.star_colors[index]


## Get a random nebula color from theme
static func get_random_nebula_color(faction_code: String, rng: RandomNumberGenerator = null) -> Color:
	var theme = get_theme(faction_code)
	if not theme or theme.nebula_colors.is_empty():
		return Color(0.2, 0.1, 0.3, 0.1)
	
	if not rng:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	
	var index = rng.randi() % theme.nebula_colors.size()
	return theme.nebula_colors[index]
