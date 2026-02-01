# ==============================================================================
# REPEATER DECORATOR
# ==============================================================================
#
# FILE: scripts/ai/bt_repeater.gd
# PURPOSE: Repeats child node execution
#
# BEHAVIOR:
# ---------
# - Repeats child N times or infinitely
# - Returns RUNNING while repeating
# - Returns SUCCESS when all repetitions complete
#
# ==============================================================================

extends BTDecorator
class_name BTRepeater


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Number of times to repeat (-1 for infinite)
var repeat_count: int = -1

## Current repetition
var current_count: int = 0


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _init(count: int = -1):
	repeat_count = count


# ==============================================================================
# EXECUTION
# ==============================================================================

func tick(delta: float) -> Status:
	if not child_node:
		return Status.FAILURE
	
	# Check if we've reached repeat limit
	if repeat_count > 0 and current_count >= repeat_count:
		reset()
		return Status.SUCCESS
	
	var status = child_node.tick(delta)
	
	match status:
		Status.SUCCESS, Status.FAILURE:
			# Child finished, increment counter and reset child
			current_count += 1
			child_node.reset()
			
			# Check if we've completed all repetitions
			if repeat_count > 0 and current_count >= repeat_count:
				reset()
				return Status.SUCCESS
			
			# Continue repeating
			return Status.RUNNING
		Status.RUNNING:
			return Status.RUNNING
	
	return Status.RUNNING


func reset() -> void:
	super.reset()
	current_count = 0
