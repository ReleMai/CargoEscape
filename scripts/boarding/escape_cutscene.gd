# ==============================================================================
# ESCAPE CUTSCENE - DRAMATIC EXIT SEQUENCE
# ==============================================================================
#
# FILE: scripts/boarding/escape_cutscene.gd
# PURPOSE: Cinematic escape sequence when successfully escaping a ship
#
# SEQUENCE:
# 1. Rush to Exit (0.5s) - UI flash: 'ESCAPING!'
# 2. Undocking (1.5s) - Airlock slams shut, clamps release, ships separate
# 3. Getaway (2s) - Player ship accelerates away, enemy ship in background
# 4. Loot Summary (transition) - Show collected items and total value
#
# VARIATIONS:
# - Clean escape (plenty of time)
# - Close call (< 10 seconds left) - alarms, red lighting
# - Perfect run (all containers searched) - special fanfare
#
# ==============================================================================

extends CanvasLayer
class_name EscapeCutscene


# ==============================================================================
# SIGNALS
# ==============================================================================

signal cutscene_started
signal cutscene_completed
signal phase_changed(phase_name: String)


# ==============================================================================
# ENUMS
# ==============================================================================

enum CutscenePhase {
	RUSH_TO_EXIT,
	UNDOCKING,
	GETAWAY,
	LOOT_SUMMARY
}

enum EscapeVariation {
	CLEAN,        # Plenty of time
	CLOSE_CALL,   # < 10 seconds left
	PERFECT_RUN   # All containers searched
}


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Timing")
@export var rush_duration: float = 0.3
@export var undocking_duration: float = 0.5
@export var getaway_duration: float = 0.5
@export var loot_summary_fade_duration: float = 0.3

@export_group("Variations")
@export var close_call_threshold: float = 10.0  # seconds


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

# Main containers
@onready var rush_container: Control = %RushContainer
@onready var undocking_container: Control = %UndockingContainer
@onready var getaway_container: Control = %GetawayContainer
@onready var loot_summary_container: Control = %LootSummaryContainer

# Rush to Exit elements
@onready var escaping_flash: ColorRect = %EscapingFlash
@onready var escaping_label: Label = %EscapingLabel

# Undocking elements
@onready var airlock_panel: Panel = %AirlockPanel
@onready var airlock_door: ColorRect = %AirlockDoor
@onready var clamp_left: ColorRect = %ClampLeft
@onready var clamp_right: ColorRect = %ClampRight
@onready var undocking_status: Label = %UndockingStatus

# Getaway elements
@onready var space_background: ColorRect = %SpaceBackground
@onready var player_ship: ColorRect = %PlayerShip
@onready var enemy_ship: ColorRect = %EnemyShip
@onready var explosion_particles: GPUParticles2D = %ExplosionParticles

# Loot Summary elements
@onready var loot_summary_panel: Panel = %LootSummaryPanel
@onready var loot_title: Label = %LootTitle
@onready var loot_items_list: VBoxContainer = %LootItemsList
@onready var total_value_label: Label = %TotalValueLabel
@onready var bonus_label: Label = %BonusLabel


# ==============================================================================
# STATE
# ==============================================================================

var current_phase: CutscenePhase = CutscenePhase.RUSH_TO_EXIT
var escape_variation: EscapeVariation = EscapeVariation.CLEAN
var phase_timer: float = 0.0
var is_active: bool = false

# Escape data
var time_remaining: float = 0.0
var total_loot_value: int = 0
var collected_items: Array[ItemData] = []
var containers_searched: int = 0
var total_containers: int = 0
var ship_explodes: bool = false


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	visible = false
	layer = 100  # On top of everything
	
	# Hide all containers initially
	_hide_all_containers()


func _process(delta: float) -> void:
	if not is_active:
		return
	
	phase_timer += delta
	
	match current_phase:
		CutscenePhase.RUSH_TO_EXIT:
			_update_rush_phase(delta)
		CutscenePhase.UNDOCKING:
			_update_undocking_phase(delta)
		CutscenePhase.GETAWAY:
			_update_getaway_phase(delta)
		CutscenePhase.LOOT_SUMMARY:
			_update_loot_summary_phase(delta)


# ==============================================================================
# PUBLIC INTERFACE
# ==============================================================================

## Start the escape cutscene with the given data
func start_cutscene(data: Dictionary) -> void:
	# Extract data
	time_remaining = data.get("time_remaining", 0.0)
	total_loot_value = data.get("total_loot_value", 0)
	collected_items = data.get("collected_items", [])
	containers_searched = data.get("containers_searched", 0)
	total_containers = data.get("total_containers", 0)
	
	# Determine variation
	_determine_variation()
	
	# Start the sequence
	is_active = true
	visible = true
	current_phase = CutscenePhase.RUSH_TO_EXIT
	phase_timer = 0.0
	
	_start_rush_phase()
	emit_signal("cutscene_started")


