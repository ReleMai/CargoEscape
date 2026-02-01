# ==============================================================================
# CARGO CONTAINER
# ==============================================================================
#
# FILE: scripts/loot/container.gd
# PURPOSE: A searchable cargo container that holds multiple items
#
# CONTAINER STATES:
# -----------------
# 1. CLOSED - Container is closed, can be clicked to open
# 2. OPEN - Container is open, showing items inside
# 3. EMPTY - All items have been taken
#
# HOW IT WORKS:
# -------------
# - Player clicks container to open it
# - Items inside are displayed as silhouettes
# - Player clicks+holds on items to search them
# - Searched items can be dragged to inventory
#
# ==============================================================================

extends Control
class_name CargoContainer


# ==============================================================================
# SIGNALS
# ==============================================================================

signal container_opened
signal container_closed
signal item_searched(item: LootItem)
signal item_taken(item: LootItem)


# ==============================================================================
# ENUMS
# ==============================================================================

enum ContainerState {
	CLOSED,
	OPEN,
	EMPTY
}


# ==============================================================================
# EXPORTED VARIABLES
# ==============================================================================

@export_group("Container Settings")
## Display name of this container
@export var container_name: String = "Cargo Container"

## How many item slots this container has
@export var slot_count: int = 6

## Size of each item cell in pixels
@export var cell_size: int = 64

@export_group("Container Visuals")
## Container color when closed
@export var closed_color: Color = Color(0.3, 0.3, 0.35, 1.0)

## Container color when open
@export var open_color: Color = Color(0.2, 0.2, 0.25, 1.0)

## Container color when empty
@export var empty_color: Color = Color(0.15, 0.15, 0.15, 0.5)


# ==============================================================================
# ONREADY VARIABLES
# ==============================================================================

@onready var container_panel: Panel = $ContainerPanel
@onready var container_label: Label = $ContainerPanel/ContainerLabel
@onready var items_container: Control = $ContainerPanel/ItemsContainer
@onready var closed_overlay: ColorRect = $ContainerPanel/ClosedOverlay
@onready var open_button: Button = $ContainerPanel/OpenButton
@onready var hover_highlight: ColorRect = $ContainerPanel/HoverHighlight
@onready var search_animation: ColorRect = $ContainerPanel/SearchAnimation


# ==============================================================================
# STATE VARIABLES
# ==============================================================================

var current_state: ContainerState = ContainerState.CLOSED

## Items currently in this container
var contained_items: Array[LootItem] = []

## Reference to loot item scene for instantiation
var loot_item_scene: PackedScene

## Animation state
var animation_time: float = 0.0
var is_searching: bool = false


# ==============================================================================
# BUILT-IN FUNCTIONS
# ==============================================================================

func _ready() -> void:
	# Load the loot item scene
	loot_item_scene = preload("res://scenes/loot/loot_item.tscn")
	
	# Set up initial state
	set_state(ContainerState.CLOSED)
	
	# Connect open button
	if open_button:
		open_button.pressed.connect(_on_open_button_pressed)
	
	# Set container name
	if container_label:
		container_label.text = container_name
	
	# Setup hover effects
	_setup_hover_effects()
	
	# Setup search animation
	_setup_search_animation()


func _process(delta: float) -> void:
	# Update search animation
	if is_searching and search_animation:
		animation_time += delta
		var pulse = (sin(animation_time * 3.0) + 1.0) / 2.0
		search_animation.color.a = 0.1 + pulse * 0.15
		search_animation.visible = true
	elif search_animation:
		search_animation.visible = false


# ==============================================================================
# HOVER & ANIMATION SETUP
# ==============================================================================

func _setup_hover_effects() -> void:
	# Connect hover events to container panel
	if container_panel:
		container_panel.mouse_entered.connect(_on_container_mouse_entered)
		container_panel.mouse_exited.connect(_on_container_mouse_exited)
	
	# Initialize hover highlight if it doesn't exist
	if not hover_highlight and container_panel:
		hover_highlight = ColorRect.new()
		hover_highlight.name = "HoverHighlight"
		hover_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hover_highlight.color = Color(1.0, 1.0, 1.0, 0.0)
		hover_highlight.z_index = 1
		container_panel.add_child(hover_highlight)
		container_panel.move_child(hover_highlight, 0)
		
		# Make it cover the whole panel
		hover_highlight.set_anchors_preset(Control.PRESET_FULL_RECT)


func _setup_search_animation() -> void:
	# Initialize search animation overlay if it doesn't exist
	if not search_animation and container_panel:
		search_animation = ColorRect.new()
		search_animation.name = "SearchAnimation"
		search_animation.mouse_filter = Control.MOUSE_FILTER_IGNORE
		search_animation.color = Color(0.4, 0.6, 1.0, 0.0)
		search_animation.visible = false
		search_animation.z_index = 2
		container_panel.add_child(search_animation)
		
		# Make it cover the whole panel
		search_animation.set_anchors_preset(Control.PRESET_FULL_RECT)


