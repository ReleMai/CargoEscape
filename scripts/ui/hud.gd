# ==============================================================================
# HUD (HEADS-UP DISPLAY) SCRIPT
# ==============================================================================
# 
# FILE: scripts/ui/hud.gd
# PURPOSE: Manages the in-game user interface showing lives, score, etc.
#
# ATTACHED TO: HUD scene (CanvasLayer)
#
# WHAT IS A CANVASLAYER?
# ----------------------
# CanvasLayer is a special node that renders on a separate layer.
# This means:
# - UI stays fixed on screen (doesn't scroll with game)
# - UI is always on top of game elements
# - UI isn't affected by game camera movement
#
# SCENE STRUCTURE:
# ----------------
# HUD (CanvasLayer) <- This script
# ├── MarginContainer
# │   ├── VBoxContainer (top-left)
# │   │   ├── LivesLabel
# │   │   └── ScoreLabel
# │   └── (other UI elements)
# └── ...
#
# ==============================================================================

extends CanvasLayer


# ==============================================================================
# ONREADY VARIABLES
# ==============================================================================

## Label showing remaining lives
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthContainer/HealthBar

## Health text label
@onready var health_label: Label = $MarginContainer/VBoxContainer/HealthContainer/HealthLabel

## Label showing current score
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel

## Label showing current speed (new!)
@onready var speed_label: Label = $MarginContainer/VBoxContainer/SpeedLabel

## Distance to hideout progress bar
@onready var distance_bar: ProgressBar = $DistanceBarContainer/VBox/DistanceBar

## Distance percentage text
@onready var distance_text: Label = $DistanceBarContainer/VBox/DistanceText

## Distance label
@onready var distance_label: Label = $DistanceBarContainer/VBox/DistanceLabel

## Combo UI elements
@onready var combo_label: Label = $MarginContainer/VBoxContainer/ComboContainer/ComboLabel
@onready var combo_timer_bar: ProgressBar = $MarginContainer/VBoxContainer/ComboContainer/ComboTimerBar


# ==============================================================================
# REGULAR VARIABLES
# ==============================================================================

## Reference to GameManager for reading game state
var game_manager: Node

## Reference to player for speed display
var player_ref: Node2D

## Animation tween for effects
var tween: Tween

## Combo animation tween
var combo_tween: Tween


# ==============================================================================
# BUILT-IN FUNCTIONS
# ==============================================================================

# ------------------------------------------------------------------------------
# _ready() - Initialize HUD
# ------------------------------------------------------------------------------
func _ready() -> void:
	# Get reference to GameManager
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		
		# Connect to GameManager signals
		game_manager.health_changed.connect(_on_health_changed)
		game_manager.game_reset.connect(_on_game_reset)
		
		# Connect to ComboSystem signals
		if game_manager.combo_system:
			game_manager.combo_system.combo_changed.connect(_on_combo_changed)
			game_manager.combo_system.combo_timer_updated.connect(_on_combo_timer_updated)
			game_manager.combo_system.combo_broken.connect(_on_combo_broken)
			game_manager.combo_system.combo_threshold_reached.connect(_on_combo_threshold_reached)
		
		# Initial update
		update_display()
	else:
		push_warning("GameManager not found - HUD won't update automatically")
	
	# Find player for speed display
	call_deferred("_find_player")


func _find_player() -> void:
	player_ref = get_tree().get_first_node_in_group("player")


# ------------------------------------------------------------------------------
# _process(delta) - Update display every frame
# ------------------------------------------------------------------------------
func _process(_delta: float) -> void:
	# Update score continuously (it changes every frame)
	if game_manager:
		update_score()
	
	# Update speed display
	update_speed()
	
	# Update distance bar
	update_distance()


# ==============================================================================
# DISPLAY UPDATE FUNCTIONS
# ==============================================================================

# ------------------------------------------------------------------------------
# update_display() - Update all HUD elements
# ------------------------------------------------------------------------------
func update_display() -> void:
	update_health()
	update_score()
	update_speed()
	update_distance()


