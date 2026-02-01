# ==============================================================================
# EXAMPLE: BEHAVIOR TREE ENEMY
# ==============================================================================
#
# FILE: scripts/ai/example_bt_enemy.gd
# PURPOSE: Example script showing how to use behavior trees with enemies
#
# This script demonstrates three ways to use behavior trees:
# 1. Using presets (easiest)
# 2. Using BTBuilder for custom trees
# 3. Manual tree construction (advanced)
#
# USAGE:
# ------
# Attach this script to an enemy node, or use it as reference.
# The enemy.gd script already has built-in support for behavior trees.
#
# ==============================================================================

extends Area2D


# ==============================================================================
# EXAMPLE 1: USING PRESETS (SIMPLEST)
# ==============================================================================

func setup_with_preset():
	# Set up patrol waypoints (relative to spawn position)
	var waypoints = [
		Vector2(0, 0),
		Vector2(-200, -100),
		Vector2(-200, 100),
	]
	
	# Create behavior tree
	var tree = BehaviorTree.new()
	tree.set_root(BTBuilder.create_basic_enemy_tree(waypoints))
	tree.initialize(self, {})
	
	# Store and use in _process
	set_meta("behavior_tree", tree)


# ==============================================================================
# EXAMPLE 2: CUSTOM TREE WITH BTBUILDER (RECOMMENDED)
# ==============================================================================

func setup_custom_tree():
	# Create a custom AI with specific behaviors
	var tree = BehaviorTree.new()
	
	# Build custom behavior tree using BTBuilder
	var root = BTBuilder.selector([
		# Priority 1: Flee if health below 25%
		BTBuilder.sequence([
			BTBuilder.condition_is_low_health(0.25),
			BTBuilder.alert(500.0, 3.0),  # Alert before fleeing
			BTBuilder.flee(300.0, 400.0)
		]),
		
		# Priority 2: Attack if player very close
		BTBuilder.sequence([
			BTBuilder.condition_can_see_player(600.0),
			BTBuilder.condition_is_in_range(120.0),
			BTBuilder.attack(120.0, 0.8, 15.0)
		]),
		
		# Priority 3: Chase if player spotted
		BTBuilder.sequence([
			BTBuilder.condition_can_see_player(600.0),
			BTBuilder.alert(400.0, 5.0),
			BTBuilder.chase(220.0, 120.0, 800.0)
		]),
		
		# Priority 4: Patrol (default behavior)
		BTBuilder.patrol([
			global_position,
			global_position + Vector2(-300, 0),
			global_position + Vector2(-300, -200),
			global_position + Vector2(0, -200),
		], 180.0)
	])
	
	tree.set_root(root)
	tree.initialize(self, {})
	set_meta("behavior_tree", tree)


# ==============================================================================
# EXAMPLE 3: MANUAL CONSTRUCTION (ADVANCED)
# ==============================================================================

func setup_manual_tree():
	# Create nodes manually for maximum control
	var tree = BehaviorTree.new()
	
	# Create flee branch
	var flee_sequence = BTSequence.new()
	flee_sequence.add_child_node(BTConditionIsLowHealth.new(0.3))
	flee_sequence.add_child_node(BTFlee.new(250.0, 300.0))
	
	# Create attack branch
	var attack_sequence = BTSequence.new()
	attack_sequence.add_child_node(BTConditionCanSeePlayer.new(500.0))
	attack_sequence.add_child_node(BTConditionIsInRange.new(100.0))
	attack_sequence.add_child_node(BTAttack.new(100.0, 1.0, 10.0))
	
	# Create chase branch
	var chase_sequence = BTSequence.new()
	chase_sequence.add_child_node(BTConditionCanSeePlayer.new(500.0))
	chase_sequence.add_child_node(BTChase.new(200.0, 100.0, 800.0))
	
	# Create patrol (default)
	var patrol_node = BTPatrol.new([
		global_position,
		global_position + Vector2(-200, -100),
		global_position + Vector2(-200, 100),
	], 150.0)
	
	# Combine into selector (try in priority order)
	var root_selector = BTSelector.new()
	root_selector.add_child_node(flee_sequence)
	root_selector.add_child_node(attack_sequence)
	root_selector.add_child_node(chase_sequence)
	root_selector.add_child_node(patrol_node)
	
	tree.set_root(root_selector)
	tree.initialize(self, {})
	set_meta("behavior_tree", tree)


