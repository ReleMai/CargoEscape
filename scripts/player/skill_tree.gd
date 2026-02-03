# ==============================================================================
# SKILL TREE MANAGER
# ==============================================================================
#
# FILE: scripts/player/skill_tree.gd
# PURPOSE: Manages player skill progression and unlocks
#
# SKILL CATEGORIES:
# - Combat (Red): Damage, crit, weapon bonuses
# - Defense (Blue): Health, armor, resistance
# - Stealth (Green): Detection, movement, surprise
# - Utility (Yellow): Luck, loot, resource bonuses
#
# ==============================================================================

extends Node
class_name SkillTree


# ==============================================================================
# SIGNALS
# ==============================================================================

signal skill_unlocked(skill_id: String, new_level: int)
signal skill_points_changed(available: int)


# ==============================================================================
# SKILL DEFINITIONS
# ==============================================================================

const SKILL_DEFINITIONS = {
	# ============ COMBAT SKILLS ============
	"combat_power": {
		"name": "Power Strike",
		"description": "Increase base attack damage.",
		"category": 0,  # COMBAT
		"max_level": 5,
		"costs": [1, 1, 2, 2, 3],
		"stat_bonuses": {"attack": 2},
		"percent_bonuses": {},
		"prerequisites": [],
		"req_level": 1
	},
	"combat_precision": {
		"name": "Precision",
		"description": "Improve critical hit chance.",
		"category": 0,
		"max_level": 5,
		"costs": [1, 1, 2, 2, 3],
		"stat_bonuses": {},
		"percent_bonuses": {"crit_chance": 0.02},
		"prerequisites": [],
		"req_level": 1
	},
	"combat_critical": {
		"name": "Deadly Force",
		"description": "Increase critical hit damage.",
		"category": 0,
		"max_level": 3,
		"costs": [2, 2, 3],
		"stat_bonuses": {},
		"percent_bonuses": {"crit_damage": 0.15},
		"prerequisites": ["combat_precision"],
		"req_level": 3
	},
	"combat_rapidfire": {
		"name": "Rapid Fire",
		"description": "Increase attack speed with ranged weapons.",
		"category": 0,
		"max_level": 3,
		"costs": [2, 2, 3],
		"stat_bonuses": {},
		"percent_bonuses": {"fire_rate": 0.08},
		"prerequisites": ["combat_power"],
		"req_level": 5
	},
	"combat_executioner": {
		"name": "Executioner",
		"description": "Deal bonus damage to low-health enemies.",
		"category": 0,
		"max_level": 1,
		"costs": [5],
		"stat_bonuses": {"attack": 5},
		"percent_bonuses": {"execute_damage": 0.25},
		"prerequisites": ["combat_critical", "combat_rapidfire"],
		"req_level": 10,
		"ability": "execute"
	},

	# ============ DEFENSE SKILLS ============
	"defense_vitality": {
		"name": "Vitality",
		"description": "Increase maximum health.",
		"category": 1,  # DEFENSE
		"max_level": 5,
		"costs": [1, 1, 2, 2, 3],
		"stat_bonuses": {"health": 10},
		"percent_bonuses": {},
		"prerequisites": [],
		"req_level": 1
	},
	"defense_toughness": {
		"name": "Toughness",
		"description": "Increase defense rating.",
		"category": 1,
		"max_level": 5,
		"costs": [1, 1, 2, 2, 3],
		"stat_bonuses": {"defense": 2},
		"percent_bonuses": {},
		"prerequisites": [],
		"req_level": 1
	},
	"defense_resistance": {
		"name": "Damage Resistance",
		"description": "Reduce incoming damage.",
		"category": 1,
		"max_level": 3,
		"costs": [2, 2, 3],
		"stat_bonuses": {},
		"percent_bonuses": {"damage_resist": 0.05},
		"prerequisites": ["defense_toughness"],
		"req_level": 3
	},
	"defense_regeneration": {
		"name": "Regeneration",
		"description": "Slowly recover health over time.",
		"category": 1,
		"max_level": 3,
		"costs": [2, 3, 4],
		"stat_bonuses": {},
		"percent_bonuses": {"health_regen": 0.01},
		"prerequisites": ["defense_vitality"],
		"req_level": 5
	},
	"defense_laststand": {
		"name": "Last Stand",
		"description": "Survive a killing blow once per mission.",
		"category": 1,
		"max_level": 1,
		"costs": [5],
		"stat_bonuses": {"health": 25},
		"percent_bonuses": {},
		"prerequisites": ["defense_resistance", "defense_regeneration"],
		"req_level": 10,
		"ability": "last_stand"
	},

	# ============ STEALTH SKILLS ============
	"stealth_shadow": {
		"name": "Shadow Walker",
		"description": "Reduce detection by enemies.",
		"category": 2,  # STEALTH
		"max_level": 5,
		"costs": [1, 1, 2, 2, 3],
		"stat_bonuses": {"stealth": 3},
		"percent_bonuses": {},
		"prerequisites": [],
		"req_level": 1
	},
	"stealth_silent": {
		"name": "Silent Steps",
		"description": "Reduce noise when moving.",
		"category": 2,
		"max_level": 3,
		"costs": [1, 2, 3],
		"stat_bonuses": {},
		"percent_bonuses": {"noise_reduction": 0.15},
		"prerequisites": ["stealth_shadow"],
		"req_level": 2
	},
	"stealth_ambush": {
		"name": "Ambush",
		"description": "Bonus damage when attacking unaware enemies.",
		"category": 2,
		"max_level": 3,
		"costs": [2, 2, 3],
		"stat_bonuses": {},
		"percent_bonuses": {"ambush_damage": 0.20},
		"prerequisites": ["stealth_shadow"],
		"req_level": 4
	},
	"stealth_pickpocket": {
		"name": "Pickpocket",
		"description": "Chance to steal items from enemies.",
		"category": 2,
		"max_level": 3,
		"costs": [2, 2, 3],
		"stat_bonuses": {"luck": 2},
		"percent_bonuses": {"steal_chance": 0.05},
		"prerequisites": ["stealth_silent"],
		"req_level": 6
	},
	"stealth_ghost": {
		"name": "Ghost",
		"description": "Brief invisibility when entering stealth.",
		"category": 2,
		"max_level": 1,
		"costs": [5],
		"stat_bonuses": {"stealth": 10},
		"percent_bonuses": {},
		"prerequisites": ["stealth_ambush", "stealth_pickpocket"],
		"req_level": 10,
		"ability": "ghost_cloak"
	},

	# ============ UTILITY SKILLS ============
	"utility_fortune": {
		"name": "Fortune",
		"description": "Increase luck for better loot.",
		"category": 3,  # UTILITY
		"max_level": 5,
		"costs": [1, 1, 2, 2, 3],
		"stat_bonuses": {"luck": 2},
		"percent_bonuses": {},
		"prerequisites": [],
		"req_level": 1
	},
	"utility_agility": {
		"name": "Agility",
		"description": "Increase movement speed.",
		"category": 3,
		"max_level": 5,
		"costs": [1, 1, 2, 2, 3],
		"stat_bonuses": {"speed": 2},
		"percent_bonuses": {},
		"prerequisites": [],
		"req_level": 1
	},
	"utility_haggler": {
		"name": "Haggler",
		"description": "Better prices when trading.",
		"category": 3,
		"max_level": 3,
		"costs": [1, 2, 3],
		"stat_bonuses": {},
		"percent_bonuses": {"trade_bonus": 0.10},
		"prerequisites": ["utility_fortune"],
		"req_level": 3
	},
	"utility_scavenger": {
		"name": "Scavenger",
		"description": "Find more items in containers.",
		"category": 3,
		"max_level": 3,
		"costs": [2, 2, 3],
		"stat_bonuses": {},
		"percent_bonuses": {"extra_loot": 0.10},
		"prerequisites": ["utility_fortune"],
		"req_level": 5
	},
	"utility_exp_master": {
		"name": "Fast Learner",
		"description": "Gain bonus experience from all sources.",
		"category": 3,
		"max_level": 3,
		"costs": [2, 3, 4],
		"stat_bonuses": {},
		"percent_bonuses": {"exp_bonus": 0.10},
		"prerequisites": ["utility_agility"],
		"req_level": 4
	},
	"utility_jackpot": {
		"name": "Jackpot",
		"description": "Rare chance to double all loot from a container.",
		"category": 3,
		"max_level": 1,
		"costs": [5],
		"stat_bonuses": {"luck": 10},
		"percent_bonuses": {"jackpot_chance": 0.05},
		"prerequisites": ["utility_scavenger", "utility_haggler"],
		"req_level": 10,
		"ability": "jackpot"
	}
}


