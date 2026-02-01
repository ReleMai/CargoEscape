# ==============================================================================
# AMBIENT OBJECT SPAWNER - BACKGROUND ATMOSPHERE SYSTEM
# ==============================================================================
#
# FILE: scripts/background/ambient_spawner.gd
# PURPOSE: Spawns ambient objects to bring the space environment to life
#
# FEATURES:
# - Random spawn timers for different object types
# - Off-screen spawn positioning
# - Max concurrent objects limit
# - Distance-based despawn (handled by objects)
# - Visual-only (no gameplay interaction)
#
# OBJECT TYPES:
# - Static/Slow: Planets, Moons, Space Stations, Asteroid Clusters
# - Moving: Ships, Comets, Satellites, Escape Pods
# - Events (Rare): Explosions, Jump Gates, Solar Flares, Meteor Showers
#
# ==============================================================================

class_name AmbientSpawner
extends Node2D


# ==============================================================================
# SIGNALS
# ==============================================================================

signal object_spawned(obj: AmbientObject)


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Container")
## Container to spawn objects into
@export var object_container: Node2D


@export_group("Spawn Settings")
## Screen size for spawn positioning
@export var screen_size: Vector2 = Vector2(1920, 1080)

## Off-screen spawn margin (how far beyond screen edge)
@export var spawn_margin: float = 100.0


@export_group("Performance")
## Maximum concurrent ambient objects
@export var max_concurrent_objects: int = 15

## Enable spawning
@export var spawning_enabled: bool = true


@export_group("Spawn Rates (seconds)")
## Base interval for static/slow objects
@export var static_object_interval: float = 15.0

## Base interval for moving objects
@export var moving_object_interval: float = 8.0

## Base interval for rare events
@export var rare_event_interval: float = 45.0


@export_group("Object Scenes")
## Planet scene variations
@export var planet_scenes: Array[PackedScene] = []

## Moon scene variations
@export var moon_scenes: Array[PackedScene] = []

## Space station scenes
@export var station_scenes: Array[PackedScene] = []

## Ship scenes (passing by)
@export var ship_scenes: Array[PackedScene] = []

## Comet scenes
@export var comet_scenes: Array[PackedScene] = []

## Event scenes
@export var event_scenes: Array[PackedScene] = []


# ==============================================================================
# STATE
# ==============================================================================

var _static_timer: Timer
var _moving_timer: Timer
var _event_timer: Timer
var _active_objects: Array[AmbientObject] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_rng.randomize()
	_setup_timers()
	
	if not object_container:
		# Create default container
		object_container = Node2D.new()
		object_container.name = "AmbientObjectContainer"
		object_container.z_index = -50  # Behind gameplay elements
		add_child(object_container)


func _process(_delta: float) -> void:
	# Clean up inactive objects
	_cleanup_inactive_objects()


# ==============================================================================
# TIMER SETUP
# ==============================================================================

func _setup_timers() -> void:
	# Static/Slow objects timer
	_static_timer = Timer.new()
	_static_timer.wait_time = static_object_interval
	_static_timer.one_shot = false
	_static_timer.timeout.connect(_on_static_timer_timeout)
	add_child(_static_timer)
	
	# Moving objects timer
	_moving_timer = Timer.new()
	_moving_timer.wait_time = moving_object_interval
	_moving_timer.one_shot = false
	_moving_timer.timeout.connect(_on_moving_timer_timeout)
	add_child(_moving_timer)
	
	# Rare events timer
	_event_timer = Timer.new()
	_event_timer.wait_time = rare_event_interval
	_event_timer.one_shot = false
	_event_timer.timeout.connect(_on_event_timer_timeout)
	add_child(_event_timer)
	
	# Start timers if enabled
	if spawning_enabled:
		start_spawning()


# ==============================================================================
# PUBLIC API
# ==============================================================================

func start_spawning() -> void:
	spawning_enabled = true
	_static_timer.start()
	_moving_timer.start()
	_event_timer.start()


func stop_spawning() -> void:
	spawning_enabled = false
	_static_timer.stop()
	_moving_timer.stop()
	_event_timer.stop()