func _on_container_mouse_entered() -> void:
	# Show hover highlight only when container can be interacted with
	if hover_highlight and current_state in [ContainerState.CLOSED, ContainerState.OPEN]:
		var tween = create_tween()
		tween.tween_property(hover_highlight, "color:a", 0.08, 0.15)


func _on_container_mouse_exited() -> void:
	# Hide hover highlight
	if hover_highlight:
		var tween = create_tween()
		tween.tween_property(hover_highlight, "color:a", 0.0, 0.15)


# ==============================================================================
# STATE MANAGEMENT
# ==============================================================================

func set_state(new_state: ContainerState) -> void:
	current_state = new_state
	
	match new_state:
		ContainerState.CLOSED:
			if closed_overlay:
				closed_overlay.visible = true
			if open_button:
				open_button.visible = true
				open_button.text = "OPEN"
			if items_container:
				items_container.visible = false
			if container_panel:
				container_panel.self_modulate = closed_color
		
		ContainerState.OPEN:
			if closed_overlay:
				closed_overlay.visible = false
			if open_button:
				open_button.visible = false
			if items_container:
				items_container.visible = true
			if container_panel:
				container_panel.self_modulate = open_color
			
			emit_signal("container_opened")
		
		ContainerState.EMPTY:
			if closed_overlay:
				closed_overlay.visible = false
			if open_button:
				open_button.visible = false
			if items_container:
				items_container.visible = true
			if container_panel:
				container_panel.self_modulate = empty_color


# ==============================================================================
# CONTAINER MANAGEMENT
# ==============================================================================

func open_container() -> void:
	if current_state == ContainerState.CLOSED:
		set_state(ContainerState.OPEN)
		print("Opened container: ", container_name)


func close_container() -> void:
	if current_state == ContainerState.OPEN:
		set_state(ContainerState.CLOSED)
		emit_signal("container_closed")


## Add items to this container (called during setup)
func populate_items(item_data_list: Array[ItemData]) -> void:
	# Clear existing items
	clear_items()
	
	# Create loot items from data
	for data in item_data_list:
		add_item(data)
	
	# Arrange items in container
	arrange_items()


## Add a single item to the container
func add_item(data: ItemData) -> LootItem:
	if not loot_item_scene:
		push_error("Container: loot_item_scene not loaded!")
		return null
	
	var loot_item = loot_item_scene.instantiate() as LootItem
	loot_item.initialize(data)
	
	# Connect signals - using correct signal names from loot_item.gd
	loot_item.search_started.connect(_on_item_search_started.bind(loot_item))
	loot_item.search_completed.connect(_on_item_revealed.bind(loot_item))
	# Note: drag_started(item) signal is handled by LootManager, not container
	
	# Add to container
	contained_items.append(loot_item)
	if items_container:
		items_container.add_child(loot_item)
	
	return loot_item


## Remove an item from the container (when taken by player)
func remove_item(item: LootItem) -> void:
	if item in contained_items:
		contained_items.erase(item)
		emit_signal("item_taken", item)
		
		# Check if container is now empty
		if contained_items.is_empty():
			set_state(ContainerState.EMPTY)


## Clear all items
func clear_items() -> void:
	for item in contained_items:
		if is_instance_valid(item):
			item.queue_free()
	contained_items.clear()


## Arrange items in a grid layout
func arrange_items() -> void:
	if not items_container:
		return
	
	var x_offset = 10
	var y_offset = 10
	var max_width = items_container.size.x - 20
	var current_row_height = 0
	
	for item in contained_items:
		var item_size = Vector2(item.item_data.grid_width * cell_size, 
								item.item_data.grid_height * cell_size)
		
		# Check if we need to wrap to next row
		if x_offset + item_size.x > max_width:
			x_offset = 10
			y_offset += current_row_height + 10
			current_row_height = 0
		
		# Position item
		item.position = Vector2(x_offset, y_offset)
		
		# Update offsets
		x_offset += item_size.x + 10
		current_row_height = max(current_row_height, item_size.y)


# ==============================================================================
# SIGNAL CALLBACKS
# ==============================================================================

func _on_open_button_pressed() -> void:
	open_container()


func _on_item_search_started(_item: LootItem) -> void:
	# Update container state to show searching animation
	_update_searching_state()


func _on_item_revealed(_item: LootItem) -> void:
	emit_signal("item_searched", _item)
	# Update searching state in case all items are now revealed
	_update_searching_state()


func _update_searching_state() -> void:
	# Check if any items are currently being searched
	var any_searching = false
	for item in contained_items:
		if item.is_searching():
			any_searching = true
			break
	is_searching = any_searching


# ==============================================================================
# UTILITY
# ==============================================================================

func get_remaining_value() -> int:
	var total = 0
	for item in contained_items:
		if item.item_data:
			total += item.item_data.value
	return total


func get_item_count() -> int:
	return contained_items.size()


func has_unrevealed_items() -> bool:
	for item in contained_items:
		if not item.is_revealed():
			return true
	return false
