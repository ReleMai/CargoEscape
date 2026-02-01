# Ship Generation System Design Document

## Overview

This document outlines the procedural ship generation system for Cargo Escape. The system creates
unique, explorable ship interiors based on faction, ship class, tier, and distance from the player's
hideout. Each ship should feel distinct while following consistent design rules.

---

## Table of Contents

1. [Core Concepts](#core-concepts)
2. [Factions](#factions)
3. [Ship Classes](#ship-classes)
4. [Room Types](#room-types)
5. [Generation Algorithm](#generation-algorithm)
6. [Visual Theming](#visual-theming)
7. [Loot Distribution](#loot-distribution)
8. [Implementation Plan](#implementation-plan)

---

## Core Concepts

### Design Philosophy
- **Uniqueness**: Each ship should feel different, even within the same tier
- **Coherence**: Ships must follow logical layouts (bridges at front, engines at back)
- **Fairness**: Player should always be able to navigate from entry to exit
- **Scalability**: System should support adding new factions/ship types easily

### Key Parameters
| Parameter | Description |
|-----------|-------------|
| Faction | The organization owning the ship (affects visuals, loot, layout style) |
| Ship Class | The type/role of the ship (cargo, military, luxury, etc.) |
| Tier | Difficulty level 1-5 (affects size, time, loot quality) |
| Distance Factor | How far from hideout (0.0-1.0, affects tier probability) |
| Seed | Random seed for reproducible generation |

---

## Factions

### Overview
Factions determine the visual theme, loot specialization, and layout preferences of ships.

### Faction Definitions

#### 1. **Civilian Commerce Guild** (CCG)
- **Theme**: Industrial, orange/brown, worn
- **Specialty**: Basic supplies, scrap, common goods
- **Ship Classes**: Cargo Shuttle, Freight Hauler
- **Layout Style**: Open cargo bays, simple corridors
- **Danger Level**: Low
- **Color Palette**:
  - Hull: `#8C6B4F` (rust brown)
  - Accent: `#BF9B30` (gold-yellow)
  - Interior: `#403830` (dark brown)

#### 2. **Nexus Corporation** (NEX)
- **Theme**: Clean, white/gold, corporate
- **Specialty**: Valuables, tech components, rare items
- **Ship Classes**: Corporate Transport, Executive Shuttle
- **Layout Style**: Organized offices, luxury suites, secured areas
- **Danger Level**: Medium
- **Color Palette**:
  - Hull: `#E8E8EC` (off-white)
  - Accent: `#D4AF37` (metallic gold)
  - Interior: `#484850` (charcoal gray)

#### 3. **Galactic Defense Force** (GDF)
- **Theme**: Military, dark gray/red, tactical
- **Specialty**: Weapons, military modules, armor
- **Ship Classes**: Patrol Frigate, Assault Cruiser, Military Transport
- **Layout Style**: Barracks, armories, tactical corridors
- **Danger Level**: High
- **Color Palette**:
  - Hull: `#40444C` (dark steel)
  - Accent: `#CC3333` (warning red)
  - Interior: `#2E3038` (dark gray)

#### 4. **Shadow Syndicate** (SYN)
- **Theme**: Covert, black/cyan, stealth
- **Specialty**: Artifacts, legendary items, contraband
- **Ship Classes**: Black Ops Vessel, Smuggler Ship
- **Layout Style**: Hidden compartments, mazes, security systems
- **Danger Level**: Extreme
- **Color Palette**:
  - Hull: `#141418` (near-black)
  - Accent: `#00D9E0` (neon cyan)
  - Interior: `#1A1A20` (very dark gray)

#### 5. **Independent Traders** (IND)
- **Theme**: Mixed, varied colors, eclectic
- **Specialty**: Random assortment, rare finds
- **Ship Classes**: Any (repurposed ships)
- **Layout Style**: Irregular, modified layouts
- **Danger Level**: Variable
- **Color Palette**: Varies per ship

---

## Ship Classes

### Class Definitions

| Class | Base Size | Tier Range | Typical Faction | Room Count |
|-------|-----------|------------|-----------------|------------|
| Cargo Shuttle | 900x600 | 1 | CCG, IND | 2-4 |
| Freight Hauler | 1100x700 | 1-2 | CCG | 4-7 |
| Corporate Transport | 1200x750 | 2-3 | NEX | 5-9 |
| Patrol Frigate | 1300x800 | 3-4 | GDF | 6-10 |
| Military Cruiser | 1400x850 | 4-5 | GDF | 8-12 |
| Black Ops Vessel | 1500x900 | 5 | SYN | 9-13 |
| Smuggler Ship | 1000x650 | 2-3 | IND, SYN | 4-8 |

### Class-Specific Features

#### Cargo Shuttle
- Simple layouts with large open spaces
- Entry at rear, exit at front
- 1-2 large cargo bays

#### Freight Hauler  
- Multiple cargo bays connected by corridors
- Crew quarters at front
- Loading bays on sides

#### Corporate Transport
- Central atrium or lobby
- Executive offices
- Conference rooms
- Secure vault area

#### Patrol Frigate
- Bridge at front
- Engine room at rear
- Central corridor spine
- Side armories and crew quarters

#### Military Cruiser
- Multiple deck feel
- Command center
- Large armory
- Barracks section

#### Black Ops Vessel
- Maze-like layout
- Hidden rooms
- Multiple dead ends
- Central secure area

---

## Room Types

### Room Categories

#### Essential Rooms (always present)
| Room Type | Min Size | Max Size | Purpose |
|-----------|----------|----------|---------|
| Entry Airlock | 80x80 | 100x100 | Player spawn point |
| Exit Airlock | 80x80 | 100x100 | Escape point |
| Corridor | 80xVaries | 120xVaries | Connects rooms |

#### Common Rooms
| Room Type | Min Size | Max Size | Container Types | Notes |
|-----------|----------|----------|-----------------|-------|
| Cargo Bay | 150x150 | 300x250 | Crate, Scrap Pile | Large open space |
| Storage | 100x100 | 150x150 | Crate, Locker | Medium room |
| Crew Quarters | 100x80 | 150x120 | Locker, Cabinet | Personal items |
| Supply Room | 80x80 | 120x120 | Cabinet, Crate | Components |

#### Special Rooms (faction/class specific)
| Room Type | Factions | Container Types | Loot Focus |
|-----------|----------|-----------------|------------|
| Bridge | All | Cabinet, Console | Tech, Valuables |
| Engine Room | All | Scrap, Cabinet | Components, Scrap |
| Armory | GDF, SYN | Armory Locker, Crate | Weapons, Modules |
| Vault | NEX, SYN | Vault, Secure Cache | Epic/Legendary |
| Medical Bay | GDF, NEX | Cabinet, Locker | Components, Supplies |
| Lab | NEX, SYN | Cabinet, Cache | Rare Tech |
| Executive Suite | NEX | Locker, Cabinet | Valuables |
| Barracks | GDF | Locker, Crate | Mixed |
| Server Room | NEX, SYN | Console | Tech Components |
| Contraband Hold | SYN, IND | Hidden Cache | Artifacts |

### Room Decorations

Each room type has associated decorations:

```
CARGO BAY:
  - Stacked crates (background)
  - Floor markings
  - Cargo lifts (non-functional)
  - Warning stripes

CREW QUARTERS:
  - Beds/bunks
  - Personal effects
  - Wall lockers
  - Lighting fixtures

BRIDGE:
  - Control panels
  - Viewscreen (background)
  - Captain's chair
  - Navigation console

ARMORY:
  - Weapon racks (background)
  - Ammo crates
  - Security barriers
  - Warning signs

ENGINE ROOM:
  - Pipes and conduits
  - Generator units
  - Warning lights
  - Grated floors
```

---

## Generation Algorithm

### Overview

The generation uses a **Grid-Based Room Placement** algorithm with **Corridor Connection** to ensure:
1. No overlapping rooms
2. All rooms are connected
3. Entry and exit are always accessible

### Step-by-Step Process

```
1. INITIALIZATION
   ├── Set ship size based on class/tier
   ├── Create grid (cells of 40x40 pixels)
   ├── Initialize random seed
   └── Determine room count based on tier

2. ROOM PLACEMENT
   ├── Place Entry Airlock (left side)
   ├── Place Exit Airlock (right side or opposite corner)
   ├── Place required rooms for class type
   │   ├── Bridge (front)
   │   ├── Engine Room (back, if military/large)
   │   └── Faction-specific rooms
   ├── Fill remaining space with appropriate rooms
   └── Validate no overlaps

3. CORRIDOR GENERATION
   ├── Build Minimum Spanning Tree between room centers
   ├── Add corridors along tree edges
   ├── Optionally add 1-2 extra connections for loops
   └── Ensure entry connects to main network

4. CONTAINER PLACEMENT
   ├── For each room:
   │   ├── Determine appropriate container types
   │   ├── Calculate container count (tier-based)
   │   └── Place containers with minimum spacing
   └── Validate positions don't block paths

5. VISUAL GENERATION
   ├── Draw floor tiles per room type
   ├── Draw walls and doors
   ├── Add decorations per room type
   └── Apply faction color theme

6. VALIDATION
   ├── Pathfind from entry to exit
   ├── Ensure all containers are reachable
   └── Verify minimum time is achievable
```

### Grid Cell System

```
Grid Cell Size: 40x40 pixels

Cell States:
  EMPTY     = 0  # Available for room
  WALL      = 1  # Ship hull/boundary
  ROOM      = 2  # Part of a room
  CORRIDOR  = 3  # Walkway
  DOOR      = 4  # Connection point
  RESERVED  = 5  # Entry/exit zones
```

### Room Placement Rules

```python
# Pseudocode for room placement
func place_room(room_type, preferred_position):
    size = get_room_size(room_type)
    
    # Try preferred position first
    if can_place_at(preferred_position, size):
        return create_room(preferred_position, size, room_type)
    
    # Try nearby positions
    for offset in spiral_search_pattern:
        test_pos = preferred_position + offset
        if can_place_at(test_pos, size):
            return create_room(test_pos, size, room_type)
    
    # Try any valid position
    for cell in all_cells:
        if can_place_at(cell, size):
            return create_room(cell, size, room_type)
    
    return null  # Failed to place

func can_place_at(position, size):
    rect = Rect2(position, size)
    
    # Check bounds
    if not ship_bounds.encloses(rect):
        return false
    
    # Check overlap with existing rooms
    for room in placed_rooms:
        if rect.intersects(room.rect.grow(MIN_ROOM_GAP)):
            return false
    
    return true
```

### Corridor Connection Algorithm

```python
# Minimum Spanning Tree using Prim's algorithm
func connect_rooms(rooms):
    corridors = []
    connected = [rooms[0]]
    unconnected = rooms.slice(1)
    
    while unconnected.size() > 0:
        best_distance = INF
        best_pair = null
        
        for connected_room in connected:
            for unconnected_room in unconnected:
                dist = room_distance(connected_room, unconnected_room)
                if dist < best_distance:
                    best_distance = dist
                    best_pair = [connected_room, unconnected_room]
        
        # Create corridor between rooms
        corridor = create_corridor(best_pair[0], best_pair[1])
        corridors.append(corridor)
        
        connected.append(best_pair[1])
        unconnected.erase(best_pair[1])
    
    # Add extra loops for variety (optional)
    for i in range(randi() % 2):
        add_random_connection(rooms, corridors)
    
    return corridors
```

---

## Visual Theming

### Color Application

```gdscript
# Theme structure
class FactionTheme:
    var hull_color: Color
    var accent_color: Color
    var interior_floor: Color
    var interior_wall: Color
    var lighting_tint: Color
    var glow_color: Color
    var decoration_style: String  # "industrial", "corporate", "military", "stealth"
```

### Floor Patterns

Each room type has a distinct floor pattern:

```
CARGO BAY: Grid lines, wear marks, yellow safety stripes
CORRIDOR: Directional arrows, center line
CREW QUARTERS: Carpet texture (corporate), metal grating (military)
BRIDGE: Clean panels, subtle glow accents
ENGINE ROOM: Warning stripes, pipe shadows
ARMORY: Reinforced floor pattern, red accents
```

### Wall Decorations

Walls can have:
- Faction logos
- Warning signs
- Posters/propaganda
- Technical panels
- Damage/wear (lower tier ships)

### Lighting Effects

```gdscript
# Lighting based on faction and room type
func get_room_lighting(faction: Faction, room_type: RoomType) -> Dictionary:
    var base = faction.lighting_tint
    
    match room_type:
        RoomType.ENGINE_ROOM:
            return {"color": base.lerp(Color.ORANGE, 0.3), "intensity": 0.8}
        RoomType.ARMORY:
            return {"color": base.lerp(Color.RED, 0.2), "intensity": 0.9}
        RoomType.BRIDGE:
            return {"color": base.lerp(Color.CYAN, 0.1), "intensity": 1.0}
        _:
            return {"color": base, "intensity": 0.85}
```

---

## Loot Distribution

### Container Placement Rules

1. **Room-Container Affinity**: Each room type has preferred container types
2. **Density by Tier**: Higher tiers = more containers per room
3. **Spacing**: Minimum 60px between containers, 80px from walls
4. **Accessibility**: All containers must be reachable from corridors

### Loot Quality Formula

```gdscript
func calculate_loot_quality(
    ship_tier: int,
    faction: Faction,
    room_type: RoomType,
    container_type: ContainerType,
    distance_factor: float
) -> Dictionary:
    
    var base_weights = {
        "common": 100,
        "uncommon": 50,
        "rare": 20,
        "epic": 5,
        "legendary": 1
    }
    
    # Apply tier modifier
    var tier_mod = pow(1.3, ship_tier - 1)
    
    # Apply faction specialization
    var faction_mod = faction.get_rarity_mods()
    
    # Apply room bonus
    var room_mod = room_type.get_loot_bonus()
    
    # Apply container modifier
    var container_mod = container_type.rarity_modifiers
    
    # Apply distance bonus
    var distance_mod = 1.0 + (distance_factor * 0.5)
    
    var final_weights = {}
    for rarity in base_weights:
        final_weights[rarity] = (
            base_weights[rarity] *
            tier_mod *
            faction_mod.get(rarity, 1.0) *
            room_mod.get(rarity, 1.0) *
            container_mod.get(rarity, 1.0) *
            distance_mod
        )
    
    return final_weights
```

### Special Loot Rules

- **Vaults**: Always contain at least 1 Rare+ item
- **Armory**: 70% chance of weapon/module items
- **Contraband Hold**: 50% chance of Artifact category
- **Bridge**: 30% chance of navigation/tech valuable

---

## Implementation Plan

### Phase 1: Core Data Structures
1. Create `Faction` class with themes and modifiers
2. Create `ShipClass` class with size/room requirements
3. Create `RoomType` enum and data class
4. Update `ShipTypes` to use new system

### Phase 2: Grid-Based Generator
1. Implement grid cell system
2. Create room placement algorithm
3. Implement corridor connection (MST)
4. Add validation and path checking

### Phase 3: Visual Renderer
1. Update `ShipInteriorRenderer` for new system
2. Implement floor patterns per room type
3. Add wall decoration system
4. Implement faction theming

### Phase 4: Container Integration
1. Room-based container type selection
2. Smart placement avoiding paths
3. Loot quality calculation

### Phase 5: Polish & Testing
1. Add entrance/exit animations
2. Test all tier/faction combinations
3. Balance loot distribution
4. Performance optimization

---

## File Structure

```
scripts/
├── data/
│   ├── factions.gd          # Faction definitions
│   ├── ship_classes.gd      # Ship class definitions
│   ├── room_types.gd        # Room type definitions
│   ├── ship_types.gd        # (Updated) Ship tier system
│   └── container_types.gd   # (Existing) Container types
├── boarding/
│   ├── ship_generator.gd    # Main generation logic
│   ├── ship_layout.gd       # (Updated) Layout data structures
│   ├── grid_system.gd       # Grid-based placement
│   ├── corridor_builder.gd  # Corridor generation
│   ├── ship_interior_renderer.gd # (Updated) Visual rendering
│   └── boarding_manager.gd  # (Existing) Game controller
└── ...

resources/
├── factions/
│   ├── ccg_theme.tres
│   ├── nex_theme.tres
│   ├── gdf_theme.tres
│   └── syn_theme.tres
├── rooms/
│   └── decorations/
└── ...

assets/
├── sprites/
│   ├── rooms/
│   │   ├── floors/
│   │   ├── walls/
│   │   └── decorations/
│   └── factions/
│       ├── ccg/
│       ├── nex/
│       ├── gdf/
│       └── syn/
└── ...
```

---

## API Reference

### ShipGenerator

```gdscript
class_name ShipGenerator

## Generate a complete ship layout
static func generate(
    tier: int,
    faction: Faction = null,
    ship_class: ShipClass = null,
    seed: int = -1
) -> ShipLayoutData

## Generate with distance factor (auto-selects tier/faction)
static func generate_for_distance(
    distance_factor: float,
    seed: int = -1
) -> ShipLayoutData
```

### ShipLayoutData

```gdscript
class_name ShipLayoutData

var ship_tier: int
var faction: Faction
var ship_class: ShipClass
var ship_size: Vector2
var rooms: Array[RoomData]
var corridors: Array[CorridorData]
var containers: Array[ContainerPlacement]
var entry_position: Vector2
var exit_position: Vector2
var theme: FactionTheme
var generation_seed: int
```

---

*Document Version: 1.0*
*Last Updated: 2026-02-01*
