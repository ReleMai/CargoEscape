# ==============================================================================
# SHIP CONTAINER - INTERACTABLE LOOT CONTAINER WITH SEARCH MECHANIC
# ==============================================================================
#
# FILE: scripts/boarding/ship_container.gd
# PURPOSE: A container in the 2D ship that players can approach and search
#
# NEW SEARCH MECHANIC:
# - Containers start CLOSED
# - Player must SEARCH to reveal items (takes time based on item rarity)
# - Each item has individual search progress
# - Moving interrupts searching
# - Once all items revealed, container becomes OPEN for looting
#
# CONTAINER TYPES:
# - Scrap Pile: Fast search, mostly junk
# - Cargo Crate: Standard shipping container
# - Locker: Personal storage
# - Supply Cabinet: Ship supplies
# - Vault: Secure storage (slow search, better loot)
# - Armory: Military weapons/modules
# - Secure Cache: High-tech (slowest search, best loot)
#
# ==============================================================================

extends Area2D
class_name ShipContainer


# ==============================================================================
# PRELOADS
# ==============================================================================

const ItemDB = preload("res://scripts/loot/item_database.gd")
const ContainerTypesClass = preload("res://scripts/data/container_types.gd")
const SearchSystemClass = preload("res://scripts/boarding/search_system.gd")

# ==============================================================================
# SIGNALS
# ==============================================================================

signal container_opened
signal container_looted(items: Array)
signal container_emptied
signal search_started
signal search_progress_updated(progress: float)
signal search_completed
signal search_cancelled
signal item_revealed(item: ItemData)

# ==============================================================================
# ENUMS
# ==============================================================================

enum ContainerState { CLOSED, SEARCHING, OPEN, EMPTY, LOCKED }

# Legacy LootTier enum for backwards compatibility
enum LootTier { NEAR = 1, MIDDLE = 2, FAR = 3, DEEPEST = 4 }

# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("Container")
@export var container_name: String = "Cargo Crate"
## Container type from ContainerTypes enum
@export_range(0, 6) var container_type_id: int = 1  # CARGO_CRATE default
@export var min_items: int = 2
@export var max_items: int = 5

@export_group("Legacy Settings")
## Legacy loot tier (used if not using new ship tier system)
@export var loot_tier: LootTier = LootTier.NEAR

@export_group("Visuals")
@export var closed_color: Color = Color(0.4, 0.35, 0.3)
@export var open_color: Color = Color(0.3, 0.4, 0.35)
@export var empty_color: Color = Color(0.2, 0.2, 0.2)
@export var searching_color: Color = Color(0.4, 0.4, 0.5)

# ==============================================================================
# NODE REFERENCES
# ==============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var highlight: Sprite2D = $Highlight
@onready var state_label: Label = $StateLabel
@onready var search_progress_bar: ProgressBar = $SearchProgressBar

# Hover state
var is_hovered: bool = false
var hover_tween: Tween = null
var pulse_time: float = 0.0
var search_pulse_time: float = 0.0

# ==============================================================================
# STATE
# ==============================================================================

var current_state: ContainerState = ContainerState.CLOSED
var is_highlighted: bool = false

## Items that haven't been revealed yet (need to search)
var hidden_items: Array[ItemData] = []
## Items that have been revealed and can be looted
var revealed_items: Array[ItemData] = []
## Legacy alias for backwards compatibility - returns ALL items
var item_data_list: Array[ItemData]:
	get:
		var all_items: Array[ItemData] = []
		all_items.append_array(hidden_items)
		all_items.append_array(revealed_items)
		return all_items

## Current item being searched
var current_search_item: ItemData = null
var search_progress: float = 0.0
var search_time_required: float = 0.0
var is_searching: bool = false

## Ship tier for loot generation (set by BoardingManager)
var ship_tier: int = 1

## Container data from ContainerTypes
var container_data: ContainerTypesClass.ContainerData = null

# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	add_to_group("containers")
	_load_container_data()
	_setup_visuals()
	set_state(ContainerState.CLOSED)
	
	# Connect hover signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _process(delta: float) -> void:
	if is_searching and current_search_item:
		_update_search(delta)
		search_pulse_time += delta
	else:
		search_pulse_time = 0.0
	
	# Update hover highlight with pulse effect
	if is_hovered and highlight and highlight.visible:
		pulse_time += delta
		var pulse = (sin(pulse_time * 5.0) + 1.0) / 2.0
		var glow_rect = highlight.get_node_or_null("Glow")
		if glow_rect:
			glow_rect.color.a = 0.2 + pulse * 0.15


# ==============================================================================
# CONTAINER SETUP
# ==============================================================================

func _load_container_data() -> void:
	container_data = ContainerTypesClass.get_container(container_type_id)
	if container_data:
		container_name = container_data.display_name


## Set the container type (called by BoardingManager)
func set_container_type(type_id: int) -> void:
	container_type_id = type_id
	_load_container_data()


