# ==============================================================================
# MODULES PANEL - SHIP MODULE DISPLAY UI
# ==============================================================================
#
# FILE: scripts/ui/modules_panel.gd
# PURPOSE: Displays equipped ship modules in three slots
#
# ==============================================================================

extends PanelContainer
class_name ModulesPanel


# Preload ModuleData for type checking
const ModuleDataScript = preload("res://scripts/loot/module_data.gd")


# ==============================================================================
# SIGNALS
# ==============================================================================

signal module_clicked(slot_type: int, module: Resource)


# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var flight_slot: PanelContainer = %FlightSlot
@onready var combat_slot: PanelContainer = %CombatSlot
@onready var utility_slot: PanelContainer = %UtilitySlot

@onready var flight_name: Label = %FlightSlot.get_node("HBox/VBox/ModuleName")
@onready var combat_name: Label = %CombatSlot.get_node("HBox/VBox/ModuleName")
@onready var utility_name: Label = %UtilitySlot.get_node("HBox/VBox/ModuleName")


# ==============================================================================
# STATE
# ==============================================================================

## Currently equipped modules (indexed by ModuleType enum)
var equipped_modules: Dictionary = {
	0: null,  # FLIGHT
	1: null,  # COMBAT
	2: null   # UTILITY
}


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	# Connect slot clicks
	flight_slot.gui_input.connect(_on_flight_slot_input)
	combat_slot.gui_input.connect(_on_combat_slot_input)
	utility_slot.gui_input.connect(_on_utility_slot_input)
	
	# Load modules from GameManager if available
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.has_method("get_equipped_modules"):
			equipped_modules = gm.get_equipped_modules()
	
	update_display()


# ==============================================================================
# PUBLIC METHODS
# ==============================================================================

## Equip a module to its appropriate slot
func equip_module(module: Resource) -> bool:
	if not module:
		return false
	
	# Check if it's a ModuleData using duck typing
	if not module.has_method("get_module_type_name"):
		return false
	
	var slot_type = module.module_type
	
	# Store in appropriate slot
	equipped_modules[slot_type] = module
	
	# Update GameManager
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.has_method("set_equipped_module"):
			gm.set_equipped_module(slot_type, module)
	
	update_display()
	return true


## Unequip a module from a slot
func unequip_module(slot_type: int) -> Resource:
	var module = equipped_modules.get(slot_type)
	equipped_modules[slot_type] = null
	
	# Update GameManager
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.has_method("set_equipped_module"):
			gm.set_equipped_module(slot_type, null)
	
	update_display()
	return module


## Get the currently equipped module in a slot
func get_module(slot_type: int) -> Resource:
	return equipped_modules.get(slot_type)


## Update the visual display of all slots
func update_display() -> void:
	_update_slot(0, flight_slot, flight_name)
	_update_slot(1, combat_slot, combat_name)
	_update_slot(2, utility_slot, utility_name)


# ==============================================================================
# PRIVATE METHODS
# ==============================================================================

func _update_slot(slot_type: int, slot: PanelContainer, name_label: Label) -> void:
	var module = equipped_modules.get(slot_type)
	
	if module and module.has_method("get_module_type_name"):
		name_label.text = module.name
		name_label.add_theme_color_override("font_color", module.get_rarity_color())
		
		# Update tooltip
		var desc = module.get_effects_description()
		slot.tooltip_text = "%s\n%s\nValue: %d" % [module.name, desc, module.value]
		
		# Update icon color to show equipped
		var icon = slot.get_node("HBox/Icon")
		if icon:
			icon.modulate.a = 1.0
	else:
		name_label.text = "Empty"
		name_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		
		var slot_names = ["Flight Module Slot", "Combat Module Slot", "Utility Module Slot"]
		slot.tooltip_text = slot_names[slot_type]
		
		var icon = slot.get_node("HBox/Icon")
		if icon:
			icon.modulate.a = 0.5


func _on_flight_slot_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		module_clicked.emit(0, equipped_modules.get(0))


func _on_combat_slot_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		module_clicked.emit(1, equipped_modules.get(1))


func _on_utility_slot_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		module_clicked.emit(2, equipped_modules.get(2))
