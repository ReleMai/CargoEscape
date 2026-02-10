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
# 3. Fog of war hides undiscovered areas
# 4. Player vision cone reveals areas as they look around
# 5. Timer starts counting down
# 6. Player explores, finds containers, searches them for loot
# 7. Each container type affects search time and loot quality
# 8. Player must reach exit before timer runs out
# 9. Score based on loot value
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
const FactionsClass = preload("res://scripts/data/factions.gd")
const ShipLayoutClass = preload("res://scripts/boarding/ship_layout.gd")
const ShipGeneratorClass = preload("res://scripts/boarding/ship_generator.gd")
const ShipInteriorRendererClass = preload("res://scripts/boarding/ship_interior_renderer.gd")
const LootMenuClass = preload("res://scripts/boarding/loot_menu.gd")
const VisionSystemClass = preload("res://scripts/boarding/vision_system.gd")
const EscapeGateClass = preload("res://scripts/boarding/escape_gate.gd")
const EscapeTrackerClass = preload("res://scripts/ui/escape_tracker.gd")
const GameOverScene = preload("res://scenes/boarding/game_over.tscn")
const ShipContainerScene = preload("res://scenes/boarding/ship_container.tscn")
const EscapeCutsceneScene = preload("res://scenes/boarding/escape_cutscene.tscn")

# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Ship Settings")
## If > 0, forces this ship tier. Otherwise randomly rolled.
@export_range(0, 5) var forced_ship_tier: int = 0
## Base warning time before timer ends
@export var warning_time: float = 20.0

@export_group("Escape Requirements")
## Enable kill requirement to escape
@export var require_kills_to_escape: bool = true
## Kill requirements by tier (index 0 = tier 1)
@export var kills_by_tier: Array[int] = [2, 3, 4, 5, 7]

@export_group("Layout")
## Enable procedural layout generation
@export var use_procedural_layout: bool = true

@export_group("Vision System")
## Enable fog of war and vision cone
@export var enable_fog_of_war: bool = true
## Reveal radius around player that's always visible
@export var always_visible_radius: float = 80.0

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
@onready var character_panel: Control = %CharacterPanel  # CharacterPanel type
@onready var inventory: SlotInventory = null  # Set in _ready
@onready var loot_menu: Control = %LootMenu
@onready var escape_prompt: Control = %EscapePrompt
@onready var ship_tier_label: Label = %ShipTierLabel  # Shows current ship tier
@onready var minimap: Control = %Minimap  # Minimap UI element

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
var current_faction_code: String = ""  # Faction code (CCG, NEX, GDF, SYN, IND)
var current_ship_data: ShipTypesClass.ShipData = null
var current_layout: ShipLayoutClass.LayoutData = null

# Player's collected items
var collected_items: Array[ItemData] = []

# Container tracking
var containers_searched: int = 0
var total_containers: int = 0

# Achievement tracking
var boarding_start_time: float = 0.0

# Camera and centering
var layout_offset: Vector2 = Vector2.ZERO  # Offset to center the ship
var screen_center: Vector2 = Vector2.ZERO

# Entrance animation
var entrance_active: bool = false
var entrance_timer: float = 0.0
var entrance_duration: float = 2.0  # Extended for more cinematic feel
var entrance_phase: int = 0  # Track animation phases

# Camera effects
var camera_shake: float = 0.0
var camera_shake_decay: float = 8.0

# Animation constants
const ENTRANCE_INITIAL_ZOOM: float = 0.5
const ENTRANCE_FINAL_ZOOM: float = 1.0
const EXIT_ZOOM: float = 0.6

# Animation layer tracking for cleanup
var active_animation_layers: Array[CanvasLayer] = []

# Vision system
var vision_system = null  # VisionSystem instance

# Escape gate system
var escape_gate: EscapeGateClass = null
var escape_tracker: EscapeTrackerClass = null

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Get screen center for layout centering
	screen_center = get_viewport_rect().size / 2.0
	
	# Get inventory reference from loot menu (single shared inventory)
	if loot_menu:
		inventory = loot_menu.get_node_or_null(
			"Panel/VBox/ContentArea/InventorySide/InventoryGrid")
	
	_setup_connections()
	_generate_ship()
	_setup_vision_system()  # Initialize fog of war
	_start_boarding()
	
	# Start entrance animation
	_start_entrance_animation()
	
	# Start tutorial if needed
	_check_and_start_tutorial()


func _exit_tree() -> void:
	# Clean up vision system
	if vision_system:
		vision_system.queue_free()
		vision_system = null
	
	# Clean up any active animation layers to prevent memory leaks
	_cleanup_animation_layers()


func _process(delta: float) -> void:
	# Process entrance animation
	if entrance_active:
		_process_entrance(delta)
	
	if not is_active:
		return
	
	_update_timer(delta)
	_update_camera(delta)
	_update_minimap()
	
	# Decay camera shake
	if camera_shake > 0:
		camera_shake = maxf(0, camera_shake - camera_shake_decay * delta)


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	
	# TAB key to toggle character panel (inventory + character)
	if event.is_action_pressed("inventory"):
		if looting_container:
			_close_loot_menu()
		else:
			_toggle_character_panel()
		get_viewport().set_input_as_handled()
		return
	
	# Escape key to close menus
	if event.is_action_pressed("ui_cancel"):
		if looting_container:
			_close_loot_menu()
		elif inventory_open:
			_toggle_character_panel()


