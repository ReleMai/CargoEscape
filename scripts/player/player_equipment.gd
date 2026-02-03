# ==============================================================================
# PLAYER EQUIPMENT MANAGER
# ==============================================================================
#
# FILE: scripts/player/player_equipment.gd
# PURPOSE: Manages player's equipped items and their effects
#
# EQUIPMENT SLOTS:
# - Primary Weapon (ranged or melee)
# - Secondary Weapon (ranged or melee)
# - Armor (body protection)
# - Helmet (head protection)
# - Accessory 1 (ring, necklace, etc.)
# - Accessory 2 (second accessory slot)
# - Relic (passive special item)
#
# ==============================================================================

extends Node
class_name PlayerEquipment


# ==============================================================================
# SIGNALS
# ==============================================================================

signal equipment_changed(slot: String, old_item: EquipmentData, new_item: EquipmentData)
signal weapon_switched(is_primary: bool, weapon: EquipmentData)
signal ammo_changed(ammo_type: int, amount: int)


# ==============================================================================
# SLOT NAMES
# ==============================================================================

const SLOT_PRIMARY_WEAPON = "primary_weapon"
const SLOT_SECONDARY_WEAPON = "secondary_weapon"
const SLOT_ARMOR = "armor"
const SLOT_HELMET = "helmet"
const SLOT_ACCESSORY_1 = "accessory_1"
const SLOT_ACCESSORY_2 = "accessory_2"
const SLOT_RELIC = "relic"

const ALL_SLOTS = [
	SLOT_PRIMARY_WEAPON,
	SLOT_SECONDARY_WEAPON,
	SLOT_ARMOR,
	SLOT_HELMET,
	SLOT_ACCESSORY_1,
	SLOT_ACCESSORY_2,
	SLOT_RELIC
]


# ==============================================================================
# EQUIPMENT SLOTS
# ==============================================================================

## Currently equipped items (slot name -> EquipmentData)
var equipped_items: Dictionary = {
	SLOT_PRIMARY_WEAPON: null,
	SLOT_SECONDARY_WEAPON: null,
	SLOT_ARMOR: null,
	SLOT_HELMET: null,
	SLOT_ACCESSORY_1: null,
	SLOT_ACCESSORY_2: null,
	SLOT_RELIC: null
}

## Which weapon is currently active (true = primary, false = secondary)
var primary_weapon_active: bool = true


# ==============================================================================
# AMMUNITION
# ==============================================================================

## Ammo inventory (AmmoType -> count)
var ammo_inventory: Dictionary = {
	EquipmentData.AmmoType.BULLET: 0,
	EquipmentData.AmmoType.SHELL: 0,
	EquipmentData.AmmoType.ENERGY_CELL: 0,
	EquipmentData.AmmoType.PLASMA_CELL: 0,
	EquipmentData.AmmoType.ROCKET: 0,
	EquipmentData.AmmoType.ARROW: 0
}


# ==============================================================================
# REFERENCES
# ==============================================================================

var player_stats: PlayerStats


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _ready() -> void:
	# PlayerStats is set via set_player_stats() from parent
	pass


## Set the player stats reference
func set_player_stats(stats: PlayerStats) -> void:
	player_stats = stats
	if player_stats:
		_recalculate_bonuses()


# ==============================================================================
# EQUIPMENT MANAGEMENT
# ==============================================================================

## Equip an item to the appropriate slot
func equip(item: EquipmentData, slot: String = "") -> EquipmentData:
	if not item:
		return null
	
	# Auto-determine slot if not specified
	if slot.is_empty():
		slot = _get_default_slot_for_type(item.equipment_type)
	
	# Validate slot for item type
	if not _is_valid_slot_for_item(item, slot):
		push_warning("Cannot equip %s to slot %s" % [item.name, slot])
		return null
	
	# Get the old item (if any)
	var old_item = equipped_items.get(slot)
	
	# Equip new item
	equipped_items[slot] = item
	
	# Recalculate stat bonuses
	_recalculate_bonuses()
	
	# Emit signal
	equipment_changed.emit(slot, old_item, item)
	
	# Return old item (for inventory placement)
	return old_item


