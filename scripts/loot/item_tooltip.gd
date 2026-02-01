# ==============================================================================
# ITEM TOOLTIP - FLUID, RESPONSIVE TOOLTIP FOR LOOT ITEMS
# ==============================================================================
#
# FILE: scripts/loot/item_tooltip.gd
# PURPOSE: Custom tooltip that follows mouse instantly with smooth animations
#
# FEATURES:
# - Instant appearance on hover (no delay)
# - Smooth fade in/out animations
# - Follows mouse position fluidly
# - Automatically positions to stay on screen
# - Rarity-colored border
# - Rich item information display
#
# ==============================================================================

extends PanelContainer
class_name ItemTooltip


# ==============================================================================
# CONSTANTS
# ==============================================================================

## How fast the tooltip fades in/out
const FADE_SPEED := 12.0

## Offset from mouse cursor
const MOUSE_OFFSET := Vector2(16, 16)

## Padding from screen edges
const SCREEN_PADDING := 10

## Background color
const BG_COLOR := Color(0.08, 0.08, 0.12, 0.95)

## Border thickness
const BORDER_WIDTH := 2


# ==============================================================================
# STATE
# ==============================================================================

## Target alpha (0 = hidden, 1 = visible)
var target_alpha := 0.0

## Current item data being displayed
var current_item: ItemData = null

## Is the tooltip active?
var is_active := false


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

var vbox: VBoxContainer
var name_label: Label
var rarity_label: Label
var value_label: Label
var desc_label: Label
var border_panel: Panel


# ==============================================================================
# SINGLETON
# ==============================================================================

## Global instance
static var instance: ItemTooltip = null


## Get or create the global tooltip instance
static func get_instance() -> ItemTooltip:
	return instance


## Register as the global instance
static func register_instance(tooltip: ItemTooltip) -> void:
	instance = tooltip


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Register as global instance
	register_instance(self)
	
	# Setup panel
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	modulate.a = 0.0
	z_index = 1000
	
	# Create styling
	_create_style()
	
	# Create content
	_create_content()
	
	# Start hidden
	visible = true
	target_alpha = 0.0


func _process(delta: float) -> void:
	# Smooth fade animation
	if modulate.a != target_alpha:
		modulate.a = move_toward(modulate.a, target_alpha, delta * FADE_SPEED)
	
	# Follow mouse when visible
	if is_active and target_alpha > 0:
		_update_position()


func _exit_tree() -> void:
	if instance == self:
		instance = null


# ==============================================================================
# STYLING
# ==============================================================================

func _create_style() -> void:
	# Create main panel style
	var style := StyleBoxFlat.new()
	style.bg_color = BG_COLOR
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.border_width_left = BORDER_WIDTH
	style.border_width_right = BORDER_WIDTH
	style.border_width_top = BORDER_WIDTH
	style.border_width_bottom = BORDER_WIDTH
	style.border_color = Color.WHITE
	add_theme_stylebox_override("panel", style)


# ==============================================================================
# CONTENT CREATION
# ==============================================================================

func _create_content() -> void:
	vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)
	
	# Item name
	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)
	
	# Rarity
	rarity_label = Label.new()
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(rarity_label)
	
	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 4
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(spacer)
	
	# Value
	value_label = Label.new()
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(value_label)
	
	# Description
	desc_label = Label.new()
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.x = 200
	desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(desc_label)


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Show tooltip for an item
func show_for_item(item: ItemData) -> void:
	if not item:
		hide_tooltip()
		return
	
	current_item = item
	is_active = true
	
	# Update content
	_update_content()
	
	# Update border color to match rarity
	_update_rarity_style()
	
	# Update position immediately
	_update_position()
	
	# Fade in
	target_alpha = 1.0


## Hide the tooltip
func hide_tooltip() -> void:
	is_active = false
	target_alpha = 0.0
	current_item = null


# ==============================================================================
# CONTENT UPDATE
# ==============================================================================

func _update_content() -> void:
	if not current_item:
		return
	
	# Name
	name_label.text = current_item.name
	
	# Rarity
	var rarity_names = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
	var rarity_name = rarity_names[clampi(current_item.rarity, 0, 4)]
	rarity_label.text = rarity_name
	rarity_label.add_theme_color_override(
		"font_color", 
		current_item.get_rarity_color()
	)
	
	# Value
	value_label.text = "💰 %d credits" % current_item.value
	
	# Description
	if current_item.description != "":
		desc_label.text = current_item.description
		desc_label.visible = true
	else:
		desc_label.visible = false


func _update_rarity_style() -> void:
	if not current_item:
		return
	
	# Update border color based on rarity
	var style = get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = current_item.get_rarity_color()
	add_theme_stylebox_override("panel", style)


# ==============================================================================
# POSITIONING
# ==============================================================================

func _update_position() -> void:
	var mouse_pos := get_global_mouse_position()
	var viewport_size := get_viewport_rect().size
	var tooltip_size := size
	
	# Default position: below and to the right of cursor
	var pos := mouse_pos + MOUSE_OFFSET
	
	# Check right edge
	if pos.x + tooltip_size.x > viewport_size.x - SCREEN_PADDING:
		pos.x = mouse_pos.x - tooltip_size.x - MOUSE_OFFSET.x
	
	# Check bottom edge
	if pos.y + tooltip_size.y > viewport_size.y - SCREEN_PADDING:
		pos.y = mouse_pos.y - tooltip_size.y - MOUSE_OFFSET.y
	
	# Clamp to screen
	pos.x = clampf(pos.x, SCREEN_PADDING, viewport_size.x - tooltip_size.x - SCREEN_PADDING)
	pos.y = clampf(pos.y, SCREEN_PADDING, viewport_size.y - tooltip_size.y - SCREEN_PADDING)
	
	global_position = pos
