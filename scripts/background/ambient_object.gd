# ==============================================================================
# AMBIENT OBJECT - BASE CLASS FOR BACKGROUND ATMOSPHERE OBJECTS
# ==============================================================================
#
# FILE: scripts/background/ambient_object.gd
# PURPOSE: Base class for all ambient objects that bring space to life
#
# FEATURES:
# - Movement across screen
# - Automatic despawn when off-screen
# - Visual-only (no gameplay interaction)
# - Configurable speed and direction
#
# ==============================================================================

class_name AmbientObject
extends Node2D


# ==============================================================================
# ENUMS
# ==============================================================================

enum ObjectType {
	## Static or slow-moving objects
	PLANET,
	MOON,
	SPACE_STATION,
	ASTEROID_CLUSTER,
	
	## Moving objects
	SHIP,
	COMET,
	SATELLITE,
	ESCAPE_POD,
	
	## Rare events
	EXPLOSION,
	JUMP_GATE,
	SOLAR_FLARE,
	METEOR_SHOWER
}


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Movement")
## Movement velocity
@export var velocity: Vector2 = Vector2(-50, 0)

## Rotation speed (radians per second)
@export var rotation_speed: float = 0.0


@export_group("Appearance")
## Object type
@export var object_type: ObjectType = ObjectType.PLANET

## Visual scale
@export var visual_scale: float = 1.0

## Base color
@export var base_color: Color = Color.WHITE


@export_group("Lifecycle")
## Auto-despawn when this far off-screen
@export var despawn_distance: float = 200.0


# ==============================================================================
# STATE
# ==============================================================================

var _screen_size: Vector2
var _is_active: bool = true


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_screen_size = get_viewport_rect().size
	_initialize()


func _process(delta: float) -> void:
	if not _is_active:
		return
	
	# Move object
	position += velocity * delta
	
	# Rotate if configured
	if rotation_speed != 0.0:
		rotation += rotation_speed * delta
	
	# Check if should despawn
	if _should_despawn():
		despawn()


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _initialize() -> void:
	# Override in subclasses for specific setup
	scale = Vector2(visual_scale, visual_scale)


# ==============================================================================
# DESPAWN LOGIC
# ==============================================================================

func _should_despawn() -> bool:
	# Check if object is too far off-screen
	var margin := despawn_distance
	
	return (position.x < -margin or 
			position.x > _screen_size.x + margin or
			position.y < -margin or
			position.y > _screen_size.y + margin)


func despawn() -> void:
	_is_active = false
	queue_free()


# ==============================================================================
# PUBLIC API
# ==============================================================================

func set_velocity(new_velocity: Vector2) -> void:
	velocity = new_velocity


func set_screen_size(size: Vector2) -> void:
	_screen_size = size


func is_active() -> bool:
	return _is_active
