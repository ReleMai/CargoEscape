# ==============================================================================
# ITEM DATA RESOURCE
# ==============================================================================
#
# FILE: scripts/loot/item_data.gd
# PURPOSE: Defines the data structure for lootable items
#
# WHAT IS A RESOURCE?
# -------------------
# A Resource in Godot is a data container that can be saved to disk.
# Think of it like a "template" or "blueprint" for items.
# 
# Benefits:
# - Create items in the editor without code
# - Reusable across multiple scenes
# - Easy to modify and balance
# - Can be saved/loaded from files
#
# HOW TO CREATE NEW ITEMS:
# 1. In Godot, right-click in FileSystem
# 2. Create New > Resource
# 3. Select "ItemData" as the type
# 4. Configure the properties in the Inspector
# 5. Save as .tres file (e.g., "gold_bar.tres")
#
# ==============================================================================

# "extends Resource" makes this a data-only class
# "class_name ItemData" registers it globally so you can use it anywhere
extends Resource
class_name ItemData


# ==============================================================================
# ITEM PROPERTIES
# ==============================================================================

@export_group("Basic Info")
## Unique identifier for this item type
@export var id: String = "item_unknown"

## Display name shown to player
@export var name: String = "Unknown Item"

## Description shown in tooltips
@export_multiline var description: String = "A mysterious item."

@export_group("Grid Size")
## Width in inventory grid cells (1-4 typical)
@export_range(1, 6) var grid_width: int = 1

## Height in inventory grid cells (1-4 typical)
@export_range(1, 6) var grid_height: int = 2

@export_group("Value & Rarity")
## How much this item is worth (credits/gold)
@export var value: int = 100

## Black market value (usually different from regular value)
@export var black_market_value: int = 100

## Physical weight in kg (affects cargo capacity)
@export var weight: float = 1.0

## Item tags for categorization and trading
@export var tags: Array[String] = []

## Rarity tier affects spawn rates and visual effects
## 0=Common, 1=Uncommon, 2=Rare, 3=Epic, 4=Legendary
@export_range(0, 4) var rarity: int = 0

## Item category for container loot weighting
## 0=Scrap, 1=Component, 2=Valuable, 3=Module, 4=Artifact
@export_range(0, 4) var category: int = 0

## Faction-specific item (null = can appear on any faction)
## "CCG", "NEX", "GDF", "SYN", "IND", or "" for non-faction-specific
@export var faction_exclusive: String = ""

@export_group("Search Time")
## Base time to search/identify this item (seconds)
## Larger/rarer items take longer to search
@export var base_search_time: float = 2.0

## Multiplier based on size (auto-calculated if 0)
@export var search_time_multiplier: float = 0.0

@export_group("Visuals")
## The actual item sprite (shown after searching)
@export var sprite: Texture2D

## Optional: Custom silhouette (if not provided, auto-generated from sprite)
@export var silhouette_sprite: Texture2D

## Color tint for rarity glow
@export var rarity_color: Color = Color.WHITE


# ==============================================================================
# COMPUTED PROPERTIES
# ==============================================================================

## Get total grid cells this item occupies
func get_cell_count() -> int:
	return grid_width * grid_height


## Get the actual search time (base + size modifier)
func get_search_time() -> float:
	if search_time_multiplier > 0:
		return base_search_time * search_time_multiplier
	else:
		# Auto-calculate based on size: larger items take longer
		var size_factor = 1.0 + (get_cell_count() - 1) * 0.3
		return base_search_time * size_factor


## Get value per cell (efficiency metric)
func get_value_density() -> float:
	return float(value) / float(get_cell_count())


## Get rarity name as string
func get_rarity_name() -> String:
	match rarity:
		0: return "Common"
		1: return "Uncommon"
		2: return "Rare"
		3: return "Epic"
		4: return "Legendary"
		_: return "Unknown"


## Get rarity color (if not custom set)
func get_rarity_color() -> Color:
	if rarity_color != Color.WHITE:
		return rarity_color
	
	match rarity:
		0: return Color(0.7, 0.7, 0.7)      # Gray - Common
		1: return Color(0.3, 0.8, 0.3)      # Green - Uncommon
		2: return Color(0.3, 0.5, 1.0)      # Blue - Rare
		3: return Color(0.7, 0.3, 0.9)      # Purple - Epic
		4: return Color(1.0, 0.8, 0.2)      # Gold - Legendary
		_: return Color.WHITE


# ==============================================================================
# STATIC HELPER - Create item programmatically
# ==============================================================================

## Create a basic item from code (useful for testing)
static func create_item(item_name: String, width: int, height: int, item_value: int) -> ItemData:
	var item = ItemData.new()
	item.id = item_name.to_lower().replace(" ", "_")
	item.name = item_name
	item.grid_width = width
	item.grid_height = height
	item.value = item_value
	item.base_search_time = 1.0 + width * height * 0.5
	return item
