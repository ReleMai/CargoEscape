# ==============================================================================
# ALERT BEHAVIOR NODE
# ==============================================================================
#
# FILE: scripts/ai/bt_alert.gd
# PURPOSE: Notify nearby enemies
#
# BEHAVIOR:
# ---------
# - Sends alert signal to nearby enemies
# - Can be used when player is spotted or enemy is attacked
# - Returns SUCCESS after alerting
#
# BLACKBOARD KEYS:
# ----------------
# - "alert_target": Node2D - The target to alert others about
# - "alert_radius": float - Radius to search for allies
#
# ==============================================================================

extends BTNode
class_name BTAlert


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Alert radius
var alert_radius: float = 400.0

## Cooldown between alerts (seconds)
var alert_cooldown: float = 5.0

## Time of last alert
var last_alert_time: float = -999.0


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _init(p_radius: float = 400.0, p_cooldown: float = 5.0):
	alert_radius = p_radius
	alert_cooldown = p_cooldown


# ==============================================================================
# EXECUTION
# ==============================================================================

func tick(delta: float) -> Status:
	if not agent:
		return Status.FAILURE
	
	# Check cooldown
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_alert_time < alert_cooldown:
		return Status.FAILURE
	
	# Get target to alert about
	var target = blackboard.get("target", null)
	if not target or not is_instance_valid(target):
		return Status.FAILURE
	
	# Find nearby enemies
	var nearby_enemies = _find_nearby_enemies()
	
	if nearby_enemies.is_empty():
		return Status.FAILURE
	
	# Alert each nearby enemy
	for enemy in nearby_enemies:
		if enemy != agent and enemy.has_method("receive_alert"):
			enemy.receive_alert(target, agent.global_position)
		elif enemy != agent and enemy.has_method("set_target"):
			enemy.set_target(target)
	
	last_alert_time = current_time
	
	# Visual feedback - could play alert animation, sound, etc.
	if agent.has_method("play_alert_effect"):
		agent.play_alert_effect()
	
	return Status.SUCCESS


func _find_nearby_enemies() -> Array:
	var nearby: Array = []
	
	# Get all enemies in the scene
	var enemies = agent.get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy == agent:
			continue
		
		var distance = agent.global_position.distance_to(enemy.global_position)
		if distance <= alert_radius:
			nearby.append(enemy)
	
	return nearby


func reset() -> void:
	super.reset()
	# Keep alert time so cooldown persists
