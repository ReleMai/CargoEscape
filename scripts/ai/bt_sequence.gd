# ==============================================================================
# SEQUENCE NODE
# ==============================================================================
#
# FILE: scripts/ai/bt_sequence.gd
# PURPOSE: Executes children in order until one fails
#
# BEHAVIOR:
# ---------
# - Executes children from left to right
# - If a child returns FAILURE, sequence returns FAILURE
# - If a child returns RUNNING, sequence returns RUNNING
# - If all children return SUCCESS, sequence returns SUCCESS
#
# USE CASE:
# ---------
# Use for actions that must all succeed in order.
# Example: "Approach target" AND "Attack target"
#
# ==============================================================================

extends BTComposite
class_name BTSequence


# ==============================================================================
# EXECUTION
# ==============================================================================

func tick(delta: float) -> Status:
	# Execute children in sequence
	while current_child_index < children.size():
		var child = children[current_child_index]
		var status = child.tick(delta)
		
		match status:
			Status.FAILURE:
				# Child failed, sequence fails
				reset()
				return Status.FAILURE
			Status.RUNNING:
				# Child still running, sequence is running
				return Status.RUNNING
			Status.SUCCESS:
				# Child succeeded, move to next child
				current_child_index += 1
	
	# All children succeeded
	reset()
	return Status.SUCCESS


func reset() -> void:
	current_child_index = 0
	for child in children:
		child.reset()
