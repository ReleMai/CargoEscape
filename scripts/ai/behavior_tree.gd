# ==============================================================================
# BEHAVIOR TREE
# ==============================================================================
#
# FILE: scripts/ai/behavior_tree.gd
# PURPOSE: Main behavior tree class that manages execution
#
# USAGE:
# ------
# var tree = BehaviorTree.new()
# tree.root_node = create_my_tree()
# tree.initialize(self, {})
# 
# In _process(delta):
#     tree.tick(delta)
#
# ==============================================================================

extends RefCounted
class_name BehaviorTree


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Root node of the behavior tree
var root_node: BTNode = null

## Agent executing this tree
var agent: Node = null

## Shared data between nodes
var blackboard: Dictionary = {}

## Whether the tree is active
var is_active: bool = true


# ==============================================================================
# INITIALIZATION
# ==============================================================================

## Initialize the behavior tree
func initialize(p_agent: Node, p_blackboard: Dictionary = {}) -> void:
	agent = p_agent
	blackboard = p_blackboard
	
	if root_node:
		root_node.initialize(agent, blackboard)


## Set the root node
func set_root(node: BTNode) -> void:
	root_node = node
	if agent and blackboard:
		root_node.initialize(agent, blackboard)


# ==============================================================================
# EXECUTION
# ==============================================================================

## Tick the behavior tree
func tick(delta: float) -> BTNode.Status:
	if not is_active or not root_node:
		return BTNode.Status.FAILURE
	
	return root_node.tick(delta)


## Reset the entire tree
func reset() -> void:
	if root_node:
		root_node.reset()


## Activate/deactivate the tree
func set_active(active: bool) -> void:
	is_active = active


# ==============================================================================
# BLACKBOARD HELPERS
# ==============================================================================

## Get value from blackboard
func get_value(key: String, default = null):
	return blackboard.get(key, default)


## Set value in blackboard
func set_value(key: String, value) -> void:
	blackboard[key] = value


## Check if blackboard has key
func has_value(key: String) -> bool:
	return blackboard.has(key)


## Clear blackboard
func clear_blackboard() -> void:
	blackboard.clear()