## Generate loot for this container based on ship and container type
## NOTE: faction_code parameter added to support faction-specific items.
##       This is backward compatible - leave empty for non-faction-specific loot.
func generate_loot(tier: int, _container_type: int = -1, faction_code: String = "") -> void:
	ship_tier = tier
	if _container_type >= 0:
		set_container_type(_container_type)
	
	hidden_items.clear()
	revealed_items.clear()
	
	# Determine item count based on container type
	var count = randi_range(min_items, max_items)
	if container_data:
		count = randi_range(container_data.min_slots, container_data.max_slots)
	
	# Generate items using the faction-aware system if faction is specified
	var items: Array = []
	if faction_code != "":
		items = ItemDB.generate_container_loot_with_faction(ship_tier, container_type_id, count, faction_code)
	else:
		# Fallback to non-faction-specific loot
		items = ItemDB.generate_container_loot(ship_tier, container_type_id, count)
	
	for item in items:
		if item:
			hidden_items.append(item)
	
	_update_visuals()


# ==============================================================================
# SEARCH SYSTEM
# ==============================================================================

## Instantly reveal all items (for immediate loot menu opening)
func reveal_all_items() -> void:
	for item in hidden_items:
		revealed_items.append(item)
	hidden_items.clear()
	is_searching = false


## Check if container can be searched (has unrevealed items)
func can_be_searched() -> bool:
	var valid_state = current_state in [ContainerState.CLOSED, ContainerState.SEARCHING]
	return valid_state and not hidden_items.is_empty()


## Check if container can be looted (has revealed items)
func can_be_looted() -> bool:
	return current_state == ContainerState.OPEN and not revealed_items.is_empty()


## Start searching the container
func start_search() -> void:
	if hidden_items.is_empty():
		return
	
	if current_state == ContainerState.CLOSED:
		set_state(ContainerState.SEARCHING)
		emit_signal("container_opened")
	
	# Pick next item to search
	current_search_item = hidden_items[0]
	search_progress = 0.0
	
	# Calculate search time based on item rarity and container type
	var modifier = container_data.search_time_modifier if container_data else 1.0
	var base_time = SearchSystemClass.calculate_search_time(current_search_item, modifier)
	search_time_required = base_time
	
	is_searching = true
	emit_signal("search_started")


## Cancel the current search (called when player moves)
func cancel_search() -> void:
	if not is_searching:
		return
	
	is_searching = false
	search_progress = 0.0
	current_search_item = null
	
	emit_signal("search_cancelled")
	_update_visuals()


## Update search progress
func _update_search(delta: float) -> void:
	search_progress += delta
	
	var progress_percent = search_progress / search_time_required
	emit_signal("search_progress_updated", progress_percent)
	
	if search_progress_bar:
		search_progress_bar.value = progress_percent * 100.0
	
	if search_progress >= search_time_required:
		_complete_current_search()


## Complete searching current item
func _complete_current_search() -> void:
	if not current_search_item:
		return
	
	# Move item from hidden to revealed
	hidden_items.erase(current_search_item)
	revealed_items.append(current_search_item)
	
	emit_signal("item_revealed", current_search_item)
	
	is_searching = false
	search_progress = 0.0
	current_search_item = null
	
	# Check if all items revealed
	if hidden_items.is_empty():
		set_state(ContainerState.OPEN)
		emit_signal("search_completed")
	else:
		# Auto-start searching next item
		start_search()
	
	_update_visuals()


# ==============================================================================
# INTERACTION (Legacy + New Support)
# ==============================================================================

func can_interact() -> bool:
	return current_state in [ContainerState.CLOSED, ContainerState.SEARCHING, ContainerState.OPEN]


func get_interact_prompt() -> String:
	match current_state:
		ContainerState.CLOSED:
			var item_count = hidden_items.size() + revealed_items.size()
			if item_count > 0:
				return "[E] Loot %s (%d items)" % [container_name, item_count]
			return "[E] Loot %s" % container_name
		ContainerState.OPEN:
			return "[E] Loot %s (%d items)" % [container_name, revealed_items.size()]
		ContainerState.EMPTY:
			return "(Empty)"
		ContainerState.LOCKED:
			return "[E] Hack Lock"
	return ""


func interact() -> Dictionary:
	var result = {
		"action": "",
		"items": [],
		"container": self
	}
	
	match current_state:
		ContainerState.CLOSED:
			if not hidden_items.is_empty():
				start_search()
				result["action"] = "searching"
			else:
				set_state(ContainerState.OPEN)
				result["action"] = "opened"
		
		ContainerState.SEARCHING:
			# Already searching, just continue
			result["action"] = "searching"
		
		ContainerState.OPEN:
			result["action"] = "loot"
			result["items"] = revealed_items.duplicate()
	
	return result


func open_container() -> void:
	# Legacy support - just start searching
	if current_state == ContainerState.CLOSED:
		if not hidden_items.is_empty():
			start_search()
		else:
			set_state(ContainerState.OPEN)
			emit_signal("container_opened")


func take_all_items() -> Array[ItemData]:
	var items = revealed_items.duplicate()
	revealed_items.clear()
	
	emit_signal("container_looted", items)
	
	if revealed_items.is_empty() and hidden_items.is_empty():
		set_state(ContainerState.EMPTY)
		emit_signal("container_emptied")
	
	return items


