# ==============================================================================
# STATS PANEL UI
# ==============================================================================
#
# FILE: scripts/ui/stats_panel.gd
# PURPOSE: Displays player statistics and allows stat point allocation
#
# DISPLAYS:
# - Level and EXP progress
# - All player stats (base + bonus)
# - Available stat points
# - Stat allocation buttons
#
# ==============================================================================

extends Control
class_name StatsPanel


# ==============================================================================
# SIGNALS
# ==============================================================================

signal stat_allocated(stat_name: String)


# ==============================================================================
# REFERENCES
# ==============================================================================

@export var player_stats: PlayerStats

## Level display
@export_group("Level Display")
@export var level_label: Label
@export var exp_label: Label
@export var exp_progress_bar: ProgressBar
@export var stat_points_label: Label

## Stat labels (stat_name -> Label)
@export_group("Stat Labels")
@export var health_label: Label
@export var attack_label: Label
@export var defense_label: Label
@export var speed_label: Label
@export var luck_label: Label
@export var stealth_label: Label

## Stat allocation buttons
@export_group("Allocation Buttons")
@export var health_button: Button
@export var attack_button: Button
@export var defense_button: Button
@export var speed_button: Button
@export var luck_button: Button
@export var stealth_button: Button

## Reset button
@export var reset_button: Button


# ==============================================================================
# STATE
# ==============================================================================

var stat_labels: Dictionary = {}
var stat_buttons: Dictionary = {}


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _ready() -> void:
	# Build mappings
	stat_labels = {
		"health": health_label,
		"attack": attack_label,
		"defense": defense_label,
		"speed": speed_label,
		"luck": luck_label,
		"stealth": stealth_label
	}
	
	stat_buttons = {
		"health": health_button,
		"attack": attack_button,
		"defense": defense_button,
		"speed": speed_button,
		"luck": luck_button,
		"stealth": stealth_button
	}
	
	# Connect buttons
	for stat in stat_buttons:
		var button = stat_buttons[stat]
		if button:
			button.pressed.connect(_on_allocate_pressed.bind(stat))
	
	if reset_button:
		reset_button.pressed.connect(_on_reset_pressed)
	
	# Connect to player stats
	if player_stats:
		_connect_stats()
	
	refresh_display()


## Set player stats reference
func set_player_stats(stats: PlayerStats) -> void:
	if player_stats:
		_disconnect_stats()
	
	player_stats = stats
	
	if player_stats:
		_connect_stats()
	
	refresh_display()


## Connect stat signals
func _connect_stats() -> void:
	if player_stats:
		player_stats.stat_changed.connect(_on_stat_changed)
		player_stats.level_up.connect(_on_level_up)
		player_stats.exp_gained.connect(_on_exp_gained)


## Disconnect stat signals
func _disconnect_stats() -> void:
	if player_stats:
		if player_stats.stat_changed.is_connected(_on_stat_changed):
			player_stats.stat_changed.disconnect(_on_stat_changed)
		if player_stats.level_up.is_connected(_on_level_up):
			player_stats.level_up.disconnect(_on_level_up)
		if player_stats.exp_gained.is_connected(_on_exp_gained):
			player_stats.exp_gained.disconnect(_on_exp_gained)


# ==============================================================================
# DISPLAY
# ==============================================================================

## Refresh all display elements
func refresh_display() -> void:
	refresh_level_display()
	refresh_stats_display()
	refresh_buttons()


## Refresh level and EXP display
func refresh_level_display() -> void:
	if not player_stats:
		return
	
	if level_label:
		level_label.text = "Level %d" % player_stats.level
	
	if exp_label:
		var current = player_stats.current_exp
		var needed = player_stats.get_exp_for_next_level()
		if player_stats.level >= PlayerStats.MAX_LEVEL:
			exp_label.text = "MAX LEVEL"
		else:
			exp_label.text = "%d / %d EXP" % [current, needed]
	
	if exp_progress_bar:
		exp_progress_bar.value = player_stats.get_exp_progress()
	
	if stat_points_label:
		var points = player_stats.available_stat_points
		if points > 0:
			stat_points_label.text = "%d Points Available" % points
			stat_points_label.modulate = Color.YELLOW
		else:
			stat_points_label.text = "No Points Available"
			stat_points_label.modulate = Color.GRAY


## Refresh all stat displays
func refresh_stats_display() -> void:
	if not player_stats:
		return
	
	for stat in stat_labels:
		_update_stat_label(stat)


## Update a single stat label
func _update_stat_label(stat_name: String) -> void:
	var label = stat_labels.get(stat_name)
	if not label or not player_stats:
		return
	
	var base = player_stats.get_base_stat(stat_name)
	var allocated = player_stats.get_allocated_stat(stat_name)
	var total = player_stats.get_stat(stat_name)
	
	# Format: "Health: 100 (Base: 80 + 20)"
	var display_name = stat_name.capitalize()
	
	if allocated > 0:
		label.text = "%s: %d [color=green](+%d)[/color]" % [display_name, total, allocated]
	else:
		label.text = "%s: %d" % [display_name, total]


## Refresh button states
func refresh_buttons() -> void:
	var has_points = player_stats and player_stats.available_stat_points > 0
	
	for stat in stat_buttons:
		var button = stat_buttons[stat]
		if button:
			button.disabled = not has_points
			button.visible = true
	
	if reset_button:
		# Only show reset if player has allocated points
		var has_allocated = false
		if player_stats:
			for stat in PlayerStats.STAT_NAMES:
				if player_stats.get_allocated_stat(stat) > 0:
					has_allocated = true
					break
		reset_button.disabled = not has_allocated


# ==============================================================================
# INPUT HANDLERS
# ==============================================================================

## Handle allocate button press
func _on_allocate_pressed(stat_name: String) -> void:
	if not player_stats:
		return
	
	if player_stats.allocate_point(stat_name):
		stat_allocated.emit(stat_name)
		refresh_display()


## Handle reset button press
func _on_reset_pressed() -> void:
	if not player_stats:
		return
	
	player_stats.reset_allocated_points()
	refresh_display()


# ==============================================================================
# SIGNAL HANDLERS
# ==============================================================================

## Handle stat change
func _on_stat_changed(stat_name: String, _old: int, _new: int) -> void:
	_update_stat_label(stat_name)
	refresh_buttons()


## Handle level up
func _on_level_up(_new_level: int) -> void:
	refresh_level_display()
	refresh_buttons()


## Handle EXP gain
func _on_exp_gained(_amount: int, _total: int) -> void:
	refresh_level_display()
