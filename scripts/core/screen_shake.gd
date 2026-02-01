# ==============================================================================
# SCREEN SHAKE SYSTEM - CONFIGURABLE CAMERA SHAKE EFFECTS
# ==============================================================================
#
# FILE: scripts/core/screen_shake.gd
# PURPOSE: Provides a reusable, configurable screen shake system for impactful moments
#
# FEATURES:
# - Configurable intensity, duration, frequency, and decay
# - Multiple shake modes (random, perlin, trauma-based)
# - Cooldown system to prevent shake spam
# - Smooth decay curves
#
# USAGE:
# var shake_system = ScreenShake.new()
# add_child(shake_system)
# shake_system.shake(intensity, duration)
#
# ==============================================================================

extends Node
class_name ScreenShake


# ==============================================================================
# ENUMS
# ==============================================================================

enum DecayMode {
	LINEAR,      ## Linear decay over time
	EXPONENTIAL, ## Exponential falloff (starts fast, slows down)
	SMOOTH       ## Smooth curve using ease-out
}

enum ShakeMode {
	RANDOM,      ## Random offset each frame
	PERLIN,      ## Smooth perlin-like noise
	TRAUMA       ## Trauma-based shake (intensity squared for feel)
}


# ==============================================================================
# SIGNALS
# ==============================================================================

signal shake_started(intensity: float, duration: float)
signal shake_finished


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Shake Settings")
## Default shake intensity (0.0 - 1.0, scales to pixels)
@export_range(0.0, 1.0, 0.05) var default_intensity: float = 0.5

## Default shake duration in seconds
@export_range(0.1, 2.0, 0.05) var default_duration: float = 0.3

## Maximum shake offset in pixels
@export_range(1.0, 50.0, 1.0) var max_offset: float = 20.0

## Shake frequency (oscillations per second)
@export_range(1.0, 60.0, 1.0) var shake_frequency: float = 30.0

## Decay mode for shake intensity
@export var decay_mode: DecayMode = DecayMode.EXPONENTIAL

## Shake mode (visual style)
@export var shake_mode: ShakeMode = ShakeMode.RANDOM


@export_group("Cooldown")
## Minimum time between shake triggers (prevents spam)
@export_range(0.0, 1.0, 0.05) var cooldown_time: float = 0.15

## Whether to allow bypass of cooldown for critical events
@export var allow_cooldown_bypass: bool = true


# ==============================================================================
# STATE VARIABLES
# ==============================================================================

## Current shake intensity (0.0 - 1.0)
var current_intensity: float = 0.0

## Time remaining for current shake
var shake_time_remaining: float = 0.0

## Total duration of current shake (for decay calculation)
var shake_duration_total: float = 0.0

## Cooldown timer
var cooldown_timer: float = 0.0

## Current shake offset
var shake_offset: Vector2 = Vector2.ZERO

## Noise for perlin-style shake
var noise_offset: float = 0.0

## Random state for consistent randomness
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	rng.randomize()


func _process(delta: float) -> void:
	# Update cooldown
	if cooldown_timer > 0:
		cooldown_timer = maxf(0, cooldown_timer - delta)
	
	# Update shake
	if shake_time_remaining > 0:
		shake_time_remaining = maxf(0, shake_time_remaining - delta)
		_update_shake(delta)
		
		# Check if shake finished
		if shake_time_remaining <= 0:
			current_intensity = 0.0
			shake_offset = Vector2.ZERO
			shake_finished.emit()
	else:
		# No active shake
		current_intensity = 0.0
		shake_offset = Vector2.ZERO


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Trigger a screen shake effect
## @param intensity: Shake intensity (0.0 - 1.0), defaults to default_intensity
## @param duration: Shake duration in seconds, defaults to default_duration
## @param bypass_cooldown: Whether to ignore cooldown timer
func shake(intensity: float = -1.0, duration: float = -1.0, bypass_cooldown: bool = false) -> void:
	# Check cooldown
	if not bypass_cooldown and cooldown_timer > 0:
		return
	
	# Use defaults if not specified
	if intensity < 0:
		intensity = default_intensity
	if duration < 0:
		duration = default_duration
	
	# Clamp values
	intensity = clampf(intensity, 0.0, 1.0)
	duration = maxf(0.1, duration)
	
	# Set shake parameters
	current_intensity = maxf(current_intensity, intensity)  # Use max if already shaking
	shake_time_remaining = duration
	shake_duration_total = duration
	
	# Reset cooldown
	if allow_cooldown_bypass or not bypass_cooldown:
		cooldown_timer = cooldown_time
	
	# Emit signal
	shake_started.emit(intensity, duration)