# ==============================================================================
# SETUP
# ==============================================================================

func _setup_connections() -> void:
	print("[BoardingManager] _setup_connections() called")
	if player:
		player.interaction_requested.connect(_on_player_interact)
		player.reached_exit.connect(_on_player_reached_exit)
		player.inventory_toggled.connect(_toggle_character_panel)
		player.tutorial_movement_detected.connect(_on_player_moved)
		print("[BoardingManager] Player signals connected")
	
	if exit_point:
		exit_point.escape_triggered.connect(_on_escape_triggered)
		print("[BoardingManager] Exit point signals connected")
	
	if loot_menu:
		loot_menu.item_transferred.connect(_on_item_transferred)
		loot_menu.menu_closed.connect(_on_loot_menu_closed)
		loot_menu.container_emptied.connect(_on_container_emptied)
		print("[BoardingManager] LootMenu signals connected (item_transferred -> _on_item_transferred)")
	else:
		print("[BoardingManager] WARNING: loot_menu is null, cannot connect signals!")
	
	# Connect to inventory item_destroyed to update loot value
	if inventory:
		inventory.item_destroyed.connect(_on_item_destroyed)
		print("[BoardingManager] Inventory signals connected")
	
	# Connect character panel to player and set inventory
	if character_panel:
		if player:
			character_panel.set_player(player)
		if inventory:
			character_panel.set_inventory(inventory)
		character_panel.closed.connect(_on_character_panel_closed)
		character_panel.opened.connect(_on_character_panel_opened)
		print("[BoardingManager] Character panel connected to player and inventory")


## Generate ship layout based on tier
func _generate_ship() -> void:
	# Determine ship tier
	if forced_ship_tier > 0:
		current_ship_tier = forced_ship_tier
	else:
		current_ship_tier = ShipTypes.roll_ship_tier()
	
	# Get ship data
	current_ship_data = ShipTypes.get_ship_by_number(current_ship_tier)
	if not current_ship_data:
		push_warning("Invalid ship tier %d, defaulting to tier 1" % current_ship_tier)
		current_ship_tier = 1
		current_ship_data = ShipTypes.get_ship_by_number(1)
	
	# Set time limit from ship data
	total_time = current_ship_data.time_limit
	
	# Generate layout using new generator or legacy system
	if use_procedural_layout:
		# Try new generator first, fall back to legacy if it fails
		var generated = ShipGeneratorClass.generate(current_ship_tier)
		if generated:
			print("[BoardingManager] Generated tier %d ship with %d rooms" % [current_ship_tier, generated.rooms.size()])
			# Extract faction code from generated layout
			var faction = FactionsClass.get_faction(generated.faction_type)
			if faction:
				current_faction_code = faction.code
			else:
				current_faction_code = ""
			
			# Convert GeneratedLayout to legacy LayoutData format for compatibility
			current_layout = _convert_generated_layout(generated)
		else:
			print("[BoardingManager] ShipGenerator failed, using legacy")
			# Fallback to legacy generator
			current_layout = ShipLayoutClass.generate_layout(current_ship_tier)
			current_faction_code = ""  # Legacy doesn't have faction
		_apply_layout()
	else:
		# Procedural layout disabled - use legacy generation
		current_layout = ShipLayoutClass.generate_layout(current_ship_tier)
		current_faction_code = ""
		_apply_layout()
	
	# Update UI with ship info
	if ship_tier_label:
		var ship_name = current_ship_data.display_name.to_upper()
		ship_tier_label.text = "TIER %d: %s" % [current_ship_tier, ship_name]
	
	emit_signal("ship_generated", current_ship_tier, total_time)


## Convert new GeneratedLayout to legacy LayoutData format
func _convert_generated_layout(generated: ShipGeneratorClass.GeneratedLayout) -> RefCounted:
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
	
	# Copy locked door and keycard data
	layout.locked_doors = generated.locked_doors
	layout.keycard_spawns = generated.keycard_spawns
	
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
		push_error("[BoardingManager] _apply_layout: current_layout is null!")
		return
	
	# Calculate offset to center the ship interior in the viewport
	var ship_size = current_layout.ship_size
	layout_offset = screen_center - ship_size / 2.0
	
	# Apply offset to ShipInterior node
	if ship_interior:
		ship_interior.position = layout_offset
	else:
		push_error("[BoardingManager] ship_interior is null!")
	
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
		# Check if this container should have a guaranteed keycard
		var keycard_tier = _get_keycard_for_position(container_data.position)
		_spawn_container(container_data.position, container_data.type, keycard_tier)
	
	# Initialize minimap with layout
	_setup_minimap()


