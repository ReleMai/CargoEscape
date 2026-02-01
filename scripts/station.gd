# ==============================================================================
# HIDEOUT - BLACK MARKET STATION
# ==============================================================================
#
# FILE: scripts/station.gd
# PURPOSE: Hideout where player can sell loot on the black market and buy upgrades
#
# FEATURES:
# ---------
# - Appears when player reaches the hideout
# - Shows black market interface for selling loot
# - Displays mission stats (distance, time, value collected)
# - Upgrades shop (future)
# - Item shop (future)
# - Offers option to start new heist or return to menu
#
# ==============================================================================

extends Control
class_name SpaceStation


# ==============================================================================
# SIGNALS
# ==============================================================================

## Emitted when player chooses to start a new mission
signal new_mission_requested

## Emitted when player sells items
signal items_sold(total_value: int)

## Emitted when player ends their run
signal run_ended(final_score: int)


# ==============================================================================
# EXPORTS
# ==============================================================================

@export_group("UI References")

## Panel containing station UI
@export var station_panel: PanelContainer

## Label showing station name
@export var station_name_label: Label

## Label showing mission stats
@export var stats_label: RichTextLabel

## Label showing inventory value
@export var value_label: Label

## Label showing total credits
@export var credits_label: Label

## Container for inventory grid preview
@export var inventory_preview: Control

## Sell all button
@export var sell_button: Button

## Upgrades button (future)
@export var upgrades_button: Button

## Shop button (future)
@export var shop_button: Button

## New mission button
@export var mission_button: Button

## End run button
@export var end_button: Button


@export_group("Hideout Settings")

## Hideout names (randomly selected)
@export var hideout_names: Array[String] = [
	"The Rusty Anchor",
	"Shadow's Den",
	"Smuggler's Rest",
	"Black Nebula Station",
	"The Pirate's Haven"
]

## Base sell price multiplier (can vary by hideout)
@export_range(0.5, 2.0, 0.1) var price_multiplier: float = 1.0


# ==============================================================================
# STATE
# ==============================================================================

## Reference to the inventory
var inventory_ref: GridInventory = null

## Mission statistics
var mission_stats: Dictionary = {
	"distance": 0.0,
	"time": 0.0,
	"items_collected": 0,
	"damage_taken": 0
}

## Total credits earned this session
var total_credits: int = 0

## Current hideout name
var current_hideout_name: String = ""


# ==============================================================================
# LIFECYCLE
# ==============================================================================

func _ready() -> void:
	visible = false
	
	# Get node references
	station_panel = get_node_or_null("StationPanel")
	station_name_label = get_node_or_null("StationPanel/VBox/Header/StationName")
	stats_label = get_node_or_null("StationPanel/VBox/Stats")
	value_label = get_node_or_null("StationPanel/VBox/ValueContainer/ValueLabel")
	credits_label = get_node_or_null("StationPanel/VBox/CreditsContainer/CreditsLabel")
	sell_button = get_node_or_null("StationPanel/VBox/ButtonContainer/SellButton")
	upgrades_button = get_node_or_null("StationPanel/VBox/ButtonContainer/UpgradesButton")
	shop_button = get_node_or_null("StationPanel/VBox/ButtonContainer/ShopButton")
	mission_button = get_node_or_null("StationPanel/VBox/ActionContainer/MissionButton")
	end_button = get_node_or_null("StationPanel/VBox/ActionContainer/EndButton")
	
	# Connect buttons if they exist
	if sell_button:
		sell_button.pressed.connect(_on_sell_pressed)
	if upgrades_button:
		upgrades_button.pressed.connect(_on_upgrades_pressed)
	if shop_button:
		shop_button.pressed.connect(_on_shop_pressed)
	if mission_button:
		mission_button.pressed.connect(_on_new_mission_pressed)
	if end_button:
		end_button.pressed.connect(_on_end_run_pressed)
	
	# Add sell button to tutorial group
	if sell_button:
		sell_button.name = "SellButton"


# ==============================================================================
# PUBLIC API
# ==============================================================================

## Show the station UI with mission results
func show_station(inventory: GridInventory, stats: Dictionary = {}) -> void:
	inventory_ref = inventory
	mission_stats = stats
	
	# Pick random hideout name
	current_hideout_name = hideout_names[randi() % hideout_names.size()]
	
	# Update UI
	_update_hideout_name()
	_update_stats_display()
	_update_value_display()
	_update_credits_display()
	
	# Show with animation
	visible = true
	_animate_show()
	
	# Start selling tutorial step if needed
	_check_and_start_selling_tutorial()


## Hide the station UI
func hide_station() -> void:
	_animate_hide()


