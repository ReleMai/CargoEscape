# ==============================================================================
# BOARDING MANAGER - MAIN GAMEPLAY CONTROLLER
# ==============================================================================
#
# FILE: scripts/boarding/boarding_manager.gd
# PURPOSE: Controls the boarding/looting gameplay phase
#
# GAMEPLAY LOOP:
# 1. Ship tier determines time limit and loot quality
# 2. Player spawns in procedurally generated ship layout
# 3. Timer starts counting down
# 4. Player explores, finds containers, searches them for loot
# 5. Each container type affects search time and loot quality
# 6. Player must reach exit before timer runs out
# 7. Score based on loot value
#
# ==============================================================================

extends Node2D
class_name BoardingManager

# ==============================================================================
# SIGNALS
# ==============================================================================

signal boarding_started
signal boarding_ended(success: bool, loot_value: int)
signal time_warning(seconds_left: int)
signal container_looted(container: Node2D)
signal ship_generated(tier: int, time_limit: float)

# ==============================================================================
# PRELOADS
# ==============================================================================

const ShipTypesClass = preload("res://scripts/data/ship_types.gd")
const ContainerTypesClass = preload("res://scripts/data/container_types.gd")
const ShipLayoutClass = preload("res://scripts/boarding/ship_layout.gd")
const ShipGeneratorClass = preload("res://scripts/boarding/ship_generator.gd")
const ShipInteriorRendererClass = preload("res://scripts/boarding/ship_interior_renderer.gd")
const LootMenuClass = preload("res://scripts/boarding/loot_menu.gd")
const GameOverScene = preload("res://scenes/boarding/game_over.tscn")
const ShipContainerScene = preload("res://scenes/boarding/ship_container.tscn")

# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Ship Settings")
## If > 0, forces this ship tier. Otherwise randomly rolled.
@export_range(0, 5) var forced_ship_tier: int = 0
## Base warning time before timer ends
@export var warning_time: float = 20.0

@export_group("Layout")
## Enable procedural layout generation
@export var use_procedural_layout: bool = true

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var player: BoardingPlayer = $Player
@onready var exit_point: ExitPoint = $ExitPoint
@onready var containers_parent: Node2D = $Containers
@onready var walls_parent: Node2D = $Walls
@onready var camera: Camera2D = $Camera2D
@onready var ship_interior: Node2D = $ShipInterior  # Parent for rendered interior

# UI References
@onready var timer_label: Label = %TimerLabel
@onready var loot_value_label: Label = %LootValueLabel
@onready var inventory_panel: Control = %InventoryPanel
@onready var inventory: GridInventory = null  # Set in _ready
@onready var loot_menu: Control = %LootMenu
@onready var escape_prompt: Control = %EscapePrompt
@onready var ship_tier_label: Label = %ShipTierLabel  # Shows current ship tier

# ==============================================================================
# STATE
# ==============================================================================

var time_remaining: float = 0.0
var total_time: float = 90.0  # Set by ship tier
var is_active: bool = false
var total_loot_value: int = 0
var inventory_open: bool = false
var looting_container: Node2D = null

# Ship data
var current_ship_tier: int = 1
var current_ship_data: ShipTypesClass.ShipData = null
var current_layout: ShipLayoutClass.LayoutData = null

# Player's collected items
var collected_items: Array[ItemData] = []

# Camera and centering
var layout_offset: Vector2 = Vector2.ZERO  # Offset to center the ship
var screen_center: Vector2 = Vector2.ZERO

# Entrance animation
var entrance_active: bool = false
var entrance_timer: float = 0.0
var entrance_duration: float = 1.2

# Camera effects
var camera_shake: float = 0.0
var camera_shake_decay: float = 8.0

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Get screen center for layout centering
	screen_center = get_viewport_rect().size / 2.0
	
	# Get inventory reference from loot menu (single shared inventory)
	if loot_menu:
		inventory = loot_menu.get_node_or_null("Panel/VBox/ContentArea/InventorySide/InventoryGrid")
	
	_setup_connections()
	_generate_ship()
	_start_boarding()
	
	# Start entrance animation
	_start_entrance_animation()


