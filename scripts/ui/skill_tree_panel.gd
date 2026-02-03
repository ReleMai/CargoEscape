# ==============================================================================
# SKILL TREE UI
# ==============================================================================
#
# FILE: scripts/ui/skill_tree_panel.gd
# PURPOSE: Displays skill tree and allows skill point allocation
#
# LAYOUT:
# - 4 columns for skill categories (Combat, Defense, Stealth, Utility)
# - Skills shown as nodes with connecting lines
# - Click to unlock/upgrade skills
#
# ==============================================================================

extends Control
class_name SkillTreePanel


# ==============================================================================
# SIGNALS
# ==============================================================================

signal skill_selected(skill_id: String)
signal skill_unlocked_ui(skill_id: String)


# ==============================================================================
# PRELOADS
# ==============================================================================

const SkillNodeScene = preload("res://scenes/ui/skill_node.tscn") if FileAccess.file_exists("res://scenes/ui/skill_node.tscn") else null


# ==============================================================================
# EXPORTS
# ==============================================================================

@export var skill_tree: SkillTree
@export var player_stats: PlayerStats

## Category containers
@export_group("Category Containers")
@export var combat_container: Control
@export var defense_container: Control
@export var stealth_container: Control
@export var utility_container: Control

## Info panel
@export_group("Info Panel")
@export var skill_name_label: Label
@export var skill_description_label: RichTextLabel
@export var skill_level_label: Label
@export var skill_cost_label: Label
@export var unlock_button: Button

## Points display
@export var points_label: Label


# ==============================================================================
# STATE
# ==============================================================================

var skill_nodes: Dictionary = {}  # skill_id -> Control
var selected_skill: String = ""
var category_containers: Dictionary = {}


# ==============================================================================
# COLORS
# ==============================================================================

const CATEGORY_COLORS = {
	0: Color(0.9, 0.3, 0.3),   # Combat - Red
	1: Color(0.3, 0.5, 0.9),   # Defense - Blue
	2: Color(0.3, 0.8, 0.4),   # Stealth - Green
	3: Color(0.9, 0.8, 0.3)    # Utility - Yellow
}

const LOCKED_COLOR = Color(0.4, 0.4, 0.4)
const AVAILABLE_COLOR = Color(0.8, 0.8, 0.8)
const MAXED_COLOR = Color(1.0, 0.85, 0.3)


# ==============================================================================
# INITIALIZATION
# ==============================================================================

func _ready() -> void:
	category_containers = {
		0: combat_container,
		1: defense_container,
		2: stealth_container,
		3: utility_container
	}
	
	# Connect signals
	if skill_tree:
		skill_tree.skill_unlocked.connect(_on_skill_unlocked)
		skill_tree.skill_points_changed.connect(_on_points_changed)
	
	if unlock_button:
		unlock_button.pressed.connect(_on_unlock_pressed)
	
	# Build skill tree UI
	_build_skill_nodes()
	_refresh_all_nodes()
	_clear_info_panel()
	_update_points_display()


## Set skill tree reference
func set_skill_tree(tree: SkillTree) -> void:
	if skill_tree:
		if skill_tree.skill_unlocked.is_connected(_on_skill_unlocked):
			skill_tree.skill_unlocked.disconnect(_on_skill_unlocked)
		if skill_tree.skill_points_changed.is_connected(_on_points_changed):
			skill_tree.skill_points_changed.disconnect(_on_points_changed)
	
	skill_tree = tree
	
	if skill_tree:
		skill_tree.skill_unlocked.connect(_on_skill_unlocked)
		skill_tree.skill_points_changed.connect(_on_points_changed)
	
	_refresh_all_nodes()
	_update_points_display()


# ==============================================================================
# SKILL NODE CREATION
# ==============================================================================

## Build all skill nodes
func _build_skill_nodes() -> void:
	if not skill_tree:
		return
	
	# Create nodes for each category
	for category in range(4):
		var skills = skill_tree.get_skills_by_category(category)
		var container = category_containers.get(category)
		
		if not container:
			continue
		
		for skill_id in skills:
			var node = _create_skill_node(skill_id, category)
			if node:
				container.add_child(node)
				skill_nodes[skill_id] = node


## Create a single skill node
func _create_skill_node(skill_id: String, category: int) -> Control:
	var skill_def = skill_tree.get_skill_definition(skill_id)
	if skill_def.is_empty():
		return null
	
	# Create node (use scene if available, otherwise create programmatically)
	var node: Control
	if SkillNodeScene:
		node = SkillNodeScene.instantiate()
	else:
		node = _create_skill_node_programmatic(skill_id, skill_def, category)
	
	return node


## Create skill node without a scene
func _create_skill_node_programmatic(skill_id: String, skill_def: Dictionary, category: int) -> Control:
	var node = Button.new()
	node.name = skill_id
	node.custom_minimum_size = Vector2(120, 60)
	node.text = skill_def.get("name", "Unknown")
	node.tooltip_text = skill_def.get("description", "")
	
	# Set metadata
	node.set_meta("skill_id", skill_id)
	node.set_meta("category", category)
	
	# Connect input
	node.pressed.connect(_on_skill_node_clicked.bind(skill_id))
	
	return node


# ==============================================================================
# NODE REFRESH
# ==============================================================================

## Refresh all skill nodes
func _refresh_all_nodes() -> void:
	for skill_id in skill_nodes:
		_refresh_skill_node(skill_id)