func clear_all_objects() -> void:
	for obj in _active_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	_active_objects.clear()


func set_screen_size(size: Vector2) -> void:
	screen_size = size


# ==============================================================================
# SPAWN LOGIC
# ==============================================================================

func _on_static_timer_timeout() -> void:
	if not _can_spawn():
		return
	
	_spawn_static_object()


func _on_moving_timer_timeout() -> void:
	if not _can_spawn():
		return
	
	_spawn_moving_object()


func _on_event_timer_timeout() -> void:
	if not _can_spawn():
		return
	
	# Events are rare - only 30% chance when timer fires
	if _rng.randf() < 0.3:
		_spawn_event()


func _can_spawn() -> bool:
	if not spawning_enabled:
		return false
	
	if _active_objects.size() >= max_concurrent_objects:
		return false
	
	return true


# ==============================================================================
# STATIC OBJECT SPAWNING
# ==============================================================================

func _spawn_static_object() -> void:
	var object_type := _rng.randi() % 4  # 0-3 for planet/moon/station/cluster
	
	match object_type:
		0:  # Planet
			_spawn_planet()
		1:  # Moon
			_spawn_moon()
		2:  # Space Station
			_spawn_space_station()
		3:  # Asteroid Cluster
			_spawn_asteroid_cluster()


func _spawn_planet() -> void:
	if planet_scenes.is_empty():
		# Create a simple procedural planet
		_spawn_procedural_planet()
		return
	
	var scene := planet_scenes[_rng.randi() % planet_scenes.size()]
	var planet := scene.instantiate() as AmbientObject
	_finalize_spawn(planet, Vector2(-20, 0), AmbientObject.ObjectType.PLANET)


func _spawn_procedural_planet() -> void:
	# Create a simple visual planet using Node2D and drawing
	var planet := AmbientObject.new()
	planet.object_type = AmbientObject.ObjectType.PLANET
	planet.visual_scale = _rng.randf_range(0.5, 2.0)
	planet.rotation_speed = _rng.randf_range(-0.1, 0.1)
	
	# Add visual (colored circle)
	var sprite := _create_planet_sprite()
	planet.add_child(sprite)
	
	_finalize_spawn(planet, Vector2(-20, 0), AmbientObject.ObjectType.PLANET)


func _create_planet_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	var size := _rng.randf_range(40, 120)
	
	# Planet colors
	var colors := [
		Color(0.8, 0.6, 0.4),  # Desert
		Color(0.4, 0.6, 0.8),  # Ocean
		Color(0.6, 0.3, 0.2),  # Red planet
		Color(0.5, 0.7, 0.5),  # Green
		Color(0.7, 0.7, 0.9),  # Ice
	]
	
	var color := colors[_rng.randi() % colors.size()]
	
	# Store drawing info in metadata
	visual.set_meta("planet_size", size)
	visual.set_meta("planet_color", color)
	visual.set_draw_callback(_draw_planet.bind(visual))
	
	return visual


func _draw_planet(visual: Node2D) -> void:
	var size: float = visual.get_meta("planet_size")
	var color: Color = visual.get_meta("planet_color")
	
	# Draw planet body
	visual.draw_circle(Vector2.ZERO, size, color)
	
	# Draw subtle rim light
	var light_color := Color(color.r * 1.2, color.g * 1.2, color.b * 1.2, 0.3)
	visual.draw_arc(Vector2.ZERO, size, 0, PI, 32, light_color, 3.0)


func _spawn_moon() -> void:
	if moon_scenes.is_empty():
		# Create simple moon
		var moon := AmbientObject.new()
		moon.object_type = AmbientObject.ObjectType.MOON
		moon.visual_scale = _rng.randf_range(0.3, 0.8)
		
		var sprite := _create_moon_sprite()
		moon.add_child(sprite)
		
		_finalize_spawn(moon, Vector2(-15, 0), AmbientObject.ObjectType.MOON)
		return
	
	var scene := moon_scenes[_rng.randi() % moon_scenes.size()]
	var moon := scene.instantiate() as AmbientObject
	_finalize_spawn(moon, Vector2(-15, 0), AmbientObject.ObjectType.MOON)


