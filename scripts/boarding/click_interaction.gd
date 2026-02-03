# ==============================================================================
# CLICK INTERACTION SYSTEM - MOUSE-BASED INTERACTION FOR BOARDING
# ==============================================================================
#
# FILE: scripts/boarding/click_interaction.gd
# PURPOSE: Handles left-click interactions with containers, doors, etc.
#
# FEATURES:
# - Left-click to interact with objects
# - Hover highlighting
# - Range checking
# - Works with vision system (can only interact with visible objects)
#
# ==============================================================================

class_name ClickInteraction
extends Node2D


# ==============================================================================
# SIGNALS
# ==============================================================================

signal interaction_requested(target: Node2D)
signal hover_changed(target: Node2D)


# ==============================================================================
# CONSTANTS
# ==============================================================================

## Maximum distance player can interact with objects
const MAX_INTERACTION_DISTANCE: float = 120.0

## Highlight color for interactable objects
const HIGHLIGHT_COLOR: Color = Color(1.0, 1.0, 0.5, 0.3)


# ==============================================================================
# EXPORTS
# ==============================================================================

@export var enabled: bool = true
@export var show_interaction_range: bool = false


# ==============================================================================
# STATE
# ==============================================================================

var player: Node2D = null
var vision_system = null  # VisionSystem instance
var current_hover: Node2D = null
var interactables: Array[Node2D] = []


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Find all interactable objects in the scene
	_refresh_interactables()


func _process(_delta: float) -> void:
	if not enabled or not player:
		return
	
	# Update hover state
	_update_hover()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or not player:
		return
	
	# Left click to interact
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click()


# ==============================================================================
# SETUP
# ==============================================================================

func initialize(p_player: Node2D, p_vision = null) -> void:
	player = p_player
	vision_system = p_vision
	_refresh_interactables()


func _refresh_interactables() -> void:
	interactables.clear()
	
	# Find containers
	for container in get_tree().get_nodes_in_group("containers"):
		if container is Node2D:
			interactables.append(container)
	
	# Find doors
	for door in get_tree().get_nodes_in_group("doors"):
		if door is Node2D:
			interactables.append(door)
	
	# Find other interactables
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is Node2D and node not in interactables:
			interactables.append(node)


## Add a new interactable to track
func register_interactable(node: Node2D) -> void:
	if node not in interactables:
		interactables.append(node)


## Remove an interactable from tracking
func unregister_interactable(node: Node2D) -> void:
	interactables.erase(node)


# ==============================================================================
# HOVER DETECTION
# ==============================================================================

func _update_hover() -> void:
	var mouse_pos = get_global_mouse_position()
	var new_hover: Node2D = null
	var closest_dist: float = INF
	
	for interactable in interactables:
		if not is_instance_valid(interactable):
			continue
		
		# Check if interactable has can_interact method
		if not interactable.has_method("can_interact"):
			continue
		
		if not interactable.can_interact():
			continue
		
		# Check distance from player
		var dist_to_player = player.global_position.distance_to(interactable.global_position)
		if dist_to_player > MAX_INTERACTION_DISTANCE:
			continue
		
		# Check if visible (if vision system exists)
		if vision_system and not vision_system.is_position_visible(interactable.global_position):
			continue
		
		# Check if mouse is over this interactable
		var dist_to_mouse = mouse_pos.distance_to(interactable.global_position)
		
		# Use a generous hit radius
		var hit_radius = _get_hit_radius(interactable)
		if dist_to_mouse <= hit_radius and dist_to_mouse < closest_dist:
			closest_dist = dist_to_mouse
			new_hover = interactable
	
	# Update hover state
	if new_hover != current_hover:
		# Unhighlight old
		if current_hover and is_instance_valid(current_hover):
			_set_highlight(current_hover, false)
		
		current_hover = new_hover
		
		# Highlight new
		if current_hover:
			_set_highlight(current_hover, true)
		
		hover_changed.emit(current_hover)


func _get_hit_radius(node: Node2D) -> float:
	# Try to get size from collision shape or use default
	if node.has_node("CollisionShape2D"):
		var col = node.get_node("CollisionShape2D")
		if col.shape is RectangleShape2D:
			var rect_shape = col.shape as RectangleShape2D
			return maxf(rect_shape.size.x, rect_shape.size.y) * 0.6
		if col.shape is CircleShape2D:
			var circle_shape = col.shape as CircleShape2D
			return circle_shape.radius * 1.2
	
	# Default hit radius
	return 40.0


func _set_highlight(node: Node2D, highlighted: bool) -> void:
	if node.has_method("set_highlighted"):
		node.set_highlighted(highlighted)
	elif node.has_node("Sprite2D"):
		var sprite = node.get_node("Sprite2D")
		if highlighted:
			sprite.modulate = sprite.modulate.lightened(0.3)
		else:
			sprite.modulate = sprite.modulate.darkened(0.3)


# ==============================================================================
# CLICK HANDLING
# ==============================================================================

func _handle_click() -> void:
	if current_hover and is_instance_valid(current_hover):
		# Verify still in range
		var dist = player.global_position.distance_to(current_hover.global_position)
		if dist <= MAX_INTERACTION_DISTANCE:
			interaction_requested.emit(current_hover)


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Get the currently hovered interactable
func get_hovered_interactable() -> Node2D:
	return current_hover


## Check if player can interact with a specific target
func can_interact_with(target: Node2D) -> bool:
	if not target or not is_instance_valid(target):
		return false
	
	if not target.has_method("can_interact"):
		return false
	
	if not target.can_interact():
		return false
	
	var dist = player.global_position.distance_to(target.global_position)
	if dist > MAX_INTERACTION_DISTANCE:
		return false
	
	if vision_system and not vision_system.is_position_visible(target.global_position):
		return false
	
	return true


## Force interact with a target (bypasses click)
func interact_with(target: Node2D) -> void:
	if can_interact_with(target):
		interaction_requested.emit(target)


# ==============================================================================
# DEBUG DRAWING
# ==============================================================================

func _draw() -> void:
	if not show_interaction_range or not player:
		return
	
	# Draw interaction range circle
	var player_local = to_local(player.global_position)
	draw_arc(player_local, MAX_INTERACTION_DISTANCE, 0, TAU, 32, Color(1, 1, 0, 0.3), 2)
	
	# Draw lines to interactables in range
	for interactable in interactables:
		if not is_instance_valid(interactable):
			continue
		
		var dist = player.global_position.distance_to(interactable.global_position)
		if dist <= MAX_INTERACTION_DISTANCE:
			var target_local = to_local(interactable.global_position)
			var color = Color.GREEN if interactable == current_hover else Color.YELLOW
			color.a = 0.5
			draw_line(player_local, target_local, color, 1)
