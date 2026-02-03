# ==============================================================================
# SHIP LIGHT - INTERIOR LIGHTING FOR SHIPS
# ==============================================================================
#
# FILE: scripts/boarding/ship_light.gd
# PURPOSE: Provides ambient and point lighting for ship interiors
#
# FEATURES:
# - Different light types (ceiling, wall, emergency, console)
# - Flickering effects for damaged areas
# - Color temperature variations
# - Shadow casting for stealth gameplay
#
# ==============================================================================

class_name ShipLight
extends PointLight2D


# ==============================================================================
# ENUMS
# ==============================================================================

enum LightType {
	CEILING,     # Main room lighting
	WALL,        # Wall-mounted fixtures
	EMERGENCY,   # Red emergency lights
	CONSOLE,     # Blue console glow
	AMBIENT      # Soft ambient fill
}


# ==============================================================================
# EXPORTS
# ==============================================================================

@export var light_type: LightType = LightType.CEILING
@export var flicker_enabled: bool = false
@export var flicker_intensity: float = 0.3
@export var flicker_speed: float = 8.0


# ==============================================================================
# CONSTANTS
# ==============================================================================

const LIGHT_CONFIGS = {
	LightType.CEILING: {
		"color": Color(1.0, 0.95, 0.85, 1.0),  # Warm white
		"energy": 0.8,
		"texture_scale": 1.5,
		"shadow_enabled": true,
		"range": 300.0
	},
	LightType.WALL: {
		"color": Color(1.0, 0.9, 0.8, 1.0),  # Warm
		"energy": 0.5,
		"texture_scale": 0.8,
		"shadow_enabled": true,
		"range": 150.0
	},
	LightType.EMERGENCY: {
		"color": Color(1.0, 0.2, 0.1, 1.0),  # Red
		"energy": 0.6,
		"texture_scale": 1.0,
		"shadow_enabled": false,
		"range": 200.0
	},
	LightType.CONSOLE: {
		"color": Color(0.3, 0.7, 1.0, 1.0),  # Blue
		"energy": 0.4,
		"texture_scale": 0.5,
		"shadow_enabled": false,
		"range": 80.0
	},
	LightType.AMBIENT: {
		"color": Color(0.8, 0.85, 1.0, 1.0),  # Cool white
		"energy": 0.3,
		"texture_scale": 2.0,
		"shadow_enabled": false,
		"range": 400.0
	}
}


# ==============================================================================
# STATE
# ==============================================================================

var base_energy: float = 1.0
var flicker_time: float = 0.0
var is_on: bool = true


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_apply_light_config()
	# Only enable processing if flickering (performance optimization)
	set_process(flicker_enabled)


func _process(delta: float) -> void:
	# Only runs if flicker_enabled is true
	if not is_on:
		energy = 0.0
		return
	
	flicker_time += delta * flicker_speed
	var flicker = sin(flicker_time) * sin(flicker_time * 2.3) * sin(flicker_time * 0.7)
	energy = base_energy * (1.0 - flicker_intensity * 0.5 + flicker * flicker_intensity * 0.5)


# ==============================================================================
# CONFIGURATION
# ==============================================================================

func _apply_light_config() -> void:
	var config = LIGHT_CONFIGS.get(light_type, LIGHT_CONFIGS[LightType.CEILING])
	
	color = config.color
	base_energy = config.energy
	energy = base_energy
	texture_scale = config.texture_scale
	shadow_enabled = config.shadow_enabled
	
	# Create a simple radial gradient texture if none exists
	if not texture:
		texture = _create_light_texture()


func _create_light_texture() -> Texture2D:
	# Create a gradient texture for the light
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	
	for x in range(64):
		for y in range(64):
			var dist = Vector2(x, y).distance_to(center) / 32.0
			var alpha = clampf(1.0 - dist, 0.0, 1.0)
			# Quadratic falloff for smoother light
			alpha = alpha * alpha
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(img)


# ==============================================================================
# PUBLIC API
# ==============================================================================

func set_light_type(type: LightType) -> void:
	light_type = type
	_apply_light_config()


func turn_on() -> void:
	is_on = true


func turn_off() -> void:
	is_on = false
	energy = 0.0


func set_flickering(flicker_on: bool, intensity: float = 0.3) -> void:
	flicker_enabled = flicker_on
	flicker_intensity = intensity
	set_process(flicker_on)
	if not flicker_on:
		energy = base_energy


## Check if a position is in shadow (for stealth)
func is_in_shadow(world_pos: Vector2) -> bool:
	if not is_on:
		return true
	
	var dist = world_pos.distance_to(global_position)
	var config = LIGHT_CONFIGS.get(light_type, LIGHT_CONFIGS[LightType.CEILING])
	var light_range = config.range * texture_scale
	
	# In shadow if outside light range or energy is low
	return dist > light_range * 0.8 or energy < 0.2
