# ==============================================================================
# CONTROLS MENU
# ==============================================================================
#
# FILE: scripts/ui/controls_menu.gd
# PURPOSE: UI for remapping game controls
#
# ==============================================================================

extends Control
class_name ControlsMenu

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var controls_list: VBoxContainer = $Panel/ScrollContainer/ControlsList
@onready var back_button: Button = $Panel/BackButton
@onready var reset_button: Button = $Panel/ResetButton
@onready var listening_label: Label = $Panel/ListeningLabel

# ==============================================================================
# STATE
# ==============================================================================

var listening_for_input: bool = false
var listening_action: String = ""

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_populate_controls_list()
	
	if listening_label:
		listening_label.visible = false


func _setup_ui() -> void:
	pass


func _connect_signals() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)


func _populate_controls_list() -> void:
	if not controls_list:
		return
	
	# Clear existing children
	for child in controls_list.get_children():
		child.queue_free()
	
	# Get all input actions
	var actions = [
		"move_up",
		"move_down", 
		"move_left",
		"move_right",
		"brake",
		"fire",
		"interact",
		"inventory"
	]
	
	# Create UI for each action
	for action in actions:
		var container = HBoxContainer.new()
		container.name = action + "_container"
		
		# Action name label
		var label = Label.new()
		label.text = AccessibilityManager.get_action_display_name(action)
		label.custom_minimum_size.x = 200
		container.add_child(label)
		
		# Current binding label
		var binding_label = Label.new()
		binding_label.name = "binding_label"
		binding_label.text = _get_action_key_text(action)
		binding_label.custom_minimum_size.x = 150
		container.add_child(binding_label)
		
		# Remap button
		var remap_button = Button.new()
		remap_button.text = "Remap"
		remap_button.pressed.connect(_on_remap_pressed.bind(action))
		container.add_child(remap_button)
		
		controls_list.add_child(container)


func _get_action_key_text(action: String) -> String:
	var events = InputMap.action_get_events(action)
	if events.size() == 0:
		return "Not bound"
	
	var event = events[0]
	if event is InputEventKey:
		# Use physical_keycode if available, fallback to keycode
		var keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		return OS.get_keycode_string(keycode)
	elif event is InputEventMouseButton:
		return "Mouse " + str(event.button_index)
	
	return "Unknown"


# ==============================================================================
# INPUT HANDLING
# ==============================================================================

func _input(event: InputEvent) -> void:
	if not listening_for_input:
		return
	
	# Only accept key and mouse button events
	if event is InputEventKey and event.pressed:
		_assign_input(event)
	elif event is InputEventMouseButton and event.pressed:
		_assign_input(event)


func _assign_input(event: InputEvent) -> void:
	if not listening_for_input or listening_action == "":
		return
	
	# Remap the action
	AccessibilityManager.remap_action(listening_action, event)
	
	# Update UI
	_update_binding_label(listening_action)
	
	# Stop listening
	listening_for_input = false
	listening_action = ""
	
	if listening_label:
		listening_label.visible = false
	
	AccessibilityManager.announce_for_screen_reader("Control remapped")


func _update_binding_label(action: String) -> void:
	if not controls_list:
		return
	
	var container = controls_list.get_node_or_null(action + "_container")
	if container:
		var binding_label = container.get_node_or_null("binding_label")
		if binding_label:
			binding_label.text = _get_action_key_text(action)


# ==============================================================================
# SIGNAL HANDLERS
# ==============================================================================

func _on_remap_pressed(action: String) -> void:
	listening_for_input = true
	listening_action = action
	
	if listening_label:
		listening_label.text = "Press any key for " + AccessibilityManager.get_action_display_name(action)
		listening_label.visible = true
	
	AccessibilityManager.announce_for_screen_reader("Press any key to remap " + action)


func _on_back_pressed() -> void:
	queue_free()


func _on_reset_pressed() -> void:
	AccessibilityManager.reset_all_inputs()
	_populate_controls_list()
	AccessibilityManager.announce_for_screen_reader("All controls reset to default")
