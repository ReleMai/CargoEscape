# ==============================================================================
# EQUIPMENT PANEL UI
# ==============================================================================
#
# FILE: scripts/ui/equipment_panel.gd
# PURPOSE: Displays player equipment slots and allows equipping/unequipping
#
# UI LAYOUT:
# - Left side: Equipment slots (weapon, armor, helmet, accessories, relic)
# - Right side: Selected item info
# - Bottom: Ammo display
#
# ==============================================================================

extends Control
class_name EquipmentPanel


# ==============================================================================
# SIGNALS
# ==============================================================================

signal slot_clicked(slot_name: String)
signal item_unequipped(slot_name: String, item: EquipmentData)


# ==============================================================================
# REFERENCES
# ==============================================================================

@export var player_equipment: PlayerEquipment
@export var player_stats: PlayerStats

## Slot UI nodes (set in editor)
@export_group("Slot Nodes")
@export var primary_weapon_slot: Control
@export var secondary_weapon_slot: Control
@export var armor_slot: Control
@export var helmet_slot: Control
@export var accessory1_slot: Control
@export var accessory2_slot: Control
@export var relic_slot: Control

## Info panel nodes
@export_group("Info Panel")
@export var item_name_label: Label
@export var item_description_label: RichTextLabel
@export var item_stats_label: RichTextLabel
@export var item_icon: TextureRect

## Ammo display nodes
@export_group("Ammo Display")
@export var ammo_container: Control
@export var ammo_labels: Dictionary = {}  # AmmoType -> Label


# ==============================================================================
# SLOT MAPPING
# ==============================================================================

var slot_nodes: Dictionary = {}


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _ready() -> void:
	# Build slot node mapping
	slot_nodes = {
		PlayerEquipment.SLOT_PRIMARY_WEAPON: primary_weapon_slot,
		PlayerEquipment.SLOT_SECONDARY_WEAPON: secondary_weapon_slot,
		PlayerEquipment.SLOT_ARMOR: armor_slot,
		PlayerEquipment.SLOT_HELMET: helmet_slot,
		PlayerEquipment.SLOT_ACCESSORY_1: accessory1_slot,
		PlayerEquipment.SLOT_ACCESSORY_2: accessory2_slot,
		PlayerEquipment.SLOT_RELIC: relic_slot
	}
	
	# Connect slot signals
	for slot_name in slot_nodes:
		var node = slot_nodes[slot_name]
		if node and node.has_signal("gui_input"):
			node.gui_input.connect(_on_slot_input.bind(slot_name))
	
	# Connect to equipment changes
	if player_equipment:
		player_equipment.equipment_changed.connect(_on_equipment_changed)
		player_equipment.ammo_changed.connect(_on_ammo_changed)
	
	# Initial refresh
	refresh_all_slots()
	refresh_ammo_display()
	clear_info_panel()


## Set equipment reference
func set_equipment(equipment: PlayerEquipment) -> void:
	if player_equipment:
		player_equipment.equipment_changed.disconnect(_on_equipment_changed)
		player_equipment.ammo_changed.disconnect(_on_ammo_changed)
	
	player_equipment = equipment
	
	if player_equipment:
		player_equipment.equipment_changed.connect(_on_equipment_changed)
		player_equipment.ammo_changed.connect(_on_ammo_changed)
	
	refresh_all_slots()
	refresh_ammo_display()


# ==============================================================================
# SLOT DISPLAY
# ==============================================================================

## Refresh all equipment slots
func refresh_all_slots() -> void:
	for slot_name in slot_nodes:
		refresh_slot(slot_name)


## Refresh a single slot display
func refresh_slot(slot_name: String) -> void:
	var node = slot_nodes.get(slot_name)
	if not node:
		return
	
	var item = player_equipment.get_equipped(slot_name) if player_equipment else null
	
	# Find icon child
	var icon_node = node.get_node_or_null("Icon")
	if icon_node and icon_node is TextureRect:
		if item and item.icon:
			icon_node.texture = item.icon
			icon_node.visible = true
		else:
			icon_node.visible = false
	
	# Find rarity border
	var border_node = node.get_node_or_null("RarityBorder")
	if border_node:
		if item:
			border_node.modulate = _get_rarity_color(item.rarity)
			border_node.visible = true
		else:
			border_node.visible = false
	
	# Update slot background
	var empty_indicator = node.get_node_or_null("EmptyIndicator")
	if empty_indicator:
		empty_indicator.visible = (item == null)


## Get color for rarity
func _get_rarity_color(rarity: int) -> Color:
	match rarity:
		0: return Color(0.7, 0.7, 0.7)      # Gray - Common
		1: return Color(0.3, 0.8, 0.3)      # Green - Uncommon
		2: return Color(0.3, 0.5, 1.0)      # Blue - Rare
		3: return Color(0.7, 0.3, 0.9)      # Purple - Epic
		4: return Color(1.0, 0.8, 0.2)      # Gold - Legendary
		_: return Color.WHITE


