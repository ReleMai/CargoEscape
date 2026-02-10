# ==============================================================================
# SKILL DATA RESOURCE
# ==============================================================================
#
# FILE: scripts/player/skill_data.gd
# PURPOSE: Defines individual skills for the skill tree
#
# SKILL TYPES:
# - Combat: Attack, critical, damage bonuses
# - Defense: Health, armor, resistance bonuses
# - Stealth: Detection, movement, surprise bonuses
# - Utility: Luck, speed, resource bonuses
#
# ==============================================================================

extends Resource
class_name SkillData


# ==============================================================================
# ENUMS
# ==============================================================================

enum SkillCategory {
	COMBAT = 0,
	DEFENSE = 1,
	STEALTH = 2,
	UTILITY = 3
}


# ==============================================================================
# PROPERTIES
# ==============================================================================

@export_group("Basic Info")
## Unique identifier
@export var id: String = "skill_unknown"

## Display name
@export var name: String = "Unknown Skill"

## Description
@export_multiline var description: String = "A mysterious ability."

## Skill category
@export var category: SkillCategory = SkillCategory.UTILITY

## Icon texture
@export var icon: Texture2D

@export_group("Upgrade Info")
## Current level (0 = not unlocked)
@export var current_level: int = 0

## Maximum level
@export var max_level: int = 5

## Skill points cost per level (index = level to unlock)
@export var point_costs: Array[int] = [1, 1, 2, 2, 3]

## Required skills to unlock (skill IDs)
@export var prerequisites: Array[String] = []

## Minimum player level to unlock
@export var required_player_level: int = 1

@export_group("Effects Per Level")
## Stat bonus per level (stat_name -> bonus per level)
@export var stat_bonuses_per_level: Dictionary = {}

## Percentage bonuses per level (e.g., "crit_chance" -> 0.02)
@export var percentage_bonuses_per_level: Dictionary = {}

## Special ability unlocked at max level
@export var max_level_ability: String = ""


# ==============================================================================
# METHODS
# ==============================================================================

## Get total stat bonus at current level
func get_stat_bonus(stat_name: String) -> int:
	var per_level = stat_bonuses_per_level.get(stat_name, 0)
	return per_level * current_level


## Get total percentage bonus at current level
func get_percentage_bonus(bonus_name: String) -> float:
	var per_level = percentage_bonuses_per_level.get(bonus_name, 0.0)
	return per_level * current_level


## Get cost to upgrade to next level
func get_next_level_cost() -> int:
	if current_level >= max_level:
		return 0
	if current_level >= point_costs.size():
		return point_costs[-1]  # Use last cost for overflow
	return point_costs[current_level]


## Check if skill can be upgraded
func can_upgrade(available_points: int, player_level: int, unlocked_skills: Array) -> bool:
	if current_level >= max_level:
		return false
	
	if available_points < get_next_level_cost():
		return false
	
	if player_level < required_player_level:
		return false
	
	# Check prerequisites
	for prereq in prerequisites:
		if not prereq in unlocked_skills:
			return false
	
	return true


## Upgrade the skill
func upgrade() -> bool:
	if current_level >= max_level:
		return false
	
	current_level += 1
	return true


## Check if max level ability is unlocked
func has_max_level_ability() -> bool:
	return current_level >= max_level and not max_level_ability.is_empty()
