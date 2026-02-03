# ==============================================================================
# LOADING SCREEN (AUTOLOAD/SINGLETON)
# ==============================================================================
#
# FILE: scripts/ui/loading_screen.gd
# PURPOSE: Displays loading screen during scene transitions with tips
#
# FEATURES:
# - Loading progress bar
# - Random gameplay tips
# - Animated background/spinner
# - Fade in/out transitions
#
# USAGE:
# LoadingScreen.start_transition("res://scenes/main.tscn")
#
# ==============================================================================

extends CanvasLayer


# ==============================================================================
# SIGNALS
# ==============================================================================

signal transition_started
signal transition_finished


# ==============================================================================
# NODE REFERENCES (created programmatically)
# ==============================================================================

var background: ColorRect = null
var spinner_container: Control = null
var spinner: ColorRect = null
var progress_bar: ProgressBar = null
var tip_label: Label = null
var loading_label: Label = null


# ==============================================================================
# GAMEPLAY TIPS
# ==============================================================================

const GAMEPLAY_TIPS: Array[String] = [
	"Search containers thoroughly - rare items hide in unexpected places",
	"Different factions have different loot tables",
	"Watch your oxygen timer!",
	"Heavier items slow you down - choose wisely",
	"Some containers require tools to open",
	"Listen for audio cues - they can warn you of danger",
	"Quick looting is key to survival",
	"Module upgrades can drastically improve your ship",
	"The deeper you go, the better the loot",
	"Don't get greedy - know when to escape",
	"Enemy patrols have patterns - learn them",
	"Your ship inventory is limited - prioritize valuable items",
	"Use cover to avoid enemy fire",
	"Asteroids can be both obstacles and shields",
	"Some ships have better loot than others",
]


# ==============================================================================
# CONSTANTS
# ==============================================================================

## Delay after scene change before hiding loading screen
const SCENE_CHANGE_DELAY: float = 0.1

## Duration to display 100% progress before transitioning
const PROGRESS_COMPLETE_DISPLAY_DURATION: float = 0.3


# ==============================================================================
# STATE
# ==============================================================================

var is_transitioning: bool = false
var target_scene: String = ""
var fade_alpha: float = 0.0
var spinner_rotation: float = 0.0
var progress: float = 0.0


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Create UI elements programmatically since this is an autoload
	_create_ui()
	
	# Hide loading screen initially
	visible = false
	layer = 100  # Ensure it's on top of everything
	
	# Set up progress bar
	if progress_bar:
		progress_bar.min_value = 0.0
		progress_bar.max_value = 100.0
		progress_bar.value = 0.0
	
	print("[LoadingScreen] Ready")


func _create_ui() -> void:
	# Background
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0.02, 0.02, 0.08, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# Spinner container (centered)
	spinner_container = Control.new()
	spinner_container.name = "SpinnerContainer"
	spinner_container.set_anchors_preset(Control.PRESET_CENTER)
	spinner_container.size = Vector2(64, 64)
	spinner_container.position = Vector2(-32, -80)
	add_child(spinner_container)
	
	# Spinner (rotating square)
	spinner = ColorRect.new()
	spinner.name = "Spinner"
	spinner.color = Color(0.4, 0.6, 1.0, 0.8)
	spinner.size = Vector2(32, 32)
	spinner.position = Vector2(16, 16)
	spinner.pivot_offset = Vector2(16, 16)
	spinner_container.add_child(spinner)
	
	# Progress container
	var progress_container = Control.new()
	progress_container.name = "ProgressContainer"
	progress_container.set_anchors_preset(Control.PRESET_CENTER)
	progress_container.size = Vector2(400, 20)
	progress_container.position = Vector2(-200, 0)
	add_child(progress_container)
	
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.show_percentage = false
	progress_container.add_child(progress_bar)
	
	# Loading label
	loading_label = Label.new()
	loading_label.name = "LoadingLabel"
	loading_label.text = "Loading..."
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.set_anchors_preset(Control.PRESET_CENTER)
	loading_label.position = Vector2(-200, 30)
	loading_label.size = Vector2(400, 30)
	add_child(loading_label)
	
	# Tip label
	tip_label = Label.new()
	tip_label.name = "TipLabel"
	tip_label.text = ""
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_label.set_anchors_preset(Control.PRESET_CENTER)
	tip_label.position = Vector2(-300, 80)
	tip_label.size = Vector2(600, 60)
	tip_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	add_child(tip_label)


