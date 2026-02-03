# ==============================================================================
# ACHIEVEMENT MANAGER (AUTOLOAD/SINGLETON)
# ==============================================================================
#
# FILE: scripts/achievement_manager.gd
# PURPOSE: Tracks achievement progress and unlocks
#
# USAGE FROM OTHER SCRIPTS:
# -------------------------
# # Check if unlocked:
# var unlocked = AchievementManager.is_achievement_unlocked("first_haul")
#
# # Trigger achievement check:
# AchievementManager.on_boarding_completed(time_taken)
# AchievementManager.on_credits_earned(amount)
#
# ==============================================================================

extends Node
class_name AchievementManagerClass


# ==============================================================================
# SIGNALS
# ==============================================================================

## Emitted when an achievement is unlocked
signal achievement_unlocked(achievement: AchievementData)

## Emitted when stats change
signal stats_updated


# ==============================================================================
# CONSTANTS
# ==============================================================================

const SAVE_FILE_PATH = "user://achievements.save"


# ==============================================================================
# ACHIEVEMENT DEFINITIONS
# ==============================================================================

var achievements: Dictionary = {}  # id -> AchievementData


# ==============================================================================
# PERSISTENT STATS
# ==============================================================================

var stats: Dictionary = {
	"boardings_completed": 0,
	"total_credits_earned": 0,
	"legendary_items_found": 0,
	"fastest_boarding_time": 999999.0,
	"factions_boarded": [],  # Array of faction codes (CCG, NEX, etc.)
	"current_containers_searched": 0,  # Reset per boarding
	"current_total_containers": 0,  # Reset per boarding
}


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_define_achievements()
	load_achievements()
	print("[AchievementManager] Initialized with %d achievements" % achievements.size())


# ==============================================================================
# ACHIEVEMENT DEFINITIONS
# ==============================================================================

func _define_achievements() -> void:
	# First Haul - Complete first boarding
	var first_haul = AchievementData.new()
	first_haul.id = "first_haul"
	first_haul.title = "First Haul"
	first_haul.description = "Complete your first boarding"
	first_haul.achievement_type = 0  # FirstBoarding
	first_haul.required_value = 1.0
	first_haul.tier = 0  # Bronze
	achievements["first_haul"] = first_haul
	
	# Big Spender - Earn 10,000 credits
	var big_spender = AchievementData.new()
	big_spender.id = "big_spender"
	big_spender.title = "Big Spender"
	big_spender.description = "Earn 10,000 total credits"
	big_spender.achievement_type = 1  # CreditsMilestone
	big_spender.required_value = 10000.0
	big_spender.tier = 1  # Silver
	achievements["big_spender"] = big_spender
	
	# Lucky Find - Find legendary item
	var lucky_find = AchievementData.new()
	lucky_find.id = "lucky_find"
	lucky_find.title = "Lucky Find"
	lucky_find.description = "Find a legendary item"
	lucky_find.achievement_type = 2  # LegendaryItem
	lucky_find.required_value = 1.0
	lucky_find.tier = 2  # Gold
	achievements["lucky_find"] = lucky_find
	
	# Speed Runner - Complete boarding in under 60s
	var speed_runner = AchievementData.new()
	speed_runner.id = "speed_runner"
	speed_runner.title = "Speed Runner"
	speed_runner.description = "Complete a boarding in under 60 seconds"
	speed_runner.achievement_type = 3  # SpeedRun
	speed_runner.required_value = 60.0
	speed_runner.tier = 1  # Silver
	achievements["speed_runner"] = speed_runner
	
	# Completionist - Search every container on a ship
	var completionist = AchievementData.new()
	completionist.id = "completionist"
	completionist.title = "Completionist"
	completionist.description = "Search every container on a ship"
	completionist.achievement_type = 4  # Completionist
	completionist.required_value = 1.0
	completionist.tier = 1  # Silver
	achievements["completionist"] = completionist
	
	# Faction Hunter - Board ships from all factions
	var faction_hunter = AchievementData.new()
	faction_hunter.id = "faction_hunter"
	faction_hunter.title = "Faction Hunter"
	faction_hunter.description = "Board ships from all 5 factions"
	faction_hunter.achievement_type = 5  # FactionHunter
	faction_hunter.required_value = 5.0  # All 5 factions
	faction_hunter.tier = 2  # Gold
	achievements["faction_hunter"] = faction_hunter


# ==============================================================================
# PUBLIC API - Event Tracking
# ==============================================================================

## Call when boarding starts
func on_boarding_started(total_containers: int) -> void:
	stats["current_containers_searched"] = 0
	stats["current_total_containers"] = total_containers
	stats_updated.emit()


## Call when a container is searched
func on_container_searched() -> void:
	stats["current_containers_searched"] += 1
	stats_updated.emit()