## Skip to the loot summary
func skip_to_summary() -> void:
	if not is_active:
		return
	
	_transition_to_loot_summary()


# ==============================================================================
# VARIATION DETERMINATION
# ==============================================================================

func _determine_variation() -> void:
	# Perfect run takes priority
	if total_containers > 0 and containers_searched >= total_containers:
		escape_variation = EscapeVariation.PERFECT_RUN
		return
	
	# Close call
	if time_remaining < close_call_threshold:
		escape_variation = EscapeVariation.CLOSE_CALL
		ship_explodes = time_remaining <= 0.0
		return
	
	# Clean escape (default)
	escape_variation = EscapeVariation.CLEAN


# ==============================================================================
# PHASE 1: RUSH TO EXIT
# ==============================================================================

func _start_rush_phase() -> void:
	_hide_all_containers()
	rush_container.visible = true
	emit_signal("phase_changed", "RUSH_TO_EXIT")
	
	# Flash effect
	if escaping_flash:
		escaping_flash.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(escaping_flash, "modulate:a", 0.7, 0.1)
		tween.tween_property(escaping_flash, "modulate:a", 0.0, 0.4)
	
	# Label animation
	if escaping_label:
		escaping_label.scale = Vector2(0.8, 0.8)
		escaping_label.modulate.a = 0.0
		
		var label_tween = create_tween()
		label_tween.set_parallel(true)
		label_tween.tween_property(escaping_label, "scale", Vector2(1.2, 1.2), rush_duration * 0.7)
		label_tween.tween_property(escaping_label, "modulate:a", 1.0, rush_duration * 0.3)
		label_tween.chain().tween_property(escaping_label, "modulate:a", 0.0, rush_duration * 0.3)


func _update_rush_phase(_delta: float) -> void:
	if phase_timer >= rush_duration:
		_transition_to_undocking()


# ==============================================================================
# PHASE 2: UNDOCKING
# ==============================================================================

func _transition_to_undocking() -> void:
	current_phase = CutscenePhase.UNDOCKING
	phase_timer = 0.0
	_start_undocking_phase()


func _start_undocking_phase() -> void:
	_hide_all_containers()
	undocking_container.visible = true
	emit_signal("phase_changed", "UNDOCKING")
	
	# Airlock slam animation
	if airlock_door:
		var door_tween = create_tween()
		door_tween.tween_property(airlock_door, "position:y", airlock_door.position.y + 100, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		door_tween.tween_callback(_play_slam_sound)
	
	# Clamps release
	await get_tree().create_timer(0.5).timeout
	if clamp_left and clamp_right:
		var clamp_tween = create_tween()
		clamp_tween.set_parallel(true)
		clamp_tween.tween_property(clamp_left, "position:x", clamp_left.position.x - 50, 0.5).set_ease(Tween.EASE_IN)
		clamp_tween.tween_property(clamp_right, "position:x", clamp_right.position.x + 50, 0.5).set_ease(Tween.EASE_IN)
	
	# Status updates
	_animate_undocking_status()


func _update_undocking_phase(_delta: float) -> void:
	if phase_timer >= undocking_duration:
		_transition_to_getaway()


func _animate_undocking_status() -> void:
	if not undocking_status:
		return
	
	var messages = [
		"AIRLOCK SEALED",
		"CLAMPS RELEASING...",
		"UNDOCKING COMPLETE"
	]
	
	var delay = 0.0
	for msg in messages:
		await get_tree().create_timer(delay).timeout
		undocking_status.text = msg
		_flash_status_text(undocking_status)
		delay = 0.5


func _flash_status_text(label: Label) -> void:
	if not label:
		return
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.1)
	tween.tween_property(label, "modulate:a", 0.7, 0.2)


# ==============================================================================
# PHASE 3: GETAWAY
# ==============================================================================

func _transition_to_getaway() -> void:
	current_phase = CutscenePhase.GETAWAY
	phase_timer = 0.0
	_start_getaway_phase()


func _start_getaway_phase() -> void:
	_hide_all_containers()
	getaway_container.visible = true
	emit_signal("phase_changed", "GETAWAY")
	
	# Apply variation effects
	match escape_variation:
		EscapeVariation.CLOSE_CALL:
			_apply_close_call_effects()
		EscapeVariation.PERFECT_RUN:
			_apply_perfect_run_effects()
	
	# Player ship accelerates away
	if player_ship:
		var ship_tween = create_tween()
		ship_tween.set_parallel(true)
		ship_tween.tween_property(player_ship, "position:x", player_ship.position.x + 300, getaway_duration).set_ease(Tween.EASE_IN)
		ship_tween.tween_property(player_ship, "scale", Vector2(0.5, 0.5), getaway_duration)
	
	# Enemy ship stays in background
	if enemy_ship and ship_explodes:
		await get_tree().create_timer(getaway_duration * 0.6).timeout
		_trigger_explosion()


