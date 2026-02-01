# ==============================================================================
# BEHAVIOR TREE NODE - BASE CLASS
# ==============================================================================
#
# FILE: scripts/ai/bt_node.gd
# PURPOSE: Base class for all behavior tree nodes
#
# BEHAVIOR TREE BASICS:
# ---------------------
# Behavior trees are hierarchical structures that define AI decision-making.
# Each node returns one of three states: SUCCESS, FAILURE, or RUNNING.
#
# NODE TYPES:
# -----------
# 1. Leaf Nodes: Action or Condition nodes that do actual work
# 2. Composite Nodes: Have children and control execution flow
# 3. Decorator Nodes: Modify behavior of a single child
#
# ==============================================================================

extends RefCounted
class_name BTNode


# ==============================================================================
# ENUMS
# ==============================================================================

## Return status of behavior tree nodes
enum Status {
	SUCCESS,  ## Node completed successfully
	FAILURE,  ## Node failed to complete
	RUNNING   ## Node is still executing
}


# ==============================================================================
# PROPERTIES
# ==============================================================================

## Reference to the agent executing this behavior tree
var agent: Node = null

## Blackboard for sharing data between nodes
var blackboard: Dictionary = {}


# ==============================================================================
# VIRTUAL METHODS
# ==============================================================================

## Execute this node (override in subclasses)
func tick(delta: float) -> Status:
	push_warning("BTNode.tick() not implemented in " + get_script().resource_path)
	return Status.FAILURE


## Called when node is entered (optional override)
func enter() -> void:
	pass


## Called when node is exited (optional override)
func exit() -> void:
	pass


## Reset node state (optional override)
func reset() -> void:
	pass


# ==============================================================================
# INITIALIZATION
# ==============================================================================

## Setup node with agent reference and blackboard
func initialize(p_agent: Node, p_blackboard: Dictionary) -> void:
	agent = p_agent
	blackboard = p_blackboard
