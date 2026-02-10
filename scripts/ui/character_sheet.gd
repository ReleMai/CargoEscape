# ==============================================================================
# CHARACTER SHEET UI
# ==============================================================================
#
# FILE: scripts/ui/character_sheet.gd
# PURPOSE: Combined character stats, equipment, and inventory panel
#
# ACCESS: Press Tab or C key during boarding to open/close
#
# FEATURES:
# - Stats display with allocation
# - Equipment slots display
#
# ==============================================================================

extends Control
class_name CharacterSheet


# ==============================================================================
# SIGNALS
# ==============================================================================

signal closed
signal opened


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("References")
## The player reference (BoardingPlayer)
@export var player: Node


# ==============================================================================
# NODE REFERENCES (found at runtime)
# ==============================================================================

var close_button: Button

# Stats display
var level_label: Label
var exp_progress: ProgressBar
var exp_label: Label
var stat_points_label: Label

# Stat value labels
var health_value: Label
var attack_value: Label
var defense_value: Label
var speed_value: Label
var luck_value: Label
var stealth_value: Label

# Stat allocation buttons
var health_button: Button
var attack_button: Button
var defense_button: Button
var speed_button: Button
var luck_button: Button
var stealth_button: Button

# Equipment slot labels
var weapon_name: Label
var secondary_name: Label
var armor_name: Label
var helmet_name: Label
var accessory1_name: Label
var accessory2_name: Label
var relic_name: Label


# ==============================================================================
# STATE
# ==============================================================================

var player_stats: PlayerStats
var player_equipment: PlayerEquipment
var is_open: bool = false


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _ready() -> void:
	# Start hidden
	visible = false
	
	# Find UI nodes
	_find_ui_nodes()
	
	# Connect buttons
	_connect_buttons()
	
	# Handle input for Tab key
	set_process_unhandled_input(true)


func _find_ui_nodes() -> void:
	# Find close button
	close_button = get_node_or_null("MarginContainer/VBoxContainer/Header/CloseButton")
	
	# Find stats panel nodes
	var left_panel = get_node_or_null("MarginContainer/VBoxContainer/ContentContainer/LeftPanel")
	if left_panel:
		level_label = left_panel.get_node_or_null("LevelPanel/LevelVBox/LevelLabel")
		exp_progress = left_panel.get_node_or_null("LevelPanel/LevelVBox/ExpProgress")
		exp_label = left_panel.get_node_or_null("LevelPanel/LevelVBox/ExpLabel")
		stat_points_label = left_panel.get_node_or_null("StatPointsLabel")
		
		var stats_grid = left_panel.get_node_or_null("StatsGrid")
		if stats_grid:
			health_value = stats_grid.get_node_or_null("HealthValue")
			attack_value = stats_grid.get_node_or_null("AttackValue")
			defense_value = stats_grid.get_node_or_null("DefenseValue")
			speed_value = stats_grid.get_node_or_null("SpeedValue")
			luck_value = stats_grid.get_node_or_null("LuckValue")
			stealth_value = stats_grid.get_node_or_null("StealthValue")
			
			health_button = stats_grid.get_node_or_null("HealthButton")
			attack_button = stats_grid.get_node_or_null("AttackButton")
			defense_button = stats_grid.get_node_or_null("DefenseButton")
			speed_button = stats_grid.get_node_or_null("SpeedButton")
			luck_button = stats_grid.get_node_or_null("LuckButton")
			stealth_button = stats_grid.get_node_or_null("StealthButton")
	
	# Find equipment panel nodes
	var right_panel = get_node_or_null("MarginContainer/VBoxContainer/ContentContainer/RightPanel")
	if right_panel:
		var equip_grid = right_panel.get_node_or_null("EquipmentGrid")
		if equip_grid:
			weapon_name = equip_grid.get_node_or_null("WeaponSlot/WeaponName")
			secondary_name = equip_grid.get_node_or_null("SecondarySlot/SecondaryName")
			armor_name = equip_grid.get_node_or_null("ArmorSlot/ArmorName")
			helmet_name = equip_grid.get_node_or_null("HelmetSlot/HelmetName")
			accessory1_name = equip_grid.get_node_or_null("Accessory1Slot/Accessory1Name")
			accessory2_name = equip_grid.get_node_or_null("Accessory2Slot/Accessory2Name")
			relic_name = equip_grid.get_node_or_null("RelicSlot/RelicName")


func _connect_buttons() -> void:
	if close_button:
		if not close_button.pressed.is_connected(close_sheet):
			close_button.pressed.connect(close_sheet)
	
	# Connect stat allocation buttons
	if health_button:
		health_button.pressed.connect(_on_allocate_health)
	if attack_button:
		attack_button.pressed.connect(_on_allocate_attack)
	if defense_button:
		defense_button.pressed.connect(_on_allocate_defense)
	if speed_button:
		speed_button.pressed.connect(_on_allocate_speed)
	if luck_button:
		luck_button.pressed.connect(_on_allocate_luck)
	if stealth_button:
		stealth_button.pressed.connect(_on_allocate_stealth)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_character_sheet"):
		if is_open:
			close_sheet()
		else:
			open_sheet()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and is_open:
		close_sheet()
		get_viewport().set_input_as_handled()


# ==============================================================================
# PLAYER CONNECTION
# ==============================================================================

