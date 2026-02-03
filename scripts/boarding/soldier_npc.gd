# ==============================================================================
# SOLDIER NPC - ENEMY GUARD FOR BOARDING SCENES
# ==============================================================================
#
# FILE: scripts/boarding/soldier_npc.gd
# PURPOSE: Enemy soldier that patrols, detects player, and engages in combat
#
# FEATURES:
# - 45 degree cone vision detection
# - Patrol waypoint system
# - Chase and search behavior
# - Laser weapon combat
# - Awareness of player stealth/hiding
#
# STATES:
# - PATROL: Following waypoints
# - SUSPICIOUS: Heard something, investigating
# - ALERT: Spotted player, moving to engage
# - CHASE: Actively pursuing player
# - SEARCH: Lost sight, searching last known position
# - ATTACK: In range, shooting at player
#
# ==============================================================================

extends CharacterBody2D
class_name SoldierNPC


# ==============================================================================
# SIGNALS
# ==============================================================================

signal player_spotted(player: Node2D)
signal player_lost()
signal soldier_died()
signal shot_fired(position: Vector2, direction: Vector2)


# ==============================================================================
# ENUMS
# ==============================================================================

enum State {
	PATROL,
	SUSPICIOUS,
	ALERT,
	CHASE,
	SEARCH,
	ATTACK,
	DEAD
}


# ==============================================================================
# CONSTANTS
# ==============================================================================

const VISION_CONE_ANGLE := 45.0  # Degrees (total cone is 90 degrees)
const VISION_RANGE := 300.0
const PERIPHERAL_RANGE := 80.0  # Can detect player behind at close range
const PATROL_SPEED := 80.0
const CHASE_SPEED := 150.0
const ATTACK_RANGE := 250.0
const ATTACK_COOLDOWN := 1.0
const SEARCH_DURATION := 5.0
const SUSPICIOUS_DURATION := 2.0


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Movement")
@export var patrol_speed: float = PATROL_SPEED
@export var chase_speed: float = CHASE_SPEED

@export_group("Vision")
@export var vision_range: float = VISION_RANGE
@export var vision_angle: float = VISION_CONE_ANGLE
@export var peripheral_range: float = PERIPHERAL_RANGE

@export_group("Combat")
@export var max_health: int = 50
@export var laser_damage: int = 10
@export var attack_range: float = ATTACK_RANGE
@export var fire_rate: float = 1.0

@export_group("Patrol")
@export var patrol_points: Array[Vector2] = []
@export var wait_time_at_point: float = 2.0

@export_group("Debug")
## Enable vision cone debug draw (impacts performance)
@export var debug_draw_vision: bool = false


# ==============================================================================
# STATE
# ==============================================================================

var current_state: State = State.PATROL
var health: int = 50
var target_player: Node2D = null
var last_known_player_pos: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT

## Patrol
var current_patrol_index: int = 0
var patrol_wait_timer: float = 0.0

## Combat
var attack_timer: float = 0.0

## Search/Suspicious
var search_timer: float = 0.0
var suspicious_timer: float = 0.0

## Detection
var detection_level: float = 0.0  # 0-1, builds up when player is partially visible
var player_in_container: bool = false


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var vision_raycast: RayCast2D = $VisionRaycast
@onready var sprite: Node2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var vision_area: Area2D = $VisionArea
@onready var alert_indicator: Node2D = $AlertIndicator


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	add_to_group("soldiers")
	
	# Setup collision
	collision_layer = 4  # Enemy layer
	collision_mask = 1 | 2  # World and player
	
	# Initialize facing direction
	if patrol_points.size() > 0:
		var first_point = patrol_points[0]
		if global_position.distance_to(first_point) > 10:
			facing_direction = (first_point - global_position).normalized()
	
	_update_vision_cone()


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	# Update timers
	_update_timers(delta)
	
	# State machine
	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.SUSPICIOUS:
			_process_suspicious(delta)
		State.ALERT:
			_process_alert(delta)
		State.CHASE:
			_process_chase(delta)
		State.SEARCH:
			_process_search(delta)
		State.ATTACK:
			_process_attack(delta)
	
	# Check for player detection
	_check_vision()
	
	# Move
	move_and_slide()
	
	# Update visuals
	_update_visuals()