func _create_moon_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	var size := _rng.randf_range(20, 50)
	var gray := _rng.randf_range(0.5, 0.8)
	var color := Color(gray, gray, gray)
	
	visual.set_meta("moon_size", size)
	visual.set_meta("moon_color", color)
	visual.set_draw_callback(_draw_moon.bind(visual))
	
	return visual


func _draw_moon(visual: Node2D) -> void:
	var size: float = visual.get_meta("moon_size")
	var color: Color = visual.get_meta("moon_color")
	
	# Draw moon
	visual.draw_circle(Vector2.ZERO, size, color)


func _spawn_space_station() -> void:
	if station_scenes.is_empty():
		# Create simple station
		var station := AmbientObject.new()
		station.object_type = AmbientObject.ObjectType.SPACE_STATION
		station.visual_scale = _rng.randf_range(0.4, 1.2)
		station.rotation_speed = _rng.randf_range(-0.05, 0.05)
		
		var sprite := _create_station_sprite()
		station.add_child(sprite)
		
		_finalize_spawn(station, Vector2(-25, 0), AmbientObject.ObjectType.SPACE_STATION)
		return
	
	var scene := station_scenes[_rng.randi() % station_scenes.size()]
	var station := scene.instantiate() as AmbientObject
	_finalize_spawn(station, Vector2(-25, 0), AmbientObject.ObjectType.SPACE_STATION)


func _create_station_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	var size := _rng.randf_range(30, 80)
	
	visual.set_meta("station_size", size)
	visual.set_draw_callback(_draw_station.bind(visual))
	
	return visual


func _draw_station(visual: Node2D) -> void:
	var size: float = visual.get_meta("station_size")
	var gray := Color(0.6, 0.6, 0.7)
	
	# Draw simple station as rectangles
	visual.draw_rect(Rect2(-size/2, -size/4, size, size/2), gray)
	visual.draw_rect(Rect2(-size/4, -size/2, size/2, size), gray)
	
	# Add some lights
	visual.draw_circle(Vector2(-size/3, 0), 3, Color(0, 1, 0, 0.8))
	visual.draw_circle(Vector2(size/3, 0), 3, Color(1, 0, 0, 0.8))


func _spawn_asteroid_cluster() -> void:
	# Spawn a small cluster of tiny asteroids
	var cluster_center := _get_spawn_position(Vector2(-30, 0))
	var count := _rng.randi_range(3, 7)
	
	for i in count:
		var asteroid := AmbientObject.new()
		asteroid.object_type = AmbientObject.ObjectType.ASTEROID_CLUSTER
		asteroid.visual_scale = _rng.randf_range(0.3, 0.6)
		asteroid.rotation_speed = _rng.randf_range(-0.3, 0.3)
		
		var sprite := _create_asteroid_sprite()
		asteroid.add_child(sprite)
		
		# Offset from cluster center
		var offset := Vector2(
			_rng.randf_range(-50, 50),
			_rng.randf_range(-50, 50)
		)
		asteroid.position = cluster_center + offset
		asteroid.velocity = Vector2(_rng.randf_range(-35, -25), 0)
		
		_add_to_container(asteroid)


func _create_asteroid_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	var size := _rng.randf_range(10, 25)
	
	visual.set_meta("asteroid_size", size)
	visual.set_draw_callback(_draw_asteroid.bind(visual))
	
	return visual


func _draw_asteroid(visual: Node2D) -> void:
	var size: float = visual.get_meta("asteroid_size")
	var color := Color(0.4, 0.35, 0.3)
	
	# Draw irregular asteroid shape
	var points: PackedVector2Array = PackedVector2Array()
	var segments := 8
	for i in segments:
		var angle := (float(i) / segments) * TAU
		var radius := size * _rng.randf_range(0.7, 1.0)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	visual.draw_colored_polygon(points, color)


# ==============================================================================
# MOVING OBJECT SPAWNING
# ==============================================================================