# ==============================================================================
# INFO PANEL
# ==============================================================================

## Display item info in the panel
func show_item_info(item: EquipmentData) -> void:
	if not item:
		clear_info_panel()
		return
	
	if item_name_label:
		item_name_label.text = item.name
		item_name_label.modulate = _get_rarity_color(item.rarity)
	
	if item_description_label:
		item_description_label.text = item.description
	
	if item_stats_label:
		item_stats_label.text = _build_stats_text(item)
	
	if item_icon:
		item_icon.texture = item.icon if item.icon else null


## Clear the info panel
func clear_info_panel() -> void:
	if item_name_label:
		item_name_label.text = "No Item Selected"
		item_name_label.modulate = Color.WHITE
	
	if item_description_label:
		item_description_label.text = ""
	
	if item_stats_label:
		item_stats_label.text = ""
	
	if item_icon:
		item_icon.texture = null


## Build stats text for item
func _build_stats_text(item: EquipmentData) -> String:
	var lines = []
	
	# Type and rarity
	lines.append("[b]%s[/b] - [color=%s]%s[/color]" % [
		item.get_type_name(),
		_get_rarity_color(item.rarity).to_html(),
		item.get_rarity_name()
	])
	lines.append("")
	
	# Weapon stats
	if item.is_weapon():
		lines.append("[color=red]Damage: %d[/color]" % item.base_damage)
		if item.equipment_type == EquipmentData.EquipmentType.WEAPON_RANGED:
			lines.append("Fire Rate: %.1f/s" % item.fire_rate)
			lines.append("Range: %d" % int(item.range_pixels))
			lines.append("Accuracy: %d%%" % int(item.accuracy * 100))
			if item.magazine_size > 0:
				lines.append("Magazine: %d" % item.magazine_size)
		else:
			lines.append("Attack Speed: %.1fx" % item.attack_speed)
		lines.append("Crit: %.0f%% (+%.1fx)" % [item.crit_chance * 100, item.crit_multiplier])
	
	# Armor stats
	if item.is_armor():
		if item.armor_value > 0:
			lines.append("[color=cyan]Armor: +%d[/color]" % item.armor_value)
		if item.damage_reduction > 0:
			lines.append("[color=cyan]Damage Reduction: %.0f%%[/color]" % (item.damage_reduction * 100))
	
	# Stat bonuses
	lines.append("")
	var bonuses = item.get_stat_bonuses()
	for stat in bonuses:
		var value = bonuses[stat]
		if value != 0:
			var color = "green" if value > 0 else "red"
			var sign = "+" if value > 0 else ""
			lines.append("[color=%s]%s%d %s[/color]" % [color, sign, value, stat.capitalize()])
	
	# Special ability
	if not item.special_ability_id.is_empty():
		lines.append("")
		lines.append("[color=yellow]Special: %s[/color]" % item.ability_description)
	
	# Value
	lines.append("")
	lines.append("Value: %d credits" % item.base_value)
	
	return "\n".join(lines)


# ==============================================================================
# AMMO DISPLAY
# ==============================================================================

## Refresh ammo display
func refresh_ammo_display() -> void:
	if not player_equipment or not ammo_container:
		return
	
	for ammo_type in ammo_labels:
		var label = ammo_labels[ammo_type]
		if label:
			var count = player_equipment.get_ammo_count(ammo_type)
			label.text = str(count)


# ==============================================================================
# INPUT HANDLING
# ==============================================================================

## Handle input on a slot
func _on_slot_input(event: InputEvent, slot_name: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_select_slot(slot_name)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_unequip_slot(slot_name)


## Select a slot (show info)
func _select_slot(slot_name: String) -> void:
	slot_clicked.emit(slot_name)
	
	if player_equipment:
		var item = player_equipment.get_equipped(slot_name)
		show_item_info(item)


## Unequip item from slot
func _unequip_slot(slot_name: String) -> void:
	if not player_equipment:
		return
	
	var item = player_equipment.unequip(slot_name)
	if item:
		item_unequipped.emit(slot_name, item)
		clear_info_panel()


# ==============================================================================
# SIGNAL HANDLERS
# ==============================================================================

## Handle equipment change
func _on_equipment_changed(slot: String, _old_item: EquipmentData, _new_item: EquipmentData) -> void:
	refresh_slot(slot)


## Handle ammo change
func _on_ammo_changed(ammo_type: int, _amount: int) -> void:
	if ammo_labels.has(ammo_type):
		var label = ammo_labels[ammo_type]
		if label and player_equipment:
			label.text = str(player_equipment.get_ammo_count(ammo_type))
