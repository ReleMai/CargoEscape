# ==============================================================================
# SELECTOR NODE
# ==============================================================================
#
# FILE: scripts/ai/bt_selector.gd
# PURPOSE: Executes children until one succeeds
#
# BEHAVIOR:
# ---------
# - Executes children from left to right
# - If a child returns SUCCESS, selector returns SUCCESS
# - If a child returns RUNNING, selector returns RUNNING
# - If all children return FAILURE, selector returns FAILURE
#
# USE CASE:
# ---------
# Use for fallback behaviors or decision-making.
# Example: "Attack" OR "Chase" OR "Patrol"
#
# ==============================================================================

extends BTComposite
class_name BTSelector


# ==============================================================================
# EXECUTION
# ==============================================================================

func tick(delta: float) -> Status:
	# Try children in order until one succeeds
	while current_child_index < children.size():
		var child = children[current_child_index]
		var status = child.tick(delta)
		
		match status:
			Status.SUCCESS:
				# Child succeeded, selector succeeds
				reset()
				return Status.SUCCESS
			Status.RUNNING:
				# Child still running, selector is running
				return Status.RUNNING
			Status.FAILURE:
				# Child failed, try next child
				current_child_index += 1
	
	# All children failed
	reset()
	return Status.FAILURE


func reset() -> void:
	current_child_index = 0
	for child in children:
		child.reset()