func _process(delta: float) -> void:
	# Process entrance animation
	if entrance_active:
		_process_entrance(delta)
	
	if not is_active:
		return
	
	_update_timer(delta)
	_update_camera(delta)
	
	# Decay camera shake
	if camera_shake > 0:
		camera_shake = maxf(0, camera_shake - camera_shake_decay * delta)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	
	# Escape key to pause/menu
	if event.is_action_pressed("ui_cancel"):
		if looting_container:
			_close_loot_menu()
		elif inventory_open:
			_toggle_inventory()


# ==============================================================================
# SETUP
# ==============================================================================

func _setup_connections() -> void:
	if player:
		player.interaction_requested.connect(_on_player_interact)
		player.reached_exit.connect(_on_player_reached_exit)
		player.inventory_toggled.connect(_toggle_inventory)
	
	if exit_point:
		exit_point.escape_triggered.connect(_on_escape_triggered)
	
	if loot_menu:
		loot_menu.item_transferred.connect(_on_item_transferred)
		loot_menu.menu_closed.connect(_on_loot_menu_closed)
		loot_menu.container_emptied.connect(_on_container_emptied)
	
	# Connect to inventory item_destroyed to update loot value
	if inventory:
		inventory.item_destroyed.connect(_on_item_destroyed)


## Generate ship layout based on tier
func _generate_ship() -> void:
	# Determine ship tier
	if forced_ship_tier > 0:
		current_ship_tier = forced_ship_tier
	else:
		current_ship_tier = ShipTypesClass.roll_ship_tier()
	
	# Get ship data
	current_ship_data = ShipTypesClass.get_ship_by_number(current_ship_tier)
	if not current_ship_data:
		push_warning("Invalid ship tier %d, defaulting to tier 1" % current_ship_tier)
		current_ship_tier = 1
		current_ship_data = ShipTypesClass.get_ship_by_number(1)
	
	# Set time limit from ship data
	total_time = current_ship_data.time_limit
	
	# Generate layout using new generator or legacy system
	if use_procedural_layout:
		# Try new generator first, fall back to legacy if it fails
		var generated = ShipGeneratorClass.generate(current_ship_tier)
		if generated:
			# Convert GeneratedLayout to legacy LayoutData format for compatibility
			current_layout = _convert_generated_layout(generated)
		else:
			# Fallback to legacy generator
			current_layout = ShipLayoutClass.generate_layout(current_ship_tier)
		_apply_layout()
	
	# Update UI with ship info
	if ship_tier_label:
		var ship_name = current_ship_data.display_name.to_upper()
		ship_tier_label.text = "TIER %d: %s" % [current_ship_tier, ship_name]
	
	emit_signal("ship_generated", current_ship_tier, total_time)


## Convert new GeneratedLayout to legacy LayoutData format
func _convert_generated_layout(generated) -> RefCounted:
	# Create a legacy LayoutData compatible object
	var layout = ShipLayoutClass.LayoutData.new()
	layout.ship_tier = generated.ship_tier
	layout.ship_size = generated.ship_size
	layout.entry_position = generated.entry_position
	layout.exit_position = generated.exit_position
	layout.hull_color = generated.hull_color
	layout.accent_color = generated.accent_color
	layout.interior_color = generated.interior_floor
	
	# Convert rooms to room_rects
	for room in generated.rooms:
		layout.room_rects.append(room.rect)
	
	# Add corridor rects (for rendering and collision)
	if generated.corridor_rects:
		layout.corridor_rects = generated.corridor_rects
	
	# Add walkable grid for collision system
	if generated.walkable_grid:
		layout.walkable_grid = generated.walkable_grid
		layout.grid_cell_size = generated.grid_cell_size
	
	# Convert container positions
	layout.container_positions = generated.container_positions
	
	# Generate wall segments from room rects
	for room_rect in layout.room_rects:
		var top_left = room_rect.position
		var top_right = Vector2(room_rect.end.x, room_rect.position.y)
		var bot_right = room_rect.end
		var bot_left = Vector2(room_rect.position.x, room_rect.end.y)
		
		layout.wall_segments.append({"start": top_left, "end": top_right})
		layout.wall_segments.append({"start": top_right, "end": bot_right})
		layout.wall_segments.append({"start": bot_right, "end": bot_left})
		layout.wall_segments.append({"start": bot_left, "end": top_left})
	
	return layout