func _process(delta: float) -> void:
	if not is_transitioning:
		return
	
	# Animate spinner
	spinner_rotation += delta * 360.0  # One rotation per second
	if spinner_rotation >= 360.0:
		spinner_rotation -= 360.0
	
	if spinner:
		spinner.rotation = deg_to_rad(spinner_rotation)
	
	# Update fade
	if fade_alpha < 1.0:
		fade_alpha += delta * 2.0  # Fade in over 0.5 seconds
		fade_alpha = minf(fade_alpha, 1.0)
		_update_fade()
	
	# Simulate loading progress (smooth animation)
	if progress < 100.0:
		progress += delta * 150.0  # Complete in ~0.67 seconds
		progress = minf(progress, 100.0)
		if progress_bar:
			progress_bar.value = progress


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Start a scene transition with loading screen
func start_transition(scene_path: String) -> void:
	if is_transitioning:
		# Silently ignore duplicate transition requests (common during input spam)
		return
	
	var from_scene = get_tree().current_scene.scene_file_path if get_tree().current_scene else "unknown"
	print("[LoadingScreen] Starting transition to: ", scene_path)
	
	# Log scene change
	if DebugLogger:
		DebugLogger.log_scene_change(from_scene.get_file(), scene_path.get_file())
	
	_transition_start_time = Time.get_ticks_msec()
	target_scene = scene_path
	is_transitioning = true
	fade_alpha = 0.0
	progress = 0.0
	spinner_rotation = 0.0
	
	# Show loading screen
	visible = true
	
	# Set random tip
	_set_random_tip()
	
	# Reset progress bar
	if progress_bar:
		progress_bar.value = 0.0
	
	# Emit signal
	transition_started.emit()
	
	# Start loading the scene in background
	_load_scene_async()


## Track transition timing
var _transition_start_time: float = 0.0

## Finish the transition
func finish_transition() -> void:
	if not is_transitioning:
		return
	
	var load_time = Time.get_ticks_msec() - _transition_start_time
	print("[LoadingScreen] Finishing transition (%.0fms)" % load_time)
	is_transitioning = false
	fade_alpha = 0.0
	
	# Change to the target scene
	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)
	
	# Hide loading screen after scene change
	await get_tree().create_timer(SCENE_CHANGE_DELAY).timeout
	visible = false
	
	# Emit signal
	transition_finished.emit()


# ==============================================================================
# PRIVATE FUNCTIONS
# ==============================================================================

## Set a random gameplay tip
func _set_random_tip() -> void:
	if not tip_label:
		return
	
	var tip_index = randi() % GAMEPLAY_TIPS.size()
	tip_label.text = GAMEPLAY_TIPS[tip_index]


## Update fade alpha on all elements
func _update_fade() -> void:
	var color_alpha = Color(1, 1, 1, fade_alpha)
	
	if background:
		background.color = Color(0.02, 0.02, 0.08, fade_alpha)
	
	if spinner:
		spinner.modulate = color_alpha
	
	if progress_bar:
		progress_bar.modulate = color_alpha
	
	if tip_label:
		tip_label.modulate = color_alpha
	
	if loading_label:
		loading_label.modulate = color_alpha


## Load scene asynchronously
func _load_scene_async() -> void:
	# Request to load scene
	var error = ResourceLoader.load_threaded_request(target_scene)
	if error != OK:
		print("[LoadingScreen] Error requesting scene load: ", error)
		finish_transition()
		return
	
	# Wait for loading to complete
	await _wait_for_scene_load()


## Wait for scene to finish loading
func _wait_for_scene_load() -> void:
	var status: ResourceLoader.ThreadLoadStatus
	
	while true:
		status = ResourceLoader.load_threaded_get_status(target_scene)
		
		match status:
			ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				print("[LoadingScreen] Invalid resource!")
				finish_transition()
				return
			
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				# Still loading, wait a frame
				await get_tree().process_frame
			
			ResourceLoader.THREAD_LOAD_FAILED:
				print("[LoadingScreen] Failed to load scene!")
				finish_transition()
				return
			
			ResourceLoader.THREAD_LOAD_LOADED:
				# Loading complete! Wait for progress bar to finish
				while progress < 100.0:
					await get_tree().process_frame
				
				# Add a small delay to show 100%
				await get_tree().create_timer(PROGRESS_COMPLETE_DISPLAY_DURATION).timeout
				
				# Finish transition
				finish_transition()
				return
