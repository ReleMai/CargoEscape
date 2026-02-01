# ==============================================================================
# ACHIEVEMENT GALLERY - UI SCREEN
# ==============================================================================
#
# FILE: scripts/ui/achievement_gallery.gd
# PURPOSE: Shows all achievements and their unlock status
#
# ==============================================================================

extends Control
class_name AchievementGallery


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var achievement_list: VBoxContainer = %AchievementList
@onready var stats_label: Label = %StatsLabel
@onready var close_button: Button = %CloseButton
@onready var completion_label: Label = %CompletionLabel


# ==============================================================================
# PRELOADS
# ==============================================================================

const AchievementItem = preload("res://scenes/ui/achievement_item.tscn")


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	
	_populate_achievements()
	_update_stats()


# ==============================================================================
# POPULATION
# ==============================================================================

func _populate_achievements() -> void:
	if not achievement_list:
		return
	
	# Clear existing items
	for child in achievement_list.get_children():
		child.queue_free()
	
	# Get all achievements
	var achievements = AchievementManager.get_all_achievements()
	
	# Sort by tier (highest first) then by unlock status
	achievements.sort_custom(func(a, b):
		if a.tier != b.tier:
			return a.tier > b.tier
		if a.is_unlocked != b.is_unlocked:
			return a.is_unlocked
		return a.title < b.title
	)
	
	# Create UI items
	for achievement in achievements:
		var item = AchievementItem.instantiate()
		achievement_list.add_child(item)
		item.set_achievement(achievement)


func _update_stats() -> void:
	# Update completion percentage
	if completion_label:
		var unlocked = AchievementManager.get_unlocked_count()
		var total = AchievementManager.get_total_count()
		var percentage = AchievementManager.get_completion_percentage()
		completion_label.text = "COMPLETION: %d/%d (%.1f%%)" % [unlocked, total, percentage]
	
	# Update stats display
	if stats_label:
		var stats_text = ""
		stats_text += "Boardings Completed: %d\n" % AchievementManager.get_stat("boardings_completed")
		stats_text += "Total Credits Earned: %d\n" % AchievementManager.get_stat("total_credits_earned")
		stats_text += "Legendary Items Found: %d\n" % AchievementManager.get_stat("legendary_items_found")
		
		var fastest = AchievementManager.get_stat("fastest_boarding_time")
		if fastest < 999999.0:
			stats_text += "Fastest Boarding: %.1fs\n" % fastest
		else:
			stats_text += "Fastest Boarding: --\n"
		
		var factions = AchievementManager.get_stat("factions_boarded")
		if factions is Array:
			stats_text += "Factions Boarded: %d/5 (%s)" % [factions.size(), ", ".join(factions)]
		
		stats_label.text = stats_text


# ==============================================================================
# CALLBACKS
# ==============================================================================

func _on_close_pressed() -> void:
	queue_free()
