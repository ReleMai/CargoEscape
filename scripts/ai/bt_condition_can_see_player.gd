# ==============================================================================
# CONDITION: CAN SEE PLAYER
# ==============================================================================
#
# FILE: scripts/ai/bt_condition_can_see_player.gd
# PURPOSE: Check if player is visible within range
#
# BEHAVIOR:
# ---------
# - Returns SUCCESS if player is in range and visible
# - Returns FAILURE otherwise
#
# ==============================================================================

extends BTNode
class_name BTConditionCanSeePlayer


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Detection range
var detection_range: float = 500.0


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _init(p_range: float = 500.0):
	detection_range = p_range


# ==============================================================================
# EXECUTION
# ==============================================================================

func tick(delta: float) -> Status:
	if not agent:
		return Status.FAILURE
	
	# Find player
	var player = agent.get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		return Status.FAILURE
	
	# Check distance
	var distance = agent.global_position.distance_to(player.global_position)
	if distance > detection_range:
		return Status.FAILURE
	
	# Store player in blackboard for other nodes to use
	blackboard["target"] = player
	
	# Could add raycast check here for line-of-sight
	# For now, simple distance check
	
	return Status.SUCCESS
