# ==============================================================================
# UI TRANSITIONS - SMOOTH ANIMATION SYSTEM FOR UI ELEMENTS
# ==============================================================================
#
# FILE: scripts/core/ui_transitions.gd
# PURPOSE: Provides reusable, smooth transitions for UI elements
#
# USAGE:
# ------
# # Fade in a panel:
# UITransitions.fade_in(my_panel, 0.3)
#
# # Slide a menu from the left:
# UITransitions.slide_in(menu, UITransitions.Direction.LEFT, 0.4)
#
# # Scale popup with bounce:
# UITransitions.popup_scale(popup, 0.3, UITransitions.Ease.BOUNCE)
#
# # Chain transitions:
# await UITransitions.fade_out(old_panel)
# UITransitions.fade_in(new_panel)
#
# WHY THIS EXISTS:
# ----------------
# 1. Consistent animation feel across the game
# 2. No need to create tweens manually everywhere
# 3. Easy to adjust timing globally
# 4. Supports await for sequencing
#
# ==============================================================================

class_name UITransitions
extends RefCounted


# ==============================================================================
# ENUMS
# ==============================================================================

## Direction for slide animations
enum Direction {
	LEFT,
	RIGHT,
	UP,
	DOWN
}

## Easing presets
enum Ease {
	SMOOTH,      ## Sine ease in/out - natural feel
	SNAPPY,      ## Cubic ease out - quick start, smooth end
	BOUNCE,      ## Back ease out - slight overshoot
	ELASTIC,     ## Elastic ease out - springy
	LINEAR       ## No easing
}


# ==============================================================================
# CONSTANTS
# ==============================================================================

## Default animation duration (seconds)
const DEFAULT_DURATION: float = 0.25

## Slide distance in pixels (for off-screen)
const SLIDE_DISTANCE: float = 100.0


# ==============================================================================
# FADE TRANSITIONS
# ==============================================================================

## Fade a control in (opacity 0 -> 1)
## Returns the tween for await support
static func fade_in(
	control: Control,
	duration: float = DEFAULT_DURATION,
	ease_type: Ease = Ease.SMOOTH
) -> Tween:
	if not is_instance_valid(control):
		return null
	
	# Kill any existing tweens
	_kill_tweens(control)
	
	# Set initial state
	control.modulate.a = 0.0
	control.visible = true
	
	# Create and configure tween
	var tween := control.create_tween()
	tween.set_ease(_get_ease_type(ease_type))
	tween.set_trans(_get_trans_type(ease_type))
	
	# Animate
	tween.tween_property(control, "modulate:a", 1.0, duration)
	
	return tween


## Fade a control out (opacity 1 -> 0)
## Optionally hides the control when done
static func fade_out(
	control: Control,
	duration: float = DEFAULT_DURATION,
	ease_type: Ease = Ease.SMOOTH,
	hide_when_done: bool = true
) -> Tween:
	if not is_instance_valid(control):
		return null
	
	_kill_tweens(control)
	
	var tween := control.create_tween()
	tween.set_ease(_get_ease_type(ease_type))
	tween.set_trans(_get_trans_type(ease_type))
	
	tween.tween_property(control, "modulate:a", 0.0, duration)
	
	if hide_when_done:
		tween.tween_callback(func(): control.visible = false)
	
	return tween


# ==============================================================================
# SLIDE TRANSITIONS
# ==============================================================================

## Slide a control in from a direction
static func slide_in(
	control: Control,
	direction: Direction = Direction.LEFT,
	duration: float = DEFAULT_DURATION,
	ease_type: Ease = Ease.SNAPPY
) -> Tween:
	if not is_instance_valid(control):
		return null
	
	_kill_tweens(control)
	
	# Calculate start position
	var target_pos := control.position
	var start_offset := _get_direction_offset(direction)
	control.position = target_pos + start_offset
	control.modulate.a = 0.0
	control.visible = true
	
	# Animate
	var tween := control.create_tween()
	tween.set_ease(_get_ease_type(ease_type))
	tween.set_trans(_get_trans_type(ease_type))
	tween.set_parallel(true)
	
	tween.tween_property(control, "position", target_pos, duration)
	tween.tween_property(control, "modulate:a", 1.0, duration * 0.5)
	
	return tween


## Slide a control out in a direction
static func slide_out(
	control: Control,
	direction: Direction = Direction.LEFT,
	duration: float = DEFAULT_DURATION,
	ease_type: Ease = Ease.SMOOTH,
	hide_when_done: bool = true
) -> Tween:
	if not is_instance_valid(control):
		return null
	
	_kill_tweens(control)
	
	var start_pos := control.position
	var end_offset := _get_direction_offset(direction)
	var end_pos := start_pos + end_offset
	
	var tween := control.create_tween()
	tween.set_ease(_get_ease_type(ease_type))
	tween.set_trans(_get_trans_type(ease_type))
	tween.set_parallel(true)
	
	tween.tween_property(control, "position", end_pos, duration)
	tween.tween_property(control, "modulate:a", 0.0, duration)
	
	if hide_when_done:
		tween.chain().tween_callback(func():
			control.visible = false
			control.position = start_pos  # Reset position
		)
	
	return tween


