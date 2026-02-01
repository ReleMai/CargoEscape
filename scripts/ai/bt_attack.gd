# ==============================================================================
# ATTACK BEHAVIOR NODE
# ==============================================================================
#
# FILE: scripts/ai/bt_attack.gd
# PURPOSE: Engage target when in range
#
# BEHAVIOR:
# ---------
# - Attacks the target if in range
# - Handles attack cooldown
# - Returns SUCCESS when attack is performed
# - Returns FAILURE if target out of range
#
# BLACKBOARD KEYS:
# ----------------
# - "target": Node2D - The target to attack
# - "last_attack_time": float - Time of last attack
#
# ==============================================================================

extends BTNode
class_name BTAttack


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Attack range
var attack_range: float = 100.0

## Attack cooldown (seconds)
var attack_cooldown: float = 1.0

## Attack damage
var attack_damage: float = 10.0

## Time of last attack
var last_attack_time: float = -999.0


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _init(p_range: float = 100.0, p_cooldown: float = 1.0, p_damage: float = 10.0):
	attack_range = p_range
	attack_cooldown = p_cooldown
	attack_damage = p_damage


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
	
	# Check if in range
	var distance = agent.global_position.distance_to(target.global_position)
	if distance > attack_range:
		return Status.FAILURE
	
	# Check cooldown
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_attack_time < attack_cooldown:
		return Status.RUNNING
	
	# Perform attack
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)
		last_attack_time = current_time
		
		# Visual feedback - enemy could face target, play animation, etc.
		if agent.has_method("play_attack_animation"):
			agent.play_attack_animation()
		
		return Status.SUCCESS
	
	return Status.FAILURE


func reset() -> void:
	super.reset()
	# Keep attack time so cooldown persists