## Connect to player
func set_player(p: Node) -> void:
	player = p
	
	if player:
		# Get stats and equipment from player
		if player.has_method("get_stats"):
			player_stats = player.get_stats()
		elif player.get("player_stats"):
			player_stats = player.player_stats
		
		if player.has_method("get_equipment"):
			player_equipment = player.get_equipment()
		elif player.get("player_equipment"):
			player_equipment = player.player_equipment
		
		# Initial refresh
		refresh_all()


# ==============================================================================
# OPEN / CLOSE
# ==============================================================================

func open_sheet() -> void:
	if is_open:
		return
	
	is_open = true
	visible = true
	
	# Refresh all panels
	refresh_all()
	
	# Emit signal
	opened.emit()
	
	# Play sound
	if AudioManager:
		AudioManager.play_sfx("ui_open", -3.0)


func close_sheet() -> void:
	if not is_open:
		return
	
	is_open = false
	visible = false
	
	# Emit signal
	closed.emit()
	
	# Play sound
	if AudioManager:
		AudioManager.play_sfx("ui_close", -3.0)


func toggle() -> void:
	if is_open:
		close_sheet()
	else:
		open_sheet()


# ==============================================================================
# UI REFRESH
# ==============================================================================

func refresh_all() -> void:
	_refresh_stats()
	_refresh_equipment()


func _refresh_stats() -> void:
	if not player_stats:
		return
	
	# Level display
	if level_label:
		level_label.text = "Level: %d" % player_stats.level
	
	# EXP display
	if exp_label:
		var next_level_exp = player_stats.get_exp_for_next_level()
		exp_label.text = "EXP: %d / %d" % [player_stats.current_exp, next_level_exp]
	
	if exp_progress:
		var progress = player_stats.get_level_progress()
		exp_progress.value = progress * 100.0
	
	# Stat points
	if stat_points_label:
		stat_points_label.text = "Stat Points: %d" % player_stats.available_stat_points
		stat_points_label.modulate = Color.YELLOW if player_stats.available_stat_points > 0 else Color.WHITE
	
	# Individual stats
	if health_value:
		health_value.text = str(player_stats.get_health())
	if attack_value:
		attack_value.text = str(player_stats.get_attack())
	if defense_value:
		defense_value.text = str(player_stats.get_defense())
	if speed_value:
		speed_value.text = str(player_stats.get_speed())
	if luck_value:
		luck_value.text = str(player_stats.get_luck())
	if stealth_value:
		stealth_value.text = str(player_stats.get_stealth())
	
	# Enable/disable allocation buttons based on available points
	var has_points = player_stats.available_stat_points > 0
	if health_button:
		health_button.disabled = not has_points
	if attack_button:
		attack_button.disabled = not has_points
	if defense_button:
		defense_button.disabled = not has_points
	if speed_button:
		speed_button.disabled = not has_points
	if luck_button:
		luck_button.disabled = not has_points
	if stealth_button:
		stealth_button.disabled = not has_points


func _refresh_equipment() -> void:
	if not player_equipment:
		# Show empty slots
		_set_slot_text(weapon_name, null)
		_set_slot_text(secondary_name, null)
		_set_slot_text(armor_name, null)
		_set_slot_text(helmet_name, null)
		_set_slot_text(accessory1_name, null)
		_set_slot_text(accessory2_name, null)
		_set_slot_text(relic_name, null)
		return
	
	# Get equipped items
	_set_slot_text(weapon_name, player_equipment.get_equipped(PlayerEquipment.SLOT_PRIMARY_WEAPON))
	_set_slot_text(secondary_name, player_equipment.get_equipped(PlayerEquipment.SLOT_SECONDARY_WEAPON))
	_set_slot_text(armor_name, player_equipment.get_equipped(PlayerEquipment.SLOT_ARMOR))
	_set_slot_text(helmet_name, player_equipment.get_equipped(PlayerEquipment.SLOT_HELMET))
	_set_slot_text(accessory1_name, player_equipment.get_equipped(PlayerEquipment.SLOT_ACCESSORY_1))
	_set_slot_text(accessory2_name, player_equipment.get_equipped(PlayerEquipment.SLOT_ACCESSORY_2))
	_set_slot_text(relic_name, player_equipment.get_equipped(PlayerEquipment.SLOT_RELIC))


func _set_slot_text(label: Label, item: EquipmentData) -> void:
	if not label:
		return
	
	if item:
		label.text = item.name
		label.modulate = item.get_rarity_color() if item.has_method("get_rarity_color") else Color.WHITE
	else:
		label.text = "(Empty)"
		label.modulate = Color(0.5, 0.5, 0.5)


# ==============================================================================
# STAT ALLOCATION
# ==============================================================================

func _on_allocate_health() -> void:
	_allocate_stat("health")


func _on_allocate_attack() -> void:
	_allocate_stat("attack")


func _on_allocate_defense() -> void:
	_allocate_stat("defense")


func _on_allocate_speed() -> void:
	_allocate_stat("speed")


func _on_allocate_luck() -> void:
	_allocate_stat("luck")


func _on_allocate_stealth() -> void:
	_allocate_stat("stealth")


func _allocate_stat(stat_name: String) -> void:
	if not player_stats:
		return
	
	if player_stats.allocate_point(stat_name):
		_refresh_stats()
		if AudioManager:
			AudioManager.play_sfx("ui_click", -3.0)


# ==============================================================================
# UTILITY
# ==============================================================================

## Check if character sheet is currently open
func is_sheet_open() -> bool:
	return is_open
