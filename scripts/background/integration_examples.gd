# ==============================================================================
# INTEGRATION EXAMPLE - USING DYNAMIC BACKGROUND IN MAIN GAME
# ==============================================================================
#
# This file shows how to integrate the DynamicBackground system
# into the existing CargoEscape game
#
# ==============================================================================

extends Node2D


# Example 1: Replace existing background in main scene
func replace_background() -> void:
	# Remove old background if it exists
	var old_background = $Background
	if old_background:
		old_background.visible = false  # Or queue_free() to remove entirely
	
	# Create new dynamic background
	var dynamic_bg = DynamicBackground.new()
	dynamic_bg.name = "DynamicBackground"
	dynamic_bg.base_scroll_speed = 50.0
	dynamic_bg.auto_scroll = false  # We'll control it manually
	dynamic_bg.color_theme = "Blue"
	add_child(dynamic_bg)
	
	# Store reference for later use
	set_meta("dynamic_background", dynamic_bg)


# Example 2: Sync with SpaceScrollingManager
func sync_with_scrolling_manager() -> void:
	var scroll_manager = $SpaceScrollingManager
	var dynamic_bg = get_meta("dynamic_background")
	
	if scroll_manager and dynamic_bg:
		# Update background scroll speed to match game scrolling
		var scroll_speed = scroll_manager.get_scroll_speed()
		dynamic_bg.set_scroll_speed(scroll_speed)


# Example 3: Change theme based on game area/sector
func change_theme_by_sector(sector_name: String) -> void:
	var dynamic_bg = get_meta("dynamic_background")
	if not dynamic_bg:
		return
	
	# Map sectors to themes
	var sector_themes = {
		"safe_zone": "Blue",
		"nebula_region": "Purple",
		"asteroid_belt": "Orange",
		"alien_space": "Green",
		"danger_zone": "Red"
	}
	
	if sector_themes.has(sector_name):
		dynamic_bg.change_theme(sector_themes[sector_name])


# Example 4: React to random events
func setup_event_handlers() -> void:
	var dynamic_bg = get_meta("dynamic_background")
	if not dynamic_bg:
		return
	
	# Connect to random event signal
	dynamic_bg.random_event_triggered.connect(_on_background_event)


func _on_background_event(event_type: String) -> void:
	match event_type:
		"comet":
			# Play comet sound effect
			print("Comet flyby!")
			# $SoundEffects.play("comet_whoosh")
		
		"explosion":
			# Flash screen slightly
			print("Distant explosion!")
			# $Camera.add_trauma(0.1)
		
		"ship_flyby":
			# Could show a notification
			print("Unknown ship detected!")


# Example 5: Adjust settings based on performance
func adjust_for_performance(low_end: bool) -> void:
	var dynamic_bg = get_meta("dynamic_background")
	if not dynamic_bg:
		return
	
	if low_end:
		# Reduce quality for low-end devices
		dynamic_bg.use_shaders = false
		dynamic_bg.set_layer_enabled("planets", false)
		dynamic_bg.set_layer_enabled("foreground", false)
		dynamic_bg.enable_random_events = false
		
		# Lower star density
		if dynamic_bg.layers.has("mid_stars"):
			dynamic_bg.layers["mid_stars"].set_star_density(30.0)
	else:
		# Full quality for high-end devices
		dynamic_bg.use_shaders = true
		dynamic_bg.enable_lod = true
		dynamic_bg.enable_random_events = true


# Example 6: Use in boarding scene
func setup_boarding_background() -> void:
	# For the boarding phase, you might want a static or slowly moving background
	var dynamic_bg = DynamicBackground.new()
	dynamic_bg.base_scroll_speed = 5.0  # Very slow drift
	dynamic_bg.auto_scroll = true
	dynamic_bg.color_theme = "Purple"  # Atmospheric purple for interior
	
	# Disable some layers for the interior view
	dynamic_bg.enable_planets = false
	dynamic_bg.enable_foreground = false
	dynamic_bg.enable_near_particles = false
	
	add_child(dynamic_bg)


# Example 7: Complete integration in _ready()
func _ready() -> void:
	# Setup dynamic background
	replace_background()
	setup_event_handlers()
	
	# Adjust based on settings
	var is_low_end = OS.get_processor_count() < 4  # Simple performance check
	adjust_for_performance(is_low_end)


# Example 8: Update in _process()
func _process(_delta: float) -> void:
	# Sync with scrolling manager if it exists
	sync_with_scrolling_manager()
	
	# Or sync with player movement
	# if has_node("Player"):
	#     var player = $Player
	#     var dynamic_bg = get_meta("dynamic_background")
	#     if dynamic_bg:
	#         dynamic_bg.set_scroll_speed(player.velocity.x * 0.3)


# Example 9: Handling scene transitions
func transition_to_new_area(area_name: String) -> void:
	var dynamic_bg = get_meta("dynamic_background")
	if not dynamic_bg:
		return
	
	# Change theme based on area
	change_theme_by_sector(area_name)
	
	# Maybe adjust scroll speed for dramatic effect
	if area_name == "escape_sequence":
		dynamic_bg.base_scroll_speed = 100.0  # Fast escape!
		dynamic_bg.enable_random_events = true  # More chaos!
	else:
		dynamic_bg.base_scroll_speed = 50.0  # Normal speed


# Example 10: Cleanup
func cleanup_background() -> void:
	var dynamic_bg = get_meta("dynamic_background")
	if dynamic_bg:
		dynamic_bg.queue_free()
		remove_meta("dynamic_background")
