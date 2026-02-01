# ==============================================================================
# LASER PROJECTILE
# ==============================================================================
#
# FILE: scripts/laser.gd
# PURPOSE: Basic laser projectile fired by the player
#
# ==============================================================================

extends Area2D
class_name Laser


# ==============================================================================
# SIGNALS
# ==============================================================================

signal hit_target(target: Node2D)


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Laser Stats")

## Damage dealt to targets (percentage of their max health)
@export var damage: float = 25.0

## Speed of the laser (pixels/second)
@export var speed: float = 800.0

## How long the laser lives before despawning (seconds)
@export var lifetime: float = 2.0


# ==============================================================================
# STATE
# ==============================================================================

var direction: Vector2 = Vector2.RIGHT
var time_alive: float = 0.0


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Connect to area detection
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Set collision - laser is on layer 4 (projectiles), detects layer 2 (enemies)
	collision_layer = 4
	collision_mask = 2


func _process(delta: float) -> void:
	# Move in direction
	position += direction * speed * delta
	
	# Track lifetime
	time_alive += delta
	if time_alive >= lifetime:
		ObjectPool.release(self)
		return
	
	# Cleanup if off screen
	var screen_size = get_viewport_rect().size
	if position.x < -50 or position.x > screen_size.x + 50:
		ObjectPool.release(self)
		return
	if position.y < -50 or position.y > screen_size.y + 50:
		ObjectPool.release(self)
		return


# ==============================================================================
# COLLISION
# ==============================================================================

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		_hit_enemy(area)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		_hit_enemy(body)


func _hit_enemy(enemy: Node2D) -> void:
	# Deal damage if enemy has health
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	else:
		# Old enemies without health - just destroy them
		if enemy.has_method("destroy"):
			enemy.destroy()
	
	hit_target.emit(enemy)
	
	# Return laser to pool on hit
	ObjectPool.release(self)


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Set the direction of the laser
func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()
	# Rotate sprite to match direction
	rotation = direction.angle()


## Set damage (for upgrades)
func set_damage(new_damage: float) -> void:
	damage = new_damage


## Reset the laser for object pooling
func reset() -> void:
	# Reset state
	time_alive = 0.0
	direction = Vector2.RIGHT
	
	# Reset visual
	rotation = 0
	modulate = Color.WHITE