# ==============================================================================
# STATE PROCESSING
# ==============================================================================

func _process_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		# No patrol points, just stand guard
		velocity = Vector2.ZERO
		return
	
	var target_point = patrol_points[current_patrol_index]
	var distance = global_position.distance_to(target_point)
	
	if distance < 10:
		# Reached patrol point, wait
		velocity = Vector2.ZERO
		patrol_wait_timer += delta
		
		if patrol_wait_timer >= wait_time_at_point:
			patrol_wait_timer = 0
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
			
			# Face next point
			var next_point = patrol_points[current_patrol_index]
			facing_direction = (next_point - global_position).normalized()
	else:
		# Move to patrol point
		facing_direction = (target_point - global_position).normalized()
		velocity = facing_direction * patrol_speed


func _process_suspicious(delta: float) -> void:
	# Turn toward sound/disturbance
	if last_known_player_pos != Vector2.ZERO:
		facing_direction = (last_known_player_pos - global_position).normalized()
	
	velocity = Vector2.ZERO
	suspicious_timer += delta
	
	if suspicious_timer >= SUSPICIOUS_DURATION:
		suspicious_timer = 0
		_change_state(State.PATROL)


func _process_alert(_delta: float) -> void:
	if not is_instance_valid(target_player):
		_change_state(State.SEARCH)
		return
	
	# Move toward player
	var direction = (target_player.global_position - global_position).normalized()
	facing_direction = direction
	velocity = direction * chase_speed
	
	# Check if in attack range
	var distance = global_position.distance_to(target_player.global_position)
	if distance <= attack_range:
		_change_state(State.ATTACK)


func _process_chase(_delta: float) -> void:
	if not is_instance_valid(target_player):
		_change_state(State.SEARCH)
		return
	
	# Check if player is hiding
	if player_in_container:
		_change_state(State.SEARCH)
		return
	
	# Check if we can still see the player
	if not _can_see_player():
		last_known_player_pos = target_player.global_position
		_change_state(State.SEARCH)
		return
	
	# Pursue
	var direction = (target_player.global_position - global_position).normalized()
	facing_direction = direction
	velocity = direction * chase_speed
	
	# Check attack range
	var distance = global_position.distance_to(target_player.global_position)
	if distance <= attack_range:
		_change_state(State.ATTACK)


func _process_search(delta: float) -> void:
	search_timer += delta
	
	# Move toward last known position
	var distance = global_position.distance_to(last_known_player_pos)
	
	if distance > 20:
		var direction = (last_known_player_pos - global_position).normalized()
		facing_direction = direction
		velocity = direction * patrol_speed
	else:
		# Reached last known position, look around
		velocity = Vector2.ZERO
		# Slowly rotate to search
		facing_direction = facing_direction.rotated(delta * 1.5)
	
	if search_timer >= SEARCH_DURATION:
		search_timer = 0
		target_player = null
		player_lost.emit()
		_change_state(State.PATROL)


func _process_attack(_delta: float) -> void:
	if not is_instance_valid(target_player):
		_change_state(State.SEARCH)
		return
	
	# Face player
	facing_direction = (target_player.global_position - global_position).normalized()
	velocity = Vector2.ZERO
	
	# Check if player moved out of range
	var distance = global_position.distance_to(target_player.global_position)
	if distance > attack_range * 1.2:
		_change_state(State.CHASE)
		return
	
	# Check if we can still see them
	if not _can_see_player() or player_in_container:
		last_known_player_pos = target_player.global_position
		_change_state(State.SEARCH)
		return
	
	# Fire weapon
	if attack_timer <= 0:
		_fire_laser()
		attack_timer = 1.0 / fire_rate


