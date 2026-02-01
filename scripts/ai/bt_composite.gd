# ==============================================================================
# COMPOSITE NODE - BASE CLASS
# ==============================================================================
#
# FILE: scripts/ai/bt_composite.gd
# PURPOSE: Base class for composite behavior tree nodes (nodes with children)
#
# COMPOSITE NODES:
# ----------------
# Composite nodes control the execution flow of multiple child nodes.
# Common types: Sequence, Selector, Parallel
#
# ==============================================================================

extends BTNode
class_name BTComposite


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Child nodes to execute
var children: Array[BTNode] = []

## Current child being executed
var current_child_index: int = 0


# ==============================================================================
# CHILD MANAGEMENT
# ==============================================================================

## Add a child node
func add_child_node(child: BTNode) -> void:
	children.append(child)
	if agent and blackboard:
		child.initialize(agent, blackboard)


## Remove a child node
func remove_child_node(child: BTNode) -> void:
	children.erase(child)


## Clear all children
func clear_children() -> void:
	children.clear()
	current_child_index = 0


# ==============================================================================
# INITIALIZATION
# ==============================================================================

## Initialize this node and all children
func initialize(p_agent: Node, p_blackboard: Dictionary) -> void:
	super.initialize(p_agent, p_blackboard)
	for child in children:
		child.initialize(p_agent, p_blackboard)


# ==============================================================================
# RESET
# ==============================================================================

func reset() -> void:
	super.reset()
	current_child_index = 0
	for child in children:
		child.reset()
