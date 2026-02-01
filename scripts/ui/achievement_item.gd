# ==============================================================================
# ACHIEVEMENT ITEM - SINGLE ACHIEVEMENT DISPLAY
# ==============================================================================
#
# FILE: scripts/ui/achievement_item.gd
# PURPOSE: Displays a single achievement in the gallery
#
# ==============================================================================

extends PanelContainer
class_name AchievementItem


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var tier_label: Label = %TierLabel
@onready var status_label: Label = %StatusLabel
@onready var icon_rect: TextureRect = %IconRect
@onready var progress_label: Label = %ProgressLabel


# ==============================================================================
# STATE
# ==============================================================================

var achievement: AchievementData = null


# ==============================================================================
# PUBLIC API
# ==============================================================================

func set_achievement(ach: AchievementData) -> void:
	achievement = ach
	if not achievement:
		return
	
	_update_display()


# ==============================================================================
# DISPLAY
# ==============================================================================

func _update_display() -> void:
	if not achievement:
		return
	
	# Set title
	if title_label:
		title_label.text = achievement.title
		if achievement.is_unlocked:
			title_label.add_theme_color_override("font_color", Color.WHITE)
		else:
			title_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	
	# Set description
	if description_label:
		description_label.text = achievement.description
		if achievement.is_unlocked:
			description_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		else:
			description_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	
	# Set tier
	if tier_label:
		tier_label.text = achievement.get_tier_name().to_upper()
		tier_label.add_theme_color_override("font_color", achievement.get_tier_color())
	
	# Set status
	if status_label:
		if achievement.is_unlocked:
			status_label.text = "UNLOCKED"
			status_label.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3))
			
			# Show unlock time if available
			if achievement.unlock_timestamp > 0:
				var time_dict = Time.get_datetime_dict_from_unix_time(achievement.unlock_timestamp)
				var date_str = "%04d-%02d-%02d" % [time_dict.year, time_dict.month, time_dict.day]
				status_label.text = "UNLOCKED - " + date_str
		else:
			status_label.text = "LOCKED"
			status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	
	# Set icon
	if icon_rect:
		if achievement.is_unlocked and achievement.icon_unlocked:
			icon_rect.texture = achievement.icon_unlocked
			icon_rect.modulate = Color.WHITE
		elif achievement.icon_locked:
			icon_rect.texture = achievement.icon_locked
			icon_rect.modulate = Color(0.4, 0.4, 0.4)
		else:
			# Use unlocked icon but grayed out
			if achievement.icon_unlocked:
				icon_rect.texture = achievement.icon_unlocked
				icon_rect.modulate = Color(0.3, 0.3, 0.3)
	
	# Set progress hint (if not unlocked)
	if progress_label:
		if not achievement.is_unlocked:
			var progress_text = _get_progress_text()
			if progress_text != "":
				progress_label.text = progress_text
				progress_label.visible = true
			else:
				progress_label.visible = false
		else:
			progress_label.visible = false
	
	# Apply style based on unlock status
	_apply_style()


func _get_progress_text() -> String:
	if not achievement:
		return ""
	
	match achievement.achievement_type:
		0:  # FirstBoarding
			var count = AchievementManager.get_stat("boardings_completed")
			return "Progress: %d/1 boardings" % count
		1:  # CreditsMilestone
			var credits = AchievementManager.get_stat("total_credits_earned")
			return "Progress: %d/%d credits" % [credits, int(achievement.required_value)]
		2:  # LegendaryItem
			var count = AchievementManager.get_stat("legendary_items_found")
			return "Progress: %d/1 legendary items" % count
		3:  # SpeedRun
			var fastest = AchievementManager.get_stat("fastest_boarding_time")
			if fastest < 999999.0:
				return "Best time: %.1fs (need: %.0fs)" % [fastest, achievement.required_value]
			return "Best time: -- (need: %.0fs)" % achievement.required_value
		4:  # Completionist
			return "Search all containers on a ship"
		5:  # FactionHunter
			var factions = AchievementManager.get_stat("factions_boarded")
			var count = factions.size() if factions is Array else 0
			return "Progress: %d/5 factions" % count
	
	return ""


func _apply_style() -> void:
	if not achievement:
		return
	
	# Get panel stylebox
	var stylebox = get_theme_stylebox("panel")
	if stylebox and stylebox is StyleBoxFlat:
		stylebox = stylebox.duplicate()
		
		if achievement.is_unlocked:
			# Unlocked: colored border
			stylebox.border_color = achievement.get_tier_color()
			stylebox.bg_color = Color(0.15, 0.15, 0.2, 0.8)
		else:
			# Locked: gray border
			stylebox.border_color = Color(0.3, 0.3, 0.3)
			stylebox.bg_color = Color(0.1, 0.1, 0.12, 0.6)
		
		add_theme_stylebox_override("panel", stylebox)
