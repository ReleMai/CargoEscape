# ==============================================================================
# PLAYER STATS RESOURCE
# ==============================================================================
#
# FILE: scripts/player/player_stats.gd
# PURPOSE: Defines player statistics, leveling, and EXP progression
#
# STAT SYSTEM:
# - Base stats are the starting values
# - Level-up grants stat points to allocate
# - Equipment can modify stats with bonuses
# - Skills can grant passive stat modifiers
#
# ==============================================================================

extends Resource
class_name PlayerStats


# ==============================================================================
# SIGNALS
# ==============================================================================

signal stat_changed(stat_name: String, old_value: int, new_value: int)
signal level_up(new_level: int)
signal exp_gained(amount: int, total: int)


# ==============================================================================
# CONSTANTS
# ==============================================================================

## EXP required for each level (index = level, value = total EXP needed)
const LEVEL_EXP_TABLE: Array[int] = [
	0,      # Level 1 (starting)
	100,    # Level 2
	300,    # Level 3
	600,    # Level 4
	1000,   # Level 5
	1500,   # Level 6
	2100,   # Level 7
	2800,   # Level 8
	3600,   # Level 9
	4500,   # Level 10
	5500,   # Level 11
	6600,   # Level 12
	7800,   # Level 13
	9100,   # Level 14
	10500,  # Level 15
	12000,  # Level 16
	13600,  # Level 17
	15300,  # Level 18
	17100,  # Level 19
	19000,  # Level 20 (max)
]

const MAX_LEVEL: int = 20
const STAT_POINTS_PER_LEVEL: int = 3

## Stat names for iteration
const STAT_NAMES: Array[String] = [
	"health", "attack", "defense", "speed", "luck", "stealth"
]


# ==============================================================================
# BASE STATS (Starting values)
# ==============================================================================

@export_group("Base Stats")
## Maximum health points
@export var base_health: int = 100

## Attack power - affects weapon damage
@export var base_attack: int = 10

## Defense - reduces incoming damage
@export var base_defense: int = 5

## Speed - affects movement and action speed
@export var base_speed: int = 10

## Luck - affects loot quality, critical hits, and evasion
@export var base_luck: int = 5

## Stealth - affects detection by enemies
@export var base_stealth: int = 10


# ==============================================================================
# ALLOCATED STATS (Points spent by player)
# ==============================================================================

@export_group("Allocated Stats")
@export var allocated_health: int = 0
@export var allocated_attack: int = 0
@export var allocated_defense: int = 0
@export var allocated_speed: int = 0
@export var allocated_luck: int = 0
@export var allocated_stealth: int = 0


# ==============================================================================
# BONUS STATS (From equipment, buffs, skills)
# ==============================================================================

var bonus_health: int = 0
var bonus_attack: int = 0
var bonus_defense: int = 0
var bonus_speed: int = 0
var bonus_luck: int = 0
var bonus_stealth: int = 0


# ==============================================================================
# PROGRESSION
# ==============================================================================

@export_group("Progression")
## Current level (1-20)
@export var level: int = 1

## Current experience points
@export var current_exp: int = 0

## Unspent stat points
@export var available_stat_points: int = 0


# ==============================================================================
# COMPUTED STATS (Base + Allocated + Bonus)
# ==============================================================================

## Get total health
func get_health() -> int:
	return base_health + allocated_health + bonus_health


## Get total attack
func get_attack() -> int:
	return base_attack + allocated_attack + bonus_attack


## Get total defense
func get_defense() -> int:
	return base_defense + allocated_defense + bonus_defense


## Get total speed
func get_speed() -> int:
	return base_speed + allocated_speed + bonus_speed


## Get total luck
func get_luck() -> int:
	return base_luck + allocated_luck + bonus_luck


## Get total stealth
func get_stealth() -> int:
	return base_stealth + allocated_stealth + bonus_stealth


## Get any stat by name
func get_stat(stat_name: String) -> int:
	match stat_name:
		"health": return get_health()
		"attack": return get_attack()
		"defense": return get_defense()
		"speed": return get_speed()
		"luck": return get_luck()
		"stealth": return get_stealth()
		_: 
			push_warning("Unknown stat: %s" % stat_name)
			return 0


## Get base value for a stat
func get_base_stat(stat_name: String) -> int:
	match stat_name:
		"health": return base_health
		"attack": return base_attack
		"defense": return base_defense
		"speed": return base_speed
		"luck": return base_luck
		"stealth": return base_stealth
		_: return 0


## Get allocated value for a stat
func get_allocated_stat(stat_name: String) -> int:
	match stat_name:
		"health": return allocated_health
		"attack": return allocated_attack
		"defense": return allocated_defense
		"speed": return allocated_speed
		"luck": return allocated_luck
		"stealth": return allocated_stealth
		_: return 0


