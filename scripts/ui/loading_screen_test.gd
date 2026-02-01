extends Control

func _ready() -> void:
	# Wait a bit then test the loading screen
	await get_tree().create_timer(1.0).timeout
	print("Testing LoadingScreen transition...")
	LoadingScreen.start_transition("res://scenes/main.tscn")

func _input(event: InputEvent) -> void:
	# Press SPACE to test loading screen
	if event.is_action_pressed("fire"):
		print("Manual test: Starting transition...")
		LoadingScreen.start_transition("res://scenes/intro/intro_scene.tscn")