## Unequip an item from a slot
func unequip(slot: String) -> EquipmentData:
	if not equipped_items.has(slot):
		return null
	
	var item = equipped_items[slot]
	if not item:
		return null
	
	equipped_items[slot] = null
	
	# Recalculate stat bonuses
	_recalculate_bonuses()
	
	# Emit signal
	equipment_changed.emit(slot, item, null)
	
	return item


## Get equipped item in a slot
func get_equipped(slot: String) -> EquipmentData:
	return equipped_items.get(slot)


## Check if a slot has an item
func has_equipped(slot: String) -> bool:
	return equipped_items.get(slot) != null


## Get the currently active weapon
func get_active_weapon() -> EquipmentData:
	if primary_weapon_active:
		return equipped_items.get(SLOT_PRIMARY_WEAPON)
	else:
		return equipped_items.get(SLOT_SECONDARY_WEAPON)


## Switch between primary and secondary weapons
func switch_weapon() -> void:
	primary_weapon_active = not primary_weapon_active
	weapon_switched.emit(primary_weapon_active, get_active_weapon())


## Set active weapon slot
func set_active_weapon(is_primary: bool) -> void:
	if primary_weapon_active != is_primary:
		primary_weapon_active = is_primary
		weapon_switched.emit(primary_weapon_active, get_active_weapon())


# ==============================================================================
# AMMUNITION MANAGEMENT
# ==============================================================================

## Add ammo to inventory
func add_ammo(ammo_type: EquipmentData.AmmoType, amount: int) -> void:
	if ammo_type == EquipmentData.AmmoType.NONE:
		return
	
	ammo_inventory[ammo_type] = ammo_inventory.get(ammo_type, 0) + amount
	ammo_changed.emit(ammo_type, ammo_inventory[ammo_type])


## Use ammo from inventory
func use_ammo(ammo_type: EquipmentData.AmmoType, amount: int = 1) -> bool:
	if ammo_type == EquipmentData.AmmoType.NONE:
		return true  # No ammo required
	
	var current = ammo_inventory.get(ammo_type, 0)
	if current < amount:
		return false  # Not enough ammo
	
	ammo_inventory[ammo_type] = current - amount
	ammo_changed.emit(ammo_type, ammo_inventory[ammo_type])
	return true


## Get ammo count for a type
func get_ammo_count(ammo_type: EquipmentData.AmmoType) -> int:
	return ammo_inventory.get(ammo_type, 0)


## Check if player has ammo for current weapon
func has_ammo_for_weapon() -> bool:
	var weapon = get_active_weapon()
	if not weapon or not weapon.requires_ammo():
		return true
	
	return get_ammo_count(weapon.ammo_type) > 0


# ==============================================================================
# STAT BONUS CALCULATION
# ==============================================================================

## Recalculate all stat bonuses from equipment
func _recalculate_bonuses() -> void:
	if not player_stats:
		return
	
	# Clear current bonuses
	player_stats.clear_all_bonuses()
	
	# Add bonuses from each equipped item
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item:
			var bonuses = item.get_stat_bonuses()
			for stat in bonuses:
				if bonuses[stat] != 0:
					player_stats.add_bonus(stat, bonuses[stat])


## Get total bonus for a stat from all equipment
func get_total_bonus(stat_name: String) -> int:
	var total = 0
	for slot in equipped_items:
		var item = equipped_items[slot]
		if item:
			var bonuses = item.get_stat_bonuses()
			total += bonuses.get(stat_name, 0)
	return total


# ==============================================================================
# COMBAT CALCULATIONS
# ==============================================================================

## Calculate total damage for current weapon
func get_weapon_damage() -> int:
	var weapon = get_active_weapon()
	if not weapon:
		return 1  # Unarmed damage
	
	var base = weapon.base_damage
	var attack_bonus = player_stats.get_attack() if player_stats else 0
	
	return base + (attack_bonus / 2)


## Calculate if attack is a critical hit
func roll_critical() -> bool:
	var weapon = get_active_weapon()
	var base_crit = weapon.crit_chance if weapon else 0.02
	var luck_bonus = (player_stats.get_luck() if player_stats else 0) * 0.005
	
	return randf() < (base_crit + luck_bonus)