func _spawn_moving_object() -> void:
	var object_type := _rng.randi() % 4  # 0-3 for ship/comet/satellite/pod
	
	match object_type:
		0:  # Ship
			_spawn_ship()
		1:  # Comet
			_spawn_comet()
		2:  # Satellite
			_spawn_satellite()
		3:  # Escape Pod
			_spawn_escape_pod()


func _spawn_ship() -> void:
	if ship_scenes.is_empty():
		var ship := AmbientObject.new()
		ship.object_type = AmbientObject.ObjectType.SHIP
		ship.visual_scale = _rng.randf_range(0.8, 1.5)
		
		var sprite := _create_ship_sprite()
		ship.add_child(sprite)
		
		_finalize_spawn(ship, Vector2(_rng.randf_range(-100, -60), 0), AmbientObject.ObjectType.SHIP)
		return
	
	var scene := ship_scenes[_rng.randi() % ship_scenes.size()]
	var ship := scene.instantiate() as AmbientObject
	_finalize_spawn(ship, Vector2(_rng.randf_range(-100, -60), 0), AmbientObject.ObjectType.SHIP)


func _create_ship_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	var length := _rng.randf_range(30, 60)
	
	visual.set_meta("ship_length", length)
	visual.set_draw_callback(_draw_ship.bind(visual))
	
	return visual


func _draw_ship(visual: Node2D) -> void:
	var length: float = visual.get_meta("ship_length")
	var color := Color(0.5, 0.5, 0.6)
	
	# Draw simple ship silhouette
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(-length/2, 0),
		Vector2(length/2, -length/4),
		Vector2(length/2, length/4)
	])
	visual.draw_colored_polygon(points, color)
	
	# Engine glow
	visual.draw_circle(Vector2(length/2, 0), 5, Color(0.3, 0.5, 1.0, 0.7))


func _spawn_comet() -> void:
	if comet_scenes.is_empty():
		var comet := AmbientObject.new()
		comet.object_type = AmbientObject.ObjectType.COMET
		comet.visual_scale = _rng.randf_range(0.6, 1.2)
		
		var sprite := _create_comet_sprite()
		comet.add_child(sprite)
		
		_finalize_spawn(comet, Vector2(_rng.randf_range(-120, -80), _rng.randf_range(-30, 30)), AmbientObject.ObjectType.COMET)
		return
	
	var scene := comet_scenes[_rng.randi() % comet_scenes.size()]
	var comet := scene.instantiate() as AmbientObject
	_finalize_spawn(comet, Vector2(_rng.randf_range(-120, -80), _rng.randf_range(-30, 30)), AmbientObject.ObjectType.COMET)


func _create_comet_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	var size := _rng.randf_range(15, 30)
	
	visual.set_meta("comet_size", size)
	visual.set_draw_callback(_draw_comet.bind(visual))
	
	return visual


func _draw_comet(visual: Node2D) -> void:
	var size: float = visual.get_meta("comet_size")
	
	# Draw comet head
	visual.draw_circle(Vector2.ZERO, size, Color(0.9, 0.9, 1.0))
	
	# Draw tail (gradient effect with multiple circles)
	for i in range(5):
		var offset := (i + 1) * size * 2
		var tail_size := size * (1.0 - i * 0.15)
		var alpha := 0.6 - i * 0.12
		visual.draw_circle(Vector2(offset, 0), tail_size, Color(0.7, 0.8, 1.0, alpha))


func _spawn_satellite() -> void:
	var satellite := AmbientObject.new()
	satellite.object_type = AmbientObject.ObjectType.SATELLITE
	satellite.visual_scale = _rng.randf_range(0.5, 1.0)
	satellite.rotation_speed = _rng.randf_range(0.5, 1.5)
	
	var sprite := _create_satellite_sprite()
	satellite.add_child(sprite)
	
	_finalize_spawn(satellite, Vector2(_rng.randf_range(-70, -50), 0), AmbientObject.ObjectType.SATELLITE)