## Get keycard tier for a container position (0 if none)
func _get_keycard_for_position(pos: Vector2) -> int:
	if not current_layout.get("keycard_spawns"):
		return 0
	
	# Check if any keycard spawn is near this container position
	for spawn in current_layout.keycard_spawns:
		var spawn_pos = spawn.get("position", Vector2.ZERO)
		if pos.distance_to(spawn_pos) < 50:  # Within 50 pixels
			return spawn.get("tier", 1)
	
	return 0


## Render the ship interior based on layout
func _render_ship_interior() -> void:
	if not ship_interior:
		push_error("[BoardingManager] ship_interior node is null!")
		return
	
	if not current_layout:
		push_error("[BoardingManager] current_layout is null!")
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


## Spawn a container at position with type and optional guaranteed keycard
func _spawn_container(pos: Vector2, container_type: int, keycard_tier: int = 0) -> void:
	if not containers_parent:
		return
	
	var container = ShipContainerScene.instantiate()
	container.position = pos
	container.z_index = 5  # Above decorations, below player
	
	# Set container type if it supports it
	if container.has_method("set_container_type"):
		container.set_container_type(container_type)
	
	# Generate loot for this container with faction support
	if container.has_method("generate_loot"):
		container.generate_loot(current_ship_tier, container_type, current_faction_code)
	
	# Add guaranteed keycard if specified
	if keycard_tier > 0 and container.has_method("add_guaranteed_item"):
		var keycard_id = "keycard_tier%d" % keycard_tier
		container.add_guaranteed_item(keycard_id)
		print("[BoardingManager] Added %s to container at %s" % [keycard_id, pos])
	
	# Connect to container signals to track search completion
	if container.has_signal("container_opened"):
		container.container_opened.connect(_on_container_searched)
	
	containers_parent.add_child(container)
	total_containers += 1


func _start_boarding() -> void:
	is_active = true
	time_remaining = total_time
	total_loot_value = 0
	collected_items.clear()
	containers_searched = 0
	total_containers = 0
	
	# Start boarding music and ambient sounds
	AudioManager.play_music("boarding_tension")
	AudioManager.start_ambient("ship_ambience")
	AudioManager.start_ambient("ventilation")
	
	# Position player at start (if not using procedural layout)
	if player and not use_procedural_layout:
		var y_pos: float = current_layout.ship_size.y / 2.0 if current_layout else 400.0
		player.position = Vector2(100, y_pos)
	
	# Initialize escape gate system (kill requirement)
	_setup_escape_gate()
	
	# Update UI
	_update_ui()
	
	# Achievement tracking - start boarding
	boarding_start_time = Time.get_ticks_msec() / 1000.0
	containers_searched = 0
	total_containers = current_layout.container_positions.size() if current_layout else 0
	
	# Log boarding start
	if DebugLogger:
		DebugLogger.log_boarding_start(current_ship_tier, 
			current_layout.room_rects.size() if current_layout else 0,
			total_containers, total_time)
	
	if AchievementManager:
		AchievementManager.on_boarding_started(total_containers)
	
	emit_signal("boarding_started")


## Setup the escape gate kill requirement system
func _setup_escape_gate() -> void:
	if not require_kills_to_escape:
		return
	
	# Create escape gate
	escape_gate = EscapeGateClass.new()
	escape_gate.kills_by_tier = kills_by_tier
	add_child(escape_gate)
	
	# Initialize with current tier and exit point
	escape_gate.initialize(current_ship_tier, exit_point)
	
	# Connect gate unlocked signal
	escape_gate.gate_unlocked.connect(_on_escape_gate_unlocked)
	
	# Create and add escape tracker UI
	escape_tracker = EscapeTrackerClass.new()
	
	# Add to a CanvasLayer so it stays on screen
	var ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	ui_layer.add_child(escape_tracker)
	
	# Connect tracker to gate
	escape_tracker.connect_to_gate(escape_gate)
	
	print("[BoardingManager] Escape gate initialized - require %d kills for tier %d" % [
		escape_gate.kills_required, current_ship_tier])


func _on_escape_gate_unlocked() -> void:
	print("[BoardingManager] Escape gate unlocked!")
	
	# Show notification
	if has_node("/root/PopupManager"):
		get_node("/root/PopupManager").show_popup("ESCAPE UNLOCKED", 
			"Exit is now accessible!", Color(0.3, 1.0, 0.5))


# ==============================================================================
# TIMER
# ==============================================================================