## Get critical damage multiplier
func get_crit_multiplier() -> float:
	var weapon = get_active_weapon()
	return weapon.crit_multiplier if weapon else 1.5


## Calculate damage reduction from armor
func get_damage_reduction() -> float:
	var total_reduction = 0.0
	
	var armor = equipped_items.get(SLOT_ARMOR)
	if armor:
		total_reduction += armor.damage_reduction
	
	var helmet = equipped_items.get(SLOT_HELMET)
	if helmet:
		total_reduction += helmet.damage_reduction
	
	# Cap at 75% reduction
	return clampf(total_reduction, 0.0, 0.75)


## Calculate flat armor value
func get_armor_value() -> int:
	var total_armor = 0
	
	var armor = equipped_items.get(SLOT_ARMOR)
	if armor:
		total_armor += armor.armor_value
	
	var helmet = equipped_items.get(SLOT_HELMET)
	if helmet:
		total_armor += helmet.armor_value
	
	return total_armor


# ==============================================================================
# SLOT VALIDATION
# ==============================================================================

## Get the default slot for an equipment type
func _get_default_slot_for_type(equip_type: EquipmentData.EquipmentType) -> String:
	match equip_type:
		EquipmentData.EquipmentType.WEAPON_RANGED, EquipmentData.EquipmentType.WEAPON_MELEE:
			# Default to primary, but use secondary if primary is full
			if not equipped_items.get(SLOT_PRIMARY_WEAPON):
				return SLOT_PRIMARY_WEAPON
			return SLOT_SECONDARY_WEAPON
		EquipmentData.EquipmentType.ARMOR:
			return SLOT_ARMOR
		EquipmentData.EquipmentType.HELMET:
			return SLOT_HELMET
		EquipmentData.EquipmentType.ACCESSORY:
			# Default to first slot, use second if full
			if not equipped_items.get(SLOT_ACCESSORY_1):
				return SLOT_ACCESSORY_1
			return SLOT_ACCESSORY_2
		EquipmentData.EquipmentType.RELIC:
			return SLOT_RELIC
		_:
			return ""


## Check if an item can be equipped to a specific slot
func _is_valid_slot_for_item(item: EquipmentData, slot: String) -> bool:
	match slot:
		SLOT_PRIMARY_WEAPON, SLOT_SECONDARY_WEAPON:
			return item.is_weapon()
		SLOT_ARMOR:
			return item.equipment_type == EquipmentData.EquipmentType.ARMOR
		SLOT_HELMET:
			return item.equipment_type == EquipmentData.EquipmentType.HELMET
		SLOT_ACCESSORY_1, SLOT_ACCESSORY_2:
			return item.equipment_type == EquipmentData.EquipmentType.ACCESSORY
		SLOT_RELIC:
			return item.equipment_type == EquipmentData.EquipmentType.RELIC
		_:
			return false


# ==============================================================================
# SERIALIZATION
# ==============================================================================

## Convert equipment to dictionary for saving
func to_dict() -> Dictionary:
	var data = {
		"equipped": {},
		"ammo": ammo_inventory.duplicate(),
		"primary_active": primary_weapon_active
	}
	
	for slot in equipped_items:
		if equipped_items[slot]:
			data.equipped[slot] = equipped_items[slot].id
	
	return data


## Load equipment from dictionary
func from_dict(data: Dictionary, item_lookup: Callable) -> void:
	primary_weapon_active = data.get("primary_active", true)
	
	# Load ammo
	var saved_ammo = data.get("ammo", {})
	for ammo_type in saved_ammo:
		ammo_inventory[int(ammo_type)] = saved_ammo[ammo_type]
	
	# Load equipped items (requires a lookup function to convert IDs to EquipmentData)
	var saved_equipped = data.get("equipped", {})
	for slot in saved_equipped:
		var item_id = saved_equipped[slot]
		var item = item_lookup.call(item_id)
		if item:
			equipped_items[slot] = item
	
	_recalculate_bonuses()
