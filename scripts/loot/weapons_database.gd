# ==============================================================================
# WEAPONS DATABASE
# ==============================================================================
#
# FILE: scripts/loot/weapons_database.gd
# PURPOSE: Central database for all weapon definitions
#
# WEAPON CATEGORIES:
# - Pistols (Common-Rare, fast, low damage)
# - Rifles (Uncommon-Epic, balanced)
# - Shotguns (Uncommon-Epic, high damage, short range)
# - SMGs (Common-Rare, high fire rate, low damage)
# - Heavy (Rare-Legendary, slow, high damage)
# - Energy (Rare-Legendary, special damage types)
# - Melee (Various, no ammo required)
#
# ==============================================================================

extends Node
class_name WeaponsDatabase


# ==============================================================================
# RANGED WEAPONS (20 total)
# ==============================================================================

const RANGED_WEAPONS = {
	# ============ PISTOLS (5) ============
	"pistol_basic": {
		"name": "Service Pistol",
		"description": "Standard-issue sidearm. Reliable and easy to use.",
		"lore": "Every spacer's first friend. The Model 7 has saved more lives than any medkit.",
		"salvage": {"scrap_metal": 2, "mechanical_parts": 1},
		"type": "ranged",
		"width": 1, "height": 2,
		"base_damage": 12,
		"fire_rate": 2.5,
		"range": 400,
		"ammo_type": 1,  # BULLET
		"magazine_size": 12,
		"reload_time": 1.2,
		"accuracy": 0.85,
		"crit_chance": 0.05,
		"crit_mult": 1.5,
		"rarity": 0,
		"value": 150,
		"icon": "res://assets/sprites/items/weapons/pistol_basic.svg"
	},
	"pistol_heavy": {
		"name": "Heavy Revolver",
		"description": "Powerful six-shooter. Packs a serious punch.",
		"lore": "They don't make 'em like this anymore. Each round costs more than your meal.",
		"salvage": {"scrap_metal": 3, "mechanical_parts": 2},
		"type": "ranged",
		"width": 2, "height": 1,
		"base_damage": 28,
		"fire_rate": 1.2,
		"range": 350,
		"ammo_type": 1,  # BULLET
		"magazine_size": 6,
		"reload_time": 2.0,
		"accuracy": 0.80,
		"crit_chance": 0.10,
		"crit_mult": 2.0,
		"rarity": 1,
		"value": 400,
		"icon": "res://assets/sprites/items/weapons/pistol_heavy.svg"
	},
	"pistol_silenced": {
		"name": "Silenced Pistol",
		"description": "Suppressed handgun. Perfect for stealth operations.",
		"lore": "The assassin's choice. What they don't hear won't hurt them... much.",
		"salvage": {"scrap_metal": 2, "mechanical_parts": 2, "electronics": 1},
		"type": "ranged",
		"width": 2, "height": 1,
		"base_damage": 15,
		"fire_rate": 2.0,
		"range": 300,
		"ammo_type": 1,  # BULLET
		"magazine_size": 10,
		"reload_time": 1.5,
		"accuracy": 0.90,
		"crit_chance": 0.15,
		"crit_mult": 2.5,
		"rarity": 2,
		"value": 800,
		"bonus_stealth": 5,
		"icon": "res://assets/sprites/items/weapons/pistol_silenced.svg"
	},
	"pistol_plasma": {
		"name": "Plasma Pistol",
		"description": "Compact energy weapon. Burns through armor.",
		"lore": "Nexus Corp's finest. Handle with care - the warranty doesn't cover self-immolation.",
		"salvage": {"scrap_metal": 2, "electronics": 3, "energy_cell": 1},
		"type": "ranged",
		"damage_type": 2,  # PLASMA
		"width": 1, "height": 2,
		"base_damage": 22,
		"fire_rate": 1.8,
		"range": 350,
		"ammo_type": 4,  # PLASMA_CELL
		"magazine_size": 8,
		"reload_time": 1.8,
		"accuracy": 0.88,
		"crit_chance": 0.08,
		"crit_mult": 1.75,
		"rarity": 3,
		"value": 1500,
		"icon": "res://assets/sprites/items/weapons/pistol_plasma.svg"
	},
	"pistol_legendary": {
		"name": "The Negotiator",
		"description": "Golden handcrafted pistol. 'Let's make a deal.'",
		"lore": "Belonged to Captain Mercer before his 'retirement'. The gold is real. So is the body count.",
		"salvage": {"scrap_metal": 2, "mechanical_parts": 3, "rare_alloy": 2, "gold_plating": 1},
		"type": "ranged",
		"width": 2, "height": 1,
		"base_damage": 35,
		"fire_rate": 2.2,
		"range": 450,
		"ammo_type": 1,  # BULLET
		"magazine_size": 8,
		"reload_time": 1.0,
		"accuracy": 0.95,
		"crit_chance": 0.20,
		"crit_mult": 3.0,
		"rarity": 4,
		"value": 5000,
		"bonus_luck": 5,
		"icon": "res://assets/sprites/items/weapons/pistol_legendary.svg"
	},

	# ============ RIFLES (5) ============
	"rifle_assault": {
		"name": "Assault Rifle",
		"description": "Versatile automatic rifle. Good at any range.",
		"lore": "GDF standard issue. If you hear the bark of an AR-7, run the other way.",
		"salvage": {"scrap_metal": 4, "mechanical_parts": 3},
		"type": "ranged",
		"width": 3, "height": 1,
		"base_damage": 18,
		"fire_rate": 5.0,
		"range": 550,
		"ammo_type": 1,  # BULLET
		"magazine_size": 30,
		"reload_time": 2.2,
		"accuracy": 0.75,
		"crit_chance": 0.05,
		"crit_mult": 1.5,
		"rarity": 1,
		"value": 600,
		"icon": "res://assets/sprites/items/weapons/rifle_assault.svg"
	},
	"rifle_marksman": {
		"name": "Marksman Rifle",
		"description": "Semi-automatic precision rifle. For the patient hunter.",
		"lore": "One shot. One kill. Repeat as necessary. - Sniper's Creed",
		"salvage": {"scrap_metal": 4, "mechanical_parts": 3, "optics": 1},
		"type": "ranged",
		"width": 3, "height": 1,
		"base_damage": 35,
		"fire_rate": 1.5,
		"range": 800,
		"ammo_type": 1,  # BULLET
		"magazine_size": 10,
		"reload_time": 2.5,
		"accuracy": 0.95,
		"crit_chance": 0.15,
		"crit_mult": 2.5,
		"rarity": 2,
		"value": 1200,
		"icon": "res://assets/sprites/items/weapons/rifle_marksman.svg"
	},
	"rifle_sniper": {
		"name": "Sniper Rifle",
		"description": "Long-range elimination tool. One shot, one kill.",
		"lore": "The last thing they never see. Effective range: yes.",
		"salvage": {"scrap_metal": 5, "mechanical_parts": 4, "optics": 2},
		"type": "ranged",
		"width": 4, "height": 1,
		"base_damage": 80,
		"fire_rate": 0.5,
		"range": 1200,
		"ammo_type": 1,  # BULLET
		"magazine_size": 5,
		"reload_time": 3.0,
		"accuracy": 0.98,
		"crit_chance": 0.25,
		"crit_mult": 3.0,
		"rarity": 3,
		"value": 2500,
		"icon": "res://assets/sprites/items/weapons/rifle_sniper.svg"
	},
	"rifle_laser": {
		"name": "Laser Rifle",
		"description": "Military-grade beam weapon. Cuts through steel.",
		"lore": "Warning: Do not look into beam. Do not point at face. Common sense not included.",
		"salvage": {"scrap_metal": 3, "electronics": 4, "energy_cell": 2},
		"type": "ranged",
		"damage_type": 1,  # ENERGY
		"width": 3, "height": 1,
		"base_damage": 25,
		"fire_rate": 3.0,
		"range": 600,
		"ammo_type": 3,  # ENERGY_CELL
		"magazine_size": 20,
		"reload_time": 2.0,
		"accuracy": 0.92,
		"crit_chance": 0.10,
		"crit_mult": 2.0,
		"rarity": 2,
		"value": 1400,
		"icon": "res://assets/sprites/items/weapons/rifle_laser.svg"
	},
	"rifle_pulse": {
		"name": "Pulse Cannon",
		"description": "Experimental energy weapon. Fires charged plasma bursts.",
		"lore": "Classified Nexus prototype. If found, return to... actually, keep it. We made more.",
		"salvage": {"scrap_metal": 4, "electronics": 5, "energy_cell": 3, "rare_alloy": 1},
		"type": "ranged",
		"damage_type": 2,  # PLASMA
		"width": 3, "height": 2,
		"base_damage": 45,
		"fire_rate": 2.0,
		"range": 500,
		"ammo_type": 4,  # PLASMA_CELL
		"magazine_size": 12,
		"reload_time": 2.5,
		"accuracy": 0.85,
		"crit_chance": 0.12,
		"crit_mult": 2.0,
		"rarity": 4,
		"value": 4500,
		"bonus_attack": 3,
		"icon": "res://assets/sprites/items/weapons/rifle_pulse.svg"
	},

	# ============ SHOTGUNS (4) ============
	"shotgun_pump": {
		"name": "Pump Shotgun",
		"description": "Classic pump-action. Devastating at close range.",
		"type": "ranged",
		"width": 3, "height": 1,
		"base_damage": 50,
		"fire_rate": 0.8,
		"range": 200,
		"ammo_type": 2,  # SHELL
		"magazine_size": 6,
		"reload_time": 3.0,
		"accuracy": 0.60,
		"crit_chance": 0.08,
		"crit_mult": 1.5,
		"rarity": 1,
		"value": 450,
		"icon": "res://assets/sprites/items/weapons/shotgun_pump.svg"
	},
	"shotgun_auto": {
		"name": "Auto Shotgun",
		"description": "Semi-automatic shotgun. Rapid room clearing.",
		"type": "ranged",
		"width": 3, "height": 1,
		"base_damage": 40,
		"fire_rate": 1.5,
		"range": 180,
		"ammo_type": 2,  # SHELL
		"magazine_size": 8,
		"reload_time": 2.5,
		"accuracy": 0.55,
		"crit_chance": 0.05,
		"crit_mult": 1.5,
		"rarity": 2,
		"value": 900,
		"icon": "res://assets/sprites/items/weapons/shotgun_auto.svg"
	},
	"shotgun_sawed": {
		"name": "Sawed-Off Shotgun",
		"description": "Compact and concealable. Maximum spread.",
		"type": "ranged",
		"width": 2, "height": 1,
		"base_damage": 60,
		"fire_rate": 1.0,
		"range": 120,
		"ammo_type": 2,  # SHELL
		"magazine_size": 2,
		"reload_time": 1.8,
		"accuracy": 0.40,
		"crit_chance": 0.10,
		"crit_mult": 1.75,
		"rarity": 1,
		"value": 350,
		"bonus_stealth": 2,
		"icon": "res://assets/sprites/items/weapons/shotgun_sawed.svg"
	},
	"shotgun_plasma": {
		"name": "Plasma Scattergun",
		"description": "Energy shotgun. Leaves nothing but ash.",
		"type": "ranged",
		"damage_type": 2,  # PLASMA
		"width": 3, "height": 1,
		"base_damage": 65,
		"fire_rate": 0.9,
		"range": 180,
		"ammo_type": 4,  # PLASMA_CELL
		"magazine_size": 4,
		"reload_time": 2.8,
		"accuracy": 0.50,
		"crit_chance": 0.12,
		"crit_mult": 2.0,
		"rarity": 3,
		"value": 2200,
		"icon": "res://assets/sprites/items/weapons/shotgun_plasma.svg"
	},

	# ============ SMGs (3) ============
	"smg_compact": {
		"name": "Compact SMG",
		"description": "Lightweight submachine gun. High rate of fire.",
		"type": "ranged",
		"width": 2, "height": 1,
		"base_damage": 10,
		"fire_rate": 10.0,
		"range": 300,
		"ammo_type": 1,  # BULLET
		"magazine_size": 25,
		"reload_time": 1.5,
		"accuracy": 0.65,
		"crit_chance": 0.03,
		"crit_mult": 1.5,
		"rarity": 0,
		"value": 300,
		"icon": "res://assets/sprites/items/weapons/smg_compact.svg"
	},
	"smg_tactical": {
		"name": "Tactical SMG",
		"description": "Military SMG with integrated suppressor.",
		"type": "ranged",
		"width": 2, "height": 1,
		"base_damage": 14,
		"fire_rate": 8.0,
		"range": 350,
		"ammo_type": 1,  # BULLET
		"magazine_size": 30,
		"reload_time": 1.8,
		"accuracy": 0.72,
		"crit_chance": 0.05,
		"crit_mult": 1.75,
		"rarity": 2,
		"value": 850,
		"bonus_stealth": 3,
		"icon": "res://assets/sprites/items/weapons/smg_tactical.svg"
	},
	"smg_energy": {
		"name": "Beam SMG",
		"description": "Rapid-fire energy weapon. Constant beam damage.",
		"type": "ranged",
		"damage_type": 1,  # ENERGY
		"width": 2, "height": 1,
		"base_damage": 12,
		"fire_rate": 12.0,
		"range": 280,
		"ammo_type": 3,  # ENERGY_CELL
		"magazine_size": 40,
		"reload_time": 2.0,
		"accuracy": 0.70,
		"crit_chance": 0.04,
		"crit_mult": 1.5,
		"rarity": 2,
		"value": 950,
		"icon": "res://assets/sprites/items/weapons/smg_energy.svg"
	},

	# ============ HEAVY (3) ============
	"heavy_lmg": {
		"name": "Light Machine Gun",
		"description": "Sustained fire support weapon. Lay down suppression.",
		"type": "ranged",
		"width": 4, "height": 2,
		"base_damage": 22,
		"fire_rate": 7.0,
		"range": 500,
		"ammo_type": 1,  # BULLET
		"magazine_size": 100,
		"reload_time": 4.0,
		"accuracy": 0.60,
		"crit_chance": 0.03,
		"crit_mult": 1.5,
		"rarity": 2,
		"value": 1800,
		"bonus_speed": -2,
		"icon": "res://assets/sprites/items/weapons/heavy_lmg.svg"
	},
	"heavy_launcher": {
		"name": "Rocket Launcher",
		"description": "Anti-armor weapon. Causes explosive devastation.",
		"type": "ranged",
		"damage_type": 3,  # EXPLOSIVE
		"width": 4, "height": 2,
		"base_damage": 120,
		"fire_rate": 0.3,
		"range": 600,
		"ammo_type": 5,  # ROCKET
		"magazine_size": 1,
		"reload_time": 4.0,
		"accuracy": 0.75,
		"crit_chance": 0.05,
		"crit_mult": 1.5,
		"rarity": 3,
		"value": 3000,
		"bonus_speed": -3,
		"icon": "res://assets/sprites/items/weapons/heavy_launcher.svg"
	},
	"heavy_minigun": {
		"name": "Minigun",
		"description": "Rotary cannon of death. Nothing survives.",
		"type": "ranged",
		"width": 4, "height": 2,
		"base_damage": 15,
		"fire_rate": 20.0,
		"range": 400,
		"ammo_type": 1,  # BULLET
		"magazine_size": 200,
		"reload_time": 5.0,
		"accuracy": 0.50,
		"crit_chance": 0.02,
		"crit_mult": 1.5,
		"rarity": 4,
		"value": 6000,
		"bonus_speed": -5,
		"bonus_attack": 5,
		"icon": "res://assets/sprites/items/weapons/heavy_minigun.svg"
	}
}