func _update_timer(delta: float) -> void:
	time_remaining -= delta
	time_remaining = max(0, time_remaining)
	
	_update_timer_display()
	
	# Time warnings with shake and audio
	if time_remaining <= warning_time and int(time_remaining) != int(time_remaining + delta):
		var secs_left = int(time_remaining)
		emit_signal("time_warning", secs_left)
		
		# Play countdown beep for each second
		AudioManager.play_sfx("countdown_beep")
		
		# Shake on specific thresholds
		if secs_left == 10 or secs_left == 5:
			shake_camera(4.0)
			AudioManager.play_sfx("alert_warning")
		elif secs_left <= 3:
			shake_camera(6.0)
			AudioManager.play_sfx("alert_warning")
	
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
	# Notify tutorial
	_on_container_interacted()
	
	# Always open loot menu immediately - the visual reveal happens in the menu
	if container is ShipContainer:
		# Move all hidden items to revealed for the loot menu
		if container.has_method("reveal_all_items"):
			container.reveal_all_items()
		
		# Open container if closed
		if container.current_state == ShipContainer.ContainerState.CLOSED:
			container.set_state(ShipContainer.ContainerState.OPEN)
			container.emit_signal("container_opened")
			
			# Add subtle container open effect
			_create_container_open_effect(container)
			
			# Mark as searched on minimap
			_mark_container_searched(container)
		
		# Open loot menu if container has items
		if not container.item_data_list.is_empty():
			_open_loot_menu(container)
		return
	
	# Generic container with open_container method
	if container.has_method("open_container"):
		container.open_container()
		
		# Mark as searched on minimap
		_mark_container_searched(container)
		
		# Try to get items from container
		if container.has_method("get") and container.get("item_data_list"):
			if not container.item_data_list.is_empty():
				_open_loot_menu(container)


func _open_loot_menu(container: Node2D) -> void:
	looting_container = container
	
	if player:
		player.set_movement_enabled(false)
		# Start searching animation
		if player.has_method("start_searching_animation"):
			player.start_searching_animation()
	
	if loot_menu:
		loot_menu.open_with_container(container)
	
	emit_signal("container_looted", container)


func _close_loot_menu() -> void:
	looting_container = null
	
	if player:
		player.set_movement_enabled(true)
		# Stop searching animation
		if player.has_method("stop_searching_animation"):
			player.stop_searching_animation()
	
	if loot_menu:
		loot_menu.close_menu()


func _on_loot_menu_closed() -> void:
	looting_container = null
	if player:
		player.set_movement_enabled(true)
		# Stop searching animation
		if player.has_method("stop_searching_animation"):
			player.stop_searching_animation()


func _on_container_emptied() -> void:
	# Container was fully looted - count as searched
	containers_searched += 1
	if AchievementManager:
		AchievementManager.on_container_searched()


func _on_container_searched() -> void:
	# Container was opened/searched
	containers_searched += 1


func _on_item_transferred(item_data: ItemData) -> void:
	# Item was successfully dragged to inventory
	print("[BoardingManager] _on_item_transferred: %s ($%d)" % [item_data.name, item_data.value])
	
	collected_items.append(item_data)
	total_loot_value += item_data.value
	print("[BoardingManager] Total loot now: $%d (%d items)" % [total_loot_value, collected_items.size()])
	_update_ui()
	
	# Log the loot
	if DebugLogger:
		DebugLogger.log_container_looted(item_data.name, item_data.value, item_data.rarity)
	
	# Check for legendary item (rarity 4)
	if item_data.rarity == 4 and AchievementManager:
		AchievementManager.on_legendary_item_found()


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

func _toggle_character_panel() -> void:
	inventory_open = not inventory_open
	
	# Notify tutorial when panel is opened
	if inventory_open:
		_on_inventory_opened()
	
	if character_panel:
		if inventory_open:
			character_panel.open_panel()
		else:
			character_panel.close_panel()
	
	if player:
		player.set_movement_enabled(not inventory_open)


func _on_character_panel_opened() -> void:
	inventory_open = true
	if player:
		player.set_movement_enabled(false)


func _on_character_panel_closed() -> void:
	inventory_open = false
	# Return inventory to loot menu for when looting
	if character_panel and loot_menu:
		var inv_path = "Panel/VBox/ContentArea/InventorySide"
		var loot_menu_container = loot_menu.get_node_or_null(inv_path)
		if loot_menu_container:
			character_panel.return_inventory_to(loot_menu_container)
	if player:
		player.set_movement_enabled(true)


# ==============================================================================
# ESCAPE
# ==============================================================================