func _update_getaway_phase(_delta: float) -> void:
	if phase_timer >= getaway_duration:
		_transition_to_loot_summary()


func _apply_close_call_effects() -> void:
	# Red lighting/alarm effect
	if space_background:
		space_background.color = Color(0.2, 0.05, 0.05)
	
	# Pulsing red flash
	var flash_tween = create_tween()
	flash_tween.set_loops()
	flash_tween.tween_property(space_background, "color:r", 0.3, 0.3)
	flash_tween.tween_property(space_background, "color:r", 0.2, 0.3)


func _apply_perfect_run_effects() -> void:
	# Golden glow/fanfare
	if space_background:
		space_background.color = Color(0.1, 0.1, 0.15)
	
	# TODO: Add particle effects or special animation for perfect run


func _trigger_explosion() -> void:
	if explosion_particles:
		explosion_particles.emitting = true
	
	# Flash effect
	if space_background:
		var flash = create_tween()
		flash.tween_property(space_background, "color", Color.WHITE, 0.1)
		flash.tween_property(space_background, "color", Color(0.02, 0.02, 0.05), 0.5)


# ==============================================================================
# PHASE 4: LOOT SUMMARY
# ==============================================================================

func _transition_to_loot_summary() -> void:
	current_phase = CutscenePhase.LOOT_SUMMARY
	phase_timer = 0.0
	_start_loot_summary_phase()


func _start_loot_summary_phase() -> void:
	_hide_all_containers()
	loot_summary_container.visible = true
	emit_signal("phase_changed", "LOOT_SUMMARY")
	
	# Fade in
	loot_summary_panel.modulate.a = 0.0
	var fade_tween = create_tween()
	fade_tween.tween_property(loot_summary_panel, "modulate:a", 1.0, loot_summary_fade_duration)
	
	# Populate loot summary
	_populate_loot_summary()
	
	# Wait a moment, then complete cutscene
	await get_tree().create_timer(3.0).timeout
	_complete_cutscene()


func _populate_loot_summary() -> void:
	# Set title based on variation
	if loot_title:
		match escape_variation:
			EscapeVariation.PERFECT_RUN:
				loot_title.text = "PERFECT RUN!"
				loot_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
			EscapeVariation.CLOSE_CALL:
				loot_title.text = "CLOSE CALL!"
				loot_title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
			_:
				loot_title.text = "ESCAPE SUCCESSFUL"
				loot_title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	
	# Clear existing items
	if loot_items_list:
		for child in loot_items_list.get_children():
			child.queue_free()
	
	# Add collected items (show top items or summary)
	if loot_items_list and collected_items.size() > 0:
		var items_to_show = min(5, collected_items.size())
		for i in items_to_show:
			var item = collected_items[i]
			var item_label = Label.new()
			item_label.text = "• %s ($%d)" % [item.name, item.value]
			loot_items_list.add_child(item_label)
		
		if collected_items.size() > items_to_show:
			var more_label = Label.new()
			more_label.text = "... and %d more items" % (collected_items.size() - items_to_show)
			more_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			loot_items_list.add_child(more_label)
	
	# Total value
	if total_value_label:
		total_value_label.text = "TOTAL VALUE: $%d" % total_loot_value
	
	# Bonus message
	if bonus_label:
		match escape_variation:
			EscapeVariation.PERFECT_RUN:
				bonus_label.text = "All containers searched! +25% bonus"
				bonus_label.visible = true
			EscapeVariation.CLOSE_CALL:
				if time_remaining > 0:
					bonus_label.text = "Close call! (%d seconds left)" % int(time_remaining)
				else:
					bonus_label.text = "Ship exploded but you escaped!"
				bonus_label.visible = true
			_:
				bonus_label.visible = false


func _update_loot_summary_phase(_delta: float) -> void:
	# User can press key to continue to next scene
	pass


# ==============================================================================
# COMPLETION
# ==============================================================================

func _complete_cutscene() -> void:
	is_active = false
	emit_signal("cutscene_completed")
	
	# Transition to undocking scene
	await _fade_to_undocking()


func _fade_to_undocking() -> void:
	# Create fade overlay
	var fade = ColorRect.new()
	# Match undocking scene's dark space background for seamless transition
	fade.color = Color(0.008, 0.012, 0.025, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	
	var tween = create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.5).set_ease(Tween.EASE_IN)
	
	await tween.finished
	
	# Change scene
	get_tree().change_scene_to_file("res://scenes/undocking/undocking_scene.tscn")


# ==============================================================================
# UTILITY
# ==============================================================================

func _hide_all_containers() -> void:
	if rush_container:
		rush_container.visible = false
	if undocking_container:
		undocking_container.visible = false
	if getaway_container:
		getaway_container.visible = false
	if loot_summary_container:
		loot_summary_container.visible = false


func _play_slam_sound() -> void:
	AudioManager.play_sfx("airlock_close", 2.0)
