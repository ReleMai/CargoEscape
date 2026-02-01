# ==============================================================================
# BEHAVIOR TREE BUILDER
# ==============================================================================
#
# FILE: scripts/ai/bt_builder.gd
# PURPOSE: Helper class for building behavior trees with fluent API
#
# USAGE:
# ------
# var tree = BTBuilder.sequence([
#     BTBuilder.condition_can_see_player(),
#     BTBuilder.chase(),
#     BTBuilder.attack()
# ])
#
# ==============================================================================

extends RefCounted
class_name BTBuilder


# ==============================================================================
# COMPOSITE NODES
# ==============================================================================

## Create a sequence node
static func sequence(children: Array[BTNode]) -> BTSequence:
	var node = BTSequence.new()
	for child in children:
		node.add_child_node(child)
	return node


## Create a selector node
static func selector(children: Array[BTNode]) -> BTSelector:
	var node = BTSelector.new()
	for child in children:
		node.add_child_node(child)
	return node


# ==============================================================================
# DECORATOR NODES
# ==============================================================================

## Create an inverter node
static func inverter(child: BTNode) -> BTInverter:
	var node = BTInverter.new()
	node.set_child(child)
	return node


## Create a repeater node
static func repeater(child: BTNode, count: int = -1) -> BTRepeater:
	var node = BTRepeater.new(count)
	node.set_child(child)
	return node


# ==============================================================================
# CONDITION NODES
# ==============================================================================

## Check if player is visible
static func condition_can_see_player(range_val: float = 500.0) -> BTConditionCanSeePlayer:
	return BTConditionCanSeePlayer.new(range_val)


## Check if health is low
static func condition_is_low_health(threshold: float = 0.3) -> BTConditionIsLowHealth:
	return BTConditionIsLowHealth.new(threshold)


## Check if target is in range
static func condition_is_in_range(range_val: float = 100.0) -> BTConditionIsInRange:
	return BTConditionIsInRange.new(range_val)


# ==============================================================================
# ACTION NODES
# ==============================================================================

## Patrol between waypoints
static func patrol(waypoints: Array[Vector2], speed: float = 150.0) -> BTPatrol:
	return BTPatrol.new(waypoints, speed)


## Chase target
static func chase(speed: float = 200.0, attack_range: float = 100.0, max_distance: float = 800.0) -> BTChase:
	return BTChase.new(speed, attack_range, max_distance)


## Attack target
static func attack(range_val: float = 100.0, cooldown: float = 1.0, damage: float = 10.0) -> BTAttack:
	return BTAttack.new(range_val, cooldown, damage)


## Flee from target
static func flee(speed: float = 250.0, safe_distance: float = 300.0) -> BTFlee:
	return BTFlee.new(speed, safe_distance)


## Alert nearby enemies
static func alert(radius: float = 400.0, cooldown: float = 5.0) -> BTAlert:
	return BTAlert.new(radius, cooldown)


# ==============================================================================
# PRESET TREES
# ==============================================================================

## Create a basic patrol-chase-attack tree
static func create_basic_enemy_tree(patrol_waypoints: Array[Vector2]) -> BTNode:
	return selector([
		# Flee if low health
		sequence([
			condition_is_low_health(0.3),
			flee()
		]),
		# Chase and attack if player spotted
		sequence([
			condition_can_see_player(500.0),
			alert(),  # Alert nearby enemies
			selector([
				# Attack if in range
				sequence([
					condition_is_in_range(100.0),
					attack()
				]),
				# Otherwise chase
				chase()
			])
		]),
		# Default: patrol
		patrol(patrol_waypoints)
	])


## Create an aggressive enemy tree (no patrol, always hunting)
static func create_aggressive_tree() -> BTNode:
	return selector([
		# Flee if very low health
		sequence([
			condition_is_low_health(0.2),
			flee()
		]),
		# Chase and attack
		sequence([
			condition_can_see_player(800.0),  # Larger detection range
			alert(),
			selector([
				sequence([
					condition_is_in_range(120.0),
					attack(120.0, 0.8, 15.0)  # Higher damage, faster attacks
				]),
				chase(250.0, 120.0, 1000.0)  # Faster chase, longer pursuit
			])
		]),
		# Fallback: Move forward slowly (hunting behavior)
		patrol([Vector2.ZERO, Vector2(-300, 0)], 100.0)
	])


## Create a defensive enemy tree (patrols, only fights when attacked)
static func create_defensive_tree(patrol_waypoints: Array[Vector2]) -> BTNode:
	return selector([
		# Flee if low health
		sequence([
			condition_is_low_health(0.4),  # Flee earlier
			flee()
		]),
		# Only fight if very close
		sequence([
			condition_can_see_player(250.0),  # Smaller detection range
			selector([
				sequence([
					condition_is_in_range(80.0),
					attack()
				]),
				chase(180.0, 80.0, 400.0)  # Shorter pursuit
			])
		]),
		# Mostly patrol
		patrol(patrol_waypoints)
	])
