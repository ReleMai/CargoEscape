# ==============================================================================
# PATROL BEHAVIOR NODE
# ==============================================================================
#
# FILE: scripts/ai/bt_patrol.gd
# PURPOSE: Move between waypoints
#
# BEHAVIOR:
# ---------
# - Cycles through waypoints in order
# - Moves toward current waypoint
# - Switches to next waypoint when close enough
# - Returns RUNNING while patrolling
#
# BLACKBOARD KEYS:
# ----------------
# - "patrol_waypoints": Array[Vector2] - List of waypoint positions
# - "patrol_index": int - Current waypoint index
# - "patrol_speed": float - Movement speed
#
# ==============================================================================

extends BTNode
class_name BTPatrol


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Distance to waypoint to consider it "reached"
var arrival_distance: float = 20.0

## Movement speed
var speed: float = 150.0

## Waypoints to patrol
var waypoints: Array[Vector2] = []

## Current waypoint index
var current_waypoint_index: int = 0


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _init(p_waypoints: Array[Vector2] = [], p_speed: float = 150.0):
	waypoints = p_waypoints
	speed = p_speed


# ==============================================================================
# EXECUTION
# ==============================================================================

func tick(delta: float) -> Status:
	if not agent or waypoints.is_empty():
		return Status.FAILURE
	
	# Get current waypoint
	var target = waypoints[current_waypoint_index]
	var distance = agent.global_position.distance_to(target)
	
	# Check if we've reached the waypoint
	if distance <= arrival_distance:
		# Move to next waypoint
		current_waypoint_index = (current_waypoint_index + 1) % waypoints.size()
		# Keep running - patrol is continuous
		return Status.RUNNING
	
	# Move toward waypoint
	var direction = (target - agent.global_position).normalized()
	agent.current_velocity = direction * speed
	
	return Status.RUNNING


func reset() -> void:
	super.reset()
	# Don't reset waypoint index - continue from where we left off