## Get total value of inventory with current price multiplier
func get_sell_value() -> int:
	if not inventory_ref:
		return 0
	return int(inventory_ref.get_total_value() * price_multiplier)


# ==============================================================================
# UI UPDATES
# ==============================================================================

func _update_hideout_name() -> void:
	if station_name_label:
		station_name_label.text = current_hideout_name


func _update_stats_display() -> void:
	if not stats_label:
		return
	
	var distance_raw: float = mission_stats.get("distance", 0.0)
	var distance_km := distance_raw / 1000.0
	var time_sec: float = mission_stats.get("time", 0.0)
	var time_min := int(time_sec / 60)
	var time_remaining := int(time_sec) % 60
	var items: int = mission_stats.get("items_collected", 0)
	var damage: int = mission_stats.get("damage_taken", 0)
	
	var stats_text := """[center][b]ESCAPE SUCCESSFUL[/b][/center]

[table=2]
[cell]Distance:[/cell][cell][right]%.1f km[/right][/cell]
[cell]Escape Time:[/cell][cell][right]%d:%02d[/right][/cell]
[cell]Items Looted:[/cell][cell][right]%d[/right][/cell]
[cell]Hits Taken:[/cell][cell][right]%d[/right][/cell]
[/table]""" % [distance_km, time_min, time_remaining, items, damage]
	
	stats_label.text = stats_text


func _update_value_display() -> void:
	if value_label:
		var sell_value := get_sell_value()
		var base_value := inventory_ref.get_total_value() if inventory_ref else 0
		
		if price_multiplier != 1.0:
			value_label.text = "Cargo Value: $%d (×%.1f = $%d)" % [
				base_value, price_multiplier, sell_value
			]
		else:
			value_label.text = "Cargo Value: $%d" % sell_value
	
	# Update sell button state
	if sell_button:
		sell_button.disabled = get_sell_value() <= 0


func _update_credits_display() -> void:
	if credits_label:
		credits_label.text = "Credits: $%d" % total_credits


# ==============================================================================
# BUTTON HANDLERS
# ==============================================================================

func _on_sell_pressed() -> void:
	if not inventory_ref:
		return
	
	var sell_value := get_sell_value()
	
	if sell_value <= 0:
		# Nothing to sell
		return
	
	# Notify tutorial
	_on_item_sold()
	
	# Add to total credits
	total_credits += sell_value
	
	# Clear inventory
	inventory_ref.clear_all()
	
	# Update display
	_update_value_display()
	_update_credits_display()
	
	# Emit signal
	items_sold.emit(sell_value)
	
	print("[Hideout] Sold cargo for $%d. Total credits: $%d" % [sell_value, total_credits])


func _on_upgrades_pressed() -> void:
	# TODO: Open upgrades menu
	print("[Hideout] Upgrades - Coming soon!")


func _on_shop_pressed() -> void:
	# TODO: Open shop menu
	print("[Hideout] Shop - Coming soon!")


func _on_new_mission_pressed() -> void:
	new_mission_requested.emit()
	hide_station()


func _on_end_run_pressed() -> void:
	run_ended.emit(total_credits)
	hide_station()
	# Return to main menu
	LoadingScreen.start_transition("res://scenes/intro/intro_scene.tscn")


# ==============================================================================
# ANIMATIONS
# ==============================================================================

func _animate_show() -> void:
	if station_panel:
		station_panel.modulate.a = 0
		station_panel.scale = Vector2(0.8, 0.8)
		
		var tween := create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_parallel(true)
		tween.tween_property(station_panel, "modulate:a", 1.0, 0.3)
		tween.tween_property(station_panel, "scale", Vector2.ONE, 0.4)


func _animate_hide() -> void:
	if station_panel:
		var tween := create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_BACK)
		tween.set_parallel(true)
		tween.tween_property(station_panel, "modulate:a", 0.0, 0.2)
		tween.tween_property(station_panel, "scale", Vector2(0.8, 0.8), 0.2)
		tween.chain().tween_callback(func(): visible = false)


# ==============================================================================
# TUTORIAL INTEGRATION
# ==============================================================================

func _check_and_start_selling_tutorial() -> void:
	# Wait for animation
	await get_tree().create_timer(0.5).timeout
	
	# Check if TutorialManager exists
	if not has_node("/root/TutorialManager"):
		return
	
	var tutorial_manager = get_node("/root/TutorialManager")
	
	# Check if we need to show selling tutorial
	if tutorial_manager.is_tutorial_active():
		# Start selling step
		tutorial_manager.start_step(tutorial_manager.TutorialStep.SELLING)


func _on_item_sold() -> void:
	# Notify tutorial that item was sold
	if has_node("/root/TutorialManager"):
		var tutorial_manager = get_node("/root/TutorialManager")
		tutorial_manager.on_player_action("item_sold")