func _create_satellite_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	var size := _rng.randf_range(15, 25)
	
	visual.set_meta("satellite_size", size)
	visual.set_draw_callback(_draw_satellite.bind(visual))
	
	return visual


func _draw_satellite(visual: Node2D) -> void:
	var size: float = visual.get_meta("satellite_size")
	
	# Draw satellite body
	visual.draw_rect(Rect2(-size/2, -size/2, size, size), Color(0.6, 0.6, 0.7))
	
	# Draw solar panels
	visual.draw_rect(Rect2(-size*1.5, -size/4, size/2, size/2), Color(0.2, 0.2, 0.5, 0.7))
	visual.draw_rect(Rect2(size, -size/4, size/2, size/2), Color(0.2, 0.2, 0.5, 0.7))


func _spawn_escape_pod() -> void:
	var pod := AmbientObject.new()
	pod.object_type = AmbientObject.ObjectType.ESCAPE_POD
	pod.visual_scale = _rng.randf_range(0.4, 0.8)
	pod.rotation_speed = _rng.randf_range(-0.5, 0.5)
	
	var sprite := _create_pod_sprite()
	pod.add_child(sprite)
	
	_finalize_spawn(pod, Vector2(_rng.randf_range(-80, -60), 0), AmbientObject.ObjectType.ESCAPE_POD)


func _create_pod_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	var size := _rng.randf_range(12, 20)
	
	visual.set_meta("pod_size", size)
	visual.set_draw_callback(_draw_pod.bind(visual))
	
	return visual


func _draw_pod(visual: Node2D) -> void:
	var size: float = visual.get_meta("pod_size")
	
	# Draw pod as capsule shape
	visual.draw_circle(Vector2.ZERO, size, Color(0.7, 0.6, 0.5))
	
	# Distress light
	visual.draw_circle(Vector2(0, -size/2), 3, Color(1.0, 0.3, 0.0, 0.9))


# ==============================================================================
# EVENT SPAWNING (Rare)
# ==============================================================================

func _spawn_event() -> void:
	if event_scenes.is_empty():
		# Create procedural event
		var event_type := _rng.randi() % 4
		match event_type:
			0:  # Distant explosion
				_spawn_explosion()
			1:  # Jump gate activation
				_spawn_jump_gate()
			2:  # Solar flare
				_spawn_solar_flare()
			3:  # Meteor shower
				_spawn_meteor_shower()
		return
	
	var scene := event_scenes[_rng.randi() % event_scenes.size()]
	var event := scene.instantiate() as AmbientObject
	_finalize_spawn(event, Vector2(0, 0), AmbientObject.ObjectType.EXPLOSION)


func _spawn_explosion() -> void:
	var explosion := AmbientObject.new()
	explosion.object_type = AmbientObject.ObjectType.EXPLOSION
	explosion.visual_scale = _rng.randf_range(1.0, 2.0)
	
	var sprite := _create_explosion_sprite()
	explosion.add_child(sprite)
	
	# Spawn anywhere on screen
	var pos := Vector2(
		_rng.randf_range(0, screen_size.x),
		_rng.randf_range(0, screen_size.y)
	)
	explosion.position = pos
	explosion.velocity = Vector2.ZERO
	
	_add_to_container(explosion)
	
	# Auto-remove after animation (simulate with timer)
	var timer := Timer.new()
	timer.wait_time = 1.5
	timer.one_shot = true
	timer.timeout.connect(explosion.despawn)
	explosion.add_child(timer)
	timer.start()


func _create_explosion_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	visual.set_meta("explosion_radius", 0.0)
	visual.set_meta("explosion_max", _rng.randf_range(40, 80))
	visual.set_draw_callback(_draw_explosion.bind(visual))
	
	# Animate expansion
	var tween := visual.create_tween()
	tween.tween_method(
		func(val: float): visual.set_meta("explosion_radius", val); visual.queue_redraw(),
		0.0,
		visual.get_meta("explosion_max"),
		1.0
	)
	
	return visual


