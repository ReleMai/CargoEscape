# ==============================================================================
# CUTSCENE MANAGER (AUTOLOAD/SINGLETON)
# ==============================================================================
#
# FILE: scripts/core/cutscene_manager.gd
# PURPOSE: Manages cutscene skip controls and settings globally
#
# FEATURES:
# - Skip entire cutscene (Space/Enter)
# - Fast forward cutscene (Hold Space for 2x speed)
# - Skip to gameplay (Escape key)
# - UI skip prompt with fade
# - Progress indicator for long cutscenes
# - Settings: Skip all cutscenes preference
#
# USAGE:
# 1. Call CutsceneManager.register_cutscene() at the start of a cutscene
# 2. Check CutsceneManager.is_fast_forwarding() in _process to apply speed
# 3. Connect to skip/complete signals to handle cutscene end
# 4. Call CutsceneManager.unregister_cutscene() when done
#
# ==============================================================================

extends Node


# ==============================================================================
# SIGNALS
# ==============================================================================

## Emitted when the player requests to skip the current cutscene
signal skip_requested

## Emitted when the player requests to skip to gameplay
signal skip_to_gameplay_requested

## Emitted when cutscene progress changes (0.0 to 1.0)
signal progress_changed(progress: float)


# ==============================================================================
# CONSTANTS
# ==============================================================================

## Fast forward speed multiplier
const FAST_FORWARD_SPEED: float = 2.0

## Time for skip hint to fade out (seconds)
const SKIP_HINT_FADE_TIME: float = 2.0


# ==============================================================================
# SETTINGS
# ==============================================================================

## Whether to automatically skip all cutscenes
var skip_all_cutscenes: bool = false


# ==============================================================================
# STATE
# ==============================================================================

## Whether a cutscene is currently active
var is_cutscene_active: bool = false

## Current cutscene name (for debugging)
var current_cutscene_name: String = ""

## Whether Space key is currently held for fast forward
var is_fast_forward_held: bool = false

## Current cutscene progress (0.0 to 1.0)
var current_progress: float = 0.0

## Whether skip hint should be shown
var show_skip_hint: bool = true

## Time since cutscene started (for fade timer)
var cutscene_time: float = 0.0


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Load settings
	_load_settings()


func _process(delta: float) -> void:
	if not is_cutscene_active:
		return
	
	# Update cutscene timer
	cutscene_time += delta
	
	# Check for fast forward input
	is_fast_forward_held = Input.is_action_pressed("ui_accept") or Input.is_physical_key_pressed(KEY_SPACE)


func _input(event: InputEvent) -> void:
	if not is_cutscene_active:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		# Skip entire cutscene (Space or Enter)
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_request_skip()
		
		# Skip to gameplay (Escape)
		elif event.keycode == KEY_ESCAPE:
			_request_skip_to_gameplay()


# ==============================================================================
# CUTSCENE REGISTRATION
# ==============================================================================

## Register a new cutscene. Call this when a cutscene starts.
## @param cutscene_name: Name of the cutscene (for debugging)
## @param show_hint: Whether to show the skip hint
func register_cutscene(cutscene_name: String = "Unknown", show_hint: bool = true) -> void:
	is_cutscene_active = true
	current_cutscene_name = cutscene_name
	current_progress = 0.0
	cutscene_time = 0.0
	show_skip_hint = show_hint
	is_fast_forward_held = false
	
	print("[CutsceneManager] Registered cutscene: ", cutscene_name)
	
	# Auto-skip if setting is enabled
	if skip_all_cutscenes:
		call_deferred("_request_skip")


## Unregister the current cutscene. Call this when a cutscene ends.
func unregister_cutscene() -> void:
	if is_cutscene_active:
		print("[CutsceneManager] Unregistered cutscene: ", current_cutscene_name)
	
	is_cutscene_active = false
	current_cutscene_name = ""
	current_progress = 0.0
	cutscene_time = 0.0
	is_fast_forward_held = false


## Update the progress of the current cutscene
## @param progress: Progress value from 0.0 to 1.0
func update_progress(progress: float) -> void:
	current_progress = clampf(progress, 0.0, 1.0)
	progress_changed.emit(current_progress)


# ==============================================================================
# SKIP CONTROLS
# ==============================================================================

## Check if fast forward is currently active
func is_fast_forwarding() -> bool:
	return is_cutscene_active and is_fast_forward_held


## Get the current speed multiplier for the cutscene
func get_speed_multiplier() -> float:
	if is_fast_forwarding():
		return FAST_FORWARD_SPEED
	return 1.0


## Request to skip the current cutscene
func _request_skip() -> void:
	if not is_cutscene_active:
		return
	
	print("[CutsceneManager] Skip requested for: ", current_cutscene_name)
	skip_requested.emit()


## Request to skip to gameplay (Escape key)
func _request_skip_to_gameplay() -> void:
	if not is_cutscene_active:
		return
	
	print("[CutsceneManager] Skip to gameplay requested for: ", current_cutscene_name)
	skip_to_gameplay_requested.emit()


## Check if the skip hint should currently be visible
func should_show_skip_hint() -> bool:
	if not is_cutscene_active or not show_skip_hint:
		return false
	
	# Fade out after SKIP_HINT_FADE_TIME seconds
	return cutscene_time < SKIP_HINT_FADE_TIME


## Get the alpha value for the skip hint (for fade animation)
func get_skip_hint_alpha() -> float:
	if not should_show_skip_hint():
		return 0.0
	
	if cutscene_time >= SKIP_HINT_FADE_TIME - 0.5:
		# Fade out over last 0.5 seconds
		var fade_progress = (cutscene_time - (SKIP_HINT_FADE_TIME - 0.5)) / 0.5
		return 1.0 - fade_progress
	
	return 1.0


# ==============================================================================
# SETTINGS MANAGEMENT
# ==============================================================================

## Load cutscene settings from persistent storage
func _load_settings() -> void:
	# For now, use a simple file-based approach
	var save_path = "user://cutscene_settings.json"
	
	if not FileAccess.file_exists(save_path):
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY:
				skip_all_cutscenes = data.get("skip_all_cutscenes", false)
				print("[CutsceneManager] Settings loaded - skip_all: ", skip_all_cutscenes)


## Save cutscene settings to persistent storage
func save_settings() -> void:
	var save_path = "user://cutscene_settings.json"
	
	var data = {
		"skip_all_cutscenes": skip_all_cutscenes
	}
	
	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("[CutsceneManager] Settings saved - skip_all: ", skip_all_cutscenes)


## Set whether to skip all cutscenes
func set_skip_all_cutscenes(value: bool) -> void:
	skip_all_cutscenes = value
	save_settings()