# ==============================================================================
# MELEE WEAPONS (10 total)
# ==============================================================================

const MELEE_WEAPONS = {
	# ============ BLADES (5) ============
	"melee_knife": {
		"name": "Combat Knife",
		"description": "Standard issue combat blade. Quick and deadly.",
		"type": "melee",
		"width": 1, "height": 2,
		"base_damage": 20,
		"attack_speed": 2.0,
		"range": 50,
		"crit_chance": 0.10,
		"crit_mult": 2.0,
		"rarity": 0,
		"value": 100,
		"bonus_stealth": 2,
		"icon": "res://assets/sprites/items/weapons/melee_knife.svg"
	},
	"melee_machete": {
		"name": "Space Machete",
		"description": "Heavy cleaving blade. Brutal efficiency.",
		"type": "melee",
		"width": 1, "height": 3,
		"base_damage": 35,
		"attack_speed": 1.2,
		"range": 70,
		"crit_chance": 0.08,
		"crit_mult": 1.75,
		"rarity": 1,
		"value": 350,
		"icon": "res://assets/sprites/items/weapons/melee_machete.svg"
	},
	"melee_katana": {
		"name": "Mono-Katana",
		"description": "Molecularly-sharpened blade. Cuts through anything.",
		"type": "melee",
		"width": 1, "height": 4,
		"base_damage": 45,
		"attack_speed": 1.5,
		"range": 80,
		"crit_chance": 0.20,
		"crit_mult": 2.5,
		"rarity": 3,
		"value": 2000,
		"bonus_speed": 2,
		"icon": "res://assets/sprites/items/weapons/melee_katana.svg"
	},
	"melee_vibroblade": {
		"name": "Vibro-Blade",
		"description": "High-frequency oscillating sword. Ignores armor.",
		"type": "melee",
		"width": 1, "height": 3,
		"base_damage": 55,
		"attack_speed": 1.3,
		"range": 75,
		"crit_chance": 0.15,
		"crit_mult": 2.0,
		"rarity": 3,
		"value": 2500,
		"bonus_attack": 3,
		"icon": "res://assets/sprites/items/weapons/melee_vibroblade.svg"
	},
	"melee_plasma_sword": {
		"name": "Plasma Blade",
		"description": "Superheated plasma edge. The weapon of legends.",
		"type": "melee",
		"damage_type": 2,  # PLASMA
		"width": 1, "height": 3,
		"base_damage": 70,
		"attack_speed": 1.4,
		"range": 85,
		"crit_chance": 0.18,
		"crit_mult": 2.5,
		"rarity": 4,
		"value": 5500,
		"bonus_attack": 5,
		"icon": "res://assets/sprites/items/weapons/melee_plasma_sword.svg"
	},

	# ============ BLUNT (3) ============
	"melee_baton": {
		"name": "Stun Baton",
		"description": "Non-lethal takedown weapon. For quiet operations.",
		"type": "melee",
		"damage_type": 1,  # ENERGY
		"width": 1, "height": 2,
		"base_damage": 15,
		"attack_speed": 2.5,
		"range": 55,
		"crit_chance": 0.05,
		"crit_mult": 3.0,  # Stun bonus
		"rarity": 1,
		"value": 250,
		"bonus_stealth": 5,
		"icon": "res://assets/sprites/items/weapons/melee_baton.svg"
	},
	"melee_hammer": {
		"name": "Power Hammer",
		"description": "Hydraulic-assisted sledge. Crushes all resistance.",
		"type": "melee",
		"width": 2, "height": 3,
		"base_damage": 60,
		"attack_speed": 0.7,
		"range": 65,
		"crit_chance": 0.12,
		"crit_mult": 2.0,
		"rarity": 2,
		"value": 900,
		"bonus_attack": 4,
		"bonus_speed": -2,
		"icon": "res://assets/sprites/items/weapons/melee_hammer.svg"
	},
	"melee_wrench": {
		"name": "Engineer's Wrench",
		"description": "Heavy industrial tool. Doubles as a weapon.",
		"type": "melee",
		"width": 1, "height": 2,
		"base_damage": 25,
		"attack_speed": 1.3,
		"range": 55,
		"crit_chance": 0.08,
		"crit_mult": 1.5,
		"rarity": 0,
		"value": 80,
		"icon": "res://assets/sprites/items/weapons/melee_wrench.svg"
	},

	# ============ EXOTIC (2) ============
	"melee_claws": {
		"name": "Predator Claws",
		"description": "Wrist-mounted retractable blades. Swift death.",
		"type": "melee",
		"width": 2, "height": 1,
		"base_damage": 30,
		"attack_speed": 3.0,
		"range": 40,
		"crit_chance": 0.25,
		"crit_mult": 2.0,
		"rarity": 3,
		"value": 1800,
		"bonus_speed": 3,
		"bonus_stealth": 3,
		"icon": "res://assets/sprites/items/weapons/melee_claws.svg"
	},
	"melee_chain": {
		"name": "Energy Whip",
		"description": "Flexible plasma filament. Reaches around cover.",
		"type": "melee",
		"damage_type": 1,  # ENERGY
		"width": 2, "height": 2,
		"base_damage": 40,
		"attack_speed": 1.0,
		"range": 120,
		"crit_chance": 0.10,
		"crit_mult": 1.75,
		"rarity": 4,
		"value": 4000,
		"icon": "res://assets/sprites/items/weapons/melee_chain.svg"
	}
}


# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

## Get all ranged weapon IDs
static func get_ranged_weapon_ids() -> Array:
	return RANGED_WEAPONS.keys()


## Get all melee weapon IDs
static func get_melee_weapon_ids() -> Array:
	return MELEE_WEAPONS.keys()


## Get all weapon IDs
static func get_all_weapon_ids() -> Array:
	var all_ids = []
	all_ids.append_array(RANGED_WEAPONS.keys())
	all_ids.append_array(MELEE_WEAPONS.keys())
	return all_ids


## Get weapon data by ID
static func get_weapon_data(weapon_id: String) -> Dictionary:
	if RANGED_WEAPONS.has(weapon_id):
		return RANGED_WEAPONS[weapon_id]
	if MELEE_WEAPONS.has(weapon_id):
		return MELEE_WEAPONS[weapon_id]
	return {}


## Create EquipmentData resource from weapon ID
static func create_weapon_resource(weapon_id: String) -> EquipmentData:
	var data = get_weapon_data(weapon_id)
	if data.is_empty():
		return null
	
	var weapon = EquipmentData.new()
	weapon.id = weapon_id
	weapon.name = data.get("name", "Unknown Weapon")
	weapon.description = data.get("description", "")
	weapon.lore_text = data.get("lore", "")
	weapon.crafting_components = data.get("salvage", {})
	weapon.craft_recipe = data.get("recipe", {})
	weapon.grid_width = data.get("width", 1)
	weapon.grid_height = data.get("height", 2)
	weapon.rarity = data.get("rarity", 0)
	weapon.base_value = data.get("value", 100)
	
	# Set equipment type
	if data.get("type") == "melee":
		weapon.equipment_type = EquipmentData.EquipmentType.WEAPON_MELEE
	else:
		weapon.equipment_type = EquipmentData.EquipmentType.WEAPON_RANGED
	
	# Weapon stats
	weapon.base_damage = data.get("base_damage", 10)
	weapon.damage_type = data.get("damage_type", EquipmentData.WeaponDamageType.PHYSICAL)
	weapon.fire_rate = data.get("fire_rate", 1.0)
	weapon.attack_speed = data.get("attack_speed", 1.0)
	weapon.range_pixels = data.get("range", 100)
	weapon.ammo_type = data.get("ammo_type", EquipmentData.AmmoType.NONE)
	weapon.magazine_size = data.get("magazine_size", 0)
	weapon.reload_time = data.get("reload_time", 1.0)
	weapon.accuracy = data.get("accuracy", 0.9)
	weapon.crit_chance = data.get("crit_chance", 0.05)
	weapon.crit_multiplier = data.get("crit_mult", 1.5)
	
	# Stat bonuses
	weapon.bonus_health = data.get("bonus_health", 0)
	weapon.bonus_attack = data.get("bonus_attack", 0)
	weapon.bonus_defense = data.get("bonus_defense", 0)
	weapon.bonus_speed = data.get("bonus_speed", 0)
	weapon.bonus_luck = data.get("bonus_luck", 0)
	weapon.bonus_stealth = data.get("bonus_stealth", 0)
	
	# Calculate EXP value
	weapon.exp_value = weapon.calculate_exp_value()
	
	# Try to load icon
	if data.has("icon") and ResourceLoader.exists(data.icon):
		weapon.icon = load(data.icon)
	
	return weapon


## Get weapons by rarity
static func get_weapons_by_rarity(rarity: int) -> Array:
	var weapons = []
	
	for id in RANGED_WEAPONS:
		if RANGED_WEAPONS[id].get("rarity", 0) == rarity:
			weapons.append(id)
	
	for id in MELEE_WEAPONS:
		if MELEE_WEAPONS[id].get("rarity", 0) == rarity:
			weapons.append(id)
	
	return weapons


## Get random weapon by rarity range
static func get_random_weapon(min_rarity: int = 0, max_rarity: int = 4, prefer_ranged: bool = true) -> String:
	var pool = []
	
	for id in RANGED_WEAPONS:
		var r = RANGED_WEAPONS[id].get("rarity", 0)
		if r >= min_rarity and r <= max_rarity:
			pool.append(id)
			if prefer_ranged:
				pool.append(id)  # Add twice to increase odds
	
	for id in MELEE_WEAPONS:
		var r = MELEE_WEAPONS[id].get("rarity", 0)
		if r >= min_rarity and r <= max_rarity:
			pool.append(id)
	
	if pool.is_empty():
		return ""
	
	return pool[randi() % pool.size()]
