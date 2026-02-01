# ==============================================================================
# CONDITION: IS LOW HEALTH
# ==============================================================================
#
# FILE: scripts/ai/bt_condition_is_low_health.gd
# PURPOSE: Check if agent health is below threshold
#
# BEHAVIOR:
# ---------
# - Returns SUCCESS if health is below threshold
# - Returns FAILURE otherwise
#
# ==============================================================================

extends BTNode
class_name BTConditionIsLowHealth


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Health threshold (percentage)
var health_threshold: float = 0.3


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _init(p_threshold: float = 0.3):
	health_threshold = p_threshold


# ==============================================================================
# EXECUTION
# ==============================================================================

func tick(delta: float) -> Status:
	if not agent:
		return Status.FAILURE
	
	# Check if agent has health properties
	if not agent.has("current_health") or not agent.has("max_health"):
		return Status.FAILURE
	
	# Calculate health percentage
	var health_percent = agent.current_health / agent.max_health
	
	# Check if below threshold
	if health_percent <= health_threshold:
		return Status.SUCCESS
	
	return Status.FAILURE