func _draw_explosion(visual: Node2D) -> void:
	var radius: float = visual.get_meta("explosion_radius")
	var max_radius: float = visual.get_meta("explosion_max")
	
	if radius <= 0:
		return
	
	# Fade out as it expands
	var alpha := 1.0 - (radius / max_radius)
	
	# Draw expanding rings
	visual.draw_circle(Vector2.ZERO, radius, Color(1.0, 0.5, 0.0, alpha * 0.5))
	visual.draw_circle(Vector2.ZERO, radius * 0.7, Color(1.0, 0.8, 0.0, alpha * 0.7))
	visual.draw_circle(Vector2.ZERO, radius * 0.4, Color(1.0, 1.0, 0.9, alpha))


func _spawn_jump_gate() -> void:
	var gate := AmbientObject.new()
	gate.object_type = AmbientObject.ObjectType.JUMP_GATE
	gate.visual_scale = _rng.randf_range(1.5, 2.5)
	
	var sprite := _create_jump_gate_sprite()
	gate.add_child(sprite)
	
	# Spawn in distance
	var pos := Vector2(
		_rng.randf_range(screen_size.x * 0.3, screen_size.x * 0.7),
		_rng.randf_range(0, screen_size.y)
	)
	gate.position = pos
	gate.velocity = Vector2.ZERO
	
	_add_to_container(gate)
	
	# Auto-remove after flash
	var timer := Timer.new()
	timer.wait_time = 2.0
	timer.one_shot = true
	timer.timeout.connect(gate.despawn)
	gate.add_child(timer)
	timer.start()


func _create_jump_gate_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	visual.set_meta("gate_intensity", 0.0)
	visual.set_draw_callback(_draw_jump_gate.bind(visual))
	
	# Flash animation
	var tween := visual.create_tween()
	tween.tween_method(
		func(val: float): visual.set_meta("gate_intensity", val); visual.queue_redraw(),
		0.0,
		1.0,
		0.5
	)
	tween.tween_method(
		func(val: float): visual.set_meta("gate_intensity", val); visual.queue_redraw(),
		1.0,
		0.0,
		1.5
	)
	
	return visual


func _draw_jump_gate(visual: Node2D) -> void:
	var intensity: float = visual.get_meta("gate_intensity")
	
	if intensity <= 0:
		return
	
	# Draw bright flash
	var size := 60.0 * intensity
	visual.draw_circle(Vector2.ZERO, size, Color(0.3, 0.7, 1.0, intensity * 0.7))
	visual.draw_circle(Vector2.ZERO, size * 0.6, Color(0.6, 0.9, 1.0, intensity))
	visual.draw_circle(Vector2.ZERO, size * 0.3, Color(1.0, 1.0, 1.0, intensity))


func _spawn_solar_flare() -> void:
	var flare := AmbientObject.new()
	flare.object_type = AmbientObject.ObjectType.SOLAR_FLARE
	flare.visual_scale = _rng.randf_range(2.0, 3.5)
	
	var sprite := _create_solar_flare_sprite()
	flare.add_child(sprite)
	
	# Spawn from edge
	var from_left := _rng.randf() > 0.5
	var pos := Vector2(
		screen_size.x if not from_left else 0,
		_rng.randf_range(0, screen_size.y)
	)
	flare.position = pos
	flare.velocity = Vector2.ZERO
	
	_add_to_container(flare)
	
	# Auto-remove
	var timer := Timer.new()
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.timeout.connect(flare.despawn)
	flare.add_child(timer)
	timer.start()


func _create_solar_flare_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	visual.set_meta("flare_intensity", 0.0)
	visual.set_draw_callback(_draw_solar_flare.bind(visual))
	
	# Pulse animation
	var tween := visual.create_tween()
	tween.set_loops()
	tween.tween_method(
		func(val: float): visual.set_meta("flare_intensity", val); visual.queue_redraw(),
		0.0,
		1.0,
		1.0
	)
	tween.tween_method(
		func(val: float): visual.set_meta("flare_intensity", val); visual.queue_redraw(),
		1.0,
		0.3,
		1.0
	)
	
	return visual