# ------------------------------------------------------------------------------
# update_distance() - Update distance to hideout progress bar
# ------------------------------------------------------------------------------
func update_distance() -> void:
	if distance_bar == null:
		return
	
	# Get distance progress from main scene
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("get_distance_progress"):
		var progress = main_scene.get_distance_progress()
		distance_bar.value = progress
		
		if distance_text:
			var percent = int(progress * 100)
			distance_text.text = "%d%% - " % percent
			if progress < 0.3:
				distance_text.text += "Enemy territory"
			elif progress < 0.7:
				distance_text.text += "Neutral space"
			elif progress < 1.0:
				distance_text.text += "Almost there!"
			else:
				distance_text.text = "HIDEOUT REACHED!"


# ------------------------------------------------------------------------------
# update_health() - Update health bar display
# ------------------------------------------------------------------------------
func update_health() -> void:
	if not game_manager:
		return
	
	if health_bar:
		health_bar.max_value = game_manager.max_health
		health_bar.value = game_manager.current_health
	
	if health_label:
		var percent = game_manager.get_health_percent()
		health_label.text = "%d%%" % int(percent)
		
		# Color based on health
		if percent > 60:
			health_label.modulate = Color(0.4, 1, 0.5)  # Green
		elif percent > 30:
			health_label.modulate = Color(1, 0.9, 0.3)  # Yellow
		else:
			health_label.modulate = Color(1, 0.3, 0.3)  # Red


# ------------------------------------------------------------------------------
# update_speed() - Update speed display
# ------------------------------------------------------------------------------
func update_speed() -> void:
	if speed_label == null:
		return
	
	if player_ref and is_instance_valid(player_ref) and player_ref.has_method("get_current_speed"):
		var speed = player_ref.get_current_speed()
		speed_label.text = "Speed: %d" % int(speed)
	else:
		speed_label.text = "Speed: ---"


# ------------------------------------------------------------------------------
# update_score() - Update score display
# ------------------------------------------------------------------------------
func update_score() -> void:
	if not score_label or not game_manager:
		return
	
	# Use formatted score (with leading zeros)
	score_label.text = "Score: " + game_manager.get_formatted_score()


# ==============================================================================
# SIGNAL CALLBACKS
# ==============================================================================

# ------------------------------------------------------------------------------
# _on_health_changed(current, max_health) - Called when player health changes
# ------------------------------------------------------------------------------
func _on_health_changed(current: float, max_health: float) -> void:
	print("HUD: Health changed! ", current, "/", max_health)
	
	# Update the display
	update_health()
	
	# Play a visual effect if damage was taken
	if current < max_health:
		flash_health_bar()


# ------------------------------------------------------------------------------
# _on_game_reset() - Called when game resets
# ------------------------------------------------------------------------------
func _on_game_reset() -> void:
	update_display()


# ==============================================================================
# VISUAL EFFECTS
# ==============================================================================

# ------------------------------------------------------------------------------
# flash_health_bar() - Flash the health bar red when hit
# ------------------------------------------------------------------------------
func flash_health_bar() -> void:
	if not health_bar:
		return
	
	# Kill existing tween if running
	if tween:
		tween.kill()
	
	# Create new tween for animation
	tween = create_tween()
	
	# Store original color
	var original_color = health_bar.modulate
	
	# Flash red
	health_bar.modulate = Color.RED
	
	# Animate back to original color over 0.3 seconds
	tween.tween_property(health_bar, "modulate", original_color, 0.3)


# ------------------------------------------------------------------------------
# animate_score_popup(amount) - Show floating score text (bonus feature)
# ------------------------------------------------------------------------------
func animate_score_popup(amount: int, world_position: Vector2) -> void:
	# This could show "+100" floating up from where points were earned
	# For now, just a placeholder for future implementation
	pass


# ==============================================================================
# COMBO SYSTEM
# ==============================================================================