func _update_timers(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta


func _change_state(new_state: State) -> void:
	var _old_state = current_state
	current_state = new_state
	
	# State enter logic
	match new_state:
		State.SEARCH:
			search_timer = 0
		State.SUSPICIOUS:
			suspicious_timer = 0
		State.ALERT:
			if target_player:
				player_spotted.emit(target_player)
		State.CHASE:
			if target_player:
				player_spotted.emit(target_player)


# ==============================================================================
# VISION SYSTEM
# ==============================================================================

func _check_vision() -> void:
	if current_state == State.DEAD:
		return
	
	# Find player in scene
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	
	var player = players[0]
	
	# Check if player is hiding in container
	if player.has_method("is_hiding") and player.is_hiding():
		player_in_container = true
		if current_state == State.ATTACK or current_state == State.CHASE:
			last_known_player_pos = player.global_position
			_change_state(State.SEARCH)
		return
	
	player_in_container = false
	
	# Check if player is in stealth and we're not already alerted
	var player_stealth = 0
	if player.has_method("get_stealth_level"):
		player_stealth = player.get_stealth_level()
	
	# Calculate detection
	var can_see = _can_see_position(player.global_position)
	var distance = global_position.distance_to(player.global_position)
	
	if can_see:
		# Stealth reduces detection range
		var effective_range = vision_range * (1.0 - player_stealth * 0.5)
		
		if distance <= effective_range:
			target_player = player
			
			# Immediate detection if already alert or player is close
			if current_state in [State.ALERT, State.CHASE, State.ATTACK] or distance < 50:
				if current_state == State.PATROL or current_state == State.SUSPICIOUS:
					_change_state(State.ALERT)
				elif current_state == State.SEARCH:
					_change_state(State.CHASE)
			else:
				# Build up detection
				detection_level += 0.02 * (1.0 - distance / effective_range)
				
				if detection_level >= 1.0:
					detection_level = 0
					_change_state(State.ALERT)
	else:
		# Peripheral/hearing detection at close range
		if distance <= peripheral_range:
			if current_state == State.PATROL:
				last_known_player_pos = player.global_position
				_change_state(State.SUSPICIOUS)
		
		# Decay detection level
		detection_level = maxf(0, detection_level - 0.01)


func _can_see_player() -> bool:
	if not is_instance_valid(target_player):
		return false
	return _can_see_position(target_player.global_position)


func _can_see_position(pos: Vector2) -> bool:
	var to_pos = pos - global_position
	var distance = to_pos.length()
	
	# Check range
	if distance > vision_range:
		return false
	
	# Check angle (cone vision)
	var angle_to_pos = rad_to_deg(facing_direction.angle_to(to_pos))
	if abs(angle_to_pos) > vision_angle:
		return false
	
	# Raycast check for obstacles
	if vision_raycast:
		vision_raycast.target_position = to_pos
		vision_raycast.force_raycast_update()
		
		if vision_raycast.is_colliding():
			var collider = vision_raycast.get_collider()
			# Check if we hit the player or something blocking vision
			if collider and collider.is_in_group("player"):
				return true
			return false
	
	return true


func _update_vision_cone() -> void:
	# Update the visual vision cone (done in _draw)
	# Only trigger redraw in debug mode for performance
	if debug_draw_vision:
		queue_redraw()


# ==============================================================================
# COMBAT
# ==============================================================================

func _fire_laser() -> void:
	if not is_instance_valid(target_player):
		return
	
	# Calculate shot direction with some spread
	var direction = (target_player.global_position - global_position).normalized()
	var spread = randf_range(-0.1, 0.1)
	direction = direction.rotated(spread)
	
	shot_fired.emit(global_position, direction)
	
	# Create laser projectile
	_spawn_laser(direction)
	
	# Play sound
	if AudioManager:
		AudioManager.play_sfx("laser_shot")


func _spawn_laser(direction: Vector2) -> void:
	# Create simple laser projectile
	var laser = _create_laser_projectile()
	laser.global_position = global_position + direction * 20
	laser.direction = direction
	laser.damage = laser_damage
	laser.shooter = self
	
	get_parent().add_child(laser)


func _create_laser_projectile() -> Node2D:
	# Create a simple laser projectile node
	var laser = Area2D.new()
	laser.set_script(preload("res://scripts/boarding/soldier_laser.gd"))
	
	# Collision
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 4
	shape.shape = circle
	laser.add_child(shape)
	
	# Visual
	var visual = ColorRect.new()
	visual.size = Vector2(12, 4)
	visual.position = Vector2(-6, -2)
	visual.color = Color(1, 0.2, 0.2)
	laser.add_child(visual)
	
	# Collision settings
	laser.collision_layer = 8  # Projectile layer
	laser.collision_mask = 2  # Player layer
	
	return laser


func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return
	
	health -= amount
	
	# Flash red
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	# Alert if not already
	if current_state == State.PATROL or current_state == State.SUSPICIOUS:
		# Look for attacker
		var players = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target_player = players[0]
			last_known_player_pos = target_player.global_position
			_change_state(State.ALERT)
	
	if health <= 0:
		_die()


func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	soldier_died.emit()
	
	# Death animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


# ==============================================================================
# VISUALS
# ==============================================================================

func _update_visuals() -> void:
	# Rotate sprite to face direction
	if sprite:
		sprite.rotation = facing_direction.angle()
	
	# Update alert indicator
	if alert_indicator:
		match current_state:
			State.PATROL:
				alert_indicator.visible = false
			State.SUSPICIOUS:
				alert_indicator.visible = true
				alert_indicator.modulate = Color.YELLOW
			State.ALERT, State.CHASE, State.ATTACK:
				alert_indicator.visible = true
				alert_indicator.modulate = Color.RED
			State.SEARCH:
				alert_indicator.visible = true
				alert_indicator.modulate = Color.ORANGE


func _draw() -> void:
	# Only draw vision cone in debug mode - significant performance impact
	if not debug_draw_vision:
		return
	
	if current_state == State.DEAD:
		return
	
	var cone_color = Color(1, 1, 0, 0.1)
	
	match current_state:
		State.SUSPICIOUS:
			cone_color = Color(1, 0.8, 0, 0.15)
		State.ALERT, State.CHASE, State.ATTACK:
			cone_color = Color(1, 0.2, 0.2, 0.2)
		State.SEARCH:
			cone_color = Color(1, 0.5, 0, 0.15)
	
	# Draw cone
	var points: PackedVector2Array = []
	points.append(Vector2.ZERO)
	
	var angle_step = vision_angle * 2 / 10
	for i in range(11):
		var angle = -vision_angle + angle_step * i
		var dir = facing_direction.rotated(deg_to_rad(angle))
		points.append(dir * vision_range)
	
	draw_colored_polygon(points, cone_color)


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Set patrol path from array of global positions
func set_patrol_path(points: Array[Vector2]) -> void:
	patrol_points = points
	current_patrol_index = 0


## Alert the soldier to a position (sound, etc)
func alert_to_position(pos: Vector2) -> void:
	if current_state == State.PATROL:
		last_known_player_pos = pos
		_change_state(State.SUSPICIOUS)


## Check if soldier is alerted
func is_alerted() -> bool:
	return current_state in [State.ALERT, State.CHASE, State.ATTACK]


## Get current state name (for debugging)
func get_state_name() -> String:
	match current_state:
		State.PATROL: return "Patrol"
		State.SUSPICIOUS: return "Suspicious"
		State.ALERT: return "Alert"
		State.CHASE: return "Chase"
		State.SEARCH: return "Search"
		State.ATTACK: return "Attack"
		State.DEAD: return "Dead"
	return "Unknown"