## Apply the generated layout to the scene
func _apply_layout() -> void:
	if not current_layout:
		return
	
	# Calculate offset to center the ship interior in the viewport
	var ship_size = current_layout.ship_size
	layout_offset = screen_center - ship_size / 2.0
	
	# Apply offset to ShipInterior node
	if ship_interior:
		ship_interior.position = layout_offset
	
	# Apply offset to Containers parent
	if containers_parent:
		containers_parent.position = layout_offset
		# Clear existing containers
		for child in containers_parent.get_children():
			child.queue_free()
	
	# Clear and render interior
	_render_ship_interior()
	
	# Position player at entry (with offset)
	if player and current_layout.entry_position != Vector2.ZERO:
		player.position = current_layout.entry_position + layout_offset
	
	# Position exit (with offset)
	if exit_point and current_layout.exit_position != Vector2.ZERO:
		exit_point.position = current_layout.exit_position + layout_offset
	
	# Setup camera limits based on ship size
	if camera:
		var margin = 100.0
		camera.limit_left = int(layout_offset.x - margin)
		camera.limit_top = int(layout_offset.y - margin)
		camera.limit_right = int(layout_offset.x + ship_size.x + margin)
		camera.limit_bottom = int(layout_offset.y + ship_size.y + margin)
	
	# Spawn containers at validated positions (already offset since containers_parent is offset)
	for container_data in current_layout.container_positions:
		_spawn_container(container_data.position, container_data.type)


## Render the ship interior based on layout
func _render_ship_interior() -> void:
	if not ship_interior:
		return
	
	# Clear existing interior children
	for child in ship_interior.get_children():
		child.queue_free()
	
	# Create and add interior renderer
	var renderer = ShipInteriorRendererClass.new()
	renderer.name = "InteriorRenderer"
	ship_interior.add_child(renderer)
	
	# Render the layout
	renderer.render_layout(current_layout, current_ship_tier)
	renderer.create_room_labels()


## Spawn a container at position with type
func _spawn_container(pos: Vector2, container_type: int) -> void:
	if not containers_parent:
		return
	
	var container = ShipContainerScene.instantiate()
	container.position = pos
	
	# Set container type if it supports it
	if container.has_method("set_container_type"):
		container.set_container_type(container_type)
	
	# Generate loot for this container
	if container.has_method("generate_loot"):
		container.generate_loot(current_ship_tier, container_type)
	
	containers_parent.add_child(container)


func _start_boarding() -> void:
	is_active = true
	time_remaining = total_time
	total_loot_value = 0
	collected_items.clear()
	
	# Position player at start (if not using procedural layout)
	if player and not use_procedural_layout:
		player.position = Vector2(100, current_layout.ship_size.y / 2 if current_layout else 400)
	
	# Update UI
	_update_ui()
	
	emit_signal("boarding_started")


# ==============================================================================
# TIMER
# ==============================================================================

func _update_timer(delta: float) -> void:
	time_remaining -= delta
	time_remaining = max(0, time_remaining)
	
	_update_timer_display()
	
	# Time warnings with shake
	if time_remaining <= warning_time and int(time_remaining) != int(time_remaining + delta):
		var secs_left = int(time_remaining)
		emit_signal("time_warning", secs_left)
		
		# Shake on specific thresholds
		if secs_left == 10 or secs_left == 5:
			shake_camera(4.0)
		elif secs_left <= 3:
			shake_camera(6.0)
	
	# Time's up!
	if time_remaining <= 0:
		_on_time_expired()


func _update_timer_display() -> void:
	if not timer_label:
		return
	
	@warning_ignore("integer_division")
	var mins = int(time_remaining) / 60
	var secs = int(time_remaining) % 60
	timer_label.text = "%d:%02d" % [mins, secs]
	
	# Color based on urgency
	if time_remaining <= warning_time / 2:
		timer_label.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		# Pulse effect when critical
		var pulse = 0.8 + sin(Time.get_ticks_msec() * 0.01) * 0.2
		timer_label.scale = Vector2(pulse, pulse)
	elif time_remaining <= warning_time:
		timer_label.add_theme_color_override("font_color", Color(1, 0.7, 0.2))
		timer_label.scale = Vector2.ONE
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)
		timer_label.scale = Vector2.ONE


func _on_time_warning_shake() -> void:
	# Small shake when time warning triggers
	shake_camera(3.0)


# ==============================================================================
# INTERACTION
# ==============================================================================

