# ==============================================================================
# CHASE BEHAVIOR NODE
# ==============================================================================
#
# FILE: scripts/ai/bt_chase.gd
# PURPOSE: Follow player when spotted
#
# BEHAVIOR:
# ---------
# - Moves toward the player
# - Returns SUCCESS when in attack range
# - Returns RUNNING while chasing
# - Returns FAILURE if player lost or out of range
#
# BLACKBOARD KEYS:
# ----------------
# - "target": Node2D - The target to chase (usually player)
# - "chase_speed": float - Movement speed while chasing
# - "max_chase_distance": float - Maximum distance to chase
#
# ==============================================================================

extends BTNode
class_name BTChase


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Chase speed
var chase_speed: float = 200.0

## Attack range (stop chasing when this close)
var attack_range: float = 100.0

## Maximum chase distance (give up if too far)
var max_chase_distance: float = 800.0


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _init(p_speed: float = 200.0, p_attack_range: float = 100.0, p_max_distance: float = 800.0):
	chase_speed = p_speed
	attack_range = p_attack_range
	max_chase_distance = p_max_distance


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
			return Status.FAILURE
		blackboard["target"] = target
	
	# Check if target is valid
	if not is_instance_valid(target):
		blackboard.erase("target")
		return Status.FAILURE
	
	# Calculate distance to target
	var distance = agent.global_position.distance_to(target.global_position)
	
	# Check if too far (give up chase)
	if distance > max_chase_distance:
		return Status.FAILURE
	
	# Check if in attack range
	if distance <= attack_range:
		# Stop moving, ready to attack
		agent.current_velocity = Vector2.ZERO
		return Status.SUCCESS
	
	# Chase toward target
	var direction = (target.global_position - agent.global_position).normalized()
	agent.current_velocity = direction * chase_speed
	
	return Status.RUNNING


func reset() -> void:
	super.reset()
