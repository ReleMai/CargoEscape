# ==============================================================================
# ACHIEVEMENT DATA RESOURCE
# ==============================================================================
#
# FILE: scripts/data/achievement_data.gd
# PURPOSE: Defines the data structure for achievements/trophies
#
# ==============================================================================

extends Resource
class_name AchievementData


# ==============================================================================
# ACHIEVEMENT PROPERTIES
# ==============================================================================

@export_group("Basic Info")
## Unique identifier for this achievement
@export var id: String = "achievement_unknown"

## Display name shown to player
@export var title: String = "Unknown Achievement"

## Description of how to unlock
@export_multiline var description: String = "Complete a secret task."

@export_group("Unlock Condition")
## Type of achievement for tracking logic
## 0=FirstBoarding, 1=CreditsMilestone, 2=LegendaryItem, 3=SpeedRun, 4=Completionist, 5=FactionHunter
@export_enum("FirstBoarding", "CreditsMilestone", "LegendaryItem", "SpeedRun", "Completionist", "FactionHunter") var achievement_type: int = 0

## Required value for unlock (e.g., 10000 credits, 60 seconds)
@export var required_value: float = 0.0

@export_group("Visuals")
## Icon for locked state
@export var icon_locked: Texture2D

## Icon for unlocked state
@export var icon_unlocked: Texture2D

## Rarity/importance (affects visual effects)
## 0=Bronze, 1=Silver, 2=Gold, 3=Platinum
@export_range(0, 3) var tier: int = 0


# ==============================================================================
# STATE (runtime, not saved in resource)
# ==============================================================================

## Whether this achievement has been unlocked
var is_unlocked: bool = false

## When it was unlocked (Unix timestamp)
var unlock_timestamp: int = 0


# ==============================================================================
# METHODS
# ==============================================================================

## Get tier name as string
func get_tier_name() -> String:
	match tier:
		0: return "Bronze"
		1: return "Silver"
		2: return "Gold"
		3: return "Platinum"
		_: return "Unknown"


## Get tier color
func get_tier_color() -> Color:
	match tier:
		0: return Color(0.8, 0.5, 0.2)      # Bronze
		1: return Color(0.75, 0.75, 0.75)   # Silver
		2: return Color(1.0, 0.84, 0.0)     # Gold
		3: return Color(0.9, 1.0, 1.0)      # Platinum
		_: return Color.WHITE


## Get type name as string
func get_type_name() -> String:
	match achievement_type:
		0: return "FirstBoarding"
		1: return "CreditsMilestone"
		2: return "LegendaryItem"
		3: return "SpeedRun"
		4: return "Completionist"
		5: return "FactionHunter"
		_: return "Unknown"
