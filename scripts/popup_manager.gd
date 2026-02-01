# ==============================================================================
# POPUP MANAGER (AUTOLOAD/SINGLETON)
# ==============================================================================
#
# FILE: scripts/popup_manager.gd
# PURPOSE: Manages popup notifications (achievements, etc.)
#
# ==============================================================================

extends CanvasLayer
class_name PopupManagerClass


# ==============================================================================
# PRELOADS
# ==============================================================================

const AchievementPopupScene = preload("res://scenes/ui/achievement_popup.tscn")


# ==============================================================================
# STATE
# ==============================================================================

var popup_queue: Array = []
var current_popup: Control = null


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Connect to achievement unlocks
	if AchievementManager:
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
	
	print("[PopupManager] Initialized")


# ==============================================================================
# ACHIEVEMENT POPUPS
# ==============================================================================

func _on_achievement_unlocked(achievement: AchievementData) -> void:
	show_achievement_popup(achievement)


func show_achievement_popup(achievement: AchievementData) -> void:
	if not achievement:
		return
	
	# Create popup instance
	var popup = AchievementPopupScene.instantiate()
	
	# Add to scene first so it calculates its size
	add_child(popup)
	
	# Position at top-right (will be animated from off-screen)
	popup.position = Vector2(
		get_viewport().get_visible_rect().size.x,
		20
	)
	
	# Show achievement (this triggers the slide-in animation)
	popup.show_achievement(achievement)
	
	print("[PopupManager] Showing achievement: %s" % achievement.title)
