# ==============================================================================
# LOOT SYSTEM DOCUMENTATION
# ==============================================================================
#
# This document explains the cargo looting minigame system in detail.
# Use this as a reference for understanding, modifying, or extending the system.
#
# ==============================================================================

## TABLE OF CONTENTS
1. [Overview](#overview)
2. [Game Flow](#game-flow)
3. [Controls](#controls)
4. [Components](#components)
5. [Item System](#item-system)
6. [Inventory System](#inventory-system)
7. [Creating New Items](#creating-new-items)
8. [Customization](#customization)

---

## OVERVIEW

The loot system is a time-based search and organize minigame. Players must:
1. Open cargo containers
2. Search items (revealing them from silhouettes)
3. Drag items to their grid-based inventory
4. Maximize value before time runs out
5. Escape (triggering the next phase)

This creates tension and strategic decisions:
- Do I search this large item or two small ones?
- Can I fit this valuable but oddly-shaped item?
- Should I keep searching or escape now?

---

## GAME FLOW

```
┌─────────────┐
│ START LOOT  │
│   PHASE     │
└──────┬──────┘
       ▼
┌─────────────────────────────────────┐
│  TIMER STARTS (default: 60 seconds) │
└──────────────────┬──────────────────┘
       ▼
┌─────────────────────────────────────┐
│  CONTAINERS GENERATED (4 default)   │
│  Each contains 3-6 random items     │
└──────────────────┬──────────────────┘
       ▼
┌─────────────────────────────────────┐
│           PLAYER ACTIONS:           │
│  • Click container → Opens it       │
│  • Click item → Starts searching    │
│  • Drag revealed → To inventory     │
│  • 1-9 → Quick select slot          │
│  • Q → Drop selected item           │
│  • E → Use/equip selected item      │
│  • Tab/I → Toggle inventory         │
│  • Esc → Close menus                │
└──────────────────┬──────────────────┘
       ▼
┌─────────────────────────────────────┐
│  TIMER HITS ZERO or ESCAPE CLICKED  │
└──────────────────┬──────────────────┘
       ▼
┌─────────────────────────────────────┐
│  CALCULATE TOTAL INVENTORY VALUE    │
│  ADD TO SCORE                       │
└──────────────────┬──────────────────┘
       ▼
┌─────────────────────────────────────┐
│  TRANSITION TO ESCAPE PHASE         │
│  (Space dodge minigame)             │
└─────────────────────────────────────┘
```

---

## CONTROLS

### Mouse Controls
- **Left-click** on container → Opens container
- **Left-click** on hidden item → Starts searching/revealing
- **Left-click and drag** revealed item → Pick up and move
- **Release** over inventory → Place item in inventory
- **Right-click** item in inventory → Destroy item

### Keyboard Shortcuts
- **1-9** → Quick select inventory slots (items are sorted top-left to bottom-right)
- **Q** → Drop/destroy the currently selected item
- **E** → Use/equip the currently selected item
- **Tab / I** → Toggle inventory view (uses existing inventory action)
- **Escape** → Close menus (uses existing ui_cancel action)

**Note:** The selected inventory slot is highlighted with a blue color to show which item is active.

---

## COMPONENTS

### LootManager (`loot_manager.gd`)
The main controller that orchestrates everything.

**Responsibilities:**
- Spawns and manages containers
- Tracks time remaining
- Coordinates drag-drop between containers and inventory
- Handles escape transition
- Manages item database

**Key Variables:**
```gdscript
@export var loot_time: float = 60.0          # Total looting time
@export var container_count: int = 4          # Number of containers
@export var min_items_per_container: int = 3  # Minimum items
@export var max_items_per_container: int = 6  # Maximum items
```

### CargoContainer (`container.gd`)
Represents a searchable cargo container.

**States:**
- `CLOSED` - Shows "OPEN" button
- `OPEN` - Items visible as silhouettes
- `EMPTY` - All items taken

**Key Features:**
- Automatically populates with items
- Manages item visibility/arrangement
- Emits signals when items are searched/taken

### LootItem (`loot_item.gd`)
The visual representation of an item in the world.

**States:**
- `HIDDEN` - Black silhouette, unknown
- `SEARCHING` - Progress bar showing
- `REVEALED` - Item visible, can be dragged
- `IN_INVENTORY` - Placed in inventory grid

**Key Features:**
- Hold-to-search mechanic with progress bar
- Drag-and-drop functionality
- Rarity glow effects

### GridInventory (`inventory.gd`)
The grid-based inventory system.

**How It Works:**
```
Grid (8x6 = 48 cells):
[0,0][1,0][2,0][3,0][4,0][5,0][6,0][7,0]
[0,1][1,1][2,1][3,1][4,1][5,1][6,1][7,1]
[0,2][1,2][2,2][3,2][4,2][5,2][6,2][7,2]
[0,3][1,3][2,3][3,3][4,3][5,3][6,3][7,3]
[0,4][1,4][2,4][3,4][4,4][5,4][6,4][7,4]
[0,5][1,5][2,5][3,5][4,5][5,5][6,5][7,5]

Items occupy multiple cells:
[A ][A ][B ][ ][ ][ ][ ][ ]
[A ][A ][B ][ ][C ][ ][ ][ ]
[ ][ ][B ][ ][C ][ ][ ][ ]
[ ][ ][ ][ ][ ][ ][ ][ ]
```

**Key Functions:**
```gdscript
can_place_item_at(item, grid_pos)  # Check if item fits
place_item(item, grid_pos)          # Place item
find_valid_position(item)           # Auto-find spot
auto_place_item(item)               # Auto-place item
```

### ItemData (`item_data.gd`)
A Resource class that defines item properties.

**Properties:**
```gdscript
@export var name: String              # Display name
@export var grid_width: int = 1       # Width in cells
@export var grid_height: int = 2      # Height in cells
@export var value: int = 100          # Worth in credits
@export var rarity: int = 0           # 0-4 (Common to Legendary)
@export var base_search_time: float   # Time to search
@export var sprite: Texture2D         # Item image
```

---

## ITEM SYSTEM

### Rarity Tiers

| Tier | Name | Color | Value Range | Drop Chance |
|------|------|-------|-------------|-------------|
| 0 | Common | Gray (#B3B3B3) | $25-100 | 50% |
| 1 | Uncommon | Green (#4DCC4D) | $80-200 | 25% |
| 2 | Rare | Blue (#4D80FF) | $300-500 | 15% |
| 3 | Epic | Purple (#B34DE6) | $500-1000 | 7% |
| 4 | Legendary | Gold (#FFCC33) | $1500+ | 3% |

### Default Items

**Common (Rarity 0):**
| Name | Size | Value | Search Time |
|------|------|-------|-------------|
| Scrap Metal | 1x1 | $25 | 1.5s |
| Circuit Board | 2x1 | $50 | 2.0s |
| Fuel Cell | 1x2 | $60 | 2.0s |

**Uncommon (Rarity 1):**
| Name | Size | Value | Search Time |
|------|------|-------|-------------|
| Medical Kit | 2x1 | $100 | 2.0s |
| Data Chip | 1x1 | $80 | 1.5s |
| Plasma Coil | 1x3 | $150 | 2.5s |

**Rare (Rarity 2):**
| Name | Size | Value | Search Time |
|------|------|-------|-------------|
| Weapon Core | 2x2 | $300 | 3.0s |
| Nav Computer | 2x2 | $350 | 3.0s |
| Shield Generator | 2x3 | $400 | 3.5s |

**Epic (Rarity 3):**
| Name | Size | Value | Search Time |
|------|------|-------|-------------|
| Alien Artifact | 2x2 | $750 | 4.0s |
| Quantum CPU | 1x1 | $500 | 3.0s |
| Stealth Module | 3x2 | $800 | 4.5s |

**Legendary (Rarity 4):**
| Name | Size | Value | Search Time |
|------|------|-------|-------------|
| Dark Matter Core | 2x2 | $1500 | 5.0s |
| Ancient Relic | 3x3 | $2500 | 6.0s |

### Value Density

A key strategy concept: value per cell.

```
Value Density = Value / (Width × Height)

Examples:
- Quantum CPU:    $500 / 1 = $500/cell  ← Very efficient!
- Dark Matter:    $1500 / 4 = $375/cell
- Ancient Relic:  $2500 / 9 = $278/cell ← Big but less efficient
```

Players must decide: grab high-density small items or gamble on big valuable ones?

---

## INVENTORY SYSTEM

### Grid Mechanics

The inventory is an 8×6 grid (48 cells total).
Default cell size: 64×64 pixels.

**Placement Rules:**
1. Item must fit within grid bounds
2. All cells item would occupy must be empty
3. Items cannot overlap

### Visual Feedback

| State | Cell Color |
|-------|------------|
| Empty | Dark gray (0.15, 0.15, 0.2) |
| Occupied | Lighter gray (0.25, 0.25, 0.3) |
| Valid hover | Green (0.2, 0.6, 0.2) |
| Invalid hover | Red (0.6, 0.2, 0.2) |

### Drag-Drop Flow

```
1. Player clicks revealed item in container
2. Item enters DRAGGING state
3. Inventory shows hover preview
4. Green = valid drop, Red = invalid
5. Player releases mouse:
   - If valid: Item placed, removed from container
   - If invalid: Item returns to container
```

---

## CREATING NEW ITEMS

### Method 1: In Code (loot_manager.gd)

```gdscript
func load_item_database() -> void:
    # Create using helper function
    var my_item = ItemData.create_item("Super Widget", 2, 2, 999)
    my_item.rarity = 3
    my_item.description = "An amazing widget!"
    item_database.append(my_item)
    
    # Or create manually
    var manual_item = ItemData.new()
    manual_item.id = "laser_gun"
    manual_item.name = "Laser Gun"
    manual_item.grid_width = 3
    manual_item.grid_height = 1
    manual_item.value = 250
    manual_item.rarity = 2
    manual_item.base_search_time = 2.0
    item_database.append(manual_item)
```

### Method 2: Resource Files (Recommended for Production)

1. In Godot, right-click `resources/items/`
2. Create New → Resource
3. Select "ItemData" as type
4. Name it (e.g., "laser_gun.tres")
5. Configure properties in Inspector:
   - Name: "Laser Gun"
   - Grid Width: 3
   - Grid Height: 1
   - Value: 250
   - Rarity: 2
   - Sprite: (assign texture)
6. Save the resource

Then load in code:
```gdscript
var laser = load("res://resources/items/laser_gun.tres")
item_database.append(laser)
```

---

## CUSTOMIZATION

### Adjusting Difficulty

In `loot_scene.tscn` or `loot_manager.gd`:

```gdscript
# More time = easier
@export var loot_time: float = 90.0  # 90 seconds instead of 60

# More containers = more choices
@export var container_count: int = 6

# More items = more loot
@export var min_items_per_container: int = 4
@export var max_items_per_container: int = 8
```

### Changing Inventory Size

In `inventory.gd` or the scene:

```gdscript
@export var grid_width: int = 10   # Wider inventory
@export var grid_height: int = 8   # Taller inventory
@export var cell_size: int = 48    # Smaller cells (more fit on screen)
```

### Adjusting Rarity Weights

In `loot_manager.gd`, modify `get_weighted_random_item()`:

```gdscript
func get_weighted_random_item() -> ItemData:
    var rarity_roll = randf()
    var max_rarity: int
    
    # Make legendaries more common:
    if rarity_roll < 0.4:       # Was 0.5
        max_rarity = 0
    elif rarity_roll < 0.65:    # Was 0.75
        max_rarity = 1
    elif rarity_roll < 0.80:    # Was 0.9
        max_rarity = 2
    elif rarity_roll < 0.90:    # Was 0.97
        max_rarity = 3
    else:                       # 10% legendary now!
        max_rarity = 4
```

### Adding Item Rotation (Future Feature)

To implement rotation:

1. Add rotation state to LootItem:
```gdscript
var is_rotated: bool = false

func rotate_item() -> void:
    is_rotated = !is_rotated
    # Swap visual width/height
```

2. Modify grid size getter:
```gdscript
func get_grid_size() -> Vector2i:
    if is_rotated:
        return Vector2i(item_data.grid_height, item_data.grid_width)
    return Vector2i(item_data.grid_width, item_data.grid_height)
```

3. Add input handling:
```gdscript
if Input.is_action_just_pressed("rotate_item") and is_dragging:
    rotate_item()
```

---

## SIGNALS REFERENCE

### LootManager Signals
```gdscript
signal looting_started                    # Phase begins
signal looting_ended(total_value: int)    # Phase ends
signal item_looted(item: LootItem)        # Item placed in inventory
signal time_warning(seconds_left: int)    # Low time warning
signal escape_triggered                   # Transition to escape
```

### Container Signals
```gdscript
signal container_opened
signal container_closed
signal item_searched(item: LootItem)
signal item_taken(item: LootItem)
```

### LootItem Signals
```gdscript
signal search_started
signal search_progress(progress: float)
signal item_revealed
signal item_picked_up
signal item_dropped(success: bool)
```

### Inventory Signals
```gdscript
signal item_placed(item: LootItem, grid_pos: Vector2i)
signal item_removed(item: LootItem)
signal inventory_changed
signal inventory_full
```

---

## TROUBLESHOOTING

### Items not appearing in containers
- Check that `loot_item_scene` is assigned in container
- Verify `item_database` is populated in `load_item_database()`
- Check console for error messages

### Drag-drop not working
- Ensure `LootItem` has `mouse_filter` set properly
- Check that `ItemsLayer` has `mouse_filter = MOUSE_FILTER_IGNORE`
- Verify item state is `REVEALED` before dragging

### Items not fitting in inventory
- Check grid dimensions in `inventory.gd`
- Verify item `grid_width` and `grid_height` values
- Use `find_valid_position()` to debug placement

### Timer not working
- Ensure `LootTimer` and `WarningTimer` nodes exist
- Check timer connections in `_ready()`
- Verify `loot_time` is set correctly