# ------------------------------------------------------------------------------
# update_combo() - Update combo display
# ------------------------------------------------------------------------------
func update_combo() -> void:
	if not game_manager or not game_manager.combo_system:
		return
	
	var combo_count = game_manager.combo_system.get_combo_count()
	var multiplier = game_manager.combo_system.get_multiplier()
	
	if combo_count > 0:
		if combo_label:
			combo_label.text = "COMBO: %dx (%.1fx)" % [combo_count, multiplier]
			combo_label.visible = true
		if combo_timer_bar:
			combo_timer_bar.visible = true
	else:
		if combo_label:
			combo_label.visible = false
		if combo_timer_bar:
			combo_timer_bar.visible = false


# ------------------------------------------------------------------------------
# _on_combo_changed(count, multiplier) - Called when combo changes
# ------------------------------------------------------------------------------
func _on_combo_changed(combo_count: int, multiplier: float) -> void:
	update_combo()
	
	# Animate combo label when it increases
	if combo_count > 0:
		_animate_combo_pulse()


# ------------------------------------------------------------------------------
# _on_combo_timer_updated(time_remaining, max_time) - Update combo timer bar
# ------------------------------------------------------------------------------
func _on_combo_timer_updated(time_remaining: float, max_time: float) -> void:
	if not combo_timer_bar:
		return
	
	var progress = time_remaining / max_time
	combo_timer_bar.value = progress
	
	# Change color based on time remaining (red when low)
	if progress < 0.3:
		combo_timer_bar.modulate = Color(1.0, 0.3, 0.3)  # Red
	elif progress < 0.6:
		combo_timer_bar.modulate = Color(1.0, 0.8, 0.2)  # Yellow
	else:
		combo_timer_bar.modulate = Color(0.4, 1.0, 0.5)  # Green


# ------------------------------------------------------------------------------
# _on_combo_broken() - Called when combo is broken
# ------------------------------------------------------------------------------
func _on_combo_broken() -> void:
	update_combo()
	
	# Flash combo label red
	if combo_label:
		_animate_combo_break()


# ------------------------------------------------------------------------------
# _on_combo_threshold_reached(threshold, multiplier) - Called on milestone
# ------------------------------------------------------------------------------
func _on_combo_threshold_reached(threshold: int, multiplier: float) -> void:
	print("[HUD] Combo threshold reached! ", threshold, "x - Multiplier: ", multiplier)
	# Could show a special visual effect here
	_animate_combo_pulse()


# ------------------------------------------------------------------------------
# _animate_combo_pulse() - Pulse animation for combo label
# ------------------------------------------------------------------------------
func _animate_combo_pulse() -> void:
	if not combo_label:
		return
	
	# Kill existing combo tween
	if combo_tween:
		combo_tween.kill()
	
	# Create pulse animation
	combo_tween = create_tween()
	combo_tween.set_ease(Tween.EASE_OUT)
	combo_tween.set_trans(Tween.TRANS_ELASTIC)
	
	# Scale up then back to normal
	combo_label.scale = Vector2(1.3, 1.3)
	combo_tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.5)


# ------------------------------------------------------------------------------
# _animate_combo_break() - Break animation for combo label
# ------------------------------------------------------------------------------
func _animate_combo_break() -> void:
	if not combo_label:
		return
	
	# Kill existing combo tween
	if combo_tween:
		combo_tween.kill()
	
	# Create shake animation
	combo_tween = create_tween()
	
	var original_color = combo_label.modulate
	combo_label.modulate = Color.RED
	combo_tween.tween_property(combo_label, "modulate", original_color, 0.3)


# ==============================================================================
# TEMPLATE: Adding New HUD Elements
# ==============================================================================
# To add a new HUD element (like a power-up indicator):
#
# 1. Add the UI element to the HUD scene in the editor
#    - Add a TextureRect for an icon
#    - Add a Label for text
#
# 2. Add @onready variable:
#    @onready var powerup_indicator: TextureRect = $PowerupIndicator
#
# 3. Create update function:
#    func update_powerup(active: bool, time_remaining: float) -> void:
#        powerup_indicator.visible = active
#        if active:
#            powerup_label.text = "%.1f" % time_remaining
#
# 4. Call from _process or signal callback:
#    if game_manager.has_powerup:
#        update_powerup(true, game_manager.powerup_time)
# ==============================================================================