func remove_item(item: ItemData) -> bool:
	var idx = revealed_items.find(item)
	if idx >= 0:
		revealed_items.remove_at(idx)
		
		if revealed_items.is_empty() and hidden_items.is_empty():
			set_state(ContainerState.EMPTY)
			emit_signal("container_emptied")
		
		return true
	return false


# ==============================================================================
# STATE MANAGEMENT
# ==============================================================================

## Public method to set container state
func set_state(new_state: ContainerState) -> void:
	current_state = new_state
	_update_visuals()


func _update_visuals() -> void:
	var color: Color
	var label_text: String
	
	match current_state:
		ContainerState.CLOSED:
			color = closed_color
			var total = hidden_items.size() + revealed_items.size()
			label_text = "%d items" % total if total > 0 else ""
		ContainerState.SEARCHING:
			color = searching_color
			# Add pulsing effect during search
			var pulse = (sin(search_pulse_time * 3.0) + 1.0) / 2.0
			color = color.lerp(Color(0.5, 0.5, 0.6), pulse * 0.3)
			label_text = "Searching..."
		ContainerState.OPEN:
			color = open_color
			label_text = "%d items" % revealed_items.size()
		ContainerState.EMPTY:
			color = empty_color
			label_text = "Empty"
		ContainerState.LOCKED:
			color = Color(0.5, 0.3, 0.3)
			label_text = "Locked"
	
	if sprite:
		sprite.modulate = color
	
	if state_label:
		state_label.text = label_text
		state_label.visible = label_text != ""
	
	if search_progress_bar:
		search_progress_bar.visible = is_searching


func set_highlighted(highlighted: bool) -> void:
	is_highlighted = highlighted
	if highlight:
		highlight.visible = highlighted


# ==============================================================================
# LEGACY ITEM GENERATION (kept for backwards compatibility)
# ==============================================================================

## Legacy method - generates items using old tier system
func _generate_items() -> void:
	hidden_items.clear()
	revealed_items.clear()
	
	# Use the old loot_tier system for backwards compatibility
	var legacy_tier = int(loot_tier)
	var count = randi_range(min_items, max_items)
	var items = ItemDB.generate_container_loot(legacy_tier, container_type_id, count)
	for item in items:
		if item:
			hidden_items.append(item)


# ==============================================================================
# SETUP
# ==============================================================================

## Sprite path mapping for each container type
const CONTAINER_SPRITES = {
	0: "res://assets/sprites/boarding/container_scrap_pile.svg",
	1: "res://assets/sprites/boarding/container_cargo_crate.svg",
	2: "res://assets/sprites/boarding/container_locker.svg",
	3: "res://assets/sprites/boarding/container_supply_cabinet.svg",
	4: "res://assets/sprites/boarding/container_vault.svg",
	5: "res://assets/sprites/boarding/container_armory.svg",
	6: "res://assets/sprites/boarding/container_secure_cache.svg"
}

func _setup_visuals() -> void:
	if highlight:
		highlight.visible = false
	if search_progress_bar:
		search_progress_bar.visible = false
		search_progress_bar.value = 0
	
	# Load container sprite based on type
	_load_container_sprite()


## Load the SVG sprite for this container type
func _load_container_sprite() -> void:
	if not sprite:
		return
	
	var sprite_path = CONTAINER_SPRITES.get(container_type_id, CONTAINER_SPRITES[1])
	
	if ResourceLoader.exists(sprite_path):
		var texture = load(sprite_path)
		if texture:
			sprite.texture = texture
			sprite.scale = Vector2(1, 1)  # Adjust scale as needed
			
			# Hide the old ColorRect children if they exist
			for child in sprite.get_children():
				if child is ColorRect:
					child.visible = false
	else:
		print("Warning: Container sprite not found: ", sprite_path)


# ==============================================================================
# HOVER EFFECTS
# ==============================================================================

func _on_mouse_entered() -> void:
	is_hovered = true
	_show_highlight()


func _on_mouse_exited() -> void:
	is_hovered = false
	_hide_highlight()


func _show_highlight() -> void:
	if not highlight:
		return
	
	# Cancel any existing tween
	if hover_tween:
		hover_tween.kill()
	
	highlight.visible = true
	var glow_rect = highlight.get_node_or_null("Glow")
	if glow_rect:
		hover_tween = create_tween()
		hover_tween.tween_property(glow_rect, "color:a", 0.3, 0.2)


func _hide_highlight() -> void:
	if not highlight:
		return
	
	# Cancel any existing tween
	if hover_tween:
		hover_tween.kill()
	
	var glow_rect = highlight.get_node_or_null("Glow")
	if glow_rect:
		hover_tween = create_tween()
		hover_tween.tween_property(glow_rect, "color:a", 0.0, 0.2)
		# Don't await - let it finish in background to avoid tween conflicts
	
	# Use a timer instead of await to hide after animation
	get_tree().create_timer(0.2).timeout.connect(func(): 
		if highlight and not is_hovered:
			highlight.visible = false
	)
