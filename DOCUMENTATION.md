# Cargo Escape - Side Scroller Space Game
## Learning Documentation

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Godot Concepts Explained](#godot-concepts-explained)
3. [Project Structure](#project-structure)
4. [Scene Breakdown](#scene-breakdown)
5. [Script Explanations](#script-explanations)
6. [How to Extend](#how-to-extend)

---

## Project Overview

**Cargo Escape** is a two-phase space heist game:

### Phase 1: Looting (Cargo Search)
- Search through cargo containers on a ship
- Items appear as silhouettes until searched
- Click items to search them (radial timer shows progress)
- Drag revealed items to your grid-based inventory
- Organize items to maximize value before timer runs out

### Phase 2: Escape (Space Dodge)
- Control a rocket ship with Newtonian space physics
- The screen auto-scrolls from right to left
- Enemies spawn and move toward the player
- Touching an enemy costs the player a life
- The goal is to escape with your loot

### Game Mechanics
- **Looting**: Click containers to open, click items to search (radial timer), drag to inventory
- **Inventory**: Grid-based system - items have different sizes, organize to fit more
- **Movement**: WASD to thrust, Space/Shift to brake
- **Space Physics**: Momentum-based, no gravity, drift in space
- **Lives System**: Player starts with 3 lives
- **Scrolling**: Background parallax scrolling creates depth illusion
- **Enemies**: Asteroids with various movement patterns

---

## Godot Concepts Explained

### What is a Node?
A **Node** is the fundamental building block in Godot. Everything in your game is a node:
- Sprites (images)
- Physics bodies (collision)
- Audio players
- UI elements

Nodes are organized in a **tree structure** (parent-child relationships).

### What is a Scene?
A **Scene** is a collection of nodes saved as a reusable file (`.tscn`).
Think of scenes as prefabs or templates. Examples:
- `player.tscn` - The rocket ship with all its components
- `enemy.tscn` - An asteroid that can be spawned multiple times
- `main.tscn` - The main game scene that combines everything

### Common Node Types Used in This Project

| Node Type | Purpose |
|-----------|---------|
| `Node2D` | Base node for 2D games, can hold children |
| `CharacterBody2D` | Physics body for player/enemy movement |
| `Area2D` | Detects overlaps/collisions without physics |
| `Sprite2D` | Displays an image/texture |
| `CollisionShape2D` | Defines collision boundaries |
| `ParallaxBackground` | Creates scrolling background layers |
| `ParallaxLayer` | Individual layer in parallax background |
| `Timer` | Triggers events after time passes |
| `AudioStreamPlayer` | Plays sound effects/music |
| `CanvasLayer` | UI layer that stays fixed on screen |
| `Label` | Displays text |

### GDScript Basics

GDScript is Godot's built-in scripting language. It's similar to Python.

```gdscript
# Variables
var health: int = 100          # Typed variable
var speed = 200.0              # Inferred type
@export var damage: int = 10   # Editable in Inspector

# Functions
func _ready():
    # Called when node enters the scene tree
    pass

func _process(delta):
    # Called every frame
    # delta = time since last frame (for smooth movement)
    pass

func _physics_process(delta):
    # Called at fixed intervals (for physics)
    pass

# Signals (events)
signal player_hit
emit_signal("player_hit")  # Trigger the signal
```

### Important GDScript Concepts

1. **`@export`** - Makes a variable editable in the Godot Inspector
2. **`@onready`** - Gets node reference when scene is ready
3. **`delta`** - Time between frames (multiply by speed for smooth movement)
4. **Signals** - Godot's event system for communication between nodes
escape game scene
│   ├── player.tscn        # Player rocket ship
│   ├── enemy.tscn         # Enemy asteroid
│   ├── background.tscn    # Parallax background
│   ├── loot/              # Looting minigame scenes
│   │   ├── loot_scene.tscn    # Main looting scene
│   │   ├── container.tscn     # Cargo container
│   │   ├── loot_item.tscn     # Individual item
│   │   └── inventory.tscn     # Grid inventory
│   └── ui/
│       ├── hud.tscn           # Escape phase HUD
│       └── game_over_screen.tscn
│
├── scripts/               # All script files (.gd)
│   ├── main.gd            # Escape game logic
│   ├── player.gd          # Player movement & collision
│   ├── enemy.gd           # Enemy behavior
│   ├── game_manager.gd    # Global game state (autoload)
│   ├── background.gd      # Parallax scrolling
│   ├── loot/              # Looting system scripts
│   │   ├── loot_manager.gd    # Main loot controller
│   │   ├── container.gd       # Container logic
│   │   ├── loot_item.gd       # Item in world
│   │   ├── item_data.gd       # Item Resource class
│   │   └── inventory.gd       # Grid inventory system
│   └── ui/
│       └── hud.gd         # HUD updates
│
├── assets/                # Game assets
│   ├── sprites/           # Image files
│   │   ├── player/
│   │   ├── enemies/
│   │   ├── items/         # Loot item sprites
│   │   └── background/
│   └── audio/             # Sound files (future)
│
└── resources/             # Godot resources
    ├── items/             # ItemData resources (.tres)te (autoload)
│   ├── background.gd      # Parallax scrolling
│   └── ui/
│       └── hud.gd         # HUD updates
│
├── assets/                # Game assets
│   ├── sprites/           # Image files
│   │   ├── player/
│   │   ├── enemies/
│   │   └── background/
│   └── audio/             # Sound files (future)
│
└── resources/             # Godot resources
    └── themes/            # UI themes (future)
```

---

## Scene Breakdown

### Loot Scene (`loot/loot_scene.tscn`)
The cargo looting minigame:
```
LootScene (Control)
├── Background              # Dark cargo bay background
├── Title                   # "CARGO LOOTING" label
├── TimerPanel              # Countdown timer display
│   └── TimerLabel
├── ContainersArea          # Where containers spawn
│   └── Container x4        # Searchable cargo containers
├── InventoryPanel          # Right side panel
│   ├── InventoryLabel
│   └── Inventory           # Grid-based inventory
├── EscapeButton            # Manual escape trigger
├── LootTimer               # Main countdown
├── WarningTimer            # Warning beeps
└── Instructions            # Help text
```

### Container Scene (`loot/container.tscn`)
```
Container (Control)
├── ContainerPanel          # Visual container box
│   ├── ContainerLabel      # "Container 1" etc.
│   ├── ItemsContainer      # Holds items inside
│   ├── ClosedOverlay       # Dark overlay when closed
│   └── OpenButton          # "OPEN" button
```

### Inventory Scene (`loot/inventory.tscn`)
```
Inventory (Control)
├── Background              # Panel background
├── GridContainer           # Visual grid cells
├── ItemsLayer              # Placed items render here
├── HoverPreview            # Drop preview indicator
└── TotalValueLabel         # "$0" total value
```

### Main Scene (`main.tscn`)
The escape phase root scene:
```
Main (Node2D)
├── ParallaxBackground      # Scrolling space background
│   ├── StarLayer1          # Far stars (slow)
│   ├── StarLayer2          # Medium stars
│   └── StarLayer3          # Close stars (fast)
├── Player                  # Instance of player.tscn
├── EnemySpawner (Timer)    # Spawns enemies periodically
├── HUD (CanvasLayer)       # UI overlay
└── GameOverScreen          # Shown when lives = 0
```

### Player Scene (`player.tscn`)
```
Player (CharacterBody2D)
├── Sprite2D                # Rocket ship image
├── CollisionShape2D        # Hit detection
└── HurtBox (Area2D)        # Detects enemy collision
    └── CollisionShape2D
```

### Enemy Scene (`enemy.tscn`)
```
Enemy (Area2D)
├── Sprite2D                # Asteroid image
├── CollisionShape2D        # Hit detection
└── VisibleOnScreenNotifier2D  # Cleanup when off-screen
```

---

## Script Explanations

Each script file contains detailed comments explaining:
- What the script does
- How each function works
- Why certain approaches are used
- Tips for modification

See individual script files for full documentation.

---

## How to Extend

### Adding New Item Types
1. Create new ItemData resource in `resources/items/`
2. Set grid size, value, rarity, search time
3. Add item sprite to `assets/sprites/items/`
4. Items auto-populate in containers

### Creating Custom Items in Code
```gdscript
var custom_item = ItemData.create_item("Diamond Ring", 1, 1, 500)
custom_item.rarity = 3  # Epic
custom_item.description = "A valuable ring"
```

### Adding New Enemy Types
1. Duplicate `enemy.tscn`
2. Change the sprite
3. Modify `enemy.gd` or create a new script
4. Add to spawner logic in `main.gd`

### Adding More Movement Patterns
In `enemy.gd`, add to the MovementPattern enum and implement in `update_pattern_movement()`

### Adding Power-ups
1. Create `powerup.tscn` (similar to enemy)
2. Create `powerup.gd` script
3. Add spawn logic to `main.gd`
4. Handle collection in `player.gd`

### Adding Sound Effects
1. Add audio files to `assets/audio/`
2. Add `AudioStreamPlayer` nodes
3. Call `.play()` when needed

---

## Quick Reference

### Input Actions (set in Project Settings > Input Map)
- `move_up` - W / Up Arrow - Thrust up
- `move_down` - S / Down Arrow - Thrust down
- `move_left` - A / Left Arrow - Thrust left
- `move_right` - D / Right Arrow - Thrust right
- `brake` - Space / Shift - Apply brakes (slow down)

### Loot System Quick Reference
| Rarity | Color | Drop Chance |
|--------|-------|-------------|
| Common | Gray | 50% |
| Uncommon | Green | 25% |
| Rare | Blue | 15% |
| Epic | Purple | 7% |
| Legendary | Gold | 3% |

### Item Value Density
To maximize loot value, consider:
- `value / (grid_width * grid_height)` = value density
- Higher density items = more efficient inventory use
- Sometimes a small epic beats a large rare

### Signals Used
- `looting_started` - Loot phase begins
- `looting_ended(value)` - Loot phase ends with total value
- `item_looted` - Item placed in inventory
- `escape_triggered` - Transition to escape phase
- `player_hit` - When player touches enemy
- `player_died` - When lives reach 0
- `enemy_destroyed` - When enemy leaves screen

### Layer Setup (for collision)
- Layer 1: Player
- Layer 2: Enemies
- Layer 3: Collectibles (future)

---

## Learning Resources

- [Official Godot Docs](https://docs.godotengine.org/)
- [GDQuest YouTube](https://www.youtube.com/c/gdquest)
- [Godot Recipes](https://kidscancode.org/godot_recipes/)
