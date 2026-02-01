# ==============================================================================
# MATH UTILITIES - COMMON MATHEMATICAL FUNCTIONS FOR GAME DEVELOPMENT
# ==============================================================================
#
# FILE: scripts/core/math_utils.gd
# PURPOSE: Centralized math functions for physics, animation, and gameplay
#
# USAGE:
# ------
# # Smooth movement:
# position = MathUtils.smooth_damp(position, target, velocity, 0.3, delta)
#
# # Approach value:
# health = MathUtils.approach(health, max_health, heal_rate * delta)
#
# # Remap range:
# alpha = MathUtils.remap(distance, 0, 100, 1.0, 0.0)
#
# WHY THIS EXISTS:
# ----------------
# 1. Common calculations in one place
# 2. Consistent implementation across codebase
# 3. Well-tested and documented functions
# 4. Avoids repeating math code
#
# ==============================================================================

class_name MathUtils
extends RefCounted


# ==============================================================================
# INTERPOLATION
# ==============================================================================

## Move a value toward a target by a maximum delta
## Unlike lerp, this moves by a fixed amount, not a percentage
## Good for: constant-speed movement, timers, health bars
static func approach(current: float, target: float, max_delta: float) -> float:
	if current < target:
		return minf(current + max_delta, target)
	return maxf(current - max_delta, target)


## Move a Vector2 toward a target by a maximum delta
static func approach_vector(
	current: Vector2, 
	target: Vector2, 
	max_delta: float
) -> Vector2:
	var diff := target - current
	var dist := diff.length()
	
	if dist <= max_delta or dist == 0.0:
		return target
	
	return current + diff / dist * max_delta


## Smooth damp - smooth movement with velocity tracking
## Returns new position, updates velocity reference
## Based on Unity's SmoothDamp function
## Good for: camera follow, smooth UI movement
static func smooth_damp(
	current: float,
	target: float,
	current_velocity: float,
	smooth_time: float,
	delta: float,
	max_speed: float = INF
) -> Dictionary:
	# Clamp smooth_time to prevent division by zero
	smooth_time = maxf(0.0001, smooth_time)
	
	var omega := 2.0 / smooth_time
	var x := omega * delta
	var exp_factor := 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	
	var change := current - target
	var original_target := target
	
	# Clamp maximum speed
	var max_change := max_speed * smooth_time
	change = clampf(change, -max_change, max_change)
	target = current - change
	
	var temp := (current_velocity + omega * change) * delta
	var new_velocity := (current_velocity - omega * temp) * exp_factor
	var new_position := target + (change + temp) * exp_factor
	
	# Prevent overshooting
	if (original_target - current > 0.0) == (new_position > original_target):
		new_position = original_target
		new_velocity = (new_position - original_target) / delta
	
	return {
		"position": new_position,
		"velocity": new_velocity
	}


## Smooth damp for Vector2
static func smooth_damp_vector(
	current: Vector2,
	target: Vector2,
	current_velocity: Vector2,
	smooth_time: float,
	delta: float,
	max_speed: float = INF
) -> Dictionary:
	var result_x := smooth_damp(
		current.x, target.x, current_velocity.x, 
		smooth_time, delta, max_speed
	)
	var result_y := smooth_damp(
		current.y, target.y, current_velocity.y, 
		smooth_time, delta, max_speed
	)
	
	return {
		"position": Vector2(result_x["position"], result_y["position"]),
		"velocity": Vector2(result_x["velocity"], result_y["velocity"])
	}


## Exponential decay interpolation
## Good for: smooth following, easing toward target
## factor: 0.0 = instant, higher = slower approach
static func exp_decay(
	current: float, 
	target: float, 
	decay: float, 
	delta: float
) -> float:
	return target + (current - target) * exp(-decay * delta)


## Exponential decay for Vector2
static func exp_decay_vector(
	current: Vector2, 
	target: Vector2, 
	decay: float, 
	delta: float
) -> Vector2:
	return target + (current - target) * exp(-decay * delta)


# ==============================================================================
# REMAPPING
# ==============================================================================

## Remap a value from one range to another
## Example: remap(5, 0, 10, 0, 100) = 50
static func remap(
	value: float,
	from_min: float,
	from_max: float,
	to_min: float,
	to_max: float
) -> float:
	var from_range := from_max - from_min
	if from_range == 0.0:
		return to_min
	
	var normalized := (value - from_min) / from_range
	return to_min + normalized * (to_max - to_min)


## Remap with clamping to output range
static func remap_clamped(
	value: float,
	from_min: float,
	from_max: float,
	to_min: float,
	to_max: float
) -> float:
	var result := remap(value, from_min, from_max, to_min, to_max)
	return clampf(result, minf(to_min, to_max), maxf(to_min, to_max))


## Normalize a value within a range (0-1)
static func normalize_range(
	value: float, 
	range_min: float, 
	range_max: float
) -> float:
	var range_size := range_max - range_min
	if range_size == 0.0:
		return 0.0
	return (value - range_min) / range_size


# ==============================================================================
# ANGLES
# ==============================================================================

## Get angle between two points (radians)
static func angle_between(from: Vector2, to: Vector2) -> float:
	return (to - from).angle()


