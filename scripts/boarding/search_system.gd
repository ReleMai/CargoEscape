# ==============================================================================
# SEARCH SYSTEM - HANDLES CONTAINER SEARCHING WITH PROGRESS AND INTERRUPTS
# ==============================================================================
#
# FILE: scripts/boarding/search_system.gd
# PURPOSE: Manages the search progress when player searches containers
#
# FEATURES:
# - Per-item search timers based on rarity
# - Container type modifies search speed
# - Movement interrupts search (progress lost)
# - Visual progress feedback
# - Sound cues for search states
#
# ==============================================================================

class_name SearchSystem
extends RefCounted


# ==============================================================================
# CONSTANTS
# ==============================================================================

## Base search times by rarity (seconds)
const BASE_SEARCH_TIMES := {
	0: 0.8,   # Common - quick grab
	1: 1.2,   # Uncommon - brief search
	2: 2.0,   # Rare - careful examination
	3: 3.5,   # Epic - hidden compartment
	4: 5.0    # Legendary - security bypass
}

## Search time variation (±percentage)
const SEARCH_TIME_VARIANCE := 0.15

## Minimum search time regardless of modifiers
const MIN_SEARCH_TIME := 0.3

## Maximum search time regardless of modifiers
const MAX_SEARCH_TIME := 10.0


# ==============================================================================
# SEARCH TIME CALCULATION
# ==============================================================================

## Calculate search time for an item
## Takes into account: base rarity time, item size, container modifier
static func calculate_search_time(
	item: Resource,  # ItemData
	container_search_modifier: float = 1.0
) -> float:
	if not item:
		return 1.0
	
	# Get base time from rarity
	var rarity: int = item.get("rarity") if item.get("rarity") != null else 0
	var base_time: float = BASE_SEARCH_TIMES.get(rarity, 1.0)
	
	# Apply item's own search time if it has one
	if item.has_method("get_search_time"):
		base_time = item.get_search_time()
	elif item.get("base_search_time") != null and item.base_search_time > 0:
		base_time = item.base_search_time
	
	# Apply container modifier
	var modified_time = base_time * container_search_modifier
	
	# Add random variance
	var variance = modified_time * SEARCH_TIME_VARIANCE
	modified_time += randf_range(-variance, variance)
	
	# Clamp to reasonable bounds
	return clampf(modified_time, MIN_SEARCH_TIME, MAX_SEARCH_TIME)


## Get display text for search time
static func get_search_time_text(seconds: float) -> String:
	if seconds < 1.0:
		return "%.1fs" % seconds
	else:
		return "%.1fs" % seconds