# ==============================================================================
# STAT POINT ALLOCATION
# ==============================================================================

## Allocate a stat point to a specific stat
func allocate_point(stat_name: String) -> bool:
	if available_stat_points <= 0:
		push_warning("No stat points available")
		return false
	
	var old_value = get_stat(stat_name)
	
	match stat_name:
		"health":
			allocated_health += 1
		"attack":
			allocated_attack += 1
		"defense":
			allocated_defense += 1
		"speed":
			allocated_speed += 1
		"luck":
			allocated_luck += 1
		"stealth":
			allocated_stealth += 1
		_:
			push_warning("Unknown stat: %s" % stat_name)
			return false
	
	available_stat_points -= 1
	stat_changed.emit(stat_name, old_value, get_stat(stat_name))
	return true


## Reset all allocated points (refund them)
func reset_allocated_points() -> void:
	var total_allocated = allocated_health + allocated_attack + allocated_defense
	total_allocated += allocated_speed + allocated_luck + allocated_stealth
	
	allocated_health = 0
	allocated_attack = 0
	allocated_defense = 0
	allocated_speed = 0
	allocated_luck = 0
	allocated_stealth = 0
	
	available_stat_points += total_allocated


# ==============================================================================
# EXP AND LEVELING
# ==============================================================================

## Add experience points
func add_exp(amount: int) -> void:
	if level >= MAX_LEVEL:
		return
	
	current_exp += amount
	exp_gained.emit(amount, current_exp)
	
	# Check for level up
	while level < MAX_LEVEL and current_exp >= get_exp_for_next_level():
		_level_up()


## Get EXP needed for next level
func get_exp_for_next_level() -> int:
	if level >= MAX_LEVEL:
		return 999999
	return LEVEL_EXP_TABLE[level]


## Get EXP progress as percentage (0.0 to 1.0)
func get_level_progress() -> float:
	if level >= MAX_LEVEL:
		return 1.0
	
	var prev_level_exp = LEVEL_EXP_TABLE[level - 1] if level > 1 else 0
	var next_level_exp = LEVEL_EXP_TABLE[level]
	var exp_in_level = current_exp - prev_level_exp
	var exp_needed = next_level_exp - prev_level_exp
	
	return clampf(float(exp_in_level) / float(exp_needed), 0.0, 1.0)


## Handle level up
func _level_up() -> void:
	level += 1
	available_stat_points += STAT_POINTS_PER_LEVEL
	level_up.emit(level)


# ==============================================================================
# BONUS STAT MANAGEMENT
# ==============================================================================

## Set a bonus stat (from equipment, skills, buffs)
func set_bonus(stat_name: String, value: int) -> void:
	var old_value = get_stat(stat_name)
	
	match stat_name:
		"health": bonus_health = value
		"attack": bonus_attack = value
		"defense": bonus_defense = value
		"speed": bonus_speed = value
		"luck": bonus_luck = value
		"stealth": bonus_stealth = value
		_:
			push_warning("Unknown stat: %s" % stat_name)
			return
	
	stat_changed.emit(stat_name, old_value, get_stat(stat_name))


## Add to a bonus stat
func add_bonus(stat_name: String, value: int) -> void:
	match stat_name:
		"health": set_bonus("health", bonus_health + value)
		"attack": set_bonus("attack", bonus_attack + value)
		"defense": set_bonus("defense", bonus_defense + value)
		"speed": set_bonus("speed", bonus_speed + value)
		"luck": set_bonus("luck", bonus_luck + value)
		"stealth": set_bonus("stealth", bonus_stealth + value)


## Clear all bonuses
func clear_all_bonuses() -> void:
	bonus_health = 0
	bonus_attack = 0
	bonus_defense = 0
	bonus_speed = 0
	bonus_luck = 0
	bonus_stealth = 0


# ==============================================================================
# SERIALIZATION
# ==============================================================================

## Convert stats to dictionary for saving
func to_dict() -> Dictionary:
	return {
		"level": level,
		"current_exp": current_exp,
		"available_stat_points": available_stat_points,
		"allocated": {
			"health": allocated_health,
			"attack": allocated_attack,
			"defense": allocated_defense,
			"speed": allocated_speed,
			"luck": allocated_luck,
			"stealth": allocated_stealth
		}
	}


## Load stats from dictionary
func from_dict(data: Dictionary) -> void:
	level = data.get("level", 1)
	current_exp = data.get("current_exp", 0)
	available_stat_points = data.get("available_stat_points", 0)
	
	var allocated = data.get("allocated", {})
	allocated_health = allocated.get("health", 0)
	allocated_attack = allocated.get("attack", 0)
	allocated_defense = allocated.get("defense", 0)
	allocated_speed = allocated.get("speed", 0)
	allocated_luck = allocated.get("luck", 0)
	allocated_stealth = allocated.get("stealth", 0)
