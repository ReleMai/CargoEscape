# ==============================================================================
# ACCESSIBILITY SETTINGS MENU
# ==============================================================================
#
# FILE: scripts/ui/accessibility_menu.gd
# PURPOSE: UI for configuring accessibility options
#
# ==============================================================================

extends Control
class_name AccessibilityMenu

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var colorblind_option: OptionButton = $Panel/VBoxContainer/ColorblindContainer/ColorblindOption
@onready var high_contrast_check: CheckBox = $Panel/VBoxContainer/HighContrastCheck
@onready var text_size_option: OptionButton = $Panel/VBoxContainer/TextSizeContainer/TextSizeOption
@onready var reduce_motion_check: CheckBox = $Panel/VBoxContainer/ReduceMotionCheck
@onready var screen_reader_check: CheckBox = $Panel/VBoxContainer/ScreenReaderCheck
@onready var back_button: Button = $Panel/VBoxContainer/BackButton
@onready var controls_button: Button = $Panel/VBoxContainer/ControlsButton

# Base font sizes to prevent compounding scaling
var base_font_sizes: Dictionary = {}

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_load_current_settings()
	# Store base font sizes before scaling
	_store_base_font_sizes()


func _setup_ui() -> void:
	# Setup colorblind mode dropdown
	if colorblind_option:
		colorblind_option.clear()
		colorblind_option.add_item("None", AccessibilityManager.ColorblindMode.NONE)
		colorblind_option.add_item("Deuteranopia (Red-Green)", AccessibilityManager.ColorblindMode.DEUTERANOPIA)
		colorblind_option.add_item("Protanopia (Red-Green)", AccessibilityManager.ColorblindMode.PROTANOPIA)
		colorblind_option.add_item("Tritanopia (Blue-Yellow)", AccessibilityManager.ColorblindMode.TRITANOPIA)
	
	# Setup text size dropdown
	if text_size_option:
		text_size_option.clear()
		text_size_option.add_item("Normal", AccessibilityManager.TextSize.NORMAL)
		text_size_option.add_item("Large", AccessibilityManager.TextSize.LARGE)
		text_size_option.add_item("Extra Large", AccessibilityManager.TextSize.EXTRA_LARGE)
	
	# Apply current text size to this menu
	_apply_text_size_to_menu()


func _connect_signals() -> void:
	if colorblind_option:
		colorblind_option.item_selected.connect(_on_colorblind_selected)
	
	if high_contrast_check:
		high_contrast_check.toggled.connect(_on_high_contrast_toggled)
	
	if text_size_option:
		text_size_option.item_selected.connect(_on_text_size_selected)
	
	if reduce_motion_check:
		reduce_motion_check.toggled.connect(_on_reduce_motion_toggled)
	
	if screen_reader_check:
		screen_reader_check.toggled.connect(_on_screen_reader_toggled)
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if controls_button:
		controls_button.pressed.connect(_on_controls_pressed)
	
	# Listen for accessibility changes
	AccessibilityManager.text_size_changed.connect(_on_text_size_changed)


func _load_current_settings() -> void:
	# Load current settings from AccessibilityManager
	if colorblind_option:
		var current_mode = AccessibilityManager.get_colorblind_mode()
		for i in colorblind_option.item_count:
			if colorblind_option.get_item_id(i) == current_mode:
				colorblind_option.select(i)
				break
	
	if high_contrast_check:
		high_contrast_check.button_pressed = AccessibilityManager.get_high_contrast()
	
	if text_size_option:
		var current_size = AccessibilityManager.get_text_size()
		for i in text_size_option.item_count:
			if text_size_option.get_item_id(i) == current_size:
				text_size_option.select(i)
				break
	
	if reduce_motion_check:
		reduce_motion_check.button_pressed = AccessibilityManager.get_reduce_motion()
	
	if screen_reader_check:
		screen_reader_check.button_pressed = AccessibilityManager.get_screen_reader_mode()


# ==============================================================================
# SIGNAL HANDLERS
# ==============================================================================

func _on_colorblind_selected(index: int) -> void:
	var mode = colorblind_option.get_item_id(index)
	AccessibilityManager.set_colorblind_mode(mode)
	AccessibilityManager.announce_for_screen_reader("Colorblind mode: " + colorblind_option.get_item_text(index))


func _on_high_contrast_toggled(enabled: bool) -> void:
	AccessibilityManager.set_high_contrast(enabled)
	AccessibilityManager.announce_for_screen_reader("High contrast " + ("enabled" if enabled else "disabled"))


func _on_text_size_selected(index: int) -> void:
	var size = text_size_option.get_item_id(index)
	AccessibilityManager.set_text_size(size)
	AccessibilityManager.announce_for_screen_reader("Text size: " + text_size_option.get_item_text(index))


func _on_reduce_motion_toggled(enabled: bool) -> void:
	AccessibilityManager.set_reduce_motion(enabled)
	AccessibilityManager.announce_for_screen_reader("Reduce motion " + ("enabled" if enabled else "disabled"))


func _on_screen_reader_toggled(enabled: bool) -> void:
	AccessibilityManager.set_screen_reader_mode(enabled)
	AccessibilityManager.announce_for_screen_reader("Screen reader mode " + ("enabled" if enabled else "disabled"))


func _on_back_pressed() -> void:
	AccessibilityManager.announce_for_screen_reader("Returning to main menu")
	queue_free()


func _on_controls_pressed() -> void:
	# Open controls remapping menu
	var controls_scene = preload("res://scenes/ui/controls_menu.tscn")
	var controls_menu = controls_scene.instantiate()
	get_parent().add_child(controls_menu)
	AccessibilityManager.announce_for_screen_reader("Opening controls menu")


func _on_text_size_changed(_size) -> void:
	_apply_text_size_to_menu()


# ==============================================================================
# TEXT SIZE APPLICATION
# ==============================================================================

func _store_base_font_sizes() -> void:
	# Recursively store base font sizes to prevent compounding
	_store_sizes_for_children(self)


func _store_sizes_for_children(node: Node) -> void:
	for child in node.get_children():
		if child is Label or child is Button or child is CheckBox or child is OptionButton:
			var key = child.get_path()
			var base_size = 16  # Default
			
			if child.has_theme_font_size_override("font_size"):
				base_size = child.get_theme_font_size("font_size")
			elif child.get_theme_font_size("font_size") > 0:
				base_size = child.get_theme_font_size("font_size")
			
			base_font_sizes[key] = base_size
		
		_store_sizes_for_children(child)


func _apply_text_size_to_menu() -> void:
	var scale = AccessibilityManager.get_text_scale()
	
	# Apply to all labels and buttons in this menu
	_apply_scale_to_children(self, scale)


func _apply_scale_to_children(node: Node, scale: float) -> void:
	for child in node.get_children():
		if child is Label or child is Button or child is CheckBox or child is OptionButton:
			var key = child.get_path()
			var base_size = base_font_sizes.get(key, 16)
			
			# Apply scale using stored base size
			child.add_theme_font_size_override("font_size", int(base_size * scale))
		
		# Recursively apply to children
		_apply_scale_to_children(child, scale)