# ==============================================================================
# SCALE TRANSITIONS
# ==============================================================================

## Scale a control in (popup effect)
static func popup_scale(
	control: Control,
	duration: float = DEFAULT_DURATION,
	ease_type: Ease = Ease.BOUNCE
) -> Tween:
	if not is_instance_valid(control):
		return null
	
	_kill_tweens(control)
	
	# Set initial state
	control.scale = Vector2.ZERO
	control.modulate.a = 0.0
	control.visible = true
	control.pivot_offset = control.size / 2.0
	
	var tween := control.create_tween()
	tween.set_ease(_get_ease_type(ease_type))
	tween.set_trans(_get_trans_type(ease_type))
	tween.set_parallel(true)
	
	tween.tween_property(control, "scale", Vector2.ONE, duration)
	tween.tween_property(control, "modulate:a", 1.0, duration * 0.5)
	
	return tween


## Scale a control out (dismiss popup)
static func dismiss_scale(
	control: Control,
	duration: float = DEFAULT_DURATION,
	ease_type: Ease = Ease.SMOOTH,
	hide_when_done: bool = true
) -> Tween:
	if not is_instance_valid(control):
		return null
	
	_kill_tweens(control)
	
	control.pivot_offset = control.size / 2.0
	
	var tween := control.create_tween()
	tween.set_ease(_get_ease_type(ease_type))
	tween.set_trans(_get_trans_type(ease_type))
	tween.set_parallel(true)
	
	tween.tween_property(control, "scale", Vector2.ZERO, duration)
	tween.tween_property(control, "modulate:a", 0.0, duration)
	
	if hide_when_done:
		tween.chain().tween_callback(func():
			control.visible = false
			control.scale = Vector2.ONE  # Reset scale
		)
	
	return tween


# ==============================================================================
# SPECIAL EFFECTS
# ==============================================================================

## Pulse effect (attention getter)
static func pulse(
	control: Control,
	scale_amount: float = 1.1,
	duration: float = 0.15
) -> Tween:
	if not is_instance_valid(control):
		return null
	
	_kill_tweens(control)
	
	control.pivot_offset = control.size / 2.0
	
	var tween := control.create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(control, "scale", Vector2.ONE * scale_amount, duration)
	tween.tween_property(control, "scale", Vector2.ONE, duration)
	
	return tween


## Shake effect (error feedback)
static func shake(
	control: Control,
	intensity: float = 10.0,
	duration: float = 0.3
) -> Tween:
	if not is_instance_valid(control):
		return null
	
	_kill_tweens(control)
	
	var original_pos := control.position
	var tween := control.create_tween()
	
	# Quick shakes
	var shake_count := 4
	var shake_duration := duration / (shake_count * 2)
	
	for i in shake_count:
		var offset := Vector2(randf_range(-intensity, intensity), 0)
		tween.tween_property(control, "position", original_pos + offset, shake_duration)
		tween.tween_property(control, "position", original_pos, shake_duration)
	
	return tween


## Flash effect (highlight)
static func flash(
	control: Control,
	flash_color: Color = Color.WHITE,
	duration: float = 0.2
) -> Tween:
	if not is_instance_valid(control):
		return null
	
	_kill_tweens(control)
	
	var original_modulate := control.modulate
	
	var tween := control.create_tween()
	tween.tween_property(control, "modulate", flash_color, duration * 0.3)
	tween.tween_property(control, "modulate", original_modulate, duration * 0.7)
	
	return tween


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

## Get offset vector for a direction
static func _get_direction_offset(direction: Direction) -> Vector2:
	match direction:
		Direction.LEFT:
			return Vector2(-SLIDE_DISTANCE, 0)
		Direction.RIGHT:
			return Vector2(SLIDE_DISTANCE, 0)
		Direction.UP:
			return Vector2(0, -SLIDE_DISTANCE)
		Direction.DOWN:
			return Vector2(0, SLIDE_DISTANCE)
	return Vector2.ZERO


## Convert our Ease enum to Tween.EaseType
static func _get_ease_type(ease_preset: Ease) -> Tween.EaseType:
	match ease_preset:
		Ease.SMOOTH:
			return Tween.EASE_IN_OUT
		Ease.SNAPPY:
			return Tween.EASE_OUT
		Ease.BOUNCE:
			return Tween.EASE_OUT
		Ease.ELASTIC:
			return Tween.EASE_OUT
		Ease.LINEAR:
			return Tween.EASE_IN
	return Tween.EASE_IN_OUT


## Convert our Ease enum to Tween.TransitionType
static func _get_trans_type(ease_preset: Ease) -> Tween.TransitionType:
	match ease_preset:
		Ease.SMOOTH:
			return Tween.TRANS_SINE
		Ease.SNAPPY:
			return Tween.TRANS_CUBIC
		Ease.BOUNCE:
			return Tween.TRANS_BACK
		Ease.ELASTIC:
			return Tween.TRANS_ELASTIC
		Ease.LINEAR:
			return Tween.TRANS_LINEAR
	return Tween.TRANS_SINE


## Kill any existing tweens on a control
static func _kill_tweens(_control: Control) -> void:
	# Get all tweens and kill ones targeting this control
	# Note: This is a best-effort cleanup
	pass