func _on_player_interact(target: Node2D) -> void:
	# Handle both ShipContainer and any container with compatible interface
	if target.has_method("open_container") or target is ShipContainer:
		_interact_with_container(target)
	elif target is ExitPoint:
		_trigger_escape()


func _interact_with_container(container: Node2D) -> void:
	# Always open loot menu immediately - the visual reveal happens in the menu
	if container is ShipContainer:
		# Move all hidden items to revealed for the loot menu
		if container.has_method("reveal_all_items"):
			container.reveal_all_items()
		
		# Open container if closed
		if container.current_state == ShipContainer.ContainerState.CLOSED:
			container.set_state(ShipContainer.ContainerState.OPEN)
			container.emit_signal("container_opened")
		
		# Open loot menu if container has items
		if not container.item_data_list.is_empty():
			_open_loot_menu(container)
		return
	
	# Generic container with open_container method
	if container.has_method("open_container"):
		container.open_container()
		
		# Try to get items from container
		if container.has_method("get") and container.get("item_data_list"):
			if not container.item_data_list.is_empty():
				_open_loot_menu(container)


func _open_loot_menu(container: Node2D) -> void:
	looting_container = container
	
	if player:
		player.set_movement_enabled(false)
	
	if loot_menu:
		loot_menu.open_with_container(container)
	
	emit_signal("container_looted", container)


func _close_loot_menu() -> void:
	looting_container = null
	
	if player:
		player.set_movement_enabled(true)
	
	if loot_menu:
		loot_menu.close_menu()


func _on_loot_menu_closed() -> void:
	looting_container = null
	if player:
		player.set_movement_enabled(true)


func _on_container_emptied() -> void:
	# Container was fully looted
	pass


func _on_item_transferred(item_data: ItemData) -> void:
	# Item was successfully dragged to inventory
	collected_items.append(item_data)
	total_loot_value += item_data.value
	_update_ui()


func _on_item_destroyed(item: LootItem) -> void:
	# Item was destroyed from inventory
	if item and item.item_data:
		collected_items.erase(item.item_data)
		total_loot_value -= item.item_data.value
		total_loot_value = max(0, total_loot_value)
		_update_ui()


# ==============================================================================
# INVENTORY
# ==============================================================================

func _toggle_inventory() -> void:
	inventory_open = not inventory_open
	
	if inventory_panel:
		inventory_panel.visible = inventory_open
		
		# Reparent the shared inventory to the standalone panel when showing
		if inventory_open and inventory:
			var target_container = inventory_panel.get_node_or_null("VBox")
			if target_container:
				# Reparent shared inventory from loot menu
				if inventory.get_parent() != target_container:
					inventory.reparent(target_container)
		elif not inventory_open and inventory and loot_menu:
			# Return inventory to loot menu
			var inv_path = "Panel/VBox/ContentArea/InventorySide"
			var loot_menu_container = loot_menu.get_node_or_null(inv_path)
			if loot_menu_container and inventory.get_parent() != loot_menu_container:
				inventory.reparent(loot_menu_container)
				# Move after label
				loot_menu_container.move_child(inventory, 1)
	
	if player:
		player.set_movement_enabled(not inventory_open)


# ==============================================================================
# ESCAPE
# ==============================================================================

func _on_player_reached_exit(_exit: Node2D) -> void:
	if escape_prompt:
		escape_prompt.visible = true


func _trigger_escape() -> void:
	if not is_active:
		return
	
	_end_boarding(true)


func _on_escape_triggered() -> void:
	_trigger_escape()


func _on_time_expired() -> void:
	# Player failed to escape in time
	_end_boarding(false)


func _end_boarding(success: bool) -> void:
	is_active = false
	
	if player:
		player.set_movement_enabled(false)
	
	emit_signal("boarding_ended", success, total_loot_value)
	
	# Transfer inventory items to GameManager for persistence
	if success and inventory:
		_transfer_inventory_to_game_manager()
	
	# Add to global score
	if success and GameManager:
		GameManager.add_score(total_loot_value)
	
	# Transition to results or next scene
	await get_tree().create_timer(1.0).timeout
	_show_results(success)


