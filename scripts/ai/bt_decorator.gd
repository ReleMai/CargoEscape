# ==============================================================================
# DECORATOR NODE - BASE CLASS
# ==============================================================================
#
# FILE: scripts/ai/bt_decorator.gd
# PURPOSE: Base class for decorator nodes (modify single child behavior)
#
# DECORATORS:
# -----------
# Decorators wrap a single child node and modify its behavior.
# Examples: Inverter, Repeater, UntilFail, etc.
#
# ==============================================================================

extends BTNode
class_name BTDecorator


# ==============================================================================
# PROPERTIES
# ==============================================================================

## The child node to decorate
var child_node: BTNode = null


# ==============================================================================
# CHILD MANAGEMENT
# ==============================================================================

## Set the child node
func set_child(child: BTNode) -> void:
	child_node = child
	if agent and blackboard:
		child_node.initialize(agent, blackboard)


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func initialize(p_agent: Node, p_blackboard: Dictionary) -> void:
	super.initialize(p_agent, p_blackboard)
	if child_node:
		child_node.initialize(p_agent, p_blackboard)


# ==============================================================================
# RESET
# ==============================================================================

func reset() -> void:
	super.reset()
	if child_node:
		child_node.reset()
