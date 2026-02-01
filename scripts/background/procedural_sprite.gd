# ==============================================================================
# PROCEDURAL SPRITE - CUSTOM NODE2D FOR DRAWING
# ==============================================================================
#
# FILE: scripts/background/procedural_sprite.gd
# PURPOSE: Simple Node2D that can draw custom shapes
#
# ==============================================================================

class_name ProceduralSprite
extends Node2D

# Drawing callback
var draw_callback: Callable

func _draw() -> void:
	if draw_callback.is_valid():
		draw_callback.call(self)

func set_draw_callback(callback: Callable) -> void:
	draw_callback = callback
	queue_redraw()
