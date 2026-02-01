# Comprehensive Item Database System

## Overview

This directory contains the comprehensive item database system with full metadata support for all game items.

## Directory Structure

```
resources/items/
├── item_database.gd          # Comprehensive item definitions with all metadata
├── scrap/                     # Common scrap items (.tres files)
├── components/                # Uncommon component items
├── valuables/                 # Rare valuable items
├── epic/                      # Epic tier items
├── legendary/                 # Legendary tier items
└── modules/                   # Ship upgrade modules
```

## Item Properties

Each item in the database includes the following comprehensive metadata:

### Basic Information
- **name**: Display name shown to players
- **id**: Unique identifier for the item
- **description**: Flavor text shown in tooltips
- **tags**: Array of classification tags (e.g., `["weapon", "illegal", "tech"]`)

### Physical Properties
- **weight**: Weight in kilograms - affects inventory capacity
- **grid_width** / **grid_height**: Size in inventory grid
- **stack_size**: Maximum stackable amount

### Economic Properties
- **base_value**: Price at regular stations (credits)
- **black_market_value**: Price at black market (higher for illegal items)
- **rarity**: Enum value (COMMON=0, UNCOMMON=1, RARE=2, EPIC=3, LEGENDARY=4)

### Faction System
- **faction_affinity**: Which faction commonly has this item (-1 = universal)
  - -1: Universal (any faction)
  - 0: CCG (Civilian Commerce Guild)
  - 1: NEX (Nexus Corporation)
  - 2: GDF (Galactic Defense Force)
  - 3: SYN (Shadow Syndicate)
  - 4: IND (Independent Traders)
- **faction_restricted**: Array of faction IDs that WON'T have this item

### Spawn Settings
- **spawn_weight**: Probability weight in loot tables (1.0 = normal, 2.0 = twice as likely)

### Visual
- **icon_path**: Path to sprite asset

## Usage Examples

### Loading Items from Comprehensive Database

```gdscript
# Load the comprehensive database
var ComprehensiveDB = preload("res://resources/items/item_database.gd")

# Create an item from the comprehensive database
var item = ComprehensiveDB.create_item_from_comprehensive_data("weapon_core")

# Access new properties
print(item.tags)  # ["valuable", "weapon", "military", "illegal", "dangerous"]
print(item.weight)  # 8.0
print(item.base_value)  # 400
print(item.black_market_value)  # 800
print(item.is_illegal())  # true
```

### Using Tags

```gdscript
# Check if item has a specific tag
if item.has_tag("illegal"):
    print("This item is illegal!")

# Get all illegal items
var illegal_items = ComprehensiveDB.get_items_by_tag("illegal")
```

### Faction-Based Filtering

```gdscript
# Get all items associated with GDF (military)
var gdf_items = ComprehensiveDB.get_items_by_faction(2)  # 2 = GDF

# Check if item is restricted for a faction
if item.is_restricted_for_faction(0):  # 0 = CCG
    print("This item won't appear on CCG ships")
```

### Black Market vs Station Value

```gdscript
# Get appropriate value based on location
var station_price = item.get_station_value()
var black_market_price = item.get_black_market_value()

print("Station: %d credits" % station_price)
print("Black Market: %d credits" % black_market_price)
```

### Rarity-Based Queries

```gdscript
# Get all legendary items
var legendary_items = ComprehensiveDB.get_items_by_rarity(4)  # 4 = LEGENDARY

# Get rarity name
print(item.get_rarity_name())  # "Epic", "Legendary", etc.
```

## Creating New Items

### Method 1: Using .tres Resource Files (Recommended)

1. In Godot Editor, right-click in FileSystem
2. Select "New Resource"
3. Choose "ItemData" as the resource type
4. Fill in all properties in the Inspector
5. Save to appropriate category folder (e.g., `resources/items/valuables/`)

### Method 2: Adding to item_database.gd

Add item definitions to the appropriate category function:

```gdscript
static func _get_valuable_items() -> Dictionary:
    return {
        "your_item_id": {
            "name": "Your Item Name",
            "id": "your_item_id",
            "description": "Item description here",
            "tags": ["valuable", "tech"],
            "weight": 5.0,
            "base_value": 250,
            "black_market_value": 400,
            "rarity": Rarity.RARE,
            "faction_affinity": 1,  # NEX
            "faction_restricted": [0],  # Not on CCG
            "spawn_weight": 0.5,
            "stack_size": 5,
            "icon_path": "res://assets/sprites/items/your_item.svg",
            "width": 2,
            "height": 1,
            "category": 2
        }
    }
```

## Item Categories

### Scrap (Category 0)
- Common items, low value
- High spawn weights (1.5-2.0)
- Stackable (20-99)
- Examples: scrap_metal, scrap_plastics, wire_bundle

### Components (Category 1)
- Uncommon items, medium value
- Medium spawn weights (0.8-1.2)
- Moderate stacking (5-20)
- Examples: data_chip, fuel_cell, plasma_coil

### Valuables (Category 2)
- Rare items, high value
- Low spawn weights (0.3-0.5)
- Usually non-stackable or low stacks
- Examples: gold_bar, weapon_core, targeting_array

### Modules (Category 3)
- Ship upgrade equipment
- Various rarities
- Always non-stackable (1)
- Examples: module_scanner, module_shield

### Artifacts (Category 4)
- Epic/Legendary items, extremely high value
- Very low spawn weights (0.01-0.2)
- Always non-stackable (1)
- Often illegal
- Examples: alien_artifact, quantum_core, singularity_gem

## Illegal Items and Black Market

Items tagged with "illegal" have special properties:
- Higher black_market_value than base_value
- May be restricted from certain factions
- Often have "dangerous" or "weapon" tags
- Typically found on Shadow Syndicate (SYN) ships

Examples:
- `weapon_core`: 400 credits (station) → 800 credits (black market)
- `alien_artifact`: 850 credits → 2500 credits
- `singularity_gem`: 5000 credits → 15000 credits

## Weight System

Weight affects inventory management:
- Lighter items are more efficient (better weight-to-value ratio)
- Heavy items limit how much you can carry
- Use `get_weight_density()` to calculate weight per grid cell

Examples:
- `scrap_metal`: 5.0 kg (heavy, low value)
- `data_chip`: 0.2 kg (very light, good value)
- `dark_matter_vial`: 0.1 kg (extremely light, legendary value)
- `void_shard`: 50.0 kg (extremely heavy despite small size)

## Integration with Existing Systems

The comprehensive database integrates seamlessly with the existing loot system:

1. **ItemDatabase** (`scripts/loot/item_database.gd`) - Original database still works
2. **ComprehensiveItemDatabase** (`resources/items/item_database.gd`) - New enhanced database
3. Both can be used together - the comprehensive database extends the original

The original `ItemDatabase.create_item()` function now supports all new properties when they're defined in the item definitions.

## Testing

To test the comprehensive database:

```gdscript
# In your test scene or script
var ComprehensiveDB = preload("res://resources/items/item_database.gd")

# Get all item IDs
var all_ids = ComprehensiveDB.get_all_item_ids()
print("Total items: ", all_ids.size())

# Test creating each item
for item_id in all_ids:
    var item = ComprehensiveDB.create_item_from_comprehensive_data(item_id)
    print("%s: %s (%s)" % [item.id, item.name, item.get_rarity_name()])
    print("  Tags: %s" % [item.tags])
    print("  Station value: %d, Black market: %d" % [item.get_station_value(), item.get_black_market_value()])
```

## Future Enhancements

Potential additions to the system:
- Durability/condition system
- Item crafting/combining
- Quest items with special flags
- Time-limited items
- Item sets/collections
- Dynamic pricing based on supply/demand
- Item modifications/upgrades