## Call when boarding completes successfully
func on_boarding_completed(time_taken: float, faction_code: String = "") -> void:
	stats["boardings_completed"] += 1
	
	# Track fastest time
	if time_taken < stats["fastest_boarding_time"]:
		stats["fastest_boarding_time"] = time_taken
	
	# Track faction
	if faction_code != "" and not stats["factions_boarded"].has(faction_code):
		stats["factions_boarded"].append(faction_code)
	
	stats_updated.emit()
	
	# Check achievements
	_check_achievement("first_haul", stats["boardings_completed"])
	_check_achievement("speed_runner", time_taken)
	_check_achievement("faction_hunter", stats["factions_boarded"].size())
	
	# Check completionist (if all containers searched)
	if stats["current_total_containers"] > 0:
		if stats["current_containers_searched"] >= stats["current_total_containers"]:
			_check_achievement("completionist", 1.0)
	
	save_achievements()


## Call when credits are earned
func on_credits_earned(amount: int) -> void:
	stats["total_credits_earned"] += amount
	stats_updated.emit()
	_check_achievement("big_spender", stats["total_credits_earned"])
	save_achievements()


## Call when a legendary item is found
func on_legendary_item_found() -> void:
	stats["legendary_items_found"] += 1
	stats_updated.emit()
	_check_achievement("lucky_find", stats["legendary_items_found"])
	save_achievements()


# ==============================================================================
# ACHIEVEMENT CHECKING
# ==============================================================================

func _check_achievement(achievement_id: String, current_value: float) -> void:
	var achievement = achievements.get(achievement_id)
	if not achievement:
		return
	
	if achievement.is_unlocked:
		return  # Already unlocked
	
	# Check if condition is met
	var unlocked = false
	
	match achievement.achievement_type:
		0, 1, 2, 4, 5:  # FirstBoarding, CreditsMilestone, LegendaryItem, Completionist, FactionHunter
			unlocked = current_value >= achievement.required_value
		3:  # SpeedRun (lower is better)
			unlocked = current_value <= achievement.required_value
	
	if unlocked:
		_unlock_achievement(achievement)


func _unlock_achievement(achievement: AchievementData) -> void:
	if achievement.is_unlocked:
		return
	
	achievement.is_unlocked = true
	achievement.unlock_timestamp = int(Time.get_unix_time_from_system())
	
	# Play achievement unlock sound
	AudioManager.play_sfx("achievement_unlock")
	
	print("[AchievementManager] Achievement unlocked: %s" % achievement.title)
	achievement_unlocked.emit(achievement)
	save_achievements()


# ==============================================================================
# QUERY API
# ==============================================================================

## Check if an achievement is unlocked
func is_achievement_unlocked(achievement_id: String) -> bool:
	var achievement = achievements.get(achievement_id)
	return achievement and achievement.is_unlocked


## Get all achievements
func get_all_achievements() -> Array:
	return achievements.values()


## Get unlocked achievements count
func get_unlocked_count() -> int:
	var count = 0
	for achievement in achievements.values():
		if achievement.is_unlocked:
			count += 1
	return count


## Get total achievements count
func get_total_count() -> int:
	return achievements.size()


## Get completion percentage
func get_completion_percentage() -> float:
	if achievements.is_empty():
		return 0.0
	return (float(get_unlocked_count()) / float(get_total_count())) * 100.0


## Get stat value
func get_stat(stat_name: String) -> Variant:
	return stats.get(stat_name, 0)


# ==============================================================================
# SAVE/LOAD
# ==============================================================================

func save_achievements() -> void:
	var save_data = {
		"achievements": {},
		"stats": stats
	}
	
	# Save achievement unlock states
	for id in achievements.keys():
		var achievement = achievements[id]
		save_data["achievements"][id] = {
			"is_unlocked": achievement.is_unlocked,
			"unlock_timestamp": achievement.unlock_timestamp
		}
	
	# Write to file
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data, "\t")
		file.store_string(json_string)
		file.close()
		print("[AchievementManager] Saved to: %s" % SAVE_FILE_PATH)
	else:
		push_error("[AchievementManager] Failed to save achievements")


func load_achievements() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[AchievementManager] No save file found, starting fresh")
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("[AchievementManager] Failed to open save file")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("[AchievementManager] Failed to parse save file")
		return
	
	var save_data = json.data
	
	# Restore stats
	if save_data.has("stats"):
		for key in save_data["stats"].keys():
			stats[key] = save_data["stats"][key]
	
	# Restore achievement unlock states
	if save_data.has("achievements"):
		for id in save_data["achievements"].keys():
			if achievements.has(id):
				var achievement = achievements[id]
				var saved = save_data["achievements"][id]
				achievement.is_unlocked = saved.get("is_unlocked", false)
				achievement.unlock_timestamp = saved.get("unlock_timestamp", 0)
	
	print("[AchievementManager] Loaded %d unlocked achievements" % get_unlocked_count())


## Reset all achievements (for debugging)
func reset_all() -> void:
	for achievement in achievements.values():
		achievement.is_unlocked = false
		achievement.unlock_timestamp = 0
	
	stats = {
		"boardings_completed": 0,
		"total_credits_earned": 0,
		"legendary_items_found": 0,
		"fastest_boarding_time": 999999.0,
		"factions_boarded": [],
		"current_containers_searched": 0,
		"current_total_containers": 0,
	}
	
	save_achievements()
	print("[AchievementManager] All achievements reset")
