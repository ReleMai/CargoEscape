# ==============================================================================
# PARALLAX LAYER - SINGLE SCROLLING LAYER WITH SHADER SUPPORT
# ==============================================================================
#
# FILE: scripts/background/parallax_layer.gd
# PURPOSE: Represents a single parallax scrolling layer in the background system
#
# FEATURES:
# - Configurable scroll speed multiplier
# - Shader-based rendering for stars
# - Support for procedural content
# - Color rect or sprite-based rendering
# - Automatic wrapping/tiling
#
# ==============================================================================

class_name ParallaxLayer
extends Node2D


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Layer Settings")

## Speed multiplier for this layer (relative to base speed)
## Lower values = farther away (slower)
## Higher values = closer (faster)
@export var speed_multiplier: float = 1.0

## Z-index for draw order
@export var draw_order: int = 0

## Layer opacity
@export_range(0.0, 1.0) var opacity: float = 1.0


@export_group("Content Type")

## Type of content for this layer
@export_enum("Stars", "Nebula", "Particles", "Custom") var content_type: String = "Stars"

## Use shader for rendering (recommended for stars)
@export var use_shader: bool = true

## Shader to use (if use_shader is true)
@export var layer_shader: Shader


@export_group("Star Settings")

## Star density (for shader-based stars)
@export_range(0.0, 100.0) var star_density: float = 50.0

## Star size range
@export var star_size_min: float = 0.5
@export var star_size_max: float = 3.0

## Star color
@export var star_color: Color = Color.WHITE

## Color variation amount
@export_range(0.0, 1.0) var color_variation: float = 0.2


@export_group("Animation")

## Enable twinkling animation
@export var enable_twinkle: bool = true

## Twinkle speed
@export_range(0.0, 10.0) var twinkle_speed: float = 2.0

## Twinkle amount
@export_range(0.0, 1.0) var twinkle_amount: float = 0.3


# ==============================================================================
# STATE
# ==============================================================================

## Current scroll offset
var scroll_offset: Vector2 = Vector2.ZERO

## Material for shader rendering
var shader_material: ShaderMaterial = null

## ColorRect for rendering
var color_rect: ColorRect = null

## Viewport size
var viewport_size: Vector2 = Vector2.ZERO


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	viewport_size = get_viewport_rect().size
	z_index = draw_order
	
	# Setup rendering based on content type
	_setup_rendering()


func _process(_delta: float) -> void:
	# Update shader uniforms if using shader
	if use_shader and shader_material:
		shader_material.set_shader_parameter("scroll_offset", scroll_offset)


# ==============================================================================
# SETUP
# ==============================================================================

func _setup_rendering() -> void:
	if use_shader:
		_setup_shader_rendering()
	else:
		_setup_procedural_rendering()


func _setup_shader_rendering() -> void:
	# Create ColorRect for shader rendering
	color_rect = ColorRect.new()
	color_rect.size = viewport_size
	color_rect.position = Vector2.ZERO
	add_child(color_rect)
	
	# Load or use provided shader
	var shader: Shader = layer_shader
	if not shader:
		# Try to load default star field shader
		shader = load("res://shaders/star_field.gdshader")
	
	if shader:
		# Create shader material
		shader_material = ShaderMaterial.new()
		shader_material.shader = shader
		
		# Set initial parameters
		_update_shader_parameters()
		
		# Apply material to ColorRect
		color_rect.material = shader_material
	else:
		push_warning("[ParallaxLayer] No shader available for layer")


func _setup_procedural_rendering() -> void:
	# Fallback to simple procedural rendering
	# This would draw stars/particles using _draw()
	queue_redraw()


func _update_shader_parameters() -> void:
	if not shader_material:
		return
	
	# Set shader parameters based on layer settings
	shader_material.set_shader_parameter("star_density", star_density)
	shader_material.set_shader_parameter("star_size_min", star_size_min)
	shader_material.set_shader_parameter("star_size_max", star_size_max)
	shader_material.set_shader_parameter("base_color", Vector3(star_color.r, star_color.g, star_color.b))
	shader_material.set_shader_parameter("color_variation", color_variation)
	shader_material.set_shader_parameter("twinkle_speed", twinkle_speed if enable_twinkle else 0.0)
	shader_material.set_shader_parameter("twinkle_amount", twinkle_amount)
	shader_material.set_shader_parameter("layer_depth", speed_multiplier)
	
	# Set scroll offset
	shader_material.set_shader_parameter("scroll_offset", scroll_offset)


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Update scroll position based on movement delta
func update_scroll(delta_position: Vector2) -> void:
	scroll_offset += delta_position * speed_multiplier
	
	# Update shader if using shader rendering
	if shader_material:
		shader_material.set_shader_parameter("scroll_offset", scroll_offset)


## Set the scroll offset directly
func set_scroll_offset(offset: Vector2) -> void:
	scroll_offset = offset
	
	if shader_material:
		shader_material.set_shader_parameter("scroll_offset", scroll_offset)


## Reset scroll position
func reset_scroll() -> void:
	scroll_offset = Vector2.ZERO
	
	if shader_material:
		shader_material.set_shader_parameter("scroll_offset", scroll_offset)


## Update layer opacity
func set_layer_opacity(new_opacity: float) -> void:
	opacity = clamp(new_opacity, 0.0, 1.0)
	modulate.a = opacity


## Get current scroll offset
func get_scroll_offset() -> Vector2:
	return scroll_offset


## Update star density (runtime)
func set_star_density(density: float) -> void:
	star_density = density
	if shader_material:
		shader_material.set_shader_parameter("star_density", density)


## Update star color (runtime)
func set_star_color(color: Color) -> void:
	star_color = color
	if shader_material:
		shader_material.set_shader_parameter("base_color", Vector3(color.r, color.g, color.b))


## Resize layer to match viewport
func resize_to_viewport() -> void:
	viewport_size = get_viewport_rect().size
	if color_rect:
		color_rect.size = viewport_size
