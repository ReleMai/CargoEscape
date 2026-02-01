# ==============================================================================
# GAME OVER SCREEN SCRIPT
# ==============================================================================
# 
# FILE: scripts/ui/game_over_screen.gd
# PURPOSE: Handles the game over UI and restart functionality
#
# ==============================================================================

extends CanvasLayer


# ==============================================================================
# ONREADY VARIABLES
# ==============================================================================

@onready var final_score_label: Label = $CenterContainer/VBoxContainer/FinalScoreLabel
@onready var restart_button: Button = $CenterContainer/VBoxContainer/RestartButton


# ==============================================================================
# REGULAR VARIABLES
# ==============================================================================

var game_manager: Node


# ==============================================================================
# BUILT-IN FUNCTIONS
# ==============================================================================

func _ready() -> void:
	# Get GameManager reference
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	
	# Connect restart button
	restart_button.pressed.connect(_on_restart_pressed)
	
	# Update final score display
	update_final_score()


# ==============================================================================
# DISPLAY FUNCTIONS
# ==============================================================================

func update_final_score() -> void:
	if game_manager:
		final_score_label.text = "Final Score: " + game_manager.get_formatted_score()


# ==============================================================================
# SIGNAL CALLBACKS
# ==============================================================================

func _on_restart_pressed() -> void:
	print("Restart button pressed")
	
	# Find the main scene and call restart
	# get_parent() returns the node this is a child of (should be Main)
	var main = get_parent()
	if main.has_method("restart_game"):
		main.restart_game()
	else:
		# Fallback: just reload the scene
		get_tree().reload_current_scene()