func _draw_solar_flare(visual: Node2D) -> void:
	var intensity: float = visual.get_meta("flare_intensity")
	
	# Draw radiating flare
	var length := 300.0
	var width := 100.0 * intensity
	
	for i in range(5):
		var alpha := (1.0 - i * 0.2) * intensity
		var points: PackedVector2Array = PackedVector2Array([
			Vector2(0, -width * (1.0 - i * 0.15)),
			Vector2(length, -width * 0.3 * (1.0 - i * 0.15)),
			Vector2(length, width * 0.3 * (1.0 - i * 0.15)),
			Vector2(0, width * (1.0 - i * 0.15))
		])
		visual.draw_colored_polygon(points, Color(1.0, 0.9, 0.5, alpha * 0.3))


func _spawn_meteor_shower() -> void:
	# Spawn multiple small meteors
	var count := _rng.randi_range(5, 10)
	
	for i in count:
		var meteor := AmbientObject.new()
		meteor.object_type = AmbientObject.ObjectType.METEOR_SHOWER
		meteor.visual_scale = _rng.randf_range(0.3, 0.7)
		
		var sprite := _create_meteor_sprite()
		meteor.add_child(sprite)
		
		# Spawn from top
		var start_x := _rng.randf_range(0, screen_size.x)
		meteor.position = Vector2(start_x, -50)
		meteor.velocity = Vector2(_rng.randf_range(-50, 50), _rng.randf_range(150, 250))
		
		_add_to_container(meteor)


func _create_meteor_sprite() -> Node2D:
	var visual := ProceduralSprite.new()
	var size := _rng.randf_range(5, 12)
	
	visual.set_meta("meteor_size", size)
	visual.set_draw_callback(_draw_meteor.bind(visual))
	
	return visual


func _draw_meteor(visual: Node2D) -> void:
	var size: float = visual.get_meta("meteor_size")
	
	# Draw meteor
	visual.draw_circle(Vector2.ZERO, size, Color(0.8, 0.5, 0.3))
	
	# Draw trail
	for i in range(3):
		var offset := (i + 1) * size * 1.5
		var trail_size := size * (1.0 - i * 0.25)
		var alpha := 0.5 - i * 0.15
		visual.draw_circle(Vector2(0, -offset), trail_size, Color(1.0, 0.7, 0.4, alpha))


# ==============================================================================
# SPAWN HELPERS
# ==============================================================================

func _finalize_spawn(obj: AmbientObject, velocity_base: Vector2, obj_type: AmbientObject.ObjectType) -> void:
	obj.object_type = obj_type
	obj.position = _get_spawn_position(velocity_base)
	obj.velocity = velocity_base
	obj.set_screen_size(screen_size)
	
	_add_to_container(obj)


func _get_spawn_position(velocity: Vector2) -> Vector2:
	var pos := Vector2.ZERO
	
	# Determine spawn side based on velocity
	if velocity.x < 0:  # Moving left, spawn from right
		pos.x = screen_size.x + spawn_margin
		pos.y = _rng.randf_range(0, screen_size.y)
	elif velocity.x > 0:  # Moving right, spawn from left
		pos.x = -spawn_margin
		pos.y = _rng.randf_range(0, screen_size.y)
	else:  # No horizontal movement, spawn from top or bottom
		pos.x = _rng.randf_range(0, screen_size.x)
		if velocity.y >= 0:  # Moving down, spawn from top
			pos.y = -spawn_margin
		else:  # Moving up, spawn from bottom
			pos.y = screen_size.y + spawn_margin
	
	return pos


func _add_to_container(obj: AmbientObject) -> void:
	if object_container:
		object_container.add_child(obj)
		_active_objects.append(obj)
		object_spawned.emit(obj)


# ==============================================================================
# CLEANUP
# ==============================================================================

func _cleanup_inactive_objects() -> void:
	# Remove inactive objects from tracking
	var i := 0
	while i < _active_objects.size():
		var obj := _active_objects[i]
		if not is_instance_valid(obj) or not obj.is_active():
			_active_objects.remove_at(i)
		else:
			i += 1