func _on_player_reached_exit(_exit: Node2D) -> void:
	if escape_prompt:
		# Animate the prompt appearing
		escape_prompt.visible = true
		escape_prompt.modulate.a = 0.0
		escape_prompt.scale = Vector2(0.8, 0.8)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(escape_prompt, "modulate:a", 1.0, 0.2)
		tween.tween_property(escape_prompt, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		
		# Subtle pulse to draw attention
		tween.set_parallel(false)
		var pulse_tween = create_tween().set_loops()
		pulse_tween.tween_property(escape_prompt, "scale", Vector2(1.05, 1.05), 0.5).set_ease(Tween.EASE_IN_OUT)
		pulse_tween.tween_property(escape_prompt, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_IN_OUT)


func _trigger_escape() -> void:
	if not is_active:
		return
	
	# Notify tutorial
	_on_exit_interacted()
	
	# Start escape animation on player
	if player and player.has_method("start_escape_animation"):
		player.start_escape_animation()
	
	_end_boarding(true)


func _on_escape_triggered() -> void:
	# Check if escape gate is locked
	if escape_gate and not escape_gate.can_escape():
		# Gate is still locked - show feedback
		AudioManager.play_sfx("error")
		var progress = escape_gate.get_progress()
		if has_node("/root/PopupManager"):
			get_node("/root/PopupManager").show_popup("EXIT LOCKED", 
				"Eliminate %d more crew members!" % progress.remaining, Color(1.0, 0.4, 0.4))
		return
	
	# Play escape music
	AudioManager.play_music("boarding_escape")
	AudioManager.play_sfx("escape")
	_trigger_escape()


func _on_time_expired() -> void:
	# Player failed to escape in time
	AudioManager.play_sfx("alert_warning")
	AudioManager.play_music("defeat")
	_end_boarding(false)


func _end_boarding(success: bool) -> void:
	is_active = false
	
	# Stop ambient sounds
	AudioManager.stop_all_ambient()
	
	# Log boarding end
	if DebugLogger:
		DebugLogger.log_boarding_end(
			success, total_loot_value, time_remaining, collected_items.size()
		)
	
	if player:
		player.set_movement_enabled(false)
		# Stop escape animation
		if player.has_method("stop_escape_animation"):
			player.stop_escape_animation()
	
	# Hide escape prompt with animation if visible
	if escape_prompt and escape_prompt.visible:
		var hide_tween = create_tween()
		hide_tween.tween_property(escape_prompt, "modulate:a", 0.0, 0.2)
		hide_tween.tween_callback(func(): escape_prompt.visible = false)
	
	emit_signal("boarding_ended", success, total_loot_value)
	
	# Transfer inventory items to GameManager for persistence
	if success and inventory:
		_transfer_inventory_to_game_manager()
	
	# Add to global score
	if success and GameManager:
		GameManager.add_score(total_loot_value)
	
	# Achievement tracking - boarding completed
	if success and AchievementManager:
		var boarding_time = (Time.get_ticks_msec() / 1000.0) - boarding_start_time
		AchievementManager.on_boarding_completed(boarding_time, current_faction_code)
	
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
	
	# Note: SlotInventory already saves to GameManager with slot positions
	# via _save_to_game_manager(), so we don't need to do it again here
	# Just verify the count
	var gm_items = GameManager.get_ship_inventory()
	print("[Boarding] GameManager already has %d items saved" % gm_items.size())
	
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
		
		# Start escape cutscene instead of direct transition
		_start_escape_cutscene()
	else:
		# Big shake when time runs out
		shake_camera(15.0)
		
		# Show game over screen (it has its own effects)
		await get_tree().create_timer(0.5).timeout
		var game_over = GameOverScene.instantiate()
		add_child(game_over)
		game_over.set_lost_loot(total_loot_value)


## Start the escape cutscene with current game data
func _start_escape_cutscene() -> void:
	var cutscene = EscapeCutsceneScene.instantiate()
	add_child(cutscene)
	
	# Prepare cutscene data
	var cutscene_data = {
		"time_remaining": time_remaining,
		"total_loot_value": total_loot_value,
		"collected_items": collected_items,
		"containers_searched": containers_searched,
		"total_containers": total_containers
	}
	
	# Start the cutscene
	cutscene.start_cutscene(cutscene_data)


func _play_escape_success_effects() -> void:
	# Initial camera shake as you reach exit
	shake_camera(8.0)
	
	# Bright flash of success with cyan/green
	var flash_layer = _create_tracked_canvas_layer("SuccessFlash", 90)
	
	var flash = ColorRect.new()
	flash.color = Color(0.2, 0.9, 0.6, 0.5)  # Brighter success flash
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func(): _remove_tracked_layer(flash_layer))
	
	# Success text overlay
	_create_escape_text_overlay()
	
	# Player fade out effect
	if player:
		var player_tween = create_tween()
		player_tween.set_delay(0.2)
		player_tween.tween_property(player, "modulate:a", 0.0, 0.3)


## Creates "ESCAPE SUCCESSFUL" text overlay
func _create_escape_text_overlay() -> void:
	var text_layer = _create_tracked_canvas_layer("EscapeText", 91)
	
	var label = Label.new()
	label.name = "EscapeLabel"
	label.text = "ESCAPE SUCCESSFUL"
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.6, 0.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	text_layer.add_child(label)
	
	# Fade in quickly
	var tween = create_tween()
	tween.tween_property(label, "theme_override_colors/font_color:a", 1.0, 0.2)
	# Stay visible briefly
	tween.tween_interval(0.2)
	# Fade out
	tween.tween_property(label, "theme_override_colors/font_color:a", 0.0, 0.3)
	tween.tween_callback(func(): _remove_tracked_layer(text_layer))


## Creates a subtle visual effect when a container is opened
func _create_container_open_effect(container: Node2D) -> void:
	if not container:
		return
	
	# Small camera shake
	shake_camera(1.5)
	
	# Brief highlight flash on container
	var original_modulate = container.modulate
	container.modulate = Color(1.2, 1.2, 1.0, 1.0)  # Slight yellow tint
	
	var tween = create_tween()
	tween.tween_property(container, "modulate", original_modulate, 0.2).set_ease(Tween.EASE_OUT)


