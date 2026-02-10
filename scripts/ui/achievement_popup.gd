# ==============================================================================
# ACHIEVEMENT POPUP - NOTIFICATION UI
# ==============================================================================
#
# FILE: scripts/ui/achievement_popup.gd
# PURPOSE: Shows a popup notification when achievement is unlocked
#
# ==============================================================================

extends Control
class_name AchievementPopup


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var title_label: Label = %TitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var icon_rect: TextureRect = %IconRect
@onready var tier_label: Label = %TierLabel
@onready var background: Panel = %Background


# ==============================================================================
# CONSTANTS
# ==============================================================================

const SHOW_DURATION = 4.0
const SLIDE_IN_TIME = 0.4
const SLIDE_OUT_TIME = 0.3


# ==============================================================================
# STATE
# ==============================================================================

var show_timer: float = 0.0
var is_showing: bool = false


# ==============================================================================
# PUBLIC API
# ==============================================================================

func show_achievement(achievement: AchievementData) -> void:
	if not achievement:
		return
	
	# Play achievement sound
	AudioManager.play_sfx("achievement_unlock")
	
	# Set achievement data
	if title_label:
		title_label.text = achievement.title
	
	if description_label:
		description_label.text = achievement.description
	
	if tier_label:
		tier_label.text = achievement.get_tier_name().to_upper()
		tier_label.add_theme_color_override("font_color", achievement.get_tier_color())
	
	if icon_rect and achievement.icon_unlocked:
		icon_rect.texture = achievement.icon_unlocked
	
	# Apply tier color to background tint
	if background:
		var tier_color = achievement.get_tier_color()
		# Use stylebox if available
		var stylebox = background.get_theme_stylebox("panel")
		if stylebox:
			stylebox = stylebox.duplicate()
			# Tint the border color to match tier
			if stylebox is StyleBoxFlat:
				stylebox.border_color = tier_color
				background.add_theme_stylebox_override("panel", stylebox)
	
	# Wait for next frame to ensure size is calculated, then animate in
	await get_tree().process_frame
	_animate_show()


# ==============================================================================
# ANIMATION
# ==============================================================================

func _animate_show() -> void:
	is_showing = true
	show_timer = SHOW_DURATION
	
	# Start off-screen to the right
	var viewport_size = get_viewport().get_visible_rect().size
	position.x = viewport_size.x
	visible = true
	
	# Slide in from right
	var target_x = viewport_size.x - size.x - 20
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:x", target_x, SLIDE_IN_TIME)


func _animate_hide() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var target_x = viewport_size.x
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "position:x", target_x, SLIDE_OUT_TIME)
	tween.tween_callback(_on_hide_complete)


func _on_hide_complete() -> void:
	is_showing = false
	visible = false
	queue_free()


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _process(delta: float) -> void:
	if not is_showing:
		return
	
	show_timer -= delta
	
	if show_timer <= 0:
		_animate_hide()
