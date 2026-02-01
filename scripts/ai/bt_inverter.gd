# ==============================================================================
# INVERTER DECORATOR
# ==============================================================================
#
# FILE: scripts/ai/bt_inverter.gd
# PURPOSE: Inverts the result of child node
#
# BEHAVIOR:
# ---------
# - SUCCESS becomes FAILURE
# - FAILURE becomes SUCCESS
# - RUNNING stays RUNNING
#
# USE CASE:
# ---------
# Useful for negating conditions.
# Example: "NOT can see player" = player is hidden
#
# ==============================================================================

extends BTDecorator
class_name BTInverter


func tick(delta: float) -> Status:
	if not child_node:
		return Status.FAILURE
	
	var status = child_node.tick(delta)
	
	match status:
		Status.SUCCESS:
			return Status.FAILURE
		Status.FAILURE:
			return Status.SUCCESS
		Status.RUNNING:
			return Status.RUNNING
	
	return Status.FAILURE
