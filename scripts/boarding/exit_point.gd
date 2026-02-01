# ==============================================================================
# EXIT POINT - ESCAPE LOCATION
# ==============================================================================
#
# FILE: scripts/boarding/exit_point.gd
# PURPOSE: The area where players escape from the ship with their loot
#
# ==============================================================================

extends Area2D
class_name ExitPoint

# ==============================================================================
# SIGNALS
# ==============================================================================

signal player_entered
signal escape_triggered

# ==============================================================================
# EXPORTS
# ==============================================================================

@export var exit_name: String = "Airlock"
@export var require_minimum_loot: bool = false
@export var minimum_loot_value: int = 100

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var particles: GPUParticles2D = $Particles

# ==============================================================================
# STATE
# ==============================================================================

var is_active: bool = true
var player_in_range: bool = false

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	add_to_group("exit_point")
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_setup_visuals()


# ==============================================================================
# INTERACTION
# ==============================================================================

func can_interact() -> bool:
	return is_active


func get_interact_prompt() -> String:
	return "[E] ESCAPE!"


func trigger_escape() -> void:
	if not is_active:
		return
	
	emit_signal("escape_triggered")


func set_active(active: bool) -> void:
	is_active = active
	_update_visuals()


# ==============================================================================
# COLLISION
# ==============================================================================

func _on_body_entered(body: Node2D) -> void:
	if body is BoardingPlayer:
		player_in_range = true
		emit_signal("player_entered")
		_show_escape_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body is BoardingPlayer:
		player_in_range = false
		_hide_escape_prompt()


# ==============================================================================
# VISUALS
# ==============================================================================

const EXIT_SPRITE_PATH = "res://assets/sprites/boarding/exit_point.svg"

func _setup_visuals() -> void:
	if label:
		label.text = exit_name
	
	# Load exit point sprite
	_load_exit_sprite()
	
	_update_visuals()


## Load the SVG sprite for the exit point
func _load_exit_sprite() -> void:
	if not sprite:
		return
	
	if ResourceLoader.exists(EXIT_SPRITE_PATH):
		var texture = load(EXIT_SPRITE_PATH)
		if texture:
			sprite.texture = texture
			sprite.scale = Vector2(1, 1)  # Adjust scale as needed
			
			# Hide the old ColorRect children if they exist
			for child in sprite.get_children():
				if child is ColorRect:
					child.visible = false
	else:
		print("Warning: Exit sprite not found: ", EXIT_SPRITE_PATH)


func _update_visuals() -> void:
	if sprite:
		sprite.modulate = Color(0.3, 1.0, 0.5) if is_active else Color(0.5, 0.5, 0.5)
	
	if particles:
		particles.emitting = is_active


func _show_escape_prompt() -> void:
	if label:
		label.text = "ESCAPE!\n[E]"
		label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))


func _hide_escape_prompt() -> void:
	if label:
		label.text = exit_name
		label.remove_theme_color_override("font_color")
