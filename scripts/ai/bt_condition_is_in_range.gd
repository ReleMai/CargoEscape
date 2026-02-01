# ==============================================================================
# CONDITION: IS IN RANGE
# ==============================================================================
#
# FILE: scripts/ai/bt_condition_is_in_range.gd
# PURPOSE: Check if target is within specified range
#
# BEHAVIOR:
# ---------
# - Returns SUCCESS if target is in range
# - Returns FAILURE otherwise
#
# ==============================================================================

extends BTNode
class_name BTConditionIsInRange


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Range to check
var check_range: float = 100.0


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _init(p_range: float = 100.0):
	check_range = p_range


# ==============================================================================
# EXECUTION
# ==============================================================================

func tick(delta: float) -> Status:
	if not agent:
		return Status.FAILURE
	
	# Get target from blackboard
	var target = blackboard.get("target", null)
	if not target or not is_instance_valid(target):
		return Status.FAILURE
	
	# Check distance
	var distance = agent.global_position.distance_to(target.global_position)
	if distance <= check_range:
		return Status.SUCCESS
	
	return Status.FAILURE