# ==============================================================================
# EXAMPLE 4: ADVANCED PATTERNS
# ==============================================================================

func setup_advanced_tree():
	# Example with decorators and more complex logic
	var tree = BehaviorTree.new()
	
	var root = BTBuilder.selector([
		# Flee when low health
		BTBuilder.sequence([
			BTBuilder.condition_is_low_health(0.3),
			BTBuilder.flee()
		]),
		
		# Complex attack pattern with repeater
		BTBuilder.sequence([
			BTBuilder.condition_can_see_player(400.0),
			BTBuilder.selector([
				# If in range, attack repeatedly
				BTBuilder.sequence([
					BTBuilder.condition_is_in_range(100.0),
					BTBuilder.repeater(BTBuilder.attack(100.0, 0.5, 8.0), 3)
				]),
				# Otherwise chase
				BTBuilder.chase(200.0, 100.0, 600.0)
			])
		]),
		
		# Default: patrol infinitely
		BTBuilder.repeater(
			BTBuilder.patrol([
				global_position,
				global_position + Vector2(-400, 0)
			]),
			-1  # Infinite repetitions
		)
	])
	
	tree.set_root(root)
	tree.initialize(self, {})
	set_meta("behavior_tree", tree)


# ==============================================================================
# EXAMPLE 5: CONDITIONAL BEHAVIORS
# ==============================================================================

func setup_conditional_tree():
	# Different behavior based on time of day, player state, etc.
	var tree = BehaviorTree.new()
	
	# You can check custom conditions using the blackboard
	var root = BTBuilder.selector([
		# If alerted by another enemy, become aggressive
		BTBuilder.sequence([
			# Custom condition - you'd implement this
			# BTCustomCondition checking blackboard["alert_received"]
			BTBuilder.chase(250.0, 100.0, 1000.0)
		]),
		
		# Normal behavior
		BTBuilder.create_basic_enemy_tree([
			global_position,
			global_position + Vector2(-200, 0)
		])
	])
	
	tree.set_root(root)
	tree.initialize(self, {})
	set_meta("behavior_tree", tree)


# ==============================================================================
# INTEGRATION EXAMPLE
# ==============================================================================

# This shows how to integrate the behavior tree in your _process function
func _process_with_behavior_tree(delta: float):
	var tree = get_meta("behavior_tree", null) as BehaviorTree
	if tree:
		var status = tree.tick(delta)
		
		# Optional: React to status
		match status:
			BTNode.Status.SUCCESS:
				pass  # Tree completed successfully
			BTNode.Status.FAILURE:
				pass  # Tree failed (might want to reset or change state)
			BTNode.Status.RUNNING:
				pass  # Tree is still running (normal)


# ==============================================================================
# TIPS AND BEST PRACTICES
# ==============================================================================

# TIP 1: Use blackboard for communication
func example_blackboard_usage():
	var tree = BehaviorTree.new()
	# ... setup tree ...
	tree.initialize(self, {
		"patrol_speed": 150.0,
		"chase_speed": 250.0,
		"is_aggressive": true
	})
	
	# Later, in a behavior node, you can access:
	# blackboard.get("patrol_speed", 150.0)


# TIP 2: Dynamically change behavior
func make_aggressive():
	var tree = get_meta("behavior_tree", null) as BehaviorTree
	if tree:
		tree.set_value("is_aggressive", true)
		# Could rebuild tree or just use blackboard values in behaviors


# TIP 3: Debug behavior trees
func debug_behavior_tree():
	var tree = get_meta("behavior_tree", null) as BehaviorTree
	if tree:
		print("Blackboard state:")
		for key in tree.blackboard:
			print("  ", key, " = ", tree.blackboard[key])


# ==============================================================================
# CALLBACKS FOR AI SYSTEM
# ==============================================================================

# These methods are called by behavior tree nodes
func receive_alert(target: Node2D, alert_position: Vector2):
	var tree = get_meta("behavior_tree", null) as BehaviorTree
	if tree:
		tree.set_value("target", target)
		tree.set_value("alert_received", true)
		tree.set_value("alert_position", alert_position)


func set_target(target: Node2D):
	var tree = get_meta("behavior_tree", null) as BehaviorTree
	if tree:
		tree.set_value("target", target)


# Visual feedback methods (optional)
func play_alert_effect():
	# Add visual/audio effect when enemy is alerted
	modulate = Color.RED
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE


func play_attack_animation():
	# Add attack animation/effect
	pass
