# ==============================================================================
# HIDEABLE OBJECT - PLAYER CAN HIDE INSIDE FOR STEALTH
# ==============================================================================
#
# FILE: scripts/boarding/hideable_object.gd
# PURPOSE: Objects the player can hide in to avoid detection
#
# FEATURES:
# - Player can enter/exit hiding with context menu or E key
# - Visual feedback when player is hiding
# - Integrate with enemy AI vision system
#
# ==============================================================================

extends Area2D
class_name HideableObject


# ==============================================================================
# SIGNALS
# ==============================================================================

signal player_entered_hiding
signal player_exited_hiding


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Hiding")
## Display name for context menu
@export var object_name: String = "Locker"
## How long it takes to enter/exit (seconds)
@export var enter_time: float = 0.5
## Can player be detected while hiding (some objects are better)
@export var stealth_rating: float = 1.0  # 1.0 = invisible, 0.5 = partially visible

@export_group("Visuals")
@export var normal_color: Color = Color(0.5, 0.5, 0.55)
@export var highlight_color: Color = Color(0.7, 0.7, 0.8)
@export var occupied_color: Color = Color(0.4, 0.5, 0.6)


# ==============================================================================
# STATE
# ==============================================================================

var is_occupied: bool = false
var player_inside: Node2D = null
var is_player_nearby: bool = false
var _current_player: Node2D = null


# ==============================================================================
# NODES
# ==============================================================================

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var collision_shape: CollisionShape2D = \
	$CollisionShape2D if has_node("CollisionShape2D") else null


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _ready() -> void:
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Set up collision layers
	collision_layer = 0
	collision_mask = 2  # Player layer
	
	# Initial visual
	_update_visuals()


# ==============================================================================
# INPUT
# ==============================================================================

func _input(event: InputEvent) -> void:
	if not is_player_nearby and not is_occupied:
		return
	
	# E to enter/exit hiding
	if event.is_action_pressed("interact"):
		if is_occupied:
			exit_hiding()
		elif is_player_nearby and _current_player:
			enter_hiding(_current_player)
			get_viewport().set_input_as_handled()


# ==============================================================================
# HIDING MECHANICS
# ==============================================================================

## Player enters hiding in this object
func enter_hiding(player: Node2D) -> void:
	if is_occupied or not player:
		return
	
	if not player.has_method("enter_hiding"):
		push_warning("HideableObject: Player doesn't have enter_hiding method")
		return
	
	is_occupied = true
	player_inside = player
	
	# Tell player to enter hiding
	player.enter_hiding(self)
	
	# Store player's original position for exit
	_update_visuals()
	player_entered_hiding.emit()
	
	# Play hiding sound
	if AudioManager:
		AudioManager.play_sfx_varied("hide_enter", 0.1, -3.0)


## Player exits hiding
func exit_hiding() -> void:
	if not is_occupied or not player_inside:
		return
	
	# Tell player to exit
	if player_inside.has_method("exit_hiding"):
		player_inside.exit_hiding()
	
	is_occupied = false
	player_inside = null
	
	_update_visuals()
	player_exited_hiding.emit()
	
	# Play exit sound
	if AudioManager:
		AudioManager.play_sfx_varied("hide_exit", 0.1, -3.0)


## Get stealth rating (how well this hides the player)
func get_stealth_rating() -> float:
	return stealth_rating


## Check if player can hide here
func can_hide() -> bool:
	return not is_occupied


# ==============================================================================
# CONTEXT MENU
# ==============================================================================

## Called when context menu requests actions
func get_context_actions() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	
	if is_occupied:
		actions.append({
			"id": "exit_hiding",
			"label": "Exit " + object_name,
			"icon": "exit",
			"callback": exit_hiding
		})
	elif is_player_nearby:
		actions.append({
			"id": "hide",
			"label": "Hide in " + object_name,
			"icon": "hide",
			"callback": func(): enter_hiding(_current_player)
		})
	
	return actions


# ==============================================================================
# COLLISION HANDLING
# ==============================================================================

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		_current_player = body
		_update_visuals()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		if body == _current_player and not is_occupied:
			_current_player = null
		_update_visuals()


# ==============================================================================
# VISUALS
# ==============================================================================

func _update_visuals() -> void:
	if not sprite:
		return
	
	var target_color := normal_color
	
	if is_occupied:
		target_color = occupied_color
	elif is_player_nearby:
		target_color = highlight_color
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", target_color, 0.15)
