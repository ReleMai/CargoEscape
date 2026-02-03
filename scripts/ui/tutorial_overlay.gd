# ==============================================================================
# TUTORIAL OVERLAY UI
# ==============================================================================
#
# FILE: scripts/ui/tutorial_overlay.gd
# PURPOSE: Visual overlay for tutorial system showing tooltips and highlights
#
# FEATURES:
# - Tooltip popup with step instructions
# - UI element highlighting
# - Skip button
# - Smooth animations
#
# ==============================================================================

extends CanvasLayer

# ==============================================================================
# CONSTANTS
# ==============================================================================

## Target identifiers for highlighting (matched with STEP_DATA in TutorialManager)
const HIGHLIGHT_TARGETS = {
	"container": {"group": "containers", "name": null},
	"inventory": {"group": null, "name": "InventoryPanel"},
	"timer": {"group": null, "name": "TimerLabel"},
	"exit": {"group": "exit_point", "name": null},
	"station_sell": {"group": null, "name": "SellButton"}
}

# ==============================================================================
# SIGNALS
# ==============================================================================

signal skip_requested

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var tooltip_panel: PanelContainer = $TooltipPanel
@onready var title_label: Label = $TooltipPanel/VBox/TitleLabel
@onready var description_label: Label = $TooltipPanel/VBox/DescriptionLabel
@onready var skip_button: Button = $SkipButton
@onready var highlight_rect: ColorRect = $HighlightRect
@onready var arrow_pointer: Polygon2D = $ArrowPointer

# ==============================================================================
# STATE
# ==============================================================================

var current_highlight_target: Node = null
var highlight_tween: Tween = null

# ==============================================================================
# BUILT-IN FUNCTIONS
# ==============================================================================

func _ready() -> void:
	# Set layer to be on top
	layer = 100
	
	# Connect skip button
	if skip_button:
		skip_button.pressed.connect(_on_skip_button_pressed)
	
	# Hide everything initially
	tooltip_panel.visible = false
	highlight_rect.visible = false
	if arrow_pointer:
		arrow_pointer.visible = false
	
	print("[TutorialOverlay] Initialized")


func _process(_delta: float) -> void:
	# Update highlight position if we have a target
	if current_highlight_target and is_instance_valid(current_highlight_target):
		_update_highlight_position()


# ==============================================================================
# PUBLIC FUNCTIONS
# ==============================================================================

## Show a tutorial step with tooltip and highlight
func show_step(step_data: Dictionary) -> void:
	# Update tooltip text
	if title_label:
		title_label.text = step_data.get("title", "Tutorial")
	
	if description_label:
		description_label.text = step_data.get("description", "")
	
	# Show tooltip with animation
	_show_tooltip()
	
	# Highlight target if specified
	var highlight_target = step_data.get("highlight_target")
	if highlight_target:
		_highlight_element(highlight_target)
	else:
		_clear_highlight()


## Hide the tutorial overlay
func hide_tutorial() -> void:
	_hide_tooltip()
	_clear_highlight()


# ==============================================================================
# PRIVATE FUNCTIONS
# ==============================================================================

func _show_tooltip() -> void:
	tooltip_panel.visible = true
	
	# Play notification sound
	AudioManager.play_sfx("ui_notification")
	
	# Animate in
	tooltip_panel.modulate.a = 0
	tooltip_panel.scale = Vector2(0.9, 0.9)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(tooltip_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(tooltip_panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _hide_tooltip() -> void:
	if not tooltip_panel:
		return
	
	var tween = create_tween()
	tween.tween_property(tooltip_panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func(): tooltip_panel.visible = false)


func _highlight_element(target_name: String) -> void:
	# Find target node in scene
	var target = _find_highlight_target(target_name)
	
	if not target:
		print("[TutorialOverlay] Highlight target not found: ", target_name)
		_clear_highlight()
		return
	
	current_highlight_target = target
	highlight_rect.visible = true
	
	# Animate highlight pulsing
	if highlight_tween:
		highlight_tween.kill()
	
	highlight_tween = create_tween()
	highlight_tween.set_loops()
	highlight_tween.tween_property(highlight_rect, "modulate:a", 0.3, 0.8)
	highlight_tween.tween_property(highlight_rect, "modulate:a", 0.15, 0.8)
	
	# Show arrow pointer
	if arrow_pointer:
		arrow_pointer.visible = true


func _clear_highlight() -> void:
	current_highlight_target = null
	highlight_rect.visible = false
	
	if highlight_tween:
		highlight_tween.kill()
		highlight_tween = null
	
	if arrow_pointer:
		arrow_pointer.visible = false


func _update_highlight_position() -> void:
	if not current_highlight_target or not is_instance_valid(current_highlight_target):
		return
	
	# Get target's global position and size
	var target_rect: Rect2
	
	if current_highlight_target is Control:
		target_rect = current_highlight_target.get_global_rect()
	elif current_highlight_target is Node2D:
		var pos = current_highlight_target.global_position
		var size = Vector2(64, 64)  # Default size for Node2D
		target_rect = Rect2(pos - size / 2, size)
	else:
		return
	
	# Position and size highlight rect
	highlight_rect.position = target_rect.position - Vector2(10, 10)
	highlight_rect.size = target_rect.size + Vector2(20, 20)
	
	# Position arrow pointer
	if arrow_pointer:
		arrow_pointer.position = target_rect.position + Vector2(target_rect.size.x / 2, -40)


func _find_highlight_target(target_name: String) -> Node:
	# Search for target in the scene tree
	var target_config = HIGHLIGHT_TARGETS.get(target_name)
	if not target_config:
		push_warning("[TutorialOverlay] Unknown highlight target: ", target_name)
		return null
	
	# Try group first
	if target_config.group:
		return _find_node_by_group(target_config.group)
	
	# Then try by name
	if target_config.name:
		var root = get_tree().root
		return _find_node_by_name_fast(target_config.name, root)
	
	return null


func _find_node_by_group(group_name: String) -> Node:
	var nodes = get_tree().get_nodes_in_group(group_name)
	if nodes.size() > 0:
		return nodes[0]
	return null


func _find_node_by_name_fast(node_name: String, parent: Node) -> Node:
	# Use Godot's built-in find_child which is faster than manual recursion
	return parent.find_child(node_name, true, false)


# ==============================================================================
# SIGNAL CALLBACKS
# ==============================================================================

func _on_skip_button_pressed() -> void:
	skip_requested.emit()
