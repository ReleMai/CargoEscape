# ==============================================================================
# ESCAPE TRACKER UI - KILL REQUIREMENT HUD
# ==============================================================================
#
# FILE: scripts/ui/escape_tracker.gd
# PURPOSE: HUD element showing kills required to unlock escape
#
# FEATURES:
# - Clean minimal design
# - Progress bar with kill count
# - Visual feedback on kills
# - Animation when gate unlocks
#
# ==============================================================================

extends Control
class_name EscapeTracker


# ==============================================================================
# SIGNALS
# ==============================================================================

signal tracker_clicked


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Display")
## Position offset from top-center of screen
@export var vertical_offset: float = 60.0
## Width of the tracker panel
@export var panel_width: float = 200.0


# ==============================================================================
# STATE
# ==============================================================================

var current_kills: int = 0
var required_kills: int = 0
var is_unlocked: bool = false


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

var background_panel: PanelContainer = null
var progress_bar: ProgressBar = null
var label_kills: Label = null
var label_status: Label = null
var icon: Label = null  # Using emoji for icon


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_build_ui()
	_update_display()


func _build_ui() -> void:
	# Container anchored to top-center
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -panel_width / 2
	offset_right = panel_width / 2
	offset_top = vertical_offset
	offset_bottom = vertical_offset + 50
	
	# Background panel
	background_panel = PanelContainer.new()
	background_panel.anchor_right = 1.0
	background_panel.anchor_bottom = 1.0
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12, 0.9)
	style.border_width_bottom = 2
	style.border_color = Color(0.8, 0.2, 0.2)  # Red border when locked
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	background_panel.add_theme_stylebox_override("panel", style)
	add_child(background_panel)
	
	# VBox for content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	background_panel.add_child(vbox)
	
	# Header row
	var header = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	vbox.add_child(header)
	
	# Lock icon
	icon = Label.new()
	icon.text = "🔒"
	icon.add_theme_font_size_override("font_size", 16)
	header.add_child(icon)
	
	# Status label
	label_status = Label.new()
	label_status.text = "ESCAPE LOCKED"
	label_status.add_theme_font_size_override("font_size", 12)
	label_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	label_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label_status)
	
	# Kill counter
	label_kills = Label.new()
	label_kills.text = "0/0"
	label_kills.add_theme_font_size_override("font_size", 14)
	label_kills.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	header.add_child(label_kills)
	
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size.y = 6
	progress_bar.show_percentage = false
	progress_bar.value = 0
	progress_bar.max_value = 100
	
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.17, 0.2)
	bar_bg.corner_radius_top_left = 3
	bar_bg.corner_radius_top_right = 3
	bar_bg.corner_radius_bottom_left = 3
	bar_bg.corner_radius_bottom_right = 3
	progress_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.9, 0.3, 0.3)  # Red initially
	bar_fill.corner_radius_top_left = 3
	bar_fill.corner_radius_top_right = 3
	bar_fill.corner_radius_bottom_left = 3
	bar_fill.corner_radius_bottom_right = 3
	progress_bar.add_theme_stylebox_override("fill", bar_fill)
	
	vbox.add_child(progress_bar)


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Update the tracker with current progress
func update_progress(current: int, required: int) -> void:
	var old_kills = current_kills
	current_kills = current
	required_kills = required
	
	# Animate if kill count increased
	if current > old_kills and not is_unlocked:
		_play_kill_animation()
	
	_update_display()


## Mark the gate as unlocked
func set_unlocked() -> void:
	if is_unlocked:
		return
	
	is_unlocked = true
	current_kills = required_kills
	_play_unlock_animation()
	_update_display()


## Connect to an EscapeGate for automatic updates
func connect_to_gate(gate: EscapeGate) -> void:
	gate.progress_updated.connect(update_progress)
	gate.gate_unlocked.connect(set_unlocked)
	
	# Initialize with current state
	var progress = gate.get_progress()
	update_progress(progress.current, progress.required)
	if progress.unlocked:
		is_unlocked = true
		_update_display()


# ==============================================================================
# DISPLAY
# ==============================================================================

func _update_display() -> void:
	# Update kill counter
	label_kills.text = "%d/%d" % [current_kills, required_kills]
	
	# Update progress bar
	if required_kills > 0:
		progress_bar.value = (float(current_kills) / float(required_kills)) * 100.0
	
	if is_unlocked:
		# Unlocked state
		icon.text = "✅"
		label_status.text = "ESCAPE READY"
		label_status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		
		# Update panel border to green
		var style = background_panel.get_theme_stylebox("panel").duplicate()
		style.border_color = Color(0.3, 0.8, 0.4)
		background_panel.add_theme_stylebox_override("panel", style)
		
		# Update progress bar to green
		var fill = progress_bar.get_theme_stylebox("fill").duplicate()
		fill.bg_color = Color(0.3, 0.8, 0.4)
		progress_bar.add_theme_stylebox_override("fill", fill)
	else:
		# Locked state
		icon.text = "🔒"
		label_status.text = "ESCAPE LOCKED"
		label_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))


# ==============================================================================
# ANIMATIONS
# ==============================================================================

func _play_kill_animation() -> void:
	# Pulse the panel
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Flash the kill counter
	var original_color = label_kills.get_theme_color("font_color")
	label_kills.add_theme_color_override("font_color", Color(1.0, 1.0, 0.3))
	await get_tree().create_timer(0.2).timeout
	label_kills.add_theme_color_override("font_color", original_color)


func _play_unlock_animation() -> void:
	# Big celebration animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Scale up and back
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
	
	# Flash white
	tween.tween_property(self, "modulate", Color(2.0, 2.0, 2.0), 0.1)
	tween.chain().tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.3)
	
	# Bounce effect
	var orig_pos = position.y
	tween.chain().tween_property(self, "position:y", orig_pos - 10, 0.1)
	tween.chain().tween_property(self, "position:y", orig_pos, 0.2)