## Transfer all items from the grid inventory to GameManager.ship_inventory
func _transfer_inventory_to_game_manager() -> void:
	if not inventory:
		return
	
	# Get all items from the grid inventory
	var items = inventory.get_all_items()
	print("[Boarding] Transferring %d items to ship inventory" % items.size())
	
	for item in items:
		if item and item.item_data:
			GameManager.add_to_ship_inventory(item.item_data)
	
	# Clear the boarding inventory after transfer
	inventory.clear_all()


func _show_results(success: bool) -> void:
	if success:
		# Set the escape station in GameManager
		if has_node("/root/GameManager"):
			var gm = get_node("/root/GameManager")
			# Load the abandoned station for the first station
			var station_data = preload("res://resources/stations/abandoned_station.tres")
			gm.set_escape_station(station_data)
		
		# Play escape success effects
		_play_escape_success_effects()
		
		# Wait a moment then transition
		await get_tree().create_timer(0.3).timeout
		
		# Seamless fade transition to undocking
		await _fade_to_undocking()
	else:
		# Big shake when time runs out
		shake_camera(15.0)
		
		# Show game over screen (it has its own effects)
		await get_tree().create_timer(0.5).timeout
		var game_over = GameOverScene.instantiate()
		add_child(game_over)
		game_over.set_lost_loot(total_loot_value)


func _play_escape_success_effects() -> void:
	# Camera shake as you board
	shake_camera(8.0)
	
	# Flash of green/success
	var flash_layer = CanvasLayer.new()
	flash_layer.layer = 90
	add_child(flash_layer)
	
	var flash = ColorRect.new()
	flash.color = Color(0.2, 0.8, 0.4, 0.4)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.4)
	tween.tween_callback(flash_layer.queue_free)


## Creates a smooth fade transition to the undocking scene
func _fade_to_undocking() -> void:
	# Create a fade overlay
	var fade_layer = CanvasLayer.new()
	fade_layer.layer = 100  # On top of everything
	add_child(fade_layer)
	
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0.008, 0.012, 0.025, 0.0)  # Match undocking background
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)
	
	# Quick zoom out effect on camera
	if camera:
		var zoom_tween = create_tween()
		zoom_tween.tween_property(camera, "zoom", Vector2(0.7, 0.7), 0.5).set_ease(Tween.EASE_IN)
	
	# Create fade tween
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.5).set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	# Change scene - the undocking scene will fade in
	get_tree().change_scene_to_file("res://scenes/undocking/undocking_scene.tscn")


# ==============================================================================
# CAMERA
# ==============================================================================

func _update_camera(_delta: float) -> void:
	if not camera or not player:
		return
	
	# Smooth follow with configurable speed
	var target_pos = player.position
	
	# Add camera shake offset
	if camera_shake > 0:
		target_pos += Vector2(
			randf_range(-camera_shake, camera_shake),
			randf_range(-camera_shake, camera_shake)
		)
	
	# Use position smoothing built into Camera2D (already enabled in scene)
	camera.position = target_pos


## Trigger camera shake effect
func shake_camera(intensity: float = 5.0) -> void:
	camera_shake = intensity


# ==============================================================================
# ENTRANCE ANIMATION
# ==============================================================================

func _start_entrance_animation() -> void:
	entrance_active = true
	entrance_timer = 0.0
	
	# Start with zoom and fade
	if camera:
		camera.zoom = Vector2(0.6, 0.6)
	
	# Disable player movement during entrance
	if player:
		player.set_movement_enabled(false)
	
	# Create fade overlay
	_create_entrance_fade()


func _process_entrance(delta: float) -> void:
	entrance_timer += delta
	var t = minf(entrance_timer / entrance_duration, 1.0)
	var eased = ease(t, 0.3)
	
	# Zoom camera in
	if camera:
		camera.zoom = Vector2(
			lerpf(0.6, 0.8, eased),
			lerpf(0.6, 0.8, eased)
		)
	
	# End entrance
	if entrance_timer >= entrance_duration:
		entrance_active = false
		if player:
			player.set_movement_enabled(true)


func _create_entrance_fade() -> void:
	# Create fade layer
	var fade_layer = CanvasLayer.new()
	fade_layer.name = "EntranceFade"
	fade_layer.layer = 100
	add_child(fade_layer)
	
	var fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 1.0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)
	
	# Fade in tween
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_callback(fade_layer.queue_free)


# ==============================================================================
# UI
# ==============================================================================

func _update_ui() -> void:
	if loot_value_label:
		loot_value_label.text = "$%d" % total_loot_value
