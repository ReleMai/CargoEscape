# ==============================================================================
# COLORBLIND FILTER OVERLAY
# ==============================================================================
#
# FILE: scripts/core/colorblind_overlay.gd
# PURPOSE: Applies colorblind shader to the entire screen
#
# ==============================================================================

extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

var shader_material: ShaderMaterial = null

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Create shader material
	var shader = preload("res://scripts/core/shaders/colorblind_filter.gdshader")
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	
	# Apply to ColorRect
	if color_rect:
		color_rect.material = shader_material
	
	# Listen for accessibility changes
	AccessibilityManager.colorblind_mode_changed.connect(_on_colorblind_mode_changed)
	
	# Apply current mode
	_update_shader()


func _on_colorblind_mode_changed(_mode) -> void:
	_update_shader()


func _update_shader() -> void:
	if not shader_material:
		return
	
	var mode = AccessibilityManager.get_colorblind_mode()
	shader_material.set_shader_parameter("mode", mode)