## Get the current shake offset to apply to camera/nodes
func get_shake_offset() -> Vector2:
	return shake_offset


## Check if currently shaking
func is_shaking() -> bool:
	return shake_time_remaining > 0


## Stop the current shake immediately
func stop_shake() -> void:
	shake_time_remaining = 0.0
	current_intensity = 0.0
	shake_offset = Vector2.ZERO
	shake_finished.emit()


## Set shake parameters at runtime
func set_shake_parameters(
	intensity: float = -1.0,
	duration: float = -1.0,
	frequency: float = -1.0,
	max_pixels: float = -1.0
) -> void:
	if intensity >= 0:
		default_intensity = clampf(intensity, 0.0, 1.0)
	if duration >= 0:
		default_duration = maxf(0.1, duration)
	if frequency >= 0:
		shake_frequency = clampf(frequency, 1.0, 60.0)
	if max_pixels >= 0:
		max_offset = clampf(max_pixels, 1.0, 50.0)


# ==============================================================================
# INTERNAL FUNCTIONS
# ==============================================================================

## Update shake offset based on current intensity and mode
func _update_shake(delta: float) -> void:
	# Calculate decay factor
	var decay_factor := _calculate_decay()
	
	# Apply decay to intensity
	var effective_intensity := current_intensity * decay_factor
	
	# Calculate shake offset based on mode
	match shake_mode:
		ShakeMode.RANDOM:
			_update_random_shake(effective_intensity)
		ShakeMode.PERLIN:
			_update_perlin_shake(effective_intensity, delta)
		ShakeMode.TRAUMA:
			_update_trauma_shake(effective_intensity)


## Calculate decay factor based on time remaining and decay mode
func _calculate_decay() -> float:
	if shake_duration_total <= 0:
		return 0.0
	
	var progress := 1.0 - (shake_time_remaining / shake_duration_total)
	
	match decay_mode:
		DecayMode.LINEAR:
			return 1.0 - progress
		DecayMode.EXPONENTIAL:
			return exp(-progress * 4.0)  # e^(-4t) for smooth exponential decay
		DecayMode.SMOOTH:
			return 1.0 - ease(progress, -2.0)  # Ease-out curve
	
	return 1.0 - progress  # Fallback to linear


## Random shake mode - new random offset each frame
func _update_random_shake(intensity: float) -> void:
	var offset_pixels := intensity * max_offset
	shake_offset = Vector2(
		rng.randf_range(-offset_pixels, offset_pixels),
		rng.randf_range(-offset_pixels, offset_pixels)
	)


## Perlin-like shake mode - smooth noise-based movement
func _update_perlin_shake(intensity: float, delta: float) -> void:
	noise_offset += delta * shake_frequency
	
	var offset_pixels := intensity * max_offset
	
	# Use sine waves with different frequencies for smooth motion
	shake_offset = Vector2(
		sin(noise_offset * 1.3) * offset_pixels,
		sin(noise_offset * 1.7) * offset_pixels
	)


## Trauma-based shake mode - squared intensity for better feel
func _update_trauma_shake(intensity: float) -> void:
	# Square the intensity for more dramatic effect at high values
	var trauma := intensity * intensity
	var offset_pixels := trauma * max_offset
	
	shake_offset = Vector2(
		rng.randf_range(-offset_pixels, offset_pixels),
		rng.randf_range(-offset_pixels, offset_pixels)
	)


# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

## Create a screen shake instance with custom parameters
static func create_shake_instance(
	parent: Node,
	intensity: float = 0.5,
	duration: float = 0.3,
	frequency: float = 30.0,
	max_pixels: float = 20.0
) -> ScreenShake:
	var shake_system := ScreenShake.new()
	shake_system.default_intensity = intensity
	shake_system.default_duration = duration
	shake_system.shake_frequency = frequency
	shake_system.max_offset = max_pixels
	parent.add_child(shake_system)
	return shake_system