## Get shortest rotation direction between two angles
## Returns -1 (counter-clockwise), 0 (same), or 1 (clockwise)
static func rotation_direction(from_angle: float, to_angle: float) -> int:
	var diff := angle_difference(from_angle, to_angle)
	if absf(diff) < 0.001:
		return 0
	return 1 if diff > 0 else -1


## Get the shortest difference between two angles (-PI to PI)
static func angle_difference(from_angle: float, to_angle: float) -> float:
	var diff := fmod(to_angle - from_angle + PI, TAU) - PI
	return diff


## Rotate an angle toward a target by a maximum delta
static func rotate_toward(
	from_angle: float, 
	to_angle: float, 
	max_delta: float
) -> float:
	var diff := angle_difference(from_angle, to_angle)
	if absf(diff) <= max_delta:
		return to_angle
	return from_angle + signf(diff) * max_delta


# ==============================================================================
# VECTORS
# ==============================================================================

## Limit a vector's magnitude
static func limit_length(vector: Vector2, max_length: float) -> Vector2:
	if vector.length_squared() > max_length * max_length:
		return vector.normalized() * max_length
	return vector


## Get a vector's component in a direction
static func project_onto(vector: Vector2, direction: Vector2) -> Vector2:
	return direction.normalized() * vector.dot(direction.normalized())


## Reflect a vector off a surface normal
static func reflect(velocity: Vector2, normal: Vector2) -> Vector2:
	return velocity - 2.0 * velocity.dot(normal) * normal


## Dampen velocity (apply friction/drag)
static func apply_drag(velocity: Vector2, drag: float, delta: float) -> Vector2:
	var factor := 1.0 - (drag * delta)
	return velocity * clampf(factor, 0.0, 1.0)


# ==============================================================================
# EASING FUNCTIONS
# ==============================================================================
# These are common easing curves for custom animations
# t should be 0.0 to 1.0

## Linear (no easing)
static func ease_linear(t: float) -> float:
	return t


## Ease in (slow start)
static func ease_in_quad(t: float) -> float:
	return t * t


## Ease out (slow end)
static func ease_out_quad(t: float) -> float:
	return 1.0 - (1.0 - t) * (1.0 - t)


## Ease in-out (slow start and end)
static func ease_in_out_quad(t: float) -> float:
	if t < 0.5:
		return 2.0 * t * t
	return 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0


## Ease out with bounce
static func ease_out_bounce(t: float) -> float:
	const N1 := 7.5625
	const D1 := 2.75
	
	if t < 1.0 / D1:
		return N1 * t * t
	if t < 2.0 / D1:
		var t_a := t - 1.5 / D1
		return N1 * t_a * t_a + 0.75
	if t < 2.5 / D1:
		var t_b := t - 2.25 / D1
		return N1 * t_b * t_b + 0.9375
	var t_c := t - 2.625 / D1
	return N1 * t_c * t_c + 0.984375


## Ease out with slight overshoot (back)
static func ease_out_back(t: float) -> float:
	const C1 := 1.70158
	const C3 := C1 + 1.0
	return 1.0 + C3 * pow(t - 1.0, 3.0) + C1 * pow(t - 1.0, 2.0)


# ==============================================================================
# RANDOM
# ==============================================================================

## Get a random point within a circle
static func random_point_in_circle(radius: float) -> Vector2:
	var angle := randf() * TAU
	var r := radius * sqrt(randf())
	return Vector2(cos(angle), sin(angle)) * r


## Get a random point on a circle's edge
static func random_point_on_circle(radius: float) -> Vector2:
	var angle := randf() * TAU
	return Vector2(cos(angle), sin(angle)) * radius


## Get a random point within a rectangle
static func random_point_in_rect(rect: Rect2) -> Vector2:
	return Vector2(
		randf_range(rect.position.x, rect.end.x),
		randf_range(rect.position.y, rect.end.y)
	)


## Get a random direction (normalized Vector2)
static func random_direction() -> Vector2:
	var angle := randf() * TAU
	return Vector2(cos(angle), sin(angle))


## Weighted random selection from an array
## weights should be same length as items
static func weighted_random(items: Array, weights: Array):
	var total_weight := 0.0
	for w in weights:
		total_weight += w
	
	var random_point := randf() * total_weight
	var cumulative := 0.0
	
	for i in items.size():
		cumulative += weights[i]
		if random_point <= cumulative:
			return items[i]
	
	return items[-1]  # Fallback


# ==============================================================================
# COLLISION/DISTANCE
# ==============================================================================

## Check if two circles overlap
static func circles_overlap(
	pos_a: Vector2, radius_a: float,
	pos_b: Vector2, radius_b: float
) -> bool:
	var combined_radius := radius_a + radius_b
	return pos_a.distance_squared_to(pos_b) < combined_radius * combined_radius


## Get closest point on a line segment to a point
static func closest_point_on_segment(
	point: Vector2,
	segment_start: Vector2,
	segment_end: Vector2
) -> Vector2:
	var segment := segment_end - segment_start
	var length_squared := segment.length_squared()
	
	if length_squared == 0.0:
		return segment_start
	
	var t := clampf(
		(point - segment_start).dot(segment) / length_squared,
		0.0, 1.0
	)
	
	return segment_start + segment * t