# ==============================================================================
# STATE
# ==============================================================================

## Current skill levels (skill_id -> level)
var skill_levels: Dictionary = {}

## Available skill points
var available_points: int = 0

## Reference to player stats
var player_stats: PlayerStats


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _ready() -> void:
	# Initialize all skills at level 0
	for skill_id in SKILL_DEFINITIONS:
		skill_levels[skill_id] = 0


## Set player stats reference
func set_player_stats(stats: PlayerStats) -> void:
	player_stats = stats
	
	# Connect to level up signal
	if player_stats:
		player_stats.level_up.connect(_on_level_up)


## Called when player levels up
func _on_level_up(new_level: int) -> void:
	# Grant skill points based on level
	# 1 point per level, bonus point every 5 levels
	add_skill_points(1)
	if new_level % 5 == 0:
		add_skill_points(1)


# ==============================================================================
# SKILL POINT MANAGEMENT
# ==============================================================================

## Add skill points
func add_skill_points(amount: int) -> void:
	available_points += amount
	skill_points_changed.emit(available_points)


## Get available skill points
func get_available_points() -> int:
	return available_points


# ==============================================================================
# SKILL UNLOCKING
# ==============================================================================

## Check if a skill can be unlocked/upgraded
func can_unlock_skill(skill_id: String) -> bool:
	if not SKILL_DEFINITIONS.has(skill_id):
		return false
	
	var skill_def = SKILL_DEFINITIONS[skill_id]
	var current_level = skill_levels.get(skill_id, 0)
	var max_level = skill_def.get("max_level", 5)
	
	# Check if already maxed
	if current_level >= max_level:
		return false
	
	# Check skill points
	var costs = skill_def.get("costs", [1])
	var cost = costs[mini(current_level, costs.size() - 1)]
	if available_points < cost:
		return false
	
	# Check player level requirement
	if player_stats:
		var req_level = skill_def.get("req_level", 1)
		if player_stats.level < req_level:
			return false
	
	# Check prerequisites
	var prereqs = skill_def.get("prerequisites", [])
	for prereq in prereqs:
		if skill_levels.get(prereq, 0) <= 0:
			return false
	
	return true


