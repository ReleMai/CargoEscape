# ==============================================================================
# SOLDIER LASER PROJECTILE
# ==============================================================================
#
# FILE: scripts/boarding/soldier_laser.gd
# PURPOSE: Laser projectile fired by soldier NPCs
#
# ==============================================================================

extends Area2D
class_name SoldierLaser


# ==============================================================================
# CONSTANTS
# ==============================================================================

const SPEED := 600.0
const LIFETIME := 2.0


# ==============================================================================
# STATE
# ==============================================================================

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10
var shooter: Node2D = null
var lifetime: float = LIFETIME


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Connect collision
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Rotate to face direction
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	# Move
	position += direction * SPEED * delta
	
	# Lifetime
	lifetime -= delta
	if lifetime <= 0:
		queue_free()


# ==============================================================================
# COLLISION
# ==============================================================================

func _on_body_entered(body: Node2D) -> void:
	if body == shooter:
		return
	
	if body.is_in_group("player"):
		_hit_player(body)
	elif not body.is_in_group("enemies"):
		# Hit wall or obstacle
		_hit_obstacle()


func _on_area_entered(area: Area2D) -> void:
	# Could hit player's hurtbox area
	var parent = area.get_parent()
	if parent and parent.is_in_group("player"):
		_hit_player(parent)


func _hit_player(player: Node2D) -> void:
	if player.has_method("take_damage"):
		player.take_damage(damage)
	
	# Spawn hit effect
	_spawn_hit_effect()
	queue_free()


func _hit_obstacle() -> void:
	_spawn_hit_effect()
	queue_free()


func _spawn_hit_effect() -> void:
	# Simple particle burst
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.3
	particles.direction = -direction
	particles.spread = 45
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 100
	particles.gravity = Vector2.ZERO
	particles.color = Color(1, 0.3, 0.2)
	
	particles.global_position = global_position
	get_parent().add_child(particles)
	
	# Auto-cleanup
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)