## Creates a smooth fade transition to the undocking scene
func _fade_to_undocking() -> void:
	# Create a fade overlay
	var fade_layer = _create_tracked_canvas_layer("UndockingFade", 100)
	
	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0.008, 0.012, 0.025, 0.0)  # Match undocking background
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)
	
	# Add scan line effect during transition
	_create_exit_scan_effect(fade_layer)
	
	# Smooth zoom out effect on camera for cinematic transition
	if camera:
		var zoom_tween = create_tween()
		zoom_tween.tween_property(camera, "zoom", Vector2(EXIT_ZOOM, EXIT_ZOOM), 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	# Fade UI elements out
	_fade_ui_elements()
	
	# Create fade tween with improved easing
	var tween = create_tween()
	tween.set_delay(0.1)  # Small delay for better flow
	tween.tween_property(fade_rect, "color:a", 1.0, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	await tween.finished
	
	# Auto-save progress after successful boarding
	if has_node("/root/SaveManager"):
		var save_manager = get_node("/root/SaveManager")
		save_manager.auto_save()
	
	# Change scene - the undocking scene will fade in
	LoadingScreen.start_transition("res://scenes/undocking/undocking_scene.tscn")


## Creates exit scan line effect
func _create_exit_scan_effect(parent_layer: CanvasLayer) -> void:
	var scan_line = ColorRect.new()
	scan_line.name = "ExitScan"
	scan_line.color = Color(0.2, 0.9, 0.6, 0.5)  # Green scan matching success
	scan_line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scan_line.size.y = 4
	scan_line.position.y = 0
	parent_layer.add_child(scan_line)
	
	var screen_height = get_viewport_rect().size.y
	
	# Sweep down faster for snappy exit
	var tween = create_tween()
	tween.tween_property(scan_line, "position:y", screen_height, 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(scan_line, "color:a", 0.0, 0.5).set_ease(Tween.EASE_IN)


## Fades out UI elements smoothly
func _fade_ui_elements() -> void:
	var ui_elements = [timer_label, loot_value_label, ship_tier_label, character_panel]
	
	for element in ui_elements:
		if element and element.visible:
			var tween = create_tween()
			tween.tween_property(element, "modulate:a", 0.0, 0.3)


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


## Clean up all active animation layers
func _cleanup_animation_layers() -> void:
	for layer in active_animation_layers:
		if is_instance_valid(layer):
			layer.queue_free()
	active_animation_layers.clear()


## Helper to create and track a canvas layer for animations
func _create_tracked_canvas_layer(layer_name: String, layer_level: int) -> CanvasLayer:
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = layer_name
	canvas_layer.layer = layer_level
	add_child(canvas_layer)
	active_animation_layers.append(canvas_layer)
	return canvas_layer


## Helper to remove a tracked layer
func _remove_tracked_layer(layer: CanvasLayer) -> void:
	active_animation_layers.erase(layer)
	if is_instance_valid(layer):
		layer.queue_free()


## Get the player's inventory (used by doors for keycard checking)
func get_inventory() -> SlotInventory:
	return inventory


# ==============================================================================
# ENTRANCE ANIMATION
# ==============================================================================

func _start_entrance_animation() -> void:
	entrance_active = true
	entrance_timer = 0.0
	entrance_phase = 0
	
	# Start with tighter zoom for dramatic reveal
	if camera:
		camera.zoom = Vector2(ENTRANCE_INITIAL_ZOOM, ENTRANCE_INITIAL_ZOOM)
	
	# Disable player movement during entrance
	if player:
		player.set_movement_enabled(false)
		# Start player invisible for spawn effect
		player.modulate.a = 0.0
	
	# Create enhanced entrance effects
	_create_entrance_fade()
	_create_scan_line_effect()
	_create_boarding_text_overlay()


func _process_entrance(delta: float) -> void:
	entrance_timer += delta
	var _t = minf(entrance_timer / entrance_duration, 1.0)
	
	# Phase 0: Initial zoom and fade (0.0 - 0.4s)
	if entrance_phase == 0 and entrance_timer > 0.4:
		entrance_phase = 1
		_trigger_player_spawn_effect()
	
	# Phase 1: Player materialization (0.4 - 1.2s)
	if entrance_phase == 1 and entrance_timer > 1.2:
		entrance_phase = 2
		_trigger_ui_slide_in()
	
	# Phase 2: Final settle and UI (1.2 - 2.0s)
	
	# Smooth camera zoom in with easing
	if camera:
		var zoom_progress = minf(entrance_timer / 1.5, 1.0)
		var eased_zoom = ease(zoom_progress, -0.4)  # Ease out for smooth deceleration
		camera.zoom = Vector2(
			lerpf(ENTRANCE_INITIAL_ZOOM, ENTRANCE_FINAL_ZOOM, eased_zoom),
			lerpf(ENTRANCE_INITIAL_ZOOM, ENTRANCE_FINAL_ZOOM, eased_zoom)
		)
	
	# Fade in player with glow effect
	if player and entrance_timer > 0.3 and entrance_timer < 1.4:
		var player_t = clampf((entrance_timer - 0.3) / 1.1, 0.0, 1.0)
		var player_eased = ease(player_t, 0.4)
		player.modulate.a = player_eased
		
		# Add slight glow during materialization
		if player_t < 0.95:
			var glow_intensity = sin(player_t * PI) * 0.3
			player.modulate = Color(
				1.0 + glow_intensity,
				1.0 + glow_intensity,
				1.0 + glow_intensity,
				player_eased
			)
		else:
			player.modulate = Color(1.0, 1.0, 1.0, player_eased)
	
	# End entrance
	if entrance_timer >= entrance_duration:
		entrance_active = false
		print("[BoardingManager] Entrance animation complete, enabling player movement")
		if player:
			player.set_movement_enabled(true)
			player.modulate = Color.WHITE
		
		# Small shake to signal control handoff
		shake_camera(2.0)


func _create_entrance_fade() -> void:
	# Create fade layer
	var fade_layer = _create_tracked_canvas_layer("EntranceFade", 100)
	
	var fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color(0, 0, 0, 1.0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_layer.add_child(fade_rect)
	
	# Fade in tween - slightly faster for snappier feel
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(func(): _remove_tracked_layer(fade_layer))


## Creates scan line effect during boarding entrance
func _create_scan_line_effect() -> void:
	var scan_layer = _create_tracked_canvas_layer("ScanEffect", 99)
	
	var scan_line = ColorRect.new()
	scan_line.name = "ScanLine"
	scan_line.color = Color(0.3, 0.8, 1.0, 0.6)  # Cyan scan beam
	scan_line.anchor_left = 0.0
	scan_line.anchor_right = 1.0
	scan_line.anchor_top = 0.0
	scan_line.anchor_bottom = 0.0
	scan_line.offset_bottom = 3  # Height of scan line
	scan_layer.add_child(scan_line)
	
	var screen_height = get_viewport_rect().size.y
	
	# Sweep down the screen
	var tween = create_tween()
	tween.tween_property(scan_line, "position:y", screen_height, 0.8).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(scan_line, "color:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): _remove_tracked_layer(scan_layer))


## Creates "BOARDING..." text overlay
func _create_boarding_text_overlay() -> void:
	var text_layer = _create_tracked_canvas_layer("BoardingText", 98)
	
	var label = Label.new()
	label.name = "BoardingLabel"
	# Safe ship name handling with simplified fallback
	var ship_name = current_ship_data.display_name.to_upper() if current_ship_data else "UNKNOWN"
	label.text = "BOARDING %s..." % ship_name
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 0.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	text_layer.add_child(label)
	
	# Fade in then out
	var tween = create_tween()
	tween.tween_property(label, "theme_override_colors/font_color:a", 1.0, 0.3).set_delay(0.2)
	tween.tween_property(label, "theme_override_colors/font_color:a", 0.0, 0.4).set_delay(0.6)
	tween.tween_callback(func(): _remove_tracked_layer(text_layer))


## Triggers player spawn/materialization particle effect
func _trigger_player_spawn_effect() -> void:
	if not player:
		return
	
	# Create spawn flash
	var flash_layer = _create_tracked_canvas_layer("SpawnFlash", 95)
	
	var flash = ColorRect.new()
	flash.color = Color(0.3, 0.8, 1.0, 0.6)  # Cyan flash
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.2)
	tween.tween_callback(func(): _remove_tracked_layer(flash_layer))
	
	# Small camera shake
	shake_camera(3.0)


## Triggers UI elements to slide in
func _trigger_ui_slide_in() -> void:
	# Animate timer label slide from top
	if timer_label:
		var original_pos = timer_label.position
		timer_label.position.y -= 50
		timer_label.modulate.a = 0.0
		
		var tween1 = create_tween()
		tween1.tween_property(timer_label, "position:y", original_pos.y, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween1.parallel().tween_property(timer_label, "modulate:a", 1.0, 0.3)
	
	# Animate loot value label slide from bottom
	if loot_value_label:
		var original_pos = loot_value_label.position
		loot_value_label.position.y += 50
		loot_value_label.modulate.a = 0.0
		
		var tween2 = create_tween()
		tween2.tween_property(loot_value_label, "position:y", original_pos.y, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween2.parallel().tween_property(loot_value_label, "modulate:a", 1.0, 0.3)
	
	# Animate ship tier label
	if ship_tier_label:
		var original_pos = ship_tier_label.position
		ship_tier_label.position.x -= 50
		ship_tier_label.modulate.a = 0.0
		
		var tween3 = create_tween()
		tween3.tween_property(ship_tier_label, "position:x", original_pos.x, 0.4).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)  # Slight delay for stagger effect
		tween3.parallel().tween_property(ship_tier_label, "modulate:a", 1.0, 0.3)


# ==============================================================================
# UI
# ==============================================================================

func _update_ui() -> void:
	if loot_value_label:
		# Value display moved to inventory only
		loot_value_label.visible = false


# ==============================================================================
# TUTORIAL INTEGRATION
# ==============================================================================

func _check_and_start_tutorial() -> void:
	# Wait for entrance animation to finish
	await get_tree().create_timer(entrance_duration + 0.5).timeout
	
	# Check if TutorialManager exists
	if not has_node("/root/TutorialManager"):
		return
	
	var tutorial_manager = get_node("/root/TutorialManager")
	
	# Start tutorial if needed
	tutorial_manager.start_tutorial()


func _on_player_moved() -> void:
	# Notify tutorial that player moved
	if has_node("/root/TutorialManager"):
		var tutorial_manager = get_node("/root/TutorialManager")
		tutorial_manager.on_player_action("movement")


func _on_container_interacted() -> void:
	# Notify tutorial that container was interacted with
	if has_node("/root/TutorialManager"):
		var tutorial_manager = get_node("/root/TutorialManager")
		tutorial_manager.on_player_action("container_search")


func _on_inventory_opened() -> void:
	# Notify tutorial that inventory was opened
	if has_node("/root/TutorialManager"):
		var tutorial_manager = get_node("/root/TutorialManager")
		tutorial_manager.on_player_action("inventory_open")


func _on_exit_interacted() -> void:
	# Notify tutorial that exit was reached
	if has_node("/root/TutorialManager"):
		var tutorial_manager = get_node("/root/TutorialManager")
		tutorial_manager.on_player_action("exit_reached")


# ==============================================================================
# MINIMAP
# ==============================================================================

## Setup the minimap with current layout data
func _setup_minimap() -> void:
	if not minimap or not current_layout:
		return
	
	# Get the minimap renderer from the scene
	var renderer = _get_minimap_renderer()
	if not renderer:
		return
	
	# Get the SubViewportContainer to determine minimap size
	var container = minimap.get_node_or_null("MarginContainer/SubViewportContainer")
	if container and renderer.has_method("set_minimap_size"):
		renderer.set_minimap_size(container.size)
	
	# Set the layout data
	renderer.set_layout(current_layout)
	
	# Set exit position
	if exit_point:
		renderer.set_exit_position(current_layout.exit_position)
	
	# Build container list with positions and searched states
	_update_minimap_containers()


## Setup the fog of war vision system
func _setup_vision_system() -> void:
	if not enable_fog_of_war:
		return
	
	if not player:
		push_warning("[BoardingManager] Cannot setup vision system: no player")
		return
	
	# Create vision system
	vision_system = VisionSystemClass.new()
	vision_system.name = "VisionSystem"
	
	# Configure vision parameters
	vision_system.always_visible_radius = always_visible_radius
	
	# Add to scene tree
	add_child(vision_system)
	
	# Initialize with player and ship bounds - use layout_offset to match ship position
	var ship_size = current_layout.ship_size if current_layout else Vector2(2000, 1500)
	var ship_origin = layout_offset if layout_offset != Vector2.ZERO else Vector2.ZERO
	var ship_bounds = Rect2(ship_origin, ship_size)
	vision_system.initialize(player, ship_bounds)
	
	# Connect player to vision system
	if player.has_method("set_vision_system"):
		player.set_vision_system(vision_system)
	else:
		# Manual connection if method doesn't exist
		vision_system.set_player(player)
	
	# Set initial look direction
	vision_system.set_look_direction(Vector2.RIGHT)
	
	# Reveal starting area (boarding dock)
	if current_layout:
		vision_system.reveal_area(current_layout.entry_position, always_visible_radius * 2)
	
	print("[BoardingManager] Vision system initialized")


## Update minimap every frame
func _update_minimap() -> void:
	if not minimap or not player:
		return
	
	var renderer = _get_minimap_renderer()
	if not renderer:
		return
	
	# Update player position (account for layout offset)
	var player_position_relative_to_layout = player.position - layout_offset
	renderer.update_player_position(player_position_relative_to_layout)


## Update minimap container states
func _update_minimap_containers() -> void:
	if not minimap or not containers_parent:
		return
	
	var renderer = _get_minimap_renderer()
	if not renderer:
		return
	
	var container_list = []
	for container_node in containers_parent.get_children():
		if container_node is ShipContainer:
			var container_data = {
				"position": container_node.position,
				"searched": container_node.current_state != ShipContainer.ContainerState.CLOSED
			}
			container_list.append(container_data)
	
	renderer.set_containers(container_list)


## Get the minimap renderer node
func _get_minimap_renderer() -> Node:
	if not minimap:
		return null
	
	# Navigate to the renderer: Minimap/MarginContainer/SubViewportContainer/SubViewport/MinimapRenderer
	var container = minimap.get_node_or_null("MarginContainer/SubViewportContainer")
	if not container:
		return null
	
	var viewport = container.get_node_or_null("SubViewport")
	if not viewport:
		return null
	
	return viewport.get_node_or_null("MinimapRenderer")


## Mark a container as searched on the minimap
func _mark_container_searched(container: Node2D) -> void:
	if not minimap or not container:
		return
	
	var renderer = _get_minimap_renderer()
	if not renderer:
		return
	
	var container_pos = container.position
	renderer.mark_container_searched(container_pos)
	
	# Also refresh the full container list
	_update_minimap_containers()


# ==============================================================================
# UPDATED INTERACTION HANDLERS
# ==============================================================================