## Unlock or upgrade a skill
func unlock_skill(skill_id: String) -> bool:
	if not can_unlock_skill(skill_id):
		return false
	
	var skill_def = SKILL_DEFINITIONS[skill_id]
	var current_level = skill_levels.get(skill_id, 0)
	
	# Spend points
	var costs = skill_def.get("costs", [1])
	var cost = costs[mini(current_level, costs.size() - 1)]
	available_points -= cost
	
	# Increase level
	skill_levels[skill_id] = current_level + 1
	
	# Apply stat bonuses to player
	_apply_skill_bonuses(skill_id)
	
	# Emit signals
	skill_unlocked.emit(skill_id, skill_levels[skill_id])
	skill_points_changed.emit(available_points)
	
	return true


## Apply stat bonuses from a skill to player stats
func _apply_skill_bonuses(skill_id: String) -> void:
	if not player_stats:
		return
	
	var skill_def = SKILL_DEFINITIONS.get(skill_id, {})
	var stat_bonuses = skill_def.get("stat_bonuses", {})
	
	# Add stat bonuses (per level)
	for stat in stat_bonuses:
		player_stats.add_bonus(stat, stat_bonuses[stat])


# ==============================================================================
# SKILL QUERIES
# ==============================================================================

## Get skill level
func get_skill_level(skill_id: String) -> int:
	return skill_levels.get(skill_id, 0)


## Get skill max level
func get_skill_max_level(skill_id: String) -> int:
	var skill_def = SKILL_DEFINITIONS.get(skill_id, {})
	return skill_def.get("max_level", 5)


## Check if skill is maxed
func is_skill_maxed(skill_id: String) -> bool:
	return get_skill_level(skill_id) >= get_skill_max_level(skill_id)


## Get skill definition
func get_skill_definition(skill_id: String) -> Dictionary:
	return SKILL_DEFINITIONS.get(skill_id, {})


## Get all skills in a category
func get_skills_by_category(category: int) -> Array:
	var result = []
	for skill_id in SKILL_DEFINITIONS:
		if SKILL_DEFINITIONS[skill_id].get("category", -1) == category:
			result.append(skill_id)
	return result


## Get total stat bonus from all skills
func get_total_skill_bonus(stat_name: String) -> int:
	var total = 0
	for skill_id in skill_levels:
		var level = skill_levels[skill_id]
		if level > 0:
			var skill_def = SKILL_DEFINITIONS.get(skill_id, {})
			var bonuses = skill_def.get("stat_bonuses", {})
			total += bonuses.get(stat_name, 0) * level
	return total


## Get total percentage bonus from all skills
func get_total_percent_bonus(bonus_name: String) -> float:
	var total = 0.0
	for skill_id in skill_levels:
		var level = skill_levels[skill_id]
		if level > 0:
			var skill_def = SKILL_DEFINITIONS.get(skill_id, {})
			var bonuses = skill_def.get("percent_bonuses", {})
			total += bonuses.get(bonus_name, 0.0) * level
	return total


## Check if player has an ability from skills
func has_ability(ability_name: String) -> bool:
	for skill_id in skill_levels:
		if is_skill_maxed(skill_id):
			var skill_def = SKILL_DEFINITIONS.get(skill_id, {})
			if skill_def.get("ability", "") == ability_name:
				return true
	return false


## Get unlocked abilities
func get_unlocked_abilities() -> Array:
	var abilities = []
	for skill_id in skill_levels:
		if is_skill_maxed(skill_id):
			var skill_def = SKILL_DEFINITIONS.get(skill_id, {})
			var ability = skill_def.get("ability", "")
			if not ability.is_empty():
				abilities.append(ability)
	return abilities


# ==============================================================================
# SERIALIZATION
# ==============================================================================

## Convert to dictionary for saving
func to_dict() -> Dictionary:
	return {
		"skill_levels": skill_levels.duplicate(),
		"available_points": available_points
	}


## Load from dictionary
func from_dict(data: Dictionary) -> void:
	skill_levels = data.get("skill_levels", {})
	available_points = data.get("available_points", 0)
	
	# Ensure all skills exist
	for skill_id in SKILL_DEFINITIONS:
		if not skill_levels.has(skill_id):
			skill_levels[skill_id] = 0
	
	# Reapply all bonuses
	if player_stats:
		player_stats.clear_all_bonuses()
		for skill_id in skill_levels:
			var level = skill_levels[skill_id]
			for i in range(level):
				_apply_skill_bonuses(skill_id)