## Refresh a single skill node
func _refresh_skill_node(skill_id: String) -> void:
	var node = skill_nodes.get(skill_id)
	if not node or not skill_tree:
		return
	
	var level = skill_tree.get_skill_level(skill_id)
	var max_level = skill_tree.get_skill_max_level(skill_id)
	var can_unlock = skill_tree.can_unlock_skill(skill_id)
	var skill_def = skill_tree.get_skill_definition(skill_id)
	var category = skill_def.get("category", 0)
	
	# Update visual state
	var color: Color
	if level >= max_level:
		color = MAXED_COLOR
	elif can_unlock:
		color = CATEGORY_COLORS.get(category, Color.WHITE)
	elif level > 0:
		color = CATEGORY_COLORS.get(category, Color.WHITE).darkened(0.3)
	else:
		color = LOCKED_COLOR
	
	node.modulate = color
	
	# Update text if it's a button
	if node is Button:
		var name_text = skill_def.get("name", "Unknown")
		node.text = "%s\n%d/%d" % [name_text, level, max_level]
	
	# Update level indicator if present
	var level_node = node.get_node_or_null("LevelIndicator")
	if level_node and level_node is Label:
		level_node.text = "%d/%d" % [level, max_level]


# ==============================================================================
# INFO PANEL
# ==============================================================================

## Show skill info
func _show_skill_info(skill_id: String) -> void:
	if not skill_tree:
		_clear_info_panel()
		return
	
	var skill_def = skill_tree.get_skill_definition(skill_id)
	if skill_def.is_empty():
		_clear_info_panel()
		return
	
	var level = skill_tree.get_skill_level(skill_id)
	var max_level = skill_def.get("max_level", 5)
	var can_unlock = skill_tree.can_unlock_skill(skill_id)
	var category = skill_def.get("category", 0)
	
	if skill_name_label:
		skill_name_label.text = skill_def.get("name", "Unknown")
		skill_name_label.modulate = CATEGORY_COLORS.get(category, Color.WHITE)
	
	if skill_description_label:
		var desc = skill_def.get("description", "")
		
		# Add stat bonuses
		var lines = [desc, ""]
		var stat_bonuses = skill_def.get("stat_bonuses", {})
		for stat in stat_bonuses:
			var per_level = stat_bonuses[stat]
			lines.append("[color=green]+%d %s per level[/color]" % [per_level, stat.capitalize()])
		
		var pct_bonuses = skill_def.get("percent_bonuses", {})
		for bonus in pct_bonuses:
			var per_level = pct_bonuses[bonus]
			lines.append("[color=cyan]+%.0f%% %s per level[/color]" % [per_level * 100, bonus.replace("_", " ").capitalize()])
		
		# Prerequisites
		var prereqs = skill_def.get("prerequisites", [])
		if not prereqs.is_empty():
			lines.append("")
			lines.append("[color=yellow]Requires: %s[/color]" % ", ".join(prereqs))
		
		# Ability at max
		var ability = skill_def.get("ability", "")
		if not ability.is_empty():
			lines.append("")
			lines.append("[color=gold]Max Level Ability: %s[/color]" % ability.replace("_", " ").capitalize())
		
		skill_description_label.text = "\n".join(lines)
	
	if skill_level_label:
		skill_level_label.text = "Level: %d / %d" % [level, max_level]
	
	if skill_cost_label:
		if level >= max_level:
			skill_cost_label.text = "MAXED"
			skill_cost_label.modulate = MAXED_COLOR
		else:
			var costs = skill_def.get("costs", [1])
			var cost = costs[mini(level, costs.size() - 1)]
			skill_cost_label.text = "Cost: %d points" % cost
			skill_cost_label.modulate = Color.WHITE if can_unlock else LOCKED_COLOR
	
	if unlock_button:
		unlock_button.visible = level < max_level
		unlock_button.disabled = not can_unlock
		unlock_button.text = "Unlock" if level == 0 else "Upgrade"


## Clear info panel
func _clear_info_panel() -> void:
	if skill_name_label:
		skill_name_label.text = "Select a Skill"
		skill_name_label.modulate = Color.WHITE
	
	if skill_description_label:
		skill_description_label.text = "Click on a skill to view details."
	
	if skill_level_label:
		skill_level_label.text = ""
	
	if skill_cost_label:
		skill_cost_label.text = ""
	
	if unlock_button:
		unlock_button.visible = false


## Update points display
func _update_points_display() -> void:
	if not points_label or not skill_tree:
		return
	
	var points = skill_tree.get_available_points()
	points_label.text = "Skill Points: %d" % points
	points_label.modulate = Color.YELLOW if points > 0 else Color.WHITE


# ==============================================================================
# INPUT HANDLERS
# ==============================================================================

## Handle skill node click
func _on_skill_node_clicked(skill_id: String) -> void:
	selected_skill = skill_id
	_show_skill_info(skill_id)
	skill_selected.emit(skill_id)


## Handle unlock button
func _on_unlock_pressed() -> void:
	if selected_skill.is_empty() or not skill_tree:
		return
	
	if skill_tree.unlock_skill(selected_skill):
		skill_unlocked_ui.emit(selected_skill)
		_refresh_skill_node(selected_skill)
		_show_skill_info(selected_skill)


# ==============================================================================
# SIGNAL HANDLERS
# ==============================================================================

## Handle skill unlock from tree
func _on_skill_unlocked(skill_id: String, _new_level: int) -> void:
	_refresh_skill_node(skill_id)
	
	# Also refresh any skills that have this as a prerequisite
	for other_id in skill_nodes:
		var skill_def = skill_tree.get_skill_definition(other_id)
		var prereqs = skill_def.get("prerequisites", [])
		if skill_id in prereqs:
			_refresh_skill_node(other_id)
	
	_update_points_display()


## Handle points changed
func _on_points_changed(_available: int) -> void:
	_update_points_display()
	_refresh_all_nodes()
	
	if not selected_skill.is_empty():
		_show_skill_info(selected_skill)
