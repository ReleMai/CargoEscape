# ==============================================================================
# UNDOCKING SCENE CONTROLLER - SEAMLESS TRANSITION MANAGER
# ==============================================================================
#
# FILE: scripts/undocking/undocking_scene_controller.gd
# PURPOSE: Controls the undocking cutscene with smooth transitions
#
# FEATURES:
# - Fade in from boarding scene
# - Status text overlay with typewriter effect
# - Progress bar showing undocking progress
# - Seamless blend to escape scene
# - Skip functionality
#
# ==============================================================================

extends Node2D


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var undocking_manager: UndockingManager = $UndockingManager
@onready var ui_layer: CanvasLayer = $UI
@onready var status_label: Label = $UI/StatusLabel
@onready var station_label: Label = $UI/StationLabel
@onready var progress_bar: ProgressBar = $UI/ProgressBar
@onready var skip_hint: Label = $UI/SkipHint


# ==============================================================================
# STATE
# ==============================================================================

var game_manager: Node
var current_station_data: Resource
var current_ship_type: int = 0  # ShipVisual.ShipType
var can_skip: bool = true

# Status text animation
var target_status: String = ""
var displayed_status: String = ""
var char_timer: float = 0.0
var chars_per_second: float = 40.0


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Get GameManager
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		_load_from_game_manager()
	else:
		push_warning("[Undocking] GameManager not found")
		current_station_data = preload("res://resources/stations/abandoned_station.tres")
	
	# Setup UI
	_setup_ui()
	
	# Connect signals
	undocking_manager.undocking_complete.connect(_on_undocking_complete)
	undocking_manager.undocking_progress.connect(_on_progress_update)
	undocking_manager.status_changed.connect(_on_status_changed)
	
	# Register with CutsceneManager
	CutsceneManager.register_cutscene("Undocking Sequence", true)
	CutsceneManager.skip_requested.connect(_on_cutscene_skip_requested)
	CutsceneManager.skip_to_gameplay_requested.connect(_on_cutscene_skip_to_gameplay)
	
	# Start the sequence
	undocking_manager.start_undocking(current_ship_type, current_station_data)


func _process(delta: float) -> void:
	# Update skip hint visibility based on CutsceneManager
	if skip_hint:
		skip_hint.modulate.a = CutsceneManager.get_skip_hint_alpha()
	
	# Animate status text (typewriter effect)
	if displayed_status != target_status:
		var speed_mult = CutsceneManager.get_speed_multiplier()
		char_timer += delta * chars_per_second * speed_mult
		var chars_to_show = int(char_timer)
		if chars_to_show >= target_status.length():
			displayed_status = target_status
		else:
			displayed_status = target_status.substr(0, chars_to_show)
		status_label.text = displayed_status


func _input(event: InputEvent) -> void:
	# CutsceneManager handles skip inputs globally
	pass


# ==============================================================================
# SETUP
# ==============================================================================

func _load_from_game_manager() -> void:
	# Get station data
	if game_manager.has_method("get_escape_station"):
		current_station_data = game_manager.get_escape_station()
	elif "escape_station" in game_manager:
		current_station_data = game_manager.escape_station
	
	if current_station_data == null:
		current_station_data = preload("res://resources/stations/abandoned_station.tres")
	
	# Get ship type
	if game_manager.has_method("get_ship_type"):
		current_ship_type = game_manager.get_ship_type()
	elif "ship_type" in game_manager:
		current_ship_type = game_manager.ship_type
	
	# Apply modules to ship visual (after undocking_manager creates it)
	call_deferred("_apply_modules")


func _apply_modules() -> void:
	if not game_manager:
		return
	
	# Get equipped modules
	var modules: Dictionary = {}
	if game_manager.has_method("get_equipped_modules"):
		modules = game_manager.get_equipped_modules()
	elif "equipped_modules" in game_manager:
		modules = game_manager.equipped_modules
	
	# Apply to ship visual
	for slot_type in modules:
		var module = modules[slot_type]
		if module and undocking_manager.ship_visual:
			undocking_manager.ship_visual.equip_module(module)


func _setup_ui() -> void:
	# Station name
	if current_station_data and "station_name" in current_station_data:
		station_label.text = "DEPARTING: " + current_station_data.station_name
	else:
		station_label.text = "DEPARTING: Unknown Station"
	
	# Initial status
	status_label.text = ""
	target_status = ""
	
	# Progress bar
	progress_bar.value = 0
	progress_bar.modulate.a = 0.7
	
	# Skip hint
	skip_hint.text = "SPACE to skip"
	skip_hint.modulate.a = 0.5


# ==============================================================================
# SIGNAL HANDLERS
# ==============================================================================

func _on_status_changed(text: String) -> void:
	target_status = text
	displayed_status = ""
	char_timer = 0.0
	
	if text == "":
		status_label.text = ""


func _on_progress_update(progress: float) -> void:
	progress_bar.value = progress * 100
	CutsceneManager.update_progress(progress)


func _on_undocking_complete() -> void:
	can_skip = false
	skip_hint.visible = false
	
	# Store station for escape scene
	if game_manager:
		if game_manager.has_method("set_escape_station"):
			game_manager.set_escape_station(current_station_data)
		elif "escape_station" in game_manager:
			game_manager.escape_station = current_station_data
	
	# Seamless transition - just a quick fade
	_transition_to_escape()


func _skip() -> void:
	if not can_skip:
		return
	
	can_skip = false
	skip_hint.visible = false
	undocking_manager.skip_animation()


# ==============================================================================
# CUTSCENE SKIP HANDLERS
# ==============================================================================

func _on_cutscene_skip_requested() -> void:
	_skip()


func _on_cutscene_skip_to_gameplay() -> void:
	# Skip directly to escape scene
	can_skip = false
	_go_to_escape()


func _transition_to_escape() -> void:
	# Quick fade (the undocking already faded partially)
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.3  # Start from where undocking left off
	fade.anchors_preset = Control.PRESET_FULL_RECT
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(fade)
	
	# Fade UI out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(fade, "modulate:a", 1.0, 0.4)
	tween.tween_property(status_label, "modulate:a", 0.0, 0.3)
	tween.tween_property(station_label, "modulate:a", 0.0, 0.3)
	tween.tween_property(progress_bar, "modulate:a", 0.0, 0.3)
	
	tween.chain().tween_callback(_go_to_escape)


func _go_to_escape() -> void:
	# Unregister cutscene before changing scene
	if CutsceneManager.skip_requested.is_connected(_on_cutscene_skip_requested):
		CutsceneManager.skip_requested.disconnect(_on_cutscene_skip_requested)
	if CutsceneManager.skip_to_gameplay_requested.is_connected(_on_cutscene_skip_to_gameplay):
		CutsceneManager.skip_to_gameplay_requested.disconnect(_on_cutscene_skip_to_gameplay)
	CutsceneManager.unregister_cutscene()
	
	LoadingScreen.start_transition("res://scenes/main.tscn")
