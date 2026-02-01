# ==============================================================================
# FLEE BEHAVIOR NODE
# ==============================================================================
#
# FILE: scripts/ai/bt_flee.gd
# PURPOSE: Retreat when low health
#
# BEHAVIOR:
# ---------
# - Moves away from target
# - Returns SUCCESS when at safe distance
# - Returns RUNNING while fleeing
#
# BLACKBOARD KEYS:
# ----------------
# - "target": Node2D - The target to flee from
# - "flee_speed": float - Movement speed while fleeing
#
# ==============================================================================

extends BTNode
class_name BTFlee


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Flee speed
var flee_speed: float = 250.0

## Safe distance (stop fleeing when this far)
var safe_distance: float = 300.0


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _init(p_speed: float = 250.0, p_safe_distance: float = 300.0):
	flee_speed = p_speed
	safe_distance = p_safe_distance


# ==============================================================================
# EXECUTION
# ==============================================================================

func tick(delta: float) -> Status:
	if not agent:
		return Status.FAILURE
	
	# Get target from blackboard or find player
	var target = blackboard.get("target", null)
	if not target:
		target = agent.get_tree().get_first_node_in_group("player")
		if not target:
			# No target to flee from, stay in place
			agent.current_velocity = Vector2.ZERO
			return Status.SUCCESS
		blackboard["target"] = target
	
	# Check if target is valid
	if not is_instance_valid(target):
		blackboard.erase("target")
		return Status.SUCCESS
	
	# Calculate distance to target
	var distance = agent.global_position.distance_to(target.global_position)
	
	# Check if at safe distance
	if distance >= safe_distance:
		agent.current_velocity = Vector2.ZERO
		return Status.SUCCESS
	
	# Flee away from target
	var direction = (agent.global_position - target.global_position).normalized()
	agent.current_velocity = direction * flee_speed
	
	return Status.RUNNING


func reset() -> void:
	super.reset()
